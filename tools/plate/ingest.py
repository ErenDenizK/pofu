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
  check     fails (exit 1, one line per problem) on a polygon off the matte, a missing asset or a
            texture budget past 9 MB

Plate, island and occluder layers are written as HEIC q70 with alpha (heic.py, ADR-0024).
Plates ship upscaled x2 with a 0.8 / 0.2 blend of `upscale.py` and Lanczos (in-app A/B 2026-11-10,
#352): `deliver` and `objects` read the upscaled plate (cached in the upscaler's cache folder). If
the model or onnxruntime is unavailable they fail loudly; `--no-upscale` ships the original take
on purpose (and says so). The JSON's coordinates stay in the original plate's pixels.
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
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO / "tools" / "assets"))
from process_assets import srgb_to_lab  # noqa: E402
import heic  # noqa: E402

PLATES = REPO / "design" / "art" / "plates"
RESOURCES = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
JSON_DIR = RESOURCES / "Plates"
DEFAULT_SIZE = (1536, 1024)
SIZE = DEFAULT_SIZE
#: Set by --no-upscale.
SCALE_UP = True
#: ASTC bytes. Was 8 MB for the original take; the x2 plate alone is 6.3 MB (8.27 MB in all), so 9 MB (PlateMath).
BUDGET = 9_000_000  # per state (the largest one)
#: How much of the lawn's colour cast the character tint keeps (the rest is its luminance), per
#: light: by day half (the sprites are painted for the day plate and the lawn's cast is slight);
#: at golden hour and night all of it (the cast is the light).
TINT_CAST = {"day": 0.5, "golden": 1.0, "night": 1.0, "rain": 0.5}
#: The key light on the characters (docs/design/visual-system.md "Characters"), per light: the rim's
#: strength (the key colour mixed in over the side gradient), the night's ground pool, and, for every
#: state, the lawn-colour bounce on a sprite's lower third. Overridable in the hand data's
#: `characterLight`.
CHARACTER_LIGHT = {"rim": {"day": 0.0, "golden": 0.40, "night": 0.40}, "fill": {"day": 0.0, "golden": 0.20, "night": 0.0},
                   "pool": {"day": 0.0, "golden": 0.0, "night": 0.35},
                   "bounce": 0.12}
#: Night: the characters' tops stay this many L* under the brightest lawn stone around them
#: (a sprite's brightest fur is `SPRITE_L`; art units of the residents' boxes: `SPRITE_WIDTH`).
STONE_MARGIN = {"night": 7.0}
SPRITE_L = 97.0
SPRITE_WIDTH = {"mochi": 30.4, "findik": 28.666, "damla": 38.267}
#: A lamp's glow centre sits this many plate pixels above its base on the ground.
LAMP_HEIGHT = 30.0
#: Plates ship upscaled by UPSCALE x2 at MIX of the model, the rest Lanczos.
UPSCALE = 2
MIX = 0.8
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
    COLOR_FIT.clear()
    for key, fit in hand.get("colorFit", {}).items():
        light, stage = key.split(":")
        COLOR_FIT[(REPO / hand["plates"][light][stage]).resolve()] = fit
    return hand


#: Plate path -> its `colorFit` (hand data, `{"<light>:<stage>": {band: {hue, dh, chroma}}}`), filled by `load_hand`.
COLOR_FIT: dict[Path, dict] = {}


def _lab(rgb: np.ndarray) -> np.ndarray:
    return heic._lab(rgb * 255.0)


def _from_lab(lab: np.ndarray) -> np.ndarray:
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], -1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) * 27 / 24389) * np.array([0.95047, 1.0, 1.08883])
    lin = xyz @ np.linalg.inv(np.array([[0.4124564, 0.2126729, 0.0193339],
                                        [0.3575761, 0.7151522, 0.1191920],
                                        [0.1804375, 0.0721750, 0.9503041]]))
    lin = np.clip(lin, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)


def color_fit(rgb: np.ndarray, fit: dict) -> np.ndarray:
    """Moves a take's colour bands toward the series without repainting it: per band, the pixels
    whose CIELAB hue lies in `hue` [lo, hi] (soft 15 degree edges, and a chroma gate so greys stay)
    turn by `dh` degrees and take `chroma` times their chroma; lightness and detail are kept."""
    lab = _lab(rgb)
    a, b = lab[..., 1], lab[..., 2]
    c, h = np.hypot(a, b), np.degrees(np.arctan2(b, a)) % 360
    gate = smooth(4, 10, c)
    for band in fit.values():
        lo, hi = band["hue"]
        w = smooth(lo - 15, lo, h) * (1 - smooth(hi, hi + 15, h)) * gate
        hn = np.radians(h + w * band.get("dh", 0))
        cn = c * (1 + w * (band.get("chroma", 1) - 1))
        a, b = cn * np.cos(hn), cn * np.sin(hn)
        c, h = cn, np.degrees(hn) % 360
    out = _from_lab(np.stack([lab[..., 0], a, b], -1))
    return np.clip(out, 0, 1)


