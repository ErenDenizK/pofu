#!/usr/bin/env python3
"""The New Year kit's props (island calendar v1, C3): cut the picked takes of batch 183 into imagesets, and find
their slots on the ten Home stages.

    python3 tools/plate/ny_kit.py slice TAKES_DIR
    python3 tools/plate/ny_kit.py slots [--overlay OUT_DIR]

`slice` reads the picked takes of `ErenDenizK/pofu-art` `design/art/takes/batch-183-yilbasi-kit/<job>/prop__<job>--tN.webp`
(private art, never committed), cleans each cut as `props_slice.clean_alpha` does, sets the states of one prop on one
canvas (same crop, same foot) and writes `world-home-prop-<id>-<state>` HEIC imagesets at about 4 px per plate pt.

`slots` finds each kit prop's foot on every stage's day plate: the open lawn nearest where batch 183's preview stands it,
clear of the painted feet, of the three home props and of the characters' spots; and writes the kit's entries into the
`props` key of `Plates/plate-home.json`, leaving the three home props and every other key as they are.
"""
from __future__ import annotations

import argparse
import glob
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import props_slice as ps  # noqa: E402

#: id -> (painted height in plate pts, [(state, job, take)]). Picks are recorded in the PR; `tree` and `lantern` lit takes are
#: the ones whose silhouette matches the unlit pick and whose alpha carries no halo.
KIT = {
    "ny-tree": (84.0, [("unlit", "x10-ny-tree", 1), ("lit", "x10-ny-tree-lit", 2)]),
    "ny-parcels": (46.0, [("still", "x10-ny-parcels", 1)]),
    "ny-snowman": (62.0, [("still", "x10-ny-snowman", 2)]),
    "ny-star": (76.0, [("unlit", "x10-ny-star-lantern", 1), ("lit", "x10-ny-star-lantern-lit", 1)]),
}
WHEN = "newYear"
PX_PER_PT = 4.0

#: Where batch 183's preview stands each prop on the level 10 plate, plate pts (x, foot y), and how far a slot may move.
DEFAULTS = {"ny-tree": (640.0, 922.0), "ny-parcels": (592.0, 872.0), "ny-snowman": (350.0, 925.0), "ny-star": (520.0, 900.0)}
REACH = {"ny-tree": 420.0, "ny-parcels": 420.0, "ny-snowman": 420.0, "ny-star": 420.0}
#: Footprint on the lawn (width, depth) as a share of the art's width, plate pts.
DEPTH = {"ny-tree": 14.0, "ny-parcels": 14.0, "ny-snowman": 14.0, "ny-star": 14.0}


