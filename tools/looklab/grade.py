#!/usr/bin/env python3
"""Look lab, experiment 1: a fitted colour grade per light state, as a 3D LUT the runtime could use.

Methods, each fitted from the game frame toward its reference (`lab.REF`):

  reinhard     mean and standard deviation of L*, a*, b* matched (Reinhard 2001), global.
  lut          sliced optimal transport (Pitie's iterative distribution transfer, 24 random
               rotations in CIELAB) moves the frame's colours onto the reference's; the
               moves are then fitted into a smooth 17^3 RGB LUT (trilinear splat, normalised
               Gaussian smoothing, an identity prior where the frame has no colours), so
               the result is one texture lookup and cannot tear neighbouring pixels apart.
  region-lut   the same, one LUT for the island and one for the backdrop (sky and cloud sea; masks from depth), blended
               by soft masks. In the game these are separate layers, so the masks are free.
  material-lut Reinhard per material (sky, sea, lawn, earth; sprites half way; `material_transfer`)
               toward the same material in the references, baked into one global 17^3 LUT.
               Distribution matching (lut, region-lut) asks a green lawn to become the
               reference's mix of lawn and sunflowers; per material it cannot.

  python3 -I tools/looklab/grade.py SHOTS_DIR OUT.jpg [--depth-model M.onnx] [--json OUT.json]

SHOTS_DIR holds `concept-<state>-home.jpg` (the screenshots branch of feat/concept-match).
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import sys

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import depth as dp  # noqa: E402
import lab  # noqa: E402

STATES = ["day", "golden", "night", "rain"]
N = 17


# ---------------------------------------------------------------- transfer

def reinhard(src_lab: np.ndarray, tgt_lab: np.ndarray, w_src=None) -> tuple[np.ndarray, np.ndarray]:
    """Per-channel (scale, offset) so the source's mean and std become the target's."""
    s = src_lab.reshape(-1, 3) if w_src is None else src_lab[w_src]
    t = tgt_lab.reshape(-1, 3)
    scale = t.std(0) / np.maximum(s.std(0), 1e-6)
    return scale, t.mean(0) - s.mean(0) * scale


def rotations(k: int, seed: int = 7) -> list[np.ndarray]:
    rng = np.random.default_rng(seed)
    out = [np.eye(3)]
    while len(out) < k:
        q, _ = np.linalg.qr(rng.normal(size=(3, 3)))
        out.append(q)
    return out


def sliced_ot(src: np.ndarray, tgt: np.ndarray, iters: int = 24, seed: int = 7) -> np.ndarray:
    """Pitie's IDT: repeated 1D quantile matching along random orthonormal bases."""
    x = src.copy()
    q = np.linspace(0, 1, 257)
    for R in rotations(iters, seed):
        xs, ts = x @ R, tgt @ R
        for c in range(3):
            xq, tq = np.quantile(xs[:, c], q), np.quantile(ts[:, c], q)
            xs[:, c] = np.interp(xs[:, c], xq + np.arange(257) * 1e-9, tq)
        x = xs @ R.T
    return x


# ---------------------------------------------------------------- LUT

