#!/usr/bin/env python3
"""Re-lock an approved master from its raw with another style-lock preset.

The style lock is a choice, so it must be redoable without regenerating
anything: this runs a master's kept raw through the same normalization as
`run.py post` (canvas fit; for stations the anchor registration from the
master's meta.json, or recomputed for a chain root; for a level edit its
alignment to the parent level) and the preset, and writes
`<master>--<preset>.png` beside the master. It refuses to write when the
result does not register with the existing master (alpha IoU < 0.97), so
the app's anchors stay valid.

`--pad N` keeps what the registration shift pushed past the canvas (a
station drawn off-centre, such as workshop-1, whose master lost the left of
its roof): the canvas grows by N pixels on every side, so the anchor moves
by (N, N), and the IoU is checked on the master's own canvas.

    python3 -I tools/imagegen/relock.py --manifest tools/imagegen/manifest/batch-01-slice.yaml \\
        --job cay-1 --raw design/art/stations/cay-1/raw.webp --preset lock-light

Dependencies: numpy and Pillow (and PyYAML for the manifest).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import pipeline as pl  # noqa: E402
import qa  # noqa: E402
import style_lock as sl  # noqa: E402

MIN_IOU = 0.97


def alpha_iou(a: np.ndarray, b: np.ndarray) -> float:
    if a.shape != b.shape:
        return 0.0
    sa, sb = a[..., 3] > 0.5, b[..., 3] > 0.5
    union = np.logical_or(sa, sb).sum()
    return float(np.logical_and(sa, sb).sum() / union) if union else 0.0


def master_path_of(job: pl.Job) -> Path:
    """The approved master, png or webp."""
    path = pl.approved_image(job)
    if not path.exists() and path.with_suffix(".webp").exists():
        return path.with_suffix(".webp")
    return path


def normalize(job: pl.Job, raw: np.ndarray, meta: dict, preset: dict, pad: int = 0) -> np.ndarray:
    """The raw through run.py post's normalization and `preset`, on a canvas grown by `pad`."""
    rgba, _ = qa.fit_canvas(qa.ensure_alpha(raw)[0], job.canvas)
    reg = None
    if job.kind == "station":
        reg = meta.get("registration") or (qa.station_registration(rgba) if not job.edit_of else None)
    if pad:
        rgba = np.pad(rgba, ((pad, pad), (pad, pad), (0, 0)))
    if reg:
        rgba = qa.shift(rgba, reg["dx"], reg["dy"])
    locked = sl.apply_lock(rgba, preset)
    if meta.get("alignment"):
        # A level edit was aligned to its parent level after the lock (qa's take normalization).
        t = dict(meta["alignment"])
        t["cx"], t["cy"] = t["cx"] + pad, t["cy"] + pad
        locked = qa.apply_alignment(locked, t)
    return locked


def relock(job: pl.Job, raw_path: Path, preset_name: str, pad: int = 0) -> tuple[Path, dict]:
    presets = sl.load_presets()
    preset = presets[preset_name]
    master_path = master_path_of(job)
    meta_path = master_path.parent / "meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {}
    locked = normalize(job, sl.load_rgba(raw_path), meta, preset, pad)
    master = sl.load_rgba(master_path)
    core = locked[pad:locked.shape[0] - pad, pad:locked.shape[1] - pad] if pad else locked
    iou = alpha_iou(core, master)
    if iou < MIN_IOU:
        raise SystemExit(f"{job.id}: the re-locked image does not register with the master (alpha IoU {iou:.3f})")
    out = master_path.with_name(f"{master_path.stem}--{preset_name}.png")
    sl.save_rgba(locked, out)
    return out, {"job": job.id, "preset": preset_name, "raw": str(raw_path), "iou": round(iou, 4), "pad": pad,
                 "master": sl.measure(master), "relocked": sl.measure(locked)}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--job", required=True)
    ap.add_argument("--raw", required=True, help="the kept raw (raw.webp or raw.png in the master folder, or the picked take)")
    ap.add_argument("--preset", default="lock-light")
    ap.add_argument("--pad", type=int, default=0, help="grow the canvas by this many pixels on every side")
    args = ap.parse_args(argv)
    manifest = pl.load_manifest(Path(args.manifest))
    out, report = relock(manifest.job(args.job), Path(args.raw), args.preset, args.pad)
    print(json.dumps(report, indent=2))
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
