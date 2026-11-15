#!/usr/bin/env python3
"""Proof round 3, R1: composition (docs/design/world-presentation-v2.md sections 1 and 2, 10).

    python3 tools/proof/composition.py --out DIR --frames DIR [--only map mid near floor]

Writes 1206 x 2622 stills (the iPhone 17 at 3x, 402 x 874 pt) plus one `<still>.json` each that
`composition_check.py` reads (the projected boxes of the subjects, the chrome and the backdrop features, in pt):

  map-<order>-stage1|2|3, map-<order>-tier2   order = journey (Home in front, the journey rising: section 1.3)
                                              or homefirst (today's order, Home on top, re-fitted with the same rules)
  mid-level01|04|10                           the island fitted to its box with the real chrome (section 1.4)
  near-rest|limit                             the macro look at 4.5 and 7.4 pt per unit with the back control (1.5)
  floor-puff-ladder                           the cloud floor at four puff sizes, made by scaling the shipped sea tile

The backdrop is section 2's one camera: a layer at depth k is drawn at scale s0 (s / s0)^k and look L0 + k (L - L0), with
the Map's tier-1 camera as the reference (s0 = 0.70). Layers: sky gradient (k 0), far clouds, far isles, whale, cloud
puffs, the floor in four puff sizes (horizon band 12 pt, middle 40, near 90, lip 160), towers and veils, islands.

Stand-ins, all named in the hand-back: the cloud towers, veils, wisps and the lip are made from the shipped sea tile
(Codex's pilot lip and tower are not here yet); the tier-2 islands do not exist, so tier 2 holds a veil and two towers;
Home's art is the matted level cut (`island_matte`), Koke's and Caglayan's are the shipped level-4 art; the back control
at near is the corner control cut from a shipped Home frame, placed bottom left.

Chrome is cut from shipped frames (fetch with `tools/review/fetch_frames.sh screenshots/main 'path-d03-0900.png'
'path-d13-map-0900.png' DIR`): the Home chrome (line card, the one action, the glance, the corner control, the gear) from
`path-d03-0900.png`, the Map's corner control and the three name chips from `path-d13-map-0900.png`.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cloud_floor  # noqa: E402
import island_matte  # noqa: E402
import near_mid  # noqa: E402
from _common import H, W, Sprite, load_rgba, smoothstep  # noqa: E402

PT = 3.0                                   # device px per pt
REF_W, REF_H = 402.0, 874.0
U = 0.3253                                 # world units per plate point (facts doc)
ISLAND_BOX = near_mid.ISLAND               # plate points
HOME_C = ((ISLAND_BOX[0] + ISLAND_BOX[2]) / 2, (ISLAND_BOX[1] + ISLAND_BOX[3]) / 2)
HOME_BOX_U = (330.0, 257.0)                # spec 1.3
TILE_PUFF = 330.0                          # one cumulus of the sea tile, in tile px (measured on the tile)
FLOOR_TOP = 520                            # first row of the floor tile that is all cloud

# ---- the camera ---------------------------------------------------------------------------------------------------
A = np.array([201.0, 437.0])               # the anchor: the middle of the screen
S0 = 0.70                                  # the reference camera: the Map's tier-1 frame
L0 = np.array([0.0, (437.0 - 609.0) / S0])  # Home's centre is at (201, 609) there


class Cam:
    """scale (pt per unit) and the screen point (pt) of Home's centre; the look point follows."""

    def __init__(self, scale: float, home_pt: tuple[float, float]):
        self.s = scale
        self.home = home_pt
        self.L = np.array([(A[0] - home_pt[0]) / scale, (A[1] - home_pt[1]) / scale])

    def k(self, k: float):
        sk = S0 * (self.s / S0) ** k
        return sk, L0 + k * (self.L - L0)

    def pt(self, wx: float, wy: float, k: float = 1.0):
        sk, Lk = self.k(k)
        return A[0] + sk * (wx - Lk[0]), A[1] + sk * (wy - Lk[1]), sk


def ref_world(rx: float, ry: float) -> tuple[float, float]:
    """The world point that the reference camera shows at screen (rx, ry) pt."""
    return L0[0] + (rx - A[0]) / S0, L0[1] + (ry - A[1]) / S0


import os  # noqa: E402
DRIFT_SCALE = float(os.environ.get("POFU_DRIFT_SCALE", "1.0"))   # a what-if for the life meter: every drift speed times this

# Speeds in screen pt/s, section 3 as corrected in round 3 (docs/design/world-presentation-round3-look.md): the single source
# for the renderer and for `life_meter.py`. Nothing ambient but the birds above CAP; no full-width layer above FULL_WIDTH_CAP.
SPEEDS = {"far_clouds": 1.0, "horizon": 0.5, "floor_mid": 1.5, "floor_near": 3.0, "lip": 5.0, "puffs": 3.0, "whale": 5.0,
          "cloud_shadow": 8.0, "wisp": 4.0, "birds": 14.0}
CAP, FULL_WIDTH_CAP, MIN_PERIOD = 8.0, 5.0, 5.0

# ---- motion (section 3), off for stills -----------------------------------------------------------------------------

class Motion:
    def __init__(self, t: float = 0.0, on: bool = False):
        self.t, self.on = t, on

    def sw(self, amp: float, period: float, phase: float = 0.0) -> float:
        return amp * math.sin(2 * math.pi * self.t / period + phase) if self.on else 0.0

    def drift(self, speed: float) -> float:
        return speed * DRIFT_SCALE * self.t if self.on else 0.0


