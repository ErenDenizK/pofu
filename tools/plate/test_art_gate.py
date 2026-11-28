"""Tests for art_gate.py (python3 -I -m unittest discover -s tools/plate -p "test_art_gate.py")."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import art_gate  # noqa: E402
import heic  # noqa: E402

CFG = json.loads(art_gate.CONFIG.read_text())
W, H = 1206, 2622


def lch_frame(L: float, C: float, h: float) -> np.ndarray:
    rgb = np.rint(art_gate.lch_to_rgb(L, C, h)).astype(np.uint8)
    return np.broadcast_to(rgb, (H, W, 3)).copy()


def save(folder: Path, name: str, frame: np.ndarray) -> None:
    Image.fromarray(frame).save(folder / f"{name}.png")


class ArtGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def test_lab_round_trip(self):
        m = art_gate.measure(lch_frame(55, 25, 110), (0, 0, 50, 50))
        self.assertAlmostEqual(m["L"], 55, delta=0.6)
        self.assertAlmostEqual(m["C"], 25, delta=0.8)
        self.assertAlmostEqual(m["h"], 110, delta=2)

    def test_night_lawn_grey_fails_green_passes(self):
        cfg = CFG["night.lawn"]
        save(self.folder, cfg["frame"], lch_frame(65, 5, 110))
        self.assertEqual(art_gate.night_lawn(cfg, self.folder)["status"], "FAIL")
        save(self.folder, cfg["frame"], lch_frame(55, 25, 110))
        self.assertEqual(art_gate.night_lawn(cfg, self.folder)["status"], "pass")

    def test_missing_frame_fails_unless_pending(self):
        r = art_gate.night_lawn(CFG["night.lawn"], self.folder)
        self.assertEqual(r["status"], "FAIL")
        r = art_gate.pofu_separation(CFG["pofu.separation"], self.folder)
        self.assertEqual(r["status"], "pending")

    def test_season_band_identical_fails_different_passes(self):
        cfg = CFG["season.band"]
        rng = np.random.default_rng(1)
        base = rng.integers(0, 200, (H, W, 3), dtype=np.uint8)
        other = np.clip(base.astype(int) + 20, 0, 255).astype(np.uint8)
        for suffix in ("", "-night"):
            save(self.folder, f"path-season-summer-i10{suffix}", base)
            save(self.folder, f"path-season-autumn-i10{suffix}", base.copy())  # shifted by 0 levels
            save(self.folder, f"path-season-winter-i10{suffix}", other)
        plate = {"seasons": {"autumn": {"complete": True}, "winter": {"complete": True}}}
        by = {r["check"]: r for r in art_gate.season_band(cfg, self.folder, plate)}
        self.assertEqual(by["season.band.autumn"]["status"], "FAIL")
        self.assertEqual(by["season.band.winter"]["status"], "pass")
        # unlisted or incomplete: pending, never a failure
        by = {r["check"]: r for r in art_gate.season_band(cfg, self.folder, {"seasons": {"autumn": {"complete": False}}})}
        self.assertEqual(by["season.band.autumn"]["status"], "pending")
        self.assertEqual(by["season.band.winter"]["status"], "pending")

    def test_mirror_correlation(self):
        rng = np.random.default_rng(2)
        strip = cv2.GaussianBlur(rng.normal(128, 40, (230, 120)), (0, 0), 3)
        rgb = lambda g: np.repeat(g[..., None], 3, axis=2)  # noqa: E731
        mirrored = art_gate.mirror_correlation(rgb(strip), rgb(strip[:, ::-1]), 8)
        self.assertGreater(mirrored, 0.9)
        other = cv2.GaussianBlur(rng.normal(128, 40, (230, 120)), (0, 0), 3)
        self.assertLess(art_gate.mirror_correlation(rgb(strip), rgb(other), 8), 0.3)

    def test_blur_share_half_blurred_frame(self):
        rng = np.random.default_rng(3)
        sharp = rng.integers(0, 255, (400, 300, 3), dtype=np.uint8)
        blurred = sharp.copy()
        blurred[200:] = cv2.GaussianBlur(sharp[200:], (0, 0), 12)
        self.assertGreaterEqual(art_gate.blur_share(blurred), 0.45)
        self.assertEqual(art_gate.blur_share(sharp), 0.0)

    def test_sky_day_target_is_zero_distance_to_itself(self):
        cfg = CFG["sky.day"]
        save(self.folder, cfg["frame"], lch_frame(*cfg["target_lch"]))
        self.assertEqual(art_gate.sky_day(cfg, self.folder)["status"], "pass")

    def test_delta_e_against_hex(self):
        cfg = CFG["sky.golden"]
        rgb = art_gate.hex_to_rgb(cfg["target_hex"]).astype(np.uint8)
        save(self.folder, cfg["frame"], np.broadcast_to(rgb, (H, W, 3)).copy())
        self.assertEqual(art_gate.sky_golden(cfg, self.folder)["status"], "pass")

    def test_null_limit_prints_measure_only(self):
        cfg = CFG["sky.contour"]
        save(self.folder, cfg["frame"], lch_frame(70, 10, 300))
        self.assertEqual(art_gate.sky_contour(cfg, self.folder)["status"], "measure")

    def test_report_exit_code(self):
        self.assertEqual(art_gate.main(["report", str(self.folder)]), 1)  # no frames: complete checks fail


if __name__ == "__main__":
    unittest.main()
