#!/usr/bin/env python3
"""Ingest a painted plate for a plate-first island (ADR-0022, docs/design/plate-islands.md §0).

Reads the hand data `design/art/plates/<island>/objects.json` (plate paths, the silhouette trace,
tap and occluder polygons, the walkable lawn, the characters' spots and the framing, all in percent
of the plate) and writes what the app draws:

  World.xcassets/world-<island>-plate-<light>-<stage>     the whole plate, opaque, its border
                                                          feathered (the island and its own sky)
  World.xcassets/world-<island>-island-<light>-<stage>    the island cut from its sky, half size
                                                          (the Map and the Island stop)
  World.xcassets/world-<island>-backdrop-<light>-<stage>  the plate's sky and cloud sea extended
                                                          past its edges, low resolution
  World.xcassets/world-<island>-occ-<id>-<light>-<stage>  an occluder's plate pixels, in its box
  Plates/plate-<island>.json                              the metadata the runtime reads

Commands (python3 -I tools/plate/ingest.py <command> <island>):

  matte     GrabCut in a band around the trace -> design/art/plates/<island>/matte.png (needs OpenCV;
            every later command reads the committed matte)
  deliver   the plate, the island cut and the backdrop
  objects   the occluder cut-outs
  json      the metadata, light map included
  variant   the plate and occluders from an upscaled picture, as flat PNGs for the screenshot tests'
            A/B (`--plate P --out DIR --prefix b`); not part of `all`
  check     fails (exit 1, one line per problem) on a polygon off the matte, a missing asset or a
            texture budget past 8 MB
  all       deliver, objects, json, check (matte is run on its own, once per plate)

Coordinates in the JSON are percent of the full plate (default 1536 x 1024; `size` in the hand data
overrides it, the home master is 1024 x 1536).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "assets"))
from process_assets import srgb_to_lab  # noqa: E402

PLATES = REPO / "design" / "art" / "plates"
RESOURCES = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
JSON_DIR = RESOURCES / "Plates"
DEFAULT_SIZE = (1536, 1024)
SIZE = DEFAULT_SIZE
BUDGET = 8_000_000
#: The reference screen (iPhone 17) in points.
SCREEN = (402.0, 874.0)
#: The backdrop's extent around the Home frame (it must still cover the screen at the Island stop),
#: and its resolution relative to the plate.
BACKDROP_SPAN = (1.6, 1.9)
BACKDROP_SCALE = 0.38
ISLAND_SCALE = 0.5
FEATHER = 48


# ---------------------------------------------------------------- basics

def load_hand(island: str) -> dict:
    """The hand data; its optional `size` ([w, h], default 1536 x 1024) sets the plate size every
    percent in it refers to (the home master is a 1024 x 1536 portrait)."""
    global SIZE
    hand = json.loads((PLATES / island / "objects.json").read_text())
    SIZE = tuple(hand.get("size", DEFAULT_SIZE))
    return hand


def load_rgb(path: Path) -> np.ndarray:
    im = Image.open(path).convert("RGB")
    if im.size != SIZE:
        raise SystemExit(f"{path}: the plate is {im.size[0]} x {im.size[1]}, not {SIZE[0]} x {SIZE[1]}")
    return np.asarray(im, np.float64) / 255


def to_img(x: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255 + 0.5))


def pct_to_px(points, size=None) -> list[list[float]]:
    """Percent of the plate to plate pixels."""
    size = size or SIZE
    return [[round(x * size[0] / 100, 1), round(y * size[1] / 100, 1)] for x, y in points]


def px_to_pct(points, size=None) -> list[list[float]]:
    size = size or SIZE
    return [[x * 100 / size[0], y * 100 / size[1]] for x, y in points]


def poly_mask(shape: tuple[int, int], pts) -> np.ndarray:
    """A filled polygon (pixel coordinates) as a boolean mask, even-odd, no OpenCV."""
    h, w = shape
    img = Image.new("L", (w, h), 0)
    from PIL import ImageDraw
    ImageDraw.Draw(img).polygon([tuple(p) for p in pts], fill=255)
    return np.asarray(img) > 127


def bbox(a: np.ndarray, t: float = 0.5) -> tuple[int, int, int, int]:
    ys, xs = np.where(a > t)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def foot_y(points) -> float:
    return max(p[1] for p in points)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def plates(hand: dict):
    """(light, stage, path) for every plate in the hand data."""
    for light, stages in sorted(hand["plates"].items()):
        for stage, rel in sorted(stages.items(), key=lambda kv: int(kv[0])):
            yield light, int(stage), REPO / rel


def asset_name(island: str, kind: str, light: str, stage: int, oid: str | None = None) -> str:
    return f"world-{island}-{kind}-{oid}-{light}-{stage}" if oid else f"world-{island}-{kind}-{light}-{stage}"


def write_imageset(name: str, img: Image.Image, jpeg: bool = False) -> Path:
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob(f"{name}.*"):
        if old.suffix in (".png", ".jpg"):
            old.unlink()
    filename = f"{name}.jpg" if jpeg else f"{name}.png"
    if jpeg:
        img.convert("RGB").save(folder / filename, "JPEG", quality=90, optimize=True)
    else:
        img.save(folder / filename, optimize=True)
    contents = {"images": [{"filename": filename, "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    return folder / filename


# ---------------------------------------------------------------- matte

def matte(rgb: np.ndarray, trace_px, water_px=()) -> np.ndarray:
    """GrabCut in a band around the hand trace (as `pilot.matte`), day sky forced to background
    everywhere but inside the water polygons (a pond is sky-blue too)."""
    import cv2  # only here: every later command reads the committed matte

    h, w = rgb.shape[:2]
    poly = np.array(trace_px, np.int32)
    inside = np.zeros((h, w), np.uint8)
    cv2.fillPoly(inside, [poly], 255)
    k = lambda r: cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    m = np.full((h, w), cv2.GC_BGD, np.uint8)
    m[cv2.dilate(inside, k(18)) > 0] = cv2.GC_PR_BGD
    m[inside > 0] = cv2.GC_PR_FGD
    m[cv2.erode(inside, k(20)) > 0] = cv2.GC_FGD
    # Day sky seen between the props (sunflowers, the windmill's sails): clear blue, in the top
    # third only (the pond below is blue too).
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    hue = np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    skyish = (hue > 235) & (hue < 290) & (chroma > 12) & (lab[..., 0] > 65)
    for water in water_px:
        skyish &= ~ndimage.binary_dilation(poly_mask((h, w), water), iterations=6)
    m[skyish] = cv2.GC_BGD
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    img = np.uint8(np.clip(rgb, 0, 1) * 255)[..., ::-1].copy()
    cv2.grabCut(img, m, None, bgd, fgd, 5, cv2.GC_INIT_WITH_MASK)
    fg = np.isin(m, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.uint8)
    n, lbl, st, _ = cv2.connectedComponentsWithStats(fg)
    keep = 1 + int(np.argmax(st[1:, cv2.CC_STAT_AREA]))
    fg = ndimage.binary_fill_holes(lbl == keep) & ~ndimage.binary_dilation(skyish, iterations=1)
    fg = ndimage.binary_opening(fg, iterations=1)
    lbl, _ = ndimage.label(fg)
    fg = lbl == 1 + int(np.argmax(np.bincount(lbl.ravel())[1:]))
    return ndimage.gaussian_filter(fg.astype(np.float64), 1.2)


def matte_path(island: str, light: str, stage: int) -> Path:
    return PLATES / island / f"matte-{light}-{stage}.png"


def load_matte(island: str, light: str, stage: int) -> np.ndarray:
    return np.asarray(Image.open(matte_path(island, light, stage)).convert("L"), np.float64) / 255


def cmd_matte(island: str) -> None:
    hand = load_hand(island)
    for light, stage, path in plates(hand):
        water = [pct_to_px(o["points"]) for o in hand["objects"] if o.get("water")]
        a = matte(load_rgb(path), pct_to_px(hand["trace"]), water)
        Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5)).save(matte_path(island, light, stage))
        print(f"matte {light} {stage}: box {bbox(a)}")


# ---------------------------------------------------------------- framing

def home_frame(hand: dict, a: np.ndarray) -> dict:
    """The Home frame in plate pixels: the island `homeWidths` screen widths wide, its x centre at
    `homeCenterX` of the island, its top `homeTopY` points below the screen's top."""
    f = hand["framing"]
    x0, y0, x1, y1 = bbox(a)
    ws = (x1 - x0) / f["homeWidths"]
    k = ws / SCREEN[0]  # plate px per point
    hs = SCREEN[1] * k
    cx = x0 + f["homeCenterX"] * (x1 - x0)
    top = y0 - f["homeTopY"] * k
    return {"x0": cx - ws / 2, "y0": top, "w": ws, "h": hs, "k": k}


