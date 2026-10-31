"""Assemble labelled stills into a frame strip (grid) PNG.

Usage: python3 strip.py OUT.png COLUMNS TILE_PX FRAME.png[=Label] ...
"""

import sys

from PIL import Image, ImageDraw, ImageFont


def font(size):
    for name in ("DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    out, cols, tile = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    items = []
    for arg in sys.argv[4:]:
        path, _, label = arg.partition("=")
        items.append((path, label))
    rows = (len(items) + cols - 1) // cols
    label_h = int(tile * 0.11)
    gap = 6
    sheet = Image.new("RGB", (cols * tile + (cols + 1) * gap, rows * (tile + label_h) + (rows + 1) * gap), (245, 228, 219))
    draw = ImageDraw.Draw(sheet)
    f = font(int(label_h * 0.5))
    for i, (path, label) in enumerate(items):
        r, c = divmod(i, cols)
        x = gap + c * (tile + gap)
        y = gap + r * (tile + label_h + gap)
        im = Image.open(path).convert("RGB").resize((tile, tile), Image.LANCZOS)
        sheet.paste(im, (x, y))
        draw.rectangle([x, y + tile, x + tile, y + tile + label_h], fill=(255, 255, 255))
        w = draw.textlength(label, font=f)
        draw.text((x + (tile - w) / 2, y + tile + label_h * 0.22), label, fill=(70, 50, 44), font=f)
    sheet.save(out, optimize=True)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
