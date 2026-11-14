#!/usr/bin/env python3
"""Portrait masters for an island whose stage plates are landscape (ADR-0025): Çağlayan.

    python3 -I tools/plate/portrait.py register caglayan     # measure where the plate sits in the master
    python3 -I tools/plate/portrait.py master caglayan       # write the day master the sky set is split from
    python3 -I tools/plate/portrait.py master caglayan night # the night master (golden, rain the same)
    python3 -I tools/plate/portrait.py plate caglayan night  # the landscape stage-4 plate cut from that master

The portrait master (`portraitFrame.master` in `objects.json`, Codex's outpaint of the landscape parent)
paints the island again, a little differently. The picked stage plates stay the truth about the island, so:

  register  finds, by ECC on the blurred luminance of the island's body, the scale and offset that carry a
            landscape plate's pixels onto the master's. The hand data stores the measure rounded
            (`portraitFrame.scale`, `offset`, in master pixels at 1024 x 1536); `check` guards that it still
            registers within a pixel.
  master    cuts the island out of the master with the committed matte (`matte-day-0.png`) and pastes the
            stage plate's island, plus a feathered margin of its own surroundings, at the measured place. Every island
            pixel is therefore the stage plate's, byte for byte before the resample, and everything else the master's own
            painting. `stage_master` does the same for each of the five stages, over the same stage-4 master, so a
            stage's island layer sits in the one sky set.

Other lights (`portraitFrame.lights.<light>`: night, golden, rain) have their own take as the master, edited first by
`master_edit.py` where the hand data lists `edits` (the take is never overwritten). The stage plates of that light are
pasted over it the same way; their sky is not the master's sky, so round the island the paste is matched to the master
(`match_edge`: the low-frequency difference in the ring outside the island, applied in proportion to how much of a
pixel is not island), or a darker plate sky would ring the island. A light with no stage-4 plate keeps the master's own
island, and `plate` cuts the landscape stage-4 plate from that master (the inverse of `portraitFrame`) for the
plate ingest, so the plate, the occluders and the sky set's island are the same pixels.

Working size is x2 (2048 x 3072): the master is upscaled by `ingest.upscaled_plate` (the plates' own 0.8 model / 0.2
Lanczos blend) and each stage plate, already upscaled x2, is resampled by the measured scale.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import ingest  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"
UP = 2                         # the master's working scale over the 1024 x 1536 portrait
PASTE_REACH = 36               # master px (x2) the pasted plate reaches past the island's silhouette
PASTE_FEATHER = 16             # gaussian sigma of the paste's edge, master px (x2)


def load_frame(island: str) -> dict:
    hand = json.loads((PLATES / island / "objects.json").read_text())
    return hand["portraitFrame"]


def light_spec(frame: dict, light: str = "day") -> dict:
    """{master, out, edits} of a light: the day's at the top of `portraitFrame`, the others under `lights`."""
    if light == "day":
        return {"master": frame["master"], "out": frame["out"], "edits": frame.get("edits", [])}
    spec = frame.get("lights", {}).get(light)
    if spec is None:
        raise SystemExit(f"portraitFrame has no {light} master")
    return {"master": spec["master"], "out": spec["out"], "edits": spec.get("edits", []), "cut": spec.get("cut")}


