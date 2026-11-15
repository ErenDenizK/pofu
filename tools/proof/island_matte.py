"""The Home island as a clean alpha layer, cut from each level's own full-size plate (proofs, scripts only).

VERSION 2 (docs/design/world-presentation-v2.md section 4.1). What changed from round 2, which kept the plate's own
haze and a soft border: (1) the matte is full size and its feather is 0: the alpha ramp is 1 to 3 texture px wide;
(2) the plate's sky, mist and the contact haze under the earth body are not in it: the edge band is re-solved from the
plate's colours (a local colour line, island colour against the sky colour just outside it) round the round-2 shape;
(3) edge pixels are decontaminated: a half-transparent pixel takes the island's colour, not the sky's; (4) no specks
and no pinholes; (5) the island's shadow is not in the matte at all: `island_shadow` draws it from the alpha, by code.
The text below is the round-2 description, still true of the shape.


The shipped Home plate (`world-home-plate-<light>-<stage>`, 2048 x 3072) is a whole painting: its own sky and cloud
sea, with an alpha that is only a feathered border (about 1 % of pixels transparent). Laid over another sky it is a
rectangle. The half-size island cut (`world-home-island-*`, 508 x 396, `ingest.ISLAND_SCALE` 0.5 of the 1024 x 1536
plate points) is that plate's matte box downsampled, with the level-10 matte's alpha, so its edges are right but it is
a quarter of the plate's pixels: too soft for mid and near. This module cuts the island from the full-size plate:

  alpha   the level-10 matte (`ingest.load_matte`, 1024 x 1536) at plate resolution: the island, its underside and
          the cloud the matte took in round it, with its wide soft feather
          x  `map_cut.sky_mask`'s `keep` (the level's own silhouette: the sky the lower level paints where level 10
             has its windmill, lighthouse, hill and harbour islet is removed), up to the plate, edges snapped to
             the plate's own colour by a guided filter
          the rim made whole by `map_cut.solid` (the sky never shows through the island)
          the straight cut at the left and right of the matte's box eased out (`skyset_extend.fade_island_edge`)
          and the lighthouse beam, which the box cuts flat, faded out along its length
  colour  the plate's own pixels

`island_layer(light, stage)` returns straight RGBA at plate texture size, cropped to the matte box, and the box's
top-left in plate points. Deterministic; results are cached under `$POFU_MATTE_CACHE` (default: next to this file's
`__pycache__`) because the sky mask runs GrabCut for a few seconds.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import ROOT, load_rgba  # noqa: E402

sys.path.insert(0, str(ROOT / "tools" / "plate"))
import ingest  # noqa: E402
import map_cut  # noqa: E402
import skyset_extend  # noqa: E402

TEX = 2                                     # plate texture px per plate point
BEAM_X = (1870, 1985)                       # texture px: the beam fades out between these columns
BEAM_Y = (1130, 1340)                       # texture rows of the beam band (the lamp is near 1200)
GUIDE_R, GUIDE_EPS = 6, 2e-3                # guided filter on the keep mask: radius px, regularisation
CACHE = Path(os.environ.get("POFU_MATTE_CACHE", Path(__file__).resolve().parent / "__pycache__" / "matte"))


def _guided(guide: np.ndarray, src: np.ndarray, r: int, eps: float) -> np.ndarray:
    """He's guided filter, grey guide, box windows."""
    k = (2 * r + 1, 2 * r + 1)
    mean = lambda x: cv2.boxFilter(x, -1, k, normalize=True)
    mi, mp = mean(guide), mean(src)
    cov = mean(guide * src) - mi * mp
    var = mean(guide * guide) - mi * mi
    a = cov / (var + eps)
    b = mp - a * mi
    return mean(a) * guide + mean(b)


