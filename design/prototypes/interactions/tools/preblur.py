#!/usr/bin/env python3
"""Pre-blurred depth-of-field variants for the interaction prototype.

This is the asset-pipeline step that the interaction spec recommends instead of
live blur: every world plate, vignette, and character gets two baked variants,
so depth of field at runtime is an opacity cross-fade between stacked images.

  soft  (.b1): Gaussian sigma 1.4 world units, stored at 1/2 resolution
  deep  (.b2): Gaussian sigma 4.0 world units, stored at 1/3 resolution

A world unit is a point at camera scale 1. Each source is padded by 3 sigma on
every side (blur bleeds outside the alpha), and the padding is written to
assets/blur-manifest.json as a fraction of the source size, so the page can
grow the blurred image's box by the same amount.

  python3 -I tools/preblur.py            (run from design/prototypes/interactions)

`app` mode builds the app's world art for `PofuWorld` with the same blur: it trims each master,
caps its resolution, bakes the soft and deep variants, cuts the home plate into depth bands, and
writes an Xcode asset catalog plus a generated Swift table of every image's box in world units,
each standing sprite's ground footprint and the plate's walkable polygon (needs scipy). Each master's
harmony correction (design/art/harmony/assets/*.json, tools/assets/harmony.py) is baked in first.

  python3 -I design/prototypes/interactions/tools/preblur.py app   (from anywhere)
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(os.path.dirname(HERE), "assets")

# Source name -> width of its box in world units (from the page's BOX table).
UNITS = {
    "isle-home": 364, "isle-harbor": 268, "isle-stars": 244, "isle-hamam": 256, "isle-library": 244,
    "st-cay-2": 120, "st-cay-3": 120, "st-garden-3": 120, "st-garden-4": 120, "st-pond-2": 120,
    "st-windmill-2": 120, "st-workshop-2": 120,
    "neighbor-bunny": 27, "res-hog": 28, "pofu": 64, "cloud-a": 80, "cloud-b": 120,
}
# The home island plate is cut into depth bands (world y), so depth of field can vary across it.
# Each band keeps the full canvas; its alpha is the plate's alpha times a band mask. A band is
# opaque through the overlap with the band in front of it, and the front band fades in over it,
# so stacked back to front the bands recompose the plate without a seam.
PLATE = "isle-home"
PLATE_BOX_TOP, PLATE_BOX_H = -106.0, 288.0  # world units (BOX in app.js)
BANDS = [(-1e9, -50), (-50, 0), (0, 50), (50, 1e9)]
FEATHER = 10.0
LEVELS = {"b1": (1.4, 2), "b2": (4.0, 3), "b3": (9.0, 4)}  # name -> (sigma in world units, downscale); b3 feeds tilt-shift only


def blur_variant(src, sigma_px, down):
    pad = int(math.ceil(3 * sigma_px))
    big = Image.new("RGBA", (src.width + 2 * pad, src.height + 2 * pad), (0, 0, 0, 0))
    big.paste(src, (pad, pad))
    # Blur premultiplied colour so transparent edges do not bleed dark fringes.
    a = np.asarray(big, dtype=np.float32) / 255.0
    pre = a.copy()
    pre[..., :3] *= pre[..., 3:4]
    blurred = []
    for i in range(4):
        ch = Image.fromarray(np.uint8(np.clip(pre[..., i] * 255.0 + 0.5, 0, 255)), "L")
        blurred.append(np.asarray(ch.filter(ImageFilter.GaussianBlur(sigma_px)), dtype=np.float32) / 255.0)
    rgb = np.stack(blurred[:3], -1)
    alpha = blurred[3][..., None]
    rgb = np.where(alpha > 1e-4, rgb / np.maximum(alpha, 1e-4), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], -1)
    img = Image.fromarray(np.uint8(out * 255.0 + 0.5), "RGBA")
    w, h = max(1, round(img.width / down)), max(1, round(img.height / down))
    return img.resize((w, h), Image.LANCZOS), pad


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


# Atmospheric perspective, baked: lighter, cooler, less saturated with distance. Amount per source
# from its placement depth (the diorama's y; larger is nearer): clamp((40 - depth) / 220) * 0.38,
# and a flat 0.3 for the distant islands. Baked for every blur level, so runtime haze costs nothing.
HAZE_RGB = np.array([220, 235, 245], dtype=np.float32)
HAZE_DEPTH = {"st-windmill-2": -74, "st-workshop-2": -70, "st-garden-3": -4, "st-garden-4": -4, "st-cay-2": -2,
              "st-cay-3": -2, "st-pond-2": 18, "isle-home-band0": -78, "isle-home-band1": -25, "isle-home-band2": 25}
HAZE_FLAT = {"isle-harbor": 0.3, "isle-stars": 0.3, "isle-hamam": 0.3, "isle-library": 0.3}


def make_haze():
    amounts = {k: float(np.clip((40 - d) / 220, 0, 1) * 0.38) for k, d in HAZE_DEPTH.items()}
    amounts.update(HAZE_FLAT)
    for name, amt in amounts.items():
        for lvl in ("", "b1", "b2", "b3"):
            suffix = f".{lvl}" if lvl else ""
            a = np.asarray(Image.open(os.path.join(ASSETS, name + suffix + ".webp")).convert("RGBA"), dtype=np.float32)
            rgb = a[..., :3]
            grey = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
            rgb = rgb + (grey[..., None] - rgb) * (amt * 0.6)  # desaturate
            rgb = rgb + (HAZE_RGB - rgb) * amt  # lighten and cool toward the sky
            out = np.concatenate([np.clip(rgb, 0, 255), a[..., 3:]], -1)
            Image.fromarray(np.uint8(out + 0.5), "RGBA").save(os.path.join(ASSETS, f"{name}.hz{suffix}.webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"haze {name}: {amt:.2f}")
    return amounts


def make_bands(manifest):
    pads = manifest[PLATE]
    crops = {}
    for lvl in ("", "b1", "b2", "b3"):
        src = Image.open(os.path.join(ASSETS, PLATE + (f".{lvl}" if lvl else "") + ".webp")).convert("RGBA")
        a = np.asarray(src, dtype=np.float32)
        py = pads[lvl][1] if lvl else 0.0
        top = PLATE_BOX_TOP - py * PLATE_BOX_H
        span = PLATE_BOX_H * (1 + 2 * py)
        y = top + (np.arange(a.shape[0]) + 0.5) / a.shape[0] * span  # world y of each row
        for k, (s0, s1) in enumerate(BANDS):
            w = np.ones_like(y) if k == 0 else smoothstep(s0 - FEATHER, s0 + FEATHER, y)
            if s1 < 1e8:
                w = np.where(y <= s1 + FEATHER, w, 0.0)
            out = a.copy()
            out[..., 3] *= w[:, None]
            # Crop to the band's opaque rows (most of the canvas is empty), and record the crop as a
            # fraction of the image height so the page can place it: no overdraw of empty pixels.
            rows = np.where(out[..., 3].max(axis=1) > 0.5)[0]
            r0, r1 = int(rows[0]), int(rows[-1]) + 1
            crops.setdefault(f"{PLATE}-band{k}", {})[lvl or "s"] = [round(r0 / a.shape[0], 5), round(r1 / a.shape[0], 5)]
            name = f"{PLATE}-band{k}" + (f".{lvl}" if lvl else "")
            Image.fromarray(np.uint8(np.clip(out[r0:r1], 0, 255) + 0.5), "RGBA").save(os.path.join(ASSETS, name + ".webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"bands for {PLATE}{'.' + lvl if lvl else ''}")
    for k in range(len(BANDS)):
        manifest[f"{PLATE}-band{k}"] = dict(pads, crop=crops[f"{PLATE}-band{k}"])


def main():
    manifest = {}
    for name, units in UNITS.items():
        path = os.path.join(ASSETS, name + ".webp")
        if not os.path.exists(path):
            print("missing", path, file=sys.stderr)
            return 1
        src = Image.open(path).convert("RGBA")
        ppu = src.width / units
        entry = {}
        for lvl, (sigma_u, down) in LEVELS.items():
            img, pad = blur_variant(src, sigma_u * ppu, down)
            img.save(os.path.join(ASSETS, f"{name}.{lvl}.webp"), "WEBP", quality=72, method=6)
            entry[lvl] = [round(pad / src.width, 4), round(pad / src.height, 4)]
        manifest[name] = entry
        print(f"{name}: {src.width}x{src.height}, {ppu:.2f} px/unit, pads {entry}")
    make_bands(manifest)
    manifest["_haze"] = {k: round(v, 3) for k, v in make_haze().items()}
    with open(os.path.join(ASSETS, "blur-manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    return 0


# ------------------------------------------------------------------ app mode (PofuWorld)
#
# World units are points at camera scale 1 (game design §15). Each source names its anchor (the
# feet or the footprint centre) in source pixels and its scale in pixels per world unit. The app
# never shows a world image above camera scale 2.4 at 3x, so the sharp image is capped at
# APP_MAX_PPU pixels per unit; masters are never upscaled.

REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
APP_RESOURCES = os.path.join(REPO, "Packages", "PofuKit", "Sources", "PofuWorld", "Resources")
APP_CATALOG = os.path.join(APP_RESOURCES, "World.xcassets")
APP_SWIFT = os.path.join(REPO, "Packages", "PofuKit", "Sources", "PofuWorld", "Geometry", "WorldArt+Generated.swift")
APP_MAX_PPU = 7.5
SWIFT_PART = 30  # sprites per literal in WorldArt+Generated.swift
# Stations are seen at most at the build push-in (x1.95 at 3x, 5.9 px per unit); capping them lower
# than the characters keeps the catalog small now that every level ships.
STATION_MAX_PPU = 6.0
APP_LEVELS = {"soft": (1.4, 2), "deep": (4.0, 3)}  # suffix -> (sigma in world units, downscale)
PROTO = os.path.join("design", "prototypes", "interactions", "assets")
ART = os.path.join("design", "art")


def _master(folder):
    """A master folder's image: the lock-light re-lock when one was adopted (relock.py), else the
    master itself. harmony.py reads the same order."""
    name = os.path.basename(folder)
    for candidate in (f"{name}--lock-light.png", f"{name}.png", f"{name}.webp"):
        if os.path.exists(os.path.join(REPO, folder, candidate)):
            return os.path.join(folder, candidate)
    raise FileNotFoundError(folder)


def _station(level_name, group="stations", max_ppu=None):
    """A station level master on the station guide: 1024 px for 120 units, the footprint centre at
    (512, 800). A re-lock with --pad grows the canvas evenly, so the anchor moves with it. `group` is
    the art folder (decor pieces live in masters/ but are drawn on the same guide)."""
    src = _master(os.path.join(ART, group, level_name))
    with Image.open(os.path.join(REPO, src)) as im:
        pad = (im.width - 1024) // 2
    return {"src": src, "ppu": 1024 / 120, "anchor": (512 + pad, 800 + pad), "max_ppu": max_ppu or STATION_MAX_PPU}


def _isle(name, box):
    # The prototype's island stand-ins for the map, with their BOX from app.js.
    return {"src": os.path.join(PROTO, name + ".webp"), "units": box[2] - box[0], "anchor_box": box}


def _blob(folder, width_units, anchor, like=None):
    """A master whose opaque box is `width_units` wide in the world, anchored at the box's centre or
    at its feet (bottom centre). `like` takes the scale and anchor from another master on the same
    canvas (a pose of the same character)."""
    ref = like or folder
    with Image.open(os.path.join(REPO, _master(ref))) as im:
        box = im.getchannel("A").point(lambda v: 255 if v > 2 else 0).getbbox()
    ppu = (box[2] - box[0]) / width_units
    cx = (box[0] + box[2]) / 2
    cy = (box[1] + box[3]) / 2 if anchor == "centre" else box[3]
    return {"src": _master(folder), "ppu": ppu, "anchor": (cx, cy)}


def _sky(folder, width_pt, anchor="centre"):
    """A sky element drawn in screen space (far isles, clouds, the cloud sea): one image `width_pt`
    points wide at most, stored at 3 px per point, never blurred (it is far and soft already)."""
    src = _master(os.path.join(ART, "masters", folder))
    with Image.open(os.path.join(REPO, src)) as im:
        box = im.getchannel("A").point(lambda v: 255 if v > 2 else 0).getbbox()
    w = box[2] - box[0]
    return {"src": src, "ppu": w / width_pt, "anchor": ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), "sky": True, "max_ppu": 3.0}


# The home plate. Each master's lawn is measured once (its top surface as an ellipse in pixels:
# centre x, centre y, radius x, radius y, from the plate drawn on a grid) and given a width in world
# units; the anchor is the lawn's centre, so the world origin stays the middle of the lawn whatever
# the plate. Swap APP_PLATE_MASTER to change plates (island-main-l-v3 when batch 05 lands: measure
# its lawn and add it here); the walkable polygon, the depth bands and the door's window follow.
#
# island-main-l-v2 is drawn 40 % wider than island-main-s. At 480 units its lawn holds the five
# home stations at every level, Pofu, Mochi and Findik with no footprint overlapping another or
# the rim (look round 3; the small plate held at most four). Its lawn is 0.18 as deep as wide, so
# depth, not width, is what limits the layout.
PLATES = {
    "island-main-s": {"folder": "design/art/masters/island-main-s", "ppu": 1436 / 350, "anchor": (768, 441),
                      "walkable": {"inset": 6.0}, "lawn_radius": (175.0, 43.6), "window": (492, 670),
                      "softlock": "design/art/masters/island-main-s/island-main-s.png"},
    "island-main-l-v2": {"folder": "design/art/masters/island-main-l-v2", "lawn": (767.0, 415.0, 742.0, 135.0),
                         "units": 480.0, "window": (439, 660)},
    # Batch 05: the same lawn over a deeper earth body (the founder found v2 too squashed).
    "island-main-l-v3": {"folder": "design/art/masters/island-main-l-v3", "lawn": (767.0, 415.0, 742.0, 135.0),
                         "units": 480.0, "window": (437, 563)},
    # Batch 60: l-v3 edited, its outline identical (IslandFootprintTests), with the residents' round doors
    # painted into the earth: Mochi's rose door from island level 2, Findik's sage door from level 6.
    "island-main-face-il2": {"folder": "design/art/masters/island-main-face-il2", "lawn": (767.0, 415.0, 742.0, 135.0),
                             "units": 480.0, "window": (437, 563)},
    "island-main-face-il6": {"folder": "design/art/masters/island-main-face-il6", "lawn": (767.0, 415.0, 742.0, 135.0),
                             "units": 480.0, "window": (437, 563)},
}
APP_PLATE_MASTER = "island-main-l-v3"
FACE_PLATES = ("island-main-face-il2", "island-main-face-il6")


def _plate(key):
    p = PLATES[key]
    spec = {"src": _master(p["folder"]), "plate": key, "window": p["window"]}
    if "lawn" in p:
        cx, cy, rx, ry = p["lawn"]
        ppu = 2 * rx / p["units"]
        spec.update(ppu=ppu, anchor=(cx, cy), walkable={"ellipse": (rx / ppu, ry / ppu), "inset": 6.0},
                    lawn_radius=(rx / ppu, ry / ppu))
    else:
        spec.update(ppu=p["ppu"], anchor=p["anchor"], walkable=p["walkable"], lawn_radius=p["lawn_radius"])
    if p.get("softlock"):
        spec["softlock"] = p["softlock"]
    return spec


# The home island's station chains: every level the art queue has generated (a level without art
# shows the highest one below it, with a level badge).
# workshop-2 (batch 05) is left out: it was edited from workshop-1's master, which lost the left of
# its roof to the registration shift, so the edit is cut too; regenerate it from the padded re-lock.
STATION_LEVELS = {"tea-stall": 5, "garden": 5, "pond": 5, "windmill": 5, "workshop": 1}
# The harbor's levels (batches 01, 05 and 21): the bagel cart 1-5, the first pier and lighthouse. The
# harbor is seen from the map and the island framing, never focused, so its art is capped lower.
HARBOR_LEVELS = {"bagel-cart": 5, "pier": 1, "lighthouse": 1}
HARBOR_MAX_PPU = 4.0
# The harbor plate is 268 units wide (the home plate 480), so its stations are drawn at 0.7 of the
# guide's size to leave a lawn for Simit and the goat.
HARBOR_SIZE = 0.7
# The harbor's dressing, drawn on the station guide: (art folder, size in the world as a fraction of the
# guide's; the plate is 268 units wide, so a prop is a third of a station, a ferry two thirds). The
# ferry, the horn, the lamp and the crates are in stations/; the bench is a decor piece in masters/.
HARBOR_PROPS = {"harbor-ferry-1": ("stations", 0.75), "harbor-horn-1": ("stations", 0.5),
                "harbor-lamp-1": ("stations", 0.5), "harbor-crates-1": ("stations", 0.45),
                "decor-bench": ("masters", 1.0), "harbor-bell": ("masters", 0.6)}

# The meadow dressing sheet (`dressing-meadow`, 1536 x 1024: twelve separate pieces on a transparent
# canvas). Each piece is cut out of its own cell (source pixels x0, y0, x1, y1: the piece's opaque box
# padded by 6, so no neighbour's pixels come along; `tools/assets/test_integrate.py` holds that rule)
# and stands on its bottom centre. All twelve share one scale, so their painted sizes stay in
# proportion (a tuft 17 units wide, the toadstool ring 29).
MEADOW_SHEET = os.path.join(ART, "masters", "dressing-meadow")
MEADOW_PPU = 10.0
MEADOW_CELLS = {
    "dressing-grass-tuft": (122, 193, 308, 321),
    "dressing-grass-tuft-2": (443, 97, 690, 322),
    "dressing-grass-tuft-3": (821, 73, 1054, 324),
    "dressing-grass-tuft-4": (1159, 129, 1414, 327),
    "dressing-wildflowers": (79, 406, 336, 655),
    "dressing-wildflowers-2": (423, 403, 709, 656),
    "dressing-wildflowers-3": (782, 407, 1060, 656),
    "dressing-wildflowers-4": (1183, 349, 1397, 659),
    "dressing-pebbles": (83, 757, 330, 934),
    "dressing-pebbles-2": (428, 787, 685, 916),
    "dressing-pebbles-3": (1140, 750, 1460, 917),
    "dressing-mushroom-ring": (757, 709, 1059, 936),
}


def _sheet_cell(sheet, ppu, harmony_as, cell, anchor=None, **extra):
    """One piece of a sheet: the master, the cell to cut and the piece's anchor (default: the bottom
    centre, 6 px above the cell's edge). `flip` mirrors the cut, `alpha_floor` clears the faint halation
    a generator leaves between pieces."""
    x0, y0, x1, y1 = cell
    return {"src": _master(sheet), "cell": cell, "ppu": ppu,
            "anchor": anchor or ((x0 + x1) / 2, y1 - 6), "max_ppu": STATION_MAX_PPU, "harmony_as": harmony_as,
            # A sheet is measured once, whole (harmony.py), not once per piece.
            "harmony": False, **extra}


def _cell(name, cell):
    """One piece of the meadow sheet: the master, the cell to cut and the piece's bottom centre."""
    return _sheet_cell(MEADOW_SHEET, MEADOW_PPU, "dressing-meadow", cell)


