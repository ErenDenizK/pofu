#!/usr/bin/env python3
"""Match proof: the script is re-rendered until it looks like the painted concept the founder picked.

    python3 tools/proof/match.py --refs R1_DIR --frames FRAMES --takes TAKES_DIR --art ART_DIR --out OUT_DIR [--only map mid near]

docs/design/world-concepts-plan.md, "How the pick becomes the spec". The picks (pofu-art batch 112, review.yaml):
map-locked t1 (order A, the journey), mid-locked t1, near-locked t2. The target of a distance is the take cut to the
phone frame with the real chrome pasted back (`concept_fit.fit_take`); the match is `composition.py`'s still with the
following added, each one a thing the Swift build can have (grade, shader, cloud kit, one new art layer):

  Map    the horizon is lifted and dissolved into haze; far isles and whale are hazed by depth; the floor is graded
         (warm tops, lavender sides: contrast about the local mean); a cloud bank (the 109 lip, pick 2) and a cast
         shadow under every island, and a thin bank in front of its foot.
  Mid    the same bank and a stronger, wider shadow under the earth body; large graded cloud forms behind the controls.
  Near   v2 section 5's thin lens at a 10.5 degree camera: per-row blur r = N s |delta| / (D + delta), the focal plane at
         Pofu's feet; the 110 focal ground patch (pick 4) under him, clipped to the lawn and tinted by the plate; the
         107 dressing picks on and behind the focal row; one soft foreground layer over the rim (a STAND-IN: new art
         in the build); a contact shadow.

Outputs per distance: `match-<distance>.png` (1206 x 2622), `pair-<distance>.png` (target | match), the drift of the
match from the target (concept_fit's edge matching, on the R1 boxes), and per-band luminance and saturation of both
(`bands-<distance>.txt`), so the gap is a number.

Needs numpy, OpenCV, Pillow, and what composition.py needs (the matte cache, `POFU_BIREFNET`).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import composition as C  # noqa: E402
import concept_fit  # noqa: E402
import near_mid  # noqa: E402
from _common import H, W, Sprite  # noqa: E402

PT = 3.0
HAZE = np.float32([0.90, 0.89, 0.98])          # the air at the horizon, read off the picked Map (rows 380 to 440 pt)
MAP_HORIZON_REF = 392.0                         # pt: the floor's first row; the picked Map has no line, the air takes it
SHADOW_RGB = np.float32([0.46, 0.45, 0.72])     # cast shadow on cloud: a lavender, never grey
ART: Path = Path(".")                           # set by main: the folder of the Codex picks
CTX = {"kind": "map"}
PICKS = {"map": "plate__x-concept-map-locked--t1", "mid": "plate__x-concept-mid-locked--t1", "near": "plate__x-concept-near-locked--t2"}
STILLS = {"map": "map-journey-stage3", "mid": "mid-level10", "near": "near-rest"}


# ---------------------------------------------------------------- small helpers

def smooth(x):
    x = np.clip(x, 0, 1)
    return x * x * (3 - 2 * x)


def veil_rows(out: np.ndarray, y0_pt: float, y1_pt: float, a0: float, a1: float, colour=HAZE, power: float = 1.0) -> None:
    """Mix `colour` into the rows y0..y1 (pt) with an alpha that goes a0 to a1, smoothly; outside it holds the end values
    only below y1 (above y0 it is a0)."""
    ys = np.arange(H, dtype=np.float32) / PT
    t = smooth((ys - y0_pt) / max(y1_pt - y0_pt, 1e-3)) ** power
    a = a0 + (a1 - a0) * t
    if a0 > a1:                                  # a fade-out veil: nothing above its first row
        a = np.where(ys < y0_pt, 0.0, a)
    a = a[:, None, None]
    out[..., :3] = out[..., :3] * (1 - a) + colour * a * out[..., 3:4]


def grade_layer(layer: np.ndarray, gain: float = 1.55, sigma: float = 48.0, warm: float = 0.24, cool: float = 0.30) -> np.ndarray:
    """Cloud contrast about the local mean (the sea tile is a pale fog; the picked clouds have cream tops and lavender
    sides), warm in the lights, lavender in the shadows. Works on a premultiplied RGBA layer, returns the same."""
    a = layer[..., 3:4]
    rgb = layer[..., :3] / np.maximum(a, 1e-4)
    mean = cv2.GaussianBlur(rgb, (0, 0), sigma)
    d = rgb - mean
    lum = d.mean(-1, keepdims=True)
    out = mean + d * gain
    sh = np.clip(-lum * 6.0, 0, 1)
    li = np.clip(lum * 6.0, 0, 1)
    out = out * (1 - cool * sh) + SHADOW_RGB * 1.12 * cool * sh
    out = out + li * warm * np.float32([0.05, 0.02, -0.07])
    out = np.clip(out, 0, 1)
    return np.concatenate([out * a, a], -1).astype(np.float32)


def lip_bank() -> np.ndarray:
    """The 109 lip (pick 2): straight RGBA, trimmed to its own box."""
    if "lip" not in CTX:
        im = np.asarray(Image.open(ART / "109" / "prop__x-cloud-lip--t2.webp").convert("RGBA"), np.float32) / 255
        ys, xs = np.where(im[..., 3] > 0.02)
        CTX["lip"] = im[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return CTX["lip"]


def bank_sprite(width_px: float, height_px: float, edge: float = 0.22, bottom_fade: float = 0.5) -> tuple[Sprite, int, int]:
    """The lip scaled to a box, its bottom and ends feathered (the lip is a tile, it has no ends of its own)."""
    lip = lip_bank()
    w, h = max(int(width_px), 8), max(int(height_px), 8)
    a = cv2.resize(lip, (w, h), interpolation=cv2.INTER_AREA)
    xs = np.linspace(0, 1, w, dtype=np.float32)
    ys = np.linspace(0, 1, h, dtype=np.float32)
    wx = smooth(np.minimum(xs, 1 - xs) / edge)[None, :]
    wy = 1 - smooth((ys - (1 - bottom_fade)) / bottom_fade)[:, None]
    a[..., 3] *= wx * wy
    under = (np.linspace(0, 1, h, dtype=np.float32) ** 1.3)[:, None, None] * 0.42      # the underside takes the lavender
    a[..., :3] = a[..., :3] * (1 - under) + SHADOW_RGB * 1.15 * under
    pm = a.copy()
    pm[..., :3] *= pm[..., 3:4]
    g = grade_layer(pm, gain=2.1, sigma=26.0, warm=0.30, cool=0.45)
    al = np.maximum(g[..., 3:4], 1e-4)
    return Sprite(np.concatenate([g[..., :3] / al, g[..., 3:]], -1)), w, h


def put_blob(out: np.ndarray, cx: float, cy: float, rx: float, ry: float, op: float, rgb=SHADOW_RGB, tail: float = 1.6) -> None:
    x0, x1 = max(int(cx - rx * 1.4), 0), min(int(cx + rx * 1.4), W)
    y0, y1 = max(int(cy - ry * 1.6), 0), min(int(cy + ry * 1.6), H)
    if x1 <= x0 or y1 <= y0:
        return
    yy, xx = np.mgrid[y0:y1, x0:x1]
    r2 = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    a = (op * np.exp(-r2 * tail)).astype(np.float32)[..., None]
    dst = out[y0:y1, x0:x1]
    dst[...] = np.concatenate([rgb * a, a], -1) + dst * (1 - a)


# ---------------------------------------------------------------- Map and mid: the air and the clouds

class MatchBackdrop(C.Backdrop):
    """composition.Backdrop plus haze by depth, a graded floor and the banks under islands."""

    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.banks: list[tuple[float, float, float]] = []
        if CTX["kind"] == "map":
            self.horizon = MAP_HORIZON_REF

    def draw_sky(self, out):
        super().draw_sky(out)
        if CTX["kind"] == "map":      # sky and floor one gradient: the sky pales toward where the floor starts
            veil_rows(out, 60.0, MAP_HORIZON_REF + 20, 0.0, 0.74, power=0.95)
        else:
            veil_rows(out, 300.0, 500.0, 0.0, 0.10)

    def draw_far(self, out):
        tmp = np.zeros_like(out)
        super().draw_far(tmp)
        haze = 0.40 if CTX["kind"] == "map" else 0.18          # far isles and the whale are the farthest things on the screen
        a = tmp[..., 3:4]
        tmp[..., :3] = tmp[..., :3] * (1 - haze) + HAZE * haze * a
        self.far = tmp                  # drawn inside draw_floor_layers: the isles sit in the haze, on the far floor rows

    def draw_floor_layers(self, out, upto=3):
        y0 = int((self.horizon - 30) * PT)
        HZ = 1.0 if CTX["kind"] == "map" else 0.35
        for i in range(upto):
            base = np.zeros_like(out)
            super().draw_floor_layers(base, 1) if False else None
            self._one(base, i)
            base[y0:] = grade_layer(base[y0:], gain=1.28 if CTX["kind"] == "map" else 1.55, sigma=70.0)
            # depth haze on the far rows: the floor layer's own pixels sit in the air, the more the nearer the horizon
            if i == 0:
                veil_rows(base, self.horizon - 8, self.horizon + 170, HZ * 0.74, 0.0, power=0.7)
            elif i == 1:
                veil_rows(base, self.horizon - 8, self.horizon + 200, HZ * 0.5, 0.0, power=0.8)
            C.over(out, base, 0)
            if i == 1:
                C.over(out, self.far, 0)       # the far picture stands in the haze, on the far floor rows

    def _one(self, base, i):
        """composition's floor layer i alone (its spec list is local to draw_floor_layers, so the call is repeated by slicing)."""
        specs = [(12.0, 0.05, self.horizon, 22.0, C.SPEEDS["horizon"], 0.0, 11.0), (40.0, 0.45, self.horizon + 9, 16.0, C.SPEEDS["floor_mid"], 3.0, 11.0),
                 (90.0, 0.85, self.horizon + 60, 30.0, C.SPEEDS["floor_near"], 5.0, 17.0)]
        puff, k, top, ramp, dr, amp, per = specs[i]
        y, m = self.screen_y(top, k)
        C.draw_floor(base, puff * m * PT, y * PT, ramp * m * PT, 0.0, detile=True, fade_px=(2 * puff * m * PT if i == 0 else 0.0),
                     soften=0.6 if i < 2 else 0.0)

    def draw_lip(self, out, top_ref=740.0):
        tmp = np.zeros_like(out)
        super().draw_lip(tmp, top_ref)
        C.over(out, grade_layer(tmp, gain=1.35 if CTX["kind"] == "map" else 1.75, sigma=70.0, cool=0.30 if CTX["kind"] == "map" else 0.5), 0)
        for cx, base, w in (self.banks if CTX["kind"] == "mid" else []):          # the front of each bank: cloud clinging to the sides of the foot, not hiding it
            self.front_bank(out, cx, base, w)

    def front_bank(self, out, cx, base, w):
        bw = w * 1.18
        bh = w * 0.34
        sp, sw, sh = bank_sprite(bw, bh, edge=0.28, bottom_fade=0.55)
        x0 = int(cx - sw / 2)
        y0 = int(base - sh * 0.12)
        tmp = np.zeros((sh, sw, 4), np.float32)
        arr = sp.mips[0]
        # centre cut away: the earth body stays the subject
        xs = np.linspace(-1, 1, sw, dtype=np.float32)
        hole = smooth((np.abs(xs) - 0.30) / 0.30)[None, :, None]
        tmp[...] = arr * hole
        x0c, y0c = max(x0, 0), max(y0, 0)
        part = tmp[y0c - y0:min(H - y0, sh), x0c - x0:min(W - x0, sw)]
        if part.size:
            C.over(out, part, y0c, x0c)


