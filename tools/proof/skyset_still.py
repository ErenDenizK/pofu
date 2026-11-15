"""A still of Home's sky set from the app's own layers (`Plates/skyset-home.json`), at rest, for the proof stills.

One camera for every layer (the set is Home's painting taken apart, so at rest it is the painting): a master pixel
is `s` device px, the master point `anchor` lands on the screen point `at`. The sky set's island layer is replaced
by the clean island cut (`island_matte`), its sea by the tall cloud floor (`cloud_floor`). Layers: sky gradient,
far clouds, the four far isles, the whale, mid clouds, the cloud sea, the island. Motion and painted details are
not drawn (they are identical in every proof that uses this).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cloud_floor  # noqa: E402
import island_matte  # noqa: E402
from _common import H, RESOURCES, W, Sprite, load_rgba  # noqa: E402


def draw_set(s: float, anchor: tuple[float, float], at: tuple[float, float], light: str = "day", stage: int = 0,
             island: bool = True) -> np.ndarray:
    """Premultiplied RGBA, H x W x 4, float32."""
    layers = json.loads((RESOURCES / "Plates" / "skyset-home.json").read_text())["lights"][light]["layers"]
    out = np.zeros((H, W, 4), np.float32)
    for spec in layers:
        role, (px, py), (sw, sh) = spec["role"], spec["pos"], spec["size"]
        if role == "stars":
            continue
        if role == "island":
            if not island:
                continue
            rgba, (x0, y0) = island_matte.island_layer(light, stage)
            sprite, px, py, sw, sh = Sprite(rgba), x0 * 2.0, y0 * 2.0, float(rgba.shape[1]), float(rgba.shape[0])
        elif role == "tile" and "-sky-sea-" in spec["asset"]:
            k = load_rgba(spec["asset"]).shape[0] / sh
            fl = cloud_floor.floor(light=light)
            sprite, sh = Sprite(fl), fl.shape[0] / k
        else:
            sprite = Sprite(load_rgba(spec["asset"]))
        x, y = at[0] + (px - anchor[0]) * s, at[1] + (py - anchor[1]) * s
        w, h = sw * s, sh * s
        if role == "sky":
            sprite.draw(out, x, y, w, h, replicate=True)
        elif role == "tile":
            sprite.draw(out, x, y, w, h, wrap_x=w)
        else:
            sprite.draw(out, x, y, w, h)
    return out