# The garden's and the harbor's dressing sheets (`dressing-garden`, `dressing-harbor`: ten pieces each on
# a transparent 1536 x 1024 canvas, two rows of five). Only the pieces the lawn wears are cut; the rest
# wait for a slot (the pot, bucket, gloves and rake; the buoy, net, oar, lantern, bollard, trays and
# pail). One scale per sheet, 13 source px per unit: the watering can is 24 units wide, a crate 20.
GARDEN_SHEET = os.path.join(ART, "masters", "dressing-garden")
HARBOR_SHEET = os.path.join(ART, "masters", "dressing-harbor")
DRESSING_PPU = 13.0
GARDEN_CELLS = {
    "dressing-watering-can": (27, 192, 348, 442),
    "dressing-seed-sack": (353, 186, 616, 448),
    "dressing-twine": (653, 242, 869, 452),
    "dressing-crate": (929, 221, 1198, 434),
    "dressing-crate-2": (1236, 170, 1502, 445),
    "dressing-trowel": (60, 577, 292, 876),
}
HARBOR_CELLS = {
    "dressing-rope": (46, 279, 307, 493),
    "dressing-barrel": (40, 593, 299, 889),
}

# The critters' pose sheets (`critter-butterfly`, `-snail`, `-bird`): one row of frames each, one scale per
# sheet and one baseline (every cell's bottom edge is the same line, 6 px under the feet), so the frames
# swap in place. The butterflies and the first two bird frames face left on the sheet; they are mirrored
# so that every critter sprite faces right and `CritterView` flips by the pose. Frame 1 of each is the
# rest pose (the snail's sheet is cut middle, right, left, so its extended pose is the rest); the butterfly's fifth frame (wings closed again) repeats the first and is not cut.
CRITTER_BUTTERFLY_SHEET = os.path.join(ART, "masters", "critter-butterfly")
CRITTER_SNAIL_SHEET = os.path.join(ART, "masters", "critter-snail")
CRITTER_BIRD_SHEET = os.path.join(ART, "masters", "critter-bird")
CRITTER_PPU = {"butterfly": 16.0, "snail": 26.0, "bird": 17.0}
BUTTERFLY_CELLS = [(76, 407, 266, 634), (349, 443, 582, 634), (611, 476, 918, 634), (961, 476, 1219, 634)]
SNAIL_CELLS = [(548, 404, 943, 688), (1077, 378, 1438, 688), (81, 419, 393, 688)]
BIRD_CELLS = [(66, 411, 326, 653), (407, 398, 711, 653), (790, 384, 1092, 653), (1174, 411, 1487, 653)]
CRITTER_CELLS = {
    **{f"critter-butterfly{'' if i == 0 else f'-{i + 1}'}": (CRITTER_BUTTERFLY_SHEET, "butterfly", c, True)
       for i, c in enumerate(BUTTERFLY_CELLS)},
    **{f"critter-snail{'' if i == 0 else f'-{i + 1}'}": (CRITTER_SNAIL_SHEET, "snail", c, False)
       for i, c in enumerate(SNAIL_CELLS)},
    **{f"critter-bird{'' if i == 0 else f'-{i + 1}'}": (CRITTER_BIRD_SHEET, "bird", c, i < 2)
       for i, c in enumerate(BIRD_CELLS)},
}
CRITTER_ALPHA_FLOOR = 24


