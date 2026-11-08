#!/usr/bin/env python3
"""The plate-first home beside its concept: concept | app Home | app whole island | before.

`Tests/WorldScreenshots/HomePlateScreenshotTests.swift` renders the home plate in the real app
(`home-plate-day-home`, `-whole`, `-settled`); CI's publish job lays them beside the concept the plate
stands in for, and, with `--before`, main's Home at the same light (`concept-day-home`), as
`home-plate.jpg` (the concept-match sheet's pattern, `tools/assets/concept_match.py`).

    python3 -I tools/plate/home_sheet.py SHOTS_DIR OUT.jpg [--before BEFORE_DIR]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
HAND = REPO / "design" / "art" / "plates" / "home" / "objects.json"
H = 1000
PAD = 16
LABEL = 30


def find(folder: Path, stem: str) -> Path | None:
    for ext in (".png", ".jpg"):
        if (folder / f"{stem}{ext}").exists():
            return folder / f"{stem}{ext}"
    return None


def fit(img: Image.Image, h: int = H) -> Image.Image:
    img = img.convert("RGB")
    return img.resize((round(img.width * h / img.height), h), Image.Resampling.LANCZOS)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("shots", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--before", type=Path)
    args = ap.parse_args(argv)
    concept = REPO / json.loads(HAND.read_text())["plates"]["day"]["0"]
    panels = [("concept (the stand-in plate)", Image.open(concept))]
    for stem, name in (("home-plate-day-home", "app: Home"), ("home-plate-day-whole", "app: whole island"),
                       ("home-plate-day-settled", "app: Home, settled")):
        path = find(args.shots, stem)
        if path:
            panels.append((name, Image.open(path)))
    if args.before:
        path = find(args.before, "concept-day-home")
        if path:
            panels.append(("before: main, Home 12:00", Image.open(path)))
    if len(panels) < 2:
        print("no home-plate frames", file=sys.stderr)
        return 1
    imgs = [(name, fit(img)) for name, img in panels]
    width = PAD + sum(im.width + PAD for _, im in imgs)
    sheet = Image.new("RGB", (width, PAD + LABEL + H + PAD), (240, 240, 240))
    draw = ImageDraw.Draw(sheet)
    x = PAD
    for name, im in imgs:
        draw.text((x, PAD + 8), name, fill=(40, 40, 40))
        sheet.paste(im, (x, PAD + LABEL))
        x += im.width + PAD
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out, "JPEG", quality=88, optimize=True)
    print(f"{args.out}: {len(imgs)} panels")
    return 0


if __name__ == "__main__":
    sys.exit(main())
