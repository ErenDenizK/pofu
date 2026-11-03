#!/usr/bin/env python3
"""Guides for the island diorama (docs/product/game-design.md, sections 6 and 15).

Writes:
  design/art/templates/station-guide.png   1024 x 1024 composition guide for
      one station vignette: the ground ellipse (the slot's footprint in the
      diorama's fixed 3/4 view), the anchor cross, and the height bar.
      Attach it to station prompts; the prompt asks to remove it.
  design/art/templates/decor-guide.png     1024 x 1024 guide for one placeable
      decor item at the station guide's scale: a footprint half as wide as a
      station's, a height bar at 45 % of a station's height, and a dashed
      hang line for items that hang from an awning or a branch.
  docs/product/assets/island-layout.png    the world layout schematic: the
      main island, the back terrace, the two islets, every slot and the
      stage that opens it.

    python3 -I tools/art/island_guides.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
MAG = (236, 0, 140, 255)
GRID = (200, 196, 204, 255)


def font(size, bold=True):
    for path in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def station_guide():
    img = Image.new("RGB", (1024, 1024), (248, 246, 242))
    d = ImageDraw.Draw(img)
    cx, cy, rx, ry = 512, 800, 360, 108          # ground ellipse, ratio 0.3 = the diorama's view angle
    for k in range(1, 4):
        d.ellipse([cx - rx * k / 3, cy - ry * k / 3, cx + rx * k / 3, cy + ry * k / 3], outline=GRID, width=2)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=MAG, width=6)
    d.line([(cx - 22, cy), (cx + 22, cy)], fill=MAG, width=5)
    d.line([(cx, cy - 22), (cx, cy + 22)], fill=MAG, width=5)
    top = 150
    for y in range(top, cy, 26):
        d.line([(cx, y), (cx, y + 13)], fill=MAG, width=3)
    d.line([(cx - 50, top), (cx + 50, top)], fill=MAG, width=4)
    out = os.path.join(ROOT, "design", "art", "templates")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, "station-guide.png"), optimize=True)


def decor_guide():
    """A decor item at the station guide's scale (same pixels per meter).

    Footprint: half a station's width (rx 180 against 360), centered lower
    on the canvas so the item sits large enough to paint. Height bar: 340 px
    (a station's is 650 px from its ellipse). Hanging items hang from the
    dashed line at y 300 and stay above y 620.
    """
    img = Image.new("RGB", (1024, 1024), (248, 246, 242))
    d = ImageDraw.Draw(img)
    cx, cy, rx, ry = 512, 840, 180, 54
    for k in range(1, 3):
        d.ellipse([cx - rx * k / 2, cy - ry * k / 2, cx + rx * k / 2, cy + ry * k / 2], outline=GRID, width=2)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], outline=MAG, width=6)
    d.line([(cx - 18, cy), (cx + 18, cy)], fill=MAG, width=5)
    d.line([(cx, cy - 18), (cx, cy + 18)], fill=MAG, width=5)
    top = cy - 340
    for y in range(top, cy, 26):
        d.line([(cx, y), (cx, y + 13)], fill=MAG, width=3)
    d.line([(cx - 40, top), (cx + 40, top)], fill=MAG, width=4)
    for x in range(232, 792, 30):
        d.line([(x, 300), (x + 15, 300)], fill=MAG, width=3)
    out = os.path.join(ROOT, "design", "art", "templates")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, "decor-guide.png"), optimize=True)


STAGE_COL = [(108, 79, 216), (143, 116, 240), (217, 130, 43), (47, 143, 91), (62, 124, 177), (194, 69, 122)]


def layout():
    W, H = 1600, 860
    img = Image.new("RGB", (W, H), (252, 252, 251))
    d = ImageDraw.Draw(img)
    s, ox, oy = 2.6, W / 2 + 60, 610
    P = lambda x, y: (ox + x * s, oy + y * s)

    def ell(cx, cy, rx, ry, fill, outline, w=3, dash=False):
        x0, y0 = P(cx - rx, cy - ry)
        x1, y1 = P(cx + rx, cy + ry)
        d.ellipse([x0, y0, x1, y1], fill=fill, outline=outline, width=w)

    # islets and bridges
    for (cx, cy, r, st) in ((226, -118, 48, 4), (-222, -92, 50, 5)):
        ell(cx, cy, r, r * 0.36, (236, 246, 228), STAGE_COL[st])
    d.line([P(150, -60), P(196, -112)], fill=(176, 138, 102), width=5)
    d.line([P(-150, -50), P(-190, -88)], fill=(176, 138, 102), width=5)
    # main island: stage 1-2 lawn inside stage 3 lawn
    ell(0, 0, 172, 56, (226, 241, 214), STAGE_COL[2])
    ell(0, 0, 124, 42, (214, 236, 196), STAGE_COL[0])
    # terrace
    ell(0, -66, 132, 34, (232, 244, 220), STAGE_COL[3])
    slots = [("Sunflower garden", -66, -4, 0), ("Çay ocağı", 64, -2, 1), ("bagel-cart stand", -132, 16, 2), ("Lily pond", 132, 18, 2),
             ("Library", -62, -74, 3), ("Workshop", 62, -70, 3), ("Observatory", 226, -118, 4), ("Hamam", -222, -92, 5)]
    f, fs = font(24), font(19, False)

    def label(x, y, text, fnt):
        box = d.textbbox((x, y), text, font=fnt, anchor="mm")
        d.rounded_rectangle([box[0] - 8, box[1] - 5, box[2] + 8, box[3] + 5], radius=10, fill=(255, 255, 255))
        d.text((x, y), text, fill=(42, 31, 45), font=fnt, anchor="mm")
    for name, x, y, st in slots:
        cx, cy = P(x, y)
        d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=STAGE_COL[st])
        d.text((cx, cy), str(st + 1), fill="white", font=font(20), anchor="mm")
        label(cx, cy + 36, name, f)
    px, py = P(6, 20)
    d.ellipse([px - 12, py - 12, px + 12, py + 12], fill=(245, 184, 61))
    label(px, py + 32, "Pofu (Home camera)", f)
    d.text((40, 36), "Pofu's island: fixed slots and the stage that opens each", fill=(42, 31, 45), font=font(34))
    legend = ["Stage 1 · day 1 · Pofu's garden", "Stage 2 · 1 tended day", "Stage 3 · 4 tended days · lawn widens",
              "Stage 4 · 10 tended days · back terrace", "Stage 5 · 20 tended days · east islet + bridge", "Stage 6 · 34 tended days · west islet + bridge"]
    for i, text in enumerate(legend):
        y = 96 + i * 32
        d.ellipse([40, y, 62, y + 22], fill=STAGE_COL[i])
        d.text((51, y + 11), str(i + 1), fill="white", font=font(15), anchor="mm")
        d.text((74, y + 11), text, fill=(74, 59, 74), font=fs, anchor="lm")
    d.text((W - 40, H - 30), "Front 3/4 view, fixed camera. World units = points at village zoom 1.0.", fill=(102, 85, 95), font=fs, anchor="rm")
    img.save(os.path.join(ROOT, "docs", "product", "assets", "island-layout.png"), optimize=True)


if __name__ == "__main__":
    station_guide()
    decor_guide()
    layout()
    print("wrote station-guide.png, decor-guide.png and island-layout.png")
