#!/usr/bin/env python3
"""Concept match sheet: each home light state beside its single-image concept, with numbers.

The founder (2026-11-07) asked for the game's light and colour to match the home concepts (day,
dusk, night, weather). `Tests/WorldScreenshots/ConceptMatchScreenshotTests.swift` renders Home at
each concept's hour and weather (`concept-<state>-home.png`, `-whole.png`); this lays every state on
one row (concept, whole-island shot, Home framing) and prints, per image, CIELAB numbers that the
research note uses (docs/research/concept-match.md):

  L, p2, p98   mean lightness and the black and white points
  C            mean chroma
  shadow a,b   mean a*, b* of the darkest 15 %: the hue of the shadows
  sky L, C     the top 15 % of the frame
  sea L, C     the bottom 12 % (the cloud sea)

  python3 -I tools/assets/concept_match.py SHOTS_DIR OUT.jpg [--before BEFORE_DIR]

With `--before`, each row also shows the same state from an earlier run (e.g. main's
screenshots branch), so a change reads as before / after / concept. A missing state is skipped.
The concept per state lives in `TARGETS`; change it when the founder picks a new home direction.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

TAKES = REPO / "design" / "art" / "takes"
TARGETS = {
    "day": "batch-25-seasons/x-season-summer/plate__x-season-summer--t2.webp",
    "golden": "batch-25-seasons/x-season-summer-evening/plate__x-season-summer-evening--t2.webp",
    # The founder's liked night (2026-11-07, ADR-0021), not the "too contrasty" home night key.
    "night": "batch-22-gezgin-forms/x-gezgin-f2-night/plate__x-gezgin-f2-night--t1.webp",
    "rain": "batch-45-beautiful-wounds/x-home-rain/plate__x-home-rain--t1.webp",
    "mist": "batch-45-beautiful-wounds/x-home-mist/plate__x-home-mist--t1.webp",
}
ROW_H = 520


def numbers(img: Image.Image) -> dict:
    rgb = np.asarray(img.convert("RGB").resize((max(1, img.width * 400 // img.height), 400)), dtype=np.float64) / 255
    lab = sl.srgb_to_lab(rgb)
    L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
    C = np.hypot(a, b)
    lo = L <= np.percentile(L, 15)
    h = L.shape[0]
    sky, sea = slice(0, int(h * 0.15)), slice(int(h * 0.88), h)
    return {
        "L": round(float(L.mean()), 1),
        "p2": round(float(np.percentile(L, 2)), 1),
        "p98": round(float(np.percentile(L, 98)), 1),
        "C": round(float(C.mean()), 1),
        "shadow_ab": [round(float(a[lo].mean()), 1), round(float(b[lo].mean()), 1)],
        "sky_LC": [round(float(L[sky].mean()), 1), round(float(C[sky].mean()), 1)],
        "sea_LC": [round(float(L[sea].mean()), 1), round(float(C[sea].mean()), 1)],
    }


def label(n: dict) -> str:
    return (f"L {n['L']} [{n['p2']}-{n['p98']}]  C {n['C']}  shadow {n['shadow_ab'][0]},{n['shadow_ab'][1]}\n"
            f"sky L,C {n['sky_LC'][0]},{n['sky_LC'][1]}  sea L,C {n['sea_LC'][0]},{n['sea_LC'][1]}")


def fit(img: Image.Image) -> Image.Image:
    return img.convert("RGB").resize((round(img.width * ROW_H / img.height), ROW_H), Image.LANCZOS)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shots", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--before", type=Path)
    args = ap.parse_args(argv)

    def find(folder: Path | None, stem: str) -> Path | None:
        if folder is None:
            return None
        for ext in (".png", ".jpg"):
            if (folder / (stem + ext)).exists():
                return folder / (stem + ext)
        return None

    rows, readout = [], {}
    for state, rel in TARGETS.items():
        cells: list[tuple[str, Image.Image]] = []
        concept = TAKES / rel
        if concept.exists():
            cells.append((f"concept {state}", Image.open(concept)))
        for tag, folder in (("before", args.before), ("now", args.shots)):
            for framing in ("whole", "home"):
                path = find(folder, f"concept-{state}-{framing}")
                if path is not None:
                    cells.append((f"{tag} {framing}" if args.before else framing, Image.open(path)))
        if len(cells) < 2:
            continue
        readout[state] = {name: numbers(img) for name, img in cells}
        rows.append((state, cells))
    if not rows:
        print("no concept-match shots found", file=sys.stderr)
        return 1

    pad, text = 12, 46
    tiles = [[(name, fit(img)) for name, img in cells] for _, cells in rows]
    width = pad + max(sum(t.width + pad for _, t in row) for row in tiles)
    sheet = Image.new("RGB", (width, pad + len(tiles) * (ROW_H + text + pad)), (238, 238, 238))
    draw = ImageDraw.Draw(sheet)
    for r, ((state, _), row) in enumerate(zip(rows, tiles)):
        x, y = pad, pad + r * (ROW_H + text + pad)
        for name, tile in row:
            sheet.paste(tile, (x, y + text))
            draw.text((x, y), f"{state} / {name}\n" + label(readout[state][name]), fill=(30, 30, 30))
            x += tile.width + pad
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out, "JPEG", quality=85, optimize=True)
    args.out.with_suffix(".json").write_text(json.dumps(readout, indent=1))
    for state, cells in readout.items():
        for name, n in cells.items():
            print(f"{state:7s} {name:14s} " + label(n).replace("\n", "  "))
    return 0


if __name__ == "__main__":
    sys.exit(main())