def fitted(rgb: np.ndarray, path: Path) -> np.ndarray:
    fit = COLOR_FIT.get(Path(path).resolve())
    return color_fit(rgb, fit) if fit else rgb


def load_rgb(path: Path) -> np.ndarray:
    im = Image.open(path).convert("RGB")
    if im.size != SIZE:
        raise SystemExit(f"{path}: the plate is {im.size[0]} x {im.size[1]}, not {SIZE[0]} x {SIZE[1]}")
    return fitted(np.asarray(im, np.float64) / 255, path)


def upscaled_plate(path: Path, scale: int = UPSCALE, mix: float = MIX) -> np.ndarray:
    """The plate x`scale`, `mix` of the upscaler and the rest Lanczos, as RGB floats. Cached by the
    picture's hash. Fails loudly (never ships the original by accident)."""
    import hashlib

    import upscale

    key = hashlib.sha256(path.read_bytes() + f"|{scale}|{mix}|general-x4v3".encode()).hexdigest()[:20]
    cached = upscale.cache_dir() / "plates" / f"{key}.png"
    if not cached.exists():
        try:
            im = Image.open(path).convert("RGB")
            big = upscale.blend_image(im, scale, mix)
        except Exception as e:  # missing onnxruntime, weights, network
            raise SystemExit(
                f"upscale failed for {path.name}: {e!r}\n"
                "the plate would ship at its original resolution; install onnxruntime and fetch the "
                "model (tools/plate/README.md), or pass --no-upscale to ship the original on purpose")
        cached.parent.mkdir(parents=True, exist_ok=True)
        big.save(cached)
    return fitted(np.asarray(Image.open(cached).convert("RGB"), np.float64) / 255, path)


def source_plate(path: Path) -> tuple[np.ndarray, int]:
    """(rgb, k): the plate to cut assets from and its scale over the original (1 with --no-upscale)."""
    rgb = load_rgb(path)
    if not SCALE_UP:
        print(f"WARNING: --no-upscale: {path.name} ships at its original resolution")
        return rgb, 1
    big = upscaled_plate(path)
    if big.shape[:2] != (SIZE[1] * UPSCALE, SIZE[0] * UPSCALE):
        raise SystemExit(f"{path}: upscaled to {big.shape[1]} x {big.shape[0]}, expected x{UPSCALE}")
    return big, UPSCALE


def scaled_matte(a: np.ndarray, k: int) -> np.ndarray:
    if k == 1:
        return a
    m = Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5)).resize((a.shape[1] * k, a.shape[0] * k), Image.Resampling.LANCZOS)
    return np.asarray(m, np.float64) / 255


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


def present(obj: dict, light: str, stage: int) -> bool:
    """Whether the object is painted in the state: `stages` lists the stages that show it (absent:
    all), for every light: a night stage is the day stage's island level (Home's night IL2 to IL9
    paints the level's own buildings, not the level-10 set)."""
    return "stages" not in obj or stage in obj["stages"]


def asset_name(island: str, kind: str, light: str, stage: int, oid: str | None = None) -> str:
    return f"world-{island}-{kind}-{oid}-{light}-{stage}" if oid else f"world-{island}-{kind}-{light}-{stage}"


def write_imageset(name: str, img: Image.Image, jpeg: bool = False) -> Path:
    folder = ASSETS / f"{name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    for old in folder.glob(f"{name}.*"):
        if old.suffix in (".png", ".jpg", heic.SUFFIX):
            old.unlink()
    # Layers with alpha (plate, island, occluder) ship as HEIC q70 (ADR-0024); the backdrop has none: JPEG.
    filename = f"{name}.jpg" if jpeg else f"{name}{heic.SUFFIX}"
    if jpeg:
        img.convert("RGB").save(folder / filename, "JPEG", quality=90, optimize=True)
    else:
        heic.save(img, folder / filename)
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
    """The state's matte; a state without its own (golden, night, the lower island levels share
    the level-10 day geometry, checked pixel for pixel) takes the first plate's."""
    path = matte_path(island, light, stage)
    if not path.exists():
        path = matte_path(island, "day", 0)
    return np.asarray(Image.open(path).convert("L"), np.float64) / 255


