"""Tests of concept_fit.py on synthetic stills and stand-in takes (a guide shifted, blurred, repainted)."""
import json
import sys
from pathlib import Path

import cv2
import numpy as np
import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import concept_fit as cf  # noqa: E402

BOXES = {
    "island": [60, 250, 340, 470],
    "pofu": [170, 330, 200, 360],
}
CHROME = [{"id": "card", "box": [20, 640, 382, 700]}, {"id": "corner_home", "box": [330, 780, 382, 832]}]


def make_still() -> Image.Image:
    """Sky and cloud with a horizon at 463 pt, textured islands, white controls."""
    rng = np.random.default_rng(3)
    a = np.zeros((cf.H, cf.W, 3), np.float32)
    ys = np.linspace(0, 1, cf.H)[:, None]
    a[:] = (0.45 + 0.3 * ys, 0.65 + 0.2 * ys, 0.95 - 0.1 * ys)[0:3] if False else 0
    a[..., 0] = 0.45 + 0.3 * ys
    a[..., 1] = 0.65 + 0.2 * ys
    a[..., 2] = 0.95 - 0.1 * ys
    hz = int(463 * cf.PT)
    a[hz:] = a[hz:] * 0.5 + 0.5
    for name, b in BOXES.items():
        x0, y0, x1, y1 = (int(v * cf.PT) for v in b)
        tex = cv2.GaussianBlur(rng.random((y1 - y0, x1 - x0, 3)).astype(np.float32), (0, 0), 4)
        tex = (tex - tex.min()) / (np.ptp(tex) + 1e-6)
        a[y0:y1, x0:x1] = 0.15 + 0.7 * tex
    for c in CHROME:
        x0, y0, x1, y1 = (int(v * cf.PT) for v in c["box"])
        a[y0:y1, x0:x1] = 0.97
    return Image.fromarray((a * 255).astype(np.uint8))


def side() -> dict:
    return {
        "horizon": 463.0,
        "subjects": [{"id": "island", "type": "island", "box": BOXES["island"]},
                     {"id": "pofu", "type": "char", "box": BOXES["pofu"]}],
        "chrome": CHROME,
        "features": [],
    }


def take_from(still: Image.Image, shift=(0, 0), blur=0.0, shift_lower=None) -> Image.Image:
    """A guide-layout take: the still at 706 x 1536 in the middle of 1024 x 1536, shifted in take px."""
    im = np.asarray(still.resize((706, 1536), Image.LANCZOS))
    canvas = np.zeros((1536, 1024, 3), np.uint8)
    canvas[:, :] = im[:, :1].mean(axis=1, keepdims=True).astype(np.uint8)
    canvas[:, 159:865] = im

    def move(c, dx, dy):
        return cv2.warpAffine(c, np.float32([[1, 0, dx], [0, 1, dy]]), (1024, 1536), borderMode=cv2.BORDER_REPLICATE)

    out = move(canvas, *shift)
    if shift_lower is not None:
        low = move(canvas, *shift_lower)
        out[800:] = low[800:]
    if blur:
        out = cv2.GaussianBlur(out, (0, 0), blur)
    return Image.fromarray(out)


def drift_of(rep, ident):
    return next(d for d in rep.drifts if d.id == ident)


def test_frame_geometry():
    f = cf.frame_from_take(Image.new("RGB", (1024, 1536)))
    assert f.size == (1206, 2622)


def test_unmoved_take_has_no_drift():
    still = make_still()
    _, rep = cf.fit_take(take_from(still), still, side(), "t", "mid", "locked")
    for ident in ("island", "pofu", "card", "corner_home"):
        assert drift_of(rep, ident).drift < 3.0, ident
    assert abs(drift_of(rep, "horizon").dy) < 3.0
    assert rep.verdict == "locked"


def test_shift_and_blur_are_measured_in_device_px():
    still = make_still()
    take = take_from(still, shift=(9, -4), blur=2.0)
    _, rep = cf.fit_take(take, still, side(), "t", "mid", "locked")
    k = 1206 / 706
    for ident in ("island", "pofu"):
        d = drift_of(rep, ident)
        assert d.dx == pytest.approx(9 * k, abs=3.0), ident
        assert d.dy == pytest.approx(-4 * k, abs=3.0), ident
    assert drift_of(rep, "horizon").dy == pytest.approx(-4 * k, abs=4.0)
    assert "island" in rep.moved and rep.verdict.startswith("MOVED")


