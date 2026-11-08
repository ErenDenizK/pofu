#!/usr/bin/env python3
"""Why the game reads pale: per-region numbers for references, CI frames and raw sprites.

Writes the tables behind `docs/research/pale-assets.md`. Every image is measured at the scale
its objects have on the phone (the CI frame is 460 px wide for 402 pt; references are resized so
their island is as wide as the game's island in the frame it is compared with), per region:

  L, C      mean CIELAB lightness and chroma; Cp95 the 95th percentile chroma
  hue       hue angle of the mean a*, b*
  loc       local contrast: RMS of L* minus its Gaussian blur at 2 px (crisp versus soft)
  fine      finest detail: RMS of L* minus its blur at 0.7 px (texture that survives at phone scale)
  acc       share of pixels with C* > 50 (colour accents), percent
  dark      share of pixels with L* < 45 (true darks: eyes, doors, gaps, contact), percent

and the hypothesis tests H2 (delivery scale and the detail budget), H3 (raw plate pixels against
the same pixels on screen, registered) and H6 (contact darkening under characters).

    python3 -I tools/plate/pale.py SHOTS_DIR [--json out.json]

SHOTS_DIR holds `concept-day-home.jpg`, `caglayan-stage-{0,4}.jpg` and `caglayan-night-4.jpg`
from `origin/screenshots/feat-look-pipeline-v2` (see tools/plate/README.md).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
from process_assets import srgb_to_lab  # noqa: E402

TAKES = REPO / "design" / "art" / "takes"
ASSETS = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "World.xcassets"
POFU = REPO / "Packages" / "PofuKit" / "Sources" / "PofuCompanion" / "Resources" / "pofu-hamster.png"
REF_DAY = TAKES / "batch-25-seasons/x-season-summer/plate__x-season-summer--t2.webp"
REF_STUCK = TAKES / "batch-34-islands-in-game/x-revontuli-stuck/plate__x-revontuli-stuck--t1.webp"
REF_HEALED = TAKES / "batch-34-islands-in-game/x-revontuli-healed/plate__x-revontuli-healed--t2.webp"

# Region boxes [x0, y0, x1, y1] as fractions, set by eye on a 10 % grid.
BOXES = {
    "ref-day": {
        "sky": [[0.0, 0.0, 0.1, 0.1], [0.7, 0.0, 0.85, 0.08], [0.92, 0.12, 1.0, 0.3]],
        "props": [[0.36, 0.14, 0.70, 0.33], [0.75, 0.10, 0.86, 0.30], [0.16, 0.21, 0.30, 0.33]],
        "lawn": [[0.06, 0.40, 0.30, 0.50], [0.70, 0.43, 0.92, 0.50], [0.30, 0.52, 0.55, 0.56]],
        "earth": [[0.25, 0.62, 0.85, 0.75]],
        "sea": [[0.0, 0.92, 1.0, 1.0]],
    },
    "game-home": {
        "sky": [[0.3, 0.03, 0.7, 0.09]],
        "props": [[0.0, 0.33, 0.45, 0.46], [0.85, 0.38, 1.0, 0.48]],
        "lawn": [[0.0, 0.46, 0.12, 0.52], [0.27, 0.535, 0.95, 0.565]],
        "earth": [[0.1, 0.6, 0.9, 0.72]],
        "sea": [[0.0, 0.86, 0.85, 0.98]],
        "characters": [[0.42, 0.44, 0.65, 0.54], [0.78, 0.50, 0.88, 0.545]],
    },
    "ref-stuck": {
        "sky": [[0.0, 0.0, 0.12, 0.3], [0.55, 0.0, 0.7, 0.15]],
        "props": [[0.13, 0.05, 0.40, 0.45], [0.47, 0.05, 0.72, 0.47], [0.70, 0.05, 0.92, 0.45]],
        "lawn": [[0.40, 0.62, 0.90, 0.70], [0.62, 0.50, 0.95, 0.60]],
        "earth": [[0.10, 0.72, 0.90, 0.85]],
        "sea": [[0.0, 0.92, 1.0, 1.0]],
        "characters": [[0.40, 0.50, 0.62, 0.67]],
    },
    "ref-healed": {
        "sky": [[0.0, 0.0, 0.1, 0.15], [0.0, 0.25, 0.08, 0.4]],
        "props": [[0.12, 0.16, 0.38, 0.45], [0.43, 0.07, 0.57, 0.42], [0.72, 0.12, 0.92, 0.45]],
        "lawn": [[0.62, 0.47, 0.95, 0.60], [0.20, 0.62, 0.60, 0.68]],
        "earth": [[0.10, 0.68, 0.90, 0.82]],
        "sea": [[0.0, 0.93, 1.0, 1.0]],
        "characters": [[0.40, 0.47, 0.62, 0.65]],
    },
    # Çağlayan's plate (world-caglayan-island-N, 728 x 464), in plate fractions.
    "caglayan-plate": {
        "props": [[0.66, 0.15, 0.92, 0.45], [0.60, 0.52, 0.69, 0.68], [0.28, 0.03, 0.60, 0.42]],
        "lawn": [[0.05, 0.52, 0.35, 0.70], [0.70, 0.48, 0.97, 0.68]],
        "earth": [[0.15, 0.74, 0.85, 0.88]],
    },
}
# Where the plate lands in the 460 x 1000 CI frame (found by tools/plate/pale.py --register).
CAGLAYAN_IN_FRAME = {"scale": 0.606, "x": 9, "y": 316}
# The CI frame is 460 px for 402 pt; the phone draws 3 px per pt.
PHONE_PX_PER_FRAME_PX = 402 * 3 / 460


def load(path: Path, width: int | None = None, rgba: bool = False) -> np.ndarray:
    im = Image.open(path).convert("RGBA" if rgba else "RGB")
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.Resampling.LANCZOS)
    return np.asarray(im, np.float64) / 255


def mask(shape, boxes) -> np.ndarray:
    h, w = shape[:2]
    m = np.zeros((h, w), bool)
    for x0, y0, x1, y1 in boxes:
        m[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)] = True
    return m


def metrics(rgb: np.ndarray, m: np.ndarray | None = None) -> dict:
    lab = srgb_to_lab(np.clip(rgb[..., :3], 0, 1))
    L = lab[..., 0]
    C = np.hypot(lab[..., 1], lab[..., 2])
    loc = (L - ndimage.gaussian_filter(L, 2.0)) ** 2
    fine = (L - ndimage.gaussian_filter(L, 0.7)) ** 2
    if m is None:
        m = np.ones(L.shape, bool)
    a, b = lab[..., 1][m].mean(), lab[..., 2][m].mean()
    return {
        "L": round(float(L[m].mean()), 1), "C": round(float(C[m].mean()), 1),
        "Cp95": round(float(np.percentile(C[m], 95)), 1),
        "hue": round(float(np.degrees(np.arctan2(b, a)) % 360)),
        "loc": round(float(np.sqrt(loc[m].mean())), 2), "fine": round(float(np.sqrt(fine[m].mean())), 2),
        "acc": round(float((C[m] > 50).mean() * 100), 1), "dark": round(float((L[m] < 45).mean() * 100), 1),
        "Lp2": round(float(np.percentile(L[m], 2)), 1),
    }


def regions(rgb: np.ndarray, kind: str) -> dict:
    return {name: metrics(rgb, mask(rgb.shape, boxes)) for name, boxes in BOXES[kind].items()}


def register(sprite: np.ndarray, frame: np.ndarray, scales=np.arange(0.45, 0.63, 0.003)) -> tuple[float, int, int]:
    """Scale and offset of a plate inside a frame (OpenCV template match on the Laplacian)."""
    import cv2
    g = lambda x: cv2.Laplacian(cv2.GaussianBlur(np.float32(x[..., :3].mean(-1)), (0, 0), 1.0), cv2.CV_32F)
    G, best = g(frame), (-1.0, 1.0, 0, 0)
    for s in scales:
        w, h = round(sprite.shape[1] * s), round(sprite.shape[0] * s)
        t = cv2.resize(np.float32(sprite), (w, h), interpolation=cv2.INTER_AREA)
        m = (cv2.erode(t[..., 3], np.ones((5, 5))) > 0.9).astype(np.float32)
        r = cv2.matchTemplate(G, g(t), cv2.TM_CCORR_NORMED, mask=m)
        r[~np.isfinite(r)] = -1
        _, v, _, loc = cv2.minMaxLoc(r)
        if v > best[0]:
            best = (v, float(s), int(loc[0]), int(loc[1]))
    return best[1:]


def plate_on_screen(stage: int, frame_path: Path) -> dict:
    """H3: the plate's own pixels against the same pixels in the CI frame, per region."""
    sp = Image.open(ASSETS / f"world-caglayan-island-{stage}.imageset/world-caglayan-island-{stage}.png").convert("RGBA")
    p = CAGLAYAN_IN_FRAME
    w, h = round(sp.width * p["scale"]), round(sp.height * p["scale"])
    raw = np.asarray(sp.resize((w, h), Image.Resampling.LANCZOS), np.float64) / 255
    frame = load(frame_path)
    scr = frame[p["y"]:p["y"] + h, p["x"]:p["x"] + w]
    solid = ndimage.binary_erosion(raw[..., 3] > 0.98, iterations=3)
    out = {}
    for name, boxes in BOXES["caglayan-plate"].items():
        m = mask(raw.shape, boxes) & solid
        out[name] = {"raw": metrics(raw[..., :3], m), "screen": metrics(scr, m)}
    m = solid
    out["island"] = {"raw": metrics(raw[..., :3], m), "screen": metrics(scr, m)}
    # Per-channel affine fit screen = gain * raw + lift over the solid island.
    fit = []
    for c in range(3):
        A = np.stack([raw[..., c][m], np.ones(m.sum())], 1)
        g, lift = np.linalg.lstsq(A, scr[..., c][m], rcond=None)[0]
        fit.append((round(float(g), 2), round(float(lift), 3)))
    out["fit"] = fit
    return out


