"""Every mapped imageset has a master and a baked output (tools/assets/integrate.py)."""
import sys
from pathlib import Path

import pytest
from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).resolve().parent))
import integrate  # noqa: E402

DATA = integrate.load_map()


def test_map_is_well_formed():
    assert DATA["entries"]
    names = [(e["target"], e["name"]) for e in DATA["entries"]]
    assert len(names) == len(set(names))
    for e in DATA["entries"]:
        assert e["target"] in DATA["targets"]
        if e["target"] == "games":
            assert len(e["points"]) == 2 and e.get("scale", 3) in (1, 2, 3)


@pytest.mark.parametrize("entry", DATA["entries"], ids=lambda e: f"{e['target']}:{e['name']}")
def test_entry_has_master_and_output(entry):
    assert integrate.master_file(entry["master"]) is not None, f"no master in {entry['master']}"
    assert integrate.output_path(entry, DATA["targets"]).is_file(), "output missing; run integrate.py run"


def test_games_outputs_are_current(tmp_path):
    # Re-baking must reproduce the committed pixels (deterministic).
    for e in DATA["entries"]:
        if e["target"] != "games":
            continue
        out = tmp_path / f"{e['name']}.png"
        integrate.bake_games(e, out)
        a = Image.open(out).convert("RGBA")
        b = Image.open(integrate.output_path(e, DATA["targets"])).convert("RGBA")
        assert a.size == b.size and ImageChops.difference(a, b).getbbox() is None, f"{e['name']} is stale"


def test_every_garden_art_case_has_a_png():
    import re

    root = integrate.REPO / DATA["targets"]["games"]
    swift = (integrate.REPO / "Packages/PofuKit/Sources/PofuGames/Scene/GardenArt.swift").read_text(encoding="utf-8")
    names = re.findall(r'case \w+ = "(garden-[\w-]+)"', swift)
    assert len(names) >= 18
    missing = [n for n in names if not (root / f"{n}.png").is_file()]
    assert not missing, missing
