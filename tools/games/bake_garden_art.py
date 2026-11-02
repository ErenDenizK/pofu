"""Bake the Ayçiçeği garden game's sprites from approved art masters.

The minigame reuses existing masters (no new generation): sunflower heads
cut from the garden station's level 1, and Pofu, Mochi and Fındık at the
sizes the game draws them (3x for an iPhone, with a little headroom for
squash and stretch). Run from the repository root:

    python3 -I tools/games/bake_garden_art.py

Outputs go to Packages/PofuKit/Sources/PofuGames/Resources/. The
script is deterministic: same masters in, same pixels out.
"""

from __future__ import annotations

import math
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
# Flat, because SwiftPM's process rule flattens resource folders anyway.
OUT = ROOT / "Packages/PofuKit/Sources/PofuGames/Resources"

# (output name, master, target height in px). Heights are 3x the largest
# on-screen size the scene uses, so sprites never upscale.
CHARACTERS = [
    ("garden-pofu", "design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png", 360),
    ("garden-mochi", "design/art/masters/mochi-v2/mochi-v2.webp", 270),
    ("garden-findik", "design/art/masters/findik-base/findik-base.webp", 270),
]

# Sunflower heads cut from garden level 1: (name, centre x, centre y, radius).
BLOOMS = [
    ("garden-bloom", 524, 385, 150),
    ("garden-bloom-small", 258, 478, 128),
]
BLOOM_SIZE = 192  # a 42 pt cell at 3x, with the petals spilling a little


def trim(image: Image.Image) -> Image.Image:
    box = image.getchannel("A").point(lambda a: 255 if a > 6 else 0).getbbox()
    return image.crop(box) if box else image


def bake_character(name: str, master: str, height: int) -> None:
    image = trim(Image.open(ROOT / master).convert("RGBA"))
    width = round(image.width * height / image.height)
    image.resize((width, height), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)


def bake_bloom(name: str, cx: int, cy: int, radius: int) -> None:
    source = Image.open(ROOT / "design/art/stations/garden-1/garden-1.png").convert("RGBA")
    head = source.crop((cx - radius, cy - radius, cx + radius, cy + radius))
    pixels = head.load()
    size = head.width
    feather = 10.0
    for y in range(size):
        for x in range(size):
            r, g, b, a = pixels[x, y]
            # Drop the stem and leaves (sage green) and anything outside
            # the head's circle, with a soft edge.
            distance = math.hypot(x - radius, y - radius)
            keep = max(0.0, min(1.0, (radius - distance) / feather))
            if g > r + 4:
                keep = 0.0
            pixels[x, y] = (r, g, b, round(a * keep))
    head = trim(head)
    side = max(head.width, head.height)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(head, ((side - head.width) // 2, (side - head.height) // 2))
    square.resize((BLOOM_SIZE, BLOOM_SIZE), Image.LANCZOS).save(OUT / f"{name}.png", optimize=True)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, master, height in CHARACTERS:
        bake_character(name, master, height)
    for name, cx, cy, radius in BLOOMS:
        bake_bloom(name, cx, cy, radius)
    for path in sorted(OUT.glob("*.png")):
        with Image.open(path) as image:
            print(f"{path.relative_to(ROOT)}: {image.width}x{image.height}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
