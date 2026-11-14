"""Tests for map_check.py: each measure on synthetic frames, and painted_light.py's file is current."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import map_check as mc  # noqa: E402
import painted_light  # noqa: E402

H, W = 800, 400


def gradient() -> np.ndarray:
    """A smooth sky: blue to pale, no detail."""
    t = np.linspace(0, 1, H)[:, None, None]
    top, bottom = np.array([90, 140, 230]), np.array([200, 215, 245])
    return np.broadcast_to(top + (bottom - top) * t, (H, W, 3)).astype(np.uint8).copy()


def clouds(frame: np.ndarray, rows: slice, seed: int = 1) -> np.ndarray:
    """Soft white puffs over `rows`."""
    rng = np.random.default_rng(seed)
    out = frame.astype(np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    for _ in range(40):
        cy = rng.uniform(rows.start, rows.stop)
        cx, r = rng.uniform(0, W), rng.uniform(8, 25)
        a = np.clip(1 - np.hypot(yy - cy, xx - cx) / r, 0, 1)[..., None] ** 0.5
        out = out * (1 - a) + 250 * a
    return out.astype(np.uint8)


def island(frame: np.ndarray, box: tuple[int, int, int, int], colour) -> np.ndarray:
    out = frame.copy()
    x0, y0, x1, y1 = box
    yy, xx = np.mgrid[0:H, 0:W]
    cx, cy, rx, ry = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2 - 4, (y1 - y0) / 2 - 4
    inside = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1
    out[inside] = colour
    return out


class MapCheckTests(unittest.TestCase):
    def test_a_flat_top_band_fails_and_clouds_pass(self):
        self.assertFalse(mc.check_flat_top(gradient())["ok"])
        self.assertTrue(mc.check_flat_top(clouds(gradient(), slice(0, 200)))["ok"])

    def test_a_day_lit_island_at_night_is_the_outlier(self):
        sky = (gradient() * 0.4).astype(np.uint8)
        boxes = {"home": (40, 300, 160, 380), "koke": (220, 300, 340, 380), "cag": (130, 500, 250, 580)}
        f = island(island(island(sky, boxes["home"], (70, 80, 90)), boxes["koke"], (75, 82, 88)), boxes["cag"], (72, 79, 92))
        masks = {k: mc.island_mask(f, b) for k, b in boxes.items()}
        self.assertTrue(mc.check_night_islands(f, masks)["ok"])
        lit = island(f, boxes["koke"], (170, 190, 140))
        masks = {k: mc.island_mask(lit, b) for k, b in boxes.items()}
        r = mc.check_night_islands(lit, masks)
        self.assertFalse(r["ok"])
        self.assertGreater(r["off"]["koke"], 0.18)

    def test_a_light_ring_round_an_island_is_found(self):
        box = (100, 300, 300, 420)
        f = island(gradient(), box, (120, 150, 80))
        mask = mc.island_mask(f, box)
        self.assertTrue(mc.check_light_ring(f, mask)["ok"])
        ringed = f.copy()
        import cv2
        k = np.ones((7, 7), np.uint8)
        ring = (cv2.dilate(mask.astype(np.uint8), k) > 0) & ~mask
        ringed[ring] = (250, 250, 250)
        self.assertFalse(mc.check_light_ring(ringed, mask)["ok"])

    def test_a_straight_vertical_cut_in_the_sky_is_found(self):
        f = clouds(gradient(), slice(100, 700))
        self.assertTrue(mc.check_sky_edges(f)["ok"])
        cut = f.copy()
        cut[200:500, 300:] = (60, 100, 200)
        r = mc.check_sky_edges(cut)
        self.assertFalse(r["ok"])
        self.assertTrue(296 <= r["column"] <= 302, r)


class PaintedLightTests(unittest.TestCase):
    def test_the_shipped_file_is_current(self):
        self.assertEqual(painted_light.main(["--check"]), 0)


if __name__ == "__main__":
    unittest.main()
