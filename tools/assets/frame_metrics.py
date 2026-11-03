#!/usr/bin/env python3
"""Measure rendered world frames per grade, so the grades are tuned with numbers, not vibes.

For each screenshot (PNG or JPEG) it reads CIELAB lightness and chroma over the world band (the
island and Pofu, without the chrome and the sky or cloud sea) and reports:

  mean      mean L*
  p2, p98   black and white point (L* percentiles)
  range     p98 - p2
  local     local contrast: RMS of L* minus its Gaussian blur (sigma 1.5 % of the width), the
            texture and edge contrast that reads as "crisp" versus "washed out"
  chroma    mean C*

and, from look round 3:

  empty     the share of the frame's rows below the top chrome that are near-uniform (the mean
            |L* - blur(L*)| along the row under 0.5): dead sky or dead cloud. The composed far
            sky and the hero framing exist to bring it down.
  run       the longest run of such rows, as a share of the frame's height: one big dead band
            reads worse than the same area scattered.
  sky L, sky C, sky b    the sky band's mean L*, C* and b* (above the island): the unwell sky
            must be cooler, darker and lower in chroma than the day's, never brighter.
  pofu h, pofu C         Pofu's mean hue angle and chroma (from frame-regions.json): at night
            the characters keep their warmth instead of turning lavender.

Each grade is checked against its targets (design/art/harmony/grade-targets.json). The band comes
from frame-regions.json, which the screenshot test writes beside the frames (the island's box and
every character's, as unit rectangles); without it, from fixed fractions of the height.

  python3 -I tools/assets/frame_metrics.py FOLDER_OR_FILES...   (prints a table and the checks)
"""
from __future__ import annotations

import json
import math
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

TARGETS = REPO / "design" / "art" / "harmony" / "grade-targets.json"

# The world band per framing, as fractions of the frame height (402 x 874 pt layouts), used when a
# frame has no regions (round 2's frames).
BANDS = {"home": (0.50, 0.80), "island": (0.43, 0.60), "frame": (0.0, 1.0)}
TOP_CHROME = 118 / 874
EMPTY_LOCAL = 0.5


def band_for(name: str) -> str:
    if "-home" in name or name.endswith("home"):
        return "home"
    if "-island" in name or name.endswith("island"):
        return "island"
    return "frame"


def _lab(img: Image.Image) -> np.ndarray:
    return sl.srgb_to_lab(np.asarray(img.convert("RGB"), dtype=np.float64) / 255)


def _highpass(L: np.ndarray, sigma: float) -> np.ndarray:
    Lim = Image.fromarray(np.uint8(np.clip(L * 2.55, 0, 255)), "L").filter(ImageFilter.GaussianBlur(sigma))
    return np.abs(L - np.asarray(Lim, dtype=np.float64) / 2.55)


