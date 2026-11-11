"""Tests for screen_check.py: the measures on synthetic frames, and a synthetic split end to end."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import screen_check as sc  # noqa: E402
import split  # noqa: E402
import test_split as ts  # noqa: E402

SCREEN = (120, 262)


class MeasureTests(unittest.TestCase):
    def test_a_line_is_flagged_and_a_step_edge_is_not(self):
        f = np.full((40, 40, 3), 200.0)
        f[:, 20:] = 60.0                                  # a plain edge
        ring = np.ones((40, 40), bool)
        self.assertFalse(sc.line_pixels(f, ring, 8.0)[2:-2, 2:-2].any())
        f[:, 10] = 255.0                                  # a one pixel line
        self.assertTrue(sc.line_pixels(f, ring, 8.0)[5:-5, 10].all())

    def test_ring_surrounds_the_partial_alpha(self):
        a = np.zeros((50, 50), np.float32)
        a[15:35, 15:35] = 1
        a[14, 15:35] = 0.5
        ring = sc.ring_mask(a, 3)
        self.assertTrue(ring[14, 20] and ring[12, 20] and ring[17, 20])
        self.assertFalse(ring[25, 25] or ring[2, 2])

    def test_dead_run(self):
        flat = np.full((100, 60, 3), 120.0)
        self.assertEqual(sc.longest_dead_run(flat, 0.0025), 1.0)
        busy = flat.copy()
        busy[::4] = 250.0
        self.assertLess(sc.longest_dead_run(busy, 0.0025), 0.1)

    def test_life_needs_a_moving_sky_and_a_still_island(self):
        a = np.zeros((60, 60, 3))
        b = a.copy()
        b[:20] += 30
        isl = np.zeros((60, 60), np.float32)
        isl[30:, :] = 1
        th = sc.THRESHOLDS["life"]
        self.assertTrue(sc.check_life(a, b, isl, th)["ok"])
        self.assertFalse(sc.check_life(a, a, isl, th)["ok"])
        c = b.copy()
        c[40:50] += 5                                     # the island moved
        self.assertFalse(sc.check_life(a, c, isl, th)["ok"])

    def test_block_edges_are_found_and_soft_clouds_are_not(self):
        f = np.full((120, 120, 3), 200.0)
        f[:, 60:] = 170.0                                  # a straight step, over 3 dE
        region = np.ones((120, 120), bool)
        self.assertTrue(sc.block_pixels(f, region, 3.0, 40).any())
        soft = np.repeat(np.linspace(150, 230, 120)[None, :, None], 120, 0).repeat(3, 2)
        self.assertFalse(sc.block_pixels(soft, region, 3.0, 40).any())

    def test_island_hued_pixels_in_a_cloud_layer_are_a_leak(self):
        rgba = np.zeros((20, 20, 4), np.float32)
        rgba[..., :3] = 0.95
        rgba[..., 3] = 1
        s = {"layers": {"far": {"rgba": rgba.copy()}}}
        self.assertTrue(sc.check_leaks(s, {"max_px": 5})["ok"])
        s["layers"]["far"]["rgba"][5:15, 5:15, :3] = (0.3, 0.7, 0.2)   # a green lawn bit
        self.assertFalse(sc.check_leaks(s, {"max_px": 5})["ok"])

    def test_resolution(self):
        th = sc.THRESHOLDS["resolution"]
        self.assertTrue(sc.check_resolution({"k": 1.4}, th)["ok"])
        self.assertFalse(sc.check_resolution({"k": 0.5}, th)["ok"])


class SyntheticSetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        p, m = ts.synthetic()
        res = split.split_plate(p, ts.HAND, mattes={"island": m, "sprites": {}}, log=lambda *_: None)
        cls.man = split.write_set(res, ts.HAND, "day", Path(cls.tmp.name), "x.heic")
        cls.p = p * 255
        cls.set = sc.load_set(Path(cls.tmp.name))
        cls.fr = sc.framing(cls.set["manifest"], {"homeWidths": 1.15, "homeCenterX": 0.47, "homeTopY": 40}, SCREEN)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_frame_zero_matches_the_master(self):
        f0 = sc.compose(self.set, 0, self.fr)
        master = sc.master_frame(self.set, self.p, self.fr)
        r = sc.check_identity(f0["rgb"], master, f0["covered"], {"mean_de": 1.5, "p99_de": 9.0})
        self.assertTrue(r["ok"], r)

    def test_drift_moves_clouds_not_the_island(self):
        f0, f2 = sc.compose(self.set, 0, self.fr), sc.compose(self.set, 120, self.fr)
        diff = np.abs(f2["rgb"] - f0["rgb"]).mean(-1)
        self.assertGreater(float(diff.mean()), 0.0)
        import cv2
        solid = cv2.erode((f0["island_alpha"] > 0.99).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
        self.assertLess(float(diff[solid].max()), 0.5)

    def test_seam_check_runs(self):
        frames = {t: sc.compose(self.set, t, self.fr)["rgb"] for t in (0, 30)}
        r = sc.check_seam(frames, sc.compose(self.set, 0, self.fr)["island_alpha"], sc.THRESHOLDS["seam"])
        self.assertIn("ring_px", r)
        self.assertGreater(r["ring_px"], 0)


if __name__ == "__main__":
    unittest.main()
