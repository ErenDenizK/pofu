#!/usr/bin/env python3
"""Proof 3, one camera: a 6 s pull-out from Home to the Map, drawn two ways from the same layers.

    python3 tools/proof/camera_pullout.py --out DIR [--which a b] [--seconds 6] [--sheet-only]

  a  today's look: the plate, its sky set and the island cut cross-faded by zoom over z 0.55 to 0.95
     (`PlateHomeViews.opacity`), the Map's sky on its own camera (`PaintedSky.mapPose`: fills the screen
     height, never zooms, follows the world camera by `mapParallax` 0.06) in its Map form
     (`PaintedSky.mapSet`: isles and whale at half size and lifted, mid clouds above their residue,
     the cloud sea as a receding stack).
  b  Fable's depth function (docs/design/feel-and-world-v1.md 2.1): every layer of Home's sky set is
     placed by the one world camera through a depth k: scale s_home * (s / s_home)^k, look and anchor
     moved k of the way from Home's. The island is k = 1, the sky gradient k = 0. No cross-fade, no
     Map sky, no separate pose. Koke and Çağlayan are k = 1 islands in world space.

The camera is the app's rail (`CameraRail`, ln scale and the look point linear in z, Home z = 2,
the Island stop z = 1, the Map z = 0) at the iPhone 17 (402 x 874 pt, 3x). Both clips use the same
z(t) (hold, smootherstep, hold), the same layers and the same motion functions (`SkyMotion`: tile
drift, bob and the whale's glide, in screen px). Painted details (falls, canopy sway, lamps) are not
drawn in either clip: they are sub-pixel at these distances and identical in both.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import (ASSETS, FPS, H, RESOURCES, W, Encoder, Sprite, contact_sheet, ease_z, load_rgba,  # noqa: E402
                     smoothstep, window_rows)

REF_W, REF_H = 402.0, 874.0
DEV = 3.0                                     # device px per pt
LIGHT = "day"

# ---- the app's constants (Swift file in each comment)
HOME_WIDTHS, HOME_SCALE = 1.15, 1.40          # plate-home.json framing; IslandFraming.homeScale
HOME_CENTER_X, HOME_TOP_Y = 0.47, 292.0       # plate-home.json framing
ISLAND_WIDTHS = 0.90
PLATE_BOX = (4.0, 438.0, 1019.0, 1230.0)      # plate-home.json islandBox, plate px (1024 x 1536 space)
POFU_PLATE = (455.0, 858.0)                   # plate-home.json characters.pofu
POFU_WORLD = (22.0, 27.0)                     # IslandLayout.pofu
TOP_BAND, BOTTOM_BAND = 118.0, 198.0         # IslandFraming
KOKE_CENTRE, KOKE_PLATE, KOKE_ART = (-100.0, 410.0), (212.0, 140.0), 250.0     # KokeLayout
CAG_CENTRE, CAG_PLATE = (150.0, 440.0), (212.0, 134.0)                          # CaglayanLayout
MAP_TOP, MAP_FOOT = -255.0, 3080.0            # PaintedSky.mapTop / mapFoot (master rows)
MAP_PARALLAX = 0.06
MAP_ISLE_SCALE, MAP_ISLE_FLOOR = 0.5, 300.0
MAP_MID_BOTTOM, MAP_FADE = 1100.0, 60.0
MAP_SEA_BAND, MAP_SEA_TOP = (2480.0, 3000.0), 2440.0
MAP_SEA_STACK = [(0.9, 0.37), (0.72, 0.71), (0.57, 0.13), (0.45, 0.55), (0.35, 0.29), (0.27, 0.83), (0.21, 0.47)]
MAP_SEA_OVERLAP, MAP_HORIZON_FADE = 60.0, 450.0
ISLE_SHADOW = dict(width=0.96, aspect=0.26, opacity=0.34, rgb=(0.33, 0.35, 0.52))   # PaintedSky.isleShadow*

# Fable's depth numbers (proof 3b): one per sky-set layer, tunable in one place.
DEPTH = {"sky": 0.0, "far": 0.12, "isle": 0.30, "whale": 0.30, "mid": 0.70, "sea": 0.88, "island": 1.0}

U = HOME_WIDTHS * REF_W / HOME_SCALE / (PLATE_BOX[2] - PLATE_BOX[0])        # world units per plate px
Q = 0.5 * U                                                                 # per master px (master = 2 x plate)


def world_of_plate(px: float, py: float) -> tuple[float, float]:
    return ((px - POFU_PLATE[0]) * U + POFU_WORLD[0], (py - POFU_PLATE[1]) * U + POFU_WORLD[1])


def world_of_master(mx: float, my: float) -> tuple[float, float]:
    return world_of_plate(mx / 2, my / 2)


class Pose:
    """ln scale (pt per unit), look (world), anchorY (pt); projects to device px."""

    def __init__(self, scale: float, lx: float, ly: float, ay: float):
        self.scale, self.lx, self.ly, self.ay = scale, lx, ly, ay

    @staticmethod
    def mix(a: "Pose", b: "Pose", t: float) -> "Pose":
        return Pose(math.exp(math.log(a.scale) + (math.log(b.scale) - math.log(a.scale)) * t),
                    a.lx + (b.lx - a.lx) * t, a.ly + (b.ly - a.ly) * t, a.ay + (b.ay - a.ay) * t)

    def project(self, wx: float, wy: float) -> tuple[float, float]:
        return (W / 2 + (wx - self.lx) * self.scale * DEV, (self.ay + (wy - self.ly) * self.scale) * DEV)


def stops() -> list[Pose]:
    """The rail while the plate shows: [Map, Island, Home] (`HomePlate.stops`)."""
    bx0, by0, bx1, by1 = PLATE_BOX
    home_box = (*world_of_plate(bx0, by0), *world_of_plate(bx1, by1))
    koke = (KOKE_CENTRE[0] - KOKE_PLATE[0] / 2, KOKE_CENTRE[1] - KOKE_PLATE[1] / 2,
            KOKE_CENTRE[0] + KOKE_PLATE[0] / 2, KOKE_CENTRE[1] + KOKE_PLATE[1] / 2)
    cag = (CAG_CENTRE[0] - CAG_PLATE[0] / 2, CAG_CENTRE[1] - CAG_PLATE[1] / 2,
           CAG_CENTRE[0] + CAG_PLATE[0] / 2, CAG_CENTRE[1] + CAG_PLATE[1] / 2)
    ax0, ay0 = min(home_box[0], koke[0], cag[0]), min(home_box[1], koke[1], cag[1])
    ax1, ay1 = max(home_box[2], koke[2], cag[2]), max(home_box[3], koke[3], cag[3])
    aw, ah = ax1 - ax0, ay1 - ay0
    band = REF_H - TOP_BAND - BOTTOM_BAND
    foot = REF_H - BOTTOM_BAND - 10
    r = (375 / REF_W) / (667 / REF_H)
    clear = (MAP_ISLE_FLOOR - MAP_TOP) / (MAP_FOOT - MAP_TOP) * REF_H
    scale = min((REF_W - 20) / aw, (band - 20) / ah, (foot - clear) / max(ah / 2 * (1 + r), 1))
    map_ = Pose(scale, (ax0 + ax1) / 2, (ay0 + ay1) / 2, foot - ah * scale / 2)
    hw = home_box[2] - home_box[0]
    island = Pose(ISLAND_WIDTHS * REF_W / hw, (home_box[0] + home_box[2]) / 2, (home_box[1] + home_box[3]) / 2, TOP_BAND + band / 2)
    home = Pose(HOME_SCALE, world_of_plate(bx0 + HOME_CENTER_X * (bx1 - bx0), by0)[0], world_of_plate(0, by0)[1], HOME_TOP_Y)
    return [map_, island, home]


def rail(z: float, s: list[Pose]) -> Pose:
    z = min(max(z, 0.0), 2.0)
    lo = int(min(math.floor(z), 1))
    return Pose.mix(s[lo], s[lo + 1], z - lo)


def map_pose(world: Pose, s: list[Pose]) -> Pose:
    """`PaintedSky.mapPose`: rows MAP_TOP..MAP_FOOT of the master fill the screen height, centred across,
    the look following the world camera's by MAP_PARALLAX."""
    top = world_of_master(0, MAP_TOP)
    foot = world_of_master(0, MAP_FOOT)
    mid_x = world_of_master(1024, 0)[0]
    scale = REF_H / (foot[1] - top[1])
    return Pose(scale, mid_x + (world.lx - s[0].lx) * MAP_PARALLAX, top[1] + (world.ly - s[0].ly) * MAP_PARALLAX, 0.0)


