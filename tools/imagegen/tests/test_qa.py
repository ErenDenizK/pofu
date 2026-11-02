"""QA checks on synthetic images (no network, no generated art needed)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import qa  # noqa: E402
import style_lock as sl  # noqa: E402

PROP = (217, 146, 94)   # wood (world-props)
ROSE = (238, 154, 144)  # awning rose


def canvas(w=1024, h=1024, bg=(0, 0, 0, 0)) -> Image.Image:
    return Image.new("RGBA", (w, h), bg)


def stall(dx=0, dy=0, scale=1.0, awning=False, size=1024) -> np.ndarray:
    """A rounded counter standing on the guide's footprint (bottom at y = 900)."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    cx, base = 512 + dx, 900 + dy
    w, h = 520 * scale, 300 * scale
    d.rounded_rectangle((cx - w / 2, base - h, cx + w / 2, base), radius=int(40 * scale), fill=PROP + (255,))
    d.ellipse((cx - 60 * scale, base - h - 120 * scale, cx + 60 * scale, base - h), fill=(212, 135, 95, 255))
    if awning:
        d.rectangle((cx - w / 2, base - h - 260 * scale, cx + w / 2, base - h - 180 * scale), fill=ROSE + (255,))
    return np.asarray(im, dtype=np.float64) / 255.0


class StationTests(unittest.TestCase):
    def test_anchor_pass_and_fail(self):
        self.assertEqual(qa.check_station_anchor(stall()).status, "pass")
        self.assertEqual(qa.check_station_anchor(stall(dx=150)).status, "fail")
        self.assertEqual(qa.check_station_anchor(stall(dy=-130)).status, "warn")

    def test_registration_moves_the_footprint_onto_the_anchor(self):
        off = stall(dx=60, dy=-40)
        reg = qa.station_registration(off)
        fixed = qa.shift(off, reg["dx"], reg["dy"])
        self.assertEqual(qa.check_station_anchor(fixed).status, "pass")

    def test_edit_alignment_recovers_a_zoomed_out_edit(self):
        parent = stall()
        child = stall(scale=0.85, dy=-20, awning=True)  # the model zoomed out to fit the awning
        self.assertLess(qa.edit_kept_fraction(child, parent), 0.8)
        aligned, t = qa.align_to_parent(child, parent)
        self.assertAlmostEqual(1 / t["scale"], 0.85, delta=0.03)
        self.assertGreater(qa.edit_kept_fraction(aligned, parent), 0.9)

    def test_edit_of_a_registered_master_is_not_registered_again(self):
        # Batch 03: simit-1 was drawn 110 px off the anchor and registered.
        # Its edit is drawn on the registered master, so it is already on
        # the anchor; re-applying the root's registration moved it off.
        root_raw = stall(dx=-110)
        reg = qa.station_registration(root_raw)
        parent = qa.shift(root_raw, reg["dx"], reg["dy"])
        child = stall(awning=True)  # the edit keeps the parent's place
        preset = sl.load_presets()["lock-light"]
        good = qa.process_take(child, "station", (1024, 1024), preset, ["world-props"],
                               registration=dict(qa.EDIT_REGISTRATION), parent_locked=sl.apply_lock(parent, preset))
        kept = {c.name: c for c in good.checks}["edit_stability"]
        self.assertEqual(kept.status, "pass", kept.message)
        shifted = qa.shift(child, reg["dx"], reg["dy"])
        self.assertLess(qa.edit_kept_fraction(shifted, parent), kept.value)  # what the double shift did

    def test_edit_chroma_drift_is_caught(self):
        parent = stall()
        grey = parent.copy()
        lab = sl.srgb_to_lab(grey[..., :3])
        lab[..., 1:] *= 0.6  # the level lost 40 % of its chroma (batch 03's windmill-2)
        grey[..., :3] = np.clip(sl.lab_to_srgb(lab), 0, 1)
        self.assertAlmostEqual(qa.edit_chroma_ratio(parent, parent), 1.0, places=3)
        checks = {c.name: c for c in qa.run_checks("station", grey, grey, ["world-props"], parent_locked=parent)}
        self.assertEqual(checks["edit_chroma"].status, "fail")

    def test_magenta_guide_remnants(self):
        im = Image.fromarray(np.round(stall() * 255).astype(np.uint8), "RGBA")
        ImageDraw.Draw(im).ellipse((152, 692, 872, 908), outline=(236, 0, 140, 255), width=6)
        dirty = np.asarray(im, dtype=np.float64) / 255.0
        limits = qa.limits_for("station")
        self.assertEqual(qa.check_magenta(stall(), limits).status, "pass")
        self.assertEqual(qa.check_magenta(dirty, limits).status, "fail")