def cmd_matte(island: str, state: str | None = None) -> None:
    """Writes the mattes of every plate, or of the one `--state <light>:<stage>` only (the other
    mattes are committed and stay as they are)."""
    hand = load_hand(island)
    for light, stage, path in plates(hand):
        if state is not None and f"{light}:{stage}" != state:
            continue
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


def calm_sea(rgb: np.ndarray, a: np.ndarray, width: int, px: int, pw: int, up: float, scale: float) -> np.ndarray:
    """One colour per column for the sea below a landscape plate: the plate's bottom band (the
    island's roots filled out), averaged over its rows, blurred across the plate's width and
    lightened toward a quiet mist as it runs down. It carries the plate's own left-to-right
    gradient and no puff: a landscape plate on a portrait screen has a quarter of the screen of
    sea under it, behind the bottom UI, and a repeated cloud band there reads as haze."""
    cut = round(rgb.shape[0] * 0.90)
    band = fill_holes(rgb[cut:].copy(), ndimage.binary_dilation(a[cut:] > 0.1, iterations=10))
    cols = band.mean(0)
    cols = resize(cols[None], pw, 1)[0]
    lpad, rpad = max(px, 0), max(width - px - pw, 0)
    cols = np.concatenate([np.repeat(cols[:1], lpad, 0), cols, np.repeat(cols[-1:], rpad, 0)], 0)
    cols = cols[max(-px, 0):max(-px, 0) + width]
    return ndimage.gaussian_filter1d(cols, max(2, pw / 10), axis=0, mode="nearest")


def backdrop(rgb: np.ndarray, a: np.ndarray, box: tuple[int, int, int, int], scale: float = BACKDROP_SCALE, calm: bool = False) -> np.ndarray:
    """The plate's own sky and cloud sea continued past its edges, in `box` (plate pixels), at
    `scale` (as `pilot.painted_frame`): above, the plate's top sky deepens upward; at the sides the
    plate mirrors; below, its cloud band (the roots filled out) repeats at growing sizes, mirrored
    and offset, so no puff repeats at one size. Inside the plate's rectangle it is the plate."""
    bx0, by0, bx1, by1 = box
    W, H = round((bx1 - bx0) * scale), round((by1 - by0) * scale)
    pw, ph = round(SIZE[0] * scale), round(SIZE[1] * scale)
    up = rgb.shape[1] / SIZE[0]  # the picture's scale over the original plate (the upscaled one is 2)
    px, py = round(-bx0 * scale), round(-by0 * scale)
    small = resize(rgb, pw, ph)
    sa = resize(np.repeat(a[..., None], 3, 2), pw, ph)[..., 0]
    canvas = np.zeros((H, W, 3))
    # Above: the plate's top sky, column by column (mirrored past its sides, blurred), deepening
    # upward toward one zenith tone, so its own left-to-right gradient runs on with no seam.
    # The median over the rows, and over columns a quarter of the plate wide: a moon or a sun glow
    # at the top edge must not run up the sky as a stripe.
    top = np.median(small[: max(3, round(0.03 * ph))], axis=0)
    top = ndimage.median_filter(top, size=(max(3, round(0.22 * pw)), 1), mode="nearest")
    lpad, rpad = max(px, 0), max(W - (px + pw), 0)
    # Past the plate's sides the edge column runs on (a mirror would make a ridge of the plate's
    # left-to-right gradient at each edge).
    cols = np.concatenate([np.repeat(top[:1], lpad, 0), top, np.repeat(top[-1:], rpad, 0)], axis=0) if (lpad or rpad) else top
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
    if calm:
        # Below: a calm sea, one colour field running down and lightening to mist (`calm_sea`).
        sea = calm_sea(rgb, a, W, px, pw, up, scale)
        y0 = py + ph - round(0.10 * ph)
        yy = np.arange(max(H - y0, 0))[:, None, None]
        mist = np.clip(sea.mean(0) * 0.5 + np.array([0.93, 0.93, 0.98]) * 0.5, 0, 1)
        t = smooth(0, max(H - y0, 1) * 0.9, yy) * 0.55
        canvas[y0:] = sea[None] * (1 - t) + mist * t
    else:
        # Below: the cloud band (full resolution, the island's roots filled out), repeated from the
        # plate's foot down, each copy resized once from the full-resolution band.
        cut = round(rgb.shape[0] * 0.86)
        band = rgb[cut:].copy()
        band = fill_holes(band, ndimage.binary_dilation(a[cut:] > 0.1, iterations=10))
        y, i = py + ph - round(0.06 * ph), 0
        while y < H:
            k = min(1.6 * 1.4 ** i, 6.0) * scale / up
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
        rgb, k = source_plate(path)
        a1 = load_matte(island, light, stage)
        a = scaled_matte(a1, k)
        write_imageset(asset_name(island, "plate", light, stage), feathered_plate(rgb, a, FEATHER * k))
        x0, y0, x1, y1 = bbox(a1, 0.02)
        cut = np.dstack([rgb, np.clip(a, 0, 1)])[y0 * k:y1 * k, x0 * k:x1 * k]
        img = to_img(cut)
        # The Map's island stays at its size in original-plate pixels (it is drawn small).
        img = img.resize((round((x1 - x0) * ISLAND_SCALE), round((y1 - y0) * ISLAND_SCALE)), Image.Resampling.LANCZOS)
        write_imageset(asset_name(island, "island", light, stage), img)
        box = backdrop_box(home_frame(hand, a1))
        write_imageset(asset_name(island, "backdrop", light, stage), to_img(backdrop(rgb, a, box, hand.get("backdropScale", BACKDROP_SCALE), calm=hand.get("backdrop") == "calm")), jpeg=True)
        print(f"deliver {light} {stage} (x{k}): island box {(x0, y0, x1, y1)}, backdrop box {box}")


