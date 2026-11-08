#!/usr/bin/env python3
"""Colour metrics for plates (ADR-0023, docs/design/visual-system.md).

    python3 -I tools/plate/colour_metrics.py measure IMG [--mask MASK.png]
    python3 -I tools/plate/colour_metrics.py compare REF IMG [IMG ...]

`measure` prints JSON: L* p5/p50/p95, C* p50/p90/p99, accent share (pixels
with C* > 40) and a hue summary for greens and yellows. `compare` prints each
image's metrics and its deltas against REF, and flags "pale" (C* p90 < 0.85 x
REF or accent share < 0.7 x REF) or "hot" (C* p99 > 1.25 x REF).

Dependencies: numpy and Pillow only.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "assets"))
from process_assets import srgb_to_lab  # noqa: E402

GREENS = (90.0, 160.0)    # CIELAB hue angle range, degrees
YELLOWS = (60.0, 90.0)
MAX_SIDE = 1024           # measure on a downscaled copy for speed
ACCENT_C = 40.0


def load(path: str, mask: str | None = None) -> np.ndarray:
    """Return an (N, 3) float array of sRGB 0..1 for the counted pixels."""
    im = Image.open(path).convert("RGBA")
    if max(im.size) > MAX_SIDE:
        k = MAX_SIDE / max(im.size)
        im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64) / 255.0
    keep = a[..., 3] > 0.5
    if mask:
        m = Image.open(mask).convert("L").resize(im.size, Image.BILINEAR)
        keep &= np.asarray(m, dtype=np.float64) / 255.0 > 0.5
    return a[..., :3][keep]


def _hue_stats(C: np.ndarray, H: np.ndarray, lo: float, hi: float, total: int) -> dict:
    sel = (H >= lo) & (H < hi) & (C > 8)
    n = int(sel.sum())
    if not n:
        return {"share": 0.0, "C_p50": 0.0, "hue_p50": None}
    return {"share": round(n / total, 4), "C_p50": round(float(np.percentile(C[sel], 50)), 2),
            "hue_p50": round(float(np.percentile(H[sel], 50)), 1)}


def metrics(rgb: np.ndarray) -> dict:
    if len(rgb) == 0:
        raise ValueError("no pixels to measure")
    lab = srgb_to_lab(rgb)
    L, C = lab[:, 0], np.hypot(lab[:, 1], lab[:, 2])
    H = np.degrees(np.arctan2(lab[:, 2], lab[:, 1])) % 360
    p = lambda a, q: round(float(np.percentile(a, q)), 2)  # noqa: E731
    return {
        "pixels": int(len(rgb)),
        "L": {"p5": p(L, 5), "p50": p(L, 50), "p95": p(L, 95)},
        "C": {"p50": p(C, 50), "p90": p(C, 90), "p99": p(C, 99)},
        "accent_share": round(float((C > ACCENT_C).mean()), 4),
        "greens": _hue_stats(C, H, *GREENS, len(rgb)),
        "yellows": _hue_stats(C, H, *YELLOWS, len(rgb)),
    }


def flags(m: dict, ref: dict) -> list[str]:
    out = []
    if m["C"]["p90"] < 0.85 * ref["C"]["p90"] or m["accent_share"] < 0.7 * ref["accent_share"]:
        out.append("pale")
    if m["C"]["p99"] > 1.25 * ref["C"]["p99"]:
        out.append("hot")
    return out


def deltas(m: dict, ref: dict) -> dict:
    def r(a, b):
        return round(a / b, 2) if b else None
    return {"L_p50": round(m["L"]["p50"] - ref["L"]["p50"], 2),
            "C_p90_ratio": r(m["C"]["p90"], ref["C"]["p90"]),
            "C_p99_ratio": r(m["C"]["p99"], ref["C"]["p99"]),
            "accent_ratio": r(m["accent_share"], ref["accent_share"])}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("measure")
    m.add_argument("image")
    m.add_argument("--mask")
    c = sub.add_parser("compare")
    c.add_argument("ref")
    c.add_argument("images", nargs="+")
    a = ap.parse_args(argv)
    if a.cmd == "measure":
        print(json.dumps(metrics(load(a.image, a.mask)), indent=2))
        return 0
    ref = metrics(load(a.ref))
    result = {"ref": {"image": a.ref, **ref}, "images": []}
    for p in a.images:
        mm = metrics(load(p))
        result["images"].append({"image": p, **mm, "delta": deltas(mm, ref), "flags": flags(mm, ref)})
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
