"""The Home island as a clean alpha layer, cut from each level's own full-size plate (proofs, scripts only).

The shipped Home plate (`world-home-plate-<light>-<stage>`, 2048 x 3072) is a whole painting: its own sky and cloud
sea, with an alpha that is only a feathered border (about 1 % of pixels transparent). Laid over another sky it is a
rectangle. The half-size island cut (`world-home-island-*`, 508 x 396, `ingest.ISLAND_SCALE` 0.5 of the 1024 x 1536
plate points) is that plate's matte box downsampled, with the level-10 matte's alpha, so its edges are right but it is
a quarter of the plate's pixels: too soft for mid and near. This module cuts the island from the full-size plate:

  alpha   the level-10 matte (`ingest.load_matte`, 1024 x 1536) at plate resolution: the island, its underside and
          the cloud the matte took in round it, with its wide soft feather
          x  `map_cut.sky_mask`'s `keep` (the level's own silhouette: the sky the lower level paints where level 10
             has its windmill, lighthouse, hill and harbour islet is removed), up to the plate, edges snapped to
             the plate's own colour by a guided filter
          the rim made whole by `map_cut.solid` (the sky never shows through the island)
          the straight cut at the left and right of the matte's box eased out (`skyset_extend.fade_island_edge`)
          and the lighthouse beam, which the box cuts flat, faded out along its length
  colour  the plate's own pixels

`island_layer(light, stage)` returns straight RGBA at plate texture size, cropped to the matte box, and the box's
top-left in plate points. Deterministic; results are cached under `$POFU_MATTE_CACHE` (default: next to this file's
`__pycache__`) because the sky mask runs GrabCut for a few seconds.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import ROOT, load_rgba  # noqa: E402

sys.path.insert(0, str(ROOT / "tools" / "plate"))
import ingest  # noqa: E402
import map_cut  # noqa: E402
import skyset_extend  # noqa: E402

TEX = 2                                     # plate texture px per plate point
BEAM_X = (1870, 1985)                       # texture px: the beam fades out between these columns
BEAM_Y = (1130, 1340)                       # texture rows of the beam band (the lamp is near 1200)
GUIDE_R, GUIDE_EPS = 6, 2e-3                # guided filter on the keep mask: radius px, regularisation
CACHE = Path(os.environ.get("POFU_MATTE_CACHE", Path(__file__).resolve().parent / "__pycache__" / "matte"))


def _guided(guide: np.ndarray, src: np.ndarray, r: int, eps: float) -> np.ndarray:
    """He's guided filter, grey guide, box windows."""
    k = (2 * r + 1, 2 * r + 1)
    mean = lambda x: cv2.boxFilter(x, -1, k, normalize=True)
    mi, mp = mean(guide), mean(src)
    cov = mean(guide * src) - mi * mp
    var = mean(guide * guide) - mi * mi
    a = cov / (var + eps)
    b = mp - a * mi
    return mean(a) * guide + mean(b)


def island_alpha(light: str, stage: int, plate_rgb: np.ndarray) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """Alpha over the matte's box at texture size, and the box (plate points)."""
    a1 = ingest.load_matte("home", light, stage)
    x0, y0, x1, y1 = ingest.bbox(a1, 0.02)
    w, h = (x1 - x0) * TEX, (y1 - y0) * TEX
    base = cv2.resize(a1[y0:y1, x0:x1].astype(np.float32), (w, h), interpolation=cv2.INTER_CUBIC)
    if stage == 0 and light == "day":
        keep = np.ones((h, w), np.float32)
    else:
        _, k = map_cut.sky_mask(light, stage)
        keep = cv2.resize(k.astype(np.float32), (w, h), interpolation=cv2.INTER_CUBIC)
        grey = cv2.cvtColor(plate_rgb[y0 * TEX:y1 * TEX, x0 * TEX:x1 * TEX], cv2.COLOR_RGB2GRAY)
        keep = np.clip(_guided(grey, np.clip(keep, 0, 1), GUIDE_R, GUIDE_EPS), 0, 1)
        keep = np.clip((keep - 0.15) / 0.7, 0, 1)             # the filter's blur back to a firm edge
    alpha = map_cut.solid(np.clip(base, 0, 1)) * keep
    alpha = cv2.GaussianBlur(alpha.astype(np.float32), (0, 0), 0.8)          # the cut's edge, about a pixel soft
    return alpha.astype(np.float32), (x0, y0, x1, y1)