# ---- layers ---------------------------------------------------------------------------------------------------------

_cache: dict = {}


def sprite(name: str) -> Sprite:
    if name not in _cache:
        _cache[name] = Sprite(load_rgba(name))
    return _cache[name]


def floor_sprite() -> Sprite:
    if "floor" not in _cache:
        fl = cloud_floor.floor(light="day")[FLOOR_TOP:]
        _cache["floor"] = Sprite(fl)
    return _cache["floor"]


def over(canvas: np.ndarray, part: np.ndarray, y0: int, x0: int = 0) -> None:
    dst = canvas[y0:y0 + part.shape[0], x0:x0 + part.shape[1]]
    dst[...] = part + dst * (1 - part[..., 3:4])


DETILE = [(0, 0.0), (1, 0.31), (0, 0.58), (1, 0.84), (1, 0.12), (0, 0.43), (1, 0.67), (0, 0.91), (0, 0.22), (1, 0.52), (1, 0.97)]


def _tile_x(u: np.ndarray, n: np.ndarray, tw: float) -> np.ndarray:
    """Sample x for tile index `n` at tile-space `u`: alternate tiles are mirrored and offset (a fixed pseudo-random order)."""
    frac = u - n * tw
    mir = np.array([DETILE[int(i) % len(DETILE)][0] for i in range(int(n.min()) - 1, int(n.max()) + 2)])
    off = np.array([DETILE[int(i) % len(DETILE)][1] for i in range(int(n.min()) - 1, int(n.max()) + 2)])
    idx = (n - n.min() + 1).astype(int)
    frac = np.where(mir[idx] == 1, tw - frac, frac)
    return np.mod(frac + off[idx] * tw, tw)


def draw_floor(canvas: np.ndarray, puff_px: float, top_px: float, ramp_px: float, xoff_px: float, bottom_px: float = H,
               alpha: float = 1.0, src: Sprite | None = None, detile: bool = False, fade_px: float = 0.0, soften: float = 0.0) -> None:
    """One floor layer: the shipped sea tile scaled so that one cumulus (TILE_PUFF tile px) is `puff_px` device px,
    repeating across the width, from `top_px` down with a soft top edge of `ramp_px`. Below the tile's last row the
    last row continues (never reached at the sizes used: the quilted floor has 2600 rows).
    `detile`: alternate tiles are mirrored and offset in a fixed irregular order and joined by a cross-fade, so one dark
    lozenge does not come back every tile. `fade_px`: the top `fade_px` rows go from 30 % to full contrast (the horizon's
    first two puff rows)."""
    sp = src or floor_sprite()
    f = puff_px / TILE_PUFF                                      # device px per tile px
    y0 = max(int(math.floor(top_px)), 0)
    y1 = min(int(math.ceil(bottom_px)), H)
    if y1 <= y0:
        return
    arr, level = sp.mip(f)
    k = 2 ** level
    ys = np.arange(y0, y1, dtype=np.float64)
    my = np.clip((ys - top_px) / f / k, 0, arr.shape[0] - 1).astype(np.float32)
    myb = np.broadcast_to(my[:, None], (len(ys), W)).copy()
    u = (np.arange(W, dtype=np.float64) - xoff_px) / f / k
    if not detile:
        mx = np.mod(u, arr.shape[1]).astype(np.float32)
        part = cv2.remap(arr, np.broadcast_to(mx, (len(ys), W)).copy(), myb, cv2.INTER_LINEAR, borderMode=cv2.BORDER_WRAP)
    else:
        tw = float(arr.shape[1])
        n = np.floor(u / tw)
        frac = u - n * tw
        ov = 0.10 * tw
        wl = np.where(frac < ov, 1 - smoothstep_np(0.5 + 0.5 * frac / ov), 0.0)            # weight of tile n-1 at its right edge
        wr = np.where(frac > tw - ov, 1 - smoothstep_np(0.5 + 0.5 * (tw - frac) / ov), 0.0)
        part = 0
        for dn, w in ((-1, wl), (0, 1 - wl - wr), (1, wr)):
            if not np.any(w > 0):
                continue
            nn = n + dn
            mx = _tile_x(u, nn, tw).astype(np.float32)
            piece = cv2.remap(arr, np.broadcast_to(mx, (len(ys), W)).copy(), myb, cv2.INTER_LINEAR, borderMode=cv2.BORDER_WRAP)
            part = part + piece * w[None, :, None].astype(np.float32)
    if soften > 0:                                               # lift the tile's dark lozenges halfway to their surround
        blur = cv2.GaussianBlur(part, (0, 0), 0.30 * puff_px)
        lift = np.maximum(blur[..., :3] - part[..., :3], 0) * part[..., 3:4]
        part = np.concatenate([part[..., :3] + soften * lift, part[..., 3:]], -1)
    ramp = np.clip((ys - top_px) / max(ramp_px, 1.0), 0, 1).astype(np.float32)
    ramp = ramp * ramp * (3 - 2 * ramp) * alpha
    if fade_px > 0:
        a = part[..., 3:4]
        m = part[..., :3].sum(1, keepdims=True) / np.maximum(a.sum(1, keepdims=True), 1e-4)       # row mean of the straight colour
        t = np.clip((ys - top_px) / fade_px, 0, 1).astype(np.float32)
        c = (0.30 + 0.70 * t * t * (3 - 2 * t))[:, None, None]
        part = np.concatenate([a * m * (1 - c) + part[..., :3] * c, a], -1)
    part = part * ramp[:, None, None]
    over(canvas, part, y0)


