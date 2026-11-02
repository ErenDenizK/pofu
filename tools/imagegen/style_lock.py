#!/usr/bin/env python3
"""Style lock: pull a generated image toward Pofu's look, measurably.

The art-direction study (docs/design/art-direction-study.md) found that
generated props drift away from R1 in three measurable ways: they are
darker (lower lightness floor), far more saturated (chroma), and carry more
fine detail at display size (hammered copper, wood grain, specular glints).
The style lock fixes those three things and nothing else. It never invents
shape; anything structural (camera, proportions, silhouette) is fixed in
the prompt and by regeneration.

Each step works in CIELAB on straight (unpremultiplied) color, and filters
are alpha-aware: transparent pixels are first filled with nearby opaque
color so nothing dark bleeds into the edges.

Presets live in ``style_lock.json`` next to this file:

    lock-light  the default: bakes only the floor, detail, hue fixes and edges;
                saturation and contrast are graded at runtime (WorldGrade)
    soft-lock   the default until 2026-11-02 (hybrid of A and a light B)
    harmonize   study treatment A: grade and clamp only
    gouache     study treatment B: strong simplification and value steps
    storybook   study treatment C: flat color blocks and a soft outline

Usage:

    python3 -I tools/imagegen/style_lock.py apply --preset lock-light IN.png OUT.png
    python3 -I tools/imagegen/style_lock.py measure IN.png [IN2.png ...]

Dependencies: numpy and Pillow only.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
PRESETS_PATH = HERE / "style_lock.json"

# ---------------------------------------------------------------------------
# Color science (sRGB D65 <-> CIELAB), vectorized
# ---------------------------------------------------------------------------

_M = np.array([[0.4124564, 0.3575761, 0.1804375],
               [0.2126729, 0.7151522, 0.0721750],
               [0.0193339, 0.1191920, 0.9503041]])
_M_INV = np.linalg.inv(_M)
_WHITE = np.array([0.95047, 1.0, 1.08883])


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    rgb = np.asarray(rgb, dtype=np.float64)
    lin = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    xyz = lin @ _M.T / _WHITE
    eps, kappa = 216 / 24389, 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (kappa * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


def lab_to_srgb(lab: np.ndarray) -> np.ndarray:
    fy = (lab[..., 0] + 16) / 116
    fx = fy + lab[..., 1] / 500
    fz = fy - lab[..., 2] / 200
    eps, kappa = 216 / 24389, 24389 / 27
    f = np.stack([fx, fy, fz], axis=-1)
    xyz = np.where(f ** 3 > eps, f ** 3, (116 * f - 16) / kappa)
    xyz[..., 1] = np.where(lab[..., 0] > kappa * eps, fy ** 3, lab[..., 0] / kappa)
    lin = (xyz * _WHITE) @ _M_INV.T
    lin = np.clip(lin, 0, 1)
    return np.where(lin <= 0.0031308, 12.92 * lin, 1.055 * np.power(lin, 1 / 2.4) - 0.055)


def lch(lab: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    return lab[..., 0], np.hypot(lab[..., 1], lab[..., 2]), np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360


def from_lch(L: np.ndarray, C: np.ndarray, H: np.ndarray) -> np.ndarray:
    h = np.radians(H)
    return np.stack([L, C * np.cos(h), C * np.sin(h)], axis=-1)


# ---------------------------------------------------------------------------
# Filters (numpy only)
# ---------------------------------------------------------------------------

def box(img: np.ndarray, r: int) -> np.ndarray:
    """Mean over a (2r+1)^2 window, edges clamped. Works on 2D or 3D arrays."""
    if r <= 0:
        return img.copy()
    pad = [(r + 1, r), (r + 1, r)] + [(0, 0)] * (img.ndim - 2)
    p = np.pad(img, pad, mode="edge")
    c = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    s = c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]
    return s / (k * k)


def bleed(rgb: np.ndarray, alpha: np.ndarray, levels: int = 7) -> np.ndarray:
    """Fill transparent areas with nearby opaque color (push-pull style).

    Filters then see plausible color outside the silhouette instead of
    whatever the transparent pixels happen to hold (often black).
    """
    w = (alpha > 0.5).astype(np.float64)
    out = rgb.copy()
    filled = w.copy()
    r = 2
    for _ in range(levels):
        num = box(rgb * w[..., None], r)
        den = box(w, r)[..., None]
        est = num / np.maximum(den, 1e-6)
        take = (filled < 0.5) & (den[..., 0] > 1e-4)
        out[take] = est[take]
        filled = np.maximum(filled, take.astype(np.float64))
        r *= 2
        if filled.min() >= 0.5:
            break
    return out


def guided_smooth(rgb: np.ndarray, r: int, eps: float) -> np.ndarray:
    """Edge-preserving smoothing (He et al. guided filter, gray guide)."""
    guide = rgb @ np.array([0.299, 0.587, 0.114])
    mean_i = box(guide, r)
    var_i = box(guide * guide, r) - mean_i ** 2
    out = np.empty_like(rgb)
    for ch in range(rgb.shape[-1]):
        p = rgb[..., ch]
        mean_p = box(p, r)
        cov = box(guide * p, r) - mean_i * mean_p
        a = cov / (var_i + eps)
        b = mean_p - a * mean_i
        out[..., ch] = box(a, r) * guide + box(b, r)
    return out


def kuwahara(rgb: np.ndarray, r: int) -> np.ndarray:
    """Classic four-quadrant Kuwahara filter: flat, painterly patches."""
    if r <= 0:
        return rgb.copy()
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    half = r // 2
    mean_c = box(rgb, half)
    mean_l = box(lum, half)
    var_l = box(lum * lum, half) - mean_l ** 2
    h, w = lum.shape
    best_var = np.full((h, w), np.inf)
    out = np.zeros_like(rgb)
    for dy in (-half, half):
        for dx in (-half, half):
            v = _shift(var_l, dy, dx)
            m = _shift(mean_c, dy, dx)
            pick = v < best_var
            best_var = np.where(pick, v, best_var)
            out[pick] = m[pick]
    return out


def _shift(a: np.ndarray, dy: int, dx: int) -> np.ndarray:
    pad = [(abs(dy), abs(dy)), (abs(dx), abs(dx))] + [(0, 0)] * (a.ndim - 2)
    p = np.pad(a, pad, mode="edge")
    h, w = a.shape[:2]
    y0, x0 = abs(dy) + dy, abs(dx) + dx
    return p[y0:y0 + h, x0:x0 + w]


def gaussian_blur(a: np.ndarray, sigma: float) -> np.ndarray:
    """Three box passes approximate a Gaussian."""
    if sigma <= 0.3:
        return a.copy()
    r = max(1, int(round(sigma * 0.9)))
    out = a
    for _ in range(3):
        out = box(out, r)
    return out


def value_noise(h: int, w: int, cell: float, seed: int) -> np.ndarray:
    """Smooth value noise in -1...1 (bilinear interpolation of a random grid)."""
    rng = np.random.default_rng(seed)
    gh, gw = int(h / cell) + 2, int(w / cell) + 2
    grid = rng.uniform(-1, 1, (gh, gw)).astype(np.float32)
    img = Image.fromarray(grid, mode="F").resize((int(gw * cell), int(gh * cell)), Image.Resampling.BICUBIC)
    return np.asarray(img, dtype=np.float64)[:h, :w]


# ---------------------------------------------------------------------------
# Tone and color operators
# ---------------------------------------------------------------------------

def soft_ceiling(x: np.ndarray, knee: float, ceiling: float) -> np.ndarray:
    """Identity below the knee, then a smooth roll-off that never passes the ceiling."""
    if ceiling <= knee:
        return np.minimum(x, ceiling)
    span = ceiling - knee
    d = np.maximum(x - knee, 0)
    # Rational roll-off: keeps the ordering (and so the modulation) of
    # strong colors instead of piling them up at the ceiling.
    return np.where(x <= knee, x, knee + d / (1 + d / span))


def hue_weight(H: np.ndarray, center: float, width: float) -> np.ndarray:
    d = np.abs((H - center + 180) % 360 - 180)
    return np.clip(1 - d / max(width, 1e-6), 0, 1) ** 2 * (3 - 2 * np.clip(1 - d / max(width, 1e-6), 0, 1))


def clamp_chroma(L: np.ndarray, C: np.ndarray, H: np.ndarray, p: dict) -> tuple[np.ndarray, np.ndarray]:
    """Soft chroma ceiling, tighter inside hue bands; a band may also turn
    its hues (for example tea red toward honey amber, so a desaturated red
    reads as amber instead of salmon pink)."""
    C = C * p.get("scale", 1.0)
    out = soft_ceiling(C, p["knee"], p["ceiling"])
    H = H.copy()
    for band in p.get("hue_bands", []):
        wgt = hue_weight(H, band["hue"], band["width"])
        banded = soft_ceiling(C, band["knee"], band["ceiling"])
        out = out * (1 - wgt) + np.minimum(out, banded) * wgt
        if band.get("hue_shift"):
            H = (H + band["hue_shift"] * wgt) % 360
    return out, H


def soft_floor(x: np.ndarray, floor: float, knee: float) -> np.ndarray:
    """Identity above the knee, then a smooth toe that never drops below the floor."""
    return -soft_ceiling(-x, -knee, -floor)


def lift_values(L: np.ndarray, p: dict) -> np.ndarray:
    """Raise the floor and compress contrast toward a high, soft key.

    With `floor_knee` the floor is a toe instead of a linear lift: values
    above the knee keep their contrast exactly (lock-light).
    """
    if "floor_knee" in p:
        out = soft_floor(L, p.get("floor", 0.0), p["floor_knee"])
        return soft_ceiling(out, p.get("highlight_knee", 100.0), p.get("highlight_ceiling", 100.0))
    floor, gamma = p.get("floor", 0.0), p.get("gamma", 1.0)
    t = np.clip(L / 100, 0, 1) ** gamma
    out = floor + (100 - floor) * t
    contrast = p.get("contrast", 1.0)
    pivot = p.get("pivot", 70.0)
    out = pivot + (out - pivot) * contrast
    return soft_ceiling(out, p.get("highlight_knee", 100.0), p.get("highlight_ceiling", 100.0))


def posterize_soft(x: np.ndarray, steps: int, lo: float, hi: float, softness: float) -> np.ndarray:
    """Quantize x into `steps` bands with smooth (not aliased) transitions."""
    t = np.clip((x - lo) / (hi - lo), 0, 1) * (steps - 1)
    base = np.floor(t)
    frac = t - base
    s = np.clip((frac - 0.5) / max(softness, 1e-3) + 0.5, 0, 1)
    s = s * s * (3 - 2 * s)
    return lo + (base + s) / (steps - 1) * (hi - lo)


def kmeans_lab(lab: np.ndarray, k: int, iters: int = 12, seed: int = 3) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    pts = lab.reshape(-1, 3)
    sample = pts[rng.choice(len(pts), min(len(pts), 20000), replace=False)]
    # k-means++ seeding on the sample
    centers = [sample[rng.integers(len(sample))]]
    for _ in range(1, k):
        d = np.min(((sample[:, None] - np.array(centers)[None]) ** 2).sum(-1), axis=1)
        centers.append(sample[rng.choice(len(sample), p=d / d.sum())])
    centers = np.array(centers)
    for _ in range(iters):
        lab_d = ((sample[:, None] - centers[None]) ** 2).sum(-1)
        lbl = lab_d.argmin(1)
        for j in range(k):
            if (lbl == j).any():
                centers[j] = sample[lbl == j].mean(0)
    labels = np.empty(len(pts), dtype=np.int32)
    for s in range(0, len(pts), 200000):
        labels[s:s + 200000] = ((pts[s:s + 200000, None] - centers[None]) ** 2).sum(-1).argmin(1)
    return centers, labels.reshape(lab.shape[:-1])


# ---------------------------------------------------------------------------
# The style lock
# ---------------------------------------------------------------------------

@dataclass
class LockResult:
    rgba: np.ndarray  # float 0..1
    preset: str
    params: dict


def load_presets(path: Path = PRESETS_PATH) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))["presets"]


def apply_lock(rgba: np.ndarray, params: dict, seed: int = 11) -> np.ndarray:
    """Apply one preset's parameters to a float RGBA image (0...1)."""
    rgba = rgba.astype(np.float64).copy()
    h, w = rgba.shape[:2]
    scale = max(h, w) / 1024.0  # parameters are specified for a 1024 px canvas
    alpha = rgba[..., 3]
    # GPT Image PNGs that went through a quantizer often top out at alpha
    # 250-254 inside the object; treat those as fully opaque.
    snap = params.get("alpha_snap", 0.97)
    alpha = np.where(alpha >= snap, 1.0, alpha)
    rgb = bleed(rgba[..., :3], alpha)

    # 1. Detail budget: split into a smooth base and a detail layer, keep
    #    only part of the detail (kills micro-texture and specular glints
    #    without blurring silhouettes or material borders).
    d = params.get("detail")
    if d:
        r = max(1, int(round(d["radius"] * scale)))
        base = guided_smooth(rgb, r, d["eps"])
        if d.get("kuwahara", 0):
            base = kuwahara(base, max(2, int(round(d["kuwahara"] * scale))))
        rgb = np.clip(base + d["keep"] * (rgb - base), 0, 1)

    lab = srgb_to_lab(rgb)
    L, C, H = lch(lab)

    # 2. Values: a high, soft key like R1's.
    if "values" in params:
        L = lift_values(L, params["values"])

    # 3. Optional value steps (gouache) or flat blocks (storybook).
    if "posterize" in params:
        p = params["posterize"]
        L = posterize_soft(L, p["steps"], p.get("lo", 30), p.get("hi", 98), p.get("softness", 0.25))
    # 4. Chroma: soft ceiling, tighter for greens (the lawn) and reds.
    if "chroma" in params:
        C, H = clamp_chroma(L, C, H, params["chroma"])

    # 5. Light: one warm key from the upper left over the object's box.
    if "light" in params:
        lp = params["light"]
        ys, xs = np.nonzero(alpha > 0.5)
        if len(ys):
            y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
            yy, xx = np.mgrid[0:h, 0:w]
            u = np.clip((xx - x0) / max(1, x1 - x0), 0, 1)
            v = np.clip((yy - y0) / max(1, y1 - y0), 0, 1)
            g = 0.5 - 0.5 * (u * 0.6 + v * 0.4) * 2  # +0.5 upper left ... -0.5 lower right
            L = L + lp.get("amount", 0.0) * g
            warm = lp.get("warmth", 0.0)
            lab_tmp = from_lch(L, C, H)
            lab_tmp[..., 2] += warm * (0.5 + g)  # warm (orange, not lemon) toward the key
            lab_tmp[..., 1] += warm * 0.6 * (0.5 + g)
            L, C, H = lch(lab_tmp)

    lab = from_lch(np.clip(L, 0, 100), C, H)

    # 6. Storybook: snap to a few flat colors, then add a soft colored outline.
    if "flat" in params:
        fp = params["flat"]
        solid = alpha > 0.5
        centers, labels = kmeans_lab(lab[solid][:, None, :], fp["colors"], seed=seed)
        flat = lab.copy()
        flat[solid] = centers[labels[:, 0]]
        lab = flat

    rgb = lab_to_srgb(lab)

    if "flat" in params and params["flat"].get("smooth", 0):
        rgb = guided_smooth(rgb, max(1, int(round(params["flat"]["smooth"] * scale))), 0.0004)

    # 7. Surface: an optional shared grain (off in the recommendation).
    g = params.get("grain")
    if g and g.get("amount", 0) > 0:
        n = value_noise(h, w, g.get("cell", 2.0) * scale, seed) * 0.6 + value_noise(h, w, g.get("cell", 2.0) * 6 * scale, seed + 1) * 0.4
        rgb = np.clip(rgb + g["amount"] * n[..., None], 0, 1)

    # 8. Edges: soften the cut-out a touch (R1's edge is soft fur, props
    #    come back razor sharp) and optionally draw a soft colored outline.
    e = params.get("edge", {})
    if e.get("outline_px", 0) > 0:
        rpx = e["outline_px"] * scale
        grown = gaussian_blur(alpha, rpx * 0.6)
        ring = np.clip((grown - alpha) * 3, 0, 1)
        dark = srgb_to_lab(bleed(rgb, alpha))
        dark[..., 0] *= e.get("outline_value", 0.55)
        ring_rgb = lab_to_srgb(dark)
        ring_rgb = bleed(ring_rgb, alpha)
        ring_rgb = gaussian_blur(ring_rgb, rpx)
        new_alpha = np.clip(alpha + ring * e.get("outline_opacity", 0.9), 0, 1)
        mix = (alpha / np.maximum(new_alpha, 1e-6))[..., None]
        rgb = rgb * mix + ring_rgb * (1 - mix)
        alpha = new_alpha
    if e.get("feather_px", 0) > 0:
        # Soften inward only (min with a blurred copy): no halo grows outside.
        alpha = np.clip(np.minimum(alpha, gaussian_blur(alpha, e["feather_px"] * scale)), 0, 1)
    out = np.dstack([rgb, alpha])
    out[alpha <= 1 / 255] = 0.0
    return out


