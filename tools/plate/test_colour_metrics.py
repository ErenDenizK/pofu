"""Tests for colour_metrics.py on synthetic images only."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import colour_metrics as cm  # noqa: E402


def meta(rgb_a, rgb_b):
    """Left half rgb_a, right half rgb_b, as flat float pixels."""
    h = np.zeros((20, 20, 3))
    h[:, :10] = rgb_a
    h[:, 10:] = rgb_b
    return h.reshape(-1, 3)


class MetricsTests(unittest.TestCase):
    def test_grey_has_no_chroma(self):
        m = cm.metrics(np.full((100, 3), 0.5))
        self.assertLess(m["C"]["p99"], 0.5)
        self.assertEqual(m["accent_share"], 0.0)

    def test_vivid_green_is_accent_and_in_greens(self):
        m = cm.metrics(np.tile([0.1, 0.7, 0.15], (100, 1)))
        self.assertEqual(m["accent_share"], 1.0)
        self.assertEqual(m["greens"]["share"], 1.0)

    def test_pale_and_hot_flags(self):
        ref = cm.metrics(meta([0.2, 0.7, 0.2], [0.95, 0.8, 0.3]))
        pale = cm.metrics(meta([0.7, 0.8, 0.7], [0.9, 0.88, 0.8]))
        hot = cm.metrics(meta([0.0, 1.0, 0.0], [1.0, 0.0, 0.0]))
        self.assertEqual(cm.flags(ref, ref), [])
        self.assertIn("pale", cm.flags(pale, ref))
        self.assertIn("hot", cm.flags(hot, ref))

    def test_cli_measure_with_mask(self):
        with tempfile.TemporaryDirectory() as d:
            img = Image.new("RGB", (40, 40), (30, 180, 40))
            img.save(Path(d) / "i.png")
            mask = Image.new("L", (40, 40), 0)
            mask.paste(255, (0, 0, 20, 40))
            mask.save(Path(d) / "m.png")
            px = cm.load(str(Path(d) / "i.png"), str(Path(d) / "m.png"))
            self.assertAlmostEqual(len(px) / 1600, 0.5, delta=0.05)
            self.assertEqual(cm.main(["measure", str(Path(d) / "i.png")]), 0)
            self.assertEqual(cm.main(["compare", str(Path(d) / "i.png"), str(Path(d) / "i.png")]), 0)


if __name__ == "__main__":
    unittest.main()