# ---------------------------------------------------------------- the layers


class SkyLayer:
    def __init__(self, spec: dict):
        self.spec = dict(spec)
        self.id, self.role = spec["id"], spec["role"]
        self.pos = list(spec["pos"])
        self.size = list(spec["size"])
        self.drift = spec.get("drift", 0)
        self.bob = spec.get("bob")
        self.window = None
        self.sprite = Sprite(load_rgba(spec["asset"]))

    def clone(self) -> "SkyLayer":
        c = object.__new__(SkyLayer)
        c.spec, c.id, c.role = self.spec, self.id, self.role
        c.pos, c.size, c.drift, c.bob, c.window, c.sprite = list(self.pos), list(self.size), self.drift, self.bob, None, self.sprite
        return c

    @property
    def kind(self) -> str:
        a = self.spec["asset"]
        if self.role == "tile":
            return "mid" if "-sky-mid-" in a else "sea" if "-sky-sea-" in a else "far"
        if self.role == "sprite":
            return "isle" if "-isle-" in a else "sprite"
        return self.role


def extend_sea(L: SkyLayer, more_master_rows: float = 3200.0) -> None:
    """The painted cloud sea ends in a hazy foot just under Home's screen. A pull-out shows what lies
    below it, so both clips extend the sea offline: past its last row, a mirror of the foot blended into
    mirror-repeats of the sea's clean band (master rows `MAP_SEA_BAND`). Home's frame is unchanged."""
    img = L.sprite.mips[0]
    k = img.shape[0] / L.size[1]                               # src rows per master row
    b0, b1 = round((MAP_SEA_BAND[0] - L.pos[1]) * k), round((MAP_SEA_BAND[1] - L.pos[1]) * k)
    band = img[b0:b1]
    tiles, n, flip = [], 0, True
    while n < more_master_rows * k:
        tiles.append(band[::-1] if flip else band)
        n += band.shape[0]
        flip = not flip
    ext = np.concatenate(tiles)
    fade = min(round(300 * k), ext.shape[0])
    foot = img[-fade:][::-1]                                    # the foot mirrored: the haze fades back out
    a = np.linspace(0, 1, fade, dtype=np.float32)[:, None, None]
    ext = ext.copy()
    ext[:fade] = foot * (1 - a) + ext[:fade] * a
    L.sprite = Sprite.__new__(Sprite)
    L.sprite.mips = [np.concatenate([img, ext])]
    L.size[1] = L.sprite.mips[0].shape[0] / k


