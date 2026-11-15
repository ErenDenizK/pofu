"""Tests for matte_check (M1 to M6 and M11). Run: python3 -I -m unittest discover -s tools/art -p "test_*.py" """
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import matte_check as mc  # noqa: E402

N = 512
SKY = np.float32([0.55, 0.72, 0.95])
EARTH = np.float32([0.45, 0.33, 0.22])


def source() -> np.ndarray:
    """A sky that is the same blue everywhere, with a brown body low in the picture."""
    img = np.empty((N, N, 3), np.float32)
    img[:] = SKY
    img[300:420, 140:372] = EARTH
    return img


def layer(alpha: np.ndarray, src: np.ndarray) -> np.ndarray:
    return np.dstack([src, alpha.astype(np.float32)])


def soft_disc(cx=256, cy=256, r=120, width=2.0) -> np.ndarray:
    y, x = np.mgrid[0:N, 0:N].astype(np.float32)
    d = np.hypot(x - cx, y - cy)
    return np.clip((r - d) / width + 0.5, 0, 1)


class MatteCheck(unittest.TestCase):
    def test_hard_rectangle_fails_m1(self):
        a = np.zeros((N, N), np.float32)
        a[:, 100:400] = 1.0                       # runs off the top and the bottom of the layer
        r = mc.check_matte(layer(a, source()), source=source())
        self.assertFalse(r["M1"]["pass"])
        self.assertFalse(r["pass"])

    def test_one_bit_edge_fails_the_m2_floor(self):
        a = np.zeros((N, N), np.float32)
        a[100:400, 100:400] = 1.0                 # inside the layer, but the edge is one bit wide
        r = mc.check_matte(layer(a, source()), source=source())
        self.assertTrue(r["M1"]["pass"])
        self.assertFalse(r["M2"]["pass"])
        self.assertLess(r["M2"]["p05"], mc.LIMITS["M2_MIN"])

    def test_sky_band_under_the_body_fails_m11(self):
        src = source()
        a = soft_disc(256, 200, 100)
        a[300:340, 150:360] = np.maximum(a[300:340, 150:360], 1.0)
        # the kept band is sky-coloured and touches the outside: the matte kept haze
        rgba = layer(a, src)
        rgba[300:340, 150:360, :3] = SKY
        r = mc.check_matte(rgba, source=src)
        self.assertFalse(r["M11"]["pass"])
        self.assertGreater(r["M11"]["value"], 0)

    def test_soft_disc_passes_m1_to_m6(self):
        src = source()
        r = mc.check_matte(layer(soft_disc(width=2.0), np.where(soft_disc()[..., None] > 0, EARTH, SKY).astype(np.float32)), source=src)
        for k in ("M1", "M2", "M3", "M4", "M5", "M6"):
            self.assertTrue(r[k]["pass"], f"{k}: {r[k]}")


if __name__ == "__main__":
    unittest.main()
