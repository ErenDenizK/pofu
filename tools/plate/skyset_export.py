#!/usr/bin/env python3
"""Ship a sky set (`split.py`) to the app: HEIC imagesets and `Plates/skyset-<island>.json`.

    python3 -I tools/plate/skyset_export.py home [--light day|golden|night|all]

The split writes full-size layers under `design/art/plates/<island>/sky/<light>/`. The app draws them
at the Home framing (1206 px wide screen, the island 1.15 screens wide, so about 0.68 screen px per
master px), so the soft cloud layers are stored smaller than the master (`SCALES`) to fit the texture
budget (9 MB, ASTC one byte a pixel, per state, `PlateMath.budgetOK`); the island, which carries the
detail, keeps its full size. The layer pixels are never graded, only resampled:

  sky     the 1/8 gradient plus 64 source pixels of replicated edge on every side, so the picture
          runs past the plate's top, bottom and sides (the camera sees more than the plate)
  sea     its bottom rows mirrored 420 master px past the plate (the old backdrop did the same)
  stars   night only: each star the sky layer already has, as its own light above the local sky,
          in three groups that the app brightens at different beats; nothing is drawn by code
  others  resampled with premultiplied alpha; the island's HEIC is copied byte for byte

`skyset-<island>.json` carries, per light, the draw order, each layer's place and size in master
pixels, its motion (the one source of the motion constants: `PofuWorld/Sky/SkySet.swift` reads it and
`skyset_render.py` renders the same frames offline), and the state's texture bytes.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"
RESOURCES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
JSON_DIR = RESOURCES / "Plates"
BUDGET = 9_000_000

#: Stored size against the master, per layer (the island is 1).
SCALES = {"far": 0.5, "mid": 0.6, "sea": 0.6, "isle_falls": 0.75, "isle_house": 0.75, "isle_dome": 0.75,
          "isle_crystal": 0.75, "whale": 0.75}
SKY_PAD = 64                 # source pixels of edge past the gradient (8 master px each)
SEA_PAD = 420                # master px of mirrored sea below the plate
STAR_ROWS = 100              # gradient rows (source px) that can hold stars
STAR_MAX_AREA = 14           # a blob this small (source px) is a star, not a cloud's edge
STAR_GROUPS = 3

#: The motion, in screen px at the 1206 px reference screen (scaled by width / 1206 in the app).
#: `drift`: px/s along +x; tiles wrap, the whale wraps once fully off screen. `bob`: a vertical
#: sine of `amp` px and `period` s that starts at zero (so t = 0 is the painting), `sign` flips its
#: direction, which with the periods is the phase offset between layers. `twinkle`: a star group's
#: own light, 0 at t = 0, up to `peak` of itself, sin^2 over `period` s.
MOTION = {
    "far": {"drift": 4, "bob": {"amp": 3, "period": 8, "sign": 1}},
    "mid": {"drift": 9, "bob": {"amp": 3, "period": 8, "sign": -1}},
    "sea": {"drift": 14, "bob": {"amp": 3, "period": 8, "sign": 1}},
    "isle_falls": {"bob": {"amp": 2, "period": 6.5, "sign": 1}},
    "isle_house": {"bob": {"amp": 2, "period": 7.5, "sign": -1}},
    "isle_dome": {"bob": {"amp": 2, "period": 6, "sign": 1}},
    "isle_crystal": {"bob": {"amp": 2, "period": 8, "sign": -1}},
    "whale": {"drift": 5, "bob": {"amp": 2, "period": 9, "sign": 1}},
}
TWINKLE = [{"peak": 0.9, "period": 3.1}, {"peak": 0.9, "period": 4.3}, {"peak": 0.9, "period": 5.7}]
REFERENCE_WIDTH = 1206


def asset_name(island: str, layer: str, light: str) -> str:
    return f"world-{island}-sky-{layer.replace('_', '-')}-{light}-0"


def _premult_resize(rgba: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """Resize straight RGBA (float 0..1) through premultiplied colour, so no dark fringe."""
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    out = cv2.resize(pre, size, interpolation=cv2.INTER_AREA)
    a = out[..., 3:4]
    out[..., :3] = np.where(a > 1e-4, out[..., :3] / np.maximum(a, 1e-4), 0)
    return out.clip(0, 1)


def _write(arr: np.ndarray, folder: Path, name: str, *, copy: Path | None = None) -> int:
    """One imageset with a HEIC; returns its pixel count (the texture budget's unit)."""
    d = ASSETS / f"{name}.imageset"
    if d.exists():
        shutil.rmtree(d)
    d.mkdir(parents=True)
    dst = d / f"{name}.heic"
    if copy is not None:
        shutil.copyfile(copy, dst)
    else:
        heic.save(Image.fromarray(np.uint8(arr * 255 + 0.5), "RGBA"), dst)
    (d / "Contents.json").write_text(json.dumps(
        {"images": [{"filename": dst.name, "idiom": "universal"}], "info": {"author": "xcode", "version": 1}},
        indent=2) + "\n")
    with heic.open_image(dst) as im:
        return im.width * im.height


def find_stars(sky: np.ndarray, hand: dict, light: str) -> np.ndarray:
    """Per star blob of the (straight RGB 0..1) gradient, its own light above the local sky, in
    `STAR_GROUPS` arrays (rows 0..STAR_ROWS). Blobs larger than a star, the fixed moon box and
    everything below the star rows are left out."""
    bg = cv2.medianBlur(np.uint8(sky * 255 + 0.5), 9).astype(np.float32) / 255
    diff = np.clip(sky - bg, 0, 1)
    peak = diff.max(-1)
    k = 8                                                   # source px per master px
    for x0, y0, x1, y1 in hand["lights"][light].get("fixedSky", []):
        diff[y0 // k: y1 // k + 2, x0 // k: x1 // k + 2] = 0
        peak[y0 // k: y1 // k + 2, x0 // k: x1 // k + 2] = 0
    peak[STAR_ROWS:] = 0
    lab, n = ndimage.label(peak > 0.03)
    groups = np.zeros((STAR_GROUPS,) + sky.shape, np.float32)
    count = 0
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() > STAR_MAX_AREA:
            continue
        ring = ndimage.binary_dilation(m, iterations=1)
        groups[count % STAR_GROUPS][ring] = diff[ring]
        count += 1
    return groups[:, :STAR_ROWS]


def export_light(island: str, light: str, hand: dict) -> dict:
    src = PLATES / island / "sky" / light
    man = json.loads((src / "manifest.json").read_text())
    w, h = man["size"]
    layers, pixels = [], 0

    def add(entry: dict, px: int) -> None:
        nonlocal pixels
        pixels += px
        layers.append(entry)

    for lay in man["layers"]:
        lid = lay["id"]
        name = asset_name(island, lid, light)
        img = heic.open_image(src / lay["file"]).convert("RGBA")
        arr = np.asarray(img, np.float32) / 255
        x, y = lay["pos"]
        dw, dh = lay["size"]
        entry = {"id": lid, "role": {"gradient": "sky", "tile": "tile", "sprite": "sprite", "island": "island"}[lay["kind"]],
                 "asset": name}
        if lay["kind"] == "gradient":
            padded = np.pad(arr, ((SKY_PAD, SKY_PAD), (SKY_PAD, SKY_PAD), (0, 0)), mode="edge")
            k = w // arr.shape[1]
            entry.update(pos=[-SKY_PAD * k, -SKY_PAD * k], size=[padded.shape[1] * k, padded.shape[0] * k])
            add(entry, _write(padded, src, name))
            if light == "night":
                stars = find_stars(arr[..., :3], hand, light)
                for g in range(STAR_GROUPS):
                    sname = asset_name(island, f"stars{g}", light)
                    rgba = np.concatenate([stars[g], np.ones(stars[g].shape[:2] + (1,), np.float32)], -1)
                    s_entry = {"id": f"stars{g}", "role": "stars", "asset": sname, "pos": [0, 0],
                               "size": [arr.shape[1] * k, STAR_ROWS * k], "twinkle": TWINKLE[g]}
                    add(s_entry, _write(rgba, src, sname))
            continue
        motion = MOTION.get(lid, {})
        if lay["kind"] == "island":
            entry.update(pos=[x, y], size=[dw, dh])
            add(entry, _write(arr, src, name, copy=src / lay["file"]))
            continue
        scale = SCALES[lid]
        if lid == "sea":
            mirrored = arr[::-1][:SEA_PAD]
            arr = np.concatenate([arr, mirrored], 0)
            dh += SEA_PAD
        small = _premult_resize(arr, (round(arr.shape[1] * scale), round(arr.shape[0] * scale)))
        entry.update(pos=[x, y], size=[dw, dh], **motion)
        if lay["kind"] == "tile":
            entry["tileWidth"] = lay["tileWidth"]
        if lid == "whale":
            entry["role"] = "whale"
        add(entry, _write(small, src, name))
    return {"layers": layers, "pixels": pixels, "master": [w, h], "islandBox": man["islandBox"],
            "plate": man["source"]["plate"]}


def state_bytes(island: str, light: str, sky_pixels: int) -> int:
    """The sky-set state's textures: the set, the island cut for the Map and the occluders (the
    plate and its backdrop are not loaded while a sky set draws)."""
    total = sky_pixels
    for folder in ASSETS.glob(f"world-{island}-*-{light}-0.imageset"):
        if re.match(rf"world-{island}-(plate|backdrop|sky-)", folder.name):
            continue
        for f in folder.iterdir():
            if f.suffix == heic.SUFFIX:
                with heic.open_image(f) as im:
                    total += im.width * im.height
    return total


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("--light", default="all")
    a = ap.parse_args(argv)
    hand = json.loads((PLATES / a.island / "sky" / "sky.json").read_text())
    lights = ["day", "golden", "night"] if a.light == "all" else [a.light]
    out_path = JSON_DIR / f"skyset-{a.island}.json"
    data = json.loads(out_path.read_text()) if out_path.exists() else {"lights": {}}
    data.update(island=a.island, version=1, master=hand["size"], referenceWidth=REFERENCE_WIDTH,
                note="Written by tools/plate/skyset_export.py. Positions and sizes are master pixels "
                     "(2048 x 3072); motion is screen px at the 1206 px reference screen.")
    for light in lights:
        res = export_light(a.island, light, hand)
        res["textureBytes"] = state_bytes(a.island, light, res["pixels"])
        data["lights"][light] = res
        print(f"{light}: {res['pixels']:,} sky px, state {res['textureBytes']:,} bytes "
              f"({'ok' if res['textureBytes'] <= BUDGET else 'OVER BUDGET'})")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    return 0 if all(data["lights"][l]["textureBytes"] <= BUDGET for l in lights) else 1


if __name__ == "__main__":
    raise SystemExit(main())
