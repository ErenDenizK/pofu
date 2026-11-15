#!/usr/bin/env python3
"""Proof round 3 (docs/design/world-presentation-v2.md section 10), scripts only.

    python3 tools/proof/round3.py edges --out DIR     R3: M1 to M10 on the level 4 and 10 plates (day, night), the
                                                       worst-edge sheets, and the edge tour (four stills at 2.7 zoom)
    python3 tools/proof/round3.py props --out DIR     R5: jar, pots and lantern at their section 6.3 slots, island
                                                       levels 2, 6 and 10, mid and near, sprite art as a placeholder

Island level L is plate stage 10 - L (`plate-home.json` stageLevels [10..1]). The tour has no chrome and no station
stills: the erase jobs are not painted yet.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / "tools" / "art"))
import camera_pullout as cp  # noqa: E402
import island_matte as im  # noqa: E402
import matte_check as mc  # noqa: E402
from _common import ASSETS, H, W, load_rgba  # noqa: E402

TEX = 2
SHADOW_RGB = {"day": (0.33, 0.35, 0.52), "golden": (0.42, 0.30, 0.38), "night": (0.03, 0.04, 0.13)}
ZOOM_TOUR = 2.7 * 0.5373                   # screen px per master px: 2.7 x the Island stop (0.9 screens over the island)
LAYER_SPECS = [("day", 0), ("night", 0), ("day", 6), ("night", 6)]


def save(a: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)).save(path)


# ---------------------------------------------------------------- the sky the island is drawn over

_BACKDROPS: dict[str, np.ndarray] = {}


def backdrop(light: str) -> np.ndarray:
    """Home's sky set for `light` (sky, far, isles, mid, the tall cloud sea; not the island) in master px, 2048 x 3600."""
    if light in _BACKDROPS:
        return _BACKDROPS[light]
    layers = cp.load_set(light, floor=True)
    OX, OY, BW, BH = 0, 0, 2048, 3600
    canvas = np.zeros((BH, BW, 4), np.float32)
    for L in layers:
        if L.role in ("island", "stars", "whale"):
            continue
        x, y = L.pos
        w, h = L.size
        if L.role == "sky":
            L.sprite.draw(canvas, x - OX, y - OY, w, h, replicate=True)
        elif L.role == "tile":
            L.sprite.draw(canvas, x - OX, y - OY, w, h, wrap_x=w)
        else:
            L.sprite.draw(canvas, x - OX, y - OY, w, h)
    rgb = canvas[..., :3] + (1 - canvas[..., 3:4]) * np.float32([0.6, 0.75, 0.95])
    _BACKDROPS[light] = rgb
    return rgb


def layer_dest(light: str, rgba: np.ndarray, x0: int, y0: int) -> np.ndarray:
    bd = backdrop(light)
    y, x = y0 * TEX, x0 * TEX
    return bd[y:y + rgba.shape[0], x:x + rgba.shape[1]]


# ---------------------------------------------------------------- R3: M1 to M10

def run_checks(out: Path) -> list[dict]:
    reports, layers, anchors = [], {}, {}
    for light, stage in LAYER_SPECS:
        rgba, (x0, y0) = im.island_layer(light, stage)
        dests = {k: layer_dest(k, rgba, x0, y0) for k in ("day", "golden", "night")}
        r = mc.check_matte(rgba, source=im.source_crop(light, stage), soft=im.soft_edges(light, stage, rgba.shape[:2]),
                           dests=dests, name=f"{light}-L{10 - stage}", out=out / "checks")
        reports.append(r)
        layers[(light, stage)] = rgba
        for k, p in mc.alpha_anchors(rgba[..., 3]).items():
            anchors.setdefault(f"{k}@L{10 - stage}", {})[light] = p
        print(mc.one_line(r))
    m10 = mc.m10_registration(anchors)
    print("M10 registration day vs night (level 4 and 10 anchors: the shape's centroid, left, right and lower third): %.2f px at %s" % (m10["value"], m10["anchor"]))
    (out / "checks" / "M10.json").write_text(json.dumps(m10, indent=1))
    (out / "checks" / "summary.txt").write_text("\n".join(mc.one_line(r) for r in reports) + "\nM7 M8 M9: n/a (no erased base, no looks yet)\nM10 %.2f px (%s)\n" % (m10["value"], m10["anchor"]))
    return reports