def to_gray(rgb: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(np.ascontiguousarray(rgb, dtype=np.float32), cv2.COLOR_RGB2GRAY)


def register(landscape: np.ndarray, master: np.ndarray, guess_scale: float = 2 / 3, guess_y: float = 425.0) -> dict:
    """Where a landscape plate (RGB 0..1, 1536 x 1024) sits in the portrait master (RGB 0..1, 1024 x 1536):
    master = scale * plate + offset, with an independent y scale as a sanity measure. Seeded by a
    template match over scale and offset, refined by ECC (affine) on the island's body."""
    mg, lg = to_gray(master), to_gray(landscape)
    best = (-1.0, guess_scale, 0.0, guess_y)
    for s in np.arange(guess_scale - 0.03, guess_scale + 0.03, 0.0025):
        small = cv2.resize(lg, (round(lg.shape[1] * s), round(lg.shape[0] * s)), interpolation=cv2.INTER_AREA)
        h, w = small.shape
        t = small[int(h * 0.3): int(h * 0.85), int(w * 0.1): int(w * 0.9)]
        r = cv2.matchTemplate(mg, t, cv2.TM_CCOEFF_NORMED)
        _, mx, _, loc = cv2.minMaxLoc(r)
        if mx > best[0]:
            best = (mx, float(s), loc[0] - w * 0.1, loc[1] - h * 0.3)
    _, s0, ox0, oy0 = best
    warp0 = np.array([[s0, 0, ox0], [0, s0, oy0]], np.float32)
    pre = cv2.warpAffine(lg, warp0, (mg.shape[1], mg.shape[0]), flags=cv2.INTER_AREA)
    mask = np.zeros(mg.shape, np.uint8)
    y0 = int(oy0 + 0.30 * lg.shape[0] * s0)
    y1 = int(oy0 + 0.85 * lg.shape[0] * s0)
    mask[y0:y1, 60:mg.shape[1] - 60] = 255
    w = np.eye(2, 3, dtype=np.float32)
    cc, w = cv2.findTransformECC(
        cv2.GaussianBlur(mg, (0, 0), 1.2), cv2.GaussianBlur(pre, (0, 0), 1.2), w, cv2.MOTION_AFFINE,
        (cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 300, 1e-8), mask, 5)
    # ECC maps master coordinates to `pre` coordinates; invert and compose with the seed warp
    a = np.vstack([w, [0, 0, 1]])
    seed = np.vstack([warp0, [0, 0, 1]])
    plate_to_master = np.linalg.inv(a) @ seed
    sx, sy = float(plate_to_master[0, 0]), float(plate_to_master[1, 1])
    # the offset at the same scale for both axes: centre the plate's island body on the measured place
    cx, cy = 0.5 * lg.shape[1], 0.6 * lg.shape[0]
    mx_, my_ = plate_to_master[:2] @ np.array([cx, cy, 1.0])
    s = (sx + sy) / 2
    return {"cc": float(cc), "scaleX": sx, "scaleY": sy, "scale": s,
            "offset": [float(mx_ - s * cx), float(my_ - s * cy)]}


def frame_matrix(frame: dict, k: float = UP) -> np.ndarray:
    """The 2 x 3 affine from a landscape plate at x1 to the master at `k` times the portrait's size."""
    s = frame["scale"] * k
    return np.array([[s, 0, frame["offset"][0] * k], [0, s, frame["offset"][1] * k]], np.float64)


def place(img: np.ndarray, frame: dict, size: tuple[int, int], k: float = UP, from_k: float = 1.0,
          interp=cv2.INTER_AREA) -> np.ndarray:
    """A landscape image (`from_k` times the plate's own size, RGB or one channel) on the master canvas
    `size` = (w, h) at the master's scale `k`: the plate's rows, zero elsewhere. The placement is
    exact to the pixel: a whole-pixel offset and a resize to the plate's footprint."""
    s = frame["scale"] * k / from_k
    w, h = round(img.shape[1] * s), round(img.shape[0] * s)
    ox, oy = round(frame["offset"][0] * k), round(frame["offset"][1] * k)
    small = cv2.resize(img, (w, h), interpolation=interp)
    out = np.zeros((size[1], size[0]) + img.shape[2:], np.float32)
    x0, y0 = max(ox, 0), max(oy, 0)
    x1, y1 = min(ox + w, size[0]), min(oy + h, size[1])
    out[y0:y1, x0:x1] = small[y0 - oy: y1 - oy, x0 - ox: x1 - ox]
    return out


def island_alpha(frame: dict, island: str, size: tuple[int, int]) -> np.ndarray:
    """The committed island matte (stage 4 day's, shared by every stage) on the master canvas."""
    m = np.asarray(Image.open(PLATES / island / "matte-day-0.png").convert("L"), np.float32) / 255
    return place(m, frame, size, interp=cv2.INTER_LINEAR).clip(0, 1)


def master_base(frame: dict, light: str = "day", island: str = "caglayan") -> np.ndarray:
    """The portrait master at x2 (RGB 0..1): the light's take, with its scripted `edits` applied at x1 first."""
    spec = light_spec(frame, light)
    src = ROOT / spec["master"]
    if spec["edits"]:
        import master_edit
        import upscale
        im = np.asarray(Image.open(src).convert("RGB"), np.float32) / 255
        size = (im.shape[1], im.shape[0])
        keep = master_edit.island_keep(island, size, frame)
        edited = master_edit.apply(im, spec["edits"], keep, island=master_edit.island_alpha(island, size, frame))
        # the edited take goes through the same upscale as any plate; the cache keys on its bytes
        src = upscale.cache_dir() / "edited" / f"{island}-{light}.png"
        src.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(np.uint8(edited * 255 + 0.5)).save(src)
    return ingest.upscaled_plate(src, scale=UP)


def plate_x2(path: Path) -> np.ndarray:
    return ingest.upscaled_plate(path, scale=UP)


def paste_weight(alpha: np.ndarray, reach: int = PASTE_REACH, feather: float = PASTE_FEATHER) -> np.ndarray:
    """1 over the island, easing to 0 over `reach` px past its silhouette."""
    k = 2 * reach + 1
    grown = cv2.dilate((alpha > 0.02).astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k)))
    return cv2.GaussianBlur(grown.astype(np.float32), (0, 0), feather).clip(0, 1)


