#!/usr/bin/env python3
"""Pofu asset pipeline: from raw AI-generated PNGs to an asset catalog.

The art bible (docs/design/art-bible.md) defines what a good asset looks
like; this tool enforces the measurable part of it and does the tedious,
error-prone part by machine:

* validate: alpha present where required, minimum resolution, palette drift
  against the locked palettes in design/tokens/pofu-tokens.json;
* key out a flat background when an image arrived without alpha;
* trim transparent margins and re-pad consistently;
* normalize character frames onto one canvas, at one scale, with the feet
  on a shared ground line;
* slice sprite sheets into registered frame sequences with a manifest;
* export @2x/@3x image sets (and app icons) into an .xcassets catalog with
  valid Contents.json files.

Subcommands (run `python3 -I tools/assets/process_assets.py <cmd> -h`):

    process        inbox folder -> validated, normalized .xcassets + report
    slice          one sprite sheet -> frame sequence + manifest.json
    palette-card   render a palette swatch card to attach to prompts
    selftest       run the self-test (tools/assets/test_process_assets.py)

Inbox naming convention: ``<kind>__<name>[--<variant>].png`` where kind is
one of char, sprite, badge, scene, icon, appicon; name is kebab-case. Example:
``char__pofu-content.png``, ``badge__first-resist.png``,
``appicon__app-icon--dark.png``. ``icon`` is a painted domain icon
(ADR-0018); ``appicon`` is the app icon.

Dependencies: Python 3.10+, Pillow, numpy (tools/assets/requirements.txt).
No model downloads, no network access.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_TOKENS = REPO_ROOT / "design" / "tokens" / "pofu-tokens.json"

# ---------------------------------------------------------------------------
# Specifications per asset kind. Point sizes are logical iOS points; @3x
# pixels are three times larger. Every value can be overridden with
# --config, a JSON file of the same shape.
# ---------------------------------------------------------------------------

DEFAULT_SPECS: dict[str, dict] = {
    "char": {
        "description": "Pofu character frame: the base or an edit of it (docs/design/companion-motion.md, section 5).",
        "requires_alpha": True,
        "min_source_px": 1024,
        "point_size": [320, 480],
        "fit": "group-baseline",
        "baseline_frac": 0.88,
        "pad_frac": 0.04,
        "palettes": ["character", "character-wilting"],
        "folder": "Character",
    },
    "sprite": {
        "description": "Prop or sticker (seed, wheel, tea glass).",
        "requires_alpha": True,
        "min_source_px": 512,
        "point_size": [96, 96],
        "fit": "contain",
        "pad_frac": 0.06,
        "palettes": ["character", "world-day", "ui"],
        "folder": "Stickers",
    },
    "badge": {
        "description": "Achievement badge medallion, no text.",
        "requires_alpha": True,
        "min_source_px": 1024,
        "point_size": [120, 120],
        "fit": "contain",
        "pad_frac": 0.03,
        "palettes": ["character", "world-day", "world-sunset", "world-night", "ui"],
        "folder": "Badges",
    },
    "scene": {
        "description": "Opaque background plate, bottom-anchored in the app.",
        "requires_alpha": False,
        "min_source_px": 1024,
        "point_width": 440,
        "fit": "width",
        "palettes": ["world-day", "world-sunset", "world-night", "character"],
        "folder": "Scenes",
    },
    "icon": {
        "description": "Painted domain icon (ADR-0018 Glass++), shown at 28-60 pt.",
        "requires_alpha": True,
        "min_source_px": 1024,
        "point_size": [60, 60],
        "fit": "contain",
        "pad_frac": 0.04,
        "palettes": ["character", "world-day", "ui"],
        "folder": "Icons",
    },
    "appicon": {
        "description": "App icon layer, 1024 x 1024, opaque (dark variant may be transparent).",
        "requires_alpha": False,
        "min_source_px": 1024,
        "fit": "icon",
        "palettes": ["character", "world-day", "world-sunset", "world-night", "ui"],
        "folder": "",
    },
}

# Drift thresholds in CIELAB Delta E (CIE76). A Delta E of about 2.3 is a
# just-noticeable difference; 10 is clearly a different color.
DRIFT_OFF_PALETTE_DE = 12.0
# Calibrated on the concept crops: the approved hamster scores mean 1.5,
# p95 5.4; the lilac chinchilla (wrong palette) scores mean 5.7, p95 11.5.
DRIFT_WARN = {"mean": 2.5, "p95": 9.0, "off_frac": 0.03}
DRIFT_FAIL = {"mean": 4.5, "p95": 14.0, "off_frac": 0.10}

ALPHA_SOLID = 0.5
FILENAME_RE = re.compile(r"^(?P<kind>[a-z]+)__(?P<name>[a-z0-9]+(?:-[a-z0-9]+)*)(?:--(?P<variant>[a-z0-9-]+))?\.png$")


# ---------------------------------------------------------------------------
# Color science
# ---------------------------------------------------------------------------

def hex_to_rgb(hex_color: str) -> np.ndarray:
    value = hex_color.lstrip("#")
    return np.array([int(value[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64) / 255.0


def rgb_to_hex(rgb: np.ndarray) -> str:
    r, g, b = (int(round(float(np.clip(c, 0, 1)) * 255)) for c in rgb)
    return f"#{r:02X}{g:02X}{b:02X}"


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    """sRGB in 0...1, shape (..., 3) -> CIELAB (D65), shape (..., 3)."""
    rgb = np.asarray(rgb, dtype=np.float64)
    linear = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    m = np.array([
        [0.4124564, 0.3575761, 0.1804375],
        [0.2126729, 0.7151522, 0.0721750],
        [0.0193339, 0.1191920, 0.9503041],
    ])
    xyz = linear @ m.T
    xyz = xyz / np.array([0.95047, 1.0, 1.08883])
    eps, kappa = 216 / 24389, 24389 / 27
    f = np.where(xyz > eps, np.cbrt(xyz), (kappa * xyz + 16) / 116)
    lightness = 116 * f[..., 1] - 16
    a = 500 * (f[..., 0] - f[..., 1])
    b = 200 * (f[..., 1] - f[..., 2])
    return np.stack([lightness, a, b], axis=-1)


# ---------------------------------------------------------------------------
# Tokens and palettes
# ---------------------------------------------------------------------------

def load_tokens(path: Path = DEFAULT_TOKENS) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def palette_sets(tokens: dict, names: list[str]) -> dict[str, list[str]]:
    sets = {}
    for name in names:
        entries = tokens["artPalettes"].get(name)
        if entries is None:
            raise SystemExit(f"Unknown palette '{name}' in {DEFAULT_TOKENS.name}")
        sets[name] = [v for k, v in entries.items() if not k.startswith("$")]
    return sets


# ---------------------------------------------------------------------------
# Palette drift
# ---------------------------------------------------------------------------

@dataclass
class DriftReport:
    mean: float
    p95: float
    off_frac: float
    status: str
    top_off_palette: list[str] = field(default_factory=list)
    pixels: int = 0

    def as_dict(self) -> dict:
        return {
            "meanDeltaE": round(self.mean, 2),
            "p95DeltaE": round(self.p95, 2),
            "offPaletteFraction": round(self.off_frac, 4),
            "status": self.status,
            "topOffPaletteColors": self.top_off_palette,
            "sampledPixels": self.pixels,
        }


def _segments(sets: dict[str, list[str]]) -> tuple[np.ndarray, np.ndarray]:
    """Line segments in Lab between every pair of colors within each set.

    Painted shading is a mix of locked colors, so the distance that matters
    is to the nearest mix, not to the nearest swatch. Mixing across sets
    (night sky with cream fur) is not allowed.
    """
    starts, ends = [], []
    for colors in sets.values():
        labs = srgb_to_lab(np.array([hex_to_rgb(c) for c in colors]))
        for i in range(len(labs)):
            starts.append(labs[i])
            ends.append(labs[i])  # degenerate segment: the swatch itself
            for j in range(i + 1, len(labs)):
                starts.append(labs[i])
                ends.append(labs[j])
    return np.array(starts), np.array(ends)


def nearest_mix_distance(lab: np.ndarray, sets: dict[str, list[str]], chunk: int = 4096) -> np.ndarray:
    a, b = _segments(sets)
    ab = b - a
    denom = np.maximum((ab ** 2).sum(-1), 1e-9)
    out = np.empty(len(lab))
    for start in range(0, len(lab), chunk):
        p = lab[start:start + chunk, None, :]
        t = np.clip(((p - a) * ab).sum(-1) / denom, 0.0, 1.0)
        closest = a + t[..., None] * ab
        out[start:start + chunk] = np.sqrt(((p - closest) ** 2).sum(-1)).min(axis=1)
    return out


def palette_drift(rgba: np.ndarray, sets: dict[str, list[str]], max_samples: int = 20000, seed: int = 7) -> DriftReport:
    """Measure how far an image's solid pixels are from the locked palette."""
    rgb = rgba[..., :3].reshape(-1, 3)
    alpha = rgba[..., 3].reshape(-1)
    solid = rgb[alpha > 0.9]
    if len(solid) == 0:
        return DriftReport(0.0, 0.0, 0.0, "fail", ["no opaque pixels"], 0)
    if len(solid) > max_samples:
        rng = np.random.default_rng(seed)
        solid = solid[rng.choice(len(solid), max_samples, replace=False)]
    lab = srgb_to_lab(solid)
    distance = nearest_mix_distance(lab, sets)
    off = distance > DRIFT_OFF_PALETTE_DE
    p95 = float(np.percentile(distance, 95))
    off_frac = float(off.mean())
    mean = float(distance.mean())
    if mean > DRIFT_FAIL["mean"] or p95 > DRIFT_FAIL["p95"] or off_frac > DRIFT_FAIL["off_frac"]:
        status = "fail"
    elif mean > DRIFT_WARN["mean"] or p95 > DRIFT_WARN["p95"] or off_frac > DRIFT_WARN["off_frac"]:
        status = "warn"
    else:
        status = "ok"
    top: list[str] = []
    if off.any():
        quantized = np.round(solid[off] * 15) / 15  # 16 levels per channel
        colors, counts = np.unique(quantized, axis=0, return_counts=True)
        for idx in np.argsort(-counts)[:5]:
            top.append(f"{rgb_to_hex(colors[idx])} ({counts[idx] / len(solid):.1%})")
    return DriftReport(mean, p95, off_frac, status, top, len(solid))


