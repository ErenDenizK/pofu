"""Edits `skyset_export.py` makes to an island's sky set where the screen shows more than the master (Çağlayan).

The screen at Çağlayan's stop is about 1.03 master widths and 1.5 master heights, so the picture runs on past the
master: above it (about 1000 master px of sky), at both sides (the drift tiles' bridge) and, as the clouds drift,
behind the island. Every edit here is made from the sky set's own pixels; the takes are never touched.

  mirror_bridge  the drift tiles' bridge (the columns past the painting that close the wrap) becomes the painting's
                 own edge columns, mirrored, cross-faded in its middle: at rest the screen's edge strips run on from
                 the painting with no seam and no quilted fragments
  fill_hidden    the colour the split painted behind the island (it never shows at rest, but drifts into view at
                 the screen's edges and beside the belly: murk, island green, quilted fragments) becomes the sea's own
                 cumulus from straight below the island; `clear_hidden` fades the mid clouds behind it instead
  top_clouds     the far layer runs on up to the top of the screen: whole clouds of the far layer itself, each
                 lifted, maybe flipped and a little smaller, scattered without overlap over the sky above the master
  extend_rows    a still star field (the night's painted stars) continued up the same way, flipped and shifted
  moon_zone      the night's moon box: the cloud the split left in the still sky inside the box goes back to the
                 far layer, measured against the moon and the sky actually drawn there, so no stepped notch shows
                 where the moon's glow sprite ends
"""
from __future__ import annotations

import cv2
import numpy as np
from scipy import ndimage

import split


def _pre(arr: np.ndarray) -> np.ndarray:
    out = arr.copy()
    out[..., :3] *= out[..., 3:4]
    return out


def _straight(pre: np.ndarray) -> np.ndarray:
    a = pre[..., 3:4].clip(0, 1)
    rgb = np.where(a > 1e-4, pre[..., :3] / np.maximum(a, 1e-4), 0).clip(0, 1)
    return np.concatenate([rgb, a], -1).astype(np.float32)


def mirror_bridge(arr: np.ndarray, paint_w: int, blend: int = 48) -> np.ndarray:
    """`arr` (straight RGBA, the tile: the painting's `paint_w` columns then the bridge) with the bridge replaced by
    the painting's right edge mirrored (its first half) and the painting's left edge mirrored (its second half),
    cross-faded over `blend` columns in its middle (premultiplied), so the tile wraps with no seam."""
    h, w = arr.shape[:2]
    bridge = w - paint_w
    if bridge <= 0:
        return arr
    pre = _pre(arr)
    j = np.arange(bridge)
    right = pre[:, paint_w - 1 - np.minimum(j, paint_w - 1)]          # x = paint_w + j mirrors paint_w - 1 - j
    left = pre[:, np.minimum(bridge - 1 - j, paint_w - 1)]             # x = w - 1 - k mirrors column k
    mid = bridge / 2
    wgt = split.smoothstep(mid - blend / 2, mid + blend / 2, j.astype(np.float32))[None, :, None]
    out = pre.copy()
    out[:, paint_w:] = right * (1 - wgt) + left * wgt
    return _straight(out)


def cloud_pieces(arr: np.ndarray, paint_w: int, top_clear: int, min_area: int = 1500, max_w: int = 760,
                 forbid: np.ndarray | None = None) -> list[np.ndarray]:
    """Whole clouds of a cloud layer (straight RGBA): connected alpha over 0.03, inside the painting's columns, clear
    of its first `top_clear` rows (where the layer fades in), of its last rows and of `forbid` (the island at rest,
    behind which the split painted the clouds), cropped with their soft edge."""
    a = arr[..., 3]
    lab, n = ndimage.label(cv2.dilate((a > 0.03).astype(np.uint8), np.ones((5, 5), np.uint8)))
    out = []
    for i, sl in enumerate(ndimage.find_objects(lab), 1):
        if sl is None:
            continue
        ys, xs = sl
        if ys.start < top_clear or ys.stop >= a.shape[0] - 4 or xs.start < 4 or xs.stop > paint_w - 4:
            continue
        if xs.stop - xs.start > max_w:
            continue
        m = lab[sl] == i
        if forbid is not None and (forbid[sl] & m).any():
            continue
        if (a[sl] * m).sum() < min_area:
            continue
        piece = arr[sl].copy()
        piece[..., 3] *= cv2.GaussianBlur(m.astype(np.float32), (0, 0), 1.0)
        out.append(np.pad(piece, ((6, 6), (6, 6), (0, 0))))
    return out


