"""Tiny synthetic checks for upscale.py; skipped without onnxruntime or the cached model.
Run: python3 -I tools/plate/test_upscale.py"""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import numpy as np
from PIL import Image

import upscale

try:
    import onnxruntime  # noqa: F401
    HAVE = upscale.model_path("general-x4v3", download=False) is not None
except ImportError:
    HAVE = False


@unittest.skipUnless(HAVE, "onnxruntime or model weights unavailable")
class UpscaleTest(unittest.TestCase):
    def setUp(self):
        yy, xx = np.mgrid[0:48, 0:56]
        a = np.stack([xx * 4, yy * 5, (xx + yy) * 2], -1).astype(np.uint8)
        a[10:30, 12:40] = (220, 180, 60)
        self.im = Image.fromarray(a)

    def test_blend_is_between_lanczos_and_the_model(self):
        sess = upscale.session("general-x4v3")
        blend = np.asarray(upscale.blend_image(self.im, 2, 0.8, sess=sess), np.float32)
        lan = np.asarray(self.im.resize((112, 96), Image.LANCZOS), np.float32)
        full = np.asarray(upscale.upscale_image(self.im, 2, sess=sess), np.float32)
        self.assertEqual(blend.shape, full.shape)
        self.assertLess(np.abs(blend - full).mean(), np.abs(lan - full).mean())

    def test_size_and_alpha(self):
        rgba = self.im.convert("RGBA")
        rgba.putalpha(Image.linear_gradient("L").resize(rgba.size))
        out = upscale.upscale_image(rgba, 2, tile=32, pad=8)
        self.assertEqual(out.size, (112, 96))
        self.assertEqual(out.mode, "RGBA")

    def test_tile_independence_and_colour(self):
        a = np.asarray(upscale.upscale_image(self.im, 2, tile=24, pad=16), float)
        b = np.asarray(upscale.upscale_image(self.im, 2, tile=64, pad=16), float)
        self.assertLess(np.abs(a - b).mean(), 2.0)  # no visible tile seams
        ref = np.asarray(self.im.resize((112, 96), Image.LANCZOS), float)
        self.assertLess(np.abs(a.mean((0, 1)) - ref.mean((0, 1))).max(), 3.0)


if __name__ == "__main__":
    unittest.main()
