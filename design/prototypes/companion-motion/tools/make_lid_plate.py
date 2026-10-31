"""Make the "lid plate": the cut-out with fur painted over both eyes.

Stand-in for the image-model variant `pofu-base-eyes-closed` in the asset
contract (docs/design/companion-motion.md). The shader reveals this plate
above the upper lid line (and below the lower one) while the visible band of
the eye is squashed, which reads as a lid sliding over the eye. Because the
plate is pixel-identical to the base outside the eyes, there is no seam.

Method per eye: harmonic (Laplace) fill of the ellipse from its boundary,
which matches the surrounding color exactly, plus high-frequency fur detail
borrowed from the fur directly above the eye, plus a little lid shading.

Usage: python3 make_lid_plate.py BASE.png OUT.png  (eye ellipses below)
"""

import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

# Eye ellipses in image px (cx, cy, rx, ry); must match RIG.eyeL/eyeR.
EYES = [(188, 218, 42, 41), (359, 217, 42, 41)]


def harmonic_fill(img, mask, iterations=3000):
    out = img.copy()
    # Start from the mean of the boundary to converge faster.
    ring = nd.binary_dilation(mask, iterations=1) & ~mask
    for c in range(img.shape[2]):
        out[..., c][mask] = img[..., c][ring].mean()
    for _ in range(iterations):
        avg = 0.25 * (np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1))
        out[mask] = avg[mask]
    return out


def main():
    src, dst = sys.argv[1], sys.argv[2]
    rgba = np.asarray(Image.open(src).convert("RGBA")).astype(float)
    h, w, _ = rgba.shape
    yy, xx = np.mgrid[0:h, 0:w]
    out = rgba.copy()
    lum = rgba[..., :3]
    blur = nd.gaussian_filter(lum, (3, 3, 0))
    detail = lum - blur
    for cx, cy, rx, ry in EYES:
        r = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
        mask = r < 1.06
        filled = harmonic_fill(rgba[..., :3], mask)
        # Fur detail from directly above the eye (shifted down by 2.2 radii).
        shift = int(round(2.2 * ry))
        borrowed = np.roll(detail, shift, axis=0)
        fur = filled + borrowed * 0.6
        # Lid shading: a touch darker toward the lid line (lower half).
        qy = (yy - cy) / ry
        shade = 1.0 - 0.04 * np.clip((qy + 0.2) / 1.2, 0, 1)
        fur = fur * shade[..., None]
        w_soft = np.clip((1.06 - r) / 0.08, 0, 1)[..., None]
        out[..., :3] = np.where(mask[..., None], w_soft * fur + (1 - w_soft) * rgba[..., :3], out[..., :3])
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA").save(dst, optimize=True)
    print(dst)


if __name__ == "__main__":
    main()
