#!/usr/bin/env python3
"""Ingest the flow board's kit v2: water (batch 135), lip kit (135), mouth
spout (135), rocks (135) and board edge (132).

Reads the picked takes from a checkout of the private art repository with
`git show origin/main:<path>` and writes the app's PNGs into
PofuGames/Resources. Reproducible: run again to regenerate. Only the files
named below are written; nothing is cleared.

  tools/art/ingest_flow_kit_v2.py --art-repo /home/user/pofu-art

Picks and numbers come from each job's review.yaml (measured on the takes):
- water t2: Lab chroma x0.9 (the take is ~8 percent more saturated than the
  backdrop's pool), stored 1024 px. The app drops its water tint.
- lip kit t1 (2172x724): four pieces at source x 76-445 (left end, cropped to
  its outer stone at the seam x 263), 504-1080 (run), 1125-1649 (spillway),
  1708-2097 (right end, cropped from the seam x 1879). All cut from the same
  rows (255 to 531) so they share one baseline; the stone's bottom is source
  y 467. Stored at half size.
- spout t1 (1774x887): dry left half, wet right half, each placed on a
  700-wide canvas centred on its own channel (dry x 447, wet x 1312), rows
  111 to 794 (the closed top rim is rows 111 to 190). Stored at half size.
- rocks t1: one sheet, four quadrants; trimmed; one scale so the largest long
  side is 216 px; no regrade (they match the backdrop's boulders).
- edge t1 (1254 px): stored at 0.6 so one source px is one device px at draw
  scale 0.6; the app slices it at 190 source px (114 stored).
"""
import argparse
import io
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "Packages/PofuKit/Sources/PofuGames/Resources"
TAKES = "design/art/takes"
WATER = f"{TAKES}/batch-135-flow-kit-v2/x-flow-water-v2/prop__x-flow-water-v2--t2.webp"
LIP = f"{TAKES}/batch-135-flow-kit-v2/x-flow-lip-kit/prop__x-flow-lip-kit--t1.webp"
SPOUT = f"{TAKES}/batch-135-flow-kit-v2/x-flow-mouth-spout/prop__x-flow-mouth-spout--t1.webp"
ROCKS = f"{TAKES}/batch-135-flow-kit-v2/x-flow-rocks-v2/prop__x-flow-rocks-v2--t1.webp"
EDGE = f"{TAKES}/batch-132-flow-board-edge-v2/x-flow-board-edge-v2/prop__x-flow-board-edge-v2--t1.webp"

ROCK_LONG_SIDE = 216
LIP_ROWS = (255, 531)
LIP_PIECES = {"flow-lip-end-left": (76, 263), "flow-lip-run": (504, 1080), "flow-lip-spill": (1125, 1649), "flow-lip-end-right": (1879, 2098)}
SPOUT_ROWS = (111, 794)
SPOUT_HALF = 350
SPOUT_CHANNEL = {"flow-spout-dry": 447, "flow-spout-wet": 1312}
EDGE_SCALE = 0.6
WATER_CHROMA = 0.9


def read_take(art_repo: Path, path: str) -> Image.Image:
    blob = subprocess.run(["git", "-C", str(art_repo), "show", f"origin/main:{path}"], check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(blob)).convert("RGBA")


def clamp_alpha(a):
    a = a.copy()
    a[a <= 4] = 0
    a[a >= 250] = 255
    return a


def prepare(img: Image.Image) -> Image.Image:
    arr = np.asarray(img).copy()
    arr[..., 3] = clamp_alpha(arr[..., 3])
    arr[arr[..., 3] == 0, :3] = 0
    return Image.fromarray(arr, "RGBA")


