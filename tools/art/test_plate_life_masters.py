"""Tests for plate_life_masters. Run: python3 -I -m unittest discover -s tools/art -p "test_*.py" """
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import plate_life_masters as plm  # noqa: E402


def canvas() -> np.ndarray:
    return np.zeros((200, 200, 4), np.uint8)


def disc(a: np.ndarray, cx: int, cy: int, r: int, rgb=(200, 120, 80)) -> None:
    ys, xs = np.mgrid[0 : a.shape[0], 0 : a.shape[1]]
    m = (xs - cx) ** 2 + (ys - cy) ** 2 <= r * r
    a[m] = (*rgb, 255)


class EditTests(unittest.TestCase):
    def test_erase_strokes_removes_small_shapes_and_keeps_the_body(self):
        a = canvas()
        disc(a, 100, 100, 50)
        disc(a, 20, 30, 5)  # a stroke, apart from the body
        out = np.array(plm.erase_strokes(Image.fromarray(a, "RGBA")))
        self.assertEqual(out[30, 20, 3], 0)
        self.assertEqual(out[100, 100, 3], 255)
        self.assertEqual(int((out[..., 3] > 0).sum()), int((a[100 - 50 : 100 + 51, :, 3] > 0).sum()))

    def test_soften_droplets_leaves_soft_dots(self):
        a = canvas()
        disc(a, 100, 100, 50)
        disc(a, 20, 30, 6, rgb=(230, 245, 250))
        out = np.array(plm.soften_droplets(Image.fromarray(a, "RGBA")))
        self.assertLess(int(out[30, 20, 3]), 255, "the hard teardrop is gone")
        self.assertGreater(int(out[30, 20, 3]), 100, "a soft dot is left where it was")
        self.assertEqual(out[100, 100, 3], 255)

    def test_left_state_cuts_at_the_gap(self):
        a = canvas()
        disc(a, 40, 100, 30)
        disc(a, 160, 100, 30)
        out = plm.left_state(Image.fromarray(a, "RGBA"))
        self.assertLess(out.width, 130)
        self.assertGreater(out.width, 70)

    def test_the_committed_masters_are_what_the_script_writes(self):
        self.assertEqual(plm.main.__module__, "plate_life_masters")
        for job in plm.JOBS:
            on_disk = plm.MASTERS / job / f"{job}.webp"
            self.assertTrue(on_disk.is_file(), job)
            self.assertTrue(np.array_equal(np.array(Image.open(on_disk).convert("RGBA")), np.array(plm.build(job))), job)


if __name__ == "__main__":
    unittest.main()
