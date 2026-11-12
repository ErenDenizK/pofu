#!/usr/bin/env python3
"""Ship a sky set (`split.py`) to the app: HEIC imagesets and `Plates/skyset-<island>.json`.

    python3 -I tools/plate/skyset_export.py home [--light day|golden|night|all]

The split writes full-size layers under `design/art/plates/<island>/sky/<light>/`. The app draws them
at the Home framing (1206 px wide screen, the island 1.15 screens wide, so about 0.68 screen px per
master px), so the soft cloud layers are stored smaller than the master (`SCALES`) to fit the texture
budget (9 MB, ASTC one byte a pixel, per state, `PlateMath.budgetOK`); the island, which carries the
detail, keeps its full size. The layer pixels are never graded, only resampled:

  sky     a smooth field fitted to the master's sky pixels (stars and the moon left out), at 1/8 size
          plus 32 source pixels of replicated edge on every side, so the picture runs past the plate;
          the night's stars are put back as the painted ones (the split's own star pixels)
  moon    night only: the moon and its halo as a sprite with a radial soft alpha (the disc from the
          master, the halo as the radial median profile, so no cloud or star rides along)
  sea     continued 420 master px past the plate by block quilting from the visible sea (`inpaint.quilt`),
          eased in over 80 rows, never mirrored
  stars   night only: each star the sky layer already has, as its own light above the local sky,
          in three groups that the app brightens at different beats; nothing is drawn by code. The star
          residue is cleared from the far and mid layers, so only the still sky star remains
  others  resampled with premultiplied alpha; the island's HEIC is copied byte for byte

`skyset-<island>.json` carries, per light, the draw order, each layer's place and size in master
pixels, its motion (the one source of the motion constants: `PofuWorld/Sky/SkySet.swift` reads it and
`skyset_render.py` renders the same frames offline), and the state's texture bytes.
"""
from __future__ import annotations

import argparse
import os
import json
import re
import shutil
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import inpaint  # noqa: E402
import split  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"
RESOURCES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
JSON_DIR = RESOURCES / "Plates"
BUDGET = 9_000_000

#: Stored size against the master, per layer (the island is 1).
SCALES = {"far": 0.5, "mid": 0.6, "sea": 0.6, "isle_falls": 0.75, "isle_house": 0.75, "isle_dome": 0.75,
          "isle_crystal": 0.75, "whale": 0.75}
SKY_PAD = 64                 # source pixels of edge past the gradient (8 master px each)
SKY_FIT_ROWS = 200           # the gradient rows (source px) that can show; below them the field holds its last row
SKY_FIT_DEGREE = 4
SEA_PAD = 420                # master px of sea continued below the plate
SEA_BAND = 0                 # rows of the known sea the continuation eases in over (0: the plate stays as painted)
SPRITE_REACH = 70            # master px past a sprite's alpha where its cloud puffs are taken back from the painting
STAR_CLEAR = 28              # master px round a star where the far and mid layers' residue is cleared
MOON_R_DISC = 76             # the disc and its near halo come from the master (master px)
MOON_R_HALO = 170            # the halo's alpha is 0 here
STAR_ROWS = 100              # gradient rows (source px) that can hold stars
STAR_MAX_AREA = 14           # a blob this small (source px) is a star, not a cloud's edge
STAR_GROUPS = 3

