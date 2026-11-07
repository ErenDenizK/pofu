#!/usr/bin/env python3
"""Look pipeline v2, phase 1: bake the runtime's per-cell 3D LUTs from the references.

The look lab's winner (docs/research/look-lab.md section 8) is a per-material colour transfer
(Reinhard in CIELAB per material: lawn, earth, the props, the characters) toward the same material
in the founder's references, baked into one 17^3 LUT per layer group and time-of-day cell. The
runtime (`LookLUT`, `pofuWorldGrade`) looks the LUT up after the cell's parametric grade, per layer
group, and crossfades the two nearest cells and the rain LUT.

Source: the game's own Home frames under the current grade (CI's `concept-<state>-home.jpg` on a
screenshots branch). The frames are pixel-aligned across states (one camera, a still frame), so
the material masks come from the day frame and serve every state. References (ADR-0021):
I1 seasons for day, golden and rain; the Gezgin f2 and Revontuli nights for night (never the Tam
Cicek night). Dawn is half day, half golden; dusk half golden, half night (no reference each).

  python3 -I tools/looklab/bake_luts.py fit SHOTS_DIR [--compose]   LUTs into World.xcassets
  python3 -I tools/looklab/bake_luts.py sky                         sky and cloud-sea colours
  python3 -I tools/looklab/bake_luts.py sheet OUT.jpg REF_DIR=... --col LABEL=DIR ...

`fit --compose` treats SHOTS_DIR as frames that already went through the baked LUTs (a branch's
screenshots) and composes a correction onto them: a measured fix round, not a refit. `sky` writes
the colour script's sky and cloud-sea colours as final colours: the references' measured colours
(`SKY_TARGETS`) for golden, dusk and night, today's graded colours for dawn and day (the backdrop
now takes only the weather and wellbeing overlays, `WorldLight.backdropGrade`). `sheet` lays reference | before | after per
state at Home and the whole-island framing with dE2000 per region and the L* numbers.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import grade as gr  # noqa: E402
import lab  # noqa: E402
import lookdev as ld  # noqa: E402

N = 17
ASSETS = lab.REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
RECORD = lab.REPO / "design/art/look-luts.json"
SCRIPT = lab.REPO / "design/art/colour-script.json"
CELLS = ["dawn", "day", "golden", "dusk", "night"]
GROUPS = ["island", "characters"]
STATES = ["day", "golden", "night", "rain"]
# Night from the two liked nights only (the brief and ADR-0021): not the I1 snow night, not Tam Cicek.
REFS = {
    "day": lab.REF["day"],
    "golden": lab.REF["golden"],
    "rain": lab.REF["rain"],
    "night": lab.REF["night"][:2],
}
# Home frame boxes (lab regions "home"): the island rows; characters: Pofu and the two residents.
ISLAND_BOXES = [(0.0, 0.33, 0.55, 0.47), (0.0, 0.47, 0.85, 0.58), (0.0, 0.58, 1.0, 0.73)]
EARTH_BOX = (0.0, 0.6, 1.0, 0.73)
CHARACTER_BOXES = [(0.43, 0.43, 0.66, 0.55), (0.68, 0.47, 0.9, 0.55)]
# How far the props (stations, fences, flowers) move with the island's mean shift, and how far the
# characters move toward their own day colours (they keep their warmth: never the night's hue).
PROP_STRENGTH = 0.8
CHARACTER_TOWARD_DAY = {"day": 0.0, "golden": 0.25, "rain": 0.5, "night": 0.75}
# Their lightness never drops below this share of the day's (Pofu is lit by sources, never dim).
SCALE_CLIP = (0.75, 1.3)
# Night means set by design where the two liked nights disagree with each other and with our
# materials: the Gezgin lawn is lamp-lit yellow-green and the Revontuli "earth" is ice, so the
# lawn keeps a moonlit teal-green and the earth face turns light mauve (violet shadows), at the
# references' island value (p50 ~70; reference-look.md 6.4, ADR-0021). Spreads stay the references'.
MEAN_OVERRIDES = {"night": {"lawn": (68.0, -8.0, 8.0), "earth": (72.0, 10.0, -8.0)}}


def box_mask(shape, boxes) -> np.ndarray:
    h, w = shape[:2]
    m = np.zeros((h, w), bool)
    for x0, y0, x1, y1 in boxes:
        m[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)] = True
    return m


def frame_materials(day_rgb: np.ndarray) -> dict[str, np.ndarray]:
    """Masks from the day frame (same camera in every state): lawn by hue, the earth face, the
    props (the rest of the island rows) and the characters."""
    lb = lab.lab(day_rgb)
    island = box_mask(day_rgb.shape, ISLAND_BOXES) & (gr.ui_free(day_rgb.shape) > 0.5)
    chars = box_mask(day_rgb.shape, CHARACTER_BOXES) & ~gr.lawn_like(lb) & (lb[..., 0] > 45)
    lawn = island & gr.lawn_like(lb) & ~chars
    earth = island & box_mask(day_rgb.shape, [EARTH_BOX]) & ~lawn
    props = island & ~lawn & ~earth & ~chars
    return {"lawn": lawn, "earth": earth, "props": props, "characters": chars}


def ref_materials(state: str) -> dict[str, np.ndarray]:
    """Pooled Lab samples per material in the state's references (region boxes, lawn by hue)."""
    out: dict[str, list] = {"lawn": [], "earth": [], "island": []}
    for p in REFS[state]:
        rgb = lab.load_rgb(p, 768)
        lb = lab.lab(rgb)
        kind = lab.kind_of(p)
        top = np.zeros(rgb.shape[:2], bool)
        for name in ("back", "focal"):
            m = lab.region_mask(rgb.shape, kind, name)
            if m is not None:
                top |= m
        earth = lab.region_mask(rgb.shape, kind, "earth")
        lawn = top & gr.lawn_like(lb)
        if lawn.sum() > 400:
            out["lawn"].append(lb[lawn])
        if earth is not None:
            out["earth"].append(lb[earth & ~gr.lawn_like(lb)])
            out["island"].append(lb[(top | earth)])
    return {k: np.concatenate(v) for k, v in out.items() if v}