def _fixed(folder, ppu, anchor="centre"):
    """A master drawn at a stated scale (the doors: one scale for the whole family), anchored at the
    centre or the feet of its opaque box."""
    with Image.open(os.path.join(REPO, _master(folder))) as im:
        box = im.getchannel("A").point(lambda v: 255 if v > 2 else 0).getbbox()
    cx = (box[0] + box[2]) / 2
    cy = (box[1] + box[3]) / 2 if anchor == "centre" else box[3]
    return {"src": _master(folder), "ppu": ppu, "anchor": (cx, cy), "max_ppu": STATION_MAX_PPU}


# The doors in the earth face (home layout H2, H3): the plate's own round door is 37 units across its
# frame; the painted frames here measure 490 px, so 13.2 px per unit matches it. One scale for the family.
DOOR_PPU = 13.2
# The hive ladder (home layout S6): drawn on the station guide at 0.85 of its size, so hive-1's two
# skeps and lavender are 36 units wide (the layout's "+-18").
HIVE_SIZE = 0.85
# The path lamp (home layout L1-L3, batch 33): drawn on the decor guide at 0.8 of its size, a lamp 37 units tall.
LAMP_SIZE = 0.8
HIVE_LEVELS = 3

KOKE_PLATES = (0, 1, 2, 3, 4)
KOKE_PLATE_UNITS = 250.0
KOKE_WIDTH = 114.0
# Çağlayan (batch 43): the plates are 768 x 512 like Koke's, but the island fills only 720 of their 768 px, so
# the image is drawn wider (226 units) to put the island itself 212 units across, as Koke's is. The island
# is cut with a shared hand-traced matte (tools/assets/caglayan_matte.py), not the colour rule: its lilac cliff
# and pale underside sit too close to the sky. Damla is 38 units wide, feet on the anchor.
CAGLAYAN_PLATES = (0, 1, 2, 3, 4)
CAGLAYAN_PLATE_UNITS = 768 * 212 / 720
CAGLAYAN_MATTE = "design/art/masters/caglayan-island-0/caglayan-matte.png"
CAGLAYAN_DAMLA_WIDTH = 38.0

