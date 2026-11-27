#!/usr/bin/env python3
"""Ingest the Gezgin's cloud wake (pofu-art batch 198 `batch-198-gezgin-wake`) into World.xcassets.

Picks (the lead's, in each job's review.yaml): the long chain of seven puffs `x14-gez-wake-long` take 1 as
`world-gezgin-wake-long`, the short cluster `x14-gez-wake-short` take 2 as `world-gezgin-wake-short`.
Both takes are clean RGBA cut-outs (transparent corners, no matte fringe: the alpha edge's colour is lilac-cream
down to alpha 1, never grey), so no matte pipeline is needed. Each is cropped to its solid pixels and scaled to
the density of the Gezgin's own cut-out (3 px per point, plan row 2b): she is 760 px wide, the long chain 920 px
(about 1.15 of her at the cruise), the short cluster 520 px.

The far end of each is faded out by a smooth alpha ramp (from 55 % of the width to nothing at the tip) so the last
puffs go soft along the chain and the tip never reads as a speed streak (the lead's note on take 1).

    python3 -I tools/art/gezgin_wake.py <pofu-art checkout>

Needs Pillow and numpy.
"""
import json, pathlib, sys
import numpy as np
from PIL import Image

ASSETS = pathlib.Path(__file__).resolve().parents[2] / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
JOBS = {
    "world-gezgin-wake-long": ("x14-gez-wake-long", 1, 920),
    "world-gezgin-wake-short": ("x14-gez-wake-short", 2, 520),
}
FADE_FROM = 0.55


def main() -> int:
    art = pathlib.Path(sys.argv[1])
    for name, (job, take, width) in JOBS.items():
        im = Image.open(art / f"design/art/takes/batch-198-gezgin-wake/{job}/prop__{job}--t{take}.webp").convert("RGBA")
        im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())
        im = im.resize((width, round(width * im.height / im.width)), Image.LANCZOS)
        px = np.array(im).astype(np.float32)
        u = np.clip((np.arange(im.width) / (im.width - 1) - FADE_FROM) / (1 - FADE_FROM), 0, 1)
        px[..., 3] *= (1 - u * u * (3 - 2 * u))[None, :]
        im = Image.fromarray(np.round(px).astype(np.uint8), "RGBA")
        folder = ASSETS / f"{name}.imageset"
        folder.mkdir(exist_ok=True)
        im.save(folder / f"{name}.png", optimize=True)
        (folder / "Contents.json").write_text(json.dumps(
            {"images": [{"filename": f"{name}.png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
        print(name, im.size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
