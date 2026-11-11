#!/usr/bin/env python3
"""Split one painted plate into an island plate over a sky set (plate-first sky, ADR-0022).

    python3 -I tools/plate/split.py home [--light day|golden|night|all] [--plate PATH] [--out DIR]

From ONE painted master (never generated separately) it cuts, per light:

  sky      a smooth gradient, stored small (stretch it over the plate)
  far      far clouds (alpha), a horizontal drift tile
  isle_*   the distant islands and the whale, sprites with positions
  mid      mid clouds (alpha), a drift tile
  sea      the cloud sea (alpha at its thin top, opaque below), a drift tile whose area behind the
           island is painted by exemplar inpainting from the visible sea (`inpaint.py`)
  island   the island, matted (guided-filter edge, colours unmixed from what is behind it, so no halo
           on any background), with the cloud bank that touches its base: the seam falls in soft cloud

Layers composite back over each other (bottom to top: sky, far, sprites, mid, sea, island) to the
master, pixel for pixel (`screen_check.py` measures it on the saved HEIC). Motion is code-only:
`manifest.json` lists the order, positions, tile widths and parallax suggestions. Output:
`design/art/plates/<island>/sky/<light>/` (HEIC q70 with alpha, `heic.py`).

Hand data: `design/art/plates/<island>/sky/sky.json` (sprite boxes and mattes, sea rows, lights) and
the island matte `design/art/plates/<island>/matte-day-0.png` (ingest's). Deterministic.
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

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import inpaint  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"
ORDER_NOTE = "bottom to top"
SKY_SCALE = 8          # the gradient is stored at 1/8 size
LUM = np.array([0.2126, 0.7152, 0.0722], np.float32)


# ---------------------------------------------------------------- small image helpers

def lum(c: np.ndarray) -> np.ndarray:
    return c @ LUM


def smoothstep(a: float, b: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - a) / max(b - a, 1e-6), 0, 1)
    return t * t * (3 - 2 * t)


def box(a: np.ndarray, r: int) -> np.ndarray:
    return cv2.boxFilter(a, -1, (2 * r + 1, 2 * r + 1), normalize=True, borderType=cv2.BORDER_REPLICATE)


def guided_filter(guide: np.ndarray, src: np.ndarray, r: int, eps: float) -> np.ndarray:
    """Colour guided filter (He et al.): `src` (H, W) follows the edges of `guide` (H, W, 3)."""
    g = guide.astype(np.float32)
    mean_g = np.stack([box(g[..., i], r) for i in range(3)], -1)
    mean_p = box(src, r)
    cov_gp = np.stack([box(g[..., i] * src, r) - mean_g[..., i] * mean_p for i in range(3)], -1)
    var = np.empty(g.shape[:2] + (3, 3), np.float32)
    for i in range(3):
        for j in range(i, 3):
            var[..., i, j] = var[..., j, i] = box(g[..., i] * g[..., j], r) - mean_g[..., i] * mean_g[..., j]
        var[..., i, i] += eps
    a = np.linalg.solve(var, cov_gp[..., None])[..., 0].astype(np.float32)
    b = mean_p - (a * mean_g).sum(-1)
    mean_a = np.stack([box(a[..., i], r) for i in range(3)], -1)
    return (mean_a * g).sum(-1) + box(b, r)


def bleed(rgb: np.ndarray, a: np.ndarray, thresh: float = 0.02) -> np.ndarray:
    """Give transparent pixels the colour of the nearest opaque one, so a lossy codec and any later
    filtering never smear junk colour into an edge."""
    solid = a > thresh
    if solid.all() or not solid.any():
        return rgb
    _, (iy, ix) = ndimage.distance_transform_edt(~solid, return_indices=True)
    return rgb[iy, ix]


def unmix(p: np.ndarray, bg: np.ndarray, a: np.ndarray) -> np.ndarray:
    """The colour F with a F + (1 - a) bg = p (clipped); p where a is ~0."""
    aa = a[..., None]
    f = np.where(aa > 0.01, bg + (p - bg) / np.maximum(aa, 0.01), p)
    return f.clip(0, 1)


def over(dst: np.ndarray, rgb: np.ndarray, a: np.ndarray) -> np.ndarray:
    return rgb * a[..., None] + dst * (1 - a[..., None])


def island_hued(rgb: np.ndarray) -> np.ndarray:
    """Pixels in an island's greens (lawn, leaves; sunset clouds are yellow-green below hue 105 and
    warm island colours cannot be told from them): what a cloud layer must not hold. `rgb` 0..1."""
    lab = heic._lab(np.asarray(rgb, np.float64) * 255)
    c = np.hypot(lab[..., 1], lab[..., 2])
    hue = np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360
    return (hue > 105) & (hue < 160) & (c > 28)


# ---------------------------------------------------------------- inputs

def hand_path(island: str) -> Path:
    return PLATES / island / "sky" / "sky.json"


def load_hand(island: str) -> dict:
    return json.loads(hand_path(island).read_text())


def load_plate(path: Path, size: tuple[int, int]) -> np.ndarray:
    """The master as RGB floats. Its own alpha is only a 1-2 px border feather (the ingest's):
    ignored, and the two edge rows and columns repeat the third so no feather colour leaks in."""
    im = heic.open_image(path).convert("RGB")
    if im.size != tuple(size):
        raise SystemExit(f"{path}: the plate is {im.size[0]} x {im.size[1]}, not {size[0]} x {size[1]}")
    p = np.asarray(im, np.float32) / 255
    p[:2] = p[2]
    p[:, :2] = p[:, 2:3]
    p[:, -2:] = p[:, -3:-2]
    return p


def island_matte(hand: dict, p: np.ndarray) -> np.ndarray:
    """The silhouette: ingest's committed matte, upscaled and snapped to the painting's edges."""
    h, w = p.shape[:2]
    m = np.asarray(Image.open(PLATES / hand["island"] / "matte-day-0.png").convert("L"), np.float32) / 255
    a0 = cv2.resize(m, (w, h), interpolation=cv2.INTER_CUBIC).clip(0, 1)
    ys, xs = np.nonzero(a0 > 0.01)
    y0, y1, x0, x1 = max(ys.min() - 40, 0), min(ys.max() + 41, h), max(xs.min() - 40, 0), min(xs.max() + 41, w)
    out = np.zeros((h, w), np.float32)
    # the matte is a soft 1.2 px blur of a GrabCut: sharpen it first, the guide then places the edge
    sharp = ((a0[y0:y1, x0:x1] - 0.5) * 2.2 + 0.5).clip(0, 1)
    g = guided_filter(p[y0:y1, x0:x1], sharp, 4, 1e-3).clip(0, 1)
    g[g < 0.03] = 0
    g[g > 0.97] = 1
    out[y0:y1, x0:x1] = g
    return out


def sprite_mattes(hand: dict, shape: tuple[int, int]) -> dict[str, np.ndarray]:
    out = {}
    for name, s in hand["sprites"].items():
        x0, y0, x1, y1 = s["box"]
        m = np.zeros(shape, np.float32)
        crop = np.asarray(Image.open(PLATES / hand["island"] / "sky" / s["matte"]).convert("L"), np.float32) / 255
        if crop.shape != (y1 - y0, x1 - x0):
            raise SystemExit(f"{name}: matte {crop.shape[::-1]} does not fit its box {(x1 - x0, y1 - y0)}")
        m[y0:y1, x0:x1] = crop
        out[name] = m
    return out


# ---------------------------------------------------------------- the sky gradient

def _basis(x, y, w, h):
    x = x / w - 0.5
    y = y / h
    return np.stack([np.ones_like(x), x, x * x, y, y * y, y ** 3, y ** 4, x * y, x * x * y, x * y * y], -1)


def fit_sky(p: np.ndarray, objs: np.ndarray, sea_top: int) -> tuple[np.ndarray, float]:
    """The smooth sky: a polynomial in x, y fitted with iterative rejection of clouds and objects,
    plus the smooth residual of the pixels that still look like sky (a sunset glow is not a
    polynomial). Frozen below the sea top: there the sky is only seen through thin cloud."""
    h, w = p.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    free = (objs < 0.01) & (yy < sea_top)
    sub = np.zeros_like(free)
    sub[::4, ::4] = True
    sel = free & sub
    thr = [0.08, 0.05, 0.035, 0.025, 0.02, 0.02]
    s = None
    for t in thr:
        a = _basis(xx[sel], yy[sel], w, h)
        coef, *_ = np.linalg.lstsq(a, p[sel], rcond=None)
        s = (_basis(xx, yy, w, h).reshape(-1, a.shape[1]) @ coef).reshape(h, w, 3)
        r = np.linalg.norm(p - s, axis=-1)
        sel = free & (r < t) & sub
    resid_p95 = float(np.percentile(r[sel], 95))
    # smooth residual at 1/8 size
    k = SKY_SCALE
    sm_w = cv2.resize((free & (r < 0.02)).astype(np.float32), (w // k, h // k), interpolation=cv2.INTER_AREA)
    sm_r = cv2.resize(np.where((free & (r < 0.02))[..., None], p - s, 0).astype(np.float32), (w // k, h // k),
                      interpolation=cv2.INTER_AREA)
    num = cv2.GaussianBlur(sm_r, (0, 0), 6)
    den = cv2.GaussianBlur(sm_w, (0, 0), 6)
    corr = num / np.maximum(den, 1e-3)[..., None] * np.clip(den / 0.15, 0, 1)[..., None]
    s = s + cv2.resize(corr, (w, h), interpolation=cv2.INTER_CUBIC)
    s[sea_top:] = s[sea_top - 1]
    return s.clip(0, 1).astype(np.float32), resid_p95


def cloud_scale(p: np.ndarray, s: np.ndarray, objs: np.ndarray, sea_top: int) -> float:
    """K: the colour distance of a full-strength cloud from the sky (97th percentile of the
    deviation above the sea), so alpha = distance / K."""
    d = np.linalg.norm(p - s, axis=-1)[:sea_top]
    bright = (lum(p) > lum(s))[:sea_top]
    sel = (objs[:sea_top] < 0.01) & (d > 0.04) & bright
    return float(np.percentile(d[sel], 85)) if sel.sum() > 1000 else 0.16


# ---------------------------------------------------------------- the split

def _group_clouds(ca: np.ndarray, sea_top: int, far_max_y: int) -> np.ndarray:
    """1 far, 2 mid, 3 sea per pixel: a connected cloud goes to the layer of its height."""
    lab, n = ndimage.label(ca > 0.18)
    grp = np.zeros(n + 1, np.uint8)
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        if sl is None:
            continue
        cy = (sl[0].start + sl[0].stop) / 2
        grp[i] = 3 if sl[0].stop > sea_top + 50 else (1 if cy < far_max_y else 2)
    _, (iy, ix) = ndimage.distance_transform_edt(lab == 0, return_indices=True)
    return grp[lab[iy, ix]]


def _soft(mask: np.ndarray) -> np.ndarray:
    return cv2.GaussianBlur(cv2.dilate(mask.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(np.float32), (0, 0), 1.5)


def paint_behind(p: np.ndarray, sky: np.ndarray, hole: np.ndarray, sea_row: int, seed: int = 0, band: int = 40,
                 band_weight: np.ndarray | None = None) -> np.ndarray:
    """The picture without the objects. Above `sea_row` (open sky, hidden by the island nearly
    everywhere) the hole is the fitted sky; at and below it, where the cloud sea shows again as the
    layers drift, real cloud blocks of the visible sea are quilted in (`inpaint.quilt`)."""
    rows = np.arange(p.shape[0])[:, None]
    sea = hole & (rows >= sea_row)
    out = np.where((hole & ~sea)[..., None], sky, p)
    if sea.any():
        # fill a band past the hole too, and ease the fill into the known cloud across it: the edge
        # of the hole is where the sea drifts out from behind the island and must not show a step
        d = ndimage.distance_transform_edt(~sea).astype(np.float32)
        big = d <= band
        fill = inpaint.quilt(out, big, periodic_x=False, y_window=350, seed=seed)
        wgt = np.where(sea, 1.0, np.clip(1 - d / band, 0, 1) * (band_weight if band_weight is not None else 1.0))
        out = out * (1 - wgt[..., None]) + fill * wgt[..., None]
    return out


def close_wrap(rgb: np.ndarray, a: np.ndarray, seam: int, seed: int = 0) -> tuple[np.ndarray, np.ndarray]:
    """Make a layer wrap in x. The last `seam` columns ease into the mirror image of the first
    `seam` (premultiplied colour and alpha), so the right edge ends on column 0's own colour: a cloud
    cut by the plate's edge continues, mirrored, and meets itself. `seam` should sit in the margin the
    Home framing crops (the screen shows 85 % of the plate's width); only those columns change."""
    h, w = a.shape
    if seam <= 0 or not (a[:, :seam] > 0.01).any() and not (a[:, w - seam:] > 0.01).any():
        return rgb, a
    pre = np.dstack([rgb * a[..., None], a]).astype(np.float32)
    x = np.arange(w - seam, w)
    t = (0.5 - 0.5 * np.cos(np.pi * (x - (w - seam) + 1) / seam)).astype(np.float32)[None, :, None]
    pre[:, w - seam:] = pre[:, w - seam:] * (1 - t) + pre[:, :seam][:, ::-1] * t
    na = pre[..., 3].clip(0, 1)
    nrgb = np.where(na[..., None] > 1e-3, pre[..., :3] / np.maximum(na, 1e-3)[..., None], rgb).clip(0, 1)
    cols = np.zeros(w, bool)
    cols[w - seam:] = True
    return np.where(cols[None, :, None], nrgb, rgb), np.where(cols[None, :], na, a)


def split_plate(p: np.ndarray, hand: dict, mattes: dict | None = None, log=print, seed: int = 0,
                light_cfg: dict | None = None) -> dict:
    """Cut the master `p` (H, W, 3 floats) into layers. Returns {"layers": {...}, "bg": ..., "info": ...}
    where each layer is a dict with rgb, a, pos (x, y) in plate pixels and kind."""
    h, w = p.shape[:2]
    sea_top, sea_solid = hand["seaTop"], hand["seaSolid"]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    mattes = mattes or {}
    isl_m = mattes["island"] if "island" in mattes else island_matte(hand, p)
    spr_m = mattes["sprites"] if "sprites" in mattes else sprite_mattes(hand, (h, w))
    zero = np.zeros((h, w), np.float32)
    objs = np.maximum.reduce([isl_m, zero] + list(spr_m.values()))

    # -- the sky, and how much each pixel is cloud
    s, resid = fit_sky(p, objs, sea_top)
    k = hand.get("cloudScale") or cloud_scale(p, s, objs, sea_top)
    log(f"sky fit residual p95 {resid:.4f}, cloud scale K {k:.3f}")
    d = np.linalg.norm(p - s, axis=-1)
    ca = cv2.GaussianBlur(((d - 0.012) / k).clip(0, 1), (0, 0), 1.0)
    ramp = ((yy - (sea_solid - 250)) / 250).clip(0, 1)
    ca = np.maximum(ca, ramp)

    # -- island: silhouette, the beam, thin props the matte missed, the cloud bank at the base
    isl = isl_m.copy()
    x0, y0, x1, y1 = hand["beam"]
    bx = np.zeros((h, w), bool)
    bx[y0:y1, x0:x1] = True
    isl = np.maximum(isl, np.where(bx, ca * (1 - ramp), 0))
    near = cv2.dilate((isl > 0.05).astype(np.uint8), np.ones((81, 81), np.uint8)) > 0
    alien = near & ((lum(p) < lum(s) - 0.06) | (p[..., 0] - p[..., 2] > 0.10) | (p[..., 1] - p[..., 2] > 0.06))
    hued = island_hued(p) & (np.linalg.norm(p - s, axis=-1) > 0.08) & \
        ((ndimage.distance_transform_edt(isl < 0.5) < 150) | (yy > sea_top - 150))
    alien |= hued                                      # island bits the matte rejected: never a cloud's
    alien = cv2.dilate(alien.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
    isl = np.maximum(isl, np.where(alien & (yy < sea_top), ca, 0))
    isl = np.maximum(isl, np.where(hued, 1.0, 0).astype(np.float32))
    sil = isl.copy()                                   # silhouette alone (no bank)
    dist = ndimage.distance_transform_edt(sil < 0.5).astype(np.float32)
    bank_px = hand["bankPx"]
    fade = 1 - smoothstep(bank_px * 0.25, bank_px, dist)
    gate = smoothstep(*hand["bankGateY"], yy)        # rows from which a bank may form (all, for Home)
    bank = (np.clip(ca / 0.5, 0, 1) * fade * gate).astype(np.float32)
    bank = cv2.GaussianBlur(bank, (0, 0), 3)
    isl = np.maximum(isl, bank)

    # -- sprites keep their own cloud puffs
    spr = {}
    for name, m in spr_m.items():
        nearm = cv2.dilate((m > 0.3).astype(np.uint8), np.ones((41, 41), np.uint8)).astype(np.float32)
        wgt = cv2.GaussianBlur(nearm, (0, 0), 14) * (yy < sea_top - 200)
        take = ca * wgt
        spr[name] = np.maximum(m, take)

    # -- paint the background behind the island and the sprites
    core = cv2.dilate((np.maximum.reduce([sil, zero] + list(spr_m.values())) > 0.003).astype(np.uint8), np.ones((15, 15), np.uint8)) > 0
    hole = core | (isl > 0.85)
    hole |= np.maximum.reduce([a > 0.85 for a in spr.values()] + [hole]) if spr else False
    hole |= cv2.dilate((np.maximum.reduce([zero] + list(spr.values())) > 0.02).astype(np.uint8), np.ones((31, 31), np.uint8)) > 0
    log(f"hole {int(hole.sum()):,} px ({hole.mean() * 100:.1f} %)")
    p_bg = paint_behind(p, s, hole, sea_top - 150, seed,
                        band_weight=np.clip((isl - 0.3) / 0.2, 0, 1))

    # -- decompose the clean background into sky + far + mid + sea (one cloud colour each pixel)
    d2 = np.linalg.norm(p_bg - s, axis=-1)
    ca2 = cv2.GaussianBlur(((d2 - 0.012) / k).clip(0, 1), (0, 0), 1.0)
    ca2 = np.where(ca2 < 0.04, 0, (ca2 - 0.04) / 0.96)       # no faint haze rims round the holes
    ca2 = np.maximum(ca2, ramp)
    # the moon and the stars belong to the sky, not to a drifting cloud layer
    fixed = np.zeros((h, w), bool)
    for fx0, fy0, fx1, fy1 in (light_cfg or {}).get("fixedSky", []):
        fixed[fy0:fy1, fx0:fx1] = True                 # the whole box, glow included, is sky
    if (light_cfg or {}).get("stars"):
        lab, n = ndimage.label((ca2 > 0.18) & (yy < sea_top - 200))
        area = ndimage.sum(np.ones_like(ca2), lab, range(1, n + 1))
        small = np.zeros(n + 1, bool)
        small[1:] = np.asarray(area) < light_cfg["stars"]
        fixed |= small[lab]
    fixed_soft = _soft(fixed) if fixed.any() else np.zeros((h, w), np.float32)
    ca2 = ca2 * (1 - fixed_soft)
    sky_full = s + (p_bg - s) * fixed_soft[..., None]
    g = _group_clouds(ca2, sea_top, hand["farMaxY"])
    a_far, a_mid, a_sea = (ca2 * _soft(g == i) for i in (1, 2, 3))
    a_far = a_far * smoothstep(0, 60, yy)          # a layer must not start with a hard top edge
    a_sea = np.maximum(a_sea, ramp)
    ex = np.maximum(a_far + a_mid + a_sea - np.maximum(ca2, a_sea), 0)  # overlaps of the soft split: off the sea
    a_sea = (a_sea - ex).clip(0, 1)
    cloud = unmix(p_bg, sky_full, np.maximum(ca2, 1e-6))
    cloud = np.where(ca2[..., None] > 0.01, cloud, p_bg)

    # layers before wrap closing, in the order they are composited
    bg_far = over(sky_full, cloud, a_far)
    bg = over(over(bg_far, cloud, a_mid), cloud, a_sea)
    bg_nosea = bg_far
    layers: dict[str, dict] = {}
    layers["sky"] = {"rgb": sky_full, "a": np.ones((h, w), np.float32), "pos": (0, 0), "kind": "gradient"}
    layers["far"] = {"rgb": cloud, "a": a_far, "pos": (0, 0), "kind": "tile"}
    for name, a in spr.items():
        f = unmix(p, bg_far, a)
        layers[name] = {"rgb": f, "a": a, "pos": (0, 0), "kind": "sprite", "bg": bg_far}
    layers["mid"] = {"rgb": cloud, "a": a_mid, "pos": (0, 0), "kind": "tile"}
    layers["sea"] = {"rgb": cloud, "a": a_sea, "pos": (0, 0), "kind": "tile"}
    layers["island"] = {"rgb": unmix(p, bg, isl), "a": isl, "pos": (0, 0), "kind": "island"}
    info = {"hole_px": int(hole.sum()), "K": k, "sky_resid_p95": resid}
    return {"layers": layers, "bg": bg, "bg_far": bg_nosea, "p_bg": p_bg, "hole": hole, "sil": sil, "info": info}


def rest_composite(layers: dict) -> np.ndarray:
    """The layers over each other at rest (full plate, unsaved precision)."""
    out = layers["sky"]["rgb"].copy()
    for name in ("far", *[n for n, l in layers.items() if l["kind"] == "sprite"], "mid", "sea", "island"):
        out = over(out, layers[name]["rgb"], layers[name]["a"])
    return out


# ---------------------------------------------------------------- writing the set

def _bbox(a: np.ndarray, t: float = 0.003) -> tuple[int, int, int, int]:
    ys, xs = np.nonzero(a > t)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def _save(rgb: np.ndarray, a: np.ndarray, path: Path) -> int:
    rgb = bleed(rgb, a)
    img = Image.fromarray(np.uint8(np.dstack([rgb, a]).clip(0, 1) * 255 + 0.5), "RGBA")
    heic.save(img, path)
    return path.stat().st_size


def write_set(res: dict, hand: dict, light: str, out: Path, plate_rel: str, seed: int = 0) -> dict:
    """Close the drift tiles, crop every layer, save HEIC q70 and `manifest.json`."""
    out.mkdir(parents=True, exist_ok=True)
    layers = res["layers"]
    h, w = layers["sky"]["a"].shape
    seam = hand["tileSeamPx"]
    entries, sizes = {}, {}
    for lid in ("far", "mid", "sea"):
        lay = layers[lid]
        lay["rgb"], lay["a"] = close_wrap(lay["rgb"], lay["a"], seam, seed)
    # sky: small
    sky = cv2.resize(layers["sky"]["rgb"], (w // SKY_SCALE, h // SKY_SCALE), interpolation=cv2.INTER_AREA)
    sizes["sky"] = _save(sky, np.ones(sky.shape[:2], np.float32), out / "sky.heic")
    entries["sky"] = {"id": "sky", "file": "sky.heic", "pos": [0, 0], "size": [sky.shape[1], sky.shape[0]],
                      "kind": "gradient", "stretchTo": [w, h], "note": "stretch over the plate; stands still"}
    names = ["sky"]
    pad = hand["spritePad"]
    order = ["far"] + list(hand["sprites"]) + ["mid", "sea", "island"]
    for lid in order:
        lay = layers[lid]
        if not (lay["a"] > 0.003).any():
            continue                       # a light with no mid clouds has no mid layer
        if lid in hand["sprites"]:
            x0, y0, x1, y1 = hand["sprites"][lid]["box"]
            box_ = (max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, w), min(y1 + pad, h))
        elif lid in ("far", "mid", "sea"):
            _, ya, _, yb = _bbox(lay["a"])
            box_ = (0, max(ya - 2, 0), w, min(yb + 2, h))
        else:
            box_ = _bbox(lay["a"])
        x0, y0, x1, y1 = box_
        sizes[lid] = _save(lay["rgb"][y0:y1, x0:x1], lay["a"][y0:y1, x0:x1], out / f"{lid}.heic")
        e = {"id": lid, "file": f"{lid}.heic", "pos": [x0, y0], "size": [x1 - x0, y1 - y0], "kind": lay["kind"]}
        if lay["kind"] == "tile":
            e["tileWidth"] = w
            e["parallax"] = {"pxPerSecond": hand["parallax"]["pxPerSecond"][lid], "unit": "screen px at referenceScreen",
                             "direction": "+x"}
        if lay["kind"] == "sprite":
            e["parallax"] = {"pxPerSecond": hand["sprites"][lid]["pxPerSecond"], "unit": "screen px at referenceScreen",
                             "direction": "+x", "wraps": False}
        entries[lid] = e
        names.append(lid)
    sil = _bbox(res["sil"], 0.5)
    manifest = {
        "island": hand["island"], "light": light, "version": 1, "size": [w, h],
        "source": {"plate": plate_rel},
        "order": names, "orderNote": ORDER_NOTE,
        "layers": [entries[n] for n in names],
        "islandBox": list(sil), "seaTop": hand["seaTop"], "seaSolid": hand["seaSolid"],
        "referenceScreen": hand["parallax"]["referenceScreen"], "tileSeamPx": seam,
        "spritePxPerSecond": {n: s["pxPerSecond"] for n, s in hand["sprites"].items()},
        "bytes": {**sizes, "total": int(sum(sizes.values()))},
        "info": {k: (round(v, 4) if isinstance(v, float) else v) for k, v in res["info"].items()},
    }
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1) + "\n")
    return manifest


def build(island: str, light: str, plate: Path | None = None, out: Path | None = None, log=print) -> dict:
    hand = load_hand(island)
    rel = hand["lights"][light]["plate"]
    path = plate or ROOT / rel
    p = load_plate(path, tuple(hand["size"]))
    log(f"{island} {light}: splitting {path.name}")
    res = split_plate(p, hand, log=log, light_cfg=hand["lights"][light])
    rc = rest_composite(res["layers"])
    from heic import delta_e2000
    de = delta_e2000(rc * 255, p * 255)
    log(f"  rest composite before saving: mean dE {de.mean():.3f}, p99 {np.percentile(de, 99):.2f}")
    man = write_set(res, hand, light, out or PLATES / island / "sky" / light, rel)
    log(f"  wrote {man['bytes']['total'] / 1e6:.2f} MB: " + ", ".join(f"{k} {v / 1e3:.0f}k" for k, v in man["bytes"].items() if k != "total"))
    return man


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("--light", default="all", help="day, golden, night or all")
    ap.add_argument("--plate", help="the master to split instead of the shipped plate (one light only)")
    ap.add_argument("--out", help="output directory (one light only)")
    a = ap.parse_args(argv)
    hand = load_hand(a.island)
    lights = list(hand["lights"]) if a.light == "all" else [a.light]
    if (a.plate or a.out) and len(lights) != 1:
        raise SystemExit("--plate and --out need one --light")
    for light in lights:
        build(a.island, light, Path(a.plate) if a.plate else None, Path(a.out) if a.out else None)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
