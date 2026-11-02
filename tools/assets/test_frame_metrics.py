"""Tests for tools/assets/frame_metrics.py (grade measurements of rendered frames)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import frame_metrics as fm  # noqa: E402


def frame(values: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(values, 0, 255)), "L").convert("RGB")


class FrameMetricsTests(unittest.TestCase):
    def test_a_washed_out_frame_has_less_range_and_local_contrast(self):
        rng = np.random.default_rng(3)
        texture = rng.normal(0, 1, (400, 200))
        crisp = frame(128 + 60 * texture)
        washed = frame(150 + 20 * texture)
        a, b = fm.measure(crisp), fm.measure(washed)
        self.assertGreater(a["range"], b["range"] * 2)
        self.assertGreater(a["local"], b["local"] * 2)
        self.assertLess(a["p2"], b["p2"])

    def test_bands_come_from_the_file_name(self):
        self.assertEqual(fm.band_for("grade-night-home"), "home")
        self.assertEqual(fm.band_for("look-4-hd2d-night-island"), "island")
        self.assertEqual(fm.band_for("motion-3"), "frame")

    def test_targets_flag_a_lifted_night(self):
        targets = __import__("json").loads(fm.TARGETS.read_text())
        self.assertEqual(fm.grade_of("grade-night-home", targets), "night")
        self.assertEqual(fm.grade_of("grade-unwell-island", targets), "unwell")
        day = {"mean": 80, "p2": 52, "p98": 97, "range": 45, "local": 5.0, "chroma": 33}
        lifted = {"mean": 40, "p2": 22, "p98": 53, "range": 31, "local": 3.3, "chroma": 8}
        deep = {"mean": 30, "p2": 5, "p98": 48, "range": 43, "local": 4.2, "chroma": 12}
        self.assertTrue(fm.check(lifted, targets["grades"]["night"], day))
        self.assertEqual(fm.check(deep, targets["grades"]["night"], day), [])


if __name__ == "__main__":
    unittest.main()
