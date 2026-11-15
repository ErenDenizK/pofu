#!/usr/bin/env python3
"""The acceptance check for mattes and looks: M1 to M10 of docs/design/world-presentation-v2.md section 4.2.

Run it on every matte (an island, a prop, a station look) at texture resolution. Lengths are texture px.

  M1  border       alpha along the four borders is 0 (no rectangle), unless `full_bleed`
  M2  width        0.05 to 0.95 alpha band along the edge normal, 95th percentile at most 3 (islands) / 2 (looks, props),
                   5th percentile at least 0.7 (a one-bit stepped edge fails)
  M3  contamination  edge pixels: how far the layer's colour is pulled from the nearest opaque colour toward the
                   source's sky at that spot (0 to 1), 95th percentile at most 0.15
  M4  specks, holes  alpha above 0.02 outside the main shape, or below 0.99 enclosed in it, in patches under 64 px: none
  M5  halo in use  composited over the destinations at device scale; a 6 px ring outside the shape and one
                   device px clear of it, against the destination alone: mean difference at most 2/255
  M6  rim          a 4 px ring inside the shape against the next 8 px inward, in luminance: within 8 %
  M7  look locality  base plus look, outside the look's matte grown by 2: equal to the base, at most 1/255
  M8  look wholeness inside the matte shrunk by 2, against the painting it was cut from: at most 2/255
  M9  ghost        correlation of the erased base's fine detail with the look's fine detail, inside the look: at most 0.25
  M10 registration named anchor points across stages and lights: within 1 px
  M11 haze         (added in round 3) opaque pixels that are the source's own sky or haze: the colour of the sky
                   just outside, within 150 px of the outside, in a connected patch of HAZE_PATCH (32) px or more that
                   reaches to within HAZE_TOUCH px of the outside. Any such patch fails. Catches the blue-grey band
                   under Home's earth body, which is opaque plate pixels, not feather. Smaller patches and patches
                   buried inside the shape are not tested (a painted highlight or a window is the same colour as the sky
                   and is not haze); a haze patch that small is still a defect and is for the eye. The test sees only
                   sky-coloured haze: pink cloud mist needs the eye too.

M7 to M10 compare two pictures and are functions here (`m7_locality`, ...); `check_matte` runs M1 to M6 on one layer
and reports M7 to M10 as not applicable. A region meant to be soft (steam, a fall's foot, a beam) is a polygon in
`soft`: M2 to M6 skip it, and the worst-edges sheet shows it for the eye. Writes a JSON report and one sheet of the
eight worst edge spans at 4x.

    python3 tools/art/matte_check.py --rgba layer.png [--source plate.png] [--out DIR] [--kind island|look|prop]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np

LIMITS = {"M1": 0.004, "M2": {"island": 3.0, "look": 2.0, "prop": 2.0}, "M2_MIN": 0.7, "M3": 0.15, "M5": 2 / 255, "M6": 0.08,
          "M7": 1 / 255, "M8": 2 / 255, "M9": 0.25, "M10": 1.0}
SPECK = 64
DEVICE_SCALE = 0.68             # Home's plate at mid: texture px to device px (1.15 screens of 1206 px over 2048 px)
TILE = 96


# ---------------------------------------------------------------- helpers

def _soft_mask(shape: tuple[int, int], soft: list[np.ndarray] | None, grow: int = 4) -> np.ndarray:
    m = np.zeros(shape, np.uint8)
    for poly in soft or []:
        cv2.fillPoly(m, [np.round(np.asarray(poly)).astype(np.int32)], 1)
    if m.any() and grow:
        m = cv2.dilate(m, np.ones((2 * grow + 1, 2 * grow + 1), np.uint8))
    return m.astype(bool)


def _inside_dist(mask: np.ndarray) -> np.ndarray:
    return cv2.distanceTransform(mask.astype(np.uint8), cv2.DIST_L2, 3)


def _luma(rgb: np.ndarray) -> np.ndarray:
    return rgb @ np.float32([0.2126, 0.7152, 0.0722])


def _nconv(img: np.ndarray, mask: np.ndarray, sigma: float) -> tuple[np.ndarray, np.ndarray]:
    m = mask.astype(np.float32)
    num = cv2.GaussianBlur(img * m[..., None], (0, 0), sigma)
    den = cv2.GaussianBlur(m, (0, 0), sigma)
    return num / np.maximum(den, 1e-4)[..., None], den


def edge_pixels(a: np.ndarray, soft: np.ndarray) -> np.ndarray:
    return (a > 0.05) & (a < 0.95) & ~soft


# ---------------------------------------------------------------- M1 to M6

def m1_border(a: np.ndarray, full_bleed: bool = False) -> dict:
    v = float(max(a[0].max(), a[-1].max(), a[:, 0].max(), a[:, -1].max()))
    return {"value": v, "limit": LIMITS["M1"], "pass": full_bleed or v <= LIMITS["M1"]}


def width_map(a: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Width of the 0.05 to 0.95 band along the normal at the pixels near a = 0.5 (0.9 / |grad a|), and those pixels."""
    gx = cv2.Sobel(a, cv2.CV_32F, 1, 0, ksize=3) / 8
    gy = cv2.Sobel(a, cv2.CV_32F, 0, 1, ksize=3) / 8
    g = np.hypot(gx, gy)
    at = (a > 0.15) & (a < 0.85)
    return np.clip(0.9 / np.maximum(g, 1e-3), 0, 30), at


