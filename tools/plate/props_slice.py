#!/usr/bin/env python3
"""Slice batch 111's prop sheet into the Home props, and compute their slots (WP5).

    python3 tools/plate/props_slice.py slice SHEET.png [--check OUT_DIR]
    python3 tools/plate/props_slice.py slots [--overlay OUT_DIR]

`slice` cuts the ten objects of the sheet (jar x4, pot x4, lantern x2, in three rows) out of its
alpha: pieces detached from the object's body (the specks the generator leaves) are dropped, the
lossy ringing under 6/255 is zeroed, and the colour under the edge is pulled from inside the object
so no pale fringe survives. The states of one prop share one crop (the same camera and the same foot
in each), written as `world-home-prop-<id>-<state>` HEIC imagesets. The sheet itself is Codex's
private art (`ErenDenizK/pofu-art`, `art/batch-111-world-home-props`, take 1) and is never committed.

`slots` finds the three slots per plate stage (jar, pots, lantern), in plate pts, from the shipped
plates (`slot_for` of `tools/proof/round3.py`: the free span of the front lip nearest the default,
12 pt clear of every painted foot) and writes them, with the props' sizes, into
`Plates/plate-home.json` as `props`.
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
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "plate"))
import heic  # noqa: E402

RES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RES / "World.xcassets"
PLATE_JSON = RES / "Plates" / "plate-home.json"

#: Sheet rows (y bands) and the objects in each, left to right.
ROWS = [(0, 330, "jar", ["empty", "third", "twothirds", "full"]),
        (330, 660, "pot", ["empty", "sprout", "bloom", "resting"]),
        (660, 1024, "lantern", ["unlit", "lit"])]

#: Painted height in plate pts (the plate is 1024 x 1536 pts; Home's mid view is about 0.455 pt per plate pt):
#: the jar reads 22 pt, a pot 18 pt, the lantern 30 pt at mid (spec WP5; `tools/proof/round3.py` HEIGHT_PT).
HEIGHT_PT = {"jar": 48.0, "pot": 40.0, "lantern": 66.0}
HEIC_QUALITY = 88
FLOOR = 6                       # alpha under this is the encoder's ringing, not paint


def clean_alpha(rgba: np.ndarray) -> np.ndarray:
    """One object's RGBA (uint8): ringing zeroed, only the main body kept, the edge colour pulled from inside."""
    a = rgba[..., 3].copy()
    a[a < FLOOR] = 0
    body = ndimage.binary_closing(a > 24, iterations=3)
    lab, n = ndimage.label(body)
    if n == 0:
        raise SystemExit("an object with no body")
    keep = lab == 1 + int(np.argmax(np.bincount(lab.ravel())[1:]))
    keep = ndimage.binary_dilation(keep, iterations=3)
    a[~keep] = 0
    # the cut's edge: steepen the outer 3 px of the alpha ramp (M2 band under 2 px) and close the near-opaque interior
    inside = cv2.distanceTransform((a > 0).astype(np.uint8), cv2.DIST_L2, 3)
    af = a.astype(np.float32) / 255
    shape = af >= 0.5
    holes = ndimage.binary_fill_holes(shape) & ~shape
    lab, n = ndimage.label(holes)
    for i, size in enumerate(np.bincount(lab.ravel())[1:], 1):
        if size < 64:
            shape |= lab == i
    ramp = cv2.GaussianBlur(shape.astype(np.float32), (0, 0), 0.5)
    af = np.where(inside <= 6, ramp, af)
    af = np.where((inside > 6) & (af > 0.8), 1.0, af)
    a = np.uint8(np.clip(af * 255 + 0.5, 0, 255))
    out = rgba.copy()
    out[..., 3] = a
    # colour under the soft edge: where alpha is under 0.9, take the nearest colour that is opaque enough
    solid = a >= 230
    idx = ndimage.distance_transform_edt(~solid, return_distances=False, return_indices=True)
    nearest = out[..., :3][idx[0], idx[1]]
    edge = (a > 0) & (a < 230)
    # a translucent glass body keeps its own colour; only the outermost ring (within 2 px of nothing) is pulled
    ring = edge & (cv2.distanceTransform((a > 0).astype(np.uint8), cv2.DIST_L2, 3) <= 2.5)
    out[..., :3][ring] = nearest[ring]
    out[a == 0, :3] = 0
    return out


