#!/usr/bin/env python3
"""Nightlab: an offline prototype of a "delit then relit" night for painted sprites.

Decides with evidence, before any Swift, whether the night should stop being one global grade plus
additive pools plus emissive overlays (lookdev's night column) and become a per-layer relight
(research/night-lighting-2d.md section E): unlight the day paint, a hemisphere moon ambient through
normals, point lights with wrap, a fake bounce, rims, emissive overlays unmultiplied, and a mild
shoulder. Every number is in one `PARAMS` dict (override with `--params P.json`, deep-merged).

  python3 -I tools/assets/nightlab.py render design/art/lookdev/home-il1.json --out OUT.jpg [--params P.json]

The sheet: top row = current night (lookdev) | new model | debug (normals above, light-only below);
bottom row = a 2x zoom on the lights, current vs new. Normals come from `normals.py` computed in
memory at working resolution (OpenGL: x right, y up, z to the viewer). Internally the shading uses a
world frame (X right, D toward the viewer, U up); a screen normal (nx, ny, nz) is (nx, nz, ny).

Working in linear light for the lighting, sRGB for compositing (lookdev's grade stays gamma-space).
"""
from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import lookdev as ld  # noqa: E402
import normals as nm  # noqa: E402

REPO = ld.REPO
MASTERS = REPO / "design" / "art" / "masters"

PARAMS: dict = {
    # 1. unlight
    "unlight": {"knee": 0.55, "compress": 0.6, "blur_frac": 0.12, "blur_pow": 0.4},
    # 2. moon ambient (linear multipliers), desaturate only dark pixels, push shadows violet
    "moon": [0.20, 0.26, 0.45],
    "moon_scale": 0.55,
    "desat": {"low": 0.45, "edge0": 0.2, "edge1": 0.6},
    "shadow_violet": 0.12,
    "violet": [0.30, 0.24, 0.56],
    # 3. hemisphere
    "hemi": {"ground": [0.18, 0.14, 0.16], "sky": [0.20, 0.26, 0.45]},
    # 4. point lights
    "light": {"intensity": 1.4, "r_scale": 2.0, "height": 0.35, "forward": 0.25, "wrap": 0.4, "depth_k": 2.0,
              "lantern": "#FFB45A", "emissive_head": True},
    "normal_strength": {"character": 0.7, "decor": 0.5, "plate": 0.35},
    "normals": {"strength": 3.0,
                "character": {"bevel": 0.22, "dome": 0.7, "detail": 0.10},
                "decor": {"bevel": 0.12, "dome": 0.35, "detail": 0.20},
                "plate": {"bevel": 0.05, "dome": 0.25, "detail": 0.05}},
    "albedo_desat": 0.3,
    "flat_up": 0.35,                        # sprites face the viewer, tilted a little toward the sky
    "lawn_up": [0.0, 0.80, 0.60],           # screen-ish up normal of the lawn, (x, U, D)
    # 5. bounce
    "bounce": {"gain": 0.2, "radius": 2.2},
    # 6. rim
    "rim": {"gain": 0.8, "cap": 0.35, "radius": 1.3, "power": 2.5, "moon": 0.5},
    # 7. emissive + haze + pool
    "emissive": {"gain": 1.2, "bloom": 0.25, "bloom_blur": 0.018, "threshold": [0.04, 0.16]},
    "pool_gain": 0.25,
    "haze": 0.05,
    # 8. mild shoulder, sky floor
    "shoulder": {"start": 0.82, "width": 0.18},
    "vignette": 0.30,
    "concept_gain": 2.0,                    # an opaque painted concept has no sky split: lift its moon level
    "sky_floor_L": 12.0,
    "debug_exposure": 1.6,
}


def merge(base: dict, over: dict) -> dict:
    out = copy.deepcopy(base)
    for k, v in over.items():
        out[k] = merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


# ---------------------------------------------------------------- pure maths (tested)

