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

The windmill (batch 134's plot pilot) has no cut-outs: its takes are the plot's whole painting (hill, gate, stairs, sky)
with the mill on it. Its looks are cut here from each take against level 1's take (the empty plot, the same painting
without the mill): where a take differs from it and is not lawn, minus the bakery wing that stands where the workshop
is (the workshop keeps its own plate), minus the paved yard; edge colours come from the mill's inside (no sky tint).
"""
from __future__ import annotations

import argparse
import json
import os
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
    "levels": 5,
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
TEA_STALL["bases"] = BASES
TEA_STALL["place"] = PLACE

# The windmill (batch 134's plot pilot; the plot is the island's level 10 and 9 painting, where the mill stands: stages 0
# and 1, island levels 10 and 9; the mill opens at island level 8, stage 2, which has no clean base yet). Looks 2 to 5 are
# the picks of the pilot's takes (level 1 has none: the lead rejected both takes, a paper pinwheel); every take is 1254 px
# square with the plot at 0.30 plate points per px. `anchor` is the tower's bottom centre in take px (the take's tower is
# unmoved from level to level), `foot` where the painted mill's bottom centre stands at stage 0 (plate points).
# `grade`: per level, (chroma, lightness) factors that bring the mill's mean CIELAB colour to the painted mill's (L* 78,
# C* 29 at stage 0; the takes are L* 71 to 76 and C* 36 to 48, level 2's sails candy orange): measured in place.
# `wing`: the bakery wing that levels 4 and 5 paint where the workshop stands is cut away (right of x, below y, in take
# px; below `y` only the tower's own footprint and the sacks stay: the paved yard is the plot's); `bush`: a take-px box
# where green (the hill's bush behind level 5's left lantern) is not the mill.
PLOT = "batch-134-plot-pilot/x-plot-windmill-{}"
WINDMILL = {
    "id": "windmill",
    "light": "day",
    "levels": 5,
    "plot": {
        "ref": (PLOT.format(1), 1),
        "takes": {2: (PLOT.format(2), 2), 3: (PLOT.format(3), 1), 4: (PLOT.format(4), 1), 5: (PLOT.format(5), 1)},
        "diff": 14,
        "grade": {2: (0.56, 1.07), 3: (0.72, 1.02), 4: (0.71, 1.03), 5: (0.77, 1.04)},
        "wing": {"x": 846, "y": 705, "roof_x": 895, "roof_y": 650},
        "bush": (0, 380, 336, 620),
    },
    "scale": 0.60,               # of a take px, at TEX px per point (0.30 points per px)
    "density": 2.0,
    "anchor": (655.0, 988.0),
    "foot": (345.0, 759.0),
    "footStage": 0,
    "bases": {
        0: {"job": JOB.format(10), "window": (500, 1020, 892, 1560), "clean": True},
        1: {"job": JOB.format(9), "window": (500, 1020, 892, 1560), "clean": True},
        2: {"job": JOB.format(8), "window": (566, 1020, 892, 1560), "clean": True},   # the bench stands left of it
    },
    "place": {
        0: {"foot": (345.0, 759.0), "scale": 1.0},
        1: {"foot": (350.0, 759.0), "scale": 0.97},
        2: {"foot": (347.0, 753.0), "scale": 0.88},
    },
}

# The pond (batch 134's plot pilot, painted into a crop of batch 117's erased level 10 base: plate x 0 to 432, y 660 to 1092,
# resized to the take's 1254 px, so a take px is 432 / 1254 plate points). The takes are aligned edits of that crop; the
# pond is ground (water), so its cut is the pixels that differ from the bare crop and are not lawn (the takes' lawn is
# regraded yellower), with the garden's gate, the path and the mailbox, which the bare crop has too, staying the plate's.
# `grade`: (chroma, lightness) factors that bring the take's water (mean CIELAB) to the plate's pond at stage 0 (L* 61, C* 23).
# The island is the same under levels 10 to 7 (an ECC fit of the erase takes moves it under 1 px), so one transform serves.
PLOT_POND = "batch-134-plot-pilot/x-plot-pond-{}"
POND = {
    "id": "pond",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "water",
        "bare": (JOB.format(10), (0, 660, 432, 1092)),
        "takes": {1: (PLOT_POND.format(1), 1), 2: (PLOT_POND.format(2), 1), 3: (PLOT_POND.format(3), 1),
                  4: (PLOT_POND.format(4), 2), 5: (PLOT_POND.format(5), 1)},
        "diff": 14,
        "reeds": {2: [(380, 280, 680, 800)]},   # level 2's reeds are lawn-green but darker than the lawn
        "clear": {1: [(0, 690, 112, 840)],        # level 1's lawn tuft left of the ring
                  3: [(1085, 600, 1260, 740), (1156, 540, 1260, 600)],      # the take's path stones beside the deck
                  4: [(1085, 600, 1260, 740), (1156, 540, 1260, 600)],
                  5: [(1085, 600, 1260, 740), (1156, 540, 1260, 600)]},
        "fill": {3: [(76, 575, 150, 630)], 4: [(76, 575, 150, 630)], 5: [(76, 575, 150, 630)]},     # the lily pad at the left rim
        "clamp": {1: [(0, 700), (112, 718), (135, 735), (160, 746), (191, 750), (250, 752), (310, 768), (360, 786), (420, 800), (900, 820)],
                  3: [(0, 715), (150, 716), (230, 730), (300, 748), (350, 764), (420, 778), (470, 782), (560, 790), (620, 806), (700, 818), (780, 822)], 4: [(0, 715), (150, 716), (230, 730), (300, 748), (350, 764), (420, 778), (470, 782), (560, 790), (620, 806), (700, 818), (780, 822)], 5: [(0, 715), (150, 716), (230, 730), (300, 748), (350, 764), (420, 778), (470, 782), (560, 790), (620, 806), (700, 818), (780, 822)]},     # the flower bush the takes paint over the water's lower edge
        "grade": {1: (0.57, 1.067), 2: (0.60, 1.11), 3: (0.61, 1.086), 4: (0.67, 1.104), 5: (0.88, 1.058)},
    },
    # The mailbox and the flower bush stand in front of the pond: their occluders are the plate's flowers, which the lake
    # (a look drawn under them) must stay behind, so they are not cleared inside the erased ring.
    "keepOccluders": ("mailbox", "westBush"),
    # The look's lower edge ran straight across the foreground hydrangeas and flowers (plate points 60..330 x 905..935) and washed their
    # tops: the occluder polygons start below their tops. The look now leaves the plate's flowers, leaves and mailbox showing.
    "flowerMatte": {"lawn": (195, 900, 230, 915), "from": 880, "dE": 20},
    "scale": 0.689,              # of a take px, at TEX px per point (0.3445 points per px)
    "density": 2.0,
    "anchor": (627.0, 223.5),    # a point at the top of the water, not at its foot: a pond is ground, so its look's foot
    "foot": (216.0, 737.0),      # (its depth) sits behind every character that can stand on it, and covers none
    "footStage": 0,
    # The window is the shipped pond (ring, deck, boat, lanterns, lily): an ellipse round the ring and a box round the deck
    # (the takes regrade the whole lawn), its top left is the garden's fence, which stays, and the mailbox is an occluder of
    # its own (texture px). The pond stands unchanged under levels 10 to 7; it is inside the island (`interior`: its alpha
    # stays the plate's), and the lawn colour is matched to a ring of all the lawn round it, not the lighter half.
    "bases": {s: {"job": JOB.format(10 - s), "window": (110, 1600, 730, 1890),
                  "shapes": [("e", 420, 1775, 322, 132), ("r", 400, 1610, 600, 1700)],       # the ring and the deck
                  "exclude": [(130, 1600, 400, 1692)],                                       # the garden's fence stays
                  "excludeOccluders": ("mailbox", "westBush"), "flowersOnly": ("westBush",), "interior": True, "lighter": False, "brightRing": True} for s in (0, 1, 2, 3)},
    "place": {s: {"foot": (216.0, 737.0), "scale": 1.0} for s in (0, 1, 2, 3)},
}
# The garden (batch 189) and the workshop (batch 191): plot ladders painted like the pond's, into a crop of batch 117's erased
# level 10 base (garden plate pts 0,594 to 320,914; workshop 381,516 to 712,847, resized to the take's 1254 px, so a take px is
# 320 / 1254 and 331 / 1254 plate points). The takes regrade the whole picture, the lawn and the sky included, and the
# stations are as green as the lawn (leaves, vines), so neither a lawn test nor a plain difference cuts them: `regrade` fits one
# affine map in CIELAB from the bare crop to each take (robustly, the lawn and sky being most of the picture), takes the
# pixels that still differ (`diff`), and gives the look its colours back through the inverse map, so the look is in the plate's
# own colours (no yellow lawn tint at the edge). Picks: t1 of every level, the take each next level edits (the one unbroken ladder).
PLOT_GARDEN = "batch-189-plot-ladder-garden/x-plot-garden-{}"
GARDEN = {
    "id": "garden",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "regrade",
        "bare": (JOB.format(10), (0, 594, 320, 914)),
        "takes": {n: (PLOT_GARDEN.format(n), 1) for n in range(1, 6)},
        "diff": 16,
        "close": {1: 41, 2: 41, 3: 41, 4: 61, 5: 81},
        "smooth": 6,
        "sky": True,
        "grade": {n: (1.0, 1.0) for n in range(1, 6)},
    },
    "scale": 0.5104,             # of a take px, at TEX px per point (0.2552 points per px)
    "density": 2.0,
    "anchor": (529.0, 988.0),    # the bed's bottom centre in the take (level 3's), where the garden's foot stands
    "foot": (135.0, 846.0),
    "footStage": 0,
    # Stage 3 (island level 7) is not wired: its plate paints the level 4 arch up into the hill's mist and the erase take paints cloud
    # there, so the base shows a pale ghost over the hill. Stages 0 to 2 are clean.
    # The old garden: the big sunflower, the bed, its flowers and the fence, left of the gate (plate x 20 to 235, y 660 to 846);
    # the pond's ring starts below the fence (y 846), where the pond's window takes over.
    "bases": {s: {"job": JOB.format(10 - s), "window": (40, 1320, 470, 1692), "shapes": [("e", 250, 1535, 235, 190)], "exclude": [(40, 1400, 110, 1530)], "interior": True, "lighter": False, "brightRing": True} for s in (0, 1, 2)},
    "place": {s: {"foot": (135.0, 846.0), "scale": 1.0} for s in (0, 1, 2)},
}
PLOT_WORKSHOP = "batch-191-plot-ladder-workshop/x-plot-workshop-{}"
WORKSHOP = {
    "id": "workshop",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "regrade",
        "bare": (JOB.format(10), (381, 516, 712, 847)),
        "takes": {n: (PLOT_WORKSHOP.format(n), 1) for n in range(1, 6)},
        "diff": 16,
        "notLawn": True,
        "close": 61,
        "flatBottom": 40,
        "grade": {n: (1.0, 1.0) for n in range(1, 6)},
    },
    "scale": 0.5279,             # 0.2640 points per take px
    "density": 2.0,
    "anchor": (668.0, 985.0),
    "foot": (557.3, 776.0),
    "footStage": 0,
    "bases": {s: {"job": JOB.format(10 - s), "window": (860, 1150, 1300 if s < 3 else 1226, 1580), "excludeOccluders": ("teaStall",), "excludeGrow": 2, "exclude": [(1070, 1526, 1200, 1620), (860, 1470, 965, 1545)],   # stage 3: the window stops at 1226, the tea stall's own window (from 1252) erases the rest
                  "interior": False, "lighter": False} for s in (0, 1, 2, 3)},
    "place": {s: {"foot": (557.3, 776.0), "scale": 1.0} for s in (0, 1, 2, 3)},
}

# The bagel cart (batch 190) and the lighthouse (batch 192): plot ladders like the workshop's, crops of batch 117's erased level 10
# base (plate pts 670,550 to 990,870 and 704,502 to 1024,822; a take px is 320 / 1254 = 0.2552 points). Their erase takes fill the
# islet gap with lawn (the bridge, the boat and the lamps are gone there), so a base window is a tight box round the old station
# and never reaches the islet's front rim, and a look is placed at the plate's own painted foot (the takes put the cart lower than
# the plate does): its pixels are the station's, never the gap's. Picks: t1 of every level (the QA pick, the take each next level
# edits; t1 and t2 are near twins and t1 changes the least away from the station: see the PR). Stages 1 and 2 (island levels 9 and 8):
# stage 0 paints a hydrangea bush in front of the tower's foot and the cart stands against the tower, and the erase take redraws the bush
# (lower, blurrier), so erasing either leaves a ragged bush and a bitten tower: it keeps its painted cart and tower. Stage 3's erase take
# paints its own flower bush on another islet shape: also painted.
PLOT_BAGEL = "batch-190-plot-ladder-bagel-cart/x-plot-bagel-cart-{}"
BAGEL_CART = {
    "id": "bagelCart",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "regrade",
        "bare": (JOB.format(10), (670, 550, 990, 870)),
        "takes": {n: (PLOT_BAGEL.format(n), 1) for n in range(1, 6)},
        "diff": 16,
        "notLawn": True,
        "raw": True,
        "close": 61,
        "grade": {n: (0.82, 1.08) for n in range(1, 6)},   # to the painted cart's mean Lab colour (L* 67, C* 42)
    },
    "scale": 0.5104,             # 0.2552 points per take px
    "density": 2.0,
    "anchor": (605.0, 1030.0),   # the cart's bottom centre in every take (the wheels)
    "foot": (825.0, 760.0),      # where the plate paints it (stages 0 to 2)
    "footStage": 1,
    "bases": {s: {"job": JOB.format(10 - s), "window": (1556, 1300, 1744, 1532), "ceiling": False, "clearAlpha": [(1600, 1296, 1700, 1384)],
                  "interior": False, "lighter": False, "brightRing": True} for s in (1, 2)},
    "place": {s: {"foot": (825.0, 760.0), "scale": 0.92} for s in (1, 2)},
}
PLOT_LIGHTHOUSE = "batch-192-plot-ladder-lighthouse/x-plot-lighthouse-{}"
LIGHTHOUSE = {
    "id": "lighthouse",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "regrade",
        "bare": (JOB.format(10), (704, 502, 1024, 822)),
        "takes": {n: (PLOT_LIGHTHOUSE.format(n), 1) for n in range(1, 6)},
        "diff": 16,
        "notLawn": True,
        "raw": True,
        "close": 61,
        "clear": {4: [(540, 520, 632, 700)], 5: [(540, 520, 632, 700)]},     # the bunting's string stub left of the cap (the bunting itself runs over the cart)
        "grade": {n: (0.75, 1.05) for n in range(1, 6)},   # to the painted tower (L* 81, C* 30)
    },
    "scale": 0.5104,
    "density": 2.0,
    "anchor": (752.0, 946.0),
    "foot": (895.0, 743.0),
    "footStage": 1,
    "bases": {s: {"job": JOB.format(10 - s), "window": (1716, 1150, 2048, 1476), "ceiling": False,
                  "interior": False, "lighter": False, "brightRing": True} for s in (1, 2)},
    "place": {s: {"foot": (895.0, 743.0), "scale": 0.93} for s in (1, 2)},
}
# The garden is cut and based (above) but not shipped: its levels 3 to 5 stand where the pond's level 3 to 5 islet does (plate
# [64,746,211,853] against [99,743,230,846]), and levels 1 and 2 collide with a pond at level 5, so it waits for a re-take whose crop
# keeps the islet. Its spot keeps the plate's own painted bed.
STATIONS = [TEA_STALL, WINDMILL, POND, WORKSHOP, BAGEL_CART, LIGHTHOUSE]


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


# ---------------------------------------------------------------- plot looks (the windmill)

def _take_rgb(job_take: tuple[str, int]) -> np.ndarray:
    job, n = job_take
    found = sorted((TAKES / job).glob(f"*--t{n}.webp"))
    if not found:
        raise SystemExit(f"{job}: take {n} is not ingested")
    return np.asarray(Image.open(found[0]).convert("RGB"), np.float32) / 255


def _lab_soft(rgb: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(cv2.GaussianBlur(rgb, (0, 0), 1.2), cv2.COLOR_RGB2Lab)


def _lawn(rgb: np.ndarray) -> np.ndarray:
    return (rgb[..., 1] > rgb[..., 0] - 0.02) & (rgb[..., 1] > rgb[..., 2] + 0.15)


def _biggest(m: np.ndarray) -> np.ndarray:
    n, lab, stat, _ = cv2.connectedComponentsWithStats(m.astype(np.uint8), connectivity=8)
    return lab == 1 + int(np.argmax(stat[1:, cv2.CC_STAT_AREA]))


def _ellipse(k: int) -> np.ndarray:
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))


def _fill_not_sky(m: np.ndarray, rgb: np.ndarray) -> np.ndarray:
    """Holes of the mask filled, except where the take paints the sky (a gap between a sail, the gallery and the tower)."""
    filled = ndimage.binary_fill_holes(m)
    sky = sky_alpha(rgb) < 0.5
    return m | (filled & ~sky)


def water_masks(plot: dict) -> tuple[dict, dict, dict]:
    """The pond's masks: where a take differs from the bare crop (batch 117's erase, cropped and resized to the take) and
    is not lawn, closed, holes filled, the biggest piece. The bare crop's own flowers, stones and mailbox do not differ, so
    they stay the plate's (holes in the look)."""
    job, (x0, y0, x1, y1) = plot["bare"]
    n = pick_of(job)
    path = sorted((TAKES / job).glob(f"*--t{n}.webp"))[0]
    ref = np.asarray(Image.open(path).convert("RGB").crop((x0, y0, x1, y1)).resize((1254, 1254), Image.LANCZOS), np.float32) / 255
    ref_lab = _lab_soft(ref)
    rgbs = {n: _take_rgb(t) for n, t in plot["takes"].items()}
    out = {}
    for n, rgb in rgbs.items():
        d = np.abs(_lab_soft(rgb) - ref_lab).max(-1)
        keep = ~_lawn(rgb)
        for bx0, by0, bx1, by1 in plot.get("reeds", {}).get(n, []):     # reeds are lawn-green but darker than the lawn
            dark = cv2.cvtColor(rgb, cv2.COLOR_RGB2Lab)[..., 0] < 70
            keep[by0:by1, bx0:bx1] |= dark[by0:by1, bx0:bx1]
        m = ((d > plot["diff"]) & keep).astype(np.uint8)
        m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8)) > 0
        m = _biggest(ndimage.binary_fill_holes(m))
        m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_CLOSE, _ellipse(plot.get("close", {}).get(n, 25))) > 0
        m = _biggest(ndimage.binary_fill_holes(m))
        for bx0, by0, bx1, by1 in plot.get("fill", {}).get(n, []):       # a pad the lawn-green test cut out of the rim
            m[by0:by1, bx0:bx1] = True
        for bx0, by0, bx1, by1 in plot.get("clear", {}).get(n, []):      # a lawn tuft or path stones the take paints beside the pond
            m[by0:by1, bx0:bx1] = False
        pts = plot.get("clamp", {}).get(n)                              # the water's lower edge where the take's flower bush covers it
        if pts:
            h, w = m.shape
            yy, xx = np.mgrid[0:h, 0:w]
            m &= yy <= np.interp(xx, [p[0] for p in pts], [p[1] for p in pts], left=1e9, right=1e9)
        m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(9)) > 0
        m = cv2.GaussianBlur(m.astype(np.float32), (0, 0), plot.get("smooth", 3.0)) > 0.5      # a smooth rim, no bites
        out[n] = _biggest(m)
    return out, rgbs, dict(out)


