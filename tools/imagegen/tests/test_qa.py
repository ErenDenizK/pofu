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

    def test_edit_is_anchored_against_its_parent_not_the_contract(self):
        # tea-stall-5 stands above the height bar and wider than the footprint
        # (batch 07: tea-stall-5-lit failed station_anchor for the parent's geometry).
        tall = stall(scale=1.5, awning=True)
        self.assertNotEqual(qa.check_station_anchor(tall).status, "pass")
        self.assertEqual(qa.check_station_anchor(tall, is_edit=True, parent=tall).status, "pass")
        # an edit that really moves off its parent still fails
        self.assertEqual(qa.check_station_anchor(stall(dy=-80), is_edit=True, parent=stall()).status, "fail")

    def test_registration_moves_the_footprint_onto_the_anchor(self):
        off = stall(dx=60, dy=-40)
        reg = qa.station_registration(off)
        fixed = qa.shift(off, reg["dx"], reg["dy"])
        self.assertEqual(qa.check_station_anchor(fixed).status, "pass")

    def test_decor_piece_is_checked_against_the_decor_guide(self):
        # Batch 08's bench: 740 px wide, top at y 419, against a 360 px footprint and a bar at y 500.
        def piece(w, h, base=888, cx=512):
            im = canvas()
            ImageDraw.Draw(im).rounded_rectangle((cx - w / 2, base - h, cx + w / 2, base), radius=20, fill=PROP + (255,))
            return np.asarray(im, dtype=np.float64) / 255.0
        self.assertEqual(qa.check_decor_anchor(piece(340, 300)).status, "pass")
        self.assertEqual(qa.check_decor_anchor(piece(740, 470)).status, "fail")
        self.assertEqual(qa.check_decor_anchor(piece(694, 491)).status, "fail")
        self.assertEqual(qa.check_decor_anchor(piece(340, 300, cx=700)).status, "fail")

    def test_decor_registration_puts_the_piece_on_the_guide(self):
        d = canvas()
        ImageDraw.Draw(d).rounded_rectangle((300, 400, 640, 700), radius=20, fill=PROP + (255,))
        off = np.asarray(d, dtype=np.float64) / 255.0
        fixed = qa.shift(off, **qa.decor_registration(off))
        self.assertEqual(qa.check_decor_anchor(fixed).status, "pass")

    def test_hanging_decor_hangs_from_the_hang_line(self):
        d = canvas()
        ImageDraw.Draw(d).rounded_rectangle((200, 100, 700, 330), radius=20, fill=PROP + (255,))
        off = np.asarray(d, dtype=np.float64) / 255.0
        self.assertNotEqual(qa.check_decor_anchor(off, "hang").status, "pass")
        fixed = qa.shift(off, **qa.decor_registration(off, "hang"))
        self.assertEqual(qa.check_decor_anchor(fixed, "hang").status, "pass")

    def test_a_prop_with_the_decor_guide_is_a_decor_job(self):
        import pipeline
        m = pipeline.load_manifest(HERE.parent / "manifest/batch-08-decor-pilot.yaml")
        self.assertEqual({j.id: j.decor for j in m.jobs if j.kind == "prop"},
                         {"decor-bench": "ground", "decor-lanterns": "hang", "decor-sailboat": "ground", "decor-mailbox": "ground"})

    def test_edit_alignment_recovers_a_zoomed_out_edit(self):
        parent = stall()
        child = stall(scale=0.85, dy=-20, awning=True)  # the model zoomed out to fit the awning
        self.assertLess(qa.edit_kept_fraction(child, parent), 0.8)
        aligned, t = qa.align_to_parent(child, parent)
        self.assertAlmostEqual(1 / t["scale"], 0.85, delta=0.03)
        self.assertGreater(qa.edit_kept_fraction(aligned, parent), 0.9)

    def test_edit_of_a_registered_master_is_not_registered_again(self):
        # Batch 03: bagel-cart-1 was drawn 110 px off the anchor and registered.
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
        self.assertAlmostEqual(qa.edit_chroma_ratio(parent, parent), 1.0, delta=0.01)
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

    def test_a_plate_job_can_flag_a_squashed_island(self):
        # Look round 2: the founder found the plate too squashed; a job's
        # depth_floor makes a too-thin earth body a QA warning or failure.
        im = canvas(1536, 1024)
        d = ImageDraw.Draw(im)
        d.ellipse((200, 520, 1336, 640), fill=(240, 191, 134, 255))  # a thin earth body
        d.ellipse((200, 300, 1336, 560), fill=(140, 192, 132, 255))  # lawn
        flat = np.asarray(im, dtype=np.float64) / 255.0
        default = {c.name for c in qa.run_checks("world", flat, flat, ["world-day"])}
        self.assertNotIn("depth_floor", default)
        checks = qa.run_checks("world", flat, flat, ["world-day"], {"depth_floor": {"warn": 0.26, "fail": 0.2}})
        floor = next(c for c in checks if c.name == "depth_floor")
        self.assertEqual(floor.status, "fail")


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



