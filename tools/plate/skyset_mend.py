#!/usr/bin/env python3
"""Mend the holes the island left in Home's drift clouds (one sky at every level).

    python3 -I tools/plate/skyset_mend.py home [--check]

The split (`split.py`) takes the level-10 island out of the painting; a far or mid cloud that the island covered keeps a
hole where the island's tree, windmill or lamp stood (alpha 0 inside the cloud). While the sky set drew its own island
layer the hole sat behind it at rest. Every matted Home state now draws the sky set without that layer behind its own
plate (`HomePlate.isMatted`), and the r3b mattes are tighter than the layer, so the holes show, at every level. This
closes them in the shipped far and mid tiles (`world-home-sky-far-*`, `-mid-*`): a hole is clear sky enclosed by a cloud
inside the island layer's footprint (grown by `REACH` master px); its alpha becomes the cloud's closed over it and its
colour the cloud's round it (a normalised blur of its premultiplied colour). Every other pixel keeps its own values. Run it after `skyset_export.py`; a mended tile has nothing left to close, so it is not rewritten.
`--check` exits 1 when a tile still has a hole.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import heic  # noqa: E402

RESOURCES = HERE.parents[1] / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
#: Master px round the island layer's footprint that may be mended, the gap a cloud is closed over (tile px), the
#: least added alpha that counts, and the blur that lends a new pixel its cloud's colour (tile px).
REACH = 24
RADIUS = 14
SOLID = 0.12
MIN_HOLE = 24          # tile px: a smaller gap is the codec's, not the island's
GAIN = 0.04
SPREAD = 6.0
TILES = ("far", "mid")


def _read(name: str) -> np.ndarray:
    return np.asarray(heic.open_image(ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}").convert("RGBA"), np.float32) / 255


def footprint(spec: dict, layer: dict, shape: tuple[int, int]) -> np.ndarray:
    """The island layer's alpha (> 0.02, grown by `REACH` master px) in `layer`'s own pixels (`shape`)."""
    isl = next(entry for entry in spec["layers"] if entry["role"] == "island")
    ia = _read(isl["asset"])[..., 3]
    iw, ih = int(round(isl["size"][0])), int(round(isl["size"][1]))
    ia = cv2.resize(ia, (iw, ih), interpolation=cv2.INTER_AREA if ia.shape[1] > iw else cv2.INTER_LINEAR)
    k = shape[1] / layer["size"][0]                     # tile px per master px
    out = np.zeros(shape, np.float32)
    # the island layer in the tile's px: master (x, y) -> ((x - pos) * k)
    m = np.float32([[k, 0, (isl["pos"][0] - layer["pos"][0]) * k], [0, k, (isl["pos"][1] - layer["pos"][1]) * k]])
    out = cv2.warpAffine((ia > 0.02).astype(np.float32), m, (shape[1], shape[0]), flags=cv2.INTER_LINEAR)
    r = max(int(round(REACH * k)), 1)
    return cv2.dilate((out > 0.01).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1,) * 2)) > 0


def mend(rgba: np.ndarray, region: np.ndarray) -> tuple[np.ndarray, int]:
    """`rgba` (straight) with the holes inside its clouds closed where they lie in `region`; the count of pixels that
    changed. A hole is clear sky enclosed by a cloud (`SOLID` alpha, its hairline gaps closed): a gap between two clouds
    or a cloud's own soft edge is not one, so nothing else changes and a mended tile has nothing left to close."""
    a = rgba[..., 3]
    solid = cv2.morphologyEx((a > SOLID).astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))
    holes = ndimage.binary_fill_holes(solid) & (a <= SOLID) & region
    lab, n = ndimage.label(holes)
    if n:
        size = ndimage.sum(holes, lab, range(1, n + 1))
        holes = np.isin(lab, 1 + np.flatnonzero(size >= MIN_HOLE))
    if not holes.any():
        return rgba, 0
    holes = cv2.dilate(holes.astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))) > 0
    closed = cv2.morphologyEx(a, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * RADIUS + 1,) * 2))
    mask = cv2.GaussianBlur(holes.astype(np.float32), (0, 0), 1.2)
    want = a + (np.maximum(a, closed) - a) * mask
    grow = (want - a) > GAIN
    if not grow.any():
        return rgba, 0
    # the hole's colour: the cloud's own round it (normalised blur of premultiplied colour, the hole left out)
    w = np.where(holes, 0, a)
    num = cv2.GaussianBlur(rgba[..., :3] * w[..., None], (0, 0), SPREAD)
    den = cv2.GaussianBlur(w, (0, 0), SPREAD)[..., None]
    fill = num / np.maximum(den, 1e-6)
    t = np.clip((want - a) / np.maximum(want, 1e-6), 0, 1)[..., None]   # the share of the new alpha that is new
    out = rgba.copy()
    out[..., :3] = np.where((want > a)[..., None], rgba[..., :3] * (1 - t) + fill * t, rgba[..., :3])
    out[..., 3] = want
    return np.clip(out, 0, 1), int(grow.sum())


