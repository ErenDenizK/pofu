"""The art light standard: prompt block, measurement and target lookup.

Rules live in docs/design/light-standard.md; numbers in
design/art/light-standard.json (value targets per colour-script cell x
layer); key direction, rim, fill, shadow hue and fog are read from
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
            f"Shadows are tinted {c['shadow']} (never grey or black) and fall {opposite(key['from'])}; paint a contact shadow in that hue "
            "under every object that touches the ground or another form, firmest in the subject plane.")
    lines.append(
        "VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest "
        "recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. "
        "A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.")
    if layer == "subject":
        lines.append("This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.")
    elif layer == "near":
        lines.append("This is a NEAR plane: close, almost the full value range, with at most a touch of atmosphere.")
    else:
        lines.append(f"This is a FAR plane: contrast and darks soften with distance and forms drift toward the fog colour {fog['colour']}, "
                     "but no black becomes grey-white and nothing is washed out.")
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


def measure_light(rgba: np.ndarray) -> dict:
    """Light statistics of the subject region (see design/art/light-standard.json `metrics`)."""
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
    dc = dark_channel(rgb)
    p2, p98 = q(Ls, 2), q(Ls, 98)
    return {"L_p2": round(p2, 1), "L_p50": round(q(Ls, 50), 1), "L_p98": round(p98, 1), "spread": round(p98 - p2, 1),
            "haze": round(q(dc[m], 10), 3), "lc_p75": round(q(sd[m], 75) * 100, 2)}


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

    out = []
    s = [hi_bad(m["L_p2"], t["p2_max"], t["p2_max"] + slack["p2"]),
         lo_bad(m["L_p98"], t["p98_min"], t["p98_min"] - slack["p98"]),
         lo_bad(m["spread"], t["spread_min"], t["spread_min"] - slack["spread"])]
    st = "fail" if "fail" in s else "warn" if "warn" in s else "pass"
    out.append(("light_values", st,
                f"{cell}: L p2 {m['L_p2']:.0f} (at most {t['p2_max']}), p98 {m['L_p98']:.0f} (at least {t['p98_min']}), "
                f"spread {m['spread']:.0f} (at least {t['spread_min']})", m["spread"]))
    lo, hi = t["median"]
    med = m["L_p50"]
    sl_ = slack["median"]
    st = "pass" if lo <= med <= hi else "warn" if lo - sl_ <= med <= hi + sl_ else "fail"
    out.append(("light_median", st, f"{cell}: median L {med:.0f} (band {lo}-{hi})", med))
    out.append(("light_haze", hi_bad(m["haze"], t["haze_max"], t["haze_max"] + slack["haze"]),
                f"{cell}: dark-channel haze {m['haze']:.2f} (at most {t['haze_max']:.2f}; no true dark means a wash)", m["haze"]))
    out.append(("light_contrast", lo_bad(m["lc_p75"], t["lc_p75_min"], t["lc_p75_min"] - slack["lc"]),
                f"{cell}: p75 local contrast {m['lc_p75']:.1f} (at least {t['lc_p75_min']})", m["lc_p75"]))
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
