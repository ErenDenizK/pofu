"""Tests for portrait.py: registering a landscape plate on a portrait master, placing it, pasting its island."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import portrait as P  # noqa: E402

FRAME = {"scale": 2 / 3, "offset": [0.0, 106.0], "size": [256, 384]}


def landscape(seed: int = 3) -> np.ndarray:
    """A textured 384 x 256 picture with a bright blob (an island) in the middle."""
    rng = np.random.default_rng(seed)
    img = cv2.GaussianBlur(rng.random((256, 384, 3)).astype(np.float32), (0, 0), 3.0)
    img = (img - img.min()) / (img.max() - img.min())
    cv2.ellipse(img, (192, 150), (130, 70), 0, 0, 360, (0.9, 0.8, 0.2), -1)
    return cv2.GaussianBlur(img, (0, 0), 1.0)


def on_master(land: np.ndarray) -> np.ndarray:
    """The landscape scaled by 2/3 and put on a 256 x 384 canvas of its own texture, at the frame's offset."""
    rng = np.random.default_rng(9)
    out = cv2.GaussianBlur(rng.random((384, 256, 3)).astype(np.float32), (0, 0), 4.0)
    y0 = int(round(FRAME["offset"][1]))
    out[y0:y0 + 171] = cv2.resize(land, (256, 171), interpolation=cv2.INTER_AREA)
    return out


class RegisterTests(unittest.TestCase):
    def test_the_measured_place_is_the_one_the_plate_was_put_at(self):
        land = landscape()
        master = on_master(land)
        r = P.register(land, master, guess_y=100.0)
        self.assertAlmostEqual(r["scale"], 2 / 3, delta=0.004)
        self.assertAlmostEqual(r["offset"][0], 0.0, delta=1.0)
        self.assertAlmostEqual(r["offset"][1], 106.0, delta=1.0)
        self.assertGreater(r["cc"], 0.95)

    def test_a_wrong_stored_frame_is_far_from_the_measure(self):
        land = landscape()
        master = on_master(land)
        r = P.register(land, master, guess_y=100.0)
        self.assertGreater(abs(r["offset"][1] - 140.0), 5)


class PlaceTests(unittest.TestCase):
    def test_place_puts_the_plate_in_its_rows_and_nothing_elsewhere(self):
        land = landscape()
        out = P.place(land, FRAME, (256, 384), k=1.0)
        self.assertEqual(out.shape, (384, 256, 3))
        self.assertEqual(float(np.abs(out[:106]).max()), 0.0)
        self.assertEqual(float(np.abs(out[106 + 171:]).max()), 0.0)
        ref = cv2.resize(land, (256, 171), interpolation=cv2.INTER_AREA)
        np.testing.assert_allclose(out[106:106 + 171], ref, atol=1e-6)

    def test_x2_working_size_doubles_offset_and_size(self):
        land = landscape()
        up = cv2.resize(land, (768, 512), interpolation=cv2.INTER_LINEAR)
        out = P.place(up, FRAME, (512, 768), k=2.0, from_k=2.0)
        self.assertEqual(float(np.abs(out[:212]).max()), 0.0)
        self.assertGreater(float(np.abs(out[212:212 + 342]).mean()), 0.05)

    def test_the_paste_weight_is_one_on_the_island_and_zero_far_from_it(self):
        a = np.zeros((300, 300), np.float32)
        a[100:200, 100:200] = 1
        w = P.paste_weight(a)
        self.assertEqual(float(w[150, 150]), 1.0)
        self.assertLess(float(w[0, 0]), 0.01)
        self.assertTrue(0.0 < float(w[100 - P.PASTE_REACH, 150]) < 0.9)


class ShippedFrameTests(unittest.TestCase):
    def test_the_stored_frame_registers_the_picked_plate_on_the_picked_master(self):
        from PIL import Image
        frame = P.load_frame("caglayan")
        land = np.asarray(Image.open(P.stage_plate_paths("caglayan")[4]).convert("RGB"), np.float32) / 255
        master = np.asarray(Image.open(P.ROOT / frame["master"]).convert("RGB"), np.float32) / 255
        r = P.register(land, master)
        self.assertAlmostEqual(frame["scale"], r["scale"], delta=0.002)
        # master px at the plate's centre agree to a pixel whichever of the two scales is used
        cx, cy = 768.0, 512.0
        stored = (frame["scale"] * cx + frame["offset"][0], frame["scale"] * cy + frame["offset"][1])
        measured = (r["scale"] * cx + r["offset"][0], r["scale"] * cy + r["offset"][1])
        self.assertAlmostEqual(stored[0], measured[0], delta=1.0)
        self.assertAlmostEqual(stored[1], measured[1], delta=1.0)


if __name__ == "__main__":
    unittest.main()
