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

# Day stage s is island level 10 - s; its erase job is `x-base-erase-l<level>-day`.
JOB = "batch-117-station-erase-volume/x-base-erase-l{:02d}-day"


# The path lanterns the night erase takes also take away (their heads and glow go, a post stub stays; the lead's reviews of batch 117
# say to paste them back from the parent): texture px boxes, full plate, taken out of the paste mask of every night base.
NIGHT_KEEP = [(575, 1460, 655, 1650), (870, 1470, 960, 1650)]


#: The stages the night bases stand on: the levels batch 117 erased by night with a pick (level 10 - stage); level 5 (stage 5) has no station
#: and levels 1 and 2 (stages 9 and 8) none of the stations' bases.
NIGHT_STAGES = (0, 1, 2, 3, 4, 6, 7)


def job_for(job: str, light: str = "day") -> str:
    """A day erase job's job in `light`: batch 117 erased every level in the day and the night plate (`-day` -> `-night`)."""
    return job.replace("-day", f"-{light}") if light in ("day", "night") else job

# The tea stall (batch 196, day levels 1 to 5, the lead's picks: t1 of every level). A plot ladder like the workshop's: crops of batch
# 117's erased level 10 base (plate pts 545,586 to 865,906, enlarged to the takes' 1536 px, so a take px is 320 / 1536 = 0.2083 points),
# each level painted aligned to it, so a look is where a take differs from the bare crop and is not lawn. The stall's table, lamp post and
# stools stand apart from it (`pieces`), and the hill's lawn seen between its posts is not the stall (`lawnOut`). Batch 123's cut-outs,
# which this replaces, were drawn for the plate's own stall of level 3 (stage 7): `scale` puts level 1's awning at the width of that old
# look's (0.93 of the new take's 128 points against 119) and `foot` (the bottom centre of level 1's cut) on its foot, so the counter
# stays put from level to level and from the old look to the new.
PLOT_TEA = "batch-196-plot-ladder-tea-stall/x-plot-tea-stall-{}"
TEA_STALL = {
    "id": "teaStall",
    "light": "day",
    "levels": 5,
    "plot": {
        "kind": "regrade",
        "size": 1536,
        "bare": (JOB.format(10), (545, 586, 865, 906)),
        "takes": {n: (PLOT_TEA.format(n), 1) for n in range(1, 6)},
        "diff": 16,
        "notLawn": True,
        "raw": True,
        "close": 61,
        "pieces": 3000,
        "lawnOut": 3,
        "clear": {n: [(1105, 1095, 1260, 1150)] for n in range(2, 6)},   # the take's grey-lilac cast shadow right of the lamp post: at the lawn's rim it hangs in the gap
        "grade": {n: (0.78, 0.99) for n in range(1, 6)},   # to the painted stall's L* 79, C* 29 (the takes: L* 74 to 81, C* 39 to 41)
    },
    "scale": 0.3875,             # 0.2083 points per take px x 0.93
    "density": 2.0,
    "anchor": (732.5, 1188.0),   # level 1's bottom centre in its take
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
BASES = {
    7: {"job": JOB.format(3), "window": (1246, 1330, 1512, 1664)},
    6: {"job": JOB.format(4), "window": (1232, 1370, 1530, 1672)},
    4: {"job": JOB.format(6), "window": (1252, 1290, 1536, 1692),
        "exclude": [(1420, 1650, 1700, 1800)], "brightRing": True},
    3: {"job": JOB.format(7), "window": (1226, 1290, 1536, 1692),      # from x 1226 above y 1500, where the workshop's window stops: a 26 px strip of its wall between the two windows stayed as a grey line up the sky; below, the plate's own lamp (x 1190, y 1580 to 1690) stays whole
        "shapes": [("r", 1226, 1290, 1536, 1500), ("r", 1252, 1500, 1536, 1692)],
        "exclude": [(1420, 1650, 1700, 1800)], "brightRing": True},     # brightRing: the lawn pasted in is the sunlit green, not the lighter half of the ring (it stepped yellow against the lawn below the path)
}

# Where each stage paints its stall (plate points) and its size against stage 7's: the foot is the bottom centre of the
# counter, the scale the counter's width over stage 7's. The look stands there at that size.
PLACE = {
    7: {"foot": (690.0, 832.0), "scale": 1.0},
    6: {"foot": (690.0, 838.0), "scale": 0.95},
    # Stages 4 and 3: the plate's own lamp stands at x 606 (head 593 to 620, foot y 845) left of the old stall, and the rim runs in
    # close right of it. The level 2 table stands 105 points left of the foot and the lamp post 65 right, so the stall is smaller
    # (0.81) and 13 points right: the table clears the lamp, the post's foot stands on lawn (the base is erased, so the old stall's
    # place binds nothing).
    4: {"foot": (711.0, 839.0), "scale": 0.81},
    3: {"foot": (711.0, 839.0), "scale": 0.81},
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
for _sp in STATIONS:
    _sp["night"] = True
    _sp["golden"] = any(_st in (0, 3, 4, 6, 7) for _st in _sp["bases"])      # `GOLDEN_STAGES`: the bagel cart and the lighthouse stand only on stages 1 and 2, where golden hour draws the night plate


# ---------------------------------------------------------------- looks

def pick_of(job: str) -> int:
    text = (TAKES / job / "review.yaml").read_text()
    m = re.search(r"^\s*pick:\s*(\d+)", text, re.M)       # top level (batches 117 to 191) or under `selection:` (batch 194)
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
    ref = np.asarray(Image.open(path).convert("RGB").crop((x0, y0, x1, y1)).resize((plot.get("size", 1254),) * 2, Image.LANCZOS), np.float32) / 255
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
    ref = np.asarray(Image.open(path).convert("RGB").crop((x0, y0, x1, y1)).resize((plot.get("size", 1254),) * 2, Image.LANCZOS), np.float32) / 255
    ref_lab = _lab_soft(ref)
    masks, rgbs = {}, {}

    def keep(m: np.ndarray) -> np.ndarray:
        """The biggest piece, or (`pieces`: a minimum area in px) every piece that big: a station with a table or a lamp post
        standing apart from it."""
        if not plot.get("pieces"):
            return _biggest(m)
        n_, lab_, stat_, _ = cv2.connectedComponentsWithStats(m.astype(np.uint8), connectivity=8)
        big = [i for i in range(1, n_) if stat_[i, cv2.CC_STAT_AREA] >= plot["pieces"]]
        return np.isin(lab_, big) if big else _biggest(m)

    for n, take in plot["takes"].items():
        rgb = _take_rgb(take)
        lab = _lab_soft(rgb)
        m = regrade_fit(ref_lab, lab)
        d = np.abs(lab - (np.c_[ref_lab.reshape(-1, 3), np.ones(ref_lab.shape[0] * ref_lab.shape[1])] @ m).reshape(lab.shape)).max(-1)
        mask = (d > plot["diff"]).astype(np.uint8)
        if plot.get("notLawn"):
            mask &= (~_lawn(rgb)).astype(np.uint8)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8)) > 0
        mask = keep(ndimage.binary_fill_holes(mask))
        mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, _ellipse(plot["close"].get(n, 41) if isinstance(plot.get("close"), dict) else plot.get("close", 25))) > 0
        mask = keep(ndimage.binary_fill_holes(mask))
        if plot.get("smooth"):                                            # a smooth rim, no bites, no grey fragments between the leaves
            mask = cv2.GaussianBlur(mask.astype(np.float32), (0, 0), plot["smooth"]) > 0.5
            mask = keep(ndimage.binary_fill_holes(cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(13)) > 0))
        if plot.get("sky"):                                               # the take's sky seen through the arch or between the leaves is not the station
            mask = keep(ndimage.binary_fill_holes(cv2.morphologyEx((mask & (sky_alpha(rgb) >= 0.5)).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(7)) > 0))
        if plot.get("notLawn"):                                           # the sky seen between the gear, the chimney and the roof is not the house
            mask = keep(cv2.morphologyEx((mask & (sky_alpha(rgb) >= 0.5)).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(7)) > 0)
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
            mask = keep(cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, _ellipse(11)) > 0)
        if plot.get("lawnOut"):                                           # the hill's lawn seen through the stall (between the posts, over the counter) is not the stall
            lawn = cv2.morphologyEx(_lawn(rgb).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(3)) > 0
            mask = keep(cv2.morphologyEx((mask & ~(cv2.dilate(lawn.astype(np.uint8), _ellipse(plot["lawnOut"])) > 0)).astype(np.uint8), cv2.MORPH_OPEN, _ellipse(5)) > 0)
        for bx0, by0, bx1, by1 in plot.get("clear", {}).get(n, []):       # a string or stub the take hangs across the neighbouring station
            mask[by0:by1, bx0:bx1] = False
        if plot.get("clear", {}).get(n):
            mask = keep(mask)
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
    if plot.get("paint"):
        # A season's look (D2): the spring take's shape, the season take's colours. The takes are aligned edits of the spring
        # takes (the season gate holds the frame), so the spring mask cuts them and nothing is cut by difference.
        rgbs = {n: t if isinstance(t, np.ndarray) else _take_rgb(t) for n, t in plot["paint"].items()}
        rgbs = {n: x if x.shape[:2] == masks[n].shape else cv2.resize(x, masks[n].shape[::-1], interpolation=cv2.INTER_AREA) for n, x in rgbs.items()}     # a relight is 1536 px, its parent plot 1254
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