def island_alpha(light: str, stage: int, plate_rgb: np.ndarray) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """Alpha over the matte's box at texture size, and the box (plate points)."""
    a1 = ingest.load_matte("home", light, stage)
    x0, y0, x1, y1 = ingest.bbox(a1, 0.02)
    w, h = (x1 - x0) * TEX, (y1 - y0) * TEX
    base = cv2.resize(a1[y0:y1, x0:x1].astype(np.float32), (w, h), interpolation=cv2.INTER_CUBIC)
    if stage == 0 and light == "day":
        keep = np.ones((h, w), np.float32)
    else:
        _, k = map_cut.sky_mask(light, stage)
        keep = cv2.resize(k.astype(np.float32), (w, h), interpolation=cv2.INTER_CUBIC)
        grey = cv2.cvtColor(plate_rgb[y0 * TEX:y1 * TEX, x0 * TEX:x1 * TEX], cv2.COLOR_RGB2GRAY)
        keep = np.clip(_guided(grey, np.clip(keep, 0, 1), GUIDE_R, GUIDE_EPS), 0, 1)
        keep = np.clip((keep - 0.15) / 0.7, 0, 1)             # the filter's blur back to a firm edge
    alpha = map_cut.solid(np.clip(base, 0, 1)) * keep
    alpha = cv2.GaussianBlur(alpha.astype(np.float32), (0, 0), 0.8)          # the cut's edge, about a pixel soft
    return alpha.astype(np.float32), (x0, y0, x1, y1)


def island_layer_v1(light: str = "day", stage: int = 0) -> tuple[np.ndarray, tuple[int, int]]:
    """Round 2's layer (feathered border, the plate's haze kept): the shape v2 starts from."""
    CACHE.mkdir(parents=True, exist_ok=True)
    f = CACHE / f"island-{light}-{stage}.npz"
    if f.exists():
        z = np.load(f)
        return z["rgba"].astype(np.float32) / 255, (int(z["x"]), int(z["y"]))
    plate = load_rgba(f"world-home-plate-{light}-{stage}")[..., :3]
    alpha, (x0, y0, x1, y1) = island_alpha(light, stage, plate)
    rgb = plate[y0 * TEX:y1 * TEX, x0 * TEX:x1 * TEX]
    rgba = np.dstack([rgb, alpha])
    rgba = skyset_extend.fade_island_edge(rgba, 140)
    # the lighthouse beam: the level-10 matte leaves it in the sky, so cut it from the plate (how far each pixel
    # is from the sky towards the beam's warm white), and fade it out along its length instead of at the box
    bx, by = x0 * TEX, y0 * TEX
    xa, xb = BEAM_X[0] - bx, BEAM_X[1] - bx
    ya, yb = BEAM_Y[0] - by, BEAM_Y[1] - by
    sky = np.median(plate[BEAM_Y[0] - 90:BEAM_Y[0] - 20, BEAM_X[0]:BEAM_X[1]].reshape(-1, 3), axis=0)
    white = np.array([1.0, 0.99, 0.93], np.float32)
    d = white - sky
    t_ = np.clip(((rgb[ya:yb, xa - 40:] - sky) @ d) / float(d @ d), 0, 1)
    t_ = np.clip((t_ - 0.12) / 0.5, 0, 1)
    gx = np.arange(rgba.shape[1] - (xa - 40), dtype=np.float32) + (xa - 40) + bx
    fb = np.clip((gx - BEAM_X[0]) / (BEAM_X[1] - BEAM_X[0]), 0, 1)
    fb = 1 - fb * fb * (3 - 2 * fb)
    rows = np.arange(yb - ya, dtype=np.float32)
    fb = fb[None, :] * np.clip(np.minimum(rows[:, None] / 30, (yb - ya - 1 - rows[:, None]) / 30), 0, 1)
    beam = (t_ * fb).astype(np.float32)
    sub = rgba[ya:yb, xa - 40:]
    na = np.maximum(sub[..., 3], beam)
    use = beam > sub[..., 3]
    sub[..., :3] = np.where(use[..., None], rgb[ya:yb, xa - 40:], sub[..., :3])
    sub[..., 3] = na
    rgba = np.clip(rgba, 0, 1).astype(np.float32)
    np.savez_compressed(f, rgba=(rgba * 255 + 0.5).astype(np.uint8), x=x0, y=y0)
    return np.round(rgba * 255) / 255, (x0, y0)


# ---------------------------------------------------------------- v2

PAD = 24                                    # plate points of room round the matte's box
BAND = 7                                    # px each side of the round-2 shape that the colour line re-solves
SIGMA_NEAR, SIGMA_FAR = 5.0, 16.0           # reach of the island / sky colour estimates (normalised convolution)
SEP_LO, SEP_HI = 0.05, 0.14                 # colour distance island to sky below which the line is not trusted
SHARP = (0.32, 0.88)                        # alpha stretched between these: the ramp ends up 1 to 3 px wide
CORE_R = 2                                  # px of the rim whose colour is taken from just inside it
EDGE_MID, EDGE_GAIN = 0.55, 5.0
ENCLOSED_MIN = 60
POCKET_REACH = 40                           # px a sky pocket may run in from the outside under a dark sky
POCKET_TOL = 0.06                           # colour distance to the sky just outside that counts as the same sky
MIN_PIECE = 64                              # px: a separate piece smaller than this is a speck; a hole smaller, a pinhole