def resize(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """Straight RGBA resized in premultiplied space, so the colour under a soft edge does not darken it."""
    f = rgba.astype(np.float32)
    a = f[..., 3:] / 255
    pre = np.concatenate([f[..., :3] * a, f[..., 3:]], axis=2)
    out = cv2.resize(pre, size, interpolation=cv2.INTER_AREA)
    alpha = out[..., 3:] / 255
    rgb = np.where(alpha > 1e-4, out[..., :3] / np.maximum(alpha, 1e-4), 0)
    return np.clip(np.concatenate([rgb, out[..., 3:]], axis=2) + 0.5, 0, 255).astype(np.uint8)


def cut(takes: Path) -> dict:
    info = {}
    for pid, (height, states) in KIT.items():
        tiles = {}
        for state, job, take in states:
            f = takes / f"prop__{job}--t{take}.webp"
            rgba = np.asarray(Image.open(f).convert("RGBA"))
            tiles[state] = ps.clean_alpha(rgba)
        tiles = ps.aligned(tiles)
        h, w = next(iter(tiles.values())).shape[:2]
        scale = height * PX_PER_PT / h
        for state, crop in tiles.items():
            size = (round(w * scale), round(h * scale))
            small = resize(crop, size)
            ps.write_imageset(f"world-home-prop-{pid}-{state}", small)
            info[pid] = {"pixels": list(size), "height": height, "width": round(height * w / h, 1),
                         "states": list(tiles), "bytes": size[0] * size[1] * len(tiles)}
        print(pid, info[pid])
    return info


def lawn(stage: int) -> tuple[np.ndarray, list[float]]:
    crops = json.loads(ps.PLATE_JSON.read_text())["plateCrop"]["day"]
    return ps.lawn_mask(stage, crops[stage]), crops[stage]


#: Stages 0 to 3 (levels 10 to 7) have one gap between Pofu's and Findik's columns, x 541 to 602 at y 868, and only the pine
#: fits it (the guest's spot, which is in the gap, is left out there: a guest comes and goes). The parcels, the snowman and the
#: star are left out of those four stages: the lawn is full, and a prop must keep half a character's width from every spot.
STAGE_FULL = 4
PINE_GAP = (562.0, 868.0)
COLUMN = 56.0      # half a character's width plus half a width of margin, plate pts
CHAR_HEIGHT = 70.0
MIN_FOOT = 880
MAX_X = 770         # the main island's east edge; the lawn beyond it is the next island's      # no kit prop stands up the hill behind the stones


def occluder_masks(plate: dict, stage: int, crop: list[float], shape: tuple[int, int]) -> list[tuple[float, np.ndarray]]:
    """The painted objects that stand in front of what is behind their foot line: (foot y, mask at one px per plate pt)."""
    out = []
    for o in plate["objects"]:
        if not o.get("occluder") or stage not in o.get("stages", range(10)):
            continue
        m = np.zeros(shape, np.uint8)
        cv2.fillPoly(m, [np.array([[x - crop[0], y - crop[1]] for x, y in o["polygon"]], np.int32)], 1)
        out.append((o["footY"], m > 0))
    return out


def slots_for(plate: dict, overlay: Path | None) -> dict[str, list[list[float]]]:
    levels = plate["stageLevels"]
    chars = plate["spots"]
    home = {p["id"]: p for p in plate["props"] if "when" not in p}
    out = {pid: [] for pid in KIT}
    for stage, level in enumerate(levels):
        mask, crop = lawn(stage)
        x0, y0 = crop[0], crop[1]
        taken: list[tuple[float, float, float, float]] = []      # x0, x1, y0, y1 of what already stands
        for hid, p in home.items():
            sx, sy = p["slots"][stage][:2]
            span = p["slots"][stage][2] if len(p["slots"][stage]) > 2 else p["width"]
            taken.append((sx - span / 2 - 10, sx + span / 2 + 10, sy - p["height"] - 6, sy + 6))
        # Props are drawn over Pofu, so every character's column is kept clear, at every spot he stands on.
        for name, pts in chars.items():
            if stage < STAGE_FULL and name == "visitor":
                continue
            for sx, sy in pts:
                taken.append((sx - COLUMN, sx + COLUMN, sy - CHAR_HEIGHT, sy))
        for lx, ly in plate["lamps"]:
            taken.append((lx - 36, lx + 36, ly - 70, ly))      # a lamp post's own ground: no prop beside it
        feet = [v for k, v in ps.FEET.items() if k != "mailbox" or level == 10]
        for a, b in feet:
            taken.append((a - 14, b + 14, -1000, 2000))
        covers = occluder_masks(plate, stage, crop, mask.shape)
        for pid, (height, _) in KIT.items():
            width = _INFO[pid]["width"]
            if stage < STAGE_FULL:
                out[pid].append(list(PINE_GAP) if pid == "ny-tree" else [])
                continue
            best, cost0 = None, 1e18
            dx, dy = DEFAULTS[pid]
            hit = lambda cx, fy: any(cx + width / 2 > a and cx - width / 2 < b and fy > c and fy - height < d
                                     for a, b, c, d in taken)
            h, wd = mask.shape
            ii = cv2.integral(mask.astype(np.uint8))
            for cx in range(int(dx - REACH[pid]), min(int(dx + REACH[pid]), MAX_X) + 1, 4):
                for fy in range(max(int(y0 + 20), MIN_FOOT), int(y0 + h), 3):
                    xa, xb = int(cx - width * 0.38 - x0), int(cx + width * 0.38 - x0)
                    ya, yb = int(fy - DEPTH[pid] - y0), int(fy - y0)
                    if xa < 0 or xb >= wd or yb >= h or ya < 0 or hit(cx, fy - 4):
                        continue
                    full = (ii[yb, xb] - ii[ya, xb] - ii[yb, xa] + ii[ya, xa]) / max((xb - xa) * (yb - ya), 1)
                    if full < 0.9:
                        continue
                    ta, tb = int(cx - width / 2 - x0), int(cx + width / 2 - x0)
                    tc, td = int(fy - height - y0), int(fy - y0)
                    if any(foot > fy and m[max(tc, 0):max(td, 0), max(ta, 0):max(tb, 0)].any() for foot, m in covers):
                        continue
                    cost = ((cx - dx) ** 2 + (fy - dy) ** 2) ** 0.5
                    if cost < cost0:
                        best, cost0 = (float(cx), float(fy)), cost
            if best is None:
                out[pid].append([])
                print(f"stage {stage} (level {level}): no slot for {pid}")
            else:
                out[pid].append([best[0], round(best[1] - 4.0, 1)])
                taken.append((best[0] - width / 2 - 8, best[0] + width / 2 + 8, best[1] - height - 6, best[1] + 6))
        print(f"stage {stage} (level {level}):", {pid: out[pid][-1] for pid in KIT})
    return out


_INFO: dict = {}


def entry(pid: str, info: dict, slots: list) -> dict:
    return {"id": pid, "when": WHEN, "height": info["height"], "width": info["width"], "pixels": info["pixels"],
            "states": info["states"], "bytes": info["bytes"], "slots": slots}


def sizes() -> dict:
    out = {}
    for pid, (height, states) in KIT.items():
        d = ps.ASSETS / f"world-home-prop-{pid}-{states[0][0]}.imageset"
        im = heic.open_image(next(d.glob("*.heic")))
        w, h = im.size
        out[pid] = {"pixels": [w, h], "height": height, "width": round(height * w / h, 1),
                    "states": [s for s, _, _ in states], "bytes": w * h * len(states)}
    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("slice")
    s.add_argument("takes", type=Path)
    t = sub.add_parser("slots")
    t.add_argument("--overlay", type=Path)
    args = ap.parse_args(argv)
    if args.cmd == "slice":
        cut(args.takes)
        return 0
    _INFO.update(sizes())
    plate = json.loads(ps.PLATE_JSON.read_text())
    slots = slots_for(plate, args.overlay)
    base = [p for p in plate["props"] if "when" not in p]
    plate["props"] = base + [entry(pid, _INFO[pid], slots[pid]) for pid in KIT]
    ps.PLATE_JSON.write_text(json.dumps(plate, indent=None, separators=(",", ":")) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