def night_sky_alpha(rgb: np.ndarray, known_sky: np.ndarray) -> np.ndarray:
    """`sky_alpha` for a night take: 1 on the island, 0 on the sky. The night sky is as blue as the purple flowers and the
    bush's shade, so the sky is the blue that is connected, after an opening that cuts a fringe of flowers loose, to the sky
    the parent shows (`known_sky`, a bool mask)."""
    blue = ((rgb[..., 2] - (rgb[..., 0] + rgb[..., 1]) / 2) > 0.16).astype(np.uint8)       # the sky's 0.32 to 0.35, the lawn's under 0.04, a blue flower's under 0.15
    core = cv2.morphologyEx(blue, cv2.MORPH_OPEN, _ellipse(9))
    n, lab = cv2.connectedComponents(core, connectivity=8)
    seeded = np.unique(lab[known_sky & (core > 0)])
    sky = np.isin(lab, seeded[seeded > 0]).astype(np.uint8)
    sky = (cv2.dilate(sky, _ellipse(11)) > 0) & (blue > 0)
    return 1 - cv2.GaussianBlur(sky.astype(np.float32), (0, 0), 1.2)


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


def match_to_parent(take_rgb: np.ndarray, parent_rgb: np.ndarray, parent_alpha: np.ndarray, hard: np.ndarray, lighter: bool = True, bright: bool = False, night: bool = False) -> np.ndarray:
    """The take's colours moved so that the mean Lab colour of a ring of lawn round the region is the parent's. `bright`: the
    ring is the sunlit green lawn only (no flower, leaf, stone or shade), so the match does not pull the lawn olive."""
    near = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (81, 81))) > 0
    close = cv2.dilate(hard, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21))) > 0
    ring = near & ~close & (parent_alpha > 0.95) & (parent_rgb[..., 1] > parent_rgb[..., 2] + 0.05)
    if night:                                           # the night lawn is a faint blue-green (a* about -4, no sunlit yellow): its green, not the lamp pools
        ring = near & ~close & (parent_alpha > 0.95) & (srgb_lab(parent_rgb)[..., 1] < -2) & (srgb_lab(parent_rgb)[..., 0] < 64)
    if ring.sum() < 200:
        return take_rgb
    lab_ring = srgb_lab(parent_rgb)[..., 0]
    if bright and not night:
        lab_p = srgb_lab(parent_rgb)
        ring &= (lab_p[..., 2] > 45) & (lab_p[..., 1] < -8)
        if ring.sum() < 200:
            return take_rgb
    if lighter and not night:
        ring &= lab_ring >= np.median(lab_ring[ring])       # lighter half: the lawn in light, not in a building's shade
    lp, lt = srgb_lab(parent_rgb), srgb_lab(take_rgb)
    delta = (np.median(lp[ring], 0) - np.median(lt[ring], 0)) if night else lp[ring].mean(0) - lt[ring].mean(0)
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


def build_base(stage: int, spec: dict, plate: np.ndarray | None = None, light: str = "day", erase: Path | None = None) -> tuple[np.ndarray, dict]:
    """The shipped plate of a day stage with the station erased: RGBA floats, the plate's crop. `plate` is a base that
    already has other stations erased (the same size): this station's window is taken out of it, so two stations that
    stand on one stage accumulate in one base. `light` is the state's key (`autumn-day` for a season's: its plate is the
    parent and `erase` the season's own erase take, from which the station's window is taken, as in spring)."""
    hand = ingest.load_hand(ISLAND)
    crop = ingest.plate_crop_points(ISLAND, hand, light, stage)
    cx, cy = crop[0] * TEX, crop[1] * TEX
    name = ingest.asset_name(ISLAND, "plate", light, stage)
    if plate is None:
        with heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}") as im:
            plate = np.asarray(im.convert("RGBA"), np.float32) / 255
    h, w = plate.shape[:2]
    parent = ingest.source_plate(ingest.REPO / hand["plates"][light][str(stage)])[0].astype(np.float32)
    take = np.asarray(Image.open(erase or take_path(job_for(spec["job"], light))).convert("RGB").resize((parent.shape[1], parent.shape[0]), Image.LANCZOS), np.float32) / 255
    hard_full = paste_masks(parent, take, spec["window"], spec.get("shapes"))
    for ex0, ey0, ex1, ey1 in spec.get("exclude", []) + (NIGHT_KEEP if light == "night" else []):
        hard_full[ey0:ey1, ex0:ex1] = 0
    for oid in spec.get("excludeOccluders", ()):         # an occluder's opaque pixels stay the plate's (the mailbox)
        x0, y0, x1, y1, alpha = occluder_pixels(stage, oid, light)
        solid = alpha > (0.02 if spec.get("excludeGrow") else 0.4)
        if oid in spec.get("flowersOnly", ()):           # the plate's flowers stay; the old pond's stones and water under the polygon still go
            name = ingest.asset_name(ISLAND, "occ", light, stage, oid)
            with open_source_asset(name) as im:
                solid &= ~old_pond_pixels(np.asarray(im.convert("RGB"), np.float32)[: solid.shape[0], : solid.shape[1]] / 255)
        hard_full[y0:y1, x0:x1][cv2.dilate(solid.astype(np.uint8), _ellipse(7 + spec.get("excludeGrow", 0))) > 0] = 0
    sl = (slice(cy, cy + h), slice(cx, cx + w))
    hard = hard_full[sl]
    p_rgb, p_a = plate[..., :3], plate[..., 3]
    t_rgb = take[sl]
    # the take's grass line is mixed with its sky: colours come from the nearest sure-island pixel
    if light == "night":
        known = p_a < 0.05
        known[max(spec["window"][1] - cy, 0):spec["window"][3] - cy, max(spec["window"][0] - cx, 0):spec["window"][2] - cx] = False
        t_a = night_sky_alpha(t_rgb, known)
    else:
        t_a = sky_alpha(t_rgb)
    sure = t_a > 0.97
    _, (iy, ix) = ndimage.distance_transform_edt(~sure, return_indices=True)
    t_rgb = np.where((t_a < 0.97)[..., None], t_rgb[iy, ix], t_rgb)
    t_rgb = match_to_parent(t_rgb, parent[sl], p_a, hard, spec.get("lighter", True), spec.get("brightRing", False), light == "night")
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



def occluder_pixels(stage: int, oid: str, light: str = "day") -> tuple[int, int, int, int, np.ndarray]:
    """An occluder's box in the plate's texture px and its alpha."""
    hand = ingest.load_hand(ISLAND)
    _, k = ingest.source_plate(ingest.REPO / hand["plates"][light][str(stage)])
    a1 = ingest.load_matte(ISLAND, light, stage)
    obj = next(o for o in hand["objects"] if o["id"] == oid)
    _, box = ingest.occluder_cut(np.zeros(a1.shape + (3,)), a1, ingest.pct_to_px(obj["points"]))
    x0, y0, x1, y1 = (v * k for v in box)
    name = ingest.asset_name(ISLAND, "occ", light, stage, oid)
    with open_source_asset(name) as im:
        alpha = np.asarray(im.convert("RGBA"), np.float32)[..., 3] / 255
    return x0, y0, x0 + alpha.shape[1], y0 + alpha.shape[0], alpha


ALPHA_STABLE = 3                  # an occluder whose alpha moves by no more than this many 8-bit levels, in no more than
ALPHA_NOISE = 0.003               # this share of its pixels (a decoded HEIC flips a few stone tests), is left as it is


def clear_alpha(alpha: np.ndarray, part: np.ndarray) -> np.ndarray:
    """An occluder's alpha with `part` (0 to 1) taken out of it: the smaller of what it is and what `part` leaves, so
    clearing the same region twice (or on top of an earlier run's result) changes nothing the second time."""
    return np.minimum(alpha, 1 - part).astype(np.float32)