def cut_objects(sheet: np.ndarray) -> dict[str, dict[str, np.ndarray]]:
    """The ten objects as full-size straight RGBA tiles (sheet-sized canvases with only the object), by prop and state."""
    a = sheet[..., 3]
    result: dict[str, dict[str, np.ndarray]] = {}
    for y0, y1, prop, states in ROWS:
        band = np.zeros_like(a, dtype=bool)
        band[y0:y1] = a[y0:y1] > 24
        joined = ndimage.binary_dilation(band, iterations=12)
        lab, n = ndimage.label(joined)
        sizes = np.bincount(lab.ravel())[1:]
        big = [i + 1 for i, s in enumerate(sizes) if s > 4000]
        boxes = []
        for i in big:
            ys, xs = np.nonzero(lab == i)
            boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        boxes.sort()
        if len(boxes) != len(states):
            raise SystemExit(f"{prop}: expected {len(states)} objects, found {len(boxes)} ({boxes})")
        result[prop] = {}
        for state, (x0, y0_, x1, y1_) in zip(states, boxes):
            tile = np.zeros_like(sheet)
            tile[y0_:y1_, x0:x1] = sheet[y0_:y1_, x0:x1]
            result[prop][state] = clean_alpha(tile)
    return result


def aligned(tiles: dict[str, np.ndarray], pad: int = 3) -> dict[str, np.ndarray]:
    """Each state cropped to its body, then set on one common canvas: feet on the bottom edge, centred on x."""
    boxes = {}
    for k, t in tiles.items():
        ys, xs = np.nonzero(t[..., 3] > 0)
        boxes[k] = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    w = max(b[2] - b[0] for b in boxes.values()) + 2 * pad
    h = max(b[3] - b[1] for b in boxes.values()) + 2 * pad
    out = {}
    for k, t in tiles.items():
        x0, y0, x1, y1 = boxes[k]
        canvas = np.zeros((h, w, 4), np.uint8)
        ox = (w - (x1 - x0)) // 2
        canvas[h - pad - (y1 - y0):h - pad, ox:ox + (x1 - x0)] = t[y0:y1, x0:x1]
        out[k] = canvas
    return out


