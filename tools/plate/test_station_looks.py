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


@pytest.mark.parametrize("stage", sorted(sl.BASES))
def test_outside_the_region_the_base_is_the_parent(stage):
    import ingest
    import heic
    x, info = sl.build_base(stage, sl.BASES[stage])
    p = f"world-home-plate-day-{stage}"
    with heic.open_image(ingest.ASSETS / f"{p}.imageset" / f"{p}{heic.SUFFIX}") as im:
        plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    cx = info["crop"][0] * sl.TEX
    cy = info["crop"][1] * sl.TEX
    x0, y0, x1, y1 = sl.BASES[stage]["window"]
    far = np.ones(plate.shape[:2], bool)
    far[max(y0 - cy - 80, 0):y1 - cy + 80, max(x0 - cx - 80, 0):x1 - cx + 80] = False
    seen = far & ((plate[..., 3] > 0.01) | (x[..., 3] > 0.01))          # a clear pixel's colour is never drawn
    assert np.abs(x[seen][:, 3] - plate[seen][:, 3]).max() < 1 / 255
    assert np.abs(x[seen][:, :3] - plate[seen][:, :3]).max() < 1 / 255
    inside = ~far
    assert np.abs(x[inside] - plate[inside]).max() > 0.2       # the stall is gone there
    assert (x[..., 3] <= plate[..., 3] + 1e-6).all()           # the alpha only shrinks


def test_every_base_stage_has_a_place_and_the_looks_scale_about_the_foot():
    assert set(sl.PLACE) == set(sl.BASES)
    data = sl.stations_data()["teaStall"]
    ref = data["box"]
    assert sorted(data["baseStages"]) == sorted(sl.BASES)
    for stage, place in data["stages"].items():
        k, (fx, fy) = place["scale"], place["foot"]
        assert place["box"][0] == pytest.approx(fx + (ref[0] - 690.0) * k, abs=0.01)
        assert place["box"][3] == pytest.approx(fy + (ref[3] - 832.0) * k, abs=0.01)
        assert 0.8 < k < 1.3


def test_no_base_without_a_pick_and_the_other_stages_keep_their_stall():
    # day level 8 (stage 2) has no pick; levels 5 and 2 (stages 5, 8) and the tile-roof stages 0 and 1 have no clean base
    for stage in (0, 1, 2, 5, 8, 9):
        assert stage not in sl.BASES
    for stage, spec in sl.BASES.items():
        assert sl.pick_of(spec["job"]) >= 1


# ---------------------------------------------------------------- the windmill (plan row 1b)

def test_the_windmill_has_looks_2_to_5_over_bases_at_stages_0_to_2():
    data = sl.stations_data(sl.WINDMILL)["windmill"]
    assert data["levels"] == 5
    assert data["baseStages"] == [0, 1, 2]
    assert data["lookLevels"] == {"day": [2, 3, 4, 5]}      # level 1 has no pick: it draws nothing, not a made-up look
    ref = data["box"]
    rx, ry = sl.WINDMILL["foot"]
    for stage, place in data["stages"].items():
        k, (fx, fy) = place["scale"], place["foot"]
        assert place["box"][0] == pytest.approx(fx + (ref[0] - rx) * k, abs=0.01)
        assert place["box"][3] == pytest.approx(fy + (ref[3] - ry) * k, abs=0.01)
        assert 0.85 < k < 1.1
    assert data["lookBytes"] and len(data["lookBytes"]) == 4


def test_windmill_stages_are_the_ones_the_plate_paints_it_on_and_have_a_pick():
    for stage, spec in sl.WINDMILL["bases"].items():
        assert sl.pick_of(spec["job"]) >= 1
        assert stage in (0, 1, 2)                               # the plate paints the mill at island levels 10, 9, 8