EDGE_RING = 60                 # master px (x2) outside the island where the edge match measures the two skies
EDGE_SIGMA = 24.0              # the smoothness of that difference field, master px (x2)


def edge_match(plate: np.ndarray, base: np.ndarray, a: np.ndarray, have: np.ndarray) -> np.ndarray:
    """The plate with its own sky, round the island, moved onto the master's: the difference master - plate,
    measured in a ring outside the silhouette and spread smoothly (normalised convolution), added in proportion to
    1 - alpha. The island's own pixels (alpha 1) are untouched; a fringe pixel half island, half sky gets half."""
    solid = (a > 0.02).astype(np.uint8)
    k = 2 * EDGE_RING + 1
    near = cv2.dilate(solid, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k))) > 0
    ring = (near & (solid == 0) & (have > 0.999)).astype(np.float32)
    diff = (base - plate) * ring[..., None]
    num = np.stack([cv2.GaussianBlur(diff[..., c], (0, 0), EDGE_SIGMA) for c in range(3)], -1)
    den = cv2.GaussianBlur(ring, (0, 0), EDGE_SIGMA)[..., None]
    field = num / np.maximum(den, 1e-4) * (den > 1e-3)
    return (plate + field * (1 - a)[..., None]).clip(0, 1)


def stage_master(island: str, plate_path: Path, base: np.ndarray | None = None, match_edge: bool = False) -> np.ndarray:
    """The master with the island (and its margin) taken from the stage plate at `plate_path`; `match_edge` moves
    the plate's sky round the island onto the master's first (`edge_match`: the other lights' plates)."""
    frame = load_frame(island)
    base = master_base(frame) if base is None else base
    h, w = base.shape[:2]
    src = plate_x2(plate_path)
    plate = place(src, frame, (w, h), from_k=UP)
    a = island_alpha(frame, island, (w, h))
    if match_edge:
        # the island's own pixels where the matte stops short of them (`islandAdd`): the plate's, not the master's
        import split
        hand = split.load_hand(island)
        if hand.get("islandAdd"):
            a = np.maximum(a, split.island_add(hand, (h, w)))
    wgt = paste_weight(a)
    # only where the plate has pixels
    have = place(np.ones(src.shape[:2], np.float32), frame, (w, h), from_k=UP)
    if match_edge:
        plate = edge_match(plate, base, a, have)
    wgt = wgt * (have > 0.999)
    return (plate * wgt[..., None] + base * (1 - wgt[..., None])).clip(0, 1)


