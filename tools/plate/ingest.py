#!/usr/bin/env python3
"""Ingest a painted plate for a plate-first island (ADR-0022, docs/design/plate-islands.md §0).

Reads the hand data `design/art/plates/<island>/objects.json` (plate paths, the silhouette trace,
tap and occluder polygons, the walkable lawn, the characters' spots and the framing, all in percent
of the plate) and writes what the app draws:

  World.xcassets/world-<island>-plate-<light>-<stage>     the whole plate, opaque, its border
                                                          feathered (the island and its own sky); a
                                                          strict-matte island's (Home's): the island alone,
                                                          alpha its matte, cropped to it (`plateCrop`), drawn
                                                          over the sky set (one sky at every level)
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
            texture budget past `texture-budget.json`'s limit

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

import cv2
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
#: Texture pixels a Home state may hold; each decodes to 4 bytes (8-bit RGBA). Rule v1, docs/design/texture-budget-v1.md
BUDGET = json.loads((JSON_DIR / "texture-budget.json").read_text())["statePixels"]  # per state (the largest one)
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
#: Islands whose every state has its own full-size matte (`matte-<light>-<stage>.png`, plate size x `MATTE_TEX`, made by
#: `tools/proof/island_matte.py`, the r3b solve). Their plate's alpha *is* that matte (feather 0); a missing master is an
#: error, never the level-10 matte (which put the level-10 sky behind every lower level).
STRICT_MATTES = {"home"}
MATTE_TEX = 2
#: The island's contact shadow (`island_shadow` in tools/proof/island_matte.py): the share of the underside it covers,
#: how far below the foot it sits (x half the island's height), its squash and blur (x half the underside's width).
SHADOW = {"opacity": 0.34, "drop": 0.9, "squash": 0.22, "reach": 0.92, "blur": 0.06, "underside": 0.55}


# ---------------------------------------------------------------- basics

#: The painted seasons other than spring (season-system-v1 D3): a state's key is `<season>-<light>` in them.
SEASONS = ("autumn", "winter")


def split_light(light: str) -> tuple[str | None, str]:
    """`("autumn", "day")` for the key `autumn-day`, `(None, "day")` for a spring light."""
    season, _, rest = light.partition("-")
    return (season, rest) if season in SEASONS and rest else (None, light)


def base_light(light: str) -> str:
    """The light a key paints (`day`, `golden`, `night`): every table keyed by a light name reads a season's key through this."""
    return split_light(light)[1]


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
    """(light, stage, path) for every plate in the hand data: spring's lights first (the first plate is the island's root,
    the harmony reference), then each season's (`<season>-<light>`)."""
    for light, stages in sorted(hand["plates"].items(), key=lambda kv: (split_light(kv[0])[0] or "", kv[0])):
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
    """The state's matte file. A season state has none of its own (D2): it is cut with its spring state's shape, never by
    difference, so it reads the matte of the same light and stage in spring."""
    return PLATES / island / f"matte-{base_light(light)}-{stage}.png"


def is_legacy(hand: dict, light: str, stage: int) -> bool:
    """A state that keeps its pre-r3b assets and matte (hand data `legacyStates`, "<light>:<stage>"): the cut cannot be
    solved there yet. `matte`, `deliver` and `objects` leave it as it is."""
    return f"{base_light(light)}:{stage}" in hand.get("legacyStates", [])


def load_matte_full(island: str, light: str, stage: int) -> np.ndarray:
    """The state's matte at its own size (a Home master is plate size x `MATTE_TEX`). Islands in `STRICT_MATTES` must have
    one per state; the others share the first plate's where a state has none (golden, night and the lower levels were
    checked pixel for pixel against it)."""
    path = matte_path(island, light, stage)
    if not path.exists():
        if island in STRICT_MATTES:
            raise FileNotFoundError(f"{path}: {island} has no matte for {light}:{stage} (run `ingest.py matte {island}`)")
        path = matte_path(island, "day", 0)
    return np.asarray(Image.open(path).convert("L"), np.float64) / 255


def load_matte(island: str, light: str, stage: int) -> np.ndarray:
    """The state's matte at plate size (the size the hand data's percents and every consumer here use)."""
    a = load_matte_full(island, light, stage)
    # the hand data's size, read here too: tools/proof/island_matte.py calls this without `load_hand`
    w, h = json.loads((PLATES / island / "objects.json").read_text()).get("size", DEFAULT_SIZE) if island in STRICT_MATTES else SIZE
    if a.shape != (h, w):
        a = cv2.resize(a.astype(np.float32), (w, h), interpolation=cv2.INTER_AREA).astype(np.float64)
    return a


