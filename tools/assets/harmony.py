#!/usr/bin/env python3
"""Asset harmony: measure every world master against the reference, and correct what is measurable.

The founder's ask (2026-11-02): every asset tuned, matched to the others and measured. Each master
that `preblur.py app` ships (its APP_SOURCES) is measured on the same footing, in CIELAB over its
opaque pixels, at the same world scale:

  L_p2, L_p98      black and white point (lightness percentiles)
  C_p95            chroma ceiling (how saturated the most colourful parts are)
  tint_a, tint_b   white balance: the mean a*, b* of the near-neutral pixels (C < 14, L > 55), the
                   colour of the light the painter imagined
  edge             edge softness: the alpha ramp's width, in world units
  detail           detail density: mean |Laplacian| of lightness at display size (4 px per unit)
  materials        per-material hue and chroma where the material library (design/art/materials.json)
                   detects one (the rose copper on the çaydanlık)

Station level chains (tea-stall-1 ... tea-stall-5) are also matched along the chain: every level was redrawn
from its locked parent and locked again, so each level lost about 30 % chroma (the çay ocağı's
median chroma fell 31 -> 11 from L1 to L5). A level's black point, white point and median chroma
(C_p50) are matched to its chain's L1 as corrected, and the chroma correction may go as far as the
chain needs. The pipeline's edit_chroma QA check stops new losses at promote time; harmony restores
the chains already generated.

Harmony corrects technical defects only (look round 3, the colour script): value range, white
balance drift, chroma lost along a chain. A material's colour is the art director's, kept in the
material library as a hue and chroma range; harmony pulls a material back only when the generator
drifted out of its range, to the range's nearest edge, never toward another material or a target
(round 2 moved the rose copper toward amber; the founder preferred the rose, so it is an accent now).

The reference is the approved island take (ADR-0018's style target). A metric is an outlier when it
is more than its tolerance away from the reference; the harmony score is 100 when everything
matches and drops as metrics leave their tolerance. Whatever is measurable becomes a correction:
black and white point (a linear remap of L), chroma scale, white balance (an a*, b* shift weighted
toward the neutrals), and material hue and chroma. Corrections are written to the manifest
(design/art/harmony/assets/<id>.json) and baked by `preblur.py app`; they apply only past tolerance,
so an asset that already matches is left exactly as painted. Characters are guarded: measured,
never corrected. Edge softness and detail cannot be fixed with colour; they are reported for the
next generation.

  python3 -I tools/assets/harmony.py measure [--sheet OUT.png]   write the manifest (and a sheet)
  python3 -I tools/assets/harmony.py check                       fail if the manifest is stale
  python3 -I tools/assets/harmony.py score IMAGE --ppu N         one image's stats and score (JSON)
"""
from __future__ import annotations

import argparse
import fnmatch
import hashlib
import importlib.util
import json
import math
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

CONFIG = REPO / "design" / "art" / "harmony" / "config.json"
MATERIALS = REPO / "design" / "art" / "materials.json"
HARMONY_DIR = REPO / "design" / "art" / "harmony"
# One small JSON per asset (assets/<id>.json) plus reference.json (the reference statistics and
# the config hash, which change only with the config), so parallel art PRs never touch one file.
MANIFEST = HARMONY_DIR / "assets"
REFERENCE = HARMONY_DIR / "reference.json"
PREBLUR = REPO / "design" / "prototypes" / "interactions" / "tools" / "preblur.py"

METRICS = ("L_p2", "L_p98", "C_p95", "tint_a", "tint_b", "edge", "detail")
# How far outside its range a material may sit before it counts as an outlier (and is pulled back).
MATERIAL_TOLERANCE = {"hue": 2.0, "chroma": 4.0}


# ---------------------------------------------------------------------------
# Sources and config
# ---------------------------------------------------------------------------

def load_config(path: Path = CONFIG, materials: Path = MATERIALS) -> dict:
    """The harmony config with the material library's detectable materials under "materials"
    (so the manifest's config hash covers the library too)."""
    with open(path) as f:
        cfg = json.load(f)
    if materials.exists():
        lib = json.loads(materials.read_text())
        cfg["materials"] = {
            name: {**{k: v for k, v in m["detect"].items() if not k.startswith("$")}, "range": {"hue": m["hue"], "chroma": m["chroma"]}}
            for name, m in lib["materials"].items() if m.get("detect")
        }
    return cfg


def _outside(value: float, lo: float, hi: float, circular: bool = False) -> float:
    """How far `value` sits outside [lo, hi] (signed: negative below), 0 inside."""
    if circular:
        mid = (lo + hi) / 2
        value = mid + ((value - mid + 180) % 360 - 180)
    return value - lo if value < lo else value - hi if value > hi else 0.0


