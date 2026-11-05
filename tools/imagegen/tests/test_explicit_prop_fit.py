"""Plain prop fit overrides must use the final canvas without moving edits."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import qa  # noqa: E402


class ExplicitPropFitTests(unittest.TestCase):
    def setUp(self):
        # The raw prop fits either width budget, but becomes oversized when
        # resized for delivery. Keep all canvas and guide geometry real.
        self.raw = np.zeros((256, 256, 4), dtype=np.float64)
        self.raw[120:220, 3:253] = (0.7, 0.5, 0.3, 1.0)
        self.canvas = (512, 512)
        self.resized, _ = qa.fit_canvas(self.raw, self.canvas)
        self.before = qa.pa.measure(self.resized)
        # Color grading and style QA do not affect the geometry contract.
        self.enterContext(patch.object(qa.sl, "apply_lock", side_effect=lambda rgba, preset: rgba.copy()))
        self.enterContext(patch.object(qa.sl, "measure", return_value={}))
        self.enterContext(patch.object(qa, "run_checks", return_value=[]))

    def process(self, **kwargs):
        return qa.process_take(self.raw, "prop", self.canvas, {}, [], **kwargs)

    def assert_unfitted(self, result):
        np.testing.assert_array_equal(result.normalized, self.resized)
        self.assertNotIn("fit", result.info)
        self.assertNotIn("fit_skipped", result.info)

    def assert_fitted_width(self, width):
        self.assertLess(qa.pa.measure(self.raw).width, width)
        self.assertGreater(self.before.width, width)
        result = self.process(fit={"max_width": width}, declared_size=(256, 256))
        after = qa.pa.measure(result.normalized)
        self.assertEqual(result.normalized.shape, (512, 512, 4))
        # Allow two edge pixels for the actual Lanczos alpha fringe.
        self.assertAlmostEqual(after.width, width, delta=2)
        self.assertAlmostEqual(after.base_x, self.before.base_x, delta=1.5)
        self.assertAlmostEqual(after.baseline, self.before.baseline, delta=1)
        self.assertAlmostEqual(result.info["fit"]["scale"], width / self.before.width, delta=0.0001)

    def test_plain_root_prop_honors_explicit_340_width_after_canvas_resize(self):
        self.assert_fitted_width(340)

    def test_plain_root_prop_honors_explicit_360_width_after_canvas_resize(self):
        self.assert_fitted_width(360)

    def test_plain_root_prop_below_minimum_fit_scale_keeps_source_geometry(self):
        raw = np.zeros((512, 768, 4), dtype=np.float64)
        raw[300:440, 40:723] = (0.7, 0.5, 0.3, 1.0)
        self.assertEqual(qa.pa.measure(raw).width, 683)
        self.assertLess(360 / qa.pa.measure(raw).width, qa.MIN_FIT_SCALE)
        result = qa.process_take(raw, "prop", (768, 512), {}, [], fit={"max_width": 360})
        np.testing.assert_array_equal(result.normalized, raw)
        self.assertNotIn("fit", result.info)
        self.assertIn("below x0.6", result.info["fit_skipped"])

    def test_plain_prop_without_fit_argument_keeps_delivery_geometry(self):
        self.assert_unfitted(self.process())

    def test_plain_prop_with_empty_fit_keeps_delivery_geometry(self):
        self.assert_unfitted(self.process(fit={}))

    def test_plain_prop_with_disabled_fit_keeps_delivery_geometry(self):
        self.assert_unfitted(self.process(fit=None))

    def test_ground_decor_with_disabled_fit_keeps_delivery_geometry(self):
        self.assert_unfitted(self.process(decor="ground", fit=None))

    def test_plain_prop_edit_inherits_parent_geometry_despite_explicit_fit(self):
        result = self.process(fit={"max_width": 340}, parent_locked=self.resized)
        self.assert_unfitted(result)
        np.testing.assert_array_equal(result.locked, self.resized)
        self.assertNotIn("alignment", result.info)

    def test_registered_plain_prop_keeps_geometry_despite_explicit_fit(self):
        result = self.process(fit={"max_width": 340}, registration=dict(qa.EDIT_REGISTRATION))
        self.assert_unfitted(result)

    def test_opaque_plain_prop_keeps_canvas_geometry_despite_explicit_fit(self):
        opaque = self.raw.copy()
        opaque[..., 3] = 1.0
        expected, _ = qa.fit_canvas(opaque, self.canvas, cover=True)
        result = self.process(transparent=False, fit={"max_width": 340})
        np.testing.assert_array_equal(result.normalized, expected)
        self.assertNotIn("fit", result.info)
        self.assertNotIn("fit_skipped", result.info)

    def test_ground_decor_still_uses_default_guide_width(self):
        result = self.process(decor="ground", fit={})
        self.assertAlmostEqual(qa.pa.measure(result.normalized).width, 360, delta=2)
        self.assertLess(result.info["fit"]["scale"], 1.0)

    def test_hanging_decor_is_not_fitted_even_with_explicit_width(self):
        self.assert_unfitted(self.process(decor="hang", fit={"max_width": 340}))


if __name__ == "__main__":
    unittest.main()
