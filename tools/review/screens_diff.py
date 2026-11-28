#!/usr/bin/env python3
"""Diff two screenshot branches (or two folders of frames) and print only frames outside the known set.

    python3 -I tools/review/screens_diff.py screenshots/main screenshots/my-branch
    python3 -I tools/review/screens_diff.py frames_a/ frames_b/ --glob 'path-*'

A side that is a directory is read as it is; any other value is a screenshots ref, fetched with
`fetch_frames.sh` (never `git fetch` a screenshots ref into the main repo). Frames are compared by
bytes, then by pixels so the report says how much changed. Glass chrome (`GLASS_BOXES`, small levels) and specks are
counted apart. Frames in `KNOWN_UNSTABLE` are counted
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
SEASON_TURN = (
    "after the swap the windmill (x 309-567, y 920-1246) is caught between two states, a station-level fade or "
    "image load on the clock; the fade hold (worldPlateFadeHold) fixed the plate itself but not this layer"
)
KNOWN_UNSTABLE: dict[str, str] = {
    "path-game-*": "SpriteKit scenes: sceneTime follows the display link's dt and the SKActions run on the system clock, "
    "so fixed sleeps before freeze() land on different frames (FlowScene.update, GardenScene.update)",
    "path-season-turn-1000": SEASON_TURN,
    "path-season-turn-1250": SEASON_TURN,
    "path-season-turn-1500": SEASON_TURN,
    "path-d04-grow-1500": "the grow moment's bloom and cross-fade (IslandGrowMoment) still run on the wall clock in this frame; not traced",
    "path-card-resident-moved": "the focused resident (Findik) idles in its own animation; not driven by worldResidentPin (cause not found)",
}

# `.glassEffect` chrome is captured live by drawHierarchy: its lens and halo shift by a few levels
# between runs. Differences of at most GLASS_TOLERANCE levels inside these boxes (x0, y0, x1, y1, in
# device pixels of a 1206 x 2622 frame) are not reported; anything stronger, or outside, still is.
GLASS_TOLERANCE = 24
GLASS_BOXES = [(880, 100, 1206, 500), (0, 1950, 1206, 2622)]
GLASS_BOXES_BY_FRAME = {"path-sheet-today": [(0, 1550, 1206, 1800)]}

# A frame whose remaining differing pixels number at most this many (text edge jitter, a lone
# speck) is counted as a speck, not listed: it is below what an art change moves.
SPECK_PIXELS = 250

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


def pixel_change(a: Path, b: Path, name: str) -> tuple[str, str]:
    """Return (kind, text): kind is "pixels-equal", "glass", "speck" or "changed"."""
    import numpy as np
    from PIL import Image

    with Image.open(a) as ia, Image.open(b) as ib:
        if ia.size != ib.size:
            return "changed", f"size {ia.size} -> {ib.size}"
        x = np.asarray(ia.convert("RGB"), dtype=np.int16)
        y = np.asarray(ib.convert("RGB"), dtype=np.int16)
    d = np.abs(x - y).max(axis=2)
    if not d.any():
        return "pixels-equal", "bytes differ, pixels equal (metadata)"
    stem = name.rsplit(".", 1)[0]
    for x0, y0, x1, y1 in GLASS_BOXES + GLASS_BOXES_BY_FRAME.get(stem, []):
        zone = d[y0:y1, x0:x1]
        zone[zone <= GLASS_TOLERANCE] = 0
    changed = int((d > 0).sum())
    if not changed:
        return "glass", "only glass chrome differs"
    ys, xs = np.nonzero(d)
    text = f"{changed} px differ, max {int(d.max())}, box x {xs.min()}-{xs.max()} y {ys.min()}-{ys.max()}"
    return ("speck" if changed <= SPECK_PIXELS else "changed"), text


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
        changed, known, same, quiet = [], 0, 0, 0
        for name in sorted(fa.keys() & fb.keys()):
            if digest(fa[name]) == digest(fb[name]):
                same += 1
            elif is_known(name):
                known += 1
            else:
                kind, text = pixel_change(fa[name], fb[name], name)
                if kind == "changed":
                    changed.append((name, text))
                else:
                    quiet += 1
        removed = sorted(fa.keys() - fb.keys())
        added = sorted(fb.keys() - fa.keys())
    for name, how in changed:
        print(f"CHANGED  {name}: {how}")
    for name in removed:
        print(f"REMOVED  {name}")
    for name in added:
        print(f"ADDED    {name}")
    print(f"{same} identical, {quiet} differ only in glass chrome or specks, {known} differ but known unstable, {len(changed)} changed, {len(removed)} removed, {len(added)} added")
    return 1 if changed or removed else 0


if __name__ == "__main__":
    sys.exit(main())
