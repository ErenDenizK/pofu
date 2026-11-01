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
    "neighbor-bunny": 27, "res-hog": 28, "pofu": 64,
}
LEVELS = {"b1": (1.4, 2), "b2": (4.0, 3)}  # name -> (sigma in world units, downscale factor)


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
    with open(os.path.join(ASSETS, "blur-manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