def bank_and_shadow(out: np.ndarray, cx: float, cy: float, rx: float, ry: float, opacity: float, rgb=None) -> None:
    """Replaces composition.shade_ellipse. Called just before an island is drawn: cx, cy is where its foot sits."""
    kind = CTX["kind"]
    w = rx * (2.1 if kind == "map" else 2.2)                         # the island's width, device px
    BANKS.append((cx, cy, w))
    # the cast shadow: wide, soft, lavender, on the cloud under the earth body (mid's is the stronger, the island is the hero)
    sw_op = 0.50 if kind == "map" else 0.92
    put_blob(out, cx, cy + w * 0.16, w * 0.52, w * 0.11, sw_op, tail=1.4)
    put_blob(out, cx, cy + w * 0.10, w * 0.34, w * 0.07, sw_op * 0.7, tail=1.2)
    # the bank behind: the lip's cloud forms, in a band under and beside the foot
    bw = w * (1.65 if kind == "map" else 1.55)
    bh = w * (0.55 if kind == "map" else 0.5)
    sp, sw, sh = bank_sprite(bw, bh, edge=0.30, bottom_fade=0.45)
    sp.draw(out, cx - sw / 2, cy - sh * 0.50, sw, sh)


BANKS: list = []


def install_backdrop_patches():
    C.Backdrop = MatchBackdrop
    C.shade_ellipse = bank_and_shadow