def regrade_fit(ref_lab: np.ndarray, take_lab: np.ndarray) -> np.ndarray:
    """The affine map (4 x 3, rows: L a b 1) from the bare crop's CIELAB to the take's, fitted robustly: the 70 percent of pixels
    that agree best, six times over (the station is a small part of the picture)."""
    a = np.c_[ref_lab.reshape(-1, 3), np.ones(ref_lab.shape[0] * ref_lab.shape[1])]
    t = take_lab.reshape(-1, 3)
    keep = np.ones(len(t), bool)
    m = np.zeros((4, 3))
    for _ in range(6):
        idx = np.nonzero(keep)[0][::7]
        m = np.linalg.lstsq(a[idx], t[idx], rcond=None)[0]
        d = np.abs(t - a @ m).max(1)
        keep = d < np.percentile(d, 70)
    return m


def regrade_masks(plot: dict) -> tuple[dict, dict, dict]:
    """The plot ladder's masks (the garden, the workshop): where a take still differs from the bare crop after the affine
    regrade of its lawn and sky (`regrade_fit`), opened, holes filled, the biggest piece, closed. `notLawn` also drops the lawn
    tuft at the foot. The returned colours are the take's mapped back through the inverse regrade, so they are the plate's own."""
    job, (x0, y0, x1, y1) = plot["bare"]
    n = pick_of(job)
    path = sorted((TAKES / job).glob(f"*--t{n}.webp"))[0]
    ref = np.asarray(Image.open(path).convert("RGB").crop((x0, y0, x1, y1)).resize((1254, 1254), Image.LANCZOS), np.float32) / 255
    ref_lab = _lab_soft(ref)
    masks, rgbs = {}, {}
    for n, take in plot["takes"].items():
        rgb = _take_rgb(take)
        lab = _lab_soft(rgb)
        m = regrade_fit(ref_lab, lab)
        d = np.abs(lab - (np.c_[ref_lab.reshape(-1, 3), np.ones(ref_lab.shape[0] * ref_lab.shape[1])] @ m).reshape(lab.shape)).max(-1)
        mask = (d > plot["diff"]).astype(np.uint8)
        if plot.get("notLawn"):
            mask &= (~_lawn(rgb)).astype(np.uint8)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8)) > 0
        mask = _biggest(ndimage.binary_fill_holes(mask))
        mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, _ellipse(plot["close"].get(n, 41) if isinstance(plot.get("close"), dict) else plot.get("close", 25))) > 0
        mask = _biggest(ndimage.binary_fill_holes(mask))
        if plot.get("smooth"):                                            # a smooth rim, no bites, no grey fragments between the leaves
            mask = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), plot["smooth"]) > 0.5
            mask = _biggest(ndimage.binary_fill_holes(cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(13)) > 0))
        if plot.get("sky"):                                               # the take's sky seen through the arch or between the leaves is not the station
            mask = _biggest(ndimage.binary_fill_holes(cv2.morphologyEx((mask & (sky_alpha(rgb) >= 0.5)).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(7)) > 0))
        if plot.get("notLawn"):                                           # the sky seen between the gear, the chimney and the roof is not the house
            mask = _biggest(cv2.morphologyEx((mask & (sky_alpha(rgb) >= 0.5)).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(7)) > 0)
        fb = plot.get("flatBottom")
        if fb:                                                            # the doorstep's pale stones match the bare crop's: close the bites in the bottom edge
            h, w = mask.shape
            has = mask.sum(0) > 120
            top = np.where(has, np.argmax(mask, 0), h)
            bottom = np.where(has, h - 1 - np.argmax(mask[::-1], 0), -1).astype(np.float32)
            bottom = ndimage.maximum_filter1d(bottom, 2 * fb + 1)
            yy = np.arange(h)[:, None]
            fill = (yy >= np.maximum(top[None, :], bottom[None, :] - 70)) & (yy <= bottom[None, :]) & (bottom[None, :] >= 0) & has[None, :]
            mask |= fill & (sky_alpha(rgb) >= 0.5) & ~_lawn(rgb)           # only the step's own pixels, never sky or grass
            mask = _biggest(cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(11)) > 0)
        for bx0, by0, bx1, by1 in plot.get("clear", {}).get(n, []):       # a string or stub the take hangs across the neighbouring station
            mask[by0:by1, bx0:bx1] = False
        if plot.get("clear", {}).get(n):
            mask = _biggest(mask)
        masks[n] = mask
        full = srgb_lab(rgb)                                              # the take in the plate's own colours: the inverse map
        inv = np.linalg.pinv(m[:3])
        back = (full - m[3]) @ inv
        rgbs[n] = rgb if plot.get("raw") else lab_srgb(back)             # `raw`: a take whose lawn is regraded far (yellow) keeps its own colours, graded per level
    # Every take has its own regrade, so the same roof comes back a little redder or yellower from take to take. The levels
    # share what the previous level already had: each one's mean colour over the part it shares with the lowest level (eroded)
    # is moved to that level's own, in L* and in chroma, so a level up never recolours the station.
    low = min(masks)
    ref_lab = srgb_lab(rgbs[low])
    for n in sorted(masks):
        if n == low:
            continue
        both = cv2.erode((masks[n] & masks[low]).astype(np.uint8), _ellipse(31)) > 0
        if both.sum() < 2000:
            continue
        lab = srgb_lab(rgbs[n])
        mt, mr = lab[both].mean(0), ref_lab[both].mean(0)
        lab[..., 0] += mr[0] - mt[0]
        ratio = np.hypot(mr[1], mr[2]) / max(np.hypot(mt[1], mt[2]), 1e-3)
        c = lab[..., 1:] * ratio
        ang = np.arctan2(mr[2], mr[1]) - np.arctan2(mt[2], mt[1])           # and the hue
        lab[..., 1] = c[..., 0] * np.cos(ang) - c[..., 1] * np.sin(ang)
        lab[..., 2] = c[..., 0] * np.sin(ang) + c[..., 1] * np.cos(ang)
        rgbs[n] = lab_srgb(lab)
    return masks, rgbs, dict(masks)