APP_SOURCES = {
    # The app draws the lock-light bakes (WorldGrade grades them at runtime); "softlock" also bakes a
    # soft-lock master as <name>--softlock to compare (WorldLook.ArtSet), for tea-stall-1 only now.
    "island-main": _plate(APP_PLATE_MASTER),
    # The earth-face plates (batch 60): the same lawn and bands, graded and harmonised like the main plate.
    **{key: {**_plate(key), "harmony_as": "island-main", "face_plate": True} for key in FACE_PLATES},
    **{f"{st}-{lvl}": _station(f"{st}-{lvl}") for st, n in STATION_LEVELS.items() for lvl in range(1, n + 1)},
    **{f"{st}-{lvl}": {**_station(f"{st}-{lvl}", max_ppu=HARBOR_MAX_PPU), "ppu": 1024 / 120 / HARBOR_SIZE}
       for st, n in HARBOR_LEVELS.items() for lvl in range(1, n + 1)},
    **{name: {**_station(name, group, HARBOR_MAX_PPU), "ppu": 1024 / 120 / size} for name, (group, size) in HARBOR_PROPS.items()},
    # Characters: Mochi v2 (batch 03) and Findik (batch 03), 30 and 28 units wide, feet on the anchor.
    "mochi": {"src": "design/art/masters/mochi-v2/mochi-v2.webp", "ppu": 901 / 30, "anchor": (515.5, 1349)},
    "findik": {"src": "design/art/masters/findik-base/findik-base.webp", "ppu": 769 / 28, "anchor": (434.5, 1170)},
    # Their poses: edits of the same canvases, so they share the base's scale and feet and swap in place.
    # (Mochi's are on her canvas; Findik's eye poses were drawn on a larger one, matched by width.)
    **{f"mochi-{pose}": {"src": f"design/art/masters/mochi-{pose}/mochi-{pose}.webp", "ppu": 901 / 30, "anchor": (515.5, 1349)}
       for pose in ("work", "surprised", "eyes-closed", "eyes-happy")},
    "findik-work": {"src": "design/art/masters/findik-work/findik-work.webp", "ppu": 769 / 28, "anchor": (434.5, 1170)},
    "findik-eyes-closed": _blob("design/art/masters/findik-eyes-closed", 28.33, "feet"),
    "findik-eyes-happy": _blob("design/art/masters/findik-eyes-happy", 28.33, "feet"),
    # The reactions (batches 29 and 41): the same canvases as the bases, so they swap in place. Mochi's and
    # Findik's on their bases' scale and feet; the goat's and Simit's by their base's box.
    **{f"mochi-{pose}": {"src": f"design/art/masters/mochi-{pose}/mochi-{pose}.webp", "ppu": 901 / 30, "anchor": (515.5, 1349)}
       for pose in ("happy", "sleepy", "proud")},
    **{f"findik-{pose}": {"src": f"design/art/masters/findik-{pose}/findik-{pose}.webp", "ppu": 769 / 28, "anchor": (434.5, 1170)}
       for pose in ("happy", "sleepy", "proud", "surprised")},
    # Pofu's own art: only the blurred variants (the live CompanionView is the sharp one). 64 units
    # wide with the feet at the rig's ground point, so the variants register with the live view.
    "pofu": {"src": "Packages/PofuKit/Sources/PofuCompanion/Resources/pofu-hamster.png", "ppu": 522 / 64, "anchor": (266, 481), "no_sharp": True},
    # The other islands on the map: the prototype's stand-ins until their islands are generated.
    "isle-harbor-standin": _isle("isle-harbor", (-134, -106.4, 134, 125.44)),
    "isle-stars-standin": _isle("isle-stars", (-122, -95, 122, 112)),
    "isle-hamam-standin": _isle("isle-hamam", (-128, -100.7, 128, 118.72)),
    "isle-library-standin": _isle("isle-library", (-122, -95, 122, 112)),
    # The harbor (vertical slice): the real plate, 268 units wide (centred on its pixels), the goat on
    # its dock and Simit at the bagel cart. Simit's three poses share one canvas, so they share the
    # base pose's scale and feet and stay registered. Keys match the harmony manifest.
    "harbor-island-s": _blob("design/art/masters/harbor-island-s", 268, "centre"),
    # Koke (batch 39): the plates were delivered at half scale (768 x 512 for 1536 x 1024), drawn 250 units
    # wide with their centre on the island's centre, cut from their own sky by each stage's committed matte
    # (tools/assets/koke_matte.py; the colour rule `matte` let warm sky and petals in). The poses share one
    # scale and one baseline (feet on the anchor); Koke is 114 units wide on the lawn.
    **{f"koke-island-{n}": {"src": _master(f"design/art/masters/koke-island-{n}"), "ppu": 768 / KOKE_PLATE_UNITS,
                            "anchor": (384, 256), "matte_file": f"design/art/masters/koke-island-{n}/koke-matte.png"}
       for n in KOKE_PLATES},
    **{f"koke-{pose}": _blob(f"design/art/masters/koke-{pose}", KOKE_WIDTH, "feet", like="design/art/masters/koke-asleep")
       for pose in ("asleep", "one-eye", "stretch")},
    **{f"caglayan-island-{n}": {"src": _master(f"design/art/masters/caglayan-island-{n}"), "ppu": 768 / CAGLAYAN_PLATE_UNITS,
                                "anchor": (384, 256), "matte_file": CAGLAYAN_MATTE} for n in CAGLAYAN_PLATES},
    "damla": _blob("design/art/masters/damla", CAGLAYAN_DAMLA_WIDTH, "feet"),
    "damla-glass": _blob("design/art/masters/damla-glass", CAGLAYAN_DAMLA_WIDTH, "feet", like="design/art/masters/damla"),
    # Nazli's rig (batch 37): body, eyes-closed, fins, tail and island patch share one 1536 x 1024 canvas, so
    # every part takes the body's scale and anchor (the box centre) and the layers stay registered. 150 units
    # is a provisional width (no scene draws her yet); the pieces are baked, not placed.
    **{f"nazli-{part}": _blob(f"design/art/masters/nazli-{part}", 150.0, "centre", like="design/art/masters/nazli-body")
       for part in ("body", "eyes-closed", "fins", "tail", "island-patch")},
    "harbor-goat": _blob("design/art/masters/harbor-goat", 34, "feet"),
    # The plate's living layer (batch 78, tools/art/plate_life_masters.py): the visitors, the parcel, Koke's moss
    # and Çağlayan's fountain, each cut from its picked take by script. Feet (or the ripple's centre) on the
    # anchor. On the plate a unit is about 1.5 px (Pofu's 64 units are 83 px, residents 1.15 times that), so Damla is about 50 px
    # wide, the parcel 32 and the moss 70 (batch 78's reviews asked for these sizes); the whale is flatter and wider.
    "visitor-damla": _blob("design/art/masters/visitor-damla", 34, "feet"),
    "visitor-gezgin": _blob("design/art/masters/visitor-gezgin", 40, "feet"),
    "guest-letter": _blob("design/art/masters/guest-letter-envelope", 24, "feet"),
    "gift-parcel": _blob("design/art/masters/gift-parcel-closed", 21, "feet"),
    "gift-moss": _blob("design/art/masters/material-moss-lawn", 54, "feet"),
    "gift-fountain": _blob("design/art/masters/home-fountain", 42, "feet"),
    "simit-kitten": _blob("design/art/masters/simit-kitten", 26, "feet"),
    "simit-kitten-work": _blob("design/art/masters/simit-kitten-work", 26, "feet", like="design/art/masters/simit-kitten"),
    "simit-kitten-ears": _blob("design/art/masters/simit-kitten-ears", 26, "feet", like="design/art/masters/simit-kitten"),
    "simit-happy": _blob("design/art/masters/simit-happy", 26, "feet", like="design/art/masters/simit-kitten"),
    "simit-sleepy": _blob("design/art/masters/simit-sleepy", 26, "feet", like="design/art/masters/simit-kitten"),
    "simit-surprised": _blob("design/art/masters/simit-surprised", 26, "feet", like="design/art/masters/simit-kitten"),
    # The goat at work, holding a coil of coral rope: an edit of the goat on its canvas.
    "goat-work": _blob("design/art/masters/goat-work", 34, "feet", like="design/art/masters/harbor-goat"),
    **{f"goat-{pose}": _blob(f"design/art/masters/goat-{pose}", 34, "feet", like="design/art/masters/harbor-goat")
       for pose in ("happy", "surprised", "sleepy", "proud")},
    # Walk and work frames (batch 59): step-a, step-b and the work beat, edits on the bases' canvases.
    **{f"mochi-{pose}": {"src": f"design/art/masters/mochi-{pose}/mochi-{pose}.webp", "ppu": 901 / 30, "anchor": (515.5, 1349)}
       for pose in ("step-a", "step-b", "work-beat")},
    **{f"goat-{pose}": _blob(f"design/art/masters/goat-{pose}", 34, "feet", like="design/art/masters/harbor-goat")
       for pose in ("step-a", "step-b", "work-beat")},
    "simit-step-b": _blob("design/art/masters/simit-step-b", 26, "feet", like="design/art/masters/simit-kitten"),
    "simit-proud": _blob("design/art/masters/simit-proud", 26, "feet", like="design/art/masters/simit-kitten"),
    # The second L3 style option of the stations that have one so far (batch 40, home progression 4.2):
    # on the harbor guide at the harbor's size, like their first options.
    **{name: {**_station(name, max_ppu=HARBOR_MAX_PPU), "ppu": 1024 / 120 / HARBOR_SIZE}
       for name in ("bagel-cart-3-blue", "lighthouse-3-blue", "lighthouse-4-blue")},
    # The home island's fixtures: the doors in the earth face and the hive ladder.
    # The pasted door sprites are retired from the home draw: the doors are painted into the earth-face plates.
    "koke-stone": _blob("design/art/masters/koke-stone", 27, "feet"),
    **{f"hive-{lvl}": {**_station(f"hive-{lvl}"), "ppu": 1024 / 120 / HIVE_SIZE} for lvl in range(1, HIVE_LEVELS + 1)},
    # The meadow's lawn dressing, cut from its sheet.
    **{name: _cell(name, cell) for name, cell in MEADOW_CELLS.items()},
    # The garden's and the harbor's dressing, and the critters' frames, cut from their sheets.
    **{name: _sheet_cell(GARDEN_SHEET, DRESSING_PPU, "dressing-garden", cell) for name, cell in GARDEN_CELLS.items()},
    **{name: _sheet_cell(HARBOR_SHEET, DRESSING_PPU, "dressing-harbor", cell) for name, cell in HARBOR_CELLS.items()},
    **{name: _sheet_cell(sheet, CRITTER_PPU[kind], sheet.rsplit("/", 1)[-1], cell, flip=flip, alpha_floor=CRITTER_ALPHA_FLOOR)
       for name, (sheet, kind, cell, flip) in CRITTER_CELLS.items()},
    # The sky (batch 04), in screen points: far isles in the haze, clouds and the cloud sea.
    "far-isle-1": _sky("far-isle-1", 300),
    "far-isle-2": _sky("far-isle-2", 160),
    "far-isle-3": _sky("far-isle-3", 260),
    "cloud-2": _sky("cloud-2", 200),
    "cloud-4": _sky("cloud-4", 260),
    "cloud-sea": _sky("cloud-sea", 520),
}
APP_SOURCES["tea-stall-1"]["softlock"] = "design/art/stations/tea-stall-1/tea-stall-1.png"
# Night overlays of practical lights (look round 4): the batch-07 "lit" edit of a station, reduced to
# what the light changed (its flame), drawn after the grade at night so it is never crushed by it.
# Not a harmony source: it is light, not paint.
APP_SOURCES["tea-stall-1-glow"] = {**_station("tea-stall-1-lit"), "emissive_of": (345, 570, 430, 635), "single": True, "harmony": False}
# The other lit edits, the same way (regions in source pixels, read off each lit master on its guide):
# the workshop's doorway, the pond's three floating lanterns and the windmill's two round windows.
for _glow, _lit, _region in (("workshop-1-glow", "workshop-1-lit", (150, 575, 320, 805)),
                             ("pond-5-glow", "pond-5-lit", (365, 620, 620, 800)),
                             ("windmill-5-glow", "windmill-5-lit", (355, 570, 600, 628))):
    APP_SOURCES[_glow] = {**_station(_lit), "emissive_of": _region, "single": True, "harmony": False}
