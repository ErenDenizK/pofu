#!/usr/bin/env python3
"""The life check of docs/design/world-presentation-v2.md section 3 (round 3 version), on 30 Hz clips.

    python3 tools/proof/life_meter.py CLIP.mp4 [...] [--expect map|mid|still]

Three parts, none of which is the old changed-pixel range (the share of changed pixels counts moving textured area, not
speed: a floor at 16 pt/s and one at 3 score the same):
  1. speeds, on the layer list (`life.layer_list`): nothing ambient but the birds above 8 pt/s, no full-width layer above
     5, no period under 5 s, at most 24 moving layers (Map) or 18 (mid); a Still clip lists no moving layer
  2. each third of the screen changes by at least 4 % of its pixels (more than 4/255 in any channel, frames one second
     apart); a Still clip changes by 0 (up to 0.05 for encoder noise)
  3. the mean absolute change between adjacent frames is printed; it gates nothing until the founder has judged the clips
The expectation comes from the file name (`mid` in it, `still` in it, otherwise the Map) or --expect. Frames are decoded
at 402 x 874 (one pixel per point) through ffmpeg.
"""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))

FW, FH, FPS = 402, 874, 30
LIMITS = {"map": 24, "mid": 18}


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
    thirds = np.zeros(3)
    n = 0
    prev = None
    adj = 0.0
    for f in frames(path):
        if prev is not None:
            adj += np.abs(f.astype(np.int16) - prev.astype(np.int16)).mean()
        prev = f
        buf.append(f)
        n += 1
        if len(buf) > FPS:
            a = buf.pop(0)
            ch = (np.abs(f.astype(np.int16) - a.astype(np.int16)).max(-1) > 4)
            thirds += [ch[i * FH // 3:(i + 1) * FH // 3].mean() for i in range(3)]
            pairs += 1
    pairs = max(pairs, 1)
    share = 100 * thirds.sum() / 3 / pairs
    return {"frames": n, "pairs": pairs, "thirds": 100 * thirds / pairs, "share": share, "adjacent": adj / max(n - 1, 1)}


def speed_check(kind: str) -> tuple[bool, list[str]]:
    """Section 3's limits on the layer list of `life.layer_list`."""
    import composition as C
    import life
    rows = life.layer_list(kind)
    bad = []
    for r in rows:
        if r["speed"] > C.CAP and not r["bird"]:
            bad.append(f"{r['name']} {r['speed']:g} pt/s over {C.CAP:g}")
        if r["full_width"] and r["speed"] > C.FULL_WIDTH_CAP:
            bad.append(f"{r['name']} is full width at {r['speed']:g} pt/s, over {C.FULL_WIDTH_CAP:g}")
        if r["period"] < C.MIN_PERIOD:
            bad.append(f"{r['name']} period {r['period']:g} s under {C.MIN_PERIOD:g}")
    if len(rows) > LIMITS[kind]:
        bad.append(f"{len(rows)} moving layers over {LIMITS[kind]}")
    fast = max((r for r in rows if not r["bird"]), key=lambda r: r["speed"])
    return not bad, bad or [f"{len(rows)} layers, fastest {fast['name']} {fast['speed']:g} pt/s"]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("clips", nargs="+", type=Path)
    ap.add_argument("--expect", choices=["map", "mid", "still"])
    args = ap.parse_args(argv)
    rc = 0
    for c in args.clips:
        kind = args.expect or ("still" if "still" in c.name else "mid" if "mid" in c.name else "map")
        r = meter(c)
        t = r["thirds"]
        if kind == "still":
            sp_ok, sp = True, ["no moving layer"]
            ok = r["frames"] > FPS and r["share"] <= 0.05
        else:
            sp_ok, sp = speed_check(kind)
            ok = r["frames"] > FPS and sp_ok and all(t >= 4.0)
        rc |= not ok
        print(f"{c.name}: speeds {'PASS' if sp_ok else 'FAIL'} ({'; '.join(sp)}); thirds top {t[0]:.1f} / middle {t[1]:.1f} / bottom {t[2]:.1f} % "
              f"(each at least 4; still 0), mean change between adjacent frames {r['adjacent']:.3f} /255 (gates nothing), "
              f"{r['frames']} frames -> {'PASS' if ok else 'FAIL'}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