def plot_masks(plot: dict) -> tuple[dict, dict, dict]:
    """({level: bool mask of the mill in the take}, {level: the take's rgb}, {level: the mask's pixels whose colour is the
    mill's own: no wing roof}): where the take differs from level 1's (the empty
    plot) and is not lawn, the biggest piece; notches the bush in front of the tower leaves are closed; levels 4 and 5 lose
    the bakery wing (right of the tower's wall, its roof where it meets the sail's tip) and the paved yard."""
    if plot.get("kind") == "water":
        return water_masks(plot)
    if plot.get("kind") == "regrade":
        return regrade_masks(plot)
    ref = _take_rgb(plot["ref"])
    ref_lab = _lab_soft(ref)
    rgbs = {n: _take_rgb(t) for n, t in plot["takes"].items()}
    base = {}
    for n, rgb in rgbs.items():
        d = np.abs(_lab_soft(rgb) - ref_lab).max(-1)
        m = ((d > plot["diff"]) & ~_lawn(rgb)).astype(np.uint8)
        m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8)) > 0
        base[n] = _biggest(_fill_not_sky(m, rgb))
    lowest = min(base)
    tower = ndimage.binary_fill_holes(cv2.morphologyEx(base[lowest].astype(np.uint8), cv2.MORPH_CLOSE, _ellipse(31)) > 0)
    h, w = tower.shape
    yy, xx = np.mgrid[0:h, 0:w]
    keep = cv2.dilate(tower.astype(np.uint8), _ellipse(9)) > 0                     # the tower's own footprint
    sacks = base[lowest + 1] & ~(cv2.dilate(base[lowest].astype(np.uint8), np.ones((9, 9), np.uint8)) > 0)
    sacks[:880] = 0
    sacks[:, :700] = 0
    keep |= cv2.dilate(sacks.astype(np.uint8), _ellipse(9)) > 0
    wing, out, trust = plot["wing"], {}, {}
    for n, rgb in rgbs.items():
        m = base[n].copy()
        roof = np.zeros(m.shape, bool)
        if n >= 4:
            # the wing's terracotta roof (a* over 20) right of the tower's cap; the tower stands in front of it, so the
            # tower's wall below the sail is its own silhouette (level 2's) and its colour comes from the wall
            roof = cv2.dilate(((_lab_soft(rgb)[..., 1] > 20) & (xx >= wing["x"] - 4) & (yy >= wing["roof_y"]) & (yy < 780)).astype(np.uint8), _ellipse(7)) > 0
            m &= ~((xx >= wing["x"]) & (yy >= wing["roof_y"]) & (xx <= wing["roof_x"]) & roof)
            m &= ~((xx > wing["roof_x"]) & (yy >= wing["roof_y"]))
            m &= ~((yy >= wing["y"]) & ~keep)
            m |= tower & (yy >= wing["y"]) & (xx >= wing["x"] - 40)
            m = _biggest(m)
        m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_CLOSE, _ellipse(25)) > 0
        m = _fill_not_sky(m, rgb)
        if n >= 4:
            m &= ~((yy >= wing["y"]) & ~keep)
            m &= ~((xx > wing["roof_x"]) & (yy >= wing["roof_y"]))
        bx0, by0, bx1, by1 = plot["bush"]                                               # the hill's bush behind level 5's lantern
        green = (rgb[..., 1] > rgb[..., 0] - 0.05) & (rgb[..., 1] > rgb[..., 2] + 0.08)
        m &= ~((xx >= bx0) & (xx < bx1) & (yy >= by0) & (yy < by1) & green)
        m &= sky_alpha(rgb) >= 0.5                                                     # the glow of a lantern is sky-pale
        m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(9)) > 0       # tendrils of the bush
        out[n] = _biggest(m)
        trust[n] = out[n] & ~roof
    return out, rgbs, trust


