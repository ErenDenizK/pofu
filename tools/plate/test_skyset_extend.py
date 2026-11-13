"""Tests for skyset_extend: the sky set past the master (Çağlayan)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import skyset_extend as se  # noqa: E402


def _tile(h: int = 64, paint: int = 200, bridge: int = 48) -> np.ndarray:
    rng = np.random.default_rng(1)
    arr = np.zeros((h, paint + bridge, 4), np.float32)
    arr[:, :paint, :3] = rng.uniform(0.2, 0.9, (h, paint, 3))
    arr[:, :paint, 3] = 1
    arr[:, paint:] = rng.uniform(0, 1, (h, bridge, 4))           # a quilted bridge: anything
    return arr


class MirrorBridge(unittest.TestCase):
    def test_bridge_runs_on_from_both_edges_and_painting_is_kept(self):
        arr = _tile()
        out = se.mirror_bridge(arr, 200, blend=16)
        np.testing.assert_array_equal(out[:, :200], arr[:, :200])
        np.testing.assert_allclose(out[:, 200], arr[:, 199], atol=1e-5)    # the right edge, mirrored
        np.testing.assert_allclose(out[:, -1], arr[:, 0], atol=1e-5)       # the wrap meets column 0's mirror


class Hidden(unittest.TestCase):
    def test_fill_hidden_takes_the_sea_below_and_keeps_alpha(self):
        arr = np.zeros((100, 20, 4), np.float32)
        arr[..., 3] = 0.7
        arr[:30, :, 0] = 0.1                         # murk behind the island
        arr[30:, :, 0] = 0.9                         # visible cumulus
        hidden = np.zeros((100, 20), np.float32)
        hidden[:20] = 1
        out = se.fill_hidden(arr, (0, 0), hidden, gap=10)
        self.assertGreater(out[5, 10, 0], 0.8)
        np.testing.assert_array_equal(out[..., 3], arr[..., 3])

    def test_clear_hidden_fades_alpha_only_behind_the_island(self):
        arr = np.ones((80, 80, 4), np.float32)
        hidden = np.zeros((80, 80), np.float32)
        hidden[:, :40] = 1
        out = se.clear_hidden(arr, (0, 0), hidden, soft=3)
        self.assertLess(out[40, 5, 3], 0.05)
        self.assertGreater(out[40, 75, 3], 0.95)


class TopClouds(unittest.TestCase):
    def test_clouds_fill_the_new_rows_without_touching_and_rows_below_are_kept(self):
        arr = np.zeros((300, 600, 4), np.float32)
        yy, xx = np.mgrid[0:300, 0:600]
        for cx, cy in ((120, 200), (400, 220)):
            d = np.hypot((xx - cx) / 60, (yy - cy) / 25)
            arr[..., 3] = np.maximum(arr[..., 3], np.clip(1.5 - d, 0, 1))
        arr[..., :3] = 0.8
        out, pos = se.top_clouds(arr, (0, 20), -380, 600, top_clear=40, cover=0.05, scale=(1.0, 1.0))
        self.assertEqual(pos, (0, -380))
        self.assertEqual(out.shape[0], 300 + 400)
        self.assertGreater(out[:400, :, 3].sum(), 0.04 * 400 * 600)
        np.testing.assert_allclose(out[400:, :, 3], arr[..., 3], atol=1e-5)

    def test_extend_rows_never_repeats_a_row_unflipped(self):
        f = np.zeros((10, 16, 1), np.float32)
        f[3, 2] = 1
        out = se.extend_rows(f, 25)
        self.assertEqual(out.shape, (25, 16, 1))
        self.assertEqual(out[15 + 3, 13, 0], 1)          # the nearest rows: flipped left to right
        self.assertEqual(out[15 + 3, 2, 0], 0)


if __name__ == "__main__":
    unittest.main()