def measure(img: Image.Image, band: str = "frame", region: dict | None = None) -> dict:
    rgb = img.convert("RGB")
    w, h = rgb.size
    if region and "island" in region:
        x0, y0, x1, y1 = region["island"]
        if band == "home":
            # At Home the island fills the frame: the band is the lawn around Pofu.
            p = region["characters"]["pofu"]
            y0, y1 = max(p[1] - 0.05, 0), min(p[3] + 0.18, 1)
    else:
        y0, y1 = BANDS[band]
    world = rgb.crop((0, int(y0 * h), w, max(int(y1 * h), int(y0 * h) + 2)))
    lab = _lab(world)
    L = lab[..., 0]
    C = np.hypot(lab[..., 1], lab[..., 2])
    sigma = 0.015 * w
    hp = _highpass(L, sigma)
    p2, p98 = np.percentile(L, [2, 98])
    out = {
        "mean": round(float(L.mean()), 1),
        "p2": round(float(p2), 1),
        "p98": round(float(p98), 1),
        "range": round(float(p98 - p2), 1),
        "local": round(float(np.sqrt((hp ** 2).mean())), 2),
        "chroma": round(float(C.mean()), 1),
    }
    out.update(emptiness(rgb))
    # The sky band: above the island (Island) or above Pofu's head (Home), under the chrome.
    sky_bottom = (y0 - 0.02) if band == "island" else (region["characters"]["pofu"][1] - 0.12 if region else 0.4)
    if sky_bottom > TOP_CHROME + 0.04:
        sky = _lab(rgb.crop((0, int(TOP_CHROME * h), w, int(sky_bottom * h))))
        out["sky_L"] = round(float(sky[..., 0].mean()), 1)
        out["sky_C"] = round(float(np.hypot(sky[..., 1], sky[..., 2]).mean()), 1)
        out["sky_b"] = round(float(sky[..., 2].mean()), 1)
    if region:
        p = region["characters"]["pofu"]
        box = (int(p[0] * w), int(p[1] * h), int(p[2] * w), int(p[3] * h))
        if box[2] - box[0] > 8 and box[3] - box[1] > 8:
            # The middle of his body: the fur, not the sky around his ears.
            bw, bh = box[2] - box[0], box[3] - box[1]
            inner = (box[0] + bw // 4, box[1] + bh // 3, box[2] - bw // 4, box[3] - bh // 8)
            fur = _lab(rgb.crop(inner)).reshape(-1, 3)
            a, b = fur[:, 1].mean(), fur[:, 2].mean()
            out["pofu_h"] = round(math.degrees(math.atan2(b, a)) % 360, 1)
            out["pofu_C"] = round(float(np.hypot(fur[:, 1], fur[:, 2]).mean()), 1)
            out["pofu_L"] = round(float(fur[:, 0].mean()), 1)
    return out


def emptiness(img: Image.Image) -> dict:
    """The share of rows below the top chrome that are near-uniform, and the longest such run."""
    small = img.convert("RGB").resize((201, round(201 * img.height / img.width)), Image.LANCZOS)
    L = _lab(small)[..., 0]
    top = int(round(TOP_CHROME * L.shape[0]))
    rows = _highpass(L, 4)[top:].mean(axis=1) < EMPTY_LOCAL
    run = best = 0
    for r in rows:
        run = run + 1 if r else 0
        best = max(best, run)
    return {"empty": round(float(rows.mean()), 3), "run": round(best / L.shape[0], 3)}


def grade_of(name: str, targets: dict) -> str | None:
    """Which grade a screenshot shows, from the targets' name patterns."""
    for grade, spec in targets["grades"].items():
        if any(re.search(p, name) for p in spec["match"]):
            return grade
    return None


def _hue_delta(a: float, b: float) -> float:
    return abs((a - b + 180) % 360 - 180)


def check(stats: dict, spec: dict, day: dict | None, framing: dict | None = None) -> list[str]:
    """The targets a frame misses. Bounds are absolute; ratios are against the day frame."""
    misses = []
    for metric, (lo, hi) in spec.get("bounds", {}).items():
        if metric not in stats:
            continue
        v = stats[metric]
        if (lo is not None and v < lo) or (hi is not None and v > hi):
            misses.append(f"{metric} {v} outside [{lo}, {hi}]")
    for metric, (lo, hi) in (framing or {}).items():
        if metric not in stats:
            continue
        v = stats[metric]
        if (lo is not None and v < lo) or (hi is not None and v > hi):
            misses.append(f"{metric} {v} outside [{lo}, {hi}]")
    if day:
        for metric, (lo, hi) in spec.get("vs_day", {}).items():
            if metric not in stats or metric not in day:
                continue
            r = stats[metric] / max(day[metric], 1e-6)
            if (lo is not None and r < lo) or (hi is not None and r > hi):
                misses.append(f"{metric} {r:.2f}x day outside [{lo}, {hi}]")
        for metric, (lo, hi) in spec.get("delta_day", {}).items():
            if metric not in stats or metric not in day:
                continue
            d = _hue_delta(stats[metric], day[metric]) if metric.endswith("_h") else stats[metric] - day[metric]
            if (lo is not None and d < lo) or (hi is not None and d > hi):
                misses.append(f"{metric} {d:+.1f} vs day outside [{lo}, {hi}]")
    return misses


def main(argv: list[str]) -> int:
    paths: list[Path] = []
    for arg in argv or ["."]:
        p = Path(arg)
        paths += sorted(p.glob("*.png")) + sorted(p.glob("*.jpg")) if p.is_dir() else [p]
    targets = json.loads(TARGETS.read_text())
    regions: dict = {}
    for folder in {p.parent for p in paths}:
        f = folder / "frame-regions.json"
        if f.exists():
            regions.update(json.loads(f.read_text()))
    rows = {}
    for path in paths:
        name = path.stem
        grade = grade_of(name, targets)
        if grade is None:
            continue
        with Image.open(path) as im:
            rows[name] = (grade, band_for(name), measure(im, band_for(name), regions.get(name)))
    cols = ["mean", "p2", "p98", "range", "local", "chroma", "empty", "run", "sky_L", "sky_C", "sky_b", "pofu_h", "pofu_C", "pofu_L"]
    print(f"{'frame':26s} {'grade':7s} {'band':6s} " + " ".join(f"{c:>6s}" for c in cols))
    for name, (grade, band, s) in rows.items():
        print(f"{name:26s} {grade:7s} {band:6s} " + " ".join(f"{s[c]:6.2f}" if c in s else f"{'-':>6s}" for c in cols))
    print()
    failed = 0
    for name, (grade, band, s) in rows.items():
        day_name = next((n for n, (g, b, _) in rows.items() if g == "day" and b == band), None)
        framing = targets.get("framing", {}).get(band)
        misses = check(s, targets["grades"][grade], rows[day_name][2] if day_name and grade != "day" else None, framing)
        failed += bool(misses)
        print(f"{'MISS' if misses else 'ok  '} {name}: {'; '.join(misses) if misses else 'within targets'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
