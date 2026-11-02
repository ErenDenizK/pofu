#!/usr/bin/env python3
"""Pre-blurred depth-of-field variants for the interaction prototype.

This is the asset-pipeline step that the interaction spec recommends instead of
live blur: every world plate, vignette, and character gets two baked variants,
so depth of field at runtime is an opacity cross-fade between stacked images.

  soft  (.b1): Gaussian sigma 1.4 world units, stored at 1/2 resolution
  deep  (.b2): Gaussian sigma 4.0 world units, stored at 1/3 resolution

A world unit is a point at camera scale 1. Each source is padded by 3 sigma on
every side (blur bleeds outside the alpha), and the padding is written to
assets/blur-manifest.json as a fraction of the source size, so the page can
grow the blurred image's box by the same amount.

  python3 -I tools/preblur.py            (run from design/prototypes/interactions)
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(os.path.dirname(HERE), "assets")

# Source name -> width of its box in world units (from the page's BOX table).
UNITS = {
    "isle-home": 364, "isle-harbor": 268, "isle-stars": 244, "isle-hamam": 256, "isle-library": 244,
    "st-cay-2": 120, "st-cay-3": 120, "st-garden-3": 120, "st-garden-4": 120, "st-pond-2": 120,
    "st-windmill-2": 120, "st-workshop-2": 120,
    "neighbor-bunny": 27, "res-hog": 28, "pofu": 64, "cloud-a": 80, "cloud-b": 120,
}
# The home island plate is cut into depth bands (world y), so depth of field can vary across it.
# Each band keeps the full canvas; its alpha is the plate's alpha times a band mask. A band is
# opaque through the overlap with the band in front of it, and the front band fades in over it,
# so stacked back to front the bands recompose the plate without a seam.
PLATE = "isle-home"
PLATE_BOX_TOP, PLATE_BOX_H = -106.0, 288.0  # world units (BOX in app.js)
BANDS = [(-1e9, -50), (-50, 0), (0, 50), (50, 1e9)]
FEATHER = 10.0
LEVELS = {"b1": (1.4, 2), "b2": (4.0, 3), "b3": (9.0, 4)}  # name -> (sigma in world units, downscale); b3 feeds tilt-shift only


def blur_variant(src, sigma_px, down):
    pad = int(math.ceil(3 * sigma_px))
    big = Image.new("RGBA", (src.width + 2 * pad, src.height + 2 * pad), (0, 0, 0, 0))
    big.paste(src, (pad, pad))
    # Blur premultiplied colour so transparent edges do not bleed dark fringes.
    a = np.asarray(big, dtype=np.float32) / 255.0
    pre = a.copy()
    pre[..., :3] *= pre[..., 3:4]
    blurred = []
    for i in range(4):
        ch = Image.fromarray(np.uint8(np.clip(pre[..., i] * 255.0 + 0.5, 0, 255)), "L")
        blurred.append(np.asarray(ch.filter(ImageFilter.GaussianBlur(sigma_px)), dtype=np.float32) / 255.0)
    rgb = np.stack(blurred[:3], -1)
    alpha = blurred[3][..., None]
    rgb = np.where(alpha > 1e-4, rgb / np.maximum(alpha, 1e-4), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], -1)
    img = Image.fromarray(np.uint8(out * 255.0 + 0.5), "RGBA")
    w, h = max(1, round(img.width / down)), max(1, round(img.height / down))
    return img.resize((w, h), Image.LANCZOS), pad


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


# Atmospheric perspective, baked: lighter, cooler, less saturated with distance. Amount per source
# from its placement depth (the diorama's y; larger is nearer): clamp((40 - depth) / 220) * 0.38,
# and a flat 0.3 for the distant islands. Baked for every blur level, so runtime haze costs nothing.
HAZE_RGB = np.array([220, 235, 245], dtype=np.float32)
HAZE_DEPTH = {"st-windmill-2": -74, "st-workshop-2": -70, "st-garden-3": -4, "st-garden-4": -4, "st-cay-2": -2,
              "st-cay-3": -2, "st-pond-2": 18, "isle-home-band0": -78, "isle-home-band1": -25, "isle-home-band2": 25}
HAZE_FLAT = {"isle-harbor": 0.3, "isle-stars": 0.3, "isle-hamam": 0.3, "isle-library": 0.3}


def make_haze():
    amounts = {k: float(np.clip((40 - d) / 220, 0, 1) * 0.38) for k, d in HAZE_DEPTH.items()}
    amounts.update(HAZE_FLAT)
    for name, amt in amounts.items():
        for lvl in ("", "b1", "b2", "b3"):
            suffix = f".{lvl}" if lvl else ""
            a = np.asarray(Image.open(os.path.join(ASSETS, name + suffix + ".webp")).convert("RGBA"), dtype=np.float32)
            rgb = a[..., :3]
            grey = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
            rgb = rgb + (grey[..., None] - rgb) * (amt * 0.6)  # desaturate
            rgb = rgb + (HAZE_RGB - rgb) * amt  # lighten and cool toward the sky
            out = np.concatenate([np.clip(rgb, 0, 255), a[..., 3:]], -1)
            Image.fromarray(np.uint8(out + 0.5), "RGBA").save(os.path.join(ASSETS, f"{name}.hz{suffix}.webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"haze {name}: {amt:.2f}")
    return amounts


def make_bands(manifest):
    pads = manifest[PLATE]
    crops = {}
    for lvl in ("", "b1", "b2", "b3"):
        src = Image.open(os.path.join(ASSETS, PLATE + (f".{lvl}" if lvl else "") + ".webp")).convert("RGBA")
        a = np.asarray(src, dtype=np.float32)
        py = pads[lvl][1] if lvl else 0.0
        top = PLATE_BOX_TOP - py * PLATE_BOX_H
        span = PLATE_BOX_H * (1 + 2 * py)
        y = top + (np.arange(a.shape[0]) + 0.5) / a.shape[0] * span  # world y of each row
        for k, (s0, s1) in enumerate(BANDS):
            w = np.ones_like(y) if k == 0 else smoothstep(s0 - FEATHER, s0 + FEATHER, y)
            if s1 < 1e8:
                w = np.where(y <= s1 + FEATHER, w, 0.0)
            out = a.copy()
            out[..., 3] *= w[:, None]
            # Crop to the band's opaque rows (most of the canvas is empty), and record the crop as a
            # fraction of the image height so the page can place it: no overdraw of empty pixels.
            rows = np.where(out[..., 3].max(axis=1) > 0.5)[0]
            r0, r1 = int(rows[0]), int(rows[-1]) + 1
            crops.setdefault(f"{PLATE}-band{k}", {})[lvl or "s"] = [round(r0 / a.shape[0], 5), round(r1 / a.shape[0], 5)]
            name = f"{PLATE}-band{k}" + (f".{lvl}" if lvl else "")
            Image.fromarray(np.uint8(np.clip(out[r0:r1], 0, 255) + 0.5), "RGBA").save(os.path.join(ASSETS, name + ".webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"bands for {PLATE}{'.' + lvl if lvl else ''}")
    for k in range(len(BANDS)):
        manifest[f"{PLATE}-band{k}"] = dict(pads, crop=crops[f"{PLATE}-band{k}"])


def main():
    manifest = {}
    for name, units in UNITS.items():
        path = os.path.join(ASSETS, name + ".webp")
        if not os.path.exists(path):
            print("missing", path, file=sys.stderr)
            return 1
        src = Image.open(path).convert("RGBA")
        ppu = src.width / units
        entry = {}
        for lvl, (sigma_u, down) in LEVELS.items():
            img, pad = blur_variant(src, sigma_u * ppu, down)
            img.save(os.path.join(ASSETS, f"{name}.{lvl}.webp"), "WEBP", quality=72, method=6)
            entry[lvl] = [round(pad / src.width, 4), round(pad / src.height, 4)]
        manifest[name] = entry
        print(f"{name}: {src.width}x{src.height}, {ppu:.2f} px/unit, pads {entry}")
    make_bands(manifest)
    manifest["_haze"] = {k: round(v, 3) for k, v in make_haze().items()}
    with open(os.path.join(ASSETS, "blur-manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
