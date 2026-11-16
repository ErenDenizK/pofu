#!/usr/bin/env python3
"""Station looks and erased bases for the Home plate (WP8 of docs/design/world-presentation-build-spec.md, N6 of
docs/design/night-plan-2026-11-15.md).

A station's level has to show on the island. The plate paints one stall per island level, so the stall cannot change on
its own: for a state that has a *base* (the plate with the station erased) the app draws the base and, over it, the
station's *look* for its level (level 1 to 1, one transform and one foot anchor for every look).

    python3 tools/plate/station_looks.py looks   # the five cut-outs -> world-home-look-<station>-<level>-<light>
    python3 tools/plate/station_looks.py bases   # the erased plates   -> world-home-base-<light>-<stage>
    python3 tools/plate/station_looks.py json    # design/art/plates/home/stations.json (ingest.py reads it)
    python3 tools/plate/station_looks.py all

Looks (the lead's picks, read from each job's `review.yaml`): graded at ingest (chroma x0.65, lightness +5 percent, one
shared grade, never at runtime), alpha normalised (below 16 to 0, 240 and over to 255, islands under 64 px dropped,
enclosed pinholes under 64 px filled), a contact shade cut from each look's own bottom contour, one scale for all.
Bases: the shipped plate with the stall's region taken from batch 117's erase pick, its colour matched to the parent
lawn (mean Lab colour of a ring round the region) and feathered; the plate's alpha may only shrink there.
Needs the plate's upscaled source (cached by `ingest.py`) and pillow-heif; no matting network.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import ingest  # noqa: E402

ISLAND = "home"
TEX = 2                          # plate texture px per plate point (the shipped plates)
DENSITY = 3.0                    # a look's texture px per plate point (the plate's is 2)
GRADE = {"chroma": 0.65, "light": 1.05}
ALPHA_LOW, ALPHA_HIGH, SPECK = 16, 240, 64
SHADE_RGB = np.float32([0.16, 0.22, 0.10])
FEATHER_TEX = 24                 # the base's colour feather, texture px
TAKES = ingest.REPO / "design" / "art" / "takes"
STATIONS_JSON = ingest.REPO / "design" / "art" / "plates" / ISLAND / "stations.json"
ASSETS = ingest.ASSETS

# The tea stall. Batch 123's cut-outs are 1254 px canvases drawn for the plate's own stall of level 3 (stage 7): the
# shared scale and the foot (the bottom centre of look 1's alpha box) put the counter on the plate's counter, so it
# stays put from level to level.
TEA_STALL = {
    "id": "teaStall",
    "light": "day",
    "jobs": [f"batch-123-tea-stall-ladder-pilot/x-look-tea-stall-{n}" for n in range(1, 6)],
    "scale": 0.294,              # of the 1254 px canvas, at TEX px per point
    "foot": (690.0, 832.0),      # plate points, at stage 7
    "footStage": 7,
}

# Bases: stage -> the erase job (batch 117, day) and the window (texture px, x0 y0 x1 y1) the stall is taken from. The
# window is the old stall and its teapot; the cart, the rope bridge and the rim stay the parent's. Stages whose job has
# no pick, and the stages whose stall is another painting (a tile roof, a workshop and a beehive beside it, erased with
# it), have no base and keep their painted stall.
# `exclude` rectangles (texture px) are taken out of the paste mask: the rope bridge's near post stands in front of the
# drum at some stages and the erase takes drop the bridge, so the parent's post and rope stay.
# Stage 8 (level 2) has a pick but no clean base: the old drum's cast shadow runs on over the lawn past the window and the
# take paints mist where it would have to be cut, so its patch shows (a hard shadow edge, a pale wisp): it keeps its stall.
# Day stage s is island level 10 - s; its erase job is `x-base-erase-l<level>-day`.
JOB = "batch-117-station-erase-volume/x-base-erase-l{:02d}-day"
BASES = {
    7: {"job": JOB.format(3), "window": (1246, 1330, 1512, 1664)},
    6: {"job": JOB.format(4), "window": (1232, 1370, 1530, 1672)},
    4: {"job": JOB.format(6), "window": (1252, 1290, 1536, 1692),
        "exclude": [(1420, 1650, 1700, 1800)]},
    3: {"job": JOB.format(7), "window": (1252, 1290, 1536, 1692),
        "exclude": [(1420, 1650, 1700, 1800)]},
}

# Where each stage paints its stall (plate points) and its size against stage 7's: the foot is the bottom centre of the
# counter, the scale the counter's width over stage 7's. The look stands there at that size.
PLACE = {
    7: {"foot": (690.0, 832.0), "scale": 1.0},
    6: {"foot": (690.0, 838.0), "scale": 0.95},
    4: {"foot": (698.0, 839.0), "scale": 1.10},
    3: {"foot": (697.0, 839.0), "scale": 1.09},
}


# ---------------------------------------------------------------- looks

def pick_of(job: str) -> int:
    text = (TAKES / job / "review.yaml").read_text()
    m = re.search(r"^pick:\s*(\d+)", text, re.M)
    if not m:
        raise SystemExit(f"{job}: review.yaml has no pick")
    return int(m.group(1))


def take_path(job: str) -> Path:
    n = pick_of(job)
    found = sorted((TAKES / job).glob(f"*--t{n}.webp"))
    if not found:
        raise SystemExit(f"{job}: the picked take {n} is not ingested")
    return found[0]


def normalise_alpha(a: np.ndarray) -> np.ndarray:
    """8-bit alpha: below `ALPHA_LOW` to 0, `ALPHA_HIGH` and over to 255, opaque islands under `SPECK` px dropped,
    enclosed holes under `SPECK` px filled (their colour is filled by the caller)."""
    a = a.copy()
    a[a < ALPHA_LOW] = 0
    a[a >= ALPHA_HIGH] = 255
    on = a > 0
    lab, n = ndimage.label(on, structure=np.ones((3, 3)))
    if n:
        sizes = ndimage.sum(on, lab, range(1, n + 1))
        for i in np.nonzero(sizes < SPECK)[0]:
            a[lab == i + 1] = 0
    off = a == 0
    lab, n = ndimage.label(off)                       # 4-connected: a pinhole is closed by its 4 neighbours
    if n:
        sizes = ndimage.sum(off, lab, range(1, n + 1))
        border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
        for i in np.nonzero(sizes < SPECK)[0]:
            if (i + 1) not in border:
                a[lab == i + 1] = 255
    return a


def srgb_lab(rgb: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(np.ascontiguousarray(rgb, np.float32), cv2.COLOR_RGB2Lab)


def lab_srgb(lab: np.ndarray) -> np.ndarray:
    return np.clip(cv2.cvtColor(np.ascontiguousarray(lab, np.float32), cv2.COLOR_Lab2RGB), 0, 1)


def graded(rgb: np.ndarray) -> np.ndarray:
    """The shared grade of the looks (batch 123's lead review): chroma x0.65, lightness +5 percent, in CIELAB."""
    lab = srgb_lab(rgb)
    lab[..., 0] = np.clip(lab[..., 0] * GRADE["light"], 0, 100)
    lab[..., 1:] *= GRADE["chroma"]
    return lab_srgb(lab)


def load_look(path: Path) -> np.ndarray:
    """Straight RGBA floats: alpha normalised, holes' colour filled from their surroundings, graded."""
    im = np.asarray(Image.open(path).convert("RGBA"))
    a8 = normalise_alpha(im[..., 3])
    rgb = im[..., :3].astype(np.float32) / 255
    new = (a8 > 0) & (im[..., 3] < ALPHA_LOW)          # a pinhole filled: it takes the nearest kept colour
    if new.any():
        keep = (a8 > 0) & ~new
        _, (iy, ix) = ndimage.distance_transform_edt(~keep, return_indices=True)
        rgb = np.where(new[..., None], rgb[iy, ix], rgb)
    return np.dstack([graded(rgb), a8.astype(np.float32) / 255])


def resize_rgba(x: np.ndarray, scale: float) -> np.ndarray:
    """Premultiplied resize (a transparent pixel's colour must not bleed into the edge)."""
    pm = np.dstack([x[..., :3] * x[..., 3:], x[..., 3:]])
    h, w = x.shape[:2]
    pm = cv2.resize(pm, (round(w * scale), round(h * scale)), interpolation=cv2.INTER_AREA)
    a = pm[..., 3:]
    return np.dstack([np.where(a > 1e-4, pm[..., :3] / np.maximum(a, 1e-4), 0), a])


def contact_shade(alpha: np.ndarray, density: float = DENSITY) -> np.ndarray:
    """The shade a cut-out casts on the lawn, from its own bottom contour (not an ellipse): every column's lowest solid
    pixel, a strip a few pixels deep, moved down and blurred, so a tripod foot that floats gets a spot of its own."""
    h, w = alpha.shape
    solid = alpha > 0.5
    has = solid.any(0)
    bottom = np.where(has, h - 1 - np.argmax(solid[::-1], 0), -10_000)
    rows = np.arange(h)[:, None]
    k = density / 3
    strip = ((rows <= bottom + 4 * k) & (rows >= bottom - 7 * k) & has[None, :]).astype(np.float32)
    tight = cv2.GaussianBlur(strip, (0, 0), 5 * k)
    wide = cv2.GaussianBlur(np.roll(strip, int(round(5 * k)), axis=0), (0, 0), 14 * k)
    return np.clip(0.40 * tight / max(float(tight.max()), 1e-4) * 0.9 + 0.22 * wide / max(float(wide.max()), 1e-4) * 0.6, 0, 0.5)


def over(base: np.ndarray, top: np.ndarray) -> np.ndarray:
    a, ba = top[..., 3:4], base[..., 3:4]
    oa = a + ba * (1 - a)
    rgb = (top[..., :3] * a + base[..., :3] * ba * (1 - a)) / np.maximum(oa, 1e-6)
    return np.dstack([rgb, oa])


def build_looks(spec: dict = TEA_STALL) -> dict:
    """{level: RGBA floats, all one size}, plus the box of the common crop in plate points and the foot anchor in it."""
    scale = spec["scale"] * DENSITY / TEX
    full = {}
    for n, job in enumerate(spec["jobs"], start=1):
        look = resize_rgba(load_look(take_path(job)), scale)
        sh = contact_shade(look[..., 3])
        shade = np.dstack([np.broadcast_to(SHADE_RGB, look.shape[:2] + (3,)), sh[..., None]])
        full[n] = over(shade, look)
    ys, xs = np.nonzero(resize_rgba(load_look(take_path(spec["jobs"][0])), scale)[..., 3] > 0.5)
    anchor = ((xs.min() + xs.max() + 1) / 2, ys.max() + 1)          # bottom centre of look 1's alpha box
    boxes = [np.nonzero(x[..., 3] > 0.02) for x in full.values()]
    x0 = min(int(b[1].min()) for b in boxes) - 2
    y0 = min(int(b[0].min()) for b in boxes) - 2
    x1 = max(int(b[1].max()) for b in boxes) + 3
    y1 = max(int(b[0].max()) for b in boxes) + 3
    x0, y0 = x0 // 4 * 4, y0 // 4 * 4                              # ASTC blocks
    x1, y1 = -(-x1 // 4) * 4, -(-y1 // 4) * 4
    cropped = {n: x[y0:y1, x0:x1] for n, x in full.items()}
    fx, fy = spec["foot"]
    box = [fx + (x0 - anchor[0]) / DENSITY, fy + (y0 - anchor[1]) / DENSITY, fx + (x1 - anchor[0]) / DENSITY, fy + (y1 - anchor[1]) / DENSITY]
    return {"looks": cropped, "box": [round(float(v), 2) for v in box], "foot": [fx, fy]}


def to_img(x: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255 + 0.5))


def look_name(station: str, level: int, light: str) -> str:
    return f"world-{ISLAND}-look-{station}-{level}-{light}"


def base_name(light: str, stage: int) -> str:
    return f"world-{ISLAND}-base-{light}-{stage}"


def cmd_looks(spec: dict = TEA_STALL) -> dict:
    built = build_looks(spec)
    for level, x in built["looks"].items():
        ingest.write_imageset(look_name(spec["id"], level, spec["light"]), to_img(x))
    h, w = next(iter(built["looks"].values())).shape[:2]
    print(f"looks: {len(built['looks'])} x {w} x {h} px, box {built['box']}")
    return built


# ---------------------------------------------------------------- bases

def sky_alpha(rgb: np.ndarray) -> np.ndarray:
    """1 on the island, 0 on the painted sky, for a take's pixels (the sky is blue, the grass is not)."""
    blue = rgb[..., 2] - (rgb[..., 0] + rgb[..., 1]) / 2
    s = np.clip((blue - 0.02) / 0.10, 0, 1)
    return 1 - cv2.GaussianBlur(s, (0, 0), 1.2)


def paste_masks(parent: np.ndarray, take: np.ndarray, window: tuple[int, int, int, int]) -> np.ndarray:
    """The old station: where the take differs from its parent inside the window, closed, holes filled, the biggest piece,
    grown 8 px (a hard 0/1 mask at texture size)."""
    x0, y0, x1, y1 = window
    d = np.abs(take - parent).max(-1)
    raw = np.zeros(parent.shape[:2], np.uint8)
    raw[y0:y1, x0:x1] = d[y0:y1, x0:x1] > 0.12
    raw = cv2.morphologyEx(raw, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
    n, lab, stat, _ = cv2.connectedComponentsWithStats(raw, connectivity=8)
    if n < 2:
        raise SystemExit("the erase take does not differ from its parent in the window")
    keep = 1 + int(np.argmax(stat[1:, cv2.CC_STAT_AREA]))
    raw = ndimage.binary_fill_holes(lab == keep).astype(np.uint8)
    return cv2.dilate(raw, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (17, 17)))


def match_to_parent(take_rgb: np.ndarray, parent_rgb: np.ndarray, parent_alpha: np.ndarray, hard: np.ndarray) -> np.ndarray:
    """The take's colours moved so that the mean Lab colour of a ring of lawn round the region is the parent's."""
    near = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (81, 81))) > 0
    close = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21))) > 0
    ring = near & ~close & (parent_alpha > 0.95) & (parent_rgb[..., 1] > parent_rgb[..., 2] + 0.05)
    if ring.sum() < 200:
        return take_rgb
    lab_ring = srgb_lab(parent_rgb)[..., 0]
    ring &= lab_ring >= np.median(lab_ring[ring])           # lighter half: the lawn in light, not in a building's shade
    lp, lt = srgb_lab(parent_rgb), srgb_lab(take_rgb)
    delta = lp[ring].mean(0) - lt[ring].mean(0)
    return lab_srgb(lt + delta)


