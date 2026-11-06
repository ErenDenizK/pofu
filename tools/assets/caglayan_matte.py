#!/usr/bin/env python3
"""One-off: the island matte shared by the five Çağlayan plates (batch 43).

The plates are painted on their own sky, and the island's lilac cliff and white-peach underside sit
close to that sky in colour, so the Koke plates' colour rule (`preblur._island_cutout`) cannot cut
them. This traces the island's silhouette by hand (`TRACE`, in the 768 x 512 master's pixels), runs
OpenCV's GrabCut inside a band around it for each of the five stages, keeps the pixels most stages agree
on and writes ONE matte, `design/art/masters/caglayan-island-0/caglayan-matte.png`, which
`preblur.py` reads (`matte_file`). The result is committed, so the pipeline itself needs no OpenCV:

    pip install opencv-python-headless && python3 tools/assets/caglayan_matte.py
"""
from pathlib import Path

import cv2
import numpy as np

REPO = Path(__file__).resolve().parents[2]
TRACE = np.array([
    (203, 90), (257, 67), (293, 47), (333, 30), (373, 40), (433, 40), (487, 47), (520, 73), (547, 113), (600, 110),
    (660, 103), (693, 157), (700, 193), (727, 243), (742, 273), (720, 320), (700, 353), (667, 393), (650, 433),
    (580, 460), (467, 460), (460, 493), (400, 460), (267, 447), (260, 480), (187, 433), (133, 440), (93, 360),
    (47, 327), (25, 267), (40, 240), (80, 213), (127, 187), (160, 137), (200, 107),
], np.int32)
OUT = REPO / "design/art/masters/caglayan-island-0/caglayan-matte.png"


def kernel(r: int):
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))


def stage_matte(n: int) -> np.ndarray:
    img = cv2.imread(str(REPO / f"design/art/masters/caglayan-island-{n}/caglayan-island-{n}.png"))
    h, w = img.shape[:2]
    inside = np.zeros((h, w), np.uint8)
    cv2.fillPoly(inside, [TRACE], 255)
    mask = np.full((h, w), cv2.GC_BGD, np.uint8)
    mask[cv2.dilate(inside, kernel(14)) > 0] = cv2.GC_PR_BGD
    mask[inside > 0] = cv2.GC_PR_FGD
    mask[cv2.erode(inside, kernel(18)) > 0] = cv2.GC_FGD
    cv2.grabCut(img, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 8, cv2.GC_INIT_WITH_MASK)
    return ((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)).astype(np.uint8) * 255


def largest(mask: np.ndarray) -> np.ndarray:
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask)
    keep = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return ((labels == keep) * 255).astype(np.uint8)


def fill_holes(mask: np.ndarray) -> np.ndarray:
    count, labels, stats, _ = cv2.connectedComponentsWithStats(255 - mask)
    out = mask.copy()
    for i in range(1, count):
        if labels[0, 0] != i:
            out[labels == i] = 255
    return out


def main() -> None:
    votes = sum((stage_matte(n) > 0).astype(np.int32) for n in range(5))
    matte = ((votes >= 3) * 255).astype(np.uint8)
    matte = cv2.morphologyEx(matte, cv2.MORPH_OPEN, kernel(3))
    matte = fill_holes(largest(matte))
    cv2.imwrite(str(OUT), matte)
    print(f"wrote {OUT.relative_to(REPO)} ({int((matte > 0).sum())} px)")


if __name__ == "__main__":
    main()
