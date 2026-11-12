#!/usr/bin/env python3
"""Mattes for the distant isles of a sky set, from the master's own pixels (no model).

    python3 tools/plate/sprite_matte.py caglayan [--light day]

For each sprite box in `design/art/plates/<island>/sky/sky.json` the matte is where the painting
leaves the fitted sky by more than `threshold`: the isle's body, its greenery and its pink underside,
the largest connected piece, holes filled, softened by a pixel. The thin cloud wisps beside an isle are
not in it: `split.py` gives each sprite the puffs of its own surroundings. Written to
`sky/mattes/<name>.png` (the box's size) as hand data, to be adjusted by eye (Home's are BiRefNet-lite's).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import split  # noqa: E402


def make(island: str, light: str = "day") -> None:
    hand = split.load_hand(island)
    p = split.load_plate(split.ROOT / hand["lights"][light]["plate"], tuple(hand["size"]))
    isl = split.island_matte(hand, p)
    s, _ = split.fit_sky(p, isl, hand["seaTop"])
    d = np.linalg.norm(p - s, axis=-1)
    out = split.PLATES / island / "sky" / "mattes"
    out.mkdir(parents=True, exist_ok=True)
    for name, sp in hand["sprites"].items():
        x0, y0, x1, y1 = sp["box"]
        crop = d[y0:y1, x0:x1]
        m = crop > sp.get("threshold", 0.07)
        m = ndimage.binary_closing(m, iterations=2)
        lab, n = ndimage.label(m)
        if n == 0:
            raise SystemExit(f"{name}: nothing leaves the sky inside its box")
        m = lab == 1 + int(np.argmax(np.bincount(lab.ravel())[1:]))
        m = ndimage.binary_fill_holes(m)
        a = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.0)
        Image.fromarray(np.uint8(a * 255 + 0.5)).save(out / f"{name}.png")
        print(f"{name}: {int(m.sum())} px of {m.size}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("--light", default="day")
    a = ap.parse_args()
    make(a.island, a.light)