def smoothstep_np(x: np.ndarray) -> np.ndarray:
    x = np.clip(x, 0, 1)
    return x * x * (3 - 2 * x)


def blob_mask(h: int, w: int, circles, blur: float) -> np.ndarray:
    m = np.zeros((h, w), np.float32)
    for cx, cy, r in circles:
        cv2.circle(m, (int(cx), int(cy)), int(r), 1.0, -1, cv2.LINE_AA)
    return cv2.GaussianBlur(m, (0, 0), blur)


def make_tower(seed: int = 1, wide: int = 440, high: int = 520) -> Sprite:
    """A billowing cloud column cut from the sea tile's own cumulus: a stand-in for Codex's pilot tower."""
    key = f"tower{seed}"
    if key in _cache:
        return _cache[key]
    rng = np.random.default_rng(seed)
    circles = []
    rows = [(0.76, 4, 0.14, 0.50), (0.58, 3, 0.15, 0.34), (0.40, 3, 0.13, 0.22), (0.24, 2, 0.11, 0.12), (0.12, 1, 0.09, 0.0)]
    for yf, n, rf, spread in rows:
        for i in range(n):
            xf = 0.5 + (spread * (i / max(n - 1, 1) - 0.5) if n > 1 else 0) + rng.uniform(-0.03, 0.03)
            circles.append((xf * wide, yf * high + rng.uniform(-8, 8), rf * wide * rng.uniform(0.9, 1.1)))
    m = blob_mask(high, wide, circles, 5.0)
    m = np.clip((m - 0.35) / 0.45, 0, 1)
    shade_ = 1 - 0.18 * (1 - cv2.GaussianBlur(m, (0, 0), 22))        # rim darker, body lit
    shade_ *= 1.05 - 0.10 * np.linspace(0, 1, high, dtype=np.float32)[:, None] * 0 + 0.0
    fl = cloud_floor.floor(light="day")
    x0 = 40 + 340 * (seed - 1)
    tex = fl[900:900 + high, x0:x0 + wide, :3]                   # one block of the quilted cumulus, no tiling, no seam
    top_lift = np.linspace(0.10, -0.04, high, dtype=np.float32)[:, None, None]
    rgb = np.clip(tex * shade_[..., None] + top_lift, 0, 1) * np.float32([1.0, 1.0, 1.02])
    rgba = np.concatenate([np.clip(rgb, 0, 1), m[..., None]], -1)
    _cache[key] = Sprite(rgba)
    return _cache[key]


def shade_ellipse(canvas: np.ndarray, cx: float, cy: float, rx: float, ry: float, opacity: float, rgb=(0.33, 0.35, 0.52)) -> None:
    x0, x1 = max(int(cx - rx) - 1, 0), min(int(cx + rx) + 2, W)
    y0, y1 = max(int(cy - ry) - 1, 0), min(int(cy + ry) + 2, H)
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    r = np.hypot((xx - cx) / max(rx, 1e-3), (yy - cy) / max(ry, 1e-3))
    a = (opacity * np.interp(r, [0, 0.5, 1], [1, 0.45, 0])).astype(np.float32)[..., None]
    dst = canvas[y0:y1, x0:x1]
    dst[...] = np.concatenate([np.float32(rgb) * a, a], -1) + dst * (1 - a)


# ---- the scene: islands on the world ------------------------------------------------------------------------------

class Slot:
    def __init__(self, name: str, centre, box, holds: str, art=None, chip=None, tappable=True):
        self.name, self.centre, self.box, self.holds, self.art, self.chip = name, centre, box, holds, art, chip


def home_layer(stage: int):
    rgba, (x0, y0) = island_matte.island_layer("day", stage)
    return Sprite(rgba), ((x0 - HOME_C[0]) * U, (y0 - HOME_C[1]) * U, rgba.shape[1] / 2 * U, rgba.shape[0] / 2 * U)


def slot_art(name: str) -> Sprite:
    return sprite("world-koke-island-4" if name == "koke" else "world-caglayan-island-day-4")


def lane_for(boxes, top: float = 59.0, bottom: float = 740.0, margin: float = 24.0, slack: float = 4.0):
    """The tallest band of rows (pt) that is at least `margin` from every box, between `top` and `bottom`; the backdrop's
    far isles and whale live there (C6). `slack` keeps the bobs inside it."""
    blocked = np.zeros(int(REF_H), bool)
    for b in boxes:
        blocked[max(int(math.floor(b[1] - margin)), 0):max(int(math.ceil(b[3] + margin)), 0)] = True
    first = min(b[1] for b in boxes) - margin               # the sky above the topmost box is not the lane: the horizon's gap is
    best, cur0, cur = (top, top), None, 0
    for y in range(int(top), int(bottom)):
        if not blocked[y]:
            cur0 = y if cur0 is None else cur0
            if y + 1 - cur0 > best[1] - best[0] and y + 1 > first + 1:
                best = (cur0, y + 1)
        else:
            cur0 = None
    return best[0] + slack, best[1] - slack