# ---------------------------------------------------------------- objects

def occluder_cut(rgb: np.ndarray, a: np.ndarray, pts_px, pad: int = 4) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """The plate's pixels inside an object's polygon and the matte, feathered 1 px, in its box."""
    return _occluder_cut(rgb, a, pts_px, pad)


def _occluder_cut(rgb, a, pts_px, pad, box=None):
    m = poly_mask(a.shape, pts_px).astype(np.float64)
    m = np.minimum(ndimage.gaussian_filter(m, 1.0), np.clip(a, 0, 1))
    if box is None:
        x0, y0, x1, y1 = bbox(m, 0.02)
        x0, y0 = max(x0 - pad, 0), max(y0 - pad, 0)
        x1, y1 = min(x1 + pad, a.shape[1]), min(y1 + pad, a.shape[0])
    else:
        x0, y0, x1, y1 = box
    return np.dstack([rgb, m])[y0:y1, x0:x1], (x0, y0, x1, y1)


def cmd_objects(island: str) -> None:
    hand = load_hand(island)
    for light, stage, path in plates(hand):
        rgb, k = source_plate(path)
        a1 = load_matte(island, light, stage)
        a = scaled_matte(a1, k)
        for obj in hand["objects"]:
            if not obj.get("occluder") or not present(obj, light, stage):
                continue
            poly = pct_to_px(obj["points"])
            # The box is the metadata's (original-plate pixels); the picture covers it exactly, x k.
            _, box = occluder_cut(np.zeros(a1.shape + (3,)), a1, poly)
            cut, _ = _occluder_cut(rgb, a, [[x * k, y * k] for x, y in poly], 4 * k, tuple(v * k for v in box))
            write_imageset(asset_name(island, "occ", light, stage, obj["id"]), to_img(cut))
            print(f"occluder {obj['id']} {light} {stage} (x{k}): box {box}")


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


# ---------------------------------------------------------------- character harmony

def srgb_to_linear(c: np.ndarray) -> np.ndarray:
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c: np.ndarray) -> np.ndarray:
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def lawn_samples(rgb: np.ndarray, walk: np.ndarray, spots, radius: float) -> dict:
    """What the plate shows where characters stand: the lawn's mid-tone (walkable pixels between
    the 25th and 75th L* percentile) overall and around each contact point (within `radius`),
    as mean linear RGB, and the lawn's own shadow depth there (L* p90 - p10)."""
    h, w = walk.shape
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    L = lab[..., 0]
    lin = srgb_to_linear(rgb)
    yy, xx = np.mgrid[0:h, 0:w]

    def mid(mask: np.ndarray):
        l = L[mask]
        keep = (l >= np.percentile(l, 25)) & (l <= np.percentile(l, 75))
        return lin[mask][keep].mean(0), float(np.percentile(l, 90) - np.percentile(l, 10))

    ambient, _ = mid(walk)
    near, depth = [], []
    for x, y in spots:
        disc = walk & ((xx - x) ** 2 + (yy - y) ** 2 <= radius ** 2)
        if disc.sum() < 50:
            continue
        c, d = mid(disc)
        near.append(c)
        depth.append(d)
    return {"ambient": ambient, "contact": np.mean(near, 0), "depth": float(np.mean(depth))}