def master_matte(light: str, stage: int, layer: np.ndarray, origin: tuple[int, int]) -> np.ndarray:
    """The r3b layer's alpha (over its box, texture px) pasted into a canvas of the whole plate, 8 bits."""
    canvas = np.zeros((SIZE[1] * MATTE_TEX, SIZE[0] * MATTE_TEX), np.float32)
    x0, y0 = origin[0] * MATTE_TEX, origin[1] * MATTE_TEX
    h, w = layer.shape[:2]
    canvas[y0:y0 + h, x0:x0 + w] = layer[..., 3]
    return np.uint8(np.clip(canvas, 0, 1) * 255 + 0.5)


#: What the r3b solve cuts that is painted and the old matte keeps (`repair_matte`), as boxes in plate points
#: (x0, y0, x1, y1) per "<light>:<stage>": the bagel cart's pennant (level 10), the lighthouse lamp's glow (level 10 at
#: golden hour), the red flowers by the tea stall (level 5). Only here: a restored piece is a hard-edged addition to
#: the solved shape, so the gate's edge checks count every one of them.
REPAIR_BOXES = {
    "day:0": [(745, 730, 795, 775)], "golden:0": [(920, 500, 1024, 670)], "day:5": [(735, 745, 800, 795)],
}
REPAIR_CHROMA = 0.30     # a pixel this colourful (max - min of RGB) and unlike the sky is paint, not mist or cloud
REPAIR_SKY = 0.20        # distance in RGB from the local sky colour under which a pixel is sky
REPAIR_REACH = 14        # texture px: paint is restored this close to the solved shape
#: Where any pixel unlike the sky (not only a colourful one) comes back: the lamp's glow is pale.
REPAIR_PALE = {"golden:0": (920, 500, 1024, 670)}


#: Where the r3b solve bites into the island's own paint (pale soil at the rim, a lawn's edge, grass seen through haze),
#: as boxes in plate points per "<light>:<stage>": inside a box every pixel warmer or greener than it is blue (soil,
#: grass: `FILL_WARM`, the excess of red or green over blue) and joined to the island comes back (`fill_matte`); the
#: blue sky and the white clouds stay out. Found by the sweep in the one-sky PR (#485): the soil under the lawn's right
#: end at level 2, the lawn's right edge at level 1, the lawn between the workshop and the lighthouse at level 6.
FILL_BOXES = {
    "day:8": [(690, 740, 930, 1100)], "day:9": [(725, 835, 805, 985)], "day:4": [(585, 712, 650, 782)],
}
#: The excess of red or green over blue below which a pixel is sky or cloud and above which it is paint (by day).
FILL_WARM = {"day": (0.03, 0.10)}
FILL_CORE = 0.9
FILL_PINHOLE = 400   # texture px
FILL_RIM = 4         # texture px


def fill_matte(m: np.ndarray, rgb: np.ndarray, light: str, stage: int) -> np.ndarray:
    """The r3b matte (8 bit) with its bites into the paint closed inside `FILL_BOXES` (see there)."""
    boxes = FILL_BOXES.get(f"{light}:{stage}")
    if not boxes:
        return m
    a = m.astype(np.float32) / 255
    warm = np.maximum(rgb[..., 0] - rgb[..., 2], rgb[..., 1] - rgb[..., 2])
    lo, hi = FILL_WARM[light]
    paint = smooth(lo, hi, warm).astype(np.float32)
    inside = np.zeros(a.shape, np.float32)
    for x0, y0, x1, y1 in boxes:
        inside[y0 * MATTE_TEX:y1 * MATTE_TEX, x0 * MATTE_TEX:x1 * MATTE_TEX] = 1
    add = paint * inside
    # only paint joined to the island: a warm speck in the sky stays out
    lab, _ = ndimage.label((add > 0.5) | (a > 0.5))
    joined = np.isin(lab, np.unique(lab[a > 0.5]))
    add = np.where(cv2.dilate(joined.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0, add, 0)
    # the restored edge as a smooth curve: the union's outline closed and eased, a pixel soft (a ragged threshold line
    # through a translucent rim would read as a frayed edge)
    # The edge is set where the paint is nearly pure (`FILL_CORE`), so its pixels carry no sky, and it is as firm as
    # the solve's own (a pixel soft).
    union = ((a > 0.5) | (add > FILL_CORE)).astype(np.uint8)
    union = cv2.morphologyEx(union, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (21, 21)))
    union = (cv2.GaussianBlur(union.astype(np.float32), (0, 0), 3) > 0.5).astype(np.float32)
    add = cv2.GaussianBlur(union, (0, 0), 0.8) * (inside > 0.5)
    out = np.maximum(a, add)
    # a pinhole the solve left beside a restored edge closes with it
    solid = out > 0.96
    near = cv2.dilate((inside > 0.5).astype(np.uint8), np.ones((61, 61), np.uint8)) > 0
    holes = ndimage.binary_fill_holes(solid) & ~solid & near
    lab, n = ndimage.label(holes)
    if n:
        size = ndimage.sum(holes, lab, range(1, n + 1))
        out = np.where(np.isin(lab, 1 + np.flatnonzero(size <= FILL_PINHOLE)), 1.0, out)
    return np.maximum(m, np.uint8(np.clip(out, 0, 1) * 255 + 0.5))


