#!/usr/bin/env python3
"""Painted-detail motion for the sky set's isles and whale (ADR-0025): masks, textures and constants.

    python3 tools/plate/skyset_detail.py home [--masks] [--light day|golden|night|all]

Run after `skyset_export.py` (which calls it). The isle sprites and the whale carry detail the painter
drew and the app only moves as a whole image; this gives that detail a little life of its own, code only,
from the sprites' own pixels (no new art, no colour change):

  fall   a waterfall's water flows down: a soft streak texture (the sprite's own high-pass detail, kept
         zero-mean, laid over the fall's own column colours) scrolls inside a mask at `speed` reference
         px/s and is blended in lightly, so the mean colour of the fall holds; a faint mist puff at the
         foot breathes
  sway   a canopy's inside shears 1 to 2 px under a feathered mask (its silhouette stays), the top
         moving most
  glow   a lantern or window flickers by a few per cent of its own light, slowly

`design/art/plates/home/sky/detail.json` says where (boxes and ellipses in the sprite's pixels). The masks
are built from the sprite's colours and written to `design/art/plates/home/sky/detail/<light>/<sprite>-<id>.png`
(alpha masks, cropped to their region); an existing PNG is used as it is, so a mask can be adjusted by hand
(`--masks` rebuilds them). The app's assets are PNG imagesets `world-<island>-sky-fx-...`, and the motion
constants (`DETAIL_MOTION`) go into `skyset-<island>.json`, the one source `PofuWorld/Sky/SkySet.swift` and
`skyset_render.py` read. At time zero nothing is drawn (every amount rises from zero over `ramp` seconds),
so the first frame is the painting.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import skyset_export as ex  # noqa: E402

PLATES = ex.PLATES
ASSETS = ex.ASSETS
JSON_DIR = ex.JSON_DIR

#: Motion, in screen px at the 1206 px reference screen (scaled by width / 1206 in the app); seconds.
#: `ramp`: every amount rises from 0 over this long (smoothstep), so time zero is the painting.
#: fall.speed: px/s down; fall.strength: how much of the moving streak texture is blended (0..1);
#: fall.gain: the streak contrast in luminance (a fraction), zero-mean; mist: peak opacity and breath period.
#: sway.amp: the canopy top's displacement; glow.amp: luminance fraction, two slow periods.
DETAIL_MOTION = {
    "ramp": 1.5,
    "fall": {"speed": 20, "strength": 0.7, "gain": 0.14, "mist": {"peak": 0.14, "period": 5.0}},
    "sway": {"amp": 1.6, "period": 4.6},
    "glow": {"amp": {"day": 0.04, "golden": 0.05, "night": 0.06}, "periods": [3.7, 2.3]},
}
SWAY_PAD = 4          # px of sprite round a sway mask: the picture it slides
FLOW_SIGMA_X = 0.9    # px: the noise's horizontal softness
FLOW_SIGMA_Y = 3.0    # px: and its vertical stretch (water streaks run down)
SEED = 7


def asset_name(island: str, sprite: str, ident: str, part: str, light: str) -> str:
    return f"world-{island}-sky-fx-{sprite.replace('_', '-')}-{ident}-{part}-{light}-0"


def mask_path(island: str, light: str, sprite: str, ident: str) -> Path:
    return PLATES / island / "sky" / "detail" / light / f"{sprite}-{ident}.png"


def load_sprite(layer: dict) -> np.ndarray:
    f = ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}.heic"
    return np.asarray(heic.open_image(f).convert("RGBA"), np.float32) / 255


def smoothstep(a: float, b: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def lab(rgb: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(np.ascontiguousarray(rgb, dtype=np.float32), cv2.COLOR_RGB2Lab)


# ---------------------------------------------------------------- masks

def fall_mask(a: np.ndarray, box: list[int]) -> np.ndarray:
    """The fall inside `box`, a hand-tight rectangle: its pixels that are close in colour to the fall's own
    colour at that row (the median of the row's middle half; the grass lip or the rock beside it drop out),
    solid in the sprite, inset a pixel and feathered, so the edges are soft and follow the water's own
    edge. A box-sized float array 0..1."""
    x0, y0, x1, y1 = box
    c = a[y0:y1, x0:x1]
    h, w = c.shape[:2]
    L = lab(c[..., :3])
    mid = slice(w // 4, w - w // 4)
    ref = np.stack([np.median(L[y, mid], axis=0) for y in range(h)]).astype(np.float32)
    ref = ndimage.gaussian_filter1d(ref, 2.5, axis=0)[:, None, :]
    gate = 1 - smoothstep(12.0, 24.0, np.linalg.norm(L - ref, axis=-1))
    rect = np.zeros((h, w), np.float32)
    rect[1:-1, 1:-1] = 1
    m = rect * gate * (c[..., 3] > 0.95)
    return np.minimum(np.clip(cv2.GaussianBlur(m, (0, 0), 0.9), 0, 1), c[..., 3])


def sway_mask(a: np.ndarray, ellipse: list[float]) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """A canopy's inside: the ellipse, solid sprite pixels only (so its silhouette never moves), eroded
    well in and feathered. Returns the mask and the region (x0, y0, x1, y1) with `SWAY_PAD` round it."""
    cx, cy, rx, ry = ellipse
    x0, y0 = int(cx - rx) - SWAY_PAD, int(cy - ry) - SWAY_PAD
    x1, y1 = int(cx + rx) + SWAY_PAD + 1, int(cy + ry) + SWAY_PAD + 1
    yy, xx = np.mgrid[y0:y1, x0:x1]
    inside = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1
    solid = a[y0:y1, x0:x1, 3] > 0.97
    m = inside & solid
    m = ndimage.binary_erosion(m, np.ones((3, 3)), iterations=4, border_value=0)
    return np.clip(cv2.GaussianBlur(m.astype(np.float32), (0, 0), 2.4), 0, 1), (x0, y0, x1, y1)


def glow_mask(a: np.ndarray, e: dict) -> np.ndarray:
    """A lit lamp or window: bright and warm inside the entry's box, feathered (`sat` and `warm` ramps
    may be set per entry: a window's cream is paler than a lantern's gold)."""
    x0, y0, x1, y1 = e["box"]
    s_lo, s_hi = e.get("sat", [0.40, 0.58])
    w_lo, w_hi = e.get("warm", [0.08, 0.28])
    c = a[y0:y1, x0:x1]
    r, g, b = c[..., 0], c[..., 1], c[..., 2]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    sat = (c[..., :3].max(-1) - c[..., :3].min(-1)) / np.maximum(c[..., :3].max(-1), 1e-3)
    m = smoothstep(0.62, 0.82, lum) * smoothstep(s_lo, s_hi, sat) * smoothstep(w_lo, w_hi, r - b) * (c[..., 3] > 0.9)
    m = ndimage.grey_dilation(m, size=(3, 3))
    return np.minimum(np.clip(cv2.GaussianBlur(m.astype(np.float32), (0, 0), 0.9), 0, 1), c[..., 3])


def read_mask(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), np.float32)[..., 3] / 255


def write_mask(path: Path, m: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rgba = np.dstack([np.full(m.shape + (3,), 255, np.uint8), np.uint8(m * 255 + 0.5)[..., None]])
    Image.fromarray(rgba, "RGBA").save(path, optimize=True)


def build_masks(island: str, light: str, hand: dict, layers: dict, *, force: bool) -> dict:
    """Every entry's mask (a box-sized float array) and its region, rebuilt only when `force` or missing."""
    out = {}
    for sprite, entries in hand.get(light, {}).items():
        a = load_sprite(layers[sprite])
        for e in entries:
            p = mask_path(island, light, sprite, e["id"])
            if e["kind"] == "sway":
                m, region = sway_mask(a, e["ellipse"])
            else:
                region = tuple(e["box"])
                m = fall_mask(a, e["box"]) if e["kind"] == "fall" else glow_mask(a, e)
            if force or not p.exists():
                write_mask(p, m)
            else:
                m = read_mask(p)
                assert m.shape == (region[3] - region[1], region[2] - region[0]), f"{p.name} does not fit its region"
            out[(sprite, e["id"])] = (m, region)
    return out