def clear_occluders(stage: int, hard_full: np.ndarray, station: str = TEA_STALL["id"], keep: tuple = (), skip: tuple = (), light: str = "day") -> None:
    """Another object's occluder cut-out that reaches into the erased stall (the workshop's polygon runs on to the stall's
    left pole) would draw the old stall again over the base: its alpha is cleared inside the erased region."""
    hand = ingest.load_hand(ISLAND)
    rgb, k = ingest.source_plate(ingest.REPO / hand["plates"][light][str(stage)])
    a1 = ingest.load_matte(ISLAND, light, stage)
    region = cv2.GaussianBlur(cv2.dilate(hard_full, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13))).astype(np.float32), (0, 0), 2.0)
    for obj in hand["objects"]:
        if not obj.get("occluder") or not ingest.present(obj, light, stage) or obj["id"] == station or obj["id"] in skip:
            continue
        _, box = ingest.occluder_cut(np.zeros(a1.shape + (3,)), a1, ingest.pct_to_px(obj["points"]))
        x0, y0, x1, y1 = (v * k for v in box)
        part = region[y0:y1, x0:x1]
        if obj["id"] in keep:                 # scenery that stands in front (flowers): only the old stall's pale stones and water go
            inner = cv2.GaussianBlur(cv2.erode(hard_full, _ellipse(29)).astype(np.float32), (0, 0), 2.0)[y0:y1, x0:x1]
            part = inner
        if part.max() <= 0.01:
            continue
        name = ingest.asset_name(ISLAND, "occ", light, stage, obj["id"])
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


def accumulate_base(stage: int, specs: list[dict] | None = None, light: str = "day", erase: Path | None = None) -> tuple[np.ndarray, dict, np.ndarray]:
    """The base of a stage with every station that has one there erased: each station's window is taken out of what the
    stations before it left. Returns the base, the plate crop (`info`, with each station's erased region in
    `info["regions"]`) and the union of the erased regions (texture px)."""
    x, info, union, regions = None, None, None, []
    for spec in stage_specs(stage, specs):
        x, info = build_base(stage, spec["bases"][stage], x, light, erase)
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


def cmd_bases(station: dict | None = None, light: str = "day") -> dict:
    """Every base of the stages `station` stands on (all stations when None), each with all the stations that share it, in
    `light` (day or night: batch 117 erased both)."""
    chosen = [station] if station else STATIONS
    stages = sorted({s for sp in chosen for s in sp["bases"] if light != "golden" or s in GOLDEN_STAGES})
    out = {}
    for stage in stages:
        x, info, _ = golden_base(stage) if light == "golden" else accumulate_base(stage, None, light)
        write_or_keep(base_name(light, stage), to_img(x))
        # The Map's island cut (and the graded island layer) is the same picture: it must not paint the stall either.
        crop = info["crop"]
        full = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
        full[crop[1] * TEX:crop[1] * TEX + x.shape[0], crop[0] * TEX:crop[0] * TEX + x.shape[1]] = x
        # `ingest.cmd_deliver` cuts it at the stage matte's box (`ingest.bbox`), `map_cut.py` clears the level-10 ghost.
        ix0, iy0, ix1, iy1 = ingest.bbox(ingest.load_matte(ISLAND, light, stage), 0.02)
        for kind in ("island", "mapisle"):
            name = ingest.asset_name(ISLAND, kind, light, stage)
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
            clear_occluders(stage, region, station_id, keep, skip, light)
        out[stage] = x.shape[:2]
        print(f"base {light} {stage}: {x.shape[1]} x {x.shape[0]} px ({', '.join(sp['id'] for sp in stage_specs(stage))})")
    return out


# ---------------------------------------------------------------- seasons (season-system-v1 D5, D6)

SEASON_BATCH = "batch-194-season-slice-pilot"
#: What a painted season ships, per season: the states (key `<season>-<light>` -> stage -> the season's erase take, the base's
#: source), the stations painted per level (`paint`: station -> level -> the season's take of that level, graded in place to
#: the season plate's mill) and the stations derived (the spring look through the colour fit of the stage-0 pair).
#: Autumn at the pilot: level 10 by day (stage 0, the master) and its night; the level 3 picks fail the gate (S1: Codex redrew
#: the adult island, `review.yaml`), so the tea stall (its looks stand on stage 7 and below) waits for a re-take.
SEASON_SLICE = {
    "autumn": {
        "states": {"autumn-day": {0: f"{SEASON_BATCH}/x-season-autumn-l10-bare-day"}, "autumn-night": {0: None}},
        "paint": {"windmill": {n: f"{SEASON_BATCH}/x-plot-windmill-{n}-autumn" for n in range(2, 6)}},
        "derive": ["pond", "workshop"],
    },
}


def season_stage_stations(season: str, key: str, stage: int) -> list[dict]:
    """The stations that stand over a base in a season's state: the ones with a spring base at the stage, when the season
    has an erase take for it (night has no bases, as in spring)."""
    return stage_specs(stage) if SEASON_SLICE[season]["states"][key].get(stage) else []


def season_paint_spec(season: str, sid: str, grade: dict | None = None) -> dict:
    spec = next(sp for sp in STATIONS if sp["id"] == sid)
    paint = SEASON_SLICE[season]["paint"][sid]
    plot = {**spec["plot"], "paint": {n: (job, pick_of(job)) for n, job in paint.items()},
            "grade": grade or {n: (1.0, 1.0) for n in paint}}
    plot["takes"] = {n: t for n, t in plot["takes"].items() if n in paint}
    return {**spec, "plot": plot}


def _lab_mean(rgb: np.ndarray, m: np.ndarray) -> np.ndarray:
    return srgb_lab(rgb.astype(np.float32).reshape(-1, 1, 3))[m.reshape(-1)].reshape(-1, 3).mean(0)


def mill_target(season: str, key: str, stage: int, sid: str) -> tuple[float, float]:
    """The station's colour on the season's own plate: mean L* and chroma of the pixels of the station's object polygon that
    its spring look level 3 covers (the mill as painted), the target the season's looks are graded to ("measured in place")."""
    import season_gate as sg
    data = json.loads(ingest.JSON_DIR.joinpath("plate-home.json").read_text())
    obj = next(o for o in data["objects"] if o.get("station") == sid)
    plate = sg.load_asset(ingest.asset_name(ISLAND, "plate", key, stage))
    spring = sg.load_asset(f"{look_name(sid, 3, 'day')}")
    st = data["stations"][sid]
    pos = st["stages"][str(stage)]
    x0, y0 = round((pos["box"][0] - 2) * TEX), round((pos["box"][1] - 434) * TEX)
    w, h = round((pos["box"][2] - pos["box"][0]) * TEX), round((pos["box"][3] - pos["box"][1]) * TEX)
    foot = cv2.resize(spring[..., 3], (w, h), interpolation=cv2.INTER_AREA) > 0.5
    cover = np.zeros(plate.shape[:2], bool)
    ys, xs = slice(max(y0, 0), min(y0 + h, plate.shape[0])), slice(max(x0, 0), min(x0 + w, plate.shape[1]))
    cover[ys, xs] = foot[ys.start - y0:ys.stop - y0, xs.start - x0:xs.stop - x0]
    mask = cover & sg.poly_mask(plate.shape[:2], obj["polygon"]) & (plate[..., 3] > 0.99)
    lab = srgb_lab(plate[mask][:, :3].reshape(-1, 1, 3)).reshape(-1, 3).mean(0)
    return float(lab[0]), float(np.hypot(lab[1], lab[2]))


