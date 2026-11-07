"""The art light standard: prompt block, measurement and target lookup.

Rules live in docs/design/light-standard.md (ADR-0021); numbers in
design/art/light-standard.json (value targets per colour-script cell x
layer, measured from the founder-picked references); key direction, rim, fill, shadow hue and fog are read from
design/art/colour-script.json and never duplicated. Pure functions (no
network), unit-tested on Linux.

A job declares `light: {cell: day|dawn|golden|dusk|night, layer: subject|near|far}`.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import style_lock as sl  # noqa: E402

ART_ROOT = HERE.parents[1] / "design" / "art"
STANDARD_PATH = ART_ROOT / "light-standard.json"
COLOUR_SCRIPT_PATH = ART_ROOT / "colour-script.json"

CELLS = ("day", "dawn", "golden", "dusk", "night")
LAYERS = ("subject", "near", "far")
# Kinds that need no light declaration (they carry no scene light).
EXEMPT_KINDS = ("icon", "ui", "widget", "appicon")
# Kinds that are sprites when transparent: painted under the day cell, relit
# by code. Plates (opaque) and concepts may paint any cell.
SPRITE_KINDS = ("char", "station", "prop", "world", "sheet")
MEASURE_PX = 800
# The subject region of an opaque plate: the lower middle, where the player looks.
PLATE_SUBJECT_BOX = (0.20, 0.30, 0.80, 0.90)  # x0, y0, x1, y1 as fractions


class LightError(ValueError):
    pass


_cache: dict[Path, dict] = {}


def _load(path: Path) -> dict:
    if path not in _cache:
        _cache[path] = json.loads(path.read_text(encoding="utf-8"))
    return _cache[path]


def standard() -> dict:
    return _load(STANDARD_PATH)


def colour_script() -> dict:
    return _load(COLOUR_SCRIPT_PATH)


def parse_light(raw, where: str = "light") -> dict:
    """Validate a `light:` mapping and return {cell, layer}."""
    if not isinstance(raw, dict) or set(raw) - {"cell", "layer"}:
        raise LightError(f"{where}: light must be {{cell: {'|'.join(CELLS)}, layer: {'|'.join(LAYERS)}}}")
    cell, layer = raw.get("cell"), raw.get("layer")
    if cell not in CELLS:
        raise LightError(f"{where}: light.cell must be one of {', '.join(CELLS)}, got {cell!r}")
    if layer not in LAYERS:
        raise LightError(f"{where}: light.layer must be one of {', '.join(LAYERS)}, got {layer!r}")
    return {"cell": cell, "layer": layer}


def is_sprite(kind: str, transparent: bool) -> bool:
    return transparent and kind in SPRITE_KINDS


def targets(light: dict) -> dict:
    return standard()["cells"][light["cell"]][light["layer"]]


# ---------------------------------------------------------------------------
# Prompt block
# ---------------------------------------------------------------------------

def direction(vec) -> str:
    """Words for a light vector (screen coordinates, y grows downward): where the light comes FROM."""
    x, y = float(vec[0]), float(vec[1])
    horiz = "left" if x < -0.33 else "right" if x > 0.33 else ""
    if not horiz:
        return "straight above" if y < -0.33 else "straight below" if y > 0.33 else "the front"
    if y < -0.5:
        return f"the upper {horiz}"
    if y < -0.1:
        return f"the {horiz}, a little above"
    if y > 0.5:
        return f"the lower {horiz}"
    if y > 0.1:
        return f"the {horiz}, a little below"
    return f"the {horiz}"


def opposite(vec) -> str:
    x, y = float(vec[0]), float(vec[1])
    words = direction([-x, -y])
    if words == "straight below":
        return "straight down, directly under the object"
    return f"toward {words}"


def render_block(light: dict, sprite: bool = False) -> str:
    """The prompt block for a declared light. Names the key direction."""
    cs = colour_script()["cells"]
    cell = "day" if sprite else light["cell"]
    c = cs[cell]
    key, fill, rim, fog = c["key"], c["fill"], c["rim"], c["fog"]
    fromw = direction(key["from"])
    layer = light["layer"]
    lines = [f"LIGHT (hour: {cell}, layer: {layer}). {c['feeling']}."]
    if sprite:
        lines.append(
            f"Paint this under the clear daylight cell: key light {key['colour']} from {fromw}, soft cool fill {fill['colour']}, "
            f"a faint rim {rim['colour']} on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. "
            "Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.")
    else:
        lines.append(
            f"Key light {key['colour']} from {fromw}; fill {fill['colour']}; rim {rim['colour']} along the edge facing away from the key. "
            f"Shadows are tinted {c['shadow']} (never grey or black), short and soft, falling {opposite(key['from'])}; every object "
            "sits on a soft occlusion pad in that hue where it touches the ground or another form.")
    lines.append(
        "VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between "
        "light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow "
        "hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: "
        "edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside "
        "with a warm bounce.")
    if cell == "night":
        lines.append(
            "NIGHT is a hue change, not a value drop: only the sky is dark (deep indigo); the island and the clouds stay light, "
            "moonlit lavender, with violet shadows and cream practicals whose glow spreads three to four times the lamp's size.")
    if layer == "subject":
        lines.append("This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.")
    elif layer == "near":
        lines.append("This is a NEAR plane: close, the same envelope, with a touch of air.")
    else:
        lines.append(f"This is a FAR plane: lighter and flatter with distance, drifting toward the fog colour {fog['colour']}.")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Measurement
# ---------------------------------------------------------------------------

def subject_mask(rgba: np.ndarray) -> np.ndarray:
    alpha = rgba[..., 3]
    if float((alpha < 0.9).mean()) > 0.02:
        return alpha > 0.9
    h, w = alpha.shape
    x0, y0, x1, y1 = PLATE_SUBJECT_BOX
    m = np.zeros((h, w), dtype=bool)
    m[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)] = True
    return m


def _shrink(rgba: np.ndarray, px: int = MEASURE_PX) -> np.ndarray:
    h, w = rgba.shape[:2]
    if max(h, w) <= px:
        return rgba
    s = px / max(h, w)
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    im = im.resize((max(3, round(w * s)), max(3, round(h * s))), Image.Resampling.LANCZOS)
    return np.asarray(im, dtype=np.float64) / 255


def dark_channel(rgb: np.ndarray, size: int = 9) -> np.ndarray:
    dc = np.clip(rgb.min(axis=2) * 255, 0, 255).astype(np.uint8)
    return np.asarray(Image.fromarray(dc).filter(ImageFilter.MinFilter(size)), dtype=np.float64) / 255


def is_opaque(rgba: np.ndarray) -> bool:
    return float((rgba[..., 3] < 0.9).mean()) <= 0.02


def measure_light(rgba: np.ndarray) -> dict:
    """Light statistics of the subject region, plus the frame's sky, sea and darks for an opaque take
    (see design/art/light-standard.json `metrics`)."""
    rgba = _shrink(rgba)
    m = subject_mask(rgba)
    if not m.any():
        return {"error": "no subject pixels"}
    rgb = rgba[..., :3]
    L = sl.srgb_to_lab(rgb)[..., 0]
    q = lambda a, p: float(np.percentile(a, p))
    Ls = L[m]
    g = L / 100
    sd = np.sqrt(np.clip(sl.box(g * g, 4) - sl.box(g, 4) ** 2, 0, None))
    out = {"L_p5": round(q(Ls, 5), 1), "L_p50": round(q(Ls, 50), 1), "L_p98": round(q(Ls, 98), 1),
           "lc_p75": round(q(sd[m], 75) * 100, 2)}
    if is_opaque(rgba):
        h = L.shape[0]
        out.update({"sky_L": round(float(L[: max(h // 8, 1)].mean()), 1),
                    "sea_L": round(float(L[h - max(h // 8, 1):].mean()), 1),
                    "dark_pct": round(float((L[h // 4:] < 30).mean()) * 100, 1)})
    return out


def evaluate(m: dict, light: dict, std: dict | None = None) -> list[tuple[str, str, str, float]]:
    """Grade measurements against a cell x layer: [(name, status, message, value)]."""
    std = std or standard()
    t = targets(light)
    slack = std["fail_slack"]
    cell = f"{light['cell']}/{light['layer']}"

    def hi_bad(v, warn, fail):  # larger is worse
        return "fail" if v > fail else "warn" if v > warn else "pass"

    def lo_bad(v, warn, fail):
        return "fail" if v < fail else "warn" if v < warn else "pass"

    def band(v, lo, hi, sl_):
        return "pass" if lo <= v <= hi else "warn" if lo - sl_ <= v <= hi + sl_ else "fail"

    def worst(*s):
        return "fail" if "fail" in s else "warn" if "warn" in s else "pass"

    out = []
    st = worst(lo_bad(m["L_p5"], t["p5_min"], t["p5_min"] - slack["p5"]),
               lo_bad(m["L_p98"], t["p98_min"], t["p98_min"] - slack["p98"]))
    out.append(("light_values", st,
                f"{cell}: L p5 {m['L_p5']:.0f} (at least {t['p5_min']}: darks stay a light mid-tone), "
                f"p98 {m['L_p98']:.0f} (at least {t['p98_min']})", m["L_p5"]))
    lo, hi = t["median"]
    out.append(("light_median", band(m["L_p50"], lo, hi, slack["median"]),
                f"{cell}: median L {m['L_p50']:.0f} (band {lo}-{hi})", m["L_p50"]))
    lo, hi = t["lc_p75"]
    out.append(("light_contrast", band(m["lc_p75"], lo, hi, slack["lc"]),
                f"{cell}: p75 local contrast {m['lc_p75']:.1f} (band {lo}-{hi}; above it reads too contrasty)", m["lc_p75"]))
    if "sky_L" in m:
        f = std["cells"][light["cell"]]["frame"]
        lo, hi = f["sky_L"]
        out.append(("light_sky", band(m["sky_L"], lo, hi, slack["sky"]),
                    f"{light['cell']}: sky L {m['sky_L']:.0f} (band {lo}-{hi})", m["sky_L"]))
        out.append(("light_sea", lo_bad(m["sea_L"], f["sea_L_min"], f["sea_L_min"] - slack["sea"]),
                    f"{light['cell']}: cloud sea L {m['sea_L']:.0f} (at least {f['sea_L_min']}: the sea is the reflector)", m["sea_L"]))
        out.append(("light_dark", hi_bad(m["dark_pct"], f["dark_max"], f["dark_max"] + slack["dark"]),
                    f"{light['cell']}: {m['dark_pct']:.1f} % below L* 30 under the sky (at most {f['dark_max']}; only the sky is dark)",
                    m["dark_pct"]))
    return out


def main(argv: list[str] | None = None) -> int:
    """`python3 -I tools/imagegen/light.py FILE... [--cell day --layer subject]`: print measurements and grades."""
    import argparse

    ap = argparse.ArgumentParser(description=main.__doc__)
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--cell", choices=CELLS)
    ap.add_argument("--layer", choices=LAYERS, default="subject")
    args = ap.parse_args(argv)
    for f in args.files:
        m = measure_light(sl.load_rgba(f))
        print(f"{f.name}: {m}")
        if args.cell and "error" not in m:
            for name, status, message, _ in evaluate(m, {"cell": args.cell, "layer": args.layer}):
                print(f"   {status:4s} {name}: {message}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