def load_set(light: str = LIGHT) -> list[SkyLayer]:
    data = json.loads((RESOURCES / "Plates" / "skyset-home.json").read_text())
    layers = [SkyLayer(e) for e in data["lights"][light]["layers"]]
    for L in layers:
        if L.kind == "sea":
            extend_sea(L)
    return layers


def bob_y(layer: SkyLayer, t: float) -> float:
    b = layer.bob
    return b["sign"] * b["amp"] * math.sin(2 * math.pi * t / b["period"]) if b else 0.0


def glide_left(rest_left: float, width: float, speed: float, t: float, margin: float = 40.0) -> float:
    span = W + 2 * margin + width
    return math.fmod(rest_left + margin + width + speed * t, span) - margin - width


def draw_layer(canvas: np.ndarray, L: SkyLayer, cam: Pose, t: float, alpha: float = 1.0) -> None:
    """One sky-set layer through camera `cam` (a master rect to a screen rect), with the app's motion."""
    x0, y0 = cam.project(*world_of_master(L.pos[0], L.pos[1]))
    s = cam.scale * DEV * Q
    w, h = L.size[0] * s, L.size[1] * s
    dy = bob_y(L, t)
    rows = None
    if L.window:
        top = y0 + dy + L.window["top"] * h
        bottom = y0 + dy + L.window["bottom"] * h
        rows = window_rows(top, bottom, L.window["topFade"] * h, L.window["bottomFade"] * h)
        if rows is None:
            return
    if L.role == "sky":
        L.sprite.draw(canvas, x0, y0, w, h, alpha=alpha, replicate=True)
    elif L.role == "tile":
        shift = math.fmod(L.drift * t, w) if w > 0 else 0.0
        L.sprite.draw(canvas, x0 + shift, y0 + dy, w, h, alpha=alpha, wrap_x=w, rows=rows)
    elif L.role == "whale":
        left = glide_left(x0, w, L.drift, t)
        L.sprite.draw(canvas, left, y0 + dy, w, h, alpha=alpha)
    elif L.role == "stars":
        return
    else:
        L.sprite.draw(canvas, x0, y0 + dy, w, h, alpha=alpha, rows=rows)


# ---- the Map's form of the set (`PaintedSky.cleanSet`, `seaStack`)