def season_looks(season: str, key: str, stage: int = 0) -> dict:
    """The season's station looks, as `world-home-look-<station>-<level>-<key>`: painted ones (the spring shape, the season
    take's colours, graded in place) and derived ones (the spring look through the stage-0 colour fit, learned on the
    station's own pixels in the spring and season plates). Returns `{station: [levels]}`."""
    import season_gate as sg
    out = {}
    data = json.loads(ingest.JSON_DIR.joinpath("plate-home.json").read_text())
    plate_a = sg.load_asset(ingest.asset_name(ISLAND, "plate", key, stage))
    plate_s = sg.load_asset(ingest.asset_name(ISLAND, "plate", "day", stage))
    for sid in SEASON_SLICE[season]["paint"]:
        spec = season_paint_spec(season, sid)
        raw = build_looks(spec)                                   # ungraded: the mean colour of each level, as the season painted it
        want_l, want_c = mill_target(season, key, stage, sid)
        grade = {}
        for n, x in raw["looks"].items():
            keep = x[..., 3] > 0.9
            lab = srgb_lab(x[..., :3])[keep]
            grade[n] = (round(want_c / float(np.hypot(lab[:, 1], lab[:, 2]).mean()), 3), round(want_l / float(lab[:, 0].mean()), 3))
        spec = season_paint_spec(season, sid, grade)
        built = build_looks(spec)
        for n, x in built["looks"].items():
            ingest.write_imageset(look_name(sid, n, key), to_img(x))
        out[sid] = sorted(built["looks"])
        print(f"looks {sid} {key}: painted levels {out[sid]}, grade {grade}")
    for sid in SEASON_SLICE[season]["derive"]:
        # The fit is learned per level, where that spring look stands on the two plates (its alpha, eroded, at the stage's place):
        # the pond's polygon holds the lawn and flowers round the water, which autumn changes and the water does not.
        pos = data["stations"][sid]["stages"][str(stage)]["box"]
        x0, y0 = round((pos[0] - 2) * TEX), round((pos[1] - 434) * TEX)
        w, h = round((pos[2] - pos[0]) * TEX), round((pos[3] - pos[1]) * TEX)
        n_levels = data["stations"][sid]["levels"]
        for n in range(1, n_levels + 1):
            with heic.open_image(ASSETS / f"{look_name(sid, n, 'day')}.imageset" / f"{look_name(sid, n, 'day')}{heic.SUFFIX}") as im:
                look = np.asarray(im.convert("RGBA"), np.float32) / 255
            foot = cv2.erode((cv2.resize(look[..., 3], (w, h), interpolation=cv2.INTER_AREA) > 0.9).astype(np.uint8), _ellipse(9)) > 0
            m = np.zeros(plate_a.shape[:2], bool)
            ys, xs = slice(max(y0, 0), min(y0 + h, m.shape[0])), slice(max(x0, 0), min(x0 + w, m.shape[1]))
            m[ys, xs] = foot[ys.start - y0:ys.stop - y0, xs.start - x0:xs.stop - x0]
            m &= (plate_a[..., 3] > 0.99) & (plate_s[..., 3] > 0.99)
            fit = sg.colour_fit(plate_s[m][:, :3], plate_a[m][:, :3])
            look[..., :3] = sg.apply_fit(fit, look[..., :3].reshape(-1, 3)).reshape(look.shape[:2] + (3,))
            ingest.write_imageset(look_name(sid, n, key), to_img(look))
        out[sid] = list(range(1, n_levels + 1))
        print(f"looks {sid} {key}: derived levels {out[sid]} by the stage-{stage} fit, per level")
    return out


def cmd_season(season: str) -> None:
    """Delivers a season's states (`ingest.py deliver` and `objects` for each), builds the erased bases from the season's own
    erase takes (the stations' windows, cuts and occluders, as `bases` does in spring) and the looks. Run `ingest.py json`
    and `station_looks.py json` after."""
    for key, stages in SEASON_SLICE[season]["states"].items():
        for stage, erase in stages.items():
            state = f"{key}:{stage}"
            ingest.cmd_deliver(ISLAND, state)
            ingest.cmd_objects(ISLAND, state)
            if not erase:
                continue
            take = take_path(erase)
            x, info, _ = accumulate_base(stage, None, key, take)
            ingest.write_imageset(base_name(key, stage), to_img(x))
            crop = info["crop"]
            full = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
            full[crop[1] * TEX:crop[1] * TEX + x.shape[0], crop[0] * TEX:crop[0] * TEX + x.shape[1]] = x
            ix0, iy0, ix1, iy1 = ingest.bbox(ingest.load_matte(ISLAND, key, stage), 0.02)
            for kind in ("island", "mapisle"):
                name = ingest.asset_name(ISLAND, kind, key, stage)
                with open_source_asset(name) as im:
                    old = np.asarray(im.convert("RGBA"), np.float32) / 255
                cut = resize_rgba(full[iy0 * TEX:iy1 * TEX, ix0 * TEX:ix1 * TEX], 1.0)
                cut = cv2.resize(np.dstack([cut[..., :3] * cut[..., 3:], cut[..., 3:]]), (old.shape[1], old.shape[0]), interpolation=cv2.INTER_AREA)
                a = cut[..., 3:]
                rgb = np.where(a > 1e-4, cut[..., :3] / np.maximum(a, 1e-4), old[..., :3])
                alpha = np.minimum(old[..., 3:], a) if kind == "mapisle" else a
                ingest.write_imageset(name, to_img(np.dstack([rgb, alpha])))
            for station_id, region in info["regions"]:
                sp = next(sp for sp in STATIONS if sp["id"] == station_id)
                keep = sp.get("keepOccluders", ())
                skip = tuple(o for o in sp["bases"][stage].get("excludeOccluders", ()) if o not in keep)
                clear_occluders(stage, region, station_id, keep, skip, key)
            print(f"base {key} {stage}: {x.shape[1]} x {x.shape[0]} px ({', '.join(sp['id'] for sp in stage_specs(stage))})")
            season_looks(season, key, stage)


# ---------------------------------------------------------------- night (N1)

#: The pond's painted night looks (batch 197, the lead's picks: take 2, 1, 1, 2, 2 of forms 1 to 5): relights of batch 134's day plots, so
#: the day look's outline cuts them (`plot_looks` with `paint`) and their colours are graded to the day look as the night plate sees it.
PLOT_POND_NIGHT = "batch-197-pond-night/x-plot-pond-{}-night"
POND_NIGHT_PICKS = {1: 2, 2: 1, 3: 1, 4: 2, 5: 2}
#: The windmill's (batch 188, the lead's picks: forms 2, 4 and 5 are cut; form 3 is a redo, so its night is its day look through the
#: colour fit; form 1 has no day look to cut by). Each station: level -> (job, take).
PLOT_MILL_NIGHT = "batch-188-windmill-night/x-plot-windmill-{}-night"
NIGHT_PAINT = {
    "pond": {n: (PLOT_POND_NIGHT.format(n), t) for n, t in POND_NIGHT_PICKS.items()},
    "windmill": {2: (PLOT_MILL_NIGHT.format(2), 2), 4: (PLOT_MILL_NIGHT.format(4), 2), 5: (PLOT_MILL_NIGHT.format(5), 1)},
}
#: The bagel cart's, workshop's, lighthouse's and tea stall's painted nights (N1b; batches 190, 191, 192 and 196, the lead's picks of
#: levels 1 to 5, recorded in their `review.yaml`): relights of the day plots, cut with the day look's outline and graded in CIELAB by
#: the lead's reviews (`station_grade`): level -> (light multiplier, darks lift in L*, chroma multiplier). The reviews give the first
#: three stations' numbers; the tea stall's were measured on the cut looks against the day look under the night fit (`TEA_NIGHT_GRADE`).
PLOT_NIGHT = {"bagelCart": "batch-190-plot-ladder-bagel-cart/x-plot-bagel-cart-{}-night", "workshop": "batch-191-plot-ladder-workshop/x-plot-workshop-{}-night",
              "lighthouse": "batch-192-plot-ladder-lighthouse/x-plot-lighthouse-{}-night", "teaStall": "batch-196-plot-ladder-tea-stall/x-plot-tea-stall-{}-night"}