def reinhard_to(src: np.ndarray, tgt: np.ndarray, strength: float = 1.0) -> np.ndarray:
    scale = np.clip(tgt.std(0) / np.maximum(src.std(0), 1e-6), *SCALE_CLIP)
    moved = (src - src.mean(0)) * scale + tgt.mean(0)
    return src + strength * (moved - src)


def identity() -> np.ndarray:
    return np.stack(np.meshgrid(*[np.linspace(0, 1, N)] * 3, indexing="ij"), -1)


def transfer(frame: np.ndarray, mats: dict, state: str, day_frame: np.ndarray) -> dict[str, np.ndarray]:
    """(source rgb, target rgb) pairs per layer group for one state."""
    lb = lab.lab(frame)
    tg = ref_materials(state)
    pairs: dict[str, tuple] = {}
    src_island, dst_island = [], []
    moved_island = []
    for k in ("lawn", "earth"):
        m = mats[k]
        s = lb[m]
        t = tg.get(k, tg["island"])
        if k in MEAN_OVERRIDES.get(state, {}):
            t = t - t.mean(0) + np.asarray(MEAN_OVERRIDES[state][k])
        d = reinhard_to(s, t)
        src_island.append(frame[m])
        dst_island.append(lab.rgb_of(d))
        moved_island.append((s, d))
    shift = np.mean([d.mean(0) - s.mean(0) for s, d in moved_island], axis=0)
    p = mats["props"]
    sp = lb[p]
    dp = sp + PROP_STRENGTH * shift
    src_island.append(frame[p])
    dst_island.append(lab.rgb_of(dp))
    pairs["island"] = (np.concatenate(src_island), np.concatenate(dst_island))
    # Characters: toward their own day colours, a share per state; never the island's hue.
    c = mats["characters"]
    sc = lb[c]
    tc = lab.lab(day_frame)[c]
    k = CHARACTER_TOWARD_DAY[state]
    dc = sc if k == 0 else reinhard_to(sc, tc, k)
    pairs["characters"] = (frame[c], lab.rgb_of(dc))
    return pairs