def first_row(a: np.ndarray, x: int, y0: int, y1: int) -> float:
    """The first row of column `x` (from `y0`) whose alpha is over a half; `y1` if none."""
    y0 = max(y0, 0)
    col = a[y0:y1, x] > 0.5
    return float(y0 + np.argmax(col)) if col.any() else float(y1)


def hill_ceiling(alpha: np.ndarray, p_a: np.ndarray, t_a: np.ndarray, window: tuple, crop_tex: tuple) -> np.ndarray:
    """The island's top edge across the window: the take's hill line, moved so that it meets the parent's edge at both
    sides of the window (the parent's edge beside the old stall), so no vertical cut or stub is left where the old stall
    ended; everything above it is sky. Only ever clears alpha."""
    x0, y0, x1, y1 = window
    cx, cy = crop_tex
    X0, X1, Y0, Y1 = x0 - cx, x1 - cx, y0 - cy, y1 - cy
    h, w = alpha.shape
    X0, X1 = max(X0, 6), min(X1, w - 6)
    yl, yr = first_row(p_a, X0 - 4, Y0 - 120, Y1), first_row(p_a, X1 + 4, Y0 - 120, Y1)
    xs = np.arange(X0, X1)
    take_line = np.array([first_row(t_a, int(x), Y0 - 120, Y1) for x in xs])
    take_line = cv2.GaussianBlur(take_line.reshape(1, -1).astype(np.float32), (0, 0), 3.0, borderType=cv2.BORDER_REPLICATE)[0]
    u = (xs - X0) / max(X1 - 1 - X0, 1)
    line = take_line + (yl - take_line[0]) * (1 - u) + (yr - take_line[-1]) * u
    out = alpha.copy()
    rows = np.arange(h, dtype=np.float32)[:, None]
    sky = np.clip((line[None, :] - rows) / 2.0 + 0.5, 0, 1)         # 1 above the line, a 2 px ramp
    out[:, X0:X1] = np.where(rows < Y1, alpha[:, X0:X1] * (1 - sky), alpha[:, X0:X1])
    return out


