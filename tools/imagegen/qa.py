"""Post-processing and QA checks for generated takes.

`process_take` is the whole chain for one raw take:

1. normalize: alpha from a chroma key if the backend returned an opaque
   image (process_assets.key_background), then fit to the kind's canvas;
2. register: stations are moved so their footprint sits on the anchor
   (chain roots only; edits inherit the root's transform so a level chain
   never shifts);
3. style lock (style_lock.py, preset by kind);
4. checks, each `pass`, `warn` or `fail`.

Every check is a pure function of arrays, so it is unit-tested on Linux.
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "assets"))
import process_assets as pa  # noqa: E402
import style_lock as sl  # noqa: E402
import light as lt  # noqa: E402

ORDER = {"pass": 0, "warn": 1, "fail": 2}

# Station guide (tools/art/island_guides.py): footprint ellipse centered at
# (512, 800), radii 360 x 108, height bar to y = 150, on a 1024 canvas.
# An object standing on the ellipse has its lowest pixels on the front half
# of the ellipse (y 800...908), so the anchor check looks at that band.
STATION = {"cx": 512, "cy": 800, "rx": 360, "ry": 108, "top": 150, "baseline_target": 900}

# The decor guide (design/art/templates/decor-guide.png, tools/art/island_guides.py):
# half a station's footprint, a 340 px height bar, a hang line at y 300 that a
# hanging piece stays under and above y 620.
DECOR = {"cx": 512, "cy": 840, "rx": 180, "ry": 54, "top": 500, "baseline_target": 888,
         "hang_y": 300, "hang_floor": 620, "hang_width": 560}

# Thresholds on the locked image, derived from R1 (art-direction study).
DEFAULT_LIMITS = {
    "chroma_p95": {"warn": 52.0, "fail": 60.0},
    "value_floor": {"warn": 35.0, "fail": 25.0},       # L p5 must stay at or above
    "detail": {"warn": 6.0, "fail": 7.5},              # Laplacian at display size, R1 = 5.3
    "lock_load": {"warn": 10.0, "fail": 18.0},         # mean Delta E the lock had to move
    "edit_kept": {"warn": 0.75, "fail": 0.55},         # share of the parent left unchanged
    "edit_chroma": {"warn": 0.85, "fail": 0.70},       # child / parent median chroma on the kept area
    "harmony": {"warn": 70.0, "fail": 0.0},            # harmony score (tools/assets/harmony.py): advisory, harmony corrects
    "depth_ratio": {"warn": 0.32, "fail": 0.42},       # island earth depth / width
    # The other side (look round 2: "too squashed"): an earth body too thin to
    # read as soil and rock. Off by default; plate jobs set it.
    "depth_floor": {"warn": 0.0, "fail": 0.0},
    "lawn_chroma": {"warn": 38.0, "fail": 46.0},       # p95 chroma of lawn greens
    "magenta_px": {"warn": 40, "fail": 300},           # guide remnants (pixels at 1024)
}
LIMITS_BY_KIND = {
    # Characters keep their fur detail and their own palette; only the
    # generic checks apply, with R1's own envelope.
    "char": {"chroma_p95": {"warn": 56.0, "fail": 64.0}, "value_floor": {"warn": 50.0, "fail": 40.0},
             "detail": {"warn": 7.0, "fail": 9.0}},
    "appicon": {"chroma_p95": {"warn": 56.0, "fail": 64.0}, "detail": {"warn": 7.0, "fail": 9.0}},
    # Icons need one darker accent to read on light glass (ADR-0018), so
    # their value floor is lower than a prop's.
    "icon": {"value_floor": {"warn": 25.0, "fail": 15.0}},
    # Crafted UI pieces carry saturated accents on purpose (a violet primary
    # face, a sunflower bloom, a lit lantern): batch 11-12 measured p95
    # chroma 55-60 on those. Same envelope as characters.
    "ui": {"chroma_p95": {"warn": 56.0, "fail": 64.0}},
}
# An edit declares what it changes with `acceptance: {edit_mode: ...}`:
#   keep    (default) the edit adds a part; everything else keeps its colors.
#   region  the edit repaints a large part of the object (fill a jar window,
#           light a lantern): edit_stability is relaxed, the shape must hold.
#   recolor the edit changes the glaze of the whole object: colors are not
#           compared; shape and light structure must hold.
EDIT_MODES = ("keep", "region", "recolor")
SILHOUETTE = {"warn": 0.93, "fail": 0.85}           # alpha IoU with the parent
STRUCTURE = {"warn": 0.80, "fail": 0.60}            # lightness correlation with the parent (recolor)
LIGHTNESS_SHIFT = {"warn": 10.0, "fail": 18.0}      # mean |L shift| (recolor: "the same lightness")
REGION_EDIT_KEPT = {"warn": 0.50, "fail": 0.30}

# Exploration jobs (ids x-*, x2-*, or acceptance `exploration: true`; batches
# 15-17) are looked at by the founder, not gated: every automated check is
# advisory (warn, never fail) EXCEPT these hard ones: transparency, size and
# decoding, and the legibility of a job's REQUIRED TEXT (read on the contact
# sheet; a check named `text_legibility`, if a backend adds one, stays hard).
EXPLORATION_HARD = {"transparency", "canvas", "opaque_pixels", "appicon_opaque", "text_legibility"}

# Night / dark variants (acceptance `profile: night`): the brief asks for a
# dark value range, so the default value floor and the "same lightness as the
# parent" check of a recolor do not apply. Instead the median lightness of the
# take must sit in a dark band.
NIGHT_PROFILE = {
    "value_floor": {"warn": 12.0, "fail": 4.0},
    "median_L": {"pass": (18.0, 50.0), "warn": (10.0, 60.0)},
}


# Additive glow sprites (manifest `blend: additive`, carried in acceptance):
# painted on pure black, the app adds them with plus-lighter blending, so
# black is no light. Value floor and palette drift do not apply (the black IS
# the content); instead the background must be near-black, chroma is measured
# on the lit pixels only, and the falloff must be soft and unbanded.
BLENDS = ("additive",)
ADDITIVE = {
    "lit_luma": 0.12,                                  # pixels above this (0..1 luma) count as the glow
    "chroma_p95": {"warn": 78.0, "fail": 90.0},        # honey-gold fades through #FF9F4A (C ~ 66)
    "bg_luma_p99": {"warn": 0.05, "fail": 0.10},       # border band must stay black
    # Hard edge: share of pixels whose luma step exceeds `edge_step` per px at
    # 256 px. A lit window's sill is one deliberate crisp edge (0.3-0.5 percent
    # of the image); a hard disc is 2 percent.
    "edge_step": 0.08,
    "edge_share": {"warn": 0.008, "fail": 0.015},
    "levels": {"warn": 0.60, "fail": 0.40},            # occupied 8-bit levels / span of the falloff: banding
    "min_lit": 0.01,                                   # the glow must cover at least 1 percent of the image
}


def is_exploration(job_id: str | None = None, acceptance: dict | None = None) -> bool:
    return bool((acceptance or {}).get("exploration")) or bool(job_id and re.match(r"^x\d*-", job_id))


def advisory(checks: list["Check"]) -> list["Check"]:
    """Downgrade every failing style check to a warning; the hard checks stay."""
    for c in checks:
        if c.status == "fail" and c.name not in EXPLORATION_HARD:
            c.status = "warn"
            c.message += " (advisory in an exploration)"
    return checks


@dataclass
class Check:
    name: str
    status: str
    message: str
    value: float | None = None

    def as_dict(self) -> dict:
        d = {"check": self.name, "status": self.status, "message": self.message}
        if self.value is not None:
            d["value"] = round(float(self.value), 4)
        return d


@dataclass
class TakeResult:
    raw: np.ndarray
    normalized: np.ndarray
    locked: np.ndarray
    checks: list[Check] = field(default_factory=list)
    info: dict = field(default_factory=dict)

    @property
    def status(self) -> str:
        return worst(c.status for c in self.checks)


def worst(statuses) -> str:
    s = "pass"
    for x in statuses:
        if ORDER[x] > ORDER[s]:
            s = x
    return s


def grade(value: float, limits: dict, higher_is_worse: bool = True) -> str:
    if higher_is_worse:
        return "fail" if value > limits["fail"] else "warn" if value > limits["warn"] else "pass"
    return "fail" if value < limits["fail"] else "warn" if value < limits["warn"] else "pass"


def limits_for(kind: str, overrides: dict | None = None) -> dict:
    out = {k: dict(v) for k, v in DEFAULT_LIMITS.items()}
    for k, v in LIMITS_BY_KIND.get(kind, {}).items():
        out[k] = dict(v)
    for k, v in (overrides or {}).items():
        if isinstance(v, dict) and k in out:
            out[k].update(v)
    return out


# ---------------------------------------------------------------------------
# Normalization
# ---------------------------------------------------------------------------

def has_meaningful_alpha(rgba: np.ndarray) -> bool:
    return float((rgba[..., 3] < 0.98).mean()) > 0.01


def ensure_alpha(rgba: np.ndarray) -> tuple[np.ndarray, Check]:
    """Keep real transparency; otherwise key a flat border-connected background."""
    if has_meaningful_alpha(rgba):
        return rgba, Check("transparency", "pass", "source has an alpha channel")
    try:
        keyed, info = pa.key_background(rgba)
    except ValueError as err:
        return rgba, Check("transparency", "fail", f"opaque and not keyable: {err}")
    leak = info["interiorHoleFraction"]
    if leak > pa.KEY_LEAK_MAX:
        return keyed, Check("transparency", "fail", f"keying {info['keyedColor']} leaked into the object ({leak:.1%})", leak)
    return keyed, Check("transparency", "warn", f"opaque source; keyed out {info['keyedColor']} (inspect the edges)", leak)


def fit_canvas(rgba: np.ndarray, size: tuple[int, int] | None, cover: bool = False,
               declared: tuple[int, int] | None = None) -> tuple[np.ndarray, Check]:
    """Scale into the kind's canvas. Sprites are never cropped (padded with
    transparency); opaque kinds (`cover`) are scaled to fill and center-cropped.

    `declared` is the job's own `size` (what the image model is asked to draw).
    A source of exactly that size is cropped and upscaled to the job's canvas
    on purpose (a 1024 x 1536 sky covering a 1290 x 2796 phone), so the upscale
    is reported as a pass; any other source size still warns."""
    h, w = rgba.shape[:2]
    if size is None:
        return rgba, Check("canvas", "pass", f"kept {w}x{h}")
    W, H = size
    if (w, h) == (W, H):
        return rgba, Check("canvas", "pass", f"{w}x{h}")
    if cover:
        s = max(W / w, H / h)
        im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
        im = im.resize((max(W, round(w * s)), max(H, round(h * s))), Image.Resampling.LANCZOS)
        x0, y0 = (im.width - W) // 2, (im.height - H) // 2
        im = im.crop((x0, y0, x0 + W, y0 + H))
        status = "warn" if s > 1.1 else "pass"
        msg = f"{w}x{h} scaled x{s:.3f} and center-cropped to {W}x{H}"
        if status == "warn" and declared is not None and (w, h) == tuple(declared):
            status, msg = "pass", msg + " (the job's declared size: crop and upscale are by design)"
        return np.asarray(im, dtype=np.float64) / 255.0, Check("canvas", status, msg, s)
    s = min(W / w, H / h)
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((W - im.width) // 2, (H - im.height) // 2))
    aspect_off = abs((w / h) / (W / H) - 1)
    status = "pass" if aspect_off < 0.02 else "warn"
    msg = f"{w}x{h} scaled x{s:.3f} into {W}x{H}" + ("" if status == "pass" else f" (aspect off by {aspect_off:.0%}, padded)")
    if min(w, h) < min(W, H) * 0.9:
        status, msg = "warn", msg + "; source smaller than the canvas (upscaled)"
    return np.asarray(canvas, dtype=np.float64) / 255.0, Check("canvas", status, msg, s)


def shift(rgba: np.ndarray, dx: int, dy: int) -> np.ndarray:
    out = np.zeros_like(rgba)
    h, w = rgba.shape[:2]
    xs, xd = (0, dx) if dx >= 0 else (-dx, 0)
    ys, yd = (0, dy) if dy >= 0 else (-dy, 0)
    cw, ch = w - abs(dx), h - abs(dy)
    if cw > 0 and ch > 0:
        out[yd:yd + ch, xd:xd + cw] = rgba[ys:ys + ch, xs:xs + cw]
    return out


# An edit's attachment is the parent master, already registered, so the
# edit itself is never moved again (run.py post passes this to edits).
EDIT_REGISTRATION = {"dx": 0, "dy": 0}


MIN_FIT_SCALE = 0.6


def scale_about(rgba: np.ndarray, s: float, anchor: tuple[float, float]) -> np.ndarray:
    """Uniformly scale `rgba` by s about `anchor`, keeping the canvas size.

    Lanczos on premultiplied alpha, so a shrunk edge gets neither a dark nor a
    light fringe from the colour of transparent pixels."""
    if s == 1.0:
        return rgba
    h, w = rgba.shape[:2]
    pm = rgba.copy()
    pm[..., :3] *= pm[..., 3:4]
    nw, nh = max(1, round(w * s)), max(1, round(h * s))
    # Place the scaled canvas so the anchor lands on itself.
    ox, oy = int(round(anchor[0] - anchor[0] * nw / w)), int(round(anchor[1] - anchor[1] * nh / h))
    out = np.zeros_like(rgba)
    x0, y0 = max(0, ox), max(0, oy)
    x1, y1 = min(w, ox + nw), min(h, oy + nh)
    for c in range(4):
        im = Image.fromarray(pm[..., c].astype(np.float32), "F").resize((nw, nh), Image.Resampling.LANCZOS)
        small = np.asarray(im, dtype=np.float64)
        if x1 > x0 and y1 > y0:
            out[y0:y1, x0:x1, c] = small[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
    a = np.clip(out[..., 3], 0.0, 1.0)
    rgb = np.clip(out[..., :3], 0.0, a[..., None])
    res = np.zeros_like(rgba)
    nz = a > 1e-6
    res[..., :3][nz] = rgb[nz] / a[nz][:, None]
    res[..., 3] = a
    return res


def fit_to_guide(rgba: np.ndarray, kind: str, mode: str = "ground", max_width: int | None = None,
                 top: int | None = None) -> tuple[np.ndarray, dict]:
    """Shrink an oversized object to its guide's footprint width and height bar.

    The image model keeps drawing stations and decor too large, so size is
    enforced here, not only in the prompt. The scale is uniform, about the
    ground anchor (footprint center, ground line), and never above 1. The
    height budget is the distance from the ground target to the bar, since
    registration puts the ground line there next. A piece that would have to
    shrink below MIN_FIT_SCALE is a real art failure and is left alone for QA
    to fail. Returns (image, info): {"scale", "anchor"} or {"fit": None, "reason"}."""
    if kind == "station":
        guide = STATION
    elif kind in ("prop", "decor"):
        if mode == "hang":
            return rgba, {"fit": None, "reason": "hanging decor is not fitted"}
        guide = DECOR
    else:
        return rgba, {"fit": None, "reason": f"{kind} has no guide"}
    max_width = int(max_width) if max_width is not None else 2 * guide["rx"]
    top = int(top) if top is not None else guide["top"]
    g = pa.measure(rgba)
    anchor = [round(g.base_x, 1), g.baseline]
    s = min(1.0, max_width / g.width, (guide["baseline_target"] - top) / max(1, g.baseline - g.top))
    if s >= 1.0:
        return rgba, {"scale": 1.0, "anchor": anchor}
    if s < MIN_FIT_SCALE:
        return rgba, {"fit": None, "reason": f"needs x{s:.2f}, below x{MIN_FIT_SCALE} (a real art failure)"}
    s = round(s, 4)
    return scale_about(rgba, s, (g.base_x, g.baseline)), {"scale": s, "anchor": anchor}


CHAR_GROUND = 0.88          # the character contract: feet at this share of the height
CHAR_TOP_MARGIN = 0.02      # headroom kept when a character must shrink to reach the ground line


def fit_char_ground(rgba: np.ndarray) -> tuple[np.ndarray, dict]:
    """Put a root character's feet on the ground line (88% of the height).

    The model often draws a character too low on the canvas. The fix is
    placement, not regeneration: shrink uniformly about the feet only when the
    head would otherwise leave the canvas (never up, never below
    MIN_FIT_SCALE), then translate vertically so the baseline lands on the
    contract. Returns (image, info): {"scale", "anchor", "dy"} or
    {"fit": None, "reason"}."""
    h = rgba.shape[0]
    g = pa.measure(rgba)
    target = int(round(CHAR_GROUND * h))
    room = target - int(round(CHAR_TOP_MARGIN * h))
    s = min(1.0, room / max(1, g.baseline - g.top))
    if s < MIN_FIT_SCALE:
        return rgba, {"fit": None, "reason": f"needs x{s:.2f}, below x{MIN_FIT_SCALE} (a real art failure)"}
    anchor = [round(g.base_x, 1), g.baseline]
    s = round(s, 4)
    out = scale_about(rgba, s, (g.base_x, g.baseline))
    dy = target - pa.measure(out).baseline
    return shift(out, 0, dy), {"scale": s, "anchor": anchor, "dy": int(dy), "ground": True}


def emit_mask(shape: tuple[int, int], boxes: list[list[float]], feather: float = 0.02) -> np.ndarray:
    """Soft mask (H, W) of boxes given as canvas fractions [x, y, w, h].

    Each edge is a linear ramp `feather` x the box size wide, centred on the
    edge; boxes are united with max."""
    h, w = shape
    mask = np.zeros((h, w), dtype=np.float64)
    xs, ys = np.arange(w) + 0.5, np.arange(h) + 0.5
    for x, y, bw, bh in boxes:
        x0, x1, y0, y1 = x * w, (x + bw) * w, y * h, (y + bh) * h
        fx, fy = max(1.0, feather * (x1 - x0)), max(1.0, feather * (y1 - y0))
        mx = np.clip(np.minimum(xs - x0, x1 - xs) / fx + 0.5, 0, 1)
        my = np.clip(np.minimum(ys - y0, y1 - ys) / fy + 0.5, 0, 1)
        mask = np.maximum(mask, my[:, None] * mx[None, :])
    return mask


def edit_kept_outside(child: np.ndarray, parent: np.ndarray, mask: np.ndarray, tol: float = 10.0, px: int = 128) -> float:
    """edit_kept_fraction over the parent area outside the emit region."""
    if child.shape != parent.shape:
        return 0.0
    c, p, m = downsample(child, px), downsample(parent, px), downsample(np.repeat(mask[..., None], 4, axis=-1), px)[..., 0]
    solid = (p[..., 3] > 0.9) & (m < 0.05)
    if not solid.any():
        return 1.0
    d = np.linalg.norm(sl.srgb_to_lab(c[..., :3][solid]) - sl.srgb_to_lab(p[..., :3][solid]), axis=-1)
    return float(((d < tol) & (c[..., 3] > 0.9)[solid]).mean())


def station_registration(rgba: np.ndarray) -> dict:
    """Translation that puts a station's footprint on the guide's anchor."""
    g = pa.measure(rgba)
    return {"dx": int(round(STATION["cx"] - g.base_x)), "dy": int(round(STATION["baseline_target"] - g.baseline))}


def decor_registration(rgba: np.ndarray, mode: str = "ground") -> dict:
    """Translation that puts a decor piece on the decor guide's anchor (like a
    station's). A ground piece stands on the footprint; a hanging piece hangs
    from the hang line. Scale is never changed here: a piece drawn at the
    wrong size fails check_decor_anchor, and the prompt is fixed instead."""
    g = pa.measure(rgba)
    if mode == "hang":
        return {"dx": int(round(DECOR["cx"] - (g.left + g.right) / 2)), "dy": int(round(DECOR["hang_y"] - g.top))}
    return {"dx": int(round(DECOR["cx"] - g.base_x)), "dy": int(round(DECOR["baseline_target"] - g.baseline))}


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def check_decor_anchor(rgba: np.ndarray, mode: str = "ground") -> Check:
    """A decor piece against the decor guide: footprint width, height bar, ground line.

    Batch 08's bench came out 740 px wide and 80 px above the bar against a
    360 px footprint and a bar at y 500, and automated QA passed it. Now the
    same numbers fail it."""
    g = pa.measure(rgba)
    problems, status = [], "pass"
    if mode == "hang":
        if abs(g.top - DECOR["hang_y"]) > 40:
            problems.append(f"top y {g.top} (hang line {DECOR['hang_y']})")
            status = worst([status, "fail" if abs(g.top - DECOR["hang_y"]) > 100 else "warn"])
        if g.bottom > DECOR["hang_floor"] + 30:
            problems.append(f"bottom y {g.bottom} below the floor ({DECOR['hang_floor']})")
            status = worst([status, "fail" if g.bottom > DECOR["hang_floor"] + 100 else "warn"])
        limit = DECOR["hang_width"] + 80
        if g.width > limit:
            problems.append(f"width {g.width} px wider than the hang line ({DECOR['hang_width']})")
            status = worst([status, "fail" if g.width > limit + 120 else "warn"])
        return Check("decor_anchor", status, "; ".join(problems) or "on the hang line", g.bottom)
    dx = g.base_x - DECOR["cx"]
    if abs(dx) > 40:
        problems.append(f"footprint center x {g.base_x:.0f} (anchor {DECOR['cx']})")
        status = worst([status, "fail" if abs(dx) > 90 else "warn"])
    lo, hi = DECOR["cy"] - 10, DECOR["cy"] + DECOR["ry"] + 26
    if not lo <= g.baseline <= hi:
        off = min(abs(g.baseline - lo), abs(g.baseline - hi))
        problems.append(f"ground line y {g.baseline} (expected {lo}-{hi})")
        status = worst([status, "fail" if off > 60 else "warn"])
    if g.top < DECOR["top"] - 30:
        problems.append(f"top y {g.top} above the height bar ({DECOR['top']})")
        status = worst([status, "fail" if g.top < DECOR["top"] - 100 else "warn"])
    foot = 2 * DECOR["rx"]
    if g.width > foot + 60:
        problems.append(f"width {g.width} px wider than the footprint ({foot})")
        status = worst([status, "fail" if g.width > foot * 1.4 else "warn"])
    return Check("decor_anchor", status, "; ".join(problems) or "on the decor guide", g.baseline)


def check_station_anchor(rgba: np.ndarray, is_edit: bool = False,
                         parent: np.ndarray | None = None) -> Check:
    """Footprint centered on the cross, standing on the ellipse, under the bar.

    Edits inherit the chain root's registration, so their footprint center
    is not re-checked (new poles or stools legitimately move it). With the
    parent given, an edit is anchored against the PARENT's bounds instead of
    the contract: a tall parent (tea-stall-5 tops out at y 49) or a lit variant of
    it must not fail for geometry the parent already has.
    """
    g = pa.measure(rgba)
    if parent is not None:
        gp = pa.measure(parent)
        # The ground line must stay on the parent's. Height and width may
        # exceed the contract only as far as the parent already did.
        top_bar = min(gp.top, STATION["top"])
        width_bar = max(gp.width, 2 * STATION["rx"])
        problems, status = [], "pass"
        if abs(g.baseline - gp.baseline) > 12:
            problems.append(f"ground line y {g.baseline} (parent {gp.baseline})")
            status = worst([status, "fail" if abs(g.baseline - gp.baseline) > 40 else "warn"])
        if g.top < top_bar - 30:
            problems.append(f"top y {g.top} above the parent's bar ({top_bar})")
            status = worst([status, "fail" if g.top < top_bar - 100 else "warn"])
        if g.width > width_bar + 80:
            problems.append(f"width {g.width} px wider than the parent's {width_bar}")
            status = worst([status, "warn"])
        return Check("station_anchor", status, "; ".join(problems) or "on the parent's anchor", g.baseline)
    problems, status = [], "pass"
    dx = g.base_x - STATION["cx"]
    if abs(dx) > 40 and not is_edit:
        problems.append(f"footprint center x {g.base_x:.0f} (anchor 512)")
        status = worst([status, "fail" if abs(dx) > 90 else "warn"])
    lo, hi = STATION["cy"], STATION["cy"] + STATION["ry"] + 22
    if not lo <= g.baseline <= hi:
        off = min(abs(g.baseline - lo), abs(g.baseline - hi))
        problems.append(f"ground line y {g.baseline} (expected {lo}-{hi})")
        status = worst([status, "fail" if off > 60 else "warn"])
    if g.top < STATION["top"] - 30:
        problems.append(f"top y {g.top} above the height bar (150)")
        status = worst([status, "fail" if g.top < STATION["top"] - 100 else "warn"])
    if g.width > 2 * STATION["rx"] + 80:
        problems.append(f"width {g.width} px wider than the footprint (720)")
        status = worst([status, "warn"])
    return Check("station_anchor", status, "; ".join(problems) or "on the anchor", g.baseline)


def magenta_pixels(rgba: np.ndarray) -> int:
    """Guide magenta (#EC008C) remnants: strongly red-purple, low yellow."""
    solid = rgba[..., 3] > 0.5
    if not solid.any():
        return 0
    lab = sl.srgb_to_lab(rgba[..., :3][solid])
    mask = (lab[:, 1] > 45) & (lab[:, 2] < 12) & (lab[:, 0] > 30)
    return int(mask.sum())


def check_magenta(rgba: np.ndarray, limits: dict) -> Check:
    h, w = rgba.shape[:2]
    n = magenta_pixels(rgba) * (1024 * 1024) / (h * w)
    return Check("no_guide_magenta", grade(n, limits["magenta_px"]), f"{n:.0f} guide-magenta pixels (per 1024^2)", n)


def lawn_chroma(rgba: np.ndarray) -> float | None:
    solid = rgba[..., 3] > 0.9
    if not solid.any():
        return None
    L, C, H = sl.lch(sl.srgb_to_lab(rgba[..., :3][solid]))
    green = (H > 95) & (H < 175) & (C > 10)
    if green.sum() < 500:
        return None
    return float(np.percentile(C[green], 95))


def island_depth_ratio(rgba: np.ndarray) -> float | None:
    """Earth depth below the lawn's front lip, over the island width."""
    solid = rgba[..., 3] > 0.5
    if not solid.any():
        return None
    lab = sl.srgb_to_lab(rgba[..., :3])
    _, C, H = sl.lch(lab)
    green = solid & (H > 105) & (H < 170) & (C > 15)
    cols = np.where(solid.any(axis=0))[0]
    width = cols[-1] - cols[0] + 1
    mid = slice(cols[0] + width // 3, cols[0] + 2 * width // 3)
    rows_green = np.where(green[:, mid].any(axis=1))[0]
    rows_solid = np.where(solid[:, mid].any(axis=1))[0]
    if not len(rows_green):
        return None
    return float((rows_solid[-1] - rows_green[-1]) / width)


def edit_kept_fraction(child: np.ndarray, parent: np.ndarray, tol: float = 10.0, px: int = 128) -> float:
    """Share of the parent's opaque area that the edit left unchanged.

    Compared at `px` wide: an image edit re-renders the whole picture, so
    texture never matches pixel for pixel; what must hold is that every
    part keeps its place, size and color (the level chain does not drift).
    """
    if child.shape != parent.shape:
        return 0.0
    child, parent = downsample(child, px), downsample(parent, px)
    p_solid = parent[..., 3] > 0.9
    if not p_solid.any():
        return 0.0
    same_alpha = child[..., 3] > 0.9
    d = np.linalg.norm(sl.srgb_to_lab(child[..., :3][p_solid]) - sl.srgb_to_lab(parent[..., :3][p_solid]), axis=-1)
    return float(((d < tol) & same_alpha[p_solid]).mean())


def edit_chroma_ratio(child: np.ndarray, parent: np.ndarray) -> float | None:
    """Median chroma of the edit over the parent's, on the area both cover.

    Batch 03 lost about a third of its chroma per level (windmill-1 C50 28,
    windmill-5 7; tea-stall-1 31, tea-stall-5 11): each edit re-drew the locked parent
    and was locked again, and every step stayed under edit_stability's
    tolerance. The ratio makes that drift visible one level at a time.
    """
    if child.shape != parent.shape:
        return None
    both = (child[..., 3] > 0.9) & (parent[..., 3] > 0.9)
    if both.sum() < 500:
        return None
    _, cc, _ = sl.lch(sl.srgb_to_lab(child[..., :3][both]))
    _, cp, _ = sl.lch(sl.srgb_to_lab(parent[..., :3][both]))
    base = float(np.median(cp))
    return float(np.median(cc) / base) if base > 2.0 else None


def edit_silhouette_iou(child: np.ndarray, parent: np.ndarray) -> float | None:
    """Alpha IoU of the edit with its parent: the shape stayed, whatever the colors did."""
    if child.shape != parent.shape:
        return None
    a, b = child[..., 3] > 0.5, parent[..., 3] > 0.5
    union = int((a | b).sum())
    return float((a & b).sum() / union) if union else None


def edit_structure(child: np.ndarray, parent: np.ndarray, px: int = 128) -> tuple[float, float] | None:
    """Lightness correlation and mean lightness shift of a recolor against its parent.

    A glaze change moves hue and chroma, not where the highlight, lip and
    sprout are (correlation stays high) and not how light the tile is."""
    if child.shape != parent.shape:
        return None
    c, p = downsample(child, px), downsample(parent, px)
    m = (c[..., 3] > 0.9) & (p[..., 3] > 0.9)
    if m.sum() < 200:
        return None
    lc = sl.srgb_to_lab(c[..., :3][m])[:, 0]
    lp = sl.srgb_to_lab(p[..., :3][m])[:, 0]
    if lc.std() < 1e-6 or lp.std() < 1e-6:
        return None
    return float(np.corrcoef(lc, lp)[0, 1]), float(abs((lc - lp).mean()))


def _band_extent(alpha: np.ndarray, frac: tuple[float, float]) -> tuple[float, float, int] | None:
    """Left, right and bottom of the solid mask within a vertical band of its bbox."""
    solid = alpha > 0.5
    rows = np.where(solid.any(axis=1))[0]
    if not len(rows):
        return None
    top, bottom = rows[0], rows[-1]
    y0 = int(top + (bottom - top) * frac[0])
    y1 = int(top + (bottom - top) * frac[1]) + 1
    cols = np.where(solid[y0:y1].any(axis=0))[0]
    if not len(cols):
        return None
    return float(cols[0]), float(cols[-1] + 1), int(bottom + 1)


def align_to_parent(child: np.ndarray, parent: np.ndarray) -> tuple[np.ndarray, dict]:
    """Undo the rescale and shift an image edit often applies to a level chain.

    GPT Image edits re-render the picture and may zoom out to fit a new
    awning. The base of the object (the lowest 30 % of the parent) almost
    never changes in a level edit, so it is the registration key: scale by
    its width ratio, then align its center and ground line. A small search
    refines the fit. The app then shows every level at the same place.
    """
    pe = _band_extent(parent[..., 3], (0.7, 1.0))
    ce = _band_extent(child[..., 3], (0.7, 1.0))
    identity = {"scale": 1.0, "cx": 0.0, "cy": 0.0, "dx": 0, "dy": 0}
    if pe is None or ce is None:
        return child, identity
    center = ((ce[0] + ce[1]) / 2, float(ce[2]))
    s0 = (pe[1] - pe[0]) / max(1.0, ce[1] - ce[0])
    best = (edit_kept_fraction(child, parent), child, identity)
    for s in s0 * np.array([0.97, 0.985, 1.0, 1.015, 1.03]):
        scaled = _scale_about(child, s, center)
        se = _band_extent(scaled[..., 3], (0.7, 1.0))
        if se is None:
            continue
        dx0 = int(round((pe[0] + pe[1]) / 2 - (se[0] + se[1]) / 2))
        dy0 = pe[2] - se[2]
        for ddx in (-4, 0, 4):
            for ddy in (-4, 0, 4):
                cand = shift(scaled, dx0 + ddx, dy0 + ddy)
                score = edit_kept_fraction(cand, parent)
                if score > best[0] + 1e-9:
                    best = (score, cand, {"scale": round(float(s), 4), "cx": center[0], "cy": center[1],
                                          "dx": dx0 + ddx, "dy": dy0 + ddy})
    return best[1], best[2]


def apply_alignment(rgba: np.ndarray, t: dict) -> np.ndarray:
    if t.get("scale", 1.0) == 1.0 and not t.get("dx") and not t.get("dy"):
        return rgba
    return shift(_scale_about(rgba, t["scale"], (t["cx"], t["cy"])), t["dx"], t["dy"])


def _scale_about(rgba: np.ndarray, s: float, center: tuple[float, float]) -> np.ndarray:
    h, w = rgba.shape[:2]
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    cx, cy = center
    # Affine maps output -> input coordinates.
    im = im.transform((w, h), Image.Transform.AFFINE, (1 / s, 0, cx - cx / s, 0, 1 / s, cy - cy / s),
                      resample=Image.Resampling.BICUBIC)
    return np.asarray(im, dtype=np.float64) / 255.0


def lock_load(raw: np.ndarray, locked: np.ndarray) -> float:
    """Mean Delta E the style lock moved the opaque pixels: how far the take drifted."""
    m = (raw[..., 3] > 0.9) & (locked[..., 3] > 0.9)
    if not m.any():
        return 0.0
    return float(np.linalg.norm(sl.srgb_to_lab(raw[..., :3][m]) - sl.srgb_to_lab(locked[..., :3][m]), axis=-1).mean())


# ---------------------------------------------------------------------------
# UI art (ADR-0018 "Glass++"): icons must read at 24 and 30 pt on glass
# ---------------------------------------------------------------------------

ICON_POINTS = (24, 30, 60)
GLASS = {"light": (244, 241, 247), "dark": (43, 37, 51)}  # glass over cream / over night, approximate


def downsample(rgba: np.ndarray, px: int) -> np.ndarray:
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    im = im.resize((px, round(px * im.height / im.width)), Image.Resampling.LANCZOS)
    return np.asarray(im, dtype=np.float64) / 255.0


def thin_fraction(rgba: np.ndarray, points: int = 24, min_stroke_pt: float = 1.5) -> float:
    """Share of the silhouette thinner than `min_stroke_pt` at `points` size.

    An opening (erode, then dilate) with a disk that size removes thin
    stems, whiskers and spikes; whatever it removes will vanish or shimmer
    at 24 pt.
    """
    a = downsample(rgba, 256)[..., 3] > 0.5
    if not a.any():
        return 0.0
    # min_stroke_pt points at `points` size, expressed in pixels of the 256 px mask.
    k = max(3, int(round(min_stroke_pt * 256 / points)) | 1)
    m = Image.fromarray((a * 255).astype(np.uint8))
    opened = np.asarray(m.filter(ImageFilter.MinFilter(k)).filter(ImageFilter.MaxFilter(k))) > 127
    return float((a & ~opened).sum() / a.sum())


def glass_contrast(rgba: np.ndarray, which: str, px: int = 72) -> float:
    """Share of the icon's pixels that differ from the glass by at least 20 L."""
    small = downsample(rgba, px)
    solid = small[..., 3] > 0.5
    if not solid.any():
        return 0.0
    L = sl.srgb_to_lab(small[..., :3][solid])[:, 0]
    bg = sl.srgb_to_lab(np.array(GLASS[which], dtype=np.float64) / 255.0)[0]
    return float((np.abs(L - bg) >= 20).mean())


def icon_checks(rgba: np.ndarray) -> list[Check]:
    checks = []
    alpha = rgba[..., 3] > 0.1
    if not alpha.any():
        return [Check("icon_fill", "fail", "empty icon")]
    ys, xs = np.nonzero(alpha)
    fill = max(ys.max() - ys.min() + 1, xs.max() - xs.min() + 1) / max(rgba.shape[:2])
    checks.append(Check("icon_fill", "pass" if 0.76 <= fill <= 0.94 else "warn",
                        f"icon spans {fill:.0%} of the canvas (target 80-92%)", fill))
    thin = thin_fraction(rgba)
    checks.append(Check("icon_thin_parts", "fail" if thin > 0.10 else "warn" if thin > 0.04 else "pass",
                        f"{thin:.1%} of the silhouette is thinner than 1.5 pt at 24 pt", thin))
    small = sl.measure(rgba, display_px=72)
    checks.append(Check("icon_small_detail", "fail" if small["detail"] > 9 else "warn" if small["detail"] > 7 else "pass",
                        f"detail at 24 pt @3x {small['detail']:.1f} (busy above 7)", small["detail"]))
    for which in ("light", "dark"):
        c = glass_contrast(rgba, which)
        checks.append(Check(f"icon_on_{which}_glass", "fail" if c < 0.25 else "warn" if c < 0.5 else "pass",
                            f"{c:.0%} of the icon separates from {which} glass at 24 pt", c))
    return checks


def appicon_checks(rgba: np.ndarray) -> list[Check]:
    checks = []
    opaque = float(rgba[..., 3].min())
    checks.append(Check("appicon_opaque", "pass" if opaque > 0.99 else "fail", "fully opaque" if opaque > 0.99 else "has transparency", opaque))
    g = (rgba[..., :3] @ np.array([0.299, 0.587, 0.114]))
    lap = np.abs(4 * g[1:-1, 1:-1] - g[:-2, 1:-1] - g[2:, 1:-1] - g[1:-1, :-2] - g[1:-1, 2:])
    h, w = lap.shape
    yy, xx = np.mgrid[0:h, 0:w]
    r = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2))
    inner, outer = lap[r <= 0.8].mean(), lap[r > 1.0].mean()
    ratio = float(outer / max(inner, 1e-6))
    checks.append(Check("appicon_calm_corners", "pass" if ratio <= 0.5 else "warn" if ratio <= 0.9 else "fail",
                        f"corner detail is {ratio:.0%} of the center's (the system masks corners)", ratio))
    return checks