def world_sources(cfg: dict | None = None) -> dict[str, dict]:
    """Every master the app ships, from preblur's APP_SOURCES: name -> {path, ppu, shipped, kind}."""
    kinds = (cfg or {}).get("kinds", {})
    spec = importlib.util.spec_from_file_location("pofu_preblur", PREBLUR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    out = {}
    for name, s in mod.APP_SOURCES.items():
        if s.get("harmony") is False:
            continue
        path = REPO / s["src"]
        if "ppu" in s:
            ppu = float(s["ppu"])
        else:
            with Image.open(path) as im:
                ppu = im.width / float(s["units"])
        out[name] = {"path": path, "ppu": ppu, "shipped": True, "kind": kinds.get(name, "station" if "ppu" in s else "world")}
    return out


ART = REPO / "design" / "art"


def _master_image(folder: Path) -> Path | None:
    """A master folder's image: the lock-light bake, else the master itself (png or webp)."""
    for candidate in (f"{folder.name}--lock-light.png", f"{folder.name}.png", f"{folder.name}.webp"):
        if (folder / candidate).exists():
            return folder / candidate
    return None


def catalog_sources(cfg: dict, shipped: dict[str, dict]) -> dict[str, dict]:
    """Every generated master in design/art (masters/ and stations/) that the app does not ship
    yet: measured and scored so a new batch is checked before it is integrated."""
    shipped_dirs = {src["path"].parent for src in shipped.values()}
    out = {}
    for group in ("stations", "masters"):
        for folder in sorted((ART / group).iterdir()):
            if not folder.is_dir() or folder in shipped_dirs:
                continue
            image = _master_image(folder)
            if image is None:
                continue
            kind = "station" if group == "stations" else "world"
            meta = folder / "meta.json"
            if meta.exists():
                kind = json.loads(meta.read_text()).get("asset", kind + "__").split("__")[0] or kind
            if folder.name.startswith("pofu-"):
                kind = "char"
            ppu = cfg.get("ppu", {}).get(folder.name) or cfg["ppu_by_kind"].get(kind, cfg["ppu_by_kind"]["world"])
            out[folder.name] = {"path": image, "ppu": float(ppu), "shipped": False, "kind": kind}
    return out


def chain_of(name: str, cfg: dict) -> tuple[str, int] | None:
    """(chain, level) for a station level such as tea-stall-3, else None."""
    spec = cfg.get("chains")
    if not spec:
        return None
    m = re.match(spec["pattern"], name)
    return (m.group("chain"), int(m.group("level"))) if m else None


CHAIN_REPLACES = ("L_p2", "L_p98", "C_p95")


def is_guarded(name: str, cfg: dict) -> bool:
    return any(fnmatch.fnmatch(name, pattern) for pattern in cfg["guard"]["assets"])


def sha(path: Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()[:16]


def config_sha(cfg: dict) -> str:
    return hashlib.sha256(json.dumps(cfg, sort_keys=True).encode()).hexdigest()[:16]


# ---------------------------------------------------------------------------
# Measuring
# ---------------------------------------------------------------------------

def _region_weight(shape: tuple[int, int], box: list[float], feather: float = 0.02) -> np.ndarray:
    """A soft rectangle over the canvas: 1 inside `box` (fractions x0, y0, x1, y1), feathered."""
    h, w = shape
    feather = max(feather, 1e-6)
    y = (np.arange(h) + 0.5) / h
    x = (np.arange(w) + 0.5) / w

    def ramp(v, lo, hi):
        a = np.clip((v - (lo - feather)) / (2 * feather), 0, 1)
        b = np.clip(((hi + feather) - v) / (2 * feather), 0, 1)
        return np.minimum(a, b)

    return ramp(y, box[1], box[3])[:, None] * ramp(x, box[0], box[2])[None, :]


def material_weight(lab: np.ndarray, mat: dict, region: np.ndarray | None) -> np.ndarray:
    """How much each pixel belongs to a material: hue band x chroma floor x region."""
    L, C, H = sl.lch(lab)
    w = sl.hue_weight(H, mat["hue"], mat["width"]) * np.clip((C - mat["min_chroma"]) / 6 + 0.5, 0, 1)
    if region is not None:
        w = w * region
    return w


def _circular_mean(H: np.ndarray, w: np.ndarray) -> float:
    r = np.radians(H)
    return float(math.degrees(math.atan2((np.sin(r) * w).sum(), (np.cos(r) * w).sum())) % 360)


def measure(rgba: np.ndarray, ppu: float, display_ppu: float = 4.0, materials: dict | None = None) -> dict:
    """The harmony metrics of one image (float RGBA, 0..1), `ppu` pixels per world unit."""
    alpha = rgba[..., 3]
    solid = alpha > 0.5
    if not solid.any():
        raise ValueError("no opaque pixels")
    lab_all = sl.srgb_to_lab(np.clip(rgba[..., :3], 0, 1))
    lab = lab_all[solid]
    L, C, _ = sl.lch(lab)
    out = {
        "L_mean": float(L.mean()),
        "L_p2": float(np.percentile(L, 2)),
        "L_p98": float(np.percentile(L, 98)),
        "C_mean": float(C.mean()),
        "C_p50": float(np.percentile(C, 50)),
        "C_p95": float(np.percentile(C, 95)),
        "warmth_b": float(lab[:, 2].mean()),
    }
    neutral = (C < 14) & (L > 55)
    if neutral.sum() >= max(200, 0.01 * len(L)):
        out["tint_a"] = float(lab[neutral, 1].mean())
        out["tint_b"] = float(lab[neutral, 2].mean())
    # Edge softness: pixels on the alpha ramp per pixel of silhouette, in world units.
    ramp = ((alpha > 0.04) & (alpha < 0.96)).sum()
    inner = solid[1:-1, 1:-1]
    rim = inner & ~(solid[:-2, 1:-1] & solid[2:, 1:-1] & solid[1:-1, :-2] & solid[1:-1, 2:])
    out["edge"] = float(ramp / max(int(rim.sum()), 1) / ppu)
    # Detail at display size.
    ys, xs = np.nonzero(alpha > 0.03)
    crop = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    im = Image.fromarray(np.uint8(np.clip(crop * 255 + 0.5, 0, 255)), "RGBA")
    s = display_ppu / ppu
    im = im.resize((max(3, round(im.width * s)), max(3, round(im.height * s))), Image.Resampling.LANCZOS)
    g = np.asarray(im.convert("L"), dtype=np.float64) / 255
    am = np.asarray(im)[..., 3] > 240
    lap = np.abs(4 * g[1:-1, 1:-1] - g[:-2, 1:-1] - g[2:, 1:-1] - g[1:-1, :-2] - g[1:-1, 2:])
    m = am[1:-1, 1:-1]
    out["detail"] = float(lap[m].mean() * 100) if m.any() else 0.0
    mats = {}
    for name, mat in (materials or {}).items():
        region = mat.get("_region")
        w = material_weight(lab_all, mat, region) * solid
        if w.sum() < 300:
            continue
        _, Cm, Hm = sl.lch(lab_all)
        mats[name] = {
            "hue": _circular_mean(Hm, w),
            "chroma": float((Cm * w).sum() / w.sum()),
            "pixels": int(w.sum()),
        }
    if mats:
        out["materials"] = mats
    return {k: (round(v, 3) if isinstance(v, float) else v) for k, v in out.items()}


def materials_for(name: str, cfg: dict, shape: tuple[int, int]) -> dict:
    """The config's materials that apply to asset `name`, with their region weights."""
    out = {}
    for mname, mat in cfg.get("materials", {}).items():
        if mname.startswith("$"):
            continue
        regions = mat.get("regions")
        if regions is not None and name not in regions:
            continue
        m = dict(mat)
        m["_region"] = _region_weight(shape, regions[name]) if regions else None
        out[mname] = m
    return out


def reference_group(kind: str, cfg: dict) -> str:
    """Which reference an asset kind is matched against: characters against Pofu, everything
    else against the approved island."""
    return kind if kind in cfg["reference"] else "world"


def reference_stats(stats: dict[str, dict], cfg: dict) -> dict[str, dict]:
    refs = {}
    for group, names in cfg["reference"].items():
        if group.startswith("$"):
            continue
        ref = {}
        for metric in METRICS:
            values = [stats[n][metric] for n in names if metric in stats.get(n, {})]
            if values:
                ref[metric] = round(float(np.mean(values)), 3)
        refs[group] = ref
    return refs


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------

def deviations(stats: dict, ref: dict, cfg: dict, kind: str = "world", chain: dict | None = None) -> dict[str, float]:
    """Each metric's distance from the reference in tolerances (signed). A chain level is matched
    on value and chroma to its chain's L1 (`chain`) instead of the world reference."""
    out = {}
    for metric, spec in cfg["metrics"].items():
        if chain is not None and metric in CHAIN_REPLACES:
            continue
        if metric in stats and metric in ref:
            out[metric] = (stats[metric] - ref[metric]) / spec["tolerance"]
    if chain is not None:
        for metric, spec in cfg["chains"]["metrics"].items():
            if metric in stats and metric in chain:
                out[f"chain_{metric}"] = (stats[metric] - chain[metric]) / spec["tolerance"]
    for mname, m in stats.get("materials", {}).items():
        rng = cfg["materials"][mname]["range"]
        out[f"{mname}_hue"] = _outside(m["hue"], *rng["hue"], circular=True) / MATERIAL_TOLERANCE["hue"]
        out[f"{mname}_chroma"] = _outside(m["chroma"], *rng["chroma"]) / MATERIAL_TOLERANCE["chroma"]
    return out


def score(stats: dict, ref: dict, cfg: dict, kind: str = "world", chain: dict | None = None) -> float:
    """100 when every metric matches; a metric one tolerance away counts 75, two 31, three 7."""
    devs = deviations(stats, ref, cfg, kind, chain)
    if not devs:
        return 100.0
    total = weight = 0.0
    for metric, d in devs.items():
        w = cfg["metrics"].get(metric, {}).get("weight", 1.0)
        total += w * math.exp(-0.2877 * d * d)
        weight += w
    return round(100 * total / weight, 1)


def outliers(stats: dict, ref: dict, cfg: dict, kind: str = "world", chain: dict | None = None) -> list[str]:
    return sorted(m for m, d in deviations(stats, ref, cfg, kind, chain).items() if abs(d) > 1)


# ---------------------------------------------------------------------------
# Correcting
# ---------------------------------------------------------------------------

IDENTITY = {"black": 0.0, "white": 0.0, "chroma": 1.0, "ceiling": 0.0, "tint_a": 0.0, "tint_b": 0.0, "materials": {}}


def is_identity(corr: dict) -> bool:
    return corr == IDENTITY or (
        corr["black"] == 0 and corr["white"] == 0 and corr["chroma"] == 1
        and corr["tint_a"] == 0 and corr["tint_b"] == 0 and not corr["materials"]
    )


def plan(stats: dict, ref: dict, cfg: dict, guarded: bool, kind: str = "world", chain: dict | None = None) -> dict:
    """The correction that brings `stats` within tolerance of `ref`, as far as colour can."""
    corr = json.loads(json.dumps(IDENTITY))
    if guarded:
        return corr
    c = cfg["correction"]
    k = c["strength"]
    tol = {m: s["tolerance"] for m, s in cfg["metrics"].items()}

    allowed = cfg.get("correct_by_kind", {}).get(kind)

    def needed(metric):
        if allowed is not None and metric not in allowed:
            return False
        return metric in stats and metric in ref and abs(stats[metric] - ref[metric]) > tol[metric]

    if chain is not None:
        # A chain level: value and chroma back to its L1.
        ctol = {m: s["tolerance"] for m, s in cfg["chains"]["metrics"].items()}
        if abs(stats["L_p2"] - chain["L_p2"]) > ctol["L_p2"]:
            corr["black"] = round(float(np.clip((chain["L_p2"] - stats["L_p2"]) * k, -c["max_black_shift"], c["max_black_shift"])), 2)
        if abs(stats["L_p98"] - chain["L_p98"]) > ctol["L_p98"]:
            corr["white"] = round(float(np.clip((chain["L_p98"] - stats["L_p98"]) * k, -c["max_white_shift"], c["max_white_shift"])), 2)
        if abs(stats["C_p50"] - chain["C_p50"]) > ctol["C_p50"]:
            lo, hi = cfg["chains"]["chroma_scale"]
            corr["chroma"] = round(float(np.clip(1 + (chain["C_p50"] / max(stats["C_p50"], 1e-3) - 1) * k, lo, hi)), 3)
            # A uniform scale would push the parts that kept their colour (a
            # tiled roof) past the L1's most colourful; a soft ceiling there.
            corr["ceiling"] = round(float(chain["C_p95"]), 1)
    if chain is None and needed("L_p2"):
        corr["black"] = round(float(np.clip((ref["L_p2"] - stats["L_p2"]) * k, -c["max_black_shift"], c["max_black_shift"])), 2)
    if chain is None and needed("L_p98"):
        corr["white"] = round(float(np.clip((ref["L_p98"] - stats["L_p98"]) * k, -c["max_white_shift"], c["max_white_shift"])), 2)
    if chain is None and needed("C_p95"):
        lo, hi = c["chroma_scale"]
        corr["chroma"] = round(float(np.clip(1 + (ref["C_p95"] / max(stats["C_p95"], 1e-3) - 1) * k, lo, hi)), 3)
    for axis in ("a", "b"):
        if needed(f"tint_{axis}"):
            shift = (ref[f"tint_{axis}"] - stats[f"tint_{axis}"]) * k
            corr[f"tint_{axis}"] = round(float(np.clip(shift, -c["max_tint_shift"], c["max_tint_shift"])), 2)
    for mname, m in stats.get("materials", {}).items():
        # Only a drift out of the material's own range is pulled back, to the range's nearest edge.
        rng = cfg["materials"][mname]["range"]
        dh = -_outside(m["hue"], *rng["hue"], circular=True)
        oc = _outside(m["chroma"], *rng["chroma"])
        if abs(dh) > MATERIAL_TOLERANCE["hue"] or abs(oc) > MATERIAL_TOLERANCE["chroma"]:
            dc = (m["chroma"] - oc) / max(m["chroma"], 1e-3)
            corr["materials"][mname] = {
                "hue_shift": round(float(np.clip(dh * k, -15, 15)), 2),
                "chroma_scale": round(float(np.clip(1 + (dc - 1) * k, 0.8, 1.3)), 3),
            }
    return corr


def apply(rgba: np.ndarray, corr: dict, src: dict | None = None, materials: dict | None = None) -> np.ndarray:
    """`rgba` (float, 0..1, straight alpha) with `corr` applied; alpha is untouched.

    `src` holds the asset's own black and white point (L_p2, L_p98), which the levels remap moves.
    """
    if is_identity(corr):
        return rgba.copy()
    lab = sl.srgb_to_lab(np.clip(rgba[..., :3], 0, 1))
    L, C, H = sl.lch(lab)
    if (corr["black"] or corr["white"]) and src:
        lo, hi = src["L_p2"], src["L_p98"]
        lo2, hi2 = lo + corr["black"], hi + corr["white"]
        L = lo2 + (L - lo) * (hi2 - lo2) / max(hi - lo, 1e-3)
        # Keep the ends inside the gamut smoothly: never past paper white or ink.
        L = np.clip(L, 0, 100)
    if corr["chroma"] != 1:
        C = C * corr["chroma"]
        if corr.get("ceiling"):
            C = sl.soft_ceiling(C, corr["ceiling"], corr["ceiling"] + 10)
    for mname, m in corr["materials"].items():
        w = material_weight(lab, materials[mname], materials[mname].get("_region"))
        H = (H + m["hue_shift"] * w) % 360
        C = C * (1 + (m["chroma_scale"] - 1) * w)
    out = sl.from_lch(L, C, H)
    if corr["tint_a"] or corr["tint_b"]:
        # White balance moves the light, so the neutrals move most and strong colours least.
        w = np.clip(1 - C / 40, 0.25, 1)
        out[..., 1] += corr["tint_a"] * w
        out[..., 2] += corr["tint_b"] * w
    rgb = sl.lab_to_srgb(out)
    return np.concatenate([np.clip(rgb, 0, 1), rgba[..., 3:4]], axis=-1)


def load_rgba(path: Path) -> np.ndarray:
    with Image.open(path) as im:
        return np.asarray(im.convert("RGBA"), dtype=np.float64) / 255.0


def correct_image(name: str, img: Image.Image, manifest: dict | None = None, cfg: dict | None = None) -> Image.Image:
    """`img` (the master as loaded by preblur) with the manifest's correction for `name` baked in."""
    manifest = manifest if manifest is not None else load_manifest()
    entry = manifest["assets"].get(name)
    if not entry or is_identity(entry["correction"]):
        return img
    cfg = cfg or load_config()
    rgba = np.asarray(img.convert("RGBA"), dtype=np.float64) / 255.0
    mats = materials_for(name, cfg, rgba.shape[:2])
    out = apply(rgba, entry["correction"], entry["before"], mats)
    return Image.fromarray(np.uint8(np.clip(out * 255 + 0.5, 0, 255)), "RGBA")


# ---------------------------------------------------------------------------
# The manifest
# ---------------------------------------------------------------------------

def build(cfg: dict | None = None) -> tuple[dict, dict]:
    """Measures every source; returns (manifest, images) where images holds before/after arrays."""
    cfg = cfg or load_config()
    sources = world_sources(cfg)
    sources.update(catalog_sources(cfg, sources))
    before, images, mats = {}, {}, {}
    for name, src in sources.items():
        rgba = load_rgba(src["path"])
        mats[name] = materials_for(name, cfg, rgba.shape[:2])
        before[name] = measure(rgba, src["ppu"], cfg["display_ppu"], mats[name])
        images[name] = {"before": rgba}
    refs = reference_stats(before, cfg)
    reference_names = {n for g, names in cfg["reference"].items() if not g.startswith("$") for n in names}
    assets = {}

    def chain_ref(name):
        """The chain's L1 as corrected, for a level above 1."""
        cl = chain_of(name, cfg)
        if cl is None or cl[1] <= 1:
            return None
        first = f"{cl[0]}-1"
        return assets[first]["after"] if first in assets else None

    order = sorted(sources, key=lambda n: (chain_of(n, cfg) or ("", 0))[1])
    for name in order:
        src = sources[name]
        guarded = is_guarded(name, cfg)
        kind = src["kind"]
        ref = refs[reference_group(kind, cfg)]
        chain = chain_ref(name)
        corr = plan(before[name], ref, cfg, guarded, kind, chain)
        after_img = apply(images[name]["before"], corr, before[name], mats[name])
        images[name]["after"] = after_img
        after = before[name] if is_identity(corr) else measure(after_img, src["ppu"], cfg["display_ppu"], mats[name])
        assets[name] = {
            "source": str(src["path"].relative_to(REPO)),
            "source_sha": sha(src["path"]),
            "ppu": round(src["ppu"], 4),
            "shipped": src["shipped"],
            "kind": src["kind"],
            "guarded": guarded,
            "reference": name in reference_names,
            "matched_to": reference_group(kind, cfg),
            "chain": {k: chain[k] for k in cfg["chains"]["metrics"]} if chain else None,
            "before": before[name],
            "score_before": score(before[name], ref, cfg, kind, chain),
            "outliers_before": outliers(before[name], ref, cfg, kind, chain),
            "correction": corr,
            "after": after,
            "score_after": score(after, ref, cfg, kind, chain),
            "outliers_after": outliers(after, ref, cfg, kind, chain),
        }
    assets = {name: assets[name] for name in sources}
    manifest = {
        "$note": "Generated by tools/assets/harmony.py measure. Do not edit; change design/art/harmony/config.json and re-run. Per-asset entries live in design/art/harmony/assets/. preblur.py app bakes each correction into the app's sprites.",
        "version": 1,
        "config_sha": config_sha(cfg),
        "reference": refs,
        "assets": assets,
    }
    return manifest, images


def load_manifest() -> dict:
    """The manifest as one dict, assembled from reference.json and assets/*.json."""
    manifest = json.loads(REFERENCE.read_text())
    manifest["assets"] = {f.stem: json.loads(f.read_text()) for f in sorted(MANIFEST.glob("*.json"))}
    return manifest


def write_manifest(manifest: dict) -> None:
    """Writes reference.json and one file per asset; removes files of assets that are gone."""
    MANIFEST.mkdir(parents=True, exist_ok=True)
    head = {k: v for k, v in manifest.items() if k != "assets"}
    REFERENCE.write_text(json.dumps(head, indent=1, sort_keys=True) + "\n")
    for name, entry in manifest["assets"].items():
        (MANIFEST / f"{name}.json").write_text(json.dumps(entry, indent=1, sort_keys=True) + "\n")
    for f in MANIFEST.glob("*.json"):
        if f.stem not in manifest["assets"]:
            f.unlink()


def stale(manifest: dict, fresh: dict) -> list[str]:
    """What differs between a committed manifest and a fresh one."""
    problems = []
    if manifest.get("config_sha") != fresh["config_sha"]:
        problems.append("config changed since the manifest was written")
    for name, entry in fresh["assets"].items():
        old = manifest.get("assets", {}).get(name)
        if old is None:
            problems.append(f"{name}: not in the manifest")
        elif old["source_sha"] != entry["source_sha"]:
            problems.append(f"{name}: the master changed")
        elif old["correction"] != entry["correction"]:
            problems.append(f"{name}: the correction changed")
    for name in manifest.get("assets", {}):
        if name not in fresh["assets"]:
            problems.append(f"{name}: no longer a source")
    return problems


def table(manifest: dict) -> str:
    lines = [f"reference ({group}): " + "  ".join(f"{k} {v:.1f}" for k, v in ref.items())
             for group, ref in manifest["reference"].items()] + [""]
    lines.append(f"{'asset':34s} {'score':>11s}  outliers before -> after; correction")
    for name, e in sorted(manifest["assets"].items(), key=lambda kv: kv[1]["score_before"]):
        corr = e["correction"]
        parts = []
        if corr["black"]:
            parts.append(f"black {corr['black']:+.1f}")
        if corr["white"]:
            parts.append(f"white {corr['white']:+.1f}")
        if corr["chroma"] != 1:
            parts.append(f"chroma x{corr['chroma']:.2f}")
        if corr["tint_a"] or corr["tint_b"]:
            parts.append(f"tint a {corr['tint_a']:+.1f} b {corr['tint_b']:+.1f}")
        for m, c in corr["materials"].items():
            parts.append(f"{m} hue {c['hue_shift']:+.1f} chroma x{c['chroma_scale']:.2f}")
        tag = " (guarded)" if e["guarded"] else " (reference)" if e["reference"] else "" if e["shipped"] else " (not in app)"
        lines.append(
            f"{name + tag:34s} {e['score_before']:5.1f}->{e['score_after']:5.1f}  "
            f"{','.join(e['outliers_before']) or '-'} -> {','.join(e['outliers_after']) or '-'}; {', '.join(parts) or 'none'}"
        )
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# The contact sheet
# ---------------------------------------------------------------------------

def _font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow < 10.1
        return ImageFont.load_default()


def _tile(rgba: np.ndarray, h: int, bg=(176, 196, 214)) -> Image.Image:
    im = Image.fromarray(np.uint8(np.clip(rgba * 255 + 0.5, 0, 255)), "RGBA")
    box = im.getchannel("A").getbbox() or (0, 0, im.width, im.height)
    im = im.crop(box)
    s = h / im.height
    if im.width * s > 1.6 * h:
        s = 1.6 * h / im.width
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.Resampling.LANCZOS)
    out = Image.new("RGBA", (round(1.6 * h), h), bg + (255,))
    out.alpha_composite(im, ((out.width - im.width) // 2, (out.height - im.height) // 2))
    return out.convert("RGB")


def sheet(manifest: dict, images: dict, cfg: dict, path: Path, zooms: dict | None = None) -> None:
    """One row per asset, worst first: before, after, and the numbers against the reference."""
    th = 200
    tw = round(1.6 * th)
    pad = 18
    text_w = 620
    # What the app ships first, then the rest of the catalog; worst first within each.
    names = sorted(manifest["assets"], key=lambda n: (not manifest["assets"][n]["shipped"], manifest["assets"][n]["score_before"]))
    zooms = zooms or {}
    rows = len(names) + len(zooms)
    W = pad + 2 * (tw + pad) + text_w
    H = 70 + rows * (th + pad) + pad
    sheet_img = Image.new("RGB", (W, H), (246, 244, 240))
    d = ImageDraw.Draw(sheet_img)
    big, small, mono = _font(26), _font(17), _font(16)
    d.text((pad, 14), "Asset harmony: before | after (corrections baked by preblur.py app)", fill=(30, 30, 30), font=big)
    d.text((pad, 46), "   ".join(f"{group} ({', '.join(cfg['reference'][group])}): " + " ".join(f"{k} {v:.1f}" for k, v in ref.items())
                                for group, ref in manifest["reference"].items()), fill=(80, 80, 80), font=small)
    y = 70

    def numbers(x, y, e):
        d.text((x, y), f"{e['name']}", fill=(20, 20, 20), font=big)
        tag = "guarded" if e["guarded"] else "reference" if e["reference"] else "in the app" if e["shipped"] else "not in the app yet"
        d.text((x, y + 30), f"score {e['score_before']:.0f} -> {e['score_after']:.0f}  {tag}", fill=(60, 60, 60), font=small)
        ly = y + 56
        ref = manifest["reference"][e["matched_to"]]
        devs_b = deviations(e["before"], ref, cfg, e["kind"], e.get("chain"))
        devs_a = deviations(e["after"], ref, cfg, e["kind"], e.get("chain"))
        for metric in list(cfg["metrics"]) + [k for k in devs_b if k not in cfg["metrics"]]:
            if metric not in devs_b:
                continue
            vb = e["before"].get(metric.removeprefix("chain_"))
            va = e["after"].get(metric.removeprefix("chain_"))
            if vb is None:
                mname, part = metric.rsplit("_", 1)
                vb = e["before"]["materials"][mname][part]
                va = e["after"].get("materials", {}).get(mname, {}).get(part, vb)
            colour = (190, 40, 30) if abs(devs_a[metric]) > 1 else (40, 120, 60) if abs(devs_b[metric]) > 1 else (90, 90, 90)
            d.text((x, ly), f"{metric:14s} {vb:7.2f} -> {va:7.2f}  ({devs_b[metric]:+.1f} -> {devs_a[metric]:+.1f} tol)", fill=colour, font=mono)
            ly += 17

    for name in names:
        e = dict(manifest["assets"][name], name=name)
        sheet_img.paste(_tile(images[name]["before"], th), (pad, y))
        sheet_img.paste(_tile(images[name]["after"], th), (pad + tw + pad, y))
        numbers(pad + 2 * (tw + pad), y, e)
        y += th + pad
    for label, (name, box) in zooms.items():
        b, a = images[name]["before"], images[name]["after"]
        h, w = b.shape[:2]
        x0, y0, x1, y1 = int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)
        sheet_img.paste(_tile(b[y0:y1, x0:x1], th, bg=(250, 238, 222)), (pad, y))
        sheet_img.paste(_tile(a[y0:y1, x0:x1], th, bg=(250, 238, 222)), (pad + tw + pad, y))
        d.text((pad + 2 * (tw + pad), y), label, fill=(20, 20, 20), font=big)
        mats = manifest["assets"][name]
        for i, (m, v) in enumerate(mats["before"].get("materials", {}).items()):
            va = mats["after"].get("materials", {}).get(m, v)
            rng = cfg["materials"][m]["range"]
            d.text((pad + 2 * (tw + pad), y + 34 + 20 * i),
                   f"{m}: hue {v['hue']:.1f} -> {va['hue']:.1f} (range {rng['hue'][0]:.0f}-{rng['hue'][1]:.0f}), "
                   f"chroma {v['chroma']:.1f} -> {va['chroma']:.1f} (range {rng['chroma'][0]:.0f}-{rng['chroma'][1]:.0f})",
                   fill=(60, 60, 60), font=small)
        y += th + pad
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix.lower() in (".jpg", ".jpeg"):
        sheet_img.save(path, "JPEG", quality=88, optimize=True)
    else:
        sheet_img.save(path, optimize=True)


def material_zooms(cfg: dict) -> dict:
    """A before/after zoom for every material region (the çaydanlık)."""
    out = {}
    for mname, mat in cfg.get("materials", {}).items():
        if mname.startswith("$"):
            continue
        for name, box in (mat.get("regions") or {}).items():
            out[f"{name}: {mname}"] = (name, box)
    return out


# ---------------------------------------------------------------------------
# Scoring one image (imagegen QA)
# ---------------------------------------------------------------------------

def score_image(rgba: np.ndarray, ppu: float, cfg: dict | None = None, manifest: dict | None = None,
                kind: str = "world") -> dict:
    """A new take's stats, outliers and score against the committed reference."""
    cfg = cfg or load_config()
    if manifest is None:
        manifest = load_manifest() if MANIFEST.is_dir() else None
    if manifest is None:
        raise FileNotFoundError("no harmony manifest; run harmony.py measure")
    ref = manifest["reference"][reference_group(kind, cfg)]
    stats = measure(rgba, ppu, cfg["display_ppu"])
    return {"stats": stats, "score": score(stats, ref, cfg, kind), "outliers": outliers(stats, ref, cfg, kind)}


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("measure", help="measure every master and write the manifest")
    m.add_argument("--sheet", type=Path, help="also draw the contact sheet here (.png or .jpg)")
    m.add_argument("--dry-run", action="store_true", help="print, do not write the manifest")
    c = sub.add_parser("check", help="fail when the committed manifest is stale")
    c.add_argument("--sheet", type=Path)
    s = sub.add_parser("score", help="one image against the reference (JSON)")
    s.add_argument("image", type=Path)
    s.add_argument("--ppu", type=float, required=True, help="pixels per world unit")
    s.add_argument("--kind", default="world", help="station, prop, world or char")
    args = ap.parse_args(argv)

    cfg = load_config()
    if args.cmd == "score":
        print(json.dumps(score_image(load_rgba(args.image), args.ppu, cfg, kind=args.kind), indent=1))
        return 0
    manifest, images = build(cfg)
    print(table(manifest))
    if args.sheet:
        sheet(manifest, images, cfg, args.sheet, material_zooms(cfg))
        print(f"\ncontact sheet: {args.sheet}")
    if args.cmd == "measure":
        if not args.dry_run:
            write_manifest(manifest)
            print(f"wrote {MANIFEST.relative_to(REPO)}/ ({len(manifest['assets'])} files) and {REFERENCE.relative_to(REPO)}")
        return 0
    committed = load_manifest() if MANIFEST.is_dir() else {}
    problems = stale(committed, manifest)
    for p in problems:
        print(f"STALE: {p}", file=sys.stderr)
    if problems:
        print("Run: python3 -I tools/assets/harmony.py measure, then preblur.py app.", file=sys.stderr)
        return 1
    print("\nharmony manifest is current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