def build_base(stage: int, spec: dict) -> tuple[np.ndarray, dict]:
    """The shipped plate of a day stage with the station erased: RGBA floats, the plate's crop."""
    light = "day"
    hand = ingest.load_hand(ISLAND)
    crop = ingest.plate_crop_points(ISLAND, hand, light, stage)
    cx, cy = crop[0] * TEX, crop[1] * TEX
    name = ingest.asset_name(ISLAND, "plate", light, stage)
    with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
        plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    h, w = plate.shape[:2]
    parent = ingest.source_plate(ingest.REPO / hand["plates"][light][str(stage)])[0].astype(np.float32)
    job = ingest.REPO / "design" / "art" / "takes" / spec["job"]
    take = np.asarray(Image.open(take_path(spec["job"])).convert("RGB").resize((parent.shape[1], parent.shape[0]), Image.LANCZOS), np.float32) / 255
    hard_full = paste_masks(parent, take, spec["window"])
    for ex0, ey0, ex1, ey1 in spec.get("exclude", []):
        hard_full[ey0:ey1, ex0:ex1] = 0
    sl = (slice(cy, cy + h), slice(cx, cx + w))
    hard = hard_full[sl]
    p_rgb, p_a = plate[..., :3], plate[..., 3]
    t_rgb = take[sl]
    # the take's grass line is mixed with its sky: colours come from the nearest sure-island pixel
    t_a = sky_alpha(t_rgb)
    sure = t_a > 0.97
    _, (iy, ix) = ndimage.distance_transform_edt(~sure, return_indices=True)
    t_rgb = np.where((t_a < 0.97)[..., None], t_rgb[iy, ix], t_rgb)
    t_rgb = match_to_parent(t_rgb, parent[sl], p_a, hard)
    m_alpha = cv2.GaussianBlur(cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))).astype(np.float32), (0, 0), 3.0)
    m_rgb = cv2.GaussianBlur(cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25))).astype(np.float32), (0, 0), FEATHER_TEX / 3)
    # the plate's alpha only shrinks in the region (the old counter hung over the sky); never grows
    # and only where the old stall (not lawn) stood: the take's hill line is not the parent's, so the parent's own grass
    # keeps its alpha, and the grass colour there is the take's nearest lawn
    pr = parent[sl]
    grass = ((pr[..., 1] > pr[..., 0] + 0.03) & (pr[..., 1] > pr[..., 2] + 0.10)).astype(np.float32)
    grass = cv2.GaussianBlur(cv2.erode(grass, np.ones((3, 3), np.uint8)), (0, 0), 1.5)
    m_shrink = m_alpha * (1 - grass)
    new_a = p_a * (1 - m_shrink) + np.minimum(p_a, t_a) * m_shrink
    new_rgb = p_rgb * (1 - m_rgb[..., None]) + t_rgb * m_rgb[..., None]
    new_a = hill_ceiling(new_a, p_a, t_a, spec["window"], (cx, cy))
    rgb = ingest.extended(np.where(new_a[..., None] > 0, new_rgb, p_rgb), new_a)
    out = np.dstack([rgb, new_a])
    info = {"crop": crop, "changed": float(m_rgb.max()), "hard_full": hard_full}
    return out, info