def m2_width(a: np.ndarray, soft: np.ndarray, kind: str) -> tuple[dict, np.ndarray, np.ndarray]:
    w, at = width_map(a)
    at &= ~soft
    p95 = float(np.percentile(w[at], 95)) if at.any() else 0.0
    p05 = float(np.percentile(w[at], 5)) if at.any() else LIMITS["M2_MIN"]
    lim = LIMITS["M2"][kind]
    return {"value": p95, "p05": p05, "median": float(np.median(w[at])) if at.any() else 0.0, "limit": lim, "limit_min": LIMITS["M2_MIN"],
            "pass": p95 <= lim and p05 >= LIMITS["M2_MIN"]}, w, at


def contamination_map(rgb: np.ndarray, a: np.ndarray, source: np.ndarray, edge: np.ndarray) -> np.ndarray:
    """Per pixel: how far the layer's colour is pulled from the nearest opaque colour toward the source's sky near it."""
    opaque = a > 0.99
    _, lab = cv2.distanceTransformWithLabels((~opaque).astype(np.uint8), cv2.DIST_L2, 3, labelType=cv2.DIST_LABEL_PIXEL)
    ys, xs = np.nonzero(opaque.ravel().reshape(a.shape))
    order = np.zeros(lab.max() + 2, np.int64)
    zero_idx = np.flatnonzero(~(~opaque).ravel())                  # label k is the k-th zero pixel of the input, row-major
    order[1:1 + len(zero_idx)] = zero_idx
    near = rgb.reshape(-1, 3)[order[lab.ravel()]].reshape(rgb.shape)
    sky, w = _nconv(source, a < 0.01, 12.0)
    d = sky - near
    dd = (d * d).sum(2)
    t = ((rgb - near) * d).sum(2) / np.maximum(dd, 1e-6)
    t = np.clip(t, 0, 1)
    t[(dd < 0.06 ** 2) | (w < 0.02)] = 0                           # no sky to be pulled toward (or none near)
    t[~edge] = 0
    return t


def m3_contamination(rgb, a, source, soft) -> tuple[dict, np.ndarray]:
    edge = edge_pixels(a, soft)
    t = contamination_map(rgb, a, source, edge)
    p95 = float(np.percentile(t[edge], 95)) if edge.any() else 0.0
    return {"value": p95, "limit": LIMITS["M3"], "pass": p95 <= LIMITS["M3"]}, t


HAZE_PATCH = 32                 # px: a smaller kept patch is a painted highlight or nothing the eye can find
HAZE_GAP = 12                   # px: the sky colour is taken from outside this far from the shape
HAZE_TOUCH = 8                  # px: a kept patch farther than this from the outside (a painted gem, a window) is not haze; the outside is also each hole