# ---------------------------------------------------------------- flow texture

def flow_texture(c: np.ndarray, m: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """The streak texture for a fall: an RGBA tile twice the fall's height (the fall's detail mirrored, so it
    wraps without a seam), `(2h, w, 4)` straight 0..1.

    It is a lighter-or-darker veil, so the painter's own gradient stays under it (nothing is replaced):
    the sprite's own high-pass detail (the pixels minus their local mean under the mask) is rolled by a
    random amount per column (streaks run down at different phases), softened along the columns,
    normalised to unit rms and made zero-mean on every row; where it is positive the veil is the fall's
    column colour lightened by `gain`, where negative that colour darkened by `gain`, with alpha
    |detail| / 2. Lightening and darkening are equal, so a fall's mean colour holds; the app draws the veil
    scrolling inside the mask at `strength` of its alpha."""
    h, w = m.shape
    mm = np.maximum(m, 1e-3)
    num = cv2.GaussianBlur(c * mm[..., None], (0, 0), 3.0)
    den = cv2.GaussianBlur(mm, (0, 0), 3.0)[..., None]
    detail = (c - num / np.maximum(den, 1e-3)).mean(-1)                      # signed luminance detail
    rolled = np.stack([np.roll(detail[:, x], int(rng.integers(0, h))) for x in range(w)], axis=1)
    rolled = cv2.GaussianBlur(rolled, (0, 0), sigmaX=FLOW_SIGMA_X, sigmaY=FLOW_SIGMA_Y)
    rolled -= (rolled * m).sum() / max(m.sum(), 1e-6)
    rolled /= max(float(np.sqrt(((rolled ** 2) * m).sum() / max(m.sum(), 1e-6))), 1e-6)   # unit rms under the mask
    solid = np.nonzero(m.max(0) > 0.9)[0]                                    # the columns the water fills
    col = np.stack([np.median(c[m[:, x] > 0.5, x], axis=0) if (m[:, x] > 0.5).any() else np.zeros(3, np.float32)
                    for x in range(w)])                                       # the fall's colour per column (median: a rim's shadow drops out)
    for x in range(w):
        if m.max(0)[x] <= 0.9:                                               # edge columns (the rock's rim) copy the nearest solid one
            col[x] = col[solid[np.argmin(np.abs(solid - x))]]
    col = ndimage.gaussian_filter1d(col, 0.8, axis=0, mode="nearest")
    lum = col.mean(1)
    keep = (np.abs(lum - np.median(lum)) < 0.06) & (m.max(0) > 0.9)           # a shaded rim keeps its own tone: no veil there
    if keep.any():                                                           # zero-mean on every row, so any window of the scroll is neutral
        rolled = rolled - (rolled * keep[None, :]).sum(1, keepdims=True) / keep.sum()
    rolled = np.clip(rolled, -2.0, 2.0) * keep[None, :]
    tile = np.concatenate([rolled, rolled[::-1]], axis=0)                    # 2h rows, mirrored: wraps
    g = np.minimum(DETAIL_MOTION["fall"]["gain"], (1 - col.max(1)) / np.maximum(col.max(1), 1e-3))[None, :, None]   # equal both ways: no clipping at white
    rgb = np.where(tile[..., None] > 0, col[None] * (1 + g), col[None] * (1 - g))
    return np.dstack([np.clip(rgb, 0, 1), np.clip(np.abs(tile) / 2.0, 0, 1)]).astype(np.float32)


def mist_spec(c: np.ndarray, a_all: np.ndarray, region: tuple, m: np.ndarray) -> dict:
    """Where the mist breathes: at the foot of the mask (its lowest solid row), centred on the fall, as wide
    as the fall and a third as tall; coloured with the fall's own lightest pixels."""
    x0, y0, x1, y1 = region
    rows = np.nonzero(m.max(1) > 0.5)[0]
    foot = int(rows.max())
    cols = np.nonzero(m[max(foot - 3, 0): foot + 1].max(0) > 0.5)[0]
    cx = float(cols.mean()) if len(cols) else m.shape[1] / 2
    wid = float(np.ptp(cols) + 1) if len(cols) else m.shape[1]
    sel = m > 0.8
    px = c[sel]
    lum = px.mean(-1)
    colour = px[lum >= np.quantile(lum, 0.6)].mean(0)
    colour = colour + (1 - colour) * 0.35                                     # a mist is a touch paler than the water
    ry = max(wid * 0.45, 5.0)
    return {"centre": [x0 + cx, y0 + foot + 1.0 + ry * 0.9], "radius": [max(wid * 0.9, 8.0), ry],
            "color": [round(float(v), 4) for v in colour]}


# ---------------------------------------------------------------- export

def write_png_set(name: str, arr: np.ndarray) -> int:
    d = ASSETS / f"{name}.imageset"
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    dst = d / f"{name}.png"
    Image.fromarray(np.uint8(np.clip(arr, 0, 1) * 255 + 0.5), "RGBA" if arr.shape[-1] == 4 else "RGB").save(dst, optimize=True)
    (d / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": dst.name, "idiom": "universal"}], "info": {"author": "xcode", "version": 1}},
        indent=2) + "\n")
    return arr.shape[0] * arr.shape[1]