def detail_budget() -> dict:
    """H2: a 1536 px take as the phone sees it, delivered whole or halved, with and without the lock's detail budget."""
    import style_lock as sl
    phone_island = round(728 * CAGLAYAN_IN_FRAME["scale"] * PHONE_PX_PER_FRAME_PX)  # island width in phone pixels
    take = load(REF_HEALED)
    island_frac = 0.95  # the island fills about 95 % of the take's width
    target_w = round(phone_island / island_frac)
    rgba = np.concatenate([take, np.ones(take.shape[:2] + (1,))], -1)
    lock = sl.preset_for("plate", sl.load_presets())[1]
    locked = sl.apply_lock(rgba.copy(), lock)[..., :3]

    def deliver(img: np.ndarray, factor: float) -> np.ndarray:
        im = Image.fromarray(np.uint8(np.clip(img, 0, 1) * 255 + 0.5))
        if factor != 1:
            im = im.resize((round(im.width * factor), round(im.height * factor)), Image.Resampling.LANCZOS)
        return np.asarray(im.resize((target_w, round(target_w * im.height / im.width)), Image.Resampling.BILINEAR), np.float64) / 255

    out = {"phone_island_px": phone_island}
    for name, img, f in [("full", take, 1), ("half", take, 0.5), ("half+lock", locked, 0.5)]:
        d = deliver(img, f)
        out[name] = metrics(d, mask(d.shape, BOXES["ref-healed"]["props"] + BOXES["ref-healed"]["characters"]))
    return out