SIZE_TEX = (2048, 3072)


def clear_occluders(stage: int, hard_full: np.ndarray) -> None:
    """Another object's occluder cut-out that reaches into the erased stall (the workshop's polygon runs on to the stall's
    left pole) would draw the old stall again over the base: its alpha is cleared inside the erased region."""
    hand = ingest.load_hand(ISLAND)
    rgb, k = ingest.source_plate(ingest.REPO / hand["plates"]["day"][str(stage)])
    a1 = ingest.load_matte(ISLAND, "day", stage)
    region = cv2.GaussianBlur(cv2.dilate(hard_full, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13))).astype(np.float32), (0, 0), 2.0)
    for obj in hand["objects"]:
        if not obj.get("occluder") or not ingest.present(obj, "day", stage) or obj["id"] == TEA_STALL["id"]:
            continue
        _, box = ingest.occluder_cut(np.zeros(a1.shape + (3,)), a1, ingest.pct_to_px(obj["points"]))
        x0, y0, x1, y1 = (v * k for v in box)
        part = region[y0:y1, x0:x1]
        if part.max() <= 0.01:
            continue
        name = ingest.asset_name(ISLAND, "occ", "day", stage, obj["id"])
        with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
            old = np.asarray(im.convert("RGBA"), np.float32) / 255
        old[..., 3] *= 1 - part[: old.shape[0], : old.shape[1]]
        ingest.write_imageset(name, to_img(old))
        print(f"  occluder {obj['id']} {stage}: cleared {int((part > 0.5).sum())} px of the erased stall")