class Backdrop:
    """Section 2's layers, drawn through one camera. `light` is day; every number is in pt at the reference camera.
    `keepout`: the boxes (pt) of the frame's subjects, slots and chrome; the far isles and the whale are placed in the
    tallest band that is 24 pt clear of all of them (C6)."""

    FAR_SC = 0.16                                   # pt per master px for the far picture (isles, whale), at most

    def __init__(self, cam: Cam, horizon_ref: float = 463.0, mo: Motion | None = None, keepout=(), whale_top: bool = False):
        self.cam, self.mo = cam, mo or Motion()
        self.horizon = horizon_ref
        self.features: list[dict] = []
        self.keepout = list(keepout)
        self.whale_top = whale_top

    # -- helpers
    def screen_y(self, ref_y: float, k: float) -> tuple[float, float]:
        wx, wy = ref_world(A[0], ref_y)
        x, y, sk = self.cam.pt(wx, wy, k)
        return y, sk / S0

    def draw_sky(self, out: np.ndarray) -> None:
        sky = sprite("world-home-sky-sky-day-0")
        sky.draw(out, 0, 0, W, H * 1.25, replicate=True)

    def draw_far(self, out: np.ndarray) -> None:
        mo = self.mo
        # far clouds (a drift tile), k 0.12
        wx, wy = ref_world(0, 24.0)
        _, y, sk = self.cam.pt(wx, wy, 0.12)
        m = sk / S0
        far = sprite("world-home-sky-far-day-0")
        w = 2048 * 0.19 * 3.0 * m * PT / 3.0
        far.draw(out, mo.drift(SPEEDS["far_clouds"]) * PT, y * PT, w, w * 910 / 2048, wrap_x=w)
        # far isles (k 0.25) and the whale (k 0.35), in the lane that C6 leaves
        import json as _j
        from _common import RESOURCES
        lay = {l["id"]: l for l in _j.loads((RESOURCES / "Plates" / "skyset-home.json").read_text())["lights"]["day"]["layers"]}
        order = [("isle_falls", 2, 9.0, 0.0, 0.10), ("isle_dome", 2, 13.0, 3.1, 0.05), ("whale", 4, 12.0, 0.6, 0.60),
                 ("isle_house", 2, 11.0, 1.7, 0.15), ("isle_crystal", 2, 10.0, 4.4, 0.00)]
        y0, y1 = lane_for(self.keepout) if self.keepout else (100.0, 200.0)
        whale_lane = None
        top_ids = ("whale",) if self.whale_top else ("isle_dome", "isle_crystal")
        if self.keepout:   # the sky above the topmost subject is a run of 0.2 of the height (C2): the whale (Home on top) or two isles go there
            lane = (63.0, min(b[1] for b in self.keepout) - 24.0 - 4.0)
            if lane[1] - lane[0] >= 40.0 and lane[1] <= 0.5 * REF_H:
                whale_lane = lane
        lane_h = y1 - y0
        sc = min(self.FAR_SC, lane_h / max(lay[i[0]]["size"][1] for i in order) / 1.05)
        if whale_lane:
            order = [o for o in order if o[0] not in top_ids] + [o for o in order if o[0] in top_ids]

        sizes = {i[0]: (lay[i[0]]["size"][0] * sc, lay[i[0]]["size"][1] * sc) for i in order}
        if whale_lane and self.whale_top and sizes["whale"][1] > whale_lane[1] - whale_lane[0]:
            whale_lane = None
        gap = max((REF_W - sum(v[0] for v in sizes.values())) / (len(order) + 1), 0.0)
        x = gap
        feats = []
        for iid, amp, per, ph, rel in order:
            wpt, hpt = sizes[iid]
            top = y0 + (lane_h - hpt) * rel
            if iid in top_ids and whale_lane:
                top = whale_lane[0] + (whale_lane[1] - whale_lane[0] - hpt) * (0.5 if iid != "isle_crystal" else 0.3)
            xs = x + wpt / 2
            x += wpt + gap
            sp = sprite(lay[iid]["asset"])
            if iid == "whale":
                xs += mo.drift(SPEEDS["whale"])
                span = REF_W + 2 * 60 + wpt
                xs = ((xs + wpt / 2 + 60) % span) - 60 - wpt / 2 if mo.on else xs
                yy = top + mo.sw(amp, per, ph)
                if mo.on:
                    ang = mo.sw(1.5, 15.0, 1.1)
                    arr = sp.mips[0]
                    rot = cv2.warpAffine(arr, cv2.getRotationMatrix2D((arr.shape[1] / 2, arr.shape[0] / 2), ang, 1.0), (arr.shape[1], arr.shape[0]),
                                         flags=cv2.INTER_LINEAR, borderValue=0)
                    Sprite(np.concatenate([rot[..., :3] / np.maximum(rot[..., 3:], 1e-4), rot[..., 3:]], -1)).draw(
                        out, (xs - wpt / 2) * PT, yy * PT, wpt * PT, hpt * PT)
                else:
                    sp.draw(out, (xs - wpt / 2) * PT, yy * PT, wpt * PT, hpt * PT)
            else:
                yy = top + mo.sw(amp, per, ph)
                sp.draw(out, (xs - wpt / 2) * PT, yy * PT, wpt * PT, hpt * PT)
            feats.append({"id": iid, "box": [xs - wpt / 2, top, xs + wpt / 2, top + hpt]})
        self.features += feats

    def draw_puffs(self, out: np.ndarray) -> None:
        """Cloud puffs, k 0.6: the sea tile's mid-clouds sibling (`mid`) as a band, windowed. (Stand-in for 5 to 7 cut-outs.)"""
        mo = self.mo
        mid = sprite("world-home-sky-mid-day-0")
        y, m = self.screen_y(300.0, 0.6)
        w = 560.0 * m * PT
        h = w * 1096 / 2048
        rows = None
        from _common import window_rows
        rows = window_rows(y * PT, y * PT + h, 50 * PT * m, 0.0)
        mid.draw(out, mo.drift(SPEEDS["puffs"]) * PT, y * PT, w, h, wrap_x=w, rows=rows)

    def draw_floor_layers(self, out: np.ndarray, upto: int = 3) -> None:
        """horizon band (12 pt puffs), middle (40), near (90). The lip is `draw_lip`, in front of the islands."""
        mo = self.mo
        specs = [(12.0, 0.05, self.horizon, 22.0, SPEEDS["horizon"], 0.0, 11.0), (40.0, 0.45, self.horizon + 9, 16.0, SPEEDS["floor_mid"], 3.0, 11.0),
                 (90.0, 0.85, self.horizon + 60, 30.0, SPEEDS["floor_near"], 5.0, 17.0)]
        for i, (puff, k, top, ramp, dr, amp, per) in enumerate(specs[:upto]):
            y, m = self.screen_y(top, k)
            y += mo.sw(amp, per, per * 0.13)
            draw_floor(out, puff * m * PT, y * PT, ramp * m * PT, mo.drift(dr) * PT, detile=True, fade_px=(2 * puff * m * PT if i == 0 else 0.0),
                       soften=0.6 if i < 2 else 0.0)

    def draw_lip(self, out: np.ndarray, top_ref: float = 740.0) -> None:
        y, m = self.screen_y(top_ref, 1.25)
        y += self.mo.sw(8.0, 23.0, 0.9)
        draw_floor(out, 160.0 * m * PT, y * PT, 60.0 * m * PT, self.mo.drift(SPEEDS["lip"]) * PT, detile=True)
        self.features.append({"id": "lip", "box": [0, y, REF_W, REF_H]})


