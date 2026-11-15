#!/usr/bin/env python3
"""The life check of docs/design/world-presentation-v2.md section 3, on 30 Hz clips.

    python3 tools/proof/life_meter.py CLIP.mp4 [...] [--expect map|mid|still]

The share of pixels that change by more than 4/255 (any channel) between two frames one second apart, averaged over
every such pair; the same per third of the screen. In range: Map 12 to 30 % overall, mid 8 to 20 %; every third at least
4 %; a Still clip 0 (up to 0.05 for encoder noise). The expectation comes from the file name (`mid` in it, `still` in it, otherwise the Map) or --expect.
Frames are decoded at 402 x 874 (one pixel per point) through ffmpeg.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np

FW, FH, FPS = 402, 874, 30
RANGE = {"map": (12.0, 30.0), "mid": (8.0, 20.0), "still": (0.0, 0.05)}


def frames(path: Path):
    p = subprocess.Popen(["ffmpeg", "-loglevel", "error", "-i", str(path), "-vf", f"scale={FW}:{FH}:flags=area", "-f", "rawvideo",
                          "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
    size = FW * FH * 3
    while True:
        b = p.stdout.read(size)
        if len(b) < size:
            break
        yield np.frombuffer(b, np.uint8).reshape(FH, FW, 3)
    p.wait()


def meter(path: Path) -> dict:
    buf: list[np.ndarray] = []
    pairs = 0
    tot = 0.0
    thirds = np.zeros(3)
    n = 0
    for f in frames(path):
        buf.append(f)
        n += 1
        if len(buf) > FPS:
            a = buf.pop(0)
            ch = (np.abs(f.astype(np.int16) - a.astype(np.int16)).max(-1) > 4)
            tot += ch.mean()
            thirds += [ch[i * FH // 3:(i + 1) * FH // 3].mean() for i in range(3)]
            pairs += 1
    pairs = max(pairs, 1)
    return {"frames": n, "pairs": pairs, "share": 100 * tot / pairs, "thirds": 100 * thirds / pairs}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("clips", nargs="+", type=Path)
    ap.add_argument("--expect", choices=list(RANGE))
    args = ap.parse_args(argv)
    for c in args.clips:
        kind = args.expect or ("still" if "still" in c.name else "mid" if "mid" in c.name else "map")
        r = meter(c)
        lo, hi = RANGE[kind]
        ok = r["frames"] > FPS and lo <= r["share"] <= hi and (kind == "still" or all(r["thirds"] >= 4.0))
        t = r["thirds"]
        print(f"{c.name}: {r['share']:.1f} % changed (range {lo:g} to {hi:g}), thirds top {t[0]:.1f} / middle {t[1]:.1f} / bottom {t[2]:.1f} "
              f"(each at least 4), {r['frames']} frames, {r['pairs']} pairs -> {'PASS' if ok else 'FAIL'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
