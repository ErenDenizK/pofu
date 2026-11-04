#!/usr/bin/env python3
"""Fix a washed take without regenerating it (docs/design/light-standard.md).

Moves a take toward the value targets of its colour-script cell x layer
(design/art/light-standard.json):

1. depth-weighted dehaze (dark-channel prior, atmospheric light = the take's own
   haze colour, never darker than mid grey); the far top of a plate keeps its haze,
   the subject plane loses it;
2. levels: a black point so the 2nd percentile reaches the target and a white
   point so the 98th does (neutral per channel, hue stays);
3. gamma toward the cell's median band (dusk and night come down, a dull day
   comes up);
4. a gentle S-curve when the spread is still short;
5. a touch of local contrast (clarity) when p75 local contrast is short.

The take is never overwritten: `<stem>--graded.<ext>` is written next to it.

    python3 -I tools/art/grade_take.py --cell day --layer subject TAKE... [--sheet out.jpg]
    python3 -I tools/art/grade_take.py --spec "path.webp:dusk:subject" ... --sheet out.jpg
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "imagegen"))
sys.path.insert(0, str(HERE.parent / "review"))
import light as lt  # noqa: E402
import style_lock as sl  # noqa: E402
import sheet  # noqa: E402

LAYER_DEHAZE = {"subject": 1.0, "near": 0.8, "far": 0.45}
FAR_KEEP = 0.15      # dehaze weight at the very top of a plate (the far sky)
OMEGA = 0.5          # share of the dark channel treated as haze
T_MIN = 0.65         # never stretch by more than 1.5x
BLACK_CAP = 0.7      # the black point never passes this (lightness 0-1)
GAMMA_RANGE = (0.5, 3.0)


def smoothstep(a: float, b: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def depth_weight(shape: tuple[int, int], layer: str, sprite: bool, centre: float | None = None,
                 alpha: np.ndarray | None = None) -> np.ndarray:
    """1 where the grade acts fully. A sprite has no depth; a plate is deeper toward the top.

    `centre` (a fraction of the canvas height) is where the plate's subject sits (the lawn's
    centre): the grade acts fully there and below it, and the haze grows toward the plate's back
    edge (the first opaque row), which keeps FAR_KEEP of it."""
    h, w = shape
    base = LAYER_DEHAZE[layer]
    if sprite:
        return np.full((h, w), base)
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    if centre is not None:
        rows = np.where((alpha > 0.03).any(axis=1))[0] if alpha is not None else []
        top = rows[0] / h if len(rows) else 0.0
        return base * (FAR_KEEP + (1 - FAR_KEEP) * smoothstep(top, max(centre, top + 0.05), y))
    return base * (FAR_KEEP + (1 - FAR_KEEP) * smoothstep(0.15, 0.65, y))


def atmosphere_of(rgb: np.ndarray) -> np.ndarray:
    """Atmospheric light of the take itself: the mean colour of the pixels with the highest dark channel."""
    dcp = lt.dark_channel(rgb)
    top = dcp >= np.percentile(dcp, 99.5)
    return np.clip(rgb[top].mean(axis=0), 0.5, 1.0)


def dehaze(rgb: np.ndarray, atmosphere: np.ndarray, weight: np.ndarray) -> np.ndarray:
    size = max(3, round(9 * max(rgb.shape[:2]) / lt.MEASURE_PX) | 1)
    dcp = lt.dark_channel(np.clip(rgb / np.maximum(atmosphere, 1e-3), 0, 1), size)
    t = np.clip(1 - OMEGA * dcp, T_MIN, 1)
    t = np.clip(sl.gaussian_blur(t, size * 1.2), T_MIN, 1)
    t = 1 - weight * (1 - t)
    return np.clip((rgb - atmosphere) / t[..., None] + atmosphere, 0, 1)


def _pct(L: np.ndarray, mask: np.ndarray) -> tuple[float, float, float]:
    v = L[mask]
    p2, p50, p98 = np.percentile(v, [2, 50, 98])
    return float(p2) / 100, float(p50) / 100, float(p98) / 100


def _median_gamma(x: np.ndarray, mask: np.ndarray, t: dict, darken_only: bool = False) -> tuple[np.ndarray, dict]:
    lo, hi = t["median"]
    med = _pct(x * 100, mask)[1]
    goal = (hi - 2) / 100 if med > hi / 100 else (lo + 2) / 100 if med < lo / 100 and not darken_only else None
    if goal is None or not 0.01 < med < 0.99:
        return x, {}
    g = float(np.clip(np.log(goal) / np.log(med), *GAMMA_RANGE))
    return x ** g, {"gamma": round(g, 2)}


def grade_rgba(rgba: np.ndarray, light: dict, strength: float = 1.0, centre: float | None = None) -> tuple[np.ndarray, dict]:
    """Return (graded rgba, what was done). Alpha is untouched.

    The tone moves happen on CIELAB lightness only (a and b are kept, a little
    chroma is given back as darks deepen), so the grade does not saturate.
    """
    t = lt.targets(light)
    rgb, alpha = rgba[..., :3], rgba[..., 3]
    sprite = float((alpha < 0.9).mean()) > 0.02
    mask = lt.subject_mask(rgba)
    info: dict = {}
    if not mask.any():
        return rgba, {"skipped": "no subject pixels"}
    weight = depth_weight(alpha.shape, light["layer"], sprite, centre, alpha) * strength
    hazy = lt.measure_light(rgba)["haze"] > t["haze_max"]  # a take that is clear enough is not dehazed
    dh = dehaze(rgb, atmosphere_of(rgb), weight) if hazy else rgb
    if hazy:
        info["dehaze"] = True
    lab = sl.srgb_to_lab(dh)
    L0 = lab[..., 0]
    x = L0 / 100
    # 1. a take lit too bright for a dark cell comes down first
    x, i = _median_gamma(x, mask, t, darken_only=True)
    info.update(i)
    # 2. black point, then white point
    p2, _, p98 = _pct(x * 100, mask)
    goal2 = max(t["p2_max"] - 6, 4.0) / 100
    if p2 * 100 > t["p2_max"]:  # only a take that misses the target is moved, and to a safe margin inside it
        b = min((p2 - goal2) / (1 - goal2), BLACK_CAP)
        x = np.clip((x - b) / (1 - b), 0, 1)
        info["black_point"] = round(b, 3)
    p98 = _pct(x * 100, mask)[2]
    goal98 = (t["p98_min"] + 3) / 100
    if p98 * 100 < t["p98_min"]:
        w = max(p98 / goal98, 0.75)
        x = np.clip(x / w, 0, 1)
        info["white_point"] = round(w, 3)
    # 3. the median band, either way
    x, i = _median_gamma(x, mask, t)
    info.update({k + "_2": v for k, v in i.items()})
    # 4. a gentle S-curve if the spread is still short
    p2, _, p98 = _pct(x * 100, mask)
    short = t["spread_min"] - (p98 - p2) * 100
    if short > 0:
        a = min(0.5, 0.2 + 0.01 * short)
        x = x + a * (x * x * (3 - 2 * x) - x)
        info["s_curve"] = round(a, 2)
    # 5. local contrast, depth-weighted, when p75 local contrast is still short
    L1 = x * 100
    lc = lt.measure_light(np.dstack([sl.lab_to_srgb(np.stack([L1, lab[..., 1], lab[..., 2]], axis=-1)), alpha]))["lc_p75"]
    if lc < t["lc_p75_min"]:
        sigma = 24 * max(L1.shape) / lt.MEASURE_PX
        L1 = np.clip(L1 + 0.6 * weight * (L1 - sl.gaussian_blur(L1, sigma)), 0, 100)
        info["clarity"] = 0.6
    L1 = L0 + (L1 - L0) * (strength if strength != 1.0 else 1.0)
    chroma = np.clip(1 + 0.006 * (L0 - L1), 0.9, 1.3)[..., None]  # a deeper tone keeps its colour (no muddy darks)
    out = sl.lab_to_srgb(np.concatenate([L1[..., None], lab[..., 1:] * chroma], axis=-1))
    return np.dstack([np.clip(out, 0, 1), alpha]), info


def graded_path(p: Path) -> Path:
    return p.with_name(f"{p.stem}--graded{p.suffix}")


def save(rgba: np.ndarray, p: Path) -> None:
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    if p.suffix.lower() == ".webp":
        im.save(p, quality=92)
    else:
        im.save(p)


def label(name: str, m: dict) -> str:
    return f"{name} p2 {m['L_p2']:.0f} p98 {m['L_p98']:.0f} med {m['L_p50']:.0f} hz {m['haze']:.2f}"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("takes", nargs="*", type=Path)
    ap.add_argument("--cell", choices=lt.CELLS)
    ap.add_argument("--layer", choices=lt.LAYERS, default="subject")
    ap.add_argument("--spec", action="append", default=[], help="PATH:CELL:LAYER (repeatable; overrides --cell/--layer)")
    ap.add_argument("--strength", type=float, default=1.0)
    ap.add_argument("--centre", type=float, help="plates: the subject's centre as a fraction of the canvas height; the grade is full there and haze grows toward the back edge")
    ap.add_argument("--sheet", type=Path, help="write a before/after sheet (JPEG, long side <= --max)")
    ap.add_argument("--max", type=int, default=1400)
    args = ap.parse_args(argv)
    jobs = [(Path(s.split(":")[0]), {"cell": s.split(":")[1], "layer": s.split(":")[2]}) for s in args.spec]
    if args.takes:
        if not args.cell:
            ap.error("--cell is required with plain take paths")
        jobs += [(p, {"cell": args.cell, "layer": args.layer}) for p in args.takes]
    if not jobs:
        ap.error("give takes (with --cell) or --spec")
    items = []
    for path, light in jobs:
        lt.parse_light(light)
        src = sl.load_rgba(path)
        before = lt.measure_light(src)
        graded, info = grade_rgba(src, light, args.strength, args.centre)
        after = lt.measure_light(graded)
        dest = graded_path(path)
        save(graded, dest)
        print(f"{path.name} [{light['cell']}/{light['layer']}]  {info}")
        print(f"   before {before}\n   after  {after}")
        flat = lambda a: Image.fromarray(np.clip(np.round(a[..., :3] * 255), 0, 255).astype(np.uint8))
        short = path.stem.split("--")[0].replace("plate__", "")
        items += [(label(short + " before", before), flat(src)), (label("after", after), flat(graded))]
    if args.sheet:
        out = sheet._save(sheet.grid(items, 4, args.max), args.sheet, args.max)
        print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
