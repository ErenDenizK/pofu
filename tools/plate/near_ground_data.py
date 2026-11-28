"""Writes (or rewrites) the `near` ground keys of plate-home.json (patch, foreground, dressing) from the built layers.

    python3 -I tools/plate/near_ground_data.py <World.xcassets> <plate-home.json>

The dressing is placed here, in plate pixels (foot, width), and each piece lists the stages whose lawn mask holds its foot,
so a piece never stands on a stone, a bed or the water of a stage that paints one there.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import pillow_heif
from PIL import Image

pillow_heif.register_heif_opener()

# art, foot x, foot y, width (plate px). Pofu's row is about 860; at near rest a plate pixel is about 4.9 device pixels.
DRESSING = [
    ("near-tuft-daisy-1", 372, 868, 34), ("near-clover", 532, 872, 22), ("near-tuft-plain-1", 572, 852, 40),
    ("near-pebbles-2", 566, 882, 30), ("near-stool", 598, 876, 38), ("near-tuft-plain-2", 598, 882, 32),
    ("near-clover", 596, 858, 20), ("near-pebbles-3", 415, 902, 30), ("near-tuft-daisy-2", 448, 897, 36),
    ("near-tuft-plain-2", 432, 944, 36), ("near-tuft-plain-1", 412, 888, 34),
]
STAGES = range(10)
# The strip's art is neutral lawn at this colour (near_ground.py `STRIP_BASE`); each painted state multiplies it by its own
# lawn, the median colour of the mask's grass in plate rows LIP_ROWS (the lawn just above the front lip), stage 0 of that state.
STRIP_BASE = (0.95, 0.95, 0.50)
LIP_ROWS = (960, 985)
# What the render does to the strip, measured on the real frames (the strip's bottom in path-near-pofu*, first CI run of this
# branch, with each state's lawn as the multiply): the rendered colour over the expected one, per channel. The tint divides it out.
RENDER = {"day": (0.667 / 0.706, 0.657 / 0.729, 0.372 / 0.306), "golden": (0.710 / 0.745, 0.639 / 0.691, 0.460 / 0.384),
          "night": (0.442 / 0.455, 0.476 / 0.525, 0.458 / 0.400), "autumn-day": (0.739 / 0.764, 0.616 / 0.643, 0.255 / 0.141)}
RENDER["autumn-night"] = RENDER["autumn-day"]
TINT_STATES = {"day": "world-home-plate-day-0", "golden": "world-home-plate-golden-0", "night": "world-home-plate-night-0",
               "autumn-day": "world-home-plate-autumn-day-0", "autumn-night": "world-home-plate-autumn-night-0"}


def strip_tints(assets: Path, crops: dict, masks: dict) -> dict:
    """`near.foreground.tint`: per state key, the multiply that takes the strip's neutral lawn to that state's lawn above the lip."""
    out = {}
    for key, art in TINT_STATES.items():
        cx, cy = crops[key][0][:2]
        plate = np.asarray(Image.open(assets / f"{art}.imageset/{art}.heic").convert("RGB")).astype(np.float32) / 255
        mask = masks[0] if not key.startswith("autumn") else np.asarray(Image.open(assets / "world-near-lawn-mask-autumn-0.imageset/world-near-lawn-mask-autumn-0.heic"))[..., 3] / 255
        px = []
        for y in range(*LIP_ROWS):
            for x in range(260, 780):
                if mask[int((y - 790) / 2), int(x / 2)] >= 0.9:
                    yy, xx = (y - cy) * 2, (x - cx) * 2
                    if 0 <= yy < plate.shape[0] and 0 <= xx < plate.shape[1]:
                        px.append(plate[yy, xx])
        lawn = np.median(np.array(px), axis=0)
        out[key] = [round(float(min(c / r / b, 1.0)), 3) for c, r, b in zip(lawn, RENDER[key], STRIP_BASE)]
    return out


def main(assets: Path, plate_json: Path) -> None:
    def size(art: str) -> tuple[int, int]:
        return Image.open(assets / f"world-{art}.imageset/world-{art}.heic").size

    masks = {s: np.asarray(Image.open(assets / f"world-near-lawn-mask-{s}.imageset/world-near-lawn-mask-{s}.heic"))[..., 3] / 255 for s in STAGES}
    out = []
    for art, x, y, w in DRESSING:
        sw, sh = size(art)
        stages = [
            s for s in STAGES
            if all(masks[s][int((y - 6 - 790) / 2), int(xx / 2)] >= 0.5 for xx in (x - w * 0.3, x, x + w * 0.3))
        ]
        if not stages:
            continue
        piece = {"art": f"world-{art}", "at": [x, y], "footY": y, "width": w, "height": round(w * sh / sw, 1), "shadow": 0.6 if "stool" in art or "pebbles" in art else 0.35}
        if len(stages) < len(STAGES):
            piece["stages"] = stages
        out.append(piece)
    out.sort(key=lambda d: (d["at"][1], d["at"][0]))
    new = {
        "patch": {"detail": "world-near-lawn-detail", "mask": "world-near-lawn-mask", "maskBox": [0, 790, 1024, 1010], "tile": 200, "rows": [795, 825, 905, 960], "fadeIn": [3.2, 4.2], "night": 0.5, "nightTone": 0.12},
        "foreground": {"art": "world-near-foreground", "x": -80, "count": 4, "width": 320, "height": 345, "top": 920, "fadeIn": [3.2, 4.2],
                       "tint": strip_tints(assets, json.loads(plate_json.read_text())["plateCrop"], masks)},
        "dressing": out,
    }
    s = plate_json.read_text()
    start = s.index('"near":') + len('"near":')
    near, end = json.JSONDecoder().raw_decode(s, start)
    near.update(new)
    s = s[:start] + json.dumps(near, separators=(",", ":")) + s[end:]
    json.loads(s)
    plate_json.write_text(s)
    for d in out:
        print(d["art"], d["at"], d.get("stages", "all"))


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
