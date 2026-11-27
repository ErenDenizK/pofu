#!/usr/bin/env python3
"""Fit one water outline per pond look (day looks: world-home-look-pond-<n>-day).

The outline is the look's own water: opaque, blue pixels, eroded so the feather sits inside
the shore, minus every solid (pier, boat, islet, bank) grown by a margin, holes filled (the
shader keeps lily pads and petals still by colour). Prints the `water` entries for
plate-home.json, in plate pixels. Usage: pond_water.py [--write plate-home.json]
"""
import json, sys
from pathlib import Path
import cv2, numpy as np
from PIL import Image
import pillow_heif
pillow_heif.register_heif_opener()

ROOT = Path(__file__).resolve().parents[2] / "Packages/PofuKit/Sources/PofuWorld/Resources"
BOX = (4.0, 736.0)  # the look's top left, plate px; density 2
DENSITY = 2.0
BUDGET = 0.05

def fit(n, inset=7, margin=5, solid_open=14):
    p = ROOT / f"World.xcassets/world-home-look-pond-{n}-day.imageset/world-home-look-pond-{n}-day.heic"
    im = np.array(Image.open(p).convert("RGBA")).astype(int)
    r, g, b, a = im[..., 0], im[..., 1], im[..., 2], im[..., 3]
    k = lambda px: cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * int(px) + 1,) * 2)
    opaque = (a > 250).astype(np.uint8)
    warm = (r - b > 5)
    leaf = (g - b > -4) & (g - r > 8)
    white = np.minimum(np.minimum(r, g), b) > 150
    thing = ((warm | leaf | white) & (opaque > 0)).astype(np.uint8)
    # Small things in the water (pads, petals, a lamp's reflection) are the shader's to keep still by
    # colour; only the big solids (pier, boat, islet, bank, pavilion, big pads) are cut out.
    solid = cv2.morphologyEx(thing, cv2.MORPH_OPEN, k(solid_open))
    hole = cv2.dilate(solid, k(margin * DENSITY))
    water = opaque & (1 - hole)
    m = cv2.morphologyEx(water, cv2.MORPH_OPEN, k(4))
    m = cv2.erode(m, k(inset * DENSITY))
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, k(4))
    cnt, lab, stats, _ = cv2.connectedComponentsWithStats(m)
    order = sorted(range(1, cnt), key=lambda i: -stats[i, cv2.CC_STAT_AREA])
    out = []
    for rank, i in enumerate(order):
        if stats[i, cv2.CC_STAT_AREA] < 0.15 * stats[order[0], cv2.CC_STAT_AREA]:
            break
        c = ((lab == i) * 255).astype(np.uint8)
        c = cv2.GaussianBlur(c, (0, 0), 3) > 127
        cs, _ = cv2.findContours(c.astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        c = cv2.approxPolyDP(max(cs, key=cv2.contourArea), 1.6, True)[:, 0, :]
        poly = [[round(BOX[0] + x / DENSITY, 1), round(BOX[1] + y / DENSITY, 1)] for x, y in c]
        xs = [q[0] for q in poly]
        mid_y = round(sum(q[1] for q in poly) / len(poly))
        out.append({"id": f"pond-look-{n}" + ("" if rank == 0 else f"-{rank + 1}"), "station": "pond", "look": n,
                    "polygon": poly, "feather": 3.0,
                    "flow": [[round(min(xs) + 10), mid_y], [round(max(xs) - 10), mid_y + 8]],
                    "speed": 1.0, "ripple": 1.2, "period": 3.0, "glint": 0.12})
    return out

def area(poly):
    s = 0
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        s += a[0] * b[1] - b[0] * a[1]
    return abs(s) / 2

if __name__ == "__main__":
    out = [w for n in range(1, 6) for w in fit(n)]
    for o in out:
        print(o["id"], len(o["polygon"]), "pts area", round(area(o["polygon"])), "share", round(area(o["polygon"]) / (1015 * 792), 4), file=sys.stderr)
    if "--write" in sys.argv:
        path = Path(sys.argv[sys.argv.index("--write") + 1])
        d = json.loads(path.read_text())
        old = [w for w in d["water"] if not w["id"].startswith("pond-look-")]
        d["water"] = old + out
        path.write_text(json.dumps(d, separators=(",", ":"), ensure_ascii=False) + ("\n" if path.read_text().endswith("\n") else ""))
    else:
        print(json.dumps(out))
