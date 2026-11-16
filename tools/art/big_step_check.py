#!/usr/bin/env python3
"""Is each step of a ladder a BIG step? The measure of docs/design/island-progression-v1.md section 5.1.

A level is what the player paid for, so it must read at a glance at mid distance (the object about 50 pt wide).
Detail inside the old outline (a pot, a string of bulbs, a lily pad) does not: only a new mass does. Two modes.

Cut-outs (station forms, the parts on Nazli's back): RGBA pictures on one registered canvas, lowest first.
For each step from A to B, with the shapes taken at alpha 0.5:

  B1  outside   area of B outside A (A grown by 1.5 % of its diagonal, so a redrawn edge is not counted),
                as a share of A's area: at least 0.25
  B2  overlap   intersection over union of the two shapes: at most 0.80
  B3  reach     the bounding box grows by at least 15 % in height or in width
                (so the new mass is above or beside the old one, not a thicker edge)

A step is BIG when B1 and B2 pass, and B3 or an outside share of 0.5 or more. Anything else is a TOUCH: fine as
decoration inside a level, never a level of its own.

Plates (an island's stages, its ground at each island level): opaque pictures in one camera. For each step, the
share of the island (`--mask`, or the whole picture) whose colour moved by more than 12 CIELAB units after a
blur of 1 % of the width (so grain and re-rendering do not count): at least 0.25 is BIG.

    python3 -I tools/art/big_step_check.py look-1.webp look-2.webp ... [--json out.json]
    python3 -I tools/art/big_step_check.py --plates stage-0.png stage-1.png ... [--mask island-matte.png]

Exit status 1 when any step is a TOUCH. Numbers guard the rule; the eye still judges the frame.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

OUTSIDE_MIN = 0.25
OUTSIDE_ALONE = 0.50
IOU_MAX = 0.80
REACH_MIN = 0.15
PLATE_DELTA = 12.0
PLATE_SHARE_MIN = 0.25


def _dilate(mask: np.ndarray, r: int) -> np.ndarray:
    """Grow a boolean mask by r px (a square element; two box passes, no dependencies)."""
    if r <= 0:
        return mask
    k = 2 * r + 1
    pad = np.pad(mask.astype(np.int32), r)
    c = np.cumsum(np.cumsum(pad, axis=0), axis=1)
    c = np.pad(c, ((1, 0), (1, 0)))
    box = c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]
    return box > 0


def _bbox(mask: np.ndarray) -> tuple[int, int, int, int]:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        return (0, 0, 0, 0)
    return (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)


def cutout_step(a: np.ndarray, b: np.ndarray) -> dict:
    """Compare two shapes (boolean arrays of one size): the step from a to b."""
    if a.shape != b.shape:
        raise ValueError(f"shapes differ: {a.shape} and {b.shape}; the looks must share one canvas")
    area_a = int(a.sum())
    if area_a == 0:
        raise ValueError("the first shape is empty")
    ax0, ay0, ax1, ay1 = _bbox(a)
    diag = float(np.hypot(ax1 - ax0, ay1 - ay0))
    grown = _dilate(a, max(1, round(diag * 0.015)))
    outside = float((b & ~grown).sum()) / area_a
    union = int((a | b).sum())
    iou = float((a & b).sum()) / union if union else 1.0
    bx0, by0, bx1, by1 = _bbox(b)
    grow_h = (by1 - by0) / max(1, ay1 - ay0) - 1.0
    grow_w = (bx1 - bx0) / max(1, ax1 - ax0) - 1.0
    reach = max(grow_h, grow_w)
    b1, b2, b3 = outside >= OUTSIDE_MIN, iou <= IOU_MAX, reach >= REACH_MIN
    big = b1 and b2 and (b3 or outside >= OUTSIDE_ALONE)
    return {
        "outside": round(outside, 3), "iou": round(iou, 3), "reach": round(reach, 3),
        "area_ratio": round(float(b.sum()) / area_a, 3),
        "B1": bool(b1), "B2": bool(b2), "B3": bool(b3), "verdict": "BIG" if big else "TOUCH",
    }


def _srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    c = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


def _box_blur(img: np.ndarray, r: int) -> np.ndarray:
    if r <= 0:
        return img
    k = 2 * r + 1
    pad = np.pad(img, ((r, r), (r, r), (0, 0)), mode="edge")
    c = np.cumsum(np.cumsum(pad, axis=0), axis=1)
    c = np.pad(c, ((1, 0), (1, 0), (0, 0)))
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


def plate_step(a: np.ndarray, b: np.ndarray, mask: np.ndarray | None = None) -> dict:
    """Compare two opaque pictures (float RGB 0..1, one size): the share of the masked area that changed."""
    if a.shape != b.shape:
        raise ValueError(f"sizes differ: {a.shape} and {b.shape}; the stages must share one camera")
    r = max(1, round(a.shape[1] * 0.01))
    delta = np.linalg.norm(_srgb_to_lab(_box_blur(a, r)) - _srgb_to_lab(_box_blur(b, r)), axis=-1)
    area = mask if mask is not None else np.ones(delta.shape, bool)
    share = float((delta[area] > PLATE_DELTA).mean()) if area.any() else 0.0
    return {"changed": round(share, 3), "verdict": "BIG" if share >= PLATE_SHARE_MIN else "TOUCH"}


def _load(path: Path):
    from PIL import Image  # imported here so the pure functions test without Pillow plugins

    try:
        import pillow_heif

        pillow_heif.register_heif_opener()
    except ImportError:
        pass
    return Image.open(path)


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("pictures", nargs="+", type=Path, help="the ladder, lowest step first")
    p.add_argument("--plates", action="store_true", help="opaque stages in one camera, not cut-outs")
    p.add_argument("--mask", type=Path, help="plates: the island's matte (white or opaque = island)")
    p.add_argument("--json", type=Path, help="write the report here")
    args = p.parse_args(argv)
    if len(args.pictures) < 2:
        p.error("a ladder needs two pictures or more")
    steps = []
    if args.plates:
        imgs = [np.asarray(_load(f).convert("RGB"), np.float64) / 255 for f in args.pictures]
        mask = None
        if args.mask:
            m = _load(args.mask)
            mask = np.asarray(m.getchannel("A") if m.mode == "RGBA" else m.convert("L")) > 127
        for i in range(len(imgs) - 1):
            steps.append({"from": args.pictures[i].name, "to": args.pictures[i + 1].name, **plate_step(imgs[i], imgs[i + 1], mask)})
    else:
        shapes = [np.asarray(_load(f).convert("RGBA").getchannel("A")) > 127 for f in args.pictures]
        for i in range(len(shapes) - 1):
            steps.append({"from": args.pictures[i].name, "to": args.pictures[i + 1].name, **cutout_step(shapes[i], shapes[i + 1])})
    for s in steps:
        nums = "  ".join(f"{k} {v}" for k, v in s.items() if k not in ("from", "to", "verdict"))
        print(f"{s['verdict']:5}  {s['from']} -> {s['to']}  {nums}")
    if args.json:
        args.json.write_text(json.dumps(steps, indent=1) + "\n")
    return 1 if any(s["verdict"] == "TOUCH" for s in steps) else 0


if __name__ == "__main__":
    sys.exit(main())
