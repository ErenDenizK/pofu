"""Tests of composition_check.py on hand-made sidecars. Run: python3 -I -m unittest discover -s tools/proof -p "test_*.py" """
from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import composition_check as cc  # noqa: E402


def box(x, y, w, h):
    return [x, y, x + w, y + h]


def journey_stage3() -> dict:
    """A Map still, Home in front (journey): Home's foot at 0.80, islands tappable and clear of the safe bands."""
    isl = lambda i, x, y, w, h: {"id": i, "type": "island", "box": box(x, y, w, h), "island": box(x, y, w, h), "tappable": True, "w_pt": w}
    return {
        "name": "map-journey-stage3", "kind": "map", "order": "journey", "horizon": None,
        "hero": box(100, 560, 200, 140),
        "subjects": [isl("home", 100, 560, 200, 139.2), isl("a", 40, 380, 120, 100), isl("b", 240, 250, 120, 100), isl("c", 60, 120, 110, 90)],
        "chrome": [{"id": "top_bar", "box": box(16, 62, 370, 50)}, {"id": "card", "box": box(16, 740, 370, 90)}, {"id": "corner_home", "box": box(330, 770, 52, 52)}],
        "features": [{"id": "isle1", "box": box(330, 440, 60, 36)}, {"id": "whale", "box": box(10, 540, 60, 40)}, {"id": "lip", "box": box(0, 700, 402, 40)}],
    }


class CompositionCheck(unittest.TestCase):
    def test_journey_tier1_stage3_passes(self):
        res = cc.check(journey_stage3())
        self.assertEqual([k for k, (ok, _) in res.items() if not ok], [])
        self.assertEqual(sorted(res), ["C1", "C2", "C3", "C4", "C5", "C6"])

    def test_isle_on_a_slot_fails_c6(self):
        m = copy.deepcopy(journey_stage3())
        m["features"].append({"id": "isle2", "box": box(110, 570, 60, 40)})     # sits on Home's art box
        res = cc.check(m)
        self.assertFalse(res["C6"][0])
        self.assertIn("isle2", res["C6"][1])


if __name__ == "__main__":
    unittest.main()
