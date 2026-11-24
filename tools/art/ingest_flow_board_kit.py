#!/usr/bin/env python3
"""Ingest the flow board's dial-and-block kit (pofu-art batch 158) into PofuGames/Resources.

Reads the picked takes from a checkout of the private art repository with
`git show origin/main:<path>` and writes the app's PNGs. Reproducible: run it
again to regenerate. Swapping a piece later (batch 161 repaints the socket,
goal, wheel and backdrop) means changing one row of PICKS, or passing
`--pick slot=<path in the art repo>`; the app reads whatever this writes, so
no Swift changes.

  tools/art/ingest_flow_board_kit.py --art-repo /home/user/pofu-art

Every cut-out is cleaned the same way (see `clean`):
- alpha at or above 220 becomes 255 (Codex's alpha is lossy: the opaque body
  arrives at 224 to 254 and shows the lawn through it);
- below 220 the alpha is a ramp from 24 (gone) to 220 (solid), which tightens
  the outer edge to about one source pixel;
- detached specks are dropped (only the biggest piece stays);
- colour is zeroed under alpha 0 and, on the edge ramp, replaced by the colour
  of the nearest solid pixel, so no fringe is left to bleed in when scaled.
Scaling is premultiplied.

Each piece is placed on a square canvas (one cell at 3x for a 96 pt cell) so
the app draws it at the cell's size. A block's body is BODY wide, a dial's disc
is DISC wide, both centred. Pieces with water get a bed mask (`flow-bed-*`):
white with the painted channel found by colour as its alpha, eroded a little so a thin brown edge stays
round the water, and run out to the canvas edge through the rim stones, so
neighbouring channels meet at the cell's edge at one width.

`flow-kit.json` records what the app needs to place things: the cell's canvas
size, BODY and DISC as fractions of the cell, and the backdrop's lawn plate as
fractions of the picture.
"""
import argparse
import io
import json
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "Packages/PofuKit/Sources/PofuGames/Resources"
KIT = "design/art/takes/batch-158-board-kit-v3"

# slot -> (job, take). The lead's picks for batch 158.
PICKS = {
    "backdrop": ("x4-kit-backdrop", 1),
    "dial-bend": ("x4-kit-dial-bend", 1),
    "dial-straight": ("x4-kit-dial-straight", 1),
    "dial-split": ("x4-kit-dial-tee", 2),
    "plain": ("x4-kit-tile-plain", 1),
    "flowers": ("x4-kit-tile-flowers", 2),
    "gate": ("x4-kit-tile-gate", 2),
    "goal": ("x4-kit-tile-goal", 1),
    "rock": ("x4-kit-tile-rock", 1),
    "socket": ("x4-kit-tile-socket", 1),
    "spring": ("x4-kit-tile-spring", 1),
    "wheel": ("x4-kit-tile-wheel", 2),
}
# Openings of the painted piece, then the quarter turns clockwise that bring it to the game's rotation 0
# (a bend opens north and east, a split north, east and south, a straight north and south).
OPENINGS = {
    "dial-bend": ("NE", 0), "dial-straight": ("NS", 0), "dial-split": ("NES", 1),
    "spring": ("S", 0), "goal": ("N", 0), "wheel": ("EW", 0), "gate": ("NS", 0),
}
DIALS = {"dial-bend", "dial-straight", "dial-split"}
CANVAS = 288
BODY = 0.96
# A dial is its grass and channel only: its own stone rim is cut away, so the block's rim is the one ring
# (a dial that kept its rim drew a second arc beside the socket's at every corner). DISC is the grass
# disc's width against the cell, the socket's inner width.
DISC = 0.85
DIAL_RIM = 0.095  # the rim's thickness against the disc's radius, with a little shade
ERODE = 3
SOLID, GONE = 220, 24


def read_take(art_repo: Path, job: str, take: int) -> Image.Image:
    path = f"{KIT}/{job}/{'plate' if 'backdrop' in job else 'prop'}__{job}--t{take}.webp"
    return read_path(art_repo, path)


def read_path(art_repo: Path, path: str) -> Image.Image:
    blob = subprocess.run(["git", "-C", str(art_repo), "show", f"origin/main:{path}"], check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(blob))


def clean(img: Image.Image) -> np.ndarray:
    arr = np.asarray(img.convert("RGBA")).copy()
    alpha = arr[..., 3].astype(np.float32)
    ramp = np.clip((alpha - GONE) / (SOLID - GONE), 0, 1) * 255
    alpha = np.where(alpha >= SOLID, 255, ramp)
    # Keep only the biggest piece: drop detached specks.
    labels, count = ndi.label(alpha > 0)
    if count > 1:
        sizes = ndi.sum(np.ones_like(labels), labels, range(1, count + 1))
        keep = 1 + int(np.argmax(sizes))
        alpha = np.where(labels == keep, alpha, 0)
    # Fill the colour of the edge ramp from the nearest solid pixel (no fringe), zero what is gone.
    solid = alpha >= 255
    _, (iy, ix) = ndi.distance_transform_edt(~solid, return_indices=True)
    rgb = arr[..., :3][iy, ix]
    rgb[alpha == 0] = 0
    out = np.dstack([rgb, np.round(alpha).astype(np.uint8)])
    return out