def to_lin(x):
    return np.power(np.clip(x, 0, 1), 2.2)


def to_srgb(x):
    return np.power(np.clip(x, 0, None), 1 / 2.2)


def lum(rgb):
    return rgb @ np.array([0.2126, 0.7152, 0.0722])


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def attenuation(d, radius):
    """saturate(1 - (d/R)^2)^2: smooth, finite radius."""
    return np.clip(1.0 - (np.asarray(d, dtype=np.float64) / radius) ** 2, 0.0, 1.0) ** 2


def wrap(ndl, w):
    return np.clip((ndl + w) / (1.0 + w), 0.0, 1.0)


def hemisphere(n_up, p):
    """mix(ground bounce, sky, N.up*0.5+0.5): (..., 3)."""
    t = (np.asarray(n_up, dtype=np.float64) * 0.5 + 0.5)[..., None]
    g, s = np.array(p["hemi"]["ground"]), np.array(p["hemi"]["sky"])
    return g * (1 - t) + s * t


def unlight(rgb, alpha, p, extent):
    """Step 1 on gamma rgb (h, w, 3): highlight compression, then divide by the blurred
    luminance^0.4 (normalised so the mean stays). The blur would be baked in the game."""
    u = p["unlight"]
    l = lum(rgb)
    c = rgb / (1.0 + u["compress"] * np.maximum(0.0, l - u["knee"]))[..., None]
    l2 = lum(c)
    s = max(u["blur_frac"] * extent, 1.0)
    w = ndimage.gaussian_filter(alpha, s)
    bl = ndimage.gaussian_filter(l2 * alpha, s) / np.maximum(w, 1e-3)
    mean = (bl * alpha).sum() / max(alpha.sum(), 1e-6)
    return c / np.power(np.maximum(bl, 1e-3) / max(mean, 1e-3), u["blur_pow"])[..., None]


# ---------------------------------------------------------------- scene objects

def find_lit(image: str) -> Path | None:
    stem = Path(image).stem
    p = MASTERS / f"{stem}-lit" / f"{stem}-lit.png"
    return p if p.exists() else None


class Light:
    def __init__(self, color, intensity, radius, pos, screen, owner):
        self.color, self.I, self.R = np.array(color), intensity, radius
        self.pos = pos            # (X, D, U) world, D already scaled
        self.screen = screen      # (x, y) canvas pixels of the lamp head
        self.owner = owner
        self.D0 = pos[1]


def bbox_of(layer, floor=0.03):
    a = layer.rgba[..., 3]
    ys, xs = np.nonzero(a > floor)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def build_lights(layers, specs, p, canvas):
    """Lights from layers whose recipe has `light`; placed at the lamp head (lit overlay centroid,
    or the recipe's `at` = (x, y) fractions of the sprite box), not at the feet."""
    w, h = canvas
    kd = p["light"]["depth_k"]
    out, emissives = [], {}
    for layer, spec in zip(layers, specs):
        lit = None
        if find_lit(spec["image"]):
            lspec = dict(spec, image=str(find_lit(spec["image"]).relative_to(REPO)))
            lit = ld.Layer(lspec, canvas)
        x0, y0, x1, y1 = bbox_of(layer)
        if lit is not None:
            crop = lit.rgba[y0:y1, x0:x1]
            base = layer.rgba[y0:y1, x0:x1]
            diff = np.clip(lum(crop[..., :3]) - lum(base[..., :3]), 0, 1) * crop[..., 3]
            m = smoothstep(*p["emissive"]["threshold"], diff)
            m = ndimage.gaussian_filter(m, 0.8)
            emissives[layer.name] = ((x0, y0, x1, y1), crop[..., :3] * m[..., None], m)
        spec_light = spec.get("light")
        if not spec_light:
            continue
        R = spec_light.get("radius", 0.12) * w * p["light"]["r_scale"]
        if layer.name in emissives and spec_light.get("at") is None:
            _, e, m = emissives[layer.name]
            ys, xs = np.mgrid[0:m.shape[0], 0:m.shape[1]]
            wsum = max(m.sum(), 1e-6)
            hx, hy = x0 + (xs * m).sum() / wsum, y0 + (ys * m).sum() / wsum
        else:
            fx, fy = spec_light.get("at", [0.5, 0.3])
            hx, hy = x0 + fx * (x1 - x0), y0 + fy * (y1 - y0)
        foot_y = layer.foot[1]
        pos = (hx, foot_y * kd + p["light"]["forward"] * R, foot_y - hy)
        pos = (pos[0], pos[1], max(pos[2], p["light"]["height"] * R))
        color = ld.hex_rgb(spec_light.get("color", p["light"]["lantern"]))
        out.append(Light(color, spec_light.get("intensity", p["light"]["intensity"]), R, pos, (hx, hy), layer))
        out[-1].D0 = foot_y * kd
    return out, emissives


