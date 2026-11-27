#!/usr/bin/env python3
"""Ingest the mooring post (pofu-art batch 160, `x4-gez-mooring-post`, take 1) into World.xcassets.

The take is already a clean RGBA cut-out (transparent corners, no matte fringe), so it needs no matte
pipeline: it is cropped to its solid pixels and scaled to 400 px wide as `world-gezgin-post`.
Take 1 over take 2: the stronger silhouette at small size (larger bracket and lantern, clearer rope turns).

    python3 -I tools/art/gezgin_post.py <pofu-art checkout>

Needs Pillow. The numbers `GezginPost` in `GezginLayout.swift` carries (the pole's foot and height as shares of
the cut-out) were measured on this cut.
"""
import json, pathlib, sys
from PIL import Image

ASSETS = pathlib.Path(__file__).resolve().parents[2] / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
TAKE = "design/art/takes/batch-160-gezgin-source/x4-gez-mooring-post/prop__x4-gez-mooring-post--t1.webp"


def main() -> int:
    im = Image.open(pathlib.Path(sys.argv[1]) / TAKE).convert("RGBA")
    box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    im = im.crop(box)
    h = round(400 * im.height / im.width)
    im = im.resize((400, h), Image.LANCZOS)
    folder = ASSETS / "world-gezgin-post.imageset"
    folder.mkdir(exist_ok=True)
    im.save(folder / "world-gezgin-post.png", optimize=True)
    (folder / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": "world-gezgin-post.png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print("size", im.size)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
