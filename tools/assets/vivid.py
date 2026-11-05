#!/usr/bin/env python3
"""World sprite vividness: measure it, and regrade the props that came out pale.

    python3 -I tools/assets/vivid.py measure [--json OUT.json]
    python3 -I tools/assets/vivid.py regrade IN.png OUT.png --kind plant

The painted masters of stations, props and home objects are pastel (look round 5: "objects still
look pale, their own colours washed out"). `regrade_image` is the deterministic fix, applied at the
source of the app images (preblur.py for the world catalog, integrate.py for the home objects), so
every blur variant and band inherits it. It never touches characters, the island plate, the sky,
glow overlays or UI chrome (`never` and the name globs in vivid.json).

The grade, in CIELAB on opaque pixels only: vibrance (boost low chroma more than high, near
neutrals left alone), a local-contrast lift on L (detail against a blurred copy, alpha-aware, so
edges get no halo), and a slight warm shift. Strengths come from vivid.json per kind. The hard
limits hold by bisection (a chroma limiter that compresses what is above the cap, the strengths
scaled down together if the value floor needs it), so the output is a function of the input and the config alone.
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

CONFIG = HERE / "vivid.json"
CATALOG = REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
PAINT = REPO / "Packages/PofuKit/Sources/PofuDesignSystem/Resources"
POFU = REPO / "Packages/PofuKit/Sources/PofuCompanion/Resources/pofu-hamster.png"
OPAQUE = 0.98
MARGIN = 0.4  # under the cap: absorbs the 8-bit rounding and gamut clipping of the saved PNG


def load_config(path: Path = CONFIG) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _match(name: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(name, p) for p in patterns)


def kind_of(name: str, target: str = "world", cfg: dict | None = None) -> str | None:
    """The kind of a world sprite or home object ('plant', 'prop', 'station', 'home'), or None when
    it is never regraded (characters, plates, sky, glow overlays, UI chrome)."""
    cfg = cfg or load_config()
    if target == "world" and _match(name, cfg["never"]):
        return None
    for kind, patterns in cfg.get(target, {}).items():
        if _match(name, patterns):
            return kind
    return None


# ---------------------------------------------------------------------------
# Measurement
# ---------------------------------------------------------------------------

def _blur_alpha(values: np.ndarray, alpha: np.ndarray, sigma: float) -> np.ndarray:
    """Gaussian blur of `values` over the opaque area only (normalised by the blurred alpha)."""
    num = sl.gaussian_blur(values * alpha, sigma)
    den = sl.gaussian_blur(alpha, sigma)
    return num / np.maximum(den, 1e-4)


def _lch(rgba: np.ndarray):
    return sl.lch(sl.srgb_to_lab(np.clip(rgba[..., :3], 0, 1)))


def measure(rgba: np.ndarray) -> dict:
    """Chroma (mean, p95), L (mean, p5) and local contrast (std of L minus its 9 px blur) on opaque pixels."""
    solid = rgba[..., 3] >= OPAQUE
    L, C, _ = _lch(rgba)
    detail = (L - _blur_alpha(L, solid.astype(np.float64), 9 / 2.0))[solid]
    return {
        "px": int(solid.sum()),
        "chroma_mean": float(C[solid].mean()),
        "chroma_p95": float(np.percentile(C[solid], 95)),
        "L_mean": float(L[solid].mean()),
        "L_p5": float(np.percentile(L[solid], 5)),
        "contrast": float(detail.std()),
    }


def pooled(paths: list[Path]) -> dict:
    """One measurement over several images (the plate's bands)."""
    parts = [sl.load_rgba(p) for p in paths]
    ms = [measure(r) for r in parts]
    C = np.concatenate([_lch(r)[1][r[..., 3] >= OPAQUE] for r in parts])
    L = np.concatenate([_lch(r)[0][r[..., 3] >= OPAQUE] for r in parts])
    w = [m["px"] for m in ms]
    return {"px": int(sum(w)), "chroma_mean": float(C.mean()), "chroma_p95": float(np.percentile(C, 95)),
            "L_mean": float(L.mean()), "L_p5": float(np.percentile(L, 5)),
            "contrast": float(np.average([m["contrast"] for m in ms], weights=w))}


# ---------------------------------------------------------------------------
# Regrade
# ---------------------------------------------------------------------------

def _smooth(x: np.ndarray, lo: float, hi: float) -> np.ndarray:
    t = np.clip((x - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def _grade(rgb: np.ndarray, alpha: np.ndarray, p: dict, cfg: dict, t: float, f: float = 1.0) -> np.ndarray:
    lab = sl.srgb_to_lab(np.clip(rgb, 0, 1))
    L, C, H = sl.lch(lab)
    neutral = _smooth(C, *cfg["neutral"])
    # Vibrance: a flat-coloured pixel gains `vibrance`, fading to nothing at chroma_ref.
    C2 = C * (1.0 + t * p["vibrance"] * neutral * np.clip(1.0 - C / cfg["chroma_ref"], 0.0, 1.0))
    # Local contrast on L, alpha-aware, bounded.
    lo, hi = cfg["blur_sigma_px"]
    sigma = float(np.clip(cfg["blur_sigma_frac"] * max(L.shape), lo, hi))
    detail = L - _blur_alpha(L, (alpha >= OPAQUE).astype(np.float64), sigma)
    lim = t * p["contrast_limit"]
    L2 = np.clip(L + np.clip(t * p["contrast"] * detail, -lim, lim) - t * p["depth"] * _smooth(L, 45.0, 85.0), 0, 100)
    out = sl.from_lch(L2, C2, H)
    out[..., 1] += t * p["warm_a"] * neutral
    out[..., 2] += t * p["warm_b"] * neutral
    # Limiter: chroma above the cap keeps only the share `f` of its excess (f = 1 leaves it alone).
    cap = cfg["chroma_p95_cap"] - MARGIN
    C3 = np.hypot(out[..., 1], out[..., 2])
    k = np.where(C3 > cap, (cap + (C3 - cap) * f) / np.maximum(C3, 1e-6), 1.0)
    out[..., 1] *= k
    out[..., 2] *= k
    return sl.lab_to_srgb(out)


def regrade(rgba: np.ndarray, kind: str, cfg: dict | None = None) -> np.ndarray:
    """RGBA floats 0..1 in, RGBA out. Alpha is kept; the limits are measured on opaque pixels."""
    cfg = cfg or load_config()
    p = cfg["kinds"][kind]
    alpha = rgba[..., 3]
    if not (alpha >= OPAQUE).any():
        return rgba
    floor = min(cfg["value_floor"], measure(rgba)["L_p5"])

    def build(t: float, f: float) -> np.ndarray:
        out = rgba.copy()
        out[..., :3] = _grade(rgba[..., :3], alpha, p, cfg, t, f)
        return out

    def search(ok) -> float:
        """The largest x in 0..1 with ok(x), by bisection (1 when ok(1))."""
        if ok(1.0):
            return 1.0
        lo, hi = 0.0, 1.0
        for _ in range(7):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if ok(mid) else (lo, mid)
        return lo

    # The value floor first (scales the whole grade), then the chroma limiter on the result.
    t = search(lambda x: measure(build(x, 0.0))["L_p5"] >= floor - 1e-6)
    f = search(lambda x: measure(build(t, x))["chroma_p95"] <= cfg["chroma_p95_cap"] - MARGIN / 2)
    return build(t, f)


def regrade_image(name: str, img: Image.Image, target: str = "world", cfg: dict | None = None) -> Image.Image:
    """Image in, image out; unchanged when `name` is never regraded."""
    cfg = cfg or load_config()
    kind = kind_of(name, target, cfg)
    if kind is None:
        return img
    rgba = np.asarray(img.convert("RGBA"), dtype=np.float64) / 255.0
    out = regrade(rgba, kind, cfg)
    return Image.fromarray(np.clip(np.rint(out * 255.0), 0, 255).astype(np.uint8), "RGBA")


# ---------------------------------------------------------------------------
# Catalog report
# ---------------------------------------------------------------------------

def catalog_sprites() -> dict[str, list[Path]]:
    """name -> sharp catalog image(s): no blur variants, alternates or normal maps; the plate's bands pooled."""
    out: dict[str, list[Path]] = {}
    for d in sorted(CATALOG.glob("*.imageset")):
        stem = d.name[: -len(".imageset")]
        if "__" in stem or "--" in stem or stem.startswith("world-island-main"):
            continue
        png = d / f"{stem}.png"
        if png.is_file():
            out[stem] = [png]
    out["world-island-main (4 bands)"] = [CATALOG / f"world-island-main-band{k}.imageset/world-island-main-band{k}.png" for k in range(4)]
    for p in sorted(PAINT.glob("paint-*.png")):
        out[p.stem] = [p]
    out["pofu-hamster"] = [POFU]
    return out


def group_of(stem: str, cfg: dict) -> str:
    if stem.startswith("world-island-main"):
        return "plate"
    name = stem.removeprefix("world-")
    if stem == "pofu-hamster" or _match(name, ["mochi*", "findik*", "simit*"]):
        return "character"
    if stem.startswith("paint-"):
        return kind_of(stem, "ui", cfg) or "chrome"
    if name.startswith("ui-"):
        return "home-static"
    if _match(name, ["cloud-*", "far-isle-*", "isle-*"]):
        return "sky"
    if _match(name, ["harbor-island-*"]):
        return "plate"
    if _match(name, ["*-glow"]):
        return "glow"
    return kind_of(name, "world", cfg) or "other"


def rows() -> list[dict]:
    cfg = load_config()
    out = []
    for stem, paths in catalog_sprites().items():
        m = pooled(paths) if len(paths) > 1 else measure(sl.load_rgba(paths[0]))
        out.append({"name": stem, "group": group_of(stem, cfg), **m})
    return out


def table(data: list[dict], groups: tuple[str, ...]) -> str:
    lines = ["| Sprite | Group | Chroma mean | Chroma p95 | L mean | L p5 | Local contrast |", "|---|---|---|---|---|---|---|"]
    for r in data:
        if r["group"] in groups:
            lines.append(f"| `{r['name']}` | {r['group']} | {r['chroma_mean']:.1f} | {r['chroma_p95']:.1f} | "
                         f"{r['L_mean']:.1f} | {r['L_p5']:.1f} | {r['contrast']:.2f} |")
    return "\n".join(lines)


def group_means(data: list[dict]) -> dict[str, dict]:
    out = {}
    for g in sorted({r["group"] for r in data}):
        rs = [r for r in data if r["group"] == g]
        out[g] = {k: float(np.mean([r[k] for r in rs])) for k in ("chroma_mean", "chroma_p95", "L_mean", "L_p5", "contrast")}
        out[g]["n"] = len(rs)
    return out


def main() -> int:
    cfg = load_config()
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("measure")
    m.add_argument("--json", type=Path, help="write the rows as JSON")
    r = sub.add_parser("regrade")
    r.add_argument("src", type=Path)
    r.add_argument("dst", type=Path)
    r.add_argument("--kind", choices=sorted(cfg["kinds"]), required=True)
    a = ap.parse_args()
    if a.cmd == "regrade":
        sl.save_rgba(regrade(sl.load_rgba(a.src), a.kind, cfg), a.dst)
        return 0
    data = rows()
    if a.json:
        a.json.write_text(json.dumps(data, indent=1), encoding="utf-8")
    print(table(data, tuple(sorted({r["group"] for r in data}))))
    for g, v in group_means(data).items():
        print(g, {k: round(x, 1) for k, x in v.items()})
    return 0


if __name__ == "__main__":
    sys.exit(main())
