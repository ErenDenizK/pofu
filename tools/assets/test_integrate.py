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
        if e["target"] in integrate.FLAT:
            assert len(e["points"]) == 2 and e.get("scale", 3) in (1, 2, 3)


@pytest.mark.parametrize("entry", DATA["entries"], ids=lambda e: f"{e['target']}:{e['name']}")
def test_entry_has_master_and_output(entry):
    assert integrate.master_file(entry["master"]) is not None, f"no master in {entry['master']}"
    assert integrate.output_path(entry, DATA["targets"]).is_file(), "output missing; run integrate.py run"


def test_games_outputs_are_current(tmp_path):
    # Re-baking must reproduce the committed pixels (deterministic).
    for e in DATA["entries"]:
        if e["target"] not in integrate.FLAT:
            continue
        out = tmp_path / f"{e['name']}.png"
        integrate.bake_games(e, out)
        a = Image.open(out).convert("RGBA")
        b = Image.open(integrate.output_path(e, DATA["targets"])).convert("RGBA")
        assert a.size == b.size and ImageChops.difference(a, b).getbbox() is None, f"{e['name']} is stale"


def test_every_paint_case_has_a_png():
    import re

    root = integrate.REPO / DATA["targets"]["ui"]
    swift = (integrate.REPO / "Packages/PofuKit/Sources/PofuDesignSystem/PofuPaint.swift").read_text(encoding="utf-8")
    names = re.findall(r'case \w+ = "(paint-[\w-]+)"', swift)
    assert len(names) >= 20
    missing = [n for n in names if not (root / f"{n}.png").is_file()]
    assert not missing, missing


def test_every_garden_art_case_has_a_png():
    import re

    root = integrate.REPO / DATA["targets"]["games"]
    swift = (integrate.REPO / "Packages/PofuKit/Sources/PofuGames/Scene/GardenArt.swift").read_text(encoding="utf-8")
    names = re.findall(r'case \w+ = "(garden-[\w-]+)"', swift)
    assert len(names) >= 18
    missing = [n for n in names if not (root / f"{n}.png").is_file()]
    assert not missing, missing


def _preblur():
    import importlib.util

    spec = importlib.util.spec_from_file_location("preblur", integrate.PREBLUR)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_meadow_sheet_cells_cut_every_piece_cleanly():
    # Each cell holds one whole piece and nothing of its neighbours: the cells are disjoint, and together
    # they hold every visible pixel of the sheet (a cut that clipped a piece, or took a bit of the next
    # one, changes the count).
    import numpy as np

    preblur = _preblur()
    sheet = Image.open(integrate.master_file(preblur.MEADOW_SHEET)).convert("RGBA")
    alpha = np.asarray(sheet.getchannel("A")) > 8
    cells = preblur.MEADOW_CELLS
    assert len(cells) == 12
    claimed = np.zeros_like(alpha)
    for name, (x0, y0, x1, y1) in cells.items():
        assert 0 <= x0 < x1 <= sheet.width and 0 <= y0 < y1 <= sheet.height, name
        assert not claimed[y0:y1, x0:x1].any(), f"{name} overlaps another cell"
        claimed[y0:y1, x0:x1] = True
        piece = alpha[y0:y1, x0:x1]
        ys, xs = np.where(piece)
        assert len(xs), f"{name} is empty"
        # The cell is the piece's box padded by 6 px: nothing is cut at an edge.
        assert xs.min() >= 5 and ys.min() >= 5 and xs.max() <= (x1 - x0) - 6 and ys.max() <= (y1 - y0) - 6, name
    assert alpha[~claimed].sum() == 0, "visible pixels outside every cell"


def test_meadow_cells_are_registered_in_the_map():
    preblur = _preblur()
    mapped = {e["name"] for e in DATA["entries"] if e["target"] == "world"}
    assert set(preblur.MEADOW_CELLS) <= mapped
    for name in preblur.MEADOW_CELLS:
        spec = preblur.APP_SOURCES[name]
        assert spec["cell"] == preblur.MEADOW_CELLS[name] and spec["harmony_as"] == "dressing-meadow"
