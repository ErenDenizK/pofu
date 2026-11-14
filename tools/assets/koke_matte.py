#!/usr/bin/env python3
"""The Koke healed plate's island matte (stage 4), cut by script from the untouched take.

`preblur._island_cutout` cuts the Koke plates from their own sky by colour. On stage 4 the take's
upper-left sky is warm (a golden sun) and full of drifting petals, so the colour rule calls that sky
island, closing joins it to Koke's back and the shipped sprite carried a stair-stepped block of sky
with petals round the bear. This traces the healed island's silhouette by hand (`TRACE_4`, in the
768 x 512 master's pixels: lawn, Koke, ferns, flowers and the three roots; the petals in the air are
left out), runs OpenCV's GrabCut in a band around it and writes the matte that `preblur.py` reads
(`matte_file`). The take itself (`koke-island-4.png`, `raw.webp`) is never written. The matte is
committed, so the pipeline needs no OpenCV:

    pip install opencv-python-headless && python3 tools/assets/koke_matte.py
    python3 -I design/prototypes/interactions/tools/preblur.py app

`tools/assets/koke_sky_check.py` checks the shipped sprites for sky left outside the silhouette.
"""
from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np

REPO = Path(__file__).resolve().parents[2]
PREBLUR = REPO / "design/prototypes/interactions/tools/preblur.py"
STAGES = (0, 1, 2, 3, 4)


def master(n: int) -> Path:
    return REPO / f"design/art/masters/koke-island-{n}/koke-island-{n}.png"


def matte_path(n: int) -> Path:
    return REPO / f"design/art/masters/koke-island-{n}/koke-matte.png"

# Clockwise from the lawn's left edge, a few pixels outside the painted edge; GrabCut finds the edge
# itself inside a band of BAND px either side of this line.
TRACE_4 = np.array([
    (52, 262), (56, 232), (70, 205), (80, 175), (85, 150), (105, 135), (128, 128), (140, 120), (132, 100),
    (150, 88), (175, 72), (195, 70), (215, 85), (225, 70), (240, 62), (262, 62), (285, 45), (300, 12),
    (330, 5), (365, 8), (385, 25), (420, 28), (450, 38), (475, 55), (500, 75), (520, 100), (535, 125),
    (548, 108), (570, 96), (595, 95), (612, 105), (625, 125), (640, 148), (665, 150), (690, 168), (703, 195),
    (710, 225), (710, 265), (695, 305), (668, 345), (635, 375), (622, 380), (625, 410), (618, 435),
    (605, 432), (600, 400), (560, 410), (520, 418), (470, 430), (420, 432), (392, 428), (390, 450),
    (385, 478), (373, 478), (370, 450), (365, 428), (310, 428), (260, 422), (210, 412), (160, 395),
    (158, 410), (152, 430), (142, 430), (140, 400), (135, 380), (110, 360), (80, 325), (60, 285),
], np.int32)
# The three roots hang pale against pale clouds, so GrabCut drops their tails: their centre lines
# are marked as island for certain.
ROOTS_4 = [
    np.array([(147, 372), (150, 387), (144, 397), (151, 407), (150, 420), (149, 428)], np.int32),
    np.array([(382, 422), (386, 437), (377, 445), (382, 455), (381, 465), (380, 472)], np.int32),
    np.array([(605, 378), (612, 392), (607, 405), (612, 415), (610, 426)], np.int32),
]
# Sky walled in between a fern frond and the left bellflowers' stems, out of the flood's reach: marked
# as sky for certain.
SKY_4 = [np.array([(140, 136), (150, 139), (160, 141), (166, 145)], np.int32)]
BAND = 10
SKY_SD = 1.5  # the painted sky is smooth: local luma deviation (5 x 5) below this
SKY_LUMA = 195  # and pale
PEEL_STEPS = 6
PEEL_DISTANCE = 24.0  # RGB distance to the local sky under which a rim pixel is sky
SKY_ROWS = 250  # only above the lawn's rim: below it the underside is as smooth and pale as the clouds


def smooth_sky(img: np.ndarray, outside: np.ndarray) -> np.ndarray:
    """Smooth, pale pixels reached from `outside` through smooth, pale pixels: the sky showing between
    fern fronds, flower stems and Koke's back, which a colour model alone takes for the pale island."""
    luma = img.astype(np.float32).mean(axis=2)
    mean = cv2.blur(luma, (5, 5))
    sd = np.sqrt(np.maximum(cv2.blur(luma * luma, (5, 5)) - mean * mean, 0))
    smooth = ((sd < SKY_SD) & (luma > SKY_LUMA)).astype(np.uint8)
    smooth[SKY_ROWS:] = 0
    _, labels = cv2.connectedComponents(smooth | outside)
    keep = np.unique(labels[(outside > 0)])
    return np.isin(labels, keep[keep > 0]) & (smooth > 0)


def kernel(r: int) -> np.ndarray:
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))


