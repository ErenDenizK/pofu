"""Tests for tools/assets/koke_sky_check.py (sky left inside a Koke island sprite's cut)."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import koke_sky_check as ksc  # noqa: E402


def take() -> tuple[np.ndarray, np.ndarray]:
    """A 160 x 120 take: a smooth warm-to-lavender sky with a textured green disc (the island)."""
    h, w = 120, 160
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    sky = np.stack([250 - xx * 0.1, 230 + yy * 0.05, 215 + xx * 0.15], axis=2)
    island = (xx - 80) ** 2 / 45**2 + (yy - 70) ** 2 / 30**2 < 1
    rng = np.random.default_rng(1)
    green = np.stack([110 + 30 * rng.random((h, w)), 170 + 30 * rng.random((h, w)), 60 + 20 * rng.random((h, w))], axis=2)
    rgb = np.where(island[..., None], green, sky)
    return np.clip(rgb, 0, 255).astype(np.uint8), island


def sprite(rgb: np.ndarray, keep: np.ndarray, box=(20, 30, 140, 110)) -> np.ndarray:
    """The pipeline's sprite: the take with `keep` as alpha, cropped, and recoloured a little."""
    alpha = (keep * 255).astype(np.uint8)
    out = np.dstack([np.clip(rgb.astype(int) - 6, 0, 255).astype(np.uint8), alpha])
    x0, y0, x1, y1 = box
    return out[y0:y1, x0:x1]


class KokeSkyCheckTests(unittest.TestCase):
    def test_a_clean_cut_passes_and_is_found_where_it_was_cut(self):
        rgb, island = take()
        f = ksc.find(rgb, sprite(rgb, island))
        self.assertEqual(f.offset, (20, 30))
        self.assertTrue(f.ok)
        self.assertEqual(f.block, 0)

    def test_a_block_of_sky_kept_beside_the_island_fails(self):
        rgb, island = take()
        keep = island.copy()
        keep[32:60, 40:80] = True  # a stair-step of sky above the disc, joined to it
        f = ksc.find(rgb, sprite(rgb, keep))
        self.assertFalse(f.ok)
        self.assertGreater(f.block, 300)
        x0, y0, x1, y1 = f.box
        self.assertLessEqual(x0, 25)
        self.assertGreaterEqual(x1, 55)

    def test_a_take_twice_the_master_is_found_and_judged_in_master_pixels(self):
        rgb, island = take()
        big = np.repeat(np.repeat(rgb, 2, axis=0), 2, axis=1)
        keep = np.repeat(np.repeat(island, 2, axis=0), 2, axis=1)
        # A take large enough for the coarse-to-fine search.
        big = np.pad(big, ((0, 160), (0, 160), (0, 0)), mode="edge")
        keep = np.pad(keep, ((0, 160), (0, 160)))
        f = ksc.find(big, sprite(big, keep, box=(40, 60, 280, 220)), scale=2.0)
        self.assertEqual(f.offset, (40, 60))
        self.assertEqual(f.max_block, 4 * ksc.MAX_BLOCK)
        self.assertTrue(f.ok)
        self.assertEqual(f.block, 0)

    def test_pale_paint_inside_the_island_is_not_sky(self):
        rgb, island = take()
        rgb[65:75, 70:90] = rgb[5, 5]  # a sky-coloured stone in the lawn, not joined to the outside
        f = ksc.find(rgb, sprite(rgb, island))
        self.assertEqual(f.block, 0)


if __name__ == "__main__":
    unittest.main()
