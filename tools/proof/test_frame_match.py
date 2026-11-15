"""Tests of frame_match.py. Run: python3 -I -m unittest discover -s tools/proof -p "test_*.py" """
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import frame_match as fm  # noqa: E402


def gradient(shift: float = 0.0) -> np.ndarray:
    ys = np.linspace(0, 1, fm.M.H, dtype=np.float32)[:, None, None]
    img = np.broadcast_to(np.concatenate([0.3 + 0.5 * ys, 0.5 + 0.3 * ys, 0.9 - 0.4 * ys], axis=2), (fm.M.H, fm.M.W, 3))
    return np.clip(img + shift, 0, 1).astype(np.float32)


class FrameMatch(unittest.TestCase):
    def test_identical_frames_have_zero_rms(self):
        rep = fm.compare(gradient(), gradient())
        self.assertEqual(rep["rms"]["L"], 0.0)
        self.assertEqual(rep["rms"]["S"], 0.0)

    def test_thirteen_bands(self):
        rep = fm.compare(gradient(), gradient(0.1))
        self.assertEqual(len(rep["bands"]), 13)
        self.assertGreater(rep["rms"]["L"], 5.0)

    def test_exit_zero_and_json(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            for n, s in (("a.png", 0.0), ("b.jpg", 0.05)):
                Image.fromarray((gradient(s) * 255).astype(np.uint8)).save(d / n)
            self.assertEqual(fm.main(["--app", str(d / "a.png"), "--target", str(d / "b.jpg"), "--distance", "map", "--out", str(d)]), 0)
            self.assertTrue((d / "frame-match-map.json").exists())


if __name__ == "__main__":
    unittest.main()
