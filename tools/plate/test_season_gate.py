"""Tests for season_gate.py (python3 -I -m unittest discover -s tools/plate -p "test_season_gate.py")."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import season_gate as sg  # noqa: E402

DATA = json.loads(sg.PLATE_JSON.read_text())
DAY, GOLDEN, NIGHT = (sg.load_asset(f"world-home-plate-{l}-0") for l in ("day", "golden", "night"))


def over_sky(plate: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    h, w = alpha.shape
    t = np.linspace(0, 1, h)[:, None, None]
    sky = (np.array([0.45, 0.7, 0.95]) * (1 - t) + np.array([0.8, 0.88, 0.95]) * t) * np.ones((h, w, 3))
    return (sky * (1 - alpha[..., None]) + plate[..., :3] * alpha[..., None]).astype(np.float32)


class FrameTests(unittest.TestCase):
    def test_golden_reproduces_section_3(self):
        r = sg.s1_frame_held(DAY, GOLDEN)
        self.assertTrue(r["ok"])
        self.assertAlmostEqual(r["median"], 0.40, delta=0.05)
        self.assertAlmostEqual(r["p90"], 0.69, delta=0.05)

    def test_night_passes_s1_and_s5(self):
        self.assertTrue(sg.s1_frame_held(DAY, NIGHT)["ok"])
        r = sg.s5_night_is_the_days(DAY, NIGHT)
        self.assertTrue(r["ok"])
        self.assertAlmostEqual(r["median"], 0.35, delta=0.05)
        self.assertAlmostEqual(r["p90"], 0.58, delta=0.05)

    def test_two_pixels_fail(self):
        r = sg.s1_frame_held(DAY, np.roll(DAY, 4, axis=1))  # 2 plate px
        self.assertFalse(r["ok"])
        self.assertAlmostEqual(r["p90"], 2.0, delta=0.1)

    def test_size_mismatch_is_an_error(self):
        with self.assertRaises(ValueError):
            sg.s1_frame_held(DAY, DAY[:-2])


class OutlineTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.alpha = DAY[..., 3]
        cls.pic = over_sky(DAY, cls.alpha)
        cls.k = np.ones((17, 17), np.uint8)

    def test_the_spring_picture_over_a_sky_passes(self):
        r = sg.s2_outline_held(self.pic, self.alpha)
        self.assertTrue(r["ok"], r)

    def test_sky_inside_the_outline_fails(self):
        eroded = cv2.erode((self.alpha > 0.5).astype(np.uint8), self.k).astype(np.float32)
        r = sg.s2_outline_held(over_sky(DAY, self.alpha * eroded), self.alpha)
        self.assertFalse(r["ok"])
        self.assertGreater(r["sky_inside"], 0)

    def test_paint_outside_the_outline_fails(self):
        grown = cv2.dilate(DAY[..., :3], self.k)
        near = cv2.dilate(self.alpha, self.k) > 0.5
        pic = np.where(near[..., None], np.where((self.alpha > 0.5)[..., None], DAY[..., :3], grown), self.pic)
        r = sg.s2_outline_held(pic, self.alpha)
        self.assertFalse(r["ok"])
        self.assertGreater(r["paint_outside"], 0)


class PaletteTests(unittest.TestCase):
    def test_a_plate_matches_itself_and_not_the_night(self):
        lawn = sg.lawn_mask(DAY.shape[:2], DATA)
        self.assertEqual(sg.s3_one_palette(DAY, DAY, lawn)["dE"], 0.0)
        self.assertFalse(sg.s3_one_palette(NIGHT, DAY, lawn)["ok"])

    def test_the_shipped_base_keeps_its_plate_lawn(self):
        lawn = sg.lawn_mask(DAY.shape[:2], DATA)
        r = sg.s3_one_palette(sg.load_asset("world-home-base-day-0"), DAY, lawn)
        self.assertTrue(r["ok"], r)


class LookTests(unittest.TestCase):
    def test_a_look_on_its_own_plate_sits_and_on_the_wrong_one_fails(self):
        box = DATA["stations"]["windmill"]["box"]
        look = sg.load_asset("world-home-look-windmill-5-day")
        self.assertTrue(sg.s4_look_sits(DAY, look, box)["ok"])
        self.assertFalse(sg.s4_look_sits(NIGHT, look, box)["ok"])

    def test_fit_residuals_are_measured_without_a_limit(self):
        r = sg.fit_residuals(DAY, GOLDEN, DATA)
        self.assertIsNone(r["limit"])
        w = r["stations"]["windmill"]
        self.assertLess(w["after"][0], w["before"][0])


class CompleteTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.assets = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)
        self.data = json.loads(json.dumps(DATA))
        self.data["seasons"] = {"autumn": {"complete": False, "states": {"day": [0]}}}
        self.key = "autumn-day"

    def put(self, name: str):
        d = self.assets / f"{name}.imageset"
        d.mkdir(exist_ok=True)
        (d / f"{name}.png").write_bytes(b"x")

    def fill(self, skip: str | None = None):
        isl = "world-home"
        names = [f"{isl}-plate-{self.key}-0", f"{isl}-island-{self.key}-0", f"{isl}-mapisle-{self.key}-0"]
        names += [f"{isl}-occ-{o}-{self.key}-0" for o in ("teaStall", "workshop", "windmill", "wheel", "mailbox", "westBush", "eastBush")]
        names += [f"{isl}-base-{self.key}-0"]
        names += [f"{isl}-look-teaStall-{n}-{self.key}" for n in range(1, 6)]
        names += [f"{isl}-look-windmill-{n}-{self.key}" for n in range(2, 6)]
        names += [f"{isl}-look-pond-{n}-{self.key}" for n in range(1, 6)]
        names += [f"{isl}-look-workshop-{n}-{self.key}" for n in range(1, 6)]
        names += [f"{isl}-look-bagelCart-{n}-{self.key}" for n in range(1, 6)]
        names += [f"{isl}-look-lighthouse-{n}-{self.key}" for n in range(1, 6)]
        for n in names:
            if n != skip:
                self.put(n)
        for t in ("harmony", "lightMap", "shadowMap", "plateCrop"):
            self.data[t][self.key] = self.data[t]["day"]

    def test_a_season_with_nothing_is_incomplete(self):
        r = sg.s8_complete(self.data, "autumn", self.assets)
        self.assertFalse(r["ok"])
        self.assertIn("world-home-plate-autumn-day-0", r["missing"]["day-0"])

    def test_a_full_state_is_complete(self):
        self.fill()
        self.assertEqual(sg.s8_complete(self.data, "autumn", self.assets), {"check": "S8", "ok": True, "missing": {}})

    def test_each_missing_piece_is_named(self):
        for gone in ("world-home-occ-windmill-autumn-day-0", "world-home-look-windmill-3-autumn-day",
                     "world-home-mapisle-autumn-day-0"):
            self.setUp()
            self.fill(skip=gone)
            self.assertEqual(sg.s8_complete(self.data, "autumn", self.assets)["missing"], {"day-0": [gone]})

    def test_a_missing_table_row_is_named(self):
        self.fill()
        del self.data["shadowMap"][self.key]
        self.assertEqual(sg.s8_complete(self.data, "autumn", self.assets)["missing"], {"day-0": [f"shadowMap[{self.key}][0]"]})

    def test_an_unlisted_season_is_not_complete(self):
        self.assertFalse(sg.s8_complete(self.data, "winter", self.assets)["ok"])

    def test_spring_names_are_todays(self):
        self.assertEqual(sg.season_key(None, "golden"), "golden")
        self.assertEqual(sg.season_key("spring", "day"), "day")
        self.assertEqual(sg.season_key("autumn", "night"), "autumn-night")

    def test_the_shipped_spring_day_state_is_complete(self):
        self.assertEqual(sg.s8_missing(DATA, "spring", "day", 0), [])


if __name__ == "__main__":
    unittest.main()