def plot_looks(plot: dict) -> dict:
    """{level: straight RGBA floats at the take's size}: the mask eroded a pixel and softened for the alpha, the colour of
    every pixel outside the mill's inside (3 px in) taken from its nearest inside pixel, so no sky or lawn tints the edge,
    then the level's grade."""
    masks, rgbs, trust = plot_masks(plot)
    out = {}
    for n, m in masks.items():
        inside = cv2.erode(trust[n].astype(np.uint8), _ellipse(7)) > 0
        _, (iy, ix) = ndimage.distance_transform_edt(~inside, return_indices=True)
        rgb = np.where(inside[..., None], rgbs[n], rgbs[n][iy, ix])        # a roof pixel inside takes the wall's colour
        alpha = cv2.GaussianBlur(cv2.erode(m.astype(np.uint8), _ellipse(3)).astype(np.float32), (0, 0), 0.9)
        chroma, light = plot["grade"][n]
        lab = srgb_lab(rgb)
        lab[..., 0] = np.clip(lab[..., 0] * light, 0, 100)
        lab[..., 1:] *= chroma
        out[n] = np.dstack([lab_srgb(lab), alpha])
    return out


def source_looks(spec: dict) -> tuple[dict, tuple[float, float]]:
    """({level: straight RGBA floats at the source's size}, the foot anchor in the resized px): a station's cut-outs
    (the tea stall's: the bottom centre of look 1's alpha box) or the plot looks cut from the plot takes (`anchor`)."""
    scale = spec["scale"] * spec.get("density", DENSITY) / TEX
    if "plot" in spec:
        raw = plot_looks(spec["plot"])
        return raw, (spec["anchor"][0] * scale, spec["anchor"][1] * scale)
    raw = {n: load_look(take_path(job)) for n, job in enumerate(spec["jobs"], start=1)}
    ys, xs = np.nonzero(resize_rgba(raw[1], scale)[..., 3] > 0.5)
    return raw, ((xs.min() + xs.max() + 1) / 2, ys.max() + 1)