# ---------------------------------------------------------------- normals

def class_of(layer) -> str:
    return "character" if layer.role == "character" else "decor"


def sprite_normals_screen(rgb, alpha, cls, p):
    """Screen-frame normals (h, w, 3) from normals.py at working resolution."""
    mask = alpha > 0.5
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        return np.broadcast_to(np.array([0, 0, 1.0]), rgb.shape).copy()
    extent = min(ys.max() - ys.min() + 1, xs.max() - xs.min() + 1)
    q = p["normals"][cls]
    bevel = float(np.clip(q["bevel"] * extent, 3.0, 400.0))
    hgt = nm.height_map(rgb, alpha, bevel=bevel, dome=q["dome"], detail=q["detail"])
    # normals.py strengths are tuned for ~600 px sprites; the slope per pixel grows as the sprite shrinks
    n = nm.height_to_normal(hgt, p["normals"]["strength"] * 600.0 / max(extent, 1))
    return np.where(mask[..., None], n, np.array([0, 0, 1.0]))


def to_world(n_screen):
    return np.stack([n_screen[..., 0], n_screen[..., 2], n_screen[..., 1]], axis=-1)


def norm(v):
    return v / np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-9)


def blend_normal(flat_world, baked_world, strength):
    return norm(flat_world * (1 - strength) + baked_world * strength)


# ---------------------------------------------------------------- shading

