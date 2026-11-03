"""Tests for the island metrics (python3 -I -m pytest -q tools/content/tests)."""
import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import island_metrics as im  # noqa: E402
import validate  # noqa: E402


def data():
    return copy.deepcopy(im.load())


def test_repository_profiles_have_no_violations():
    violations, sched = im.check(data())
    assert violations == []
    assert sched["caglayan"]["arrival"] == 4


def test_every_profile_names_an_existing_island_node():
    nodes, _ = validate.load_content()
    ids = {n["id"] for n in nodes if n.get("type") == "island"}
    for name, isl in data()["islands"].items():
        assert isl["node"] in ids, name


def test_profiles_file_is_not_read_as_a_node():
    nodes, errors = validate.load_content()
    assert not any(n["_file"].name == "profiles.yaml" for n in nodes)
    assert errors == []


def test_satellite_that_shares_nothing_is_flagged():
    d = data()
    d["islands"]["koke"]["axes"] = {ax: f"other-{ax}" for ax in d["axes"]}
    violations, _ = im.check(d)
    assert any(v.startswith("satellite: koke shares 0") for v in violations)


def test_consecutive_bigs_too_alike_are_flagged():
    d = data()
    d["islands"]["gezgin"]["axes"] = dict(d["islands"]["caglayan"]["axes"])
    violations, _ = im.check(d)
    assert any(v.startswith("bigs: caglayan -> gezgin") for v in violations)


def test_runway_counts_consecutive_beats():
    assert im.runway({"beats": {0: "a", 1: "b", 3: "c"}}) == 2
    assert im.runway({"beats": {0: "a"}}) == 1


def test_richer_island_earns_a_longer_gap():
    d = data()
    before = im.schedule(d)["gezgin"]["arrival"]
    d["islands"]["koke"]["beats"] = {i: "beat" for i in range(8)}
    after = im.schedule(d)["gezgin"]["arrival"]
    assert after > before


def test_dead_days_are_flagged():
    d = data()
    d["islands"]["koke"]["beats"] = {0: "arrival"}
    d["islands"]["caglayan"]["beats"] = {0: "arrival", 1: "stage 1"}
    d["rules"]["big_gap"] = 12
    violations, _ = im.check(d)
    assert any(v.startswith("dead days") for v in violations)


def test_stacked_wows_are_flagged():
    d = data()
    # Revontuli blooms on the day the whale blooms.
    sched = im.schedule(d)
    d["islands"]["revontuli"]["bloom"] = sched["gezgin"]["bloom"] - sched["revontuli"]["arrival"]
    violations, _ = im.check(d)
    assert any("stacked wows" in v for v in violations)


def test_palette_drift_and_home_palette_are_flagged():
    d = data()
    d["palette_deltas"]["water"]["hue"] = 120
    d["islands"]["caglayan"]["axes"]["palette"] = d["islands"]["aycicegi"]["axes"]["palette"]
    violations, _ = im.check(d)
    assert any(v.startswith("palette: water drifts") for v in violations)
    assert any("uses the home palette" in v for v in violations)


def test_two_god_tier_islands_back_to_back_are_flagged():
    d = data()
    d["islands"]["canlar"]["tier"] = "god"
    d["islands"]["canlar"]["intensity"] = 9
    violations, _ = im.check(d)
    assert any("back to back" in v for v in violations)


def test_the_hook_must_land_early():
    d = data()
    d["rules"]["tiers"]["hook_by"] = 5
    violations, _ = im.check(d)
    assert any("the hook must land" in v for v in violations)


def test_founder_score_of_the_current_design_judges_it():
    d = data()
    d["islands"]["gezgin"]["founder_scores"].append({"loop": 1, "date": "2026-11-10", "score": 6, "note": "x"})
    violations, sched = im.check(d)
    assert any(v.startswith("tier: gezgin founder score 6") for v in violations)
    # A weak island holds the player less long.
    assert sched["gezgin"]["runway"] == d["rules"]["tiers"]["weak_runway"]


def test_scores_of_an_older_design_are_history():
    d = data()
    # Gezgin was scored 7 in loop 0 and redesigned in loop 1: the 7 no longer judges it.
    assert im.latest_score(d["islands"]["gezgin"]) is None
    assert im.latest_score(d["islands"]["revontuli"]) == 10


def test_founder_targets_are_checked():
    d = data()
    d["targets"]["koke"] = {"arrival": [1, 2]}
    violations, _ = im.check(d)
    assert any(v.startswith("target: koke") for v in violations)


def test_cluster_without_an_atmosphere_is_flagged():
    d = data()
    del d["atmospheres"]["water"]
    violations, _ = im.check(d)
    assert "atmosphere: cluster water has none" in violations


def test_two_clusters_under_one_light_are_flagged():
    d = data()
    d["atmospheres"]["moon"] = dict(d["atmospheres"]["cold"])
    violations, _ = im.check(d)
    assert any(v.startswith("atmosphere: cold / moon differ on 0") for v in violations)


def test_reusing_home_haze_is_flagged():
    d = data()
    d["atmospheres"]["water"]["haze"] = d["atmospheres"]["home"]["haze"]
    violations, _ = im.check(d)
    assert any(v.startswith("atmosphere: water reuses home's haze") for v in violations)


def test_big_island_without_a_game_is_flagged():
    d = data()
    del d["play"]["gezgin"]
    violations, _ = im.check(d)
    assert "play: gezgin has no playable island block" in violations


def test_plate_with_too_few_stations_is_flagged():
    d = data()
    d["play"]["canlar"]["stations"] = ["the bell"]
    violations, _ = im.check(d)
    assert any(v.startswith("play: canlar has 1 stations") for v in violations)
