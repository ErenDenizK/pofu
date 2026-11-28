"""screens_diff on synthetic frame folders."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import screens_diff  # noqa: E402


def _frame(folder: Path, name: str, color) -> None:
    folder.mkdir(exist_ok=True)
    Image.new("RGB", (40, 30), color).save(folder / f"{name}.png")


def test_reports_only_frames_outside_the_known_set(tmp_path, capsys):
    a, b = tmp_path / "a", tmp_path / "b"
    for folder, shade in ((a, 10), (b, 11)):
        _frame(folder, "path-home", (1, 2, 3))
        _frame(folder, "path-game-flow-stage1", (shade, 0, 0))
        _frame(folder, "path-row-locked", (shade, 0, 0))
    _frame(b, "path-new", (0, 0, 0))
    assert screens_diff.main([str(a), str(b)]) == 1
    out = capsys.readouterr().out
    assert "CHANGED  path-row-locked" in out
    assert "path-game-flow-stage1" not in out.replace("known", "")
    assert "ADDED    path-new" in out
    assert "1 identical, 0 differ only in glass chrome or specks, 1 differ but known unstable, 1 changed, 0 removed, 1 added" in out


def test_clean_run_exits_zero(tmp_path):
    a, b = tmp_path / "a", tmp_path / "b"
    for folder in (a, b):
        _frame(folder, "path-home", (1, 2, 3))
    assert screens_diff.main([str(a), str(b)]) == 0


def test_glass_and_specks_are_counted_apart(tmp_path, capsys):
    import numpy as np

    a, b = tmp_path / "a", tmp_path / "b"
    a.mkdir(); b.mkdir()
    base = np.full((2622, 1206, 3), 100, dtype=np.uint8)
    for name, edit in (("glass", lambda m: m.__setitem__((slice(2300, 2400), slice(100, 300)), 110)),
                       ("speck", lambda m: m.__setitem__((slice(500, 502), slice(500, 502)), 200)),
                       ("real", lambda m: m.__setitem__((slice(500, 600), slice(500, 600)), 200))):
        moved = base.copy()
        edit(moved)
        Image.fromarray(base).save(a / f"path-{name}.png")
        Image.fromarray(moved).save(b / f"path-{name}.png")
    assert screens_diff.main([str(a), str(b)]) == 1
    out = capsys.readouterr().out
    assert "CHANGED  path-real" in out and "path-glass" not in out and "path-speck" not in out
    assert "2 differ only in glass chrome or specks" in out