def fit_lut(src_rgb: np.ndarray, dst_rgb: np.ndarray, n: int = N, sigma: float = 1.2, prior: float = 0.6) -> np.ndarray:
    """A smooth n^3 RGB->RGB LUT through the (src, dst) pairs; identity where there is no data."""
    g = np.clip(src_rgb, 0, 1) * (n - 1)
    i0 = np.minimum(np.floor(g).astype(int), n - 2)
    f = g - i0
    disp = dst_rgb - src_rgb
    num = np.zeros((n, n, n, 3))
    den = np.zeros((n, n, n))
    for dr in (0, 1):
        for dg in (0, 1):
            for db in (0, 1):
                wgt = ((f[:, 0] if dr else 1 - f[:, 0]) * (f[:, 1] if dg else 1 - f[:, 1]) * (f[:, 2] if db else 1 - f[:, 2]))
                idx = (i0[:, 0] + dr, i0[:, 1] + dg, i0[:, 2] + db)
                np.add.at(den, idx, wgt)
                for c in range(3):
                    np.add.at(num[..., c], idx, wgt * disp[:, c])
    den_s = ndimage.gaussian_filter(den, sigma, mode="nearest")
    num_s = np.stack([ndimage.gaussian_filter(num[..., c], sigma, mode="nearest") for c in range(3)], -1)
    # The prior pulls empty cells to identity; scaled to the mean occupancy so it is resolution-free.
    w0 = prior * den_s[den_s > 0].mean() * 0.05
    d = num_s / (den_s[..., None] + w0)
    ident = np.stack(np.meshgrid(*[np.linspace(0, 1, n)] * 3, indexing="ij"), -1)
    return np.clip(ident + d, 0, 1)


def apply_lut(rgb: np.ndarray, lut: np.ndarray) -> np.ndarray:
    n = lut.shape[0]
    c = np.clip(rgb, 0, 1).reshape(-1, 3).T * (n - 1)
    out = np.stack([ndimage.map_coordinates(lut[..., k], c, order=1, mode="nearest") for k in range(3)], -1)
    return out.reshape(rgb.shape)


def samples(rgb: np.ndarray, weight: np.ndarray | None, k: int, seed: int) -> np.ndarray:
    flat = rgb.reshape(-1, 3)
    p = None if weight is None else weight.reshape(-1) / weight.sum()
    idx = np.random.default_rng(seed).choice(len(flat), size=min(k, len(flat)), replace=True, p=p)
    return flat[idx]


