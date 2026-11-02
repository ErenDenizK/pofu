#!/usr/bin/env python3
"""Approximate depth map for the home island plate (technique f, depth-map 2.5D).

Stand-in for a production depth map. The value encodes world depth d (the diorama's y proxy,
larger is nearer) as v = (d + 120) / 240 in an 8-bit grey image at half resolution:

  - flat lawn surfaces (the main lawn and the back terrace's top): d = y, a plane seen from above;
  - vertical faces (the terrace's cliff, the rock bowl): d = the y of the edge they hang from,
    plus a small bulge for the rock's roundness.

Pixels are classed as lawn or earth by hue. In production this file would come from a monocular
depth model (Depth Anything V2 or Apple's Depth Pro) run in tools/art on every plate, then
corrected by hand where the model guesses wrong (thin props, the island's underside).

  python3 -I tools/depthmap.py            (run from design/prototypes/interactions)
"""
import os

import numpy as np
from PIL import Image, ImageFilter

ASSETS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets")
BOX = (-182.0, -106.0, 182.0, 182.0)  # world units, as BOX['isle-home'] in app.js


def main():
    src = Image.open(os.path.join(ASSETS, "isle-home.webp")).convert("RGBA")
    src = src.resize((src.width // 2, src.height // 2), Image.LANCZOS)
    a = np.asarray(src, dtype=np.float32) / 255.0
    h, w = a.shape[:2]
    x = BOX[0] + (np.arange(w) + 0.5) / w * (BOX[2] - BOX[0])
    y = BOX[1] + (np.arange(h) + 0.5) / h * (BOX[3] - BOX[1])
    X, Y = np.meshgrid(x, y)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    green = (g > r * 1.02) & (g > b)

    def edge(cy, ry, rx):  # front edge of an ellipse seen from above, y as a function of x
        return cy + ry * np.sqrt(np.clip(1 - (X / rx) ** 2, 0, 1))

    terrace_base = edge(-50.0, 35.0, 135.0)
    lip = edge(5.0, 45.0, 175.0)
    in_terrace = (np.abs(X) < 135) & (Y < terrace_base + 4)
    d = np.where(green, Y, 0.0)  # lawn and terrace top: a plane
    face = ~green & in_terrace
    rock = ~green & ~in_terrace
    d = np.where(face, terrace_base, d)
    d = np.where(rock, lip + 10 * (1 - (X / 175.0) ** 2), d)
    v = np.clip((d + 120) / 240, 0, 1)
    v = np.where(al > 0.02, v, (lip.mean() + 120) / 240)  # neutral outside the plate
    img = Image.fromarray(np.uint8(v * 255 + 0.5), "L").filter(ImageFilter.GaussianBlur(2))
    img.save(os.path.join(ASSETS, "isle-home.depth.webp"), "WEBP", lossless=True)
    print("isle-home.depth.webp", img.size)


if __name__ == "__main__":
    main()
