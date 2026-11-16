#!/usr/bin/env python3
"""N6 of docs/design/night-plan-2026-11-15.md: does a station's level show on the island?

Sets batch 123's tea-stall looks (pofu-art, the lead's picks) on batch 117's erased Home base (the level 3 day
plate with the stall painted out) and renders the three rail stops (Map, Island, Home) for stall levels 1, 3, 5
at 1206 x 2622, plus a sheet. Script only; nothing but the proof images is written, and they go outside the repo
unless you ask for them.

    python3 -I tools/proof/upgrade_proof.py --art DIR --erase TAKE.webp --out DIR [--stalls 1 3 5] [--debug]

`--art` holds `look1.webp` .. `look5.webp` (the picked takes of batch 123, picks 1, 1, 2, 1, 1), `--erase` is the
picked take of batch 117's `x-base-erase-l03-day` (pick 1). Needs the island matte's model
(`POFU_BIREFNET`, see island_matte.py) the first time, then its cache.

The stops are the shipped rail's numbers (HomePlate.mapStop at tier 0, islandStop 0.9 widths, homeStop), computed
here in plate points: u = 0.3253 world units per plate point, 3 device px per pt.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import island_matte  # noqa: E402
import skyset_still  # noqa: E402
from _common import H, W, Sprite  # noqa: E402

U = 0.3253                      # world units per plate point
PT = 3.0                        # device px per pt
TEX = 2                         # plate texture px per plate point
STAGE = 7                       # plate stage 7 = island level 3 (stage = 10 - level)
BOX = (4.0, 438.0, 1019.0, 1230.0)   # plate-home.json islandBox, plate points

# the paste region of the stall on the erased take, texture px (x0, y0, x1, y1): the diff of take and parent at
# 1:1 shows the stall, its teapot and the sky between the posts inside it; the cart (right) and the rope bridge
# (below) stay the parent's, as the lead's review of the level 3 take asks.
PASTE = (1246, 1330, 1512, 1664)
FEATHER = 9.0
# look 1 against the plate's own stall (texture px): scale and the foot of the counter
SCALE = 0.294
FOOT = (1380.0, 1664.0)         # bottom centre of the look 1 alpha box
GRADE = dict(chroma=0.65, light=1.05, alpha_floor=12)   # the lead's ingest notes of batch 123

# rail stops: scale (pt per world unit), look (plate points), anchorY (pt)
def stops() -> dict[str, tuple[float, tuple[float, float], float]]:
    cx, cy = (BOX[0] + BOX[2]) / 2, (BOX[1] + BOX[3]) / 2
    # Map, tier 0 (no wonder island open): Home alone, 0.70 of the width, its foot at 0.80 of the height; the
    # next island's tower (veiled Koke, 195 units wide at -150) stands left of it and sets the look's x.
    home_w = 330.0
    s_map = min(0.70 * 402 / home_w, 370.0 / (165 + 247.5))
    look_x = (-247.5 + 165) / 2
    look_y = 257 / 2 - (0.8 * 874 - 437) / s_map
    s_isl = 0.9 * 402 / ((BOX[2] - BOX[0]) * U)
    return {
        "map": (s_map, (cx + look_x / U, cy + look_y / U), 437.0),
        "mid": (s_isl, (cx, cy), (118 + 874 - 198) / 2),
        "near": (1.40, (BOX[0] + 0.47 * (BOX[2] - BOX[0]), BOX[1]), 292.0),
    }


def srgb_lab(rgb):
    return cv2.cvtColor(rgb.astype(np.float32), cv2.COLOR_RGB2Lab)


def lab_srgb(lab):
    return np.clip(cv2.cvtColor(lab.astype(np.float32), cv2.COLOR_Lab2RGB), 0, 1)


def load_look(path: Path) -> np.ndarray:
    """A look as straight RGBA floats, graded: alpha below 12/255 is 0, chroma x0.65, lightness +5 percent."""
    a = np.asarray(Image.open(path).convert("RGBA"), np.float32) / 255
    a[..., 3] = np.where(a[..., 3] * 255 < GRADE["alpha_floor"], 0, a[..., 3])
    lab = srgb_lab(a[..., :3])
    lab[..., 0] = np.clip(lab[..., 0] * GRADE["light"], 0, 100)
    lab[..., 1:] *= GRADE["chroma"]
    a[..., :3] = lab_srgb(lab)
    return a


def chroma(rgb: np.ndarray, m: np.ndarray) -> float:
    lab = srgb_lab(rgb)
    c = np.hypot(lab[..., 1], lab[..., 2])
    return float(np.median(c[m > 0.5]))


def place_look(look: np.ndarray, size: tuple[int, int]) -> tuple[np.ndarray, tuple[int, int]]:
    """The look scaled to the plate and its alpha-box foot at FOOT; returns the RGBA and its top-left (texture px).
    The scale and foot come from look 1 so that every level shares them (the foot holds within 10 px in 1254 px)."""
    return cv2.resize(look, None, fx=SCALE, fy=SCALE, interpolation=cv2.INTER_AREA), (0, 0)


def over(base: np.ndarray, top: np.ndarray) -> np.ndarray:
    """Straight RGBA over straight RGBA."""
    a = top[..., 3:4]
    ba = base[..., 3:4]
    oa = a + ba * (1 - a)
    rgb = (top[..., :3] * a + base[..., :3] * ba * (1 - a)) / np.maximum(oa, 1e-6)
    return np.concatenate([rgb, oa], -1)


def sky_alpha(rgb: np.ndarray) -> np.ndarray:
    """1 on the island, 0 on the painted sky, for the pasted region of the erased take (sky is blue, grass is not)."""
    blue = rgb[..., 2] - (rgb[..., 0] + rgb[..., 1]) / 2
    s = np.clip((blue - 0.02) / 0.10, 0, 1)
    s = cv2.GaussianBlur(s, (0, 0), 1.2)
    return 1 - s


def build_layers(art: Path, erase: Path, stalls: list[int], debug: Path | None):
    """The island layer (straight RGBA at texture size) with the stall painted out, and one per stall level."""
    rgba, (lx, ly) = island_matte.island_layer("day", STAGE)          # the parent's clean cut
    rgba = rgba.copy()
    plate = island_matte.plate_rgb("day", STAGE)
    take = np.asarray(Image.open(erase).convert("RGB").resize((plate.shape[1], plate.shape[0]), Image.LANCZOS), np.float32) / 255
    ox, oy = lx * TEX, ly * TEX
    x0, y0, x1, y1 = PASTE
    # the paste mask is the old stall itself: where the take differs from its parent inside PASTE, closed, holes
    # filled and grown 8 px, feathered 3 px. Rim, cart and bridge are outside it and stay the parent's.
    d = np.abs(take - plate).max(-1)
    raw = np.zeros(plate.shape[:2], np.uint8)
    raw[y0:y1, x0:x1] = (d[y0:y1, x0:x1] > 0.12)
    raw = cv2.morphologyEx(raw, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
    n, lab, stat, _ = cv2.connectedComponentsWithStats(raw, connectivity=8)
    keep = 1 + int(np.argmax(stat[1:, cv2.CC_STAT_AREA]))
    raw = ndimage.binary_fill_holes(lab == keep).astype(np.uint8)
    raw = cv2.dilate(raw, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (17, 17)))
    m = cv2.GaussianBlur(raw.astype(np.float32), (0, 0), 3.0)
    ya = max(y0 - 40, oy)
    sl = (slice(ya, y1 + 40), slice(x0 - 40, x1 + 40))
    lsl = (slice(ya - oy, y1 + 40 - oy), slice(x0 - 40 - ox, x1 + 40 - ox))
    mm = m[sl][..., None]
    t_rgb = take[sl]
    t_a = sky_alpha(t_rgb)
    # the take's colours at the grass line are mixed with sky: pull them from the nearest sure-island pixel
    sure = t_a > 0.97
    idx = ndimage.distance_transform_edt(~sure, return_distances=False, return_indices=True)
    fixed = t_rgb[idx[0], idx[1]]
    t_rgb = np.where((t_a < 0.97)[..., None], fixed, t_rgb)
    base = rgba[lsl]
    # the rim stays the parent's: the take may only take island away (the old stall hanging in the sky), never add it
    new_a = base[..., 3:4] * (1 - mm) + np.minimum(base[..., 3], t_a)[..., None] * mm
    new_rgb = base[..., :3] * (1 - mm) + t_rgb * mm
    rgba[lsl] = np.concatenate([new_rgb, new_a], -1)
    erased = rgba.copy()
    if debug:
        dbg = np.concatenate([(rgba[lsl][..., :3] * rgba[lsl][..., 3:4] + (1 - rgba[lsl][..., 3:4]) * np.float32([1, 0, 1]))], 1)
        Image.fromarray((dbg * 255).astype(np.uint8)).save(debug / "erased-base-crop.png")
    out = {}
    for n in stalls:
        look, _ = place_look(load_look(art / f"look{n}.webp"), (0, 0))
        ys, xs = np.where(look[..., 3] > 0.05)
        # alpha-box bottom centre of look 1 is the anchor of every level (same transform)
        if n == stalls[0] or "anchor" not in out:
            pass
        out[n] = look
    # anchor from look 1's alpha box, whichever levels are asked
    l1 = place_look(load_look(art / "look1.webp"), (0, 0))[0]
    ys, xs = np.where(l1[..., 3] > 0.05)
    ax, ay = (xs.min() + xs.max()) / 2, ys.max()
    layers = {}
    for n, look in out.items():
        lay = erased.copy()
        # a soft contact shade under the foot (the app draws one): on the island only
        yy, xx = np.mgrid[0:lay.shape[0], 0:lay.shape[1]].astype(np.float32)
        cxp, cyp = FOOT[0] - ox, FOOT[1] - oy
        sh = np.clip(1 - (((xx - cxp) / 140) ** 2 + ((yy - cyp + 4) / 24) ** 2), 0, 1) ** 0.8
        sh = cv2.GaussianBlur(sh, (0, 0), 9) * 0.34
        sh_rgb = np.float32([0.16, 0.22, 0.10])
        k = (sh * lay[..., 3])[..., None]
        lay[..., :3] = lay[..., :3] * (1 - k) + sh_rgb * k
        # the look
        tx, ty = int(round(FOOT[0] - ox - ax)), int(round(FOOT[1] - oy - ay))
        h, w = look.shape[:2]
        sub = lay[ty:ty + h, tx:tx + w]
        lay[ty:ty + h, tx:tx + w] = over(sub, look)
        layers[n] = lay
    return layers, (lx, ly), (rgba, erased)


def render(layer: np.ndarray, origin: tuple[int, int], stop: tuple[float, tuple[float, float], float]) -> np.ndarray:
    scale, (lookx, looky), anchor_y = stop
    s_pt = scale * PT * U                       # device px per plate point
    # master px = 2 plate points; the sky set wants master coords
    sky = skyset_still.draw_set(s_pt / 2, (lookx * 2, looky * 2), (W / 2, anchor_y * PT), "day", STAGE, island=False)
    spr = Sprite(layer)
    lx, ly = origin
    x = W / 2 + (lx - lookx) * s_pt
    y = anchor_y * PT + (ly - looky) * s_pt
    spr.draw(sky, x, y, layer.shape[1] / TEX * s_pt, layer.shape[0] / TEX * s_pt)
    rgb = sky[..., :3] + (1 - sky[..., 3:4]) * np.float32([0.7, 0.8, 0.95])
    return np.clip(rgb, 0, 1)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--art", type=Path, required=True)
    ap.add_argument("--erase", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--stalls", type=int, nargs="+", default=[1, 3, 5])
    ap.add_argument("--cams", nargs="+", default=["map", "mid", "near"])
    ap.add_argument("--debug", action="store_true")
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    layers, origin, (base, erased) = build_layers(a.art, a.erase, a.stalls, a.out if a.debug else None)
    st = stops()
    frames = {}
    for n, lay in layers.items():
        for cam, stop in st.items():
            if cam not in a.cams:
                continue
            fr = render(lay, (origin[0] * TEX, origin[1] * TEX), (stop[0], stop[1], stop[2])) if False else render(lay, origin, stop)
            frames[(n, cam)] = fr
            Image.fromarray((fr * 255 + 0.5).astype(np.uint8)).save(a.out / f"stall{n}-{cam}.png")
            print(n, cam, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