def lawn_chroma(rgb: np.ndarray, walk: np.ndarray) -> float:
    """The walkable lawn's colourfulness: the mean CIELAB chroma of its mid-tone (25th to 75th L*
    percentile)."""
    lab = srgb_to_lab(np.clip(rgb, 0, 1))
    l = lab[..., 0][walk]
    c = np.hypot(lab[..., 1], lab[..., 2])[walk]
    keep = (l >= np.percentile(l, 25)) & (l <= np.percentile(l, 75))
    return float(c[keep].mean())


#: How far a sprite's chroma follows the lawn's (`saturation` in a state's harmony data): the
#: lawn's chroma over the reference plate's to this power, never under `SATURATION_FLOOR`.
SATURATION_POWER = 0.6
SATURATION_FLOOR = 0.5


def key_colour(rgb: np.ndarray, hand: dict, walk: np.ndarray, light: str) -> list[float]:
    """The key light's colour, read from the plate (sRGB): at night the lamps' glow (the bright
    half of a disc around each lamp's lantern), otherwise the lit stones (the walkable lawn's top
    10 % L*)."""
    lab = srgb_to_lab(np.clip(rgb, 0, 1))[..., 0]
    h, w = lab.shape
    lamps = [(x, y - LAMP_HEIGHT) for x, y in pct_to_px(hand.get("lamps", []))]
    if light == "night" and lamps:
        yy, xx = np.mgrid[0:h, 0:w]
        picks = []
        for x, y in lamps:
            disc = (xx - x) ** 2 + (yy - y) ** 2 <= 12 ** 2
            picks.append(rgb[disc & (lab >= np.percentile(lab[disc], 60))].mean(0))
        c = np.mean(picks, 0)
    else:
        c = rgb[walk & (lab >= np.percentile(lab[walk], 90))].mean(0)
    return [round(float(v), 3) for v in c]


def stone_levels(rgb: np.ndarray, hand: dict, walk: np.ndarray) -> dict:
    """Per character, the brightest lawn stone around it: the walkable lawn's L* p95 in a ring 0.8 to
    2.4 character widths out, outside every character's disc (`tools/plate/harmony_check.py`
    measures the same ring in the app frame)."""
    h, w = walk.shape
    L = srgb_to_lab(np.clip(rgb, 0, 1))[..., 0]
    yy, xx = np.mgrid[0:h, 0:w]
    pw = hand["pofuWidth"] * SIZE[0] / 100
    boosts = hand.get("residentBoosts", {})
    spots = {k: pct_to_px([v])[0] for k, v in hand["characters"].items()}
    widths = {k: pw if k == "pofu" else SPRITE_WIDTH[k] * pw / 64 * boosts.get(k, hand.get("residentBoost", 1.0)) for k in spots}
    near = np.zeros((h, w), bool)
    for k, (x, y) in spots.items():
        near |= (xx - x) ** 2 + (yy - y) ** 2 <= (0.8 * widths[k]) ** 2
    out = {}
    for k, (x, y) in spots.items():
        d2 = (xx - x) ** 2 + (yy - y) ** 2
        ring = walk & ~near & (d2 >= (0.8 * widths[k]) ** 2) & (d2 <= (2.4 * widths[k]) ** 2)
        out[k] = float(np.percentile(L[ring], 95))
    return out


def lstar_to_srgb(lstar: float) -> float:
    """The grey sRGB value whose lightness is `lstar`."""
    f = (lstar + 16) / 116
    y = f ** 3 if f ** 3 > 0.008856 else (f - 16 / 116) / 7.787
    return float(linear_to_srgb(np.array(y)))


def lawn_ratio(rgb: np.ndarray, hand: dict, ref: dict) -> np.ndarray:
    """A plate's lawn light over the reference's, per channel (linear), clipped to 0.25...1: the
    tint before its cast is set (`harmony_state`)."""
    walk = poly_mask(rgb.shape[:2], pct_to_px(hand["walkable"]))
    s = lawn_samples(rgb, walk, list(pct_to_px_pts(hand)), hand["pofuWidth"] * SIZE[0] / 100 * 0.9)
    return np.clip(np.sqrt(s["ambient"] * s["contact"]) / np.maximum(ref["_a"], 1e-4), 0.25, 1.0)


LUMA = np.array([0.2126, 0.7152, 0.0722])