def shade(rgb_srgb, alpha, nw, X, Y, foot_y, ground, lights, p, extent, wall=None):
    """Relight one layer crop. rgb gamma (h,w,3), alpha (h,w), nw world normals (X, D, U), X/Y canvas
    pixel grids; `ground`: pixels lie on the ground (plate) instead of standing on foot_y.
    Returns (lit sRGB before emissive, light-only linear contribution)."""
    kd = p["light"]["depth_k"]
    un = unlight(rgb_srgb, alpha, p, extent)
    ul = lum(un)[..., None]
    un = ul + (un - ul) * (1.0 - p["albedo_desat"])     # warm light reads warm, not olive, on a green albedo
    albedo = to_lin(un)
    moon = np.array(p["moon"]) * p["moon_scale"]
    amb = hemisphere(nw[..., 2], p) * (moon / np.array(p["hemi"]["sky"]))   # hemisphere carries the moon level
    PX = X
    PD = Y * kd if ground else np.full_like(Y, foot_y * kd)
    PU = np.zeros_like(Y) if ground else foot_y - Y
    if wall is not None:
        # plate pixels that are rock, not lawn: a wall below the lawn edge (depth of the edge, going down)
        edge_y, rock = wall
        PD = np.where(rock, edge_y * kd, PD)
        PU = np.where(rock, -(Y - edge_y), PU)
    diff = np.zeros(alpha.shape + (3,))
    bounce = np.zeros_like(diff)
    rim = np.zeros_like(diff)
    nz_view = np.clip(nw[..., 1], 0, 1)
    edge = np.power(1.0 - nz_view, p["rim"]["power"])
    ordered = sorted(lights, key=lambda l: (l.pos[0] - X.mean()) ** 2 + (l.pos[1] / kd - Y.mean()) ** 2)[:4]
    for L in ordered:
        tx, td, tu = L.pos[0] - PX, L.pos[1] - PD, L.pos[2] - PU
        d = np.sqrt(tx * tx + td * td + tu * tu) + 1e-6
        ndl = (nw[..., 0] * tx + nw[..., 1] * td + nw[..., 2] * tu) / d
        at = attenuation(d, L.R)
        diff += (L.color * L.I)[None, None, :] * (at * wrap(ndl, p["light"]["wrap"]))[..., None]
        bounce += (L.color * L.I * p["bounce"]["gain"])[None, None, :] * attenuation(d, L.R * p["bounce"]["radius"])[..., None]
        # rim: only lights behind or beside the sprite, on edges that face the light on screen
        ux, uy = L.screen[0] - X, Y - L.screen[1]
        un = np.maximum(np.hypot(ux, uy), 1e-6)
        nxy = np.maximum(np.hypot(nw[..., 0], nw[..., 2]), 1e-6)
        facing = np.clip((nw[..., 0] * ux + nw[..., 2] * uy) / (nxy * un), 0, 1)
        behind = np.clip(1.0 - np.maximum(L.D0 - PD, 0.0) / (0.5 * L.R), 0, 1)
        r = (0.0 if ground else 1.0) * p["rim"]["gain"] * edge * facing * behind * attenuation(d, L.R * p["rim"]["radius"])
        rim += (L.color * L.I)[None, None, :] * r[..., None]
    albedo_l = lum(albedo)[..., None]
    rim = np.minimum(rim * (0.4 + albedo_l), p["rim"]["cap"])
    # moon rim: cool, from above and behind, soft
    moon_rim = (np.array(p["hemi"]["sky"]) * p["rim"]["moon"])[None, None, :] * (edge * np.clip(nw[..., 2] + 0.2, 0, 1) * (0.0 if ground else 1.0))[..., None]
    light_only = albedo * (diff + bounce) + rim
    total = albedo * amb + light_only + moon_rim * (0.4 + albedo_l) * 0.5
    s = to_srgb(total)
    # desaturate dark pixels only, push the dark toward blue-violet
    l = lum(s)
    k = p["desat"]["low"] + (1 - p["desat"]["low"]) * smoothstep(p["desat"]["edge0"], p["desat"]["edge1"], l)
    s = l[..., None] + (s - l[..., None]) * k[..., None]
    dark = 1.0 - smoothstep(0.1, 0.45, l)
    v = np.array(p["violet"])
    s = s * (1 - p["shadow_violet"] * dark[..., None]) + p["shadow_violet"] * dark[..., None] * v * (l[..., None] / max(lum(v), 1e-6))
    return s, light_only


def shoulder(x, p):
    a, w = p["shoulder"]["start"], p["shoulder"]["width"]
    return np.where(x < a, x, a + w * np.tanh((x - a) / w))


def lawn_mask(rgb):
    g = smoothstep(-0.03, 0.04, rgb[..., 1] - rgb[..., 0])      # lawn: g >= r; the earth is peach (r > g)
    return ndimage.gaussian_filter(g, 2.0)


def l_star(y):
    y = np.maximum(y, 1e-6)
    return np.where(y > 0.008856, 116 * np.cbrt(y) - 16, 903.3 * y)


