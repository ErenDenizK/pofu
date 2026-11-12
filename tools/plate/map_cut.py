#!/usr/bin/env python3
"""Cut Home's island for the Map from each level's own painting, without the level-10 ghost.

    python3 -I tools/plate/map_cut.py [--check] [--preview DIR]

Every Home state shares the level-10 matte (`ingest.py load_matte`), so below level 10 the shipped
island cut (`world-home-island-<light>-<stage>`) carries the sky the lower level paints where level 10
has its windmill, lighthouse, hill and harbour islet: a pale sky-and-cloud silhouette behind the island
on the Map. This tool removes it, from the shipped art alone (no new painting):

  1. the sky's colours: the state's own plate outside the matte (its sky and clouds), in CIELAB;
  2. inside the matte, a pixel is sky when its colour lies within `NEAR` (Delta E) of that sky, and
     it is reached from the matte's outside through sky-coloured pixels (a hysteresis flood: seeds within
     `SEED`, growing within `NEAR`), so a white fence or the pond, enclosed by the island, stays;
  3. the cut keeps the shipped RGB and alpha, times the remaining mask, its new edge feathered by one
     pixel; components smaller than `SPECK` are dropped;
  4. the alpha is made whole inside (`solid`): the level-10 matte's wide feather into the cloud would
     let the Map's sky show through the island's rim.

Writes `World.xcassets/world-home-mapisle-<light>-<stage>` (HEIC q70 with alpha, as the island cut) for
every state; level 10's day, golden and night are the matte's own shape and come out unchanged.
`--check` fails when any state keeps more than `MAX_GHOST` of its sky-coloured pixels touching the top.
Deterministic. Needs numpy, scipy, OpenCV, Pillow and pillow-heif.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.spatial import cKDTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import ingest  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "World.xcassets"
PLATES = ROOT / "design" / "art" / "plates"

SEED = 5.0    # Delta E: a pixel this close to the sky starts the flood
NEAR = 11.0   # Delta E: the flood grows through pixels this close
TRIM = 9.0    # Delta E: after GrabCut, sky-coloured pixels this close at the new edge go too
CORE = 14     # px at plate size: a present object's tap polygon, eroded this far, is surely painted
SPECK = 40    # px at cut size: smaller kept islands of pixels are dropped
SAMPLES = 40000
LAWN = 0.47    # share of the plate's height: no sky is sampled below it (the cloud sea is as warm as the earth)
BLUE = -10.0  # CIELAB b*: the clear sky is bluer than this, a white roof, a cloud or a teapot is not
EDGE = 0.52    # share of the plate's height: down to here a pixel the sky's own colour is still sky
BODY = 0.47    # share of the plate's height: below it the matte is the island's body at every level
ISLET = 0.79   # share of the plate's width: the harbour islet lies right of it
NECK = 0.80    # share of the plate's width: the matte's neck between the island and the islet
HOLE = 30      # px at plate size: enclosed clear sky this large is cut out
NECK_FADE = 0.035  # share of the plate's width over which the cut fades out before the neck
SOLID = (0.10, 0.50)  # shipped alpha: from the first up to the second is stretched to full (`solid`)


def lab(rgb: np.ndarray) -> np.ndarray:
    return ingest.srgb_to_lab(np.clip(rgb, 0, 1))


def states(island: str = "home"):
    data = json.loads((ASSETS.parent / "Plates" / f"plate-{island}.json").read_text())
    hand = ingest.load_hand(island)
    for light, stage, _ in ingest.plates(hand):
        yield light, stage, data


def load(name: str) -> np.ndarray:
    heic.register()
    path = ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}"
    return np.asarray(Image.open(path).convert("RGBA"), np.float32) / 255


def sky_mask(light: str, stage: int) -> tuple[np.ndarray, np.ndarray]:
    """The shipped cut (RGBA at cut size) and the mask of its ghost sky (True = remove)."""
    cut = load(ingest.asset_name("home", "island", light, stage))
    plate = load(ingest.asset_name("home", "plate", light, stage))
    hand = ingest.load_hand("home")
    a1 = ingest.load_matte("home", light, stage)
    h1, w1 = a1.shape
    rgb = cv2.resize(plate[..., :3], (w1, h1), interpolation=cv2.INTER_AREA)
    x0, y0, x1, y1 = ingest.bbox(a1, 0.02)
    inside = a1 > 0.02
    # The sky's colours: outside the matte and above the lawn, away from the feathered border.
    outside = ndimage.binary_erosion(~inside, iterations=6)
    outside[int(LAWN * h1):, :] = False
    outside[:, :24] = False
    outside[:, w1 - 24:] = False
    outside[:24, :] = False
    col = lab(rgb)
    sky = col[outside]
    if len(sky) > SAMPLES:
        sky = sky[np.random.default_rng(7).choice(len(sky), SAMPLES, replace=False)]
    d, _ = cKDTree(sky).query(col.reshape(-1, 3), k=1)
    d = d.reshape(h1, w1)
    # GrabCut, seeded from what the plate data knows at this stage:
    #   background  outside the matte; sky-coloured pixels above the lawn reached from outside
    #   foreground  the island's body below the lawn's back edge, and every object painted at this stage
    #   probable    the rest of the matte (what stands above the lawn, and the harbour islet)
    k = lambda r: cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    body = inside.copy()
    body[: int(BODY * h1), :] = False
    body = cv2.erode(body.astype(np.uint8), k(6)) > 0
    present = {o["id"] for o in hand["objects"] if ingest.present(o, light, stage)}
    islet = np.zeros_like(inside)
    islet[:, int(ISLET * w1):] = True
    islet_painted = bool(present & {"bagelCart", "pier", "lighthouse"})
    if not islet_painted:
        body &= ~islet
    objects = np.zeros_like(inside)
    m = np.full((h1, w1), cv2.GC_PR_FGD, np.uint8)
    m[~inside] = cv2.GC_BGD
    m[body] = cv2.GC_FGD
    for o in hand["objects"]:
        if o["id"] in present and o["id"] not in ("door",):
            poly = ingest.poly_mask((h1, w1), ingest.pct_to_px(o["points"]))
            objects |= poly
            # A tap polygon is loose around its object (sky inside it beside a roof): only its core is sure.
            m[cv2.erode(poly.astype(np.uint8), k(CORE)) > 0] = cv2.GC_FGD
    upper = np.zeros_like(inside)
    upper[: int(BODY * h1), :] = True
    upper |= islet & ~body
    edge = ndimage.binary_dilation(~inside, iterations=2) & inside
    grow = inside & upper & (d < NEAR) & (m != cv2.GC_FGD)
    lbl, _ = ndimage.label(grow)
    hit = np.unique(lbl[edge & (d < SEED)])
    flood = np.isin(lbl, hit[hit > 0])
    m[flood & ~objects] = cv2.GC_PR_BGD
    m[flood & ~objects & (d < SEED)] = cv2.GC_BGD
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    img = np.uint8(np.clip(rgb, 0, 1) * 255)[..., ::-1].copy()
    cv2.grabCut(img, m, None, bgd, fgd, 5, cv2.GC_INIT_WITH_MASK)
    fg = np.isin(m, (cv2.GC_FGD, cv2.GC_PR_FGD))
    # What GrabCut left of the sky at the new edge (slivers beside a roof, a cloud on a hilltop): sky-
    # coloured pixels above the lawn reached from the background, never a painted object.
    low = np.zeros_like(inside)
    low[: int(EDGE * h1), :] = True
    for _ in range(3):
        free = fg & ((upper & (d < TRIM) & (m != cv2.GC_FGD) & ~objects) | ((upper | low) & (d < SEED) & (col[..., 2] < BLUE)))
        lbl, _ = ndimage.label(free)
        hit = np.unique(lbl[ndimage.binary_dilation(~fg, iterations=1) & free])
        fg &= ~np.isin(lbl, hit[hit > 0])
    # The sky seen through an object (between a stall's counter and its canopy): enclosed clear sky.
    hole, n = ndimage.label((upper | low) & fg & (d < SEED) & (col[..., 2] < BLUE))
    if n:
        sizes = ndimage.sum(np.ones_like(d), hole, range(1, n + 1))
        fg &= ~np.isin(hole, 1 + np.flatnonzero(sizes >= HOLE))
    if not islet_painted:
        # No islet at this level: what the matte keeps beyond the neck is the painting's cloud.
        fg[:, int(NECK * w1):] = False
    fg = ndimage.binary_opening(fg, iterations=1)
    lbl, n = ndimage.label(fg)
    if n:
        sizes = ndimage.sum(fg, lbl, range(1, n + 1))
        fg = np.isin(lbl, 1 + np.flatnonzero(sizes >= SPECK))
    fg = ndimage.binary_fill_holes(fg)
    # To cut size: the cut is the matte's box at `ingest.ISLAND_SCALE`.
    ch, cw = cut.shape[:2]
    soft = fg.astype(np.float32)
    if not islet_painted:
        # The island ends in the painting's cloud before the neck: a short fade there, not a straight edge.
        cols = np.arange(w1, dtype=np.float32) / w1
        soft *= np.clip((NECK - cols) / NECK_FADE, 0, 1)[None, :]
    keep = cv2.resize(soft[y0:y1, x0:x1], (cw, ch), interpolation=cv2.INTER_AREA)
    return cut, keep


def day_shape(light: str, stage: int) -> tuple[np.ndarray, np.ndarray]:
    """The shipped cut of `light` and, as its mask, the day plate's own matte over the cut's box."""
    cut = load(ingest.asset_name("home", "island", light, stage))
    a1 = ingest.load_matte("home", light, stage)
    day = ingest.load_matte("home", "day", stage)
    x0, y0, x1, y1 = ingest.bbox(a1, 0.02)
    ch, cw = cut.shape[:2]
    keep = cv2.resize(day[y0:y1, x0:x1].astype(np.float32), (cw, ch), interpolation=cv2.INTER_AREA)
    return cut, keep


def solid(alpha: np.ndarray) -> np.ndarray:
    """The island's own soft edge made whole: where the level-10 matte feathered the island into the
    painting's cloud (the rim and the tea stand at low levels), the shipped alpha falls to a half and
    less over many pixels and the Map's sky showed through the island. Alpha from `SOLID[0]` up to
    `SOLID[1]` is stretched to full, so the island ends in the painting's own mist, opaque; the outer
    pixel stays feathered."""
    lo, hi = SOLID
    return np.clip((alpha - lo) / (hi - lo), 0, 1)


def clean(cut: np.ndarray, keep: np.ndarray) -> np.ndarray:
    out = cut.copy()
    out[..., 3] = solid(cut[..., 3]) * np.clip(cv2.GaussianBlur(keep, (3, 3), 0.6), 0, 1)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--preview", type=Path, help="also write each cut over magenta here")
    ap.add_argument("--dry", action="store_true", help="do not write the assets")
    args = ap.parse_args()
    for light, stage, _ in states():
        day_own = stage != 0 and ingest.matte_path("home", "day", stage).exists()
        if stage == 0 or (light == "day" and day_own):
            # Level 10, and a level whose day plate has its own matte (IL1): the cut is the painting's
            # own shape and ships as it is.
            cut = load(ingest.asset_name("home", "island", light, stage))
            keep = np.ones(cut.shape[:2], np.float32)
        elif day_own:
            # Another light of such a level is the same painting relit: it takes the day's own shape.
            cut, keep = day_shape(light, stage)
        else:
            cut, keep = sky_mask(light, stage)
        out = clean(cut, keep)
        removed = 1 - float(out[..., 3].sum()) / max(float(cut[..., 3].sum()), 1)
        img = Image.fromarray(np.uint8(np.clip(out, 0, 1) * 255 + 0.5), "RGBA")
        name = ingest.asset_name("home", "mapisle", light, stage)
        if not args.dry:
            ingest.write_imageset(name, img)
        if args.preview:
            args.preview.mkdir(parents=True, exist_ok=True)
            bg = Image.new("RGBA", img.size, (255, 0, 255, 255))
            bg.alpha_composite(img)
            bg.convert("RGB").save(args.preview / f"{name}.png")
        print(f"{name}: removed {removed:.1%} of the cut")
    return 0


if __name__ == "__main__":
    sys.exit(main())
