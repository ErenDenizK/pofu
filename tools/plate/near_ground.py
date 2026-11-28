"""The near camera's ground (mainflow plan row 3a): build the shipped layers from pofu-art's takes.

    python3 -I tools/plate/near_ground.py build --art <pofu-art checkout or dir of the takes> --out <dir>

Reads the picked takes (batch 206 lawn tile v2 t2, batch 119 tufts-ragged t2 and foreground-strip t2,
batch 107 pebbles-clover t1 and tea-stool t1) and writes, into `--out`:

- `near-lawn-detail`: the lawn tile with its grid daisies and clover painted out (periodic clone), reduced to
  a luminance detail around mid grey. Drawn with an overlay blend over the plate it adds sharp blades and
  takes the plate's own colour in every light (day, golden, night, autumn).
- `near-foreground`: the soft strip's opaque body and soft top, its bottom row extended so one image covers
  the whole earth face.
- `near-tuft-1..4`, `near-pebbles-1..2`, `near-clover`, `near-stool`: the dressing, cut from their sheets,
  trimmed and reduced so each is about 200 px wide.

`mask` builds the lawn mask from the day plate: the lawn only, never a path stone, never the earth face.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

TILE_SRC = "design/art/takes/batch-206-near-lawn-tile-v2/x-near-lawn-tile-v2/plate__x-near-lawn-tile-v2--t2.webp"
TUFTS = "design/art/takes/batch-119-near-lawn-and-foreground/x-near-tufts-ragged/prop__x-near-tufts-ragged--t2.webp"
STRIP = "design/art/takes/batch-119-near-lawn-and-foreground/x-near-foreground-strip/prop__x-near-foreground-strip--t2.webp"
PEBBLES = "design/art/takes/batch-107-near-dressing-pilot/x-near-pebbles-clover/prop__x-near-pebbles-clover--t1.webp"
STOOL = "design/art/takes/batch-107-near-dressing-pilot/x-near-tea-stool/prop__x-near-tea-stool--t1.webp"

TILE_SIZE = 640
# The grid daisies and clover leaves of the tile (x, y, radius in the 1024 source), painted out.
BLEMISHES = [(203, 165, 40), (848, 255, 40), (511, 470, 40), (193, 712, 40), (847, 793, 40),
             (650, 140, 52), (125, 385, 52), (676, 683, 52), (55, 915, 52)]
# Detail strength: grey = 0.5 + GAIN * (ratio - 1).
GAIN = 1.7


def load(art: Path, rel: str, mode: str = "RGBA") -> Image.Image:
    p = art / rel
    if not p.exists():
        raise SystemExit(f"missing take: {p}")
    return Image.open(p).convert(mode)


def paint_out(rgb: np.ndarray) -> np.ndarray:
    """Clone grass over each blemish from a clean spot 200 to 400 px away, feathered; the tile wraps, so a blemish at an edge works."""
    h, w, _ = rgb.shape
    out = rgb.copy()
    yy, xx = np.mgrid[0:h, 0:w]

    def wrapped(ax: int, ay: int, bx: int, by: int) -> float:
        return float(np.hypot((ax - bx + w / 2) % w - w / 2, (ay - by + h / 2) % h - h / 2))

    for i, (x, y, r) in enumerate(BLEMISHES):
        for k in range(200):
            ang = 2.4 * (i + 1) + 0.9 * k
            dist = 200 + (k * 37) % 200
            sx, sy = int(x + dist * np.cos(ang)) % w, int(y + dist * np.sin(ang)) % h
            if all(wrapped(sx, sy, bx, by) > r + br + 30 for bx, by, br in BLEMISHES):
                break
        else:
            raise SystemExit("no clean source for a blemish")
        src = np.roll(rgb, (y - sy, x - sx), axis=(0, 1))
        d = np.hypot((xx - x + w / 2) % w - w / 2, (yy - y + h / 2) % h - h / 2)
        m = np.clip((r * 1.5 - d) / (r * 0.5), 0, 1)[..., None]
        out = out * (1 - m) + src * m
    return out


def detail_tile(art: Path) -> Image.Image:
    rgb = np.asarray(load(art, TILE_SRC, "RGB")).astype(np.float32)
    rgb = paint_out(rgb)
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    base = ndi.gaussian_filter(lum, 26, mode="wrap")
    ratio = lum / np.maximum(base, 1.0)
    g = np.clip(0.5 + GAIN * (ratio - 1.0), 0, 1)
    im = Image.fromarray((g * 255 + 0.5).astype(np.uint8), "L").resize((TILE_SIZE, TILE_SIZE), Image.LANCZOS)
    return im


# The lawn the focal ground may cover, in plate pixels: the ground between the pond's bank, the stall's lawn and the front
# bushes at every stage. The mask takes the stones, water, soil and flowers out of it by colour, per stage, from that
# stage's day plate (golden, night and autumn paint the same geometry).
LAWN = [(200, 800), (500, 795), (800, 820), (800, 985), (200, 985)]
MASK_ROWS = (790, 1010)  # plate rows the mask covers
MASK_W = 512  # plate columns 0..1024 at half resolution


FEATHER = 20  # plate-image px (2 per plate px): the band fades in over this distance from a stone, flower or leaf pile


def lawn_pixels(plate_path: Path, crop: list[int]) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """The plate (float RGB) and a boolean field, True on grass: no stone, flower, water, soil or autumn leaf pile.
    Stones are beige (blue near half of green), flowers and water have more blue still, soil and leaves are red;
    lawn, lit or shaded, is none of them. `crop` is the plate's `plateCrop` box [x0, y0, x1, y1] of the state: the
    image is that box at 2 px per plate pixel."""
    from PIL import ImageDraw
    import pillow_heif

    pillow_heif.register_heif_opener()
    p = np.asarray(Image.open(plate_path).convert("RGB")).astype(np.float32)
    r, g, b = p[..., 0], p[..., 1], p[..., 2]
    cx, cy = crop[0], crop[1]
    poly = Image.new("L", (p.shape[1], p.shape[0]), 0)
    ImageDraw.Draw(poly).polygon([((x - cx) * 2, (y - cy) * 2) for x, y in LAWN], fill=255)
    stone = ndi.binary_dilation(ndi.binary_opening((b > 0.5 * g) | (r > g * 1.3), iterations=2), iterations=5)
    lawn = ndi.binary_erosion(ndi.binary_opening((np.asarray(poly) > 0) & ~stone, iterations=3), iterations=3)
    # Distance from the nearest stone, flower or pile (not the lawn's own polygon edge), which the band fades in over.
    feature = ndi.binary_opening((b > 0.5 * g) | (r > g * 1.3), iterations=2)
    return p, lawn, ndi.distance_transform_edt(~feature)


def lawn_mask(plate_path: Path, crop: list[int], feather: bool = False) -> Image.Image:
    """`near-lawn-mask-<stage>` (`-autumn-<stage>` for autumn's own painting): white, its alpha 1 on grass."""
    cx, cy = crop[0], crop[1]
    _, lawn, dist = lawn_pixels(plate_path, crop)
    # Place the crop's rows and columns into a full-plate field (rows 790..1010, columns 0..1024) at 2 px per plate pixel.
    full = np.zeros(((MASK_ROWS[1] - MASK_ROWS[0]) * 2, 2048), np.float32)
    blurred = ndi.gaussian_filter(lawn.astype(np.float32), 2.0)
    if feather:  # autumn's leaf piles: the band fades in away from a pile, never ending in a ring (the dilated exclusion keeps 5 px clear)
        t = np.clip((dist - 5) / FEATHER, 0, 1)
        blurred = blurred * (t * t * (3 - 2 * t))
    for fy in range(full.shape[0]):
        sy = fy + (MASK_ROWS[0] - cy) * 2
        if 0 <= sy < blurred.shape[0]:
            width = min(blurred.shape[1], 2048 - cx * 2)
            full[fy, cx * 2 : cx * 2 + width] = blurred[sy, :width]
    grey = Image.fromarray((np.clip(full, 0, 1) * 255).astype(np.uint8), "L").resize((MASK_W, (MASK_ROWS[1] - MASK_ROWS[0]) // 2), Image.LANCZOS)
    out = Image.new("RGBA", grey.size, (255, 255, 255, 0))
    out.putalpha(grey)
    return out


STRIP_W, STRIP_H = 480, 345  # before the seam crossfade cuts SEAM texels of width


SEAM = 96  # texels the strip's two edges are crossfaded over, so unflipped copies repeat without a seam or a mirror axis


STRIP_BASE = (0.95, 0.95, 0.50)  # the strip is neutral lawn at this colour; the app multiplies it by each state's own lawn (near_ground_data.py)


def foreground(art: Path) -> Image.Image:
    """The soft strip from its ramp down to where it is fully opaque, reduced and made to repeat sideways; below that
    its own last rows, blurred sideways, relax to the plate's lawn colour, so one image covers the whole earth face."""
    im = load(art, STRIP)
    arr = np.asarray(im).astype(np.float32)
    alpha = arr[..., 3]
    top = int(np.argmax((alpha > 8).any(axis=1)))
    solid = np.where(alpha.min(axis=1) >= 250)[0]
    if len(solid) == 0:
        raise SystemExit("the strip has no fully opaque row")
    end = int(solid[0]) + 40  # a little of the opaque body under the ramp
    small = np.asarray(im.crop((0, max(top - 4, 0), im.width, min(end, im.height))).resize((STRIP_W, round((min(end, im.height) - max(top - 4, 0)) * STRIP_W / im.width)), Image.LANCZOS)).astype(np.float32)
    rows = small.shape[0]
    if rows >= STRIP_H:
        raise SystemExit("the strip body is taller than the strip")
    last = ndi.gaussian_filter(small[-8:, :, :3].mean(axis=0), (6, 0))
    out = np.zeros((STRIP_H, STRIP_W, 4), np.float32)
    out[:rows] = small
    # Below the body the colour relaxes from the last rows' to a wide blur of them to the lawn's own colour.
    raw = small[-8:, :, :3].mean(axis=0)
    wide = ndi.gaussian_filter(raw, (60, 0), mode="nearest")
    n = STRIP_H - rows
    k = np.clip(np.arange(n) / 40.0, 0, 1)[:, None, None]
    k2 = np.clip((np.arange(n) - 10) / 50.0, 0, 1)[:, None, None]
    out[rows:, :, :3] = (last[None] * (1 - k) + wide[None] * k) * (1 - k2) + np.array(STRIP_BASE, np.float32)[None, None] * 255 * k2
    blend = min(24, rows)
    t = np.linspace(0, 1, blend)[:, None, None]
    out[rows - blend : rows, :, :3] = small[-blend:, :, :3] * (1 - t) + last[None] * t
    out[rows - blend :, :, 3] = 255
    # Repeatable: the first SEAM texels crossfade into the last SEAM texels of the source, then those are cut.
    w = STRIP_W - SEAM
    t = np.linspace(0, 1, SEAM)[None, :, None]
    seamless = out[:, :w].copy()
    seamless[:, :SEAM] = out[:, :SEAM] * t + out[:, w : w + SEAM] * (1 - t)
    return Image.fromarray(np.clip(seamless, 0, 255).astype(np.uint8), "RGBA")


def trim(im: Image.Image, scale: float) -> Image.Image:
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 6)
    im = im.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
    return im.resize((max(int(im.width * scale), 1), max(int(im.height * scale), 1)), Image.LANCZOS)


def split(sheet: Image.Image, cells: list[tuple[int, int, int, int]], scale: float) -> list[Image.Image]:
    return [trim(sheet.crop(c), scale) for c in cells]


DRESS_SCALE = 0.27


def dressing(art: Path) -> dict[str, Image.Image]:
    tufts = load(art, TUFTS)
    pebbles = load(art, PEBBLES)
    stool = load(art, STOOL)
    w, h = tufts.size
    q = [(0, 0, w // 2, h // 2), (w // 2, 0, w, h // 2), (0, h // 2, w // 2, h), (w // 2, h // 2, w, h)]
    out: dict[str, Image.Image] = {}
    for name, cell in zip(["near-tuft-plain-1", "near-tuft-daisy-1", "near-tuft-daisy-2", "near-tuft-plain-2"], q):
        out[name] = trim(tufts.crop(cell), DRESS_SCALE)
    w, h = pebbles.size
    out["near-pebbles-3"] = trim(pebbles.crop((0, 0, w // 2, h // 2)), DRESS_SCALE)
    out["near-pebbles-2"] = trim(pebbles.crop((w // 2, 0, w, h // 2)), DRESS_SCALE)
    out["near-clover"] = trim(pebbles.crop((w // 2, h // 2, w, h)), DRESS_SCALE)
    out["near-stool"] = trim(stool, DRESS_SCALE)
    return out


def save_heic(im: Image.Image, path: Path, quality: int = 80) -> None:
    import pillow_heif

    pillow_heif.register_heif_opener()
    im.save(path, quality=quality)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["build"])
    ap.add_argument("--art", type=Path, required=True)
    ap.add_argument("--plates", type=Path, required=True, help="World.xcassets: reads world-home-plate-day-<stage> of every stage")
    ap.add_argument("--plate-json", type=Path, required=True, help="plate-home.json: its plateCrop box per stage")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--xcassets", type=Path, help="also write each layer as world-<name>.imageset here")
    a = ap.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    crops = json.loads(a.plate_json.read_text())["plateCrop"]
    layers: dict[str, Image.Image] = {"near-lawn-detail": detail_tile(a.art).convert("RGB"), "near-foreground": foreground(a.art)}
    layers.update(dressing(a.art))
    for stage, crop in enumerate(crops["day"]):
        if crop is not None:
            layers[f"near-lawn-mask-{stage}"] = lawn_mask(a.plates / f"world-home-plate-day-{stage}.imageset/world-home-plate-day-{stage}.heic", crop)
    # Autumn's own painting (stage 0) keeps its leaf piles soft: its band fades in away from each pile.
    layers["near-lawn-mask-autumn-0"] = lawn_mask(a.plates / "world-home-plate-autumn-day-0.imageset/world-home-plate-autumn-day-0.heic", crops["autumn-day"][0], feather=True)
    total = 0
    for name, im in layers.items():
        save_heic(im, a.out / f"{name}.heic", 85 if name == "near-lawn-detail" else 80)
        total += im.width * im.height
        if a.xcassets:
            d = a.xcassets / f"world-{name}.imageset"
            d.mkdir(parents=True, exist_ok=True)
            (d / f"world-{name}.heic").write_bytes((a.out / f"{name}.heic").read_bytes())
            (d / "Contents.json").write_text(json.dumps({"images": [{"filename": f"world-{name}.heic", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
        print(f"{name}: {im.width} x {im.height}")
    print(f"near layers: {total:,} px")


if __name__ == "__main__":
    main()
