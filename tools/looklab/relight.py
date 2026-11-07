#!/usr/bin/env python3
"""Look lab, experiments 2 and 3: ambient occlusion, contact shadows and a relight rig from depth.

  ao(depth, ids)          screen-space AO: 16 directions x 3 radii on the depth buffer; a sample
                          nearer than the pixel by more than a bias occludes it, fading with range.
  contact(depth, ids)     depth-buffer ray march toward the key light (Unreal-style contact
                          shadows): short, sharp, only where a sprite meets the ground.
  normals_by_id(...)      normals from depth, computed per layer id so no gradient crosses an edge.
  relight_day(...)        ratio relight: the art is kept as it is lit and multiplied by
                          rig(n) / day_rig(flat), so the paint's own light survives and the rig adds
                          direction (warm key, cool sky fill, cloud-sea bounce from below, rim) and,
                          for golden or rain, the light's colour and level.
  relight_night(...)      delit-then-relit (nightlab's `unlight`), a moon/sky hemisphere, and point
                          lights at the lantern, the stall and the house door with inverse-square
                          falloff in screen + depth space, wrap lighting, and their own short shadows.

  python3 -I tools/looklab/relight.py OUT_DIR [--depth-model M.onnx] [--cells colour-script.json]

Writes `02-depth-ao.jpg`, `03-relight.jpg` and a json readout into OUT_DIR.
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
import scene as sc_mod  # noqa: E402
import lookdev as ld  # noqa: E402
import nightlab as nl  # noqa: E402

DAY_RIG = {
    "key": {"dir": [-0.45, 0.70, 0.55], "colour": [1.00, 0.93, 0.80], "intensity": 1.0, "wrap": 0.35},
    "sky": {"colour": [0.70, 0.80, 1.00], "intensity": 0.55},
    "bounce": {"colour": [1.00, 0.88, 0.90], "intensity": 0.45},
    "rim": {"colour": [1.00, 0.95, 0.85], "intensity": 0.35, "power": 3.0},
    "strength": 0.8,
}
GOLDEN_RIG = {
    "key": {"dir": [0.75, 0.35, 0.45], "colour": [1.00, 0.72, 0.50], "intensity": 1.1, "wrap": 0.45},
    "sky": {"colour": [0.75, 0.62, 0.95], "intensity": 0.5},
    "bounce": {"colour": [1.00, 0.70, 0.75], "intensity": 0.55},
    "rim": {"colour": [1.00, 0.70, 0.45], "intensity": 0.6, "power": 2.5},
    "strength": 0.85,
}
RAIN_RIG = {
    "key": {"dir": [0.0, 1.0, 0.3], "colour": [0.92, 0.92, 1.00], "intensity": 0.6, "wrap": 0.8},
    "sky": {"colour": [0.85, 0.85, 1.00], "intensity": 0.8},
    "bounce": {"colour": [0.95, 0.92, 1.00], "intensity": 0.5},
    "rim": {"colour": [0.9, 0.9, 1.0], "intensity": 0.1, "power": 3.0},
    "strength": 0.6,
}
NIGHT_RIG = {
    "moon": {"dir": [0.55, 0.65, 0.35], "colour": [0.62, 0.68, 1.00], "intensity": 0.42, "wrap": 0.5},
    "sky": {"colour": [0.40, 0.42, 0.85], "intensity": 0.42},
    "bounce": {"colour": [0.75, 0.70, 0.95], "intensity": 0.35},
    "point": {"intensity": 1.9, "wrap": 0.8, "depth_px": 0.35, "falloff": 1.0},
    "character_lift": 1.35,  # a character catches more of every light (the film habit of a character key)
    "rim": {"colour": [1.0, 0.78, 0.5], "intensity": 0.5, "power": 2.5},
    "emissive_gain": 2.2,
}


# ---------------------------------------------------------------- occlusion

def shift(a: np.ndarray, dy: int, dx: int) -> np.ndarray:
    return ndimage.shift(a, (dy, dx), order=0, mode="nearest")


def ao(depth: np.ndarray, ids: np.ndarray, ground: np.ndarray | None = None, radii=(0.008, 0.02, 0.045),
       bias: float = 0.002, rng: float = 0.08, dirs: int = 16, cross_only: bool = False) -> np.ndarray:
    """Occlusion 0..1 (1 = fully occluded) for everything but the sky.

    Works on height above the ground (depth minus `ground`), not raw depth: on a lawn tilted toward
    the camera every lower neighbour is nearer, and raw-depth AO greys the whole slope. `ground`
    is the plate without its sprites (layered depth) or a wide blur of the depth (monocular).
    `cross_only`: only another layer occludes (a sprite does not darken itself; its own form
    shading is the relight's job)."""
    h, w = depth.shape
    if ground is None:
        ground = ndimage.gaussian_filter(depth, 0.04 * w)
    H = depth - ground
    occ = np.zeros_like(depth)
    tot = 0.0
    for r in radii:
        rp = r * w
        for k in range(dirs):
            t = 2 * np.pi * (k + 0.5 * (r == radii[1])) / dirs
            dy, dx = int(round(np.sin(t) * rp)), int(round(np.cos(t) * rp))
            dd = shift(H, -dy, -dx) - H - bias
            o = np.clip(dd / (r * 1.0), 0, 1) * (dd < rng)
            if cross_only:
                o = o * (shift(ids, -dy, -dx) != ids)
            occ += o
            tot += 1
    occ = occ / tot
    occ = ndimage.gaussian_filter(occ, 1.2)
    return np.where(ids == 0, 0, np.clip(occ * 4.0, 0, 1))


def contact(depth: np.ndarray, ids: np.ndarray, sdir=(-0.6, 0.8), d_per_px: float = 0.0011, steps: int = 16,
            step_px: float = 1.5, thickness: float = 0.06, soft: float = 2.0) -> np.ndarray:
    """1 where a short ray toward the light is blocked by a sprite nearer than the ray; the plate receives.

    `sdir` is the screen direction toward the key (image y down): a key from the front-left marches
    down-left, and the ray climbs `d_per_px` per pixel, a little faster than the lawn's own slope
    (0.25 depth over its ~210 px), so only the base of a sprite, close by, can block it."""
    sh = np.zeros_like(depth)
    sprite = ids >= 3
    for k in range(1, steps + 1):
        dx, dy = sdir[0] * step_px * k, sdir[1] * step_px * k
        ds = ndimage.shift(depth, (-dy, -dx), order=1, mode="nearest")
        blocker = ndimage.shift(sprite.astype(float), (-dy, -dx), order=0, mode="constant") > 0.5
        ray = depth + d_per_px * step_px * k
        hit = blocker & (ds > ray) & (ds - ray < thickness)
        sh = np.maximum(sh, hit * (1 - k / (steps + 1)) ** 0.5)
    sh = np.where(ids == 2, sh, 0)
    return ndimage.gaussian_filter(sh, soft)


# ---------------------------------------------------------------- normals

def normals_by_id(depth: np.ndarray, ids: np.ndarray, scale: float = 60.0) -> np.ndarray:
    n = np.zeros(depth.shape + (3,))
    n[..., 2] = 1
    for i in np.unique(ids):
        m = ids == i
        if i == 0 or m.sum() < 20:
            continue
        idx = ndimage.distance_transform_edt(~m, return_distances=False, return_indices=True)
        filled = depth[tuple(idx)]
        nn = dp.normals(filled, scale=scale * (0.5 if i == 2 else 1.0), blur=1.5 if i == 2 else 1.0)
        n[m] = nn[m]
    return n


def plate_normals(scene, n: np.ndarray) -> np.ndarray:
    """The plate as the game knows it: the lawn faces up (tilted to the camera), the earth face
    is a rounded wall whose underside turns down toward the cloud sea."""
    h, w = scene.h, scene.w
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    u = np.clip((xx - scene.cx) / scene.rx, -0.98, 0.98)
    below = np.clip((yy - scene.y_front) / max(scene.y_bottom - scene.y_front, 1), 0, 1)
    face = np.stack([u * 0.9, 0.25 - 1.3 * below ** 1.5, np.sqrt(1 - u ** 2) + 0.2], -1)
    lawn = np.stack([u * 0.25, np.full_like(u, 0.85), np.full_like(u, 0.5)], -1)
    t = ndimage.gaussian_filter(scene.lawn.astype(float), 0.006 * w)[..., None]  # soft lip, per column
    pn = lawn * t + face * (1 - t)
    pn /= np.linalg.norm(pn, axis=-1, keepdims=True)
    detail = n - np.array([0, 0, 1.0])  # keep the depth's small relief on top
    pn = pn + 0.5 * detail
    pn /= np.linalg.norm(pn, axis=-1, keepdims=True)
    return np.where((scene.ids == 2)[..., None], pn, n)


def unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


# ---------------------------------------------------------------- day rig

def rig(n: np.ndarray, r: dict, shadow: np.ndarray | None = None) -> np.ndarray:
    """Linear light (h, w, 3) from a rig dict for screen normals n (x right, y up, z out)."""
    k = r["key"]
    ndl = n @ unit(k["dir"])
    wr = np.clip((ndl + k["wrap"]) / (1 + k["wrap"]), 0, 1)
    if shadow is not None:
        wr = wr * (1 - shadow)
    out = wr[..., None] * np.array(k["colour"]) * k["intensity"]
    up = n[..., 1]
    out += (0.5 + 0.5 * up)[..., None] * np.array(r["sky"]["colour"]) * r["sky"]["intensity"]
    out += np.clip(-up, 0, 1)[..., None] * np.array(r["bounce"]["colour"]) * r["bounce"]["intensity"]
    side = np.clip(n[..., :2] @ unit(k["dir"])[:2] * -1, 0, 1)  # the side away from the key...
    rim = (1 - np.clip(n[..., 2], 0, 1)) ** r["rim"]["power"] * (0.3 + 0.7 * side)
    out += rim[..., None] * np.array(r["rim"]["colour"]) * r["rim"]["intensity"]
    return out


def relight_day(rgb: np.ndarray, n: np.ndarray, r: dict, occl: np.ndarray, shadow: np.ndarray, sky_mask: np.ndarray,
                ao_gain: float = 0.7, shadow_tint=(0.55, 0.58, 0.80), base: dict | None = None) -> np.ndarray:
    """The art was painted under soft neutral daylight: the ratio is this rig on the real normals over
    the day rig on a flat, front-facing normal, so a golden or rain rig also shifts colour and value."""
    flat = np.zeros_like(n)
    flat[..., 2] = 1
    ratio = rig(n, r, shadow) / np.maximum(rig(flat, base or DAY_RIG), 1e-4)
    ratio = 1 + r["strength"] * (ratio - 1)
    lin = lab.to_lin(rgb) * ratio
    # AO and contact shadows darken toward a cool tint, never to grey (the references' shadows are coloured).
    tint = np.array(shadow_tint)
    lin = lin * (1 - ao_gain * occl[..., None] * (1 - tint))
    out = lab.to_srgb(lin / (1 + 0.15 * np.maximum(lin - 0.85, 0)))
    return np.where(sky_mask[..., None], rgb, out)  # the sky and the cloud sea are graded, not relit


def apply_ao(rgb, occl, shadow, gain=0.7, contact_gain=0.6, tint=(0.55, 0.58, 0.80)):
    lin = lab.to_lin(rgb)
    t = np.array(tint)
    lin = lin * (1 - gain * occl[..., None] * (1 - t)) * (1 - contact_gain * shadow[..., None] * (1 - t))
    return lab.to_srgb(lin)


# ---------------------------------------------------------------- night rig

def relight_night(scene, n: np.ndarray, r: dict, occl: np.ndarray, sky_rgb: np.ndarray, night_lights=None) -> np.ndarray:
    h, w = scene.h, scene.w
    p = nl.PARAMS

    def unlit(rgb, alpha):
        ys, xs = np.nonzero(alpha > 0.5)
        ext = max(np.ptp(ys) if len(ys) else 1, np.ptp(xs) if len(xs) else 1)
        return np.clip(nl.unlight(rgb, alpha, p, ext), 0, 1)

    albedo = scene.raw(sky_rgb * 0, layer_fn=lambda l: unlit(l.rgba[..., :3], l.rgba[..., 3]))
    lin_a = lab.to_lin(albedo)
    m = r["moon"]
    ndl = np.clip((n @ unit(m["dir"]) + m["wrap"]) / (1 + m["wrap"]), 0, 1)
    light = ndl[..., None] * np.array(m["colour"]) * m["intensity"]
    up = n[..., 1]
    light += (0.5 + 0.5 * up)[..., None] * np.array(r["sky"]["colour"]) * r["sky"]["intensity"]
    light += np.clip(-up, 0, 1)[..., None] * np.array(r["bounce"]["colour"]) * r["bounce"]["intensity"]
    light *= (1 - 0.6 * occl)[..., None]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    pt = r["point"]
    for L in (night_lights if night_lights is not None else scene.lights()):
        dz = (scene.depth - L["depth"]) * pt["depth_px"] * w
        v = np.stack([L["x"] - xx, -(L["y"] - yy), -dz], -1)
        dist = np.linalg.norm(v, axis=-1)
        ldir = v / np.maximum(dist, 1e-6)[..., None]
        ndl = np.clip(((n * ldir).sum(-1) + pt["wrap"]) / (1 + pt["wrap"]), 0, 1)
        att = 1 / (1 + (dist / L["radius"]) ** 2) ** pt["falloff"]
        light += (ndl * att)[..., None] * L["colour"] * L["intensity"] * pt["intensity"]
    rim = (1 - np.clip(n[..., 2], 0, 1)) ** r["rim"]["power"]
    near = np.zeros((h, w))
    for L in (night_lights if night_lights is not None else scene.lights()):
        near = np.maximum(near, np.exp(-((xx - L["x"]) ** 2 + (yy - L["y"]) ** 2) / (2 * (L["radius"] * 1.6) ** 2)))
    light += (rim * near)[..., None] * np.array(r["rim"]["colour"]) * r["rim"]["intensity"]
    chars = np.isin(scene.ids, [3 + i for i, l in enumerate(scene.layers) if l.role == "character"])
    light = light * np.where(chars, r["character_lift"], 1.0)[..., None]
    out = lin_a * light
    # Emissive parts (lamp glass, windows): the source's own bright paint near its light point is
    # lit from inside, above 1.0 in linear light so the bloom pass can pick it up.
    raw = scene.raw(sky_rgb)
    lr = lab.to_lin(raw)
    em = np.zeros((h, w))
    for L in (night_lights if night_lights is not None else scene.lights()):
        layer = [l for l in scene.layers if l.name == L["name"]][0]
        core = np.exp(-((xx - L["x"]) ** 2 + (yy - L["y"]) ** 2) / (2 * (0.25 * L["radius"]) ** 2))
        e = core * layer.rgba[..., 3] * lab.smoothstep(0.35, 0.75, lab.luma(raw))
        glow = lr * (0.35 + 0.65 * L["colour"]) * r["emissive_gain"]  # lit from inside: warmer, brighter
        out = out * (1 - e[..., None]) + glow * e[..., None]
        em = np.maximum(em, e)
    out = lab.to_srgb(out / (1 + 0.25 * np.maximum(out - 0.8, 0)))
    sky = scene.ids == 0
    return np.where(sky[..., None], sky_rgb, out), em


# ---------------------------------------------------------------- sheets

def gray(a):
    return lab.to_img(np.repeat(np.clip(a, 0, 1)[..., None], 3, -1))


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--depth-model")
    ap.add_argument("--cells", type=Path, default=ld.SCRIPT)
    a = ap.parse_args(argv)
    a.out_dir.mkdir(parents=True, exist_ok=True)
    s = sc_mod.Scene()
    cells = ld.load_cells(a.cells)
    ref = lab.ref_stats("day")
    before_frames, _ = ld.render_scene(s.spec, cells)  # dawn, day, golden, night under the game's light
    day_cell = cells["day"]
    sky = s.sky(ld.hex_rgb(day_cell["sky"]["zenith"]), ld.hex_rgb(day_cell["sky"]["horizon"]))
    raw = s.raw(sky)
    occl = ao(s.depth, s.ids, s.ground, cross_only=True)
    cont = contact(s.depth, s.ids)
    with_ao = apply_ao(raw, occl, cont)
    readout = {}
    model = dp.model_path(a.depth_model)
    rows = [[(lab.to_img(raw), "raw art, no shadows"),
             (lab.to_img(before_frames[1]), "game light now (lookdev day):\nprojected shadow + foot pad"),
             (lab.to_img(with_ao), "raw + AO + contact (layered depth)")]]
    dbg = [(gray(s.depth), "layered depth (ids + lawn plane + domes)"), (gray(1 - occl), "AO, layered"),
           (gray(1 - cont), "contact shadows, layered")]
    for k, v in (("raw", raw), ("lookdev", before_frames[1]), ("ao", with_ao)):
        readout[k] = lab.compare(lab.stats(v, "lab"), ref)
    if model:
        dm = dp.monocular(raw, model)
        occl_m = ao(dm, np.where(s.ids == 0, 0, 2))
        with_m = apply_ao(raw, occl_m, np.zeros_like(occl_m))
        readout["ao_monocular"] = lab.compare(lab.stats(with_m, "lab"), ref)
        rows[0].append((lab.to_img(with_m), "raw + AO (monocular depth)"))
        dbg.append((gray(dm), "Depth Anything V2 small (CPU, 1 s)"))
        dbg.append((gray(1 - occl_m), "AO, monocular"))
    rows.append(dbg)
    # A 2x zoom on the props' feet, the place contact shadows matter.
    box = (int(s.w * 0.33), int(s.h * 0.24), int(s.w * 0.83), int(s.h * 0.50))
    rows.append([(lab.to_img(raw).crop(box), "zoom: raw"), (lab.to_img(before_frames[1]).crop(box), "zoom: game light now"),
                 (lab.to_img(with_ao).crop(box), "zoom: AO + contact")])
    lab.sheet(rows, a.out_dir / "02-depth-ao.jpg", "Experiment 2: ambient occlusion and contact shadows from depth (lab home scene)",
              cell_h=330)

    # Relight, day + golden + night.
    nrm = plate_normals(s, normals_by_id(s.depth, s.ids))
    sky_mask = s.ids < 2
    day = relight_day(raw, nrm, DAY_RIG, occl, cont, sky_mask)
    gcell = cells["golden"]
    gsky = s.sky(ld.hex_rgb(gcell["sky"]["zenith"]), ld.hex_rgb(gcell["sky"]["horizon"]))
    graw = s.raw(gsky)
    gold = relight_day(graw, nrm, GOLDEN_RIG, occl, contact(s.depth, s.ids, sdir=(0.8, 0.6)), sky_mask)
    ncell = cells["night"]
    nsky = nl.night_sky(ncell, (s.w, s.h), nl.PARAMS)
    night, em = relight_night(s, nrm, NIGHT_RIG, occl, nsky)
    nl_frame = nl.render_new(s.spec, nl.PARAMS, cells)[0]
    for k, v in (("day_relit", day), ("golden_lookdev", before_frames[2]), ("golden_relit", gold)):
        readout[k] = lab.compare(lab.stats(v, "lab"), lab.ref_stats("golden") if "golden" in k else ref)
    nref = lab.ref_stats("night")
    for k, v in (("night_lookdev", before_frames[3]), ("night_nightlab", nl_frame), ("night_relit", night)):
        readout[k] = lab.compare(lab.stats(v, "lab"), nref)
    enc = lambda v: lab.to_img(np.clip(v * 0.5 + 0.5, 0, 1))  # noqa: E731
    rows = [[(lab.to_img(raw), "day: raw art"), (lab.to_img(day), "day: relit (key, sky fill, sea bounce, rim, AO)\n" + lab.fmt(readout["day_relit"])),
             (enc(nrm), "normals (layer depth + plate shape)")],
            [(lab.to_img(before_frames[2]), "golden: game light now\n" + lab.fmt(readout["golden_lookdev"])),
             (lab.to_img(gold), "golden: relit, low warm key from the right\n" + lab.fmt(readout["golden_relit"])),
             (lab.to_img(lab.load_rgb(lab.REF["golden"][0], 900)), "reference: I1 summer evening")],
            [(lab.to_img(before_frames[3]), "night: game light now (lookdev)\n" + lab.fmt(readout["night_lookdev"])),
             (lab.to_img(nl_frame), "night: nightlab (delit + pools)\n" + lab.fmt(readout["night_nightlab"])),
             (lab.to_img(night), "night: relit from sources\n" + lab.fmt(readout["night_relit"]))]]
    lab.sheet(rows, a.out_dir / "03-relight.jpg", "Experiment 3: relight with a light rig from estimated normals", cell_h=330)
    (a.out_dir / "relight.json").write_text(json.dumps(readout, indent=1))
    for k, v in readout.items():
        print(k, lab.fmt(v))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