def render_map(ch):
    BANKS.clear()
    CTX["kind"] = "map"
    install_backdrop_patches()
    # front banks need the islands' positions: draw_lip runs after the islands, so hand it the list the hook collected
    orig = MatchBackdrop.draw_lip

    def draw_lip(self, out, top_ref=740.0):
        self.banks = list(BANKS)
        return orig(self, out, top_ref)
    MatchBackdrop.draw_lip = draw_lip
    try:
        return C.render_map(ch, 3, 1, False)
    finally:
        MatchBackdrop.draw_lip = orig


def render_mid(ch):
    BANKS.clear()
    CTX["kind"] = "mid"
    install_backdrop_patches()
    orig = MatchBackdrop.draw_lip

    def draw_lip(self, out, top_ref=740.0):
        self.banks = list(BANKS)
        return orig(self, out, top_ref)
    MatchBackdrop.draw_lip = draw_lip
    try:
        return C.render_mid(ch, 10)
    finally:
        MatchBackdrop.draw_lip = orig


# ---------------------------------------------------------------- Near: the thin lens, the patch, the dressing

ELEV_DEG = 10.5
N_REST = 1.6
CAP_PT = 14.0


def lens_radius_pt(delta: np.ndarray, ppu: float, n: float) -> np.ndarray:
    """v2 5.1: r = N s |delta| / (D + delta), s the framing (pt per unit), D = 1375 / s, capped at 14 pt."""
    d = 1375.0 / ppu
    den = np.maximum(d + delta, 0.05 * d)
    return np.minimum(n * ppu * np.abs(delta) / den, CAP_PT)


