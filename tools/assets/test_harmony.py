"""Tests for the asset harmony tool (tools/assets/harmony.py).

Run:  python3 -I -m unittest discover -s tools/assets -p "test_*.py"
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harmony as hm  # noqa: E402

sl = hm.sl


def solid(rgb, size=(64, 64), alpha=1.0) -> np.ndarray:
    a = np.zeros(size + (4,))
    a[..., :3] = np.asarray(rgb, dtype=float)
    a[..., 3] = alpha
    return a


def lab_patch(L, a, b, size=(64, 64)) -> np.ndarray:
    rgb = sl.lab_to_srgb(np.array([[L, a, b]], dtype=float))[0]
    return solid(rgb, size)


class MeasureTests(unittest.TestCase):
    def test_lightness_percentiles_and_chroma(self):
        img = lab_patch(70, 20, 30)
        img[:8] = lab_patch(30, 0, 0, (8, 64))
        stats = hm.measure(img, ppu=4.0)
        self.assertAlmostEqual(stats["L_p2"], 30, delta=1.0)
        self.assertAlmostEqual(stats["L_p98"], 70, delta=1.0)
        self.assertAlmostEqual(stats["C_p95"], 36, delta=1.5)

    def test_white_balance_reads_the_neutrals(self):
        img = lab_patch(80, 3, 9)  # a warm off-white
        stats = hm.measure(img, ppu=4.0)
        self.assertAlmostEqual(stats["tint_a"], 3, delta=0.6)
        self.assertAlmostEqual(stats["tint_b"], 9, delta=0.6)

    def test_edge_softness_is_in_world_units(self):
        hard = solid((0.5, 0.5, 0.5), (80, 80), 0.0)
        hard[20:60, 20:60, 3] = 1.0
        soft = hard.copy()
        for k, a in enumerate((0.25, 0.5, 0.75)):
            soft[17 + k:63 - k, 17 + k:63 - k, 3] = np.maximum(soft[17 + k:63 - k, 17 + k:63 - k, 3], a)
        e_hard = hm.measure(hard, ppu=2.0)["edge"]
        e_soft = hm.measure(soft, ppu=2.0)["edge"]
        self.assertLess(e_hard, 0.1)
        self.assertGreater(e_soft, 1.0)
        # Twice the pixels per unit, half the width in units.
        self.assertAlmostEqual(hm.measure(soft, ppu=4.0)["edge"], e_soft / 2, delta=0.01)

    def test_nothing_opaque_is_an_error(self):
        with self.assertRaises(ValueError):
            hm.measure(solid((1, 1, 1), alpha=0.0), ppu=4.0)


class PlanTests(unittest.TestCase):
    cfg = hm.load_config()
    ref = {"L_p2": 50.0, "L_p98": 93.0, "C_p95": 48.0, "tint_a": 2.0, "tint_b": 8.0, "edge": 1.0, "detail": 1.0}

    def test_within_tolerance_is_left_as_painted(self):
        stats = dict(self.ref, L_p2=55.0, C_p95=50.0)
        self.assertTrue(hm.is_identity(hm.plan(stats, self.ref, self.cfg, guarded=False)))

    def test_a_pale_master_gets_its_blacks_and_chroma_back(self):
        stats = dict(self.ref, L_p2=70.0, C_p95=30.0)
        corr = hm.plan(stats, self.ref, self.cfg, guarded=False)
        self.assertLess(corr["black"], -10)
        self.assertGreater(corr["chroma"], 1.3)
        self.assertLessEqual(corr["chroma"], self.cfg["correction"]["chroma_scale"][1])

    def test_guarded_assets_are_never_corrected(self):
        stats = dict(self.ref, L_p2=80.0, C_p95=10.0)
        self.assertTrue(hm.is_identity(hm.plan(stats, self.ref, self.cfg, guarded=True)))
        self.assertTrue(hm.is_guarded("pofu", self.cfg))
        self.assertTrue(hm.is_guarded("cloud-3", self.cfg))
        self.assertFalse(hm.is_guarded("cay-1", self.cfg))

    def test_characters_only_get_white_balance(self):
        stats = dict(self.ref, C_p95=20.0, tint_b=2.0)
        corr = hm.plan(stats, self.ref, self.cfg, guarded=False, kind="char")
        self.assertEqual(corr["chroma"], 1.0)
        self.assertGreater(corr["tint_b"], 0)

    def test_a_faded_chain_level_is_matched_to_its_first_level(self):
        # Each level was redrawn from its locked parent and locked again, so
        # chroma fell level by level (PR #67): cay-5 against cay-1.
        self.assertEqual(hm.chain_of("cay-5", self.cfg), ("cay", 5))
        self.assertIsNone(hm.chain_of("island-main", self.cfg))
        first = dict(self.ref, C_p50=40.0, C_p95=55.0, L_p2=46.0, L_p98=92.0)
        faded = dict(self.ref, C_p50=11.0, C_p95=20.0, L_p2=60.0, L_p98=92.0)
        corr = hm.plan(faded, self.ref, self.cfg, guarded=False, kind="station", chain=first)
        self.assertGreater(corr["chroma"], 2.5)
        self.assertLessEqual(corr["chroma"], self.cfg["chains"]["chroma_scale"][1])
        self.assertEqual(corr["ceiling"], 55.0)
        self.assertLess(corr["black"], -10)
        devs = hm.deviations(faded, self.ref, self.cfg, "station", first)
        self.assertIn("chain_C_p50", devs)
        self.assertNotIn("C_p95", devs)

    def test_score_is_100_at_the_reference_and_falls_with_distance(self):
        self.assertEqual(hm.score(self.ref, self.ref, self.cfg), 100.0)
        one = dict(self.ref, L_p98=self.ref["L_p98"] + self.cfg["metrics"]["L_p98"]["tolerance"])
        far = dict(self.ref, L_p98=self.ref["L_p98"] + 3 * self.cfg["metrics"]["L_p98"]["tolerance"])
        self.assertGreater(hm.score(one, self.ref, self.cfg), hm.score(far, self.ref, self.cfg))
        self.assertEqual(hm.outliers(far, self.ref, self.cfg), ["L_p98"])


class ApplyTests(unittest.TestCase):
    cfg = hm.load_config()

    def test_levels_move_the_black_point_and_keep_alpha(self):
        img = lab_patch(80, 5, 10)
        img[:16] = lab_patch(60, 5, 10, (16, 64))
        img[..., 3] = np.linspace(0.2, 1, 64)[None, :]
        src = hm.measure(img, ppu=4.0)
        corr = dict(json.loads(json.dumps(hm.IDENTITY)), black=-20.0)
        out = hm.apply(img, corr, src)
        np.testing.assert_array_equal(out[..., 3], img[..., 3])
        after = hm.measure(out, ppu=4.0)
        self.assertAlmostEqual(after["L_p2"], src["L_p2"] - 20, delta=1.0)
        self.assertAlmostEqual(after["L_p98"], src["L_p98"], delta=1.0)

    def test_the_copper_warms_inside_its_region_only(self):
        # A rose copper (hue 54) on both halves of the canvas; the region covers the left half.
        h = 54.0
        img = lab_patch(62, 40 * np.cos(np.radians(h)), 40 * np.sin(np.radians(h)), (40, 80))
        mat = dict(self.cfg["materials"]["copper"])
        mat["_region"] = hm._region_weight((40, 80), [0.0, 0.0, 0.5, 1.0], feather=0.0)
        mats = {"copper": mat}
        before = hm.measure(img, ppu=4.0, materials=mats)
        corr = dict(json.loads(json.dumps(hm.IDENTITY)), materials={"copper": {"hue_shift": 7.0, "chroma_scale": 1.1}})
        out = hm.apply(img, corr, before, mats)
        _, C, H = sl.lch(sl.srgb_to_lab(out[..., :3]))
        self.assertAlmostEqual(float(H[20, 10]), h + 7, delta=1.0)
        self.assertGreater(float(C[20, 10]), 42)
        self.assertAlmostEqual(float(H[20, 70]), h, delta=0.5)

    def test_identity_is_a_copy(self):
        img = lab_patch(70, 10, 20)
        out = hm.apply(img, hm.IDENTITY)
        np.testing.assert_array_equal(out, img)
        self.assertIsNot(out, img)


class ManifestTests(unittest.TestCase):
    def test_stale_lists_what_changed(self):
        fresh = {"config_sha": "a", "assets": {"x": {"source_sha": "1", "correction": hm.IDENTITY}}}
        self.assertEqual(hm.stale(fresh, fresh), [])
        old = {"config_sha": "b", "assets": {"x": {"source_sha": "2", "correction": hm.IDENTITY}, "y": {}}}
        problems = hm.stale(old, fresh)
        self.assertEqual(len(problems), 3)

    def test_the_committed_manifest_covers_every_shipped_source(self):
        manifest = json.loads(hm.MANIFEST.read_text())
        shipped = hm.world_sources(hm.load_config())
        for name in shipped:
            self.assertIn(name, manifest["assets"])
            self.assertTrue(manifest["assets"][name]["shipped"])
        # The çaydanlık is the founder's cold-copper case: corrected toward warm copper.
        cay = manifest["assets"]["cay-1"]
        self.assertIn("copper", cay["correction"]["materials"])
        self.assertGreater(cay["after"]["materials"]["copper"]["hue"], cay["before"]["materials"]["copper"]["hue"] + 3)
        # The faded chain levels come back toward their L1's median chroma.
        for level in ("cay-2", "cay-3"):
            e = manifest["assets"][level]
            self.assertLess(abs(e["after"]["C_p50"] - e["chain"]["C_p50"]), self.cfg_tol())

    def cfg_tol(self):
        return hm.load_config()["chains"]["metrics"]["C_p50"]["tolerance"]


if __name__ == "__main__":
    unittest.main()
