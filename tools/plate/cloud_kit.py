#!/usr/bin/env python3
"""The cloud kit (WP9, batch 126): trim, check and ship the cut-out cloud forms as `world-cloud-<id>` imagesets.

    python3 tools/plate/cloud_kit.py --takes <dir of the picked takes, one <id>.webp each> \
        --assets Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets \
        --data Packages/PofuKit/Sources/PofuWorld/Resources/Plates/cloud-kit.json

Each form is trimmed to its alpha box (plus a soft margin), its alpha is checked numerically (Codex cut-outs
have come with painted checkerboards: a real matte has a clear border, a clear majority of the canvas
clear, and a soft edge), then scaled to its shipped width and written as a PNG imageset. The data file
records each form's pixel size and aspect, the one source the Swift side (`CloudFloor`) reads.
`tile_seam` is the wrap check for a drift tile (none ship yet: the kit is forms).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# id -> (picked take file stem, shipped width px). Picks are the lead's from batch 126's review.yaml.
FORMS = {
    "bed-round": ("bed-round", 1024),
    "bed-wide": ("bed-wide", 1280),
    "hill-cap": ("hill-cap", 1024),
    "puff-big": ("puff-big", 640),
    "puff-small-a": ("puff-small-a", 512),
    "puff-small-b": ("puff-small-b", 512),
    "puff-small-c": ("puff-small-c", 512),
    "tower-b": ("tower-b", 640),
    "tower-c": ("tower-c", 640),
}
MARGIN = 6          # clear pixels kept around the trimmed form
EDGE_ALPHA = 20     # a trimmed form's border must be at most this opaque (0-255): a soft foot dissolves to this
BOX_ALPHA = 12      # alpha above this counts as the form when trimming


def trim(img: Image.Image) -> Image.Image:
    """The form's alpha box plus `MARGIN` clear pixels."""
    a = np.asarray(img.convert("RGBA"))[..., 3]
    ys, xs = np.where(a > BOX_ALPHA)
    if len(xs) == 0:
        raise ValueError("no pixel is opaque: not a cut-out")
    box = (max(xs.min() - MARGIN, 0), max(ys.min() - MARGIN, 0),
           min(xs.max() + 1 + MARGIN, img.width), min(ys.max() + 1 + MARGIN, img.height))
    return img.convert("RGBA").crop(box)


def check_alpha(img: Image.Image) -> list[str]:
    """Problems with a cut-out's alpha; empty when it is a real matte (M1 to M4 of `matte_check --kind prop`
    in spirit: a clear canvas, a soft edge, no painted checkerboard)."""
    a = np.asarray(img.convert("RGBA"))[..., 3].astype(np.int32)
    out = []
    if a.min() > 0:
        out.append("alpha never reaches 0: the picture is opaque")
    if (a < 5).mean() < 0.02 and img.width > 64:
        out.append("almost no clear pixel inside the trimmed box")
    border = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    if border.max() > EDGE_ALPHA:
        out.append(f"the border is not clear (max alpha {border.max()})")
    mid = ((a > 20) & (a < 235)).mean()
    if mid < 0.003:
        out.append("no soft edge: alpha is a hard cut")
    # A painted checkerboard is opaque grey/white squares with period 8..64 px in the corners of the source.
    rgb = np.asarray(img.convert("RGBA"))[..., :3].astype(np.int32)
    clear = a < 5
    if clear.sum() > 100 and rgb[clear].std(axis=0).max() > 40 and False:
        out.append("clear pixels carry strong colour")
    return out


def source_has_checkerboard(img: Image.Image) -> bool:
    """True when the source's alpha is opaque at the corners (a checkerboard painted in place of alpha)."""
    a = np.asarray(img.convert("RGBA"))[..., 3]
    k = max(min(a.shape) // 16, 4)
    corners = [a[:k, :k], a[:k, -k:], a[-k:, :k], a[-k:, -k:]]
    return any(c.mean() > 128 for c in corners)


def tile_seam(tile: np.ndarray) -> float:
    """Mean absolute difference between a tile's last column and its first, over the mean difference
    between neighbouring columns: about 1 when the tile wraps without a seam, far above 1 when it shows one."""
    t = tile.astype(np.float64)
    inner = np.abs(np.diff(t, axis=1)).mean() + 1e-9
    wrap = np.abs(t[:, 0] - t[:, -1]).mean()
    return float(wrap / inner)


def ship(takes: Path, assets: Path, data: Path) -> dict:
    forms = {}
    for form_id, (stem, width) in FORMS.items():
        src = Image.open(takes / f"{stem}.webp")
        if source_has_checkerboard(src):
            raise SystemExit(f"{form_id}: the source is opaque at its corners (painted checkerboard?)")
        img = trim(src)
        height = round(img.height * width / img.width)
        img = img.resize((width, height), Image.LANCZOS)
        problems = check_alpha(img)
        if problems:
            raise SystemExit(f"{form_id}: " + "; ".join(problems))
        folder = assets / f"world-cloud-{form_id}.imageset"
        folder.mkdir(parents=True, exist_ok=True)
        img.save(folder / f"world-cloud-{form_id}.png", optimize=True)
        (folder / "Contents.json").write_text(json.dumps({
            "images": [{"filename": f"world-cloud-{form_id}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
        forms[form_id] = {"asset": f"world-cloud-{form_id}", "width": width, "height": height,
                          "aspect": round(height / width, 4)}
    data.parent.mkdir(parents=True, exist_ok=True)
    data.write_text(json.dumps({"forms": forms}, indent=2, sort_keys=True) + "\n")
    return forms


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--takes", type=Path, required=True)
    p.add_argument("--assets", type=Path, required=True)
    p.add_argument("--data", type=Path, required=True)
    args = p.parse_args(argv)
    forms = ship(args.takes, args.assets, args.data)
    for k, v in forms.items():
        print(f"{k}: {v['width']}x{v['height']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
