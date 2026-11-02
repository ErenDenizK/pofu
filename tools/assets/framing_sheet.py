#!/usr/bin/env python3
"""The framing before/after sheet: round 2's published frames beside this run's, with the empty-row
numbers under each (look round 3).

  python3 -I tools/assets/framing_sheet.py BEFORE_DIR AFTER_DIR OUT.jpg

BEFORE_DIR holds round 2's frames (screenshots/feat-look-round-2: grade-day-home.jpg and
grade-day-island.jpg); AFTER_DIR this run's PNGs. Frames missing on either side are skipped.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import frame_metrics as fm  # noqa: E402

FRAMES = [("grade-day-island", "Island · day"), ("grade-night-island", "Island · night"), ("grade-day-home", "Home · day")]


def _find(folder: Path, stem: str) -> Path | None:
    for ext in (".png", ".jpg"):
        if (folder / (stem + ext)).exists():
            return folder / (stem + ext)
    return None


def _font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def main(argv: list[str]) -> int:
    before, after, out = Path(argv[0]), Path(argv[1]), Path(argv[2])
    cells = []
    for stem, label in FRAMES:
        b, a = _find(before, stem), _find(after, stem)
        if b and a:
            cells.append((label, b, a))
    if not cells:
        print("no frames to compare", file=sys.stderr)
        return 0
    w, h, pad, head, foot = 402, 874, 16, 36, 54
    sheet = Image.new("RGB", (pad + len(cells) * 2 * (w + pad), pad + head + h + foot + pad), (242, 242, 242))
    d = ImageDraw.Draw(sheet)
    big, small = _font(18), _font(14)
    for i, (label, b, a) in enumerate(cells):
        for j, (tag, path) in enumerate((("round 2", b), ("round 3", a))):
            x = pad + (2 * i + j) * (w + pad)
            with Image.open(path) as im:
                e = fm.emptiness(im)
                sheet.paste(im.convert("RGB").resize((w, h), Image.LANCZOS), (x, pad + head))
            d.text((x, pad + 8), f"{label} · {tag}", fill=(25, 25, 25), font=big)
            d.text((x, pad + head + h + 8), f"empty rows {e['empty']:.0%}  ·  longest dead run {e['run']:.0%} of the height", fill=(60, 60, 60), font=small)
    sheet.save(out, "JPEG", quality=86, optimize=True)
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