# The masked lit edits (batch 36): each is its day master with only the glass changed, so the glow is
# the difference against that master inside the edit's `emit_region` (padded a little), not a colour key.
# Their scale and anchor are the day master's: the harbor's lighthouse at the harbor's 0.7, the path lamp
# at LAMP_SIZE, Mochi's door at the doors' scale.
APP_SOURCES["path-lamp"] = {**_station("path-lamp", "masters"), "ppu": 1024 / 120 / LAMP_SIZE}
for _glow, _spec, _parent, _region in (
        ("lighthouse-1-glow", {**_station("lighthouse-1-lit", max_ppu=HARBOR_MAX_PPU), "ppu": 1024 / 120 / HARBOR_SIZE},
         "design/art/stations/lighthouse-1", (380, 278, 655, 404)),
        ("path-lamp-glow", {**_station("path-lamp-lit", "masters"), "ppu": 1024 / 120 / LAMP_SIZE},
         "design/art/masters/path-lamp", (468, 580, 617, 712)),
        ("door-mochi-glow", _fixed("design/art/masters/door-mochi-lit", DOOR_PPU),
         "design/art/masters/door-mochi", (402, 432, 608, 643))):
    APP_SOURCES[_glow] = {**_spec, "emissive_of": _region, "emissive_parent": _parent, "single": True, "harmony": False}
