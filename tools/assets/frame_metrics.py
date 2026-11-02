#!/usr/bin/env python3
"""Measure rendered world frames per grade, so the grades are tuned with numbers, not vibes.

For each screenshot (PNG or JPEG) it reads CIELAB lightness and chroma over the world band (the
island and Pofu, without the chrome and the empty sky or cloud sea) and reports:

  mean      mean L*
  p2, p98   black and white point (L* percentiles)
  range     p98 - p2
  local     local contrast: RMS of L* minus its Gaussian blur (sigma 1.5 % of the width), the
            texture and edge contrast that reads as "crisp" versus "washed out"
  chroma    mean C*

and checks each grade against its targets (design/art/harmony/grade-targets.json). The band is
chosen from the file name: "-home" frames use the Home band (Pofu and the lawn), "-island" frames
the Island band (the plate and its stations).

  python3 -I tools/assets/frame_metrics.py FOLDER_OR_FILES...   (prints a table and the checks)
"""
from __future__ import annotations

import json
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

# The world band per framing, as fractions of the frame height (402 x 874 pt layouts).
BANDS = {"home": (0.50, 0.80), "island": (0.43, 0.60), "frame": (0.0, 1.0)}


def band_for(name: str) -> str:
    if "-home" in name or name.endswith("home"):
        return "home"
    if "-island" in name or name.endswith("island"):
        return "island"
    return "frame"


def measure(img: Image.Image, band: str = "frame") -> dict:
    rgb = img.convert("RGB")
    h = rgb.height
    y0, y1 = BANDS[band]
    rgb = rgb.crop((0, int(y0 * h), rgb.width, int(y1 * h)))
    a = np.asarray(rgb, dtype=np.float64) / 255
    lab = sl.srgb_to_lab(a)
    L = lab[..., 0]
    C = np.hypot(lab[..., 1], lab[..., 2])
    sigma = 0.015 * rgb.width
    Lim = Image.fromarray(np.uint8(np.clip(L * 2.55, 0, 255)), "L").filter(ImageFilter.GaussianBlur(sigma))
    Lb = np.asarray(Lim, dtype=np.float64) / 2.55
    p2, p98 = np.percentile(L, [2, 98])
    return {
        "mean": round(float(L.mean()), 1),
        "p2": round(float(p2), 1),
        "p98": round(float(p98), 1),
        "range": round(float(p98 - p2), 1),
        "local": round(float(np.sqrt(((L - Lb) ** 2).mean())), 2),
        "chroma": round(float(C.mean()), 1),
    }


def grade_of(name: str, targets: dict) -> str | None:
    """Which grade a screenshot shows, from the targets' name patterns."""
    for grade, spec in targets["grades"].items():
        if any(re.search(p, name) for p in spec["match"]):
            return grade
    return None


def check(stats: dict, spec: dict, day: dict | None) -> list[str]:
    """The targets a frame misses. Bounds are absolute; ratios are against the day frame."""
    misses = []
    for metric, (lo, hi) in spec.get("bounds", {}).items():
        v = stats[metric]
        if (lo is not None and v < lo) or (hi is not None and v > hi):
            misses.append(f"{metric} {v} outside [{lo}, {hi}]")
    if day:
        for metric, (lo, hi) in spec.get("vs_day", {}).items():
            r = stats[metric] / max(day[metric], 1e-6)
            if (lo is not None and r < lo) or (hi is not None and r > hi):
                misses.append(f"{metric} {r:.2f}x day outside [{lo}, {hi}]")
    return misses


def main(argv: list[str]) -> int:
    paths: list[Path] = []
    for arg in argv or ["."]:
        p = Path(arg)
        paths += sorted(p.glob("*.png")) + sorted(p.glob("*.jpg")) if p.is_dir() else [p]
    targets = json.loads(TARGETS.read_text())
    rows = {}
    for path in paths:
        name = path.stem
        grade = grade_of(name, targets)
        if grade is None:
            continue
        with Image.open(path) as im:
            rows[name] = (grade, band_for(name), measure(im, band_for(name)))
    print(f"{'frame':38s} {'grade':10s} {'band':6s} {'mean':>5s} {'p2':>5s} {'p98':>5s} {'range':>5s} {'local':>6s} {'chroma':>6s}")
    for name, (grade, band, s) in rows.items():
        print(f"{name:38s} {grade:10s} {band:6s} {s['mean']:5.1f} {s['p2']:5.1f} {s['p98']:5.1f} {s['range']:5.1f} {s['local']:6.2f} {s['chroma']:6.1f}")
    print()
    failed = 0
    for name, (grade, band, s) in rows.items():
        day_name = next((n for n, (g, b, _) in rows.items() if g == "day" and b == band), None)
        misses = check(s, targets["grades"][grade], rows[day_name][2] if day_name and grade != "day" else None)
        failed += bool(misses)
        print(f"{'MISS' if misses else 'ok  '} {name}: {'; '.join(misses) if misses else 'within targets'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
