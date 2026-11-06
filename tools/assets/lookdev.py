#!/usr/bin/env python3
"""Lookdev sheet: composite art layers under the game's real light at four hours, and flag layers
that do not sit in the same light.

Founder's ask (2026-11-06): test light and colour harmony with near-game concepts as background,
decor and characters. A scene recipe (`design/art/lookdev/<scene>.json`) lists a background (an
opaque `concept`, or a transparent `plate` that gets the cell's sky) and layers (decor, characters)
standing at a ground point. Each scene renders as one row: dawn, day, golden, night.

The light is a port, not an approximation:

  grade     `WorldGrade.apply` + the vignette of `pofuWorldGrade` (WorldShaders.metal); the values
            come from `design/art/colour-script.json` cells. The sky takes the grade without its
            input levels (`WorldGrade.sky`).
  shadows   `SunShadow.make` + `ShadowTuning`: direction from the sun's screen x, length from its
            height, opacity and softness per hour, the cell's shadow hue at luminance 0.14, the
            moon's faint blue one at night, plus the ambient pad at the feet. A layer's baked
            silhouette (`<name>-shadow.imageset` in the PofuWorld catalog) is used when it exists,
            else one is derived from its alpha (1/4 size, blurred, back up).
  night     the night grade, then an additive warm pool (`glow-ground-pool`) under each layer
            that has a `light`.

Harmony readout: per column and layer, after grading, the mean L*, chroma p95 and white-balance
tint (a*, b* of the near-neutrals, as `harmony.measure`) against the background ground around the
layer's feet (L* and chroma) and the whole graded background (tint: a lawn has no neutrals).
A layer is flagged when |dL| > 18, the chroma ratio is > 1.6 or < 0.55, or the tint is > 8 away.

  python3 -I tools/assets/lookdev.py render design/art/lookdev/<scene>.json --out OUT.jpg
  python3 -I tools/assets/lookdev.py render-all --out-dir DIR

Each sheet gets a `.json` readout next to it.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(HERE))
import harmony as hm  # noqa: E402

sl = hm.sl

SCRIPT = REPO / "design" / "art" / "colour-script.json"
SCENES = REPO / "design" / "art" / "lookdev"
CATALOG = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "World.xcassets"
HOURS = ["dawn", "day", "golden", "night"]

# ShadowTuning.swift, one place so a Swift change is one edit here.
TOWARD_CAMERA = 0.4
FORESHORTENING = 0.5
LENGTH_BY_SUN_Y = [(0.11, 0.35), (0.20, 0.90), (0.30, 1.80), (0.36, 2.40)]
OPACITY = {"day": 0.50, "golden": 0.52, "dawn": 0.34, "night": 0.10}
SOFTNESS = {"day": 0.25, "golden": 0.55, "dawn": 0.85, "night": 0.90}
MOON_LENGTH = 1.2
MOON_TINT = (0.10, 0.14, 0.30)
TINT_LUMINANCE = 0.14
PAD_OPACITY = {"day": 0.38, "golden": 0.38, "dawn": 0.38, "night": 0.42}

# Flag thresholds (the brief).
FLAG_DL = 18.0
FLAG_CHROMA_HI = 1.6
FLAG_CHROMA_LO = 0.55
FLAG_TINT = 8.0


# ---------------------------------------------------------------- grade

def hex_rgb(h: str) -> tuple[float, float, float]:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def load_cells(path: Path = SCRIPT) -> dict:
    return json.loads(path.read_text())["cells"]


def grade_params(cell: dict, sky: bool = False) -> dict:
    """The cell's grade with WorldGrade's defaults; `sky` drops the input levels."""
    g = cell["grade"]
    return {
        "black": 0.0 if sky else g.get("black", 0.0),
        "white": 1.0 if sky else g.get("white", 1.0),
        "lift": g.get("lift", [0, 0, 0]),
        "gamma": g.get("gamma", [1, 1, 1]),
        "gain": g.get("gain", [1, 1, 1]),
        "contrast": g.get("contrast", 1.0),
        "pivot": g.get("pivot", 0.55),
        "saturation": g.get("saturation", 1.0),
        "vignette": g.get("vignette", 0.0),
    }


def apply_grade(rgb: np.ndarray, p: dict) -> np.ndarray:
    """WorldGrade.apply / the shader's `grade` on gamma-encoded rgb (..., 3), 0..1."""
    x = np.asarray(rgb, dtype=np.float64)
    span = max(p["white"] - p["black"], 1e-3)
    lift, gamma, gain = (np.asarray(p[k], dtype=np.float64) for k in ("lift", "gamma", "gain"))
    x = (x - p["black"]) / span
    x = gain * (x + lift * (1 - x))
    x = np.maximum(x, 0) ** (1 / np.maximum(gamma, 0.01))
    x = (x - p["pivot"]) * p["contrast"] + p["pivot"]
    luma = x @ np.array([0.2126, 0.7152, 0.0722])
    x = luma[..., None] + (x - luma[..., None]) * p["saturation"]
    return np.clip(x, 0, 1)


