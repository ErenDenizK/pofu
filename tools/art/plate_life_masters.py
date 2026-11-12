#!/usr/bin/env python3
"""Cut the plate's living-layer masters from the picked batch-78 takes, by script.

    python3 -I tools/art/plate_life_masters.py [--check]

The picked take is never overwritten (docs/studio.md section 9, "Editing art by
script"): each master is written to `design/art/masters/<job>/<job>.webp` (lossless)
from the take that `design/art/takes/batch-78-plate-life/<job>/review.yaml` picks,
and the take stays as Codex delivered it. Where the lead's review asked for an edit,
the edit is made here, so a later repaint starts from a true record:

- guest-letter-envelope: the closed envelope, cut from the left of the two-state sheet
  `design/art/masters/guest-letter/` (batch 35), for the quiet day's letter.
- visitor-damla: the two pairs of drawn motion strokes beside the raised paw and the
  tail are erased (each is a small separate shape of hard alpha, found by its size).
- home-fountain: the five hard teardrop droplets become soft spray dots.

The rest (visitor-gezgin, gift-parcel-closed, material-moss-lawn) are the takes as
painted, re-encoded losslessly. Visitor-sumi is not here: its take reads as Damla's
twin and waits for batch-83 (docs/research/route-2026-11-12-codex-pause.md section 5.1).

`--check` writes nothing and exits 1 when a master on disk differs from what the
script would write.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import yaml
from PIL import Image
from scipy import ndimage as ndi

REPO = Path(__file__).resolve().parents[2]
TAKES = REPO / "design/art/takes/batch-78-plate-life"
MASTERS = REPO / "design/art/masters"

#: job id -> the edit its review asked for ("" is none).
JOBS = {
    "visitor-damla": "erase_strokes",
    "visitor-gezgin": "",
    "gift-parcel-closed": "",
    "home-fountain": "soften_droplets",
    "material-moss-lawn": "",
}
#: Masters cut from a master already in the repository, not from a batch-78 take.
FROM_MASTER = {"guest-letter-envelope": ("guest-letter/guest-letter.png", "left_state")}
SOLID = 40  # alpha above this is a shape; the faint fringe is not
STROKE_MAX_AREA = 400  # px; the strokes are about 150 to 200, a droplet or a limb far more
DROPLET_MAX_AREA = 1200  # px; the teardrops are 270 to 780, the jet is far larger


def picked_take(job: str) -> Path:
    review = yaml.safe_load((TAKES / job / "review.yaml").read_text(encoding="utf-8"))
    pick = review["pick"]
    found = sorted((TAKES / job).glob(f"*--t{pick}.webp"))
    if len(found) != 1:
        raise SystemExit(f"{job}: take {pick} not found")
    return found[0]


def _small_shapes(alpha: np.ndarray, max_area: int) -> list[np.ndarray]:
    """Masks of the solid shapes that are not the main body and are smaller than `max_area`."""
    labels, count = ndi.label(alpha > SOLID)
    if count < 2:
        return []
    areas = ndi.sum(np.ones_like(labels), labels, index=range(1, count + 1))
    main = int(np.argmax(areas)) + 1
    return [labels == i for i in range(1, count + 1) if i != main and areas[i - 1] <= max_area]


def erase_strokes(img: Image.Image) -> Image.Image:
    """Zero the alpha of every small separate shape and of the fringe that surrounds it.

    The fringe is only taken where it is not part of the main body: the body's own
    pixels are those connected to it at any alpha above 8, so the paw is never touched.
    """
    rgba = np.array(img.convert("RGBA"))
    alpha = rgba[..., 3]
    body = ndi.label(alpha > 8)[0]
    main_labels = np.bincount(body[body > 0]).argmax()
    on_body = body == main_labels
    for shape in _small_shapes(alpha, STROKE_MAX_AREA):
        near = ndi.binary_dilation(shape, iterations=5) & ~on_body
        alpha[near] = 0
    rgba[..., 3] = alpha
    return Image.fromarray(rgba, "RGBA")


def soften_droplets(img: Image.Image) -> Image.Image:
    """Replace each hard teardrop with a soft round dot of its own colour."""
    rgba = np.array(img.convert("RGBA"))
    alpha = rgba[..., 3].astype(np.float32)
    h, w = alpha.shape
    ys, xs = np.mgrid[0:h, 0:w]
    out = rgba.copy()
    for shape in _small_shapes(rgba[..., 3], DROPLET_MAX_AREA):
        near = ndi.binary_dilation(shape, iterations=4)
        out[near, 3] = 0
        cy, cx = ndi.center_of_mass(shape)
        colour = rgba[shape, :3].astype(np.float32).mean(axis=0)
        # Lift toward the jet's white-cyan so a dot reads as spray, not a bead.
        colour = colour * 0.5 + np.array([236, 246, 252], dtype=np.float32) * 0.5
        sigma = 5.0
        dot = np.exp(-((xs - cx) ** 2 + (ys - cy) ** 2) / (2 * sigma * sigma)) * 0.75
        dot_a = np.clip(dot * 255, 0, 255)
        take = dot_a > out[..., 3]
        out[take, :3] = colour.astype(np.uint8)
        out[take, 3] = dot_a[take].astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def left_state(img: Image.Image) -> Image.Image:
    """The left shape of a sheet of two states side by side: cut at the widest empty column between them."""
    rgba = img.convert("RGBA")
    columns = np.array(rgba)[..., 3].max(axis=0) > 8
    xs = np.flatnonzero(columns)
    gap = np.flatnonzero(~columns[xs[0] : xs[-1]]) + xs[0]
    cut = int(gap[len(gap) // 2]) if len(gap) else rgba.width // 2
    return rgba.crop((0, 0, cut, rgba.height))


EDITS = {"left_state": left_state, "": lambda im: im.convert("RGBA"), "erase_strokes": erase_strokes, "soften_droplets": soften_droplets}


def build(job: str) -> Image.Image:
    if job in FROM_MASTER:
        source, edit = FROM_MASTER[job]
        return EDITS[edit](Image.open(MASTERS / source))
    return EDITS[JOBS[job]](Image.open(picked_take(job)))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    stale = []
    for job in [*JOBS, *FROM_MASTER]:
        out = MASTERS / job / f"{job}.webp"
        img = build(job)
        if args.check:
            same = out.is_file() and np.array_equal(np.array(Image.open(out).convert("RGBA")), np.array(img))
            if not same:
                stale.append(job)
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        img.save(out, "WEBP", lossless=True, exact=True)
        if job in FROM_MASTER:
            source = f"the master `design/art/masters/{FROM_MASTER[job][0]}`"
            edit = FROM_MASTER[job][1]
        else:
            source = f"the picked take `design/art/takes/batch-78-plate-life/{job}/{picked_take(job).name}`"
            edit = JOBS[job] or "none"
        (out.parent / "provenance.md").write_text(
            f"# {job}\n\nCut by `tools/art/plate_life_masters.py` from {source}. "
            f"Edit: {edit}. The source itself is untouched.\n",
            encoding="utf-8",
        )
        print("wrote", out.relative_to(REPO))
    if stale:
        print("stale masters:", ", ".join(stale), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
