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
        "patch": {"detail": "world-near-lawn-detail", "mask": "world-near-lawn-mask", "maskBox": [0, 790, 1024, 1010], "tile": 200, "rows": [795, 825, 905, 960], "fadeIn": [3.2, 4.2], "night": 0.5},
        "foreground": {"art": "world-near-foreground", "x": -80, "count": 4, "width": 320, "height": 345, "top": 920, "fadeIn": [3.2, 4.2]},
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
