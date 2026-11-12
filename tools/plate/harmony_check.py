#!/usr/bin/env python3
"""Do the characters sit in the plate's light? (docs/design/visual-system.md, "Characters".)

Measures a full-resolution Home frame from the app (`home-plate-full-<state>.png`, 1206 x 2622):
the characters' body regions against the surrounding lawn, in CIELAB, and checks the difference
(character minus lawn, dL* and dC*) against the band calibrated on the level-10 day frame.

    python3 -I tools/plate/harmony_check.py FRAME [FRAME ...] [--json] [--overlay DIR]

Where the bodies are: nothing is segmented from the picture. The frame's geometry is the app's
(`HomePlate`): the island is `framing.homeWidths` screen widths wide with its centre at the screen's,
its top `framing.homeTopY` points down, so a plate pixel is `W * homeWidths / islandBox.width`
frame pixels; Pofu's art is `pofuWidth` plate pixels wide with its ground point on his spot, Mochi
and Findik are scaled by the same factor times `residentBoost`. The body is the ellipse of the
art's body (Pofu: the rig's body ellipse; the residents: their sharp box), shrunk to 0.75 so it
holds no lawn. The lawn is the walkable polygon in a ring 0.8...2.4 character widths around each
character, outside every character's disc; its L* and C* are the 25th to 75th percentile mean
(stones and shadows do not move it).

The band: on the level-10 day frame the difference of each character to its lawn (character minus
lawn, dL* and dC*) is what a character painted for that plate looks like, `REF`. A state is in
harmony when

  - dL* is within `TOL_L` of `REF`'s dL* (the character is as much lighter or darker than its lawn
    as by day), and
  - dC* is at most `CAP_C` (a character is never louder than its lawn: night's lawn is nearly grey)
    and at least `REF`'s dC* minus `FLOOR_C` (and never flatter against it than by day);

and the characters take the light, not only its brightness:

  - night: each character's 95th percentile L* is at or below the brightest lawn stone around it (the
    ring's L* p95): by night the three are never the brightest things on the lawn (no sticker look);
  - golden hour: the hue of Pofu's fur (CIELAB hue angle of its mean colour) moves from the level-10
    day frame's at least half as far, in the same direction, as the hue of the lawn around him does.

Calibration: `REF` is the level-10 day frame (CI frame, see `REF`); across the day plates (levels 10, 5, 2) dL* moves at most 8.2 and dC* at most
11.2 (Pofu, Mochi, Findik), so `TOL_L` 10 and `FLOOR_C` 12 (docs/design/visual-system.md "Characters").
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
from process_assets import srgb_to_lab  # noqa: E402

PLATES = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "Plates"
PLATE_JSON = PLATES / "plate-home.json"
SCREEN_W = 402.0

#: The art's boxes in art units (`WorldArt+Generated.swift`, sharp): (min x, min y, max x, max y).
SPRITE_BOX = {"mochi": (-15.2, -23.141, 15.2, 0.192), "findik": (-14.291, -26.835, 14.375, 0.232),
              "damla": (-19.119, -46.952, 19.148, 0.115)}
#: Damla holds a full glass at Çağlayan's stage 4 (`damla-glass`): her box there.
DAMLA_GLASS_BOX = (-19.593, -53.295, 18.807, 0.038)
#: Pofu's rig (`CompanionRig.hamster`, 522 x 496 px): ground point and body ellipse.
RIG = {"w": 522.0, "h": 496.0, "ground": (266.0, 481.0), "body": (265.0, 300.0, 249.0, 219.0)}
SHRINK = 0.75
RING = (0.8, 2.4)

#: The level-10 day frame's (dL*, dC*) per character, the band's anchor ...
REF = {"pofu": (6.2, -37.9), "mochi": (11.3, -39.5), "findik": (2.5, -30.3)}
#: ... how far dL* may stray from it, how far dC* may fall below it, and dC*'s ceiling.
TOL_L = 10.0
FLOOR_C = 12.0
CAP_C = 8.0
#: Golden hour: the fur's hue shift over the lawn's at least this, and the lawn's smallest shift that asks.
HUE_FOLLOW = 0.5
HUE_MIN = 2.0


def frame_map(data: dict, w: int):
    """Plate pixels to frame pixels at Home, as (m, fx, fy): scale and the two mappings."""
    box = data["islandBox"]
    f = data["framing"]
    m = w * f["homeWidths"] / (box[2] - box[0])
    cx = box[0] + f["homeCenterX"] * (box[2] - box[0])
    top = f["homeTopY"] * w / SCREEN_W
    return m, (lambda x: w / 2 + (x - cx) * m), (lambda y: top + (y - box[1]) * m)


def characters(data: dict, w: int, stage: int = 0) -> dict:
    """Each character's feet, body ellipse (cx, cy, rx, ry) and width, in frame pixels. `stage` is
    the story stage of a Çağlayan frame (Damla's art holds a glass at 4)."""
    m, fx, fy = frame_map(data, w)
    out = {}
    unit = data["pofuWidth"] / 64.0 * m  # frame px per art unit, Pofu's proportion
    for name, (x, y) in data["characters"].items():
        feet = (fx(x), fy(y))
        if name == "pofu":
            aw = data["pofuWidth"] * m
            ah = aw * RIG["h"] / RIG["w"]
            gx, gy = RIG["ground"]
            left, top = feet[0] - gx / RIG["w"] * aw, feet[1] - gy / RIG["h"] * ah
            bx, by, rx, ry = RIG["body"]
            c = (left + bx / RIG["w"] * aw, top + by / RIG["h"] * ah, rx / RIG["w"] * aw, ry / RIG["h"] * ah)
            width = aw
        else:
            k = unit * data.get("residentBoosts", {}).get(name, data.get("residentBoost", 1.0))
            x0, y0, x1, y1 = DAMLA_GLASS_BOX if name == "damla" and stage >= 4 else SPRITE_BOX[name]
            c = (feet[0] + (x0 + x1) / 2 * k, feet[1] + (y0 + y1) / 2 * k, (x1 - x0) / 2 * k * 0.95, (y1 - y0) / 2 * k * 0.95)
            width = (x1 - x0) * k
        out[name] = {"feet": feet, "ellipse": (c[0], c[1], c[2] * SHRINK, c[3] * SHRINK), "width": width}
    return out


def ellipse_mask(shape, e) -> np.ndarray:
    h, w = shape
    yy, xx = np.mgrid[0:h, 0:w]
    return ((xx - e[0]) / max(e[2], 1e-6)) ** 2 + ((yy - e[1]) / max(e[3], 1e-6)) ** 2 <= 1


def polygon_mask(shape, pts) -> np.ndarray:
    h, w = shape
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).polygon([tuple(p) for p in pts], fill=255)
    return np.asarray(img) > 127