# ---------------------------------------------------------------------------
# Image helpers
# ---------------------------------------------------------------------------

def load_rgba(path: Path) -> tuple[np.ndarray, bool]:
    """Return the image as float RGBA in 0...1 and whether it carried alpha."""
    with Image.open(path) as im:
        has_alpha_channel = im.mode in ("RGBA", "LA", "PA") or (im.mode == "P" and "transparency" in im.info)
        arr = np.asarray(im.convert("RGBA"), dtype=np.float64) / 255.0
    meaningful = has_alpha_channel and float((arr[..., 3] < 0.98).mean()) > 0.01
    return arr, meaningful


def to_image(rgba: np.ndarray) -> Image.Image:
    return Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8)).copy()


def detect_flat_background(rgba: np.ndarray, band_frac: float = 0.02) -> tuple[np.ndarray, float]:
    """Median border color and its spread (p90 Delta E from the median)."""
    h, w = rgba.shape[:2]
    band = max(2, int(min(h, w) * band_frac))
    border = np.concatenate([
        rgba[:band, :, :3].reshape(-1, 3), rgba[-band:, :, :3].reshape(-1, 3),
        rgba[:, :band, :3].reshape(-1, 3), rgba[:, -band:, :3].reshape(-1, 3),
    ])
    color = np.median(border, axis=0)
    spread = float(np.percentile(np.linalg.norm(srgb_to_lab(border) - srgb_to_lab(color), axis=-1), 90))
    return color, spread


