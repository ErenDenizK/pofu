#!/usr/bin/env python3
"""Offline AI upscaler for painted plates (Real-ESRGAN family, ONNX, CPU).

    python3 -I tools/plate/upscale.py IN OUT --scale 2 [--model general-x4v3|anime6b]

Runs a x4 Real-ESRGAN ONNX model tile by tile (bounded memory), then Lanczos-resamples to the
requested scale,
then pins low-frequency colour to the Lanczos result (no tone drift). Alpha is upscaled separately with Lanczos. Weights are downloaded once to
~/.cache/pofu-upscale/ (override: POFU_UPSCALE_CACHE) from a pinned URL and checked against a
pinned sha256; they are never committed. Licence notes: tools/plate/README.md.
"""
import argparse
import hashlib
import os
import sys
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image

MODELS = {
    "anime6b": dict(
        url="https://huggingface.co/RekluzLabs/realesrgan_anime6b.onnx/resolve/main/realesrgan_anime6b.onnx",
        sha256="45bd54934aeabe8df744c8fdacb9e8846c9b55cb4e60c499db77405d1625a667"),
    "general-x4v3": dict(
        url="https://huggingface.co/Heliosoph/realesrgan-onnx/resolve/main/realesr-general-x4v3.onnx",
        sha256="09b757accd747d7e423c1d352b3e8f23e77cc5742d04bae958d4eb8082b76fa4"),
}
NATIVE = 4


def cache_dir():
    return Path(os.environ.get("POFU_UPSCALE_CACHE", Path.home() / ".cache" / "pofu-upscale"))


def _sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def model_path(name, download=True):
    spec = MODELS[name]
    p = cache_dir() / f"{name}.onnx"
    if p.exists() and _sha(p) == spec["sha256"]:
        return p
    if not download:
        return None
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(".part")
    urllib.request.urlretrieve(spec["url"], tmp)
    if _sha(tmp) != spec["sha256"]:
        tmp.unlink()
        raise RuntimeError(f"sha256 mismatch for {name}")
    tmp.replace(p)
    return p


def session(name, threads=0, download=True):
    import onnxruntime as ort
    path = model_path(name, download)
    if path is None:
        raise FileNotFoundError(name)
    so = ort.SessionOptions()
    if threads:
        so.intra_op_num_threads = threads
    return ort.InferenceSession(str(path), so, providers=["CPUExecutionProvider"])


def upscale_rgb(rgb, sess, tile=256, pad=16):
    """rgb: HxWx3 uint8 -> (H*4)x(W*4)x3 uint8. Overlapping tiles, cropped to the core."""
    h, w, _ = rgb.shape
    x = np.asarray(rgb, np.float32).transpose(2, 0, 1)[None] / 255.0
    inp = sess.get_inputs()[0].name
    out = np.zeros((3, h * NATIVE, w * NATIVE), np.float32)
    for y0 in range(0, h, tile):
        for x0 in range(0, w, tile):
            y1, x1 = min(y0 + tile, h), min(x0 + tile, w)
            ya, xa = max(y0 - pad, 0), max(x0 - pad, 0)
            yb, xb = min(y1 + pad, h), min(x1 + pad, w)
            # reflect-pad at the image border so edge tiles see context, not a hard cut
            patch = x[:, :, ya:yb, xa:xb]
            r = sess.run(None, {inp: np.ascontiguousarray(patch)})[0][0]
            out[:, y0 * NATIVE:y1 * NATIVE, x0 * NATIVE:x1 * NATIVE] = \
                r[:, (y0 - ya) * NATIVE:(y1 - ya) * NATIVE, (x0 - xa) * NATIVE:(x1 - xa) * NATIVE]
    return (np.clip(out, 0, 1).transpose(1, 2, 0) * 255.0 + 0.5).astype(np.uint8)


def match_colour(big, ref, sigma):
    """Keep the model's detail but pin its low frequencies (colour, tone) to the Lanczos result."""
    from scipy.ndimage import gaussian_filter
    a = np.asarray(big, np.float32)
    b = np.asarray(ref, np.float32)
    corr = np.stack([gaussian_filter(b[..., c], sigma) - gaussian_filter(a[..., c], sigma)
                     for c in range(3)], -1)
    return Image.fromarray(np.clip(a + corr + 0.5, 0, 255).astype(np.uint8))


def upscale_image(im, scale=2, model="general-x4v3", sess=None, tile=256, pad=16, match=True):
    sess = sess or session(model)
    size = (round(im.width * scale), round(im.height * scale))
    alpha = im.getchannel("A") if im.mode in ("RGBA", "LA") else None
    rgb = im.convert("RGB")
    big = Image.fromarray(upscale_rgb(np.asarray(rgb), sess, tile, pad))
    if big.size != size:
        big = big.resize(size, Image.LANCZOS)
    if match:
        big = match_colour(big, rgb.resize(size, Image.LANCZOS), sigma=2.0 * max(scale, 1))
    if alpha is not None:
        big.putalpha(alpha.resize(size, Image.LANCZOS))
    return big


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--scale", type=float, default=2.0)
    ap.add_argument("--model", default="general-x4v3", choices=sorted(MODELS))
    ap.add_argument("--tile", type=int, default=256)
    ap.add_argument("--no-match", action="store_true", help="skip the low-frequency colour match")
    args = ap.parse_args(argv)
    im = Image.open(args.input)
    im.load()
    out = upscale_image(im, args.scale, args.model, tile=args.tile, match=not args.no_match)
    out.save(args.output)
    print(f"{args.input} {im.size} -> {args.output} {out.size} ({args.model})")


if __name__ == "__main__":
    sys.exit(main())