def row_delta(y_dev: np.ndarray, focus_y: float, s_dev: float) -> np.ndarray:
    """Depth behind (+) or in front (-) of the focal plane for a ground point on device row y: the row difference in plate
    pixels, times units per plate pixel, times cos e / sin e (the painting's elevation)."""
    e = math.radians(ELEV_DEG)
    return (focus_y - y_dev) / s_dev * near_mid.UPP * math.cos(e) / math.sin(e)


def blur_by_rows(img: np.ndarray, r_pt: np.ndarray, sharp_pt: float = 0.5) -> np.ndarray:
    """Variable blur by row from a stack: sigma = half the circle of confusion in device px. Rows with r under 0.35 pt skip."""
    sig = r_pt * PT * 0.5
    levels = [0.0, 1.5, 3.0, 5.0, 8.0, 12.0, 18.0, 26.0]
    stack = [img if s == 0 else cv2.GaussianBlur(img, (0, 0), s) for s in levels]
    pos = np.interp(sig, levels, np.arange(len(levels)))
    lo = np.floor(pos).astype(int).clip(0, len(levels) - 2)
    fr = (pos - lo).astype(np.float32)[:, None, None]
    out = np.empty_like(img)
    for i in range(len(levels) - 1):
        m = lo == i
        if m.any():
            out[m] = stack[i][m] * (1 - fr[m]) + stack[i + 1][m] * fr[m]
    return out