def key_background(rgba: np.ndarray, color: np.ndarray | None = None, tol_lo: float = 2.0,
                   tol_hi: float = 7.0, max_spread: float = 6.0) -> tuple[np.ndarray, dict]:
    """Key out a flat background that touches the image border.

    Only pixels connected to the border are keyed, so cream fur inside the
    silhouette survives even when it is close to the background color.
    Edge pixels are decontaminated: the background color is unmixed from
    semi-transparent fringes so the sprite has no peach halo on violet.
    """
    if color is None:
        color, spread = detect_flat_background(rgba)
        if spread > max_spread:
            raise ValueError(f"background is not flat enough to key (border spread Delta E {spread:.1f} > {max_spread})")
    else:
        spread = 0.0
    lab = srgb_to_lab(rgba[..., :3])
    distance = np.linalg.norm(lab - srgb_to_lab(color), axis=-1)

    candidate = (distance < tol_hi).astype(np.uint8) * 255
    # copy(): fromarray may share read-only memory, and floodfill would then
    # silently do nothing.
    padded = Image.fromarray(np.pad(candidate, 1, constant_values=255)).copy()
    ImageDraw.floodfill(padded, (0, 0), 128)
    connected = (np.asarray(padded)[1:-1, 1:-1] == 128)

    ramp = np.clip((distance - tol_lo) / (tol_hi - tol_lo), 0.0, 1.0)
    ramp = ramp * ramp * (3 - 2 * ramp)  # smoothstep
    alpha = np.where(connected, ramp, 1.0) * rgba[..., 3]

    out = rgba.copy()
    a = alpha[..., None]
    with np.errstate(divide="ignore", invalid="ignore"):
        unmixed = (rgba[..., :3] - (1 - a) * color) / np.maximum(a, 1e-6)
    fringe = (alpha > 0.02) & (alpha < 0.999)
    out[..., :3] = np.where(fringe[..., None], np.clip(unmixed, 0, 1), rgba[..., :3])
    out[..., 3] = alpha
    out[alpha <= 0.02] = 0.0
    info = {"keyedColor": rgb_to_hex(color), "borderSpreadDeltaE": round(spread, 2),
            "keyedFraction": round(float((alpha < 0.5).mean()), 4),
            "interiorHoleFraction": round(interior_hole_fraction(alpha), 4)}
    return out, info


KEY_LEAK_MAX = 0.02


def interior_hole_fraction(alpha: np.ndarray) -> float:
    """Share of the silhouette's interior that ended up transparent.

    Keying a white character on a near-white background leaks through thin
    fur strands into the face. Closing the mask seals those channels; any
    transparency left deep inside the sealed silhouette is a leak. The
    approved hamster scores 0.0; the white chinchilla concept scores 0.24.
    """
    # Work on a small copy: the check is about shape, and rank filters are
    # quadratic in kernel size.
    small = Image.fromarray(np.round(alpha * 255).astype(np.uint8)).copy()
    small.thumbnail((256, 256), Image.Resampling.BILINEAR)
    alpha = np.asarray(small, dtype=np.float64) / 255
    h, w = alpha.shape
    k = max(3, int(min(h, w) * 0.03) | 1)
    solid = Image.fromarray(((alpha > ALPHA_SOLID) * 255).astype(np.uint8)).copy()
    closed = solid.filter(ImageFilter.MaxFilter(k)).filter(ImageFilter.MinFilter(k))
    inverse = Image.fromarray(np.pad(255 - np.asarray(closed), 1, constant_values=255).astype(np.uint8)).copy()
    ImageDraw.floodfill(inverse, (0, 0), 128)
    outside = np.asarray(inverse)[1:-1, 1:-1] == 128
    filled = Image.fromarray(((~outside) * 255).astype(np.uint8)).copy()
    interior = np.asarray(filled.filter(ImageFilter.MinFilter(2 * k + 1))) > 0
    if not interior.any():
        return 0.0
    return float((interior & (alpha < 0.1)).sum() / interior.sum())


@dataclass
class Geometry:
    """Where the opaque content sits inside an image (pixel units)."""
    left: int
    top: int
    right: int  # exclusive
    bottom: int  # exclusive
    baseline: int  # first row below the feet
    base_x: float  # horizontal center of the feet

    @property
    def width(self) -> int:
        return self.right - self.left

    def as_dict(self) -> dict:
        return {"bbox": [self.left, self.top, self.right, self.bottom], "baseline": self.baseline,
                "baseX": round(self.base_x, 1)}


def measure(rgba: np.ndarray, alpha_min: float = 8 / 255) -> Geometry:
    alpha = rgba[..., 3]
    visible = alpha > alpha_min
    if not visible.any():
        raise ValueError("image is fully transparent")
    rows = np.where(visible.any(axis=1))[0]
    cols = np.where(visible.any(axis=0))[0]
    top, bottom, left, right = int(rows[0]), int(rows[-1]) + 1, int(cols[0]), int(cols[-1]) + 1

    solid = alpha > ALPHA_SOLID
    counts = solid.sum(axis=1)
    min_count = max(3, int(0.02 * (right - left)))
    solid_rows = np.where(counts >= min_count)[0]
    baseline = int(solid_rows[-1]) + 1 if len(solid_rows) else bottom

    height = max(1, baseline - top)
    foot_top = max(top, baseline - max(2, int(0.12 * height)))
    foot = solid[foot_top:baseline]
    ys, xs = np.nonzero(foot)
    base_x = float(xs.mean()) if len(xs) else (left + right) / 2
    return Geometry(left, top, right, bottom, baseline, base_x)


