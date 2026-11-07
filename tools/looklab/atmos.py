#!/usr/bin/env python3
"""Look lab, experiment 4: depth haze toward the back only, and bloom / halation on lights.

  haze(rgb, depth, colour)    aerial perspective in linear light: mix toward the horizon colour by
                              smoothstep(near, far) of distance (1 - depth). The island's front
                              is untouched; the back row takes a few percent; the cloud sea and
                              anything past the island take more (the references' falloff).
  bloom(rgb)                  soft threshold on linear luminance, three Gaussian octaves
                              (0.4 %, 1.2 %, 3.5 % of the width), red spread wider than blue
                              (halation), added back.

The falloff is measured, not guessed: `depth_profile` bins a frame by monocular depth over the
island and reports chroma and local contrast per bin (back / front ratios), and `glow_profile`
reads the radius where a lantern's excess luminance halves, as a share of the frame width.

  python3 -I tools/looklab/atmos.py OUT_DIR [--depth-model M.onnx] [--cells colour-script.json]
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import depth as dp  # noqa: E402
import lab  # noqa: E402
import lookdev as ld  # noqa: E402
import nightlab as nl  # noqa: E402
import relight as rl  # noqa: E402
import scene as sc_mod  # noqa: E402

HAZE = {"near": 0.36, "far": 0.6, "amount": 0.35, "power": 1.0}
BLOOM = {"threshold": 0.55, "knee": 0.25, "sigmas": [0.004, 0.012, 0.035], "weights": [0.5, 0.3, 0.2],
         "strength": 0.8, "halation": [1.0, 0.8, 0.6], "emissive_boost": 4.0}


def haze(rgb: np.ndarray, depth: np.ndarray, colour, p: dict = HAZE, keep: np.ndarray | None = None) -> np.ndarray:
    dist = 1 - depth
    t = lab.smoothstep(p["near"], p["far"], dist) ** p["power"] * p["amount"]
    if keep is not None:
        t = t * (1 - keep)
    lin = lab.to_lin(rgb) * (1 - t[..., None]) + lab.to_lin(np.asarray(colour, float)) * t[..., None]
    return lab.to_srgb(lin)


def bloom(rgb: np.ndarray, mask: np.ndarray | None = None, p: dict = BLOOM) -> np.ndarray:
    lin = lab.to_lin(rgb)
    y = lab.luma(lin)
    t, k = p["threshold"], p["knee"]
    soft = np.clip(y - t + k, 0, 2 * k) ** 2 / (4 * k + 1e-6)
    contrib = np.maximum(soft, y - t) / np.maximum(y, 1e-6)
    src = lin * contrib[..., None]
    if mask is not None:  # the frame is display-referred (clipped at 1): emissive parts get their HDR back
        src = src * (1 + p["emissive_boost"] * mask[..., None])
    w = rgb.shape[1]
    glow = np.zeros_like(lin)
    for s, wt in zip(p["sigmas"], p["weights"]):
        for c in range(3):
            glow[..., c] += wt * ndimage.gaussian_filter(src[..., c], s * w * (1 + 0.5 * (1 - p["halation"][c])))
    out = lin + p["strength"] * glow * np.array(p["halation"])
    return lab.to_srgb(out / (1 + 0.2 * np.maximum(out - 0.9, 0)))


def depth_profile(rgb: np.ndarray, d: np.ndarray, island: np.ndarray, bins: int = 4) -> dict:
    """Chroma and local contrast of the island by depth quartile (0 = farthest)."""
    lb = lab.lab(rgb)
    C = np.hypot(lb[..., 1], lb[..., 2])
    lc = lab.local_contrast(lb[..., 0])
    m = island > 0.5
    q = np.quantile(d[m], np.linspace(0, 1, bins + 1))
    chroma, loc = [], []
    for i in range(bins):
        sel = m & (d >= q[i]) & (d <= q[i + 1])
        chroma.append(float(C[sel].mean()))
        loc.append(float(np.sqrt(lc[sel].mean())))
    return {"chroma": [round(c, 1) for c in chroma], "loc": [round(v, 2) for v in loc],
            "chroma_back_front": round(chroma[0] / max(chroma[-1], 1e-6), 2), "loc_back_front": round(loc[0] / max(loc[-1], 1e-6), 2)}


def glow_profile(rgb: np.ndarray, box) -> dict:
    """Find the brightest warm spot in `box` (fractions) and the radius where its excess luminance halves."""
    h, w = rgb.shape[:2]
    x0, y0, x1, y1 = int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)
    y = lab.luma(lab.to_lin(rgb))
    warm = ndimage.gaussian_filter(y * (rgb[..., 0] > rgb[..., 2]), 2)
    sub = warm[y0:y1, x0:x1]
    cy, cx = np.unravel_index(np.argmax(sub), sub.shape)
    cy, cx = cy + y0, cx + x0
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot(yy - cy, xx - cx)
    rmax = 0.12 * w
    edges = np.linspace(0, rmax, 25)
    prof = np.array([y[(r >= edges[i]) & (r < edges[i + 1])].mean() for i in range(24)])
    base = prof[-4:].mean()
    ex = np.maximum(prof - base, 0)
    half = edges[1:][np.argmax(ex < 0.5 * ex[0])] if (ex < 0.5 * ex[0]).any() else rmax
    # A wider measure: where the excess falls to 10 %.
    tenth = edges[1:][np.argmax(ex < 0.1 * ex[0])] if (ex < 0.1 * ex[0]).any() else rmax
    return {"at": [round(cx / w, 3), round(cy / h, 3)], "half_pct_w": round(100 * half / w, 2),
            "tenth_pct_w": round(100 * tenth / w, 2), "peak_over_bg": round(float(ex[0]), 3)}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--depth-model")
    ap.add_argument("--cells", type=Path, default=ld.SCRIPT)
    a = ap.parse_args(argv)
    model = dp.model_path(a.depth_model)
    if not model:
        raise SystemExit("atmos.py measures falloff with the monocular model: pass --depth-model")
    s = sc_mod.Scene()
    cells = ld.load_cells(a.cells)
    day_cell = cells["day"]
    sky = s.sky(ld.hex_rgb(day_cell["sky"]["zenith"]), ld.hex_rgb(day_cell["sky"]["horizon"]))
    nrm = rl.plate_normals(s, rl.normals_by_id(s.depth, s.ids))
    occl = rl.ao(s.depth, s.ids, s.ground, cross_only=True)
    day = rl.relight_day(s.raw(sky), nrm, rl.DAY_RIG, occl, rl.contact(s.depth, s.ids), s.ids < 2)
    hz = haze(day, s.depth, ld.hex_rgb(day_cell["sky"]["horizon"]), keep=(s.ids == 0).astype(float))
    nsky = nl.night_sky(cells["night"], (s.w, s.h), nl.PARAMS)
    night, em = rl.relight_night(s, nrm, rl.NIGHT_RIG, occl, nsky)
    nb = bloom(night, em)
    ref_day = lab.load_rgb(lab.REF["day"][0], 1200)
    ref_night = lab.load_rgb(lab.REF["night"][0], 1200)
    out = {}
    island_lab = (s.ids >= 2).astype(float)
    dm_lab = dp.monocular(s.raw(sky), model)
    for k, v in (("day_relit", day), ("day_haze", hz)):
        out[k] = depth_profile(v, dm_lab, island_lab)
    dr = dp.monocular(ref_day, model)
    out["ref_day"] = depth_profile(ref_day, dr, dp.masks_from_depth(dr)["island"])
    lamp = [l for l in s.lights() if l["name"] == "path-lamp"][0]
    lb = (lamp["x"] / s.w - 0.015, lamp["y"] / s.h - 0.02, lamp["x"] / s.w + 0.015, lamp["y"] / s.h + 0.02)
    out["glow_lookdev"] = glow_profile(ld.render_scene(s.spec, cells)[0][3], lb)
    out["glow_relit"] = glow_profile(night, lb)
    out["glow_bloom"] = glow_profile(nb, lb)
    out["glow_ref"] = glow_profile(ref_night, (0.52, 0.15, 0.64, 0.33))
    print(json.dumps(out))
    (a.out_dir / "atmos.json").write_text(json.dumps(out, indent=1))

    def dcap(k):
        o = out[k]
        return f"chroma by depth (far..near) {o['chroma']}\nback/front chroma {o['chroma_back_front']}  contrast {o['loc_back_front']}"

    def gcap(k):
        o = out[k]
        return f"glow half-radius {o['half_pct_w']} % w, 10 %: {o['tenth_pct_w']} % w"

    def crop(img, at, half=0.09):
        h, w = img.shape[:2]
        cx, cy = at[0] * w, at[1] * h
        r = half * w
        return lab.to_img(img).crop((int(cx - r), int(cy - r * 0.8), int(cx + r), int(cy + r * 0.8)))

    rows = [[(lab.to_img(day), "day relit, no haze\n" + dcap("day_relit")), (lab.to_img(hz), "+ depth haze (back only)\n" + dcap("day_haze")),
             (lab.to_img(ref_day), "reference I1 summer\n" + dcap("ref_day"))],
            [(lab.to_img(night), "night relit, no bloom\n" + gcap("glow_relit")), (lab.to_img(nb), "+ bloom and halation\n" + gcap("glow_bloom")),
             (lab.to_img(ref_night), "reference Gezgin night\n" + gcap("glow_ref"))],
            [(crop(ld.render_scene(s.spec, cells)[0][3], out["glow_lookdev"]["at"]), "lamp, game light now\n" + gcap("glow_lookdev")),
             (crop(night, out["glow_relit"]["at"]), "lamp, relit"), (crop(nb, out["glow_bloom"]["at"]), "lamp, relit + bloom"),
             (crop(ref_night, out["glow_ref"]["at"]), "reference lantern")]]
    lab.sheet(rows, a.out_dir / "04-atmos-bloom.jpg", "Experiment 4: depth haze and bloom, measured against the references' falloff",
              cell_h=330)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
