"""HEIC with alpha for shipped plate layers (ADR-0024): plates, islands and occluders.

Quality 70, pillow-heif (`pip install -r tools/plate/requirements.txt`). Missing, it fails loudly:
a plate must never silently ship as a 5 MB PNG. Backdrops stay JPEG (no alpha).
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

QUALITY = 70
SUFFIX = ".heic"


def require() -> None:
    try:
        import pillow_heif  # noqa: F401
    except ImportError as e:
        raise SystemExit(
            f"pillow-heif is missing ({e!r}): plate layers ship as HEIC (ADR-0024).\n"
            "pip install -r tools/plate/requirements.txt") from e


def register() -> None:
    """Teach Pillow to read and write HEIC."""
    require()
    import pillow_heif
    pillow_heif.register_heif_opener()


def save(img: Image.Image, path: Path, quality: int = QUALITY) -> None:
    register()
    img.convert("RGBA").save(path, format="HEIF", quality=quality)


def open_image(path: Path) -> Image.Image:
    """Any image the tools read, HEIC included; for a shipped layer give the stem and it picks
    `.heic` over `.png`."""
    path = Path(path)
    if path.suffix == ".png" and not path.exists() and path.with_suffix(SUFFIX).exists():
        path = path.with_suffix(SUFFIX)
    if path.suffix == SUFFIX:
        register()
    return Image.open(path)


# ---------------------------------------------------------------- measure

def _lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    xyz = lin @ np.array([[0.4124564, 0.2126729, 0.0193339],
                          [0.3575761, 0.7151522, 0.1191920],
                          [0.1804375, 0.0721750, 0.9503041]]) / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def delta_e2000(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """CIEDE2000 between two sRGB (0-255) arrays of the same shape, per pixel."""
    l1, a1, b1 = np.moveaxis(_lab(a.astype(np.float64)), -1, 0)
    l2, a2, b2 = np.moveaxis(_lab(b.astype(np.float64)), -1, 0)
    c1, c2 = np.hypot(a1, b1), np.hypot(a2, b2)
    g = 0.5 * (1 - np.sqrt((((c1 + c2) / 2) ** 7) / (((c1 + c2) / 2) ** 7 + 25.0 ** 7)))
    a1p, a2p = a1 * (1 + g), a2 * (1 + g)
    c1p, c2p = np.hypot(a1p, b1), np.hypot(a2p, b2)
    h1p = np.degrees(np.arctan2(b1, a1p)) % 360
    h2p = np.degrees(np.arctan2(b2, a2p)) % 360
    dl, dc = l2 - l1, c2p - c1p
    dh = h2p - h1p
    dh = np.where(dh > 180, dh - 360, np.where(dh < -180, dh + 360, dh))
    dh = np.where(c1p * c2p == 0, 0, dh)
    dH = 2 * np.sqrt(c1p * c2p) * np.sin(np.radians(dh) / 2)
    lm, cm = (l1 + l2) / 2, (c1p + c2p) / 2
    hs = h1p + h2p
    hm = np.where(np.abs(h1p - h2p) > 180, (hs + 360) / 2, hs / 2)
    hm = np.where(c1p * c2p == 0, hs, hm)
    t = (1 - 0.17 * np.cos(np.radians(hm - 30)) + 0.24 * np.cos(np.radians(2 * hm))
         + 0.32 * np.cos(np.radians(3 * hm + 6)) - 0.20 * np.cos(np.radians(4 * hm - 63)))
    sl = 1 + 0.015 * (lm - 50) ** 2 / np.sqrt(20 + (lm - 50) ** 2)
    sc, sh = 1 + 0.045 * cm, 1 + 0.015 * cm * t
    rt = (-2 * np.sqrt(cm ** 7 / (cm ** 7 + 25.0 ** 7))
          * np.sin(np.radians(60 * np.exp(-(((hm - 275) / 25) ** 2)))))
    return np.sqrt((dl / sl) ** 2 + (dc / sc) ** 2 + (dH / sh) ** 2 + rt * (dc / sc) * (dH / sh))


def p95_vs_source(src: Image.Image, other: Image.Image, background: int = 128) -> float:
    """ΔE2000 p95 of `other` against `src`, both RGBA composited on a flat grey, over the pixels
    the source paints (alpha > 2%): what the player sees."""
    s, o = np.asarray(src.convert("RGBA"), np.float64), np.asarray(other.convert("RGBA"), np.float64)
    if s.shape != o.shape:
        raise ValueError(f"size differs: {s.shape} vs {o.shape}")
    def over(x):
        al = x[..., 3:4] / 255
        return x[..., :3] * al + background * (1 - al)
    seen = s[..., 3] > 5
    if not seen.any():
        return 0.0
    return float(np.percentile(delta_e2000(over(s), over(o))[seen], 95))