def luma(rgb: np.ndarray) -> np.ndarray:
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722


def additive_checks(rgba: np.ndarray) -> list[Check]:
    """QA profile of an additive glow sprite (opaque, painted on black)."""
    lim = ADDITIVE
    rgb = rgba[..., :3]
    Y = luma(rgb)
    h, w = Y.shape
    checks: list[Check] = []
    lit = Y > lim["lit_luma"]
    frac = float(lit.mean())
    if frac < lim["min_lit"]:
        return [Check("glow_present", "fail", f"only {frac:.1%} of the image is lit (at least {lim['min_lit']:.0%})", frac)]
    # 1. chroma, on lit pixels only (the black has no hue).
    _, C, _ = sl.lch(sl.srgb_to_lab(rgb[lit]))
    c95 = float(np.percentile(C, 95))
    checks.append(Check("chroma_ceiling", grade(c95, lim["chroma_p95"]),
                        f"glow chroma p95 {c95:.0f} on {frac:.0%} lit pixels (additive profile)", c95))
    # 2. the background is near-black: the outer band of the image.
    b = max(2, round(0.04 * min(h, w)))
    band = np.concatenate([Y[:b].ravel(), Y[-b:].ravel(), Y[:, :b].ravel(), Y[:, -b:].ravel()])
    bg = float(np.percentile(band, 99))
    checks.append(Check("additive_background", grade(bg, lim["bg_luma_p99"]),
                        f"border luma p99 {bg:.3f} (near-black, at most {lim['bg_luma_p99']['warn']:.2f}): the glow dies before the edge", bg))
    # 3. soft falloff: no hard step (at 256 px, after a 1 px blur).
    im = Image.fromarray(np.clip(np.round(Y * 255), 0, 255).astype(np.uint8), "L")
    s = 256 / max(w, h)
    im = im.resize((max(8, round(w * s)), max(8, round(h * s))), Image.Resampling.BOX).filter(ImageFilter.GaussianBlur(1.0))
    g = np.asarray(im, dtype=np.float64) / 255.0
    gy, gx = np.gradient(g)
    edge = float((np.hypot(gx, gy) > lim["edge_step"]).mean())
    checks.append(Check("additive_falloff", grade(edge, lim["edge_share"]),
                        f"{edge:.2%} of the image has a hard edge (luma step over {lim['edge_step']:.2f} per px at 256 px; soft falloff, at most {lim['edge_share']['warn']:.1%})", edge))
    # 4. banding: a smooth, grainy falloff uses nearly every 8-bit level of its span.
    levels = np.round(Y[lit] * 255).astype(int)
    lo, hi = int(levels.min()), int(np.percentile(levels, 99.5))
    span = max(1, hi - lo + 1)
    used = len(np.unique(levels[(levels >= lo) & (levels <= hi)]))
    ratio = used / span
    checks.append(Check("additive_banding", grade(ratio, lim["levels"], higher_is_worse=False),
                        f"{used} of {span} luma levels used across the falloff ({ratio:.0%}; low means banding)", ratio))
    return checks


