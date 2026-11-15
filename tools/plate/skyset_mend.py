#!/usr/bin/env python3
"""Mend the holes the island left in Home's drift clouds (one sky at every level).

    python3 -I tools/plate/skyset_mend.py home [--check]

The split (`split.py`) takes the level-10 island out of the painting; a far or mid cloud that the island covered keeps a
hole where the island's tree, windmill or lamp stood (alpha 0 inside the cloud). While the sky set drew its own island
layer the hole sat behind it at rest. Every matted Home state now draws the sky set without that layer behind its own
plate (`HomePlate.isMatted`), and the r3b mattes are tighter than the layer, so the holes show, at every level. This
closes them in the shipped far and mid tiles (`world-home-sky-far-*`, `-mid-*`): a hole is clear sky enclosed by a cloud
inside the island layer's footprint (grown by `REACH` master px); its alpha becomes the cloud's closed over it and its
colour the cloud's round it (a normalised blur of its premultiplied colour). Every other pixel keeps its own values. Run it after `skyset_export.py`; a mended tile has nothing left to close, so it is not rewritten.
`--check` exits 1 when a tile still has a hole.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import heic  # noqa: E402

RESOURCES = HERE.parents[1] / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
#: Master px round the island layer's footprint that may be mended, the gap a cloud is closed over (tile px), the
#: least added alpha that counts, and the blur that lends a new pixel its cloud's colour (tile px).
REACH = 24
RADIUS = 14
SOLID = 0.12
MIN_HOLE = 24          # tile px: a smaller gap is the codec's, not the island's
GAIN = 0.04
SPREAD = 6.0
TILES = ("far", "mid")


def _read(name: str) -> np.ndarray:
    return np.asarray(heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}").convert("RGBA"), np.float32) / 255


def footprint(spec: dict, layer: dict, shape: tuple[int, int]) -> np.ndarray:
    """The island layer's alpha (> 0.02, grown by `REACH` master px) in `layer`'s own pixels (`shape`)."""
    isl = next(entry for entry in spec["layers"] if entry["role"] == "island")
    ia = _read(isl["asset"])[..., 3]
    iw, ih = int(round(isl["size"][0])), int(round(isl["size"][1]))
    ia = cv2.resize(ia, (iw, ih), interpolation=cv2.INTER_AREA if ia.shape[1] > iw else cv2.INTER_LINEAR)
    k = shape[1] / layer["size"][0]                     # tile px per master px
    out = np.zeros(shape, np.float32)
    # the island layer in the tile's px: master (x, y) -> ((x - pos) * k)
    m = np.float32([[k, 0, (isl["pos"][0] - layer["pos"][0]) * k], [0, k, (isl["pos"][1] - layer["pos"][1]) * k]])
    out = cv2.warpAffine((ia > 0.02).astype(np.float32), m, (shape[1], shape[0]), flags=cv2.INTER_LINEAR)
    r = max(int(round(REACH * k)), 1)
    return cv2.dilate((out > 0.01).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1,) * 2)) > 0


def mend(rgba: np.ndarray, region: np.ndarray) -> tuple[np.ndarray, int]:
    """`rgba` (straight) with the holes inside its clouds closed where they lie in `region`; the count of pixels that
    changed. A hole is clear sky enclosed by a cloud (`SOLID` alpha, its hairline gaps closed): a gap between two clouds
    or a cloud's own soft edge is not one, so nothing else changes and a mended tile has nothing left to close."""
    a = rgba[..., 3]
    solid = cv2.morphologyEx((a > SOLID).astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))
    holes = ndimage.binary_fill_holes(solid) & (a <= SOLID) & region
    lab, n = ndimage.label(holes)
    if n:
        size = ndimage.sum(holes, lab, range(1, n + 1))
        holes = np.isin(lab, 1 + np.flatnonzero(size >= MIN_HOLE))
    if not holes.any():
        return rgba, 0
    holes = cv2.dilate(holes.astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))) > 0
    closed = cv2.morphologyEx(a, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * RADIUS + 1,) * 2))
    mask = cv2.GaussianBlur(holes.astype(np.float32), (0, 0), 1.2)
    want = a + (np.maximum(a, closed) - a) * mask
    grow = (want - a) > GAIN
    if not grow.any():
        return rgba, 0
    # the hole's colour: the cloud's own round it (normalised blur of premultiplied colour, the hole left out)
    w = np.where(holes, 0, a)
    num = cv2.GaussianBlur(rgba[..., :3] * w[..., None], (0, 0), SPREAD)
    den = cv2.GaussianBlur(w, (0, 0), SPREAD)[..., None]
    fill = num / np.maximum(den, 1e-6)
    t = np.clip((want - a) / np.maximum(want, 1e-6), 0, 1)[..., None]   # the share of the new alpha that is new
    out = rgba.copy()
    out[..., :3] = np.where((want > a)[..., None], rgba[..., :3] * (1 - t) + fill * t, rgba[..., :3])
    out[..., 3] = want
    return np.clip(out, 0, 1), int(grow.sum())


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island", nargs="?", default="home")
    ap.add_argument("--check", action="store_true", help="only report; exit 1 when a tile still has a hole")
    args = ap.parse_args(argv)
    data = json.loads((RESOURCES / "Plates" / f"skyset-{args.island}.json").read_text())
    left = 0
    for light, spec in sorted(data["lights"].items()):
        for layer in spec["layers"]:
            if layer["id"] not in TILES:
                continue
            rgba = _read(layer["asset"])
            out, n = mend(rgba, footprint(spec, layer, rgba.shape[:2]))
            print(f"{light} {layer['id']}: {n} px {'to mend' if args.check else 'mended'}")
            if n and not args.check:
                heic.save(heic_image(out), ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}{heic.SUFFIX}")
            left += n
    return 1 if args.check and left else 0


def heic_image(rgba: np.ndarray):
    from PIL import Image
    return Image.fromarray(np.uint8(np.clip(rgba, 0, 1) * 255 + 0.5), "RGBA")


if __name__ == "__main__":
    sys.exit(main())