def vignette_map(h: int, w: int, strength: float) -> np.ndarray:
    """The shader's elliptical vignette: factors (h, w, 3), a little warm."""
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    u = ((xs + 0.5) / w - 0.5) * 2.0
    v = ((ys + 0.5) / h - 0.5) * 2.0
    d = np.sqrt(u ** 2 + (v * 0.9) ** 2) / 1.345
    t = np.clip((d - 0.3) / 0.7, 0, 1)
    f = 1.0 - strength * t ** 1.6
    return np.stack([f, f + (1 - f) * 0.06, f + (1 - f) * 0.02], axis=-1)


def grade_rgba(rgba: np.ndarray, p: dict) -> np.ndarray:
    """Grade + vignette on a full-canvas RGBA (straight alpha); alpha is kept."""
    out = rgba.copy()
    out[..., :3] = apply_grade(rgba[..., :3], p) * vignette_map(*rgba.shape[:2], p["vignette"])
    return out


# ---------------------------------------------------------------- sun shadow

def shadow_length(sun_y: float) -> float:
    t = LENGTH_BY_SUN_Y
    if not sun_y > t[0][0]:
        return t[0][1]
    if sun_y >= t[-1][0]:
        return t[-1][1]
    for (y0, l0), (y1, l1) in zip(t, t[1:]):
        if sun_y <= y1:
            return l0 + (l1 - l0) * (sun_y - y0) / (y1 - y0)
    return t[-1][1]


def darkened(rgb, luminance: float):
    lum = 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
    if lum <= 1e-6:
        return (luminance,) * 3
    k = luminance / lum
    return tuple(min(c * k, 1.0) for c in rgb)


def sun_shadow(hour: str, cell: dict) -> dict:
    """SunShadow.make for one hour: direction (dx, dy), length, opacity, softness, tint, pad."""
    sun_x, sun_y = cell["sun"]
    gx, gy = 0.5 - sun_x, TOWARD_CAMERA
    n = max(math.hypot(gx, gy), 1e-9)
    ax, ay = gx / n, gy / n
    night = hour == "night"
    return {
        "hour": hour,
        "dx": ax,
        "dy": ay * FORESHORTENING,
        "length": MOON_LENGTH if night else shadow_length(sun_y),
        "opacity": OPACITY[hour],
        "softness": SOFTNESS[hour],
        "tint": MOON_TINT if night else darkened(hex_rgb(cell["shadow"]), TINT_LUMINANCE),
        "pad": PAD_OPACITY[hour],
    }


def project_shadow(mask: np.ndarray, foot: tuple[float, float], sh: dict, size: tuple[int, int]) -> np.ndarray:
    """Shear a silhouette (alpha, canvas-sized, 0..1) flat onto the ground: a point `h` above
    the foot lands at foot + direction * length * h (SunShadow.cast)."""
    fx, fy = foot
    k = sh["dy"] * sh["length"]
    if k <= 1e-6:
        return np.zeros_like(mask)
    # Output (X, Y) -> source (x, y): h = (Y - fy) / k, x = X - dx*length*h, y = fy - h.
    sx = sh["dx"] * sh["length"]
    a, b, c = 1.0, -sx / k, sx / k * fy
    d, e, f = 0.0, -1.0 / k, fy + fy / k
    im = Image.fromarray(np.uint8(np.clip(mask, 0, 1) * 255 + 0.5), "L")
    out = im.transform(size, Image.Transform.AFFINE, (a, b, c, d, e, f), resample=Image.Resampling.BILINEAR)
    return np.asarray(out, dtype=np.float64) / 255


def blur(a: np.ndarray, radius: float) -> np.ndarray:
    if radius < 0.5:
        return a
    im = Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5), "L").filter(ImageFilter.GaussianBlur(radius))
    return np.asarray(im, dtype=np.float64) / 255