def harmony_state(rgb: np.ndarray, hand: dict, ref: dict | None, light: str = "day", stage: int = 0,
                  cast_from: dict | None = None) -> dict:
    """The character harmony rule (docs/design/visual-system.md "Characters"): per state one
    ambient multiply tint, one contact-shadow strength and the key light, read from the plate.

      A     the plate's lawn light: the geometric mean of the walkable lawn's mid-tone and the
            mid-tone around the three contact points (linear RGB)
      tint  A of the state over A of the level-10 day plate, per channel, at most 1 (a multiply
            only darkens: the day sprites are painted for the day plate), with `TINT_CAST[light]`
            of its colour cast (day half, golden hour and night all of it); at night never lighter
            than `STONE_MARGIN` L* under the brightest lawn stone around any character (a sprite's
            top is `SPRITE_L` L*; the margin leaves room for the key light's lift), and each
            character's own `scale` of it where its stones are darker
      contact  the lawn's shadow depth around the contact points over the day's, 0.5...1.2
      key   the key light's colour (`key_colour`), `rim` its strength on the lit side, `pool` the
            night lamp pool's strength (only where the stage's level, `stageLevels[stage]`, is at
            least `lampsFromLevel`: the lamps are not lit below it), `bounce` the lawn-colour
            bounce on the lower third
    """
    walk = poly_mask(rgb.shape[:2], pct_to_px(hand["walkable"]))
    spots = list(pct_to_px_pts(hand))
    s = lawn_samples(rgb, walk, spots, hand["pofuWidth"] * SIZE[0] / 100 * 0.9)
    a = np.sqrt(s["ambient"] * s["contact"])
    cl = {**CHARACTER_LIGHT, **hand.get("characterLight", {})}
    chroma = lawn_chroma(rgb, walk)
    if ref is None:
        return {"tint": [1.0, 1.0, 1.0], "contact": 1.0, "bounce": cl["bounce"], "_a": a, "_depth": s["depth"], "_chroma": chroma}
    ratio = np.clip(a / np.maximum(ref["_a"], 1e-4), 0.25, 1.0)
    luma = float(ratio @ LUMA)
    cast = TINT_CAST.get(light, 0.5)
    # The lawn's light sets the lightness in full and the colour cast by TINT_CAST.
    ratio = np.clip(luma + (ratio - luma) * cast, 0.25, 1.0)
    if cast_from is not None:
        # One cast for the whole light (`characterLight.castFrom`): the lightness is this plate's
        # own (a lawn's cast moves from level to level; the characters' colour must not), the
        # colour is the root state's, `castOwn` of this plate's kept; the key light's colour too.
        own = cl.get("castOwn", 0.0)
        ratio = np.clip(luma * (cast_from["tint"] + (ratio / luma - cast_from["tint"]) * own), 0.25, 1.0)
    tint = linear_to_srgb(ratio)
    scales: dict[str, float] = {}
    margins = {**STONE_MARGIN, **cl.get("stoneMargin", {})}
    if light in margins:
        # The brightest stone around each character caps its own top; the shared tint is capped by
        # the brightest of them and each darker neighbourhood scales its character down from it.
        stones = stone_levels(rgb, hand, walk)
        def cap(stone: float) -> float:
            return lstar_to_srgb(stone - margins[light]) / (lstar_to_srgb(SPRITE_L) * float(tint.mean()))
        tint = np.clip(tint * min(1.0, max(cap(v) for v in stones.values())), 0.25, 1.0)
        top = max(cap(v) for v in stones.values())
        scales = {k: round(min(1.0, cap(v) / top), 3) for k, v in stones.items()}
    contact = float(np.clip(s["depth"] / max(ref["_depth"], 1e-4), 0.5, 1.2))
    out = {"tint": [round(float(v), 4) for v in tint], "contact": round(contact, 3), "_a": a, "_depth": s["depth"], "_chroma": chroma}
    if cl.get("saturate"):
        # A plate paler than the reference (Çağlayan's dry stages) asks the sprite to be less
        # colourful than the lawn it stands on: a multiply cannot take chroma out.
        sat = float(np.clip((chroma / max(ref["_chroma"], 1e-4)) ** SATURATION_POWER, SATURATION_FLOOR, 1.0))
        if sat < 0.995:
            out["saturation"] = round(sat, 3)
    rim = cl["rim"].get(light, 0.0)
    if rim > 0:
        out["key"] = cast_from["key"] if cast_from is not None else key_colour(rgb, hand, walk, light)
        out["rim"] = rim
        out["fill"] = cl["fill"].get(light, 0.0)
    pool = cl["pool"].get(light, 0.0)
    if pool > 0 and hand.get("lamps") and lamps_lit(hand, stage):
        out["pool"] = pool
    out["bounce"] = cl["bounce"]
    if scales:
        out["scale"] = scales
    return out