def map_set(layers: list[SkyLayer]) -> list[SkyLayer]:
    out: list[SkyLayer] = []
    isles: list[int] = []
    for L in layers:
        if L.role == "island":
            continue
        if L.kind == "isle" or L.role == "whale":
            c = L.clone()
            cx, cy = L.pos[0] + L.size[0] / 2, L.pos[1] + L.size[1] / 2
            c.pos = [cx + (L.pos[0] - cx) * MAP_ISLE_SCALE, cy + (L.pos[1] - cy) * MAP_ISLE_SCALE]
            c.size = [L.size[0] * MAP_ISLE_SCALE, L.size[1] * MAP_ISLE_SCALE]
            out.append(c)
            isles.append(len(out) - 1)
        elif L.kind == "mid":
            c = L.clone()
            hh = L.size[1]
            c.window = dict(top=0.0, bottom=(MAP_MID_BOTTOM - L.pos[1]) / hh, topFade=0.0, bottomFade=MAP_FADE / hh)
            out.append(c)
        elif L.kind == "sea":
            out += sea_stack(L)
        else:
            out.append(L)
    foot = max((out[i].pos[1] + out[i].size[1] for i in isles), default=MAP_ISLE_FLOOR)
    lift = min(MAP_ISLE_FLOOR - foot, 0)
    for i in isles:
        out[i].pos[1] += lift
    return out


def sea_stack(sea: SkyLayer) -> list[SkyLayer]:
    near = sea.clone()
    hh = sea.size[1]
    near.window = dict(top=(MAP_SEA_TOP - sea.pos[1]) / hh, bottom=1.0, topFade=MAP_FADE / hh, bottomFade=0.0)
    rows = [near]
    bottom = MAP_SEA_TOP + MAP_FADE + MAP_SEA_OVERLAP
    band = MAP_SEA_BAND
    for n, (f, slide) in enumerate(MAP_SEA_STACK):
        c = sea.clone()
        c.id = f"{sea.id}-map{n}"
        y = bottom - (band[1] - sea.pos[1]) * f
        c.pos = [sea.pos[0] - slide * sea.size[0] * f, y]
        c.size = [sea.size[0] * f, sea.size[1] * f]
        c.drift = sea.drift * f
        c.bob = None
        last = n == len(MAP_SEA_STACK) - 1
        c.window = dict(top=(band[0] - sea.pos[1]) / hh, bottom=(band[1] - sea.pos[1]) / hh,
                        topFade=(MAP_HORIZON_FADE if last else MAP_FADE) / hh, bottomFade=MAP_FADE / hh)
        rows.insert(0, c)
        bottom = y + (band[0] - sea.pos[1]) * f + (MAP_FADE + MAP_SEA_OVERLAP) * f
    return rows


# ---- islands on the world

class Island:
    def __init__(self, art: str, centre: tuple[float, float], width: float, shadow_box=None):
        self.sprite = Sprite(load_rgba(art))
        self.centre, self.width = centre, width
        self.height = width * self.sprite.h / self.sprite.w
        self.shadow_box = shadow_box              # (centre, width, height) world units of the island's box

    def rect_world(self):
        return (self.centre[0] - self.width / 2, self.centre[1] - self.height / 2, self.width, self.height)

    def draw(self, canvas: np.ndarray, cam: Pose, alpha: float = 1.0, shadow: bool = True) -> None:
        x, y, w, h = self.rect_world()
        sx, sy = cam.project(x, y)
        if shadow and self.shadow_box:
            (bx0, by0, bx1, by1) = self.shadow_box
            wd = (bx1 - bx0) * ISLE_SHADOW["width"]
            ht = wd * ISLE_SHADOW["aspect"]
            cx, cy = (bx0 + bx1) / 2, by1 - (by1 - by0) * 0.12
            px, py = cam.project(cx, cy)
            rx, ry = wd / 2 * cam.scale * DEV, ht / 2 * cam.scale * DEV
            shade(canvas, px, py, rx, ry, ISLE_SHADOW["opacity"] * alpha, ISLE_SHADOW["rgb"])
        self.sprite.draw(canvas, sx, sy, w * cam.scale * DEV, h * cam.scale * DEV, alpha=alpha)


