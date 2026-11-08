#!/usr/bin/env python3
"""Plate-first pilot: Revontuli composed the way ADR-0022 (c) proposes, offline, beside the concept and
the current pipeline.

The stand-ins are concept takes, not production plates: stage 0 is `x-revontuli-stuck` t1, stage 4 is
`x-revontuli-healed` t2 (the picks in docs/design/concept-flows-islands.md section 3). They were generated
independently, so their props do not register; the healed take is aligned to the stuck one by its island
silhouette only, and the transition shows that residue honestly. The painted Pofu and Mochi are patched
out of both takes (in production the plate is painted without them) and the sprites are put back, lit
from the plate.

Per frame, back to front (the runtime order of docs/design/plate-islands.md):
  1. sky from the colour script's night cell (zenith, horizon, glow, stars), ungraded;
  2. code aurora curtains (screen blend), strength by stage;
  3. the plate at full resolution, cut by its matte, no grade, no fog, no haze;
  4. Pofu and Mochi sprites, gain from the plate's sampled local light, a contact pad in the plate's own
     shadow colour and a rim from the nearest practical;
  5. the cloud sea (colour script sea colours) with one front row over the plate's foot.

    python3 -I tools/plate/pilot.py SHOTS_DIR OUT.jpg [--frames DIR]

SHOTS_DIR as for pale.py (needs caglayan-night-0.jpg, caglayan-night-4.jpg, concept-night-home.jpg).
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

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "looklab"))
sys.path.insert(0, str(REPO / "tools" / "assets"))
sys.path.insert(0, str(HERE))
import lab as ll  # noqa: E402
import pale  # noqa: E402
from process_assets import srgb_to_lab  # noqa: E402

CELLS = json.loads((REPO / "design" / "art" / "colour-script.json").read_text())["cells"]
FRAME = (460, 1000)  # the CI frame (402 x 874 pt); composed at 2x and reduced
SS = 2

# Hand traces of the island silhouettes, in percent of the 1536 x 1024 take.
TRACE = {
    "stuck": [(3, 48), (6, 42), (13, 38), (14, 24), (22, 16), (25, 10), (28, 10), (30, 15), (38, 18), (42, 25),
              (41, 38), (46, 40), (47, 8), (50, 5), (54, 6), (57, 12), (56, 23), (52, 25), (52, 28), (55, 24),
              (60, 22), (64, 28), (67, 35), (70, 38), (71, 30), (73, 22), (78, 10), (82, 6), (86, 12), (88, 22),
              (91, 28), (90, 38), (93, 40), (97, 47), (97, 56), (94, 66), (88, 75), (86, 82), (76, 84), (65, 87),
              (58, 88), (56, 94), (54, 88), (40, 89), (32, 90), (31, 95), (29, 90), (18, 85), (12, 82), (10, 86),
              (9, 80), (5, 70), (2, 58)],
    "healed": [(3, 52), (8, 45), (12, 40), (12, 30), (16, 26), (19, 20), (20, 13), (23, 13), (25, 20), (32, 22),
               (38, 28), (37, 40), (44, 42), (44, 12), (46, 8), (50, 8), (53, 10), (55, 14), (55, 22), (52, 24),
               (51, 26), (55, 25), (60, 28), (63, 34), (66, 38), (71, 40), (72, 30), (76, 18), (80, 10), (83, 12),
               (86, 22), (89, 30), (88, 40), (93, 42), (97, 52), (97, 62), (94, 72), (88, 82), (84, 90), (70, 93),
               (60, 94), (59, 97), (57, 94), (45, 95), (32, 94), (30, 97), (28, 93), (16, 90), (15, 93), (13, 88),
               (8, 80), (4, 70), (2, 60)],
}
# The painted duo to patch out (percent box) and the horizontal shift of the clean snow copied over it.
DUO = {"stuck": ((39, 47, 64, 69), 26), "healed": ((39, 46, 63, 67), 27)}
# Sprite feet (percent of the take) and width (percent of the take's width), from the painted duo.
FEET = {"pofu": ((46.0, 64.0), 11.0), "mochi": ((57.0, 63.5), 12.5)}
# The nearest practical to the duo, in percent of the take, and its colour: the lamp post's lantern.
PRACTICAL = {"stuck": ((52, 18), (1.0, 0.86, 0.62), 0.0), "healed": ((52, 18), (1.0, 0.80, 0.50), 1.0)}
KEEP = {"stuck": (49, 4, 58, 23), "healed": None}
TAKES = {"stuck": pale.REF_STUCK, "healed": pale.REF_HEALED}
SPRITES = {"pofu": pale.POFU, "mochi": pale.ASSETS / "world-mochi.imageset/world-mochi.png"}


def hexrgb(h: str) -> np.ndarray:
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def lin(x):
    return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)


def srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * x ** (1 / 2.4) - 0.055)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- the plate

def matte(rgb: np.ndarray, trace, keep=None) -> np.ndarray:
    """GrabCut in a band around the hand trace; returns a soft alpha."""
    h, w = rgb.shape[:2]
    poly = np.array([(x * w / 100, y * h / 100) for x, y in trace], np.int32)
    inside = np.zeros((h, w), np.uint8)
    cv2.fillPoly(inside, [poly], 255)
    k = lambda r: cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    m = np.full((h, w), cv2.GC_BGD, np.uint8)
    m[cv2.dilate(inside, k(16)) > 0] = cv2.GC_PR_BGD
    m[inside > 0] = cv2.GC_PR_FGD
    m[cv2.erode(inside, k(22)) > 0] = cv2.GC_FGD
    # Night sky caught inside the trace (between the post, the fox and the tree, and the lantern's glow
    # on the sky): violet-blue and darker than any snow.
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    hue = np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360
    skyish = (lab[..., 0] < 64) & (hue > 250) & (hue < 315) & (np.hypot(lab[..., 1], lab[..., 2]) > 12)
    skyish[int(h * 0.5):] = False
    if keep:  # a glass lamp that shows the sky through it stays in
        x0, y0, x1, y1 = keep
        skyish[int(y0 * h / 100):int(y1 * h / 100), int(x0 * w / 100):int(x1 * w / 100)] = False
    m[skyish] = cv2.GC_BGD
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    img = np.uint8(np.clip(rgb, 0, 1) * 255)[..., ::-1].copy()
    cv2.grabCut(img, m, None, bgd, fgd, 4, cv2.GC_INIT_WITH_MASK)
    fg = np.isin(m, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8)
    n, lbl, st, _ = cv2.connectedComponentsWithStats(fg)
    keep = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    fg = ndimage.binary_fill_holes(lbl == keep)
    return ndimage.gaussian_filter(fg.astype(np.float64), 1.2)


def patch_duo(rgb: np.ndarray, key: str) -> np.ndarray:
    """Patch the painted duo out (the production plate has none): the texture of clean snow from beside
    it over the low-frequency shading of an inpaint of the hole, so no lighter or darker box shows."""
    (x0, y0, x1, y1), shift = DUO[key]
    h, w = rgb.shape[:2]
    X0, Y0, X1, Y1 = int(x0 * w / 100), int(y0 * h / 100), int(x1 * w / 100), int(y1 * h / 100)
    dx = int(shift * w / 100)
    hole = np.zeros((h, w), np.uint8)
    hole[Y0:Y1, X0:X1] = 255
    filled = cv2.inpaint(np.uint8(rgb * 255), hole, 9, cv2.INPAINT_TELEA).astype(np.float64) / 255
    sig = 0.012 * w
    low = ndimage.gaussian_filter(filled, (sig, sig, 0))
    src = np.roll(rgb, -dx, axis=1)
    tex = src - ndimage.gaussian_filter(src, (sig, sig, 0))
    m = ndimage.gaussian_filter(hole / 255.0, 0.01 * w)
    m = np.clip(m * 1.8, 0, 1)[..., None]
    return np.clip((low + tex) * m + rgb * (1 - m), 0, 1)


def load_take(key: str) -> tuple[np.ndarray, np.ndarray]:
    rgb = ll.load_rgb(TAKES[key])
    a = matte(rgb, TRACE[key], KEEP[key])
    return patch_duo(rgb, key), a


def bbox(a: np.ndarray, t: float = 0.5) -> tuple[int, int, int, int]:
    ys, xs = np.where(a > t)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def align(src: np.ndarray, a_src: np.ndarray, a_dst: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Map `src` onto `dst` by the island body's box (x scale, y scale, shift): silhouettes only."""
    # The body: rows below 45 % of the take, where props do not change the outline.
    def body(a):
        b = a.copy()
        b[: int(a.shape[0] * 0.45)] = 0
        return bbox(b)
    sx0, sy0, sx1, sy1 = body(a_src)
    dx0, dy0, dx1, dy1 = body(a_dst)
    kx, ky = (dx1 - dx0) / (sx1 - sx0), (dy1 - dy0) / (sy1 - sy0)
    M = np.float32([[kx, 0, dx0 - kx * sx0], [0, ky, dy0 - ky * sy0]])
    h, w = a_dst.shape
    warp = lambda x: cv2.warpAffine(np.float32(x), M, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
    return warp(src).astype(np.float64), warp(a_src).astype(np.float64)


# ---------------------------------------------------------------- code layers

def sky(cell: dict, W: int, H: int, seed: int = 4) -> np.ndarray:
    s = cell["sky"]
    z, hz, glow = hexrgb(s["zenith"]), hexrgb(s["horizon"]), hexrgb(s["glow"])
    t = np.clip(np.linspace(0, 1, H) / 0.7, 0, 1)[:, None, None]
    out = np.broadcast_to(z * (1 - t) + hz * t, (H, W, 3)).copy()
    yy, xx = np.mgrid[0:H, 0:W] / max(W, H)
    sun = cell["sun"]
    g = np.exp(-((xx - sun[0] * W / max(W, H)) ** 2 + (yy - sun[1] * H / max(W, H)) ** 2) / 0.02) * s["glowStrength"]
    out = out * (1 - g[..., None]) + glow * g[..., None]
    rng = np.random.default_rng(seed)
    n = int(W * H / 2600 * s["stars"])
    st = np.zeros((H, W))
    ys, xs = rng.integers(0, int(H * 0.62), n), rng.integers(0, W, n)
    st[ys, xs] = rng.uniform(0.3, 1.0, n) ** 2
    st = ndimage.gaussian_filter(st, 0.8 * SS) * (6 * SS)
    return np.clip(out + st[..., None] * np.array([0.95, 0.95, 1.0]), 0, 1)


def aurora(W: int, H: int, strength: float, y_base: float, seed: int = 7) -> np.ndarray:
    """Two light-on-black curtains: thin folded ribbons with a bright green hem, rays that fade upward
    to violet, gaps between folds (never a filled band, which reads as a mountain range)."""
    if strength <= 0:
        return np.zeros((H, W, 3))
    rng = np.random.default_rng(seed)
    out = np.zeros((H, W, 3))
    x = np.arange(W) / W
    y = np.arange(H)[:, None]
    green, violet = np.array([0.36, 0.92, 0.66]), np.array([0.62, 0.46, 0.98])
    for k, (tilt, amp, freq, phase, hgt, gain) in enumerate([(-0.12, 0.022, 1.6, 0.4, 0.12, 1.0),
                                                             (0.08, 0.016, 2.4, 2.2, 0.08, 0.7)]):
        yc = (y_base + 0.05 * k + tilt * (x - 0.5) + amp * np.sin(2 * np.pi * freq * x + phase)) * H
        rays = ndimage.gaussian_filter1d(rng.normal(size=W), W * 0.0018)
        rays = np.clip((rays - rays.mean()) / rays.std() * 0.35 + 0.7, 0, 1) ** 1.3
        folds = ndimage.gaussian_filter1d(rng.normal(size=W), W * 0.03)
        folds = 0.25 + 0.75 * smooth(-0.9, 0.5, folds / folds.std())
        breadth = smooth(0.02, 0.2, x) * smooth(0.98, 0.8, x) * folds
        up = (yc[None, :] - y) / (hgt * H)
        prof = np.where(up >= 0, np.exp(-up * 2.8) * (0.45 + 0.55 * np.exp(-up * 6)),
                        np.exp(-(up * hgt * H / (4.0 * SS)) ** 2))
        inten = prof * (rays * breadth)[None, :] * gain
        mix = np.clip(up * 1.3, 0, 1)[..., None]
        out += inten[..., None] * (green * (1 - mix) + violet * mix)
    return np.clip(out * strength * 1.25, 0, 1)


def screen(base: np.ndarray, light: np.ndarray) -> np.ndarray:
    return 1 - (1 - base) * (1 - np.clip(light, 0, 1))


def cloud_row(W: int, H: int, y: float, bump: float, n: int, seed: int, depth: float | None = None) -> np.ndarray:
    """Coverage 0...1 and a 0...1 'height in billow' for a scalloped cloud row whose base line is y (px)."""
    rng = np.random.default_rng(seed)
    xs = (np.arange(n) + rng.uniform(-0.3, 0.3, n)) * W / (n - 1)
    rs = bump * rng.uniform(0.7, 1.25, n)
    X = np.arange(W)
    top = np.full(W, y)
    for cx, r in zip(xs, rs):
        d = np.clip(1 - ((X - cx) / r) ** 2, 0, None)
        top = np.minimum(top, y - r * 0.8 * np.sqrt(d))
    Y = np.arange(H)[:, None]
    cov = smooth(-1.5 * SS, 1.5 * SS, Y - top[None, :])
    height = np.clip((Y - top[None, :]) / (depth or bump * 1.4), 0, 1)
    return cov, height


def cloud_sea(cell: dict, W: int, H: int, y0: float, rows: int = 5, front_only: bool = False) -> tuple[np.ndarray, np.ndarray]:
    """Rows of round billows from `y0` to the frame's foot, growing toward the viewer. Each billow is the
    sea's light colour on its crown and its shade colour low down, and the next row's crowns overlap the
    shade, so the rows read as separate billows (colours from the colour script's sea)."""
    light, shade = hexrgb(cell["sea"]["light"]), hexrgb(cell["sea"]["shade"])
    rgb, a = np.broadcast_to(shade, (H, W, 3)).copy(), np.zeros((H, W))  # straight colour: no black fringes
    step = (H - y0) / (rows + 0.3)
    spec = [(y0 + i * step, 0.06 * W * (1 + 0.6 * i), 11 + i) for i in range(rows)]
    if front_only:
        spec = [(y0, 0.075 * W, 31)]
    for y, r, seed in spec:
        rng = np.random.default_rng(seed)
        n = int(W / (r * 1.25)) + 3
        xs = (np.arange(n) - 1 + rng.uniform(-0.25, 0.25, n)) * r * 1.25
        rs = r * rng.uniform(0.75, 1.2, n)
        cys = y + rng.uniform(-0.25, 0.25, n) * r * 0.3
        # The shade below the crowns: a band from the row's line down to the frame's foot.
        band = np.zeros((H, W))
        band[int(y):] = 1
        band = ndimage.gaussian_filter(band, (2 * SS, 0))
        rgb = rgb * (1 - band[..., None]) + shade * band[..., None]
        a = a + band * (1 - a)
        layer, la = np.zeros((H, W, 3)), np.zeros((H, W))
        blobs = []
        for k in rng.permutation(n):
            cx, rx, cy = xs[k], rs[k], cys[k]
            ry = rx * rng.uniform(0.45, 0.62)
            blobs.append((cx, cy, rx, ry))
            # Two small crowns on each billow: clusters, not eggs.
            for side in (-1, 1):
                q = rng.uniform(0.32, 0.5)
                blobs.append((cx + side * rx * rng.uniform(0.25, 0.5), cy - ry * rng.uniform(0.45, 0.7), rx * q, rx * q * 0.8))
        for cx, cy, rx, ry in blobs:
            X0, X1 = int(max(cx - rx - 4, 0)), int(min(cx + rx + 4, W))
            Y0, Y1 = int(max(cy - ry - 4, 0)), int(min(cy + ry + 4, H))
            if X1 <= X0 or Y1 <= Y0:
                continue
            yy, xx = np.mgrid[Y0:Y1, X0:X1]
            e = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
            cov = smooth(1.0 + 2.0 * SS / rx, 1.0 - 2.0 * SS / rx, e)
            v = np.clip((yy - (cy - ry)) / (2 * ry), 0, 1)
            t = (0.65 * smooth(0.5, 1.0, v))[..., None]
            col = light * (1 - t) + shade * t
            sub = layer[Y0:Y1, X0:X1]
            sub[:] = sub * (1 - cov[..., None]) + col * cov[..., None]
            la[Y0:Y1, X0:X1] = la[Y0:Y1, X0:X1] + cov * (1 - la[Y0:Y1, X0:X1])
        # Softer with distance: the far rows (the first ones) blur more.
        sig = (3.0 - 0.45 * spec.index((y, r, seed))) * SS
        layer = ndimage.gaussian_filter(layer * la[..., None], (sig, sig, 0))
        la = ndimage.gaussian_filter(la, sig)
        layer = layer / np.maximum(la[..., None], 1e-4)
        rgb = rgb * (1 - la[..., None]) + layer * la[..., None]
        a = a + la * (1 - a)
    if front_only:
        # Only the crowns of the front row cross the plate's foot; they fade out below it.
        a = a * smooth(y0 + 0.5 * spec[0][1], y0 - 0.1 * spec[0][1], np.arange(H))[:, None]
    return rgb, a

# ---------------------------------------------------------------- characters

def sprite(name: str, width: int) -> np.ndarray:
    im = Image.open(SPRITES[name]).convert("RGBA")
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 8)
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    im = im.resize((width, round(im.height * width / im.width)), Image.Resampling.LANCZOS)
    return np.asarray(im, np.float64) / 255


