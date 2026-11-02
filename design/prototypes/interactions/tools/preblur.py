#!/usr/bin/env python3
"""Pre-blurred depth-of-field variants for the interaction prototype.

This is the asset-pipeline step that the interaction spec recommends instead of
live blur: every world plate, vignette, and character gets two baked variants,
so depth of field at runtime is an opacity cross-fade between stacked images.

  soft  (.b1): Gaussian sigma 1.4 world units, stored at 1/2 resolution
  deep  (.b2): Gaussian sigma 4.0 world units, stored at 1/3 resolution

A world unit is a point at camera scale 1. Each source is padded by 3 sigma on
every side (blur bleeds outside the alpha), and the padding is written to
assets/blur-manifest.json as a fraction of the source size, so the page can
grow the blurred image's box by the same amount.

  python3 -I tools/preblur.py            (run from design/prototypes/interactions)

`app` mode builds the app's world art for `PofuWorld` with the same blur: it trims each master,
caps its resolution, bakes the soft and deep variants, cuts the home plate into depth bands, and
writes an Xcode asset catalog plus a generated Swift table of every image's box in world units.

  python3 -I design/prototypes/interactions/tools/preblur.py app   (from anywhere)
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(os.path.dirname(HERE), "assets")

# Source name -> width of its box in world units (from the page's BOX table).
UNITS = {
    "isle-home": 364, "isle-harbor": 268, "isle-stars": 244, "isle-hamam": 256, "isle-library": 244,
    "st-cay-2": 120, "st-cay-3": 120, "st-garden-3": 120, "st-garden-4": 120, "st-pond-2": 120,
    "st-windmill-2": 120, "st-workshop-2": 120,
    "neighbor-bunny": 27, "res-hog": 28, "pofu": 64, "cloud-a": 80, "cloud-b": 120,
}
# The home island plate is cut into depth bands (world y), so depth of field can vary across it.
# Each band keeps the full canvas; its alpha is the plate's alpha times a band mask. A band is
# opaque through the overlap with the band in front of it, and the front band fades in over it,
# so stacked back to front the bands recompose the plate without a seam.
PLATE = "isle-home"
PLATE_BOX_TOP, PLATE_BOX_H = -106.0, 288.0  # world units (BOX in app.js)
BANDS = [(-1e9, -50), (-50, 0), (0, 50), (50, 1e9)]
FEATHER = 10.0
LEVELS = {"b1": (1.4, 2), "b2": (4.0, 3), "b3": (9.0, 4)}  # name -> (sigma in world units, downscale); b3 feeds tilt-shift only


def blur_variant(src, sigma_px, down):
    pad = int(math.ceil(3 * sigma_px))
    big = Image.new("RGBA", (src.width + 2 * pad, src.height + 2 * pad), (0, 0, 0, 0))
    big.paste(src, (pad, pad))
    # Blur premultiplied colour so transparent edges do not bleed dark fringes.
    a = np.asarray(big, dtype=np.float32) / 255.0
    pre = a.copy()
    pre[..., :3] *= pre[..., 3:4]
    blurred = []
    for i in range(4):
        ch = Image.fromarray(np.uint8(np.clip(pre[..., i] * 255.0 + 0.5, 0, 255)), "L")
        blurred.append(np.asarray(ch.filter(ImageFilter.GaussianBlur(sigma_px)), dtype=np.float32) / 255.0)
    rgb = np.stack(blurred[:3], -1)
    alpha = blurred[3][..., None]
    rgb = np.where(alpha > 1e-4, rgb / np.maximum(alpha, 1e-4), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], -1)
    img = Image.fromarray(np.uint8(out * 255.0 + 0.5), "RGBA")
    w, h = max(1, round(img.width / down)), max(1, round(img.height / down))
    return img.resize((w, h), Image.LANCZOS), pad


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


# Atmospheric perspective, baked: lighter, cooler, less saturated with distance. Amount per source
# from its placement depth (the diorama's y; larger is nearer): clamp((40 - depth) / 220) * 0.38,
# and a flat 0.3 for the distant islands. Baked for every blur level, so runtime haze costs nothing.
HAZE_RGB = np.array([220, 235, 245], dtype=np.float32)
HAZE_DEPTH = {"st-windmill-2": -74, "st-workshop-2": -70, "st-garden-3": -4, "st-garden-4": -4, "st-cay-2": -2,
              "st-cay-3": -2, "st-pond-2": 18, "isle-home-band0": -78, "isle-home-band1": -25, "isle-home-band2": 25}
HAZE_FLAT = {"isle-harbor": 0.3, "isle-stars": 0.3, "isle-hamam": 0.3, "isle-library": 0.3}


def make_haze():
    amounts = {k: float(np.clip((40 - d) / 220, 0, 1) * 0.38) for k, d in HAZE_DEPTH.items()}
    amounts.update(HAZE_FLAT)
    for name, amt in amounts.items():
        for lvl in ("", "b1", "b2", "b3"):
            suffix = f".{lvl}" if lvl else ""
            a = np.asarray(Image.open(os.path.join(ASSETS, name + suffix + ".webp")).convert("RGBA"), dtype=np.float32)
            rgb = a[..., :3]
            grey = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
            rgb = rgb + (grey[..., None] - rgb) * (amt * 0.6)  # desaturate
            rgb = rgb + (HAZE_RGB - rgb) * amt  # lighten and cool toward the sky
            out = np.concatenate([np.clip(rgb, 0, 255), a[..., 3:]], -1)
            Image.fromarray(np.uint8(out + 0.5), "RGBA").save(os.path.join(ASSETS, f"{name}.hz{suffix}.webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"haze {name}: {amt:.2f}")
    return amounts


def make_bands(manifest):
    pads = manifest[PLATE]
    crops = {}
    for lvl in ("", "b1", "b2", "b3"):
        src = Image.open(os.path.join(ASSETS, PLATE + (f".{lvl}" if lvl else "") + ".webp")).convert("RGBA")
        a = np.asarray(src, dtype=np.float32)
        py = pads[lvl][1] if lvl else 0.0
        top = PLATE_BOX_TOP - py * PLATE_BOX_H
        span = PLATE_BOX_H * (1 + 2 * py)
        y = top + (np.arange(a.shape[0]) + 0.5) / a.shape[0] * span  # world y of each row
        for k, (s0, s1) in enumerate(BANDS):
            w = np.ones_like(y) if k == 0 else smoothstep(s0 - FEATHER, s0 + FEATHER, y)
            if s1 < 1e8:
                w = np.where(y <= s1 + FEATHER, w, 0.0)
            out = a.copy()
            out[..., 3] *= w[:, None]
            # Crop to the band's opaque rows (most of the canvas is empty), and record the crop as a
            # fraction of the image height so the page can place it: no overdraw of empty pixels.
            rows = np.where(out[..., 3].max(axis=1) > 0.5)[0]
            r0, r1 = int(rows[0]), int(rows[-1]) + 1
            crops.setdefault(f"{PLATE}-band{k}", {})[lvl or "s"] = [round(r0 / a.shape[0], 5), round(r1 / a.shape[0], 5)]
            name = f"{PLATE}-band{k}" + (f".{lvl}" if lvl else "")
            Image.fromarray(np.uint8(np.clip(out[r0:r1], 0, 255) + 0.5), "RGBA").save(os.path.join(ASSETS, name + ".webp"), "WEBP", quality=80 if not lvl else 72, method=6)
        print(f"bands for {PLATE}{'.' + lvl if lvl else ''}")
    for k in range(len(BANDS)):
        manifest[f"{PLATE}-band{k}"] = dict(pads, crop=crops[f"{PLATE}-band{k}"])


def main():
    manifest = {}
    for name, units in UNITS.items():
        path = os.path.join(ASSETS, name + ".webp")
        if not os.path.exists(path):
            print("missing", path, file=sys.stderr)
            return 1
        src = Image.open(path).convert("RGBA")
        ppu = src.width / units
        entry = {}
        for lvl, (sigma_u, down) in LEVELS.items():
            img, pad = blur_variant(src, sigma_u * ppu, down)
            img.save(os.path.join(ASSETS, f"{name}.{lvl}.webp"), "WEBP", quality=72, method=6)
            entry[lvl] = [round(pad / src.width, 4), round(pad / src.height, 4)]
        manifest[name] = entry
        print(f"{name}: {src.width}x{src.height}, {ppu:.2f} px/unit, pads {entry}")
    make_bands(manifest)
    manifest["_haze"] = {k: round(v, 3) for k, v in make_haze().items()}
    with open(os.path.join(ASSETS, "blur-manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1, sort_keys=True)
    return 0


# ------------------------------------------------------------------ app mode (PofuWorld)
#
# World units are points at camera scale 1 (game design §15). Each source names its anchor (the
# feet or the footprint centre) in source pixels and its scale in pixels per world unit. The app
# never shows a world image above camera scale 2.4 at 3x, so the sharp image is capped at
# APP_MAX_PPU pixels per unit; masters are never upscaled.

REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
APP_RESOURCES = os.path.join(REPO, "Packages", "PofuKit", "Sources", "PofuWorld", "Resources")
APP_CATALOG = os.path.join(APP_RESOURCES, "World.xcassets")
APP_SWIFT = os.path.join(REPO, "Packages", "PofuKit", "Sources", "PofuWorld", "Geometry", "WorldArt+Generated.swift")
APP_MAX_PPU = 7.5
APP_LEVELS = {"soft": (1.4, 2), "deep": (4.0, 3)}  # suffix -> (sigma in world units, downscale)
PROTO = os.path.join("design", "prototypes", "interactions", "assets")


def _st(name):
    # The prototype's station stand-ins: 600 x 660 for a 120 x 132 unit box, anchor 112 units down.
    return {"src": os.path.join(PROTO, name + ".webp"), "ppu": 5.0, "anchor": (300, 560)}


def _isle(name, box):
    # The prototype's island stand-ins for the map, with their BOX from app.js.
    return {"src": os.path.join(PROTO, name + ".webp"), "units": box[2] - box[0], "anchor_box": box}


APP_SOURCES = {
    # Batch 01 masters (design/art). The home plate's lawn spans x 50-1486 px for 350 units, centred
    # at (768, 441); it is cut into depth bands below. The app draws the lock-light bakes (WorldGrade
    # grades them at runtime); "softlock" also bakes the soft-lock masters as <name>--softlock, to
    # compare, until the founder has chosen (WorldLook.ArtSet).
    "island-main": {"src": "design/art/masters/island-main-s/island-main-s--lock-light.png", "ppu": 1436 / 350, "anchor": (768, 441),
                    "softlock": "design/art/masters/island-main-s/island-main-s.png"},
    "cay-1": {"src": "design/art/stations/cay-1/cay-1--lock-light.png", "ppu": 1024 / 120, "anchor": (512, 800),
              "softlock": "design/art/stations/cay-1/cay-1.png"},
    "mochi": {"src": "design/art/masters/mochi-base/mochi-base.png", "ppu": 871 / 30, "anchor": (511, 1349)},
    # Pofu's own art: only the blurred variants (the live CompanionView is the sharp one). 64 units
    # wide with the feet at the rig's ground point, so the variants register with the live view.
    "pofu": {"src": "Packages/PofuKit/Sources/PofuCompanion/Resources/pofu-hamster.png", "ppu": 522 / 64, "anchor": (266, 481), "no_sharp": True},
    # Stand-ins from the interaction prototype until batch 01 covers them.
    "garden-standin": _st("st-garden-3"),
    "pond-standin": _st("st-pond-2"),
    "workshop-standin": _st("st-workshop-2"),
    "windmill-standin": _st("st-windmill-2"),
    "findik-standin": {"src": os.path.join(PROTO, "res-hog.webp"), "ppu": 134 / 28, "anchor": (67, 125 * 22 / 26)},
    "isle-harbor-standin": _isle("isle-harbor", (-134, -106.4, 134, 125.44)),
    "isle-stars-standin": _isle("isle-stars", (-122, -95, 122, 112)),
    "isle-hamam-standin": _isle("isle-hamam", (-128, -100.7, 128, 118.72)),
    "isle-library-standin": _isle("isle-library", (-122, -95, 122, 112)),
}
# The home plate's depth bands in world y (larger is nearer): back lawn, middle lawn, front lawn
# and lip, earth body. Each band's depth lives in PofuWorld's IslandLayout.
APP_PLATE = "island-main"
APP_BANDS = [(-1e9, -14.0), (-14.0, 14.0), (14.0, 44.0), (44.0, 1e9)]
APP_FEATHER = 8.0


def _trim(img, margin=2):
    box = img.getchannel("A").point(lambda v: 255 if v > 2 else 0).getbbox()
    if box is None:
        return img, (0, 0)
    x0, y0 = max(0, box[0] - margin), max(0, box[1] - margin)
    x1, y1 = min(img.width, box[2] + margin), min(img.height, box[3] + margin)
    return img.crop((x0, y0, x1, y1)), (x0, y0)


def _write_imageset(name, img):
    folder = os.path.join(APP_CATALOG, name + ".imageset")
    os.makedirs(folder, exist_ok=True)
    img.save(os.path.join(folder, name + ".png"), "PNG", optimize=True)
    with open(os.path.join(folder, "Contents.json"), "w") as f:
        json.dump({"images": [{"filename": name + ".png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")


def _box(origin, size, ppu, anchor):
    """An image's box in world units relative to the anchor: [minX, minY, maxX, maxY]."""
    x0 = (origin[0] - anchor[0]) / ppu
    y0 = (origin[1] - anchor[1]) / ppu
    return [round(x0, 3), round(y0, 3), round(x0 + size[0] / ppu, 3), round(y0 + size[1] / ppu, 3)]