def lamps_lit(hand: dict, stage: int) -> bool:
    """Whether the stage's level has its lamps lit (`lampsFromLevel`; absent: every stage does)."""
    first = hand.get("lampsFromLevel")
    levels = hand.get("stageLevels")
    return first is None or not levels or levels[stage] >= first


def pct_to_px_pts(hand: dict):
    for _, p in sorted(hand["characters"].items()):
        yield pct_to_px([p])[0]


#: A state's harmony data where the island does not paint it (a sparse light): the arrays are
#: indexed by stage and the runtime never asks for it.
UNPAINTED_HARMONY = {"tint": [1.0, 1.0, 1.0], "contact": 1.0}


def stage_count(hand: dict, light: str) -> int:
    """How many stages a light's arrays hold: the highest painted stage + 1 (a light painted at
    some stages only, as Çağlayan's night, pads the others)."""
    return max(int(s) for s in hand["plates"][light]) + 1


def is_sparse(hand: dict) -> bool:
    return any(sorted(int(s) for s in st) != list(range(len(st))) for st in hand["plates"].values())


def painted_stages(hand: dict) -> dict:
    return {l: sorted(int(s) for s in st) for l, st in sorted(hand["plates"].items())}


def cast_roots(hand: dict, ref: dict) -> dict:
    """`characterLight.castFrom` `{light: stage}`: per light the root state whose tint colour (its
    lawn ratio over the reference's, at the luma of 1) and key colour every state of the light
    keeps, so that a character's colour does not change from one level's night to the next (the
    lamps' glow is read from a plate where they are not lit, too: a blue, unlit one)."""
    out = {}
    for light, stage in hand.get("characterLight", {}).get("castFrom", {}).items():
        rgb = load_rgb(REPO / hand["plates"][light][str(stage)])
        r = lawn_ratio(rgb, hand, ref)
        luma = float(r @ LUMA)
        r = np.clip(luma + (r - luma) * TINT_CAST.get(light, 0.5), 0.25, 1.0)
        walk = poly_mask(rgb.shape[:2], pct_to_px(hand["walkable"]))
        out[light] = {"tint": r / float(r @ LUMA), "key": key_colour(rgb, hand, walk, light)}
    return out


def harmony_all(hand: dict, mattes: dict) -> dict:
    """`{light: [{tint, contact}, ...]}` per painted state, against the reference plate's lawn
    (`referenceState` in the hand data, else the first plate: the island's picked root), by stage."""
    ref = None
    if "referenceState" in hand:
        light, stage = hand["referenceState"]
        ref = harmony_state(load_rgb(REPO / hand["plates"][light][str(stage)]), hand, None, light)
    out: dict[str, dict[int, dict]] = {}
    casts = None
    for light, stage, path in plates(hand):
        if ref is not None and casts is None:  # the island's root state is the first plate: its lawn is `ref`
            casts = cast_roots(hand, ref)
        h = harmony_state(load_rgb(path), hand, ref, light, stage, (casts or {}).get(light))
        if ref is None:
            ref = h
        h = {k: v for k, v in h.items() if not k.startswith("_")}
        # A trim measured in the app frame (`harmony_check.py`) where the plate's own stone reading
        # and the frame's ring disagree: `characterLight.scaleTrim["<light>:<stage>"][<character>]` and `characterLight.saturationTrim["<light>:<stage>"]`.
        trims = hand.get("characterLight", {})
        for name, trim in trims.get("scaleTrim", {}).get(f"{light}:{stage}", {}).items():
            h["scale"][name] = round(h["scale"][name] * trim, 3)
        if f"{light}:{stage}" in trims.get("saturationTrim", {}):
            h["saturation"] = round(h.get("saturation", 1.0) * trims["saturationTrim"][f"{light}:{stage}"], 3)
        out.setdefault(light, {})[stage] = h
    return {l: [st.get(i, dict(UNPAINTED_HARMONY)) for i in range(stage_count(hand, l))] for l, st in out.items()}


# ---------------------------------------------------------------- json