def cut_rim(arr: np.ndarray) -> np.ndarray:
    """Keeps the inside of a dial's disc, leaving out its stone rim, with a one pixel soft edge."""
    ys, xs = np.where(arr[..., 3] > 200)
    cx, cy = (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2
    radius = (xs.max() - xs.min()) / 2 * (1 - DIAL_RIM)
    yy, xx = np.mgrid[0:arr.shape[0], 0:arr.shape[1]]
    inside = np.clip(radius - np.hypot(xx - cx, yy - cy) + 0.5, 0, 1)
    out = arr.copy()
    out[..., 3] = np.round(arr[..., 3] * inside).astype(np.uint8)
    out[out[..., 3] == 0, :3] = 0
    return out


def resize_premultiplied(arr: np.ndarray, size) -> np.ndarray:
    f = arr.astype(np.float32) / 255
    f[..., :3] *= f[..., 3:4]
    planes = [np.asarray(Image.fromarray(f[..., i], mode="F").resize(size, Image.LANCZOS)) for i in range(4)]
    out = np.stack(planes, axis=-1)
    alpha = np.clip(out[..., 3:4], 0, 1)
    rgb = np.where(alpha > 1e-4, out[..., :3] / np.maximum(alpha, 1e-4), 0)
    return (np.concatenate([np.clip(rgb, 0, 1), alpha], axis=-1) * 255 + 0.5).astype(np.uint8)


def place(arr: np.ndarray, width_fraction: float):
    """Crops to the body, scales it to `width_fraction` of the canvas, centres it. Returns the canvas and the
    transform (scale, offset x, offset y, crop x0, crop y0) the mask follows."""
    ys, xs = np.where(arr[..., 3] > 0)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    scale = CANVAS * width_fraction / (x1 - x0)
    w, h = round((x1 - x0) * scale), round((y1 - y0) * scale)
    body = resize_premultiplied(arr[y0:y1, x0:x1], (w, h))
    canvas = np.zeros((CANVAS, CANVAS, 4), np.uint8)
    ox, oy = (CANVAS - w) // 2, (CANVAS - h) // 2
    canvas[oy:oy + h, ox:ox + w] = body
    return canvas, (scale, ox, oy, x0, y0, w, h)


def bed_mask(arr: np.ndarray) -> np.ndarray:
    """The painted channel bed by colour: terracotta, a third darker than the rim stones and unlike grass."""
    r, g, b = (arr[..., i].astype(np.float32) for i in range(3))
    hue = (g - b) / np.maximum(r - b, 1)  # 0 is red, 1 is yellow: the bed sits near 0.27, the rim stones above 0.37
    bed = (arr[..., 3] > 200) & (r > 100) & (r - b >= 60) & (hue < 0.34)
    bed = ndi.binary_opening(bed, iterations=2)
    bed = ndi.binary_fill_holes(bed)
    # Opening with a disc a little under half a channel wide drops small knobs and flecks of brown.
    yy, xx = np.mgrid[-44:45, -44:45]
    bed = ndi.binary_opening(bed, structure=(xx * xx + yy * yy) <= 44 * 44)
    bed = ndi.binary_closing(bed, iterations=10)
    labels, count = ndi.label(bed)
    if count == 0:
        raise SystemExit("no channel bed found")
    sizes = ndi.sum(np.ones_like(labels), labels, range(1, count + 1))
    return labels == 1 + int(np.argmax(sizes))


EDGE_WIDTH = 28  # the channel's width at the cell edge, in canvas pixels, the same for every piece


def extend(mask: np.ndarray, sides: str) -> np.ndarray:
    """Runs the channel out to the canvas edge on each open side. Across the rim stones the band moves to the
    cell's axis and to EDGE_WIDTH, so the channels of two neighbours meet at the edge at one place and one width
    (the painted arms sit a few pixels off the axis and differ in width)."""
    mask = mask.copy()
    mid = mask.shape[0] // 2
    turns = {"N": 0, "E": 1, "S": 2, "W": 3}  # rot90 is counter-clockwise: east to north is one turn
    for side in sides:
        k = turns[side]
        m = np.rot90(mask, k).copy()
        rows = np.where(m[:, mid - 45:mid + 45].any(axis=1))[0]
        y0 = int(rows.min())
        probe = m[min(y0 + 10, m.shape[0] - 1)]
        labels, count = ndi.label(probe)
        centres = [(np.where(labels == i)[0].min() + np.where(labels == i)[0].max()) / 2 for i in range(1, count + 1)]
        i = 1 + int(np.argmin([abs(c - mid) for c in centres]))
        xs = np.where(labels == i)[0]
        centre, half = (xs.min() + xs.max()) / 2, (xs.max() - xs.min()) / 2
        for r in range(0, y0):
            t = 1 - r / max(y0, 1)  # 1 at the edge, 0 where the painted arm begins
            c = centre + (mid - centre) * t
            h = half + (EDGE_WIDTH / 2 - half) * t
            m[r, int(round(c - h)):int(round(c + h)) + 1] = True
        mask = np.rot90(m, -k)
    return mask


def softened(mask: np.ndarray) -> np.ndarray:
    eroded = ndi.binary_erosion(mask, iterations=ERODE, border_value=1)
    return np.clip(ndi.gaussian_filter(eroded.astype(np.float32), 0.9), 0, 1)


def save_rgba(arr: np.ndarray, name: str) -> None:
    Image.fromarray(arr, "RGBA").save(RES / f"{name}.png", optimize=True)
    print(name, arr.shape[1], "x", arr.shape[0])


def piece(art_repo: Path, slot: str, source) -> None:
    img = source if isinstance(source, Image.Image) else read_take(art_repo, *source)
    arr = clean(img)
    if slot in DIALS:
        arr = cut_rim(arr)
    sides, quarter = OPENINGS.get(slot, ("", 0))
    if quarter:
        arr = np.rot90(arr, quarter).copy()
        # rot90 turns counter-clockwise; OPENINGS names the openings after it.
    canvas, (scale, ox, oy, x0, y0, w, h) = place(arr, DISC if slot in DIALS else BODY)
    kind = "dial" if slot in DIALS else "block"
    save_rgba(canvas, f"flow-{kind}-{slot.replace('dial-', '')}")
    if sides:
        mask_full = bed_mask(arr)
        m = np.zeros((CANVAS, CANVAS), bool)
        m8 = Image.fromarray((mask_full[y0:y0 + round(h / scale), x0:x0 + round(w / scale)] * 255).astype(np.uint8))
        m8 = np.asarray(m8.resize((w, h), Image.LANCZOS)) > 127
        m[oy:oy + h, ox:ox + w] = m8
        if slot == "wheel":
            # The hub and the arms are lit and shaded unevenly, so colour finds only parts of them: the wheel's
            # bed is its straight east-west band and the hub disc, which the painting keeps on the axis.
            yy, xx = np.mgrid[0:CANVAS, 0:CANVAS]
            m = (np.abs(yy - CANVAS / 2) < 0.05 * CANVAS) | (np.hypot(yy - CANVAS / 2, xx - CANVAS / 2) < 0.16 * CANVAS)
            m &= (np.abs(xx - CANVAS / 2) < 0.5 * CANVAS * BODY)
        m = extend(m, sides)
        alpha = (softened(m) * 255).astype(np.uint8)
        rgba = np.dstack([np.full_like(alpha, 255)] * 3 + [alpha])
        Image.fromarray(rgba, "RGBA").save(RES / f"flow-bed-{slot.replace('dial-', '')}.png", optimize=True)


def backdrop(art_repo: Path, source) -> dict:
    img = (source if isinstance(source, Image.Image) else read_take(art_repo, *source)).convert("RGB")
    img.save(RES / "flow-backdrop.png", optimize=True)
    print("flow-backdrop", img.size)
    a = np.asarray(img).astype(np.int32)
    green = (a[..., 1] >= a[..., 0] - 5) & (a[..., 1] > 110) & (a[..., 2] < 90)
    core = ndi.binary_erosion(green, iterations=34)
    labels, count = ndi.label(core)
    sizes = ndi.sum(np.ones_like(labels), labels, range(1, count + 1))
    plate = labels == 1 + int(np.argmax(sizes))
    ys, xs = np.where(plate)
    w, h = img.size
    # The eroded core lost 34 px on each side; the board may use all but a small margin of the lawn.
    margin = 34 - 10
    x0, x1, y0, y1 = xs.min() - margin, xs.max() + 1 + margin, ys.min() - margin, ys.max() + 1 + margin
    return {"plate": {k: round(float(v), 4) for k, v in {"x": x0 / w, "y": y0 / h, "width": (x1 - x0) / w, "height": (y1 - y0) / h}.items()}, "aspect": w / h}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--art-repo", type=Path, default=Path("/home/user/pofu-art"))
    parser.add_argument("--pick", action="append", default=[], help="slot=path in the art repo (a take's webp)")
    args = parser.parse_args()
    picks = dict(PICKS)
    for item in args.pick:
        slot, path = item.split("=", 1)
        picks[slot] = read_path(args.art_repo, path)
    info = backdrop(args.art_repo, picks["backdrop"])
    for slot, source in picks.items():
        if slot != "backdrop":
            piece(args.art_repo, slot, source)
    info.update({"canvas": CANVAS, "body": BODY, "disc": DISC})
    (RES / "flow-kit.json").write_text(json.dumps(info, indent=2) + "\n")
    print(info)


if __name__ == "__main__":
    main()