def tile(rgb, size=1024, inset=140, notch=False) -> np.ndarray:
    """A rounded tile with a lighter sprout, in one glaze (a stand-in for a plot tile)."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((inset, inset, size - inset, size - inset), radius=90, fill=rgb + (255,))
    light = tuple(min(255, c + 25) for c in rgb)
    d.ellipse((430, 400, 600, 570), fill=light + (255,))
    d.rectangle((500, 560, 530, 760), fill=light + (255,))
    if notch:  # the edit changed the shape: a bite out of the tile
        d.rectangle((inset, inset, 520, 520), fill=(0, 0, 0, 0))
    return np.asarray(im, dtype=np.float64) / 255.0


class EditModeTests(unittest.TestCase):
    """Edits that repaint the object (batches 11-12: glaze recolors, a refilled jar, a lit lantern)."""

    SAGE, HONEY = (168, 190, 150), (214, 188, 120)

    def names(self, child, parent, **acc):
        cs = qa.run_checks("ui", child, child, ["world-props", "world-day", "character"], acc, parent_locked=parent)
        return {c.name: c for c in cs}

    def test_a_recolor_fails_the_default_edit_stability_by_construction(self):
        c = self.names(tile(self.HONEY), tile(self.SAGE))
        self.assertNotEqual(c["edit_stability"].status, "pass")

    def test_recolor_mode_checks_shape_and_light_instead_of_colors(self):
        c = self.names(tile(self.HONEY), tile(self.SAGE), edit_mode="recolor")
        self.assertNotIn("edit_stability", c)
        self.assertNotIn("edit_chroma", c)
        for name in ("edit_silhouette", "edit_structure", "edit_lightness"):
            self.assertEqual(c[name].status, "pass", name)

    def test_recolor_mode_still_catches_a_changed_shape_and_a_changed_lightness(self):
        c = self.names(tile(self.HONEY, notch=True), tile(self.SAGE), edit_mode="recolor")
        self.assertEqual(c["edit_silhouette"].status, "fail")
        dark = self.names(tile((70, 90, 55)), tile(self.SAGE), edit_mode="recolor")
        self.assertEqual(dark["edit_lightness"].status, "fail")

    def test_region_mode_relaxes_edit_stability_but_keeps_the_shape_check(self):
        parent = tile(self.SAGE)
        child = tile(self.SAGE)
        child[430:600, 430:600, :3] = (0.2, 0.15, 0.1)  # the window is refilled
        keep = self.names(child, parent)
        region = self.names(child, parent, edit_mode="region")
        self.assertLess(keep["edit_stability"].value, 0.99)
        self.assertEqual(region["edit_stability"].status, "pass")
        self.assertEqual(region["edit_silhouette"].status, "pass")
        gone = self.names(tile(self.SAGE, notch=True), parent, edit_mode="region")
        self.assertEqual(gone["edit_silhouette"].status, "fail")

    def test_default_mode_adds_no_new_check(self):
        c = self.names(tile(self.SAGE), tile(self.SAGE))
        self.assertNotIn("edit_silhouette", c)
        self.assertEqual(c["edit_stability"].status, "pass")

    def test_night_profile_accepts_a_dark_recolor_and_rejects_a_light_one(self):
        night = self.names(tile((38, 44, 92)), tile(self.SAGE), edit_mode="recolor", profile="night")
        self.assertNotIn("edit_lightness", night)
        self.assertEqual(night["night_lightness"].status, "pass")
        self.assertNotEqual(night["value_floor"].status, "fail")
        plain = self.names(tile((38, 44, 92)), tile(self.SAGE), edit_mode="recolor")
        self.assertEqual(plain["edit_lightness"].status, "fail")
        light = self.names(tile(self.HONEY), tile(self.SAGE), edit_mode="recolor", profile="night")
        self.assertEqual(light["night_lightness"].status, "fail")

    def test_exploration_style_failures_are_advisory_but_transparency_stays_hard(self):
        loud = tile((12, 12, 20))  # far below the value floor
        args = ("ui", (1024, 1024), sl.load_presets()["soft-lock"], ["world-props"])
        strict = qa.process_take(loud, *args)
        self.assertEqual({c.name: c.status for c in strict.checks}["value_floor"], "fail")
        soft = qa.process_take(loud, *args, {"exploration": True})
        by = {c.name: c.status for c in soft.checks}
        self.assertEqual(by["value_floor"], "warn")
        self.assertNotIn("fail", by.values())
        cut = loud.copy()
        cut[:300, :, 3] = 0
        bad = qa.process_take(cut, *args, {"exploration": True}, transparent=False)
        self.assertEqual({c.name: c.status for c in bad.checks}["transparency"], "fail")

    def test_exploration_is_recognised_by_id(self):
        for jid in ("x-koke-1", "x2-hub-grown", "x-b16-logo-b"):
            self.assertTrue(qa.is_exploration(jid))
        self.assertFalse(qa.is_exploration("ui-sheet-paper-night"))
        self.assertTrue(qa.is_exploration("anything", {"exploration": True}))

    def test_unknown_mode_is_an_error(self):
        with self.assertRaises(ValueError):
            self.names(tile(self.SAGE), tile(self.SAGE), edit_mode="recolour")


class KindProfileTests(unittest.TestCase):
    def test_ui_accepts_a_saturated_accent_but_a_prop_does_not(self):
        self.assertEqual(qa.grade(58.0, qa.limits_for("ui")["chroma_p95"]), "warn")
        self.assertEqual(qa.grade(60.5, qa.limits_for("ui")["chroma_p95"]), "warn")
        self.assertEqual(qa.grade(60.5, qa.limits_for("prop")["chroma_p95"]), "fail")
        self.assertEqual(qa.grade(66.0, qa.limits_for("ui")["chroma_p95"]), "fail")

    def test_extra_palettes_cover_the_colors_a_brief_names(self):
        # The UI's deep honey verb colour (the violet left the UI palette in #320).
        honey = np.zeros((64, 64, 4))
        honey[..., :3] = (0x8A / 255, 0x5A / 255, 0x00 / 255)
        honey[..., 3] = 1
        base = ["world-props", "world-day", "character"]
        self.assertEqual(qa.check_palette(honey, base).status, "fail")
        self.assertEqual(qa.check_palette(honey, base + ["ui"]).status, "pass")
        tabby = np.zeros((64, 64, 4))
        tabby[..., :3] = (0xD5 / 255, 0x80 / 255, 0x3E / 255)
        tabby[..., 3] = 1
        self.assertNotEqual(qa.check_palette(tabby, ["character"]).status, "pass")
        self.assertEqual(qa.check_palette(tabby, ["character", "character-tabby"]).status, "pass")


class ParentCanvasTests(unittest.TestCase):
    def test_edit_of_an_approved_smaller_parent_compares_on_the_job_canvas(self):
        # Findik's approved 870x1306 master is smaller than the 1024x1536 pose job.
        # Resizing an unchanged approved image must not count as a complete repaint.
        image = canvas(80, 120)
        ImageDraw.Draw(image).rounded_rectangle((15, 40, 65, 110), radius=12, fill=PROP + (255,))
        parent = np.asarray(image, dtype=np.float64) / 255.0
        before = parent.copy()
        child, _ = qa.fit_canvas(parent, (160, 240))
        preset = sl.preset_for("char", sl.load_presets())[1]
        result = qa.process_take(child, "char", (160, 240), preset, ["character"],
                                 parent_locked=parent, registration=dict(qa.EDIT_REGISTRATION))
        kept = next(c for c in result.checks if c.name == "edit_stability")
        self.assertEqual(kept.status, "pass")
        self.assertGreater(kept.value, 0.99)
        self.assertEqual(result.info["parent_canvas"]["source"], [80, 120])
        self.assertEqual(result.info["parent_canvas"]["target"], [160, 240])
        self.assertTrue(np.array_equal(parent, before))

        # Canonicalizing the reference frame must not hide a real whole-body repaint.
        repainted = child.copy()
        repainted[..., :3][repainted[..., 3] > 0.9] = (0.05, 0.1, 0.9)
        changed = qa.process_take(repainted, "char", (160, 240), preset, ["character"],
                                  parent_locked=parent, registration=dict(qa.EDIT_REGISTRATION))
        self.assertEqual(next(c for c in changed.checks if c.name == "edit_stability").status, "fail")


class HarmonyCheckTests(unittest.TestCase):
    """The promote-time harmony score (tools/assets/harmony.py)."""

    def test_the_approved_tea_stall_scores_well_and_a_flat_stall_scores_low(self):
        tea_stall = sl.load_rgba(HERE.parents[2] / "design" / "art" / "stations" / "tea-stall-1" / "tea-stall-1--lock-light.png")
        lim = qa.limits_for("station")
        good = qa.check_harmony(tea_stall, "station", lim)
        self.assertIsNotNone(good)
        self.assertGreater(good.value, 70)
        flat = qa.check_harmony(stall(), "station", lim)
        self.assertLess(flat.value, good.value)
        self.assertNotEqual(flat.status, "fail")  # advisory: harmony corrects what it can

    def test_every_world_kind_gets_a_harmony_line(self):
        res = qa.process_take(stall(), "station", (1024, 1024), sl.load_presets()["lock-light"],
                              ["world-props", "world-day", "character"], register_root=True)
        self.assertIn("harmony", {c.name for c in res.checks})


class StickerGroundLineTests(unittest.TestCase):
    """A sticker is a character centred on a square canvas, not standing on the ground line."""

    def _sticker(self) -> np.ndarray:
        im = canvas()
        ImageDraw.Draw(im).ellipse((312, 312, 712, 712), fill=PROP + (255,))  # feet at 69 % of the height
        return np.asarray(im, dtype=np.float64) / 255.0

    def _names(self, acceptance=None) -> dict:
        raw = self._sticker()
        return {c.name: c for c in qa.run_checks("char", raw, raw, ["character"], acceptance)}

    def test_a_character_is_held_to_the_ground_line_by_default(self):
        self.assertEqual(self._names()["ground_line"].status, "fail")

    def test_a_sticker_turns_the_ground_line_off(self):
        self.assertNotIn("ground_line", self._names({"ground_line": False}))

    def test_the_square_canvas_is_kept(self):
        rgba, check = qa.fit_canvas(self._sticker(), (1024, 1024))
        self.assertEqual(rgba.shape[:2], (1024, 1024))
        self.assertEqual(check.status, "pass")


if __name__ == "__main__":
    unittest.main()


def _box(w, h, base=888, cx=512):
    im = canvas()
    ImageDraw.Draw(im).rounded_rectangle((cx - w / 2, base - h, cx + w / 2, base), radius=20, fill=PROP + (255,))
    return np.asarray(im, dtype=np.float64) / 255.0


class GuideFitTests(unittest.TestCase):
    def test_oversized_decor_is_scaled_to_the_footprint_about_its_anchor(self):
        raw = _box(470, 300)
        g0 = qa.pa.measure(raw)
        fitted, info = qa.fit_to_guide(raw, "prop", "ground")
        g = qa.pa.measure(fitted)
        self.assertAlmostEqual(info["scale"], 360 / 470, delta=0.01)
        self.assertLessEqual(g.width, 361)
        self.assertAlmostEqual(g.base_x, g0.base_x, delta=1.5)
        self.assertAlmostEqual(g.baseline, g0.baseline, delta=1)
        self.assertEqual(info["anchor"][1], g0.baseline)
        # No fringe: every solid pixel keeps the object's colour.
        solid = fitted[..., 3] > 0.99
        off = np.abs(fitted[..., :3][solid] - np.array(PROP) / 255).max(axis=1)
        self.assertLess((off > 0.02).mean(), 0.02)  # only Lanczos ringing at the rim
        self.assertLess(off.max(), 0.2)

    def test_height_bar_limits_a_station(self):
        raw = _box(300, 840, base=900)  # top at y 60, bar at 150
        fitted, info = qa.fit_to_guide(raw, "station")
        self.assertAlmostEqual(info["scale"], 750 / 840, delta=0.01)
        self.assertGreaterEqual(qa.pa.measure(fitted).top, 148)

    def test_station_width_override(self):
        fitted, info = qa.fit_to_guide(stall(), "station", max_width=400)
        self.assertLessEqual(qa.pa.measure(fitted).width, 404)
        self.assertAlmostEqual(info["scale"], 400 / 520, delta=0.01)

    def test_within_limit_is_untouched(self):
        raw = _box(340, 300)
        fitted, info = qa.fit_to_guide(raw, "prop", "ground")
        self.assertIs(fitted, raw)
        self.assertEqual(info["scale"], 1.0)

    def test_far_too_big_is_refused(self):
        raw = _box(700, 380)
        fitted, info = qa.fit_to_guide(raw, "prop", "ground")
        self.assertIs(fitted, raw)
        self.assertIsNone(info["fit"])

    def test_hanging_decor_is_skipped(self):
        raw = _box(480, 200)
        fitted, info = qa.fit_to_guide(raw, "prop", "hang")
        self.assertIs(fitted, raw)
        self.assertIsNone(info["fit"])

    def test_process_take_fits_roots_but_not_edits(self):
        preset = sl.load_presets()["lock-light"]
        pal = ["world-props"]
        raw = _box(470, 300)
        res = qa.process_take(raw, "prop", None, preset, pal, decor="ground", register_root=True, fit={})
        self.assertIn("fit", res.info)
        self.assertLessEqual(qa.pa.measure(res.normalized).width, 361)
        edit = qa.process_take(raw, "prop", None, preset, pal, decor="ground", parent_locked=raw,
                               registration=dict(qa.EDIT_REGISTRATION), fit={})
        self.assertNotIn("fit", edit.info)
        off = qa.process_take(raw, "prop", None, preset, pal, decor="ground", register_root=True, fit=None)
        self.assertNotIn("fit", off.info)

    def test_scale_about_replays_from_meta(self):
        raw = _box(470, 300)
        fitted, info = qa.fit_to_guide(raw, "prop", "ground")
        again = qa.scale_about(raw, info["scale"], tuple(info["anchor"]))
        self.assertTrue(np.allclose(fitted, again))


def _glow(size=256, radius=0.35, soft=True, bg=0.0, levels=None) -> np.ndarray:
    """A warm honey glow on black (opaque), centered; `soft` is a smooth falloff."""
    yy, xx = np.mgrid[:size, :size]
    d = np.hypot(yy - size / 2, xx - size / 2) / (size * radius)
    k = np.clip(1 - d, 0, 1) ** 2 if soft else (d < 1).astype(float) * 0.8
    if levels:  # posterize the falloff into few bands
        k = np.round(k * levels) / levels
    rgb = np.stack([k * 1.0, k * 0.78, k * 0.45], axis=-1) + bg
    return np.concatenate([np.clip(rgb, 0, 1), np.ones((size, size, 1))], axis=-1)


class AdditiveGlowTests(unittest.TestCase):
    def names(self, checks):
        return {c.name: c.status for c in checks}

    def test_soft_glow_on_black_passes_and_skips_value_floor_and_palette(self):
        res = qa.run_checks("ui", _glow(), _glow(), ["world-props"], {"blend": "additive"})
        st = self.names(res)
        self.assertNotIn("value_floor", st)
        self.assertNotIn("palette_drift", st)
        self.assertEqual(st["additive_background"], "pass")
        self.assertEqual(st["additive_falloff"], "pass")
        self.assertEqual(st["additive_banding"], "pass")
        self.assertEqual(st["chroma_ceiling"], "pass")

    def test_the_same_glow_fails_the_default_profile(self):
        st = self.names(qa.run_checks("ui", _glow(), _glow(), ["world-props"], {}))
        self.assertEqual(st["value_floor"], "fail")
        self.assertEqual(st["palette_drift"], "fail")

    def test_grey_background_fails(self):
        st = self.names(qa.additive_checks(_glow(bg=0.2)))
        self.assertEqual(st["additive_background"], "fail")

    def test_hard_edged_disc_fails_the_falloff(self):
        st = self.names(qa.additive_checks(_glow(soft=False)))
        self.assertEqual(st["additive_falloff"], "fail")

    def test_posterized_falloff_is_banding(self):
        st = self.names(qa.additive_checks(_glow(levels=6)))
        self.assertEqual(st["additive_banding"], "fail")

    def test_chroma_is_measured_on_lit_pixels_only(self):
        # Honey gold passes; a saturated blue glow is over the ceiling. The black
        # around the glow (no hue) is not part of the measurement.
        chroma = [c for c in qa.additive_checks(_glow()) if c.name == "chroma_ceiling"][0]
        self.assertLess(chroma.value, qa.ADDITIVE["chroma_p95"]["warn"])
        vivid = _glow()
        vivid[..., :3] = vivid[..., :3] * np.array([1.0, 0.3, 0.0]) / np.array([1.0, 0.78, 0.45])
        vchroma = [c for c in qa.additive_checks(vivid) if c.name == "chroma_ceiling"][0]
        self.assertGreater(vchroma.value, chroma.value)
        self.assertNotEqual(vchroma.status, "pass")

    def test_a_blank_image_has_no_glow(self):
        st = self.names(qa.additive_checks(_glow(radius=0.001)))
        self.assertEqual(st["glow_present"], "fail")

    def test_process_take_ships_black_as_black(self):
        preset = sl.load_presets()["lock-light"]
        res = qa.process_take(_glow(size=512), "ui", (256, 256), preset, ["world-props"], {"blend": "additive"}, transparent=False)
        self.assertLess(float(res.locked[..., :3][:8, :8].max()), 0.02)
        self.assertIn("lock_skipped", res.info)
        self.assertNotIn("fail", [c.status for c in res.checks])


class FoliagePaletteTests(unittest.TestCase):
    def solid(self, hex_):
        a = np.zeros((64, 64, 4))
        a[..., :3] = [int(hex_[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        a[..., 3] = 1
        return a

    def test_foliage_covers_the_olive_greens_and_meadow_flowers(self):
        base = ["character", "character-wilting"]
        for hex_ in ("#A6A05E", "#9C965A","#A4A7CD", "#E9B857", "#F0A9B5", "#C9B8E3"):
            self.assertEqual(qa.check_palette(self.solid(hex_), base + ["world-foliage"]).status, "pass", hex_)

    def test_a_neon_green_is_still_off_the_foliage_family(self):
        self.assertEqual(qa.check_palette(self.solid("#33FF33"), ["world-foliage"]).status, "fail")


class DeclaredCanvasTests(unittest.TestCase):
    def sky(self, w=1024, h=1536):
        return np.ones((h, w, 4)) * 0.8

    def test_declared_size_makes_the_portrait_plate_upscale_by_design(self):
        _, c = qa.fit_canvas(self.sky(), (1290, 2796), cover=True)
        self.assertEqual(c.status, "warn")
        out, c = qa.fit_canvas(self.sky(), (1290, 2796), cover=True, declared=(1024, 1536))
        self.assertEqual((c.status, out.shape[:2]), ("pass", (2796, 1290)))

    def test_an_undeclared_source_size_still_warns(self):
        _, c = qa.fit_canvas(self.sky(800, 1200), (1290, 2796), cover=True, declared=(1024, 1536))
        self.assertEqual(c.status, "warn")