STATION_NIGHT_PICKS = {"bagelCart": [1, 1, 1, 1, 1], "workshop": [1, 1, 1, 1, 1], "lighthouse": [2, 1, 2, 1, 1], "teaStall": [2, 2, 2, 2, 1]}
#: The tea stall's grade is measured, as the lead measured the others (pofu-art #228): its look's pixels in the day and the night plate of
#: its foot stage (7; levels 1 to 3 stand where the plate's own stall does) give the day-to-night ratio of the mean L*, the 5th
#: percentile of L* and the mean chroma C*; each level's cut take is graded so that its mean L*, p5 and C* are the day look's times these.
TEA_NIGHT_RATIO = {"light": 0.80, "p5": 0.76, "chroma": 0.65}
TEA_NIGHT_GRADE = None
STATION_NIGHT_GRADE = {
    "bagelCart": {n: (1.15, 11.0, 0.5) for n in range(1, 6)},
    "workshop": {1: (1.17, 11.0, 0.9), 2: (1.17, 11.0, 0.9), 3: (1.07, 6.0, 0.8), 4: (1.07, 6.0, 0.8), 5: (1.07, 6.0, 0.8)},
    "lighthouse": {n: (1.25, 19.0, 0.65) for n in range(1, 6)},
    "teaStall": TEA_NIGHT_GRADE,                  # None: measured (`measured_grade`)
}
#: The workshop's night takes drop lit lamps (the lead's reviews): the bulb hanging in the opening at levels 1 and 2 and the two wall
#: lamps at level 2, take px (x0, y0, x1, y1). The bulb is pasted from the day take through the night fit, the wall lamps from level 1's.
WORKSHOP_BULB = (540, 590, 610, 700)
WORKSHOP_LAMPS = [(270, 625, 310, 695), (785, 625, 820, 695)]
#: The workshop's window panes at levels 1 and 2 (take px): the day form's are warm and lit, the night takes' blue. Their glow is pasted back
#: from the day take through the night fit, where it is warm and bright, soft-edged.
#: The workshop's cog on the roof (the look's px, x0 y0 x1 y1): it takes the chroma cap in full.
GEAR = (188, 18, 312, 146)
WORKSHOP_WINDOWS = [(362, 630, 442, 762), (846, 638, 884, 760)]
#: What the night plate's own station measures (pofu-art #228, `stats.json`: mean L*, mean C* over the il8 night plate's station): the painted
#: nights are graded to it (`fit_grade`). The tea stall's is measured per level (`measured_grade`).
#: Stations whose painted night is matched to the derived look of the same level: mean L* and C* (x the factor) are the derived look's rather than
#: the plate's own station, and the warm pixels' median hue is turned onto the derived look's (`turn_hue`, a plain rotation of a* b*).
LOOK_MATCH = {"bagelCart": 1.0}
WARM_C, WARM_L, WARM_H = 12.0, 55.0, (30.0, 150.0)
PLATE_NIGHT_TARGET = {"workshop": (55.5, 24.3), "bagelCart": (58.1, 18.3), "lighthouse": (71.7, 23.7)}
#: The tea stall keeps the derived (N1) night looks at every level: batch 196 sits 15 to 20 degrees greener than the plate's warm hue after the
#: grade (its body reads lime or lilac at 1:1), so its painted nights are not shipped; redo pending. Its picks, grade and hue restore stay below.
#: The bagel cart's painted nights (batch 190) are back on with `LOOK_MATCH`: the raw takes' warm pixels sit 11 to 18 degrees greener than the
#: derived look's (median hue 66 to 71 against 52 to 56) and the build adds 2 to 3 more, so the hue is turned back onto the derived look's.
DERIVED_NIGHT = ("teaStall",)
for _sid, _picks in STATION_NIGHT_PICKS.items():
    NIGHT_PAINT[_sid] = {n: (PLOT_NIGHT[_sid].format(n), t) for n, t in enumerate(_picks, start=1)}


def night_fit(sid: str, stage: int, level: int, look: np.ndarray, data: dict, light: str = "night") -> np.ndarray:
    """The colour fit, in linear RGB, from the day plate to the `light` (night, or golden) plate of `stage`, learned on the pixels the station's look
    covers there (its alpha eroded; both plates solid), as the season's derived looks (`season_looks`)."""
    import season_gate as sg
    hand = ingest.load_hand(ISLAND)

    def full(light: str) -> np.ndarray:                              # the state's plate in the full plate's texture frame
        plate = sg.load_asset(ingest.asset_name(ISLAND, "plate", light, stage))
        cx, cy = (v * TEX for v in ingest.plate_crop_points(ISLAND, hand, light, stage)[:2])
        canvas = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
        canvas[cy:cy + plate.shape[0], cx:cx + plate.shape[1]] = plate
        return canvas

    plate_n, plate_d = full(light), full("day")
    pos = data["stations"][sid]["stages"][str(stage)]["box"]
    x0, y0 = round(pos[0] * TEX), round(pos[1] * TEX)
    w, h = round((pos[2] - pos[0]) * TEX), round((pos[3] - pos[1]) * TEX)
    foot = cv2.erode((cv2.resize(look[..., 3], (w, h), interpolation=cv2.INTER_AREA) > 0.9).astype(np.uint8), _ellipse(9)) > 0
    m = np.zeros(plate_n.shape[:2], bool)
    m[y0:y0 + h, x0:x0 + w] = foot
    d = plate_d
    if m.sum() < 500:
        raise SystemExit(f"{sid} level {level}: the {light} fit has {int(m.sum())} px at stage {stage}")
    return sg.colour_fit(d[m][:, :3], plate_n[m][:, :3])


def night_looks(only: str | None = None) -> dict:
    """The night looks, `world-home-look-<station>-<level>-night`: the painted ones (the pond's, batch 197, graded to its day look
    under the night fit; the windmill's levels 2, 4, 5; the bagel cart's, workshop's, lighthouse's and tea stall's, `station_night_looks`,
    graded by the lead's reviews) and, for every other level, the day look through that fit (the colour fit of #549's season derive,
    learned per level on the station's own pixels in the day and the night plate of its foot stage). Where the painted take has
    a lantern or window lit, it stays lit (N1b); the derived looks light nothing (D51, D68). `only`: one station."""
    import season_gate as sg
    data = json.loads(ingest.JSON_DIR.joinpath("plate-home.json").read_text())
    out = {}
    for spec in STATIONS:
        sid = spec["id"]
        if only not in (None, sid):
            continue
        stage = spec.get("footStage", min(spec["bases"]))
        levels = data["stations"][sid].get("lookLevels", {}).get("day") or list(range(1, spec["levels"] + 1))
        fits, days = {}, {}
        for n in levels:
            with heic.open_image(ASSETS / f"{look_name(sid, n, 'day')}.imageset" / f"{look_name(sid, n, 'day')}{heic.SUFFIX}") as im:
                day = np.asarray(im.convert("RGBA"), np.float32) / 255
            fits[n], days[n] = night_fit(sid, stage, n, day, data), day
        painted = station_night_looks(spec, days, fits) if sid in STATION_NIGHT_GRADE and sid not in DERIVED_NIGHT else {}
        for n in levels:
            day, fit = days[n], fits[n]
            look = day.copy()
            look[..., :3] = sg.apply_fit(fit, day[..., :3].reshape(-1, 3)).reshape(day.shape[:2] + (3,))
            if n in painted:
                look = painted[n]
            elif n in NIGHT_PAINT.get(sid, {}) and sid not in DERIVED_NIGHT:
                look = painted_night_look(spec, n, day, look)
            ingest.write_imageset(look_name(sid, n, "night"), to_img(look))
        out[sid] = levels
        print(f"night looks {sid}: levels {levels} by the stage-{stage} fit" + (f", painted at levels {sorted(NIGHT_PAINT[sid])}, the rest derived" if sid in NIGHT_PAINT and sid not in DERIVED_NIGHT else ", derived"))
    return out


def station_grade(rgb: np.ndarray, mask: np.ndarray, light: float, darks: float, chroma: float) -> np.ndarray:
    """A night take graded by the lead's review (light x`light`, the darks lifted by `darks` L* in all, chroma x`chroma`), in CIELAB. The
    multiply lifts the darkest 5 percent of the cut (`mask`) by (light - 1) of their L*; a toe curve adds the rest, most at the
    darkest and nothing from L* 60 up, so the lights are the multiply's."""
    lab = srgb_lab(rgb)
    L = lab[..., 0]
    p5 = float(np.percentile(L[mask], 5))
    extra = max(darks - (light - 1) * p5, 0.0)
    knee = 60.0
    toe = np.clip((knee - L * light) / max(knee - p5 * light, 1e-3), 0, 1)
    lab[..., 0] = np.clip(L * light + extra * toe, 0, 100)
    lab[..., 1:] *= chroma
    return lab_srgb(lab)


def measured_grade(rgb: np.ndarray, cut: np.ndarray, day: np.ndarray) -> tuple[float, float, float]:
    """(light, darks, chroma) that put a night take's cut (`cut`, a mask of the take) on the day look's mean L*, p5 and mean C* times
    `TEA_NIGHT_RATIO`."""
    k = day[..., 3] > 0.9
    d = srgb_lab(day[..., :3])[k]
    t = srgb_lab(rgb)[cut]
    mean_t, p5_t, c_t = float(d[:, 0].mean()) * TEA_NIGHT_RATIO["light"], float(np.percentile(d[:, 0], 5)) * TEA_NIGHT_RATIO["p5"], float(np.hypot(d[:, 1], d[:, 2]).mean()) * TEA_NIGHT_RATIO["chroma"]
    light = mean_t / float(t[:, 0].mean())
    darks = p5_t - float(np.percentile(t[:, 0], 5))
    return round(light, 3), round(max(darks, 0.0), 1), round(c_t / float(np.hypot(t[:, 1], t[:, 2]).mean()), 3)


