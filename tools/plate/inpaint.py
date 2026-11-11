"""Exemplar inpainting for plate layers: a small multi-scale PatchMatch, numpy and OpenCV only.

Used by `split.py` to paint the part of the cloud sea (and sky) that the island hides, from the
visible cloud texture of the same painting, and to close a layer's horizontal wrap. It copies real
patches (no diffusion smear): every hole pixel is a vote of source patches that live entirely in the
known part of the image.

    inpaint(img, hole, periodic_x=True, y_window=350, seed=0) -> float32 image, known pixels untouched

`img` is (H, W, C) float with C <= 4 (RGB, or premultiplied RGB + alpha), `hole` a bool mask. The
source patches wrap round in x when `periodic_x` (the layers are drift tiles). `y_window` is a soft
preference for sources at the same height (a cloud sea thickens downward): beyond it a patch pays
a penalty that grows with the distance. Deterministic for a given `seed`.
"""
from __future__ import annotations

import cv2
import numpy as np

PATCH = 5
REUSE = 4e-3         # quilt: cost of a source per use of its pixels (per pixel and channel, SSD)
MAX_DC = 0.08        # quilt: largest brightness correction per block
CHUNK = 150_000
MAX_RADIUS = 160     # random-search reach per level (px); the pyramid covers the long jumps
WEIGHT_ALPHA = 2.0   # the fourth channel (alpha) counts double: structure first


def _wrap_pad(a: np.ndarray, p: int) -> np.ndarray:
    return np.concatenate([a[:, -p:], a, a[:, :p]], axis=1)


def _blur(a: np.ndarray, sigma: float, periodic: bool) -> np.ndarray:
    p = int(3 * sigma) + 1
    if periodic:
        p = min(p, a.shape[1] - 1)
        b = cv2.GaussianBlur(_wrap_pad(a, p), (0, 0), sigma)[:, p:-p]
    else:
        b = cv2.GaussianBlur(a, (0, 0), sigma)
    return b.reshape(a.shape)


def pull_push(img: np.ndarray, known: np.ndarray, periodic: bool) -> np.ndarray:
    """Smooth starting fill: known colour spread by normalised Gaussian blurs of growing width."""
    out = img.copy()
    todo = ~known
    kf = known.astype(np.float32)
    sigma = 2.0
    while todo.any() and sigma < 4 * max(img.shape[:2]):
        num = _blur(img * kf[..., None], sigma, periodic)
        den = _blur(kf, sigma, periodic)[..., None]
        ok = todo & (den[..., 0] > 1e-3)
        out[ok] = num[ok] / den[ok]
        todo &= ~ok
        sigma *= 2
    if todo.any():
        out[todo] = img[known].mean(0) if known.any() else 0
    return out


def _dilate(mask: np.ndarray, r: int, periodic: bool) -> np.ndarray:
    k = np.ones((2 * r + 1, 2 * r + 1), np.uint8)
    m = mask.astype(np.uint8)
    if periodic:
        return cv2.dilate(_wrap_pad(m, r), k)[:, r:-r].astype(bool)
    return cv2.dilate(m, k).astype(bool)