def _nconv(img: np.ndarray, mask: np.ndarray, sigma: float) -> tuple[np.ndarray, np.ndarray]:
    """Colour of the masked pixels spread by a Gaussian (normalised convolution), and the weight under it."""
    m = mask.astype(np.float32)
    num = cv2.GaussianBlur(img * m[..., None], (0, 0), sigma)
    den = cv2.GaussianBlur(m, (0, 0), sigma)
    return num / np.maximum(den, 1e-4)[..., None], den


def _estimate(rgb: np.ndarray, known: np.ndarray) -> np.ndarray:
    """A colour for every pixel from the `known` ones, near first, far where nothing is near."""
    near, wn = _nconv(rgb, known, SIGMA_NEAR)
    far, wf = _nconv(rgb, known, SIGMA_FAR)
    t = np.clip(wn / 0.08, 0, 1)[..., None]
    return near * t + far * (1 - t)


def _fill_small(mask: np.ndarray, area: int) -> np.ndarray:
    """`mask` with every hole smaller than `area` filled."""
    inv = (~mask).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(inv, connectivity=4)
    out = mask.copy()
    for i in range(1, n):
        x, y, w, h, a = st[i]
        if a < area and x > 0 and y > 0 and x + w < mask.shape[1] and y + h < mask.shape[0]:
            out[lab == i] = True
    return out


def _drop_small(mask: np.ndarray, area: int) -> np.ndarray:
    n, lab, st, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), connectivity=8)
    keep = np.zeros(n, bool)
    keep[1:] = st[1:, 4] >= area
    return keep[lab]