def fit_group(src: np.ndarray, dst: np.ndarray) -> np.ndarray:
    idx = np.random.default_rng(5).choice(len(src), size=min(60000, len(src)), replace=False)
    return gr.fit_lut(src[idx], np.clip(dst[idx], 0, 1), n=N, sigma=1.0)


def compose(outer: np.ndarray, inner: np.ndarray) -> np.ndarray:
    """outer(inner(x)) as one LUT."""
    return np.clip(gr.apply_lut(inner.reshape(-1, 1, 3), outer).reshape(inner.shape), 0, 1)


def mean_lut(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    return (a + b) / 2


# ---------------------------------------------------------------- the strip texture

def name_of(group: str, cell: str) -> str:
    return f"world-lut-{group}-{cell}"


def write_strip(lut: np.ndarray, name: str) -> Path:
    """An (N*N) x (N+1) RGB strip: row 0 is a 0.5 grey calibration row (the shader reads texel
    (0, 0) to undo an sRGB decode, like the normal maps); row 1 + g, column b * N + r holds
    LUT[r, g, b]."""
    img = np.zeros((N + 1, N * N, 3))
    img[0] = 128 / 255
    for b in range(N):
        img[1:, b * N:(b + 1) * N] = lut[:, :, b].transpose(1, 0, 2)
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    out = folder / f"{name}.png"
    Image.fromarray(np.round(np.clip(img, 0, 1) * 255).astype(np.uint8), "RGB").save(out, optimize=True)
    (folder / "Contents.json").write_text(
        '{\n  "images": [\n    {\n      "filename": "%s.png",\n      "idiom": "universal"\n    }\n  ],\n'
        '  "info": {\n    "author": "xcode",\n    "version": 1\n  }\n}\n' % name
    )
    return out


def read_strip(name: str) -> np.ndarray:
    path = ASSETS / f"{name}.imageset" / f"{name}.png"
    if not path.exists():
        return identity()
    img = np.asarray(Image.open(path).convert("RGB"), np.float64) / 255
    lut = np.zeros((N, N, N, 3))
    for b in range(N):
        lut[:, :, b] = img[1:, b * N:(b + 1) * N].transpose(1, 0, 2)
    return lut


# ---------------------------------------------------------------- numbers

def island_p50(rgb: np.ndarray, kind: str) -> float:
    m = np.zeros(rgb.shape[:2], bool)
    for name in ("back", "focal", "earth"):
        r = lab.region_mask(rgb.shape, kind, name)
        if r is not None:
            m |= r
    return float(np.median(lab.lab(rgb)[..., 0][m]))


def readout(rgb: np.ndarray, kind: str, ref: dict) -> dict:
    c = lab.compare(lab.stats(rgb, kind), ref)
    L = lab.lab(rgb)[..., 0]
    h = L.shape[0]
    sky = lab.region_mask(rgb.shape, kind, "sky")
    sea = lab.region_mask(rgb.shape, kind, "sea")
    top = float(np.median(L[: max(int(h * 0.05), 1)]))
    return {**c, "p50": round(island_p50(rgb, kind), 1), "skyTop": round(top, 1),
            "sky": round(float(L[sky].mean()), 1) if sky is not None else None,
            "sea": round(float(L[sea].mean()), 1) if sea is not None else None}


def ref_readout(state: str) -> dict:
    vals = []
    for p in REFS[state]:
        rgb = lab.load_rgb(p, 1024)
        k = lab.kind_of(p)
        L = lab.lab(rgb)[..., 0]
        vals.append((island_p50(rgb, k), float(np.median(L[: int(L.shape[0] * 0.05)])),
                     float(L[lab.region_mask(rgb.shape, k, "sky")].mean()), float(L[lab.region_mask(rgb.shape, k, "sea")].mean())))
    v = np.mean(vals, axis=0)
    return {"p50": round(v[0], 1), "skyTop": round(v[1], 1), "sky": round(v[2], 1), "sea": round(v[3], 1)}


# ---------------------------------------------------------------- fit

def fit(shots: Path, composing: bool) -> dict:
    frames = {s: lab.load_rgb(shots / f"concept-{s}-home.jpg") for s in STATES}
    mats = frame_materials(frames["day"])
    luts: dict[tuple[str, str], np.ndarray] = {}
    record: dict = {"source": str(shots.name), "composed": composing, "states": {}}
    for s in STATES:
        pairs = transfer(frames[s], mats, s, frames["day"])
        for g in GROUPS:
            src, dst = pairs[g]
            luts[(g, s)] = fit_group(src, dst)
        ref = lab.ref_stats(s)
        before = lab.compare(lab.stats(frames[s], "home"), ref)
        pred = frames[s].copy()
        isl = box_mask(pred.shape, [(0, 0.3, 1, 0.75)])
        pred[isl] = gr.apply_lut(frames[s][isl][:, None, :], luts[("island", s)])[:, 0, :]
        after = lab.compare(lab.stats(pred, "home"), ref)
        record["states"][s] = {"before": before, "predicted": after,
                               "p50": [round(island_p50(frames[s], "home"), 1), round(island_p50(pred, "home"), 1)]}
        print(s, "island dE", before["dE_regions"], "->", after["dE_regions"], "p50", record["states"][s]["p50"])
    for g in GROUPS:
        cell_luts = {
            "day": luts[(g, "day")], "golden": luts[(g, "golden")], "night": luts[(g, "night")],
            "rain": luts[(g, "rain")],
        }
        cell_luts["dawn"] = mean_lut(cell_luts["day"], cell_luts["golden"])
        cell_luts["dusk"] = mean_lut(cell_luts["golden"], cell_luts["night"])
        for cell, lut in cell_luts.items():
            name = name_of(g, cell)
            if composing:
                lut = compose(lut, read_strip(name))
            write_strip(lut, name)
    return record


# ---------------------------------------------------------------- sky and sea

# The references' measured colours (CIELAB), per cell: the zenith (top 5 %), the horizon, the sky's
# clouds (lit side, shade) and the cloud sea (lit side, shade). Night: Gezgin f2 + Revontuli
# (zenith L* 27-34 saturated blue-violet, lighter toward the horizon; the cloud sea warm white).
# Golden: I1 summer evening, pink-peach where our sky was lilac.
SKY_TARGETS = {
    "night": {"zenith": (28, 14, -36), "horizon": (44, 13, -34), "glow": (78, 6, -12),
              "cloudLight": (86, 4, -6), "cloudShade": (62, 10, -24),
              "sea.light": (88, 3, 3), "sea.shade": (74, 7, -12)},
    "dusk": {"zenith": (36, 18, -32), "horizon": (66, 20, -6), "glow": (80, 16, 18),
             "cloudLight": (84, 10, 2), "cloudShade": (64, 14, -18),
             "sea.light": (88, 6, 6), "sea.shade": (74, 10, -8)},
    "golden": {"zenith": (68, 24, -16), "horizon": (84, 18, 18), "glow": (90, 10, 30),
               "cloudLight": (92, 8, 10), "cloudShade": (74, 18, -6),
               "sea.light": (90, 8, 8), "sea.shade": (78, 12, -2)},
}


def lab_to_rgb(v) -> np.ndarray:
    return np.clip(lab.rgb_of(np.asarray(v, np.float64)[None, :])[0], 0, 1)


def to_hex(rgb) -> str:
    return "#" + "".join(f"{int(round(float(v) * 255)):02X}" for v in rgb)


# Cells whose sky keeps today's look: their colours are rewritten as their current graded values,
# since the sky and the cloud sea now take only the overlays' grade (WorldLight.backdropGrade).
KEEP_GRADED = ["dawn", "day"]
SKY_KEYS = ["zenith", "horizon", "glow", "cloudLight", "cloudShade"]
SEA_KEYS = ["light", "shade"]


def sky() -> None:
    """Writes the sky and cloud-sea colours as final colours (the file is hand-formatted, so the
    hex values are replaced in place). Run once per re-key: a cell in KEEP_GRADED is baked through
    its own sky grade, a cell in SKY_TARGETS takes the references' measured colours."""
    import re
    text = SCRIPT.read_text()
    script = json.loads(text)

    def put(cell: str, block: str, field: str, value: str) -> None:
        nonlocal text
        start = text.index(f'"{cell}": {{', text.index('"cells"'))
        at = text.index(f'"{block}": {{', start)
        end = text.index("\n", at)
        line = re.sub(f'"{field}": "#[0-9A-Fa-f]{{6}}"', f'"{field}": "{value}"', text[at:end], count=1)
        text = text[:at] + line + text[end:]

    for cell in KEEP_GRADED:
        c = script["cells"][cell]
        params = ld.grade_params(c, sky=True)
        for block, keys in (("sky", SKY_KEYS), ("sea", SEA_KEYS)):
            for k in keys:
                put(cell, block, k, to_hex(ld.apply_grade(np.asarray(ld.hex_rgb(c[block][k]))[None, :], params)[0]))
    for cell, targets in SKY_TARGETS.items():
        for key, target in targets.items():
            block, field = ("sea", key.split(".")[1]) if key.startswith("sea.") else ("sky", key)
            put(cell, block, field, to_hex(lab_to_rgb(target)))
            print(f"{cell:7s} {key:11s} {to_hex(lab_to_rgb(target))}  L*a*b* {target}")
    SCRIPT.write_text(text)


# ---------------------------------------------------------------- the comparison sheet

def sheet(out: Path, columns: list[tuple[str, Path]]) -> dict:
    rows, labels, numbers = [], [], {}
    for s in STATES:
        ref = lab.ref_stats(s)
        rr = ref_readout(s)
        for framing in ("home", "whole"):
            row = [(lab.to_img(lab.load_rgb(REFS[s][0], 900)),
                    f"reference {REFS[s][0].parent.name}\np50 {rr['p50']}  skyTop {rr['skyTop']}  sea {rr['sea']}")]
            for label, folder in columns:
                p = folder / f"concept-{s}-{framing}.jpg"
                if not p.exists():
                    p = folder / f"concept-{s}-{framing}.png"
                if not p.exists():
                    continue
                rgb = lab.load_rgb(p)
                r = readout(rgb, framing, ref)
                numbers.setdefault(s, {}).setdefault(framing, {})[label] = r
                row.append((lab.to_img(rgb), f"{label} {framing}\ndE {r['dE']} (sky {r['dE_regions'].get('sky')} "
                            f"isl {round(np.mean([r['dE_regions'][k] for k in ('back', 'focal', 'earth')]), 1)} "
                            f"sea {r['dE_regions'].get('sea')})\np50 {r['p50']}  skyTop {r['skyTop']}  sea {r['sea']}"))
            rows.append(row)
            labels.append(f"{s} {framing}")
        numbers.setdefault(s, {})["reference"] = rr
    lab.sheet(rows, out, "Look pipeline v2: reference | main | branch (dE2000 by region, L* island p50, sky top, sea)",
              cell_h=420, row_labels=labels)
    return numbers


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("fit")
    f.add_argument("shots", type=Path)
    f.add_argument("--compose", action="store_true")
    sub.add_parser("sky")
    s = sub.add_parser("sheet")
    s.add_argument("out", type=Path)
    s.add_argument("--col", action="append", default=[], help="LABEL=DIR")
    s.add_argument("--json", type=Path)
    a = ap.parse_args(argv)
    if a.cmd == "fit":
        record = fit(a.shots, a.compose)
        old = json.loads(RECORD.read_text()) if RECORD.exists() and a.compose else {}
        rounds = old.get("rounds", []) + [record]
        RECORD.write_text(json.dumps({
            "$note": "Per-cell 3D LUTs per layer group (look pipeline v2, phase 1): fitted by "
                     "tools/looklab/bake_luts.py from the game's Home frames toward the references "
                     "(I1 day, golden, rain; Gezgin f2 + Revontuli night). Each round: the source "
                     "frames, whether it composed a correction, and dE before / predicted.",
            "size": N, "groups": GROUPS, "cells": CELLS + ["rain"],
            "references": {k: [str(p.relative_to(lab.REPO)) for p in v] for k, v in REFS.items()},
            "rounds": rounds}, indent=1) + "\n")
    elif a.cmd == "sky":
        sky()
    else:
        cols = [(c.split("=", 1)[0], Path(c.split("=", 1)[1])) for c in a.col]
        numbers = sheet(a.out, cols)
        if a.json:
            a.json.write_text(json.dumps(numbers, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