def lab_of(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    return lab[..., 0], np.hypot(lab[..., 1], lab[..., 2])


def lab_ab(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    return lab[..., 1], lab[..., 2]


def hue_deg(a: float, b: float) -> float:
    return float(np.degrees(np.arctan2(b, a)))


def trimmed_mean(v: np.ndarray) -> float:
    lo, hi = np.percentile(v, [25, 75])
    return float(v[(v >= lo) & (v <= hi)].mean())


def measure(rgb: np.ndarray, data: dict, stage: int = 0) -> dict:
    """Per character: body mean L*, C*, the lawn's, and the differences."""
    h, w = rgb.shape[:2]
    L, C = lab_of(rgb)
    A, B = lab_ab(rgb)
    m, fx, fy = frame_map(data, w)
    walk = polygon_mask((h, w), [(fx(x), fy(y)) for x, y in data["walkable"]])
    chars = characters(data, w, stage)
    yy, xx = np.mgrid[0:h, 0:w]
    near_any = np.zeros((h, w), bool)
    for c in chars.values():
        ex, ey, rx, ry = c["ellipse"]
        near_any |= ((xx - ex) ** 2 + (yy - ey) ** 2) <= (c["width"] * RING[0]) ** 2
    out = {}
    for name, c in chars.items():
        body = ellipse_mask((h, w), c["ellipse"])
        ex, ey = c["ellipse"][:2]
        d2 = (xx - ex) ** 2 + (yy - ey) ** 2
        ring = walk & ~near_any & (d2 >= (c["width"] * RING[0]) ** 2) & (d2 <= (c["width"] * RING[1]) ** 2)
        if body.sum() < 20 or ring.sum() < 200:
            raise SystemExit(f"{name}: the body ({int(body.sum())} px) or its lawn ({int(ring.sum())} px) is empty: wrong frame size?")
        bl, bc = float(L[body].mean()), float(C[body].mean())
        ll, lc = trimmed_mean(L[ring]), trimmed_mean(C[ring])
        out[name] = {"body": [round(bl, 1), round(bc, 1)], "lawn": [round(ll, 1), round(lc, 1)],
                     "dL": round(bl - ll, 1), "dC": round(bc - lc, 1),
                     "p95": round(float(np.percentile(L[body], 95)), 1), "stone": round(float(np.percentile(L[ring], 95)), 1),
                     "hue": round(hue_deg(float(A[body].mean()), float(B[body].mean())), 1),
                     "lawnHue": round(hue_deg(float(A[ring].mean()), float(B[ring].mean())), 1)}
    return out


def in_band(result: dict, ref: dict | None = None) -> dict:
    """Per character: is it within TOL of its reference difference? (`ref` is the island's own
    root frame's `{name: (dL, dC)}`; Home's is the calibrated `REF`.)"""
    ref = ref or REF
    return {n: abs(r["dL"] - ref[n][0]) <= TOL_L and ref[n][1] - FLOOR_C <= r["dC"] <= CAP_C for n, r in result.items()}


def no_sticker(result: dict) -> dict:
    """Night: per character, is its top (L* p95) at or below the brightest lawn stone around it?"""
    return {n: r["p95"] <= r["stone"] for n, r in result.items()}


def wrap(deg: float) -> float:
    return (deg + 180.0) % 360.0 - 180.0


def pull(day_hue: float, hue: float, key: float) -> float:
    """How many degrees a hue moved toward the key light's hue from the day frame's."""
    return abs(wrap(day_hue - key)) - abs(wrap(hue - key))


def follows_hue(day: dict, golden: dict, character: str = "pofu", key: float | None = None) -> tuple[bool, float, float]:
    """Golden hour: does the character's hue follow the light? It does when it moves from the day
    frame's at least `HUE_FOLLOW` as far, in the same direction, as the lawn's (Pofu's fur sits on
    the lawn's side of the key), or, with the key light's CIELAB hue angle `key`, at least
    `HUE_FOLLOW` as far toward it as the lawn's does (an otter's brown sits on the other side
    of the golden key from the lawn's yellow-green, and both close in on it). Returns (ok, the
    character's shift, the lawn's shift) in degrees, the shifts signed by that rule; a lawn that
    moves under `HUE_MIN` degrees asks nothing."""
    c = wrap(golden[character]["hue"] - day[character]["hue"])
    l = wrap(golden[character]["lawnHue"] - day[character]["lawnHue"])
    if abs(l) < HUE_MIN:
        return True, round(c, 1), round(l, 1)
    if c * l > 0 and abs(c) >= HUE_FOLLOW * abs(l):
        return True, round(c, 1), round(l, 1)
    if key is not None:
        pc = pull(day[character]["hue"], golden[character]["hue"], key)
        pl = pull(day[character]["lawnHue"], golden[character]["lawnHue"], key)
        if pl >= HUE_MIN:
            return pc >= HUE_FOLLOW * pl, round(pc, 1), round(pl, 1)
    return False, round(c, 1), round(l, 1)


def key_hue(data: dict, light: str, stage: int) -> float | None:
    """The CIELAB hue angle of a state's key light (its stored `key` colour), or `None`."""
    states = data.get("harmony", {}).get(light, [])
    key = states[stage].get("key") if stage < len(states) else None
    if not key:
        return None
    a, b = lab_ab(np.array([[key]], np.float64))
    return hue_deg(float(a[0, 0]), float(b[0, 0]))


def overlay(rgb: np.ndarray, data: dict, path: Path, stage: int = 0) -> None:
    img = Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255 + 0.5))
    d = ImageDraw.Draw(img)
    for c in characters(data, rgb.shape[1], stage).values():
        ex, ey, rx, ry = c["ellipse"]
        d.ellipse([ex - rx, ey - ry, ex + rx, ey + ry], outline=(255, 0, 255), width=3)
    img.save(path)