def backdrop_box(frame: dict) -> tuple[int, int, int, int]:
    cx, cy = frame["x0"] + frame["w"] / 2, frame["y0"] + frame["h"] / 2
    bw, bh = frame["w"] * BACKDROP_SPAN[0], frame["h"] * BACKDROP_SPAN[1]
    return round(cx - bw / 2), round(cy - bh / 2), round(cx + bw / 2), round(cy + bh / 2)


# ---------------------------------------------------------------- the backdrop

def fill_holes(rgb: np.ndarray, hole: np.ndarray, iterations: int = 6) -> np.ndarray:
    """A smooth fill of `hole` from its surroundings (normalized convolution at growing radii):
    no OpenCV, low frequency only."""
    out = rgb.copy()
    known = (~hole).astype(np.float64)
    for i in range(iterations):
        s = 2.0 * 1.8 ** i
        num = ndimage.gaussian_filter(out * known[..., None], (s, s, 0))
        den = ndimage.gaussian_filter(known, s)[..., None]
        est = num / np.maximum(den, 1e-6)
        fill = (known < 0.5)[..., None] & (den > 0.02)
        out = np.where(fill, est, out)
        known = np.maximum(known, (den[..., 0] > 0.02).astype(np.float64) * 0.999)
    return out


def resize(x: np.ndarray, w: int, h: int) -> np.ndarray:
    return np.asarray(to_img(x).resize((max(w, 1), max(h, 1)), Image.Resampling.LANCZOS), np.float64) / 255


