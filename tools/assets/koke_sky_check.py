#!/usr/bin/env python3
"""Fails when a shipped Koke island sprite still carries its take's own sky.

The Koke plates are painted on their own sky and cut out for the world, which draws its own sky
behind them. A cut that keeps a piece of the painted sky shows as a pale block round the island on
every hour of the world's sky (stage 4 shipped one). This finds, for each stage:

1. where the sprite sits in the untouched take it was baked from (`preblur.py`'s `bake_src`, the
   1536 px take of `design/art/masters/koke-island-N`, else the master itself; the sprite is a crop of
   it, recoloured, never rescaled);
2. the take's sky colour at every pixel, spread in from the pixels the sprite leaves transparent;
3. the opaque sprite pixels whose take pixel is that sky: the sky's colour (RGB distance below
   `CLOSE`), as smooth as the painted sky, and reached from the transparent outside through such
   pixels. Those are the source background outside the silhouette.

Pixels within `RIM` px of the transparent outside are the edge's fringe and are counted apart;
deeper ones are a block of sky and fail the check. `RIM` and `MAX_BLOCK` are in master pixels and
scale with the take (twice the rim and four times the block for a take twice the master's width).

    python3 -I tools/assets/koke_sky_check.py            # all five stages
    python3 -I tools/assets/koke_sky_check.py 4 --overlay /tmp/k4.png
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

REPO = Path(__file__).resolve().parents[2]
CATALOG = REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
PREBLUR = REPO / "design/prototypes/interactions/tools/preblur.py"
STAGES = (0, 1, 2, 3, 4)
OPAQUE = 128  # sprite alpha at or above this is drawn as the island
CLOSE = 22.0  # RGB distance to the local sky colour under which a take pixel is sky
SMOOTH = 2.0  # the painted sky's local luma deviation (5 x 5) stays under this
RIM = 2  # px from the transparent outside that count as the edge's fringe
MAX_BLOCK = 20  # sky pixels deeper than the rim that a stage may carry


@dataclass
class Finding:
    stage: int
    offset: tuple[int, int]
    block: int  # opaque sky pixels deeper than RIM
    fringe: int  # opaque sky pixels within RIM of the outside
    box: tuple[int, int, int, int] | None  # sprite-space bounding box of the block pixels
    mask: np.ndarray  # sprite-space: 2 block, 1 fringe, 0 clean
    max_block: int = MAX_BLOCK

    @property
    def ok(self) -> bool:
        return self.block <= self.max_block


def master_path(stage: int) -> Path:
    return REPO / f"design/art/masters/koke-island-{stage}/koke-island-{stage}.png"


def take_path(stage: int) -> Path:
    """The image the stage's sprite is baked from: preblur's `bake_src` when it has one, else the master."""
    import importlib.util

    spec = importlib.util.spec_from_file_location("pofu_preblur", PREBLUR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    bake = mod.APP_SOURCES[f"koke-island-{stage}"].get("bake_src")
    return REPO / bake if bake else master_path(stage)


def sprite_path(stage: int) -> Path:
    return CATALOG / f"world-koke-island-{stage}.imageset/world-koke-island-{stage}.png"


def locate(take: np.ndarray, sprite: np.ndarray) -> tuple[int, int]:
    """The sprite's top-left corner in the take: the offset where their luma gradients agree best
    (the sprite is a crop of the take, recoloured by the pipeline but never moved or scaled)."""
    def edges(rgb: np.ndarray) -> np.ndarray:
        luma = rgb[..., :3].astype(np.float32).mean(axis=2)
        return np.hypot(ndimage.sobel(luma, 0), ndimage.sobel(luma, 1))

    dy, dx = take.shape[0] - sprite.shape[0], take.shape[1] - sprite.shape[1]
    if dy < 0 or dx < 0:
        raise ValueError("the sprite is larger than its take")
    xs, ys = range(dx + 1), range(dy + 1)
    if (dx + 1) * (dy + 1) > 20000 and min(sprite.shape[:2]) >= 64:
        # A large take: find it at half size first, then refine within a few pixels.
        def half(a: np.ndarray) -> np.ndarray:
            h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
            return a[:h, :w].astype(np.float32).reshape(h // 2, 2, w // 2, 2, -1).mean(axis=(1, 3))
        cx, cy = locate(half(take), half(sprite))
        xs = range(max(0, 2 * cx - 3), min(dx, 2 * cx + 3) + 1)
        ys = range(max(0, 2 * cy - 3), min(dy, 2 * cy + 3) + 1)
    big, small = edges(take), edges(sprite)
    weight = (sprite[..., 3] >= OPAQUE).astype(np.float32)
    small = (small - small[weight > 0].mean()) * weight
    best, at = -np.inf, (0, 0)
    for y in ys:
        for x in xs:
            score = float((big[y:y + small.shape[0], x:x + small.shape[1]] * small).sum())
            if score > best:
                best, at = score, (x, y)
    return at


def local_sky(rgb: np.ndarray, sky: np.ndarray, scale: float = 1.0) -> np.ndarray:
    """The sky's colour everywhere, spread in from the `sky` pixels: the finest of several normalised
    Gaussian averages that has sky within reach, so a wide block still gets its sky's colour."""
    out = np.zeros(rgb.shape, np.float32)
    done = np.zeros(sky.shape, bool)
    for sigma in (4.0 * scale, 12.0 * scale, 36.0 * scale, 108.0 * scale):
        w = ndimage.gaussian_filter(sky.astype(np.float32), sigma)
        c = np.stack([ndimage.gaussian_filter(rgb[..., i] * sky, sigma) for i in range(3)], axis=2)
        reach = (w > 0.02) & ~done
        out[reach] = c[reach] / w[reach][:, None]
        done |= reach
    return out


