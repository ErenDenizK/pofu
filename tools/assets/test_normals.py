"""Tests for the normal-map baker (tools/assets/normals.py).

Run:  python3 -I -m unittest discover -s tools/assets -p "test_normals.py"
"""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import normals as nm  # noqa: E402


class HeightToNormal(unittest.TestCase):
    def test_flat_height_is_the_flat_normal(self):
        n = nm.height_to_normal(np.zeros((8, 8)))
        self.assertTrue(np.allclose(n, [0, 0, 1]))

    def test_slope_rising_to_the_right_leans_left(self):
        # Height grows with x: the surface faces -x (toward the left).
        h = np.tile(np.arange(8, dtype=float), (8, 1)) * 0.1
        n = nm.height_to_normal(h, strength=1.0)[4, 4]
        self.assertLess(n[0], 0)
        self.assertAlmostEqual(n[1], 0, places=6)
        self.assertGreater(n[2], 0)

    def test_slope_rising_downward_leans_up(self):
        # Rows run downward; height growing with the row faces up (+y).
        h = np.tile(np.arange(8, dtype=float)[:, None], (1, 8)) * 0.1
        n = nm.height_to_normal(h, strength=1.0)[4, 4]
        self.assertGreater(n[1], 0)
        self.assertAlmostEqual(n[0], 0, places=6)

    def test_normals_are_unit_length(self):
        rng = np.random.default_rng(1)
        n = nm.height_to_normal(rng.random((16, 16)), strength=3.0)
        self.assertTrue(np.allclose(np.linalg.norm(n, axis=-1), 1.0))

    def test_encode_decode_round_trip(self):
        n = nm.height_to_normal(np.random.default_rng(2).random((12, 12)))
        back = nm.decode(nm.encode(n))
        self.assertLess(np.abs(back - n).max(), 0.02)


class Dome(unittest.TestCase):
    def setUp(self):
        self.alpha = np.zeros((64, 64))
        yy, xx = np.mgrid[:64, :64]
        self.alpha[(xx - 32) ** 2 + (yy - 32) ** 2 < 24**2] = 1.0
        self.rgb = np.full((64, 64, 3), 0.6)

    def test_height_is_zero_outside_and_peaks_inside(self):
        h = nm.height_map(self.rgb, self.alpha, detail=0)
        self.assertEqual(h[0, 0], 0)
        self.assertGreater(h[32, 32], h[32, 10])
        self.assertGreater(h[32, 10], 0)

    def test_rim_faces_outward(self):
        h = nm.height_map(self.rgb, self.alpha, detail=0)
        n = nm.height_to_normal(h)
        # Left rim leans left (-x), right rim right (+x), top rim up (+y).
        self.assertLess(n[32, 9, 0], -0.2)
        self.assertGreater(n[32, 55, 0], 0.2)
        self.assertGreater(n[9, 32, 1], 0.2)
        self.assertLess(n[55, 32, 1], -0.2)

    def test_centre_is_nearly_flat(self):
        n = nm.height_to_normal(nm.height_map(self.rgb, self.alpha, detail=0))
        self.assertGreater(n[32, 32, 2], 0.9)

    def test_luminance_detail_changes_the_surface(self):
        rgb = self.rgb.copy()
        rgb[30:34, 20:44] = 0.1  # a dark painted stroke
        flat = nm.height_map(self.rgb, self.alpha, detail=0)
        etched = nm.height_map(rgb, self.alpha, detail=0.3)
        self.assertGreater(np.abs(etched - flat).max(), 0.01)


class Bake(unittest.TestCase):
    def test_bake_writes_an_opaque_map_with_a_flat_border(self):
        with tempfile.TemporaryDirectory() as tmp:
            src, out = Path(tmp) / "s.png", Path(tmp) / "n.png"
            arr = np.zeros((40, 60, 4), dtype=np.uint8)
            arr[8:32, 10:50] = [200, 150, 90, 255]
            Image.fromarray(arr, "RGBA").save(src)
            nm.bake(src, out, scale=0.5)
            im = np.asarray(Image.open(out))
            self.assertEqual(im.shape, (20, 30, 4))
            self.assertTrue((im[..., 3] == 255).all())
            self.assertTrue((im[0, 0, :3] == [128, 128, 255]).all())
            self.assertTrue((im[10, 0, :3] == [128, 128, 255]).all())


if __name__ == "__main__":
    unittest.main()
