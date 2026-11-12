"""The light standard: prompt block, manifest validation, QA check, grade_take.

Run: python3 -I -m pytest -q tools/imagegen/tests/test_light.py
"""
from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE.parents[1] / "art"))
import grade_take as gt  # noqa: E402
import light as lt  # noqa: E402
import pipeline as pl  # noqa: E402
import qa  # noqa: E402

REFS = {"station-guide": "design/art/templates/station-guide.png"}


def dark_plate(w=480, h=320, seed=4, lo=0.04, hi=0.85) -> np.ndarray:
    """An opaque plate in v1's look: true darks, crisp detail, a wide value range (L about 5-90).
    The references fail nothing of the standard; this fails it."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w]
    base = 0.50 + 0.25 * np.sin(xx / 29.0) * np.cos(yy / 23.0)
    blobs = np.zeros((h, w))
    for _ in range(40):
        cx, cy, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(10, 40)
        blobs += np.exp(-(((xx - cx) ** 2 + (yy - cy) ** 2) / (2 * r * r))) * rng.uniform(-0.25, 0.25)
    fine = rng.normal(0, 0.05, (h, w))
    v = np.clip(base + blobs + fine, lo, hi)
    rgb = np.stack([v, v * 0.97, v * 0.92], axis=-1)
    return np.dstack([np.clip(rgb, 0, 1), np.ones((h, w))])


def take(rel: str) -> np.ndarray:
    import style_lock as sl
    return sl.load_rgba(lt.ART_ROOT / "takes" / rel)


def job(**changes) -> dict:
    j = {"id": "a-1", "kind": "plate", "prompt": [{"text": "A scene."}, {"block": "prop-style-v2"}]}
    j.update(changes)
    return j


def manifest(batch="batch-20-test", jobs=None, **top) -> dict:
    return {"batch": batch, "jobs": jobs or [job()], **top}


class BlockTests(unittest.TestCase):
    def test_every_cell_block_names_the_key_direction_and_colours(self):
        cs = lt.colour_script()["cells"]
        for cell in lt.CELLS:
            text = lt.render_block({"cell": cell, "layer": "subject"})
            key = cs[cell]["key"]
            self.assertIn(lt.direction(key["from"]), text, cell)
            self.assertIn(key["colour"], text, cell)
            self.assertIn(cs[cell]["shadow"], text, cell)
            self.assertIn("reference envelope", text)
            self.assertIn("never black", text)
        self.assertIn("hue change, not a value drop", lt.render_block({"cell": "night", "layer": "subject"}))
        self.assertNotIn("hue change", lt.render_block({"cell": "day", "layer": "subject"}))

    def test_directions_read_naturally(self):
        self.assertEqual(lt.direction([-0.7, -0.7]), "the upper left")
        self.assertEqual(lt.direction([0.95, -0.3]), "the right, a little above")
        self.assertEqual(lt.direction([0.0, -1.0]), "straight above")
        self.assertIn("lower right", lt.opposite([-0.7, -0.7]))

    def test_sprite_block_is_day_and_bans_cast_shadow(self):
        text = lt.render_block({"cell": "day", "layer": "subject"}, sprite=True)
        self.assertIn("upper left", text)
        self.assertIn("Do NOT paint a cast shadow", text)
        self.assertIn("contact occlusion", text)

    def test_layers_differ(self):
        far = lt.render_block({"cell": "day", "layer": "far"})
        sub = lt.render_block({"cell": "day", "layer": "subject"})
        self.assertIn("FAR plane", far)
        self.assertIn("SUBJECT plane", sub)

    def test_style_anchor_v2_drops_the_hard_coded_key(self):
        v1, v2 = pl.read_block("style-anchor-v1"), pl.read_block("style-anchor-v2")
        self.assertIn("upper left", v1)
        self.assertNotIn("upper left", v2)
        self.assertNotIn("rim light along the right", v2)
        self.assertIn("LIGHT block", v2)


class ManifestTests(unittest.TestCase):
    def test_a_new_manifest_must_declare_light(self):
        with self.assertRaisesRegex(pl.ManifestError, "needs `light"):
            pl.parse_manifest(manifest(), REFS)
        m = pl.parse_manifest(manifest(jobs=[job(light={"cell": "dusk", "layer": "subject"})]), REFS)
        self.assertEqual(m.jobs[0].light, {"cell": "dusk", "layer": "subject"})

    def test_defaults_can_carry_light(self):
        m = pl.parse_manifest(manifest(defaults={"light": {"cell": "day", "layer": "near"}}), REFS)
        self.assertEqual(m.jobs[0].light["layer"], "near")

    def test_old_batches_are_grandfathered(self):
        for batch in ("batch-18-loop-1-concepts", "batch-03-home-island", "retry-2026-11-03", "vertical-slice-01"):
            pl.parse_manifest(manifest(batch=batch), REFS)
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest(manifest(batch="retry-2026-11-05"), REFS)
        with self.assertRaises(pl.ManifestError):  # an old batch can opt in
            pl.parse_manifest(manifest(batch="batch-19-x", light_standard=True), REFS)

    def test_ui_kinds_need_no_light_and_may_not_declare_one(self):
        for kind in lt.EXEMPT_KINDS:
            extra = {"transparent": False} if kind == "appicon" else {}
            pl.parse_manifest(manifest(jobs=[job(kind=kind, **extra)]), REFS)
            with self.assertRaises(pl.ManifestError):
                pl.parse_manifest(manifest(jobs=[job(kind=kind, light={"cell": "day", "layer": "subject"}, **extra)]), REFS)

    def test_external_jobs_need_no_light(self):
        pl.parse_manifest(manifest(jobs=[
            {"id": "ext", "kind": "world", "name": "ext", "external": "batch-01-slice"},
            job(light={"cell": "day", "layer": "subject"})]), REFS)

    def test_bad_values_are_rejected(self):
        for bad in ({"cell": "noon", "layer": "subject"}, {"cell": "day", "layer": "mid"}, {"cell": "day"}, "day",
                    {"cell": "day", "layer": "subject", "extra": 1}):
            with self.assertRaises(pl.ManifestError, msg=str(bad)):
                pl.parse_manifest(manifest(jobs=[job(light=bad)]), REFS)

    def test_a_sprite_is_painted_under_day(self):
        sprite = job(kind="prop", light={"cell": "dusk", "layer": "subject"})
        with self.assertRaisesRegex(pl.ManifestError, "day cell"):
            pl.parse_manifest(manifest(jobs=[sprite]), REFS)
        pl.parse_manifest(manifest(jobs=[job(kind="prop", light={"cell": "day", "layer": "far"})]), REFS)
        # an opaque plate may paint any cell
        pl.parse_manifest(manifest(jobs=[job(light={"cell": "night", "layer": "subject"})]), REFS)

    def test_prompt_gets_the_light_block_before_the_output_line(self):
        m = pl.parse_manifest(manifest(jobs=[job(light={"cell": "golden", "layer": "far"})]), REFS)
        text = pl.compose_prompt(m.jobs[0])
        self.assertIn("LIGHT (hour: golden, layer: far)", text)
        self.assertIn("from the right, a little above", text)
        self.assertLess(text.index("LIGHT (hour"), text.index("Output:"))
        old = pl.parse_manifest(manifest(batch="batch-18-x"), REFS)
        self.assertNotIn("LIGHT (hour", pl.compose_prompt(old.jobs[0]))

    def test_shipped_manifests_still_parse(self):
        config = pl.load_config()
        for path in sorted((pl.HERE / "manifest").glob("*.yaml")):
            with self.subTest(path.name):
                pl.load_manifest(path, config)


class StandardTests(unittest.TestCase):
    def test_every_cell_and_layer_has_targets_and_far_planes_are_lighter_and_flatter(self):
        std = lt.standard()
        self.assertEqual(std["version"], 2)
        for cell in lt.CELLS:
            self.assertIn("sky_L", std["cells"][cell]["frame"])
            for layer in lt.LAYERS:
                self.assertIn("p5_min", std["cells"][cell][layer])
            s, f = (std["cells"][cell][l] for l in ("subject", "far"))
            self.assertGreaterEqual(f["p5_min"], s["p5_min"])
            self.assertLessEqual(f["lc_p75"][1], s["lc_p75"][1])

    def test_night_is_a_hue_change_not_a_value_drop(self):
        cells = lt.standard()["cells"]
        day, night = cells["day"]["subject"], cells["night"]["subject"]
        self.assertGreaterEqual(night["median"][0], day["median"][0] - 10)
        self.assertGreaterEqual(night["p5_min"], day["p5_min"] - 10)
        self.assertLess(cells["night"]["frame"]["sky_L"][1], 50)  # only the sky goes dark
        self.assertGreaterEqual(cells["night"]["frame"]["sea_L_min"], 70)  # the sea is the reflector

    def test_colours_are_not_duplicated_in_the_standard(self):
        text = (lt.STANDARD_PATH).read_text(encoding="utf-8")
        self.assertNotRegex(text, r"#[0-9A-Fa-f]{6}")

    def statuses(self, rgba, cell):
        return {n: s for n, s, _, _ in lt.evaluate(lt.measure_light(rgba), {"cell": cell, "layer": "subject"})}

    def test_every_liked_reference_passes_its_cell(self):
        refs = lt.standard()["reference"]
        for cell in ("day", "golden", "night"):
            for rel in refs[cell]:
                with self.subTest(rel):
                    self.assertEqual(set(self.statuses(take(rel), cell).values()), {"pass"})

    def test_the_too_contrasty_night_fails_on_contrast(self):
        for rel in lt.standard()["reference"]["too_contrasty_night"]:
            self.assertEqual(self.statuses(take(rel), "night")["light_contrast"], "fail")

    def test_the_approved_pofu_passes_the_day_subject_cell(self):
        import style_lock as sl
        r1 = lt.ART_ROOT / "masters" / "pofu-hamster-base-v1" / "pofu-hamster-base.png"
        self.assertEqual(set(self.statuses(sl.load_rgba(r1), "day").values()), {"pass"})

    def test_the_dark_earth_band_fails_the_day_cell(self):
        import style_lock as sl
        band = (HERE.parents[2] / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
                / "world-island-main-band2.imageset/world-island-main-band2.png")
        if not band.exists():
            self.skipTest("app resource not in this checkout (pofu-art)")
        self.assertEqual(self.statuses(sl.load_rgba(band), "day")["light_values"], "fail")

    def test_a_crushed_night_frame_fails(self):
        # The game's night before ADR-0021: island L* 10-50 under a near-black sky and sea.
        frame = dark_plate(lo=0.02, hi=0.45)
        s = self.statuses(frame, "night")
        for name in ("light_values", "light_median", "light_sea", "light_dark"):
            self.assertEqual(s[name], "fail", name)


class CheckAndGradeTests(unittest.TestCase):
    LIGHT = {"cell": "day", "layer": "subject"}

    def statuses(self, rgba, enforce, light=None):
        return {c.name: c.status for c in qa.check_light(rgba, light or self.LIGHT, enforce=enforce)}

    def test_a_dark_contrasty_take_fails_then_passes_once_graded(self):
        t = dark_plate()
        before = self.statuses(t, enforce=True)
        self.assertEqual(before["light_values"], "fail")
        graded, info = gt.grade_rgba(t, self.LIGHT)
        self.assertIn("airlight", info)
        after = self.statuses(graded, enforce=True)
        self.assertEqual({after[k] for k in ("light_values", "light_median")}, {"pass"}, after)
        np.testing.assert_array_equal(graded[..., 3], t[..., 3])

    def test_a_night_take_is_lifted_into_the_band_and_a_graded_take_is_left_alone(self):
        night = {"cell": "night", "layer": "subject"}
        graded, _ = gt.grade_rgba(dark_plate(), night)
        m = lt.measure_light(graded)
        lo, hi = lt.targets(night)["median"]
        self.assertTrue(lo - 2 <= m["L_p50"] <= hi, m)
        self.assertGreaterEqual(m["L_p5"], lt.targets(night)["p5_min"] - 1, m)
        again, _ = gt.grade_rgba(graded, night)
        self.assertLess(abs(lt.measure_light(again)["L_p50"] - m["L_p50"]), 3)

    def test_a_reference_is_left_alone(self):
        ref = take(lt.standard()["reference"]["day"][0])
        _, info = gt.grade_rgba(ref, self.LIGHT)
        self.assertEqual(info, {})

    def test_the_standard_is_warn_only_until_enforced(self):
        t = dark_plate()
        self.assertTrue(lt.standard()["enforce"] is False)
        shipped = self.statuses(t, enforce=None)
        self.assertNotIn("fail", shipped.values())
        self.assertIn("warn", shipped.values())

    def test_exploration_downgrades_a_failing_light_check(self):
        checks = qa.advisory(qa.check_light(dark_plate(), self.LIGHT, enforce=True))
        self.assertNotIn("fail", {c.status for c in checks})

    def test_light_replaces_value_floor_in_run_checks(self):
        t = dark_plate()
        names = [c.name for c in qa.run_checks("plate", t, t, ["world-props"], light=self.LIGHT)]
        self.assertIn("light_values", names)
        self.assertNotIn("value_floor", names)
        names = [c.name for c in qa.run_checks("plate", t, t, ["world-props"])]
        self.assertIn("value_floor", names)
        self.assertNotIn("light_values", names)


if __name__ == "__main__":
    unittest.main()