def stage_of(stem: str) -> int:
    """The story stage in a Çağlayan frame's name (`caglayan-plate-full-s4-golden`), else 0."""
    m = re.search(r"-s(\d)-", stem + "-")
    return int(m.group(1)) if m else 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("frames", nargs="+")
    ap.add_argument("--json", action="store_true", help="print JSON")
    ap.add_argument("--overlay", help="write each frame with the measured regions drawn to this folder")
    ap.add_argument("--island", default="home", help="the plate island the frames show (Resources/Plates/plate-<island>.json)")
    ap.add_argument("--reference", help="a substring of the frame that is the island's own root (Çağlayan: -s4-day): "
                    "its (dL*, dC*) is the band's anchor instead of Home's calibrated REF, and golden hue follows it "
                    "(Home's night frames default to `l10-night` when it is among the frames; `--reference l10-night` for all)")
    ap.add_argument("--plate-json")
    args = ap.parse_args(argv)
    data = json.loads(Path(args.plate_json or PLATES / f"plate-{args.island}.json").read_text())
    report, ok = {}, True
    results = {}
    for f in args.frames:
        rgb = np.asarray(Image.open(f).convert("RGB"), np.float64) / 255
        stem = Path(f).stem
        results[stem] = measure(rgb, data, stage_of(stem))
        if args.overlay:
            Path(args.overlay).mkdir(parents=True, exist_ok=True)
            overlay(rgb, data, Path(args.overlay) / f"{stem}.png", stage_of(stem))
    anchor = args.reference or ("l10-day" if args.island == "home" else None)
    day = next((r for s, r in results.items() if anchor and anchor in s), None)
    ref = {n: (r["dL"], r["dC"]) for n, r in day.items()} if day is not None and args.reference else None
    # Home's nights are measured against the level-10 night frame's own differences (a night lawn is
    # nearly grey and the day's calibration cannot hold it): `l10-night`, when it is among the frames.
    night = next((r for s, r in results.items() if "l10-night" in s), None) if args.island == "home" and not args.reference else None
    night_ref = {n: (r["dL"], r["dC"]) for n, r in night.items()} if night is not None else None
    for stem, r in results.items():
        band = in_band(r, night_ref if "night" in stem and night_ref else ref)
        rep = {"characters": r, "inBand": band}
        ok &= all(band.values())
        if "night" in stem:
            rep["noSticker"] = no_sticker(r)
            ok &= all(rep["noSticker"].values())
        report[stem] = rep
    for stem, r in results.items():
        if "golden" in stem and day is not None:
            good, c, l = follows_hue(day, r, "pofu" if "pofu" in r else next(iter(r)), key_hue(data, "golden", stage_of(stem)))
            report[stem]["hueFollow"] = {"ok": good, "furShift": c, "lawnShift": l}
            ok &= good
    if args.json:
        print(json.dumps(report, indent=1))
    else:
        first = next(iter(report.values()))["characters"] if report else {"pofu": 0}
        who = "pofu" if "pofu" in first else next(iter(first))
        for name, rep in report.items():
            print(name)
            for c, r in rep["characters"].items():
                extra = f" | p95 {r['p95']:5.1f} stone {r['stone']:5.1f}" + ("" if rep.get("noSticker", {}).get(c, True) else " STICKER") if "noSticker" in rep else ""
                print(f"  {c:7s} body L* {r['body'][0]:5.1f} C* {r['body'][1]:5.1f} | lawn L* {r['lawn'][0]:5.1f} C* {r['lawn'][1]:5.1f}"
                      f" | dL* {r['dL']:+5.1f} dC* {r['dC']:+5.1f} {'ok' if rep['inBand'][c] else 'OUT OF BAND'}{extra}")
            if "hueFollow" in rep:
                h = rep["hueFollow"]
                print(f"  {who} fur hue shift {h['furShift']:+.1f} deg vs lawn {h['lawnShift']:+.1f} deg: {'ok' if h['ok'] else 'DOES NOT FOLLOW THE LIGHT'}")
    print(f"harmony: {'ok' if ok else 'out of band'} (dL* within {TOL_L} of the reference's, dC* in [its dC* - {FLOOR_C}, +{CAP_C}]; "
          f"night: character L* p95 <= the brightest lawn stone; golden: fur hue follows the lawn's by {HUE_FOLLOW:.0%})")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