def fill_colours(rgb: np.ndarray, a: np.ndarray, light: str, stage: int) -> np.ndarray:
    """The plate's colours with the rim of every `FILL_BOXES` region given the colour of the paint `FILL_RIM` texture px
    inside it: a restored edge runs through pixels the painting blended with its sky (a grass tip, a pale cart handle),
    and the sky behind is the sky set's, so the blend would show as a pale fringe. The solve's own rim is decontaminated
    the same way (`decontaminated`)."""
    boxes = FILL_BOXES.get(f"{light}:{stage}")
    if not boxes:
        return rgb
    inside = np.zeros(a.shape, bool)
    for x0, y0, x1, y1 in boxes:
        inside[y0 * MATTE_TEX:y1 * MATTE_TEX, x0 * MATTE_TEX:x1 * MATTE_TEX] = True
    depth = ndimage.distance_transform_edt(a > 0.5)
    deep = depth >= FILL_RIM
    _, (iy, ix) = ndimage.distance_transform_edt(~deep, return_indices=True)
    rim = inside & (a > 0.004) & ~deep
    out = rgb.copy()
    out[rim] = rgb[iy[rim], ix[rim]]
    return out


def legacy_matte(island: str, light: str, stage: int, shape: tuple[int, int]) -> np.ndarray:
    """The matte this state shipped before the r3b solve (`<island>/legacy/matte-*.png`: the first plate's, and IL1's own
    for stage 9), at `shape`."""
    d = PLATES / island / "legacy"
    f = d / f"matte-{light}-{stage}.png"
    if not f.exists():
        f = d / "matte-day-0.png"
    a = np.asarray(Image.open(f).convert("L"), np.float32) / 255
    return cv2.resize(a, (shape[1], shape[0]), interpolation=cv2.INTER_LINEAR)


def repair_matte(m: np.ndarray, rgb: np.ndarray, old: np.ndarray, light: str, stage: int) -> np.ndarray:
    """The r3b matte (8 bit) united, inside `REPAIR_BOXES` only, with the old one where the plate's pixel is painted and
    not sky: the solve cuts a pennant, a flower, a lamp's glow that the old wide matte kept."""
    boxes = REPAIR_BOXES.get(f"{light}:{stage}")
    if not boxes:
        return m
    sys.path.insert(0, str(REPO / "tools" / "proof"))
    import island_matte  # noqa: PLC0415

    a = m.astype(np.float32) / 255
    ell = lambda n: cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * n + 1, 2 * n + 1))
    far = cv2.dilate(((a > 0.02) | (old > 0.02)).astype(np.uint8), ell(60)) == 0
    sky = island_matte._estimate(rgb.astype(np.float32), far)
    dist = np.linalg.norm(rgb - sky, axis=2)
    want = (dist > REPAIR_SKY) & ((rgb.max(2) - rgb.min(2)) > REPAIR_CHROMA)
    inside = np.zeros(a.shape, bool)
    for x0, y0, x1, y1 in boxes:
        inside[y0 * MATTE_TEX:y1 * MATTE_TEX, x0 * MATTE_TEX:x1 * MATTE_TEX] = True
    pale = np.zeros(a.shape, bool)
    if f"{light}:{stage}" in REPAIR_PALE:
        x0, y0, x1, y1 = REPAIR_PALE[f"{light}:{stage}"]
        pale[y0 * MATTE_TEX:y1 * MATTE_TEX, x0 * MATTE_TEX:x1 * MATTE_TEX] = True
        want |= pale & (dist > 0.05)
    near = cv2.dilate((a > 0.5).astype(np.uint8), ell(REPAIR_REACH)) > 0
    add = want & inside & (old > 0.5) & near & (a < 0.98)
    soft = cv2.GaussianBlur(add.astype(np.float32), (0, 0), 0.8)
    return np.maximum(m, np.uint8(np.clip(soft, 0, 1) * 255 + 0.5))