#: The bank under the belly: the level-10 island layer's own air and cloud from master row `BANK_TOP` down (faded in
#: over `BANK_FADE` rows), the island's body (its r3b matte, grown `BANK_GROW` px) taken out and filled from round it, at
#: `BANK_SCALE` of the master; it draws, still, between the cloud sea and the plate (`k` 1: it stays with the island).
BANK_TOP = 1760
BANK_FADE = 120
BANK_GROW = 14
BANK_SCALE = 0.4
BANK_ID = "bank"


def bank(island: str, light: str, spec: dict) -> tuple[np.ndarray, list[int]]:
    """The bank of `light` (straight RGBA at `BANK_SCALE`) and its top-left in master px. The split filled the cloud sea
    behind the island with streaked guesses, which the island layer hid; a matted plate is tighter, so the bank puts the
    painting's own air back under every level's belly. Where the body was it is filled from the bank round it (the
    lower levels' bellies are not the same shape), so no hole, ring or tendril ghost is left."""
    sys.path.insert(0, str(HERE))
    import ingest  # noqa: PLC0415

    isl = next(entry for entry in spec["layers"] if entry["role"] == "island")
    rgba = _read(isl["asset"])
    x, y = (int(v) for v in isl["pos"])
    w, h = int(round(isl["size"][0])), int(round(isl["size"][1]))
    if rgba.shape[:2] != (h, w):
        rgba = cv2.resize(rgba, (w, h), interpolation=cv2.INTER_LINEAR)
    m = ingest.load_matte_full(island, light, 0)[y:y + h, x:x + w].astype(np.float32)
    body = cv2.dilate((m > 0.02).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * BANK_GROW + 1,) * 2))
    top = BANK_TOP - BANK_FADE - y
    rgba, body = rgba[top:], body[top:]
    rows = np.clip(np.arange(rgba.shape[0]) / BANK_FADE, 0, 1)[:, None]
    a = rgba[..., 3] * (1 - body) * rows
    # fill the body from round it: premultiplied colour and alpha, inpainted at a quarter size, then the hole's own
    small = lambda img: cv2.resize(img, (img.shape[1] // 4, img.shape[0] // 4), interpolation=cv2.INTER_AREA)
    hole = (small(body.astype(np.float32)) > 0.01).astype(np.uint8)
    pre = np.dstack([rgba[..., :3] * a[..., None], a])
    filled = np.dstack([cv2.inpaint(np.uint8(np.clip(small(pre[..., c]), 0, 1) * 255), hole, 9, cv2.INPAINT_TELEA) for c in range(4)])
    filled = cv2.resize(filled.astype(np.float32) / 255, (rgba.shape[1], rgba.shape[0]), interpolation=cv2.INTER_LINEAR)
    use = cv2.GaussianBlur(cv2.dilate(body, np.ones((7, 7), np.uint8)).astype(np.float32), (0, 0), 2.5)[..., None]
    pre = (pre * (1 - use) + filled * use) * rows[..., None]
    alpha = np.clip(pre[..., 3], 0, 1)
    rgb = pre[..., :3] / np.maximum(alpha[..., None], 1e-4)
    out = np.dstack([np.clip(rgb, 0, 1), alpha])
    out = cv2.resize(out, (round(out.shape[1] * BANK_SCALE), round(out.shape[0] * BANK_SCALE)), interpolation=cv2.INTER_AREA)
    return out, [x, y + top]


def bank_entry(light: str, pos: list[int], size: list[int]) -> dict:
    return {"id": BANK_ID, "role": "sprite", "asset": f"world-home-sky-{BANK_ID}-{light}-0", "pos": pos, "size": size, "k": 1}


def write_bank(island: str, data: dict, check: bool) -> int:
    """Writes each light's bank and its layer (just under the island layer) into the sky set file; the count of lights
    whose bank or layer was missing or out of date."""
    stale = 0
    for light, spec in sorted(data["lights"].items()):
        img, pos = bank(island, light, spec)
        size = [2048, int(round(img.shape[0] / BANK_SCALE))]
        entry = bank_entry(light, pos, size)
        layers = [entry_ for entry_ in spec["layers"] if entry_["id"] != BANK_ID]
        at = next(i for i, entry_ in enumerate(layers) if entry_["role"] == "island")
        layers.insert(at, entry)
        name = entry["asset"]
        path = ASSETS / f"{name}.imageset" / f"{name}{heic.SUFFIX}"
        same = layers == spec["layers"] and path.exists()
        if same:
            # the codec moves a pixel a few levels: the same bank reads back within that
            old = _read(name)
            same = old.shape == img.shape and float(np.abs(old - img).mean()) < 0.004
        print(f"{light} bank: {img.shape[1]} x {img.shape[0]} at {pos}{'' if same else (' missing' if check else ' written')}")
        if not same:
            stale += 1
            if check:
                continue
            spec["layers"] = layers
            path.parent.mkdir(parents=True, exist_ok=True)
            heic.save(heic_image(img), path)
            contents = {"images": [{"filename": path.name, "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}
            (path.parent / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
        # the set's own count of its pixels and the state's bytes (`skyset_export.state_bytes`) take the bank in
        import skyset_export  # noqa: PLC0415
        pixels = 0
        for layer in spec["layers"]:
            with heic.open_image(ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}{heic.SUFFIX}") as im:
                pixels += im.width * im.height
        counts = {"pixels": pixels, "textureBytes": skyset_export.state_bytes(island, light, pixels + spec.get("detailPixels", 0))}
        if any(spec.get(k) != v for k, v in counts.items()):
            stale += 1
            if not check:
                spec.update(counts)
    return stale


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island", nargs="?", default="home")
    ap.add_argument("--check", action="store_true", help="only report; exit 1 when a tile still has a hole")
    args = ap.parse_args(argv)
    data = json.loads((RESOURCES / "Plates" / f"skyset-{args.island}.json").read_text())
    left = 0
    for light, spec in sorted(data["lights"].items()):
        for layer in spec["layers"]:
            if layer["id"] not in TILES:
                continue
            rgba = _read(layer["asset"])
            out, n = mend(rgba, footprint(spec, layer, rgba.shape[:2]))
            print(f"{light} {layer['id']}: {n} px {'to mend' if args.check else 'mended'}")
            if n and not args.check:
                heic.save(heic_image(out), ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}{heic.SUFFIX}")
            left += n
    stale = write_bank(args.island, data, args.check) if args.island == "home" else 0
    if stale and not args.check:
        f = RESOURCES / "Plates" / f"skyset-{args.island}.json"
        f.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    return 1 if args.check and (left or stale) else 0


def heic_image(rgba: np.ndarray):
    from PIL import Image
    return Image.fromarray(np.uint8(np.clip(rgba, 0, 1) * 255 + 0.5), "RGBA")


if __name__ == "__main__":
    sys.exit(main())