def texture_bytes(island: str, hand: dict) -> int:
    """ASTC 4 x 4: one byte per pixel, the largest state's images (plate, island, backdrop,
    occluders): the app holds one state, or two for the length of a crossfade."""
    worst = 0
    for light, stage, _ in plates(hand):
        total = 0
        for folder in ASSETS.glob(f"world-{island}-*-{light}-{stage}.imageset"):
            # Only this tool's layers: a sky set's layers (`world-<island>-sky-*`) are the sky set's
            # own budget (skyset-<island>.json), and the plate and its backdrop are not loaded while it draws.
            if not folder.name.startswith(tuple(f"world-{island}-{kind}-" for kind in ("plate", "island", "backdrop", "occ"))):
                continue
            for f in folder.iterdir():
                if f.suffix in (".png", ".jpg", heic.SUFFIX):
                    with heic.open_image(f) as im:
                        total += im.width * im.height
        worst = max(worst, total)
    return worst


def build_json(island: str, hand: dict, mattes: dict, maps: dict, harmony: dict | None = None) -> dict:
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
        if "stages" in obj:
            entry["stages"] = obj["stages"]
        if obj.get("occluder"):
            _, box = occluder_cut(np.zeros(a.shape + (3,)), a, poly)
            entry["box"] = list(box)
        objects.append(entry)
    lights = sorted(hand["plates"])
    data = {
        "island": island,
        "version": 1,
        "standIn": bool(hand.get("standIn", False)),
        "minLevel": hand.get("minLevel", 1),
        "plateSize": list(SIZE),
        "stages": max(int(s) for st in hand["plates"].values() for s in st) + 1,
        "lights": lights,
        "lightStages": {l: stage_count(hand, l) for l in lights},
        "stageLevels": hand.get("stageLevels", [hand.get("minLevel", 1)]),
        "harmony": harmony or {},
        "islandBox": list(bbox(a, 0.02)),
        "backdropBox": list(backdrop_box(home_frame(hand, a))),
        "feather": FEATHER,
        "objects": objects,
        "walkable": pct_to_px(hand["walkable"]),
        "characters": {k: pct_to_px([v])[0] for k, v in sorted(hand["characters"].items())},
        "pofuWidth": round(hand["pofuWidth"] * SIZE[0] / 100, 1),
        "framing": hand["framing"],
        "residentBoost": hand.get("residentBoost", 1.0),
        "residentBoosts": hand.get("residentBoosts", {}),
        "lamps": pct_to_px(hand.get("lamps", [])),
        "lampHeight": LAMP_HEIGHT,
        "lightDirection": hand.get("lightDirection", [0.5, 0.3]),
        "lightMap": {l: [maps[(l, s)][0] if (l, s) in maps else [] for s in range(stage_count(hand, l))] for l in lights},
        "shadowMap": {l: [maps[(l, s)][1] if (l, s) in maps else [] for s in range(stage_count(hand, l))] for l in lights},
        "textureBytes": texture_bytes(island, hand),
    }
    if is_sparse(hand):
        data["painted"] = painted_stages(hand)
    if hand.get("backdrop"):
        data["backdropStyle"] = hand["backdrop"]
    return data


def cmd_json(island: str) -> Path:
    hand = load_hand(island)
    mattes, maps = {}, {}
    for light, stage, path in plates(hand):
        a = load_matte(island, light, stage)
        mattes[(light, stage)] = a
        maps[(light, stage)] = light_map(load_rgb(path), a)
    data = build_json(island, hand, mattes, maps, harmony_all(hand, mattes))
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
        for stage in data.get("painted", {}).get(light, range(data.get("lightStages", {}).get(light, data["stages"]))):
            for kind in ("plate", "island", "backdrop"):
                if asset_name(island, kind, light, stage) not in assets:
                    out.append(f"missing asset {asset_name(island, kind, light, stage)}")
            for obj in data["objects"]:
                if "stages" in obj and stage not in obj["stages"]:
                    continue
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
    ap.add_argument("command", choices=["matte", "deliver", "objects", "json", "check", "all"])
    ap.add_argument("island")
    ap.add_argument("--state", metavar="LIGHT:STAGE",
                    help="matte only: write the matte of this state only (e.g. day:9)")
    ap.add_argument("--no-upscale", action="store_true",
                    help="ship the original take (only when the model is unavailable; loud on purpose)")
    args = ap.parse_args(argv)
    heic.require()  # fail before any work, like the upscaler
    global SCALE_UP
    SCALE_UP = not args.no_upscale
    if args.command == "matte":
        cmd_matte(args.island, args.state)
    elif args.command == "deliver":
        cmd_deliver(args.island)
    elif args.command == "objects":
        cmd_objects(args.island)
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