def largest(mask: np.ndarray) -> np.ndarray:
    _, labels, stats, _ = cv2.connectedComponentsWithStats(mask)
    keep = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return ((labels == keep) * 255).astype(np.uint8)


def fill_holes(mask: np.ndarray, keep: np.ndarray | None = None) -> np.ndarray:
    """Holes filled, except a hole that holds a marked sky pocket (`keep`)."""
    count, labels, _, _ = cv2.connectedComponentsWithStats(255 - mask)
    out = mask.copy()
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    if keep is not None:
        border |= set(np.unique(labels[keep > 0]))
    for i in range(1, count):
        if i not in border:
            out[labels == i] = 255
    return out


def local_sky(img: np.ndarray, sky: np.ndarray, sigma: float = 6.0) -> np.ndarray:
    """The sky's colour at every pixel, spread in from the `sky` pixels (normalised convolution)."""
    w = cv2.GaussianBlur(sky.astype(np.float32), (0, 0), sigma)
    rgb = cv2.GaussianBlur(img.astype(np.float32) * sky[..., None], (0, 0), sigma)
    return rgb / np.maximum(w, 1e-6)[..., None]


def peel(img: np.ndarray, fg: np.ndarray, steps: int = PEEL_STEPS, close: float = PEEL_DISTANCE) -> np.ndarray:
    """Strip the matte's rim of pixels that are the local sky's colour, one ring at a time: the pale
    halo GrabCut leaves round the flowers and the lawn's rim."""
    fg = fg > 0
    for _ in range(steps):
        rim = fg & ~(cv2.erode(fg.astype(np.uint8), kernel(1)) > 0)
        dist = np.linalg.norm(img.astype(np.float32) - local_sky(img, ~fg), axis=2)
        drop = rim & (dist < close)
        if not drop.any():
            break
        fg &= ~drop
    return fg.astype(np.uint8) * 255


def matte(img: np.ndarray, trace: np.ndarray, sure: list[np.ndarray] = (), band: int = BAND,
          region: bool = False, sky: list[np.ndarray] = ()) -> np.ndarray:
    """GrabCut inside a band round the traced silhouette (a polygon, or a mask with `region`); the
    largest piece, holes filled."""
    h, w = img.shape[:2]
    if region:
        inside = trace.copy()
    else:
        inside = np.zeros((h, w), np.uint8)
        cv2.fillPoly(inside, [trace], 255)
    mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    mask[cv2.dilate(inside, kernel(band)) > 0] = cv2.GC_PR_BGD
    mask[inside > 0] = cv2.GC_PR_FGD
    mask[cv2.erode(inside, kernel(band)) > 0] = cv2.GC_FGD
    mask[smooth_sky(img, (inside == 0).astype(np.uint8))] = cv2.GC_BGD
    lines = np.zeros((h, w), np.uint8)
    cv2.polylines(lines, sure, False, 255, 3)
    mask[lines > 0] = cv2.GC_FGD
    pockets = np.zeros((h, w), np.uint8)
    cv2.polylines(pockets, list(sky), False, 255, 2)
    mask[pockets > 0] = cv2.GC_BGD
    cv2.setRNGSeed(0)
    cv2.grabCut(img, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 8, cv2.GC_INIT_WITH_MASK)
    out = ((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)).astype(np.uint8) * 255
    out = cv2.morphologyEx(out, cv2.MORPH_OPEN, kernel(1))
    out = fill_holes(largest(out), keep=pockets)
    out = peel(img, out)
    out[lines > 0] = 255  # peeling never takes a root
    return fill_holes(largest(out), keep=pockets)


def colour_rule(img: np.ndarray) -> np.ndarray:
    """The pipeline's own colour cut (`preblur._island_cutout`) as a 0/255 mask."""
    sys.path.insert(0, str(PREBLUR.parent))
    import preblur
    from PIL import Image

    cut = preblur._island_cutout(Image.fromarray(img[..., ::-1]))
    return (np.asarray(cut.getchannel("A")) >= 128).astype(np.uint8) * 255


def stage_matte(n: int) -> np.ndarray:
    img = cv2.imread(str(master(n)), cv2.IMREAD_COLOR)
    if n == 4:
        return matte(img, TRACE_4, ROOTS_4, sky=SKY_4)
    # Stages 0 to 3 keep the hump's outline, which the colour rule finds; only the sky it lets in
    # above the lawn (behind the fern, between the bellflowers) is taken back out. Below the lawn's
    # rim the colour rule's cut stands, roots and all, peeled of the sky it closes into the corners
    # where the roots meet the underside.
    rule = colour_rule(img)
    out = matte(img, rule, region=True)
    out[SKY_ROWS:] = rule[SKY_ROWS:]
    return fill_holes(largest(peel(img, out)))


def main() -> None:
    stages = [int(a) for a in sys.argv[1:]] or list(STAGES)
    for n in stages:
        out = stage_matte(n)
        cv2.imwrite(str(matte_path(n)), out)
        print(f"wrote {matte_path(n).relative_to(REPO)} ({int((out > 0).sum())} px)")


if __name__ == "__main__":
    main()
