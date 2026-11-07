"""Look lab: depth, region masks and normals for a painted frame.

Two depth sources, compared in experiment 2:

  monocular   Depth Anything V2 small (ONNX, CPU, ~1 s per frame). Relative inverse depth
              (larger = nearer), normalised to 0..1. The weights are not in the repo: download
              `onnx/model.onnx` of `onnx-community/depth-anything-v2-small` from Hugging Face
              and pass its path with `--depth-model` or `LOOKLAB_DEPTH_MODEL`.
  layered     what the game itself knows, no model: the sky and cloud sea are far, the plate's
              lawn is a plane tilted toward the camera (nearer lower on screen), its earth face
              is a vertical wall at the lawn's front lip, and each sprite stands at its foot's
              depth with a dome from its alpha distance (`normals.height_map`).

Normals come from the depth's screen gradient (OpenGL: x right, y up, z toward the viewer).
"""
from __future__ import annotations

import os
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

import lab

_SESSION = None


def model_path(explicit: str | None = None) -> Path | None:
    p = explicit or os.environ.get("LOOKLAB_DEPTH_MODEL")
    return Path(p) if p and Path(p).exists() else None


def monocular(rgb: np.ndarray, model: Path) -> np.ndarray:
    """Depth Anything V2 small on CPU: 0..1, larger is nearer, at the frame's size."""
    global _SESSION
    import onnxruntime as ort  # optional dependency, only for this path
    if _SESSION is None or _SESSION[0] != str(model):
        so = ort.SessionOptions()
        so.intra_op_num_threads = 4
        _SESSION = (str(model), ort.InferenceSession(str(model), so, providers=["CPUExecutionProvider"]))
    sess = _SESSION[1]
    h, w = rgb.shape[:2]
    s = 518 / min(w, h)
    W, H = int(round(w * s / 14)) * 14, int(round(h * s / 14)) * 14
    x = np.asarray(lab.to_img(rgb).resize((W, H), Image.Resampling.BICUBIC), np.float32) / 255
    x = (x - np.array([0.485, 0.456, 0.406], np.float32)) / np.array([0.229, 0.224, 0.225], np.float32)
    d = sess.run(None, {sess.get_inputs()[0].name: x.transpose(2, 0, 1)[None].astype(np.float32)})[0][0]
    d = np.asarray(Image.fromarray(d.astype(np.float32)).resize((w, h), Image.Resampling.BILINEAR), np.float64)
    lo, hi = np.percentile(d, 1), np.percentile(d, 99.5)
    return np.clip((d - lo) / max(hi - lo, 1e-6), 0, 1)


def masks_from_depth(d: np.ndarray, near: float = 0.45, soft: float = 0.01) -> dict[str, np.ndarray]:
    """Soft sky / island / sea masks: the island is what is near; the rest splits at its centre."""
    h, w = d.shape
    island = lab.smoothstep(near - 0.08, near + 0.08, d)
    island = ndimage.binary_opening(island > 0.5, iterations=2)
    lbl, n = ndimage.label(island)
    if n:
        sizes = ndimage.sum(island, lbl, range(1, n + 1))
        island = lbl == (1 + int(np.argmax(sizes)))
        island = ndimage.binary_fill_holes(island)
    ys = np.nonzero(island)[0]
    cy = ys.mean() if len(ys) else h / 2
    yy = np.mgrid[0:h, 0:w][0]
    s = max(h * soft, 1)
    isl = ndimage.gaussian_filter(island.astype(float), s)
    below = lab.smoothstep(cy - 2 * s, cy + 2 * s, yy.astype(float))
    return {"sky": (1 - isl) * (1 - below), "island": isl, "sea": (1 - isl) * below}


def normals(depth: np.ndarray, scale: float = 40.0, blur: float = 1.5) -> np.ndarray:
    """Screen normals from a depth map (larger = nearer), unit vectors (h, w, 3)."""
    d = ndimage.gaussian_filter(depth, blur) * scale
    gx = ndimage.sobel(d, axis=1) / 8
    gy = ndimage.sobel(d, axis=0) / 8
    n = np.stack([-gx, gy, np.ones_like(d)], axis=-1)  # nearer-to-the-right faces left; image y is down
    return n / np.linalg.norm(n, axis=-1, keepdims=True)