def night_sky(cell, canvas, p):
    w, h = canvas
    sky = ld.grade_rgba(np.concatenate([ld.sky_gradient(cell, canvas), np.ones((h, w, 1))], axis=-1),
                        ld.grade_params(cell, sky=True))[..., :3]
    top = to_lin(sky[: max(h // 20, 1)]).mean(axis=(0, 1))
    y = lum(top)
    floor_y = ((p["sky_floor_L"] + 16) / 116) ** 3
    if y < floor_y:
        tint = np.array([0.5, 0.55, 1.0])
        sky = to_srgb(to_lin(sky) + (floor_y - y) * tint / lum(tint))
    return np.clip(sky, 0, 1)


def paste_over(dst, box, rgb, alpha):
    x0, y0, x1, y1 = box
    a = alpha[..., None]
    dst[y0:y1, x0:x1] = dst[y0:y1, x0:x1] * (1 - a) + rgb * a


def render_new(scene, p, cells):
    cell = cells["night"]
    w, h = scene["canvas"]
    bg, kind = ld.load_background(scene["background"], scene["canvas"])
    specs = scene.get("layers", [])
    pairs = sorted(zip((ld.Layer(s, scene["canvas"]) for s in specs), specs), key=lambda t: t[0].y)
    layers = [t[0] for t in pairs]
    specs = [t[1] for t in pairs]
    lights, emissives = build_lights(layers, specs, p, scene["canvas"])

    frame = night_sky(cell, scene["canvas"], p) if kind == "plate" else np.zeros((h, w, 3))
    dbg_n = np.zeros((h, w, 3))
    dbg_l = np.zeros((h, w, 3))
    emissive_canvas = np.zeros((h, w, 3))
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)

    # --- background (plate or concept): its own normals, the lawn mostly facing up
    a = bg[..., 3]
    if kind == "plate":
        bx0, by0, bx1, by1 = ld.alpha_bbox(a)
        box = (bx0, by0, bx1, by1)
    else:
        box = (0, 0, w, h)
    sl_ = (slice(box[1], box[3]), slice(box[0], box[2]))
    rgb, al = bg[sl_][..., :3], a[sl_]
    ns = sprite_normals_screen(rgb, al, "plate", p) if kind == "plate" else None
    up = norm(np.array([p["lawn_up"][0], p["lawn_up"][2], p["lawn_up"][1]]))  # world (X, D, U)
    if kind == "plate":
        lawn = lawn_mask(rgb)[..., None]
        baked = to_world(ns)
        rock_flat = norm(np.array([0.0, 0.9, -0.25]))
        nw_lawn = blend_normal(up, baked, p["normal_strength"]["plate"])
        nw_rock = blend_normal(rock_flat, baked, 0.6)
        nw = norm(lawn * nw_lawn + (1 - lawn) * nw_rock)
        ext = max(box[2] - box[0], box[3] - box[1])
    else:
        # a full painted concept: ground-ish up normal with only the paint's own relief
        ns = sprite_normals_screen(rgb, np.ones_like(al), "plate", p)
        nw = blend_normal(norm(np.array([0.0, 0.65, 0.75])), to_world(ns), 1.0)
        ext = max(w, h)
    pb = p if kind == "plate" else merge(p, {"moon_scale": p["moon_scale"] * p["concept_gain"]})
    wall = None
    if kind == "plate":
        lw = lawn[..., 0] > 0.5
        lab, n = ndimage.label(lw)
        if n > 1:                                                           # the lawn is the biggest green blob
            lw = lab == (1 + int(np.argmax(ndimage.sum(lw, lab, range(1, n + 1)))))
        rows = np.arange(lw.shape[0])[:, None] + box[1]
        edge_y = np.where(lw, rows, -1).max(axis=0)[None, :]
        edge_y = np.where(edge_y < 0, rows, edge_y)                         # no lawn in this column: no wall
        edge_y = ndimage.median_filter(edge_y, size=(1, 41), mode="nearest")
        wall = (np.broadcast_to(edge_y, lw.shape).astype(np.float64), (~ndimage.binary_dilation(lw, iterations=2)) & (al > 0.5))
    lit, lo = shade(rgb, al if kind == "plate" else np.ones_like(al), nw, xs[sl_], ys[sl_], 0, True, lights, pb, ext, wall)
    if p["pool_gain"] > 0 and kind == "plate":
        for L in lights:
            pw = int(2 * L.R / p["light"]["r_scale"] * 1.0)
            pool = ld.Image.fromarray(np.uint8(ld.pool_image() * 255 + 0.5), "L").resize((max(pw, 4), max(pw // 2, 2)))
            canvas_pool = np.zeros((h, w))
            ld.paste(canvas_pool, np.asarray(pool, dtype=np.float64) / 255, int(round(L.screen[0] - pw / 2)),
                     int(round(L.owner.foot[1] - pw / 4)))
            lit = lit + canvas_pool[sl_][..., None] * L.color * p["pool_gain"] * lum(to_lin(rgb))[..., None] ** 0.5 * 0.6
    paste_over(frame, box, lit, al if kind == "plate" else np.ones_like(al))
    dbg_n[sl_] = np.where(al[..., None] > 0.5, to_screen_enc(nw), 0)
    dbg_l[sl_] = to_srgb(lo * p["debug_exposure"]) * (al[..., None] > 0.5)

    # --- shadows: lookdev's moon shadow (faint), under the sprites
    sh = ld.sun_shadow("night", cell)
    for layer in layers:
        if not layer.casts:
            continue
        shadow = ld.blur(ld.project_shadow(layer.sil, layer.foot, sh, (w, h)), sh["softness"] * 0.04 * layer.height_px) * sh["opacity"]
        pad = ld.ellipse_pad((w, h), (layer.foot[0], layer.foot[1] - 0.004 * h), layer.width_px * 0.38,
                             max(layer.width_px * 0.09, 3)) * sh["pad"]
        if kind == "plate":
            shadow, pad = shadow * (a > 0.5), pad * (a > 0.5)
        ld.over(frame, np.array(sh["tint"]), shadow)
        ld.over(frame, np.zeros(3), pad)

    # --- sprites back to front
    for layer in layers:
        x0, y0, x1, y1 = bbox_of(layer)
        sl2 = (slice(y0, y1), slice(x0, x1))
        rgb, al = layer.rgba[sl2][..., :3], layer.rgba[sl2][..., 3]
        cls = class_of(layer)
        ns = sprite_normals_screen(rgb, al, cls, p)
        flat = norm(np.array([0.0, 1.0, p["flat_up"]]))
        nw = blend_normal(flat, to_world(ns), p["normal_strength"][cls])
        lit, lo = shade(rgb, al, nw, xs[sl2], ys[sl2], layer.foot[1], False, lights, p, min(x1 - x0, y1 - y0))
        if layer.name in emissives:
            (ex0, ey0, ex1, ey1), e, m = emissives[layer.name]
            if e.shape[:2] == lit.shape[:2]:
                lit = lit + e * p["emissive"]["gain"]
                emissive_canvas[sl2] += e * p["emissive"]["gain"]
        paste_over(frame, (x0, y0, x1, y1), lit, al)
        dbg_n[sl2] = dbg_n[sl2] * (1 - al[..., None]) + to_screen_enc(nw) * al[..., None]
        dbg_l[sl2] = dbg_l[sl2] * (1 - al[..., None]) + to_srgb(lo * p["debug_exposure"]) * al[..., None]

    # --- light-only bloom + warm haze at each lamp head, then the shoulder
    if emissive_canvas.any():
        bl = ndimage.gaussian_filter(emissive_canvas, (p["emissive"]["bloom_blur"] * w,) * 2 + (0,))
        frame = frame + bl * p["emissive"]["bloom"] * 2.0
    for L in lights:
        d = np.hypot(xs - L.screen[0], (ys - L.screen[1]) * 1.4)
        frame = frame + (attenuation(d, L.R * 0.8)[..., None] * L.color * L.I * p["haze"])
    frame = shoulder(frame, p)
    if p["vignette"] > 0:
        frame = frame * ld.vignette_map(h, w, p["vignette"])
    new_chars = [l for l in layers if l.role == "character"]
    return np.clip(frame, 0, 1), dbg_n, np.clip(dbg_l, 0, 1), lights, new_chars


def to_screen_enc(nw):
    """World normal back to the OpenGL screen encoding the baked maps use."""
    return np.clip(np.stack([nw[..., 0], nw[..., 2], nw[..., 1]], axis=-1) * 0.5 + 0.5, 0, 1)


def render_current(scene, cells):
    bg, kind = ld.load_background(scene["background"], scene["canvas"])
    layers = sorted((ld.Layer(s, scene["canvas"]) for s in scene.get("layers", [])), key=lambda l: l.y)
    for l in layers:
        if l.light and l.light.get("new_only"):
            l.light = None
    frame, _ = ld.render_cell(scene, layers, bg, kind, "night", cells["night"], scene["background"])
    return frame


# ---------------------------------------------------------------- sheet

def img(a, size=None):
    im = Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5), "RGB")
    return im.resize(size, Image.Resampling.LANCZOS) if size else im


def make_sheet(scene, cur, new, dn, dl, lights, chars, out: Path, p):
    w, h = scene["canvas"]
    cw = 800
    ch = int(cw * h / w)
    pad, top = 8, 22
    font = ld.hm._font(15)
    W = pad + 3 * (cw + pad)
    # zoom crop around the lights (or the middle)
    if lights:
        pts = [l.screen for l in lights] + [lights[0].owner.foot] * 0
        xs_ = [q[0] for q in pts] + [c.foot[0] for c in chars[:1]]
        cx = float((min(xs_) + max(xs_)) / 2)
        cy = float(np.mean([l.screen[1] for l in lights])) + 0.06 * h
    else:
        cx, cy = w * 0.4, h * 0.5
    zw, zh = int(0.55 * w), int(0.55 * w * h / w * 0.62)
    x0 = int(np.clip(cx - zw / 2, 0, w - zw))
    y0 = int(np.clip(cy - zh / 2, 0, h - zh))
    zoom = lambda a: img(a[y0:y0 + zh, x0:x0 + zw], (cw, int(cw * zh / zw)))
    zh_px = int(cw * zh / zw)
    sheet = Image.new("RGB", (W, top + ch + pad + top + zh_px + pad), (246, 242, 236))
    d = ImageDraw.Draw(sheet)
    cols = [("current night (lookdev)", img(cur, (cw, ch))), ("new model", img(new, (cw, ch)))]
    for i, (t, im) in enumerate(cols):
        sheet.paste(im, (pad + i * (cw + pad), top))
        d.text((pad + i * (cw + pad), 2), t, font=font, fill=(40, 36, 48))
    x = pad + 2 * (cw + pad)
    hh = (ch - pad) // 2
    d.text((x, 2), "debug: normals / light-only", font=font, fill=(40, 36, 48))
    sheet.paste(img(dn, (cw, hh)), (x, top))
    sheet.paste(img(dl, (cw, hh)), (x, top + hh + pad))
    y = top + ch + pad
    d.text((pad, y - 2), "zoom: current", font=font, fill=(40, 36, 48))
    d.text((pad + cw + pad, y - 2), "zoom: new", font=font, fill=(40, 36, 48))
    sheet.paste(zoom(cur), (pad, y + top - 4))
    sheet.paste(zoom(new), (pad + cw + pad, y + top - 4))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, quality=90)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render")
    r.add_argument("scene", type=Path)
    r.add_argument("--out", type=Path, required=True)
    r.add_argument("--params", type=Path)
    args = ap.parse_args(argv)
    p = PARAMS
    if args.params:
        p = merge(PARAMS, json.loads(args.params.read_text()))
    scene = ld.load_scene(args.scene)
    cells = ld.load_cells()
    cur = render_current(scene, cells)
    new, dn, dl, lights, chars = render_new(scene, p, cells)
    make_sheet(scene, cur, new, dn, dl, lights, chars, args.out, p)
    print(f"wrote {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