def contact(rgb: np.ndarray, box, below: float = 0.06) -> float:
    """H6: ground L* in a thin band under a character's box minus ground L* to its sides (negative = a contact shadow)."""
    h, w = rgb.shape[:2]
    L = srgb_to_lab(np.clip(rgb, 0, 1))[..., 0]
    x0, y0, x1, y1 = box
    bw = x1 - x0
    under = L[int((y1 - 0.01) * h):int((y1 + below * 0.5) * h), int((x0 + 0.15 * bw) * w):int((x1 - 0.15 * bw) * w)]
    side = np.concatenate([
        L[int((y1 - 0.01) * h):int((y1 + below * 0.5) * h), int((x0 - 0.45 * bw) * w):int((x0 - 0.1 * bw) * w)].ravel(),
        L[int((y1 - 0.01) * h):int((y1 + below * 0.5) * h), int((x1 + 0.1 * bw) * w):int((x1 + 0.45 * bw) * w)].ravel()])
    return round(float(under.mean() - side.mean()), 1)


def sprite_metrics(path: Path, width: int) -> dict:
    a = load(path, width, rgba=True)
    return metrics(a[..., :3], a[..., 3] > 0.9)


def run(shots: Path) -> dict:
    res = {}
    day = load(REF_DAY, 1024)
    home = load(shots / "concept-day-home.jpg")
    # Revontuli takes at the width where their island matches Çağlayan's on screen (441 px).
    rev_w = round(728 * CAGLAYAN_IN_FRAME["scale"] / 0.95)
    stuck, healed = load(REF_STUCK, rev_w), load(REF_HEALED, rev_w)
    res["regions"] = {
        "ref-day (I1 summer t2)": regions(day, "ref-day"),
        "game-home day (CI)": regions(home, "game-home"),
        "ref-night (Revontuli stuck t1)": regions(stuck, "ref-stuck"),
        "ref-night (Revontuli healed t2)": regions(healed, "ref-healed"),
    }
    res["h3"] = {
        "caglayan-4 day": plate_on_screen(4, shots / "caglayan-stage-4.jpg"),
        "caglayan-0 day": plate_on_screen(0, shots / "caglayan-stage-0.jpg"),
        "caglayan-4 night": plate_on_screen(4, shots / "caglayan-night-4.jpg"),
    }
    res["sprites"] = {
        "windmill-5": sprite_metrics(ASSETS / "world-windmill-5.imageset/world-windmill-5.png", 120),
        "garden-5": sprite_metrics(ASSETS / "world-garden-5.imageset/world-garden-5.png", 110),
        "tea-stall-5": sprite_metrics(ASSETS / "world-tea-stall-5.imageset/world-tea-stall-5.png", 110),
        "pofu (companion)": sprite_metrics(POFU, 110),
        "mochi": sprite_metrics(ASSETS / "world-mochi.imageset/world-mochi.png", 50),
        "island-band0 (lawn lip)": sprite_metrics(ASSETS / "world-island-main-band0.imageset/world-island-main-band0.png", 1000),
    }
    res["h2"] = detail_budget()
    res["h6"] = {
        "game-home pofu": contact(home, BOXES["game-home"]["characters"][0]),
        "game-home mochi": contact(home, BOXES["game-home"]["characters"][1]),
        "ref stuck duo": contact(stuck, BOXES["ref-stuck"]["characters"][0]),
        "ref healed duo": contact(healed, BOXES["ref-healed"]["characters"][0]),
    }
    return res


