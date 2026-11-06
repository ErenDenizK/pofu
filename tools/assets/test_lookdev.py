"""Tests for the lookdev sheet (tools/assets/lookdev.py).

Run:  python3 -m pytest tools/assets/test_lookdev.py -q
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lookdev as ld  # noqa: E402

CELLS = ld.load_cells()


def graded(rgb, hour):
    return ld.apply_grade(np.array(rgb), ld.grade_params(CELLS[hour]))


def test_grade_matches_hand_computed_swift_formula():
    # WorldGrade.apply worked by hand from the colour-script cells (pivot 0.55 by default).
    np.testing.assert_allclose(graded((0.5, 0.5, 0.5), "day"), [0.49204261, 0.49204261, 0.48960801], atol=1e-6)
    np.testing.assert_allclose(graded((0.8, 0.6, 0.3), "golden"), [0.98522731, 0.57780565, 0.06897463], atol=1e-6)
    # Night: black point 0.32, pivot 0.2, saturation 0.72.
    np.testing.assert_allclose(graded((0.7, 0.6, 0.5), "night"), [0.16492741, 0.14991855, 0.21223324], atol=1e-6)


def test_sky_grade_drops_input_levels():
    p = ld.grade_params(CELLS["night"], sky=True)
    assert p["black"] == 0 and p["white"] == 1


def test_shadow_direction_flips_between_dawn_and_golden():
    dawn = ld.sun_shadow("dawn", CELLS["dawn"])
    golden = ld.sun_shadow("golden", CELLS["golden"])
    assert dawn["dx"] > 0 > golden["dx"]  # sun on the left casts right; sun on the right casts left
    assert dawn["dy"] > 0 and golden["dy"] > 0  # always toward the viewer
    assert ld.sun_shadow("night", CELLS["night"])["opacity"] < 0.15


def test_projected_shadow_leans_with_the_sun():
    mask = np.zeros((200, 200))
    mask[60:100, 95:105] = 1  # a post standing on y=100
    for hour, sign in (("dawn", 1), ("golden", -1)):
        sh = ld.sun_shadow(hour, CELLS[hour])
        out = ld.project_shadow(mask, (100, 100), sh, (200, 200))
        ys, xs = np.nonzero(out > 0.5)
        assert ys.min() >= 99  # flat on the ground, below the foot line
        assert np.sign(xs.mean() - 100) == sign


def test_flag_fires_on_mismatched_layer():
    ground = {"L": 70.0, "C95": 30.0}
    ok = ld.flag_layer({"L": 72.0, "C95": 33.0, "tint": (1.0, 1.0)}, ground, (0.0, 0.0))
    assert not ok["flagged"]
    bad = ld.flag_layer({"L": 40.0, "C95": 80.0, "tint": (15.0, 5.0)}, ground, (0.0, 0.0))
    assert bad["flagged"] and len(bad["flags"]) == 3
