#!/usr/bin/env python3
"""A strip of the characters from Home frames, one column per frame, one row per character, 1:1.

    python3 -I tools/plate/character_strip.py OUT_PREFIX FRAME [FRAME ...] [--per-sheet 5]

Each cell is a 150 x 150 crop of the frame around a character's feet (`harmony_check.characters`'
geometry), so a seam, a halo or a step in colour from one level to the next is visible at the size
the app draws them. Frames are `home-plate-full-<state>.png` (1206 x 2622); the sheets are written
as `OUT_PREFIX-1.png`, `OUT_PREFIX-2.png`, ... with `--per-sheet` columns each (at most 1000 px wide
at the default 5), in the order given.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import harmony_check as hc  # noqa: E402

CELL = 150


def crop(img: Image.Image, feet: tuple[float, float]) -> Image.Image:
    x, y = round(feet[0]), round(feet[1])
    return img.crop((x - CELL // 2, y - CELL + 15, x + CELL // 2, y + 15))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("out")
    ap.add_argument("frames", nargs="+")
    ap.add_argument("--per-sheet", type=int, default=5)
    ap.add_argument("--plate-json")
    args = ap.parse_args(argv)
    data = json.loads(Path(args.plate_json or hc.PLATE_JSON).read_text())
    names = list(hc.characters(data, 1206))
    written = []
    for n, start in enumerate(range(0, len(args.frames), args.per_sheet), 1):
        chunk = args.frames[start:start + args.per_sheet]
        sheet = Image.new("RGB", (CELL * len(chunk), CELL * len(names)))
        draw = ImageDraw.Draw(sheet)
        for col, f in enumerate(chunk):
            img = Image.open(f).convert("RGB")
            for row, (name, c) in enumerate(hc.characters(data, img.width).items()):
                sheet.paste(crop(img, c["feet"]), (col * CELL, row * CELL))
            label = Path(f).stem.removeprefix("home-plate-full-")
            draw.rectangle((col * CELL, 0, col * CELL + 8 * len(label) + 6, 12), fill=(0, 0, 0))
            draw.text((col * CELL + 3, 1), label, fill=(255, 255, 255))
        out = Path(f"{args.out}-{n}.png")
        sheet.save(out)
        written.append(str(out))
    print("\n".join(written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