def solve_edge(rgb: np.ndarray, shape: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Alpha and decontaminated colour at plate resolution. `rgb` the plate crop (0..1), `shape` round 2's alpha."""
    inside = _drop_small(_fill_small(shape > 0.5, MIN_PIECE), MIN_PIECE)
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * BAND + 1, 2 * BAND + 1))
    deep = cv2.erode(inside.astype(np.uint8), k).astype(bool)
    far_out = ~cv2.dilate(inside.astype(np.uint8), k).astype(bool)
    band = ~deep & ~far_out
    fg = _estimate(rgb, deep)
    bg = _estimate(rgb, far_out)
    d = fg - bg
    dist = np.linalg.norm(d, axis=2)
    t = ((rgb - bg) * d).sum(2) / np.maximum(dist * dist, 1e-6)
    rel = np.clip((dist - SEP_LO) / (SEP_HI - SEP_LO), 0, 1)
    resid = np.linalg.norm(rgb - (bg + t[..., None] * d), axis=2)
    rel *= 1 - np.clip((resid - 0.05) / 0.10, 0, 0.7)      # a pixel that is not a mix of the two (texture): less sure
    hard = cv2.GaussianBlur(inside.astype(np.float32), (0, 0), 0.6)
    a = rel * np.clip(t, 0, 1) + (1 - rel) * hard
    # inside the band the colour line decides; the shape decides outside it, and holds the rim whole
    w = cv2.GaussianBlur(band.astype(np.float32), (0, 0), 1.0)
    a = w * a + (1 - w) * inside
    a = np.clip((a - SHARP[0]) / (SHARP[1] - SHARP[0]), 0, 1)
    a = np.where(far_out, 0.0, a)
    a = np.where(deep, 1.0, a)
    solid_ = _drop_small(_fill_small(a > 0.5, MIN_PIECE), MIN_PIECE)
    a = np.where(~cv2.dilate(solid_.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool), 0.0, a)
    a = np.where(_fill_small(a > 0.5, MIN_PIECE) & (a <= 0.5) & ~band, 1.0, a)
    # pockets: sky (haze) caught in a notch more than BAND from the outside, e.g. between a root and the body. Pixels
    # that look like the sky just outside, not like the island next to them, and are joined to the outside through
    # such pixels, are sky.
    cross = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
    d_bg = np.linalg.norm(rgb - bg, axis=2)
    chroma = lambda c: c / np.maximum(c.sum(2, keepdims=True), 1e-3)
    blue_sky = (bg[..., 2] - bg[..., 0]) > 0.08                       # a haze: its colour, lighter or darker, is the sky
    same_hue = (np.linalg.norm(chroma(rgb) - chroma(bg), axis=2) < 0.03) & blue_sky & (rgb.mean(2) > 0.35)
    # the sky inside a notch can be some way from the sky just outside it: a wide estimate (sigma 48) is a second reference
    bg_wide, _ = _nconv(rgb, far_out, 48.0)
    d_wide = np.linalg.norm(rgb - bg_wide, axis=2)
    same_wide = (np.linalg.norm(chroma(rgb) - chroma(bg_wide), axis=2) < 0.03) & ((bg_wide[..., 2] - bg_wide[..., 0]) > 0.08) & (rgb.mean(2) > 0.35)
    skylike = ((d_bg < POCKET_TOL) | same_hue | (d_wide < POCKET_TOL) | same_wide).astype(np.uint8)
    # sky-like pixels joined to the outside by a chain of sky-like pixels (a pond, a window, a blue door are enclosed
    # by the island and stay)
    n_, lab_ = cv2.connectedComponents(((skylike > 0) | (a < 0.5)).astype(np.uint8), connectivity=4)
    outside_lab = np.unique(lab_[a < 0.02])
    reach_far = np.isin(lab_, outside_lab[outside_lab > 0]) & (skylike > 0)
    # a dark sky (night) looks like a lavender wall or a tree's shade: there a pocket may only run POCKET_REACH px in
    bright = bg_wide.mean(2) > 0.6
    near_ = (a < 0.5).astype(np.uint8)
    for _ in range(POCKET_REACH):
        near_ = cv2.dilate(near_, cross) & (skylike | near_)
    reach = (reach_far & bright) | (near_ > 0) & (skylike > 0)
    reach = cv2.dilate(reach.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & (skylike > 0)
    # sky that the island's own parts enclose (between an awning and a cart): the plate's sky colour, a patch of
    # ENCLOSED_MIN px or more, is not the island either
    strict = ((d_wide < 0.05) & bright & ((bg_wide[..., 2] - bg_wide[..., 0]) > 0.08) & (rgb.mean(2) > 0.5) & (a > 0.5)).astype(np.uint8)
    strict = cv2.morphologyEx(strict, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n_e, lab_e, st_e, _ = cv2.connectedComponentsWithStats(strict, connectivity=8)
    enc = np.isin(lab_e, [i for i in range(1, n_e) if st_e[i, 4] >= ENCLOSED_MIN])
    enc = cv2.dilate(enc.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & (skylike > 0)
    reach = reach | enc
    pocket = reach & (a > 0.5)
    fringe = cv2.dilate(pocket.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool) & ((d_bg < 2 * POCKET_TOL) | same_hue)
    a = np.where(reach | fringe, 0.0, a)
    a = np.where(a < 0.02, 0.0, a).astype(np.float32)
    # no specks, no pinholes (M4): a piece of alpha under MIN_PIECE px goes, a hole under it closes
    a = np.where(_drop_small(a > 0.02, MIN_PIECE), a, 0.0).astype(np.float32)
    a = np.where(_fill_small(a >= 0.99, MIN_PIECE) & ~(a >= 0.99), 1.0, a).astype(np.float32)
    # a ramp that is still fuzzy (grass tips on a cloud) is drawn steeper about 0.55: 1 to 3 px, nothing stays outside
    a = np.clip((a - EDGE_MID) * EDGE_GAIN + 0.5, 0, 1).astype(np.float32)
    a = np.where(_drop_small(a > 0.02, MIN_PIECE), a, 0.0).astype(np.float32)
    a = np.where(_fill_small(a >= 0.99, MIN_PIECE) & ~(a >= 0.99), 1.0, a).astype(np.float32)
    # colour: the island's own at the edge (unmix against the sky just outside, held within 0.04 of the island's estimate)
    core = cv2.erode((a >= 0.99).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * CORE_R + 1, 2 * CORE_R + 1))).astype(bool)
    inner = _estimate(rgb, core)
    un = np.clip((rgb - (1 - a)[..., None] * bg) / np.maximum(a, 0.3)[..., None], 0, 1)
    edge_rgb = inner + np.clip(un - inner, -0.04, 0.04) * np.clip((a - 0.3) / 0.4, 0, 1)[..., None]
    out = np.where(core[..., None], rgb, edge_rgb)           # the outer CORE_R px of the island are the plate's colour inside, not at the edge
    return a, np.clip(out, 0, 1).astype(np.float32)


def _beam(plate: np.ndarray, rgb: np.ndarray, box: tuple[int, int, int, int]) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """The lighthouse beam as its own soft alpha over the box (v1's cut: the warm white of the sky towards it), and
    the rect it lies in, a soft edge by declaration."""
    x0, y0, x1, y1 = box
    bx, by = x0 * TEX, y0 * TEX
    xa, xb = BEAM_X[0] - bx, BEAM_X[1] - bx
    ya, yb = BEAM_Y[0] - by, BEAM_Y[1] - by
    sky = np.median(plate[BEAM_Y[0] - 90:BEAM_Y[0] - 20, BEAM_X[0]:BEAM_X[1]].reshape(-1, 3), axis=0)
    white = np.array([1.0, 0.99, 0.93], np.float32)
    d = white - sky
    sub = rgb[ya:yb, xa - 40:]
    t_ = np.clip(((sub - sky) @ d) / float(d @ d), 0, 1)
    t_ = np.clip((t_ - 0.12) / 0.5, 0, 1)
    gx = np.arange(sub.shape[1], dtype=np.float32) + (xa - 40) + bx
    fb = np.clip((gx - BEAM_X[0]) / (BEAM_X[1] - BEAM_X[0]), 0, 1)
    fb = 1 - fb * fb * (3 - 2 * fb)
    rows = np.arange(yb - ya, dtype=np.float32)
    fb = fb[None, :] * np.clip(np.minimum(rows[:, None] / 30, (yb - ya - 1 - rows[:, None]) / 30), 0, 1)
    return (t_ * fb).astype(np.float32), (xa - 40, ya, rgb.shape[1], yb)


def has_beam(stage: int) -> bool:
    return stage <= 0                       # only the level-10 plate has the lighthouse


def fill_lawn_gaps(rgb: np.ndarray, shape: np.ndarray) -> np.ndarray:
    """The level-10 matte is the shape of every level, but a lower level paints lawn where level 10 has a channel (between
    the tea stall's land and the harbour islet at level 4). Where the plate is lawn-coloured outside the shape and joined to
    it, the shape takes it in."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lawn = ((g > b + 0.12) & (g > r * 0.92) & (g > 0.35)).astype(np.uint8)
    out = (shape > 0.5)
    cand = (lawn > 0) & ~out
    cand = cv2.morphologyEx(cand.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(cand, connectivity=4)
    touch = cv2.dilate(out.astype(np.uint8), np.ones((5, 5), np.uint8)).astype(bool)
    take = np.zeros(n, bool)
    for i in np.unique(lab[touch & (cand > 0)]):
        if i > 0 and st[i, 4] >= 150:
            take[i] = True
    fill = take[lab]
    fill = cv2.morphologyEx(fill.astype(np.uint8), cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8)).astype(bool)
    return np.maximum(shape, fill.astype(np.float32))


def island_layer(light: str = "day", stage: int = 0) -> tuple[np.ndarray, tuple[int, int]]:
    """v2: straight RGBA at plate texture size over the matte box, and the box's top-left in plate points."""
    CACHE.mkdir(parents=True, exist_ok=True)
    f = CACHE / f"island2-{light}-{stage}.npz"
    if f.exists():
        z = np.load(f)
        return z["rgba"].astype(np.float32) / 255, (int(z["x"]), int(z["y"]))
    plate = load_rgba(f"world-home-plate-{light}-{stage}")[..., :3]
    # a night or golden plate is its day plate's island level repainted in another light (same geometry): the shape is the
    # day plate's, because the sky mask grabbed from a dark plate loses the tree, the windmill and the lighthouse
    shape_plate = plate if light == "day" else load_rgba(f"world-home-plate-day-{stage}")[..., :3]
    shape, (bx0, by0, bx1, by1) = island_alpha("day", stage, shape_plate)
    # the matte's box is cut at 2 % alpha: give the layer room on every side (the plate's own edge where it ends) so no
    # part of the island is clipped flat by the layer
    ph, pw = plate.shape[0] // TEX, plate.shape[1] // TEX
    x0, y0, x1, y1 = max(bx0 - PAD, 0), max(by0 - PAD, 0), min(bx1 + PAD, pw), min(by1 + PAD, ph)
    shape = np.pad(shape, (((by0 - y0) * TEX, (y1 - by1) * TEX), ((bx0 - x0) * TEX, (x1 - bx1) * TEX)))
    rgb = plate[y0 * TEX:y1 * TEX, x0 * TEX:x1 * TEX]
    a, col = solve_edge(rgb, fill_lawn_gaps(rgb, shape))
    a[:1], a[-1:], a[:, :1], a[:, -1:] = 0, 0, 0, 0
    rgba = np.dstack([col, a])
    if has_beam(stage):
        beam, (xa, ya, xb, yb) = _beam(plate, rgb, (x0, y0, x1, y1))
        sub = rgba[ya:yb, xa:xb]
        use = beam > sub[..., 3]
        sub[..., :3] = np.where(use[..., None], rgb[ya:yb, xa:xb], sub[..., :3])
        sub[..., 3] = np.maximum(sub[..., 3], beam)
    rgba = np.clip(rgba, 0, 1).astype(np.float32)
    np.savez_compressed(f, rgba=(rgba * 255 + 0.5).astype(np.uint8), x=x0, y=y0)
    return np.round(rgba * 255) / 255, (x0, y0)


def soft_edges(light: str, stage: int, shape: tuple[int, int]) -> list[np.ndarray]:
    """Polygons (layer px, x y) the checks skip because the region is meant to be soft: the beam's rect."""
    if not has_beam(stage):
        return []
    x0, y0 = island_layer(light, stage)[1]
    xa, ya = BEAM_X[0] - 40 - x0 * TEX, BEAM_Y[0] - y0 * TEX
    xb, yb = shape[1], BEAM_Y[1] - y0 * TEX
    return [np.array([[xa, ya], [xb, ya], [xb, yb], [xa, yb]], np.float32)]


def source_crop(light: str, stage: int) -> np.ndarray:
    """The plate pixels under the layer (what it was cut from)."""
    rgba, (x0, y0) = island_layer(light, stage)
    plate = load_rgba(f"world-home-plate-{light}-{stage}")[..., :3]
    return plate[y0 * TEX:y0 * TEX + rgba.shape[0], x0 * TEX:x0 * TEX + rgba.shape[1]]


def island_shadow(alpha: np.ndarray, *, opacity: float = 0.34, drop: float = 0.9, squash: float = 0.22) -> np.ndarray:
    """The island's shadow on the cloud below, by code: an ellipse under the silhouette's underside (its lower 45 %),
    squashed, dropped `drop` x half the island's height below its foot and blurred wide. Returns an alpha layer
    `alpha.shape[1]` wide and 1.5 x as tall, to be filled with a dark sky tone and put on the near floor layer. This is
    the only shadow: the plate's own contact haze is not in the matte."""
    h, w = alpha.shape
    ys = np.where(alpha.max(1) > 0.5)[0]
    top, bot = int(ys[0]), int(ys[-1])
    prof = alpha[top + int((bot - top) * 0.55):bot].max(0)
    xs = np.where(prof > 0.5)[0]
    cx, hw = (xs[0] + xs[-1]) / 2, (xs[-1] - xs[0]) / 2
    cy = bot + (bot - top) * drop * 0.5
    yy, xx = np.mgrid[:int(h * 1.5), :w].astype(np.float32)
    e = ((xx - cx) / (hw * 0.92)) ** 2 + ((yy - cy) / (hw * squash)) ** 2
    sh = cv2.GaussianBlur(np.clip(1 - e, 0, 1) ** 0.7, (0, 0), hw * 0.06)
    return (sh * opacity).astype(np.float32)


if __name__ == "__main__":
    from PIL import Image
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    for spec in sys.argv[2:]:
        light, stage = spec.split(":")
        rgba, (x0, y0) = island_layer(light, int(stage))
        bg = np.empty(rgba.shape[:2] + (3,), np.float32)
        bg[:] = (1, 0, 1)
        im = rgba[..., :3] * rgba[..., 3:] + bg * (1 - rgba[..., 3:])
        Image.fromarray((im * 255 + 0.5).astype(np.uint8)).save(out / f"matte-{light}-{stage}-magenta.png")
        print(light, stage, rgba.shape, (x0, y0), "alpha mean %.3f" % rgba[..., 3].mean())