def slice_parts(path: Path, min_area: int = 2500) -> list[np.ndarray]:
    """A pilot sprite sheet cut into its connected pieces (straight RGBA, trimmed), left to right, top to bottom."""
    im = np.asarray(Image.open(path).convert("RGBA"), np.float32) / 255
    mask = (im[..., 3] > 0.1).astype(np.uint8)
    mask = cv2.dilate(mask, np.ones((9, 9), np.uint8))
    n, lab, stats, _ = cv2.connectedComponentsWithStats(mask)
    parts = []
    for i in range(1, n):
        x, y, w, h, a = stats[i]
        if a < min_area:
            continue
        parts.append((y // 400 * 10000 + x, im[y:y + h, x:x + w].copy()))
    parts.sort(key=lambda p: p[0])
    out = []
    for _, p in parts:
        ys, xs = np.where(p[..., 3] > 0.05)
        out.append(p[ys.min():ys.max() + 1, xs.min():xs.max() + 1])
    return out


def paste_straight(canvas: np.ndarray, rgba: np.ndarray, foot_x: float, foot_y: float, width: float, alpha: float = 1.0,
                   feather_base: float = 0.0) -> None:
    """Straight RGBA centred on foot_x, its bottom at foot_y, `width` px wide, over an RGB float canvas (0..1)."""
    h0, w0 = rgba.shape[:2]
    w = max(int(width), 4)
    h = max(int(round(w * h0 / w0)), 4)
    a = cv2.resize(rgba, (w, h), interpolation=cv2.INTER_AREA)
    if feather_base > 0:           # the lead's note: a dead-straight flat base reads as a shelf; melt the last tenth into the lawn
        ys = np.linspace(0, 1, h, dtype=np.float32)
        a[..., 3] *= (1 - smooth((ys - (1 - feather_base)) / feather_base) * 0.85)[:, None]
    x0, y0 = int(round(foot_x - w / 2)), int(round(foot_y - h))
    xa, ya = max(x0, 0), max(y0, 0)
    xb, yb = min(x0 + w, canvas.shape[1]), min(y0 + h, canvas.shape[0])
    if xb <= xa or yb <= ya:
        return
    part = a[ya - y0:yb - y0, xa - x0:xb - x0]
    al = part[..., 3:4] * alpha
    canvas[ya:yb, xa:xb] = canvas[ya:yb, xa:xb] * (1 - al) + part[..., :3] * al


def contact_shadow(canvas: np.ndarray, fx: float, fy: float, w: float, k: float = 0.36) -> None:
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    rx, ry = w * 0.46, w * 0.075
    e = ((xs - fx) / rx) ** 2 + ((ys - (fy - ry * 0.2)) / ry) ** 2
    a = (np.clip(1 - e, 0, 1) ** 0.7 * k)
    a = cv2.GaussianBlur(a, (0, 0), max(2.0, w * 0.02))[..., None]
    canvas[...] = canvas * (1 - a) + np.float32([0.11, 0.16, 0.08]) * a


def lawn_mask(rgb: np.ndarray) -> np.ndarray:
    """1 on grass, 0 on the stepping stones and flowers: from greenness of the blurred plate."""
    b = cv2.GaussianBlur(rgb, (0, 0), 5)
    g = b[..., 1] - np.maximum(b[..., 0], b[..., 2]) * 0.80
    return smooth((g - 0.02) / 0.10)


def focal_patch(canvas: np.ndarray, fx: float, fy: float, width: float) -> None:
    """The 110 patch (pick 4) under the focused character: falloff over the outer 45 percent of its radius, tinted by the
    plate beneath it except where the patch is white (the daisies), clipped to the lawn."""
    im = np.asarray(Image.open(ART / "110" / "prop__x-near-patch-day--t4.webp").convert("RGBA"), np.float32) / 255
    h0, w0 = im.shape[:2]
    w = int(width)
    h = int(width * h0 / w0)
    p = cv2.resize(im, (w, h), interpolation=cv2.INTER_AREA)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    r = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2))
    fall = 1 - smooth((r - 0.55) / 0.45)
    a = p[..., 3] * fall
    x0, y0 = int(fx - w / 2), int(fy - h * 0.40)
    xa, ya, xb, yb = max(x0, 0), max(y0, 0), min(x0 + w, W), min(y0 + h, H)
    base = canvas[ya:yb, xa:xb]
    pp = p[ya - y0:yb - y0, xa - x0:xb - x0, :3].copy()
    aa = a[ya - y0:yb - y0, xa - x0:xb - x0]
    under = cv2.GaussianBlur(base, (0, 0), 30)
    mean_p = pp.reshape(-1, 3)[aa.reshape(-1) > 0.5].mean(0) if (aa > 0.5).any() else pp.mean((0, 1))
    tint = np.clip(under / np.maximum(mean_p, 1e-3), 0.55, 1.6)
    white = smooth((pp.min(-1) - 0.70) / 0.12)[..., None]
    pp = pp * (1 + (tint - 1) * (1 - white))
    m = (aa * lawn_mask(base))[..., None] * 0.92
    canvas[ya:yb, xa:xb] = base * (1 - m) + np.clip(pp, 0, 1) * m


