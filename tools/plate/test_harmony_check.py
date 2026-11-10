"""Tests for harmony_check.py (python3 -I tools/plate/test_harmony_check.py)."""
from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harmony_check as hc  # noqa: E402

W, H = 603, 1311  # half the iPhone 17's device pixels: the same geometry, faster


def data() -> dict:
    return json.loads(hc.PLATE_JSON.read_text())


def frame(lawn, body) -> np.ndarray:
    """A frame with a flat lawn over the walkable polygon and flat character bodies."""
    d = data()
    f = np.full((H, W, 3), 0.7)
    m, fx, fy = hc.frame_map(d, W)
    f[hc.polygon_mask((H, W), [(fx(x), fy(y)) for x, y in d["walkable"]])] = lawn
    for n, c in hc.characters(d, W).items():
        f[hc.ellipse_mask((H, W), c["ellipse"])] = body[n] if isinstance(body, dict) else body
    return f


class Geometry(unittest.TestCase):
    def test_pofu_is_33_points_wide_and_stands_on_his_spot(self):
        d = data()
        c = hc.characters(d, 402)  # a 1x frame: pixels are points
        self.assertAlmostEqual(c["pofu"]["width"], 33, delta=0.6)
        m, fx, fy = hc.frame_map(d, 402)
        x, y = d["characters"]["pofu"]
        self.assertAlmostEqual(c["pofu"]["feet"][0], fx(x))
        self.assertAlmostEqual(c["pofu"]["feet"][1], fy(y))
        # The island is homeWidths screens wide, its top homeTopY down.
        box = d["islandBox"]
        self.assertAlmostEqual(fx(box[2]) - fx(box[0]), 402 * d["framing"]["homeWidths"], delta=0.01)
        self.assertAlmostEqual(fy(box[1]), d["framing"]["homeTopY"], delta=0.01)

    def test_friends_are_at_least_60_percent_of_pofus_painted_height(self):
        d = data()
        m, _, _ = hc.frame_map(d, 402)
        unit = d["pofuWidth"] / 64 * m
        pofu = 64 * 496 / 522 * unit
        for name, art_h in {"mochi": 23.333, "findik": 27.067}.items():
            h = art_h * unit * d["residentBoosts"][name]
            self.assertGreaterEqual(h / pofu, 0.6, name)

    def test_every_body_is_on_the_lawn_ring_with_room(self):
        r = hc.measure(frame([0.4, 0.7, 0.3], [0.9, 0.85, 0.8]), data())
        self.assertEqual(set(r), {"pofu", "mochi", "findik"})


class Measure(unittest.TestCase):
    def test_a_character_the_colour_of_its_lawn_has_no_difference(self):
        r = hc.measure(frame([0.4, 0.7, 0.3], [0.4, 0.7, 0.3]), data())
        for v in r.values():
            self.assertAlmostEqual(v["dL"], 0, delta=0.2)
            self.assertAlmostEqual(v["dC"], 0, delta=0.2)

    def test_a_pale_body_on_a_rich_lawn_is_lighter_and_flatter(self):
        r = hc.measure(frame([0.4, 0.7, 0.3], [0.9, 0.86, 0.84]), data())
        self.assertGreater(r["pofu"]["dL"], 5)
        self.assertLess(r["pofu"]["dC"], -20)

    def test_band_accepts_the_reference_and_flags_a_body_that_does_not_follow_the_light(self):
        ok = hc.in_band({n: {"dL": v[0], "dC": v[1]} for n, v in hc.REF.items()})
        self.assertTrue(all(ok.values()))
        # A day-bright sprite on a night lawn: far lighter than by day.
        bad = hc.in_band({"pofu": {"dL": hc.REF["pofu"][0] + 25, "dC": -5}})
        self.assertFalse(bad["pofu"])
        # Louder than its lawn.
        loud = hc.in_band({"pofu": {"dL": hc.REF["pofu"][0], "dC": hc.CAP_C + 3}})
        self.assertFalse(loud["pofu"])
        # A calm lawn lets a character be as grey as it is: dC* near zero is in band.
        calm = hc.in_band({"pofu": {"dL": hc.REF["pofu"][0] + 3, "dC": 3}})
        self.assertTrue(calm["pofu"])

    def test_night_characters_must_not_be_the_brightest_thing_on_the_lawn(self):
        ok = hc.no_sticker({"pofu": {"p95": 70.0, "stone": 78.0}, "mochi": {"p95": 74.8, "stone": 74.8}})
        self.assertTrue(all(ok.values()))
        sticker = hc.no_sticker({"pofu": {"p95": 85.0, "stone": 80.0}})
        self.assertFalse(sticker["pofu"])

    def test_a_flat_night_body_is_measured_against_the_stones_around_it(self):
        # Bodies at L* ~ 70 on a flat lawn that is as light: the p95 of the body is its own colour, the
        # ring's is the lawn's, so a body lighter than the lawn is a sticker.
        light = hc.measure(frame([0.55, 0.6, 0.5], [0.95, 0.9, 0.88]), data())
        dark = hc.measure(frame([0.55, 0.6, 0.5], [0.3, 0.3, 0.3]), data())
        self.assertFalse(all(hc.no_sticker(light).values()))
        self.assertTrue(all(hc.no_sticker(dark).values()))

    def test_golden_fur_must_follow_the_lawns_hue_by_half(self):
        def r(fur, lawn):
            return {"pofu": {"hue": fur, "lawnHue": lawn}}
        # The lawn turns 10 degrees; the fur 6 the same way: ok. 3: not enough. Opposite way: no.
        self.assertTrue(hc.follows_hue(r(70, 100), r(64, 90))[0])
        self.assertFalse(hc.follows_hue(r(70, 100), r(67, 90))[0])
        self.assertFalse(hc.follows_hue(r(70, 100), r(76, 90))[0])
        # A lawn that did not move asks nothing; hue wraps around 180.
        self.assertTrue(hc.follows_hue(r(70, 100), r(70, 101))[0])
        self.assertTrue(hc.follows_hue(r(175, 175), r(-175, -175))[0])

    def test_the_wrong_frame_size_fails_loudly(self):
        with self.assertRaises(SystemExit):
            hc.measure(np.full((20, 20, 3), 0.5), data())


if __name__ == "__main__":
    unittest.main()