def write_imageset(name: str, rgba: np.ndarray) -> None:
    d = ASSETS / f"{name}.imageset"
    d.mkdir(parents=True, exist_ok=True)
    heic.save(Image.fromarray(rgba), d / f"{name}.heic", quality=HEIC_QUALITY)
    (d / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": f"{name}.heic", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def run_slice(sheet_path: Path, check: Path | None) -> dict:
    sheet = np.asarray(Image.open(sheet_path).convert("RGBA"))
    objects = cut_objects(sheet)
    info: dict[str, dict] = {}
    total = 0
    for prop, tiles in objects.items():
        tiles = aligned(tiles)
        h, w = next(iter(tiles.values())).shape[:2]
        for state, crop in tiles.items():
            write_imageset(f"world-home-prop-{prop}-{state}", crop)
            if check:
                check.mkdir(parents=True, exist_ok=True)
                Image.fromarray(crop).save(check / f"{prop}-{state}.png")
        info[prop] = {"pixels": [int(w), int(h)], "heightPt": HEIGHT_PT[prop], "widthPt": round(HEIGHT_PT[prop] * w / h, 1),
                      "states": list(tiles), "bytes": int(w * h)}
        print(f"{prop}: {w} x {h} px, {len(tiles)} states")
    return info


# ---------------------------------------------------------------- slots

TEX = 2                                           # the plate textures are 2 px per plate pt
DEFAULTS = {"jar": 520.0, "pots": 340.0, "lantern": 650.0}
SPAN = {"jar": 70.0, "pots": 150.0, "lantern": 50.0}
REACH = {"lantern": 300.0, "pots": 300.0, "jar": 330.0}
CLEAR = 12.0
FEET = {"wheel": (466.0, 597.0), "mailbox": (268.0, 335.0)}
#: Hand-set slots by (stage, prop), for a stage whose open lawn the search cannot read.
#: Stages 0 to 3 (levels 10 to 7): the front lip is flowers and the open lawn is stepping stones, so the pots stand on
#: the lawn's front edge left of the wheel and the jar and lantern among the hydrangeas right of it, each 12 pt clear of
#: the wheel's and the mailbox's feet (checked by eye on the plate, `--overlay`).
DECLARED: dict[tuple[int, str], tuple[float, ...]] = {
    (stage, prop): value
    for stage in range(4)
    for prop, value in (("pots", (400.0, 968.0, 80.0)), ("jar", (632.0, 985.0, 46.0)), ("lantern", (700.0, 978.0, 44.0)))
}


def lawn_mask(stage: int, crop: list[float]) -> np.ndarray:
    """The plate's open lawn at 1 px per plate pt (grass-coloured, no stones, flowers, water or painted objects), cropped."""
    files = glob.glob(str(ASSETS / f"world-home-plate-day-{stage}.imageset" / "*.heic"))
    p = np.asarray(heic.open_image(Path(files[0])).convert("RGBA"), np.float32) / 255
    r, g, b, a = (p[..., i] for i in range(4))
    lawn = ((a > 0.9) & (g > b + 0.2) & (g > r * 0.9) & (g > 0.5)).astype(np.uint8)
    lawn = cv2.morphologyEx(lawn, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    return cv2.resize(lawn, (lawn.shape[1] // TEX, lawn.shape[0] // TEX), interpolation=cv2.INTER_AREA) > 0.9


#: A prop's footprint on the lawn, plate pts: width and depth. The row of pots is the widest.
FOOT = {"jar": (46.0, 14.0), "pots": (150.0, 16.0), "lantern": (44.0, 14.0)}
FRONT = 900.0                                         # props stand in front of Pofu's row (his feet are at 858)


def slot_for(prop, mask, crop, obstacles, fixed=None):
    """As `spot`, with the pots' row narrowing (150, 120, 90, 70 pt) until some lawn holds it; returns (x, y, width)."""
    if fixed is not None:
        return fixed
    widths = (150.0, 120.0, 90.0, 70.0) if prop == "pots" else (FOOT[prop][0],)
    for w in widths:
        for need in (0.93, 0.85, 0.75):
            got = spot(prop, w, mask, crop, obstacles, need)
            if got:
                return (*got, w)
    if fixed is not None:
        return fixed
    raise SystemExit(f"no lawn for {prop} at {crop}")


def spot(prop, w, mask, crop, obstacles, need=0.93):
    """The foot spot where the whole footprint is open lawn, nearest the default, preferring the front."""
    x0, y0 = crop[0], crop[1]
    d = FOOT[prop][1]
    best, best_cost = None, 1e18
    h, wd = mask.shape
    ii = cv2.integral(mask.astype(np.uint8))
    for cx in range(int(DEFAULTS[prop] - REACH[prop]), int(DEFAULTS[prop] + REACH[prop]) + 1, 4):
        if any(cx + w / 2 + g > a and cx - w / 2 - g < b for a, b, g in obstacles.values()):
            continue
        for fy in range(int(FRONT), int(y0 + h), 3):
            xa, xb = int(cx - w / 2 - x0), int(cx + w / 2 - x0)
            ya, yb = int(fy - d - y0), int(fy - y0)
            if xa < 0 or xb >= wd or yb >= h:
                continue
            full = (ii[yb, xb] - ii[ya, xb] - ii[yb, xa] + ii[ya, xa]) / max((xb - xa) * (yb - ya), 1)
            if full >= need:
                cost = abs(cx - DEFAULTS[prop]) * 1.0 - fy * 2.0
                if cost < best_cost:
                    best, best_cost = (float(cx), float(fy)), cost
    return best


def run_slots(overlay: Path | None) -> list[dict]:
    plate = json.loads(PLATE_JSON.read_text())
    levels = plate["stageLevels"]
    crops = plate["plateCrop"]["day"]
    out = []
    for stage, level in enumerate(levels):
        mask = lawn_mask(stage, crops[stage])
        obs = {k: (a, b, CLEAR) for k, (a, b) in FEET.items() if k != "mailbox" or level == 10}
        slots = {}
        for p in ("pots", "lantern", "jar"):
            slots[p] = slot_for(p, mask, crops[stage], obs, DECLARED.get((stage, p)))
            half = slots[p][2] / 2 if len(slots[p]) > 2 else FOOT[p][0] / 2
            obs[p] = (slots[p][0] - half, slots[p][0] + half, 14.0)
        out.append({k: [round(vs[0], 1), round(vs[1] - 4.0, 1), *[round(v, 1) for v in vs[2:]]] for k, vs in slots.items()})
        print(f"stage {stage} (level {level}): {out[-1]}")
        if overlay:
            overlay.mkdir(parents=True, exist_ok=True)
            files = glob.glob(str(ASSETS / f"world-home-plate-day-{stage}.imageset" / "*.heic"))
            im = heic.open_image(Path(files[0])).convert("RGBA")
            bg = Image.new("RGBA", im.size, (255, 0, 255, 255))
            bg.alpha_composite(im)
            arr = np.asarray(bg.convert("RGB")).copy()
            x0, y0 = crops[stage][0], crops[stage][1]
            for k, (sx, sy, *rest) in slots.items():
                w, d = (rest[0] if rest else FOOT[k][0]), FOOT[k][1]
                cv2.rectangle(arr, (int((sx - w / 2 - x0) * TEX), int((sy - d - y0) * TEX)), (int((sx + w / 2 - x0) * TEX), int((sy - y0) * TEX)), (255, 0, 0), 3)
                cv2.putText(arr, k, (int((sx - x0) * TEX) - 20, int((sy - y0) * TEX) + 40), cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 0), 3)
            Image.fromarray(arr).resize((arr.shape[1] // 2, arr.shape[0] // 2)).save(overlay / f"slots-{stage}.jpg", quality=85)
    return out


def write_props(info: dict | None, slots: list[dict]) -> None:
    plate = json.loads(PLATE_JSON.read_text())
    old = {p["id"]: p for p in plate.get("props", [])}
    props = []
    for pid, prop in (("jar", "jar"), ("pots", "pot"), ("lantern", "lantern")):
        entry = dict(old.get(pid, {}))
        entry["id"] = pid
        if slots:
            entry["slots"] = [s[pid] for s in slots]
        if info:
            entry["height"] = info[prop]["heightPt"]
            entry["width"] = info[prop]["widthPt"]
            entry["pixels"] = info[prop]["pixels"]
            entry["states"] = info[prop]["states"]
            entry["bytes"] = info[prop]["bytes"] * len(info[prop]["states"])
        props.append(entry)
    plate["props"] = props
    PLATE_JSON.write_text(json.dumps(plate, indent=None, separators=(",", ":")) + "\n")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("slice")
    s.add_argument("sheet", type=Path)
    s.add_argument("--check", type=Path)
    t = sub.add_parser("slots")
    t.add_argument("--overlay", type=Path)
    args = ap.parse_args(argv)
    if args.cmd == "slice":
        info = run_slice(args.sheet, args.check)
        write_props(info, None)
    else:
        write_props(None, run_slots(args.overlay))
    return 0


if __name__ == "__main__":
    sys.exit(main())