def ot_lut(src_rgb: np.ndarray, tgt_rgb_list: list[np.ndarray], w_src=None, w_tgts=None, k: int = 60000,
           sigma: float = 1.2, seed: int = 3) -> np.ndarray:
    s = samples(src_rgb, w_src, k, seed)
    t = np.concatenate([samples(t, None if w_tgts is None else w_tgts[i], k // len(tgt_rgb_list), seed + i + 1)
                        for i, t in enumerate(tgt_rgb_list)])
    moved = lab.rgb_of(sliced_ot(lab.lab(s), lab.lab(t)))
    return fit_lut(s, moved, sigma=sigma)


def ui_free(shape) -> np.ndarray:
    """The home frame's map button (bottom right) is UI: leave it out of every fit."""
    h, w = shape[:2]
    m = np.ones((h, w))
    m[int(h * 0.88):, int(w * 0.78):] = 0
    return m


# ---------------------------------------------------------------- the three methods

def grade_reinhard(src: np.ndarray, tgts: list[np.ndarray]) -> np.ndarray:
    sl, tl = lab.lab(src), np.concatenate([lab.lab(t).reshape(-1, 3) for t in tgts])
    scale, off = reinhard(sl, tl, ui_free(src.shape) > 0)
    return lab.rgb_of(sl * scale + off)


def grade_lut(src: np.ndarray, tgts: list[np.ndarray]) -> tuple[np.ndarray, np.ndarray]:
    lut = ot_lut(src, tgts, w_src=ui_free(src.shape))
    return apply_lut(src, lut), lut


def grade_regions(src: np.ndarray, tgts: list[np.ndarray], m_src: dict, m_tgts: list[dict]) -> tuple[np.ndarray, dict]:
    out = np.zeros_like(src)
    tot = np.zeros(src.shape[:2])
    luts = {}
    # Two regions: the island, and the backdrop (sky + cloud sea). A three-way split put a seam
    # between sky and sea beside the island; the backdrop's two parts share one gradient anyway.
    m_src = {"island": m_src["island"], "backdrop": m_src["sky"] + m_src["sea"]}
    m_tgts = [{"island": m["island"], "backdrop": m["sky"] + m["sea"]} for m in m_tgts]
    for name in ("island", "backdrop"):
        ws = m_src[name] * ui_free(src.shape)
        if ws.sum() < 500:
            continue
        lut = ot_lut(src, tgts, w_src=ws, w_tgts=[m[name] + 1e-9 for m in m_tgts])
        luts[name] = lut
        out += apply_lut(src, lut) * m_src[name][..., None]
        tot += m_src[name]
    out = out / np.maximum(tot, 1e-6)[..., None]
    return out, luts


# ---------------------------------------------------------------- material transfer (the winner)

def lawn_like(labv: np.ndarray) -> np.ndarray:
    """Green foliage by hue (95..160 deg) and chroma; the lawn in both the game and the references."""
    H = np.degrees(np.arctan2(labv[..., 2], labv[..., 1])) % 360
    C = np.hypot(labv[..., 1], labv[..., 2])
    return (H > 95) & (H < 160) & (C > 10)


def ref_materials(rgb: np.ndarray, masks: dict) -> dict[str, np.ndarray]:
    """Materials in a reference from depth masks + colour: sky (top band), sea, lawn (green), earth
    (lower island, peach hues) and the island as a whole (for sprites, which a reference does not
    separate)."""
    lb = lab.lab(rgb)
    isl = masks["island"] > 0.5
    ys = np.nonzero(isl)[0]
    cy = ys.mean() if len(ys) else rgb.shape[0] / 2
    yy = np.mgrid[0:rgb.shape[0], 0:rgb.shape[1]][0]
    lawn = isl & lawn_like(lb)
    H = np.degrees(np.arctan2(lb[..., 2], lb[..., 1])) % 360
    C = np.hypot(lb[..., 1], lb[..., 2])
    # Earth: the lower island in peach-to-caramel hues (not the clouds the depth mask may include).
    earth = isl & ~lawn & (yy > cy) & (lb[..., 0] > 35) & (H > 35) & (H < 95) & (C > 10)
    # Sky: the top band only (lower sky is mostly cloud, which belongs with the sea).
    sky = (masks["sky"] > 0.5) & (yy < 0.18 * rgb.shape[0])
    return {"sky": sky, "sea": masks["sea"] > 0.5, "lawn": lawn, "earth": earth, "island": isl}


def material_transfer(src: np.ndarray, src_mats: dict[str, np.ndarray], tgts: list[np.ndarray],
                      tgt_mats: list[dict[str, np.ndarray]], scale_clip=(0.75, 1.3), sprite_strength: float = 0.5,
                      min_px: int = 400) -> np.ndarray:
    """Reinhard per material: each material's L*a*b* mean and spread move to the same material in the
    references (spread scaling clipped), so a green lawn is never asked to become a sunflower. Sprites
    take the island's mean shift at `sprite_strength` (characters keep their own colours)."""
    sl_ = lab.lab(src)
    out = sl_.copy()
    pooled = {k: np.concatenate([lab.lab(t)[m[k]] for t, m in zip(tgts, tgt_mats) if m[k].sum() >= min_px] or [np.zeros((0, 3))])
              for k in ("sky", "sea", "lawn", "earth", "island")}
    for k in ("sky", "sea", "lawn", "earth"):
        m = src_mats.get(k)
        if m is None or m.sum() < min_px or len(pooled[k]) < min_px:
            continue
        s_, t_ = sl_[m], pooled[k]
        scale = np.clip(t_.std(0) / np.maximum(s_.std(0), 1e-6), *scale_clip)
        out[m] = (s_ - s_.mean(0)) * scale + t_.mean(0)
    m = src_mats.get("sprites")
    if m is not None and m.sum() >= min_px and len(pooled["island"]) >= min_px:
        island_src = np.concatenate([sl_[src_mats[k]] for k in ("lawn", "earth") if src_mats.get(k) is not None])
        shift = (pooled["island"].mean(0) - island_src.mean(0)) * sprite_strength
        shift[0] = np.clip(shift[0], -12, 12)
        out[m] = sl_[m] + shift
    return lab.rgb_of(out)


def lut_from_pairs(src: np.ndarray, dst: np.ndarray, mask: np.ndarray, k: int = 60000, seed: int = 5) -> np.ndarray:
    """Bake a per-pixel transfer into a smooth LUT (what the runtime would load)."""
    idx = np.flatnonzero(mask.reshape(-1))
    idx = np.random.default_rng(seed).choice(idx, size=min(k, len(idx)), replace=False)
    return fit_lut(src.reshape(-1, 3)[idx], dst.reshape(-1, 3)[idx], sigma=1.0)


def save_cube(lut: np.ndarray, path: Path, title: str) -> None:
    """Adobe .cube (red fastest): loadable in any grading tool and trivially into a Metal 3D texture."""
    n = lut.shape[0]
    lines = [f'TITLE "{title}"', f"LUT_3D_SIZE {n}"]
    for b in range(n):
        for g in range(n):
            for r in range(n):
                lines.append(" ".join(f"{v:.5f}" for v in lut[r, g, b]))
    path.write_text("\n".join(lines) + "\n")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("shots", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--depth-model")
    ap.add_argument("--json", type=Path)
    ap.add_argument("--cube-dir", type=Path, help="also write the fitted LUTs as .cube files here")
    a = ap.parse_args(argv)
    model = dp.model_path(a.depth_model)
    rows, labels, readout = [], [], {}
    for st in STATES:
        src = lab.load_rgb(a.shots / f"concept-{st}-home.jpg")
        refs = [lab.load_rgb(p, 768) for p in lab.REF[st]]
        ref = lab.ref_stats(st)
        res = {"before": src, "reinhard": grade_reinhard(src, refs)}
        res["lut"], glut = grade_lut(src, refs)
        if model:
            m_src = dp.masks_from_depth(dp.monocular(src, model))
            m_tgts = [dp.masks_from_depth(dp.monocular(r, model)) for r in refs]
            res["region-lut"], _ = grade_regions(src, refs, m_src, m_tgts)
            # The winner: Reinhard per material, baked into ONE global LUT (lawn, earth and sky
            # differ in colour, so a single 3D lookup can carry all three moves).
            tm = [ref_materials(r, m) for r, m in zip(refs, m_tgts)]
            sm = ref_materials(src, m_src)
            sm["sprites"] = sm.pop("island") & ~sm["lawn"] & ~sm["earth"]
            moved = material_transfer(src, sm, refs, tm)
            mlut = lut_from_pairs(src, moved, ui_free(src.shape) > 0)
            res["material-lut"] = apply_lut(src, mlut)
            if a.cube_dir:
                a.cube_dir.mkdir(parents=True, exist_ok=True)
                save_cube(mlut, a.cube_dir / f"{st}.cube", f"look-lab {st} material LUT")
        readout[st] = {k: lab.compare(lab.stats(v, "home"), ref) for k, v in res.items()}
        readout[st]["reference_bf"] = lab.ref_bf(ref)
        row = [(lab.to_img(v), f"{k}\n{lab.fmt(readout[st][k])}") for k, v in res.items()]
        refimg = lab.to_img(lab.load_rgb(lab.REF[st][0], 900))
        row.append((refimg, f"reference ({lab.REF[st][0].parent.name})\nb/f {readout[st]['reference_bf']}"))
        rows.append(row)
        labels.append(st)
        print(st, {k: lab.fmt(v) for k, v in readout[st].items() if isinstance(v, dict)})
    lab.sheet(rows, a.out, "Experiment 1: fitted grade on the Home frame (feat/concept-match screenshots) toward I1",
              cell_h=420, row_labels=labels)
    if a.json:
        a.json.write_text(json.dumps(readout, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