def backdrop(rgb: np.ndarray, a: np.ndarray, box: tuple[int, int, int, int], scale: float = BACKDROP_SCALE) -> np.ndarray:
    """The plate's own sky and cloud sea continued past its edges, in `box` (plate pixels), at
    `scale` (as `pilot.painted_frame`): above, the plate's top sky deepens upward; at the sides the
    plate mirrors; below, its cloud band (the roots filled out) repeats at growing sizes, mirrored
    and offset, so no puff repeats at one size. Inside the plate's rectangle it is the plate."""
    bx0, by0, bx1, by1 = box
    W, H = round((bx1 - bx0) * scale), round((by1 - by0) * scale)
    pw, ph = round(SIZE[0] * scale), round(SIZE[1] * scale)
    px, py = round(-bx0 * scale), round(-by0 * scale)
    small = resize(rgb, pw, ph)
    sa = resize(np.repeat(a[..., None], 3, 2), pw, ph)[..., 0]
    canvas = np.zeros((H, W, 3))
    # Above: the plate's top sky, column by column (mirrored past its sides, blurred), deepening
    # upward toward one zenith tone, so its own left-to-right gradient runs on with no seam.
    top = small[: max(3, round(0.03 * ph))].mean(0)
    lpad, rpad = max(px, 0), max(W - (px + pw), 0)
    cols = np.concatenate([top[:lpad][::-1], top, top[pw - rpad:][::-1]], axis=0) if (lpad or rpad) else top
    cols = ndimage.gaussian_filter1d(cols, max(2, pw / 12), axis=0, mode="nearest")
    c0 = px - lpad
    cols = cols[max(-c0, 0):max(-c0, 0) + W]
    if cols.shape[0] < W:
        cols = np.concatenate([cols, np.repeat(cols[-1:], W - cols.shape[0], 0)], 0)
    topc = cols.mean(0)
    zen = np.clip(topc * np.array([0.80, 0.88, 0.97]) + np.array([-0.02, 0.0, 0.03]), 0, 1)
    yy = np.arange(H)[:, None, None]
    deepen = smooth(0, 1, np.clip((py - yy) / max(py, 1), 0, 1)) * 0.85
    canvas[:] = cols[None] * (1 - deepen) + zen * deepen
    # Below: the cloud band (full resolution, the island's roots filled out), repeated from the
    # plate's foot down, each copy resized once from the full-resolution band.
    cut = round(SIZE[1] * 0.86)
    band = rgb[cut:].copy()
    band = fill_holes(band, ndimage.binary_dilation(a[cut:] > 0.1, iterations=10))
    y, i = py + ph - round(0.06 * ph), 0
    while y < H:
        k = min(1.6 * 1.4 ** i, 6.0) * scale
        src = band[:, ::-1] if i % 2 == 0 else band
        b = resize(src, round(band.shape[1] * k), round(band.shape[0] * k))
        if b.shape[1] < W:
            b = resize(b, W, round(b.shape[0] * W / b.shape[1]))
        off = round((b.shape[1] - W) * ((0.31 + 0.29 * i) % 1.0))
        b = b[:, off:off + W]
        feather = round(b.shape[0] * 0.5)
        y_top = y - feather
        hh = min(b.shape[0], H - y_top)
        m = smooth(0, feather, np.arange(hh))[:, None, None]
        canvas[y_top:y_top + hh] = b[:hh] * m + canvas[y_top:y_top + hh] * (1 - m)
        y, i = y_top + hh, i + 1
    # The plate, mirrored past its sides so the sky and the clouds run on.
    left, right = max(px, 0), max(W - (px + pw), 0)
    wide = np.concatenate([small[:, :left][:, ::-1], small, small[:, pw - right:][:, ::-1]], axis=1) if (left or right) else small
    wide_a = np.concatenate([sa[:, :left][:, ::-1], sa, sa[:, pw - right:][:, ::-1]], axis=1) if (left or right) else sa
    # The island's own pixels never repeat in the mirrored margins: fill them from their surroundings.
    mirrored = np.zeros(wide_a.shape, bool)
    mirrored[:, :left] = True
    mirrored[:, left + pw:] = True
    ghost = mirrored & ndimage.binary_dilation(wide_a > 0.1, iterations=4)
    if ghost.any():
        wide = fill_holes(wide, ghost)
    x0 = px - left
    sx0, dx0 = max(-x0, 0), max(x0, 0)
    dx1 = min(W, x0 + wide.shape[1])
    sy0, dy0 = max(-py, 0), max(py, 0)
    dy1 = min(H, py + ph)
    sub = wide[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
    rows = sy0 + np.arange(sub.shape[0])
    fade = np.minimum(smooth(0, 0.10 * ph, ph - rows), smooth(0, 0.16 * ph, rows)).reshape(-1, 1, 1)
    keep = wide_a[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0][..., None]
    fade = np.maximum(fade, keep)
    canvas[dy0:dy1, dx0:dx1] = sub * fade + canvas[dy0:dy1, dx0:dx1] * (1 - fade)
    return np.clip(canvas, 0, 1)


def feathered_plate(rgb: np.ndarray, a: np.ndarray, feather: int = FEATHER) -> Image.Image:
    """The whole plate with its rectangle's border feathered into the backdrop (the island itself
    never fades)."""
    h, w = a.shape
    ys, xs = np.arange(h)[:, None], np.arange(w)[None, :]
    edge = np.minimum(np.minimum(xs, w - 1 - xs), np.minimum(ys, h - 1 - ys)).astype(np.float64)
    alpha = np.maximum(smooth(0, feather, edge), np.clip(a, 0, 1))
    return to_img(np.dstack([rgb, alpha]))


def cmd_deliver(island: str) -> None:
    hand = load_hand(island)
    for light, stage, path in plates(hand):
        rgb, a = load_rgb(path), load_matte(island, light, stage)
        write_imageset(asset_name(island, "plate", light, stage), feathered_plate(rgb, a))
        x0, y0, x1, y1 = bbox(a, 0.02)
        cut = np.dstack([rgb, np.clip(a, 0, 1)])[y0:y1, x0:x1]
        img = to_img(cut)
        img = img.resize((round(img.width * ISLAND_SCALE), round(img.height * ISLAND_SCALE)), Image.Resampling.LANCZOS)
        write_imageset(asset_name(island, "island", light, stage), img)
        box = backdrop_box(home_frame(hand, a))
        write_imageset(asset_name(island, "backdrop", light, stage), to_img(backdrop(rgb, a, box)), jpeg=True)
        print(f"deliver {light} {stage}: island box {(x0, y0, x1, y1)}, backdrop box {box}")


# ---------------------------------------------------------------- objects

def occluder_cut(rgb: np.ndarray, a: np.ndarray, pts_px, pad: int = 4) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """The plate's pixels inside an object's polygon and the matte, feathered 1 px, in its box."""
    m = poly_mask(a.shape, pts_px).astype(np.float64)
    m = np.minimum(ndimage.gaussian_filter(m, 1.0), np.clip(a, 0, 1))
    x0, y0, x1, y1 = bbox(m, 0.02)
    x0, y0 = max(x0 - pad, 0), max(y0 - pad, 0)
    x1, y1 = min(x1 + pad, a.shape[1]), min(y1 + pad, a.shape[0])
    return np.dstack([rgb, m])[y0:y1, x0:x1], (x0, y0, x1, y1)


def cmd_objects(island: str) -> None:
    hand = load_hand(island)
    for light, stage, path in plates(hand):
        rgb, a = load_rgb(path), load_matte(island, light, stage)
        for obj in hand["objects"]:
            if not obj.get("occluder"):
                continue
            cut, box = occluder_cut(rgb, a, pct_to_px(obj["points"]))
            write_imageset(asset_name(island, "occ", light, stage, obj["id"]), to_img(cut))
            print(f"occluder {obj['id']} {light} {stage}: box {box}")


# ---------------------------------------------------------------- A/B variants

def cmd_variant(island: str, plate: Path, out: Path, prefix: str) -> None:
    """The plate and its occluder cut-outs from a replacement picture of the same composition at a
    whole-number scale (an upscaled plate), as flat PNGs `<prefix>-<asset name>.png` in `out`. They
    are not imagesets: the screenshot tests load them to compare resolutions (README). The matte and
    the polygons are the shipped ones, scaled."""
    hand = load_hand(island)
    light, stage, _ = next(plates(hand))
    im = Image.open(plate).convert("RGB")
    k = im.width / SIZE[0]
    if abs(im.height - SIZE[1] * k) > 1:
        raise SystemExit(f"{plate}: {im.width} x {im.height} is not a scale of {SIZE[0]} x {SIZE[1]}")
    rgb = np.asarray(im, np.float64) / 255
    m = Image.fromarray(np.uint8(np.clip(load_matte(island, light, stage), 0, 1) * 255 + 0.5)).resize(im.size, Image.Resampling.LANCZOS)
    a = np.asarray(m, np.float64) / 255
    out.mkdir(parents=True, exist_ok=True)
    feathered_plate(rgb, a, round(FEATHER * k)).save(out / f"{prefix}-{asset_name(island, 'plate', light, stage)}.png", optimize=True)
    for obj in hand["objects"]:
        if obj.get("occluder"):
            pts = [[x * k, y * k] for x, y in pct_to_px(obj["points"])]
            cut, _ = occluder_cut(rgb, a, pts, round(4 * k))
            to_img(cut).save(out / f"{prefix}-{asset_name(island, 'occ', light, stage, obj['id'])}.png", optimize=True)
    print(f"variant {prefix}: {im.size} -> {out}")


# ---------------------------------------------------------------- light map

def hexc(c) -> str:
    r, g, b = (int(round(float(v) * 255)) for v in np.clip(c, 0, 1))
    return f"#{r:02x}{g:02x}{b:02x}"


def light_map(rgb: np.ndarray, a: np.ndarray, grid=None, lit_pct: float = 60, shadow_pct: float = 12) -> tuple[list, list]:
    """Per cell of a `grid` (32 columns, rows by aspect: 20 for the 3:2 landscape, 48 for the portrait): the mean colour of the island's lit pixels (L* at or above the
    cell's 60th percentile) and of its shadow pixels (at or below the 12th), alpha > 0.99; empty
    cells take their nearest filled neighbour's."""
    h, w = a.shape
    gw, gh = grid or (32, round(32 * h / w))
    L = srgb_to_lab(np.clip(rgb, 0, 1))[..., 0]
    lit = np.full((gh, gw, 3), np.nan)
    dark = np.full((gh, gw, 3), np.nan)
    for j in range(gh):
        for i in range(gw):
            ys, ye = j * h // gh, (j + 1) * h // gh
            xs, xe = i * w // gw, (i + 1) * w // gw
            inside = a[ys:ye, xs:xe] > 0.99
            if inside.sum() < 12:
                continue
            l = L[ys:ye, xs:xe][inside]
            c = rgb[ys:ye, xs:xe][inside]
            lit[j, i] = c[l >= np.percentile(l, lit_pct)].mean(0)
            dark[j, i] = c[l <= np.percentile(l, shadow_pct)].mean(0)
    for grid_ in (lit, dark):
        empty = np.isnan(grid_[..., 0])
        if empty.all():
            grid_[:] = 1.0
            continue
        if empty.any():
            _, (iy, ix) = ndimage.distance_transform_edt(empty, return_indices=True)
            grid_[:] = grid_[iy, ix]
    return ([[hexc(lit[j, i]) for i in range(gw)] for j in range(gh)],
            [[hexc(dark[j, i]) for i in range(gw)] for j in range(gh)])


# ---------------------------------------------------------------- json

def texture_bytes(island: str, hand: dict) -> int:
    """ASTC 4 x 4: one byte per pixel, over every image the island ships."""
    total = 0
    for folder in ASSETS.glob(f"world-{island}-*.imageset"):
        for f in folder.iterdir():
            if f.suffix in (".png", ".jpg"):
                with Image.open(f) as im:
                    total += im.width * im.height
    return total


def build_json(island: str, hand: dict, mattes: dict, maps: dict) -> dict:
    light0, stage0 = next((l, s) for l, s, _ in plates(hand))
    a = mattes[(light0, stage0)]
    objects = []
    for obj in hand["objects"]:
        poly = pct_to_px(obj["points"])
        entry = {
            "id": obj["id"],
            "tap": bool(obj.get("tap", False)),
            "label": obj.get("label", ""),
            "polygon": poly,
            "footY": foot_y(poly),
            "occluder": bool(obj.get("occluder", False)),
            "sway": obj.get("sway", 0),
            "emissive": bool(obj.get("emissive", False)),
        }
        if "station" in obj:
            entry["station"] = obj["station"]
        if obj.get("occluder"):
            _, box = occluder_cut(np.zeros(a.shape + (3,)), a, poly)
            entry["box"] = list(box)
        objects.append(entry)
    lights = sorted(hand["plates"])
    return {
        "island": island,
        "version": 1,
        "standIn": bool(hand.get("standIn", False)),
        "minLevel": hand.get("minLevel", 1),
        "plateSize": list(SIZE),
        "stages": max(int(s) for st in hand["plates"].values() for s in st) + 1,
        "lights": lights,
        "islandBox": list(bbox(a, 0.02)),
        "backdropBox": list(backdrop_box(home_frame(hand, a))),
        "feather": FEATHER,
        "objects": objects,
        "walkable": pct_to_px(hand["walkable"]),
        "characters": {k: pct_to_px([v])[0] for k, v in sorted(hand["characters"].items())},
        "pofuWidth": round(hand["pofuWidth"] * SIZE[0] / 100, 1),
        "framing": hand["framing"],
        "residentBoost": hand.get("residentBoost", 1.0),
        "lightDirection": hand.get("lightDirection", [0.5, 0.3]),
        "lightMap": {l: [maps[(l, s)][0] for s in range(len(hand["plates"][l]))] for l in lights},
        "shadowMap": {l: [maps[(l, s)][1] for s in range(len(hand["plates"][l]))] for l in lights},
        "textureBytes": texture_bytes(island, hand),
    }


def cmd_json(island: str) -> Path:
    hand = load_hand(island)
    mattes, maps = {}, {}
    for light, stage, path in plates(hand):
        a = load_matte(island, light, stage)
        mattes[(light, stage)] = a
        maps[(light, stage)] = light_map(load_rgb(path), a)
    data = build_json(island, hand, mattes, maps)
    JSON_DIR.mkdir(parents=True, exist_ok=True)
    out = JSON_DIR / f"plate-{island}.json"
    out.write_text(json.dumps(data, separators=(",", ":")) + "\n")
    print(f"json: {out.relative_to(REPO)} ({data['textureBytes']:,} texture bytes)")
    return out


# ---------------------------------------------------------------- check

def problems(data: dict, a: np.ndarray, assets: set[str], tolerance: float = 32.0) -> list[str]:
    """Hand-traced outlines are in percent (1 % is 15 px) and tap polygons are padded for a finger, so
    a vertex may sit `tolerance` px (about 2 %) off the matte and a polygon may span the sky between
    a windmill's sails; the walkable lawn may not leave the matte."""
    out = []
    island = data["island"]
    outside = ndimage.distance_transform_edt(a < 0.5)

    def off(points) -> float:
        h, w = a.shape
        return max(outside[min(max(int(y), 0), h - 1), min(max(int(x), 0), w - 1)] for x, y in points)

    for obj in data["objects"]:
        if off(obj["polygon"]) > tolerance:
            out.append(f"{obj['id']}: the polygon leaves the matte by {off(obj['polygon']):.0f} px")
    walk = poly_mask(a.shape, data["walkable"])
    if walk.any() and outside[walk].max() > 4:
        out.append(f"walkable: leaves the matte by {outside[walk].max():.0f} px")
    for name, (x, y) in data["characters"].items():
        if not walk[min(int(y), a.shape[0] - 1), min(int(x), a.shape[1] - 1)]:
            out.append(f"{name}: stands off the walkable lawn")
    if data["textureBytes"] > BUDGET:
        out.append(f"textureBytes {data['textureBytes']:,} > {BUDGET:,}")
    for light in data["lights"]:
        for stage in range(data["stages"]):
            for kind in ("plate", "island", "backdrop"):
                if asset_name(island, kind, light, stage) not in assets:
                    out.append(f"missing asset {asset_name(island, kind, light, stage)}")
            for obj in data["objects"]:
                if obj["occluder"] and asset_name(island, "occ", light, stage, obj["id"]) not in assets:
                    out.append(f"missing asset {asset_name(island, 'occ', light, stage, obj['id'])}")
    return out


def cmd_check(island: str) -> int:
    data = json.loads((JSON_DIR / f"plate-{island}.json").read_text())
    hand = load_hand(island)
    light, stage, _ = next(plates(hand))
    assets = {p.name.removesuffix(".imageset") for p in ASSETS.glob(f"world-{island}-*.imageset")}
    found = problems(data, load_matte(island, light, stage), assets)
    for p in found:
        print(p)
    print("check: ok" if not found else f"check: {len(found)} problem(s)")
    return 1 if found else 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["matte", "deliver", "objects", "json", "check", "all", "variant"])
    ap.add_argument("island")
    ap.add_argument("--plate", type=Path, help="variant: the replacement picture")
    ap.add_argument("--out", type=Path, help="variant: the output folder")
    ap.add_argument("--prefix", default="v", help="variant: the file name prefix")
    args = ap.parse_args(argv)
    if args.command == "matte":
        cmd_matte(args.island)
    elif args.command == "deliver":
        cmd_deliver(args.island)
    elif args.command == "objects":
        cmd_objects(args.island)
    elif args.command == "variant":
        if not (args.plate and args.out):
            ap.error("variant needs --plate and --out")
        cmd_variant(args.island, args.plate, args.out, args.prefix)
    elif args.command == "json":
        cmd_json(args.island)
    elif args.command == "check":
        return cmd_check(args.island)
    else:
        cmd_deliver(args.island)
        cmd_objects(args.island)
        cmd_json(args.island)
        return cmd_check(args.island)
    return 0


if __name__ == "__main__":
    sys.exit(main())
