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

ORDER = {"pass": 0, "warn": 1, "fail": 2}

# Station guide (tools/art/island_guides.py): footprint ellipse centered at
# (512, 800), radii 360 x 108, height bar to y = 150, on a 1024 canvas.
# An object standing on the ellipse has its lowest pixels on the front half
# of the ellipse (y 800...908), so the anchor check looks at that band.
STATION = {"cx": 512, "cy": 800, "rx": 360, "ry": 108, "top": 150, "baseline_target": 900}

# Thresholds on the locked image, derived from R1 (art-direction study).
DEFAULT_LIMITS = {
    "chroma_p95": {"warn": 52.0, "fail": 60.0},
    "value_floor": {"warn": 35.0, "fail": 25.0},       # L p5 must stay at or above
    "detail": {"warn": 6.0, "fail": 7.5},              # Laplacian at display size, R1 = 5.3
    "lock_load": {"warn": 10.0, "fail": 18.0},         # mean Delta E the lock had to move
    "edit_kept": {"warn": 0.75, "fail": 0.55},         # share of the parent left unchanged
    "depth_ratio": {"warn": 0.32, "fail": 0.42},       # island earth depth / width
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
}


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


def fit_canvas(rgba: np.ndarray, size: tuple[int, int] | None, cover: bool = False) -> tuple[np.ndarray, Check]:
    """Scale into the kind's canvas. Sprites are never cropped (padded with
    transparency); opaque kinds (`cover`) are scaled to fill and center-cropped."""
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
        return (np.asarray(im, dtype=np.float64) / 255.0,
                Check("canvas", status, f"{w}x{h} scaled x{s:.3f} and center-cropped to {W}x{H}", s))
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


def station_registration(rgba: np.ndarray) -> dict:
    """Translation that puts a station's footprint on the guide's anchor."""
    g = pa.measure(rgba)
    return {"dx": int(round(STATION["cx"] - g.base_x)), "dy": int(round(STATION["baseline_target"] - g.baseline))}


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def check_station_anchor(rgba: np.ndarray, is_edit: bool = False) -> Check:
    """Footprint centered on the cross, standing on the ellipse, under the bar.

    Edits inherit the chain root's registration, so their footprint center
    is not re-checked (new poles or stools legitimately move it).
    """
    g = pa.measure(rgba)
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


def run_checks(kind: str, raw: np.ndarray, locked: np.ndarray, palettes: list[str], acceptance: dict | None = None,
               parent_locked: np.ndarray | None = None) -> list[Check]:
    acceptance = acceptance or {}
    lim = limits_for(kind, acceptance)
    m = sl.measure(locked)
    checks = []
    if "error" in m:
        return [Check("opaque_pixels", "fail", "no opaque pixels")]
    checks.append(Check("chroma_ceiling", grade(m["C_p95"], lim["chroma_p95"]), f"chroma p95 {m['C_p95']:.0f} (R1 51)", m["C_p95"]))
    checks.append(Check("value_floor", grade(m["L_p5"], lim["value_floor"], higher_is_worse=False),
                        f"lightness p5 {m['L_p5']:.0f} (R1 59)", m["L_p5"]))
    checks.append(Check("detail_budget", grade(m["detail"], lim["detail"]), f"detail at display size {m['detail']:.1f} (R1 5.3)", m["detail"]))
    if kind != "char":
        load = lock_load(raw, locked)
        checks.append(Check("lock_load", grade(load, lim["lock_load"]),
                            f"the lock moved colors by mean dE {load:.1f}" + (" (prefer a take that needs less)" if load > lim["lock_load"]["warn"] else ""), load))
    if kind in ("station", "prop", "world"):
        checks.append(check_magenta(locked, lim))
    checks.append(check_palette(locked, palettes))
    if kind == "station":
        checks.append(check_station_anchor(locked, is_edit=parent_locked is not None))
    if kind == "world":
        ratio = island_depth_ratio(locked)
        if ratio is not None:
            checks.append(Check("depth_ratio", grade(ratio, lim["depth_ratio"]), f"earth depth / width {ratio:.2f} (target <= 0.30)", ratio))
        lc = lawn_chroma(locked)
        if lc is not None:
            checks.append(Check("lawn_chroma", grade(lc, lim["lawn_chroma"]), f"lawn chroma p95 {lc:.0f} (palette meadow 38)", lc))
    if kind == "char":
        g = pa.measure(locked)
        frac = g.baseline / locked.shape[0]
        checks.append(Check("ground_line", "pass" if abs(frac - 0.88) <= 0.02 else "warn" if abs(frac - 0.88) <= 0.05 else "fail",
                            f"feet at {frac:.1%} of the height (contract 88%)", frac))
        if pa.baked_shadow_suspected(locked, g):
            checks.append(Check("no_ground_shadow", "warn", "a ground shadow seems painted in"))
    if kind == "icon":
        checks.extend(icon_checks(locked))
    if kind == "appicon":
        checks.extend(appicon_checks(locked))
    if parent_locked is not None:
        kept = edit_kept_fraction(locked, parent_locked)
        checks.append(Check("edit_stability", grade(kept, lim["edit_kept"], higher_is_worse=False),
                            f"{kept:.0%} of the parent level unchanged", kept))
    return checks


# ---------------------------------------------------------------------------
# The chain for one take
# ---------------------------------------------------------------------------

def process_take(raw: np.ndarray, kind: str, canvas: tuple[int, int] | None, preset: dict, palettes: list[str],
                 acceptance: dict | None = None, registration: dict | None = None,
                 parent_locked: np.ndarray | None = None, register_root: bool = False,
                 transparent: bool = True) -> TakeResult:
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
    rgba, c = fit_canvas(rgba, canvas, cover=not transparent)
    checks.append(c)
    info: dict = {}
    if kind == "station":
        reg = registration if registration is not None else (station_registration(rgba) if register_root else None)
        if reg:
            rgba = shift(rgba, reg["dx"], reg["dy"])
            info["registration"] = reg
    normalized = rgba
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
    checks.extend(run_checks(kind, normalized, locked, palettes, acceptance, parent_locked))
    info["metrics_raw"] = sl.measure(normalized)
    info["metrics_locked"] = sl.measure(locked)
    return TakeResult(raw=raw, normalized=normalized, locked=locked, checks=checks, info=info)
