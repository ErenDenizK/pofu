"""Key the flat background out of an AI concept image.

Prototype-only tool. The asset contract (docs/design/companion-motion.md)
asks for transparent PNGs straight from the image model; this script exists
because the first concept was delivered on a flat peach background with a
painted ground shadow.

Method:
1. Fit a smooth background (per-channel quadratic in x, y) to the border.
2. Distance from the background gives the silhouette and fur wisps.
3. Near the ground, color cannot separate the painted shadow from fur or the
   pink feet (they share hue and value), but texture can: the shadow is
   smooth, fur and the outlined feet are not. Local luminance deviation
   gates the bottom zone.
4. Edge colors are decontaminated (un-premultiplied against the background,
   then pulled toward the nearest solid fur color) so no peach fringe shows
   on other backgrounds.

Usage: python3 key_background.py IN.png OUT.png [--pad 12]
Requires numpy, scipy, Pillow.
"""

import argparse

import numpy as np
from PIL import Image
from scipy import ndimage as nd


def fit_background(rgb: np.ndarray, border: int = 6) -> np.ndarray:
    h, w, _ = rgb.shape
    yy, xx = np.mgrid[0:h, 0:w]
    sel = np.zeros((h, w), bool)
    sel[:border] = sel[-border:] = True
    sel[:, :border] = sel[:, -border:] = True

    def basis(x, y):
        return np.stack([np.ones_like(x), x, y, x * x, y * y, x * y], 1)

    fit = basis(xx[sel] / w, yy[sel] / h)
    full = basis((xx / w).ravel(), (yy / h).ravel())
    out = np.empty_like(rgb)
    for c in range(3):
        coef, *_ = np.linalg.lstsq(fit, rgb[..., c][sel], rcond=None)
        out[..., c] = (full @ coef).reshape(h, w)
    return out


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def disk(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r


def key(rgb: np.ndarray) -> np.ndarray:
    h, w, _ = rgb.shape
    bg = fit_background(rgb)
    dist = np.sqrt(((rgb - bg) ** 2).sum(-1))

    lum = rgb.mean(-1)
    mean = nd.uniform_filter(lum, 5)
    tex = np.sqrt(np.maximum(nd.uniform_filter(lum * lum, 5) - mean * mean, 0))

    # The ground zone: the lowest part of the figure, where the painted
    # shadow lives.
    rows = np.nonzero((dist > 10).any(1))[0]
    ground_bottom = rows.max()
    zone_top = int(ground_bottom - 0.16 * (ground_bottom - rows.min()))
    zone = np.zeros((h, w), bool)
    zone[zone_top:] = True

    solid = (dist > 26) & ~zone
    textured = (tex > 5.0) & (dist > 12) & zone

    # The painted contact crease is textured too and runs wider than the
    # body. Gate the ground zone with an ellipse fitted to the body's
    # flanks, and let the feet (closed outlines, so solid once filled)
    # through as compact blobs.
    body = nd.binary_fill_holes(nd.binary_closing(solid, structure=disk(3)))
    top, bottom = rows.min(), zone_top
    ys_fit, dx_fit = [], []
    cols = np.arange(w)
    mids = []
    for y in range(int(top + 0.45 * (bottom - top)), bottom):
        xs = cols[body[y]]
        if xs.size:
            mids.append((xs.min() + xs.max()) / 2)
    cx = float(np.median(mids))
    for y in range(int(top + 0.45 * (bottom - top)), bottom):
        xs = cols[body[y]]
        if xs.size:
            for x in (xs.min(), xs.max()):
                ys_fit.append(y)
                dx_fit.append((x - cx) ** 2)
    ys_fit = np.array(ys_fit, float)
    m = np.stack([np.array(dx_fit), ys_fit ** 2, ys_fit], 1)
    (pp, qq, rr), *_ = np.linalg.lstsq(m, np.ones(len(ys_fit)), rcond=None)
    cy = -rr / (2 * qq)
    k = 1 + qq * cy * cy
    rx, ry = np.sqrt(k / pp), np.sqrt(k / qq)
    yy, xx = np.mgrid[0:h, 0:w]
    ellipse = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 0.97
    # The painted contact crease (the darkest row per column under the
    # middle of the body) is where body and feet meet the floor; everything
    # below it is shadow. Fit a smooth curve through it so darker flank fur
    # does not notch the silhouette.
    smooth_lum = nd.gaussian_filter(lum, 1.5)
    crease = zone_top + np.argmin(smooth_lum[zone_top:], axis=0)
    zone_h = h - zone_top
    centre = np.abs(cols - cx) < 0.7 * rx
    low = crease > zone_top + 0.25 * min(zone_h, ground_bottom - zone_top)
    pick = centre & low
    coef = np.polyfit(cols[pick], crease[pick], 2)
    crease_fit = np.polyval(coef, cols)
    above = yy <= crease_fit[None, :] + 3
    textured = zone & ellipse & above & (dist > 12)

    hard = nd.binary_closing(solid | textured, structure=disk(3))
    hard = nd.binary_fill_holes(hard)
    labels, n = nd.label(hard)
    if n > 1:
        sizes = nd.sum(hard, labels, range(1, n + 1))
        hard = labels == (1 + int(np.argmax(sizes)))
    hard = nd.binary_opening(hard, structure=disk(1))
    hard = nd.binary_fill_holes(hard)

    # Soft fur wisps just outside the hard silhouette (not in the ground
    # zone, where they would pick up the shadow).
    band = nd.binary_dilation(hard, structure=disk(7)) & ~hard & ~zone
    wisp = smoothstep(9, 34, dist) * band
    edge = nd.gaussian_filter(hard.astype(float), 0.9)
    alpha = np.clip(np.maximum(edge, wisp), 0, 1)
    alpha[nd.binary_erosion(hard, structure=disk(2))] = 1

    # Decontaminate: remove the background contribution, then pull weak
    # pixels toward the nearest solid color.
    a = np.maximum(alpha, 1e-3)[..., None]
    unmixed = np.clip(bg + (rgb - bg) / a, 0, 255)
    core = nd.binary_erosion(hard, structure=disk(3))
    _, (iy, ix) = nd.distance_transform_edt(~core, return_indices=True)
    nearest = nd.gaussian_filter(rgb, (2, 2, 0))[iy, ix]
    trust = smoothstep(0.35, 0.9, alpha)[..., None]
    color = np.where(core[..., None], rgb, trust * unmixed + (1 - trust) * nearest)
    return np.dstack([color, alpha * 255]).clip(0, 255).astype(np.uint8)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("src")
    p.add_argument("dst")
    p.add_argument("--pad", type=int, default=12)
    args = p.parse_args()
    rgb = np.asarray(Image.open(args.src).convert("RGB")).astype(float)
    rgba = key(rgb)
    ys, xs = np.nonzero(rgba[..., 3] > 4)
    pad = args.pad
    y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, rgba.shape[0])
    x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad + 1, rgba.shape[1])
    out = rgba[y0:y1, x0:x1].copy()
    # Zero the color of fully transparent pixels: better compression and no
    # hidden fringe when filtered.
    out[out[..., 3] == 0, :3] = 0
    Image.fromarray(out, "RGBA").save(args.dst, optimize=True)
    print(f"{args.dst}: {out.shape[1]}x{out.shape[0]}, crop {x0},{y0}")


if __name__ == "__main__":
    main()