def cmd_bases() -> dict:
    out = {}
    for stage, spec in BASES.items():
        x, info = build_base(stage, spec)
        ingest.write_imageset(base_name("day", stage), to_img(x))
        # The Map's island cut (and the graded island layer) is the same picture: it must not paint the stall either.
        crop = info["crop"]
        full = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
        full[crop[1] * TEX:crop[1] * TEX + x.shape[0], crop[0] * TEX:crop[0] * TEX + x.shape[1]] = x
        # `ingest.cmd_deliver` cuts it at the stage matte's box (`ingest.bbox`), `map_cut.py` clears the level-10 ghost.
        ix0, iy0, ix1, iy1 = ingest.bbox(ingest.load_matte(ISLAND, "day", stage), 0.02)
        for kind in ("island", "mapisle"):
            name = ingest.asset_name(ISLAND, kind, "day", stage)
            with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
                old = np.asarray(im.convert("RGBA"), np.float32) / 255
            cut = resize_rgba(full[iy0 * TEX:iy1 * TEX, ix0 * TEX:ix1 * TEX], 1.0)
            cut = cv2.resize(np.dstack([cut[..., :3] * cut[..., 3:], cut[..., 3:]]), (old.shape[1], old.shape[0]), interpolation=cv2.INTER_AREA)
            a = cut[..., 3:]
            rgb = np.where(a > 1e-4, cut[..., :3] / np.maximum(a, 1e-4), old[..., :3])
            alpha = np.minimum(old[..., 3:], a) if kind == "mapisle" else a
            ingest.write_imageset(name, to_img(np.dstack([rgb, alpha])))
        clear_occluders(stage, info["hard_full"])
        out[stage] = x.shape[:2]
        print(f"base day {stage}: {x.shape[1]} x {x.shape[0]} px")
    return out