# ---------------------------------------------------------------------------
# Measurement (also used by QA)
# ---------------------------------------------------------------------------

def measure(rgba: np.ndarray, display_px: int = 390) -> dict:
    """Value, chroma and detail statistics of the opaque part of an image.

    `detail` is the mean absolute Laplacian of luminance (x100) after the
    object is scaled so its longer side is `display_px`: detail as the eye
    sees it on the phone, not at 1024 px. R1 scores about 5.3.
    """
    alpha = rgba[..., 3]
    solid = alpha > 0.9
    if not solid.any():
        return {"error": "no opaque pixels"}
    L, C, _ = lch(srgb_to_lab(rgba[..., :3][solid]))
    ys, xs = np.nonzero(alpha > 0.03)
    crop = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    im = Image.fromarray(np.clip(np.round(crop * 255), 0, 255).astype(np.uint8), "RGBA")
    s = display_px / max(im.size)
    im = im.resize((max(3, int(im.size[0] * s)), max(3, int(im.size[1] * s))), Image.Resampling.LANCZOS)
    g = np.asarray(im.convert("L"), dtype=np.float64) / 255
    am = np.asarray(im)[..., 3] > 240
    lap = np.abs(4 * g[1:-1, 1:-1] - g[:-2, 1:-1] - g[2:, 1:-1] - g[1:-1, :-2] - g[1:-1, 2:])
    m = am[1:-1, 1:-1]
    detail = float(lap[m].mean() * 100) if m.any() else 0.0
    pct = lambda a, q: round(float(np.percentile(a, q)), 1)
    return {
        "L_p5": pct(L, 5), "L_p50": pct(L, 50), "L_p95": pct(L, 95),
        "C_p50": pct(C, 50), "C_p95": pct(C, 95), "C_p99": pct(C, 99),
        "detail": round(detail, 2),
    }