# The plates to compare (look round 4: the founder chooses between v2 and v3), baked as
# island-main-band<k>--v2 with v2's own harmony correction.
PLATE_COMPARE = {"--v2": "island-main-l-v2"}
# Look round 2's warm copper (the çaydanlık's hue moved from 54 to 59), kept only to compare in the
# teapot sheet: the colour script (look round 3) keeps the rose copper as an accent instead.
ROUND2_COPPER = {"tea-stall-1": {"rose-copper": {"hue_shift": 6.97, "chroma_scale": 1.09}}}
# The uncorrected bake is kept to compare only where it tells a story; every other sprite ships
# corrected only (the catalog would double otherwise).
UNHARMONIZED_COMPARE = {"island-main", "tea-stall-3", "windmill-4"}
# The home plate's depth bands in world y (larger is nearer): back lawn, middle lawn, front lawn
# and lip, earth body, cut at these fractions of the lawn's half depth. Their depths are generated
# into WorldArt.generatedPlate.
APP_PLATE = "island-main"
BAND_CUTS = (-0.32, 0.32, 1.0)
BAND_CENTRES = (-0.64, 0.0, 0.66, 1.38)
# Containment (look round 2): every object stands inside the plate's walkable footprint. The
# walkable polygon is the plate's lawn eroded by "inset" world units, so nothing stands on the grass
# lip or hangs over the rim: either its largest green region ("inset" alone), or an authored ellipse
# ("ellipse": [rx, ry] in world units; the pale lawn of the large plate defeats the green mask), or
# an authored "polygon": [[x, y], ...] in world units. A sprite's footprint is the convex hull
# of its opaque pixels within the bottom FOOT_DEPTH x (base width) of the image: the ground ellipse
# of an object seen from about 20 degrees, matching the station guide (rx 360, ry 108 px).
WALK_ROWS = 20
FOOT_DEPTH = 0.30
FOOT_MAX_POINTS = 16
APP_FEATHER = 8.0


def _alpha_floor(img, floor):
    """Alpha below `floor` goes to 0 and the rest is remapped to 0..255: the faint halation round a piece
    (a generator's glow) is cut away instead of being cut off at the cell's edge."""
    r, g, b, a = img.split()
    a = a.point(lambda v: 0 if v <= floor else round((v - floor) * 255 / (255 - floor)))
    return Image.merge("RGBA", (r, g, b, a))


def _trim(img, margin=2):
    box = img.getchannel("A").point(lambda v: 255 if v > 2 else 0).getbbox()
    if box is None:
        return img, (0, 0)
    x0, y0 = max(0, box[0] - margin), max(0, box[1] - margin)
    x1, y1 = min(img.width, box[2] + margin), min(img.height, box[3] + margin)
    return img.crop((x0, y0, x1, y1)), (x0, y0)


def _lawn_mask(img):
    """The plate's lawn: its largest green, opaque region, holes filled."""
    from scipy import ndimage

    a = np.asarray(img, dtype=np.float32) / 255.0
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    green = (g > r * 1.02) & (g > b * 1.05) & (al > 0.5)
    labels, n = ndimage.label(green)
    if n == 0:
        raise ValueError("the plate has no lawn")
    sizes = ndimage.sum(green, labels, range(1, n + 1))
    return ndimage.binary_fill_holes(labels == (1 + int(np.argmax(sizes))))


def _island_cutout(img, lum=212):
    """An opaque island plate painted on its own sky (the Koke plates) as a sprite: everything that is
    not sky or cloud (green or warm, dark, or darker than the pale sky) is the island; closing joins the
    pale buds to the lawn, the largest piece is kept and its holes filled, and the edge is feathered by
    1.5 px. The world draws its own sky and cloud sea behind it."""
    import numpy as np
    from PIL import ImageFilter
    from scipy import ndimage

    rgb = np.array(img.convert("RGB")).astype(int)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = (r * 299 + g * 587 + b * 114) // 1000
    mask = (g - b > 10) | (r - b > 28) | (np.maximum(np.maximum(r, g), b) < 150) | (luma < lum)
    k = max(3, (img.width // 100) | 1)
    mask = ndimage.binary_closing(mask, structure=np.ones((k * 2 + 1, k * 2 + 1)))
    mask = ndimage.binary_opening(mask, structure=np.ones((3, 3)))
    labels, n = ndimage.label(mask)
    sizes = ndimage.sum(mask, labels, range(1, n + 1))
    mask = ndimage.binary_fill_holes(labels == 1 + int(np.argmax(sizes)))
    alpha = Image.fromarray((mask * 255).astype("uint8")).filter(ImageFilter.GaussianBlur(1.5))
    out = img.convert("RGBA")
    out.putalpha(alpha)
    return out


def _walkable(img, ppu, anchor, spec):
    """The walkable polygon in world units, relative to the plate's anchor: right edge back to
    front, then left edge front to back."""
    if "polygon" in spec:
        return [[round(float(x), 2), round(float(y), 2)] for x, y in spec["polygon"]]
    if "ellipse" in spec:
        rx, ry = spec["ellipse"][0] - spec["inset"], spec["ellipse"][1] - spec["inset"]
        # Right edge back to front, then left edge front to back, like the measured polygon.
        ts = [math.pi * (-0.5 + i / WALK_ROWS) for i in range(WALK_ROWS + 1)]
        right = [[round(rx * math.cos(t), 2), round(ry * math.sin(t), 2)] for t in ts]
        left = [[-x, y] for x, y in reversed(right[1:-1])]
        return right + left
    from scipy import ndimage

    k = max(1, int(round(spec["inset"] * ppu)))
    yy, xx = np.mgrid[-k:k + 1, -k:k + 1]
    lawn = ndimage.binary_erosion(_lawn_mask(img), structure=(xx ** 2 + yy ** 2) <= k * k)
    rows = np.where(lawn.any(axis=1))[0]
    left, right = [], []
    for y in np.linspace(rows[0], rows[-1], WALK_ROWS).round().astype(int):
        xs = np.where(lawn[y])[0]
        yw = round(float((y + 0.5 - anchor[1]) / ppu), 2)
        left.append([round(float((xs[0] - anchor[0]) / ppu), 2), yw])
        right.append([round(float((xs[-1] + 1 - anchor[0]) / ppu), 2), yw])
    return right + left[::-1]


def _hull(points):
    pts = sorted(set(points))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def _footprint(img, ppu, anchor):
    """A sprite's ground footprint in world units relative to its anchor: the convex hull of its
    opaque pixels in the bottom FOOT_DEPTH x base width, at most FOOT_MAX_POINTS points (the
    vertex that adds the least area goes first, so the hull only loses slivers)."""
    solid = np.asarray(img.getchannel("A")) > 127
    rows = np.where(solid.any(axis=1))[0]
    if not len(rows):
        return []
    top, bottom = int(rows[0]), int(rows[-1]) + 1
    low = solid[max(top, int(bottom - 0.15 * (bottom - top))):bottom]
    cols = np.where(low.any(axis=0))[0]
    depth = FOOT_DEPTH * (cols[-1] - cols[0] + 1)
    points = []
    for y in range(max(top, int(bottom - depth)), bottom):
        xs = np.where(solid[y])[0]
        if len(xs):
            points += [(int(xs[0]), y), (int(xs[0]), y + 1), (int(xs[-1]) + 1, y), (int(xs[-1]) + 1, y + 1)]
    hull = _hull(points)

    def area(a, b, c):
        return abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]))

    while len(hull) > FOOT_MAX_POINTS:
        n = len(hull)
        i = min(range(n), key=lambda i: area(hull[i - 1], hull[i], hull[(i + 1) % n]))
        hull.pop(i)
    return [[round((x - anchor[0]) / ppu, 2), round((y - anchor[1]) / ppu, 2)] for x, y in hull]


