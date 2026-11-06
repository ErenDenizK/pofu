"""Root character ground fit and masked lit edits (emit_region)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import pipeline as pl  # noqa: E402
import qa  # noqa: E402


def char(top: int, bottom: int, size: int = 400) -> np.ndarray:
    img = np.zeros((size, size, 4))
    img[top:bottom, 150:250] = (0.6, 0.4, 0.3, 1.0)
    return img


class Patched(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(qa.sl, "apply_lock", side_effect=lambda rgba, preset: rgba.copy()))
        self.enterContext(patch.object(qa.sl, "measure", return_value={}))


class GroundFitTests(Patched):
    def run_fit(self, img, fit):
        self.enterContext(patch.object(qa, "run_checks", return_value=[]))
        return qa.process_take(img, "char", (400, 400), {}, [], fit=fit)

    def test_low_character_moves_up_to_88_percent(self):
        r = self.run_fit(char(200, 384), {"ground": True})  # feet at 96%
        self.assertAlmostEqual(qa.pa.measure(r.normalized).baseline, 352, delta=1)
        self.assertEqual(r.info["fit"]["scale"], 1.0)
        self.assertLess(r.info["fit"]["dy"], 0)

    def test_tall_character_also_shrinks_to_keep_headroom(self):
        r = self.run_fit(char(10, 390), {"ground": True})
        g = qa.pa.measure(r.normalized)
        self.assertAlmostEqual(g.baseline, 352, delta=1)
        self.assertGreaterEqual(g.top, 7)
        self.assertLess(r.info["fit"]["scale"], 1.0)

    def test_without_ground_flag_nothing_moves(self):
        for fit in (None, {}):
            r = self.run_fit(char(200, 384), fit)
            np.testing.assert_array_equal(r.normalized, char(200, 384))
            self.assertNotIn("fit", r.info)

    def test_edit_keeps_parent_geometry(self):
        parent = char(200, 384)
        self.enterContext(patch.object(qa, "run_checks", return_value=[]))
        r = qa.process_take(parent.copy(), "char", (400, 400), {}, [], fit={"ground": True}, parent_locked=parent)
        self.assertNotIn("fit", r.info)


class EmitRegionTests(unittest.TestCase):
    def setUp(self):
        self.enterContext(patch.object(qa.sl, "apply_lock", side_effect=lambda rgba, preset: rgba.copy()))
        self.enterContext(patch.object(qa.sl, "measure", return_value={}))
        # The whole-image edit checks would fail this take; the region must silence them.
        self.enterContext(patch.object(qa, "run_checks", return_value=[
            qa.Check("edit_stability", "fail", "x"), qa.Check("edit_chroma", "fail", "x"), qa.Check("palette", "pass", "x")]))
        self.parent = np.zeros((200, 200, 4))
        self.parent[20:180, 20:180] = (0.5, 0.5, 0.5, 1.0)
        self.take = self.parent.copy()
        self.take[40:80, 40:80] = (0.9, 0.6, 0.2, 1.0)      # the light, inside the region
        self.take[120:160, 120:160] = (0.2, 0.2, 0.9, 1.0)  # a stray change outside it
        self.region = [[0.15, 0.15, 0.35, 0.35]]

    def process(self, region):
        return qa.process_take(self.take, "prop", (200, 200), {}, [], parent_locked=self.parent, emit_region=region)

    def test_master_equals_parent_outside_region(self):
        r = self.process(self.region)
        outside = qa.emit_mask((200, 200), self.region) < 0.001
        np.testing.assert_allclose(r.locked[outside], self.parent[outside], atol=0.01)
        np.testing.assert_allclose(r.locked[50:70, 50:70], self.take[50:70, 50:70], atol=0.01)
        self.assertEqual(r.info["emit_region"], self.region)

    def test_leakage_is_warn_not_fail_and_stability_is_not_judged(self):
        r = self.process(self.region)
        status = {c.name: c.status for c in r.checks}
        self.assertEqual(status["emit_leak"], "warn")
        self.assertNotIn("edit_stability", status)
        self.assertNotIn("edit_chroma", status)
        self.assertNotIn("fail", status.values())

    def test_clean_take_passes_leak_check(self):
        self.take[120:160, 120:160] = self.parent[120:160, 120:160]
        status = {c.name: c.status for c in self.process(self.region).checks}
        self.assertEqual(status["emit_leak"], "pass")

    def test_without_region_whole_take_ships(self):
        r = self.process(None)
        self.assertGreater(r.locked[140, 140, 2], 0.7)
        self.assertNotIn("emit_region", r.info)

    def test_mask_feather_is_soft_and_small(self):
        m = qa.emit_mask((1000, 1000), [[0.2, 0.2, 0.5, 0.5]])
        self.assertEqual(m[450, 450], 1.0)
        self.assertEqual(m[50, 50], 0.0)
        edge = m[450, 190:211]
        self.assertTrue(0 < edge.max() <= 1 and (np.diff(edge) >= 0).all())
        self.assertLess(((m[450] > 0) & (m[450] < 1)).sum(), 40)  # ~2% of a 500 px box = 10 px per edge


class ManifestTests(unittest.TestCase):
    def parse(self, **job):
        base = {"id": "tea-stall-1", "kind": "station", "prompt": [{"text": "A tea stall."}],
                "light": {"cell": "day", "layer": "subject"}}
        edit = {"id": "tea-stall-lit", "kind": "station", "edit_of": "tea-stall-1", "prompt": [{"text": "Light it."}, {"block": "edit-keep-v1"}],
                "light": {"cell": "day", "layer": "subject"}}
        edit.update(job)
        return pl.parse_manifest({"batch": "test-batch", "jobs": [base, edit]}, {})

    def test_emit_region_boxes_parse_as_fractions(self):
        m = self.parse(emit_region=[{"x": 0.1, "y": 0.2, "w": 0.3, "h": 0.4}, [0.5, 0.5, 0.2, 0.2]])
        self.assertEqual(m.job("tea-stall-lit").emit_region, [[0.1, 0.2, 0.3, 0.4], [0.5, 0.5, 0.2, 0.2]])

    def test_emit_region_rejects_bad_boxes(self):
        for bad in ([[0.8, 0.1, 0.4, 0.2]], [[0.1, 0.1, 0, 0.2]], [], "x", [{"x": 1}]):
            with self.assertRaises(pl.ManifestError):
                self.parse(emit_region=bad)

    def test_emit_region_needs_edit_of(self):
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest({"batch": "test-batch", "jobs": [
                {"id": "tea-stall-1", "kind": "station", "prompt": [{"text": "x"}], "emit_region": [[0, 0, 1, 1]],
                 "light": {"cell": "day", "layer": "subject"}}]}, {})

    def test_ground_fit_only_on_root_char(self):
        with self.assertRaises(pl.ManifestError):
            self.parse(fit={"ground": True})
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest({"batch": "test-batch", "jobs": [
                {"id": "tea-stall-1", "kind": "station", "fit": {"ground": True}, "prompt": [{"text": "x"}],
                 "light": {"cell": "day", "layer": "subject"}}]}, {})


if __name__ == "__main__":
    unittest.main()