def island_world_rect(cam: Cam, centre, box):
    x, y, sk = cam.pt(centre[0] - box[0] / 2, centre[1] - box[1] / 2)
    return x, y, box[0] * sk, box[1] * sk


# ---- chrome, cut from shipped frames --------------------------------------------------------------------------------

def _cut(arr: np.ndarray, rect, radius: float, inset: float = 1.2) -> np.ndarray:
    x0, y0, x1, y1 = rect
    ss = 4
    w, h = x1 - x0, y1 - y0
    m = Image.new("L", (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle((inset * ss, inset * ss, (w - inset) * ss - 1, (h - inset) * ss - 1), radius * ss, fill=255)
    a = np.asarray(m.resize((w, h), Image.LANCZOS), np.float32)[..., None] / 255
    rgb = arr[y0:y1, x0:x1] / 255.0
    return np.concatenate([rgb, a], -1).astype(np.float32)


class Chrome:
    """Every piece is a rectangle of a shipped 1206 x 2622 frame with a rounded mask; size in device px."""

    def __init__(self, frames: Path):
        d03 = np.asarray(Image.open(frames / "path-d03-0900.png").convert("RGB"), np.float32)
        m13 = np.asarray(Image.open(frames / "path-d13-map-0900.png").convert("RGB"), np.float32)
        self.p = {
            "card": _cut(d03, (60, 1884, 1146, 2066), 56),
            "action": _cut(d03, (412, 2103, 792, 2275), 86),
            "glance": _cut(d03, (60, 2312, 880, 2496), 92),
            "corner_home": _cut(d03, (990, 2340, 1146, 2496), 78),
            "gear": _cut(d03, (1014, 210, 1146, 342), 66),
            "corner_map": _cut(m13, (990, 2340, 1146, 2496), 78),
            "chip_home": _cut(m13, (503, 1195, 503 + 271, 1195 + 78), 39),
            "chip_koke": _cut(m13, (246, 1951, 246 + 145, 1951 + 78), 39),
            "chip_caglayan": _cut(m13, (778, 2013, 778 + 220, 2013 + 78), 39),
        }
        self.sprites = {k: Sprite(v) for k, v in self.p.items()}

    def size_pt(self, key: str) -> tuple[float, float]:
        a = self.p[key]
        return a.shape[1] / PT, a.shape[0] / PT

    def put(self, out: np.ndarray, key: str, x_pt: float, y_pt: float, flip: bool = False) -> list[float]:
        a = self.p[key]
        sp = self.sprites[key] if not flip else Sprite(a[:, ::-1])
        sp.draw(out, round(x_pt * PT), round(y_pt * PT), a.shape[1], a.shape[0])
        return [x_pt, y_pt, x_pt + a.shape[1] / PT, y_pt + a.shape[0] / PT]


def put_home_chrome(out: np.ndarray, ch: Chrome, with_corner: bool = True) -> list[dict]:
    """Chrome positions as shipped on the Home frame (path-d03): everything in its own place."""
    items = []
    for key, x, y in (("card", 60, 1884), ("action", 412, 2103), ("glance", 60, 2312), ("corner_home", 990, 2340), ("gear", 1014, 210)):
        items.append({"id": key, "box": ch.put(out, key, x / PT, y / PT)})
    return items


# ---- stills -------------------------------------------------------------------------------------------------------

def to_png(out: np.ndarray, path: Path) -> None:
    rgb = np.clip(out[..., :3], 0, 1)
    Image.fromarray((rgb * 255 + 0.5).astype(np.uint8)).save(path)


def save_meta(path: Path, meta: dict) -> None:
    path.with_suffix(".json").write_text(json.dumps(meta, indent=1))


# ---- the Map ---------------------------------------------------------------------------------------------------------

TIER1 = {  # island, world centre (units, Home at 0,0), box
    "koke": ((-150.0, -470.0), (250.0, 166.0)),
    "caglayan": ((150.0, -540.0), (212.0, 150.0)),
}
TIER2 = [((-190.0, -1050.0), (230.0, 150.0)), ((20.0, -1100.0), (230.0, 150.0)), ((200.0, -950.0), (230.0, 150.0))]
CHIP_H = 26.0        # pt
CHIP_GAP = 6.0       # pt between an island's box and its chip


def map_slots(stage: int, tier: int, flip: bool):
    """The slots of a Map frame: holds = island | veil | tower. stage 1: Koke veiled, Caglayan a tower; 2: Koke open,
    Caglayan veiled; 3: both open. Tier 2 adds three places above, the first veiled and two towers. `flip`: today's order
    (Home on top, the rest below it)."""
    sg = -1.0 if flip else 1.0
    holds = {1: ("veil", "tower"), 2: ("island", "veil"), 3: ("island", "island")}[stage] if tier == 1 else ("island", "island")
    slots = [Slot("home", (0.0, 0.0), HOME_BOX_U, "island")]
    for (name, (c, b)), h in zip(TIER1.items(), holds):
        slots.append(Slot(name, (c[0], sg * c[1]), b, h))
    if tier == 2:
        for (c, b), h, n in zip(TIER2, ("veil", "tower", "tower"), "abc"):
            slots.append(Slot("t2" + n, (c[0], sg * c[1]), b, h))
    return slots


def map_camera(slots, tier: int, flip: bool) -> Cam:
    if not flip:
        s, foot = (0.70, 699.0) if tier == 1 else (0.47, 699.0)
        xs = [x for sl in slots for x in (sl.centre[0] - sl.box[0] / 2, sl.centre[0] + sl.box[0] / 2)]
        home_x = 201.0 - (min(xs) + max(xs)) / 2 * s
        return Cam(s, (home_x, foot - HOME_BOX_U[1] * s / 2))
    # Home on top: fit the constellation (boxes and chips) to x 16..386, y 118..790, scale clamped to 0.45 at least
    xs = [x for sl in slots for x in (sl.centre[0] - sl.box[0] / 2, sl.centre[0] + sl.box[0] / 2)]
    y0 = min(sl.centre[1] - sl.box[1] / 2 for sl in slots)
    s = 0.45
    for _ in range(20):                                           # chips are 26 pt whatever the scale
        y1 = max(sl.centre[1] + sl.box[1] / 2 + ((CHIP_GAP + CHIP_H) / s if sl.holds == "island" else 0.0) for sl in slots)
        s = max(0.45, min(370.0 / (max(xs) - min(xs)), (790.0 - 118.0) / (y1 - y0)))
    y1 = max(sl.centre[1] + sl.box[1] / 2 + ((CHIP_GAP + CHIP_H) / s if sl.holds == "island" else 0.0) for sl in slots)
    top = 118.0 + max(0.0, (790.0 - 118.0 - (y1 - y0) * s) / 2)
    home_x = 201.0 - (min(xs) + max(xs)) / 2 * s
    return Cam(s, (home_x, top - y0 * s))


def render_map(ch: Chrome, stage: int, tier: int, flip: bool, mo: Motion | None = None, hours_home: int = 4):
    mo = mo or Motion()
    slots = map_slots(stage, tier, flip)
    cam = map_camera(slots, tier, flip)
    out = np.zeros((H, W, 4), np.float32)
    home_y, _ = cam.pt(0, 0)[1], 0
    horizon = 463.0 if not flip else cam.pt(0, 0)[1] + 150.0 * 0 + 30
    hs, (hx, hy, hw, hh) = home_layer(hours_home)[0], home_layer(hours_home)[1]
    keep = []
    for sl in slots:                                   # the boxes C6 keeps the backdrop away from, before anything is drawn
        x, y, w, h = island_world_rect(cam, sl.centre, sl.box)
        if sl.holds == "island":
            keep.append([x, y, x + w, y + h + CHIP_GAP + ch.size_pt("chip_" + sl.name)[1]])
            if sl.name == "home":
                px, py, _s = cam.pt(hx, hy)
                keep.append([px, py, px + hw * _s, py + hh * _s])
        else:
            tw, th = sl.box[0] * 0.78, sl.box[1] * 1.25
            tx, ty, sk = cam.pt(sl.centre[0] - tw / 2, sl.centre[1] + sl.box[1] / 2 - th)
            keep.append([tx, ty, tx + tw * sk, ty + th * sk])
    keep.append([318.0, 769.0, 370.0, 821.0])           # the corner control
    bd = Backdrop(Cam(S0, (201.0, 609.0)), horizon_ref=horizon if flip else 463.0, mo=mo, keepout=keep, whale_top=flip)   # a Map frame is fixed: the backdrop sits at its reference
    if flip:
        # today's order: the sea starts under Home's lower half, as the shipped Map's does
        bd.horizon = max(0.40 * REF_H, 0.0) * 1.0
    bd.draw_sky(out)
    bd.draw_far(out)
    bd.draw_puffs(out)
    bd.draw_floor_layers(out)
    subjects, chips = [], []
    for i, sl in enumerate(slots):
        x, y, w, h = island_world_rect(cam, sl.centre, sl.box)
        _, _, sk = cam.pt(0, 0)
        bob = mo.sw(2.0, 6.0 + 1.5 * i, i * 1.9)
        cxp, cyp = x + w / 2, y + h / 2 + bob
        if sl.holds == "island":
            shade_ellipse(out, cxp * PT, (y + h * 0.90) * PT, w * 0.48 * PT, w * 0.13 * PT, 0.34)
            if sl.name == "home":
                px, py, _s = cam.pt(hx, hy)
                hs.draw(out, px * PT, (py + bob) * PT, hw * _s * PT, hh * _s * PT)
                art_box = [px, py, px + hw * _s, py + hh * _s]
            else:
                art = slot_art(sl.name)
                aw = sl.box[0] * _s_of(cam)
                art.draw(out, (cxp - aw / 2) * PT, (cyp - aw * art.h / art.w / 2) * PT, aw * PT, aw * art.h / art.w * PT)
            chip = "chip_" + {"home": "home", "koke": "koke", "caglayan": "caglayan"}[sl.name]
            cw, chh = ch.size_pt(chip)
            cy0 = y + h + CHIP_GAP
            cb = ch.put(out, chip, cxp - cw / 2, cy0)
            subjects.append({"id": sl.name, "type": "island", "box": [x, y, x + w, y + h + CHIP_GAP + chh], "island": [x, y, x + w, y + h],
                             "chip": cb, "tappable": True, "w_pt": w,
                             **({"art": art_box} if sl.name == "home" else {})})
        else:
            tw, th = sl.box[0] * 0.78, sl.box[1] * 1.25
            bottom = sl.centre[1] + sl.box[1] / 2
            tx, ty, sk = cam.pt(sl.centre[0] - tw / 2, bottom - th)
            if sl.holds == "veil":
                art = slot_art(sl.name) if sl.name in ("koke", "caglayan") else slot_art("koke")
                aw = sl.box[0] * sk
                ghost = art.mips[0].copy()
                g = ghost[..., :3].mean(-1, keepdims=True)
                ghost[..., :3] = (ghost[..., :3] * 0.4 + g * 0.6 + np.float32([0.18, 0.18, 0.30]) * ghost[..., 3:]) * 1.0
                Sprite(np.concatenate([ghost[..., :3] / np.maximum(ghost[..., 3:], 1e-4), ghost[..., 3:]], -1)).draw(
                    out, (cxp - aw / 2) * PT, (cyp - aw * art.h / art.w / 2 + 6) * PT, aw * PT, aw * art.h / art.w * PT, alpha=0.62)
            bil = 1 + (0.02 * math.sin(2 * math.pi * mo.t / 20.0 + i) if mo.on else 0.0)
            tower = make_tower(i % 3 + 1)
            tw2, th2 = tw * sk * bil, th * sk * bil
            tower.draw(out, (tx + tw * sk / 2 - tw2 / 2) * PT, (ty + th * sk - th2 + bob) * PT, tw2 * PT, th2 * PT,
                       alpha=0.80 if sl.holds == "veil" else 1.0)
            subjects.append({"id": sl.name, "type": sl.holds, "box": [tx, ty, tx + tw * sk, ty + th * sk], "tappable": False})
    bd.draw_lip(out)
    chrome = [{"id": "corner_map", "box": ch.put(out, "corner_map", 314.0 + 4, 766.0 + 3)}]
    meta = {"kind": "map", "scale": cam.s, "order": "homefirst" if flip else "journey", "horizon": bd.horizon, "stage": stage, "tier": tier,
            "hero": next(s for s in subjects if s["id"] == "home")["box"], "subjects": subjects, "chrome": chrome, "features": bd.features}
    return out, meta


def _s_of(cam: Cam) -> float:
    return cam.pt(0, 0)[2]


# ---- mid ---------------------------------------------------------------------------------------------------------------

MID_SCALE = 1.145
STAGE_OF_LEVEL = {1: 9, 4: 6, 10: 0}      # the plates count down: stage 0 is level 10, the richest


def render_mid(ch: Chrome, level: int, mo: Motion | None = None):
    mo = mo or Motion()
    cam = Cam(MID_SCALE, (201.0, 383.0))
    out = np.zeros((H, W, 4), np.float32)
    layer, (hx, hy, hw, hh) = home_layer(STAGE_OF_LEVEL[level])
    px, py, sk = cam.pt(hx, hy)
    keep = [[px, py, px + hw * sk, py + hh * sk]] + [[x / PT, y / PT, x / PT + ch.size_pt(k)[0], y / PT + ch.size_pt(k)[1]] for k, x, y in
                                                      (("card", 60, 1884), ("action", 412, 2103), ("glance", 60, 2312), ("corner_home", 990, 2340), ("gear", 1014, 210))]
    bd = Backdrop(cam, mo=mo, keepout=keep)
    bd.draw_sky(out)
    bd.draw_far(out)
    bd.draw_puffs(out)
    bd.draw_floor_layers(out)
    shade_ellipse(out, 201.0 * PT, (383 + 330 * 0.78 * 0.5 * sk / MID_SCALE * 0 + 0.40 * 257 * sk) * PT, 330 * sk * 0.46 * PT, 330 * sk * 0.12 * PT, 0.30)
    layer.draw(out, px * PT, py * PT, hw * sk * PT, hh * sk * PT)
    # the characters, on the plate's own feet
    pil = Image.fromarray((np.clip(out[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8)).convert("RGBA")
    s_pt = sk * U * PT                                        # device px per plate point
    chars = []
    for feet, art, w in ((near_mid.MOCHI_FEET, near_mid.MOCHI, near_mid.MOCHI_W), (near_mid.POFU_FEET, near_mid.POFU, near_mid.POFU_W)):
        fx = W / 2 + (feet[0] - HOME_C[0]) * s_pt
        fy = 383 * PT + (feet[1] - HOME_C[1]) * s_pt
        near_mid.stand(pil, art, fx, fy, w * s_pt, "day", 0, 0.35)
        ar = near_mid.tight(art)
        chars.append([ (fx - w * s_pt / 2) / PT, (fy - w * s_pt * ar.height / ar.width) / PT, (fx + w * s_pt / 2) / PT, fy / PT])
    out2 = np.concatenate([np.asarray(pil.convert("RGB"), np.float32) / 255, np.ones((H, W, 1), np.float32)], -1)
    lip = Backdrop(cam, mo=mo)
    lip.draw_lip(out2)
    bd.features += lip.features
    chrome = put_home_chrome(out2, ch)
    box = [px, py, px + hw * sk, py + hh * sk]
    meta = {"kind": "mid", "level": level, "scale": MID_SCALE, "hero": box, "horizon": bd.horizon,
            "subjects": [{"id": "island", "type": "island", "box": box, "tappable": True},
                         {"id": "pofu", "type": "char", "box": chars[1]}, {"id": "mochi", "type": "char", "box": chars[0]}],
            "chrome": chrome, "features": bd.features}
    return out2, meta


# ---- near --------------------------------------------------------------------------------------------------------------

def render_near(ch: Chrome, ppu: float):
    im = near_mid.near("pofu", "day", ppu, "macro", feet_y=0.60)
    out = np.concatenate([np.asarray(im.convert("RGB"), np.float32) / 255, np.ones((H, W, 1), np.float32)], -1)
    # the back control: the corner control mirrored to the left, bottom left (a stand-in cut from the Home frame)
    chrome = [{"id": "back_control", "box": ch.put(out, "corner_home", 16.0 + 4, 766.0 + 3, flip=True)}]
    s = near_mid.s_of(ppu)
    pw = near_mid.POFU_W * s
    ar = near_mid.tight(near_mid.POFU)
    feet = [W / 2 / PT, 0.60 * REF_H]
    box = [feet[0] - pw / 2 / PT, feet[1] - pw * ar.height / ar.width / PT, feet[0] + pw / 2 / PT, feet[1]]
    ix0 = (near_mid.ISLAND[0] - near_mid.POFU_FEET[0]) * s / PT + feet[0]
    ix1 = (near_mid.ISLAND[2] - near_mid.POFU_FEET[0]) * s / PT + feet[0]
    iy0 = (near_mid.ISLAND[1] - near_mid.POFU_FEET[1]) * s / PT + feet[1]
    iy1 = (near_mid.ISLAND[3] - near_mid.POFU_FEET[1]) * s / PT + feet[1]
    meta = {"kind": "near", "ppu": ppu, "feet": feet, "hero": box, "pofu_w_pt": pw / PT,
            "subjects": [{"id": "pofu", "type": "char", "box": box}, {"id": "lawn", "type": "island", "box": [ix0, iy0, ix1, iy1], "tappable": False}],
            "chrome": chrome, "features": []}
    return out, meta


# ---- the floor ladder ------------------------------------------------------------------------------------------------

def render_ladder():
    out = np.zeros((H, W, 4), np.float32)
    sprite("world-home-sky-sky-day-0").draw(out, 0, 0, W, H * 1.25, replicate=True)
    sizes = [12.0, 40.0, 90.0, 160.0]
    cw = W // 4
    for i, p in enumerate(sizes):
        col = np.zeros((H, cw, 4), np.float32)
        tmp = np.zeros((H, W, 4), np.float32)
        top = 0.30 * H
        draw_floor(tmp, p * PT, top, p * PT * 0.5, 0, bottom_px=top + floor_sprite().h * p * PT / TILE_PUFF)   # only the rows the tile has
        col[...] = tmp[:, i * cw:(i + 1) * cw]
        over(out, col, 0, i * cw)
        cv2.line(out, (i * cw, 0), (i * cw, H), (1, 1, 1, 1), 2)
    return out, {"kind": "floor", "sizes_pt": sizes}


# ---- main ---------------------------------------------------------------------------------------------------------------

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--frames", type=Path, required=True, help="directory holding path-d03-0900.png and path-d13-map-0900.png")
    ap.add_argument("--only", nargs="+", default=["map", "mid", "near", "floor"], choices=["map", "mid", "near", "floor"])
    args = ap.parse_args(argv)
    args.out.mkdir(parents=True, exist_ok=True)
    ch = Chrome(args.frames)

    def emit(name, res):
        out, meta = res
        meta["name"] = name
        to_png(out, args.out / f"{name}.png")
        save_meta(args.out / f"{name}.png", meta)
        print(name, flush=True)

    if "map" in args.only:
        for order, flip in (("journey", False), ("homefirst", True)):
            for st in (1, 2, 3):
                emit(f"map-{order}-stage{st}", render_map(ch, st, 1, flip))
            emit(f"map-{order}-tier2", render_map(ch, 3, 2, flip))
    if "mid" in args.only:
        for lv in (1, 4, 10):
            emit(f"mid-level{lv:02d}", render_mid(ch, lv))
    if "near" in args.only:
        emit("near-rest", render_near(ch, 4.5))
        emit("near-limit", render_near(ch, 7.4))
    if "floor" in args.only:
        emit("floor-puff-ladder", render_ladder())
    return 0


if __name__ == "__main__":
    sys.exit(main())