class _Matcher:
    def __init__(self, img, tgt, valid, k, ywin, ypen, cw, rng, periodic):
        self.h, self.w, self.c = img.shape
        self.tgt = tgt
        self.valid = valid
        self.k = k
        r = k // 2
        dy, dx = np.mgrid[-r:r + 1, -r:r + 1]
        self.dy, self.dx = dy.ravel(), dx.ravel()
        g = np.exp(-(self.dy ** 2 + self.dx ** 2) / (2 * (0.6 * k) ** 2))
        self.pw = (g / g.sum()).astype(np.float32)
        self.cw = cw
        self.ywin, self.ypen = ywin, ypen
        self.rng = rng
        self.periodic = periodic
        self.ty, self.tx = np.nonzero(tgt)
        self.vy, self.vx = np.nonzero(valid)

    def gather(self, flat, cy, cx):
        yy = np.clip(cy[:, None] + self.dy, 0, self.h - 1)
        xx = cx[:, None] + self.dx
        xx = xx % self.w if self.periodic else np.clip(xx, 0, self.w - 1)
        return flat[yy * self.w + xx]

    def cost(self, T, flat, sy, sx, ty):
        ok = self.valid[sy, sx]
        d = np.empty(len(sy), np.float32)
        for i in range(0, len(sy), CHUNK):  # chunked: a million patches of 25 pixels is a lot of RAM
            sl = slice(i, i + CHUNK)
            S = self.gather(flat, sy[sl], sx[sl])
            d[sl] = (((T[sl] - S) ** 2) * self.cw).sum(-1) @ self.pw
        if self.ypen:
            over = np.maximum(np.abs(sy - ty) - self.ywin, 0) / max(self.ywin, 1)
            d = d + self.ypen * over ** 2
        return np.where(ok, d, np.inf)

    def run(self, img, sy, sx, iters):
        """Refine the source map (sy, sx) at the target pixels; returns it and the cost."""
        flat = img.reshape(-1, self.c)
        ty, tx = self.ty, self.tx
        T = np.concatenate([self.gather(flat, ty[i:i + CHUNK], tx[i:i + CHUNK]) for i in range(0, len(ty), CHUNK)]) \
            if len(ty) else np.zeros((0, len(self.dy), self.c), np.float32)
        cur_y, cur_x = sy[ty, tx].copy(), sx[ty, tx].copy()
        best = self.cost(T, flat, cur_y, cur_x, ty)
        # fix invalid starts: best of several random valid sources
        bad = ~np.isfinite(best)
        for _ in range(6 if bad.any() else 0):
            n = bad.sum()
            pick = self.rng.integers(0, len(self.vy), n)
            c = self.cost(T[bad], flat, self.vy[pick], self.vx[pick], ty[bad])
            better = c < best[bad]
            idx = np.nonzero(bad)[0][better]
            cur_y[idx], cur_x[idx] = self.vy[pick][better], self.vx[pick][better]
            best[idx] = c[better]
            bad = ~np.isfinite(best)
        sy[ty, tx], sx[ty, tx] = cur_y, cur_x
        for it in range(iters):
            # propagation: a neighbour's source, shifted by the step between the two
            for ddy, ddx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                ny, nx = ty - ddy, (tx - ddx) % self.w if self.periodic else np.clip(tx - ddx, 0, self.w - 1)
                ny = np.clip(ny, 0, self.h - 1)
                has = self.tgt[ny, nx]
                cy = np.clip(sy[ny, nx] + ddy, 0, self.h - 1)
                cx = sx[ny, nx] + ddx
                cx = cx % self.w if self.periodic else np.clip(cx, 0, self.w - 1)
                c = np.where(has, self.cost(T, flat, cy, cx, ty), np.inf)
                better = c < best
                cur_y, cur_x, best = np.where(better, cy, cur_y), np.where(better, cx, cur_x), np.where(better, c, best)
                sy[ty, tx], sx[ty, tx] = cur_y, cur_x
            # random search around the current source, radius halving
            r = float(min(max(self.h, self.w), MAX_RADIUS))
            while r >= 1:
                cy = np.clip(cur_y + self.rng.integers(-int(r), int(r) + 1, len(ty)), 0, self.h - 1)
                cx = cur_x + self.rng.integers(-int(r), int(r) + 1, len(ty))
                cx = cx % self.w if self.periodic else np.clip(cx, 0, self.w - 1)
                c = self.cost(T, flat, cy, cx, ty)
                better = c < best
                cur_y, cur_x, best = np.where(better, cy, cur_y), np.where(better, cx, cur_x), np.where(better, c, best)
                r /= 2
            sy[ty, tx], sx[ty, tx] = cur_y, cur_x
        cost = np.zeros((self.h, self.w), np.float32)
        cost[ty, tx] = best
        return sy, sx, cost

    def vote(self, img, sy, sx, cost, hole):
        """Each hole pixel: the weighted mean of what every patch that covers it says."""
        flat = img.reshape(-1, self.c)
        ty, tx = self.ty, self.tx
        wq = np.zeros((self.h, self.w), np.float32)
        wq[ty, tx] = 1.0 / (1.0 + 20.0 * np.minimum(cost[ty, tx], 1e3))
        acc = np.zeros_like(img)
        den = np.zeros((self.h, self.w), np.float32)
        for dy, dx, pw in zip(self.dy, self.dx, self.pw):
            yy = np.clip(sy[ty, tx] + dy, 0, self.h - 1)
            xx = sx[ty, tx] + dx
            xx = xx % self.w if self.periodic else np.clip(xx, 0, self.w - 1)
            v = np.zeros_like(img)
            v[ty, tx] = flat[yy * self.w + xx] * (pw * wq[ty, tx])[:, None]
            w = np.zeros((self.h, self.w), np.float32)
            w[ty, tx] = pw * wq[ty, tx]
            acc += np.roll(v, (dy, dx), axis=(0, 1))
            den += np.roll(w, (dy, dx), axis=(0, 1))
        out = img.copy()
        ok = hole & (den > 1e-9)
        out[ok] = acc[ok] / den[ok][:, None]
        return out


def _down(img, known):
    """Half size, averaging only known pixels; the new hole is every coarse pixel that touched one."""
    h, w = known.shape
    h2, w2 = h // 2, w // 2
    kf = known[:h2 * 2, :w2 * 2].astype(np.float32)
    num = cv2.resize(img[:h2 * 2, :w2 * 2] * kf[..., None], (w2, h2), interpolation=cv2.INTER_AREA).reshape(h2, w2, -1)
    den = cv2.resize(kf, (w2, h2), interpolation=cv2.INTER_AREA)
    k2 = den > 0.999
    out = num / np.maximum(den, 1e-6)[..., None]
    return out.astype(np.float32), k2


