"""Tests for cloud_kit.py on synthetic forms (no repository art)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cloud_kit  # noqa: E402


def blob(size=200, pad=40) -> Image.Image:
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    r = np.hypot(xx - size / 2, yy - size / 2)
    a = np.clip((size / 2 - pad - r) / 10, 0, 1)
    rgba = np.zeros((size, size, 4), np.uint8)
    rgba[..., :3] = 240
    rgba[..., 3] = (a * 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


class CloudKitTests(unittest.TestCase):
    def test_trim_keeps_the_form_with_a_clear_margin(self):
        t = cloud_kit.trim(blob())
        self.assertLess(t.width, 200)
        self.assertEqual(cloud_kit.check_alpha(t), [])

    def test_an_opaque_picture_is_refused(self):
        img = Image.new("RGBA", (100, 100), (255, 255, 255, 255))
        self.assertTrue(cloud_kit.check_alpha(img))

    def test_a_painted_checkerboard_is_found(self):
        img = Image.new("RGBA", (256, 256), (200, 200, 200, 255))
        self.assertTrue(cloud_kit.source_has_checkerboard(img))
        self.assertFalse(cloud_kit.source_has_checkerboard(blob()))

    def test_tile_wraps_without_a_seam(self):
        x = np.arange(512)
        good = np.tile(np.sin(2 * np.pi * x / 512 * 3)[None, :], (64, 1))
        bad = np.tile((x / 512.0)[None, :], (64, 1))
        self.assertLess(cloud_kit.tile_seam(good), 3)
        self.assertGreater(cloud_kit.tile_seam(bad), 100)


if __name__ == "__main__":
    unittest.main()