# ---------------------------------------------------------------- R3: the edge tour

def compose_view(light: str, island: tuple[str, int], centre: tuple[float, float], S: float) -> np.ndarray:
    """One 1206 x 2622 still: `light`'s sky set, the island's code shadow, the island layer; master px (centre) at the
    screen's centre, S screen px per master px. The sky is sampled cubic, the layers bilinear (the app's sampling)."""
    il, ist = island
    rgba, (x0, y0) = im.island_layer(il, ist)
    M = np.float32([[S, 0, W / 2 - centre[0] * S], [0, S, H / 2 - centre[1] * S]])
    sky = cv2.warpAffine(backdrop(light), M, (W, H), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT_101)
    # the shadow, by code, on the cloud below the island
    sh = im.island_shadow(rgba[..., 3])
    Ms = M.copy()
    Ms[0, 2] += x0 * TEX * S
    Ms[1, 2] += y0 * TEX * S
    sha = cv2.warpAffine(sh, Ms, (W, H), flags=cv2.INTER_LINEAR)
    sky = sky * (1 - sha[..., None]) + np.float32(SHADOW_RGB[light]) * sha[..., None]
    pm = rgba.copy()
    pm[..., :3] *= pm[..., 3:4]
    wp = cv2.warpAffine(pm, Ms, (W, H), flags=cv2.INTER_LINEAR)
    return wp[..., :3] + sky * (1 - wp[..., 3:4])


def rim_spots(light: str, stage: int) -> dict[str, tuple[float, float]]:
    """Four points on the rim of the layer, in master px: the left lawn, the underside's left, a root tendril's foot, the
    islet at the right."""
    rgba, (x0, y0) = im.island_layer(light, stage)
    a = rgba[..., 3] > 0.5
    ys, xs = np.nonzero(a)
    pts = {}
    left = xs.argmin()
    pts["left lawn"] = (xs[left], ys[left] + 120)
    under = np.where(a.any(0))[0]
    cx = int(np.percentile(xs, 30))
    col = np.nonzero(a[:, cx])[0]
    pts["underside"] = (cx, col.max() - 60)
    low = ys.argmax()
    pts["root foot"] = (xs[low], ys[low] - 80)
    right = xs.argmax()
    sel = (xs > xs.max() - 250)
    pts["islet"] = (xs[right] - 120, int(np.median(ys[sel])) + 140)
    return {k: (float(x + x0 * TEX), float(y + y0 * TEX)) for k, (x, y) in pts.items()}


def run_tour(out: Path) -> list[Path]:
    plan = [("left lawn", ("day", 0), "day"), ("underside", ("day", 0), "golden"),
            ("root foot", ("day", 6), "night"), ("islet", ("night", 0), "day")]
    paths = []
    for n, (spot, island, sky) in enumerate(plan, 1):
        pt = rim_spots(*island)[spot]
        frame = compose_view(sky, island, pt, ZOOM_TOUR)
        p = out / f"tour-{n}-{spot.replace(' ', '-')}-{island[0]}L{10 - island[1]}-on-{sky}.png"
        save(frame, p)
        ImageDraw.Draw(img := Image.open(p)).text((16, 16), f"{spot}: {island[0]} island level {10 - island[1]} over the {sky} sky, 2.7 zoom", fill=(255, 255, 255))
        img.save(p)
        paths.append(p)
        print("tour", p.name)
    return paths


# ---------------------------------------------------------------- R5: the props

