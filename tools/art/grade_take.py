#!/usr/bin/env python3
"""Move a take into the reference envelope without regenerating it (docs/design/light-standard.md, ADR-0021).

Moves a take toward the value targets of its colour-script cell x layer
(design/art/light-standard.json, measured from the founder-picked references):

1. airlight lift: when the darks fall below the cell's floor (L p5), a toe
   curve lifts them to it (values above the knee stay), tinted toward the
   take's own lightest colour (the air), depth-weighted so a plate's far top
   takes the most;
2. a white point so the 98th percentile reaches cream;
3. gamma toward the cell's median band (either way);
4. softening: when p75 local contrast is above the band, the detail is pulled
   back toward its blur (one soft texture scale, never crisp micro-contrast).

The take is never overwritten: `<stem>--graded.<ext>` is written next to it.

    python3 -I tools/art/grade_take.py --cell day --layer subject TAKE... [--sheet out.jpg]
    python3 -I tools/art/grade_take.py --spec "path.webp:night:subject" ... --sheet out.jpg
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

LAYER_AIR = {"subject": 0.85, "near": 0.95, "far": 1.0}
NEAR_KEEP = 0.85     # airlight weight at the very bottom of a plate (the subject plane)
GAMMA_RANGE = (0.5, 2.5)
MARGIN = 3.0         # land this far inside a target, so a graded take passes with room


def smoothstep(a: float, b: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def depth_weight(shape: tuple[int, int], layer: str, sprite: bool) -> np.ndarray:
    """How much of the airlight lift a pixel takes: a sprite takes it evenly, a plate more toward its top (farther)."""
    h, w = shape
    base = LAYER_AIR[layer]
    if sprite:
        return np.full((h, w), base)
    y = np.linspace(0, 1, h)[:, None] * np.ones((1, w))
    return base * (1 - (1 - NEAR_KEEP) * smoothstep(0.15, 0.85, y))


def toe(L: np.ndarray, p5: float, goal: float, knee_above: float = 20.0) -> np.ndarray:
    """The lift (in L*) of a toe curve: p5 lands on `goal`, the knee (`goal + knee_above`) and
    everything above it stay, darker values rise the most (a black fringe becomes a mid-tone)."""
    knee = goal + knee_above
    return np.clip((goal - p5) * (knee - L) / max(knee - p5, 1e-3), 0, None)


def _pct(L: np.ndarray, mask: np.ndarray, q: float) -> float:
    return float(np.percentile(L[mask], q))


def _median_gamma(L: np.ndarray, mask: np.ndarray, t: dict) -> tuple[np.ndarray, dict]:
    lo, hi = t["median"]
    med = _pct(L, mask, 50)
    goal = hi - MARGIN if med > hi else lo + MARGIN if med < lo else None
    if goal is None or not 1 < med < 99:
        return L, {}
    g = float(np.clip(np.log(goal / 100) / np.log(med / 100), *GAMMA_RANGE))
    return 100 * (L / 100) ** g, {"gamma": round(g, 2)}


def grade_rgba(rgba: np.ndarray, light: dict, strength: float = 1.0) -> tuple[np.ndarray, dict]:
    """Return (graded rgba, what was done). Alpha is untouched.

    Tone moves happen on CIELAB lightness; the airlight lift also pulls a and b
    a little toward the air's colour, as real atmosphere does.
    """
    t = lt.targets(light)
    rgb, alpha = rgba[..., :3], rgba[..., 3]
    sprite = float((alpha < 0.9).mean()) > 0.02
    mask = lt.subject_mask(rgba)
    if not mask.any():
        return rgba, {"skipped": "no subject pixels"}
    info: dict = {}
    lab = sl.srgb_to_lab(rgb)
    L0 = lab[..., 0]
    L, ab = L0.copy(), lab[..., 1:].copy()
    # 1. airlight lift: a toe that brings p5 up to the floor and leaves values above the knee alone
    p5 = _pct(L, mask, 5)
    goal5 = t["p5_min"] + MARGIN
    if p5 < t["p5_min"]:
        wgt = depth_weight(L.shape, light["layer"], sprite) * strength
        lift = toe(L, p5, goal5) * wgt
        air_ab = ab[mask & (L >= _pct(L, mask, 97))].mean(axis=0)
        k = (lift / 100)[..., None]
        L = L + lift
        ab = ab * (1 - k) + air_ab * k
        info["airlight"] = round(goal5 - p5, 1)
    # 2. white point
    p98 = _pct(L, mask, 98)
    if p98 < t["p98_min"]:
        w = max(p98 / (t["p98_min"] + MARGIN), 0.8)
        L = np.clip(L / w, 0, 100)
        info["white_point"] = round(w, 3)
    # 3. the median band, either way
    L, i = _median_gamma(L, mask, t)
    info.update(i)
    # 4. soften micro-contrast when it is above the band, or give a flattened take a little form back
    lc_lo, lc_hi = t["lc_p75"]
    lc = lt.measure_light(np.dstack([sl.lab_to_srgb(np.concatenate([L[..., None], ab], axis=-1)), alpha]))["lc_p75"]
    if lc < lc_lo:
        sigma = 12 * max(L.shape) / lt.MEASURE_PX
        amount = float(np.clip(1.2 * (lc_lo + 0.3 - lc) / max(lc, 0.5), 0.2, 1.0))
        L = np.clip(L + amount * (L - sl.gaussian_blur(L, sigma)), 0, 100)
        info["form"] = round(amount, 2)
    elif lc > lc_hi:
        keep = float(np.clip((lc_hi - 0.3) / lc, 0.3, 1.0))
        base = sl.gaussian_blur(L, 1.5 * max(L.shape) / lt.MEASURE_PX)
        L = base + (L - base) * keep
        info["soften"] = round(keep, 2)
    # 5. the form step can dip the darks again: a last toe on lightness only
    p5 = _pct(L, mask, 5)
    if p5 < t["p5_min"]:
        L = L + toe(L, p5, goal5)
        info["airlight_2"] = round(goal5 - p5, 1)
    if strength != 1.0:
        L = L0 + (L - L0) * strength
    out = sl.lab_to_srgb(np.concatenate([np.clip(L, 0, 100)[..., None], ab], axis=-1))
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
    return f"{name} p5 {m['L_p5']:.0f} med {m['L_p50']:.0f} p98 {m['L_p98']:.0f} lc {m['lc_p75']:.1f}"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("takes", nargs="*", type=Path)
    ap.add_argument("--cell", choices=lt.CELLS)
    ap.add_argument("--layer", choices=lt.LAYERS, default="subject")
    ap.add_argument("--spec", action="append", default=[], help="PATH:CELL:LAYER (repeatable; overrides --cell/--layer)")
    ap.add_argument("--strength", type=float, default=1.0)
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
        graded, info = grade_rgba(src, light, args.strength)
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