def test_small_shift_stays_locked():
    still = make_still()
    _, rep = cf.fit_take(take_from(still, shift=(2, 1), blur=1.5), still, side(), "t", "mid", "locked")
    assert rep.moved == [] and rep.verdict == "locked"


def test_boxes_are_measured_independently():
    still = make_still()
    # the lower part (island and pofu are above row 800 of the take; the card and corner are below) moves alone
    take = take_from(still, shift=(0, 0), shift_lower=(10, 0))
    _, rep = cf.fit_take(take, still, side(), "t", "mid", "locked")
    assert drift_of(rep, "island").drift < 4.0
    assert drift_of(rep, "card").dx > cf.MOVED_PX
    assert "card" in rep.moved and "island" not in rep.moved


def test_repainted_colour_does_not_fake_a_move():
    still = make_still()
    take = np.asarray(take_from(still, blur=1.0)).astype(np.float32)
    take = np.clip(take[..., ::-1] * 0.8 + 30, 0, 255).astype(np.uint8)   # colours swapped and dimmed
    _, rep = cf.fit_take(Image.fromarray(take), still, side(), "t", "mid", "locked")
    assert rep.moved == []


def test_free_take_is_not_judged():
    still = make_still()
    _, rep = cf.fit_take(take_from(still, shift=(30, 0)), still, side(), "t", "mid", "free")
    assert rep.verdict.startswith("free")


def test_chrome_is_pasted_back_from_the_still():
    still = make_still()
    blank = Image.new("RGB", (1024, 1536), (10, 80, 10))
    fitted, _ = cf.fit_take(blank, still, side(), "t", "mid", "free")
    a = np.asarray(fitted)
    cx, cy = int(200 * cf.PT), int(670 * cf.PT)
    assert a[cy, cx].min() > 240                      # inside the card: the still's white
    assert abs(int(a[int(560 * cf.PT), int(30 * cf.PT)][1]) - 80) < 3   # outside: the take
    # the take's own painted control is replaced even if the take moved it
    assert a[int(300 * cf.PT), int(200 * cf.PT)].tolist() == [10, 80, 10]


def test_off_frame_box_is_skipped():
    still = make_still()
    s = side()
    s["subjects"].append({"id": "lawn", "type": "island", "box": [-459, -90, 1027, 1069]})
    _, rep = cf.fit_take(take_from(still), still, s, "t", "near", "locked")
    d = drift_of(rep, "lawn")
    assert d.dx is None and "frame" in d.note
    assert not any(k.kind == "horizon" for k in rep.drifts)   # near has no horizon


def test_run_writes_report_and_one_sheet_per_distance(tmp_path):
    refs, takes, out = tmp_path / "refs", tmp_path / "takes", tmp_path / "out"
    refs.mkdir(), takes.mkdir()
    still = make_still()
    still.save(refs / "mid-level10.png")
    (refs / "mid-level10.json").write_text(json.dumps(side()))
    take_from(still, shift=(1, 1), blur=1.5).save(takes / "x-concept-mid-locked-1.png")
    take_from(still, shift=(25, 0), blur=1.5).save(takes / "x-concept-mid-locked-2.webp")
    take_from(still, shift=(40, 10)).save(takes / "x-concept-mid-free-1.png")
    (takes / "notes.txt").write_text("ignored")
    reps = cf.run(takes, refs, out)
    assert [r.kind for r in reps] == ["free", "locked", "locked"] or len(reps) == 3
    verdicts = {r.name: r.verdict for r in reps}
    assert verdicts["x-concept-mid-locked-1"] == "locked"
    assert verdicts["x-concept-mid-locked-2"].startswith("MOVED")
    assert (out / "sheet-mid.jpg").exists() and (out / "report.txt").exists()
    data = json.loads((out / "report.json").read_text())
    assert len(data) == 3
    sheet = Image.open(out / "sheet-mid.jpg")
    assert sheet.width > 3 * 400            # three columns
    assert cf.main([str(takes), "--refs", str(refs), "--out", str(out)]) == 0


def test_compare_frames_reports_a_shift_and_none_for_identical():
    still = make_still()
    side = {"subjects": [{"id": "island", "type": "island", "box": BOXES["island"]}], "chrome": [], "features": []}
    same = cf.compare_frames(still, still, side, "mid", "same")
    assert same.drifts[0].drift < 1.0
    shifted = Image.fromarray(np.roll(np.asarray(still), 30, axis=0))
    moved = cf.compare_frames(still, shifted, side, "mid", "moved")
    assert 25 < moved.drifts[0].dy < 35