def build_looks(spec: dict = TEA_STALL) -> dict:
    """{level: RGBA floats, all one size}, plus the box of the common crop in plate points and the foot anchor in it."""
    density = spec.get("density", DENSITY)
    scale = spec["scale"] * density / TEX
    raw, anchor = source_looks(spec)
    full = {}
    for n, src in raw.items():
        look = resize_rgba(src, scale)
        sh = contact_shade(look[..., 3], density)
        shade = np.dstack([np.broadcast_to(SHADE_RGB, look.shape[:2] + (3,)), sh[..., None]])
        full[n] = over(shade, look)
    boxes = [np.nonzero(x[..., 3] > 0.02) for x in full.values()]
    x0 = min(int(b[1].min()) for b in boxes) - 2
    y0 = min(int(b[0].min()) for b in boxes) - 2
    x1 = max(int(b[1].max()) for b in boxes) + 3
    y1 = max(int(b[0].max()) for b in boxes) + 3
    x0, y0 = x0 // 4 * 4, y0 // 4 * 4                              # ASTC blocks
    x1, y1 = -(-x1 // 4) * 4, -(-y1 // 4) * 4
    cropped = {n: x[y0:y1, x0:x1] for n, x in full.items()}
    fx, fy = spec["foot"]
    box = [fx + (x0 - anchor[0]) / density, fy + (y0 - anchor[1]) / density, fx + (x1 - anchor[0]) / density, fy + (y1 - anchor[1]) / density]
    if spec.get("flowerMatte"):
        keep = 1 - flower_matte(spec, box)
        for x in cropped.values():
            x[..., 3] *= keep[: x.shape[0], : x.shape[1]]
    return {"looks": cropped, "box": [round(float(v), 2) for v in box], "foot": [fx, fy]}


def flower_matte(spec: dict, box: list[float]) -> np.ndarray:
    """1 where the plate's own flowers, leaves and mailbox stand in front of a look (0 to 1, the look's pixels): the stage 0 base
    (the pond erased, lawn and flowers left) differs from its lawn colour there. A look drawn over it must leave them showing, so
    its alpha is multiplied by 1 - this. `flowerMatte`: {"lawn": a plate-points box of bare lawn, "from": the first plate-points
    row the matte reaches up to, "dE": the distance from the lawn colour that is a flower}."""
    fm = spec["flowerMatte"]
    assert spec.get("density", DENSITY) == TEX, "the matte is cut on the plate's texture grid"
    hand = ingest.load_hand(ISLAND)
    stage = min(spec["bases"])
    crop = ingest.plate_crop_points(ISLAND, hand, "day", stage)
    name = base_name("day", stage)
    with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
        base = np.asarray(im.convert("RGB"), np.float32) / 255

    def tex(x0: float, y0: float, x1: float, y1: float) -> tuple[slice, slice]:
        return slice(round((y0 - crop[1]) * TEX), round((y1 - crop[1]) * TEX)), slice(round((x0 - crop[0]) * TEX), round((x1 - crop[0]) * TEX))

    mu = np.median(srgb_lab(base[tex(*fm["lawn"])]).reshape(-1, 3), 0)
    ys, xs = tex(box[0], fm["from"], box[2], box[3])
    d = np.sqrt(((srgb_lab(base[ys, xs]) - mu) ** 2).sum(-1))
    m = (d > fm.get("dE", 20)).astype(np.uint8)
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, _ellipse(7))
    m = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 0.8)
    out = np.zeros((round((box[3] - box[1]) * TEX), round((box[2] - box[0]) * TEX)), np.float32)
    top = round((fm["from"] - box[1]) * TEX)
    out[top:top + m.shape[0], : m.shape[1]] = m[: out.shape[0] - top, : out.shape[1]]
    return out


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


def paste_masks(parent: np.ndarray, take: np.ndarray, window: tuple[int, int, int, int], shapes: list | None = None) -> np.ndarray:
    """The old station: where the take differs from its parent inside the window, closed, holes filled, the biggest piece,
    grown 8 px (a hard 0/1 mask at texture size). `shapes` (ellipses `("e", cx, cy, rx, ry)` and boxes `("r", x0, y0, x1, y1)`,
    texture px) narrow the window to their union: a station whose window is a ring on a lawn that the take regrades all over."""
    x0, y0, x1, y1 = window
    d = np.abs(take - parent).max(-1)
    raw = np.zeros(parent.shape[:2], np.uint8)
    raw[y0:y1, x0:x1] = d[y0:y1, x0:x1] > 0.12
    if shapes:
        yy, xx = np.mgrid[0:raw.shape[0], 0:raw.shape[1]]
        inside = np.zeros(raw.shape, bool)
        for kind, a, b, c, e in shapes:
            inside |= ((xx - a) / c) ** 2 + ((yy - b) / e) ** 2 <= 1 if kind == "e" else (xx >= a) & (xx < c) & (yy >= b) & (yy < e)
        raw &= inside.astype(np.uint8)
    raw = cv2.morphologyEx(raw, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
    n, lab, stat, _ = cv2.connectedComponentsWithStats(raw, connectivity=8)
    if n < 2:
        raise SystemExit("the erase take does not differ from its parent in the window")
    keep = 1 + int(np.argmax(stat[1:, cv2.CC_STAT_AREA]))
    raw = ndimage.binary_fill_holes(lab == keep).astype(np.uint8)
    return cv2.dilate(raw, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (17, 17)))