def shadow_params(a: np.ndarray) -> dict:
    """The island's contact shadow as data (`plate-<island>.json` `shadow`): `island_shadow` of island_matte.py, as the
    ellipse it draws. `a` is the matte at any size; the result is in plate pixels (the hand data's units)."""
    k = a.shape[1] / SIZE[0]
    ys = np.where(a.max(1) > 0.5)[0]
    top, bot = int(ys[0]), int(ys[-1])
    prof = a[top + int((bot - top) * SHADOW["underside"]):bot].max(0)
    xs = np.where(prof > 0.5)[0]
    cx, hw = (xs[0] + xs[-1]) / 2, (xs[-1] - xs[0]) / 2
    cy = bot + (bot - top) * SHADOW["drop"] * 0.5
    return {"centre": [round(cx / k, 1), round(cy / k, 1)],
            "radii": [round(hw * SHADOW["reach"] / k, 1), round(hw * SHADOW["squash"] / k, 1)],
            "blur": round(hw * SHADOW["blur"] / k, 1), "opacity": SHADOW["opacity"]}


def cmd_matte(island: str, state: str | None = None) -> None:
    """Writes the mattes of every plate, or of the one `--state <light>:<stage>` only (the other
    mattes are committed and stay as they are).

    A `STRICT_MATTES` island's masters are the r3b solve (`tools/proof/island_matte.py`: the BiRefNet-lite network,
    `POFU_BIREFNET`, and its edge solve), one per state at plate size x `MATTE_TEX`. It reads the plates as shipped, so
    run it before `deliver` rewrites them; every state is solved before the first master is written."""
    hand = load_hand(island)
    wanted = [(light, stage, path) for light, stage, path in plates(hand)
              if (state is None or f"{light}:{stage}" == state) and not split_light(light)[0]]    # a season has no matte of its own
    if island in STRICT_MATTES:
        wanted = [w for w in wanted if not is_legacy(hand, w[0], w[1])]
        sys.path.insert(0, str(REPO / "tools" / "proof"))
        import island_matte  # noqa: PLC0415 (needs the network's weights; the other commands do not)

        solved = [(light, stage, path, *island_matte.island_layer(light, stage)) for light, stage, path in wanted]
        for light, stage, path, layer, origin in solved:
            m = master_matte(light, stage, layer, origin)
            rgb = source_plate(path)[0]
            m = repair_matte(m, rgb, legacy_matte(island, light, stage, m.shape), light, stage)
            m = fill_matte(m, rgb, light, stage)
            Image.fromarray(m).save(matte_path(island, light, stage), optimize=True)
            x0, y0, x1, y1 = bbox(m / 255.0, 0.02)
            print(f"matte {light} {stage}: box {(x0 // MATTE_TEX, y0 // MATTE_TEX, x1 // MATTE_TEX, y1 // MATTE_TEX)}")
        return
    for light, stage, path in wanted:
        water = [pct_to_px(o["points"]) for o in hand["objects"] if o.get("water")]
        a = matte(load_rgb(path), pct_to_px(hand["trace"]), water)
        Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + 0.5)).save(matte_path(island, light, stage))
        print(f"matte {light} {stage}: box {bbox(a)}")


# ---------------------------------------------------------------- framing

def home_frame(hand: dict, a: np.ndarray) -> dict:
    """The Home frame in plate pixels: the island `homeWidths` screen widths wide, its x centre at
    `homeCenterX` of the island, its top `homeTopY` points below the screen's top."""
    f = hand["framing"]
    x0, y0, x1, y1 = hand.get("frameBox") or bbox(a)
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


def decontaminated(rgb: np.ndarray, a: np.ndarray, light: str, stage: int) -> np.ndarray:
    """The plate's colours with the edge pixels of the r3b layer (`island_matte.island_layer`): a half-transparent pixel
    carries the island's colour, not the sky's, so nothing pale is left to show round the rim. Pixels the solve left
    alone are the plate's own. Needs the layer (the matting network's weights, or its cache from `matte`).

    A season state has no solve (its matte is its spring state's, D2): the pixels the matte holds less than whole take
    the colour of the nearest whole one, so the take's own sky does not tint the rim."""
    if split_light(light)[0]:
        deep = a >= 0.98
        _, (iy, ix) = ndimage.distance_transform_edt(~deep, return_indices=True)
        return np.where((deep | (a <= 0.0))[..., None], rgb, rgb[iy, ix])
    sys.path.insert(0, str(REPO / "tools" / "proof"))
    import island_matte  # noqa: PLC0415

    layer, (x0, y0) = island_matte.island_layer(light, stage)
    k = rgb.shape[1] // SIZE[0]
    if k != MATTE_TEX:
        print(f"WARNING: the plate is x{k}, the r3b layer x{MATTE_TEX}: its edge colours are not applied")
        return rgb
    X0, Y0 = x0 * k, y0 * k
    h, w = layer.shape[:2]
    out = rgb.copy()
    sub = out[Y0:Y0 + h, X0:X0 + w]
    sa = a[Y0:Y0 + h, X0:X0 + w]
    lc = layer[..., :3].astype(np.float64)
    # only where the solve itself has alpha: a pixel `repair_matte` gave back keeps the painting's own colour
    la = layer[..., 3]
    use = (la > 0) & (sa > 0) & ((sa < 0.98) | (np.abs(lc - sub).max(-1) > 0.08))
    sub[use] = lc[use]
    return out