def lit_from_plate(spr: np.ndarray, plate: np.ndarray, plate_a: np.ndarray, feet: tuple[int, int],
                   practical: tuple[tuple[int, int], np.ndarray, float]) -> tuple[np.ndarray, dict]:
    """Gain the sprite by the plate's local light (snow around the feet against white snow), add a rim
    from the practical on its side, and return the contact pad colour (the plate's own shadow tone)."""
    fx, fy = feet
    w = spr.shape[1]
    ring = np.zeros(plate.shape[:2], bool)
    ring[max(fy - w // 3, 0):fy + w // 6, max(fx - w, 0):fx + w] = True
    ring &= plate_a > 0.99
    lab = srgb_to_lab(plate[ring])
    L = lab[:, 0]
    lit = plate[ring][L >= np.percentile(L, 60)].mean(0)
    shadow = plate[ring][L <= np.percentile(L, 8)].mean(0)
    white = np.array([0.95, 0.95, 0.96])
    gain = np.clip(lin(lit) / lin(white), 0.2, 1.1)
    gain = gain / max(gain.max(), 1e-6) * min(1.0, float(lin(lit).mean() / lin(white).mean()) ** 0.5)
    rgb = lin(spr[..., :3]) * gain
    # Ambient occlusion low on the body: the bottom fifth goes toward the ground's shadow tone.
    h = spr.shape[0]
    ao = smooth(0.78, 1.0, np.arange(h) / h)[:, None, None] * 0.35
    rgb = rgb * (1 - ao) + lin(shadow) * gain.mean() * ao
    (px, py), pcol, pstr = practical
    if pstr > 0:
        a = spr[..., 3]
        side = np.sign(px - fx) or 1
        rim = np.clip(a - ndimage.shift(a, (0, side * 3 * SS), order=1), 0, 1)
        rim = ndimage.gaussian_filter(rim, 1.0 * SS) * smooth(0.0, 0.7, 1 - np.arange(h) / h)[:, None]
        rgb = rgb + rim[..., None] * lin(np.array(pcol)) * 0.55 * pstr
    out = spr.copy()
    out[..., :3] = srgb(rgb)
    ratio = np.clip(lin(shadow) / np.maximum(lin(lit), 1e-4), 0.15, 1.0)
    return out, {"gain": np.round(gain, 3).tolist(), "ratio": ratio}


def place(canvas: np.ndarray, spr: np.ndarray, cx: int, by: int) -> None:
    h, w = spr.shape[:2]
    x0, y0 = cx - w // 2, by - h
    sub = canvas[y0:y0 + h, x0:x0 + w]
    a = spr[..., 3:4]
    sub[:] = spr[..., :3] * a + sub * (1 - a)


def contact_pad(canvas: np.ndarray, cx: int, by: int, w: int, ratio: np.ndarray, strength: float = 0.75) -> None:
    """Multiply the ground under the feet toward the plate's own shadow tone (ratio = shadow / lit, linear)."""
    y0, y1, x0, x1 = by - w // 4, by + w // 4, cx - w, cx + w
    sub = canvas[y0:y1, x0:x1]
    yy, xx = np.mgrid[y0:y1, x0:x1]
    e = ((xx - cx) / (0.46 * w)) ** 2 + ((yy - by + 0.015 * w) / (0.09 * w)) ** 2
    m = np.clip(1 - e, 0, 1) ** 1.2 * strength
    m = ndimage.gaussian_filter(m, 1.5 * SS)[..., None]
    sub[:] = srgb(lin(sub) * (1 - m + m * ratio))


# ---------------------------------------------------------------- compose

def compose(plate: np.ndarray, plate_a: np.ndarray, stage: int, key: str, pose: str, cell: dict,
            aurora_strength: float | None = None) -> tuple[np.ndarray, dict]:
    """One phone frame; returns the 460 x 1000 frame and the island's box in it."""
    W, H = FRAME[0] * SS, FRAME[1] * SS
    # Camera: 'whole' matches Çağlayan's island stop (island 441 of 460 px, centre y 457);
    # 'close' frames the island at 1.35x the screen width with the lawn at the frame's middle.
    bw, by0 = (441, 457) if pose == "whole" else (621, 470)
    x0b, y0b, x1b, y1b = bbox(plate_a)
    k = bw * SS / (x1b - x0b)
    pw, ph = round(plate.shape[1] * k), round(plate.shape[0] * k)
    px = round(W / 2 - (x0b + x1b) / 2 * k)
    py = round(by0 * SS - (y0b + y1b) / 2 * k)
    im = Image.fromarray(np.uint8(np.clip(plate, 0, 1) * 255)).resize((pw, ph), Image.Resampling.LANCZOS)
    pr = np.asarray(im, np.float64) / 255
    pa = np.asarray(Image.fromarray(np.uint8(plate_a * 255)).resize((pw, ph), Image.Resampling.LANCZOS), np.float64) / 255

    base = sky(cell, W, H)
    strength = aurora_strength if aurora_strength is not None else [0.0, 0.0, 0.25, 0.4, 1.0][stage]
    base = screen(base, aurora(W, H, strength, 0.21 if pose == "whole" else 0.13))
    sea_rgb, sea_a = cloud_sea(cell, W, H, py + y1b * k - 0.03 * H)
    canvas = base * (1 - sea_a[..., None]) + sea_rgb * sea_a[..., None]

    def paste(dst, src, a, x, y):
        Hh, Ww = dst.shape[:2]
        sx0, sy0 = max(0, -x), max(0, -y)
        dx0, dy0 = max(0, x), max(0, y)
        dx1, dy1 = min(Ww, x + src.shape[1]), min(Hh, y + src.shape[0])
        s = src[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
        aa = a[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0, None]
        dst[dy0:dy1, dx0:dx1] = s * aa + dst[dy0:dy1, dx0:dx1] * (1 - aa)

    paste(canvas, pr, pa, px, py)
    info = {}
    for name in ("pofu", "mochi"):
        (fx, fy), wpct = FEET[name]
        sw = round(wpct / 100 * plate.shape[1] * k)
        spr = sprite(name, sw)
        feet = (round(fx / 100 * plate.shape[1] * k), round(fy / 100 * plate.shape[0] * k))
        (ppx, ppy), pcol, pstr = PRACTICAL[key]
        prac = ((round(ppx / 100 * pw), round(ppy / 100 * ph)), pcol, pstr)
        lit, inf = lit_from_plate(spr, pr, pa, feet, prac)
        info[name] = inf["gain"]
        contact_pad(canvas, px + feet[0], py + feet[1], sw, inf["ratio"])
        place(canvas, lit, px + feet[0], py + feet[1] + round(0.02 * sw))
    # The front cloud row over the plate's foot.
    f_rgb, f_a = cloud_sea(cell, W, H, py + y1b * k + 0.012 * H, rows=1, front_only=True)
    f_a = f_a * 0.92
    canvas = canvas * (1 - f_a[..., None]) + f_rgb * f_a[..., None]
    out = np.asarray(Image.fromarray(np.uint8(np.clip(canvas, 0, 1) * 255 + 0.5)).resize(FRAME, Image.Resampling.LANCZOS), np.float64) / 255
    box = ((px + x0b * k) / SS, (py + y0b * k) / SS, (px + x1b * k) / SS, (py + y1b * k) / SS)
    full_a = np.zeros(canvas.shape[:2])
    ys, xs = slice(max(py, 0), min(py + ph, H)), slice(max(px, 0), min(px + pw, W))
    full_a[ys, xs] = pa[ys.start - py:ys.stop - py, xs.start - px:xs.stop - px]
    island = np.asarray(Image.fromarray(np.uint8(full_a * 255)).resize(FRAME, Image.Resampling.BILINEAR), np.float64) / 255
    return out, {"box": box, "island": island, "lit": info}


def diff_mask(a: np.ndarray, b: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    d = ll.de2000(srgb_to_lab(a), srgb_to_lab(b))
    d = ndimage.gaussian_filter(d, 3)
    m = smooth(6, 16, d) * (alpha > 0.5)
    m = ndimage.binary_dilation(m > 0.5, iterations=6).astype(np.float64)
    return ndimage.gaussian_filter(m, 6)


def transition(stuck, healed, alpha, origin, t: float) -> np.ndarray:
    """The diff-mask reveal: changed pixels flip inside a ring growing from `origin`; the rest crossfade."""
    h, w = alpha.shape
    m = diff_mask(stuck, healed, alpha)
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.hypot(xx - origin[0] * w / 100, (yy - origin[1] * h / 100) * 1.4) / w
    r = t * 1.1
    front = smooth(r, r - 0.08, d) if t > 0 else np.zeros_like(d)
    b = m * front + (1 - m) * smooth(0.3, 0.9, t)
    out = stuck * (1 - b[..., None]) + healed * b[..., None]
    ring = np.exp(-((d - r) / 0.02) ** 2) * m * (0 < t < 1)
    return screen(out, ring[..., None] * np.array([1.0, 0.85, 0.55]) * 0.35)


# ---------------------------------------------------------------- measuring

def regions(img: np.ndarray, island: np.ndarray, box) -> dict:
    """sky (open sky above the island), top (island top: props, snow), earth (body), sea (below)."""
    h, w = img.shape[:2]
    x0, y0, x1, y1 = box
    bh = y1 - y0
    Y, X = np.mgrid[0:h, 0:w]
    isl = island > 0.9
    out = {
        "sky": (~(island > 0.05)) & (Y < y0 + 0.35 * bh) & (Y > max(y0 - 0.5 * bh, 0.12 * h)),
        "top": isl & (Y < y0 + 0.62 * bh) & (X > x0 + 0.08 * (x1 - x0)) & (X < x1 - 0.08 * (x1 - x0)),
        "earth": isl & (Y > y0 + 0.66 * bh) & (Y < y0 + 0.9 * bh),
        "sea": (~(island > 0.05)) & (Y > y1 + 0.02 * h) & (Y < min(y1 + 0.25 * h, 0.95 * h)),
    }
    lab = srgb_to_lab(img)
    L = lab[..., 0]
    loc = (L - ndimage.gaussian_filter(L, 2.0)) ** 2
    res = {}
    for k, m in out.items():
        if m.sum() < 50:
            continue
        res[k] = {"lab": lab[m].mean(0), "L": float(L[m].mean()), "C": float(np.hypot(lab[..., 1][m], lab[..., 2][m]).mean()),
                  "loc": float(np.sqrt(loc[m].mean()))}
    return res


def caption(name: str, r: dict, ref: dict | None) -> str:
    parts = [f"{k} {r[k]['L']:.0f}/{r[k]['C']:.0f}" + (f"/{r[k]['loc']:.1f}" if k in ("top", "earth") else "")
             for k in ("sky", "top", "earth", "sea") if k in r]
    s = name + "\n" + "  ".join(parts[:2]) + "\n" + "  ".join(parts[2:])
    if ref:
        de = [float(ll.de2000(r[k]["lab"], ref[k]["lab"])) for k in ("sky", "top", "earth", "sea") if k in r and k in ref]
        s += f"\ndE2000 {np.mean(de):.1f}  (" + " ".join(f"{v:.0f}" for v in de) + ")"
    return s


def concept_frame(rgb: np.ndarray, a: np.ndarray, pose: str) -> tuple[np.ndarray, np.ndarray, tuple]:
    """The concept itself, cropped to the phone's aspect around its island at the pilot's scale: the
    reference column measures the same regions the pilot does."""
    x0, y0, x1, y1 = bbox(a)
    bw, by0 = (441, 457) if pose == "whole" else (621, 470)
    k = bw / (x1 - x0)
    W, H = FRAME
    big = np.asarray(Image.fromarray(np.uint8(rgb * 255)).resize((round(rgb.shape[1] * k), round(rgb.shape[0] * k)), Image.Resampling.LANCZOS), np.float64) / 255
    ba = np.asarray(Image.fromarray(np.uint8(a * 255)).resize((big.shape[1], big.shape[0]), Image.Resampling.BILINEAR), np.float64) / 255
    cx, cy = (x0 + x1) / 2 * k, (y0 + y1) / 2 * k
    ox, oy = round(cx - W / 2), round(cy - by0)
    canvas = np.full((H, W, 3), 0.94)
    isl = np.zeros((H, W))
    sx0, sy0 = max(ox, 0), max(oy, 0)
    sx1, sy1 = min(ox + W, big.shape[1]), min(oy + H, big.shape[0])
    canvas[sy0 - oy:sy1 - oy, sx0 - ox:sx1 - ox] = big[sy0:sy1, sx0:sx1]
    isl[sy0 - oy:sy1 - oy, sx0 - ox:sx1 - ox] = ba[sy0:sy1, sx0:sx1]
    box = (x0 * k - ox, y0 * k - oy, x1 * k - ox, y1 * k - oy)
    return canvas, isl, box


def ci_frame(path: Path, stage: int) -> tuple[np.ndarray, np.ndarray, tuple]:
    img = pale.load(path)
    p = pale.CAGLAYAN_IN_FRAME
    sp = Image.open(pale.ASSETS / f"world-caglayan-island-{stage}.imageset/world-caglayan-island-{stage}.png").convert("RGBA")
    w, h = round(sp.width * p["scale"]), round(sp.height * p["scale"])
    a = np.asarray(sp.resize((w, h), Image.Resampling.LANCZOS))[..., 3] / 255
    isl = np.zeros(img.shape[:2])
    isl[p["y"]:p["y"] + h, p["x"]:p["x"] + w] = a
    return img, isl, bbox(isl)


def home_frame(path: Path) -> tuple[np.ndarray, np.ndarray, tuple]:
    """concept-night-home: the island fills the width; its top is 0.33 to 0.57 and its body 0.6 to 0.75."""
    img = pale.load(path)
    h, w = img.shape[:2]
    isl = np.zeros((h, w))
    isl[int(0.33 * h):int(0.75 * h)] = 1
    return img, isl, (0, 0.33 * h, w, 0.75 * h)


def to_img(x: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255 + 0.5))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shots", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--frames", type=Path)
    a = ap.parse_args(argv)
    cell = CELLS["night"]

    stuck, sa = load_take("stuck")
    healed_raw, ha_raw = load_take("healed")
    healed, ha = align(healed_raw, ha_raw, sa)
    alpha = np.minimum(sa, ha)  # one matte for the pair, as production plates share one

    frames, readout = {}, {}
    frames["s0-whole"] = compose(stuck, sa, 0, "stuck", "whole", cell)
    frames["s4-whole"] = compose(healed_raw, ha_raw, 4, "healed", "whole", cell)
    frames["s4-close"] = compose(healed_raw, ha_raw, 4, "healed", "close", cell)
    for i, t in enumerate((0.0, 1 / 3, 2 / 3, 1.0)):
        mid = transition(stuck, healed, alpha, (52, 18), t)
        frames[f"tr-{i}"] = compose(mid, alpha, 4, "healed" if t >= 0.5 else "stuck", "whole", cell, aurora_strength=t ** 1.5)

    def native(path, key):
        rgb = ll.load_rgb(path)
        m = matte(rgb, TRACE[key], KEEP[key])
        return rgb, m, bbox(m)
    refs = {"s0": native(pale.REF_STUCK, "stuck"), "s4": native(pale.REF_HEALED, "healed")}
    refs["s4c"] = refs["s4"]

    def at_pilot_scale(rgb, m, box):
        # Measured where the island is as wide as in the whole pose (441 px), so local contrast compares.
        k = 441 / (box[2] - box[0])
        size = (round(rgb.shape[1] * k), round(rgb.shape[0] * k))
        r2 = np.asarray(to_img(rgb).resize(size, Image.Resampling.LANCZOS), np.float64) / 255
        m2 = np.asarray(Image.fromarray(np.uint8(m * 255)).resize(size, Image.Resampling.BILINEAR), np.float64) / 255
        return r2, m2, tuple(v * k for v in box)
    measured = {k: at_pilot_scale(*v) for k, v in refs.items()}
    cur = {
        "s0": ci_frame(a.shots / "caglayan-night-0.jpg", 0),
        "s4": ci_frame(a.shots / "caglayan-night-4.jpg", 4),
        "s4c": home_frame(a.shots / "concept-night-home.jpg"),
    }
    R = {k: regions(*v) for k, v in measured.items()}

    def cell_of(img, isl, box, name, ref, measure=None):
        r = regions(*(measure or (img, isl, box)))
        readout[name] = {k: {m: round(v[m], 1) for m in ("L", "C", "loc")} for k, v in r.items()}
        return to_img(img), caption(name, r, ref)

    rows = []
    for key, ref_key, label in (("s0-whole", "s0", "stage 0"), ("s4-whole", "s4", "stage 4"), ("s4-close", "s4c", "stage 4 close")):
        img, info = frames[key]
        rows.append([
            cell_of(*refs[ref_key], f"concept · {label} (whole take)", None, measured[ref_key]),
            cell_of(*cur[ref_key], "current (Çağlayan CI, night)" if ref_key != "s4c" else "current (home, night CI)", R[ref_key]),
            cell_of(img, info["island"], info["box"], f"plate-first · {label}", R[ref_key]),
        ])
    # The transition row: the concept pair, the current plain crossfade, the pilot's reveal as 2 x 2
    # crops of the island (the change is too small to read on whole frames at this size).
    pair = np.concatenate([refs["s0"][0], refs["s4"][0]], 0)
    cross = cur["s0"][0] * 0.5 + cur["s4"][0] * 0.5
    crops = [frames[f"tr-{i}"][0][150:600] for i in range(4)]
    grid = np.concatenate([np.concatenate(crops[:2], 1), np.concatenate(crops[2:], 1)], 0)
    des = []
    for i in range(4):
        img, info = frames[f"tr-{i}"]
        r = regions(img, info["island"], info["box"])
        des.append(np.mean([float(ll.de2000(r[k]["lab"], R["s4"][k]["lab"])) for k in r if k in R["s4"]]))
    rows.append([
        (to_img(pair), "concept · stuck t1 / healed t2\n(independent takes: props move)"),
        (to_img(cross), "current · Çağlayan 0 → 4\nplain crossfade at 50 %"),
        (to_img(grid), "plate-first · reveal t = 0, 1/3 (top) · 2/3, 1 (bottom), from the lantern\n"
                       f"dE2000 to healed concept {des[0]:.1f} → {des[1]:.1f} → {des[2]:.1f} → {des[3]:.1f}"),
    ])
    ll.sheet(rows, a.out, title="Plate-first pilot · Revontuli at night, iPhone 17 portrait (460 x 1000 = 402 x 874 pt)"
             " · captions: region L*/C*(/local contrast) · sky, top, earth, sea", cell_h=520, max_kb=900)
    if a.frames:
        a.frames.mkdir(parents=True, exist_ok=True)
        for k, (img, _) in frames.items():
            to_img(img).save(a.frames / f"{k}.png")
    readout["lit"] = {k: v[1]["lit"] for k, v in frames.items() if k.startswith("s")}
    readout["transition_dE"] = [round(x, 1) for x in des]
    print(json.dumps(readout, indent=1, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