def m11_haze(rgba: np.ndarray, source: np.ndarray, soft: np.ndarray) -> tuple[dict, np.ndarray]:
    """Opaque (alpha above 0.5) pixels within 40 px of the outside that are the sky's colour there (same chromaticity,
    sky blue-ish) or within 0.05 of it: haze the matte kept. Fails on any connected patch of HAZE_PATCH px or more."""
    a = rgba[..., 3]
    # the sky is read from at least HAZE_GAP px out: a lawn or a hill that fades into the sky always matches the sky just
    # beside it, and is not haze
    far = (a < 0.01) & (_inside_dist(a < 0.01) >= HAZE_GAP)
    sky, w = _nconv(source, far, 10.0)
    chroma = lambda c: c / np.maximum(c.sum(2, keepdims=True), 1e-3)
    blue = (sky[..., 2] - sky[..., 0]) > 0.08
    same = ((np.linalg.norm(chroma(source) - chroma(sky), axis=2) < 0.03) & blue & (source.mean(2) > 0.35)) | \
           (np.linalg.norm(source - sky, axis=2) < 0.05)
    near = _inside_dist(~(a < 0.01)) <= 150
    close = _inside_dist(~(a < 0.01)) <= HAZE_TOUCH
    bad = same & (a > 0.5) & near & (w > 0.02) & ~soft
    bad = cv2.morphologyEx(bad.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, cen = cv2.connectedComponentsWithStats(bad, connectivity=8)
    keep = [i for i in range(1, n) if st[i, 4] >= HAZE_PATCH and close[lab == i].any()]
    big = [(int(st[i, 4]), (float(cen[i][0]), float(cen[i][1]))) for i in keep]
    mask = np.isin(lab, keep)
    return {"value": len(big), "pixels": int(sum(b[0] for b in big)), "limit": 0, "pass": not big, "found": big[:12]}, mask


def m4_specks(a: np.ndarray, soft: np.ndarray) -> tuple[dict, list]:
    found = []
    n, lab, st, cen = cv2.connectedComponentsWithStats((a > 0.02).astype(np.uint8), connectivity=8)
    main = 1 + int(np.argmax(st[1:, 4])) if n > 1 else 0
    for i in range(1, n):
        if i != main and st[i, 4] < SPECK and not soft[lab == i].any():
            found.append(("speck", int(st[i, 4]), (float(cen[i][0]), float(cen[i][1]))))
    n, lab, st, cen = cv2.connectedComponentsWithStats((a < 0.99).astype(np.uint8), connectivity=4)
    h, w = a.shape
    for i in range(1, n):
        x, y, bw, bh, area = st[i]
        if area < SPECK and x > 0 and y > 0 and x + bw < w and y + bh < h and not soft[lab == i].any():
            found.append(("hole", int(area), (float(cen[i][0]), float(cen[i][1]))))
    return {"value": len(found), "limit": 0, "pass": not found, "found": found[:20]}, found


def composite(rgba: np.ndarray, dest: np.ndarray) -> np.ndarray:
    a = rgba[..., 3:4]
    return rgba[..., :3] * a + dest * (1 - a)


def m5_halo(rgba: np.ndarray, dests: dict[str, np.ndarray], soft: np.ndarray, scale: float = DEVICE_SCALE) -> tuple[dict, dict]:
    """Over each destination at device scale: mean |composite - destination| in the 6 px ring just outside the shape."""
    h, w = rgba.shape[:2]
    sz = (max(int(w * scale), 1), max(int(h * scale), 1))
    pm = rgba.copy()
    pm[..., :3] *= pm[..., 3:4]
    pm = cv2.resize(pm, sz, interpolation=cv2.INTER_AREA)
    a = pm[..., 3:4]
    rgb = np.where(a > 1e-4, pm[..., :3] / np.maximum(a, 1e-4), 0)
    small = np.dstack([rgb, a[..., 0]])
    sm = cv2.resize(soft.astype(np.uint8), sz, interpolation=cv2.INTER_NEAREST).astype(bool)
    shape = small[..., 3] > 0.5
    d_out = _inside_dist(~shape)
    ring = (d_out > 1) & (d_out <= 7) & ~sm              # from the second device px out: the first holds the edge's own anti-aliasing, which any edge has
    out, maps = {}, {}
    for name, dest in dests.items():
        dst = cv2.resize(dest.astype(np.float32), sz, interpolation=cv2.INTER_AREA)
        diff = np.abs(composite(small, dst) - dst).mean(2)
        out[name] = float(diff[ring].mean()) if ring.any() else 0.0
        maps[name] = (diff, ring)
    worst = max(out.values()) if out else 0.0
    return {"value": worst, "per_destination": out, "limit": LIMITS["M5"], "pass": worst <= LIMITS["M5"]}, maps


def rim_map(rgba: np.ndarray, soft: np.ndarray):
    a = rgba[..., 3]
    shape = a > 0.5
    d = _inside_dist(shape)
    ring = (d > 0) & (d <= 4) & ~soft
    inner = (d > 4) & (d <= 12) & ~soft
    return ring, inner, _luma(rgba[..., :3])


def m6_rim(rgba: np.ndarray, soft: np.ndarray) -> dict:
    ring, inner, lum = rim_map(rgba, soft)
    if not ring.any() or not inner.any():
        return {"value": 0.0, "limit": LIMITS["M6"], "pass": True}
    r, i = float(lum[ring].mean()), float(lum[inner].mean())
    v = abs(r - i) / max(i, 1e-3)
    return {"value": v, "ring": r, "inner": i, "limit": LIMITS["M6"], "pass": v <= LIMITS["M6"]}


# ---------------------------------------------------------------- M7 to M10 (two pictures)

def m7_locality(base: np.ndarray, with_look: np.ndarray, look_alpha: np.ndarray) -> dict:
    """base and base-plus-look (RGB 0..1) outside the look's matte grown by 2: equal to 1/255."""
    grown = cv2.dilate((look_alpha > 0.01).astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)
    diff = np.abs(with_look - base).max(2)
    v = float(diff[~grown].max()) if (~grown).any() else 0.0
    return {"value": v, "limit": LIMITS["M7"], "pass": v <= LIMITS["M7"]}


def m8_wholeness(look_rgb: np.ndarray, look_alpha: np.ndarray, painting: np.ndarray) -> dict:
    """The look's colour inside its matte shrunk by 2, against the painting it was cut from."""
    core = cv2.erode((look_alpha > 0.99).astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)
    diff = np.abs(look_rgb - painting).max(2)
    v = float(np.percentile(diff[core], 99.9)) if core.any() else 0.0
    return {"value": v, "limit": LIMITS["M8"], "pass": v <= LIMITS["M8"]}


def m9_ghost(base: np.ndarray, look_rgb: np.ndarray, look_alpha: np.ndarray) -> dict:
    """Correlation of the base's fine detail with the look's fine detail inside the look's matte."""
    core = cv2.erode((look_alpha > 0.99).astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)

    def fine(x):
        g = _luma(x)
        return g - cv2.GaussianBlur(g, (0, 0), 3)
    fb, fl = fine(base)[core], fine(look_rgb)[core]
    if fb.size < 16 or fb.std() < 1e-6 or fl.std() < 1e-6:
        return {"value": 0.0, "limit": LIMITS["M9"], "pass": True}
    v = float(np.corrcoef(fb, fl)[0, 1])
    return {"value": v, "limit": LIMITS["M9"], "pass": v <= LIMITS["M9"]}


def m10_registration(anchors: dict[str, dict[str, tuple[float, float]]]) -> dict:
    """`anchors[name][state] = (x, y)`: the largest spread of one anchor across states, px."""
    worst, which = 0.0, ""
    for name, states in anchors.items():
        pts = np.array(list(states.values()), np.float64)
        if len(pts) < 2:
            continue
        spread = float(np.hypot(*(pts.max(0) - pts.min(0))))
        if spread > worst:
            worst, which = spread, name
    return {"value": worst, "anchor": which, "limit": LIMITS["M10"], "pass": worst <= LIMITS["M10"]}


def alpha_anchors(a: np.ndarray) -> dict[str, tuple[float, float]]:
    """Anchors of a silhouette that do not hang on one stray pixel: the centroid of the whole shape, of its left third, its
    right third and its lowest third (by columns or rows of the shape's extent). The top is not an anchor: the tree is
    painted differently in each light."""
    m = a > 0.5
    ys, xs = np.nonzero(m)
    x0, x1, y1 = xs.min(), xs.max(), ys.max()
    out = {}
    for name, sel in (("all", np.ones_like(xs, bool)), ("left", xs < x0 + (x1 - x0) / 3), ("right", xs > x1 - (x1 - x0) / 3),
                      ("bottom", ys > y1 - (y1 - ys.min()) / 3)):
        out[name] = (float(xs[sel].mean()), float(ys[sel].mean()))
    return out


# ---------------------------------------------------------------- the whole report and the sheet

def _tile_scores(w, w_at, t, halo_maps, rgba, soft, kind):
    """Score of each TILE x TILE span along the edge: the worst of its failures over their limits (1 = at the limit)."""
    h, wd = w.shape
    ring, inner, lum = rim_map(rgba, soft)
    lim2 = LIMITS["M2"][kind]
    spans = []
    for y in range(0, h - TILE // 2, TILE // 2):
        for x in range(0, wd - TILE // 2, TILE // 2):
            sl = (slice(y, y + TILE), slice(x, x + TILE))
            at = w_at[sl]
            if at.sum() < 12:
                continue
            s_w = float(np.percentile(w[sl][at], 90)) / lim2
            tt = t[sl]
            ed = edge_pixels(rgba[sl][..., 3], soft[sl])
            s_c = float(np.percentile(tt[ed], 90)) / LIMITS["M3"] if ed.any() else 0.0
            s_h = 0.0
            for diff, rg in halo_maps.values():
                pass
            r_, i_ = ring[sl], inner[sl]
            s_r = abs(float(lum[sl][r_].mean()) - float(lum[sl][i_].mean())) / max(float(lum[sl][i_].mean()), 1e-3) / LIMITS["M6"] if r_.any() and i_.any() else 0.0
            spans.append((max(s_w, s_c, s_r, s_h), x, y, {"width": s_w, "contamination": s_c, "rim": s_r}))
    spans.sort(key=lambda s: -s[0])
    chosen = []
    for s in spans:
        if all(abs(s[1] - c[1]) >= TILE or abs(s[2] - c[2]) >= TILE for c in chosen):
            chosen.append(s)
        if len(chosen) == 8:
            break
    return chosen


def worst_sheet(rgba, spans, dests, path: Path, title: str, zoom: int = 4) -> None:
    from PIL import Image, ImageDraw
    names = list(dests)[:2]
    cells = []
    for score, x, y, parts in spans:
        row = []
        for n in names:
            d = dests[n]
            crop = composite(rgba[y:y + TILE, x:x + TILE], d[y:y + TILE, x:x + TILE])
            row.append(Image.fromarray((np.clip(crop, 0, 1) * 255 + 0.5).astype(np.uint8)).resize((TILE * zoom, TILE * zoom), Image.NEAREST))
        cells.append((score, x, y, parts, row))
    cw, ch = TILE * zoom * len(names), TILE * zoom
    cols = 2
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cw + 8) + 8, rows * (ch + 28) + 36), (24, 24, 24))
    dr = ImageDraw.Draw(sheet)
    dr.text((8, 8), title + "   worst 8 edge spans at 4x   (score 1.0 = at a limit)", fill=(255, 255, 255))
    for i, (score, x, y, parts, row) in enumerate(cells):
        ox, oy = 8 + (i % cols) * (cw + 8), 36 + (i // cols) * (ch + 28)
        dr.text((ox, oy), "%d,%d  score %.2f  w %.2f c %.2f r %.2f" % (x, y, score, parts["width"], parts["contamination"], parts["rim"]),
                fill=(255, 255, 255))
        for j, im in enumerate(row):
            sheet.paste(im, (ox + j * ch, oy + 14))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def default_dests(shape: tuple[int, int]) -> dict[str, np.ndarray]:
    """Plain vertical gradients for the three lights when no real backdrop is given."""
    h, w = shape
    t = np.linspace(0, 1, h, dtype=np.float32)[:, None, None]
    ramps = {"day": ((0.45, 0.68, 0.97), (0.93, 0.88, 0.97)), "golden": ((0.96, 0.66, 0.45), (0.99, 0.85, 0.72)),
             "night": ((0.08, 0.10, 0.26), (0.30, 0.28, 0.50))}
    return {k: np.broadcast_to(np.float32(a) * (1 - t) + np.float32(b) * t, (h, w, 3)).copy() for k, (a, b) in ramps.items()}


def check_matte(rgba: np.ndarray, *, source: np.ndarray | None = None, soft: list[np.ndarray] | None = None,
                kind: str = "island", full_bleed: bool = False, dests: dict[str, np.ndarray] | None = None,
                name: str = "matte", out: Path | None = None) -> dict:
    """M1 to M6 on one straight-RGBA layer (0..1) and its source picture. Writes `<name>.json` and
    `<name>-worst.png` into `out` when given."""
    a = rgba[..., 3].astype(np.float32)
    sm = _soft_mask(a.shape, soft)
    dests = dests or default_dests(a.shape)
    report = {"name": name, "kind": kind, "size": [a.shape[1], a.shape[0]], "soft_edges": len(soft or [])}
    report["M1"] = m1_border(a, full_bleed)
    r2, w, w_at = m2_width(a, sm, kind)
    report["M2"] = r2
    if source is not None:
        r3, t = m3_contamination(rgba[..., :3], a, source, sm)
        report["M3"] = r3
    else:
        t = np.zeros_like(a)
        report["M3"] = {"value": None, "pass": None, "note": "no source given"}
    report["M4"], _ = m4_specks(a, sm)
    if source is not None:
        report["M11"], _ = m11_haze(rgba, source, sm)
    report["M5"], halo = m5_halo(rgba, dests, sm)
    report["M6"] = m6_rim(rgba, sm)
    for k in ("M7", "M8", "M9", "M10"):
        report[k] = {"value": None, "pass": None, "note": "compares two pictures; see the function"}
    report["pass"] = all(report[k]["pass"] is not False for k in ("M1", "M2", "M3", "M4", "M5", "M6", "M11") if k in report)
    spans = _tile_scores(w, w_at, t, halo, rgba, sm, kind)
    report["worst_spans"] = [{"x": x, "y": y, "score": round(s, 3), **{k: round(v, 3) for k, v in parts.items()}} for s, x, y, parts in spans]
    if out is not None:
        out.mkdir(parents=True, exist_ok=True)
        (out / f"{name}.json").write_text(json.dumps(report, indent=1))
        worst_sheet(rgba, spans, dests, out / f"{name}-worst.png", name)
    return report


def one_line(r: dict) -> str:
    def f(k):
        v = r[k]
        if v.get("value") is None:
            return f"{k} n/a"
        if k in ("M4", "M11"):
            return f"{k} {v['value']}{'' if v['pass'] else ' FAIL'}"
        s = {"M1": "%.4f", "M5": "%.4f"}.get(k, "%.2f") % v["value"]
        if k == "M2":
            s += " (p05 %.2f)" % v["p05"]
        return f"{k} {s}{'' if v['pass'] else ' FAIL'}"
    return f"{r['name']}: " + "  ".join(f(k) for k in ("M1", "M2", "M3", "M4", "M5", "M6", "M11") if k in r)


def main(argv=None) -> int:
    from PIL import Image
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--rgba", type=Path, required=True)
    ap.add_argument("--source", type=Path)
    ap.add_argument("--out", type=Path, default=Path("matte-check"))
    ap.add_argument("--kind", default="island", choices=["island", "look", "prop"])
    ap.add_argument("--full-bleed", action="store_true")
    args = ap.parse_args(argv)
    rgba = np.asarray(Image.open(args.rgba).convert("RGBA"), np.float32) / 255
    src = np.asarray(Image.open(args.source).convert("RGB"), np.float32) / 255 if args.source else None
    r = check_matte(rgba, source=src, kind=args.kind, full_bleed=args.full_bleed, name=args.rgba.stem, out=args.out)
    print(one_line(r))
    return 0 if r["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
