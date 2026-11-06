"""Tests for nightlab's pure maths."""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nightlab as nl  # noqa: E402

P = nl.PARAMS


def test_attenuation_values():
    assert nl.attenuation(0.0, 100.0) == 1.0
    assert abs(nl.attenuation(50.0, 100.0) - 0.75 ** 2) < 1e-12
    assert nl.attenuation(100.0, 100.0) == 0.0
    assert nl.attenuation(250.0, 100.0) == 0.0


def test_unlight_compresses_highlights():
    alpha = np.ones((32, 32))
    rgb = np.full((32, 32, 3), 0.5)
    rgb[:, :16] = 0.98
    out = nl.unlight(rgb, alpha, P, 32)
    hi_before, lo_before = 0.98, 0.5
    # compression alone shrinks the gap between bright and mid; the blur division keeps the mean
    gap_before = hi_before - lo_before
    gap_after = nl.lum(out[16, 4]) - nl.lum(out[16, 28])
    assert gap_after < gap_before


def test_hemisphere_sky_up_ground_down():
    up = nl.hemisphere(np.array(1.0), P)
    down = nl.hemisphere(np.array(-1.0), P)
    assert np.allclose(up, P["hemi"]["sky"])
    assert np.allclose(down, P["hemi"]["ground"])
