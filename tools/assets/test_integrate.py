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
        if e["target"] in integrate.FLAT and e["target"] not in ("app", "postcard"):
            assert len(e["points"]) == 2 and e.get("scale", 3) in (1, 2, 3)


@pytest.mark.parametrize("entry", DATA["entries"], ids=lambda e: f"{e['target']}:{e['name']}")
def test_entry_has_master_and_output(entry):
    assert integrate.source_file(entry) is not None, f"no source image for {entry['name']}"
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


def _sheet_tables():
    """Every cell table of the experience art: (sheet folder, cells by name, the alpha level a piece
    is judged at)."""
    preblur = _preblur()
    tables = [
        (preblur.GARDEN_SHEET, preblur.GARDEN_CELLS, 8),
        (preblur.HARBOR_SHEET, preblur.HARBOR_CELLS, 8),
    ]
    for sheet in (preblur.CRITTER_BUTTERFLY_SHEET, preblur.CRITTER_SNAIL_SHEET, preblur.CRITTER_BIRD_SHEET):
        cells = {n: c for n, (s, _k, c, _f) in preblur.CRITTER_CELLS.items() if s == sheet}
        tables.append((sheet, cells, preblur.CRITTER_ALPHA_FLOOR))
    return preblur, tables


def test_experience_sheet_cells_cut_every_piece_cleanly():
    # Each cell holds one whole piece and nothing of a neighbour: disjoint, inside the sheet, and the
    # piece (above the halation floor) clear of the cell's edges by at least 5 px.
    import numpy as np

    preblur, tables = _sheet_tables()
    for sheet_dir, cells, level in tables:
        sheet = Image.open(integrate.master_file(sheet_dir)).convert("RGBA")
        alpha = np.asarray(sheet.getchannel("A")) > level
        claimed = np.zeros_like(alpha)
        assert cells, sheet_dir
        for name, (x0, y0, x1, y1) in cells.items():
            assert 0 <= x0 < x1 <= sheet.width and 0 <= y0 < y1 <= sheet.height, name
            assert not claimed[y0:y1, x0:x1].any(), f"{name} overlaps another cell"
            claimed[y0:y1, x0:x1] = True
            ys, xs = np.where(alpha[y0:y1, x0:x1])
            assert len(xs), f"{name} is empty"
            assert xs.min() >= 5 and ys.min() >= 5 and xs.max() <= (x1 - x0) - 6 and ys.max() <= (y1 - y0) - 6, name


def test_experience_cells_are_registered_in_the_map_and_harmony():
    preblur, tables = _sheet_tables()
    mapped = {e["name"] for e in DATA["entries"] if e["target"] == "world"}
    for sheet_dir, cells, _level in tables:
        folder = sheet_dir.rsplit("/", 1)[-1]
        assert set(cells) <= mapped, folder
        for name, cell in cells.items():
            spec = preblur.APP_SOURCES[name]
            assert spec["cell"] == cell and spec["harmony_as"] == folder and spec["harmony"] is False, name


def test_critter_frames_share_a_baseline_and_face_right():
    # Every cell of a sheet ends on one line (6 px under the feet), so the frames swap in place; the
    # sprites all face right (the sheets' left-facing frames are mirrored).
    preblur, tables = _sheet_tables()
    for sheet_dir, cells, _level in tables:
        if "critter-" not in sheet_dir:
            continue
        assert len({c[3] for c in cells.values()}) == 1, sheet_dir
    flips = {n: spec.get("flip", False) for n, spec in preblur.APP_SOURCES.items() if n.startswith("critter-")}
    assert all(flips[n] for n in flips if n.startswith("critter-butterfly"))
    assert not any(flips[n] for n in flips if n.startswith("critter-snail"))
    assert [flips[n] for n in ("critter-bird", "critter-bird-2", "critter-bird-3", "critter-bird-4")] == [True, True, False, False]


def test_experience_flat_entries_have_their_outputs():
    targets = DATA["targets"]
    by_target = {}
    for e in DATA["entries"]:
        by_target.setdefault(e["target"], []).append(e["name"])
    assert {"glow-window-spill", "glow-warm-halo", "glow-pond-shimmer"} <= set(by_target["glow"])
    assert [n for n in by_target["sprite"]] == ["firefly-1", "firefly-2", "firefly-3"]
    assert set(by_target["shield"]) == {f"shield-pofu-door-{m}" for m in ("calm", "proud", "sleepy")}
    assert set(by_target["app"]) == {"launch-sky", "cloud-curtain-1", "cloud-curtain-2", "cloud-curtain-3"}
    for e in DATA["entries"]:
        if e["target"] in ("sprite", "shield", "app", "glow"):
            assert integrate.output_path(e, targets).is_file(), e["name"]


def test_launch_sky_is_restored_to_its_declared_size():
    entry = next(e for e in DATA["entries"] if e["name"] == "launch-sky")
    out = integrate.output_path(entry, DATA["targets"])
    assert Image.open(out).size == (1290, 2796)


def test_shield_plates_are_square_and_small():
    for mood in ("calm", "proud", "sleepy"):
        entry = next(e for e in DATA["entries"] if e["name"] == f"shield-pofu-door-{mood}")
        out = integrate.output_path(entry, DATA["targets"])
        image = Image.open(out)
        assert image.size == (360, 360) and image.mode == "RGBA"
        assert out.stat().st_size < 400_000


def test_shield_icons_are_round_180_and_under_30_kb():
    names = ("curious", "proud", "jealous", "calm", "relieved", "sleepy")
    entries = [e for e in DATA["entries"] if e["target"] == "shield-icons"]
    assert [e["name"] for e in entries] == [f"shield-pofu-{n}" for n in names]
    for e in entries:
        assert e["source"].startswith("design/art/takes/")  # provenance: the exploration take
        out = integrate.output_path(e, DATA["targets"])
        image = Image.open(out).convert("RGBA")
        assert image.size == (180, 180)
        assert image.getpixel((0, 0))[3] == 0 and image.getpixel((90, 90))[3] >= 240  # round, on transparency
        assert out.stat().st_size <= 30_000
