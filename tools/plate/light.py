#!/usr/bin/env python3
"""Can a fitted LUT replace a painted light state? Fit on one painted pair, apply to another plate,
measure against that plate's painted truth.

For each light (golden, rain, night) a LUT is fitted from a day take to its painted counterpart (take 1
of each), then applied to a DIFFERENT day plate (take 2, and for golden and night also the
`cl1-backdrop-day` plate) and compared with that plate's own painted state. The pairs are independent
takes, not registered edits, so the fit is a distribution transfer (sliced optimal transport, the look
lab's `ot_lut`): a lower bound for what registered production pairs would give.

Numbers per row: dE2000 between 3 x 3 grid-cell mean colours of the result and the painted truth
(mean over the island's cells), the same for the untouched day plate (the gap the LUT must close),
and the take-to-take floor (painted truth t1 against t2: what painting itself varies by).

    python3 -I tools/plate/light.py OUT.jpg
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "looklab"))
import grade  # noqa: E402
import lab as ll  # noqa: E402

T = REPO / "design" / "art" / "takes"
S = T / "batch-25-seasons"
B = T / "batch-18-loop-1-concepts"


def take(path: str, n: int) -> Path:
    p = Path(path)
    return p / f"plate__{p.name}--t{n}.webp"


CASES = [
    # light, fit source, fit target, test plate, test truth, floor pair
    ("golden", take(S / "x-season-summer", 1), take(S / "x-season-summer-evening", 1),
     take(S / "x-season-summer", 2), take(S / "x-season-summer-evening", 2)),
    ("golden", take(S / "x-season-summer", 1), take(S / "x-season-summer-evening", 1),
     take(B / "cl1-backdrop-day", 1), take(B / "cl1-backdrop-dusk", 1)),
    ("rain", take(S / "x-season-summer", 1), take(S / "x-season-rain", 1),
     take(S / "x-season-summer", 2), take(S / "x-season-rain", 2)),
    ("night", take(S / "x-season-snow", 1), take(S / "x-season-snow-night", 1),
     take(S / "x-season-snow", 2), take(S / "x-season-snow-night", 2)),
    ("night", take(S / "x-season-snow", 1), take(S / "x-season-snow-night", 1),
     take(B / "cl1-backdrop-day", 1), take(B / "cl1-backdrop-night", 1)),
]
W = 512


def cells(rgb: np.ndarray, n: int = 3) -> np.ndarray:
    """Mean Lab of the n x n grid over the middle band (the island; sky top and sea bottom cut off)."""
    h, w = rgb.shape[:2]
    band = rgb[int(0.12 * h):int(0.82 * h)]
    lb = ll.lab(band)
    hh, ww = band.shape[:2]
    return np.array([lb[i * hh // n:(i + 1) * hh // n, j * ww // n:(j + 1) * ww // n].reshape(-1, 3).mean(0)
                     for i in range(n) for j in range(n)])


def de(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.mean([ll.de2000(x, y) for x, y in zip(cells(a), cells(b))]))


def main(argv: list[str] | None = None) -> int:
    out = Path((argv or sys.argv[1:])[0])
    rows, readout = [], []
    for light, fs, ft, ts, tt in CASES:
        src, dst = ll.load_rgb(fs, W), ll.load_rgb(ft, W)
        lut = grade.ot_lut(src, [dst])
        test, truth = ll.load_rgb(ts, W), ll.load_rgb(tt, W)
        fitted = grade.apply_lut(test, lut)
        # The floor only exists when the fit's target and the truth are two takes of the same scene.
        floor = de(ll.load_rgb(ft, W), truth) if ft.parent == tt.parent else float("nan")
        r = {"light": light, "test": ts.parent.name + " t" + ts.stem[-1], "fitted": round(de(fitted, truth), 1),
             "untouched": round(de(test, truth), 1), "floor": round(floor, 1)}
        readout.append(r)
        rows.append([
            (ll.to_img(test), f"{light}: day plate {r['test']}\nuntouched dE {r['untouched']}"),
            (ll.to_img(fitted), f"LUT fitted on {fs.parent.name} t1 pair\ndE to painted truth {r['fitted']}"),
            (ll.to_img(truth), f"painted truth {tt.parent.name} t{tt.stem[-1]}\n" + (f"floor (t1 vs t2 of the truth) dE {r['floor']}" if r["floor"] == r["floor"] else "floor: no second take")),
        ])
    ll.sheet(rows, out, title="Fitted LUT against painted light (dE2000, 3 x 3 cell means over the island band)",
             cell_h=230, max_kb=500)
    print(json.dumps(readout, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