def match_to_parent(take_rgb: np.ndarray, parent_rgb: np.ndarray, parent_alpha: np.ndarray, hard: np.ndarray, lighter: bool = True, bright: bool = False) -> np.ndarray:
    """The take's colours moved so that the mean Lab colour of a ring of lawn round the region is the parent's. `bright`: the
    ring is the sunlit green lawn only (no flower, leaf, stone or shade), so the match does not pull the lawn olive."""
    near = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (81, 81))) > 0
    close = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21))) > 0
    ring = near & ~close & (parent_alpha > 0.95) & (parent_rgb[..., 1] > parent_rgb[..., 2] + 0.05)
    if ring.sum() < 200:
        return take_rgb
    lab_ring = srgb_lab(parent_rgb)[..., 0]
    if bright:
        lab_p = srgb_lab(parent_rgb)
        ring &= (lab_p[..., 2] > 45) & (lab_p[..., 1] < -8)
        if ring.sum() < 200:
            return take_rgb
    if lighter:
        ring &= lab_ring >= np.median(lab_ring[ring])       # lighter half: the lawn in light, not in a building's shade
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


def drop_specks(alpha: np.ndarray, window: tuple, crop_tex: tuple, margin: int = 48) -> np.ndarray:
    """The erase leaves wisps of its own mist floating over the sky where the old station's sails were: inside the window
    (and `margin` px round it) every piece of alpha that is not the island's body, and the fringe farther than 5 px from the
    body, goes. Only for a station whose bases ask for it (`clean`)."""
    core = (alpha > 0.3).astype(np.uint8)
    n, lab, stat, _ = cv2.connectedComponentsWithStats(core, connectivity=8)
    body = lab == 1 + int(np.argmax(stat[1:, cv2.CC_STAT_AREA]))
    keep = cv2.dilate(body.astype(np.uint8), _ellipse(11)) > 0
    x0, y0, x1, y1 = window
    cx, cy = crop_tex
    region = np.zeros(alpha.shape, bool)
    region[max(y0 - cy - margin, 0):y1 - cy + margin, max(x0 - cx - margin, 0):x1 - cx + margin] = True
    return np.where(region & ~keep, 0.0, alpha)


def old_pond_pixels(rgb: np.ndarray) -> np.ndarray:
    """Where an occluder's pixels are the old pond's: the ring stones (pale, and their shaded brown) and its water."""
    lab = srgb_lab(rgb)
    stone = (lab[..., 2] > 8) & (lab[..., 1] > 0) & (np.hypot(lab[..., 1], lab[..., 2]) < 32) & (lab[..., 0] > 62)
    stone |= (lab[..., 1] > 3) & (lab[..., 2] > 3) & (np.hypot(lab[..., 1], lab[..., 2]) < 22) & (lab[..., 0] > 40) & (lab[..., 0] < 78)   # the ring stones' shaded brown
    water = cv2.dilate(((lab[..., 2] < -3) & (lab[..., 1] < 4) & (lab[..., 0] < 72)).astype(np.uint8), np.ones((3, 3), np.uint8)) > 0   # (lilac has a* over 4 or is lighter than L* 72)
    return stone | water


def build_base(stage: int, spec: dict, plate: np.ndarray | None = None) -> tuple[np.ndarray, dict]:
    """The shipped plate of a day stage with the station erased: RGBA floats, the plate's crop. `plate` is a base that
    already has other stations erased (the same size): this station's window is taken out of it, so two stations that
    stand on one stage accumulate in one base."""
    light = "day"
    hand = ingest.load_hand(ISLAND)
    crop = ingest.plate_crop_points(ISLAND, hand, light, stage)
    cx, cy = crop[0] * TEX, crop[1] * TEX
    name = ingest.asset_name(ISLAND, "plate", light, stage)
    if plate is None:
        with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
            plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    h, w = plate.shape[:2]
    parent = ingest.source_plate(ingest.REPO / hand["plates"][light][str(stage)])[0].astype(np.float32)
    job = ingest.REPO / "design" / "art" / "takes" / spec["job"]
    take = np.asarray(Image.open(take_path(spec["job"])).convert("RGB").resize((parent.shape[1], parent.shape[0]), Image.LANCZOS), np.float32) / 255
    hard_full = paste_masks(parent, take, spec["window"], spec.get("shapes"))
    for ex0, ey0, ex1, ey1 in spec.get("exclude", []):
        hard_full[ey0:ey1, ex0:ex1] = 0
    for oid in spec.get("excludeOccluders", ()):         # an occluder's opaque pixels stay the plate's (the mailbox)
        x0, y0, x1, y1, alpha = occluder_pixels(stage, oid)
        solid = alpha > (0.02 if spec.get("excludeGrow") else 0.4)
        if oid in spec.get("flowersOnly", ()):           # the plate's flowers stay; the old pond's stones and water under the polygon still go
            name = ingest.asset_name(ISLAND, "occ", "day", stage, oid)
            with open_source_asset(name) as im:
                solid &= ~old_pond_pixels(np.asarray(im.convert("RGB"), np.float32)[: solid.shape[0], : solid.shape[1]] / 255)
        hard_full[y0:y1, x0:x1][cv2.dilate(solid.astype(np.uint8), _ellipse(7 + spec.get("excludeGrow", 0))) > 0] = 0
    sl = (slice(cy, cy + h), slice(cx, cx + w))
    hard = hard_full[sl]
    p_rgb, p_a = plate[..., :3], plate[..., 3]
    t_rgb = take[sl]
    # the take's grass line is mixed with its sky: colours come from the nearest sure-island pixel
    t_a = sky_alpha(t_rgb)
    sure = t_a > 0.97
    _, (iy, ix) = ndimage.distance_transform_edt(~sure, return_indices=True)
    t_rgb = np.where((t_a < 0.97)[..., None], t_rgb[iy, ix], t_rgb)
    t_rgb = match_to_parent(t_rgb, parent[sl], p_a, hard, spec.get("lighter", True), spec.get("brightRing", False))
    m_alpha = cv2.GaussianBlur(cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9))).astype(np.float32), (0, 0), 3.0)
    m_rgb = cv2.GaussianBlur(cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25))).astype(np.float32), (0, 0), FEATHER_TEX / 3)
    # the plate's alpha only shrinks in the region (the old counter hung over the sky); never grows
    # and only where the old stall (not lawn) stood: the take's hill line is not the parent's, so the parent's own grass
    # keeps its alpha, and the grass colour there is the take's nearest lawn
    pr = parent[sl]
    grass = ((pr[..., 1] > pr[..., 0] + 0.03) & (pr[..., 1] > pr[..., 2] + 0.10)).astype(np.float32)
    grass = cv2.GaussianBlur(cv2.erode(grass, np.ones((3, 3), np.uint8)), (0, 0), 1.5)
    m_shrink = m_alpha * (1 - grass)
    if spec.get("shrinkAbove"):                           # below the hill line the take's blue flowers are not sky: the alpha stays
        m_shrink[max(spec["shrinkAbove"] - cy, 0):] = 0
    new_a = p_a * (1 - m_shrink) + np.minimum(p_a, t_a) * m_shrink
    for bx0, by0, bx1, by1 in spec.get("clearAlpha", ()):    # sky the erase take paints blossoms into (the old flag's)
        new_a[by0 - cy:by1 - cy, bx0 - cx:bx1 - cx] = 0
    if spec.get("interior"):                           # inside the island: the take's flowers are not sky, the alpha stays
        new_a = p_a
    new_rgb = p_rgb * (1 - m_rgb[..., None]) + t_rgb * m_rgb[..., None]
    if spec.get("ceiling", True) and not spec.get("interior"):   # a window inside the island (the pond) has no top edge of its own
        new_a = hill_ceiling(new_a, p_a, t_a, spec["window"], (cx, cy))
    if spec.get("clean"):
        new_a = drop_specks(new_a, spec["window"], (cx, cy))
    rgb = ingest.extended(np.where(new_a[..., None] > 0, new_rgb, p_rgb), new_a)
    out = np.dstack([rgb, new_a])
    info = {"crop": crop, "changed": float(m_rgb.max()), "hard_full": hard_full}
    return out, info


