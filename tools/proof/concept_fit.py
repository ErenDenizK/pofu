#!/usr/bin/env python3
"""Fit Codex's world-concept takes (pofu-art batch-112) to the phone frame and measure how far they drifted.

    python3 tools/proof/concept_fit.py TAKES_DIR --refs R1_DIR --out OUT_DIR

docs/design/world-concepts-plan.md, review point 1. Per take (`x-concept-<distance>-<locked|free>[...]`):

  1. crop the 1024 x 1536 take to the phone frame (x 159 to 865, 706 px) and scale it to 1206 x 2622;
  2. paste the app's real chrome back, cut from the R1 still of that distance (a rounded mask per control);
  3. measure drift from the guide (the R1 still, softened to the guide's 706 px so both are equally sharp);
  4. write `<take>-fit.png`, one `sheet-<distance>.jpg` (script proof | locked | free) and `report.txt/json`.

R1_DIR holds `composition.py`'s stills and their `.json` sidecars (boxes in pt on the 402 x 874 frame):
map-journey-stage3, map-homefirst-stage3, mid-level10, near-rest. TAKES_DIR is the folder of Codex's takes
(png/jpg/webp); the job id must be in the file name, anything after it (a variant number) is free.

HOW DRIFT IS MEASURED. For each box of the sidecar (a subject, a chrome control, a backdrop feature) the guide's
patch, the box plus a margin, is turned into an edge map (Sobel magnitude of the blurred luminance) and matched to
the take's edge map by normalised cross-correlation, over a search window of +-SEARCH pt and a few scales
(0.90 to 1.10). Edges, not colour, so a repaint of light, air and cloud does not hide or fake a move. The result
is the shift of the box centre in device px (1206 x 2622, 3 px per pt), a size ratio, and the correlation (below
SCORE_MIN the match is `uncertain`: the box was repainted past recognition, look at it). Positions of a locked take
are judged by `drift` = the largest of |dx| and |dy|: over MOVED_PX (12) a subject or control is `moved` and the
take is not shown as locked. A free take is not judged, its drift is information. The horizon is the vertical shift
that best aligns the take's row profile (luminance and saturation, subjects and chrome masked out) with the
guide's around the guide's horizon; over HORIZON_WARN_PX it is flagged. Backdrop features (far isles, whale) are
reported, never judged: a paint-over may redraw them.

Needs numpy, OpenCV and Pillow only.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

W, H, PT = 1206, 2622, 3.0
CANVAS_W, CANVAS_H = 1024, 1536
CROP_X0, CROP_X1 = 159, 865
MOVED_PX = 12.0          # a locked subject or control further than this from the guide is `moved`
HORIZON_WARN_PX = 24.0
SEARCH_PT = 40.0         # search radius around the guide position
MARGIN_PT = 8.0          # context around a box
SCALES = (0.90, 0.94, 0.97, 1.0, 1.03, 1.06, 1.10)
SCORE_MIN = 0.30
WORK = 0.5               # matching runs at half device resolution

# distance -> still, and the sidecar's chrome mask radius (pt) per control id (default: a full pill, h / 2)
STILLS = {
    "map-journey": "map-journey-stage3",
    "map-homefirst": "map-homefirst-stage3",
    "mid": "mid-level10",
    "near": "near-rest",
}
CHROME_RADIUS_PT = {"card": 22.0}
JOB_RE = re.compile(r"x-concept-(map-homefirst|map|mid|near)-(locked|free)")


# ---------------------------------------------------------------- the frame

def frame_from_take(take: Image.Image) -> Image.Image:
    """The 1024 x 1536 take cut to the phone screen and scaled to 1206 x 2622."""
    if take.size != (CANVAS_W, CANVAS_H):
        take = take.resize((CANVAS_W, CANVAS_H), Image.LANCZOS)
    return take.convert("RGB").crop((CROP_X0, 0, CROP_X1, CANVAS_H)).resize((W, H), Image.LANCZOS)


def guide_frame(still: Image.Image) -> Image.Image:
    """The still as the guide holds it: 706 x 1536 and back, so it is as soft as a take can be."""
    return still.convert("RGB").resize((CROP_X1 - CROP_X0, CANVAS_H), Image.LANCZOS).resize((W, H), Image.LANCZOS)


def chrome_mask(box_pt, ctrl_id: str, feather_px: float = 2.0) -> np.ndarray:
    """Float mask (H, W) of one control: a rounded rectangle, edge feathered."""
    x0, y0, x1, y1 = (round(v * PT) for v in box_pt)
    r = CHROME_RADIUS_PT.get(ctrl_id)
    r = round(r * PT) if r else (y1 - y0) // 2
    r = min(r, (x1 - x0) // 2, (y1 - y0) // 2)
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).rounded_rectangle((x0, y0, x1, y1), radius=r, fill=255)
    a = np.asarray(m, np.float32) / 255.0
    return cv2.GaussianBlur(a, (0, 0), feather_px) if feather_px else a


def paste_chrome(frame: Image.Image, still: Image.Image, chrome: list[dict]) -> Image.Image:
    """The real controls from the still over the take: each inside its rounded mask."""
    out = np.asarray(frame, np.float32)
    src = np.asarray(still.convert("RGB"), np.float32)
    for c in chrome:
        a = chrome_mask(c["box"], c["id"])[..., None]
        out = out * (1 - a) + src * a
    return Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8))


# ---------------------------------------------------------------- drift

def edge_map(img: Image.Image) -> np.ndarray:
    g = cv2.cvtColor(np.asarray(img.convert("RGB")), cv2.COLOR_RGB2GRAY).astype(np.float32) / 255.0
    g = cv2.resize(g, (round(W * WORK), round(H * WORK)), interpolation=cv2.INTER_AREA)
    g = cv2.GaussianBlur(g, (0, 0), 1.2)
    return cv2.magnitude(cv2.Sobel(g, cv2.CV_32F, 1, 0, ksize=3), cv2.Sobel(g, cv2.CV_32F, 0, 1, ksize=3))


@dataclass
class Drift:
    id: str
    kind: str                  # subject type, "chrome" or "feature"
    dx: float | None = None    # device px, take minus guide, box centre
    dy: float | None = None
    size: float | None = None  # take box size over guide box size
    score: float | None = None
    note: str = ""

    @property
    def drift(self) -> float | None:
        return None if self.dx is None else max(abs(self.dx), abs(self.dy))

    @property
    def uncertain(self) -> bool:
        return self.score is not None and self.score < SCORE_MIN


def _parabola(v0: float, v1: float, v2: float) -> float:
    d = v0 - 2 * v1 + v2
    return 0.0 if abs(d) < 1e-9 else float(np.clip(0.5 * (v0 - v2) / d, -1, 1))


def measure_box(guide_e: np.ndarray, take_e: np.ndarray, box_pt, ident: str, kind: str) -> Drift:
    """Match one box's edge patch of the guide into the take's edge map."""
    k = PT * WORK  # pt -> work px
    eh, ew = guide_e.shape
    x0, y0, x1, y1 = (v * k for v in box_pt)
    m = MARGIN_PT * k
    px0, py0, px1, py1 = (int(round(v)) for v in (x0 - m, y0 - m, x1 + m, y1 + m))
    px0, py0, px1, py1 = max(px0, 0), max(py0, 0), min(px1, ew), min(py1, eh)
    if px1 - px0 < 12 or py1 - py0 < 12:
        return Drift(ident, kind, note="box off the frame")
    if (x1 - x0) * (y1 - y0) > 0.5 * ew * eh or x0 < -5 * k or x1 > ew + 5 * k or y0 < -5 * k or y1 > eh + 5 * k:
        return Drift(ident, kind, note="box leaves the frame, not measured")
    patch = guide_e[py0:py1, px0:px1]
    if float(patch.std()) < 1e-4:
        return Drift(ident, kind, note="no edges to match")
    sr = int(round(SEARCH_PT * k))
    best = (-2.0, 1.0, 0.0, 0.0)
    for s in SCALES:
        t = cv2.resize(patch, None, fx=s, fy=s, interpolation=cv2.INTER_AREA if s < 1 else cv2.INTER_LINEAR)
        th, tw = t.shape
        cx, cy = (px0 + px1) / 2, (py0 + py1) / 2
        sx0, sy0 = int(round(cx - tw / 2)) - sr, int(round(cy - th / 2)) - sr
        # pad the take's map so a window may reach past an edge
        win = np.zeros((th + 2 * sr, tw + 2 * sr), np.float32)
        ax0, ay0, ax1, ay1 = max(sx0, 0), max(sy0, 0), min(sx0 + tw + 2 * sr, ew), min(sy0 + th + 2 * sr, eh)
        if ax1 <= ax0 or ay1 <= ay0:
            continue
        win[ay0 - sy0:ay1 - sy0, ax0 - sx0:ax1 - sx0] = take_e[ay0:ay1, ax0:ax1]
        r = cv2.matchTemplate(win, t, cv2.TM_CCOEFF_NORMED)
        _, mx, _, loc = cv2.minMaxLoc(r)
        if mx > best[0]:
            ix, iy = loc
            fx = _parabola(r[iy, ix - 1], r[iy, ix], r[iy, ix + 1]) if 0 < ix < r.shape[1] - 1 else 0.0
            fy = _parabola(r[iy - 1, ix], r[iy, ix], r[iy + 1, ix]) if 0 < iy < r.shape[0] - 1 else 0.0
            # centre of the matched patch in the take, minus the patch centre in the guide
            ox = (sx0 + ix + fx + tw / 2) - cx
            oy = (sy0 + iy + fy + th / 2) - cy
            best = (mx, s, ox, oy)
    score, s, ox, oy = best
    inv = 1.0 / WORK
    return Drift(ident, kind, dx=ox * inv, dy=oy * inv, size=s, score=score)


def profile(img: Image.Image, mask_boxes) -> tuple[np.ndarray, np.ndarray]:
    """Row profile (luminance and saturation) of the columns free of any box, per device row."""
    a = np.asarray(img.convert("RGB"), np.float32) / 255.0
    keep = np.ones((H, W), bool)
    for b in mask_boxes:
        x0, y0, x1, y1 = (int(round(v * PT)) for v in b)
        keep[max(y0 - 12, 0):y1 + 12, max(x0 - 12, 0):x1 + 12] = False
    lum = a @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    sat = (a.max(-1) - a.min(-1)) / np.maximum(a.max(-1), 1e-3)
    w = keep.sum(1).astype(np.float32)
    ok = w > W * 0.15
    out = []
    for ch in (lum, sat):
        p = np.where(ok, (ch * keep).sum(1) / np.maximum(w, 1), np.nan)
        idx = np.arange(H)
        p = np.interp(idx, idx[ok], p[ok]) if ok.any() else np.zeros(H, np.float32)
        out.append(cv2.GaussianBlur(p.astype(np.float32).reshape(-1, 1), (0, 0), 6).ravel())
    return out[0], out[1]


def measure_horizon(guide: Image.Image, take: Image.Image, horizon_pt: float, mask_boxes, span_pt=170.0,
                    max_shift_pt=60.0) -> Drift:
    gl, gs = profile(guide, mask_boxes)
    tl, ts = profile(take, mask_boxes)
    h0 = int(round(horizon_pt * PT))
    half, sh = int(span_pt * PT), int(max_shift_pt * PT)
    lo, hi = max(h0 - half, sh), min(h0 + half, H - sh)

    def norm(v):
        v = v - v.mean()
        n = np.linalg.norm(v)
        return v / n if n > 1e-6 else v

    g = np.concatenate([norm(gl[lo:hi]), norm(gs[lo:hi])])
    best = (-2.0, 0)
    scores = {}
    for d in range(-sh, sh + 1):
        t = np.concatenate([norm(tl[lo + d:hi + d]), norm(ts[lo + d:hi + d])])
        scores[d] = float(g @ t) / 2.0
        if scores[d] > best[0]:
            best = (scores[d], d)
    sc, d = best
    frac = _parabola(scores.get(d - 1, sc), sc, scores.get(d + 1, sc))
    return Drift("horizon", "horizon", dx=0.0, dy=d + frac, size=1.0, score=sc)


# ---------------------------------------------------------------- one take

@dataclass
class TakeReport:
    name: str
    distance: str
    kind: str
    drifts: list[Drift] = field(default_factory=list)
    verdict: str = ""
    moved: list[str] = field(default_factory=list)
    uncertain: list[str] = field(default_factory=list)
    global_shift: tuple[float, float] = (0.0, 0.0)

    def to_json(self) -> dict:
        r = lambda v: None if v is None else round(float(v), 2)
        return {
            "take": self.name, "distance": self.distance, "kind": self.kind, "verdict": self.verdict,
            "moved": self.moved, "uncertain": self.uncertain, "global_shift_px": [r(v) for v in self.global_shift],
            "boxes": [{"id": d.id, "type": d.kind, "dx": r(d.dx), "dy": r(d.dy), "drift": r(d.drift),
                       "size": r(d.size), "score": r(d.score), "note": d.note} for d in self.drifts],
        }


def fit_take(take: Image.Image, still: Image.Image, side: dict, name: str, distance: str, kind: str):
    """Returns (the fitted frame with the real chrome, the TakeReport)."""
    frame = frame_from_take(take)
    guide = guide_frame(still)
    ge, te = edge_map(guide), edge_map(frame)
    rep = TakeReport(name, distance, kind)
    locked_boxes = []
    for s in side.get("subjects", []):
        locked_boxes.append(("subject:" + s["type"], s["id"], s["box"]))
    for c in side.get("chrome", []):
        locked_boxes.append(("chrome", c["id"], c["box"]))
    for f in side.get("features", []):
        locked_boxes.append(("feature", f["id"], f["box"]))
    for k, ident, box in locked_boxes:
        rep.drifts.append(measure_box(ge, te, box, ident, k))
    if side.get("horizon") is not None and distance != "near":
        mask = [b for _, _, b in locked_boxes if not _.startswith("feature")]
        rep.drifts.append(measure_horizon(guide, frame, side["horizon"], mask))
    judged = [d for d in rep.drifts if d.kind.startswith("subject") or d.kind == "chrome"]
    meas = [d for d in judged if d.dx is not None and not d.uncertain]
    if meas:
        rep.global_shift = (float(np.median([d.dx for d in meas])), float(np.median([d.dy for d in meas])))
    rep.uncertain = [d.id for d in rep.drifts if d.uncertain]
    rep.moved = [d.id for d in judged if d.drift is not None and d.drift > MOVED_PX and not d.uncertain]
    hz = next((d for d in rep.drifts if d.kind == "horizon"), None)
    if kind == "locked":
        if rep.moved:
            rep.verdict = "MOVED: not shown as locked"
        elif rep.uncertain:
            rep.verdict = "check by eye: " + ", ".join(rep.uncertain) + " repainted past matching"
        else:
            rep.verdict = "locked"
        if hz is not None and abs(hz.dy) > HORIZON_WARN_PX:
            rep.verdict += f" (horizon {hz.dy:+.0f} px)"
    else:
        rep.verdict = "free (drift is information)"
    return paste_chrome(frame, still, side.get("chrome", [])), rep


def format_report(rep: TakeReport) -> str:
    L = [f"{rep.name}  [{rep.distance}, {rep.kind}]  ->  {rep.verdict}",
         f"  global shift (median of subjects and chrome): dx {rep.global_shift[0]:+.1f}  dy {rep.global_shift[1]:+.1f} px"]
    L.append(f"  {'box':<14}{'type':<16}{'dx':>7}{'dy':>7}{'drift':>7}{'size':>7}{'match':>7}")
    for d in rep.drifts:
        if d.dx is None:
            L.append(f"  {d.id:<14}{d.kind:<16}{'-':>7}{'-':>7}{'-':>7}{'-':>7}{'-':>7}  {d.note}")
            continue
        flag = ""
        if d.kind == "horizon":
            flag = "  WARN" if abs(d.dy) > HORIZON_WARN_PX else ""
            L.append(f"  {d.id:<14}{d.kind:<16}{'':>7}{d.dy:>+7.1f}{abs(d.dy):>7.1f}{'':>7}{d.score:>7.2f}{flag}")
            continue
        if d.uncertain:
            flag = "  uncertain"
        elif not d.kind.startswith("feature") and d.drift > MOVED_PX:
            flag = "  MOVED" if rep.kind == "locked" else "  moved"
        L.append(f"  {d.id:<14}{d.kind:<16}{d.dx:>+7.1f}{d.dy:>+7.1f}{d.drift:>7.1f}{d.size:>7.2f}{d.score:>7.2f}{flag}")
    return "\n".join(L)


# ---------------------------------------------------------------- run, sheets

def find_takes(folder: Path) -> list[tuple[Path, str, str]]:
    out = []
    for p in sorted(folder.iterdir()):
        if p.suffix.lower() not in (".png", ".jpg", ".jpeg", ".webp"):
            continue
        m = JOB_RE.search(p.stem)
        if not m:
            continue
        dist, kind = m.groups()
        out.append((p, "map-journey" if dist == "map" else dist, kind))
    return out


def sheet(distance: str, still: Image.Image, fitted: list[tuple[str, str, Image.Image, str]], path: Path,
          cell_w: int = 400) -> None:
    """Three columns: script proof | locked | free; a row per variant. Shrunk: a map, not a place to judge seams."""
    cell_h = round(cell_w * H / W)
    cols = {"locked": [], "free": []}
    for kind, name, im, verdict in fitted:
        cols[kind].append((name, im, verdict))
    rows = max(1, len(cols["locked"]), len(cols["free"]))
    gap, head = 8, 22
    sh = Image.new("RGB", (gap + 3 * (cell_w + gap), gap + rows * (cell_h + head + gap)), (24, 24, 24))
    d = ImageDraw.Draw(sh)
    for r in range(rows):
        y = gap + r * (cell_h + head + gap)
        cells = [("script proof", still, "") if r == 0 else None]
        for kind in ("locked", "free"):
            cells.append((f"{kind} {r + 1}: {cols[kind][r][2]}", cols[kind][r][1], "") if r < len(cols[kind]) else None)
        for c, cell in enumerate(cells):
            x = gap + c * (cell_w + gap)
            if cell is None:
                continue
            d.text((x, y + 4), cell[0][:62], fill=(255, 255, 255))
            sh.paste(cell[1].convert("RGB").resize((cell_w, cell_h), Image.LANCZOS), (x, y + head))
    path.parent.mkdir(parents=True, exist_ok=True)
    sh.save(path, quality=90)


def run(takes_dir: Path, refs_dir: Path, out_dir: Path) -> list[TakeReport]:
    out_dir.mkdir(parents=True, exist_ok=True)
    reports: list[TakeReport] = []
    by_dist: dict[str, list] = {}
    stills: dict[str, tuple[Image.Image, dict]] = {}
    for path, dist, kind in find_takes(takes_dir):
        if dist not in stills:
            png = refs_dir / f"{STILLS[dist]}.png"
            js = refs_dir / f"{STILLS[dist]}.json"
            if not png.exists() or not js.exists():
                print(f"skip {path.name}: {png.name} / {js.name} missing in {refs_dir}", file=sys.stderr)
                continue
            stills[dist] = (Image.open(png).convert("RGB"), json.loads(js.read_text()))
        still, side = stills[dist]
        fitted, rep = fit_take(Image.open(path), still, side, path.stem, dist, kind)
        fitted.save(out_dir / f"{path.stem}-fit.png")
        reports.append(rep)
        by_dist.setdefault(dist, []).append((kind, path.stem, fitted, rep.verdict))
    for dist, items in by_dist.items():
        sheet(dist, stills[dist][0], items, out_dir / f"sheet-{dist}.jpg")
    (out_dir / "report.txt").write_text("\n\n".join(format_report(r) for r in reports) + "\n")
    (out_dir / "report.json").write_text(json.dumps([r.to_json() for r in reports], indent=1))
    return reports


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("takes", type=Path, help="folder of Codex takes")
    ap.add_argument("--refs", type=Path, required=True, help="folder of the R1 stills and sidecars")
    ap.add_argument("--out", type=Path, required=True)
    a = ap.parse_args(argv)
    reps = run(a.takes, a.refs, a.out)
    for r in reps:
        print(format_report(r), end="\n\n")
    if not reps:
        print("no takes found (file names need x-concept-<map|map-homefirst|mid|near>-<locked|free>)", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
