#!/usr/bin/env python3
"""Home's level 3 golden plate with the day plate's sprout under the wheel.

The picked IL3 golden take (batch 87, t2) is the day plate's island under golden light, but it grows a
pink bloom on the sprout under the wheel, which the day plate does not have. The lead review asks for the
sprout back from the day plate: this reads both, cuts the day's sprout through a feathered ellipse, gain-
matches it to the golden take on a ring round the ellipse (per channel, as `il1_composite.py`) and writes
`design/art/plates/home/derived/plate-il3-golden.webp` (lossless). The takes are never overwritten
(docs/studio.md section 9); `objects.json` names the derived plate and `docs/state/plates.yaml` records it as
`edited`. Run before `ingest.py`:

    python3 -I tools/plate/golden_sprout.py build
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

REPO = Path(__file__).resolve().parent.parent.parent
PLATES = REPO / "design" / "art" / "plates" / "home"
OUT = PLATES / "derived" / "plate-il3-golden.webp"
GOLDEN = "design/art/takes/batch-87-home-golden/x-home-flow-il3-golden/plate__x-home-flow-il3-golden--t2.webp"
DAY_STAGE = "7"  # island level 3
#: The sprout's ellipse in plate pixels (centre x, centre y, radii) and the feather, hand data.
CENTRE, RADII, FEATHER, RING = (538.0, 982.0), (30.0, 22.0), 3.0, (6.0, 14.0)


def build() -> Path:
    day_path = json.loads((PLATES / "objects.json").read_text())["plates"]["day"][DAY_STAGE]
    day = np.asarray(Image.open(REPO / day_path).convert("RGB"), np.float64) / 255
    gold = np.asarray(Image.open(REPO / GOLDEN).convert("RGB"), np.float64) / 255
    h, w = gold.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx - CENTRE[0]) / RADII[0], (yy - CENTRE[1]) / RADII[1])
    mask = ndimage.gaussian_filter((r <= 1).astype(np.float64), FEATHER)
    ring = (r > 1 + RING[0] / RADII[0]) & (r < 1 + RING[1] / RADII[0])
    gain = np.array([np.median(gold[..., c][ring]) / max(np.median(day[..., c][ring]), 1e-4) for c in range(3)])
    patch = np.clip(day * gain, 0, 1)
    out = gold * (1 - mask[..., None]) + patch * mask[..., None]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((out * 255 + 0.5).astype(np.uint8)).save(OUT, lossless=True, quality=100)
    return OUT


if __name__ == "__main__":
    if sys.argv[1:] != ["build"]:
        sys.exit(__doc__)
    print(build())
