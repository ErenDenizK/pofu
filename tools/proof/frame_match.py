#!/usr/bin/env python3
"""Frame match: one app frame against the founder's picked target, as a table of numbers.

    python3 tools/proof/frame_match.py --app FRAME --target JPG [--distance map|mid|near] [--out DIR]

The 13 horizontal bands of `match.py`'s table (mean luminance and saturation, 0 to 100) for the target and the app
frame, and the RMS gap of each. `match.py` supplies the measures (`luma`, `sat`, the band count); nothing is copied.
Prints the table, writes `frame-match-<distance>.json` into DIR (default: the current folder) and always exits 0:
it informs the eye, it never gates (docs/design/world-presentation-build-spec.md, WP1).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import match as M  # noqa: E402

BANDS = 13


def load(path: Path) -> np.ndarray:
    """RGB 0..1 at the device frame size (match.W x match.H)."""
    im = Image.open(path).convert("RGB")
    if im.size != (M.W, M.H):
        im = im.resize((M.W, M.H), Image.LANCZOS)
    return np.asarray(im, np.float32) / 255


def band_values(img: np.ndarray, n: int = BANDS) -> list[tuple[float, float]]:
    out = []
    for i in range(n):
        part = img[int(i * M.H / n):int((i + 1) * M.H / n)]
        out.append((float(M.luma(part).mean() * 100), float(M.sat(part).mean() * 100)))
    return out


def compare(app: np.ndarray, target: np.ndarray, n: int = BANDS) -> dict:
    a, t = band_values(app, n), band_values(target, n)
    rms = {k: math.sqrt(sum((x[j] - y[j]) ** 2 for x, y in zip(a, t)) / n) for j, k in enumerate(("L", "S"))}
    bands = [{"from_pt": round(int(i * M.H / n) / M.PT), "to_pt": round(int((i + 1) * M.H / n) / M.PT),
              "L_target": t[i][0], "L_app": a[i][0], "S_target": t[i][1], "S_app": a[i][1]} for i in range(n)]
    return {"bands": bands, "rms": rms}


def table(rep: dict, distance: str) -> str:
    lines = [f"frame match, {distance}", f"{'band (pt)':<12}{'L tgt':>7}{'L app':>7}   {'S tgt':>6}{'S app':>7}"]
    for b in rep["bands"]:
        lines.append(f"{b['from_pt']:>4}-{b['to_pt']:<6}{b['L_target']:>7.1f}{b['L_app']:>7.1f}   {b['S_target']:>6.1f}{b['S_app']:>7.1f}")
    lines.append(f"{'rms gap':<12}{'':>7}{rep['rms']['L']:>7.1f}   {'':>6}{rep['rms']['S']:>7.1f}")
    return "\n".join(lines)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--app", type=Path, required=True, help="the app frame (png or jpg)")
    ap.add_argument("--target", type=Path, required=True, help="the picked target (jpg)")
    ap.add_argument("--distance", default="mid", choices=["map", "mid", "near"])
    ap.add_argument("--out", type=Path, default=Path("."))
    args = ap.parse_args(argv)
    rep = compare(load(args.app), load(args.target))
    rep["distance"] = args.distance
    print(table(rep, args.distance))
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / f"frame-match-{args.distance}.json").write_text(json.dumps(rep, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