#: The motion, in screen px at the 1206 px reference screen (scaled by width / 1206 in the app).
#: `drift`: px/s along +x; tiles wrap, the whale wraps once fully off screen. `bob`: a vertical
#: sine of `amp` px and `period` s that starts at zero (so t = 0 is the painting), `sign` flips its
#: direction, which with the periods is the phase offset between layers. `twinkle`: a star group's
#: own light, 0 at t = 0, up to `peak` of itself, sin^2 over `period` s.
MOTION = {
    "far": {"drift": 4, "bob": {"amp": 3, "period": 8, "sign": 1}},
    "mid": {"drift": 9, "bob": {"amp": 3, "period": 8, "sign": -1}},
    "sea": {"drift": 14, "bob": {"amp": 3, "period": 8, "sign": 1}},
    "isle_falls": {"bob": {"amp": 2, "period": 6.5, "sign": 1}},
    "isle_house": {"bob": {"amp": 2, "period": 7.5, "sign": -1}},
    "isle_dome": {"bob": {"amp": 2, "period": 6, "sign": 1}},
    "isle_crystal": {"bob": {"amp": 2, "period": 8, "sign": -1}},
    "whale": {"drift": 5, "bob": {"amp": 2, "period": 9, "sign": 1}},
}
TWINKLE = [{"peak": 0.9, "period": 3.1}, {"peak": 0.9, "period": 4.3}, {"peak": 0.9, "period": 5.7}]
REFERENCE_WIDTH = 1206


def asset_name(island: str, layer: str, light: str, n: int = 0) -> str:
    """`world-<island>-sky-<layer>-<light>-<n>`: n is 0 for a shared layer; a staged island's own island layer
    carries its stage (Çağlayan: five day stages over one sky)."""
    return f"world-{island}-sky-{layer.replace('_', '-')}-{light}-{n}"


def _premult_resize(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """Resize straight RGBA (float 0..1) through premultiplied colour, so no dark fringe."""
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    out = cv2.resize(pre, size, interpolation=cv2.INTER_AREA)
    a = out[..., 3:4]
    out[..., :3] = np.where(a > 1e-4, out[..., :3] / np.maximum(a, 1e-4), 0)
    return out.clip(0, 1)


def _write(arr: np.ndarray, folder: Path, name: str, *, copy: Path | None = None) -> int:
    """One imageset with a HEIC; returns its pixel count (the texture budget's unit)."""
    d = ASSETS / f"{name}.imageset"
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    dst = d / f"{name}.heic"
    if copy is not None:
        shutil.copyfile(copy, dst)
    else:
        heic.save(Image.fromarray(np.uint8(arr * 255 + 0.5), "RGBA"), dst)
    (d / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": dst.name, "idiom": "universal"}], "info": {"author": "xcode", "version": 1}},
        indent=2) + "\n")
    with heic.open_image(dst) as im:
        return im.width * im.height


def fit_field(sky: np.ndarray, exclude: np.ndarray, rows: int = SKY_FIT_ROWS, degree: int = SKY_FIT_DEGREE) -> np.ndarray:
    """A smooth sky: a low-degree polynomial in (x, y) fitted to the gradient's pixels outside `exclude`
    (stars, the moon) in its first `rows` rows; below them it holds the last fitted row (hidden anyway)."""
    h, w, _ = sky.shape
    yy, xx = np.mgrid[0:h, 0:w]
    x = xx / (w - 1) * 2 - 1
    y = np.minimum(yy, rows - 1) / (rows - 1) * 2 - 1
    terms = [(i, j) for i in range(degree + 1) for j in range(degree + 1 - i)]
    basis = np.stack([x ** i * y ** j for i, j in terms], -1)
    use = ~exclude
    use[rows:] = False
    out = np.zeros_like(sky)
    for c in range(3):
        coef, *_ = np.linalg.lstsq(basis[use], sky[..., c][use], rcond=None)
        out[..., c] = basis @ coef
    return np.clip(out, 0, 1)


