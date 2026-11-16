"""Tests for tools/plate/station_looks.py: the alpha rules, the contact shade and the shipped looks and base."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import station_looks as sl  # noqa: E402
import ingest as _ingest  # noqa: E402
import pytest  # noqa: E402


@pytest.fixture(autouse=True)
def _keep_ingest_size():
    """`ingest.load_hand` sets the module's SIZE and COLOR_FIT to the island's; other tests expect their own."""
    size, fit = _ingest.SIZE, dict(_ingest.COLOR_FIT)
    yield
    _ingest.SIZE = size
    _ingest.COLOR_FIT.clear()
    _ingest.COLOR_FIT.update(fit)


def test_alpha_is_normalised():
    a = np.zeros((40, 40), np.uint8)
    a[5:30, 5:30] = 200
    a[10, 10] = 10              # below 16: clear
    a[6, 6] = 245               # 240 and over: opaque
    out = sl.normalise_alpha(a)
    assert out[10, 10] == 255   # a pinhole of one pixel inside the shape is filled (it was clear, enclosed, under 64)
    assert out[6, 6] == 255
    assert out[20, 20] == 200


def test_specks_and_pinholes_under_64_px():
    a = np.zeros((60, 60), np.uint8)
    a[10:50, 10:50] = 255
    a[20:23, 20:23] = 0         # a 9 px enclosed hole: filled
    a[30:40, 30:40] = 0         # a 100 px hole: stays
    a[2:4, 2:4] = 255           # a 4 px island: dropped
    out = sl.normalise_alpha(a)
    assert out[21, 21] == 255
    assert out[35, 35] == 0
    assert out[3, 3] == 0


def test_a_clear_notch_on_the_border_is_not_a_hole():
    a = np.zeros((30, 30), np.uint8)
    a[:, 10:] = 255
    a[0:3, 15:18] = 0
    assert sl.normalise_alpha(a)[1, 16] == 0


def test_contact_shade_follows_the_bottom_contour_not_an_ellipse():
    alpha = np.zeros((120, 160), np.float32)
    alpha[20:90, 20:140] = 1            # a counter
    alpha[90:110, 100:106] = 1          # one tripod foot, lower than the counter
    shade = sl.contact_shade(alpha)
    assert shade[108, 103] > 0.15                       # under the foot
    assert shade[100, 40] < shade[108, 103] or shade[100, 40] < 0.1   # nothing deep under the counter's middle, far from its bottom
    assert shade[115:, :].max() < shade[108, 103]       # it does not run on below the contour
    assert shade[:20].max() < 0.01                      # none above the cut-out


def test_the_shipped_looks_share_one_canvas_and_the_base_is_the_plates_size():
    import ingest
    import heic
    sizes = set()
    for n in range(1, 6):
        name = sl.look_name("teaStall", n, "day")
        with heic.open_image(ingest.ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
            sizes.add(im.size)
    assert len(sizes) == 1
    p, b = "world-home-plate-day-7", sl.base_name("day", 7)
    with heic.open_image(ingest.ASSETS / f"{p}.imageset" / f"{p}{heic.SUFFIX}") as a, heic.open_image(ingest.ASSETS / f"{b}.imageset" / f"{b}{heic.SUFFIX}") as c:
        assert a.size == c.size


def test_outside_the_region_the_base_is_the_parent():
    import ingest
    import heic
    x, info = sl.build_base(7)
    p = "world-home-plate-day-7"
    with heic.open_image(ingest.ASSETS / f"{p}.imageset" / f"{p}{heic.SUFFIX}") as im:
        plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    cx = info["crop"][0] * sl.TEX
    cy = info["crop"][1] * sl.TEX
    x0, y0, x1, y1 = sl.BASES[7]["window"]
    far = np.ones(plate.shape[:2], bool)
    far[max(y0 - cy - 80, 0):y1 - cy + 80, max(x0 - cx - 80, 0):x1 - cx + 80] = False
    seen = far & ((plate[..., 3] > 0.01) | (x[..., 3] > 0.01))          # a clear pixel's colour is never drawn
    assert np.abs(x[seen][:, 3] - plate[seen][:, 3]).max() < 1 / 255
    assert np.abs(x[seen][:, :3] - plate[seen][:, :3]).max() < 1 / 255
    inside = ~far
    assert np.abs(x[inside] - plate[inside]).max() > 0.2       # the stall is gone there
    assert (x[..., 3] <= plate[..., 3] + 1e-6).all()           # the alpha only shrinks