def palette_sets(names: list[str]) -> dict[str, list[str]]:
    tokens = pa.load_tokens()["artPalettes"]
    extra = json.loads((HERE / "palettes.json").read_text(encoding="utf-8"))
    sets = {}
    for n in names:
        src = tokens.get(n) or extra.get(n)
        if src is None:
            raise KeyError(f"unknown palette {n}")
        sets[n] = [v for k, v in src.items() if not k.startswith("$")]
    return sets


def check_palette(rgba: np.ndarray, names: list[str]) -> Check:
    rep = pa.palette_drift(rgba, palette_sets(names))
    status = {"ok": "pass", "warn": "warn", "fail": "fail"}[rep.status]
    return Check("palette_drift", status, f"mean dE {rep.mean:.1f}, p95 {rep.p95:.1f}, off-palette {rep.off_frac:.1%}"
                 + (f" (top: {', '.join(rep.top_off_palette[:2])})" if rep.top_off_palette else ""), rep.mean)


HARMONY_KINDS = ("station", "prop", "world", "char")


def check_harmony(locked: np.ndarray, kind: str, lim: dict) -> Check | None:
    """The take's harmony score against the approved reference (tools/assets/harmony.py): the
    same measurement that corrects the shipped masters, so a take that needs less correction
    wins. Skipped when the harmony manifest is not there (a fresh checkout of the tools only)."""
    try:
        import harmony
    except ImportError:
        return None
    if not harmony.MANIFEST.is_dir():
        return None
    cfg = harmony.load_config()
    ppu = cfg["ppu_by_kind"].get(kind, cfg["ppu_by_kind"]["world"]) * locked.shape[1] / 1024
    if kind == "world":
        ppu = cfg["ppu_by_kind"]["world"] * locked.shape[1] / 1536
    try:
        r = harmony.score_image(locked, ppu, cfg, kind=kind)
    except ValueError:
        return None
    out = ", ".join(r["outliers"]) or "none"
    return Check("harmony", grade(r["score"], lim["harmony"], higher_is_worse=False),
                 f"harmony score {r['score']:.0f} against the {harmony.reference_group(kind, cfg)} reference (outliers: {out})",
                 r["score"])