def derive_silhouette(alpha: np.ndarray) -> np.ndarray:
    """No baked shadow: alpha at 1/4 size, blurred, back up."""
    h, w = alpha.shape
    im = Image.fromarray(np.uint8(alpha * 255 + 0.5), "L")
    small = im.resize((max(w // 4, 1), max(h // 4, 1)), Image.Resampling.BOX).filter(ImageFilter.GaussianBlur(1.5))
    return np.asarray(small.resize((w, h), Image.Resampling.BILINEAR), dtype=np.float64) / 255


def baked_shadow_path(image: Path, explicit: str | None = None) -> Path | None:
    if explicit:
        p = REPO / explicit
        return p if p.exists() else None
    stem = image.stem
    for name in (f"{stem}-shadow", f"world-{stem}-shadow"):
        p = CATALOG / f"{name}.imageset" / f"{name}.png"
        if p.exists():
            return p
    return None


# ---------------------------------------------------------------- scene loading

def load_rgba(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64) / 255


def to_image(a: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5), "RGBA")


def alpha_bbox(alpha: np.ndarray, floor: float = 0.03) -> tuple[int, int, int, int]:
    ys, xs = np.nonzero(alpha > floor)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


class Layer:
    """One sprite placed on the canvas: pixels, silhouette, foot point, all canvas-sized."""

    def __init__(self, spec: dict, canvas: tuple[int, int]):
        w, h = canvas
        path = REPO / spec["image"]
        self.name = spec.get("name") or Path(spec["image"]).stem
        self.role = spec.get("role", "decor")
        self.casts = bool(spec.get("casts", True))
        self.light = spec.get("light")
        self.y = float(spec["y"])
        src = load_rgba(path)
        x0, y0, x1, y1 = alpha_bbox(src[..., 3])
        shadow_src = None
        sp = baked_shadow_path(path, spec.get("shadow"))
        if sp is not None:
            sm = np.asarray(Image.open(sp).convert("RGBA"), dtype=np.float64)[..., 3] / 255
            shadow_src = np.asarray(
                Image.fromarray(np.uint8(sm * 255 + 0.5), "L").resize(src.shape[1::-1], Image.Resampling.BILINEAR),
                dtype=np.float64) / 255
        self.baked_shadow = shadow_src is not None
        crop = src[y0:y1, x0:x1]
        sil = (shadow_src if shadow_src is not None else derive_silhouette(src[..., 3]))[y0:y1, x0:x1]
        th = max(int(round(float(spec["height"]) * h)), 2)
        tw = max(int(round(crop.shape[1] * th / crop.shape[0])), 2)
        img = to_image(crop).resize((tw, th), Image.Resampling.LANCZOS)
        sil_img = Image.fromarray(np.uint8(np.clip(sil, 0, 1) * 255 + 0.5), "L").resize((tw, th), Image.Resampling.BILINEAR)
        self.width_px, self.height_px = tw, th
        self.foot = (float(spec["x"]) * w, self.y * h)
        ox = int(round(self.foot[0] - tw / 2))
        oy = int(round(self.foot[1] - th))
        self.rgba = np.zeros((h, w, 4))
        self.sil = np.zeros((h, w))
        paste(self.rgba, np.asarray(img, dtype=np.float64) / 255, ox, oy)
        paste(self.sil, np.asarray(sil_img, dtype=np.float64) / 255, ox, oy)


def paste(dst: np.ndarray, src: np.ndarray, ox: int, oy: int) -> None:
    h, w = dst.shape[:2]
    sh, sw = src.shape[:2]
    x0, y0 = max(ox, 0), max(oy, 0)
    x1, y1 = min(ox + sw, w), min(oy + sh, h)
    if x1 > x0 and y1 > y0:
        dst[y0:y1, x0:x1] = src[y0 - oy:y1 - oy, x0 - ox:x1 - ox]


def load_background(spec: dict, canvas: tuple[int, int]) -> tuple[np.ndarray, str]:
    """A canvas-sized RGBA: a concept covers the canvas, a plate is cropped and fitted."""
    w, h = canvas
    kind = spec.get("kind", "plate")
    src = load_rgba(REPO / spec["image"])
    if kind == "plate" and src[..., 3].min() > 0.99:
        kind = "concept"  # an opaque "plate" has no sky to show: grade it like the world
    out = np.zeros((h, w, 4))
    if kind == "concept":
        im = to_image(src)
        s = max(w / im.width, h / im.height)
        im = im.resize((math.ceil(im.width * s), math.ceil(im.height * s)), Image.Resampling.LANCZOS)
        l, t = (im.width - w) // 2, (im.height - h) // 2
        out[:] = np.asarray(im, dtype=np.float64)[t:t + h, l:l + w] / 255
        out[..., 3] = 1.0
        return out, kind
    x0, y0, x1, y1 = alpha_bbox(src[..., 3])
    crop = to_image(src[y0:y1, x0:x1])
    fit = float(spec.get("fit", 0.9))
    s = min(w * fit / crop.width, h * fit / crop.height)
    crop = crop.resize((max(int(crop.width * s), 1), max(int(crop.height * s), 1)), Image.Resampling.LANCZOS)
    cy = float(spec.get("center_y", 0.55))
    paste(out, np.asarray(crop, dtype=np.float64) / 255, (w - crop.width) // 2, int(h * cy - crop.height / 2))
    return out, kind


def sky_gradient(cell: dict, canvas: tuple[int, int]) -> np.ndarray:
    """Zenith at the top to the horizon colour at 70 % height (rgb, ungraded)."""
    w, h = canvas
    z, hz = np.array(hex_rgb(cell["sky"]["zenith"])), np.array(hex_rgb(cell["sky"]["horizon"]))
    t = np.clip(np.linspace(0, 1, h) / 0.7, 0, 1)[:, None, None]
    return np.broadcast_to(z * (1 - t) + hz * t, (h, w, 3)).copy()


# ---------------------------------------------------------------- compositing

def over(dst: np.ndarray, rgb: np.ndarray, alpha: np.ndarray) -> None:
    a = alpha[..., None]
    dst[:] = dst * (1 - a) + rgb * a


def pool_image() -> np.ndarray:
    p = CATALOG / "glow-ground-pool.imageset" / "glow-ground-pool.png"
    if p.exists():
        return np.asarray(Image.open(p).convert("RGBA"), dtype=np.float64)[..., 3] / 255
    ys, xs = np.mgrid[0:256, 0:512]
    d = np.hypot((xs - 255.5) / 256, (ys - 127.5) / 128)
    return np.clip(1 - d, 0, 1) ** 2


def add_pool(canvas_rgb: np.ndarray, layer: Layer, gain: float) -> None:
    """An additive warm pool on the ground at the layer's feet."""
    light = layer.light
    h, w = canvas_rgb.shape[:2]
    pw = max(int(2 * float(light.get("radius", 0.2)) * w), 4)
    ph = max(pw // 2, 2)
    pool = np.asarray(Image.fromarray(np.uint8(pool_image() * 255 + 0.5), "L").resize((pw, ph), Image.Resampling.BILINEAR),
                      dtype=np.float64) / 255
    layer_pool = np.zeros((h, w))
    paste(layer_pool, pool, int(round(layer.foot[0] - pw / 2)), int(round(layer.foot[1] - ph / 2)))
    colour = np.array(hex_rgb(light.get("color", "#FFB36B")))
    canvas_rgb += layer_pool[..., None] * colour * gain
    np.clip(canvas_rgb, 0, 1, out=canvas_rgb)


def ellipse_pad(size: tuple[int, int], foot: tuple[float, float], rx: float, ry: float) -> np.ndarray:
    w, h = size
    ys, xs = np.mgrid[0:h, 0:w]
    d = ((xs - foot[0]) / rx) ** 2 + ((ys - foot[1]) / ry) ** 2
    return blur(np.clip(1.0 - d, 0, 1) ** 0.5, max(rx * 0.12, 1))


def lab_stats(rgb: np.ndarray, weight: np.ndarray | None = None) -> dict | None:
    """Mean L*, chroma p95 and near-neutral tint of rgb (n, 3)."""
    if len(rgb) < 20:
        return None
    lab = sl.srgb_to_lab(np.clip(rgb, 0, 1))
    L, C, _ = sl.lch(lab)
    out = {"L": float(L.mean()), "C95": float(np.percentile(C, 95))}
    neutral = (C < 14) & (L > 55)
    if neutral.sum() >= max(50, 0.01 * len(L)):
        out["tint"] = (float(lab[neutral, 1].mean()), float(lab[neutral, 2].mean()))
    return out


def ground_box(bg_rgb: np.ndarray, bg_alpha: np.ndarray, layer: Layer) -> np.ndarray:
    """Graded background pixels around the layer's feet, as the ground it stands on."""
    h, w = bg_alpha.shape
    fx, fy = layer.foot
    for grow in (1.0, 1.8, 3.0):
        hw = max(layer.width_px * 0.65 * grow, 0.06 * w)
        x0, x1 = int(max(fx - hw, 0)), int(min(fx + hw, w))
        y0, y1 = int(max(fy - 0.07 * h * grow, 0)), int(min(fy + 0.05 * h * grow, h))
        box = bg_rgb[y0:y1, x0:x1][bg_alpha[y0:y1, x0:x1] > 0.5]
        if len(box) >= 200:
            return box
    return box


def flag_layer(layer_stats: dict, ground: dict | None, bg_tint: tuple[float, float] | None) -> dict:
    res = {"L": round(layer_stats["L"], 1), "C95": round(layer_stats["C95"], 1), "flags": []}
    if ground:
        dl = layer_stats["L"] - ground["L"]
        ratio = layer_stats["C95"] / max(ground["C95"], 1e-6)
        res["dL"], res["chroma_ratio"] = round(dl, 1), round(ratio, 2)
        if abs(dl) > FLAG_DL:
            res["flags"].append(f"dL {dl:+.0f}")
        if ratio > FLAG_CHROMA_HI or ratio < FLAG_CHROMA_LO:
            res["flags"].append(f"chroma x{ratio:.2f}")
    if "tint" in layer_stats and bg_tint is not None:
        dist = math.hypot(layer_stats["tint"][0] - bg_tint[0], layer_stats["tint"][1] - bg_tint[1])
        res["tint_dist"] = round(dist, 1)
        if dist > FLAG_TINT:
            res["flags"].append(f"tint {dist:.0f}")
    res["flagged"] = bool(res["flags"])
    return res


def render_cell(scene: dict, layers: list[Layer], bg: np.ndarray, kind: str, hour: str, cell: dict,
                spec_bg: dict) -> tuple[np.ndarray, dict]:
    """One column: the composited frame (rgb 0..1) and the harmony readout."""
    canvas = scene["canvas"]
    w, h = canvas
    full, sky = grade_params(cell), grade_params(cell, sky=True)
    frame = np.zeros((h, w, 3))
    if kind == "concept":
        gbg = grade_rgba(bg, full)
        frame[:] = gbg[..., :3]
        bg_alpha = np.ones((h, w))
    else:
        s = grade_rgba(np.concatenate([sky_gradient(cell, canvas), np.ones((h, w, 1))], axis=-1), sky)
        frame[:] = s[..., :3]
        gbg = grade_rgba(bg, sky)
        over(frame, gbg[..., :3], bg[..., 3])
        bg_alpha = bg[..., 3]
    bg_rgb = gbg[..., :3]
    # Whole-background tint (near-neutrals), over the opaque pixels.
    bg_stats = lab_stats(bg_rgb[bg_alpha > 0.5])
    bg_tint = bg_stats.get("tint") if bg_stats else None

    # Shadows under all layers.
    sh = sun_shadow(hour, cell)
    tint = np.array(sh["tint"])
    for layer in layers:
        if not layer.casts:
            continue
        blur_r = sh["softness"] * 0.04 * layer.height_px
        shadow = project_shadow(layer.sil, layer.foot, sh, (w, h))
        shadow = blur(shadow, blur_r) * sh["opacity"]
        if kind == "plate":
            shadow = shadow * (bg_alpha > 0.5)
        over(frame, tint, shadow)
        pad = ellipse_pad((w, h), (layer.foot[0], layer.foot[1] - 0.004 * h), layer.width_px * 0.38,
                          max(layer.width_px * 0.09, 3)) * sh["pad"]
        if kind == "plate":
            pad = pad * (bg_alpha > 0.5)
        over(frame, np.zeros(3), pad)

    # Night pools, additive, under the layers.
    if hour == "night":
        gain = cell["light"].get("poolGain", 1.0)
        for layer in layers:
            if layer.light:
                add_pool(frame, layer, gain * 0.5)

    # Layers by y, each graded with the same cell; measure on opaque pixels after grading.
    readout = {}
    for layer in layers:
        g = grade_rgba(layer.rgba, full)
        over(frame, g[..., :3], g[..., 3])
        solid = g[..., 3] > 0.5
        stats = lab_stats(g[..., :3][solid])
        ground = lab_stats(ground_box(bg_rgb, bg_alpha, layer))
        if stats:
            readout[layer.name] = flag_layer(stats, ground, bg_tint)
            readout[layer.name]["role"] = layer.role
            if ground:
                readout[layer.name]["ground_L"] = round(ground["L"], 1)
                readout[layer.name]["ground_C95"] = round(ground["C95"], 1)
    return np.clip(frame, 0, 1), readout


def load_scene(path: Path) -> dict:
    scene = json.loads(Path(path).read_text())
    scene.setdefault("title", Path(path).stem)
    scene["canvas"] = tuple(scene["canvas"])
    return scene


def render_scene(scene: dict, cells: dict | None = None) -> tuple[list[np.ndarray], dict]:
    cells = cells or load_cells()
    bg, kind = load_background(scene["background"], scene["canvas"])
    layers = sorted((Layer(s, scene["canvas"]) for s in scene.get("layers", [])), key=lambda l: l.y)
    frames, readout = [], {}
    for hour in HOURS:
        frame, ro = render_cell(scene, layers, bg, kind, hour, cells[hour], scene["background"])
        frames.append(frame)
        readout[hour] = ro
    return frames, readout


# ---------------------------------------------------------------- sheet

LABEL_W = 150
PAD = 8
ROW_H = 17
RED = (214, 40, 40)
INK = (40, 36, 48)
PAPER = (246, 242, 236)


def sheet(scenes: list[tuple[dict, list[np.ndarray], dict]], path: Path, max_width: int = 2400) -> None:
    ncol = len(HOURS)
    col_w = (max_width - LABEL_W - PAD * (ncol + 1)) // ncol
    font, small = hm._font(15), hm._font(13)
    rows = []
    for scene, frames, readout in scenes:
        w, h = scene["canvas"]
        ch = int(round(col_w * h / w))
        names = [n for n in readout[HOURS[0]]] if readout[HOURS[0]] else []
        table_h = ROW_H * (len(names) + 2) + 6
        rows.append((scene, frames, readout, ch, table_h, names))
    total_h = PAD + sum(r[3] + r[4] + 24 + PAD for r in rows)
    img = Image.new("RGB", (max_width, total_h), PAPER)
    d = ImageDraw.Draw(img)
    y = PAD
    for scene, frames, readout, ch, table_h, names in rows:
        d.text((PAD, y + 4), scene["title"], font=font, fill=INK)
        d.text((PAD, y + 24), f"{scene['background'].get('kind', 'plate')} bg", font=small, fill=(110, 104, 120))
        for i, hour in enumerate(HOURS):
            x = LABEL_W + PAD + i * (col_w + PAD)
            d.text((x, y), hour, font=font, fill=INK)
            fr = Image.fromarray(np.uint8(frames[i] * 255 + 0.5), "RGB").resize((col_w, ch), Image.Resampling.LANCZOS)
            img.paste(fr, (x, y + 22))
            ty = y + 22 + ch + 4
            d.text((x, ty), f"{'layer':<14}{'dL':>6}{'C x':>7}{'tint':>6}", font=small, fill=(110, 104, 120))
            for j, name in enumerate(names):
                r = readout[hour].get(name)
                if not r:
                    continue
                dl = f"{r['dL']:+.0f}" if "dL" in r else "-"
                cr = f"{r['chroma_ratio']:.2f}" if "chroma_ratio" in r else "-"
                tt = f"{r['tint_dist']:.0f}" if "tint_dist" in r else "-"
                line = f"{name[:14]:<14}{dl:>6}{cr:>7}{tt:>6}"
                d.text((x, ty + ROW_H * (j + 1)), line, font=small, fill=RED if r["flagged"] else INK)
        y += ch + table_h + 24 + PAD
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, quality=88)


def write_json(readout: dict, scene: dict, path: Path) -> None:
    path.with_suffix(".json").write_text(json.dumps({"title": scene["title"], "hours": readout}, indent=2))


def render_one(scene_path: Path, out: Path, cells: dict | None = None) -> dict:
    scene = load_scene(scene_path)
    frames, readout = render_scene(scene, cells)
    sheet([(scene, frames, readout)], out)
    write_json(readout, scene, out)
    return readout


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("render", help="render one scene recipe to a sheet")
    r.add_argument("scene", type=Path)
    r.add_argument("--out", type=Path, required=True)
    ra = sub.add_parser("render-all", help="render every recipe in design/art/lookdev")
    ra.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args(argv)
    if args.cmd == "render":
        ro = render_one(args.scene, args.out)
        reports = {args.scene.stem: ro}
    else:
        reports = {}
        for p in sorted(SCENES.glob("*.json")):
            reports[p.stem] = render_one(p, args.out_dir / f"{p.stem}.jpg")
    for name, ro in reports.items():
        for hour, layers in ro.items():
            for layer, r in layers.items():
                if r["flagged"]:
                    print(f"{name} {hour} {layer}: {', '.join(r['flags'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