def fit_grade(rgb: np.ndarray, cut: np.ndarray, darks: float, mean_l: float, mean_c: float) -> tuple[float, float, float]:
    """(light, darks, chroma) that put the cut of a night take on `mean_l` and `mean_c` (the plate's own at the station), the darks lifted by `darks`
    as in `station_grade`: the light is found by bisection (the toe makes it not a plain ratio)."""
    lo, hi = 0.5, 1.8
    for _ in range(30):
        mid = (lo + hi) / 2
        lab = srgb_lab(station_grade(rgb, cut, mid, darks, 1.0))
        if lab[..., 0][cut].mean() < mean_l:
            lo = mid
        else:
            hi = mid
    light = (lo + hi) / 2
    lab = srgb_lab(station_grade(rgb, cut, light, darks, 1.0))
    c = float(np.hypot(lab[..., 1], lab[..., 2])[cut].mean())
    return round(light, 3), darks, round(mean_c / c, 3)


#: The awnings of the tea stall and the bagel cart (the look's px, x0 y0 x1 y1: the front awning, levels 1 to 5): the painted nights turn their
#: yellow olive or khaki and flatten their stripes.
AWNING = {"teaStall": (100, 172, 345, 218), "bagelCart": (20, 130, 205, 200)}
AWNING_HUE_TOL, AWNING_CONTRAST_MIN = 5.0, 0.70


def awning_set(day: np.ndarray, sid: str) -> np.ndarray:
    """The awning's pixels in the day look's outline: inside `AWNING`, solid, light (L* over 65)."""
    x0, y0, x1, y1 = AWNING[sid]
    m = np.zeros(day.shape[:2], bool)
    m[y0:y1, x0:x1] = (day[y0:y1, x0:x1, 3] > 0.9) & (srgb_lab(day[y0:y1, x0:x1, :3])[..., 0] > 65)
    return m


def awning_measure(look: np.ndarray, day: np.ndarray, sid: str, hue_ref: np.ndarray | None = None) -> tuple[float, float]:
    """(hue angle difference in degrees of the awning's warm pixels, stripe contrast as a share of the day look's): the chroma-weighted mean hue of
    the pixels the day look has yellow, and the L* gap between the 85th and 15th percentile of the awning's pixels. `hue_ref`: the look the hue is
    measured against instead of the day look's (the derived night look, for `LOOK_MATCH`: the day's yellow is not a night's)."""
    m = awning_set(day, sid)
    dl, nl = srgb_lab(day[..., :3]), srgb_lab(look[..., :3])
    ang = lambda x, k: np.degrees(np.arctan2((x[..., 2] * np.hypot(x[..., 1], x[..., 2]))[k].sum(), (x[..., 1] * np.hypot(x[..., 1], x[..., 2]))[k].sum()))
    warm = m & (np.hypot(dl[..., 1], dl[..., 2]) > 25)
    gap = lambda x: float(np.percentile(x[..., 0][m], 85) - np.percentile(x[..., 0][m], 15))
    hl = dl if hue_ref is None else srgb_lab(hue_ref[..., :3])
    return float(abs((ang(nl, warm) - ang(hl, warm) + 180) % 360 - 180)), gap(nl) / gap(dl)


def restore_awning(look: np.ndarray, fitted: np.ndarray, day: np.ndarray, sid: str) -> np.ndarray:
    """The awning of a painted night on the day look's hue (no rotation) and the day look's stripes: inside the awning's pixels the a* and b* take the day
    look's hue at the largest of the derived look's, the painted night's and half the day look's chroma (a cream stripe keeps its warmth), and the lightness the derived look's relief
    (stripes, scallops) at the painted night's mean."""
    m = awning_set(day, sid)
    lab, ref, dl = srgb_lab(look[..., :3]), srgb_lab(fitted), srgb_lab(day[..., :3])
    cd, cr, cl = (np.hypot(x[..., 1], x[..., 2]) for x in (dl, ref, lab))
    w = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.0)[..., None]
    out = lab.copy()
    hued = dl[..., 1:] / np.maximum(cd, 1e-3)[..., None] * np.maximum(np.maximum(cr, cl), 0.5 * cd)[..., None]
    out[..., 1:] = lab[..., 1:] * (1 - w) + hued * w
    light = ref[..., 0] + (lab[..., 0][m].mean() - ref[..., 0][m].mean())
    out[..., 0] = lab[..., 0] * (1 - w[..., 0]) + light * w[..., 0]
    return np.dstack([lab_srgb(out), look[..., 3:]])


def warm_hue(lab: np.ndarray, m: np.ndarray) -> float:
    """The median hue angle (degrees, CIELAB) of the warm pixels of `lab` inside `m`: C* over 12, L* over 55, hue 30 to 150."""
    c = np.hypot(lab[..., 1], lab[..., 2])
    h = np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360
    k = m & (c > WARM_C) & (lab[..., 0] > WARM_L) & (h > WARM_H[0]) & (h < WARM_H[1])
    return float(np.median(h[k])) if k.any() else float("nan")


def turn_hue(look: np.ndarray, fitted: np.ndarray, keep: np.ndarray) -> np.ndarray:
    """`look` with a* b* turned (one rotation for the whole look, so no pixel changes its chroma) until its warm pixels' median hue is the
    derived look's `fitted`."""
    lab, ref = srgb_lab(look[..., :3]), srgb_lab(fitted)
    want = warm_hue(ref, keep)
    for _ in range(4):
        d = np.radians(want - warm_hue(lab, keep))
        if abs(np.degrees(d)) < 0.05:
            break
        a, b = lab[..., 1].copy(), lab[..., 2].copy()
        lab[..., 1], lab[..., 2] = a * np.cos(d) - b * np.sin(d), a * np.sin(d) + b * np.cos(d)
    return np.dstack([lab_srgb(lab), look[..., 3:]])


def turn_awning(look: np.ndarray, fitted: np.ndarray, day: np.ndarray, sid: str) -> np.ndarray:
    """The awning's a* b* turned (a rotation, soft-edged) until the chroma-weighted hue of its warm pixels is the derived look's: the awning's pixels
    sit a few degrees off the whole look's median, which `turn_hue` matches."""
    m = awning_set(day, sid)
    lab, ref = srgb_lab(look[..., :3]), srgb_lab(fitted)
    warm = m & (np.hypot(*(srgb_lab(day[..., :3])[..., 1:].transpose(2, 0, 1))) > 25)
    ang = lambda x: np.arctan2((x[..., 2] * np.hypot(x[..., 1], x[..., 2]))[warm].sum(), (x[..., 1] * np.hypot(x[..., 1], x[..., 2]))[warm].sum())
    d = ang(ref) - ang(lab)
    w = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.0)
    a, b = lab[..., 1].copy(), lab[..., 2].copy()
    lab[..., 1], lab[..., 2] = a * np.cos(d * w) - b * np.sin(d * w), a * np.sin(d * w) + b * np.cos(d * w)
    return np.dstack([lab_srgb(lab), look[..., 3:]])


def warm_pale(look: np.ndarray, fitted: np.ndarray) -> np.ndarray:
    """A pale pixel of the painted night (L* over 58, C* under 20) takes the derived look's hue and the larger of the two chromas: the take's cream
    stripes (the awning's, the umbrella's) wander to green or blue at low chroma, where the hue is a few units of a* b*, while the derived look's are warm."""
    lab, ref = srgb_lab(look[..., :3]), srgb_lab(fitted)
    c, cr = np.hypot(lab[..., 1], lab[..., 2]), np.hypot(ref[..., 1], ref[..., 2])
    w = np.clip((20.0 - c) / 6.0, 0, 1) * np.clip((lab[..., 0] - 58.0) / 4.0, 0, 1)
    tgt = ref[..., 1:] / np.maximum(cr, 1e-3)[..., None] * np.maximum(c, cr)[..., None]
    lab[..., 1:] = lab[..., 1:] * (1 - w[..., None]) + tgt * w[..., None]
    return np.dstack([lab_srgb(lab), look[..., 3:]])


def cap_chroma(look: np.ndarray, fitted: np.ndarray, day: np.ndarray, k: float = 1.25) -> np.ndarray:
    """No pixel of the painted night more chromatic than `k` times the derived look's (the cog and the roof of the workshop: the relight's gold and
    pink run hotter than the plate around them), except the lit sources: the day look's own small bright spots (L* over 88, not a solid body), dilated."""
    lab, ref, dl = srgb_lab(look[..., :3]), srgb_lab(fitted), srgb_lab(day[..., :3])
    c, cr = np.hypot(lab[..., 1], lab[..., 2]), np.hypot(ref[..., 1], ref[..., 2])
    bright = (dl[..., 0] > 88).astype(np.uint8)
    big = cv2.dilate(cv2.morphologyEx(bright, cv2.MORPH_OPEN, _ellipse(21)), _ellipse(9))      # a solid bright body (the cog), not a lamp
    lit = cv2.GaussianBlur(cv2.dilate(bright & (1 - big), _ellipse(11)).astype(np.float32), (0, 0), 3)
    lit[GEAR[1]:GEAR[3], GEAR[0]:GEAR[2]] = 0                                      # the cog is a body, not a lamp
    f = np.minimum(1.0, k * cr / np.maximum(c, 1e-3))
    f = 1 - (1 - f) * (1 - lit)
    lab[..., 1:] *= f[..., None]
    return np.dstack([lab_srgb(lab), look[..., 3:]])