def stage_plate_paths(island: str, light: str = "day") -> dict[int, Path]:
    """The light's painted stage plates (a plate cut from the master by `plate` is not one: it is the master)."""
    hand = json.loads((PLATES / island / "objects.json").read_text())
    cut = light_spec(hand["portraitFrame"], light).get("cut") if light != "day" else None
    return {int(s): ROOT / p for s, p in hand["plates"].get(light, {}).items() if p != cut}


def light_master(island: str, light: str, base: np.ndarray | None = None) -> np.ndarray:
    """The master a light's sky set is split from: its take (edited), with the stage-4 plate's island pasted
    over it where that light paints one."""
    frame = load_frame(island)
    base = master_base(frame, light, island) if base is None else base
    paths = stage_plate_paths(island, light)
    if 4 not in paths:
        return base
    return stage_master(island, paths[4], base, match_edge=light != "day")


def cut_plate(island: str, master: np.ndarray, size: tuple[int, int] = (1536, 1024)) -> np.ndarray:
    """The landscape plate (`size`, RGB 0..1) the master paints at `portraitFrame`: the inverse of `place`."""
    frame = load_frame(island)
    s = frame["scale"] * UP
    x0, y0 = frame["offset"][0] * UP, frame["offset"][1] * UP
    # plate px (u, v) -> master px (s (u + 0.5) - 0.5 + x0, ...): pixel centres, as `place`'s resize maps them
    m = np.array([[s, 0, x0 + 0.5 * s - 0.5], [0, s, y0 + 0.5 * s - 0.5]], np.float64)
    # warpAffine has no area filter; pre-blur by the scale so the down-sample does not alias
    sigma = max(s - 1, 0) * 0.5
    src = cv2.GaussianBlur(master.astype(np.float32), (0, 0), sigma) if sigma > 0.1 else master.astype(np.float32)
    return cv2.warpAffine(src, m, size, flags=cv2.INTER_LINEAR | cv2.WARP_INVERSE_MAP, borderMode=cv2.BORDER_REPLICATE).clip(0, 1)


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if len(args) not in (2, 3) or args[0] not in ("register", "master", "plate"):
        raise SystemExit(__doc__)
    cmd, island = args[:2]
    light = args[2] if len(args) == 3 else "day"
    frame = load_frame(island)
    if cmd == "register":
        landscape = np.asarray(Image.open(stage_plate_paths(island)[4]).convert("RGB"), np.float32) / 255
        master = np.asarray(Image.open(ROOT / frame["master"]).convert("RGB"), np.float32) / 255
        r = register(landscape, master)
        print(json.dumps({k: (round(v, 4) if isinstance(v, float) else [round(x, 2) for x in v]) for k, v in r.items()}))
        print("stored:", frame["scale"], frame["offset"])
        return 0
    spec = light_spec(frame, light)
    if cmd == "plate":
        if not spec.get("cut"):
            raise SystemExit(f"portraitFrame.lights.{light} names no `cut` plate")
        master = np.asarray(heic.open_image(ROOT / spec["out"]).convert("RGB"), np.float32) / 255
        dst = ROOT / spec["cut"]
        Image.fromarray(np.uint8(cut_plate(island, master) * 255 + 0.5), "RGB").save(dst, lossless=True, quality=100, method=6)
        print(f"wrote {dst.relative_to(ROOT)} ({dst.stat().st_size / 1e6:.2f} MB)")
        return 0
    if light == "day":
        out = stage_master(island, stage_plate_paths(island)[4], master_base(frame))
    else:
        out = light_master(island, light)
    dst = ROOT / spec["out"]
    dst.parent.mkdir(parents=True, exist_ok=True)
    heic.save(Image.fromarray(np.uint8(out * 255 + 0.5), "RGB").convert("RGBA"), dst)
    print(f"wrote {dst.relative_to(ROOT)} ({dst.stat().st_size / 1e6:.2f} MB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
