#!/usr/bin/env python3
"""Measure how light each painted sky and island is, for the island grade under a painting.

    python3 -I tools/plate/painted_light.py [--check]

An island drawn under a painted sky (the Map and the flights, Koke's and the harbor's stops under Home's
sky, Çağlayan's own stop) must sit in the hour: when the sky goes dark at night or grey in rain, the
island goes darker with it, as Home's own painting does. `PaintedSky.islandGrade` does that from two
numbers per state, both measured here from the shipped art (no painting is changed):

  sky      the mean linear luminance (Rec. 709) of the state's backdrop (`world-<island>-backdrop-<light>-<stage>`,
           the plate's sky and cloud sea extended), the same measure for every island and light
  island   the alpha-weighted mean linear luminance of the island cut (`world-<island>-island-<light>-<stage>`),
           and its mean gamma-encoded colour (`rgb`), which the Swift tests grade with `WorldGrade.apply`

Koke is a sprite with one picture for every hour: its stage art (`world-koke-island-<stage>`) has an
`island` and `rgb` and no sky. Writes `Packages/PofuKit/Sources/PofuWorld/Resources/Plates/painted-light.json`;
`--check` fails when the file differs from a fresh measure. Deterministic. Needs numpy, Pillow, pillow-heif.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
OUT = RESOURCES / "Plates" / "painted-light.json"
LIGHTS = ("day", "golden", "night", "rain")


def image(name: str) -> np.ndarray | None:
    """The asset as RGBA 0..1, or None when it is not in the catalog."""
    folder = ASSETS / f"{name}.imageset"
    if not folder.is_dir():
        return None
    files = sorted(p for p in folder.iterdir() if p.suffix.lower() in (".heic", ".png", ".jpg", ".jpeg"))
    if not files:
        return None
    heic.register()
    return np.asarray(Image.open(files[0]).convert("RGBA"), np.float64) / 255


def linear(c: np.ndarray) -> np.ndarray:
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def luminance(rgba: np.ndarray) -> float:
    """Alpha-weighted mean linear luminance (Rec. 709)."""
    y = linear(rgba[..., :3]) @ np.array([0.2126, 0.7152, 0.0722])
    a = rgba[..., 3]
    return float((y * a).sum() / max(a.sum(), 1e-9))


def mean_rgb(rgba: np.ndarray) -> list[float]:
    a = rgba[..., 3:4]
    return [round(float(v), 4) for v in (rgba[..., :3] * a).sum((0, 1)) / max(float(a.sum()), 1e-9)]


def measure() -> dict:
    out: dict = {"note": "Written by tools/plate/painted_light.py: mean linear luminance of each state's backdrop "
                         "(sky) and island cut (island), and the island's mean gamma-encoded colour (rgb)."}
    for island in ("home", "caglayan"):
        states = {}
        for light in LIGHTS:
            for stage in range(10):
                sky, cut = image(f"world-{island}-backdrop-{light}-{stage}"), image(f"world-{island}-island-{light}-{stage}")
                if sky is None or cut is None:
                    continue
                states[f"{light}-{stage}"] = {"sky": round(luminance(sky), 4), "island": round(luminance(cut), 4),
                                              "rgb": mean_rgb(cut)}
        out[island] = states
    koke = {}
    for stage in range(10):
        art = image(f"world-koke-island-{stage}")
        if art is not None:
            koke[str(stage)] = {"island": round(luminance(art), 4), "rgb": mean_rgb(art)}
    out["koke"] = koke
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="fail when the shipped file is stale")
    args = ap.parse_args(argv)
    data = json.dumps(measure(), indent=1, sort_keys=True) + "\n"
    if args.check:
        if not OUT.exists() or OUT.read_text() != data:
            print(f"{OUT.relative_to(ROOT)} is stale: run tools/plate/painted_light.py", file=sys.stderr)
            return 1
        print("painted-light.json is current")
        return 0
    OUT.write_text(data)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