def _band_cut(img, box, k):
    """Cuts band k out of an image spanning `box` (world units); returns the crop and its box."""
    a = np.asarray(img, dtype=np.float32)
    y = box[1] + (np.arange(a.shape[0]) + 0.5) / a.shape[0] * (box[3] - box[1])
    s0, s1 = APP_BANDS[k]
    w = np.ones_like(y) if k == 0 else smoothstep(s0 - APP_FEATHER, s0 + APP_FEATHER, y)
    if s1 < 1e8:
        w = np.where(y <= s1 + APP_FEATHER, w, 0.0)
    out = a.copy()
    out[..., 3] *= w[:, None]
    rows = np.where(out[..., 3].max(axis=1) > 0.5)[0]
    r0, r1 = int(rows[0]), int(rows[-1]) + 1
    per_row = (box[3] - box[1]) / a.shape[0]
    crop = Image.fromarray(np.uint8(np.clip(out[r0:r1], 0, 255) + 0.5), "RGBA")
    return crop, [box[0], round(box[1] + r0 * per_row, 3), box[2], round(box[1] + r1 * per_row, 3)]


def app_main():
    import shutil

    if os.path.isdir(APP_CATALOG):
        shutil.rmtree(APP_CATALOG)
    os.makedirs(APP_CATALOG)
    with open(os.path.join(APP_CATALOG, "Contents.json"), "w") as f:
        json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
        f.write("\n")
    table = {}
    jobs = []
    for name, spec in APP_SOURCES.items():
        jobs.append((name, "", spec))
        if spec.get("softlock"):
            jobs.append((name, "--softlock", {**spec, "src": spec["softlock"]}))
    for name, alt, spec in jobs:
        path = os.path.join(REPO, spec["src"])
        if not os.path.exists(path):
            print("missing", path, file=sys.stderr)
            return 1
        src = Image.open(path).convert("RGBA")
        if "anchor_box" in spec:
            bx = spec["anchor_box"]
            ppu = src.width / spec["units"]
            anchor = (-bx[0] * ppu, -bx[1] * src.height / (bx[3] - bx[1]))
        else:
            ppu, anchor = spec["ppu"], spec["anchor"]
        img, (ox, oy) = _trim(src)
        anchor = (anchor[0] - ox, anchor[1] - oy)
        if ppu > APP_MAX_PPU:
            f = APP_MAX_PPU / ppu
            img = img.resize((max(1, round(img.width * f)), max(1, round(img.height * f))), Image.LANCZOS)
            anchor, ppu = (anchor[0] * f, anchor[1] * f), APP_MAX_PPU
        variants = {"sharp": (img, _box((0, 0), img.size, ppu, anchor))}
        for suffix, (sigma_u, down) in APP_LEVELS.items():
            blurred, pad = blur_variant(img, sigma_u * ppu, down)
            # The blurred image covers the source padded by `pad` source pixels on every side.
            variants[suffix] = (blurred, _box((-pad, -pad), (img.width + 2 * pad, img.height + 2 * pad), ppu, anchor))
        if name == APP_PLATE:
            for k in range(len(APP_BANDS)):
                entry = {}
                for suffix, (vimg, vbox) in variants.items():
                    crop, cbox = _band_cut(vimg, vbox, k)
                    _write_imageset(f"world-{name}-band{k}{alt}" + ("" if suffix == "sharp" else "__" + suffix), crop)
                    entry[suffix] = cbox
                table[f"{name}-band{k}{alt}"] = entry
            print(f"{name}{alt}: {len(APP_BANDS)} bands, {ppu:.2f} px/unit")
            continue
        entry = {}
        for suffix, (vimg, vbox) in variants.items():
            if suffix == "sharp" and spec.get("no_sharp"):
                continue
            _write_imageset(f"world-{name}{alt}" + ("" if suffix == "sharp" else "__" + suffix), vimg)
            entry[suffix] = vbox
        table[name + alt] = entry
        print(f"{name}{alt}: {img.width}x{img.height}, {ppu:.2f} px/unit, box {entry.get('sharp', entry['soft'])}")
    _write_swift(table)
    return 0


def _write_swift(table):
    def box(b):
        return f"WorldBox(minX: {b[0]}, minY: {b[1]}, maxX: {b[2]}, maxY: {b[3]})" if b else "nil"

    lines = [
        "// Generated by design/prototypes/interactions/tools/preblur.py (app mode). Do not edit.",
        "// Boxes are in world units, relative to each image's anchor (the feet or the footprint centre).",
        "",
        "extension WorldArt {",
        "    static let generated: [String: WorldSprite] = [",
    ]
    for name in sorted(table):
        e = table[name]
        lines.append(f'        "{name}": WorldSprite(')
        lines.append(f'            sharp: {box(e.get("sharp"))},')
        lines.append(f'            soft: {box(e["soft"])},')
        lines.append(f'            deep: {box(e["deep"])}')
        lines.append("        ),")
    lines += ["    ]", "}", ""]
    with open(APP_SWIFT, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    sys.exit(app_main() if sys.argv[1:] == ["app"] else main())