def moon_sprite(plate: np.ndarray, field_up: np.ndarray) -> tuple[np.ndarray, tuple[int, int]]:
    """The moon and its halo as RGBA with a radial soft alpha: the disc and its near halo are the
    master's pixels; beyond them the colour is the field plus the halo's radial median profile (a
    median over angle, so the cloud below and the stars drop out). Returns the sprite and its master
    top-left."""
    sub = plate[:520, :760].max(-1)
    lab, n = ndimage.label(sub > 0.97)
    sizes = ndimage.sum(np.ones_like(sub), lab, range(1, n + 1))
    m = lab == (1 + int(np.argmax(sizes)))
    cy, cx = ndimage.center_of_mass(m)
    r_out = MOON_R_HALO
    y0, x0 = int(round(cy)) - r_out, int(round(cx)) - r_out
    ys, xs = np.mgrid[y0:y0 + 2 * r_out, x0:x0 + 2 * r_out]
    r = np.hypot(ys - cy, xs - cx)
    valid = ys >= 0                                   # the halo runs on above the plate's top edge
    yc = np.clip(ys, 0, plate.shape[0] - 1)
    crop = plate[yc, np.clip(xs, 0, plate.shape[1] - 1)]
    base = field_up[yc, np.clip(xs, 0, plate.shape[1] - 1)]
    resid = crop - base
    bins = np.clip(r.astype(int), 0, r_out)
    prof = np.zeros((r_out + 1, 3), np.float32)
    for b in range(r_out + 1):
        sel = (bins == b) & valid
        if sel.any():
            prof[b] = np.median(resid[sel], axis=0)
    prof = cv2.GaussianBlur(prof.reshape(-1, 1, 3), (0, 0), 1.5).reshape(-1, 3)
    halo = np.clip(base + prof[bins], 0, 1)
    k = np.clip((r - (MOON_R_DISC - 3)) / 6, 0, 1)[..., None]           # disc -> profile, over 6 px
    rgb = crop * (1 - k) + halo * k
    alpha = 1 - split.smoothstep(MOON_R_HALO * 0.55, MOON_R_HALO, r)
    return np.dstack([rgb, alpha]).astype(np.float32), (x0, y0)


def star_centres(arr: np.ndarray, hand: dict, light: str) -> list[tuple[float, float]]:
    """Centres (master px, x then y) of the stars the gradient already has."""
    out = []
    for blob in _star_blobs(arr, hand, light):
        yy, xx = np.nonzero(blob)
        out.append((float(xx.mean() * 8 + 4), float(yy.mean() * 8 + 4)))
    return out