def paste_glow(dst: np.ndarray, day: np.ndarray, box: tuple[int, int, int, int]) -> None:
    """The lit pane of the day take `day` inside `box` (its bright warm pixels) over `dst`, soft-edged, at lightness x0.92 and chroma x0.75: the
    colour fit greys a glow (b* 12 to 15 on a pane that is 55 to 70 by day), the night plate's windows are warm."""
    x0, y0, x1, y1 = box
    lab = srgb_lab(day)
    lit = ((lab[..., 0] > 70) & (lab[..., 2] > 25)).astype(np.uint8)
    m = np.zeros_like(lit)
    m[y0:y1, x0:x1] = cv2.morphologyEx(lit, cv2.MORPH_CLOSE, _ellipse(15))[y0:y1, x0:x1]
    w = cv2.GaussianBlur(cv2.dilate(m, _ellipse(5)).astype(np.float32), (0, 0), 2.5)[..., None]
    lab[..., 0] *= 0.92
    lab[..., 1:] *= 0.75
    dst[:] = dst * (1 - w) + lab_srgb(lab) * w


def paste_box(dst: np.ndarray, src: np.ndarray, box: tuple[int, int, int, int], feather: float = 3.0) -> None:
    """`src` over `dst` inside `box` (px, x0 y0 x1 y1), the edge softened by `feather` px."""
    x0, y0, x1, y1 = box
    a = np.zeros(dst.shape[:2], np.float32)
    a[y0 + 2:y1 - 2, x0 + 2:x1 - 2] = 1
    a = cv2.GaussianBlur(a, (0, 0), feather)[..., None]
    dst[:] = dst * (1 - a) + src * a


def station_night_looks(spec: dict, days: dict, fits: dict) -> dict:
    """{level: the painted night look} of a station of `STATION_NIGHT_GRADE`: the night take graded (`station_grade`), the lit
    sources the take dropped pasted back (the workshop's), then cut with the day look's outline on the day look's canvas (the box,
    foot and size unchanged). Prints the cut's light, darks and chroma against the day look under the night fit."""
    import season_gate as sg
    sid = spec["id"]
    masks, day_rgbs, _ = plot_masks(spec["plot"])
    grade = STATION_NIGHT_GRADE[sid]
    painted = {}
    for n, take in NIGHT_PAINT[sid].items():
        rgb = _take_rgb(take)
        cut = cv2.erode(masks[n].astype(np.uint8), _ellipse(3)) > 0
        if sid in LOOK_MATCH:
            d = srgb_lab(sg.apply_fit(fits[n], days[n][..., :3].reshape(-1, 3)).reshape(days[n].shape[:2] + (3,)))[days[n][..., 3] > 0.9]
            g = fit_grade(rgb, cut, grade[n][1], float(d[:, 0].mean()), float(np.hypot(d[:, 1], d[:, 2]).mean()) * LOOK_MATCH[sid])
        elif sid in PLATE_NIGHT_TARGET:
            g = fit_grade(rgb, cut, grade[n][1], *PLATE_NIGHT_TARGET[sid])
        else:
            g = grade[n] if grade else measured_grade(rgb, cut, days[n])
        painted[n] = station_grade(rgb, cut, *g)
        print(f"  {sid} {n}: grade light x{g[0]:.3f}, darks +{g[1]:.1f}, chroma x{g[2]:.3f}")
    if sid == "workshop":
        first = painted[1].copy()
        for n in (1, 2):
            dayfit = sg.apply_fit(fits[n], day_rgbs[n].reshape(-1, 3)).reshape(day_rgbs[n].shape)
            paste_box(painted[n], dayfit, WORKSHOP_BULB)
            for box in WORKSHOP_WINDOWS:
                paste_glow(painted[n], day_rgbs[n], box)
            if n == 2:
                for box in WORKSHOP_LAMPS:
                    paste_box(painted[n], first, box)
    plot = {**spec["plot"], "grade": {k: (1.0, 1.0) for k in spec["plot"]["takes"]}, "paint": painted}
    built = build_looks({**spec, "plot": plot})["looks"]
    out = {}
    for n, look in built.items():
        day = days[n]
        assert look.shape == day.shape, (sid, n, look.shape, day.shape)
        look = np.dstack([look[..., :3], day[..., 3:]])           # the day look's own alpha: the same outline in both lights
        fitted = sg.apply_fit(fits[n], day[..., :3].reshape(-1, 3)).reshape(day.shape[:2] + (3,))
        if sid in AWNING:
            look = restore_awning(look, fitted, day, sid)
            if sid in LOOK_MATCH:
                look = turn_awning(turn_hue(warm_pale(look, fitted), fitted, (day[..., 3] > 0.9) & (look[..., 3] > 0.9)), fitted, day, sid)
            hue, contrast = awning_measure(look, day, sid, fitted if sid in LOOK_MATCH else None)
            ok = hue <= AWNING_HUE_TOL and contrast >= AWNING_CONTRAST_MIN
            print(f"  {sid} {n}: awning hue off by {hue:.1f} degrees, stripe contrast {contrast:.2f} of the day look's" + ("" if ok else ", fails: derived look"))
            if not ok:
                look = np.dstack([fitted, day[..., 3:]])
        if sid == "workshop":
            look = cap_chroma(look, fitted, day)
        keep = (day[..., 3] > 0.9) & (look[..., 3] > 0.9)
        want, got = srgb_lab(fitted)[keep], srgb_lab(look[..., :3])[keep]
        cm = lambda x: float(np.hypot(x[:, 1], x[:, 2]).mean())
        print(f"  {sid} {n}: L p5/p50/mean {np.percentile(got[:, 0], 5):.1f}/{np.median(got[:, 0]):.1f}/{got[:, 0].mean():.1f} (derived {np.percentile(want[:, 0], 5):.1f}/{np.median(want[:, 0]):.1f}/{want[:, 0].mean():.1f}), C* {cm(got):.1f} (derived {cm(want):.1f})")
        out[n] = look
    return out


def painted_night_look(spec: dict, n: int, day: np.ndarray, fitted: np.ndarray) -> np.ndarray:
    """The night look of level `n` of a station painted by night (`NIGHT_PAINT`): the relight cut with the day plot's outline
    (`build_looks` on the same canvas as the day look, so the box, foot and size are unchanged) and graded in CIELAB to the day look
    under the night fit (the relights run darker and more chromatic than the night plate: batch 188's reviews)."""
    paint = NIGHT_PAINT[spec["id"]]
    plot = {**spec["plot"], "grade": {k: (1.0, 1.0) for k in spec["plot"]["takes"]},
            "paint": {k: paint.get(k, spec["plot"]["takes"][k]) for k in spec["plot"]["takes"]}}
    built = build_looks({**spec, "plot": plot})["looks"][n]
    assert built.shape == day.shape, (built.shape, day.shape)
    keep = (day[..., 3] > 0.9) & (built[..., 3] > 0.9)
    want, got = srgb_lab(fitted[..., :3])[keep], srgb_lab(built[..., :3])[keep]
    c = float(np.hypot(want[:, 1], want[:, 2]).mean() / np.hypot(got[:, 1], got[:, 2]).mean())
    l = float(want[:, 0].mean() / got[:, 0].mean())
    lab = srgb_lab(built[..., :3])
    lab[..., 0] = np.clip(lab[..., 0] * l, 0, 100)
    lab[..., 1:] *= c
    print(f"  {spec['id']} {n}: grade chroma {c:.3f}, light {l:.3f}")
    return np.dstack([lab_srgb(lab), day[..., 3:]])           # the day look's own alpha: the same outline in both lights


def cmd_night(station: str | None = None) -> None:
    """The night bases (every stage a station stands on) and looks; with `station`, that station's looks only. Run `ingest.py json` and
    `station_looks.py json` after."""
    if station is None:
        cmd_bases(None, "night")
    night_looks(station)


# ---------------------------------------------------------------- golden (N2)

#: The stages the golden bases stand on: golden paints stages 0 and 3 to 7, and stage 5 has no station. Stages 1 and 2 paint no
#: golden plate; the hour borrows the night plate there (`HomePlate.borrowed`), with its night bases and looks.
GOLDEN_STAGES = (0, 3, 4, 6, 7)
#: The two path lanterns' heads and posts at stage 0 (texture px, full plate; `NIGHT_KEEP` less the bush above the first).
GOLDEN_KEEP = [(575, 1510, 655, 1650), (870, 1520, 960, 1650)]
GOLDEN_SPREAD = 50              # the residual spread's blur sigma, texture px
GOLDEN_RING = (161, 41)          # the fit's ring round the erased regions: dilated by 161 px, outside 41 px (texture px)


