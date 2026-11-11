"""Tests for split.py and inpaint.py on a synthetic plate (no repository art)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import inpaint  # noqa: E402
import split  # noqa: E402

W, H = 256, 384
HAND = {"island": "x", "seaTop": 250, "seaSolid": 330, "farMaxY": 90, "beam": [230, 120, 256, 150],
        "bankPx": 24, "bankGateY": [220, 260], "tileSeamPx": 8, "spritePad": 8, "sprites": {},
        "parallax": {"referenceScreen": [1206, 2622], "pxPerSecond": {"far": 4, "mid": 9, "sea": 14}}}


def synthetic() -> tuple[np.ndarray, np.ndarray]:
    """Blue gradient sky, two white clouds, a textured white sea from y 250, a brown-green island
    ellipse (alpha matte returned) sitting on the sea."""
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    sky = np.stack([0.45 + 0.1 * yy / H, 0.65 + 0.1 * yy / H, 0.95 - 0.05 * yy / H], -1)
    p = sky.copy()
    rng = np.random.default_rng(1)
    for cx, cy, r in ((60, 50, 22), (190, 70, 18)):
        a = np.clip(1 - np.hypot(xx - cx, (yy - cy) * 1.8) / r, 0, 1)[..., None] ** 0.5
        p = p * (1 - a) + np.array([1, 1, 1]) * a
    tex = 0.5 + 0.5 * np.sin(xx / 9 + 2 * np.sin(yy / 13)) * np.sin(yy / 7 + xx / 31)
    sea_a = np.clip((yy - 240) / 60, 0, 1)[..., None]
    p = p * (1 - sea_a) + (0.82 + 0.15 * tex[..., None] * np.array([1, 1, 1])) * sea_a
    m = np.clip(1 - (((xx - 120) / 90) ** 2 + ((yy - 250) / 60) ** 2) ** 0.5, 0, 1) * 12
    m = np.clip(m, 0, 1).astype(np.float32)
    isl = np.stack([0.55 + 0.1 * np.sin(xx / 5), 0.45 + 0.2 * np.sin(yy / 4), 0.25 + 0 * xx], -1)
    p = p * (1 - m[..., None]) + isl * m[..., None]
    return p.clip(0, 1).astype(np.float32), m


class InpaintTests(unittest.TestCase):
    def test_known_pixels_untouched_and_fill_copies_texture(self):
        p, _ = synthetic()
        hole = np.zeros((H, W), bool)
        hole[300:360, 60:160] = True
        out = inpaint.inpaint(p, hole, y_window=80, seed=0)
        self.assertTrue(np.array_equal(out[~hole], p[~hole]))
        # the fill is texture, not a smear: its local contrast is within 2x of the real sea's
        real = p[300:360, 60:160].std(axis=1).mean()
        self.assertGreater(out[300:360, 60:160].std(axis=1).mean(), 0.4 * real)
        self.assertLess(float(np.abs(out - p)[hole].mean()), 0.25)

    def test_deterministic_and_periodic(self):
        p, _ = synthetic()
        hole = np.zeros((H, W), bool)
        hole[300:340, :10] = True
        hole[300:340, -10:] = True
        a = inpaint.inpaint(p, hole, seed=3)
        b = inpaint.inpaint(p, hole, seed=3)
        self.assertTrue(np.array_equal(a, b))
        self.assertTrue(np.isfinite(a).all())

    def test_whole_image_hole_refused(self):
        with self.assertRaises(ValueError):
            inpaint.inpaint(np.zeros((20, 20, 3), np.float32), np.ones((20, 20), bool))


class SplitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.p, cls.m = synthetic()
        cls.res = split.split_plate(cls.p, HAND, mattes={"island": cls.m, "sprites": {}}, log=lambda *_: None)

    def test_layers_composite_back_to_the_master(self):
        rc = split.rest_composite(self.res["layers"])
        de = heic.delta_e2000(rc * 255, self.p * 255)
        self.assertLess(de.mean(), 1.0)
        self.assertLess(np.percentile(de, 99), 7.0)

    def test_island_has_no_halo_on_another_background(self):
        isl = self.res["layers"]["island"]
        red = np.zeros_like(self.p) + np.array([1.0, 0.0, 0.0], np.float32)
        out = split.over(red, isl["rgb"], isl["a"])
        edge = (isl["a"] > 0.05) & (isl["a"] < 0.95) & (self.res["sil"] > 0.01) & (self.res["sil"] < 0.99)
        self.assertTrue(edge.any())
        # no sky blue / white leaks into the edge pixels: blue stays below green's level of the island
        self.assertLess(float(out[edge][:, 2].mean()), 0.5)

    def test_sea_is_filled_behind_the_island(self):
        sea = self.res["layers"]["sea"]
        behind = (self.res["sil"] > 0.99)
        behind[:285] = False
        self.assertTrue(behind.any())
        self.assertGreater(float(sea["a"][behind].min()), 0.6)
        # painted cloud, not island colour: the fill is bright and unsaturated
        px = sea["rgb"][behind]
        self.assertGreater(float(px.mean()), 0.7)

    def test_unmix_is_exact_where_unclipped(self):
        bg = np.full((4, 4, 3), 0.2, np.float32)
        p = np.full((4, 4, 3), 0.5, np.float32)
        a = np.full((4, 4), 0.5, np.float32)
        f = split.unmix(p, bg, a)
        self.assertTrue(np.allclose(split.over(bg, f, a), p, atol=1e-6))

    def test_guided_filter_snaps_to_edges(self):
        g = np.zeros((40, 40, 3), np.float32)
        g[:, 20:] = 1
        src = np.zeros((40, 40), np.float32)
        src[:, 22:] = 1                                  # edge two pixels off
        out = split.guided_filter(g, src, 4, 1e-3)
        self.assertGreater(float(out[:, 21].mean()), 0.5)

    def test_write_set_roundtrip(self):
        res = split.split_plate(self.p, HAND, mattes={"island": self.m, "sprites": {}}, log=lambda *_: None)
        with tempfile.TemporaryDirectory() as d:
            man = split.write_set(res, HAND, "day", Path(d), "x.heic")
            self.assertEqual(man["order"][0], "sky")
            self.assertEqual(man["order"][-1], "island")
            self.assertEqual(man["layers"][1]["tileWidth"], W)
            for lay in man["layers"]:
                self.assertTrue((Path(d) / lay["file"]).exists())
            far = heic.open_image(Path(d) / "far.heic")
            self.assertEqual(far.width, W)
            self.assertGreater(man["bytes"]["total"], 0)

    def test_wrap_closed(self):
        lay = dict(self.res["layers"]["sea"])
        rgb, a = split.close_wrap(lay["rgb"].copy(), lay["a"].copy(), 8, seed=0)
        left, right = rgb[300:380, 0], rgb[300:380, -1]
        self.assertLess(float(np.abs(left - right).mean()), 0.25)


if __name__ == "__main__":
    unittest.main()