def _star_blobs(sky: np.ndarray, hand: dict, light: str) -> list[np.ndarray]:
    bg = cv2.medianBlur(np.uint8(sky * 255 + 0.5), 9).astype(np.float32) / 255
    peak = np.clip(sky - bg, 0, 1).max(-1)
    k = 8
    for x0, y0, x1, y1 in hand["lights"][light].get("fixedSky", []):
        peak[y0 // k: y1 // k + 2, x0 // k: x1 // k + 2] = 0
    peak[STAR_ROWS:] = 0
    lab, n = ndimage.label(peak > 0.03)
    return [lab == i for i in range(1, n + 1) if (lab == i).sum() <= STAR_MAX_AREA]


def continue_sea(arr: np.ndarray, seed: int = 0, light: str = "", pad: int | None = None, quilt: dict | None = None) -> np.ndarray:
    """The sea tile (straight RGBA, opaque at its bottom) continued `SEA_PAD` rows downward: real cloud
    blocks of the visible sea quilted in, the last `SEA_BAND` known rows eased into the fill, and the
    new rows closed round the tile's wrap (as `split.close_wrap` closes the rest). `quilt` (Çağlayan, whose
    screen shows 570 rows past the master) sets the block, overlap, topk, band and window: bigger blocks keep
    the puffs crisp where the default 72 px blocks blur them."""
    pad = SEA_PAD if pad is None else pad
    q = {"block": 72, "overlap": 24, "topk": 10, "band": SEA_BAND, "window": 350, **(quilt or {})}
    cache = os.environ.get("SKYSET_CACHE")             # the quilt takes minutes: a work folder can keep it
    cached = Path(cache) / f"sea-{light}.npy" if cache and light else None
    if cached is not None and cached.exists():
        return np.load(cached)
    h, w, _ = arr.shape
    pre = arr.copy()
    pre[..., :3] *= pre[..., 3:4]
    ext = np.concatenate([pre, np.repeat(pre[-1:], pad, 0)], 0)
    hole = np.zeros(ext.shape[:2], bool)
    hole[h - q["band"]:] = True
    # only the solid cloud below the thin top is quilted from: a block drawn from the sea's half-transparent top would
    # bring holes down with it
    start = max(h - q.get("source", h), 0)
    fill = np.zeros_like(ext)
    fill[start:] = inpaint.quilt(ext[start:], hole[start:], periodic_x=True, y_window=q["window"], block=q["block"],
                                 overlap=q["overlap"], topk=q["topk"], seed=seed)
    fill[:start] = ext[:start]
    fa = fill[..., 3].clip(0, 1)
    frgb = np.where(fa[..., None] > 1e-3, fill[..., :3] / np.maximum(fa, 1e-3)[..., None], 0).clip(0, 1)
    frgb, fa = split.close_wrap(frgb, fa, 160, seed)
    fill = np.dstack([frgb * fa[..., None], fa])
    wgt = np.zeros(ext.shape[0], np.float32)
    if q["band"]:
        wgt[h - q["band"]:h] = split.smoothstep(0, q["band"], np.arange(q["band"], dtype=np.float32))
    wgt[h:] = 1
    out = ext * (1 - wgt[:, None, None]) + fill * wgt[:, None, None]
    if q.get("step"):
        # the first new row still meets the last (blended) one with a colour step all along it, a straight line across the
        # sea: carry the step's difference, smoothed along x, off over `step` rows; the rows above stay as they are
        d = cv2.GaussianBlur((out[h - 1] - out[h])[None], (0, 0), sigmaX=14, sigmaY=0.01)[0]
        ramp = 1 - split.smoothstep(0, q["step"], np.arange(q["step"], dtype=np.float32))
        out[h: h + q["step"]] += d[None] * ramp[:, None, None]
    a = out[..., 3:4].clip(0, 1)
    rgb = np.where(a > 1e-3, out[..., :3] / np.maximum(a, 1e-3), 0).clip(0, 1)
    res = np.concatenate([rgb, a], -1)
    if cached is not None:
        cached.parent.mkdir(parents=True, exist_ok=True)
        np.save(cached, res)
    return res


def extend_sky_up(sky: np.ndarray, rows: int, fit_rows: int = 40, tau_rows: float = 6.0, flat_rows: float = 8.0) -> np.ndarray:
    """The gradient (H, W, 3 at 1/8 size) continued `rows` rows upward by a smooth fitted field, so the picture
    runs on past the master's top edge with no band and no seam: the first row is the gradient's own (smoothed
    along x), and each row above it moves on by the vertical slope fitted to the top `fit_rows` rows, the slope
    easing off exponentially (`tau_rows`) so the zenith deepens and settles instead of running away, and the
    colour's variation along x (a tint at one corner) dying away over `flat_rows`. The join is continuous in
    value and in slope; only the drifting cloud layers cross it."""
    h, w, _ = sky.shape
    base = cv2.GaussianBlur(sky[:1], (0, 0), sigmaX=6, sigmaY=0.01)[0]                 # the first row, smoothed along x only
    prof = sky[:fit_rows].mean(1)                                         # (fit_rows, 3)
    t = np.arange(fit_rows, dtype=np.float64)
    slope = np.array([np.polyfit(t, prof[:, c], 1)[0] for c in range(3)])  # per row, downward
    up = np.arange(1, rows + 1, dtype=np.float64)[:, None]
    shift = -slope[None, :] * tau_rows * (1 - np.exp(-up / tau_rows))     # (rows, 3): moving up darkens/deepens
    mean = base.mean(0)
    keep = np.exp(-up / flat_rows)[:, :, None]                            # how much of the row's own variation is left
    rowbase = mean[None, None, :] + (base[None, :, :] - mean[None, None, :]) * keep
    ext = np.clip(rowbase + shift[:, None, :], 0, 1)[::-1]                # farthest first
    return np.concatenate([ext.astype(np.float32), sky], 0)


def rebuild_sprites(sprites: dict[str, tuple[np.ndarray, tuple[int, int]]], plate: np.ndarray, bg: np.ndarray, k: float, floor: float = 0.0) -> dict:
    """Give each distant isle (and the whale) back the cloud puffs the split left in the painting: the
    split took a thin ring round each sprite (the pink underside of an isle, the wisps beside it were
    left behind or came out as stray fragments). Alpha is the painting's own difference from what is
    behind it (`bg`: sky, stars, far clouds) within `SPRITE_REACH` px of the sprite's alpha and clear of
    the other sprites; the colour is unmixed against `bg`, so at rest sprite over background is the
    painting. Returns {id: (rgba, (x, y))} cropped to the new alpha."""
    h, w, _ = plate.shape
    olds = {}
    for sid, (arr, (x, y)) in sprites.items():
        a = np.zeros((h, w), np.float32)
        ah, aw = arr.shape[:2]
        a[y: y + ah, x: x + aw] = arr[..., 3]
        olds[sid] = a
    ca = cv2.GaussianBlur(((np.linalg.norm(plate - bg, axis=-1) - 0.012) / k).clip(0, 1), (0, 0), 1.0)
    ca = np.where(ca < 0.04, 0, (ca - 0.04) / 0.96)
    out = {}
    size = 2 * SPRITE_REACH + 1
    for sid, a in olds.items():
        others = np.maximum.reduce([o for i, o in olds.items() if i != sid] + [np.zeros_like(a)])
        near = cv2.dilate((a > 0.3).astype(np.uint8), np.ones((size, size), np.uint8)).astype(np.float32)
        zone = cv2.GaussianBlur(near, (0, 0), 18) * (1 - np.clip(others * 4, 0, 1))
        na = np.maximum(a, ca * zone).clip(0, 1)
        na[na < max(0.01, floor)] = 0
        if floor:
            na = split.clean_alpha(na, floor)
        ys, xs = np.nonzero(na > 0.003)
        y0, y1, x0, x1 = max(ys.min() - 2, 0), min(ys.max() + 3, h), max(xs.min() - 2, 0), min(xs.max() + 3, w)
        rgb = split.unmix(plate, bg, na)
        rgb = split.bleed(rgb, na)
        out[sid] = (np.dstack([rgb, na])[y0:y1, x0:x1].astype(np.float32), (int(x0), int(y0)))
    return out


def over_rgb(dst: np.ndarray, rgba: np.ndarray, pos: tuple[int, int]) -> np.ndarray:
    """`rgba` (straight) composited over `dst` at `pos`, in place; returns dst."""
    x, y = pos
    sy0, sx0 = max(-y, 0), max(-x, 0)                  # a sprite may run past the top edge (the moon's halo)
    y, x = max(y, 0), max(x, 0)
    part = rgba[sy0:, sx0:]
    hh, ww = min(part.shape[0], dst.shape[0] - y), min(part.shape[1], dst.shape[1] - x)
    a = part[:hh, :ww, 3:4]
    dst[y: y + hh, x: x + ww] = part[:hh, :ww, :3] * a + dst[y: y + hh, x: x + ww] * (1 - a)
    return dst


def find_stars(sky: np.ndarray, hand: dict, light: str) -> np.ndarray:
    """Per star blob of the (straight RGB 0..1) gradient, its own light above the local sky, in
    `STAR_GROUPS` arrays (rows 0..STAR_ROWS). Blobs larger than a star, the fixed moon box and
    everything below the star rows are left out."""
    bg = cv2.medianBlur(np.uint8(sky * 255 + 0.5), 9).astype(np.float32) / 255
    diff = np.clip(sky - bg, 0, 1)
    peak = diff.max(-1)
    k = 8                                                   # source px per master px
    for x0, y0, x1, y1 in hand["lights"][light].get("fixedSky", []):
        diff[y0 // k: y1 // k + 2, x0 // k: x1 // k + 2] = 0
        peak[y0 // k: y1 // k + 2, x0 // k: x1 // k + 2] = 0
    peak[STAR_ROWS:] = 0
    lab, n = ndimage.label(peak > 0.03)
    groups = np.zeros((STAR_GROUPS,) + sky.shape, np.float32)
    count = 0
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() > STAR_MAX_AREA:
            continue
        ring = ndimage.binary_dilation(m, iterations=1)
        groups[count % STAR_GROUPS][ring] = diff[ring]
        count += 1
    return groups[:, :STAR_ROWS]


def export_light(island: str, light: str, hand: dict) -> dict:
    src = PLATES / island / "sky" / light
    man = json.loads((src / "manifest.json").read_text())
    w, h = man["size"]
    k = 8                                                    # master px per gradient px
    cfg = hand.get("export", {})                             # an island that runs on past its master (Çağlayan)
    tag = light if island == "home" else f"{island}-{light}"   # the quilt caches' key
    base_stage = hand.get("baseStage")
    layers, pixels = [], 0
    plate = np.asarray(heic.open_image(ROOT / man["source"]["plate"]).convert("RGB"), np.float32) / 255

    def add(entry: dict, px: int) -> None:
        nonlocal pixels
        pixels += px
        layers.append(entry)

    sky0 = np.asarray(heic.open_image(src / "sky.heic").convert("RGB"), np.float32) / 255
    stars_on = light == "night"
    blobs = _star_blobs(sky0, hand, light) if stars_on else []
    centres = star_centres(sky0, hand, light) if stars_on else []
    # the field: the gradient without its stars and the moon
    exclude = np.zeros(sky0.shape[:2], bool)
    for blob in blobs:
        exclude |= ndimage.binary_dilation(blob, iterations=2)
    moon = None
    if stars_on:
        sub = plate[:520, :760].max(-1)
        lab, n = ndimage.label(sub > 0.97)
        sizes = ndimage.sum(np.ones_like(sub), lab, range(1, n + 1))
        cy, cx = ndimage.center_of_mass(lab == (1 + int(np.argmax(sizes))))
        yy, xx = np.mgrid[0:sky0.shape[0], 0:sky0.shape[1]]
        exclude |= np.hypot(yy * k + k / 2 - cy, xx * k + k / 2 - cx) < MOON_R_HALO + 24
    field = sky0 if cfg.get("splitSky") else fit_field(sky0, exclude)   # Çağlayan: the one smooth field the clouds were unmixed against
    sky_arr = field.copy()
    if stars_on:                                              # the painted stars, put back
        for blob in blobs:
            ring = ndimage.binary_dilation(blob, iterations=1)
            sky_arr[ring] = np.maximum(field[ring], sky0[ring])
        moon, moon_pos = moon_sprite(plate, cv2.resize(field, (w, h), interpolation=cv2.INTER_LINEAR))

    # the far layer without the stars' residue, then each sprite rebuilt against sky + stars + far
    raw = {lay["id"]: np.asarray(heic.open_image(src / lay["file"]).convert("RGBA"), np.float32) / 255 for lay in man["layers"]}
    far_arr = raw.get("far")
    if far_arr is not None and stars_on:
        # the night's far layer keeps no faint haze (streaks at the moon box's edge): below 8 % alpha it is sky
        far_arr[..., 3] = np.where(far_arr[..., 3] < 0.08, 0, far_arr[..., 3])
    if far_arr is not None and centres:
        fy, fx = far_arr.shape[:2]
        fpos = next(l["pos"] for l in man["layers"] if l["id"] == "far")
        yy, xx = np.mgrid[0:fy, 0:fx]
        for cx_, cy_ in centres:
            far_arr[..., 3][np.hypot(xx + fpos[0] - cx_, yy + fpos[1] - cy_) < STAR_CLEAR] = 0
    bg = cv2.resize(sky_arr, (w, h), interpolation=cv2.INTER_LINEAR)
    if stars_on:
        bg = over_rgb(bg, moon, moon_pos)
    if far_arr is not None:
        bg = over_rgb(bg, far_arr, tuple(next(l["pos"] for l in man["layers"] if l["id"] == "far")))
    sprite_in = {l["id"]: (raw[l["id"]], tuple(l["pos"])) for l in man["layers"] if l["kind"] == "sprite"}
    rebuilt = rebuild_sprites(sprite_in, plate, bg, man["info"]["K"], hand.get("alphaFloor", 0.0))

    for lay in man["layers"]:
        lid = lay["id"]
        name = asset_name(island, lid, light)
        arr = raw[lid]
        x, y = lay["pos"]
        dw, dh = lay["size"]
        entry = {"id": lid, "role": {"gradient": "sky", "tile": "tile", "sprite": "sprite", "island": "island"}[lay["kind"]],
                 "asset": name}
        if lay["kind"] == "gradient":
            if cfg:
                top, bottom, side = cfg["skyPadTop"] // k, cfg["skyPadBottom"] // k, cfg["skyPadSide"] // k
                padded = np.pad(extend_sky_up(sky_arr, top), ((0, bottom), (side, side), (0, 0)), mode="edge")
                origin = [-side * k, -top * k]
            else:
                padded = np.pad(sky_arr, ((SKY_PAD, SKY_PAD), (SKY_PAD, SKY_PAD), (0, 0)), mode="edge")
                origin = [-SKY_PAD * k, -SKY_PAD * k]
            padded = np.concatenate([padded, np.ones(padded.shape[:2] + (1,), np.float32)], -1)
            entry.update(pos=origin, size=[padded.shape[1] * k, padded.shape[0] * k])
            add(entry, _write(padded, src, name))
            if stars_on:
                mname = asset_name(island, "moon", light)
                mh, mw = moon.shape[:2]
                add({"id": "moon", "role": "sprite", "asset": mname, "pos": [moon_pos[0], moon_pos[1]], "size": [mw, mh]},
                    _write(moon, src, mname))
                stars = find_stars(sky0, hand, light)
                for g in range(STAR_GROUPS):
                    sname = asset_name(island, f"stars{g}", light)
                    rgba = np.concatenate([stars[g], np.ones(stars[g].shape[:2] + (1,), np.float32)], -1)
                    s_entry = {"id": f"stars{g}", "role": "stars", "asset": sname, "pos": [0, 0],
                               "size": [sky0.shape[1] * k, STAR_ROWS * k], "twinkle": TWINKLE[g]}
                    add(s_entry, _write(rgba, src, sname))
            continue
        like = hand["sprites"].get(lid, {}).get("motionLike") if lay["kind"] == "sprite" else None
        motion = MOTION.get(lid) or MOTION.get(like, {})
        if lay["kind"] == "island":
            if base_stage:
                name = entry["asset"] = asset_name(island, "island", light, int(base_stage))
            entry.update(pos=[x, y], size=[dw, dh])
            add(entry, _write(arr, src, name, copy=src / lay["file"]))
            continue
        if lid == "far":
            arr = far_arr
        if lid == "mid" and centres:                          # the stars' residue belongs to the still sky
            yy, xx = np.mgrid[0:arr.shape[0], 0:arr.shape[1]]
            for cx_, cy_ in centres:
                arr[..., 3][np.hypot(xx + x - cx_, yy + y - cy_) < STAR_CLEAR] = 0
        if lay["kind"] == "sprite":
            arr, (x, y) = rebuilt[lid]
            dh, dw = arr.shape[:2]
        scale = SCALES.get(lid, 0.75)
        if lid == "sea":
            sea_pad = cfg.get("seaPad", SEA_PAD)
            arr = continue_sea(arr, light=tag, pad=sea_pad, quilt=cfg.get("seaQuilt"))
            dh += sea_pad
        small = _premult_resize(arr, (round(arr.shape[1] * scale), round(arr.shape[0] * scale)))
        if hand.get("alphaFloor"):                     # the resample and the codec leave faint crumbs again: clean the stored layer
            small[..., 3] = split.clean_alpha(small[..., 3], hand["alphaFloor"] + 0.015, 250, 0.32)
            small[..., :3] = np.where(small[..., 3:4] > 0, small[..., :3], 0)
        entry.update(pos=[x, y], size=[dw, dh], **motion)
        if lay["kind"] == "tile":
            entry["tileWidth"] = lay["tileWidth"]
        if lid == "whale":
            entry["role"] = "whale"
        add(entry, _write(small, src, name))
    out = {"layers": layers, "pixels": pixels, "master": [w, h], "islandBox": man["islandBox"],
           "plate": man["source"]["plate"]}
    if man.get("stageIslands"):
        # the other stages' island layers, the same box over the same sky; each its own imageset
        stages = {}
        for stage, fname in man["stageIslands"].items():
            name = asset_name(island, "island", light, int(stage))
            if stage != base_stage:
                _write(None, src, name, copy=src / fname)
            stages[stage] = name
        out["stageIslands"] = stages
    return out


def state_bytes(island: str, light: str, sky_pixels: int, stage: int = 0) -> int:
    """The sky-set state's textures: the set, the island cut for the Map and the occluders (the
    plate and its backdrop are not loaded while a sky set draws)."""
    total = sky_pixels
    for folder in ASSETS.glob(f"world-{island}-*-{light}-{stage}.imageset"):
        if re.match(rf"world-{island}-(plate|backdrop|sky-)", folder.name):
            continue
        for f in folder.iterdir():
            if f.suffix == heic.SUFFIX:
                with heic.open_image(f) as im:
                    total += im.width * im.height
    return total


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("--light", default="all")
    a = ap.parse_args(argv)
    hand = json.loads((PLATES / a.island / "sky" / "sky.json").read_text())
    lights = ["day", "golden", "night"] if a.light == "all" else [a.light]
    out_path = JSON_DIR / f"skyset-{a.island}.json"
    data = json.loads(out_path.read_text()) if out_path.exists() else {"lights": {}}
    if hand.get("matteFrame"):                        # the plates are not the master (Çağlayan): where they sit on it
        data["plateFrame"] = {"scale": hand["matteFrame"]["scale"], "offset": hand["matteFrame"]["offset"]}
    data.update(island=a.island, version=1, master=hand["size"], referenceWidth=REFERENCE_WIDTH,
                note="Written by tools/plate/skyset_export.py. Positions and sizes are master pixels "
                     "(2048 x 3072); motion is screen px at the 1206 px reference screen.")
    for light in lights:
        res = export_light(a.island, light, hand)
        res["textureBytes"] = state_bytes(a.island, light, res["pixels"])
        data["lights"][light] = res
        print(f"{light}: {res['pixels']:,} sky px, state {res['textureBytes']:,} bytes "
              f"({'ok' if res['textureBytes'] <= BUDGET else 'OVER BUDGET'})")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    if (PLATES / a.island / "sky" / "detail.json").exists():
        import skyset_detail                           # the isles' and the whale's painted-detail motion (after the sprites)
        skyset_detail.attach(a.island, lights)
    data = json.loads(out_path.read_text())
    derive_stages(data, lights)
    out_path.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    return 0 if all(spec["textureBytes"] <= BUDGET for spec in data["lights"].values()) else 1


def derive_stages(data: dict, lights: list[str]) -> None:
    """A staged island (Çağlayan's five day stages over one sky): one state per stage, `<light>-<stage>`, the
    same layers with the island layer of that stage's plate and the state's own texture bytes. The plain
    `<light>` entry stays as the base stage's (the offline tools read it); the app asks for `<light>-<stage>` first."""
    for light in lights:
        spec = data["lights"][light]
        for stage, asset in (spec.pop("stageIslands", None) or {}).items():
            state = json.loads(json.dumps(spec))
            for layer in state["layers"]:
                if layer["role"] == "island":
                    layer["asset"] = asset
            state["textureBytes"] = state_bytes(data["island"], light, spec["pixels"] + spec.get("detailPixels", 0), int(stage))
            data["lights"][f"{light}-{stage}"] = state
            print(f"{light}-{stage}: state {state['textureBytes']:,} bytes ({'ok' if state['textureBytes'] <= BUDGET else 'OVER BUDGET'})")

if __name__ == "__main__":
    raise SystemExit(main())
