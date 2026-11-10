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
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
from process_assets import srgb_to_lab  # noqa: E402

PLATE_JSON = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "Plates" / "plate-home.json"
SCREEN_W = 402.0

#: The art's boxes in art units (`WorldArt+Generated.swift`, sharp): (min x, min y, max x, max y).
SPRITE_BOX = {"mochi": (-15.2, -23.141, 15.2, 0.192), "findik": (-14.291, -26.835, 14.375, 0.232)}
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


def characters(data: dict, w: int) -> dict:
    """Each character's feet, body ellipse (cx, cy, rx, ry) and width, in frame pixels."""
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
            x0, y0, x1, y1 = SPRITE_BOX[name]
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


def measure(rgb: np.ndarray, data: dict) -> dict:
    """Per character: body mean L*, C*, the lawn's, and the differences."""
    h, w = rgb.shape[:2]
    L, C = lab_of(rgb)
    A, B = lab_ab(rgb)
    m, fx, fy = frame_map(data, w)
    walk = polygon_mask((h, w), [(fx(x), fy(y)) for x, y in data["walkable"]])
    chars = characters(data, w)
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


def in_band(result: dict) -> dict:
    """Per character: is it within TOL of its reference difference?"""
    return {n: abs(r["dL"] - REF[n][0]) <= TOL_L and REF[n][1] - FLOOR_C <= r["dC"] <= CAP_C for n, r in result.items()}


def no_sticker(result: dict) -> dict:
    """Night: per character, is its top (L* p95) at or below the brightest lawn stone around it?"""
    return {n: r["p95"] <= r["stone"] for n, r in result.items()}


def wrap(deg: float) -> float:
    return (deg + 180.0) % 360.0 - 180.0


def follows_hue(day: dict, golden: dict, character: str = "pofu") -> tuple[bool, float, float]:
    """Golden hour: does the character's hue move from the day frame's at least `HUE_FOLLOW` as far,
    in the same direction, as the lawn's? Returns (ok, character shift, lawn shift) in degrees; a lawn
    that moves under `HUE_MIN` degrees asks nothing."""
    c = wrap(golden[character]["hue"] - day[character]["hue"])
    l = wrap(golden[character]["lawnHue"] - day[character]["lawnHue"])
    if abs(l) < HUE_MIN:
        return True, round(c, 1), round(l, 1)
    return c * l > 0 and abs(c) >= HUE_FOLLOW * abs(l), round(c, 1), round(l, 1)


def overlay(rgb: np.ndarray, data: dict, path: Path) -> None:
    img = Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255 + 0.5))
    d = ImageDraw.Draw(img)
    for c in characters(data, rgb.shape[1]).values():
        ex, ey, rx, ry = c["ellipse"]
        d.ellipse([ex - rx, ey - ry, ex + rx, ey + ry], outline=(255, 0, 255), width=3)
    img.save(path)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("frames", nargs="+")
    ap.add_argument("--json", action="store_true", help="print JSON")
    ap.add_argument("--overlay", help="write each frame with the measured regions drawn to this folder")
    ap.add_argument("--plate-json", default=str(PLATE_JSON))
    args = ap.parse_args(argv)
    data = json.loads(Path(args.plate_json).read_text())
    report, ok = {}, True
    results = {}
    for f in args.frames:
        rgb = np.asarray(Image.open(f).convert("RGB"), np.float64) / 255
        r = measure(rgb, data)
        stem = Path(f).stem
        band = in_band(r)
        rep = {"characters": r, "inBand": band}
        ok &= all(band.values())
        if "night" in stem:
            rep["noSticker"] = no_sticker(r)
            ok &= all(rep["noSticker"].values())
        results[stem] = r
        report[stem] = rep
        if args.overlay:
            Path(args.overlay).mkdir(parents=True, exist_ok=True)
            overlay(rgb, data, Path(args.overlay) / f"{stem}.png")
    day = next((r for s, r in results.items() if "l10-day" in s), None)
    for stem, r in results.items():
        if "golden" in stem and day is not None:
            good, c, l = follows_hue(day, r)
            report[stem]["hueFollow"] = {"ok": good, "furShift": c, "lawnShift": l}
            ok &= good
    if args.json:
        print(json.dumps(report, indent=1))
    else:
        for name, rep in report.items():
            print(name)
            for c, r in rep["characters"].items():
                extra = f" | p95 {r['p95']:5.1f} stone {r['stone']:5.1f}" + ("" if rep.get("noSticker", {}).get(c, True) else " STICKER") if "noSticker" in rep else ""
                print(f"  {c:7s} body L* {r['body'][0]:5.1f} C* {r['body'][1]:5.1f} | lawn L* {r['lawn'][0]:5.1f} C* {r['lawn'][1]:5.1f}"
                      f" | dL* {r['dL']:+5.1f} dC* {r['dC']:+5.1f} {'ok' if rep['inBand'][c] else 'OUT OF BAND'}{extra}")
            if "hueFollow" in rep:
                h = rep["hueFollow"]
                print(f"  pofu fur hue shift {h['furShift']:+.1f} deg vs lawn {h['lawnShift']:+.1f} deg: {'ok' if h['ok'] else 'DOES NOT FOLLOW THE LIGHT'}")
    print(f"harmony: {'ok' if ok else 'out of band'} (dL* within {TOL_L} of the level-10 day's, dC* in [its dC* - {FLOOR_C}, +{CAP_C}]; "
          f"night: character L* p95 <= the brightest lawn stone; golden: fur hue follows the lawn's by {HUE_FOLLOW:.0%})")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
