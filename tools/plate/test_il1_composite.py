"""Tests of il1_composite.py on synthetic pictures (no art files): `python3 -I tools/plate/test_il1_composite.py`."""
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import il1_composite as c  # noqa: E402

H, W = 120, 160


def sky(r, g, b):
    return np.dstack([np.full((H, W), v) for v in (r, g, b)])


class Masks(unittest.TestCase):
    def test_polygon_mask_is_soft_and_bounded(self):
        m = c.poly_mask((H, W), [[20, 20], [100, 20], [100, 80], [20, 80]], 6)
        self.assertAlmostEqual(m[50, 60], 1.0, places=3)
        self.assertLess(m[5, 5], 0.001)
        self.assertTrue(0.3 < m[50, 20] < 0.7)  # the edge sits on the polygon's side

    def test_exclude_cuts_a_hole(self):
        r = {"poly": [[0, 0], [160, 0], [160, 120], [0, 120]], "feather": 0,
             "exclude": [{"poly": [[60, 40], [100, 40], [100, 80], [60, 80]], "feather": 0}]}
        m = c.region_mask((H, W), r)
        self.assertEqual(m[60, 80], 0)
        self.assertEqual(m[10, 10], 1)

    def test_union_of_regions(self):
        a = {"poly": [[0, 0], [60, 0], [60, 120], [0, 120]], "feather": 0}
        b = {"poly": [[100, 0], [160, 0], [160, 120], [100, 120]], "feather": 0}
        m = c.donor_mask((H, W), [a, b])
        self.assertEqual((m[60, 30], m[60, 80], m[60, 130]), (1, 0, 1))


class Colour(unittest.TestCase):
    def test_sky_bias_recovers_a_constant_offset(self):
        base = sky(0.45, 0.62, 0.95)
        donor = base + np.array([0.03, 0.012, 0.0])
        m = np.zeros((H, W))
        f = c.sky_bias(base, donor, m)
        self.assertTrue(np.allclose(f, [0.03, 0.012, 0.0], atol=1e-6))

    def test_sky_bias_ignores_the_regions_themselves(self):
        base = sky(0.45, 0.62, 0.95)
        donor = base.copy()
        donor[:, 100:] += 0.2  # a real difference inside the region
        m = np.zeros((H, W))
        m[:, 100:] = 1
        f = c.sky_bias(base, donor, m)
        self.assertLess(abs(f).max(), 1e-6)

    def test_ring_patch_matches_the_ring(self):
        base = np.dstack([np.full((H, W), v) for v in (0.8, 0.6, 0.5)])
        source = np.dstack([np.full((H, W), v) for v in (0.6, 0.5, 0.45)])
        yy, xx = np.mgrid[0:H, 0:W]
        solid = (xx - 80) ** 2 + (yy - 60) ** 2 < 15 ** 2
        patch = c.ring_patch(base, source, solid.astype(float), 3, 16, solid)
        self.assertTrue(np.allclose(patch[60, 80], [0.8, 0.6, 0.5], atol=1e-3))


class Composite(unittest.TestCase):
    def hand(self):
        full = [[0, 0], [160, 0], [160, 60], [0, 60]]
        return {"day": {"regions": [{"poly": full, "feather": 0}], "doors": []}}

    def test_composite_takes_the_donor_in_the_region_and_the_base_elsewhere(self):
        base = sky(0.45, 0.62, 0.95)
        donor = sky(0.5, 0.64, 0.95)
        donor[10:20, 10:20] = (1.0, 1.0, 1.0)  # a cloud the donor has
        base[90:100, 10:20] = (0.2, 0.7, 0.2)  # a lawn the base keeps
        out = c.composite("day", self.hand(), base, donor, base)
        self.assertTrue((out[15, 15] > 0.9).all())                            # the cloud, nearly white (the sky offset is removed from it)
        self.assertTrue(np.allclose(out[40, 80], base[40, 80], atol=1e-6))    # donor sky moved onto the base's
        self.assertTrue(np.allclose(out[95, 15], [0.2, 0.7, 0.2], atol=1e-6))  # outside: the base

    def test_door_patch_is_earth_at_the_ring_colour(self):
        base = sky(0.8, 0.6, 0.5)
        base[50:70, 70:90] = (0.2, 0.3, 0.8)  # the door
        earth = sky(0.6, 0.5, 0.45)
        hand = {"day": {"regions": [], "doors": [{"cx": 80, "cy": 60, "rx": 16, "ry": 16, "feather": 2}]}}
        out = c.composite("day", hand, base, base, earth)
        self.assertTrue(np.allclose(out[60, 80], [0.8, 0.6, 0.5], atol=0.02))

    def test_committed_hand_data_names_existing_takes(self):
        hand = c.load_hand()
        for light in c.LIGHTS:
            for key in ("base", "donor", "earth"):
                self.assertTrue((c.REPO / hand[light][key]).is_file(), hand[light][key])


if __name__ == "__main__":
    unittest.main()
