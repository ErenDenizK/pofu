"""Tests for master_edit.py: rain streaks come out, the painting around them stays; the lift raises the sea."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import master_edit as me  # noqa: E402


def clouds(h: int = 200, w: int = 160, seed: int = 1) -> np.ndarray:
    rng = np.random.default_rng(seed)
    base = cv2.GaussianBlur(rng.normal(0, 1, (h, w)).astype(np.float32), (0, 0), 8)
    base = 0.45 + 0.15 * base / np.abs(base).max()
    return np.repeat(base[..., None], 3, 2) * np.array([0.9, 0.88, 1.0], np.float32)


class DerainTests(unittest.TestCase):
    def test_thin_vertical_streaks_are_removed(self):
        img = clouds()
        rain = img.copy()
        for x in (20, 57, 101, 140):
            rain[30:70, x] += 0.06                       # a 1 px light streak, 40 rows long
        out, mask = me.derain(rain)
        for x in (20, 57, 101, 140):
            self.assertTrue(mask[40:60, x].all(), f"streak at {x}")
        self.assertLess(np.abs(out - img)[30:70].max(), 0.02)

    def test_the_painting_without_streaks_is_left_alone(self):
        img = clouds()
        img[100:140, 40:120] += 0.1                      # a broad light cloud: wider than a streak
        out, mask = me.derain(img)
        self.assertLess(mask.mean(), 0.01)
        self.assertLess(np.abs(out - img).max(), 0.02)

    def test_a_short_dot_is_not_a_streak(self):
        img = clouds()
        img[50:53, 80] += 0.08                           # a star or a sparkle: 3 rows
        _, mask = me.derain(img)
        self.assertFalse(mask[51, 80])

    def test_kept_pixels_are_never_touched(self):
        rain = clouds()
        rain[30:70, 57] += 0.06
        keep = np.zeros(rain.shape[:2], bool)
        keep[:, 50:65] = True
        out, mask = me.derain(rain, keep)
        self.assertFalse(mask[keep].any())
        np.testing.assert_array_equal(out[keep], rain[keep])


class LiftTests(unittest.TestCase):
    def test_the_sea_is_lifted_and_its_p95_lands_near_the_target(self):
        img = clouds(seed=4) * 0.8
        out, info = me.lift(img, None, L=8, p95=info_target(img) + 12, from_y=100, ramp=20)
        self.assertAlmostEqual(info["median"][1] - info["median"][0], 8, delta=1.5)
        self.assertAlmostEqual(info["p95"][1], info_target(img) + 12, delta=1.5)
        sky = me.to_lab(out)[:60, :, 0].mean() - me.to_lab(img)[:60, :, 0].mean()
        self.assertLess(abs(sky), 0.5, "sky=0: the rows above the ramp keep their lightness")

    def test_hue_is_kept(self):
        img = clouds(seed=5)
        out, _ = me.lift(img, None, L=8, p95=None, from_y=0, ramp=1)
        a0, a1 = me.to_lab(img), me.to_lab(out)
        h0 = np.degrees(np.arctan2(a0[..., 2], a0[..., 1]))
        h1 = np.degrees(np.arctan2(a1[..., 2], a1[..., 1]))
        self.assertLess(np.median(np.abs(h1 - h0)), 2.0)


class WarmTests(unittest.TestCase):
    def test_only_the_lit_island_is_warmed(self):
        img = np.full((40, 80, 3), 0.85, np.float32)
        img[:, 40:] = 0.35                                # the shade
        island = np.zeros((40, 80), np.float32)
        island[:, 20:60] = 1
        out, _ = me.warm(img, island, a=3, b=3, lo=65, hi=85)
        d = me.to_lab(out) - me.to_lab(img)
        self.assertAlmostEqual(float(d[20, 30, 2]), 3, delta=0.5, msg="lit island")
        self.assertLess(abs(float(d[20, 50, 2])), 0.3, "the shade keeps its colour")
        self.assertLess(abs(float(d[20, 10, 2])), 0.3, "off the island nothing moves")


def info_target(img: np.ndarray) -> float:
    return float(np.percentile(me.to_lab(img)[100:, :, 0], 95))


if __name__ == "__main__":
    unittest.main()
