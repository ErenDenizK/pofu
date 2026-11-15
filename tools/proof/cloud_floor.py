"""One tall, seamless cloud floor for the Home sky set (proof 3), made by quilting from the painting's own clouds.

The shipped sea tile (`world-home-sky-sea-<light>-0`) ends 1289 px (about 2150 master rows) down. A pull-out shows
what lies below Home, so the floor must go on for several screens. The first proof mirrored the tile's clean band, which
draws a horizontal band every 520 master rows. This quilts instead (`inpaint.quilt`: blocks of the visible cumulus
rows, each the best match of what is already there, one of the best ten at random, feathered, wrapped in x so the drift
tile stays seamless): the sea down to `KEEP` is the painting itself, everything below it is new rows of the same
clouds, never mirrored. `floor(rows)` returns straight RGBA at the tile's own resolution; the result is cached.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import ROOT, load_rgba  # noqa: E402

sys.path.insert(0, str(ROOT / "tools" / "plate"))
import inpaint  # noqa: E402


SRC_TOP, KEEP = 560, 940          # tile rows: the clean cumulus band the quilt copies from; where the painting ends
BLOCK, OVERLAP = 128, 40
CACHE = Path(os.environ.get("POFU_MATTE_CACHE", Path(__file__).resolve().parent / "__pycache__" / "matte"))


def floor(rows: int = 2200, light: str = "day", seed: int = 3) -> np.ndarray:
    return _seam(_close(_quilt(rows, light, seed), seed))


def _close(a: np.ndarray, seed: int, seam: int = 220) -> np.ndarray:
    """The quilt wraps in x only through the blocks it copies, so the new rows meet themselves across the tile's edge
    with a vertical seam. Close it as the sky split does for every layer (`split.close_wrap`): the last `seam` columns
    of the new rows ease into the mirror of the first ones."""
    import split
    out = a.copy()
    rgb, al = split.close_wrap(out[KEEP:, :, :3], out[KEEP:, :, 3], seam, seed)
    out[KEEP:, :, :3], out[KEEP:, :, 3] = rgb, al
    return out


def _seam(a: np.ndarray, rows: int = 18, sigma: float = 7.0) -> np.ndarray:
    """Where the painting ends and the new rows begin, a faint line runs across: blur the few rows round it along y."""
    import cv2
    out = a.copy()
    y0, y1 = KEEP - rows, KEEP + rows
    blur = cv2.GaussianBlur(out[y0 - 40:y1 + 40], (0, 0), sigmaX=0.01, sigmaY=sigma)[40:-40]
    t = np.linspace(-1, 1, y1 - y0, dtype=np.float32)
    w = np.cos(t * np.pi / 2)[:, None, None] ** 2
    out[y0:y1] = out[y0:y1] * (1 - w) + blur * w
    return out


def _quilt(rows: int, light: str, seed: int) -> np.ndarray:
    f = CACHE / f"cloudfloor-{light}-{rows}-{seed}.npy"
    if f.exists():
        return np.load(f)
    sea = load_rgba(f"world-home-sky-sea-{light}-0")
    pre = sea.copy()
    pre[..., :3] *= pre[..., 3:4]
    src = pre[SRC_TOP:KEEP]
    ext = np.concatenate([src, np.zeros((rows, src.shape[1], 4), np.float32)], 0)
    hole = np.zeros(ext.shape[:2], bool)
    hole[src.shape[0]:] = True
    fill = inpaint.quilt(ext, hole, periodic_x=True, y_window=4000, block=BLOCK, overlap=OVERLAP, topk=10, seed=seed)
    out = np.concatenate([pre[:SRC_TOP], fill], 0)
    a = out[..., 3:4].clip(0, 1)
    rgb = np.where(a > 1e-3, out[..., :3] / np.maximum(a, 1e-3), 0).clip(0, 1)
    res = np.concatenate([rgb, a], -1).astype(np.float32)
    CACHE.mkdir(parents=True, exist_ok=True)
    np.save(f, res)
    return res


if __name__ == "__main__":
    import time
    from PIL import Image
    t = time.time()
    r = floor(int(sys.argv[2]) if len(sys.argv) > 2 else 1900)
    print(r.shape, "%.0fs" % (time.time() - t))
    bg = np.empty(r.shape[:2] + (3,), np.float32)
    bg[:] = (0.4, 0.6, 0.95)
    im = r[..., :3] * r[..., 3:] + bg * (1 - r[..., 3:])
    Image.fromarray((im * 255 + 0.5).astype(np.uint8)).save(sys.argv[1])