def check_light(rgba: np.ndarray, light: dict, enforce: bool | None = None) -> list[Check]:
    """The light standard v2 (design/art/light-standard.json, ADR-0021): the dark floor,
    median band and local-contrast band of the subject region, and for an opaque take
    the sky, the cloud sea and the darks under the sky, per colour-script cell x layer. Generalises NIGHT_PROFILE and replaces value_floor for jobs that
    declare `light`. A failure is hard for production unless the standard is still
    warn-only (`enforce: false`); an exploration job downgrades it again (advisory)."""
    std = lt.standard()
    enforce = std.get("enforce", False) if enforce is None else enforce
    m = lt.measure_light(rgba)
    if "error" in m:
        return [Check("light_values", "fail", "no subject pixels to measure")]
    checks = []
    for name, status, message, value in lt.evaluate(m, light, std):
        if status == "fail" and not enforce:
            status, message = "warn", message + " (warn-only until the founder has seen the light pilot)"
        checks.append(Check(name, status, message, value))
    return checks


def run_checks(kind: str, raw: np.ndarray, locked: np.ndarray, palettes: list[str], acceptance: dict | None = None,
               parent_locked: np.ndarray | None = None, decor: str | None = None, light: dict | None = None) -> list[Check]:
    acceptance = acceptance or {}
    lim = limits_for(kind, acceptance)
    night = acceptance.get("profile") == "night" and not light
    if night:
        lim["value_floor"] = dict(NIGHT_PROFILE["value_floor"])
    m = sl.measure(locked)
    checks = []
    if "error" in m:
        return [Check("opaque_pixels", "fail", "no opaque pixels")]
    if acceptance.get("blend") == "additive":
        # Value floor, palette drift and the lit-object chroma do not apply to
        # light painted on black; the additive profile replaces them.
        checks.extend(additive_checks(locked))
        checks.append(Check("detail_budget", grade(m["detail"], lim["detail"]), f"detail at display size {m['detail']:.1f} (R1 5.3)", m["detail"]))
        return checks
    checks.append(Check("chroma_ceiling", grade(m["C_p95"], lim["chroma_p95"]), f"chroma p95 {m['C_p95']:.0f} (R1 51)", m["C_p95"]))
    if light:
        checks.extend(check_light(locked, light))
    else:
        checks.append(Check("value_floor", grade(m["L_p5"], lim["value_floor"], higher_is_worse=False),
                            f"lightness p5 {m['L_p5']:.0f} (R1 59)", m["L_p5"]))
    if night:
        med, band = m["L_p50"], NIGHT_PROFILE["median_L"]
        ok = band["pass"][0] <= med <= band["pass"][1]
        near = band["warn"][0] <= med <= band["warn"][1]
        checks.append(Check("night_lightness", "pass" if ok else "warn" if near else "fail",
                            f"night variant: median lightness {med:.0f} (dark band {band['pass'][0]:.0f}-{band['pass'][1]:.0f})", med))
    checks.append(Check("detail_budget", grade(m["detail"], lim["detail"]), f"detail at display size {m['detail']:.1f} (R1 5.3)", m["detail"]))
    if kind != "char":
        load = lock_load(raw, locked)
        checks.append(Check("lock_load", grade(load, lim["lock_load"]),
                            f"the lock moved colors by mean dE {load:.1f}" + (" (prefer a take that needs less)" if load > lim["lock_load"]["warn"] else ""), load))
    if kind in ("station", "prop", "world"):
        checks.append(check_magenta(locked, lim))
    checks.append(check_palette(locked, palettes))
    if kind == "station":
        checks.append(check_station_anchor(locked, is_edit=parent_locked is not None, parent=parent_locked))
    if decor and parent_locked is None:
        checks.append(check_decor_anchor(locked, decor))
    if kind == "world":
        ratio = island_depth_ratio(locked)
        if ratio is not None:
            checks.append(Check("depth_ratio", grade(ratio, lim["depth_ratio"]),
                                f"earth depth / width {ratio:.2f} (at most {lim['depth_ratio']['warn']:.2f})", ratio))
            if lim["depth_floor"]["warn"] > 0:
                checks.append(Check("depth_floor", grade(ratio, lim["depth_floor"], higher_is_worse=False),
                                    f"earth depth / width {ratio:.2f} (at least {lim['depth_floor']['warn']:.2f}: visible soil and rock)", ratio))
        lc = lawn_chroma(locked)
        if lc is not None:
            checks.append(Check("lawn_chroma", grade(lc, lim["lawn_chroma"]), f"lawn chroma p95 {lc:.0f} (palette meadow 38)", lc))
    if kind == "char":
        g = pa.measure(locked)
        frac = g.baseline / locked.shape[0]
        # `acceptance: {ground_line: false}` for a character that does not stand on the
        # contract's ground line (a sticker, centred on a square canvas).
        if acceptance.get("ground_line", True) is not False:
            checks.append(Check("ground_line", "pass" if abs(frac - 0.88) <= 0.02 else "warn" if abs(frac - 0.88) <= 0.05 else "fail",
                                f"feet at {frac:.1%} of the height (contract 88%)", frac))
        if pa.baked_shadow_suspected(locked, g):
            checks.append(Check("no_ground_shadow", "warn", "a ground shadow seems painted in"))
    if kind == "icon":
        checks.extend(icon_checks(locked))
    if kind == "appicon":
        checks.extend(appicon_checks(locked))
    if kind in HARMONY_KINDS:
        h = check_harmony(locked, kind, lim)
        if h is not None:
            checks.append(h)
    if parent_locked is not None:
        mode = acceptance.get("edit_mode", "keep")
        if mode not in EDIT_MODES:
            raise ValueError(f"edit_mode must be one of {', '.join(EDIT_MODES)}, got {mode!r}")
        if mode != "keep":
            iou = edit_silhouette_iou(locked, parent_locked)
            if iou is not None:
                checks.append(Check("edit_silhouette", grade(iou, SILHOUETTE, higher_is_worse=False),
                                    f"{iou:.0%} of the parent's shape kept", iou))
        if mode == "recolor":
            st = edit_structure(locked, parent_locked)
            if st is not None:
                corr, dl = st
                checks.append(Check("edit_structure", grade(corr, STRUCTURE, higher_is_worse=False),
                                    f"light structure matches the parent (r {corr:.2f})", corr))
                if acceptance.get("profile") != "night":  # a night recolor is asked to get darker: night_lightness judges it
                    checks.append(Check("edit_lightness", grade(dl, LIGHTNESS_SHIFT),
                                        f"mean lightness moved by {dl:.1f} L (the same lightness was asked)", dl))
            return checks
        if mode == "region" and "edit_kept" not in acceptance:
            lim["edit_kept"] = dict(REGION_EDIT_KEPT)
        kept = edit_kept_fraction(locked, parent_locked)
        checks.append(Check("edit_stability", grade(kept, lim["edit_kept"], higher_is_worse=False),
                            f"{kept:.0%} of the parent level unchanged", kept))
        ratio = edit_chroma_ratio(locked, parent_locked)
        if ratio is not None:
            lo = lim["edit_chroma"]
            status = "pass" if lo["warn"] <= ratio <= 1 / lo["warn"] else "warn" if lo["fail"] <= ratio <= 1 / lo["fail"] else "fail"
            checks.append(Check("edit_chroma", status, f"chroma x{ratio:.2f} of the parent level (drift compounds along a chain)", ratio))
    return checks


