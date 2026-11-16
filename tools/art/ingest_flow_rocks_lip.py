#!/usr/bin/env python3
"""Ingest the flow board's cut-out rocks (batch 130) and top lip (batch 131).

Reads the picked takes from a checkout of the private art repository with
`git show origin/main:<path>` (never copies refs into this repo's .git) and
writes the app's PNGs into PofuGames/Resources. Reproducible: run again to
regenerate.

  tools/art/ingest_flow_rocks_lip.py --art-repo /home/user/pofu-art

Rocks:  flow-rock-cut.png, -2, -3, -4 (replace the batch 121 cut-out).
Lip:    flow-board-lip.png.

What it does, and why (from the art review of both batches):
- takes are 1254 px (lip 2172x724), not the manifest size: scaled down with
  premultiplied-alpha Lanczos so no fringe appears;
- alpha is clamped (<=4 -> 0, >=250 -> 255): WebP left insides at 252-254;
- trimmed to the alpha box;
- rocks 1, 2, 4 are chalk-flat (L about 83 of 100): darkened 8 L; rock 4's
  peach and lilac tints are pulled 20 percent toward grey (its green clover
  is left alone);
- the lip's dry spillway is only ~16 percent of its width while the painted
  cascade of the backdrop is ~40 percent of the board: a flat strip of the
  notch floor is stretched (stretching only the featureless floor, not the
  moss ends) until the dip (measured where the top edge is within 50 px of the floor) is ~38 percent of the lip (the painted cascade is ~40 percent of the board).
"""
import argparse
import io
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "Packages/PofuKit/Sources/PofuGames/Resources"
ROCK_PATH = "design/art/takes/batch-130-flow-rock-cutouts/x-flow-rock-cut-{n}/prop__x-flow-rock-cut-{n}--t1.webp"
LIP_PATH = "design/art/takes/batch-131-flow-board-frame/x-flow-board-lip/prop__x-flow-board-lip--t1.webp"

# The app's cell is 246 px in the player-path frames; a rock may fill 216 of it.
ROCK_LONG_SIDE = 216
LIP_WIDTH = 1200
# The notch (dip) as a share of the lip's width after the stretch.
NOTCH_SHARE = 0.38


def read_take(art_repo: Path, path: str) -> Image.Image:
    blob = subprocess.run(["git", "-C", str(art_repo), "show", f"origin/main:{path}"], check=True, capture_output=True).stdout
    return Image.open(io.BytesIO(blob)).convert("RGBA")


def clamp_alpha(a: np.ndarray) -> np.ndarray:
    a = a.copy()
    a[a <= 4] = 0
    a[a >= 250] = 255
    return a


def trim(img: Image.Image) -> Image.Image:
    box = img.getchannel("A").getbbox()
    return img.crop(box)


def resize_premultiplied(img: Image.Image, size) -> Image.Image:
    arr = np.asarray(img).astype(np.float32) / 255
    arr[..., :3] *= arr[..., 3:4]
    planes = [Image.fromarray(arr[..., i], mode="F").resize(size, Image.LANCZOS) for i in range(4)]
    out = np.stack([np.asarray(p) for p in planes], axis=-1)
    alpha = np.clip(out[..., 3:4], 0, 1)
    rgb = np.where(alpha > 1e-4, out[..., :3] / np.maximum(alpha, 1e-4), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), alpha], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    c = np.where(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124564, 0.3575761, 0.1804375], [0.2126729, 0.7151522, 0.0721750], [0.0193339, 0.1191920, 0.9503041]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 216 / 24389, np.cbrt(xyz), (24389 / 27 * xyz + 16) / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


def lab_to_srgb(lab: np.ndarray) -> np.ndarray:
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], axis=-1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) / (24389 / 27)) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2404542, -1.5371385, -0.4985314], [-0.9692660, 1.8760108, 0.0415560], [0.0556434, -0.2040259, 1.0572252]])
    c = np.clip(xyz @ m.T, 0, 1)
    return np.where(c <= 0.0031308, 12.92 * c, 1.055 * c ** (1 / 2.4) - 0.055)


