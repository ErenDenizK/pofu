#!/usr/bin/env python3
"""Plate-first, the risky mechanisms as frames: occlusion behind a painted object, a sway mask, an
upgrade inserted between stages, a tap highlight, and a character in a painted object's shadow.

All on the healed Revontuli stand-in (`x-revontuli-healed` t2), with the pilot's code sky and aurora.
Masks here are hand polygons in percent of the take; production masks come from `ingest.py` (see
docs/design/plate-islands.md). Prints the numbers each proof claims.

    python3 -I tools/plate/proofs.py OUT.jpg
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import pilot as P  # noqa: E402

K = 0.6  # work at 0.6 of the 1536 take (922 px), about the phone's close pose
TREE = [(72, 44.5), (71.5, 38), (74, 30), (77, 20), (80, 10), (83, 12), (86, 22), (89, 30), (91, 40), (89, 44.5)]
SAUNA = [(12, 46), (12, 30), (16, 26), (19, 20), (20, 13), (23, 13), (25, 20), (32, 22), (38, 28), (37, 40),
         (36, 47)]
BENCH = ("world-decor-bench", (10.5, 48.0), 6.0)  # U2: the snow by the sauna's left wall


def poly_mask(shape, pts) -> np.ndarray:
    h, w = shape[:2]
    m = np.zeros((h, w), np.uint8)
    cv2.fillPoly(m, [np.array([(x * w / 100, y * h / 100) for x, y in pts], np.int32)], 1)
    return m.astype(np.float64)


def base() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rgb, a = P.load_take("healed")
    size = (round(rgb.shape[1] * K), round(rgb.shape[0] * K))
    rgb = np.asarray(P.to_img(rgb).resize(size, Image.Resampling.LANCZOS), np.float64) / 255
    a = np.asarray(Image.fromarray(np.uint8(a * 255)).resize(size, Image.Resampling.LANCZOS), np.float64) / 255
    H, W = rgb.shape[:2]
    P.SS = 1
    sky = P.screen(P.sky(P.CELLS["night"], W, H), P.aurora(W, H, 1.0, 0.12))
    return rgb, a, sky


def over(bg, rgb, a):
    return rgb * a[..., None] + bg * (1 - a[..., None])


def sprite_on(canvas, plate, plate_a, name, feet_pct, width_pct, occluder=None):
    """A lit sprite with its contact pad, then the occluder's plate pixels back on top (it is behind)."""
    H, W = canvas.shape[:2]
    sw = round(width_pct / 100 * W)
    if name in P.SPRITES:
        spr = P.sprite(name, sw)
    else:
        im = Image.open(P.pale.ASSETS / f"{name}.imageset/{name}.png").convert("RGBA")
        bb = im.getbbox()
        im = im.crop(bb).resize((sw, round((bb[3] - bb[1]) * sw / (bb[2] - bb[0]))), Image.Resampling.LANCZOS)
        spr = np.asarray(im, np.float64) / 255
    fx, fy = round(feet_pct[0] / 100 * W), round(feet_pct[1] / 100 * H)
    lit, info = P.lit_from_plate(spr, plate, plate_a, (fx, fy), ((round(0.52 * W), round(0.18 * H)), (1.0, 0.8, 0.5), 1.0))
    out = canvas.copy()
    P.contact_pad(out, fx, fy, sw, info["ratio"])
    P.place(out, lit, fx, fy + round(0.02 * sw))
    if occluder is not None:
        out = over(out, plate, occluder * plate_a)
    return out, info["gain"]


def sway(plate, plate_a, sky, mask, amp_px: float):
    """Bend the masked object: horizontal shift growing with height above its foot, feathered edge."""
    H, W = plate_a.shape
    ys, xs = np.where(mask > 0)
    foot, top = ys.max(), ys.min()
    weight = np.clip((foot - np.arange(H)) / max(foot - top, 1), 0, 1) ** 1.6
    soft = ndimage.gaussian_filter(ndimage.binary_dilation(mask > 0, iterations=6).astype(float), 3)
    dx = amp_px * weight[:, None] * soft
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    mapx = (xx - dx).astype(np.float32)
    rgb2 = np.stack([cv2.remap(np.float32(plate[..., c]), mapx, yy, cv2.INTER_LINEAR) for c in range(3)], -1)
    a2 = cv2.remap(np.float32(plate_a), mapx, yy, cv2.INTER_LINEAR)
    return over(sky, rgb2.astype(np.float64), a2.astype(np.float64))


