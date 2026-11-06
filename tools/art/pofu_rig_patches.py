#!/usr/bin/env python3
"""Cut the approved Pofu rig masters into small face patches for the app.

The masters (design/art/masters/pofu-*) are whole-body edits of the base
(pofu-hamster-base-v1, 1024x1536). The app draws the 522x496 `pofu-hamster`
cut from the same drawing, so each patch is a feathered window of a master,
scaled by the same bbox mapping, saved next to the base with its place as a
fraction of the base art. Prints the Swift table for PofuFacePart.placement.
"""
import os, sys
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
M = os.path.join(ROOT, "design/art/masters")
OUT = os.path.join(ROOT, "Packages/PofuKit/Sources/PofuCompanion/Resources")
BBOX = (138, 663, 892, 1376)  # the hamster in the 1024x1536 canvas
W, H = 522, 496
# `pofu-hamster.png` keeps a 12 px margin: its alpha box is (12, 12, 520, 484).
sx, sy = 508 / (BBOX[2] - BBOX[0]), 472 / (BBOX[3] - BBOX[1])

base = np.array(Image.open(f"{M}/pofu-hamster-base-v1/pofu-hamster-base.png").convert("RGBA")).astype(int)

# (master, window in master px (x0,y0,x1,y1), feather px, "auto" = tighten to the diff)
PARTS = {
    "mouth-smirk": ("pofu-mouth-smirk", (458, 982, 592, 1090), 14, False),
    "mouth-open": ("pofu-mouth-open", (458, 982, 592, 1090), 14, False),
    "mouth-o": ("pofu-mouth-o", (458, 982, 592, 1090), 14, False),
    "mouth-worried": ("pofu-mouth-worried", (458, 982, 592, 1090), 14, False),
    "ears-droop": ("pofu-ears-droop", (120, 590, 910, 880), 46, False),
    "paws-wave": ("pofu-paws-wave", (110, 1005, 500, 1260), 34, False),
}

os.makedirs(OUT, exist_ok=True)
for key, (master, win, feather, auto) in PARTS.items():
    src = Image.open(f"{M}/{master}/{master}.webp").convert("RGBA")
    a = np.array(src).astype(int)
    x0, y0, x1, y1 = win
    if auto:
        d = np.abs(a - base).max(axis=2)[y0:y1, x0:x1] > 40
        ys, xs = np.where(d)
        pad = 18
        x0, x1 = x0 + max(xs.min() - pad, 0), x0 + min(xs.max() + pad, x1 - x0)
        y0, y1 = y0 + max(ys.min() - pad, 0), y0 + min(ys.max() + pad, y1 - y0)
    w, h = x1 - x0, y1 - y0
    # feathered rounded window
    mask = Image.new("L", (w, h), 0)
    inset = min(feather, w // 4, h // 4)
    mask.paste(255, (inset, inset, w - inset, h - inset))
    mask = mask.filter(ImageFilter.GaussianBlur(inset / 2.2))
    crop = src.crop((x0, y0, x1, y1))
    alpha = np.array(crop.getchannel("A")).astype(float) * np.array(mask) / 255
    # premultiplied colour would bleed: keep colour, scale alpha
    crop.putalpha(Image.fromarray(alpha.astype("uint8")))
    ow, oh = max(round(w * sx), 1), max(round(h * sy), 1)
    crop = crop.resize((ow, oh), Image.LANCZOS)
    crop.save(f"{OUT}/pofu-part-{key}.png", optimize=True)
    px, py = 12 + (x0 - BBOX[0]) * sx, 12 + (y0 - BBOX[1]) * sy
    print(f'        "{key}": (x: {px / W:.4f}, y: {py / H:.4f}, w: {ow / W:.4f}, h: {oh / H:.4f}),')
