"""Every mapped imageset has a master and a baked output (tools/assets/integrate.py)."""
import sys
from pathlib import Path

import pytest
from PIL import Image, ImageChops

sys.path.insert(0, str(Path(__file__).resolve().parent))
import integrate  # noqa: E402

REPO = integrate.REPO
DATA = integrate.load_map()


def test_map_is_well_formed():
    assert DATA["entries"]
    names = [(e["target"], e["name"]) for e in DATA["entries"]]
    assert len(names) == len(set(names))
    for e in DATA["entries"]:
        assert e["target"] in DATA["targets"]
        if e["target"] in integrate.FLAT and e["target"] not in ("app", "postcard", "fx"):
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


def test_gate_postcards_are_the_batch_50_masters_with_mist():
    entries = [e for e in DATA["entries"] if e["target"] == "postcard"]
    assert [e["name"] for e in entries] == ["dawn", "day", "golden", "mist", "night", "rain"]
    for e in entries:
        assert e["master"] == f"design/art/masters/gate-postcard-{e['name']}"  # provenance: the master
        out = integrate.output_path(e, DATA["targets"])
        assert Image.open(out).size == (1024, 1536) and out.stat().st_size <= 400_000


def test_weather_fx_are_baked_under_the_hook_names():
    names = {e["name"] for e in DATA["entries"] if e["target"] == "fx"}
    assert names == {"world-fog-card-1", "world-fog-card-2", "world-fog-card-3", "world-rain-tile",
                     "world-rainbow-arc", "world-puddle-glint", "world-light-shaft"}
    for e in DATA["entries"]:
        if e["target"] != "fx":
            continue
        assert e["source"].startswith("design/art/takes/batch-44-weather-fx/")
        image = Image.open(integrate.output_path(e, DATA["targets"]))
        assert image.mode == "RGBA" and image.getchannel("A").getextrema()[1] > 100
        if e["name"].startswith("world-fog-card"):
            assert image.size == (768, 240)  # the ratio FogCardImage lays out


def test_rain_tile_wraps_without_a_seam():
    import numpy as np

    entry = next(e for e in DATA["entries"] if e["name"] == "world-rain-tile")
    alpha = np.asarray(Image.open(integrate.output_path(entry, DATA["targets"])).getchannel("A"), dtype=float)
    assert np.abs(alpha[0] - alpha[-1]).mean() < 6 and np.abs(alpha[:, 0] - alpha[:, -1]).mean() < 6
    assert alpha[0].mean() < 20  # and the tile's own edges stay faint (the seam is blended away)


def test_rain_tile_has_no_dark_streaks():
    """The wrap blend runs through premultiplied colour: a streak blended straight with the clear pixels' black came
    out as a dark half-alpha twin, the dark smeared streaks beside the clean ones in Çağlayan's rain (2026-11)."""
    import numpy as np

    entry = next(e for e in DATA["entries"] if e["name"] == "world-rain-tile")
    rgba = np.asarray(Image.open(integrate.output_path(entry, DATA["targets"])).convert("RGBA"), dtype=float)
    seen = rgba[..., 3] > 24
    assert np.percentile(rgba[..., :3].mean(-1)[seen], 1) > 150


def test_seamless_blends_premultiplied():
    import numpy as np

    a = np.zeros((8, 8, 4), np.uint8)
    a[2, 2] = (230, 240, 255, 200)          # one light pixel; the clear rest is black
    out = np.asarray(integrate._seamless(Image.fromarray(a, "RGBA")), dtype=float)
    lit = out[..., 3] > 0
    assert (out[..., :3][lit].min(-1) > 200).all()


def test_two_tone_icons_are_nine_square_pngs_from_the_take():
    entries = [e for e in DATA["entries"] if e["target"] == "icons-duo"]
    assert [e["name"] for e in entries] == [f"paint-duo-{n}" for n in (
        "home", "island", "map", "settings", "close", "add", "letter", "shield", "gift")]
    for e in entries:
        assert e["source"].startswith("design/art/takes/batch-46-flat-icons/x-icons-flat-duo/")
        image = Image.open(integrate.output_path(e, DATA["targets"]))
        assert image.size == (192, 192) and image.getpixel((0, 0))[3] == 0


def test_the_earth_face_plates_share_the_main_plates_outline():
    # Edits of island-main-l-v3: only the doors differ, the silhouette (alpha) is the same.
    import numpy as np

    def alpha(name):
        base = REPO / "design/art/masters" / name
        return np.asarray(Image.open(integrate.master_file(f"design/art/masters/{name}")).getchannel("A"), dtype=int)

    ref = alpha("island-main-l-v3") > 128
    for name in ("island-main-face-il2", "island-main-face-il6"):
        mask = alpha(name) > 128
        assert (mask & ref).sum() / (mask | ref).sum() > 0.98, name  # the same silhouette (0.5-1 % of edge pixels re-rendered)


def test_kit_faces_are_baked_under_their_hook_names():
    # A `kit` entry bakes a `PofuKitArt` face (Kit/KitArt.swift) and nothing else.
    import re

    swift = (REPO / "Packages/PofuKit/Sources/PofuDesignSystem/Kit/KitArt.swift").read_text(encoding="utf-8")
    hooks = set(re.findall(r'case \w+ = "([\w-]+)"', swift))
    kit = [e for e in DATA["entries"] if e["target"] == "kit"]
    assert kit
    for e in kit:
        assert e["name"] in hooks, e["name"]
        out = integrate.output_path(e, DATA["targets"])
        assert Image.open(out).mode == "RGBA"