SIZE_TEX = (2048, 3072)

SOURCE_REF = os.environ.get("STATION_LOOKS_FROM", "origin/main")


def open_source_asset(name: str, ref: str | None = None, repo: Path | None = None, assets: Path | None = None):
    """The asset `name` as it is on `ref` (default `origin/main`, or $STATION_LOOKS_FROM), not as the working tree has it. The
    tool rewrites the island cut, the Map cut and the occluders in place; a run that read its own earlier output would clear
    twice and draw its base from occluders it had already cut, so every run would drift (three runs gave three different
    bases). Reading the layers it modifies from the ref makes `bases` a function of the ref and the takes: run it as often
    as you like. Falls back to the working tree for an asset the ref does not have (a new one). Returns an open image."""
    import tempfile
    data = source_bytes(name, ref, repo, assets)
    if data is None:
        return heic.open_image((assets or ASSETS) / f"{name}.imageset" / f"{name}{heic.SUFFIX}")
    tmp = tempfile.NamedTemporaryFile(suffix=heic.SUFFIX, delete=False)
    tmp.write(data)
    tmp.close()
    im = heic.open_image(Path(tmp.name))
    im.load()
    os.unlink(tmp.name)
    return im


def source_bytes(name: str, ref: str | None = None, repo: Path | None = None, assets: Path | None = None) -> bytes | None:
    """The HEIC bytes of asset `name` on the ref, None where the ref does not have it."""
    import subprocess
    repo = repo or ingest.REPO
    path = (assets or ASSETS) / f"{name}.imageset" / f"{name}{heic.SUFFIX}"
    got = subprocess.run(["git", "-C", str(repo), "show", f"{ref or SOURCE_REF}:{path.relative_to(repo).as_posix()}"], capture_output=True)
    return got.stdout if got.returncode == 0 else None


def keep_source(name: str) -> None:
    """A layer this run leaves alone goes back to the ref's bytes (an earlier run may have rewritten it)."""
    data = source_bytes(name)
    if data is not None:
        (ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}").write_bytes(data)



def occluder_pixels(stage: int, oid: str) -> tuple[int, int, int, int, np.ndarray]:
    """An occluder's box in the plate's texture px and its alpha."""
    hand = ingest.load_hand(ISLAND)
    _, k = ingest.source_plate(ingest.REPO / hand["plates"]["day"][str(stage)])
    a1 = ingest.load_matte(ISLAND, "day", stage)
    obj = next(o for o in hand["objects"] if o["id"] == oid)
    _, box = ingest.occluder_cut(np.zeros(a1.shape + (3,)), a1, ingest.pct_to_px(obj["points"]))
    x0, y0, x1, y1 = (v * k for v in box)
    name = ingest.asset_name(ISLAND, "occ", "day", stage, oid)
    with open_source_asset(name) as im:
        alpha = np.asarray(im.convert("RGBA"), np.float32)[..., 3] / 255
    return x0, y0, x0 + alpha.shape[1], y0 + alpha.shape[0], alpha


ALPHA_STABLE = 3                  # an occluder whose alpha moves by no more than this many 8-bit levels, in no more than
ALPHA_NOISE = 0.003               # this share of its pixels (a decoded HEIC flips a few stone tests), is left as it is


def clear_alpha(alpha: np.ndarray, part: np.ndarray) -> np.ndarray:
    """An occluder's alpha with `part` (0 to 1) taken out of it: the smaller of what it is and what `part` leaves, so
    clearing the same region twice (or on top of an earlier run's result) changes nothing the second time."""
    return np.minimum(alpha, 1 - part).astype(np.float32)


def clear_occluders(stage: int, hard_full: np.ndarray, station: str = TEA_STALL["id"], keep: tuple = (), skip: tuple = ()) -> None:
    """Another object's occluder cut-out that reaches into the erased stall (the workshop's polygon runs on to the stall's
    left pole) would draw the old stall again over the base: its alpha is cleared inside the erased region."""
    hand = ingest.load_hand(ISLAND)
    rgb, k = ingest.source_plate(ingest.REPO / hand["plates"]["day"][str(stage)])
    a1 = ingest.load_matte(ISLAND, "day", stage)
    region = cv2.GaussianBlur(cv2.dilate(hard_full, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13))).astype(np.float32), (0, 0), 2.0)
    for obj in hand["objects"]:
        if not obj.get("occluder") or not ingest.present(obj, "day", stage) or obj["id"] == station or obj["id"] in skip:
            continue
        _, box = ingest.occluder_cut(np.zeros(a1.shape + (3,)), a1, ingest.pct_to_px(obj["points"]))
        x0, y0, x1, y1 = (v * k for v in box)
        part = region[y0:y1, x0:x1]
        if obj["id"] in keep:                 # scenery that stands in front (flowers): only the old stall's pale stones and water go
            inner = cv2.GaussianBlur(cv2.erode(hard_full, _ellipse(29)).astype(np.float32), (0, 0), 2.0)[y0:y1, x0:x1]
            part = inner
        if part.max() <= 0.01:
            continue
        name = ingest.asset_name(ISLAND, "occ", "day", stage, obj["id"])
        with open_source_asset(name) as im:
            old = np.asarray(im.convert("RGBA"), np.float32) / 255
        part = part[: old.shape[0], : old.shape[1]]
        if obj["id"] in keep:
            lab = srgb_lab(old[..., :3])
            stone = old_pond_pixels(old[..., :3])
            water = stone
            wide = cv2.GaussianBlur(cv2.dilate(hard_full, _ellipse(61)).astype(np.float32), (0, 0), 2.0)[y0:y1, x0:x1][: old.shape[0], : old.shape[1]]
            part = np.maximum(part * stone, wide * water).astype(np.float32)   # water also beside the mailbox, whose own pixels the region skips
        new = old.copy()
        new[..., 3] = clear_alpha(old[..., 3], part)
        if (np.abs(new[..., 3] - old[..., 3]) * 255 > ALPHA_STABLE).mean() <= ALPHA_NOISE:     # already cleared: no second lossy encode
            keep_source(name)
            print(f"  occluder {obj['id']} {stage}: already clear")
            continue
        ingest.write_imageset(name, to_img(new))
        print(f"  occluder {obj['id']} {stage}: cleared {int((part > 0.5).sum())} px of the erased stall")