def test_a_windmill_looks_edge_carries_no_sky_and_the_levels_share_one_canvas():
    import ingest
    import heic
    sizes = set()
    for n in (2, 3, 4, 5):
        name = sl.look_name("windmill", n, "day")
        with heic.open_image(ingest.ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
            x = np.asarray(im.convert("RGBA"), np.float32) / 255
        sizes.add(x.shape[:2])
        edge = (x[..., 3] > 0.05) & (x[..., 3] < 0.9)
        sky = sl.sky_alpha(x[..., :3]) < 0.5                     # blue where the grass is not
        assert (edge & sky).sum() < 0.01 * edge.sum() + 20, f"look {n}: sky-coloured pixels on the edge"
        assert max(x[0, :, 3].max(), x[-1, :, 3].max(), x[:, 0, 3].max(), x[:, -1, 3].max()) < 0.02, f"look {n}: clipped by its canvas"
    assert len(sizes) == 1


@pytest.mark.parametrize("stage", sorted(sl.WINDMILL["bases"]))
def test_the_windmill_base_is_the_parent_outside_the_window_and_the_alpha_only_shrinks(stage):
    import ingest
    import heic
    spec = sl.WINDMILL["bases"][stage]
    x, info = sl.build_base(stage, spec)
    p = f"world-home-plate-day-{stage}"
    with heic.open_image(ingest.ASSETS / f"{p}.imageset" / f"{p}{heic.SUFFIX}") as im:
        plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    cx, cy = info["crop"][0] * sl.TEX, info["crop"][1] * sl.TEX
    x0, y0, x1, y1 = spec["window"]
    far = np.ones(plate.shape[:2], bool)
    far[max(y0 - cy - 80, 0):y1 - cy + 80, max(x0 - cx - 80, 0):x1 - cx + 80] = False
    seen = far & ((plate[..., 3] > 0.01) | (x[..., 3] > 0.01))
    assert np.abs(x[seen][:, 3] - plate[seen][:, 3]).max() < 1 / 255
    assert np.abs(x[seen][:, :3] - plate[seen][:, :3]).max() < 1 / 255
    assert (x[..., 3] <= plate[..., 3] + 1e-6).all()
    assert np.abs(x[~far] - plate[~far]).max() > 0.2            # the mill is gone there


def test_the_workshop_the_bakery_wing_stands_on_is_not_in_the_windmills_cut():
    # the bakery wing of levels 4 and 5 is cut away: no look pixel stands right of the tower's wall below the sail
    masks, _, _ = sl.plot_masks(sl.WINDMILL["plot"])
    wing = sl.WINDMILL["plot"]["wing"]
    for n in (4, 5):
        assert not masks[n][wing["y"]:, wing["x"] + 45:].any(), f"level {n}: the wing is in the cut"


# ---------------------------------------------------------------- the pond and shared bases (plan row 1c)

def test_the_pond_has_five_looks_over_the_bases_at_stages_0_to_3():
    data = sl.stations_data(sl.POND)["pond"]
    assert data["levels"] == 5 and "lookLevels" not in data           # every level has a cut that holds
    assert data["baseStages"] == [0, 1, 2, 3]
    assert len(data["lookBytes"]) == 5
    for stage, place in data["stages"].items():
        fx, fy = place["foot"]
        x0, y0, x1, y1 = place["box"]
        assert x0 < fx < x1 and y0 < fy < y1


def test_every_pond_stage_has_a_pick_and_the_plate_keeps_its_garden_fence_and_mailbox():
    for stage, spec in sl.POND["bases"].items():
        assert sl.pick_of(spec["job"]) >= 1
        assert spec["job"].endswith(f"l{10 - stage:02d}-day")
        assert spec["interior"] is True                              # a window inside the island has no hill line to cut and keeps its alpha
        assert "mailbox" in spec["excludeOccluders"]


def test_the_pond_cut_has_the_water_and_not_the_lawn_or_the_plates_flowers():
    masks, rgbs, _ = sl.plot_masks(sl.POND["plot"])
    assert set(masks) == {1, 2, 3, 4, 5}
    areas = {n: m.mean() for n, m in masks.items()}
    assert all(0.05 < a < 0.5 for a in areas.values()), areas
    assert areas[5] > areas[1]                                        # the lake of level 5 is bigger than the level 1 pool
    for n, m in masks.items():
        if n == 2:
            continue                                                  # its reeds are lawn-green and stay
        lawn = sl._lawn(rgbs[n])
        assert (m & lawn).sum() < 0.2 * m.sum(), f"level {n}: the lawn is in the cut"       # leaves of the pavilion are green


def test_stations_that_share_a_stage_share_one_base_that_has_both_erased():
    import ingest
    import heic
    stage = 3
    assert [sp["id"] for sp in sl.stage_specs(stage)] == ["teaStall", "pond"]
    both, info, _ = sl.accumulate_base(stage)
    tea_only, _ = sl.build_base(stage, sl.TEA_STALL["bases"][stage])
    p = f"world-home-plate-day-{stage}"
    with heic.open_image(ingest.ASSETS / f"{p}.imageset" / f"{p}{heic.SUFFIX}") as im:
        plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    cx, cy = info["crop"][0] * sl.TEX, info["crop"][1] * sl.TEX
    px0, py0, px1, py1 = sl.POND["bases"][stage]["window"]
    tx0, ty0, tx1, ty1 = sl.TEA_STALL["bases"][stage]["window"]
    pond_win = (slice(py0 - cy, py1 - cy), slice(px0 - cx, px1 - cx))
    tea_win = (slice(ty0 - cy, ty1 - cy), slice(tx0 - cx, tx1 - cx))
    # the tea stall's window is the tea-only base's, the pond's window is no longer the plate's
    assert np.abs(both[tea_win] - tea_only[tea_win]).max() < 1e-6
    assert np.abs(both[pond_win] - plate[pond_win]).max() > 0.2
    assert np.abs(tea_only[pond_win] - plate[pond_win]).max() < 1e-6    # alone, the tea stall leaves the pond painted
    assert (both[..., 3] <= plate[..., 3] + 1e-6).all()                 # the alpha only shrinks
    assert [r[0] for r in info["regions"]] == ["teaStall", "pond"]


def test_a_shared_stage_counts_its_base_once_in_the_texture_budget():
    import ingest
    stations = ingest.stations_data("home")
    shared = {k: v["baseBytes"]["3"] for k, v in stations.items() if "3" in v.get("baseBytes", {})}
    assert set(shared) == {"teaStall", "pond"}
    looks = sum(sum(sorted(stations[k]["lookBytes"])[-2:]) for k in shared)
    assert ingest.station_bytes("home", "day", 3) == max(shared.values()) + looks