# ---------------------------------------------------------------------------
# The chain for one take
# ---------------------------------------------------------------------------

def process_take(raw: np.ndarray, kind: str, canvas: tuple[int, int] | None, preset: dict, palettes: list[str],
                 acceptance: dict | None = None, registration: dict | None = None,
                 parent_locked: np.ndarray | None = None, register_root: bool = False,
                 transparent: bool = True, decor: str | None = None, light: dict | None = None,
                 fit: dict | None = None, declared_size: tuple[int, int] | None = None,
                 emit_region: list[list[float]] | None = None) -> TakeResult:
    checks: list[Check] = []
    if transparent:
        rgba, c = ensure_alpha(raw)
    else:
        holes = float((raw[..., 3] < 0.99).mean())
        rgba = raw.copy()
        rgba[..., 3] = 1.0
        c = (Check("transparency", "pass", "opaque, as this kind must be") if holes == 0 else
             Check("transparency", "fail", f"this kind must be opaque, but {holes:.1%} of the source is transparent", holes))
    checks.append(c)
    rgba, c = fit_canvas(rgba, canvas, cover=not transparent, declared=declared_size)
    checks.append(c)
    info: dict = {}
    if parent_locked is not None and parent_locked.shape[:2] != rgba.shape[:2]:
        # Approved historical masters can have a smaller canvas (Findik: 870x1306).
        # Compare both images in the requested job frame; otherwise an unchanged
        # edit gets zero stability solely because the array dimensions differ.
        source_canvas = [parent_locked.shape[1], parent_locked.shape[0]]
        target_canvas = (rgba.shape[1], rgba.shape[0])
        parent_locked, _ = fit_canvas(parent_locked, target_canvas, cover=not transparent)
        info["parent_canvas"] = {"source": source_canvas, "target": list(target_canvas)}
    # Guide fit: root stations, ground decor, and plain props with an explicit
    # override (an edit inherits its parent's frame). {} = guide defaults for
    # stations/decor; plain props keep their frame unless an override is given.
    if (fit is not None and parent_locked is None and registration is None and transparent
            and (kind == "station" or decor == "ground" or (kind == "prop" and not decor and bool(fit)))):
        rgba, finfo = fit_to_guide(rgba, kind, decor or "ground", fit.get("max_width"), fit.get("top"))
        if "scale" in finfo:
            info["fit"] = finfo
        else:
            info["fit_skipped"] = finfo["reason"]
    if fit and fit.get("ground") and kind == "char" and parent_locked is None and registration is None and transparent:
        rgba, finfo = fit_char_ground(rgba)
        if "scale" in finfo:
            info["fit"] = finfo
        else:
            info["fit_skipped"] = finfo["reason"]
    if kind == "station":
        reg = registration if registration is not None else (station_registration(rgba) if register_root else None)
        if reg:
            rgba = shift(rgba, reg["dx"], reg["dy"])
            info["registration"] = reg
    if decor and parent_locked is None:
        reg = registration if registration is not None else (decor_registration(rgba, decor) if register_root else None)
        if reg:
            rgba = shift(rgba, reg["dx"], reg["dy"])
            info["registration"] = reg
    normalized = rgba
    if (acceptance or {}).get("blend") == "additive":
        # The lock lifts the value floor (black becomes L 19 grey), which an
        # additive glow cannot take: black is no light. Ship the take as drawn.
        locked = normalized.copy()
        info["lock_skipped"] = "additive glow: black stays black"
    else:
        locked = sl.apply_lock(normalized, preset)
    if parent_locked is not None and transparent and locked.shape == parent_locked.shape:
        locked, t = align_to_parent(locked, parent_locked)
        if t["scale"] != 1.0 or t["dx"] or t["dy"]:
            normalized = apply_alignment(normalized, t)
            info["alignment"] = t
            off = abs(t["scale"] - 1)
            checks.append(Check("edit_alignment", "pass" if off <= 0.03 else "warn" if off <= 0.25 else "fail",
                                f"the edit rescaled the object x{1 / t['scale']:.3f} and moved it; aligned back to the parent",
                                t["scale"]))
    leak = None
    if emit_region and parent_locked is not None and locked.shape == parent_locked.shape:
        # Lit edit: only the light-carrying region of the take ships. The master
        # is the parent outside it (feathered edge), so whole-image stability and
        # chroma cannot fail the take; its leakage outside the region is a warning.
        mask = emit_mask(locked.shape[:2], emit_region)
        kept = edit_kept_outside(locked, parent_locked, mask)
        leak = Check("emit_leak", "pass" if kept >= 0.98 else "warn",
                     f"{kept:.0%} of the parent unchanged outside the emit region (masked out of the master)", kept)
        locked = parent_locked * (1 - mask[..., None]) + locked * mask[..., None]
        info["emit_region"] = [list(b) for b in emit_region]
    style = run_checks(kind, normalized, locked, palettes, acceptance, parent_locked, decor, light)
    if leak:
        style = [c for c in style if c.name not in ("edit_stability", "edit_chroma")] + [leak]
    checks.extend(advisory(style) if (acceptance or {}).get("exploration") else style)
    info["metrics_raw"] = sl.measure(normalized)
    info["metrics_locked"] = sl.measure(locked)
    return TakeResult(raw=raw, normalized=normalized, locked=locked, checks=checks, info=info)