#: Section 6.3: default slots in plate pts (1024 x 1536 space) on the front lip. The jar is front centre just right of
#: Pofu's stand (455, 858); the pots a row on the left lip toward the garden; the lantern on a post at the right lip.
DEFAULTS = {"jar": 520.0, "pots": 340.0, "lantern": 650.0}
HEIGHT_PT = {"jar": 48.0, "pots": 40.0, "lantern": 66.0}          # plate pts: 22 pt, 18 pt and 30 pt at mid (0.455 pt per plate pt)
SPAN = {"jar": 70.0, "pots": 150.0, "lantern": 50.0}              # lip width each needs, plate pts
SPRITES = {"jar": "paint-jar-full", "pot-a": "paint-pot-bud", "pot-b": "paint-pot-bloom", "pot-c": "paint-pot-bud", "lantern": "paint-lantern-on"}
SPRITE_DIR = HERE.parents[1] / "Packages" / "PofuKit" / "Sources" / "PofuDesignSystem" / "Resources"
MID = dict(S=1.366, cx=481.0, top=438.0, sx=W / 2, sy=876.0)       # Home stop: plate pts to px (plate-home.json framing)


def lip_profile(light: str, stage: int):
    """For each column of the plate (pts): the lip's y (pts), the lowest lawn-green pixel of the island layer, and how much of
    the rim just above it is clean lawn (no flowers, no decor) 0..1."""
    rgba, (x0, y0) = im.island_layer(light, stage)
    r, g, b, a = (rgba[..., i] for i in range(4))
    lawn = (a > 0.9) & (g > b + 0.12) & (g > r * 0.92)
    # the lawn's own colours: yellow-green. Flowers, mailbox, planters break the run.
    sat_ok = lawn & (g > 0.45)
    lip = {}
    clean = {}
    for px in range(int(x0), int(x0 + rgba.shape[1] / TEX)):
        c = (px - x0) * TEX
        col = sat_ok[:, c:c + TEX].any(1)
        ys = np.nonzero(col)[0]
        if len(ys) < 10:
            continue
        ylow = ys.max()
        window = (lawn[max(ylow - 60, 0):ylow, c:c + TEX]).mean()
        lip[px] = y0 + ylow / TEX
        clean[px] = float(window)
    return lip, clean


def slot_for(prop: str, lip, clean) -> tuple[float, float]:
    """The free lip span nearest the default: a window of the prop's width where the rim above is lawn."""
    xs = sorted(lip)
    half = SPAN[prop] / 2
    best, best_cost = None, 1e9
    for cx in range(int(DEFAULTS[prop] - 200), int(DEFAULTS[prop] + 200), 5):
        span = [x for x in xs if cx - half <= x <= cx + half]
        if len(span) < SPAN[prop] * 0.9:
            continue
        free = float(np.mean([clean[x] for x in span]))
        bumpy = float(np.ptp([lip[x] for x in span]))
        if free < 0.9 or bumpy > 14:
            continue
        cost = abs(cx - DEFAULTS[prop])
        if cost < best_cost:
            best, best_cost = cx, cost
    if best is None:
        best = int(DEFAULTS[prop])
    # flowers and hanging wisteria run below the lawn's rim: the foot stands on the rim the span's higher columns show
    ys = [lip[x] for x in xs if best - 90 <= x <= best + 90]
    return float(best), float(np.percentile(ys, 20)) - 6.0         # a little inside the lip


def sprite(name: str) -> np.ndarray:
    return np.asarray(Image.open(SPRITE_DIR / f"{name}.png").convert("RGBA"), np.float32) / 255