def highlight(frame, mask, plate_a, t: float = 1.0):
    """The tapped object: its pixels (polygon and plate alpha) lift 6 %, fading out toward its foot, and a
    warm rim glows along its silhouette against the sky only (never a line across the painted ground)."""
    obj = (mask > 0) & (plate_a > 0.5)
    ys = np.where(obj)[0]
    fade = np.clip((ys.max() - np.arange(obj.shape[0])) / (0.25 * (ys.max() - ys.min())), 0, 1)[:, None]
    m = ndimage.gaussian_filter(obj.astype(float), 1.0) * fade
    sky = plate_a < 0.5
    edge = ndimage.binary_dilation(obj, iterations=3) & ~obj & sky
    edge = ndimage.gaussian_filter(edge.astype(float), 1.2) * fade
    out = frame + (1 - frame) * 0.06 * t * m[..., None]
    return P.screen(out, edge[..., None] * np.array([1.0, 0.88, 0.6]) * 1.2 * t)


def crop(img, box):
    h, w = img.shape[:2]
    x0, y0, x1, y1 = box
    return img[int(y0 * h / 100):int(y1 * h / 100), int(x0 * w / 100):int(x1 * w / 100)]


def main(argv: list[str] | None = None) -> int:
    out = Path((argv or sys.argv[1:])[0])
    plate, a, sky = base()
    frame = over(sky, plate, a)
    tree, sauna = poly_mask(a.shape, TREE), poly_mask(a.shape, SAUNA)
    nums = {}

    # 1. Occlusion: Pofu walks behind the spruce (feet above its foot line), then in front of it.
    behind, g_behind = sprite_on(frame, plate, a, "pofu", (73.5, 42.5), 9, occluder=tree)
    front, g_front = sprite_on(frame, plate, a, "pofu", (80, 52), 9)
    # 2. Light from the plate: Pofu in the sauna's lee (cooler, darker) against the open snow.
    lee, g_lee = sprite_on(frame, plate, a, "pofu", (27, 50.5), 9)
    nums["gain behind tree / front / sauna lee"] = [g_behind, g_front, g_lee]
    # 3. Sway: the spruce bends 0 and 5 px at the top (phone px at this scale), the trunk stays.
    s0, s1 = frame, sway(plate, a, sky, tree, 5.0)
    diff = np.abs(P.srgb_to_lab(s1)[..., 0] - P.srgb_to_lab(s0)[..., 0])
    nums["sway: moved pixels outside the tree's dilated mask"] = int(((diff > 2) & (ndimage.binary_dilation(tree > 0, iterations=12) == 0)).sum())
    heat = np.clip(diff[..., None] / 20, 0, 1) * np.array([1.0, 0.4, 0.2]) + s0 * 0.35
    # 4. Upgrade insert between stages: the bench as a harmonised sprite (plate light, contact pad).
    bench, g_bench = sprite_on(frame, plate, a, BENCH[0], BENCH[1], BENCH[2])
    nums["bench gain"] = g_bench
    # 5. Tap highlight on the sauna.
    tap = highlight(frame, sauna, a)

    zoom_tree, zoom_sauna = (62, 2, 98, 62), (0, 6, 44, 60)
    rows = [
        [(P.to_img(crop(behind, zoom_tree)), "occlusion: Pofu behind the spruce\n(occluder mask redrawn over the sprite)"),
         (P.to_img(crop(front, zoom_tree)), "the same Pofu in front of it\n(feet below the spruce's foot line)"),
         (P.to_img(crop(lee, zoom_sauna)), f"Pofu in the sauna's lee: light from the plate\ngain {g_lee} against open snow {g_front}")],
        [(P.to_img(crop(s1, zoom_tree)), "sway mask: spruce top +5 px\n(weight grows with height, trunk fixed)"),
         (P.to_img(crop(heat, zoom_tree)), f"what moved (|dL*|): only the tree\npixels moved outside its mask: {nums['sway: moved pixels outside the tree' + chr(39) + 's dilated mask']}"),
         (P.to_img(crop(bench, zoom_sauna)), "upgrade as a harmonised sprite insert: lit and\npadded, but no snow on it: reads foreign")],
        [(P.to_img(crop(frame, zoom_sauna)), "tap: before"),
         (P.to_img(crop(tap, zoom_sauna)), "tap: the sauna lifts 6 % with a warm rim on its\nsilhouette (0.25 s, then fades)"),
         (P.to_img(crop(frame, zoom_sauna) * 0 + crop(sauna * (a > 0.5), zoom_sauna)[..., None] * 0.85 + 0.1), "the sauna's polygon (hit target\nand highlight mask, from ingest.py)")],
    ]
    P.ll.sheet(rows, out, title="Plate-first mechanisms on a painted plate (Revontuli healed stand-in)", cell_h=300, max_kb=600)
    print(json.dumps(nums, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
