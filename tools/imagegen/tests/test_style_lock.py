"""Style lock: color math, presets, and the behavior the study relies on."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import pipeline as pl  # noqa: E402
import style_lock as sl  # noqa: E402

R1 = pl.REPO_ROOT / "design" / "art" / "masters" / "pofu-hamster-base-v1" / "pofu-hamster-base.png"


def saturated_prop() -> np.ndarray:
    im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((100, 200, 412, 460), radius=30, fill=(200, 90, 20, 255))
    d.ellipse((190, 80, 320, 210), fill=(230, 60, 20, 255))
    for x in range(110, 400, 9):  # fine "wood grain": the detail the lock should calm
        d.line((x, 210, x + 3, 450), fill=(120, 50, 10, 255), width=2)
    return np.asarray(im, dtype=np.float64) / 255.0


class ColorTests(unittest.TestCase):
    def test_lab_round_trip(self):
        rng = np.random.default_rng(0)
        rgb = rng.random((500, 3))
        back = sl.lab_to_srgb(sl.srgb_to_lab(rgb))
        self.assertLess(np.abs(back - rgb).max(), 1e-6)

    def test_soft_ceiling_is_monotonic_and_bounded(self):
        x = np.linspace(0, 200, 400)
        y = sl.soft_ceiling(x, 30, 50)
        self.assertTrue(np.all(np.diff(y) >= 0))
        self.assertLess(y.max(), 50)
        self.assertTrue(np.allclose(y[x <= 30], x[x <= 30]))

    def test_soft_floor_is_a_toe(self):
        x = np.linspace(0, 100, 401)
        y = sl.soft_floor(x, 14, 30)
        self.assertTrue(np.all(np.diff(y) > 0))
        self.assertGreater(y.min(), 14)
        self.assertTrue(np.allclose(y[x >= 30], x[x >= 30]))


class PresetTests(unittest.TestCase):
    def setUp(self):
        self.presets = sl.load_presets()

    def test_every_kind_has_a_preset(self):
        for kind in pl.KINDS:
            name, params = sl.preset_for(kind, self.presets)
            self.assertIn(name, self.presets, kind)

    def test_soft_lock_pulls_a_saturated_dark_prop_toward_r1(self):
        src = saturated_prop()
        out = sl.apply_lock(src, self.presets["soft-lock"])
        before, after = sl.measure(src), sl.measure(out)
        self.assertLess(after["C_p95"], before["C_p95"] - 15)
        self.assertGreater(after["L_p5"], before["L_p5"] + 5)
        self.assertLess(after["detail"], before["detail"])
        # transparency is preserved and nothing grows outside the silhouette
        self.assertEqual(float(out[5, 5, 3]), 0.0)
        self.assertTrue(np.all(out[..., 3] <= src[..., 3] + 1e-9))

    def test_lock_light_is_the_default_for_world_art(self):
        for kind in ("station", "prop", "world", "plate", "icon"):
            self.assertEqual(sl.preset_for(kind, self.presets)[0], "lock-light", kind)
        self.assertEqual(sl.preset_for("char", self.presets)[0], "char-guard")
        self.assertIn("soft-lock", self.presets)  # kept for comparison

    def test_lock_light_keeps_saturation_and_contrast_near_neutral(self):
        # A mid-key, moderately saturated prop: the runtime grade shapes
        # it, so the lock must leave its color and contrast nearly alone.
        im = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((100, 200, 412, 460), radius=30, fill=(196, 120, 72, 255))
        d.ellipse((190, 80, 320, 210), fill=(110, 150, 190, 255))
        d.rectangle((140, 300, 380, 360), fill=(92, 70, 52, 255))
        src = np.asarray(im, dtype=np.float64) / 255.0
        light = sl.apply_lock(src, self.presets["lock-light"])
        soft = sl.apply_lock(src, self.presets["soft-lock"])
        before, after, old = sl.measure(src), sl.measure(light), sl.measure(soft)
        self.assertAlmostEqual(after["C_p95"], before["C_p95"], delta=2.5)
        self.assertAlmostEqual(after["L_p50"], before["L_p50"], delta=2.5)
        self.assertGreater(after["L_p95"] - after["L_p5"], (before["L_p95"] - before["L_p5"]) - 3)
        # soft-lock bakes a real desaturation and contrast cut; lock-light does not
        self.assertLess(old["C_p95"], after["C_p95"] - 6)
        self.assertLess(old["L_p95"] - old["L_p5"], after["L_p95"] - after["L_p5"] - 3)

    def test_lock_light_still_lifts_near_black_and_tames_neon_green(self):
        im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle((20, 20, 236, 120), fill=(8, 6, 4, 255))
        d.rectangle((20, 130, 236, 236), fill=(90, 230, 40, 255))
        out = sl.apply_lock(np.asarray(im, dtype=np.float64) / 255.0, self.presets["lock-light"])
        L, C, _ = sl.lch(sl.srgb_to_lab(out[..., :3]))
        self.assertGreater(float(L[60, 128]), 14)
        self.assertLess(float(C[180, 128]), 50)

    def test_lock_is_deterministic(self):
        src = saturated_prop()
        a = sl.apply_lock(src, self.presets["gouache"])
        b = sl.apply_lock(src, self.presets["gouache"])
        self.assertTrue(np.array_equal(a, b))

    def test_char_guard_leaves_r1_essentially_untouched(self):
        r1 = sl.load_rgba(R1)
        out = sl.apply_lock(r1, self.presets["char-guard"])
        solid = r1[..., 3] > 0.9
        diff = np.abs(out[..., :3][solid] - r1[..., :3][solid]).mean()
        self.assertLess(diff, 0.004)


if __name__ == "__main__":
    unittest.main()
