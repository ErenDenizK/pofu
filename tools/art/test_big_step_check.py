"""Tests for big_step_check. Run: python3 -I -m unittest discover -s tools/art -p "test_*.py" """
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import big_step_check as bs  # noqa: E402

N = 400


def stall() -> np.ndarray:
    """A counter with an awning: a box 120 wide and 100 tall, standing on the ground line."""
    m = np.zeros((N, N), bool)
    m[200:300, 140:260] = True
    return m


class CutoutSteps(unittest.TestCase):
    def test_a_pot_on_the_counter_is_a_touch(self) -> None:
        b = stall()
        b[190:200, 180:200] = True  # a flower pot on top: inside the reach of the old outline
        r = bs.cutout_step(stall(), b)
        self.assertEqual(r["verdict"], "TOUCH")
        self.assertFalse(r["B1"])

    def test_a_fringe_all_round_is_a_touch(self) -> None:
        b = bs._dilate(stall(), 6)  # flowers at the foot and a thicker edge: more area, no new mass
        self.assertEqual(bs.cutout_step(stall(), b)["verdict"], "TOUCH")

    def test_a_second_storey_is_big(self) -> None:
        b = stall()
        b[140:200, 150:250] = True  # a storey on top: 60 % taller
        r = bs.cutout_step(stall(), b)
        self.assertEqual(r["verdict"], "BIG")
        self.assertTrue(r["B1"] and r["B2"] and r["B3"])

    def test_a_yard_beside_it_is_big(self) -> None:
        b = stall()
        b[250:300, 260:340] = True  # tables on a terrace beside it
        self.assertEqual(bs.cutout_step(stall(), b)["verdict"], "BIG")

    def test_a_redrawn_edge_is_not_counted(self) -> None:
        b = np.roll(stall(), 1, axis=1)  # the edit moved the shape by one px
        r = bs.cutout_step(stall(), b)
        self.assertEqual(r["outside"], 0.0)
        self.assertEqual(r["verdict"], "TOUCH")

    def test_sizes_must_match(self) -> None:
        with self.assertRaises(ValueError):
            bs.cutout_step(stall(), np.zeros((N, N + 1), bool))


class PlateSteps(unittest.TestCase):
    def setUp(self) -> None:
        self.grey = np.full((N, N, 3), 0.55)

    def test_a_few_lights_is_a_touch(self) -> None:
        b = self.grey.copy()
        b[100:120, 100:120] = [1.0, 0.9, 0.5]
        self.assertEqual(bs.plate_step(self.grey, b)["verdict"], "TOUCH")

    def test_moss_over_a_third_is_big(self) -> None:
        b = self.grey.copy()
        b[:, : N // 3] = [0.45, 0.70, 0.25]
        r = bs.plate_step(self.grey, b)
        self.assertEqual(r["verdict"], "BIG")
        self.assertGreater(r["changed"], 0.28)

    def test_grain_is_not_change(self) -> None:
        rng = np.random.default_rng(1)
        b = np.clip(self.grey + rng.normal(0, 0.03, self.grey.shape), 0, 1)
        self.assertEqual(bs.plate_step(self.grey, b)["changed"], 0.0)

    def test_the_mask_limits_the_area(self) -> None:
        b = self.grey.copy()
        b[:, : N // 2] = [0.2, 0.3, 0.9]  # the sky half changed, the island half did not
        mask = np.zeros((N, N), bool)
        mask[:, N // 2 + 20 :] = True
        self.assertEqual(bs.plate_step(self.grey, b, mask)["changed"], 0.0)


if __name__ == "__main__":
    unittest.main()