def inpaint(img: np.ndarray, hole: np.ndarray, *, periodic_x: bool = True, y_window: float = 350,
            y_penalty: float = 4.0, seed: int = 0, patch: int = PATCH, levels: int | None = None,
            iters: tuple[int, ...] = (6, 5, 4), final_iters: int = 1, margin: int | None = None) -> np.ndarray:
    """Fill `hole` with patches of the known pixels; see the module doc."""
    img = np.asarray(img, np.float32)
    if img.ndim == 2:
        img = img[..., None]
    hole = np.asarray(hole, bool)
    if not hole.any():
        return img.copy()
    if hole.all():
        raise ValueError("nothing to copy from: the whole image is the hole")
    h, w, c = img.shape
    # work on the hole's rows plus a margin (the y window and the patches need context)
    rows = np.nonzero(hole.any(1))[0]
    mg = margin if margin is not None else int(y_window) + 2 * patch + 8
    y0, y1 = max(rows[0] - mg, 0), min(rows[-1] + 1 + mg, h)
    sub, hsub = img[y0:y1], hole[y0:y1]
    out = _inpaint(sub, hsub, periodic_x, y_window, y_penalty, np.random.default_rng(seed), patch, levels, iters, final_iters)
    res = img.copy()
    res[y0:y1][hsub] = out[hsub]
    return res