def clear_old(island: str, light: str) -> None:
    for d in ASSETS.glob(f"world-{island}-sky-fx-*-{light}-0.imageset"):
        shutil.rmtree(d)


def export_light(island: str, light: str, spec: dict, hand: dict, force: bool) -> int:
    """Writes the detail assets and each sprite layer's `details`; returns the new pixels."""
    clear_old(island, light)
    layers = {l["id"]: l for l in spec["layers"]}
    masks = build_masks(island, light, hand, layers, force=force)
    rng = np.random.default_rng(SEED)
    pixels = 0
    for sprite, entries in hand.get(light, {}).items():
        layer = layers[sprite]
        a = load_sprite(layer)
        sh, sw = a.shape[:2]
        rx, ry = layer["size"][0] / sw, layer["size"][1] / sh                  # master px per stored px
        details = []
        for e in entries:
            m, (x0, y0, x1, y1) = masks[(sprite, e["id"])]
            c = a[y0:y1, x0:x1]
            item = {"id": e["id"], "kind": e["kind"],
                    "pos": [round(layer["pos"][0] + x0 * rx, 3), round(layer["pos"][1] + y0 * ry, 3)],
                    "size": [round((x1 - x0) * rx, 3), round((y1 - y0) * ry, 3)],
                    "ramp": DETAIL_MOTION["ramp"]}
            if e["kind"] == "fall":
                mk = DETAIL_MOTION["fall"]
                item["mask"] = asset_name(island, sprite, e["id"], "mask", light)
                pixels += write_png_set(item["mask"], np.dstack([np.ones(m.shape + (3,), np.float32), m]))
                tex = flow_texture(c[..., :3], m, rng)
                item["flow"] = asset_name(island, sprite, e["id"], "flow", light)
                pixels += write_png_set(item["flow"], tex)
                item["flowHeight"] = round(tex.shape[0] * ry, 3)               # the tile's period, master px
                item.update(speed=mk["speed"], strength=mk["strength"])
                mist = mist_spec(c[..., :3], a, (x0, y0, x1, y1), m)
                item["mist"] = {"centre": [round(layer["pos"][0] + mist["centre"][0] * rx, 3), round(layer["pos"][1] + mist["centre"][1] * ry, 3)],
                                "radius": [round(mist["radius"][0] * rx, 3), round(mist["radius"][1] * ry, 3)],
                                "color": mist["color"], **mk["mist"]}
            elif e["kind"] == "sway":
                item["mask"] = asset_name(island, sprite, e["id"], "mask", light)
                pixels += write_png_set(item["mask"], np.dstack([np.ones(m.shape + (3,), np.float32), m]))
                item["crop"] = asset_name(island, sprite, e["id"], "crop", light)
                pixels += write_png_set(item["crop"], c)
                item.update(DETAIL_MOTION["sway"])
            else:
                item["asset"] = asset_name(island, sprite, e["id"], "glow", light)
                pixels += write_png_set(item["asset"], np.dstack([c[..., :3], m]))
                g = DETAIL_MOTION["glow"]
                item.update(amp=g["amp"][light], periods=g["periods"])
            details.append(item)
        layer["details"] = details
    return pixels


def attach(island: str, lights: list[str] | None = None, force: bool = False) -> None:
    """Add the detail to the shipped sky-set JSON (and its texture bytes) from the shipped sprites."""
    path = JSON_DIR / f"skyset-{island}.json"
    data = json.loads(path.read_text())
    hand = json.loads((PLATES / island / "sky" / "detail.json").read_text())
    for light in lights or ["day", "golden", "night"]:
        spec = data["lights"][light]
        spec["detailPixels"] = export_light(island, light, spec, hand, force)
        spec["textureBytes"] = ex.state_bytes(island, light, spec["pixels"] + spec["detailPixels"])
        print(f"{light}: +{spec['detailPixels']:,} detail px, state {spec['textureBytes']:,} bytes "
              f"({'ok' if spec['textureBytes'] <= ex.BUDGET else 'OVER BUDGET'})")
    path.write_text(json.dumps(data, separators=(",", ":")) + "\n")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("--light", default="all")
    ap.add_argument("--masks", action="store_true", help="rebuild the mask PNGs (otherwise an existing one is kept)")
    a = ap.parse_args(argv)
    attach(a.island, None if a.light == "all" else [a.light], a.masks)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
