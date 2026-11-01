#!/usr/bin/env python3
"""Soften the review's stand-in sprites into a painterly look and write WebP.

    python3 -I tools/painterly.py <sprites_dir> <assets_dir>

The vector stand-ins from render-standins.js read as flat UI drawings. A
light "paint" pass makes them sit next to Pofu's painted fur without
pretending to be final art: a mode filter merges small details into
brush-like patches, a soft blur removes vector edges, a gentle warm
light from the upper left matches the art bible, and the alpha edge is
feathered. Everything stays labeled as a stand-in on the page.

Pofu's face sprites are R1 plus code overlays, so they only get resized.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy.ndimage import uniform_filter

SRC, DST = sys.argv[1], sys.argv[2]
os.makedirs(DST, exist_ok=True)

# Output scale per sprite (fraction of the rendered size) and WebP quality.
SCALE = {"isle-home": 0.75, "pofu-": 1.0, "st-": 1.0, "isle-": 0.75}


def _kuwahara(rgb: np.ndarray, r: int) -> np.ndarray:
    """Kuwahara filter: each pixel takes the mean of its calmest quadrant (a gouache look)."""
    lum = rgb.mean(axis=2)
    k = r + 1
    mean_l = uniform_filter(lum, k)
    var = uniform_filter(lum * lum, k) - mean_l ** 2
    means = np.stack([uniform_filter(rgb[..., i], k) for i in range(3)], -1)
    best, out = None, np.zeros_like(rgb)
    for dy, dx in ((-r // 2, -r // 2), (-r // 2, r // 2), (r // 2, -r // 2), (r // 2, r // 2)):
        v = np.roll(var, (dy, dx), (0, 1))
        m = np.roll(means, (dy, dx), (0, 1))
        if best is None:
            best, out = v, m
        else:
            sel = v < best
            best = np.where(sel, v, best)
            out = np.where(sel[..., None], m, out)
    return out


def _noise(h: int, w: int, seed: int) -> np.ndarray:
    """Soft multi-scale value noise in -1..1: brush-scale color variation."""
    rng = np.random.default_rng(seed)
    acc = np.zeros((h, w))
    for cell, amp in ((48, 1.0), (18, 0.6), (7, 0.35)):
        g = rng.random((h // cell + 2, w // cell + 2))
        acc += amp * np.array(Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), float) / 255
    acc -= acc.mean()
    return acc / (np.abs(acc).max() + 1e-6)


def paint(im: Image.Image, seed: int) -> Image.Image:
    im = im.convert("RGBA")
    a = np.array(im.getchannel("A"), float)
    rgb = np.array(im.convert("RGB"), float)
    # Bleed colors under transparent pixels so the filters never pull in black.
    solid = np.array(im.convert("RGB").filter(ImageFilter.MaxFilter(9)), float)
    rgb = np.where((a > 8)[..., None], rgb, solid)
    h, w = a.shape
    # Brush-scale variation in value and a little warmth, then the gouache filter.
    n = _noise(h, w, seed)
    rgb = rgb * (1 + 0.07 * n[..., None]) + np.stack([6 * n, 2 * n, -4 * n], -1)
    # A soft key light from the upper left (art bible section 4).
    yy, xx = np.mgrid[0:h, 0:w]
    rgb *= (1.04 - 0.08 * ((xx / w + yy / h) / 2))[..., None]
    rgb = _kuwahara(np.clip(rgb, 0, 255), 6)
    out = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))
    out = out.convert("RGBA")
    out.putalpha(Image.fromarray(a.astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.1)))
    return out


boxes = json.load(open(os.path.join(SRC, "boxes.json")))
for i, name in enumerate(sorted(boxes)):
    im = Image.open(os.path.join(SRC, name + ".png"))
    scale = next((v for k, v in SCALE.items() if name.startswith(k)), 0.6)
    if not name.startswith("pofu-"):
        im = paint(im, i)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    im.save(os.path.join(DST, name + ".webp"), "WEBP", quality=82, method=6)
    print(f"{name:16} {im.size}  {os.path.getsize(os.path.join(DST, name + '.webp')) // 1024} KB")