class NormalizeTests(unittest.TestCase):
    def test_flat_green_background_is_keyed(self):
        im = Image.new("RGBA", (1024, 1024), (0, 255, 0, 255))
        ImageDraw.Draw(im).ellipse((300, 300, 700, 800), fill=PROP + (255,))
        keyed, check = qa.ensure_alpha(np.asarray(im, dtype=np.float64) / 255.0)
        self.assertEqual(check.status, "warn")
        self.assertLess(keyed[10, 10, 3], 0.05)
        self.assertGreater(keyed[550, 500, 3], 0.95)

    def test_busy_opaque_background_fails(self):
        rng = np.random.default_rng(1)
        noisy = np.dstack([rng.random((256, 256, 3)), np.ones((256, 256))])
        self.assertEqual(qa.ensure_alpha(noisy)[1].status, "fail")

    def test_fit_contain_and_cover(self):
        src = np.ones((1254, 1254, 4))
        out, c = qa.fit_canvas(src, (1024, 1024))
        self.assertEqual(out.shape[:2], (1024, 1024))
        self.assertEqual(c.status, "pass")
        wide, c = qa.fit_canvas(np.ones((1024, 1536, 4)), (1536, 720), cover=True)
        self.assertEqual(wide.shape[:2], (720, 1536))
        self.assertGreater(wide[..., 3].min(), 0.99)


class LookTests(unittest.TestCase):
    def test_lock_load_is_zero_for_identical_images(self):
        a = stall()
        self.assertEqual(qa.lock_load(a, a), 0.0)

    def test_saturated_stall_fails_chroma_before_the_lock_and_passes_after(self):
        hot = canvas()
        ImageDraw.Draw(hot).rounded_rectangle((250, 500, 774, 900), radius=40, fill=(230, 80, 10, 255))
        raw = np.asarray(hot, dtype=np.float64) / 255.0
        lim = qa.limits_for("station")
        self.assertEqual(qa.grade(sl.measure(raw)["C_p95"], lim["chroma_p95"]), "fail")
        locked = sl.apply_lock(raw, sl.load_presets()["soft-lock"])
        self.assertNotEqual(qa.grade(sl.measure(locked)["C_p95"], lim["chroma_p95"]), "fail")

    def test_island_depth_ratio(self):
        def island(depth):
            im = canvas(1536, 1024)
            d = ImageDraw.Draw(im)
            d.ellipse((200, 600 - depth, 1336, 600 + depth), fill=(240, 191, 134, 255))  # earth
            d.ellipse((200, 200, 1336, 540), fill=(140, 192, 132, 255))                # lawn
            return np.asarray(im, dtype=np.float64) / 255.0
        self.assertLess(qa.island_depth_ratio(island(200)), qa.island_depth_ratio(island(400)))
        self.assertGreater(qa.island_depth_ratio(island(400)), 0.32)


class IconTests(unittest.TestCase):
    def icon(self, stem: bool, dark_accent: bool) -> np.ndarray:
        im = canvas()
        d = ImageDraw.Draw(im)
        d.ellipse((150, 150, 874, 874), fill=(246, 201, 92, 255))
        if dark_accent:
            d.ellipse((420, 420, 604, 604), fill=(110, 70, 50, 255))
        if stem:
            d.rectangle((505, 40, 519, 150), fill=(94, 158, 106, 255))
        return np.asarray(im, dtype=np.float64) / 255.0

    def test_thin_parts_are_flagged(self):
        self.assertLess(qa.thin_fraction(self.icon(False, True)), 0.02)
        self.assertGreater(qa.thin_fraction(self.icon(True, True)), qa.thin_fraction(self.icon(False, True)))

    def test_pale_icon_does_not_read_on_light_glass(self):
        pale = qa.glass_contrast(self.icon(False, False), "light")
        accented = qa.glass_contrast(self.icon(False, True), "light")
        self.assertLess(pale, accented)
        self.assertGreater(qa.glass_contrast(self.icon(False, False), "dark"), 0.9)

    def test_app_icon_checks(self):
        opaque = np.ones((1024, 1024, 4)) * 0.8
        opaque[..., 3] = 1
        self.assertEqual(qa.appicon_checks(opaque)[0].status, "pass")
        holey = opaque.copy()
        holey[:10, :10, 3] = 0
        self.assertEqual(qa.appicon_checks(holey)[0].status, "fail")


class ProcessTakeTests(unittest.TestCase):
    def test_whole_chain_on_a_good_station(self):
        res = qa.process_take(stall(), "station", (1024, 1024), sl.load_presets()["soft-lock"],
                              ["world-props", "world-day", "character"], register_root=True)
        names = {c.name: c.status for c in res.checks}
        self.assertEqual(names["station_anchor"], "pass")
        self.assertEqual(names["transparency"], "pass")
        self.assertIn(res.status, ("pass", "warn"))

    def test_opaque_kind_with_holes_fails(self):
        res = qa.process_take(stall(), "widget", (1536, 720), sl.load_presets()["soft-lock"], ["world-day"], transparent=False)
        self.assertEqual(res.checks[0].status, "fail")


if __name__ == "__main__":
    unittest.main()