def shade(canvas: np.ndarray, cx: float, cy: float, rx: float, ry: float, opacity: float, rgb) -> None:
    x0, x1 = max(int(cx - rx) - 1, 0), min(int(cx + rx) + 2, canvas.shape[1])
    y0, y1 = max(int(cy - ry) - 1, 0), min(int(cy + ry) + 2, canvas.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    r = np.hypot((xx - cx) / max(rx, 1e-3), (yy - cy) / max(ry, 1e-3))
    a = (opacity * np.interp(r, [0, 0.5, 1], [1, 0.45, 0])).astype(np.float32)[..., None]
    col = np.float32(rgb)
    dst = canvas[y0:y1, x0:x1]
    dst[...] = np.concatenate([col * a, a], -1) + dst * (1 - a)


class Scene:
    def __init__(self):
        self.layers = load_set()
        self.rail = stops()
        bx0, by0, bx1, by1 = PLATE_BOX
        self.home_box = (*world_of_plate(bx0, by0), *world_of_plate(bx1, by1))
        self.home_island = next(L for L in self.layers if L.role == "island")
        self.mapisle = Island("world-home-mapisle-day-0", ((self.home_box[0] + self.home_box[2]) / 2, (self.home_box[1] + self.home_box[3]) / 2),
                              self.home_box[2] - self.home_box[0])
        self.koke = Island("world-koke-island-4", KOKE_CENTRE, KOKE_ART,
                           (KOKE_CENTRE[0] - KOKE_PLATE[0] / 2, KOKE_CENTRE[1] - KOKE_PLATE[1] / 2,
                            KOKE_CENTRE[0] + KOKE_PLATE[0] / 2, KOKE_CENTRE[1] + KOKE_PLATE[1] / 2))
        self.cag = Island("world-caglayan-island-day-4", CAG_CENTRE, CAG_PLATE[0],
                          (CAG_CENTRE[0] - CAG_PLATE[0] / 2, CAG_CENTRE[1] - CAG_PLATE[1] / 2,
                           CAG_CENTRE[0] + CAG_PLATE[0] / 2, CAG_CENTRE[1] + CAG_PLATE[1] / 2))
        self.map_layers = map_set(self.layers)

    # -- (a) today's look
    def frame_a(self, z: float, t: float) -> np.ndarray:
        cam = rail(z, self.rail)
        f = smoothstep((z - 0.55) / 0.4)                          # PlateHomeLayer.opacity(z:)
        out = np.zeros((H, W, 4), np.float32)
        if f < 0.999:
            mp = map_pose(cam, self.rail)
            for L in self.map_layers:
                draw_layer(out, L, mp, t)
            self.mapisle.draw(out, cam, shadow=False)
            self.koke.draw(out, cam)
            self.cag.draw(out, cam)
        if f > 0.001:
            group = np.zeros((H, W, 4), np.float32)
            for L in self.layers:
                draw_layer(group, L, cam, t)
            out[...] = group * f + out * (1 - group[..., 3:4] * f)
        return out[..., :3]

    # -- (b) Fable's depth function
    def depth_cam(self, k: float, cam: Pose) -> Pose:
        h = self.rail[2]
        return Pose(h.scale * (cam.scale / h.scale) ** k, h.lx + k * (cam.lx - h.lx), h.ly + k * (cam.ly - h.ly), h.ay + k * (cam.ay - h.ay))

    def frame_b(self, z: float, t: float) -> np.ndarray:
        cam = rail(z, self.rail)
        out = np.zeros((H, W, 4), np.float32)
        for L in self.layers:
            k = DEPTH.get(L.kind, DEPTH["isle"])
            draw_layer(out, L, self.depth_cam(k, cam), t)
        self.koke.draw(out, cam)
        self.cag.draw(out, cam)
        return out[..., :3]


def z_of(t: float, total: float) -> float:
    return 2.0 * (1.0 - ease_z(t, total))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--which", nargs="+", default=["a", "b"], choices=["a", "b"])
    ap.add_argument("--seconds", type=float, default=6.0)
    ap.add_argument("--stills", type=Path, help="also write the six sheet frames here as PNG (1:1, for looking)")
    ap.add_argument("--no-video", action="store_true")
    args = ap.parse_args(argv)
    sc = Scene()
    n = round(args.seconds * FPS)
    picks = [round(i * (n - 1) / 5) for i in range(6)]
    names = {"a": "pullout-a-today", "b": "pullout-b-depth"}
    for which in args.which:
        enc = None if args.no_video else Encoder(args.out / f"{names[which]}.mp4")
        kept: list[np.ndarray] = []
        labels = []
        for i in range(n):
            t = i / FPS
            z = z_of(t, args.seconds)
            fr = sc.frame_a(z, t) if which == "a" else sc.frame_b(z, t)
            if enc:
                enc.write(fr)
            if i in picks:
                kept.append(fr.copy())
                labels.append(f"{which} t={t:.2f}s z={z:.2f}")
                if args.stills:
                    from PIL import Image
                    args.stills.mkdir(parents=True, exist_ok=True)
                    Image.fromarray((np.clip(fr, 0, 1) * 255 + 0.5).astype(np.uint8)).save(args.stills / f"{names[which]}-{i:03d}.png")
        if enc:
            enc.close()
        contact_sheet(kept, args.out / f"{names[which]}-sheet.jpg", labels)
        print(which, "done", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