def island_layer(light: str = "day", stage: int = 0) -> tuple[np.ndarray, tuple[int, int]]:
    CACHE.mkdir(parents=True, exist_ok=True)
    f = CACHE / f"island-{light}-{stage}.npz"
    if f.exists():
        z = np.load(f)
        return z["rgba"].astype(np.float32) / 255, (int(z["x"]), int(z["y"]))
    plate = load_rgba(f"world-home-plate-{light}-{stage}")[..., :3]
    alpha, (x0, y0, x1, y1) = island_alpha(light, stage, plate)
    rgb = plate[y0 * TEX:y1 * TEX, x0 * TEX:x1 * TEX]
    rgba = np.dstack([rgb, alpha])
    rgba = skyset_extend.fade_island_edge(rgba, 140)
    # the lighthouse beam: the level-10 matte leaves it in the sky, so cut it from the plate (how far each pixel
    # is from the sky towards the beam's warm white), and fade it out along its length instead of at the box
    bx, by = x0 * TEX, y0 * TEX
    xa, xb = BEAM_X[0] - bx, BEAM_X[1] - bx
    ya, yb = BEAM_Y[0] - by, BEAM_Y[1] - by
    sky = np.median(plate[BEAM_Y[0] - 90:BEAM_Y[0] - 20, BEAM_X[0]:BEAM_X[1]].reshape(-1, 3), axis=0)
    white = np.array([1.0, 0.99, 0.93], np.float32)
    d = white - sky
    t_ = np.clip(((rgb[ya:yb, xa - 40:] - sky) @ d) / float(d @ d), 0, 1)
    t_ = np.clip((t_ - 0.12) / 0.5, 0, 1)
    gx = np.arange(rgba.shape[1] - (xa - 40), dtype=np.float32) + (xa - 40) + bx
    fb = np.clip((gx - BEAM_X[0]) / (BEAM_X[1] - BEAM_X[0]), 0, 1)
    fb = 1 - fb * fb * (3 - 2 * fb)
    rows = np.arange(yb - ya, dtype=np.float32)
    fb = fb[None, :] * np.clip(np.minimum(rows[:, None] / 30, (yb - ya - 1 - rows[:, None]) / 30), 0, 1)
    beam = (t_ * fb).astype(np.float32)
    sub = rgba[ya:yb, xa - 40:]
    na = np.maximum(sub[..., 3], beam)
    use = beam > sub[..., 3]
    sub[..., :3] = np.where(use[..., None], rgb[ya:yb, xa - 40:], sub[..., :3])
    sub[..., 3] = na
    rgba = np.clip(rgba, 0, 1).astype(np.float32)
    np.savez_compressed(f, rgba=(rgba * 255 + 0.5).astype(np.uint8), x=x0, y=y0)
    return np.round(rgba * 255) / 255, (x0, y0)


if __name__ == "__main__":
    from PIL import Image
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for spec in sys.argv[2:]:
        light, stage = spec.split(":")
        rgba, (x0, y0) = island_layer(light, int(stage))
        bg = np.empty(rgba.shape[:2] + (3,), np.float32)
        bg[:] = (1, 0, 1)
        im = rgba[..., :3] * rgba[..., 3:] + bg * (1 - rgba[..., 3:])
        Image.fromarray((im * 255 + 0.5).astype(np.uint8)).save(out / f"matte-{light}-{stage}-magenta.png")
        print(light, stage, rgba.shape, (x0, y0), "alpha mean %.3f" % rgba[..., 3].mean())