def _write_imageset(name, img):
    folder = os.path.join(APP_CATALOG, name + ".imageset")
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name + ".png"), "PNG", optimize=True)
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({"images": [{"filename": name + ".png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")


def _box(origin, size, ppu, anchor):
    """An image's box in world units relative to the anchor: [minX, minY, maxX, maxY]."""
    x0 = (origin[0] - anchor[0]) / ppu
    y0 = (origin[1] - anchor[1]) / ppu
    return [round(x0, 3), round(y0, 3), round(x0 + size[0] / ppu, 3), round(y0 + size[1] / ppu, 3)]


def _bands(lawn_ry):
    """The plate's depth bands in world y: (from, to) per band, back to front."""
    edges = [-1e9] + [c * lawn_ry for c in BAND_CUTS] + [1e9]
    return list(zip(edges[:-1], edges[1:]))


def _band_cut(img, box, k, bands):
    """Cuts band k out of an image spanning `box` (world units); returns the crop and its box."""
    a = np.asarray(img, dtype=np.float32)
    y = box[1] + (np.arange(a.shape[0]) + 0.5) / a.shape[0] * (box[3] - box[1])
    s0, s1 = bands[k]
    w = np.ones_like(y) if k == 0 else smoothstep(s0 - APP_FEATHER, s0 + APP_FEATHER, y)
    if s1 < 1e8:
        w = np.where(y <= s1 + APP_FEATHER, w, 0.0)
    out = a.copy()
    out[..., 3] *= w[:, None]
    rows = np.where(out[..., 3].max(axis=1) > 0.5)[0]
    r0, r1 = int(rows[0]), int(rows[-1]) + 1
    per_row = (box[3] - box[1]) / a.shape[0]
    crop = Image.fromarray(np.uint8(np.clip(out[r0:r1], 0, 255) + 0.5), "RGBA")
    return crop, [box[0], round(box[1] + r0 * per_row, 3), box[2], round(box[1] + r1 * per_row, 3)]


def _harmony():
    """tools/assets/harmony.py and its committed manifest (look round 2: asset harmony)."""
    sys.path.insert(0, os.path.join(REPO, "tools", "assets"))
    import harmony

    return harmony, harmony.load_manifest(), harmony.load_config()


# The weather and light FX (tools/assets/integrate.py, target `fx`) live beside the baked sprites under
# world- names the code asks for; this script does not write them and keeps them.
FX_KEEP = ("world-fog-card-", "world-rain-tile", "world-rainbow-arc", "world-puddle-glint", "world-light-shaft")


def app_main():
    import shutil

    harmony, manifest, harmony_cfg = _harmony()
    sys.path.insert(0, os.path.join(REPO, "tools", "assets"))
    import vivid

    def corrected(name):
        entry = manifest["assets"].get(name)
        return entry is not None and not harmony.is_identity(entry["correction"])

    # Rebuild only what this script writes (world-*); the normal maps (tools/assets/normals.py) and the
    # hand-placed ui-* imagesets in the same catalog stay.
    if os.path.isdir(APP_CATALOG):
        for entry in os.listdir(APP_CATALOG):
            if entry.startswith("world-") and entry.endswith(".imageset") and "--normal" not in entry and not entry.startswith(FX_KEEP):
                shutil.rmtree(os.path.join(APP_CATALOG, entry))
    os.makedirs(APP_CATALOG, exist_ok=True)
    with open(os.path.join(APP_CATALOG, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")
    table = {}
    walkable = {}
    jobs = []
    for name, spec in APP_SOURCES.items():
        jobs.append((name, "", spec))
        if spec.get("softlock"):
            jobs.append((name, "--softlock", {**spec, "src": spec["softlock"]}))
        # Every sprite carries its harmony correction; the uncorrected colour is kept as
        # <name>--unharmonized to compare (WorldLook.ArtSet.unharmonized) until the founder signs off.
        if corrected(name) and name in UNHARMONIZED_COMPARE:
            jobs.append((name, "--unharmonized", spec))
        if name in ROUND2_COPPER:
            jobs.append((name, "--round2", spec))
        if name == APP_PLATE:
            for alt, key in PLATE_COMPARE.items():
                if key != APP_PLATE_MASTER:
                    jobs.append((name, alt, _plate(key)))
    for name, alt, spec in jobs:
        path = os.path.join(REPO, spec["src"])
        # A graded copy (tools/art/grade_take.py) is what the app draws; harmony still measures the master.
        graded = os.path.join(os.path.dirname(path), os.path.basename(os.path.dirname(path)) + "--graded.webp")
        if os.path.exists(graded) and not alt:
            path = graded
        if not os.path.exists(path):
            print("missing", path, file=sys.stderr)
            return 1
        src = Image.open(path).convert("RGBA")
        if spec.get("matte"):
            src = _island_cutout(src)
        elif spec.get("matte_file"):
            src.putalpha(Image.open(os.path.join(REPO, spec["matte_file"])).convert("L").filter(ImageFilter.GaussianBlur(1.0)))
        harmony_key = spec.get("harmony_as", name)
        if alt in ("", "--round2") and corrected(harmony_key):
            src = harmony.correct_image(harmony_key, src, manifest, harmony_cfg)
        if "cell" in spec:
            # A piece of a sheet: cut after the sheet's own correction, so every piece shares it.
            x0, y0 = spec["cell"][:2]
            src = src.crop(tuple(spec["cell"]))
            spec = {**spec, "anchor": (spec["anchor"][0] - x0, spec["anchor"][1] - y0)}
            if spec.get("alpha_floor"):
                src = _alpha_floor(src, spec["alpha_floor"])
            if spec.get("flip"):
                src = src.transpose(Image.FLIP_LEFT_RIGHT)
                spec = {**spec, "anchor": (src.width - spec["anchor"][0], spec["anchor"][1])}
        if alt == "--round2":
            src = _round2_copper(harmony, harmony_cfg, name, src)
        if alt in PLATE_COMPARE:
            src = harmony.correct_image(PLATE_COMPARE[alt], src, manifest, harmony_cfg)
        if spec.get("emissive_of"):
            if spec.get("emissive_parent"):
                src = _emissive_diff(src, Image.open(os.path.join(REPO, _master(spec["emissive_parent"]))).convert("RGBA"), spec["emissive_of"])
            else:
                src = _emissive(src, spec["emissive_of"])
        if "anchor_box" in spec:
            bx = spec["anchor_box"]
            ppu = src.width / spec["units"]
            anchor = (-bx[0] * ppu, -bx[1] * src.height / (bx[3] - bx[1]))
        else:
            ppu, anchor = spec["ppu"], spec["anchor"]
        img, (ox, oy) = _trim(src)
        anchor = (anchor[0] - ox, anchor[1] - oy)
        cap = spec.get("max_ppu", APP_MAX_PPU)
        if ppu > cap:
            f = cap / ppu
            img = img.resize((max(1, round(img.width * f)), max(1, round(img.height * f))), Image.LANCZOS)
            anchor, ppu = (anchor[0] * f, anchor[1] * f), cap
        if not spec.get("emissive_of"):
            # Props and stations get the vividness regrade (tools/assets/vivid.py) at their final size, so its
            # chroma cap holds on the shipped pixels; characters, plates, sky and glow overlays are left
            # alone by its config.
            img = vivid.regrade_image(name, img)
            # Art direction (design/art/harmony/direction.json): the lawn's value and chroma, and the one
            # chroma scale for props and stations, after vivid so its boost does not undo it. Compare
            # bakes (--unharmonized, --v2) stay as they were.
            if alt in ("", "--round2"):
                img = harmony.direct_image(harmony_key, img)
        variants = {"sharp": (img, _box((0, 0), img.size, ppu, anchor))}
        if spec.get("single"):
            # One image in world units, never blurred: a light overlay.
            _write_imageset(f"world-{name}{alt}", img)
            box = variants["sharp"][1]
            table[name + alt] = {"sharp": box, "soft": box, "deep": box}
            print(f"{name}{alt}: single, {img.width}x{img.height}, box {box}")
            continue
        if spec.get("sky"):
            # Screen-space sky art: one image, its box in points around its centre.
            _write_imageset(f"world-{name}{alt}", img)
            box = variants["sharp"][1]
            table[name + alt] = {"sharp": box, "soft": box, "deep": box}
            print(f"{name}{alt}: sky, {img.width}x{img.height}, box {box}")
            continue
        if "walkable" in spec and not alt:
            rx, ry = spec["lawn_radius"]
            bands = _bands(ry)
            if not spec.get("face_plate"):  # the face plates share the main plate's walkable polygon and table
                walkable[name] = _walkable(img, ppu, anchor, spec["walkable"])
                wx, wy = spec["window"]
                plate = {"master": spec["plate"], "lawn": [round(rx, 2), round(ry, 2)],
                         "bands": [round(c * ry, 2) for c in BAND_CENTRES],
                         "window": [round((wx - spec["anchor"][0]) / spec["ppu"], 2), round((wy - spec["anchor"][1]) / spec["ppu"], 2)]}
        for suffix, (sigma_u, down) in APP_LEVELS.items():
            blurred, pad = blur_variant(img, sigma_u * ppu, down)
            # The blurred image covers the source padded by `pad` source pixels on every side.
            variants[suffix] = (blurred, _box((-pad, -pad), (img.width + 2 * pad, img.height + 2 * pad), ppu, anchor))
        if name == APP_PLATE or spec.get("face_plate"):
            for k in range(len(bands)):
                entry = {}
                for suffix, (vimg, vbox) in variants.items():
                    crop, cbox = _band_cut(vimg, vbox, k, bands)
                    _write_imageset(f"world-{name}-band{k}{alt}" + ("" if suffix == "sharp" else "__" + suffix), crop)
                    entry[suffix] = cbox
                table[f"{name}-band{k}{alt}"] = entry
            print(f"{name}{alt}: {len(bands)} bands, {ppu:.2f} px/unit")
            continue
        entry = {}
        for suffix, (vimg, vbox) in variants.items():
            if suffix == "sharp" and spec.get("no_sharp"):
                continue
            _write_imageset(f"world-{name}{alt}" + ("" if suffix == "sharp" else "__" + suffix), vimg)
            entry[suffix] = vbox
        entry["footprint"] = _footprint(img, ppu, anchor)
        table[name + alt] = entry
        print(f"{name}{alt}: {img.width}x{img.height}, {ppu:.2f} px/unit, box {entry.get('sharp', entry['soft'])}")
    _write_swift(table, walkable, plate)
    return 0


def _emissive(lit, region):
    """The light a "lit" edit adds, for a night overlay: the edit's warm, bright pixels inside
    `region` (x0, y0, x1, y1 in source pixels: the burner's opening, where the edit painted the
    flame), feathered. Measured against the base the edit is too re-rendered to diff (its whole
    image moved by up to 0.13 in luma), so the region is authored and the flame keyed by colour."""
    from PIL import ImageFilter

    a = np.asarray(lit, dtype=np.float32) / 255.0
    h, w = a.shape[:2]
    x0, y0, x1, y1 = region
    box = np.zeros((h, w), dtype=np.float32)
    box[y0:y1, x0:x1] = 1
    box = np.asarray(Image.fromarray(np.uint8(box * 255), "L").filter(ImageFilter.GaussianBlur(6)), dtype=np.float32) / 255.0
    warm = np.clip((a[..., 0] - a[..., 2] - 0.12) * 4, 0, 1)
    bright = np.clip((a[..., :3] @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32) - 0.5) * 4, 0, 1)
    alpha = box * warm * bright * a[..., 3]
    out = Image.fromarray(np.uint8(np.clip(a * 255, 0, 255)), "RGBA")
    out.putalpha(Image.fromarray(np.uint8(alpha * 255), "L").filter(ImageFilter.GaussianBlur(1.5)))
    return out


def _emissive_diff(lit, parent, region):
    """The light a masked lit edit adds: its pixels that differ from the day master it was cut from,
    inside `region` (x0, y0, x1, y1 in source pixels, a little wider than the edit's emit box), feathered.
    The edit is exactly the parent outside its mask, so a difference of a few levels is the light."""
    from PIL import ImageFilter

    a = np.asarray(lit, dtype=np.float32) / 255.0
    b = np.asarray(parent.resize(lit.size) if parent.size != lit.size else parent, dtype=np.float32) / 255.0
    h, w = a.shape[:2]
    x0, y0, x1, y1 = region
    box = np.zeros((h, w), dtype=np.float32)
    box[y0:y1, x0:x1] = 1
    box = np.asarray(Image.fromarray(np.uint8(box * 255), "L").filter(ImageFilter.GaussianBlur(4)), dtype=np.float32) / 255.0
    diff = np.abs(a[..., :3] - b[..., :3]).max(axis=2)
    changed = np.clip((diff - 0.05) * 5, 0, 1)
    alpha = box * changed * a[..., 3]
    out = Image.fromarray(np.uint8(np.clip(a * 255, 0, 255)), "RGBA")
    out.putalpha(Image.fromarray(np.uint8(alpha * 255), "L").filter(ImageFilter.GaussianBlur(1.5)))
    return out


def _round2_copper(harmony, cfg, name, img):
    """Look round 2's copper hue shift, for the teapot comparison only."""
    rgba = np.asarray(img.convert("RGBA"), dtype=np.float64) / 255.0
    mats = harmony.materials_for(name, cfg, rgba.shape[:2])
    corr = dict(harmony.IDENTITY, materials=ROUND2_COPPER[name])
    out = harmony.apply(rgba, corr, None, mats)
    return Image.fromarray(np.uint8(np.clip(out * 255 + 0.5, 0, 255)), "RGBA")


def _write_swift(table, walkable, plate):
    def box(b):
        return f"WorldBox(minX: {b[0]}, minY: {b[1]}, maxX: {b[2]}, maxY: {b[3]})" if b else "nil"

    def points(ps, indent):
        if not ps:
            return "[]"
        pad = " " * indent
        body = "".join(f"\n{pad}    WorldPoint(x: {x}, y: {y})," for x, y in ps)
        return f"[{body}\n{pad}]"

    lines = [
        "// Generated by design/prototypes/interactions/tools/preblur.py (app mode). Do not edit.",
        "// Boxes, footprints and walkable polygons are in world units, relative to each image's anchor",
        "// (the feet or the footprint centre).",
        "",
        "extension WorldArt {",
        "    /// Every baked sprite. The table is built from parts of at most `SWIFT_PART` sprites: one literal",
        "    /// of all of them takes the compiler more than 13 GB to type-check.",
        "    static let generated: [String: WorldSprite] = {",
        "        var table: [String: WorldSprite] = [:]",
    ]
    names = sorted(table)
    parts = [names[i:i + SWIFT_PART] for i in range(0, len(names), SWIFT_PART)]
    lines += [f"        table.merge(generated{k}) {{ first, _ in first }}" for k in range(len(parts))]
    lines += ["        return table", "    }()", ""]
    for k, part in enumerate(parts):
        lines.append(f"    private static let generated{k}: [String: WorldSprite] = [")
        for name in part:
            e = table[name]
            lines.append(f'        "{name}": WorldSprite(')
            lines.append(f'            sharp: {box(e.get("sharp"))},')
            lines.append(f'            soft: {box(e["soft"])},')
            lines.append(f'            deep: {box(e["deep"])},')
            lines.append(f'            footprint: {points(e.get("footprint", []), 12)}')
            lines.append("        ),")
        lines += ["    ]", ""]
    lines.append("    /// Each plate's walkable polygon, in world units relative to the plate's anchor.")
    lines.append("    static let generatedWalkable: [String: [WorldPoint]] = [")
    for name in sorted(walkable):
        lines.append(f'        "{name}": {points(walkable[name], 8)},')
    lines += ["    ]", ""]
    lines.append(f"    /// The home plate (`{plate['master']}`): its lawn's radii, its depth bands' centres and the door's")
    lines.append("    /// round window, in world units.")
    lines.append("    static let generatedPlate = WorldPlate(")
    lines.append(f'        master: "{plate["master"]}",')
    lines.append(f"        lawnRadiusX: {plate['lawn'][0]},")
    lines.append(f"        lawnRadiusY: {plate['lawn'][1]},")
    lines.append(f"        bandDepthY: [{', '.join(str(b) for b in plate['bands'])}],")
    lines.append(f"        window: WorldPoint(x: {plate['window'][0]}, y: {plate['window'][1]})")
    lines.append("    )")
    lines += ["}", ""]
    with open(APP_SWIFT, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    sys.exit(app_main() if sys.argv[1:] == ["app"] else main())