def soft_foreground(canvas: np.ndarray, y_start: float, y_full: float) -> None:
    """STAND-IN for the one soft foreground layer (new art in the build): the lawn above, mirrored and blurred to r 12 pt,
    lifted a little, fading in over the rim, so the picture ends on grass as the picked near does."""
    h_src = H - int(y_start)
    src_top = int(y_start - h_src * 1.25)
    band = canvas[max(src_top, 0):int(y_start)][::-1]
    band = cv2.resize(np.ascontiguousarray(band), (W, h_src), interpolation=cv2.INTER_AREA)
    band = cv2.GaussianBlur(band, (0, 0), 38)
    # a few soft white flower discs, blurred (the picked near has daisies and phlox out of focus)
    rng = np.random.default_rng(5)
    fl = np.zeros_like(band)
    for _ in range(0):
        cx, cy = rng.uniform(0, W), rng.uniform(h_src * 0.25, h_src * 0.95)
        col = [np.float32([1.0, 0.96, 0.9]), np.float32([0.86, 0.66, 0.9]), np.float32([1.0, 0.78, 0.84])][rng.integers(3)]
        cv2.circle(fl, (int(cx), int(cy)), int(rng.uniform(10, 24)), col.tolist(), -1)
    fl = cv2.GaussianBlur(fl, (0, 0), 14)
    fm = np.clip(fl.max(-1, keepdims=True) * 1.2, 0, 1)
    band = band * (1 - fm * 0.45) + fl * fm * 0.45
    band = np.clip(band * np.float32([0.80, 0.84, 0.72]), 0, 1)
    ys = np.arange(int(y_start), H, dtype=np.float32)
    a = smooth((ys - y_start) / max(y_full - y_start, 1))[:, None, None]
    dst = canvas[int(y_start):H]
    canvas[int(y_start):H] = dst * (1 - a) + band[:dst.shape[0]] * a


def render_near(ch, ppu: float = 4.5):
    """The near still: the plate through the lens, Pofu sharp on the focal row, patch and dressing on it."""
    s = near_mid.s_of(ppu)
    fy = 0.60 * H
    fx = W / 2
    cx, cy = near_mid.POFU_FEET[0], near_mid.POFU_FEET[1] - (fy - H / 2) / s
    g = near_mid.ground("day", cx, cy, s)
    rgb = np.asarray(g.convert("RGB"), np.float32) / 255
    rows = np.arange(H, dtype=np.float32)
    delta = row_delta(rows, fy, s)
    r_pt = lens_radius_pt(delta, ppu, N_REST)
    rgb = blur_by_rows(rgb, r_pt)
    t = smooth((rows - 0.42 * H) / (0.5 * H))[:, None, None]       # the ground darkens and saturates toward the viewer (read off the picked near)
    lum = rgb.mean(-1, keepdims=True)
    rgb = np.clip((lum + (rgb - lum) * (1 + 0.30 * t)) * (1 - 0.17 * t), 0, 1)
    pofu_w = near_mid.POFU_W * s
    # focal ground patch, then the dressing on and behind the focal row (v2 5.3: none in front of the sharp zone)
    focal_patch(rgb, fx, fy + 6, pofu_w * 3.4)
    soft_dressing(rgb, fx, fy, pofu_w, rows, r_pt)
    contact_shadow(rgb, fx, fy, pofu_w, 0.40)
    art = near_mid.tight(near_mid.POFU)
    wpx = int(round(pofu_w))
    ah = int(round(wpx * art.height / art.width))
    pa = np.asarray(art.resize((wpx, ah), Image.LANCZOS), np.float32) / 255
    paste_straight(rgb, pa, fx, fy, wpx)
    soft_foreground(rgb, 0.80 * H, 0.885 * H)
    rng = np.random.default_rng(7)
    rgb = np.clip(rgb + rng.normal(0, 1.4 / 255, (H, W, 1)).astype(np.float32), 0, 1)
    out = np.concatenate([rgb, np.ones((H, W, 1), np.float32)], -1)
    chrome = [{"id": "back_control", "box": ch.put(out, "corner_home", 16.0 + 4, 766.0 + 3, flip=True)}]
    pw_pt = pofu_w / PT
    feet = [fx / PT, 0.60 * C.REF_H]
    box = [feet[0] - pw_pt / 2, feet[1] - pw_pt * art.height / art.width, feet[0] + pw_pt / 2, feet[1]]
    meta = {"kind": "near", "ppu": ppu, "elevation_deg": ELEV_DEG, "N": N_REST, "feet": feet, "hero": box, "pofu_w_pt": pw_pt,
            "subjects": [{"id": "pofu", "type": "char", "box": box}], "chrome": chrome, "features": [],
            "lens_r_pt": {"sky_inf": N_REST * ppu, "row_up_300px": float(lens_radius_pt(row_delta(np.float32([fy - 300]), fy, s), ppu, N_REST)[0]),
                          "row_down_300px": float(lens_radius_pt(row_delta(np.float32([fy + 300]), fy, s), ppu, N_REST)[0])}}
    return out, meta