def load_rgba(path: Path) -> np.ndarray:
    with Image.open(path) as im:
        return np.asarray(im.convert("RGBA"), dtype=np.float64) / 255.0


def save_rgba(rgba: np.ndarray, path: Path) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA").save(path, optimize=True)


def preset_for(kind: str, presets: dict, override: str | None = None) -> tuple[str, dict]:
    """The preset name and parameters to use for an asset kind."""
    name = override or presets.get("_by_kind", {}).get(kind) or "lock-light"
    return name, presets[name]


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("apply", help="apply a preset to one image")
    a.add_argument("--preset", default="lock-light")
    a.add_argument("--presets", default=str(PRESETS_PATH))
    a.add_argument("src")
    a.add_argument("dst")
    m = sub.add_parser("measure", help="print value, chroma and detail statistics")
    m.add_argument("files", nargs="+")
    args = ap.parse_args(argv)
    if args.cmd == "apply":
        presets = load_presets(Path(args.presets))
        out = apply_lock(load_rgba(Path(args.src)), presets[args.preset])
        save_rgba(out, Path(args.dst))
        print(json.dumps({"preset": args.preset, "before": measure(load_rgba(Path(args.src))), "after": measure(out)}))
        return 0
    for f in args.files:
        print(f, json.dumps(measure(load_rgba(Path(f)))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