def smoothness(rgb: np.ndarray, scale: float = 1.0) -> np.ndarray:
    luma = rgb.mean(axis=2)
    size = int(round(5 * scale)) | 1  # 5 x 5 master pixels
    mean = ndimage.uniform_filter(luma, size)
    return np.sqrt(np.maximum(ndimage.uniform_filter(luma * luma, size) - mean * mean, 0))


def find(take: np.ndarray, sprite: np.ndarray, stage: int = -1, scale: float = 1.0) -> Finding:
    """Sky pixels left opaque in `sprite` (RGBA) cut from `take` (RGB, the take with its sky). `scale` is
    the take's width over the master's: the rim and the allowed block are in master pixels."""
    x, y = locate(take, sprite)
    h, w = sprite.shape[:2]
    src = take[y:y + h, x:x + w, :3].astype(np.float32)
    opaque = sprite[..., 3] >= OPAQUE
    outside = sprite[..., 3] == 0
    near_sky = np.linalg.norm(src - local_sky(src, outside, scale), axis=2) < CLOSE
    candidate = opaque & near_sky & (smoothness(src, scale) < SMOOTH)
    # The cut's feathered edge (alpha between 0 and OPAQUE) joins the outside, or a block would be
    # walled off from it by its own soft rim.
    clear = ~opaque
    labels, _ = ndimage.label(candidate | clear)
    keep = np.unique(labels[clear])
    sky = candidate & np.isin(labels, keep[keep > 0])
    depth = ndimage.distance_transform_edt(opaque)
    block = sky & (depth > RIM * scale)
    mask = np.where(block, 2, np.where(sky, 1, 0)).astype(np.uint8)
    ys, xs = np.nonzero(block)
    box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1) if xs.size else None
    return Finding(stage, (x, y), int(block.sum()), int((sky & ~block).sum()), box, mask,
                   int(round(MAX_BLOCK * scale * scale)))


def check_stage(stage: int) -> Finding:
    path = take_path(stage)
    take = np.asarray(Image.open(path).convert("RGB"))
    with Image.open(master_path(stage)) as master:
        scale = take.shape[1] / master.width
    sprite = np.asarray(Image.open(sprite_path(stage)).convert("RGBA"))
    return find(take, sprite, stage, scale)


def overlay(stage: int, finding: Finding, out: Path) -> None:
    """The sprite on blue with the block in red and the fringe in yellow."""
    sprite = Image.open(sprite_path(stage)).convert("RGBA")
    ground = Image.new("RGBA", sprite.size, (40, 90, 200, 255))
    ground.alpha_composite(sprite)
    rgb = np.array(ground.convert("RGB"))
    rgb[finding.mask == 2] = (255, 0, 0)
    rgb[finding.mask == 1] = (255, 220, 0)
    Image.fromarray(rgb).save(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("stages", nargs="*", type=int, default=list(STAGES))
    ap.add_argument("--overlay", type=Path, help="write the sprite with its sky marked (one stage)")
    args = ap.parse_args()
    failed = 0
    for stage in args.stages:
        f = check_stage(stage)
        state = "ok  " if f.ok else "FAIL"
        print(f"{state} koke-island-{stage}: {f.block} px of sky inside the cut (box {f.box}), "
              f"{f.fringe} px of fringe; sprite at {f.offset} in the take")
        failed += not f.ok
        if args.overlay:
            overlay(stage, f, args.overlay)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
