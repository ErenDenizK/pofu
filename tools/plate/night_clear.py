#!/usr/bin/env python3
"""Home's night levels 8 and 9 without the cloud and mist that lay on the island (batch 125).

Each of batch 125's picks is an edit of its night parent with the cloud and mist on the island cleared; every take also
re-renders the plate a little everywhere else. So only the cleared region comes from the pick: where the pick and the
parent differ by a lot over a wide area (`REGION_DIFF`, blobs of at least `REGION_AREA` px) near the island, grown by
`REGION_GROW` px and feathered over `FEATHER` px, the pick is pasted over the parent (as batches 108 and 117 did). Outside
it every pixel is the parent's. The takes are never overwritten (docs/studio.md section 9): this writes
`design/art/plates/home/derived/plate-l<level>-night-clear.webp` (lossless); `objects.json` points the night stage there
and `docs/state/plates.yaml` records it as `edited`.

    python3 -I tools/plate/night_clear.py build     # writes the derived plates
    python3 -I tools/plate/night_clear.py check     # fails if a committed plate is stale
    python3 -I tools/plate/night_clear.py preview OUT_DIR   # parent, pick, mask and plate side by side
"""
from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
TAKES = REPO / "design" / "art" / "takes" / "batch-125-home-night-clear"
DERIVED = REPO / "design" / "art" / "plates" / "home" / "derived"
#: level: (the parent the job edited, the lead's pick). The parents are the night plates these levels shipped. Levels 1
#: and 2 (picks l1 t1, l2 t1) are not used yet: their soil's edge thins over the cloud and no matte holds it whole
#: (the one-sky PR, #485), so those nights keep their old plates.
JOBS = {
    8: ("design/art/takes/batch-72-home-night/x-home-flow-il8-night/plate__x-home-flow-il8-night--t2.webp", 2),
    9: ("design/art/takes/batch-72-home-night/x-home-flow-il9-night/plate__x-home-flow-il9-night--t1.webp", 2),
}
REGION_DIFF = 0.14   # max RGB difference (blurred) that marks the cleared place
REGION_AREA = 2500   # px: a smaller difference is the take's re-render, not the clearing
REGION_GROW = 10
FEATHER = 14.0


def pick_path(level: int) -> Path:
    job = f"x-home-l{level}-night-clear"
    return TAKES / job / f"plate__{job}--t{JOBS[level][1]}.webp"


def derived_path(level: int) -> Path:
    return DERIVED / f"plate-l{level}-night-clear.webp"


def _rgb(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB"), np.float32) / 255


def region(parent: np.ndarray, pick: np.ndarray) -> np.ndarray:
    """The cleared place as a feathered mask 0 ... 1."""
    d = cv2.GaussianBlur(np.abs(parent - pick).max(2), (0, 0), 3)
    core = d > REGION_DIFF
    lab, n = ndimage.label(core)
    if n:
        size = ndimage.sum(core, lab, range(1, n + 1))
        core = np.isin(lab, 1 + np.flatnonzero(size >= REGION_AREA))
    core = cv2.morphologyEx(core.astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (31, 31)))
    core = ndimage.binary_fill_holes(core).astype(np.uint8)
    grown = cv2.dilate(core, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * REGION_GROW + 1,) * 2))
    return np.clip(cv2.GaussianBlur(grown.astype(np.float32), (0, 0), FEATHER), 0, 1)


def build_one(level: int) -> tuple[np.ndarray, np.ndarray]:
    parent = _rgb(REPO / JOBS[level][0])
    pick = _rgb(pick_path(level))
    m = region(parent, pick)[..., None]
    return np.clip(parent * (1 - m) + pick * m, 0, 1), m[..., 0]


def _img(x: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(x, 0, 1) * 255 + 0.5))


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv[1:] if argv is None else argv
    cmd = argv[0] if argv else "check"
    stale = []
    for level in JOBS:
        plate, m = build_one(level)
        out = derived_path(level)
        if cmd == "build":
            DERIVED.mkdir(parents=True, exist_ok=True)
            _img(plate).save(out, lossless=True)
            print(f"level {level}: {out.relative_to(REPO)} (pasted {float(m.mean()) * 100:.1f} % of the plate)")
        elif cmd == "preview":
            d = Path(argv[1])
            d.mkdir(parents=True, exist_ok=True)
            row = [_rgb(REPO / JOBS[level][0]), _rgb(pick_path(level)), np.repeat(m[..., None], 3, 2), plate]
            _img(np.concatenate(row, 1)).resize((4 * 512, 768)).save(d / f"night-clear-l{level}.png")
        else:
            if not out.exists() or np.abs(_rgb(out) - plate).max() > 1.5 / 255:
                stale.append(str(out.relative_to(REPO)))
    for s in stale:
        print(f"stale or missing: {s} (run `night_clear.py build`)")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