def golden_fit(day_plate: np.ndarray, gold_plate: np.ndarray, union: np.ndarray) -> np.ndarray:
    """The colour fit, in linear RGB, from the day plate to the golden plate of one stage, learned on the ring of plate round the
    erased regions (not the regions themselves: they hold the old stations, which the golden painting draws unlike the day's)."""
    import season_gate as sg
    near = cv2.dilate(union, _ellipse(GOLDEN_RING[0])) > 0
    close = cv2.dilate(union, _ellipse(GOLDEN_RING[1])) > 0
    ring = near & ~close & (day_plate[..., 3] > 0.99) & (gold_plate[..., 3] > 0.99)
    if ring.sum() < 2000:
        raise SystemExit(f"the golden fit has {int(ring.sum())} px")
    return sg.colour_fit(day_plate[ring][:, :3], gold_plate[ring][:, :3])


def golden_base(stage: int) -> tuple[np.ndarray, dict, np.ndarray]:
    """The golden plate of `stage` with every station's window taken from the day base, which has the stations erased, graded to
    the golden plate by the fit of the ring round the windows (`golden_fit`). Returns the base, `info` (crop, regions) and the
    union of the windows. The golden painting is the day's composition, so the windows are the day base's (texture px)."""
    import season_gate as sg
    hand = ingest.load_hand(ISLAND)
    crop_day, crop_gold = (ingest.plate_crop_points(ISLAND, hand, l, stage) for l in ("day", "golden"))
    day_base, info, union = accumulate_base(stage, None, "day")

    def framed(plate: np.ndarray, crop: list) -> np.ndarray:       # a state's plate in the full plate's texture frame (the crops differ)
        canvas = np.zeros((SIZE_TEX[1], SIZE_TEX[0], 4), np.float32)
        canvas[crop[1] * TEX:crop[1] * TEX + plate.shape[0], crop[0] * TEX:crop[0] * TEX + plate.shape[1]] = plate
        return canvas

    day_plate = framed(sg.load_asset(ingest.asset_name(ISLAND, "plate", "day", stage)), crop_day)
    gold_crop = sg.load_asset(ingest.asset_name(ISLAND, "plate", "golden", stage))
    gold = framed(gold_crop, crop_gold)
    day_base = framed(day_base, crop_day)
    hard = union.astype(np.uint8)
    for ex0, ey0, ex1, ey1 in GOLDEN_KEEP:                 # the path lanterns the erase takes the heads of stay the plate's, lit
        hard[ey0:ey1, ex0:ex1] = 0
    fit = golden_fit(day_plate, gold, hard)
    graded = day_base.copy()
    shape = day_base.shape[:2] + (3,)
    graded[..., :3] = sg.apply_fit(fit, day_base[..., :3].reshape(-1, 3)).reshape(shape)
    # What the global fit leaves (the golden painting's lawn is not the day lawn's colour as one map): the ring's own residual, spread
    # inward by a normalised blur, so the window's colour meets the golden plate's at its edge.
    near = cv2.dilate(hard, _ellipse(GOLDEN_RING[0])) > 0
    close = cv2.dilate(hard, _ellipse(GOLDEN_RING[1])) > 0
    ring = (near & ~close & (day_plate[..., 3] > 0.99) & (gold[..., 3] > 0.99)).astype(np.float32)
    fitted_plate = sg.apply_fit(fit, day_plate[..., :3].reshape(-1, 3)).reshape(shape)
    resid = (gold[..., :3] - fitted_plate) * ring[..., None]
    weight = cv2.GaussianBlur(ring, (0, 0), GOLDEN_SPREAD)
    spread = cv2.GaussianBlur(resid, (0, 0), GOLDEN_SPREAD) / np.maximum(weight, 1e-4)[..., None]
    graded[..., :3] = np.clip(graded[..., :3] + spread * np.clip(weight * 8, 0, 1)[..., None], 0, 1)
    m_alpha = cv2.GaussianBlur(cv2.dilate(hard, _ellipse(9)).astype(np.float32), (0, 0), 3.0)
    m_rgb = cv2.GaussianBlur(cv2.dilate(hard, _ellipse(25)).astype(np.float32), (0, 0), FEATHER_TEX / 3)
    new_a = gold[..., 3] * (1 - m_alpha) + np.minimum(gold[..., 3], day_base[..., 3]) * m_alpha
    new_rgb = gold[..., :3] * (1 - m_rgb[..., None]) + graded[..., :3] * m_rgb[..., None]
    rgb = ingest.extended(np.where(new_a[..., None] > 0, new_rgb, gold[..., :3]), new_a)
    cx, cy = crop_gold[0] * TEX, crop_gold[1] * TEX
    out = np.dstack([rgb, new_a])[cy:cy + gold_crop.shape[0], cx:cx + gold_crop.shape[1]]
    info = {**info, "crop": crop_gold, "changed": float(m_rgb.max())}
    return out, info, union


def golden_looks() -> dict:
    """The golden looks, `world-home-look-<station>-<level>-golden`: each station's day look through the colour fit from the day
    plate to the golden plate, learned per level on the station's own pixels at its foot stage (`night_fit` with `golden`), as the
    night's derived looks. Only the stations that stand on a golden stage have them."""
    import season_gate as sg
    data = json.loads(ingest.JSON_DIR.joinpath("plate-home.json").read_text())
    out = {}
    for spec in STATIONS:
        if not spec.get("golden"):
            continue
        sid = spec["id"]
        stage = min(st for st in spec["bases"] if st in GOLDEN_STAGES)
        levels = data["stations"][sid].get("lookLevels", {}).get("day") or list(range(1, spec["levels"] + 1))
        for n in levels:
            with heic.open_image(ASSETS / f"{look_name(sid, n, 'day')}.imageset" / f"{look_name(sid, n, 'day')}{heic.SUFFIX}") as im:
                day = np.asarray(im.convert("RGBA"), np.float32) / 255
            fit = night_fit(sid, stage, n, day, data, "golden")
            look = day.copy()
            look[..., :3] = sg.apply_fit(fit, day[..., :3].reshape(-1, 3)).reshape(day.shape[:2] + (3,))
            ingest.write_imageset(look_name(sid, n, "golden"), to_img(look))
        out[sid] = levels
        print(f"golden looks {sid}: levels {levels} by the stage-{stage} fit")
    return out


def cmd_golden() -> None:
    """The golden bases (every golden stage a station stands on) and looks. Run `ingest.py json` and `station_looks.py json` after."""
    cmd_bases(None, "golden")
    golden_looks()


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
    if spec.get("night"):                                      # the night bases (batch 117's night erases) and looks (`cmd_night`)
        nights = sorted(st for st in spec["bases"] if st in NIGHT_STAGES)
        data.setdefault("lights", {spec["light"]: data["baseStages"]})["night"] = nights
        data["lightBaseBytes"] = {"night": {str(s): asset_pixels(base_name("night", s)) for s in nights}}
        if "lookLevels" in data:
            data["lookLevels"]["night"] = levels
    if spec.get("golden"):                                     # the golden bases and looks (`cmd_golden`)
        golds = sorted(st for st in spec["bases"] if st in GOLDEN_STAGES)
        data["lights"]["golden"] = golds
        data["lightBaseBytes"]["golden"] = {str(s): asset_pixels(base_name("golden", s)) for s in golds}
        if "lookLevels" in data:
            data["lookLevels"]["golden"] = levels
    for season, entry in SEASON_SLICE.items():                # a season's states that stand this station over a base
        for key, stages in entry["states"].items():
            on = sorted(st for st, erase in stages.items() if erase and st in spec["bases"])
            if on:
                data.setdefault("lights", {spec["light"]: data["baseStages"]})[key] = on
                if "lookLevels" in data:
                    data["lookLevels"][key] = levels
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
    ap.add_argument("command", choices=["looks", "bases", "json", "all", "season", "night", "golden"])
    ap.add_argument("--season", default="autumn", choices=sorted(SEASON_SLICE), help="season: the season to deliver (default autumn)")
    ap.add_argument("--station", choices=[sp["id"] for sp in STATIONS], help="one station (default: every station)")
    args = ap.parse_args(argv)
    heic.require()
    if args.command == "season":
        cmd_season(args.season)
        return 0
    if args.command == "night":
        cmd_night(args.station)
        return 0
    if args.command == "golden":
        cmd_golden()
        return 0
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