def soft_dressing(rgb: np.ndarray, fx: float, fy: float, pofu_w: float, rows: np.ndarray, r_pt: np.ndarray) -> None:
    """107 picks: daisy clump and tuft on the focal row beside Pofu, pebbles and clover just behind, the tea stool behind
    the left; each blurred by its own foot row (a standing thing is sharp or soft as one object)."""
    d = ART / "107"
    daisies = slice_parts(d / "prop__x-near-tufts-daisies--t1.webp")
    pebbles = slice_parts(d / "prop__x-near-pebbles-clover--t1.webp")
    stool = np.asarray(Image.open(d / "prop__x-near-tea-stool--t1.webp").convert("RGBA"), np.float32) / 255
    ys, xs = np.where(stool[..., 3] > 0.05)
    stool = stool[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    # (art, dx, foot dy from Pofu's feet, width in Pofu widths)
    items = []
    clumps = [p for p in daisies if p.shape[1] > 1.2 * p.shape[0]] or daisies
    for i, (dx, dy, wf) in enumerate([(-0.80, 0.10, 0.62), (0.74, 0.02, 0.50)][:len(clumps)]):
        items.append((clumps[i], dx, dy, wf, 0.10))
    for i, (dx, dy, wf) in enumerate([(0.52, -0.30, 0.42), (-0.52, -0.42, 0.36)][:len(pebbles)]):
        items.append((pebbles[i], dx, dy, wf, 0.0))
    items.append((stool, -1.02, -0.62, 0.52, 0.0))
    items.sort(key=lambda it: it[2])                                  # far first
    for art, dx, dy, wf, feather in items:
        ffy = fy + dy * pofu_w
        ffx = fx + dx * pofu_w
        layer = np.zeros_like(rgb)
        contact_shadow_into(layer, ffx, ffy, wf * pofu_w)
        w = wf * pofu_w
        tmp = rgb.copy()
        contact_shadow(tmp, ffx, ffy, w * 1.1, 0.30)
        paste_straight(tmp, art, ffx, ffy, w, feather_base=feather)
        r = float(np.interp(ffy, rows, r_pt))
        if r > 0.35:
            sg = r * PT * 0.5
            y0, y1 = int(max(ffy - 1.6 * w, 0)), int(min(ffy + 0.5 * w, H))
            tmp[y0:y1] = cv2.GaussianBlur(tmp[y0:y1], (0, 0), sg)
            rgb[y0:y1] = tmp[y0:y1]
        else:
            rgb[...] = tmp


def contact_shadow_into(layer, x, y, w):   # kept for symmetry; the shadow is drawn into the working copy
    return None


# ---------------------------------------------------------------- measuring: bands, drift, pairs

def luma(img: np.ndarray) -> np.ndarray:
    return img[..., 0] * 0.2126 + img[..., 1] * 0.7152 + img[..., 2] * 0.0722


def sat(img: np.ndarray) -> np.ndarray:
    mx, mn = img.max(-1), img.min(-1)
    return (mx - mn) / np.maximum(mx, 1e-4)


def band_table(target: Image.Image, match: Image.Image, still: Image.Image, n: int = 13) -> tuple[str, dict]:
    """Mean luminance (0..100) and saturation (0..100) per horizontal band for the target, the old R1 still and the match."""
    ims = {k: np.asarray(v.convert("RGB"), np.float32) / 255 for k, v in (("target", target), ("r1", still), ("match", match))}
    lines = [f"{'band (pt)':<12}{'L tgt':>7}{'L r1':>7}{'L mat':>7}   {'S tgt':>6}{'S r1':>7}{'S mat':>7}"]
    tot = {"r1": [0.0, 0.0], "match": [0.0, 0.0]}
    for i in range(n):
        y0, y1 = int(i * H / n), int((i + 1) * H / n)
        row = {}
        for k, a in ims.items():
            part = a[y0:y1]
            row[k] = (float(luma(part).mean() * 100), float(sat(part).mean() * 100))
        lines.append(f"{y0 / PT:>4.0f}-{y1 / PT:<6.0f}{row['target'][0]:>7.1f}{row['r1'][0]:>7.1f}{row['match'][0]:>7.1f}   "
                     f"{row['target'][1]:>6.1f}{row['r1'][1]:>7.1f}{row['match'][1]:>7.1f}")
        for k in ("r1", "match"):
            tot[k][0] += (row[k][0] - row["target"][0]) ** 2
            tot[k][1] += (row[k][1] - row["target"][1]) ** 2
    rms = {k: (math.sqrt(v[0] / n), math.sqrt(v[1] / n)) for k, v in tot.items()}
    lines.append(f"{'rms gap':<12}{'':>7}{rms['r1'][0]:>7.1f}{rms['match'][0]:>7.1f}   {'':>6}{rms['r1'][1]:>7.1f}{rms['match'][1]:>7.1f}")
    return "\n".join(lines), {k: {"L": v[0], "S": v[1]} for k, v in rms.items()}


def drift_report(target: Image.Image, other: Image.Image, side: dict, distance: str, name: str):
    """concept_fit's edge matching of `other` against `target` on the R1 boxes (the match must not have moved a subject)."""
    return concept_fit.compare_frames(target, other, side, distance, name)


def pair(target: Image.Image, match: Image.Image, path: Path) -> None:
    sh = Image.new("RGB", (2 * W + 12, H), (20, 20, 20))
    sh.paste(target.convert("RGB"), (0, 0))
    sh.paste(match.convert("RGB"), (W + 12, 0))
    sh.save(path)


def main(argv=None) -> int:
    global ART
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--refs", type=Path, required=True, help="folder of composition.py's R1 stills and sidecars")
    ap.add_argument("--frames", type=Path, required=True, help="folder with path-d03-0900.png and path-d13-map-0900.png")
    ap.add_argument("--takes", type=Path, required=True, help="folder of the picked concept takes (webp)")
    ap.add_argument("--art", type=Path, required=True, help="folder with 107/ 109/ 110/ (the pofu-art pilot picks)")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--only", nargs="+", default=["map", "mid", "near"], choices=["map", "mid", "near"])
    a = ap.parse_args(argv)
    ART = a.art
    a.out.mkdir(parents=True, exist_ok=True)
    ch = C.Chrome(a.frames)
    render = {"map": render_map, "mid": render_mid, "near": render_near}
    report = []
    for d in a.only:
        still = Image.open(a.refs / f"{STILLS[d]}.png").convert("RGB")
        side = json.loads((a.refs / f"{STILLS[d]}.json").read_text())
        dist = "map-journey" if d == "map" else d
        target, _ = concept_fit.fit_take(Image.open(a.takes / f"{PICKS[d]}.webp"), still, side, PICKS[d], dist, "locked")
        out, meta = render[d](ch)
        match = Image.fromarray((np.clip(out[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
        match.save(a.out / f"match-{d}.png")
        target.save(a.out / f"target-{d}.png")
        pair(target, match, a.out / f"pair-{d}.png")
        table, rms = band_table(target, match, still)
        (a.out / f"bands-{d}.txt").write_text(table + "\n")
        before = drift_report(target, still, side, dist, "R1 still vs target")
        after = drift_report(target, match, side, dist, "match vs target")
        (a.out / f"drift-{d}.txt").write_text(concept_fit.format_report(before) + "\n\n" + concept_fit.format_report(after) + "\n")
        report.append({"distance": d, "band_rms": rms, "meta": {k: v for k, v in meta.items() if k in ("lens_r_pt", "elevation_deg", "N")},
                       "drift_r1": before.to_json(), "drift_match": after.to_json()})
        print(f"{d}: band rms gap L {rms['r1']['L']:.1f} -> {rms['match']['L']:.1f}, S {rms['r1']['S']:.1f} -> {rms['match']['S']:.1f}")
    (a.out / "match-report.json").write_text(json.dumps(report, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