def table(res: dict) -> str:
    keys = ["L", "C", "Cp95", "hue", "loc", "fine", "acc", "dark", "Lp2"]
    lines = []
    for src, regs in res["regions"].items():
        lines.append(f"## {src}")
        for r, m in regs.items():
            lines.append(f"  {r:11s}" + "  ".join(f"{k} {m[k]:>5}" for k in keys))
    lines.append("## H3: raw plate -> screen (Çağlayan, registered)")
    for src, regs in res["h3"].items():
        lines.append(f"  {src}: fit gain/lift per channel {regs['fit']}")
        for r in ("props", "lawn", "earth", "island"):
            a, b = regs[r]["raw"], regs[r]["screen"]
            lines.append(f"    {r:7s} raw L {a['L']:5} C {a['C']:5} loc {a['loc']:5} dark {a['dark']:5} Lp2 {a['Lp2']:5}"
                         f"  ->  screen L {b['L']:5} C {b['C']:5} loc {b['loc']:5} dark {b['dark']:5} Lp2 {b['Lp2']:5}")
    lines.append("## raw sprites (alpha > 0.9, at drawn size)")
    for n, m in res["sprites"].items():
        lines.append(f"  {n:24s}" + "  ".join(f"{k} {m[k]:>5}" for k in keys))
    lines.append(f"## H2: detail at phone scale (island {res['h2']['phone_island_px']} px), props + characters")
    for n in ("full", "half", "half+lock"):
        m = res["h2"][n]
        lines.append(f"  {n:10s} loc {m['loc']}  fine {m['fine']}  C {m['C']}  dark {m['dark']}")
    lines.append("## H6: contact darkening under characters (L* under minus beside)")
    for n, v in res["h6"].items():
        lines.append(f"  {n:18s} {v}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shots", type=Path)
    ap.add_argument("--json", type=Path)
    ap.add_argument("--register", action="store_true", help="re-find the plate's place in the frame")
    a = ap.parse_args(argv)
    if a.register:
        sp = load(ASSETS / "world-caglayan-island-4.imageset/world-caglayan-island-4.png", rgba=True)
        print(register(sp, load(a.shots / "caglayan-stage-4.jpg")))
        return 0
    res = run(a.shots)
    print(table(res))
    if a.json:
        a.json.write_text(json.dumps(res, indent=1, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