def stage_specs(stage: int, specs: list[dict] | None = None) -> list[dict]:
    """The stations whose plate has this day stage erased, in `STATIONS` order."""
    return [sp for sp in (specs or STATIONS) if stage in sp["bases"]]


def accumulate_base(stage: int, specs: list[dict] | None = None) -> tuple[np.ndarray, dict, np.ndarray]:
    """The base of a stage with every station that has one there erased: each station's window is taken out of what the
    stations before it left. Returns the base, the plate crop (`info`, with each station's erased region in
    `info["regions"]`) and the union of the erased regions (texture px)."""
    x, info, union, regions = None, None, None, []
    for spec in stage_specs(stage, specs):
        x, info = build_base(stage, spec["bases"][stage], x)
        hf = info["hard_full"]
        union = hf if union is None else np.maximum(union, hf)
        regions.append((spec["id"], hf))
    if x is None:
        raise SystemExit(f"no station has a base at stage {stage}")
    info["regions"] = regions
    return x, info, union


def same_picture(old: np.ndarray, new: np.ndarray) -> bool:
    """Whether `new` is `old` up to a HEIC encode: same size, premultiplied, the mean difference under 1.6 of 256 levels and
    at most 0.1 percent of the pixels off by more than 12."""
    if old.shape != new.shape:
        return False
    po, pn = old[..., :3] * old[..., 3:] / 255, new[..., :3] * new[..., 3:] / 255
    d = np.maximum(np.abs(po - pn).max(-1), np.abs(old[..., 3] - new[..., 3]))
    return bool(d.mean() < 1.6 and (d > 12).mean() <= 0.001)


def write_or_keep(name: str, img: Image.Image) -> bool:
    """Write the layer unless the ref's already is this picture (up to an encode): then the ref's bytes stay, so a run that
    changes nothing for a stage leaves its files alone (no noise in the diff, no new frame to check). Returns whether it wrote."""
    data = source_bytes(name)
    if data is not None:
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:                     # the new picture as it would ship: same encode as the ref's
            heic.save(img, Path(tmp) / f"x{heic.SUFFIX}")
            with heic.open_image(Path(tmp) / f"x{heic.SUFFIX}") as shipped, open_source_asset(name) as old:
                if same_picture(np.asarray(old.convert("RGBA"), np.float32), np.asarray(shipped.convert("RGBA"), np.float32)):
                    keep_source(name)
                    return False
    ingest.write_imageset(name, img)
    return True


def cmd_bases(station: dict | None = None) -> dict:
    """Every base of the stages `station` stands on (all stations when None), each with all the stations that share it."""
    chosen = [station] if station else STATIONS
    stages = sorted({s for sp in chosen for s in sp["bases"]})
    out = {}
    for stage in stages:
        x, info, _ = accumulate_base(stage)
        write_or_keep(base_name("day", stage), to_img(x))
        # The Map's island cut (and the graded island layer) is the same picture: it must not paint the stall either.
        crop = info["crop"]
        full = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
        full[crop[1] * TEX:crop[1] * TEX + x.shape[0], crop[0] * TEX:crop[0] * TEX + x.shape[1]] = x
        # `ingest.cmd_deliver` cuts it at the stage matte's box (`ingest.bbox`), `map_cut.py` clears the level-10 ghost.
        ix0, iy0, ix1, iy1 = ingest.bbox(ingest.load_matte(ISLAND, "day", stage), 0.02)
        for kind in ("island", "mapisle"):
            name = ingest.asset_name(ISLAND, kind, "day", stage)
            with open_source_asset(name) as im:
                old = np.asarray(im.convert("RGBA"), np.float32) / 255
            cut = resize_rgba(full[iy0 * TEX:iy1 * TEX, ix0 * TEX:ix1 * TEX], 1.0)
            cut = cv2.resize(np.dstack([cut[..., :3] * cut[..., 3:], cut[..., 3:]]), (old.shape[1], old.shape[0]), interpolation=cv2.INTER_AREA)
            a = cut[..., 3:]
            rgb = np.where(a > 1e-4, cut[..., :3] / np.maximum(a, 1e-4), old[..., :3])
            alpha = np.minimum(old[..., 3:], a) if kind == "mapisle" else a
            write_or_keep(name, to_img(np.dstack([rgb, alpha])))
        for station_id, region in info["regions"]:                  # each station's own erased region, its own occluder kept
            sp = next(sp for sp in STATIONS if sp["id"] == station_id)
            keep = sp.get("keepOccluders", ())
            skip = tuple(o for o in sp["bases"][stage].get("excludeOccluders", ()) if o not in keep)    # an occluder whose pixels the base keeps
            clear_occluders(stage, region, station_id, keep, skip)
        out[stage] = x.shape[:2]
        print(f"base day {stage}: {x.shape[1]} x {x.shape[0]} px ({', '.join(sp['id'] for sp in stage_specs(stage))})")
    return out


# ---------------------------------------------------------------- data

def asset_pixels(name: str) -> int:
    with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
        return im.width * im.height


def stations_data(spec: dict = TEA_STALL) -> dict:
    """The `stations` block of plate-home.json (read by ingest.build_json)."""
    built = build_looks(spec)
    levels = sorted(built["looks"])
    data = {
        "light": spec["light"],
        "levels": spec["levels"],
        "box": built["box"],
        "foot": built["foot"],
        "density": spec.get("density", DENSITY),
        "baseStages": sorted(spec["bases"]),
        "stages": {str(st): stage_place(st, built["box"], spec) for st in sorted(spec["bases"])},
        "lookBytes": [asset_pixels(look_name(spec["id"], n, spec["light"])) for n in levels],
        "baseBytes": {str(s): asset_pixels(base_name(spec["light"], s)) for s in sorted(spec["bases"])},
    }
    if levels != list(range(1, spec["levels"] + 1)):          # a level whose look is missing draws the nearest lower one
        data["lookLevels"] = {spec["light"]: levels}
    return {spec["id"]: data}


def stage_place(stage: int, ref_box: list[float], spec: dict = TEA_STALL) -> dict:
    """One stage's transform: the look canvas's box scaled about the foot, and the foot (plate points)."""
    fx, fy = spec["place"][stage]["foot"]
    k = spec["place"][stage]["scale"]
    rx, ry = spec["foot"]
    box = [fx + (ref_box[0] - rx) * k, fy + (ref_box[1] - ry) * k, fx + (ref_box[2] - rx) * k, fy + (ref_box[3] - ry) * k]
    return {"foot": [fx, fy], "scale": k, "box": [round(v, 2) for v in box]}


def cmd_json() -> None:
    stations = {}
    for spec in STATIONS:
        stations.update(stations_data(spec))
    STATIONS_JSON.write_text(json.dumps({"stations": stations}, indent=1) + "\n")
    print(f"json: {STATIONS_JSON.relative_to(ingest.REPO)}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["looks", "bases", "json", "all"])
    ap.add_argument("--station", choices=[sp["id"] for sp in STATIONS], help="one station (default: every station)")
    args = ap.parse_args(argv)
    heic.require()
    chosen = [sp for sp in STATIONS if args.station in (None, sp["id"])]
    for spec in chosen:
        if args.command in ("looks", "all"):
            cmd_looks(spec)
    if args.command in ("bases", "all"):
        cmd_bases(chosen[0] if args.station else None)
    if args.command in ("json", "all"):
        cmd_json()
    return 0


if __name__ == "__main__":
    sys.exit(main())