def _inpaint(img, hole, periodic, ywin, ypen, rng, k, levels, iters, final_iters):
    h, w, c = img.shape
    cw = np.ones(c, np.float32)
    if c == 4:
        cw[3] = WEIGHT_ALPHA
    # pyramid
    pyr = [(img, ~hole)]
    thick = float(cv2.distanceTransform(hole.astype(np.uint8), cv2.DIST_L2, 3).max()) * 2
    n = levels if levels is not None else int(np.clip(np.floor(np.log2(max(thick, 1) / 10)), 0, 5))
    for _ in range(n):
        di, dk = _down(*pyr[-1])
        if dk.all() or (~dk).sum() == dk.size or min(dk.shape) < 8:
            break
        pyr.append((di, dk))
    n = len(pyr) - 1
    # coarsest: smooth fill, then refine by patches
    cur = None
    sy = sx = None
    for lvl in range(n, -1, -1):
        base, known = pyr[lvl]
        hl = ~known
        hh, ww = known.shape
        if cur is None:
            cur = pull_push(base, known, periodic)
        else:
            cur = cv2.resize(cur, (ww, hh), interpolation=cv2.INTER_LINEAR).reshape(hh, ww, c)
            cur = np.where(known[..., None], base, cur)
        valid = ~_dilate(hl, k // 2, periodic)
        if not valid.any():
            continue
        tgt = _dilate(hl, k // 2, periodic)
        m = _Matcher(cur, tgt, valid, k, ywin / 2 ** lvl, ypen, cw, rng, periodic)
        nsy = np.zeros((hh, ww), np.int64)
        nsx = np.zeros((hh, ww), np.int64)
        if sy is not None:
            py, px = np.nonzero(tgt)
            sy_up = np.clip(sy[np.clip(py // 2, 0, sy.shape[0] - 1), np.clip(px // 2, 0, sy.shape[1] - 1)] * 2, 0, hh - 1)
            sx_up = np.clip(sx[np.clip(py // 2, 0, sx.shape[0] - 1), np.clip(px // 2, 0, sx.shape[1] - 1)] * 2, 0, ww - 1)
            nsy[py, px], nsx[py, px] = sy_up, sx_up
        else:
            py, px = np.nonzero(tgt)
            pick = rng.integers(0, len(m.vy), len(py))
            nsy[py, px], nsx[py, px] = m.vy[pick], m.vx[pick]
        it = final_iters if lvl == 0 else iters[min(n - lvl, len(iters) - 1)]
        for r in range(2):  # match, vote, match again on the new estimate
            nsy, nsx, cost = m.run(cur, nsy, nsx, it)
            cur = m.vote(cur, nsy, nsx, cost, hl)
            cur = np.where(known[..., None], base, cur)
            if lvl == 0:
                break
        sy, sx = nsy, nsx
    return cur


def quilt(img: np.ndarray, hole: np.ndarray, *, periodic_x: bool = True, y_window: int = 350,
          block: int = 72, overlap: int = 24, topk: int = 10, seed: int = 0) -> np.ndarray:
    """Fill `hole` by image quilting: blocks of the visible texture, placed in raster order, each the
    best masked-SSD match of what is already there (the known pixels round the hole and the blocks
    placed before it) among the valid sources within `y_window` rows, one of the `topk` best at
    random so the fill does not repeat, feathered over `overlap` px. Real cloud puffs, kept sharp:
    PatchMatch averages mismatched patches into flat white on a hole this big, a quilt does not.
    Known pixels are never touched. `img` (H, W, C<=4) float, `hole` bool."""
    img = np.asarray(img, np.float32)
    hole = np.asarray(hole, bool)
    if not hole.any():
        return img.copy()
    if hole.all():
        raise ValueError("nothing to copy from: the whole image is the hole")
    h, w, c = img.shape
    rng = np.random.default_rng(seed)
    b, ov = block, overlap
    if periodic_x:                       # roll so that a column free of hole sits at the wrap
        free = np.nonzero(~hole.any(0))[0]
        if len(free):
            sh = -int(free[len(free) // 2])
            img, hole = np.roll(img, sh, 1), np.roll(hole, sh, 1)
        else:
            sh = 0
    else:
        sh = 0
    ys, xs = np.nonzero(hole)
    cur = img.copy()
    have = ~hole
    # valid source top-lefts: the b x b block holds no hole pixel (x wraps through a padded copy)
    pad = np.concatenate([img, img[:, :b]], 1) if periodic_x else img
    padhole = np.concatenate([hole, hole[:, :b]], 1) if periodic_x else hole
    ii = cv2.integral(padhole.astype(np.uint8))
    cnt = ii[b:, b:] - ii[:-b, b:] - ii[b:, :-b] + ii[:-b, :-b]
    valid = cnt == 0                                   # (H-b+1, Wpad-b+1)
    step = b - ov
    used = np.zeros(pad.shape[:2], np.float32)
    ramp = np.clip((np.arange(b) + 0.5) / ov, 0, 1)
    ramp = np.minimum(ramp, ramp[::-1])
    feather = np.minimum.outer(ramp, ramp).astype(np.float32)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    for ty in range(max(y0 - ov, 0), y1, step):
        ty = min(ty, h - b)
        for tx in range(max(x0 - ov, 0), x1, step):
            tx = min(tx, w - b)
            blk_hole = hole[ty:ty + b, tx:tx + b]
            if not (blk_hole & ~have[ty:ty + b, tx:tx + b]).any():
                continue
            tmpl = cur[ty:ty + b, tx:tx + b]
            mask = have[ty:ty + b, tx:tx + b].astype(np.float32)
            r0, r1 = max(ty - y_window, 0), min(ty + y_window + b, h)
            area = pad[r0:r1]
            vmap = valid[r0: r1 - b + 1]
            if not vmap.any():
                r0, r1, area, vmap = 0, h, pad, valid
            # masked SSD by correlation (FFT): sum M (I - T)^2 = sum M T^2 - 2 I * (M T) + I^2 * M
            mt = tmpl * mask[..., None]
            cross = cv2.matchTemplate(area, mt, cv2.TM_CCORR).reshape(vmap.shape)
            sq = cv2.matchTemplate((area ** 2).sum(-1).astype(np.float32), mask, cv2.TM_CCORR).reshape(vmap.shape)
            cost = (mt * tmpl).sum() - 2 * cross + sq
            # a source already used a lot is dearer: no wallpaper of one cloud top repeated along a row
            use = cv2.matchTemplate(used[r0:r1], np.ones((b, b), np.float32), cv2.TM_CCORR).reshape(vmap.shape) / (b * b)
            cost = cost + use * REUSE * b * b * c
            cost = np.where(vmap, cost, np.inf)
            flat = cost.ravel()
            k = min(topk, int(np.isfinite(flat).sum()))
            idx = np.argpartition(flat, k - 1)[:k] if k < len(flat) else np.arange(len(flat))
            idx = idx[np.isfinite(flat[idx])]
            pick = idx[rng.integers(0, len(idx))]
            sy, sx = np.unravel_index(pick, cost.shape)
            src = area[sy:sy + b, sx:sx + b]
            used[r0 + sy: r0 + sy + b, sx: sx + b] += 1
            wsum = float(mask.sum())
            if wsum > 40:                  # brightness of the overlap: no step against what is already there
                delta = ((tmpl - src) * mask[..., None]).sum((0, 1)) / wsum
                delta = np.clip(delta, -MAX_DC, MAX_DC)
                if c == 4:
                    delta[3] = 0
                src = src + delta
            wgt = np.where(mask > 0, feather, 1.0).astype(np.float32)[..., None]
            blend = src * wgt + tmpl * (1 - wgt)
            put = blk_hole
            cur[ty:ty + b, tx:tx + b] = np.where(put[..., None], blend, tmpl)
            have[ty:ty + b, tx:tx + b] |= blk_hole
    if sh:
        cur = np.roll(cur, -sh, 1)
    return cur