# ---------------------------------------------------------------- data

def asset_pixels(name: str) -> int:
    with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
        return im.width * im.height


def stations_data(spec: dict = TEA_STALL) -> dict:
    """The `stations` block of plate-home.json (read by ingest.build_json)."""
    built = build_looks(spec)
    levels = sorted(built["looks"])
    return {
        spec["id"]: {
            "light": spec["light"],
            "levels": len(levels),
            "box": built["box"],
            "foot": built["foot"],
            "density": DENSITY,
            "baseStages": sorted(BASES),
            "stages": {str(st): stage_place(st, built["box"]) for st in sorted(BASES)},
            "lookBytes": [asset_pixels(look_name(spec["id"], n, spec["light"])) for n in levels],
            "baseBytes": {str(s): asset_pixels(base_name(spec["light"], s)) for s in sorted(BASES)},
        }
    }


def stage_place(stage: int, ref_box: list[float]) -> dict:
    """One stage's transform: the look canvas's box scaled about the foot, and the foot (plate points)."""
    fx, fy = PLACE[stage]["foot"]
    k = PLACE[stage]["scale"]
    rx, ry = TEA_STALL["foot"]
    box = [fx + (ref_box[0] - rx) * k, fy + (ref_box[1] - ry) * k, fx + (ref_box[2] - rx) * k, fy + (ref_box[3] - ry) * k]
    return {"foot": [fx, fy], "scale": k, "box": [round(v, 2) for v in box]}


def cmd_json() -> None:
    STATIONS_JSON.write_text(json.dumps({"stations": stations_data()}, indent=1) + "\n")
    print(f"json: {STATIONS_JSON.relative_to(ingest.REPO)}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["looks", "bases", "json", "all"])
    args = ap.parse_args(argv)
    heic.require()
    if args.command in ("looks", "all"):
        cmd_looks()
    if args.command in ("bases", "all"):
        cmd_bases()
    if args.command in ("json", "all"):
        cmd_json()
    return 0


if __name__ == "__main__":
    sys.exit(main())