def baked_shadow_suspected(rgba: np.ndarray, g: Geometry) -> bool:
    """True when the figure ends in a wide, flat band: a painted ground shadow.

    Feet are two narrow blobs; a cast shadow is an ellipse almost as wide
    as the body. Sprites must not carry one (the app draws contact shadows
    so they can squash with hops), and a baked shadow also pulls the
    detected ground line below the feet.
    """
    solid = rgba[g.top:g.baseline, g.left:g.right, 3] > ALPHA_SOLID
    if solid.shape[0] < 10:
        return False
    widths = solid.sum(axis=1)
    bottom = widths[-max(2, int(0.03 * len(widths))):]
    return float(bottom.max()) > 0.6 * float(widths.max())


def resize_rgba(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    # Pillow resamples RGBA in premultiplied space, so no dark fringes.
    return img.resize(size, Image.Resampling.LANCZOS)


# ---------------------------------------------------------------------------
# Asset catalog writing
# ---------------------------------------------------------------------------

CATALOG_INFO = {"info": {"author": "xcode", "version": 1}}


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def ensure_catalog(catalog: Path) -> None:
    write_json(catalog / "Contents.json", CATALOG_INFO)


def ensure_group(catalog: Path, folder: str) -> Path:
    if not folder:
        return catalog
    group = catalog / folder
    write_json(group / "Contents.json", {**CATALOG_INFO, "properties": {"provides-namespace": True}})
    return group


def write_imageset(parent: Path, name: str, scaled: dict[int, Image.Image]) -> Path:
    imageset = parent / f"{name}.imageset"
    if imageset.exists():
        shutil.rmtree(imageset)
    imageset.mkdir(parents=True)
    images = [{"idiom": "universal", "scale": "1x"}]
    for scale in (2, 3):
        filename = f"{name}@{scale}x.png"
        scaled[scale].save(imageset / filename, optimize=True)
        images.append({"filename": filename, "idiom": "universal", "scale": f"{scale}x"})
    write_json(imageset / "Contents.json", {"images": images, **CATALOG_INFO})
    return imageset


def write_appicon(catalog: Path, name: str, variants: dict[str, Image.Image]) -> Path:
    iconset = catalog / f"{name}.appiconset"
    if iconset.exists():
        shutil.rmtree(iconset)
    iconset.mkdir(parents=True)
    images = []
    for variant, img in variants.items():
        filename = f"{name}{'' if variant == 'light' else '-' + variant}.png"
        img.save(iconset / filename, optimize=True)
        entry = {"filename": filename, "idiom": "universal", "platform": "ios", "size": "1024x1024"}
        if variant in ("dark", "tinted"):
            entry = {"appearances": [{"appearance": "luminosity", "value": variant}], **entry}
        images.append(entry)
    write_json(iconset / "Contents.json", {"images": images, **CATALOG_INFO})
    return iconset


# ---------------------------------------------------------------------------
# process: inbox -> catalog
# ---------------------------------------------------------------------------

@dataclass
class Item:
    path: Path
    kind: str
    name: str
    variant: str | None
    rgba: np.ndarray | None = None
    issues: list[dict] = field(default_factory=list)
    info: dict = field(default_factory=dict)

    def issue(self, level: str, message: str) -> None:
        self.issues.append({"level": level, "message": message})

    @property
    def failed(self) -> bool:
        return any(i["level"] == "error" for i in self.issues)


def parse_inbox(inbox: Path, specs: dict) -> tuple[list[Item], list[str]]:
    items, skipped = [], []
    for path in sorted(inbox.glob("*.png")):
        match = FILENAME_RE.match(path.name)
        if not match or match["kind"] not in specs:
            skipped.append(path.name)
            continue
        items.append(Item(path, match["kind"], match["name"], match["variant"]))
    return items, skipped


def validate_and_prepare(item: Item, spec: dict, tokens: dict, key_mode: str) -> None:
    rgba, has_alpha = load_rgba(item.path)
    h, w = rgba.shape[:2]
    item.info["sourceSize"] = [w, h]
    if min(w, h) < spec["min_source_px"]:
        item.issue("error", f"source {w}x{h} is below the minimum {spec['min_source_px']} px on the short side")

    if spec["requires_alpha"] and not has_alpha:
        if key_mode == "off":
            item.issue("error", "no transparency and keying is off; request a transparent PNG")
        else:
            try:
                color = None if key_mode == "auto" else hex_to_rgb(key_mode)
                rgba, key_info = key_background(rgba, color)
                item.info["keyed"] = key_info
                if key_info["interiorHoleFraction"] > KEY_LEAK_MAX:
                    item.issue("error", f"keying leaked into the silhouette ({key_info['interiorHoleFraction']:.1%} of the "
                                        "interior is transparent); regenerate with a transparent or chroma-green background")
                else:
                    item.issue("warn", f"no alpha in source; keyed out {key_info['keyedColor']} (check edges)")
            except ValueError as error:
                item.issue("error", f"no alpha and could not key: {error}")
    if item.kind == "appicon" and item.variant in (None, "light") and has_alpha:
        if float(rgba[..., 3].min()) < 0.999:
            item.issue("error", "app icons must be fully opaque (no transparency)")

    if spec["requires_alpha"] and not item.failed:
        if baked_shadow_suspected(rgba, measure(rgba)):
            item.issue("warn", "a ground shadow seems painted in; erase it or regenerate with 'no ground shadow' "
                               "(the app draws contact shadows), otherwise the ground line sits below the feet")

    sets = palette_sets(tokens, spec["palettes"])
    drift = palette_drift(rgba, sets)
    item.info["paletteDrift"] = drift.as_dict()
    if drift.status == "fail":
        item.issue("error", f"palette drift: mean Delta E {drift.mean:.1f}, p95 {drift.p95:.1f}, {drift.off_frac:.1%} off-palette "
                            f"(top: {', '.join(drift.top_off_palette[:3])})")
    elif drift.status == "warn":
        item.issue("warn", f"palette drift: mean Delta E {drift.mean:.1f}, p95 {drift.p95:.1f}, {drift.off_frac:.1%} off-palette")
    item.rgba = rgba


def crop(rgba: np.ndarray, g: Geometry) -> Image.Image:
    return to_image(rgba[g.top:g.bottom, g.left:g.right])


def render_group_baseline(items: list[Item], spec: dict) -> dict[str, dict[int, Image.Image]]:
    """One scale for the whole group, feet on one ground line, feet centered.

    If every frame arrived on the same canvas size, they are edits of one
    base (the asset contract), so all of them get the *identical*
    transform: region-composited variants then stay aligned pixel for
    pixel. Otherwise each frame is registered by its own feet.
    """
    pw, ph = spec["point_size"]
    pad = spec["pad_frac"]
    ground = spec["baseline_frac"]
    geos = {it.name + (it.variant or ""): measure(it.rgba) for it in items}
    locked = len(items) > 1 and len({it.rgba.shape[:2] for it in items}) == 1
    if locked:
        ref = next((it for it in items if it.name.endswith("base") and not it.variant), items[0])
        g_ref = geos[ref.name + (ref.variant or "")]
        union = Geometry(
            left=min(g.left for g in geos.values()), top=min(g.top for g in geos.values()),
            right=max(g.right for g in geos.values()), bottom=max(g.bottom for g in geos.values()),
            baseline=g_ref.baseline, base_x=g_ref.base_x,
        )
        geos = {key: union for key in geos}

    # Unit canvas: width 1 by ph/pw. Find the largest scale (canvas units per
    # source pixel) at which every frame fits on both sides of its feet.
    aspect = ph / pw
    scales = []
    for it in items:
        g = geos[it.name + (it.variant or "")]
        left_extent = g.base_x - g.left
        right_extent = g.right - g.base_x
        above = g.baseline - g.top
        below = g.bottom - g.baseline
        scales.append(min(
            (0.5 - pad) / max(left_extent, 1), (0.5 - pad) / max(right_extent, 1),
            (ground * aspect - pad) / max(above, 1),
            ((1 - ground) * aspect - pad / 2) / max(below, 1) if below > 0 else math.inf,
        ))
    unit_scale = min(scales)

    out = {}
    for it in items:
        key = it.name + (it.variant or "")
        g = geos[key]
        content = crop(it.rgba, g)
        rendered = {}
        for scale in (2, 3):
            cw, ch = pw * scale, ph * scale
            s = unit_scale * cw
            size = (max(1, round(g.width * s)), max(1, round((g.bottom - g.top) * s)))
            scaled = resize_rgba(content, size)
            canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            x = round(cw / 2 - (g.base_x - g.left) * s)
            y = round(ground * ch - (g.baseline - g.top) * s)
            canvas.alpha_composite(scaled, (x, y))
            rendered[scale] = canvas
        it.info["registration"] = {**g.as_dict(), "mode": "locked-to-base" if locked else "per-frame-feet",
                                   "groundLineFrac": ground, "scalePxPerSourcePx@3x": round(unit_scale * pw * 3, 4)}
        if unit_scale * pw * 3 > 1.0:
            it.issue("warn", f"@3x upscales the source by {unit_scale * pw * 3:.2f}x")
        out[key] = rendered
    return out


def render_contain(item: Item, spec: dict) -> dict[int, Image.Image]:
    pw, ph = spec["point_size"]
    g = measure(item.rgba)
    content = crop(item.rgba, g)
    rendered = {}
    for scale in (2, 3):
        cw, ch = pw * scale, ph * scale
        inner_w, inner_h = cw * (1 - 2 * spec["pad_frac"]), ch * (1 - 2 * spec["pad_frac"])
        s = min(inner_w / content.width, inner_h / content.height)
        size = (max(1, round(content.width * s)), max(1, round(content.height * s)))
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        canvas.alpha_composite(resize_rgba(content, size), ((cw - size[0]) // 2, (ch - size[1]) // 2))
        rendered[scale] = canvas
        if scale == 3 and s > 1.0:
            item.issue("warn", f"@3x upscales the source by {s:.2f}x")
    return rendered


def render_scene(item: Item, spec: dict) -> dict[int, Image.Image]:
    img = to_image(item.rgba).convert("RGB")
    rendered = {}
    for scale in (2, 3):
        w = spec["point_width"] * scale
        h = round(img.height * w / img.width)
        rendered[scale] = img.resize((w, h), Image.Resampling.LANCZOS)
        factor = w / img.width
        if scale == 3 and factor > 1.5:
            item.issue("error", f"@3x would upscale the plate {factor:.2f}x (max 1.5x); upscale the master first")
        elif scale == 3 and factor > 1.0:
            item.issue("warn", f"@3x upscales the plate {factor:.2f}x")
    return rendered


def run_process(args: argparse.Namespace) -> int:
    specs = json.loads(json.dumps(DEFAULT_SPECS))
    if args.config:
        for kind, override in json.loads(Path(args.config).read_text(encoding="utf-8")).items():
            specs.setdefault(kind, {}).update(override)
    tokens = load_tokens(args.tokens)
    items, skipped = parse_inbox(Path(args.inbox), specs)
    if not items:
        print(f"No assets found in {args.inbox} (expected <kind>__<name>.png).", file=sys.stderr)
        return 2

    catalog = Path(args.out)
    ensure_catalog(catalog)
    for item in items:
        validate_and_prepare(item, specs[item.kind], tokens, args.key)

    exported: list[str] = []
    ok_items = [it for it in items if not it.failed or args.allow_failures]

    # Character frames are normalized together so they share scale and ground.
    chars = [it for it in ok_items if specs[it.kind]["fit"] == "group-baseline"]
    if chars:
        group_dir = ensure_group(catalog, specs["char"]["folder"])
        for key, rendered in render_group_baseline(chars, specs["char"]).items():
            item = next(it for it in chars if it.name + (it.variant or "") == key)
            name = item.name + (f"-{item.variant}" if item.variant else "")
            exported.append(str(write_imageset(group_dir, name, rendered).relative_to(catalog)))

    icons: dict[str, dict[str, Image.Image]] = {}
    for item in ok_items:
        spec = specs[item.kind]
        name = item.name + (f"-{item.variant}" if item.variant and item.kind != "appicon" else "")
        if spec["fit"] == "contain":
            exported.append(str(write_imageset(ensure_group(catalog, spec["folder"]), name, render_contain(item, spec)).relative_to(catalog)))
        elif spec["fit"] == "width":
            rendered = render_scene(item, spec)
            if not item.failed or args.allow_failures:
                exported.append(str(write_imageset(ensure_group(catalog, spec["folder"]), name, rendered).relative_to(catalog)))
        elif spec["fit"] == "icon":
            img = to_image(item.rgba)
            if img.size != (1024, 1024):
                if img.width != img.height:
                    item.issue("error", "app icon must be square")
                    continue
                img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
            variant = item.variant or "light"
            if variant == "tinted":
                img = img.convert("LA").convert("RGBA")
            if variant in ("light", "tinted"):
                img = img.convert("RGB")
            icons.setdefault(item.name, {})[variant] = img
    for name, variants in icons.items():
        if "light" not in variants:
            print(f"icon {name}: missing the default (light) variant; skipped", file=sys.stderr)
            continue
        asset_name = "AppIcon" if name == "app-icon" else name
        exported.append(str(write_appicon(catalog, asset_name, variants).relative_to(catalog)))

    report = {
        "catalog": str(catalog),
        "exported": exported,
        "skipped": skipped,
        "items": [{"file": it.path.name, "kind": it.kind, "name": it.name, "variant": it.variant,
                   "status": "error" if it.failed else ("warn" if it.issues else "ok"),
                   "issues": it.issues, **it.info} for it in items],
    }
    report_path = Path(args.report) if args.report else catalog.parent / f"{catalog.stem}-report.json"
    write_json(report_path, report)

    for it in items:
        status = "FAIL" if it.failed else ("warn" if it.issues else "ok")
        drift = it.info.get("paletteDrift", {})
        print(f"[{status:4s}] {it.path.name}  drift p95={drift.get('p95DeltaE', '-')}  off={drift.get('offPaletteFraction', '-')}")
        for issue in it.issues:
            print(f"         {issue['level']}: {issue['message']}")
    for name in skipped:
        print(f"[skip] {name} (does not match <kind>__<name>.png)")
    print(f"\nExported {len(exported)} asset(s) to {catalog}\nReport: {report_path}")
    return 1 if any(it.failed for it in items) else 0


# ---------------------------------------------------------------------------
# slice: sprite sheet -> registered frame sequence
# ---------------------------------------------------------------------------

def find_cuts(projection: np.ndarray, count: int, window_frac: float = 0.08) -> list[int]:
    """Cut positions near the even grid lines, snapped to the emptiest band."""
    n = len(projection)
    cell = n / count
    cuts = [0]
    window = max(1, int(cell * window_frac))
    for k in range(1, count):
        guess = int(round(k * cell))
        lo, hi = max(1, guess - window), min(n - 1, guess + window)
        segment = projection[lo:hi]
        best = np.flatnonzero(segment == segment.min())
        cuts.append(int(lo + best[len(best) // 2]))  # middle of the emptiest run
    cuts.append(n)
    return cuts


def slice_sheet(rgba: np.ndarray, cols: int, rows: int, snap: bool = True) -> list[tuple[tuple[int, int, int, int], np.ndarray]]:
    alpha = rgba[..., 3]
    if snap:
        xs = find_cuts(alpha.sum(axis=0), cols)
        ys = find_cuts(alpha.sum(axis=1), rows)
    else:
        xs = [round(i * rgba.shape[1] / cols) for i in range(cols + 1)]
        ys = [round(i * rgba.shape[0] / rows) for i in range(rows + 1)]
    cells = []
    for r in range(rows):
        for c in range(cols):
            box = (xs[c], ys[r], xs[c + 1], ys[r + 1])
            cells.append((box, rgba[box[1]:box[3], box[0]:box[2]]))
    return cells


def isolate_main_figure(cell: np.ndarray) -> np.ndarray:
    """Drop stray specks and slivers of neighbouring cells: keep the
    largest connected opaque region (plus anything overlapping its box)."""
    solid = (cell[..., 3] > ALPHA_SOLID).astype(np.uint8)
    if not solid.any():
        return cell
    h, w = solid.shape
    best_area, best_mask = 0, None
    remaining = (solid * 255).astype(np.uint8)
    # Flood-fill labelling with Pillow; cells are small, components few.
    for _ in range(64):
        ys, xs = np.nonzero(remaining == 255)
        if len(ys) == 0:
            break
        work = Image.fromarray(remaining).copy()
        ImageDraw.floodfill(work, (int(xs[0]), int(ys[0])), 100)
        arr = np.asarray(work)
        component = arr == 100
        area = int(component.sum())
        if area > best_area:
            best_area, best_mask = area, component
        remaining = np.where(component, 0, arr).astype(np.uint8)
    rows = np.where(best_mask.any(axis=1))[0]
    cols = np.where(best_mask.any(axis=0))[0]
    margin = max(2, int(0.04 * max(h, w)))
    keep = np.zeros((h, w), dtype=bool)
    keep[max(0, rows[0] - margin):rows[-1] + 1 + margin, max(0, cols[0] - margin):cols[-1] + 1 + margin] = True
    out = cell.copy()
    out[~keep] = 0.0
    return out


def frame_consistency(frames: list[np.ndarray], geos: list[Geometry]) -> list[dict]:
    """Per-frame color and scale deviation from the sequence median."""
    means = []
    for f in frames:
        solid = f[..., :3][f[..., 3] > 0.9]
        means.append(srgb_to_lab(solid.mean(axis=0)) if len(solid) else np.zeros(3))
    means = np.array(means)
    median_lab = np.median(means, axis=0)
    widths = np.array([g.width for g in geos], dtype=float)
    median_w = float(np.median(widths))
    out = []
    for i, g in enumerate(geos):
        color_shift = float(np.linalg.norm(means[i] - median_lab))
        width_change = float(widths[i] / median_w - 1) if median_w else 0.0
        flags = []
        if color_shift > 4.0:
            flags.append(f"color shift Delta E {color_shift:.1f} vs sequence median")
        if abs(width_change) > 0.12:
            flags.append(f"width {width_change:+.0%} vs median (scale drift or a big squash?)")
        out.append({"meanColorShiftDeltaE": round(color_shift, 2), "widthChange": round(width_change, 3), "flags": flags})
    return out


def run_slice(args: argparse.Namespace) -> int:
    cols, rows = (int(v) for v in args.grid.lower().split("x"))
    tokens = load_tokens(args.tokens)
    rgba, has_alpha = load_rgba(Path(args.sheet))
    notes = []
    if not has_alpha:
        if args.key == "off":
            print("Sheet has no transparency and keying is off.", file=sys.stderr)
            return 1
        color = None if args.key == "auto" else hex_to_rgb(args.key)
        rgba, key_info = key_background(rgba, color)
        notes.append(f"keyed background {key_info['keyedColor']}")
        if key_info["interiorHoleFraction"] > KEY_LEAK_MAX:
            print(f"Keying leaked into the figures ({key_info['interiorHoleFraction']:.1%} of the interior); "
                  "regenerate the sheet on a transparent or chroma-green background.", file=sys.stderr)
            return 1

    cells = slice_sheet(rgba, cols, rows, snap=not args.no_snap)
    count = args.frames or len(cells)
    cells = cells[:count]
    frames = [isolate_main_figure(c) for _, c in cells]
    empty = [i for i, f in enumerate(frames) if not (f[..., 3] > 8 / 255).any()]
    if empty:
        print(f"Empty cells: {empty}. Use --frames to drop trailing empty cells.", file=sys.stderr)
        return 1
    geos = [measure(f) for f in frames]

    pad = max(2, int(args.pad_frac * max(c.shape[1] for _, c in cells)))
    if args.register == "feet":
        # Shared registration: every frame's feet center and ground line land
        # on the same canvas point, so in-place loops do not jitter.
        left = max(g.base_x - g.left for g in geos)
        right = max(g.right - g.base_x for g in geos)
        above = max(g.baseline - g.top for g in geos)
        below = max(g.bottom - g.baseline for g in geos)
        width = int(math.ceil(left + right)) + 2 * pad
        height = int(math.ceil(above + below)) + 2 * pad
        anchor = (pad + left, pad + above)
        placements = [(round(anchor[0] - (g.base_x - g.left)), round(anchor[1] - (g.baseline - g.top))) for g in geos]
    else:
        # Cell registration: keep each figure where the artist drew it inside
        # its cell (hops leave the ground); crop the union box.
        u_left = min(g.left for g in geos)
        u_top = min(g.top for g in geos)
        u_right = max(g.right for g in geos)
        u_bottom = max(g.bottom for g in geos)
        width = u_right - u_left + 2 * pad
        height = u_bottom - u_top + 2 * pad
        anchor = (pad + float(np.median([g.base_x for g in geos])) - u_left, pad + max(g.baseline for g in geos) - u_top)
        placements = [(pad + g.left - u_left, pad + g.top - u_top) for g in geos]

    sets = palette_sets(tokens, args.palettes.split(","))
    consistency = frame_consistency(frames, geos)
    out_dir = Path(args.out) / args.name
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    scales = [2, 3] if args.point_height else [1]
    manifest_frames = []
    worst = "ok"
    for i, (frame, g, (x, y)) in enumerate(zip(frames, geos, placements)):
        canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        canvas.alpha_composite(crop(frame, g), (int(x), int(y)))
        drift = palette_drift(np.asarray(canvas, dtype=np.float64) / 255.0, sets)
        if drift.status == "fail" or (drift.status == "warn" and worst == "ok"):
            worst = drift.status
        files = {}
        for scale in scales:
            if scale == 1:
                img = canvas
                filename = f"{args.name}-{i:02d}.png"
            else:
                target_h = args.point_height * scale
                target_w = round(width * target_h / height)
                img = resize_rgba(canvas, (target_w, target_h))
                filename = f"{args.name}-{i:02d}@{scale}x.png"
                if scale == 3 and target_h > height:
                    consistency[i]["flags"].append(f"@3x upscales the cell {target_h / height:.2f}x")
            img.save(out_dir / filename, optimize=True)
            files[f"{scale}x"] = filename
        manifest_frames.append({"index": i, "files": files, "sourceCell": list(cells[i][0]),
                                "registration": g.as_dict(), "paletteDrift": drift.as_dict(), **consistency[i]})

    manifest = {
        "name": args.name,
        "fps": args.fps,
        "loop": not args.no_loop,
        "frameCount": len(frames),
        "durationSeconds": round(len(frames) / args.fps, 3),
        "registration": args.register,
        "canvasPx": [width, height],
        "anchorPx": [round(anchor[0], 1), round(anchor[1], 1)],
        "anchorUnit": [round(anchor[0] / width, 4), round(anchor[1] / height, 4)],
        "pointHeight": args.point_height,
        "source": Path(args.sheet).name,
        "grid": [cols, rows],
        "paletteDriftWorst": worst,
        "notes": notes,
        "frames": manifest_frames,
    }
    write_json(out_dir / "manifest.json", manifest)

    for f in manifest_frames:
        flags = f["flags"] + ([f"palette drift {f['paletteDrift']['status']}"] if f["paletteDrift"]["status"] != "ok" else [])
        print(f"frame {f['index']:02d}  cell baseline={f['registration']['baseline']:4d}  baseX={f['registration']['baseX']:7.1f}  "
              f"dE={f['meanColorShiftDeltaE']:5.2f}  {'; '.join(flags) or 'ok'}")
    print(f"\n{len(frames)} frames at {args.fps} fps -> {out_dir}  (canvas {width}x{height}px, registration {args.register})")
    return 1 if worst == "fail" else 0


# ---------------------------------------------------------------------------
# palette-card: a swatch image to attach as a color reference
# ---------------------------------------------------------------------------

def run_palette_card(args: argparse.Namespace) -> int:
    tokens = load_tokens(args.tokens)
    sets = palette_sets(tokens, args.palettes.split(","))
    colors = [c for values in sets.values() for c in values]
    size = 1024
    columns = 4
    rows = math.ceil(len(colors) / columns)
    margin, gap = 64, 24
    cell = (size - 2 * margin - (columns - 1) * gap) // columns
    height = 2 * margin + rows * cell + (rows - 1) * gap
    card = Image.new("RGB", (size, height), (255, 246, 236))
    draw = ImageDraw.Draw(card)
    for i, color in enumerate(colors):
        r, c = divmod(i, columns)
        x, y = margin + c * (cell + gap), margin + r * (cell + gap)
        draw.rounded_rectangle((x, y, x + cell, y + cell), radius=cell // 4, fill=color)
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    card.save(args.out, optimize=True)
    print(f"Wrote {args.out} ({len(colors)} swatches, no text so the model cannot copy labels)")
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="process_assets.py", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tokens", default=str(DEFAULT_TOKENS), help="tokens JSON with art palettes")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("process", help="inbox folder -> .xcassets catalog and report")
    p.add_argument("--inbox", required=True, help="folder of raw PNGs named <kind>__<name>.png")
    p.add_argument("--out", required=True, help="output catalog folder, e.g. build/PofuArt.xcassets")
    p.add_argument("--report", help="report JSON path (default: next to the catalog)")
    p.add_argument("--key", default="auto", help="background keying when alpha is missing: auto, off, or #RRGGBB")
    p.add_argument("--config", help="JSON overriding per-kind specs")
    p.add_argument("--allow-failures", action="store_true", help="export assets even if validation failed")
    p.set_defaults(func=run_process)

    s = sub.add_parser("slice", help="sprite sheet -> registered frame sequence + manifest.json")
    s.add_argument("--sheet", required=True)
    s.add_argument("--name", required=True, help="animation name, kebab-case, e.g. pofu-blink")
    s.add_argument("--grid", default="4x4", help="COLSxROWS, e.g. 4x4 or 3x3")
    s.add_argument("--frames", type=int, help="use only the first N cells (row-major)")
    s.add_argument("--fps", type=float, default=12.0)
    s.add_argument("--no-loop", action="store_true")
    s.add_argument("--register", choices=["feet", "cell"], default="feet",
                   help="feet: lock every frame's feet to one point (in-place loops); cell: keep the drawn position")
    s.add_argument("--point-height", type=int, help="export @2x/@3x at this height in points instead of source pixels")
    s.add_argument("--pad-frac", type=float, default=0.03)
    s.add_argument("--no-snap", action="store_true", help="cut on the exact even grid instead of snapping to gutters")
    s.add_argument("--key", default="auto", help="background keying when alpha is missing: auto, off, or #RRGGBB")
    s.add_argument("--palettes", default="character,character-wilting")
    s.add_argument("--out", required=True, help="output folder; frames go to <out>/<name>/")
    s.set_defaults(func=run_slice)

    c = sub.add_parser("palette-card", help="render a swatch card to attach to image prompts")
    c.add_argument("--palettes", default="character")
    c.add_argument("--out", required=True)
    c.set_defaults(func=run_palette_card)

    t = sub.add_parser("selftest", help="run the self-test")
    t.set_defaults(func=lambda _args: _selftest())
    return parser


def _selftest() -> int:
    import unittest
    here = Path(__file__).resolve().parent
    suite = unittest.defaultTestLoader.discover(str(here), pattern="test_process_assets.py", top_level_dir=str(here))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
