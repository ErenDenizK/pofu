#!/usr/bin/env python3
"""Bake tangent-space normal maps for painted sprites (graphics spike).

A painted sprite has no geometry, so the height map is inferred from the
art itself, the way SpriteIlluminator and Laigter do it:

  1. a rounded dome from the alpha silhouette: the distance to the edge
     (Euclidean distance transform) shaped by a circular bevel profile, so
     the rim of every shape turns away from the viewer;
  2. a little luminance detail: the art's own high-passed luminance
     (inverted by default, dark strokes stand proud), so painted cracks,
     planks and fur clumps catch light.

The normal comes from the height's central differences. Convention
(OpenGL, y up): R = x (right), G = y (up), B = z (toward the viewer), each
n * 0.5 + 0.5. Pixels outside the silhouette are the flat normal
(0.5, 0.5, 1.0) and the map is fully opaque, so it never scales a normal
through premultiplied alpha; the 1 px border is always flat, and pixel
(0, 0) is therefore a known value the shader uses to calibrate the
texture's colour decoding.

Usage:
  python3 -I tools/assets/normals.py bake SRC.png OUT.png [--scale 0.5]
  python3 -I tools/assets/normals.py spike      # the three spike sprites
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
COMPANION = ROOT / "Packages/PofuKit/Sources/PofuCompanion/Resources"

# (source png, imageset name) for the spike scene: the çay ocağı, Mochi and
# Pofu. Normals are baked from the app's sprites so they register exactly.
SPIKE = [
    # A table with a kettle on it: a tight bevel, strong painted detail.
    (ASSETS / "world-cay-1.imageset/world-cay-1.png", "world-cay-1--normal", dict(bevel=14.0, dome=0.25, detail=0.45, strength=6.0)),
    (ASSETS / "world-mochi.imageset/world-mochi.png", "world-mochi--normal", dict(bevel=18.0, dome=0.6, detail=0.25, strength=6.0)),
    # A fur ball: nearly all dome, so the key wraps round the whole body.
    (COMPANION / "pofu-hamster.png", "world-pofu--normal", dict(bevel=60.0, dome=0.8, detail=0.2, strength=8.0)),
]


def luminance(rgb: np.ndarray) -> np.ndarray:
    return rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float64)


def bevel_profile(d: np.ndarray, radius: float) -> np.ndarray:
    """Circular bevel: 0 at the edge, rising like a quarter circle to 1 at
    `radius` pixels in, flat beyond. The slope is vertical at the edge, so
    the rim turns fully away from the viewer."""
    t = np.clip(d / max(radius, 1e-6), 0.0, 1.0)
    return np.sqrt(1.0 - (1.0 - t) ** 2)


def height_map(
    rgb: np.ndarray,
    alpha: np.ndarray,
    bevel: float | None = None,
    dome: float = 0.35,
    detail: float = 0.12,
    invert_luma: bool = True,
) -> np.ndarray:
    """Height in 0..~1 (pixels outside the silhouette are 0)."""
    mask = alpha > 0.5
    if not mask.any():
        return np.zeros(alpha.shape, dtype=np.float64)
    d = ndimage.distance_transform_edt(mask)
    d_max = float(d.max())
    ys, xs = np.nonzero(mask)
    extent = min(ys.max() - ys.min() + 1, xs.max() - xs.min() + 1)
    radius = bevel if bevel is not None else float(np.clip(extent * 0.10, 4.0, 36.0))
    base = (1.0 - dome) * bevel_profile(d, radius) + dome * (d / d_max) ** 0.6
    base = ndimage.gaussian_filter(base, 1.0) * mask

    lum = luminance(rgb)
    sigma = max(extent / 40.0, 1.5)
    # High-pass inside the silhouette only (outside is not paint).
    weight = ndimage.gaussian_filter(mask.astype(np.float64), sigma)
    local = ndimage.gaussian_filter(lum * mask, sigma) / np.maximum(weight, 1e-3)
    high = (lum - local) * mask
    if invert_luma:
        high = -high
    high = ndimage.gaussian_filter(high, 0.8)
    # Detail fades out toward the rim so the bevel stays clean.
    fade = np.clip(d / max(radius, 1.0), 0.0, 1.0)
    return (base + detail * high * fade) * mask


def height_to_normal(height: np.ndarray, strength: float = 4.0) -> np.ndarray:
    """Tangent-space unit normals (h, w, 3), x right, y up, z out, from a
    height map whose rows run top to bottom. `strength` scales the slope."""
    padded = np.pad(height, 1, mode="edge")
    dx = (padded[1:-1, 2:] - padded[1:-1, :-2]) * 0.5
    dy_down = (padded[2:, 1:-1] - padded[:-2, 1:-1]) * 0.5
    # Rows grow downward, so "up" is the negative row direction.
    nx = -dx * strength
    ny = dy_down * strength
    nz = np.ones_like(height)
    n = np.stack([nx, ny, nz], axis=-1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True)


def encode(normals: np.ndarray) -> np.ndarray:
    return np.clip(np.rint((normals * 0.5 + 0.5) * 255.0), 0, 255).astype(np.uint8)


def decode(rgb8: np.ndarray) -> np.ndarray:
    n = rgb8.astype(np.float64) / 255.0 * 2.0 - 1.0
    return n / np.maximum(np.linalg.norm(n, axis=-1, keepdims=True), 1e-9)


def bake(src: Path, out: Path, scale: float = 0.5, strength: float = 4.0, **kw) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    arr = np.asarray(im, dtype=np.float64) / 255.0
    rgb, alpha = arr[..., :3], arr[..., 3]
    h = height_map(rgb, alpha, **kw)
    n = height_to_normal(h, strength)
    mask = alpha > 0.5
    flat = np.array([0.0, 0.0, 1.0])
    n = np.where(mask[..., None], n, flat)
    # Keep the border flat so pixel (0, 0) is a known calibration value.
    n[0, :, :] = flat
    n[-1, :, :] = flat
    n[:, 0, :] = flat
    n[:, -1, :] = flat
    rgb8 = encode(n)
    if scale != 1.0:
        w, hgt = max(round(im.width * scale), 1), max(round(im.height * scale), 1)
        small = Image.fromarray(rgb8, "RGB").resize((w, hgt), Image.BOX)
        rgb8 = encode(decode(np.asarray(small)))
        rgb8[0, :, :] = rgb8[-1, :, :] = encode(flat[None, :])[0]
        rgb8[:, 0, :] = rgb8[:, -1, :] = encode(flat[None, :])[0]
    result = Image.fromarray(rgb8, "RGB").convert("RGBA")
    result.putalpha(255)
    out.parent.mkdir(parents=True, exist_ok=True)
    result.save(out, "PNG", optimize=True)
    return result


def write_imageset(name: str, png: Path) -> None:
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / f"{name}.png"
    if png.resolve() != target.resolve():
        target.write_bytes(png.read_bytes())
    (folder / "Contents.json").write_text(
        '{\n  "images": [\n    {\n      "filename": "%s.png",\n      "idiom": "universal"\n    }\n  ],\n'
        '  "info": {\n    "author": "xcode",\n    "version": 1\n  }\n}\n' % name
    )


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("bake", help="bake one normal map")
    b.add_argument("src", type=Path)
    b.add_argument("out", type=Path)
    b.add_argument("--scale", type=float, default=0.5)
    b.add_argument("--strength", type=float, default=4.0)
    b.add_argument("--keep-luma", action="store_true", help="bright = high instead of dark = high")
    sub.add_parser("spike", help="bake the spike scene's three sprites into the asset catalog")
    args = ap.parse_args(argv)
    if args.cmd == "bake":
        bake(args.src, args.out, args.scale, args.strength, invert_luma=not args.keep_luma)
        return 0
    for src, name, kw in SPIKE:
        out = ASSETS / f"{name}.imageset" / f"{name}.png"
        bake(src, out, **kw)
        write_imageset(name, out)
        print(f"{name}: {out.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
