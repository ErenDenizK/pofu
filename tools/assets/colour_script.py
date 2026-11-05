#!/usr/bin/env python3
"""The colour script: validate design/art/colour-script.json and generate PofuWorld's Swift for it.

The colour script (look round 3; docs/design/colour-script.md) is Pofu's light as data: five hour
cells (dawn, day, golden, dusk, night) and the unwell state layered over any hour. Swift never
hand-copies its numbers: this writes `ColourScript+Generated.swift`, and CI runs `check`, which fails
when the generated file is stale or the script is invalid.

  python3 -I tools/assets/colour_script.py generate            write the Swift
  python3 -I tools/assets/colour_script.py check               fail if stale or invalid
  python3 -I tools/assets/colour_script.py swatches OUT.png    the cells' swatches, for review
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
SCRIPT = REPO / "design" / "art" / "colour-script.json"
SWIFT = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Look" / "ColourScript+Generated.swift"

CELLS = ("dawn", "day", "golden", "dusk", "night")
SKY = ("zenith", "horizon", "glow", "cloudLight", "cloudShade", "tint")
GRADE_FIELDS = ("black", "white", "lift", "gamma", "gain", "contrast", "pivot", "saturation", "vignette")
HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")


def load(path: Path = SCRIPT) -> dict:
    return json.loads(path.read_text())


def validate(script: dict) -> list[str]:
    """Problems with the script, empty when it is usable."""
    problems = []
    cells = script.get("cells", {})
    for name in CELLS:
        if name not in cells:
            problems.append(f"missing cell {name}")
    keys = script.get("schedule", {}).get("keys", [])
    minutes = [k["minute"] for k in keys]
    if not keys or minutes[0] != 0 or minutes[-1] != 1440 or minutes != sorted(minutes):
        problems.append("schedule keys must run from minute 0 to 1440 in order")
    for k in keys:
        if k["cell"] not in cells:
            problems.append(f"schedule names an unknown cell {k['cell']}")

    def colour(where, value):
        if not isinstance(value, str) or not HEX.match(value):
            problems.append(f"{where}: {value!r} is not #RRGGBB")

    def grade(where, g):
        for f in g:
            if f not in GRADE_FIELDS:
                problems.append(f"{where}: unknown grade field {f}")
        for f in ("lift", "gamma", "gain"):
            if f in g and len(g[f]) != 3:
                problems.append(f"{where}.{f}: three channels")
        if g.get("saturation", 1) < 0 or g.get("contrast", 1) <= 0:
            problems.append(f"{where}: saturation and contrast must be positive")

    for name, c in cells.items():
        for f in SKY:
            colour(f"{name}.sky.{f}", c["sky"][f])
        for light in ("key", "fill", "rim"):
            colour(f"{name}.{light}", c[light]["colour"])
        colour(f"{name}.shadow", c["shadow"])
        colour(f"{name}.fog", c["fog"]["colour"])
        for f in ("light", "shade"):
            colour(f"{name}.sea.{f}", c["sea"][f])
        grade(f"{name}.grade", c["grade"])
        grade(f"{name}.character", c["character"])
        for f in ("poolGain", "ambientFloor", "moonRim"):
            v = c.get("light", {}).get(f)
            if not isinstance(v, (int, float)) or not 0 <= v <= 1.5:
                problems.append(f"{name}.light.{f}: a number from 0 to 1.5")
        if c.get("light", {}).get("ambientFloor", 0) > 0.3:
            problems.append(f"{name}.light.ambientFloor: a floor, not a light (at most 0.3)")
        # Pofu is never cut by the grade's saturation (pro-game-craft 4.3, the rule for Pofu).
        if c["character"].get("saturation", 1) < 1:
            problems.append(f"{name}.character: Pofu's saturation is never cut (< 1)")
    unwell = script.get("states", {}).get("unwell")
    if not unwell:
        problems.append("missing state unwell")
    else:
        grade("unwell.grade", unwell["grade"])
        grade("unwell.character", unwell["character"])
        colour("unwell.sky.toward", unwell["sky"]["toward"])
        if unwell["sky"]["value"] > 1:
            problems.append("unwell.sky.value: the unwell sky is never brighter than the hour's")
    return problems


# ---------------------------------------------------------------------------
# Swift
# ---------------------------------------------------------------------------

def _num(v: float) -> str:
    return repr(float(v))


def _hex(v: str) -> str:
    return f"PofuRGB(hex: 0x{v[1:].upper()})"


def _rgb(v: str) -> str:
    r, g, b = (int(v[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return f"GradeRGB({r:.4f}, {g:.4f}, {b:.4f})"


def _triple(v) -> str:
    return f"GradeRGB({_num(v[0])}, {_num(v[1])}, {_num(v[2])})"


def _grade(g: dict, indent: str) -> str:
    parts = []
    for f in GRADE_FIELDS:
        if f in g:
            parts.append(f"{f}: {_triple(g[f]) if f in ('lift', 'gamma', 'gain') else _num(g[f])}")
    if not parts:
        return "WorldGrade()"
    inner = (",\n" + indent + "    ").join(parts)
    return f"WorldGrade(\n{indent}    {inner}\n{indent})"


def _point(p) -> str:
    return f"SkyPoint(x: {_num(p[0])}, y: {_num(p[1])})"


def _light(l: dict) -> str:
    direction = f", from: {_point(l['from'])}" if "from" in l else ""
    return f"ScriptLight(colour: {_rgb(l['colour'])}, intensity: {_num(l['intensity'] if 'intensity' in l else l['strength'])}{direction})"


def swift(script: dict) -> str:
    out = [
        "// Generated by tools/assets/colour_script.py from design/art/colour-script.json. Do not edit.",
        "import PofuDesignSystem",
        "",
        "extension ColourScript {",
        "    static let generatedCells: [ColourCell.Name: ColourCell] = [",
    ]
    for name in CELLS:
        c = script["cells"][name]
        s = c["sky"]
        i = "            "
        out += [
            f"        .{name}: ColourCell(",
            f"{i}name: .{name},",
            f"{i}sun: {_point(c['sun'])},",
            f"{i}sky: SkyColours(",
            f"{i}    zenith: {_hex(s['zenith'])},",
            f"{i}    horizon: {_hex(s['horizon'])},",
            f"{i}    glow: {_hex(s['glow'])},",
            f"{i}    glowStrength: {_num(s['glowStrength'])},",
            f"{i}    cloudLight: {_hex(s['cloudLight'])},",
            f"{i}    cloudShade: {_hex(s['cloudShade'])},",
            f"{i}    cloudOpacity: {_num(s['cloudOpacity'])},",
            f"{i}    stars: {_num(s['stars'])},",
            f"{i}    tint: {_hex(s['tint'])}",
            f"{i}),",
            f"{i}key: {_light(c['key'])},",
            f"{i}fill: {_light(c['fill'])},",
            f"{i}shadow: {_rgb(c['shadow'])},",
            f"{i}rim: {_light(c['rim'])},",
            f"{i}practicals: Practicals(ember: {_num(c['practicals']['ember'])}, window: {_num(c['practicals']['window'])}),",
            f"{i}poolGain: {_num(c['light']['poolGain'])},",
            f"{i}ambientFloor: {_num(c['light']['ambientFloor'])},",
            f"{i}moonRim: {_num(c['light']['moonRim'])},",
            f"{i}fog: ScriptFog(colour: {_hex(c['fog']['colour'])}, far: {_num(c['fog']['far'])}),",
            f"{i}sea: SeaColours(light: {_hex(c['sea']['light'])}, shade: {_hex(c['sea']['shade'])}, opacity: {_num(c['sea']['opacity'])}),",
            f"{i}grade: {_grade(c['grade'], i)},",
            f"{i}character: {_grade(c['character'], i)}",
            "        ),",
        ]
    out += ["    ]", "", "    static let generatedSchedule: [ColourScript.Key] = ["]
    for k in script["schedule"]["keys"]:
        sun = _point(k["sun"]) if "sun" in k else "nil"
        out.append(f"        Key(minute: {_num(k['minute'])}, cell: .{k['cell']}, sun: {sun}),")
    u = script["states"]["unwell"]
    i = "        "
    out += [
        "    ]",
        "",
        "    static let generatedUnwell = ColourState(",
        f"{i}grade: {_grade(u['grade'], i)},",
        f"{i}character: {_grade(u['character'], i)},",
        f"{i}skyValue: {_num(u['sky']['value'])},",
        f"{i}skyChroma: {_num(u['sky']['chroma'])},",
        f"{i}skyToward: {_hex(u['sky']['toward'])},",
        f"{i}skyAmount: {_num(u['sky']['amount'])},",
        f"{i}keyIntensity: {_num(u['key']['intensity'])},",
        f"{i}windowFloor: {_num(u['practicals']['window'])}",
        "    )",
        "}",
        "",
    ]
    return "\n".join(out)


# ---------------------------------------------------------------------------
# Swatches
# ---------------------------------------------------------------------------

def swatches(script: dict, path: Path) -> None:
    from PIL import Image, ImageDraw

    rows = [("sky", lambda c: [c["sky"]["zenith"], c["sky"]["horizon"], c["sky"]["glow"]]),
            ("key", lambda c: [c["key"]["colour"]]), ("fill", lambda c: [c["fill"]["colour"]]),
            ("shadow", lambda c: [c["shadow"]]), ("rim", lambda c: [c["rim"]["colour"]]),
            ("fog", lambda c: [c["fog"]["colour"]]), ("sea", lambda c: [c["sea"]["light"], c["sea"]["shade"]])]
    cw, rh, lw = 220, 46, 70
    img = Image.new("RGB", (lw + cw * len(CELLS), 40 + rh * len(rows)), (246, 244, 240))
    d = ImageDraw.Draw(img)
    for j, name in enumerate(CELLS):
        c = script["cells"][name]
        d.text((lw + j * cw + 6, 8), f"{name}: {c['feeling']}", fill=(30, 30, 30))
        for r, (label, get) in enumerate(rows):
            cols = get(c)
            y = 40 + r * rh
            w = (cw - 10) / len(cols)
            for k, hx in enumerate(cols):
                rgb = tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5))
                d.rectangle([lw + j * cw + k * w, y, lw + j * cw + (k + 1) * w - 2, y + rh - 6], fill=rgb)
    for r, (label, _) in enumerate(rows):
        d.text((6, 40 + r * rh + 14), label, fill=(60, 60, 60))
    img.save(path)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("generate")
    sub.add_parser("check")
    sw = sub.add_parser("swatches")
    sw.add_argument("out", type=Path)
    args = ap.parse_args(argv)
    script = load()
    problems = validate(script)
    for p in problems:
        print(f"INVALID: {p}", file=sys.stderr)
    if problems:
        return 1
    if args.cmd == "swatches":
        swatches(script, args.out)
        return 0
    text = swift(script)
    if args.cmd == "generate":
        SWIFT.write_text(text)
        print(f"wrote {SWIFT.relative_to(REPO)}")
        return 0
    if not SWIFT.exists() or SWIFT.read_text() != text:
        print("STALE: run python3 -I tools/assets/colour_script.py generate", file=sys.stderr)
        return 1
    print("colour script is current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