#: Plate px round the island where a clear pixel's colour is the island's (see `extended`).
EXTEND = 2


def extended(rgb: np.ndarray, a: np.ndarray, reach: int = EXTEND) -> np.ndarray:
    """The plate's colours with every clear pixel (alpha 0) within `reach` px of the island given the colour of the nearest
    pixel that is not. The picture is stored in a lossy codec (HEIC q70, chroma at half resolution), which mixes a clear
    pixel's colour into the opaque ones beside it: the sky's colour there would tint the rim, the island's own cannot. A
    clear pixel is never drawn, so the change is invisible."""
    clear = a < 0.004
    dist, (iy, ix) = ndimage.distance_transform_edt(clear, return_indices=True)
    near = clear & (dist <= reach)
    out = rgb.copy()
    out[near] = rgb[iy[near], ix[near]]
    return out


#: Texture px of clear room kept round the island when a matted plate is cropped to it, and the grid the crop snaps to
#: (ASTC's 4 x 4 blocks; a multiple of `MATTE_TEX`, so the crop is whole plate points).
CROP_PAD = 8
CROP_GRID = 4


def plate_crop(a: np.ndarray) -> tuple[int, int, int, int]:
    """The box a matted plate ships cropped to (texture px of the x`MATTE_TEX` plate, `a` its alpha): every pixel with
    alpha, `CROP_PAD` of clear room round them, snapped out to `CROP_GRID` and kept inside the plate. Everything outside
    is clear: the sky set behind is the picture there (one sky at every level)."""
    ys, xs = np.nonzero(a > 0)
    h, w = a.shape
    snap_lo = lambda v: max((v - CROP_PAD) // CROP_GRID * CROP_GRID, 0)
    snap_hi = lambda v, top: min(-(-(v + CROP_PAD) // CROP_GRID) * CROP_GRID, top)
    return snap_lo(int(xs.min())), snap_lo(int(ys.min())), snap_hi(int(xs.max()) + 1, w), snap_hi(int(ys.max()) + 1, h)


def plate_crop_points(island: str, hand: dict, light: str, stage: int) -> list[int] | None:
    """`plateCrop` of one state in plate points (the JSON's units), or `None`: the state ships the whole plate over its
    backdrop (a legacy matte, or an island whose mattes are not strict)."""
    if island not in STRICT_MATTES or is_legacy(hand, light, stage):
        return None
    return [v // MATTE_TEX for v in plate_crop(load_matte_full(island, light, stage))]


def wanted_plates(hand: dict, state: str | None):
    """`plates(hand)`, or the one state `LIGHT:STAGE` (a season's: `autumn-day:0`) when `state` is given."""
    return [(l, s_, p) for l, s_, p in plates(hand) if state is None or f"{l}:{s_}" == state]


def cmd_deliver(island: str, state: str | None = None) -> None:
    hand = load_hand(island)
    strict = island in STRICT_MATTES
    for light, stage, path in wanted_plates(hand, state):
        if strict and is_legacy(hand, light, stage):
            print(f"deliver {light} {stage}: legacy matte, assets left as they are")
            continue
        rgb, k = source_plate(path)
        a1 = load_matte(island, light, stage)
        if strict:
            a = load_matte_full(island, light, stage)
            if a.shape != rgb.shape[:2]:
                a = cv2.resize(a.astype(np.float32), (rgb.shape[1], rgb.shape[0]), interpolation=cv2.INTER_AREA).astype(np.float64)
            rgb = fill_colours(decontaminated(rgb, a, light, stage), a, light, stage)
            # The plate's alpha is the matte: feather 0, the sky and the cloud sea round the island are the sky set's.
            # It ships cropped to the island (`plate_crop`, `plateCrop` in the JSON): the clear rows cost no texture.
            cx0, cy0, cx1, cy1 = (v * k for v in plate_crop_points(island, hand, light, stage))
            full = np.dstack([extended(rgb, a), np.clip(a, 0, 1)])
            write_imageset(asset_name(island, "plate", light, stage), to_img(full[cy0:cy1, cx0:cx1]))
        else:
            a = scaled_matte(a1, k)
            write_imageset(asset_name(island, "plate", light, stage), feathered_plate(rgb, a, FEATHER * k))
        x0, y0, x1, y1 = bbox(a1, 0.02)
        cut = np.dstack([extended(rgb, a) if strict else rgb, np.clip(a, 0, 1)])[y0 * k:y1 * k, x0 * k:x1 * k]
        img = to_img(cut)
        # The Map's island stays at its size in original-plate pixels (it is drawn small).
        img = img.resize((round((x1 - x0) * ISLAND_SCALE), round((y1 - y0) * ISLAND_SCALE)), Image.Resampling.LANCZOS)
        write_imageset(asset_name(island, "island", light, stage), img)
        if strict:
            # The state's own matte has no level-10 ghost to cut away (`map_cut.py`): the Map's cut is the island's.
            write_imageset(asset_name(island, "mapisle", light, stage), img)
        if not strict:
            # A strict island's backdrop is not rewritten: a matted state draws the sky set behind its plate, so the
            # backdrop is not drawn there; the legacy states keep theirs as they are.
            box = backdrop_box(home_frame(hand, a1))
            write_imageset(asset_name(island, "backdrop", light, stage), to_img(backdrop(rgb, a, box, hand.get("backdropScale", BACKDROP_SCALE), calm=hand.get("backdrop") == "calm")), jpeg=True)
        print(f"deliver {light} {stage} (x{k}): island box {(x0, y0, x1, y1)}")


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


def cmd_objects(island: str, state: str | None = None) -> None:
    hand = load_hand(island)
    for light, stage, path in wanted_plates(hand, state):
        if island in STRICT_MATTES and is_legacy(hand, light, stage):
            continue
        rgb, k = source_plate(path)
        a1 = load_matte(island, light, stage)
        a = scaled_matte(a1, k)
        if island in STRICT_MATTES:
            a = cv2.resize(load_matte_full(island, light, stage).astype(np.float32), (rgb.shape[1], rgb.shape[0]), interpolation=cv2.INTER_AREA).astype(np.float64)
            rgb = decontaminated(rgb, a, light, stage)
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
    bl = base_light(light)              # a season's key (`autumn-day`) takes its light's tables
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
    cast = TINT_CAST.get(bl, 0.5)
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
    if bl in margins:
        # The brightest stone around each character caps its own top; the shared tint is capped by
        # the brightest of them and each darker neighbourhood scales its character down from it.
        stones = stone_levels(rgb, hand, walk)
        def cap(stone: float) -> float:
            return lstar_to_srgb(stone - margins[bl]) / (lstar_to_srgb(SPRITE_L) * float(tint.mean()))
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
    rim = cl["rim"].get(bl, 0.0)
    if rim > 0:
        out["key"] = cast_from["key"] if cast_from is not None else key_colour(rgb, hand, walk, bl)
        out["rim"] = rim
        out["fill"] = cl["fill"].get(bl, 0.0)
    pool = cl["pool"].get(bl, 0.0)
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

def sky_bytes(island: str, light: str) -> int:
    """The textures of the island's sky set for `light` without its island layer (`Plates/skyset-<island>.json`, the
    set at stage 0): what a matted state draws behind its plate. 0 when the island has no sky set for the light."""
    light = base_light(light)                       # one sky set for every season
    f = JSON_DIR / f"skyset-{island}.json"
    if not f.exists():
        return 0
    spec = json.loads(f.read_text())["lights"].get(light)
    if spec is None:
        return 0
    total = spec.get("detailPixels", 0)
    for layer in spec["layers"]:
        if layer["role"] == "island":
            continue
        with heic.open_image(ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}{heic.SUFFIX}") as im:
            total += im.width * im.height
    return total


def stations_data(island: str) -> dict:
    """The `stations` block `tools/plate/station_looks.py json` wrote (looks and erased bases), or empty."""
    f = PLATES / island / "stations.json"
    return json.loads(f.read_text()).get("stations", {}) if f.exists() else {}


def station_stages(st: dict, light: str) -> list[int]:
    """The stages of `light` a station has an erased base for (`lights` per light, else `baseStages` of its one light)."""
    if "lights" in st:
        return st["lights"].get(light, [])
    return st.get("baseStages", []) if st.get("light") == light else []


def base_states(island: str) -> set[tuple[str, int]]:
    out = set()
    for st in stations_data(island).values():
        lights = st["lights"] if "lights" in st else {st.get("light"): st.get("baseStages", [])}
        out |= {(light, s) for light, stages in lights.items() for s in stages}
    return out


def station_bytes(island: str, light: str, stage: int) -> int:
    """Texture px of a state's station layers: its one erased base (shared by every station on it; it replaces the plate), each station's largest look (the one drawn, at any level), and once more the largest of those (the old look
    of the one reveal that can run: a build is one station, `BuildMoment.station`)."""
    base, looks = 0, []
    for st in stations_data(island).values():
        if stage not in station_stages(st, light):
            continue
        base = max(base, st.get("lightBaseBytes", {}).get(light, {}).get(str(stage), st.get("baseBytes", {}).get(str(stage), 0)))
        looks.append(max(st.get("lookBytes", [0])))
    return base + sum(looks) + max(looks, default=0)


def props_pixels(island: str) -> int:
    """The props' worst frame in texture px (`plate-<island>.json` `props`): every prop's sprite sheet divided by its
    states, times all its states, except the jar, which shows one (as `HomePropsTests` counts). 0 without the file."""
    f = JSON_DIR / f"plate-{island}.json"
    if not f.exists():
        return 0
    total = 0
    for p in json.loads(f.read_text()).get("props", []):
        states = max(len(p.get("states", [])), 1)
        total += p.get("bytes", 0) // states * (1 if p.get("id") == "jar" else states)
    return total


def near_pixels(island: str, light: str, stage: int) -> int:
    """The near camera's ground (plan row 3a, `tools/plate/near_ground.py`): the detail tile, the strip and the dressing
    that every Home state holds, and the one lawn mask of this state (autumn's own for an autumn state)."""
    if island != "home":
        return 0
    mask = f"world-near-lawn-mask-{'autumn-' if light.startswith('autumn') else ''}{stage}.imageset"
    total = 0
    for folder in ASSETS.glob("world-near-*.imageset"):
        if "lawn-mask" in folder.name and folder.name != mask:
            continue
        for f in folder.iterdir():
            if f.suffix == heic.SUFFIX:
                with heic.open_image(f) as im:
                    total += im.width * im.height
    return total


def state_texture_bytes(island: str, hand: dict) -> dict[tuple[str, int], int]:
    """Rule v1 (docs/design/texture-budget-v1.md): the texture pixels one Home state draws or keeps, 4 bytes a pixel
    decoded (8-bit RGBA, what HEIC decodes to). Per state: the drawn picture (the base where a station has one, else the
    plate), the occluders that can draw (not those of a station on this base), each station's current look at its
    largest and one more look for the one reveal, the props' worst frame, the near ground (`near_pixels`); a matted state adds the sky set without its
    island layer and the far picture (the plate crop, w x h), any other the island cut, the Map cut and the backdrop.
    The app holds one state, or two for a crossfade."""
    out = {}
    for light, stage, _ in plates(hand):
        crop = plate_crop_points(island, hand, light, stage)
        matted = crop is not None
        kinds = ("plate", "occ") if matted else ("plate", "island", "mapisle", "backdrop", "occ")
        total = sky_bytes(island, light) if matted else 0
        if matted:
            total += (crop[2] - crop[0]) * (crop[3] - crop[1])      # the far picture (`FarSnapshot`, 1 px per plate px)
        total += station_bytes(island, light, stage) + props_pixels(island) + near_pixels(island, light, stage)
        on_base = (light, stage) in base_states(island)
        if on_base:
            kinds = tuple(k for k in kinds if k != "plate")      # the base is the plate there (`station_bytes` counts it)
        retired = {name for name, st in stations_data(island).items() if stage in station_stages(st, light)}
        for folder in ASSETS.glob(f"world-{island}-*-{light}-{stage}.imageset"):
            # Only this tool's layers: a sky set's own (`world-<island>-sky-*`) are counted above, by `sky_bytes`.
            if not folder.name.startswith(tuple(f"world-{island}-{kind}-" for kind in kinds)):
                continue
            if not split_light(light)[0] and any(f"-{season}-{light}-{stage}.imageset" in folder.name for season in SEASONS):
                continue                                  # `world-home-plate-autumn-day-0` is autumn's, not day's
            if any(folder.name == f"world-{island}-occ-{name}-{light}-{stage}.imageset" for name in retired):
                continue
            for f in folder.iterdir():
                if f.suffix in (".png", ".jpg", heic.SUFFIX):
                    with heic.open_image(f) as im:
                        total += im.width * im.height
        out[(light, stage)] = total
    return out


def texture_bytes(island: str, hand: dict) -> int:
    """The largest state's textures (`state_texture_bytes`)."""
    return max(state_texture_bytes(island, hand).values(), default=0)


def season_states(hand: dict) -> dict:
    """`{season: {"complete": bool, "states": {light: [stage, ...]}}}` from the hand data's `plates` keyed `<season>-<light>`
    and `seasons.<season>.complete` (absent: false, the season is Rehearsal's until its last commit)."""
    out: dict[str, dict] = {}
    for key, stages in hand["plates"].items():
        season, light = split_light(key)
        if season:
            out.setdefault(season, {"complete": bool(hand.get("seasons", {}).get(season, {}).get("complete", False)), "states": {}})
            out[season]["states"][light] = sorted(int(s) for s in stages)
    return dict(sorted(out.items()))


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
    every = sorted(hand["plates"], key=lambda l: (split_light(l)[0] or "", l))     # spring's lights, then each season's
    lights = [l for l in every if not split_light(l)[0]]
    data = {
        "island": island,
        "version": 1,
        "standIn": bool(hand.get("standIn", False)),
        "minLevel": hand.get("minLevel", 1),
        "plateSize": list(SIZE),
        "stages": max(int(s) for l in lights for s in hand["plates"][l]) + 1,
        "lights": lights,
        "lightStages": {l: stage_count(hand, l) for l in lights},
        "stageLevels": hand.get("stageLevels", [hand.get("minLevel", 1)]),
        "harmony": harmony or {},
        "islandBox": list(hand.get("islandBox") or bbox(a, 0.02)),
        "backdropBox": list(backdrop_box(home_frame(hand, a))),
        "feather": 0 if island in STRICT_MATTES else FEATHER,
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
        "lightMap": {l: [maps[(l, s)][0] if (l, s) in maps else [] for s in range(stage_count(hand, l))] for l in every},
        "shadowMap": {l: [maps[(l, s)][1] if (l, s) in maps else [] for s in range(stage_count(hand, l))] for l in every},
        "textureBytes": texture_bytes(island, hand),
    }
    stations = stations_data(island)
    if stations:
        # Looks and erased bases of the stations (`tools/plate/station_looks.py`): version 2.
        data["version"] = 2
        data["stations"] = stations
    if island in STRICT_MATTES:
        # Per light, per stage: the box the plate image covers (plate points), or null where the state ships the whole
        # plate over its backdrop (a legacy matte). A matted state draws the sky set behind the cropped plate.
        # (a stage the light does not paint, in a sparse light, has no matte: null)
        painted = painted_stages(hand)
        data["plateCrop"] = {l: [plate_crop_points(island, hand, l, s) if s in painted[l] else None for s in range(stage_count(hand, l))] for l in every}
        # Per stage (the lights of a stage are one drawing, so one matte): the island's contact shadow, drawn by code
        # on the floor layer under the island.
        data["shadow"] = [shadow_params(load_matte_full(island, "day", s)) for s in range(data["stages"])]
    if is_sparse(hand):
        data["painted"] = {l: v for l, v in painted_stages(hand).items() if l in lights}
    seasons = season_states(hand)
    if seasons:
        # The states each season paints (`seasons` in the player's data, season-system-v1 D4); `complete` is hand data.
        data["seasons"] = seasons
    if hand.get("backdrop"):
        data["backdropStyle"] = hand["backdrop"]
    return data


def keep_hand_keys(data: dict, old: dict) -> dict:
    """`data` (what this tool owns) plus every key of the shipped file that the tool does not write: `props` (written by
    `tools/plate/props_slice.py`), `camera` and `near` (the lens, WP11), `water` (the region shaders, WP13), `mooring`
    (the Gezgin's berth) and `spots` (where the cast stands) are edited by hand or by another tool, so a re-ingest
    must not drop them, and a key added later is kept without anyone listing it here. A key the tool owns is the tool's."""
    return {**data, **{k: v for k, v in old.items() if k not in data}}


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
    old = json.loads(out.read_text()) if out.exists() else {}
    data = keep_hand_keys(data, old)
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
            matted = (data.get("plateCrop", {}).get(light) or [None] * (stage + 1))[stage] is not None
            for kind in ("plate", "island") if matted else ("plate", "island", "backdrop"):
                if asset_name(island, kind, light, stage) not in assets:
                    out.append(f"missing asset {asset_name(island, kind, light, stage)}")
            for obj in data["objects"]:
                if "stages" in obj and stage not in obj["stages"]:
                    continue
                if obj["occluder"] and asset_name(island, "occ", light, stage, obj["id"]) not in assets:
                    out.append(f"missing asset {asset_name(island, 'occ', light, stage, obj['id'])}")
    for season, entry in data.get("seasons", {}).items():
        for light, stages in entry["states"].items():
            for stage in stages:
                key = f"{season}-{light}"
                for kind in ("plate", "island", "mapisle"):
                    if asset_name(island, kind, key, stage) not in assets:
                        out.append(f"missing asset {asset_name(island, kind, key, stage)}")
                for obj in data["objects"]:
                    if "stages" in obj and stage not in obj["stages"]:
                        continue
                    if obj["occluder"] and asset_name(island, "occ", key, stage, obj["id"]) not in assets:
                        out.append(f"missing asset {asset_name(island, 'occ', key, stage, obj['id'])}")
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
                    help="matte, deliver and objects: this state only (e.g. day:9, or a season's: autumn-day:0)")
    ap.add_argument("--no-upscale", action="store_true",
                    help="ship the original take (only when the model is unavailable; loud on purpose)")
    args = ap.parse_args(argv)
    heic.require()  # fail before any work, like the upscaler
    global SCALE_UP
    SCALE_UP = not args.no_upscale
    if args.command == "matte":
        cmd_matte(args.island, args.state)
    elif args.command == "deliver":
        cmd_deliver(args.island, args.state)
    elif args.command == "objects":
        cmd_objects(args.island, args.state)
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
