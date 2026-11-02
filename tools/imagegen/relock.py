#!/usr/bin/env python3
"""Re-lock an approved master from its raw with another style-lock preset.

The style lock is a choice, so it must be redoable without regenerating
anything: this runs a master's kept raw through the same normalization as
`run.py post` (canvas fit and, for stations, the anchor registration from
the master's meta.json or recomputed for a chain root) and the preset, and
writes `<master>--<preset>.png` beside the master. It refuses to write when
the result does not register with the existing master (alpha IoU < 0.97),
so the app's anchors stay valid.

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


def relock(job: pl.Job, raw_path: Path, preset_name: str) -> tuple[Path, dict]:
    presets = sl.load_presets()
    preset = presets[preset_name]
    master_path = pl.approved_image(job)
    meta_path = master_path.parent / "meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {}
    raw = sl.load_rgba(raw_path)
    rgba, _ = qa.fit_canvas(qa.ensure_alpha(raw)[0], job.canvas)
    if job.kind == "station":
        reg = meta.get("registration") or (qa.station_registration(rgba) if not job.edit_of else None)
        if reg:
            rgba = qa.shift(rgba, reg["dx"], reg["dy"])
    locked = sl.apply_lock(rgba, preset)
    master = sl.load_rgba(master_path)
    iou = alpha_iou(locked, master)
    if iou < MIN_IOU:
        raise SystemExit(f"{job.id}: the re-locked image does not register with the master (alpha IoU {iou:.3f})")
    out = master_path.with_name(f"{master_path.stem}--{preset_name}.png")
    sl.save_rgba(locked, out)
    return out, {"job": job.id, "preset": preset_name, "raw": str(raw_path), "iou": round(iou, 4),
                 "master": sl.measure(master), "relocked": sl.measure(locked)}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--job", required=True)
    ap.add_argument("--raw", required=True, help="the kept raw (raw.webp or raw.png in the master folder)")
    ap.add_argument("--preset", default="lock-light")
    args = ap.parse_args(argv)
    manifest = pl.load_manifest(Path(args.manifest))
    out, report = relock(manifest.job(args.job), Path(args.raw), args.preset)
    print(json.dumps(report, indent=2))
    print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
