#!/usr/bin/env python3
"""Checks on composited frames of a plate split (`split.py`), at the app framing.

    python3 -I tools/plate/screen_check.py home [day|golden|night|all] [--json OUT] [--frames DIR]

A frame is composited from the saved sky set (`design/art/plates/<island>/sky/<light>/`, HEIC) at the
Home framing (`framing` in `objects.json`: the island 1.15 screens wide on a 1206 x 2622 screen) with
the cloud layers drifted as at time t (far 4, mid 9, sea 14 screen px per second). Eight measures in six checks, each a
function on frames so the same code can read a CI screenshot later (`check_frame`):

  1 identity   frame zero against the unsplit master: mean dE2000 and p99
  2 seam       with the clouds drifted (t = 0, 30, 120 s), in a ring round the island's edge no pixel
               differs from both neighbours across any axis by more than dE 8, beyond what the master
               has there itself (a thin line that was not in the painting is a halo or a seam)
  2b blocks   straight block edges (a filled hole's tiles) in the cloud sea round the island, new at t > 0
  2c leak     no island-hued pixel in the drifting layers (a rejected island bit would wrap round)
  3 colour     `colour_metrics` bands (pale / hot flags) and the sky-to-lawn luminance ratio against
               the master's, drifted frames too
  4 dead       the longest run of rows with no detail, as a share of the screen height
  5 life       two seconds of drift change the sky and leave the island untouched
  6 resolution source pixels per screen pixel on the island

`sky` renders the shipped sky set (`skyset_render.py`, the app's layers and motion) and runs three more: no mirror
image in the rows past the plate, no stripe or box edge in the sky layer, no doubled star (a star's ghost left in a
drifting layer). `ci` reads the app's own frames instead: `--frames DIR` holds `home-plate-full-l10-<light>.png` from the
simulator (the sky set at time zero, `worldStillFrame`) and `--before DIR` the same frames of the
plate-only build; each is checked as `check_ci` says (identity against the previous frame, colour,
dead composition, resolution).

The thresholds are starting guesses calibrated on Home (`THRESHOLDS`; `calibration.json` next to the
sky sets records what each light measured). Needs numpy, OpenCV, Pillow, pillow-heif.
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
import colour_metrics  # noqa: E402
import heic  # noqa: E402
import split  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"
SCREEN = (1206, 2622)            # px: 402 x 874 pt at 3x
SCREEN_PT = (402, 874)
DRIFT = {"far": 4.0, "mid": 9.0, "sea": 14.0}   # screen px per second
TIMES = (0, 30, 120)

# the three checks on the shipped layers (`run_sky`) and the mirror check on any frame; calibrated on the
# sky sets before and after the fixes (`calibration.json`)
SKY_THRESHOLDS = {
    "mirror": {"ratio_min": 0.5, "rows": 300, "min_rows": 40},
    "sky_edges": {"col_hp": 0.4, "row_hp": 1.0, "band": 0.42},
    "ghosts": {"max_points": 0, "radius": 24, "min_area": 6, "max_area": 150},
    "speckle": {"floor": 0.02, "max_area": 250, "max_alpha": 0.30, "max_pieces": 0},
    "dark_halo": {"lo": 0.08, "hi": 0.9, "dark": 0.02, "max_px": 30000, "rows": 1700},
    "sea_line": {"window": 14, "ratio_max": 2.2, "excess_max": 1.2},
}

# starting guesses, calibrated on Home day, golden and night (see calibration.json)
THRESHOLDS = {
    "identity": {"mean_de": 1.5, "p99_de": 6.0},
    # Çağlayan's CI frames against the landscape build: the island and the rows its plate covered. The island is the
    # stage plate's own pixels (strict); the rest of those rows is the portrait master's sky, repainted by the
    # outpaint, so it differs from the landscape plate's by a little (looser); the rows past the plate are new.
    # Çağlayan's own sets drop the alpha under 0.08 (noise) and quilt the sea past the master: the p99 gives a little
    "identity_portrait": {"mean_de": 1.5, "p99_de": 7.0},
    "identity_plate": {"island_mean_de": 1.5, "island_p99_de": 6.0, "rows_mean_de": 4.0, "rows_p99_de": 14.0},
    "seam": {"de": 8.0, "ring_px": 6, "max_new_share": 0.002, "block_de": 3.0, "block_run": 40, "near_px": 300,
             "max_new_block_share": 0.0005},
    "leak": {"max_px": 200, "palette_de": 12.0, "palette_k": 8},
    "colour": {"ratio_tol": 0.10, "pale_hot": True},
    "dead": {"max_run_share": 0.20, "over_master": 0.02, "row_detail": 0.0025},
    "life": {"sky_floor": 0.25, "island_max": 0.5},
    "resolution": {"min_source_per_screen": 0.9},
}


# ---------------------------------------------------------------- the set

def load_set(dir_: Path) -> dict:
    """The manifest and its layers as premultiplied float RGBA arrays (straight colour decoded
    from the saved HEIC, so codec loss is part of what is measured)."""
    man = json.loads((dir_ / "manifest.json").read_text())
    w, h = man["size"]
    layers = {}
    for lay in man["layers"]:
        im = np.asarray(heic.open_image(dir_ / lay["file"]).convert("RGBA"), np.float32) / 255
        if lay["kind"] == "gradient":
            im = cv2.resize(im, (w, h), interpolation=cv2.INTER_LINEAR)
        layers[lay["id"]] = {"rgba": im, "pos": tuple(lay["pos"]), "kind": lay["kind"], "meta": lay}
    return {"manifest": man, "layers": layers}


def framing(man: dict, hand: dict | None = None, screen: tuple[int, int] = SCREEN) -> dict:
    """The Home frame: plate px per screen px `k`, the window's top-left in plate px, as ingest's
    `home_frame` does (island `homeWidths` screens wide, centred at `homeCenterX` of its box, its
    top `homeTopY` points below the screen's top)."""
    f = hand or json.loads((PLATES / man["island"] / "objects.json").read_text())["framing"]
    x0, y0, x1, _ = man["islandBox"]
    ws = (x1 - x0) / f["homeWidths"]
    k = ws / screen[0]
    kpt = ws / (screen[0] / 3)
    cx = x0 + f["homeCenterX"] * (x1 - x0)
    return {"k": k, "x0": cx - ws / 2, "y0": y0 - f["homeTopY"] * kpt * screen[0] / SCREEN[0], "ws": ws,
            "screen": screen}


def _place(rgba: np.ndarray, pos, size, kind: str, pad: tuple[int, int]) -> np.ndarray:
    """The layer on a full-plate canvas (premultiplied), plus `pad` rows above and below that
    extend the picture past the plate: the sky repeats its edge row, the cloud sea mirrors."""
    w, h = size
    top, bot = pad
    canvas = np.zeros((h + top + bot, w, 4), np.float32)
    x, y = pos
    rh, rw = rgba.shape[:2]
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    canvas[top + y: top + y + rh, x: x + rw] = pre
    if kind == "gradient":
        canvas[:top] = canvas[top]
        canvas[top + h:] = canvas[top + h - 1]
    elif kind == "sea" and bot:
        n = min(bot, h - y)
        canvas[top + h: top + h + n] = canvas[top + h - 1: top + h - 1 - n: -1][:n]
    return canvas


def compose(s: dict, t: float = 0.0, frame: dict | None = None, upto: str | None = None) -> dict:
    """Composite the set at time `t` into a 1206 x 2622 frame. Returns the frame ("rgb" 0..255
    float), the island's screen alpha, and the plate-covered mask."""
    man = s["manifest"]
    w, h = man["size"]
    fr = frame or framing(man)
    scr = fr["screen"]
    k = fr["k"]
    c = 1 / k                                                    # screen px per plate px
    top = max(int(np.ceil(-fr["y0"])), 0) + 4
    bot = max(int(np.ceil(fr["y0"] + scr[1] * k - h)), 0) + 4
    sw, sh = int(round(w * c)), int(round((h + top + bot) * c))
    ox = int(round((fr["x0"]) * c))
    oy = int(round((fr["y0"] + top) * c))
    out = np.zeros((scr[1], scr[0], 3), np.float32)
    island_a = np.zeros(scr[::-1], np.float32)
    drift_rate = {**DRIFT, **{n: v for n, v in man.get("spritePxPerSecond", {}).items()}}
    for lid in man["order"]:
        lay = s["layers"][lid]
        kind = lay["meta"].get("role", lay["kind"])
        # a drift tile may be wider than the master (a bridge added to the right, `split.bridge_wrap`)
        tile = lay["kind"] == "tile"
        tw = lay["rgba"].shape[1] if tile else w
        stw = int(round(tw * c)) if tile else sw
        canvas = _place(lay["rgba"], lay["pos"], (tw, h), "sea" if lid == "sea" else lay["kind"], (top, bot))
        img = cv2.resize(canvas, (stw, sh), interpolation=cv2.INTER_AREA).reshape(sh, stw, 4)
        shift = int(round(drift_rate.get(lid, 0.0) * t)) if (lay["kind"] == "tile" or lay["kind"] == "sprite") else 0
        if lay["kind"] == "tile" and shift:
            img = np.roll(img, shift, axis=1)
        elif lay["kind"] == "sprite" and shift:
            img = _shift_x(img, shift)
        # the screen window
        win = np.zeros((scr[1], scr[0], 4), np.float32)
        x_src0, y_src0 = ox, oy
        xs0, xs1 = max(x_src0, 0), min(x_src0 + scr[0], sw)
        ys0, ys1 = max(y_src0, 0), min(y_src0 + scr[1], sh)
        if tile and ys1 > ys0:
            # a tile wraps: the columns past the master's edge (the screen can be wider than it) are its next copy
            cols = (np.arange(scr[0]) + x_src0) % stw
            win[ys0 - y_src0: ys1 - y_src0] = img[ys0:ys1][:, cols]
        elif xs1 > xs0 and ys1 > ys0:
            win[ys0 - y_src0: ys1 - y_src0, xs0 - x_src0: xs1 - x_src0] = img[ys0:ys1, xs0:xs1]
        a = win[..., 3:4]
        out = win[..., :3] + out * (1 - a)
        if lid == "island":
            island_a = win[..., 3]
        if upto == lid:
            break
    cover = np.zeros(scr[::-1], bool)
    r0, r1 = max(int(round((-fr["y0"]) * c)), 0), min(int(round((h - fr["y0"]) * c)), scr[1])
    cover[r0:r1] = True
    c0, c1 = max(-ox, 0), min(sw - ox, scr[0])                    # the columns the master reaches (the screen may be wider)
    cover[:, :c0] = False
    cover[:, c1:] = False
    return {"rgb": np.clip(out, 0, 1) * 255, "island_alpha": island_a, "covered": cover, "frame": fr}


def _shift_x(img: np.ndarray, s: int) -> np.ndarray:
    """A sprite drifts without wrapping (its tile is the plate: it leaves one side)."""
    out = np.zeros_like(img)
    if s >= 0:
        out[:, s:] = img[:, : img.shape[1] - s]
    else:
        out[:, :s] = img[:, -s:]
    return out


def master_frame(s: dict, plate: np.ndarray, frame: dict | None = None) -> np.ndarray:
    """The unsplit master (plate RGB 0..255) at the same framing, extended the same way: the rows past
    the plate repeat its edge rows (only the covered rows are compared)."""
    man = s["manifest"]
    w, h = man["size"]
    fr = frame or framing(man)
    scr = fr["screen"]
    k = fr["k"]
    c = 1 / k
    top = max(int(np.ceil(-fr["y0"])), 0) + 4
    bot = max(int(np.ceil(fr["y0"] + scr[1] * k - h)), 0) + 4
    ext = np.concatenate([np.repeat(plate[:1], top, 0), plate, np.repeat(plate[-1:], bot, 0)], 0).astype(np.float32)
    sw, sh = int(round(w * c)), int(round((h + top + bot) * c))
    img = cv2.resize(ext, (sw, sh), interpolation=cv2.INTER_AREA)
    ox, oy = int(round(fr["x0"] * c)), int(round((fr["y0"] + top) * c))
    out = np.zeros((scr[1], scr[0], 3), np.float32)
    xs0, xs1 = max(ox, 0), min(ox + scr[0], sw)
    ys0, ys1 = max(oy, 0), min(oy + scr[1], sh)
    out[ys0 - oy: ys1 - oy, xs0 - ox: xs1 - ox] = img[ys0:ys1, xs0:xs1]
    return np.clip(out, 0, 255)


# ---------------------------------------------------------------- measures

def de_map(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    return heic.delta_e2000(a, b)


def check_identity(frame: np.ndarray, master: np.ndarray, covered: np.ndarray, th: dict) -> dict:
    keep = covered
    de = de_map(frame[keep], master[keep])
    mean, p99 = float(de.mean()), float(np.percentile(de, 99))
    return {"mean_de": round(mean, 3), "p99_de": round(p99, 3),
            "ok": mean < th["mean_de"] and p99 < th["p99_de"]}


def ring_mask(island_alpha: np.ndarray, px: int) -> np.ndarray:
    k = np.ones((2 * px + 1, 2 * px + 1), np.uint8)
    outer = cv2.dilate((island_alpha > 0.01).astype(np.uint8), k) > 0
    inner = cv2.erode((island_alpha > 0.99).astype(np.uint8), k) > 0
    return outer & ~inner


_AXES = (((0, 1), (0, -1)), ((1, 0), (-1, 0)), ((1, 1), (-1, -1)), ((1, -1), (-1, 1)))


def line_pixels(frame: np.ndarray, ring: np.ndarray, de_thresh: float) -> np.ndarray:
    """Ring pixels that differ from BOTH neighbours across some axis by more than `de_thresh`
    (horizontal, vertical, two diagonals): a thin line, as a halo or a seam is. A plain edge has one
    neighbour like itself and does not count."""
    ys, xs = np.nonzero(ring)
    h, w = ring.shape
    ys = np.clip(ys, 1, h - 2)
    xs = np.clip(xs, 1, w - 2)
    here = frame[ys, xs]
    bad = np.zeros(len(ys), bool)
    for (dy1, dx1), (dy2, dx2) in _AXES:
        d1 = de_map(here, frame[ys + dy1, xs + dx1])
        d2 = de_map(here, frame[ys + dy2, xs + dx2])
        bad |= (d1 > de_thresh) & (d2 > de_thresh)
    out = np.zeros(ring.shape, bool)
    out[ys[bad], xs[bad]] = True
    return out


def check_seam(frames: dict[int, np.ndarray], island_alpha: np.ndarray, th: dict) -> dict:
    """`frames` maps t to a frame; the first is the reference (t = 0)."""
    ring = ring_mask(island_alpha, th["ring_px"])
    base = line_pixels(frames[0], ring, th["de"])
    near_base = cv2.dilate(base.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
    res, ok = {}, True
    for t, fr in frames.items():
        lp = line_pixels(fr, ring, th["de"])
        new = lp & ~near_base
        share = float(new.sum() / max(ring.sum(), 1))
        res[str(t)] = {"line_share": round(float(lp.sum() / max(ring.sum(), 1)), 5), "new_share": round(share, 5),
                       "new_px": int(new.sum())}
        ok &= share <= th["max_new_share"]
    return {"ring_px": int(ring.sum()), "t": res, "ok": bool(ok)}


def block_pixels(frame: np.ndarray, region: np.ndarray, de: float, run: int) -> np.ndarray:
    """Pixels on a long straight vertical or horizontal step (a block edge of a filled hole): one
    pixel step above `de` that keeps going straight for `run` px. Soft clouds have none."""
    f = frame.astype(np.float32)
    dx = np.zeros(frame.shape[:2], np.float32)
    dy = np.zeros_like(dx)
    dx[:, :-1] = de_map(f[:, :-1], f[:, 1:])
    dy[:-1] = de_map(f[:-1], f[1:])
    vx = cv2.morphologyEx((dx > de).astype(np.uint8), cv2.MORPH_OPEN, np.ones((run, 1), np.uint8))
    hy = cv2.morphologyEx((dy > de).astype(np.uint8), cv2.MORPH_OPEN, np.ones((1, run), np.uint8))
    return ((vx > 0) | (hy > 0)) & region


def check_blocks(frames: dict[int, np.ndarray], island_alpha: np.ndarray, th: dict, covered: np.ndarray | None = None) -> dict:
    """Straight block edges in the cloud sea round the island (the filled hole drifting out), beyond
    what frame zero has."""
    k = th["near_px"]
    solid = island_alpha > 0.5
    near = (cv2.dilate(solid.astype(np.uint8), np.ones((2 * k + 1, 2 * k + 1), np.uint8)) > 0) & ~solid
    ys = np.nonzero(solid.any(1))[0]
    near[: (ys[0] + ys[-1]) // 2] = False              # the cloud sea round the island's lower half
    if covered is not None:
        near &= covered.any(0)[None, :]                # not the screen's margin beyond the master (the split's own frame leaves it bare)
    base = block_pixels(frames[0], near, th["block_de"], th["block_run"])
    base = cv2.dilate(base.astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    res, ok = {}, True
    for t, fr in frames.items():
        new = block_pixels(fr, near, th["block_de"], th["block_run"]) & ~base
        share = float(new.sum() / max(near.sum(), 1))
        res[str(t)] = {"new_px": int(new.sum()), "new_share": round(share, 6)}
        ok &= share <= th["max_new_block_share"]
    return {"t": res, "ok": bool(ok)}


def island_palette(island_rgba: np.ndarray, k: int = 8) -> np.ndarray:
    """The island's own greens as `k` CIELAB cluster centres: the opaque pixels of the island layer (the matte's
    inside) that are in the island's hue band (`split.island_hued`). What a cloud layer must not hold is
    *these* colours, not every green: an aurora is green too."""
    rgb, a = island_rgba[..., :3], island_rgba[..., 3]
    sel = (a > 0.95) & split.island_hued(rgb)
    if sel.sum() < k:
        return np.zeros((0, 3), np.float32)
    lab = heic._lab(np.asarray(rgb[sel], np.float64) * 255).astype(np.float32)
    if len(lab) > 40000:
        lab = lab[np.random.default_rng(0).choice(len(lab), 40000, replace=False)]
    _, _, centres = cv2.kmeans(lab, k, None, (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_MAX_ITER, 30, 0.5), 3,
                               cv2.KMEANS_PP_CENTERS)
    return centres


def check_leaks(s: dict, th: dict) -> dict:
    """The drifting layers (far, mid, sea) must hold no island pixels: an island bit the matte rejected would
    wrap round and show as a second harbour at the edge. A pixel is island's when it is in the island's hue band
    *and* within `palette_de` dE of one of the island layer's own colours (`island_palette`, taken from the
    island matte's inside): a green aurora or a yellow-green sunset cloud is not the lawn. A set without an island
    layer falls back to the hue band alone."""
    res, total = {}, 0
    island = s["layers"].get("island")
    palette = island_palette(island["rgba"], th.get("palette_k", 8)) if island is not None and "palette_de" in th else None
    for lid in ("far", "mid", "sea"):
        if lid not in s["layers"]:
            continue
        im = s["layers"][lid]["rgba"]
        bad = split.island_hued(im[..., :3]) & (im[..., 3] > 0.25)
        if palette is not None and len(palette) and bad.any():
            lab = heic._lab(np.asarray(im[..., :3][bad], np.float64) * 255)
            near = np.sqrt(((lab[:, None, :] - palette[None, :, :]) ** 2).sum(-1)).min(1) < th["palette_de"]
            keep = np.zeros_like(bad)
            keep[bad] = near
            bad = keep
        n = int(bad.sum())
        res[lid] = n
        total += n
    return {"px": res, "ok": total <= th["max_px"]}


def plate_to_master(hand: dict, master_size: tuple[int, int]):
    """A function (x percent, y percent of the plate) -> master pixels. Home's plate is the master; Çağlayan's
    landscape plates sit on the portrait master at `portraitFrame` (`tools/plate/portrait.py`)."""
    w, h = master_size
    f = hand.get("portraitFrame")
    if not f:
        return lambda x, y: (x / 100 * w, y / 100 * h)
    k = w / f["size"][0]
    pw, ph = hand.get("size", (1536, 1024))
    return lambda x, y: ((x / 100 * pw) * f["scale"] * k + f["offset"][0] * k, (y / 100 * ph) * f["scale"] * k + f["offset"][1] * k)


def region_masks(man: dict, frame: dict, island_alpha: np.ndarray, hand: dict) -> dict:
    """Sky and lawn regions in screen pixels: lawn is the walkable polygon (objects.json, percent of
    the plate); sky is everything above the sea top that the island does not cover."""
    w, h = man["size"]
    scr = frame["screen"]
    k = frame["k"]
    c = 1 / k
    yy, xx = np.mgrid[0:scr[1], 0:scr[0]].astype(np.float32)
    py, px = frame["y0"] + yy * k, frame["x0"] + xx * k
    sky = (island_alpha < 0.01) & (py >= 0) & (py < man["seaTop"] - 100)
    sky &= cv2.erode((island_alpha > 0.01).astype(np.uint8), np.ones((9, 9), np.uint8)) == 0
    lawn = np.zeros(scr[::-1], np.uint8)
    to_master = plate_to_master(hand, (w, h))
    for poly in [hand["walkable"]] if hand.get("walkable") else []:
        pts = np.array([[(to_master(x, y)[0] - frame["x0"]) * c, (to_master(x, y)[1] - frame["y0"]) * c] for x, y in poly], np.int32)
        cv2.fillPoly(lawn, [pts], 1)
    return {"sky": sky, "lawn": lawn > 0}


def luminance(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return lin @ np.array([0.2126, 0.7152, 0.0722])


def ambient_ratio(frame: np.ndarray, masks: dict) -> float:
    y = luminance(frame)
    return float(y[masks["sky"]].mean() / max(y[masks["lawn"]].mean(), 1e-6))


def check_colour(frames: dict[int, np.ndarray], master: np.ndarray, covered: np.ndarray, masks: dict, th: dict) -> dict:
    keep = covered

    def metrics(img):
        px = np.clip(img[keep] / 255, 0, 1)
        return colour_metrics.metrics(px[:: max(len(px) // 400_000, 1)])
    ref = metrics(master)
    r_master = ambient_ratio(master, masks)
    res, ok = {}, True
    for t, fr in frames.items():
        m = metrics(fr)
        fl = colour_metrics.flags(m, ref)
        ratio = ambient_ratio(fr, masks)
        off = ratio / r_master - 1
        res[str(t)] = {"flags": fl, "ambient_ratio": round(ratio, 4), "ratio_off": round(off, 4),
                       "L_p50": m["L"]["p50"], "C_p90": m["C"]["p90"]}
        ok &= (not fl) and abs(off) <= th["ratio_tol"]
    return {"master_ratio": round(r_master, 4), "master_C_p90": ref["C"]["p90"], "t": res, "ok": bool(ok)}


def row_detail(frame: np.ndarray) -> np.ndarray:
    """Per row: mean gradient magnitude of the luminance (0..1), after a 1 px blur."""
    y = cv2.GaussianBlur(luminance(frame).astype(np.float32), (0, 0), 1.0)
    gx = cv2.Sobel(y, cv2.CV_32F, 1, 0, ksize=3) / 8
    gy = cv2.Sobel(y, cv2.CV_32F, 0, 1, ksize=3) / 8
    return np.hypot(gx, gy).mean(1)


def longest_dead_run(frame: np.ndarray, floor: float) -> float:
    dead = row_detail(frame) < floor
    best = run = 0
    for d in dead:
        run = run + 1 if d else 0
        best = max(best, run)
    return best / len(dead)


def check_dead(frame: np.ndarray, th: dict) -> dict:
    share = longest_dead_run(frame, th["row_detail"])
    return {"longest_run_share": round(share, 4), "ok": share <= th["max_run_share"]}


def check_dead_vs_master(frame: np.ndarray, master: np.ndarray, th: dict) -> dict:
    """The split must not add dead rows to the painting: its longest run within `over_master` of the master's."""
    share, ref = longest_dead_run(frame, th["row_detail"]), longest_dead_run(master, th["row_detail"])
    return {"longest_run_share": round(share, 4), "master": round(ref, 4),
            "ok": share <= th["max_run_share"] and share <= ref + th["over_master"]}


def check_life(f0: np.ndarray, f2: np.ndarray, island_alpha: np.ndarray, th: dict) -> dict:
    diff = np.abs(f2 - f0).mean(-1)
    solid = cv2.erode((island_alpha > 0.99).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
    sky = island_alpha < 0.01
    sky_d = float(diff[sky].mean())
    isl_d = float(diff[solid].max()) if solid.any() else 0.0
    return {"sky_mean_abs": round(sky_d, 3), "island_max_abs": round(isl_d, 4),
            "ok": sky_d > th["sky_floor"] and isl_d <= th["island_max"]}


def check_resolution(frame: dict, th: dict) -> dict:
    spp = frame["k"]                      # source (plate) px per screen px
    return {"source_per_screen": round(spp, 3), "ok": spp >= th["min_source_per_screen"]}


def check_frame(frame: np.ndarray, master: np.ndarray, covered: np.ndarray, island_alpha: np.ndarray,
                masks: dict, th: dict = THRESHOLDS) -> dict:
    """Identity, colour and dead composition on one frame (a CI screenshot, say) against the master."""
    return {"identity": check_identity(frame, master, covered, th["identity"]),
            "colour": check_colour({0: frame}, master, covered, masks, th["colour"]),
            "dead": check_dead(frame, th["dead"])}


# ---------------------------------------------------------------- sky checks (mirror, straight edges, ghosts)

def check_mirror(frame: np.ndarray, plate_bottom: int, th: dict, limit: int | None = None) -> dict:
    """No mirror image past the plate: the rows below its bottom edge must not be the rows above it
    flipped. `ratio` is the mean absolute difference of the flipped rows against the rows below,
    over the same against the flipped rows moved 311 px sideways (the control a plain texture
    scores about 1 on); a mirror scores near 0. `limit` is the last usable row (CI frames end in chrome)."""
    h = frame.shape[0] if limit is None else min(limit, frame.shape[0])
    n = min(th["rows"], plate_bottom, h - plate_bottom)
    if n < th["min_rows"]:
        return {"rows": max(n, 0), "ratio": None, "ok": True, "note": "no rows past the plate"}
    above = frame[plate_bottom - n: plate_bottom][::-1]
    below = frame[plate_bottom: plate_bottom + n]
    d = float(np.abs(above - below).mean())
    control = float(np.abs(np.roll(above, 311, axis=1) - below).mean())
    ratio = d / max(control, 1e-6)
    return {"rows": n, "ratio": round(ratio, 3), "ok": ratio >= th["ratio_min"]}


def check_sky_edges(sky: np.ndarray, th: dict) -> dict:
    """Stripes and straight box edges in a sky-only frame, over the rows above the island: the column
    means (and the row means) of the luminance, minus their own smooth version (Gaussian sigma 6 and 8),
    must stay within `col_hp` and `row_hp` grey levels. A smooth gradient has only its 8-bit contours;
    a stripe or the edge of a filled box (the first night's moon rectangle) is a step many rows long.
    Stars are median-filtered away first."""
    top = sky[: int(sky.shape[0] * th["band"])]
    lum = cv2.medianBlur(np.uint8(np.clip(luminance(top) ** (1 / 2.2), 0, 1) * 255 + 0.5), 5).astype(np.float32)
    cols = lum.mean(0)
    rows = lum.mean(1)
    hp_c = np.abs(cols - ndimage.gaussian_filter1d(cols, 6))[18:-18]       # the filter's own edge effect is cut off
    hp_r = np.abs(rows - ndimage.gaussian_filter1d(rows, 8))[24:-24]
    return {"col_hp": round(float(hp_c.max()), 3), "row_hp": round(float(hp_r.max()), 3),
            "ok": bool(hp_c.max() <= th["col_hp"] and hp_r.max() <= th["row_hp"])}


def check_ghosts(below: np.ndarray, above: np.ndarray, th: dict) -> dict:
    """Doubled points: `below` is the still sky (gradient, moon, stars), `above` the same with the
    drifting layers over it. A small compact patch that the drifting layers add within `radius` px of a
    star of the sky is that star's ghost (residue of the star left in a cloud layer)."""
    lum = luminance(below)
    sm = cv2.medianBlur(np.uint8(np.clip(lum ** (1 / 2.2), 0, 1) * 255 + 0.5), 15).astype(np.float32)
    stars_lab, n = ndimage.label(((np.uint8(np.clip(lum ** (1 / 2.2), 0, 1) * 255 + 0.5) - sm) > 10))
    centres = [ndimage.center_of_mass(stars_lab == i) for i in range(1, n + 1) if (stars_lab == i).sum() <= 120]
    added = de_map(above, below) > 2.0
    lab, m = ndimage.label(added)
    ghosts = 0
    for i in range(1, m + 1):
        comp = lab == i
        area = int(comp.sum())
        if area > th["max_area"] or area < th["min_area"]:
            continue
        cy, cx = ndimage.center_of_mass(comp)
        if any(np.hypot(cy - sy, cx - sx) <= th["radius"] for sy, sx in centres):
            ghosts += 1
    return {"stars": len(centres), "ghost_points": ghosts, "ok": ghosts <= th["max_points"]}


def check_speckle(layers: dict, th: dict) -> dict:
    """Noise in the cloud and sprite layers: isolated small pieces of faint alpha. A piece is a connected region of
    alpha above `floor` no larger than `max_area` px whose strongest alpha stays under `max_alpha`; a matte that has
    them shows crumbs and dots round a cloud once the layer drifts or is copied. Counted over `layers`
    ({id: straight RGBA 0..1})."""
    res, total = {}, 0
    for lid, rgba in layers.items():
        a = rgba[..., 3]
        lab, n = ndimage.label(a > th["floor"])
        if n == 0:
            res[lid] = 0
            continue
        area = np.bincount(lab.ravel(), minlength=n + 1)[1:]
        peak = np.asarray(ndimage.maximum(a, lab, range(1, n + 1)))
        bad = int(((area <= th["max_area"]) & (peak < th["max_alpha"])).sum())
        res[lid] = bad
        total += bad
    return {"pieces": res, "total": total, "ok": total <= th["max_pieces"]}


def check_dark_halo(sky_rgb: np.ndarray, layers: list[tuple[np.ndarray, tuple[int, int]]], th: dict) -> dict:
    """Boxes behind clouds: a cloud layer's soft edge is its colour over the sky field it was unmixed against, so its
    straight colour is never darker than that field. Where the layer was cut against a different sky (a hole-filled or
    locally adapted one), the halo carries the other sky's colour and shows as a faint darker-blue patch once the cloud
    drifts off it. Counts pixels with alpha in (`lo`, `hi`) whose luminance is below the field's by `dark`.
    `sky_rgb` is the sky field on the master's pixels (0..1); `layers` are (straight RGBA at master size, top-left)."""
    bad = 0
    for rgba, (x, y) in layers:
        h, w = rgba.shape[:2]
        ys0, xs0 = max(-y, 0), max(-x, 0)
        sub = rgba[ys0: ys0 + max(min(h, sky_rgb.shape[0] - y) - ys0, 0), xs0: xs0 + max(min(w, sky_rgb.shape[1] - x) - xs0, 0)]
        if sub.size == 0:
            continue
        sk = sky_rgb[y + ys0: y + ys0 + sub.shape[0], x + xs0: x + xs0 + sub.shape[1]]
        a = sub[..., 3]
        mask = (a > th["lo"]) & (a < th["hi"]) & (sky_rgb.shape[0] > 0)
        # only above the cloud sea: there the field is the whole story
        dark = (luminance(sub[..., :3] * 255) < luminance(sk * 255) - th["dark"]) & mask
        bad += int(dark.sum())
    return {"px": bad, "ok": bad <= th["max_px"]}


def check_horizontal_line(frame: np.ndarray, rows: tuple[int, int], th: dict) -> dict:
    """A straight horizontal line across the cloud sea: the mean absolute luminance step between a row and the next,
    over the whole width, against the median of the rows around it. Clouds have steps that vary along a row and
    average out; a seam (two pictures meeting, a block row) steps by the same amount all along it. `ratio` is the
    worst row's step over its neighbours' median, `excess` its step above that median in grey levels."""
    y = cv2.GaussianBlur(np.clip(luminance(frame) ** (1 / 2.2), 0, 1).astype(np.float32) * 255, (0, 0), 0.8)
    d = np.abs(np.diff(y, axis=0)).mean(1)
    r0, r1 = max(rows[0], th["window"]), min(rows[1], len(d) - th["window"])
    worst, at, exc = 0.0, r0, 0.0
    for r in range(r0, r1):
        near = np.r_[d[r - th["window"]: r - 1], d[r + 2: r + th["window"]]]
        base = float(np.median(near))
        ratio = float(d[r] / max(base, 0.05))
        if ratio > worst:
            worst, at, exc = ratio, r, float(d[r] - base)
    return {"row": int(at), "ratio": round(worst, 2), "excess": round(exc, 2),
            "ok": not (worst > th["ratio_max"] and exc > th["excess_max"])}


def check_dark_halo_set(s: dict, th: dict) -> dict:
    """`check_dark_halo` on a loaded shipped set (`skyset_render.load`): the sky layer stretched to its size, the far and mid
    layers at theirs (not the isles, whose greenery is darker than any sky), above `rows` master rows."""
    master_w, master_h = s["master"]
    sky = next(l for l in s["layers"] if l["role"] == "sky")
    ox, oy = (int(round(v)) for v in sky["pos"])
    field = cv2.resize(sky["rgba"][..., :3], (int(round(sky["size"][0])), int(round(sky["size"][1]))), interpolation=cv2.INTER_LINEAR)
    canvas = np.zeros((master_h, master_w, 3), np.float32)
    ys0, xs0 = max(-oy, 0), max(-ox, 0)
    part = field[ys0: ys0 + master_h - max(oy, 0), xs0: xs0 + master_w - max(ox, 0)]
    canvas[max(oy, 0): max(oy, 0) + part.shape[0], max(ox, 0): max(ox, 0) + part.shape[1]] = part
    placed = []
    for l in s["layers"]:
        if l["role"] != "tile" or l["id"] == "sea":
            continue
        w, h = int(round(l["size"][0])), int(round(l["size"][1]))
        big = cv2.resize(l["rgba"], (w, h), interpolation=cv2.INTER_LINEAR)
        top = int(round(l["pos"][1]))
        keep = max(min(h, th["rows"] - top), 0)
        placed.append((big[:keep, :master_w], (int(round(l["pos"][0])), top)))
    return check_dark_halo(canvas, placed, th)


def run_sky(island: str, light: str, th: dict = SKY_THRESHOLDS) -> dict:
    """The three checks on the shipped sky set rendered by `skyset_render` (the app's layers and motion):
    the rows past the plate at t = 0 and 3 s, the sky layer alone, and the stars' ghosts at t = 0 and 60 s."""
    import skyset_render as rd
    s = rd.load(island, light)
    fr = framing(s["manifest"])
    h = s["manifest"]["size"][1]
    bottom = int(round((h - fr["y0"]) / fr["k"]))
    ids = [layer["id"] for layer in s["layers"]]
    out: dict = {"light": light}
    out["mirror"] = {t: check_mirror(rd.render(s, t, fr), bottom, th["mirror"]) for t in (0, 3)}
    out["mirror"]["ok"] = all(v["ok"] for v in out["mirror"].values())
    top = int(round(-fr["y0"] / fr["k"]))              # rows above the master (the picture runs on up: Çağlayan)
    if top > th["mirror"]["min_rows"]:
        sky_top = {t: rd.render(s, t, fr) for t in (0, 3)}
        out["mirror_top"] = {t: check_mirror(f[::-1], f.shape[0] - top, th["mirror"]) for t, f in sky_top.items()}
        out["mirror_top"]["ok"] = all(v["ok"] for v in out["mirror_top"].values())
    out["sky_edges"] = check_sky_edges(rd.render(s, 0, fr, upto="sky"), th["sky_edges"])
    last_still = [i for i in ids if i.startswith("stars") or i in ("sky", "moon")][-1]
    ghosts = {}
    for t in (0, 60):                  # the stars twinkle with t: compare at the same time
        below = rd.render(s, t, fr, upto=last_still)
        ghosts[t] = check_ghosts(below, rd.render(s, t, fr, upto="far"), th["ghosts"]) if "far" in ids else {"ok": True}
    out["ghosts"] = {**{str(t): v for t, v in ghosts.items()}, "ok": all(v["ok"] for v in ghosts.values())}
    cloud = {l["id"]: l["rgba"] for l in s["layers"] if l["role"] in ("tile", "sprite", "whale")}
    out["speckle"] = check_speckle(cloud, th["speckle"])
    out["dark_halo"] = check_dark_halo_set(s, th["dark_halo"])
    sea_top = int(round((s["manifest"]["islandBox"][3] - fr["y0"]) / fr["k"])) + 40    # below the island's lowest root
    out["sea_line"] = {t: check_horizontal_line(rd.render(s, t, fr), (sea_top, SCREEN[1] - 4), th["sea_line"]) for t in (0, 3)}
    out["sea_line"]["ok"] = all(v["ok"] for v in out["sea_line"].values())
    # speckle is enforced where the hand data sets an `alphaFloor` (Çağlayan); Home's sets are older and only reported
    hand_sky = json.loads((PLATES / island / "sky" / "sky.json").read_text())
    keys = ["mirror", "mirror_top", "sky_edges", "ghosts", "sea_line"] + (["speckle", "dark_halo"] if hand_sky.get("alphaFloor") else [])
    out["ok"] = all(out[k]["ok"] for k in keys if k in out)
    return out


# ---------------------------------------------------------------- CI frames

def set_lights(island: str) -> list[str]:
    """The lights an island has a split sky set for (Home: day, golden, night; Çağlayan: day)."""
    return [l for l in ("day", "golden", "night") if (PLATES / island / "sky" / l / "manifest.json").exists()]


def ci_states(island: str) -> list[tuple[str, str]]:
    """(light, the CI frame's name) per state with a sky set: Home's three level-10 lights; Çağlayan's day at its five
    story stages (`caglayan-plate-full-s<stage>-day.png`)."""
    if island == "home":
        return [(l, f"home-plate-full-l10-{l}.png") for l in set_lights(island)]
    return [("day", f"{island}-plate-full-s{n}-day.png") for n in range(5)]


def plate_rows(man: dict, hand: dict, fr: dict, screen_h: int) -> tuple[int, int]:
    """The screen rows the previous build's plate covered: Home's plate is the master; Çağlayan's landscape plate
    is a band of it (`portraitFrame`)."""
    w, h = man["size"]
    f = hand.get("portraitFrame")
    if f:
        k = w / f["size"][0]
        pw, ph = hand.get("size", (1536, 1024))
        top = f["offset"][1] * k
        bottom = top + ph * f["scale"] * k
    else:
        top, bottom = 0, h
    r0 = int(round((top - fr["y0"]) / fr["k"]))
    r1 = int(round((bottom - fr["y0"]) / fr["k"]))
    return max(r0, 0), min(r1, screen_h)


def _read(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), np.float32)


def check_ci(island: str, light: str, frame: np.ndarray, before: np.ndarray, th: dict = THRESHOLDS) -> dict:
    """A CI screenshot of the sky-set build against the plate-only build's frame of the same state:
    frame-zero identity (mean and p99 dE2000 over the whole frame, chrome included: it is the same in
    both), colour (the sky-to-lawn ratio and the pale / hot flags), dead composition (no more than the
    previous frame's own, `check_dead_vs_master`) and resolution. The regions come from the shipped
    set composited at the Home framing."""
    set_dir = PLATES / island / "sky" / light
    s = load_set(set_dir)
    man = s["manifest"]
    hand = json.loads((PLATES / island / "objects.json").read_text())
    fr = framing(man, hand["framing"], (frame.shape[1], frame.shape[0]))
    out: dict = {"light": light, "frame": list(frame.shape[1::-1]), "before": list(before.shape[1::-1])}
    if frame.shape != before.shape:
        out["ok"] = False
        out["error"] = "the frames differ in size"
        return out
    comp = compose(s, 0, fr)
    covered = np.ones(frame.shape[:2], bool)
    masks = region_masks(man, fr, comp["island_alpha"], hand)
    out["identity"] = check_identity(frame, before, covered, th["identity"])
    # the rows the plate covered, the rows past it, and the island itself, apart: past the plate the two builds
    # paint different things (a calm sea, a repainted sky), and only the plate's rows are expected to match
    r0, r1 = plate_rows(man, hand, fr, frame.shape[0])
    on_plate = np.zeros(frame.shape[:2], bool)
    on_plate[r0:r1] = True
    dth = {"mean_de": 99, "p99_de": 99}
    out["plate_rows"] = [r0, r1]
    out["identity_plate_rows"] = check_identity(frame, before, on_plate, dth)
    out["identity_past_plate"] = check_identity(frame, before, ~on_plate, dth) if (~on_plate).any() else None
    isl = comp["island_alpha"] > 0.99
    out["identity_island"] = check_identity(frame, before, isl, dth) if isl.any() else None
    out["colour"] = check_colour({0: frame}, before, covered, masks, th["colour"])
    out["dead"] = check_dead_vs_master(frame, before, th["dead"])
    out["resolution"] = check_resolution(fr, th["resolution"])
    bottom = int(round((man["size"][1] - fr["y0"]) / fr["k"]))
    out["mirror"] = check_mirror(frame, bottom, SKY_THRESHOLDS["mirror"], limit=frame.shape[0])
    keys = ["colour", "dead", "resolution", "mirror"]
    if hand.get("portraitFrame"):
        # the build before drew a different picture past the plate: judge the island and the plate's rows
        ip = th["identity_plate"]
        out["identity_island"]["ok"] = bool(out["identity_island"]["mean_de"] < ip["island_mean_de"]
                                              and out["identity_island"]["p99_de"] < ip["island_p99_de"])
        out["identity_plate_rows"]["ok"] = bool(out["identity_plate_rows"]["mean_de"] < ip["rows_mean_de"]
                                                  and out["identity_plate_rows"]["p99_de"] < ip["rows_p99_de"])
        out["identity"]["ok"] = True                    # informational: the whole frame includes the new sky
        keys += ["identity_island", "identity_plate_rows"]
    else:
        keys.append("identity")
    out["ok"] = all(out[k]["ok"] for k in keys)
    return out


def run_ci(island: str, frames_dir: Path, before_dir: Path, th: dict = THRESHOLDS) -> dict:
    res = {}
    for light, name in ci_states(island):
        key = name.removeprefix(f"{island}-plate-full-").removesuffix(".png") if island != "home" else light
        if not (frames_dir / name).exists() or not (before_dir / name).exists():
            res[key] = {"light": light, "ok": False, "error": f"{name} is missing"}
            continue
        res[key] = check_ci(island, light, _read(frames_dir / name), _read(before_dir / name), th)
    return res


# ---------------------------------------------------------------- the whole check

def run(island: str, light: str, set_dir: Path | None = None, plate: np.ndarray | None = None,
        th: dict = THRESHOLDS, frames_dir: Path | None = None) -> dict:
    set_dir = set_dir or PLATES / island / "sky" / light
    s = load_set(set_dir)
    man = s["manifest"]
    hand = json.loads((PLATES / island / "objects.json").read_text())
    if plate is None:
        p = heic.open_image(ROOT / man["source"]["plate"]).convert("RGB")
        plate = np.asarray(p, np.float32)
        plate[:2] = plate[2]
        plate[:, :2] = plate[:, 2:3]
        plate[:, -2:] = plate[:, -3:-2]
    fr = framing(man, hand["framing"])
    comps = {t: compose(s, t, fr) for t in TIMES}
    comps[2] = compose(s, 2, fr)
    master = master_frame(s, plate, fr)
    f0 = comps[0]
    masks = region_masks(man, fr, f0["island_alpha"], hand)
    out = {"light": light, "frame": {"k": round(fr["k"], 4), "x0": round(fr["x0"], 1), "y0": round(fr["y0"], 1)}}
    out["identity"] = check_identity(f0["rgb"], master, f0["covered"], th["identity_portrait" if hand.get("portraitFrame") else "identity"])
    out["seam"] = check_seam({t: comps[t]["rgb"] for t in TIMES}, f0["island_alpha"], th["seam"])
    out["blocks"] = check_blocks({t: comps[t]["rgb"] for t in TIMES}, f0["island_alpha"], th["seam"], f0["covered"])
    out["leak"] = check_leaks(s, th["leak"])
    out["colour"] = check_colour({t: comps[t]["rgb"] for t in TIMES}, master, f0["covered"], masks, th["colour"])
    if hand.get("portraitFrame"):
        # the picture runs on past the master (above and below): the dead-composition check reads the shipped set
        # as the app draws it, `skyset_render`, not the split's own layers (whose gradient only repeats its edge rows)
        import skyset_render as rd
        # the gradient beyond the master is meant to be plain: only the rows the master covers count
        shown = rd.render(rd.load(island, light), 0, fr)
        r0, r1 = plate_rows(man, {}, fr, shown.shape[0])
        out["dead"] = check_dead(shown[r0:r1], th["dead"])
    else:
        out["dead"] = check_dead_vs_master(f0["rgb"], master, th["dead"])
    out["life"] = check_life(f0["rgb"], comps[2]["rgb"], f0["island_alpha"], th["life"])
    out["resolution"] = check_resolution(fr, th["resolution"])
    out["ok"] = all(out[k]["ok"] for k in ("identity", "seam", "blocks", "leak", "colour", "dead", "life", "resolution"))
    if frames_dir:
        frames_dir.mkdir(parents=True, exist_ok=True)
        for t in TIMES:
            Image.fromarray(np.uint8(comps[t]["rgb"] + 0.5)).save(frames_dir / f"{light}-t{t}.png")
        Image.fromarray(np.uint8(master + 0.5)).save(frames_dir / f"{light}-master.png")
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("light", nargs="?", default="all")
    ap.add_argument("--json", help="write the results here")
    ap.add_argument("--frames", help="also save the composited frames (png) here; with `ci`, the CI frames")
    ap.add_argument("--before", help="with `ci`: the plate-only build's CI frames")
    a = ap.parse_args(argv)
    if a.light == "sky":
        res = {l: run_sky(a.island, l) for l in set_lights(a.island)}
        print(json.dumps(res, indent=1))
        if a.json:
            Path(a.json).write_text(json.dumps({"thresholds": SKY_THRESHOLDS, "sky": res}, indent=1) + "\n")
        return 0 if all(r["ok"] for r in res.values()) else 1
    if a.light == "ci":
        if not (a.frames and a.before):
            ap.error("ci needs --frames and --before")
        res = run_ci(a.island, Path(a.frames), Path(a.before))
        print(json.dumps(res, indent=1))
        if a.json:
            Path(a.json).write_text(json.dumps({"thresholds": THRESHOLDS, "ci": res}, indent=1) + "\n")
        return 0 if all(r["ok"] for r in res.values()) else 1
    lights = set_lights(a.island) if a.light == "all" else [a.light]
    res = {}
    code = 0
    for light in lights:
        r = run(a.island, light, frames_dir=Path(a.frames) if a.frames else None)
        res[light] = r
        print(json.dumps({k: v for k, v in r.items()}, indent=1))
        code |= 0 if r["ok"] else 1
    if a.json:
        Path(a.json).write_text(json.dumps({"thresholds": THRESHOLDS, "screen": list(SCREEN), "times": list(TIMES),
                                            "drift": DRIFT, "lights": res}, indent=1) + "\n")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