def resize_premultiplied(img: Image.Image, size) -> Image.Image:
    arr = np.asarray(img).astype(np.float32) / 255
    arr[..., :3] *= arr[..., 3:4]
    planes = [Image.fromarray(arr[..., i], mode="F").resize(size, Image.LANCZOS) for i in range(4)]
    out = np.stack([np.asarray(p) for p in planes], axis=-1)
    alpha = np.clip(out[..., 3:4], 0, 1)
    rgb = np.where(alpha > 1e-4, out[..., :3] / np.maximum(alpha, 1e-4), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")


def srgb_to_lab(rgb):
    c = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


def lab_to_srgb(lab):
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], axis=-1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) / (24389 / 27)) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2404542, -1.5371385, -0.4985314], [-0.9692660, 1.8760108, 0.0415560], [0.0556434, -0.2040259, 1.0572252]])
    c = np.clip(xyz @ m.T, 0, 1)
    return np.where(c <= 0.0031308, 12.92 * c, 1.055 * c ** (1 / 2.4) - 0.055)


def half(img: Image.Image) -> Image.Image:
    return resize_premultiplied(img, (max(1, round(img.width / 2)), max(1, round(img.height / 2))))


def save(img: Image.Image, name: str) -> None:
    img.save(RES / f"{name}.png", optimize=True)
    print(name, img.size)


def water(art_repo: Path) -> None:
    img = read_take(art_repo, WATER).convert("RGB").resize((1024, 1024), Image.LANCZOS)
    lab = srgb_to_lab(np.asarray(img).astype(np.float32) / 255)
    lab[..., 1] *= WATER_CHROMA
    lab[..., 2] *= WATER_CHROMA
    out = (np.clip(lab_to_srgb(lab), 0, 1) * 255 + 0.5).astype(np.uint8)
    save(Image.fromarray(out, "RGB"), "flow-water")


def lip(art_repo: Path) -> None:
    img = prepare(read_take(art_repo, LIP))
    for name, (x0, x1) in LIP_PIECES.items():
        save(half(img.crop((x0, LIP_ROWS[0], x1, LIP_ROWS[1]))), name)
    print("lip: stone bottom at stored row", (467 - LIP_ROWS[0]) // 2, "of", (LIP_ROWS[1] - LIP_ROWS[0]) // 2)


def spout(art_repo: Path) -> None:
    img = prepare(read_take(art_repo, SPOUT))
    for name, centre in SPOUT_CHANNEL.items():
        piece = img.crop((centre - SPOUT_HALF, SPOUT_ROWS[0], centre + SPOUT_HALF, SPOUT_ROWS[1]))
        arr = np.asarray(piece).copy()
        # Keep only this state's half: the other half's pixels lie outside its own 887 px column.
        column = (0, 887) if "dry" in name else (887, 1774)
        xs = np.arange(centre - SPOUT_HALF, centre + SPOUT_HALF)
        arr[:, (xs < column[0]) | (xs >= column[1]), :] = 0
        save(half(Image.fromarray(arr, "RGBA")), name)


def rocks(art_repo: Path) -> None:
    img = prepare(read_take(art_repo, ROCKS))
    mid = img.width // 2
    quads = [(0, 0, mid, mid), (mid, 0, img.width, mid), (0, mid, mid, img.height), (mid, mid, img.width, img.height)]
    parts = []
    for box in quads:
        part = img.crop(box)
        parts.append(part.crop(part.getchannel("A").getbbox()))
    factor = ROCK_LONG_SIDE / max(max(p.size) for p in parts)
    for n, part in enumerate(parts, start=1):
        out = resize_premultiplied(part, (max(1, round(part.width * factor)), max(1, round(part.height * factor))))
        save(out, "flow-rock-cut" if n == 1 else f"flow-rock-cut-{n}")


def edge(art_repo: Path) -> None:
    img = prepare(read_take(art_repo, EDGE))
    side = round(img.width * EDGE_SCALE)
    save(resize_premultiplied(img, (side, side)), "flow-board-edge")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--art-repo", type=Path, default=Path("/home/user/pofu-art"))
    args = parser.parse_args()
    water(args.art_repo)
    lip(args.art_repo)
    spout(args.art_repo)
    rocks(args.art_repo)
    edge(args.art_repo)


if __name__ == "__main__":
    main()
