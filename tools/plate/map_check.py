#!/usr/bin/env python3
"""Checks on the painted Map's frames (`map-plate-*`, `flight-*`), as a blind critic would judge them.

    python3 -I tools/plate/map_check.py FRAME.png [FRAME.png ...] [--json OUT]

Four measures, each a function on one frame (RGB, 1206 x 2622) so a test can feed it a synthetic one:

  flat_top     the top band of the screen (`TOP` of its height) is not an empty gradient: the spread of
               its local detail (the 95th percentile of a high-pass, in luma 0..255) reaches `min_detail`
               (Home's own frame measures about 6 there; the first painted Map measured 0.5)
  night_islands at night every island is about as light as the others: the median luma of each island's
               pixels within `tol` of their median (one island left day-lit under a night sky is the outlier)
  light_ring   no light ring round an island: in a thin band just outside its mask the luma does not sit
               above both the island's rim inside and the sky further out by more than `ring_de`
  sky_edges    no straight vertical edge in the sky: no column whose horizontal step stays above `step`
               over `run` rows in a row (a tile cut, a cloud ending on a straight line)

The islands' masks come from `--islands` boxes (x0,y0,x1,y1 in frame px, as `name:x0,y0,x1,y1`) and a
colour split inside each box: the pixels that differ from the sky around the box. Every measure is a
guard against a known defect; none clears a frame by itself (look at it at 1:1). Needs numpy, OpenCV,
Pillow.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

TOP = 0.25
THRESHOLDS = {
    "flat_top": {"min_detail": 3.0},
    "night_islands": {"tol": 0.18},
    "light_ring": {"ring_px": 6, "ring_de": 12.0, "max_share": 0.08},
    "sky_edges": {"step": 6.0, "run": 100, "margin": 4, "wander": 2},
}


def luma(rgb: np.ndarray) -> np.ndarray:
    rgb = rgb.astype(np.float32)
    return 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]


def check_flat_top(frame: np.ndarray, th: dict = THRESHOLDS["flat_top"]) -> dict:
    """The top band carries painted detail, not only a gradient."""
    band = luma(frame[: int(frame.shape[0] * TOP)])
    hp = np.abs(band - cv2.GaussianBlur(band, (0, 0), 6))
    detail = float(np.percentile(hp, 95))
    return {"detail": round(detail, 2), "ok": detail >= th["min_detail"]}


def island_mask(frame: np.ndarray, box: tuple[int, int, int, int], de: float = 18.0) -> np.ndarray:
    """The island's pixels inside `box`: those that differ from the sky ring round the box by more than
    `de` (RGB distance), the largest connected piece and its holes filled."""
    h, w = frame.shape[:2]
    x0, y0, x1, y1 = max(box[0], 0), max(box[1], 0), min(box[2], w), min(box[3], h)
    pad = 12
    ring = np.zeros((h, w), bool)
    ring[max(y0 - pad, 0): min(y1 + pad, h), max(x0 - pad, 0): min(x1 + pad, w)] = True
    ring[y0:y1, x0:x1] = False
    sky = np.median(frame[ring].astype(np.float32), axis=0) if ring.any() else np.zeros(3, np.float32)
    crop = frame[y0:y1, x0:x1].astype(np.float32)
    diff = np.linalg.norm(crop - sky, axis=2) > de
    n, lbl, stats, _ = cv2.connectedComponentsWithStats(diff.astype(np.uint8), 8)
    mask = np.zeros((h, w), bool)
    if n > 1:
        big = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        piece = (lbl == big).astype(np.uint8)
        filled = piece.copy()
        cnts, _ = cv2.findContours(piece, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        cv2.drawContours(filled, cnts, -1, 1, thickness=cv2.FILLED)
        mask[y0:y1, x0:x1] = filled > 0
    return mask


def check_night_islands(frame: np.ndarray, masks: dict[str, np.ndarray], th: dict = THRESHOLDS["night_islands"]) -> dict:
    """Each island's median luma against the islands' median: none stands far off it."""
    values = {name: float(np.median(luma(frame)[m])) for name, m in masks.items() if m.sum() > 200}
    if len(values) < 2:
        return {"islands": values, "ok": True}
    mid = float(np.median(list(values.values())))
    off = {name: round(v / max(mid, 1e-6) - 1, 3) for name, v in values.items()}
    return {"islands": {k: round(v, 1) for k, v in values.items()}, "off": off,
            "ok": all(abs(v) <= th["tol"] for v in off.values())}


def check_light_ring(frame: np.ndarray, mask: np.ndarray, th: dict = THRESHOLDS["light_ring"]) -> dict:
    """A thin band just outside the island is not lighter than both the rim inside and the sky beyond."""
    px = th["ring_px"]
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * px + 1, 2 * px + 1))
    m = mask.astype(np.uint8)
    out1 = cv2.dilate(m, k) > 0
    out2 = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (6 * px + 1, 6 * px + 1))) > 0
    inner = mask & ~(cv2.erode(m, k) > 0)
    ring = out1 & ~mask
    beyond = out2 & ~out1
    if ring.sum() == 0 or beyond.sum() == 0 or inner.sum() == 0:
        return {"share": 0.0, "ok": True}
    y = luma(frame)
    blur_in = cv2.blur(np.where(inner, y, 0), (4 * px + 1, 4 * px + 1)) / np.maximum(cv2.blur(inner.astype(np.float32), (4 * px + 1, 4 * px + 1)), 1e-6)
    blur_out = cv2.blur(np.where(beyond, y, 0), (8 * px + 1, 8 * px + 1)) / np.maximum(cv2.blur(beyond.astype(np.float32), (8 * px + 1, 8 * px + 1)), 1e-6)
    bright = ring & (y > blur_in + th["ring_de"]) & (y > blur_out + th["ring_de"])
    share = float(bright.sum() / ring.sum())
    return {"share": round(share, 4), "ok": share <= th["max_share"]}


def check_sky_edges(frame: np.ndarray, sky: np.ndarray | None = None, th: dict = THRESHOLDS["sky_edges"]) -> dict:
    """No straight vertical edge in the sky: a column whose step to its neighbour stays high over a run
    of rows. `sky` masks where the sky is (default: everywhere)."""
    y = cv2.GaussianBlur(luma(frame), (0, 0), 1.0)
    step = np.abs(np.diff(y, axis=1))
    if sky is not None:
        step = np.where(sky[:, 1:] & sky[:, :-1], step, 0)
    m = th["margin"]
    step[:, :m] = 0
    step[:, -m:] = 0
    # A cut drawn by hand wanders a pixel or two: a column counts while the edge stays within `wander`.
    hot = cv2.dilate((step > th["step"]).astype(np.uint8), np.ones((1, 2 * th["wander"] + 1), np.uint8)) > 0
    worst, where = 0, None
    for x in np.flatnonzero(hot.sum(0) >= th["run"]):
        col = hot[:, x].astype(np.int8)
        d = np.diff(np.concatenate([[0], col, [0]]))
        starts, ends = np.flatnonzero(d == 1), np.flatnonzero(d == -1)
        run = int((ends - starts).max()) if len(starts) else 0
        if run > worst:
            worst, where = run, int(x)
    return {"longest_run": worst, "column": where, "ok": worst < th["run"]}


def parse_box(text: str) -> tuple[str, tuple[int, int, int, int]]:
    name, nums = text.split(":", 1)
    x0, y0, x1, y1 = (int(v) for v in nums.split(","))
    return name, (x0, y0, x1, y1)


def check(frame: np.ndarray, boxes: dict[str, tuple[int, int, int, int]], night: bool) -> dict:
    masks = {name: island_mask(frame, box) for name, box in boxes.items()}
    sky = np.ones(frame.shape[:2], bool)
    for m in masks.values():
        sky &= ~(cv2.dilate(m.astype(np.uint8), np.ones((15, 15), np.uint8)) > 0)
    out = {"flat_top": check_flat_top(frame), "sky_edges": check_sky_edges(frame, sky)}
    out["light_ring"] = {name: check_light_ring(frame, m) for name, m in masks.items()}
    if night:
        out["night_islands"] = check_night_islands(frame, masks)
    out["ok"] = all(v["ok"] for k, v in out.items() if k not in ("light_ring",)) and all(v["ok"] for v in out["light_ring"].values())
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("frames", nargs="+", type=Path)
    ap.add_argument("--islands", nargs="*", default=[], help="name:x0,y0,x1,y1 island boxes in frame px")
    ap.add_argument("--night", action="store_true", help="also compare the islands' light (night frames)")
    ap.add_argument("--json", type=Path)
    args = ap.parse_args(argv)
    boxes = dict(parse_box(b) for b in args.islands)
    report = {}
    for path in args.frames:
        frame = np.asarray(Image.open(path).convert("RGB"))
        report[path.name] = check(frame, boxes, args.night or "night" in path.stem)
    text = json.dumps(report, indent=1)
    if args.json:
        args.json.write_text(text)
    print(text)
    return 0 if all(r["ok"] for r in report.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