def draw_prop(canvas: np.ndarray, sp: np.ndarray, foot_px: tuple[float, float], height_px: float, light: str = "day") -> None:
    """Sprite with its foot-centre at foot_px and a contact shadow from code; premultiplied bilinear."""
    h = height_px
    w = h * sp.shape[1] / sp.shape[0]
    # code shadow: a squashed dark ellipse at the foot, left-lit
    yy, xx = np.mgrid[:H, :W].astype(np.float32)
    ex = ((xx - (foot_px[0] + w * 0.05)) / (w * 0.5)) ** 2 + ((yy - foot_px[1]) / (w * 0.13)) ** 2
    sh = np.clip(1 - ex, 0, 1) ** 1.2 * 0.38
    canvas[...] = canvas * (1 - sh[..., None]) + np.float32([0.18, 0.22, 0.10]) * sh[..., None]
    pm = sp.copy()
    pm[..., :3] *= pm[..., 3:4]
    k = h / sp.shape[0]
    M = np.float32([[k, 0, foot_px[0] - w / 2], [0, k, foot_px[1] - h]])
    wp = cv2.warpAffine(pm, M, (W, H), flags=cv2.INTER_AREA if k < 1 else cv2.INTER_LINEAR)
    canvas[...] = wp[..., :3] + canvas * (1 - wp[..., 3:4])


def props_frame(level: int, view: str, light: str = "day") -> tuple[np.ndarray, dict]:
    stage = 10 - level
    plate = load_rgba(f"world-home-plate-{light}-{stage}")[..., :3]
    lip, clean = lip_profile(light, stage)
    slots = {p: slot_for(p, lip, clean) for p in DEFAULTS}
    if view == "mid":
        S, cx, cy, sx, sy = MID["S"], MID["cx"], MID["top"], MID["sx"], MID["sy"]
        M = np.float32([[S * 2 * 0.5 * 0 + S, 0, sx - cx * S], [0, S, sy - cy * S]])      # plate pts to px
    else:
        S = 3.0
        gx = (slots["pots"][0] + slots["lantern"][0]) / 2
        gy = np.mean([v[1] for v in slots.values()])
        M = np.float32([[S, 0, W / 2 - gx * S], [0, S, 1500 - gy * S]])
    Mt = M.copy()
    Mt[:, :2] *= 0.5                                         # the plate raster is 2 px per pt
    frame = cv2.warpAffine(plate, Mt, (W, H), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    items = [("jar", "jar", slots["jar"], HEIGHT_PT["jar"])]
    for i, dx in enumerate((-48.0, 0.0, 48.0)):
        items.append((f"pot-{'abc'[i]}", "pots", (slots["pots"][0] + dx, slots["pots"][1] + (3 if i == 1 else 0)), HEIGHT_PT["pots"]))
    items.append(("lantern", "lantern", slots["lantern"], HEIGHT_PT["lantern"]))
    items.sort(key=lambda t: t[2][1])                         # by footY
    for key, prop, (px, py), hpt in items:
        draw_prop(frame, sprite(SPRITES[key]), (M[0, 0] * px + M[0, 2], M[1, 1] * py + M[1, 2]), hpt * S, light)
    return frame, slots


def run_props(out: Path) -> list[Path]:
    paths, report = [], {}
    for level in (2, 6, 10):
        for view in ("mid", "near"):
            frame, slots = props_frame(level, view)
            img = Image.fromarray((np.clip(frame, 0, 1) * 255 + 0.5).astype(np.uint8))
            d = ImageDraw.Draw(img)
            d.rectangle((0, 0, 560, 70), fill=(0, 0, 0))
            d.text((12, 10), f"island level {level}, {view}   jar / pots / lantern at section 6.3 slots", fill=(255, 255, 255))
            d.text((12, 36), "PLACEHOLDER SPRITES FOR POSITION ONLY (painted props come from Codex)", fill=(255, 220, 120))
            p = out / f"props-L{level}-{view}.png"
            p.parent.mkdir(parents=True, exist_ok=True)
            img.save(p)
            paths.append(p)
            report[f"L{level}"] = {k: [round(v[0], 1), round(v[1], 1)] for k, v in slots.items()}
            print("props", p.name, report[f"L{level}"])
    (out / "slots.json").write_text(json.dumps(report, indent=1))
    return paths


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("what", choices=["edges", "props"])
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args(argv)
    args.out.mkdir(parents=True, exist_ok=True)
    if args.what == "edges":
        run_checks(args.out)
        run_tour(args.out)
    else:
        run_props(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
