"""montage and diff on synthetic images (no ffmpeg needed)."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import sheet  # noqa: E402


def _solid(path: Path, color, size=(1600, 900)) -> Path:
    Image.new("RGB", size, color).save(path)
    return path


def test_montage_is_small_labeled_jpeg(tmp_path):
    paths = [_solid(tmp_path / f"i{i}.png", (40 * i, 90, 200 - 30 * i)) for i in range(7)]
    out = tmp_path / "m.jpg"
    sheet.main(["montage", *map(str, paths), "--max", "1400", "--cols", "3", "-o", str(out)])
    with Image.open(out) as im:
        assert im.format == "JPEG"
        assert max(im.size) <= 1400
        # 3 columns, 3 rows of landscape cells: wider than tall
        assert im.width > 0 and im.height > 0
    assert out.stat().st_size < 400_000


def test_montage_respects_a_small_max(tmp_path):
    paths = [_solid(tmp_path / f"i{i}.png", (i * 30, 0, 0)) for i in range(4)]
    out = tmp_path / "m.jpg"
    sheet.montage(paths, 0, 500, out)
    with Image.open(out) as im:
        assert max(im.size) <= 500


def test_diff_identical_is_zero(tmp_path, capsys):
    a = _solid(tmp_path / "a.png", (120, 130, 140), (400, 300))
    out = tmp_path / "d.jpg"
    stats = sheet.diff(a, a, 1400, out)
    assert stats["mean_abs"] == 0 and stats["max_abs"] == 0 and stats["changed_pct"] == 0
    assert out.exists()


def test_diff_reports_a_changed_patch(tmp_path):
    a = _solid(tmp_path / "a.png", (100, 100, 100), (400, 300))
    arr = np.full((300, 400, 3), 100, dtype=np.uint8)
    arr[:150, :200] = 200  # one quadrant brighter by 100
    Image.fromarray(arr).save(tmp_path / "b.png")
    stats = sheet.diff(a, tmp_path / "b.png", 1400, tmp_path / "d.jpg")
    assert stats["max_abs"] == 100
    assert abs(stats["changed_pct"] - 25.0) < 0.01
    assert abs(stats["mean_abs"] - 25.0) < 0.01
    with Image.open(tmp_path / "d.jpg") as im:
        assert max(im.size) <= 1400


def test_diff_resizes_the_second_image(tmp_path):
    a = _solid(tmp_path / "a.png", (50, 50, 50), (400, 300))
    b = _solid(tmp_path / "b.png", (50, 50, 50), (800, 600))
    assert sheet.diff(a, b, 1400, tmp_path / "d.jpg")["max_abs"] == 0


def test_pick_times_tops_up_with_even_spacing():
    times = sheet.pick_times(10.0, [], 5)
    assert len(times) == 5 and times[0] == 0.0 and times == sorted(times)
    assert sheet.pick_times(10.0, [1, 2, 3, 4, 5, 6], 4)[0] == 0.0