def regrade(img: Image.Image, darken_l: float, desaturate_nongreen: float = 0.0) -> Image.Image:
    arr = np.asarray(img).astype(np.float32) / 255
    lab = srgb_to_lab(arr[..., :3])
    lab[..., 0] = np.clip(lab[..., 0] - darken_l, 0, 100)
    if desaturate_nongreen:
        tint = lab[..., 1] > -4  # peach and lilac sit at a >= -4; clover and grass are green (a < -4)
        lab[..., 1] = np.where(tint, lab[..., 1] * (1 - desaturate_nongreen), lab[..., 1])
        lab[..., 2] = np.where(tint, lab[..., 2] * (1 - desaturate_nongreen), lab[..., 2])
    arr[..., :3] = lab_to_srgb(lab)
    return Image.fromarray((arr * 255 + 0.5).astype(np.uint8), "RGBA")


def prepare(img: Image.Image) -> Image.Image:
    arr = np.asarray(img).copy()
    arr[..., 3] = clamp_alpha(arr[..., 3])
    arr[arr[..., 3] == 0, :3] = 0
    return trim(Image.fromarray(arr, "RGBA"))


def rock(art_repo: Path, n: int, factor: float) -> Image.Image:
    img = prepare(read_take(art_repo, ROCK_PATH.format(n=n)))
    img = resize_premultiplied(img, (max(1, round(img.width * factor)), max(1, round(img.height * factor))))
    if n in (1, 2, 4):
        img = regrade(img, 8.0, 0.2 if n == 4 else 0.0)
    return img


def lip(art_repo: Path) -> Image.Image:
    img = prepare(read_take(art_repo, LIP_PATH))
    arr = np.asarray(img)
    a = arr[..., 3]
    # The notch floor: the span where the top edge sits at its lowest, flat.
    top = np.array([np.argmax(a[:, x] > 128) if (a[:, x] > 128).any() else -1 for x in range(a.shape[1])])
    floor = top[a.shape[1] // 3: 2 * a.shape[1] // 3].max()
    low = np.where(top[: 2 * a.shape[1] // 3] >= floor - 2)[0]
    low = low[low > a.shape[1] // 3]
    mid = (low.min() + low.max()) // 2
    dip = np.where(top > floor - 50)[0]
    dip = dip[(dip > mid - 400) & (dip < mid + 400)]
    dip_width = dip.max() - dip.min()
    strip = 120
    extra = max(0, round((NOTCH_SHARE * img.width - dip_width) / (1 - NOTCH_SHARE)))
    left = img.crop((0, 0, mid - strip // 2, img.height))
    centre = img.crop((mid - strip // 2, 0, mid + strip // 2, img.height)).resize((strip + extra, img.height), Image.BICUBIC)
    right = img.crop((mid + strip // 2, 0, img.width, img.height))
    out = Image.new("RGBA", (left.width + centre.width + right.width, img.height))
    out.paste(left, (0, 0))
    out.paste(centre, (left.width, 0))
    out.paste(right, (left.width + centre.width, 0))
    print(f"lip: notch floor centre x={mid}, dip {dip_width}px, strip stretched +{extra}px, width {img.width}->{out.width}")
    scale = LIP_WIDTH / out.width
    return resize_premultiplied(out, (LIP_WIDTH, round(out.height * scale)))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--art-repo", type=Path, default=Path("/home/user/pofu-art"))
    args = parser.parse_args()
    # One factor for all four so the painted relative sizes hold: the largest long side becomes 216 px.
    longest = max(max(prepare(read_take(args.art_repo, ROCK_PATH.format(n=n))).size) for n in (1, 2, 3, 4))
    factor = ROCK_LONG_SIDE / longest
    for n in (1, 2, 3, 4):
        name = "flow-rock-cut" if n == 1 else f"flow-rock-cut-{n}"
        img = rock(args.art_repo, n, factor)
        img.save(RES / f"{name}.png", optimize=True)
        print(name, img.size)
    img = lip(args.art_repo)
    img.save(RES / "flow-board-lip.png", optimize=True)
    print("flow-board-lip", img.size)


if __name__ == "__main__":
    main()
