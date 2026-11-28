#!/usr/bin/env python3
"""Diff two screenshot branches (or two folders of frames) and print only frames outside the known set.

    python3 -I tools/review/screens_diff.py screenshots/main screenshots/my-branch
    python3 -I tools/review/screens_diff.py frames_a/ frames_b/ --glob 'path-*'

A side that is a directory is read as it is; any other value is a screenshots ref, fetched with
`fetch_frames.sh` (never `git fetch` a screenshots ref into the main repo). Frames are compared by
bytes, then by pixels so the report says how much changed. Frames in `KNOWN_UNSTABLE` are counted
and left out of the list: they differ between two runs of the same commit and are no evidence.
Exit status 0 when nothing outside the known set changed, 1 otherwise.
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import subprocess
import sys
import tempfile
from pathlib import Path

# frame glob -> why two runs of the same commit still differ. Only a cause that was traced and
# could not be removed belongs here; an entry is a debt, not a license.
KNOWN_UNSTABLE: dict[str, str] = {
    "path-game-flow-*": "SpriteKit actions run on the display link; the fixed sleeps before freeze() land on different frames",
    "path-game-garden-midround": "SpriteKit drag follow and actions run on the display link; the frame is taken mid-motion",
}

HERE = Path(__file__).resolve().parent


def is_known(name: str) -> str | None:
    stem = name.rsplit(".", 1)[0]
    for pattern, reason in KNOWN_UNSTABLE.items():
        if fnmatch.fnmatch(stem, pattern):
            return reason
    return None


def load(side: str, glob: str, scratch: Path, label: str) -> dict[str, Path]:
    path = Path(side)
    if path.is_dir():
        return {p.name: p for p in sorted(path.rglob("*.png")) if fnmatch.fnmatch(p.stem, glob)}
    out = scratch / label
    subprocess.run(["bash", str(HERE / "fetch_frames.sh"), side, f"{glob}.png", str(out)], check=True, stdout=subprocess.DEVNULL)
    return {p.name: p for p in sorted(out.glob("*.png"))}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pixel_change(a: Path, b: Path) -> str:
    try:
        import numpy as np
        from PIL import Image
    except ImportError:
        return "bytes differ"
    with Image.open(a) as ia, Image.open(b) as ib:
        if ia.size != ib.size:
            return f"size {ia.size} -> {ib.size}"
        x = np.asarray(ia.convert("RGB"), dtype=np.int16)
        y = np.asarray(ib.convert("RGB"), dtype=np.int16)
    d = np.abs(x - y).max(axis=2)
    changed = int((d > 0).sum())
    if not changed:
        return "bytes differ, pixels equal (metadata)"
    ys, xs = np.nonzero(d)
    return f"{changed} px differ, max {int(d.max())}, box x {xs.min()}-{xs.max()} y {ys.min()}-{ys.max()}"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("a", help="baseline: a screenshots ref or a folder")
    ap.add_argument("b", help="candidate: a screenshots ref or a folder")
    ap.add_argument("--glob", default="*", help="frame-name glob without extension (default: all)")
    args = ap.parse_args(argv)
    with tempfile.TemporaryDirectory(prefix="screens-diff.") as tmp:
        scratch = Path(tmp)
        fa = load(args.a, args.glob, scratch, "a")
        fb = load(args.b, args.glob, scratch, "b")
        changed, known, same = [], 0, 0
        for name in sorted(fa.keys() & fb.keys()):
            if digest(fa[name]) == digest(fb[name]):
                same += 1
            elif is_known(name):
                known += 1
            else:
                changed.append((name, pixel_change(fa[name], fb[name])))
        removed = sorted(fa.keys() - fb.keys())
        added = sorted(fb.keys() - fa.keys())
    for name, how in changed:
        print(f"CHANGED  {name}: {how}")
    for name in removed:
        print(f"REMOVED  {name}")
    for name in added:
        print(f"ADDED    {name}")
    print(f"{same} identical, {known} differ but known unstable, {len(changed)} changed, {len(removed)} removed, {len(added)} added")
    return 1 if changed or removed else 0


if __name__ == "__main__":
    sys.exit(main())