def top_clouds(arr: np.ndarray, pos: tuple[int, int], top_y: int, paint_w: int, top_clear: int, seed: int = 7,
               cover: float = 0.20, avoid: list[tuple[float, float, float]] | None = None,
               scale: tuple[float, float] = (1.0, 1.35), extra: list[np.ndarray] | None = None,
               clear_top: int = 0) -> tuple[np.ndarray, tuple[int, int]]:
    """The far tile `arr` (straight RGBA at `pos`) run on up to master row `top_y`: whole clouds of its own
    (`cloud_pieces`), each scaled by a factor in `scale` and flipped at random, scattered (periodic in x) without
    touching each other or the layer's own clouds (`extra`: more whole clouds, the mid layer's) until their alpha covers `cover` of the new rows; `avoid` lists
    discs (x, y, r) in master px a cloud must not cover at rest (the moon). The first `clear_top` new rows stay
    open sky (as Home's sky is above its isles: clouds thin out towards the zenith). Returns the taller tile and its pos."""
    h, w = arr.shape[:2]
    x0, y0 = pos
    add = y0 - top_y
    if add <= 0:
        return arr, pos
    rng = np.random.default_rng(seed)
    pieces = cloud_pieces(arr, paint_w, top_clear) + list(extra or [])
    if not pieces:
        return arr, pos
    out = np.concatenate([np.zeros((add, w, 4), np.float32), arr], 0)
    pre = _pre(out)
    taken = cv2.dilate((out[..., 3] > 0.02).astype(np.uint8), np.ones((61, 61), np.uint8)) > 0
    area = add * w
    got, tries = 0.0, 0
    # each cloud is used once before any is used again, the bigger ones first in each round (a sky of many small
    # copies of one puff reads as wallpaper)
    order: list[int] = []
    sizes = np.array([float(pc[..., 3].sum()) for pc in pieces])
    while got < cover * area and tries < 4000:
        tries += 1
        if not order:
            order = list(np.argsort(-(sizes * rng.uniform(0.5, 1.5, len(sizes))))[::-1])
        p = pieces[order.pop()]
        f = rng.uniform(*scale)
        fx, fy = f * rng.uniform(0.85, 1.25), f * rng.uniform(0.9, 1.1)     # stretched a little, each copy its own shape
        q = cv2.resize(_pre(p), (max(int(p.shape[1] * fx), 8), max(int(p.shape[0] * fy), 8)),
                       interpolation=cv2.INTER_AREA if fx < 1 else cv2.INTER_LINEAR)
        if rng.random() < 0.5:
            q = q[:, ::-1]
        ph, pw = q.shape[:2]
        # the piece's bottom stays above the old layer's faded top rows plus a little, its top below top_y
        y = int(rng.integers(clear_top, max(add + top_clear // 2 - ph, clear_top + 1)))
        x = int(rng.integers(0, w))
        cols = (x + np.arange(pw)) % w
        rows = slice(y, y + ph)
        if rows.stop > out.shape[0]:
            continue
        mask = q[..., 3] > 0.02
        if (taken[rows][:, cols] & mask).any():
            continue
        if avoid:
            cy, cx = np.mgrid[y: y + ph, 0:pw]
            hit = False
            for ax, ay, ar in avoid:
                dx = (x + cx - (ax - x0) + w / 2) % w - w / 2
                if (mask & (np.hypot(dx, cy - (ay - top_y)) < ar)).any():
                    hit = True
                    break
            if hit:
                continue
        region = pre[rows][:, cols]
        a = q[..., 3:4]
        pre[rows, cols] = q + region * (1 - a)
        grown = cv2.dilate(mask.astype(np.uint8), np.ones((61, 61), np.uint8)) > 0
        t = taken[rows][:, cols] | grown
        taken[rows, cols] = t
        got += float(q[..., 3].sum())
    return _straight(pre), (x0, top_y)


def extend_rows(field: np.ndarray, rows: int) -> np.ndarray:
    """A sparse field (stars: light above the sky, H x W x C) continued `rows` rows upward: its own rows flipped
    left to right, then (past its height) shifted by half the width, so no star is repeated where it can be
    compared with itself. Returns the `rows` new rows (farthest first)."""
    h, w = field.shape[:2]
    out = np.zeros((rows,) + field.shape[1:], field.dtype)
    flip = field[:, ::-1]
    n = min(rows, h)
    out[rows - n:] = flip[h - n:]
    k = rows - n
    while k > 0:
        m = min(k, h)
        out[k - m: k] = np.roll(field, w // 2, axis=1)[h - m:]
        k -= m
    return out


def moon_far(plate: np.ndarray, still: np.ndarray, far: np.ndarray, fpos: tuple[int, int], centre: tuple[float, float],
             r_disc: float, r_zone: float, k: float, box: tuple[int, int, int, int] | None = None) -> np.ndarray:
    """The far layer (straight RGBA at `fpos`) round the moon, rebuilt against the still picture actually drawn
    there (`still`: the sky and the moon sprite, master-sized): its alpha is the painting's difference from
    `still` (`split`'s rule, clouds only lighten), its colour unmixed; outside `r_zone` (and the `box`, dilated) the
    layer is kept, with a soft hand-over between. The moon's disc (`r_disc`) stays sky."""
    fh, fw = far.shape[:2]
    fx, fy = fpos
    cx, cy = centre
    H, W = plate.shape[:2]
    ys0, ys1 = max(fy, 0), min(fy + fh, H)
    xs1 = min(W, fx + fw)
    yy, xx = np.mgrid[ys0:ys1, fx:xs1].astype(np.float32)
    r = np.hypot(xx - cx, yy - cy)
    zone = (r < r_zone).astype(np.float32)
    if box is not None:
        bx0, by0, bx1, by1 = box
        zone = np.maximum(zone, ((xx >= bx0 - 40) & (xx < bx1 + 40) & (yy >= by0 - 40) & (yy < by1 + 40)).astype(np.float32))
    zone = cv2.GaussianBlur(cv2.erode(zone, np.ones((31, 31), np.uint8)), (0, 0), 10)
    p = plate[ys0:ys1, fx:xs1]
    s = still[ys0:ys1, fx:xs1]
    d = np.linalg.norm(p - s, axis=-1)
    ca = cv2.GaussianBlur(((d - 0.012) / k).clip(0, 1), (0, 0), 1.0)
    ca = np.where(split.lum(p) < split.lum(s) - 0.004, 0, ca)
    ca = ca * split.smoothstep(r_disc + 2, r_disc + 14, r)
    col = split.unmix(p, s, np.maximum(ca, 1e-6))
    new = _pre(np.concatenate([col, ca[..., None]], -1).astype(np.float32))
    old = _pre(far[ys0 - fy: ys1 - fy, : xs1 - fx])
    z = zone[..., None]
    pre_all = _pre(far)
    pre_all[ys0 - fy: ys1 - fy, : xs1 - fx] = new * z + old * (1 - z)
    return _straight(pre_all)


def fill_hidden(arr: np.ndarray, pos: tuple[int, int], hidden: np.ndarray, gap: int = 60,
                lo: float = 0.5, hi: float = 0.9) -> np.ndarray:
    """The cloud sea tile `arr` (straight RGBA at `pos`) with the colour the split painted behind the island (`hidden`,
    master-sized island alpha at rest: murk, island green, quilted fragments that drift into view at the screen's
    edges and beside the belly) replaced by the sea's own visible cumulus straight below the island (`gap` rows past
    its lowest hidden row), per pixel weighted by the island's alpha (`lo` to `hi`); the tile's alpha is kept."""
    h, w = arr.shape[:2]
    x0, y0 = pos
    hid = np.zeros((h, w), np.float32)
    H, W = hidden.shape
    ys0, ys1 = max(y0, 0), min(y0 + h, H)
    if ys1 <= ys0:
        return arr
    pw = min(W, w - x0)
    hid[ys0 - y0: ys1 - y0, x0: x0 + pw] = hidden[ys0:ys1, :pw]
    wgt = cv2.GaussianBlur(split.smoothstep(lo, hi, hid), (0, 0), 3)
    rows = np.flatnonzero((wgt > 0.01).any(1))
    if rows.size == 0:
        return arr
    shift = int(rows.max() - rows.min() + gap)
    if rows.max() + shift >= h:
        return arr
    src = np.clip(np.arange(h) + shift, 0, h - 1)
    rgb = arr[..., :3] * (1 - wgt[..., None]) + arr[src, :, :3] * wgt[..., None]
    return np.concatenate([rgb, arr[..., 3:4]], -1).astype(np.float32)


def clear_hidden(arr: np.ndarray, pos: tuple[int, int], hidden: np.ndarray, lo: float = 0.6, hi: float = 0.95,
                 soft: float = 10.0) -> np.ndarray:
    """A cloud tile with nothing below it to borrow from (the mid layer): its alpha behind the island at rest
    (`hidden` from `lo` to `hi`, softened by `soft` px) eases to nothing, so a cloud that drifts out from behind the
    island ends in a soft edge instead of the murk the split painted there."""
    h, w = arr.shape[:2]
    x0, y0 = pos
    hid = np.zeros((h, w), np.float32)
    H, W = hidden.shape
    ys0, ys1 = max(y0, 0), min(y0 + h, H)
    if ys1 <= ys0:
        return arr
    pw = min(W, w - x0)
    hid[ys0 - y0: ys1 - y0, x0: x0 + pw] = hidden[ys0:ys1, :pw]
    core = cv2.erode(split.smoothstep(lo, hi, hid), np.ones((int(2 * soft) + 1,) * 2, np.uint8))
    wgt = cv2.GaussianBlur(core, (0, 0), soft)
    out = arr.copy()
    out[..., 3] *= 1 - wgt
    return out


def clear_crumbs(arr: np.ndarray, boxes: list, min_alpha: float = 0.003) -> np.ndarray:
    """Delete whole cloud pieces from a tile layer: every connected piece of alpha (above `min_alpha`) that touches one
    of `boxes` ([x0, x1, y0, y1] in the layer's own pixels) goes. A box is a probe, not a mask: it names a piece by a
    few pixels inside it. This takes out the leftovers of the old island cut-out that the screen's edges still show,
    the mid layer's clouds cut by the plate's edge (a straight edge at the paint width, or a hole where the island was),
    without touching the clouds beside them."""
    if not boxes:
        return arr
    n, lab = cv2.connectedComponents((arr[..., 3] > min_alpha).astype(np.uint8), connectivity=8)
    drop = np.zeros(n, bool)
    for x0, x1, y0, y1 in boxes:
        drop[np.unique(lab[max(y0, 0): y1, max(x0, 0): x1])] = True
    drop[0] = False
    out = arr.copy()
    gone = drop[lab]
    out[gone] = 0
    return out
