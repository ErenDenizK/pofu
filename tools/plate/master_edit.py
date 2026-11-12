#!/usr/bin/env python3
"""Scripted edits of a painted sky master, applied before it is split (ADR-0025). The take is never overwritten.

    python3 -I tools/plate/master_edit.py caglayan rain OUT.png     # the edited master at the take's own size

Codex is paused, so what a lead review asks of a picked take ("lift the cloud sea", "no rain streaks: rain is
code") is done here, by a deterministic script whose steps are hand data: `portraitFrame.lights.<light>.edits` in
the island's `objects.json`, recorded beside the take's cell in `docs/state/plates.yaml`. Each edit works on the
take at its own size (1024 x 1536, RGB 0..1), before the x2 upscale, so the upscaler never sharpens what an edit
removed. `derain` and `lift` measure and work on the sky and the cloud sea (the island's matte, grown, is
`keep`); `warm` works on the island alone.

  derain   removes rain streaks painted into the sky (thin, light, near-vertical lines): the luminance above a
           narrow horizontal median that holds over a vertical run is a streak; those pixels take the horizontal
           median of their row. Anything wider than `width` px, or shorter than `run` px, is not a streak.
  warm     warms the island's sunlit faces (golden: the take's island barely takes the low side light): `a`, `b`
           added in CIELAB in proportion to the island's matte and to how lit a pixel is (lightness `lo` .. `hi`).
  lift     raises the cloud sea's lightness in CIELAB (`L`), and stretches its spread so its 95th percentile
           lands near `p95` (the pearl highlights), easing in over `ramp` rows from `fromY` down; hue and
           chroma are kept. The sky above `fromY` gets `sky` of the lift.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
PLATES = ROOT / "design" / "art" / "plates"


def luminance(rgb: np.ndarray) -> np.ndarray:
    return (0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]).astype(np.float32)


def streak_mask(rgb: np.ndarray, keep: np.ndarray | None = None, width: int = 7, run: int = 9,
                thresh: float = 0.010) -> np.ndarray:
    """Pixels of thin, light, near-vertical streaks: the luminance above its row's `width`-px median, averaged over
    `run` rows, beyond `thresh`, and above it on most of those rows on its own. `keep` (bool) marks pixels never to touch (the island)."""
    y = luminance(rgb)
    resid = y - ndimage.median_filter(y, size=(1, width), mode="nearest")
    vert = ndimage.uniform_filter(resid, size=(run, 1), mode="nearest")
    # most of the run must stand above the row on its own: a star or a sparkle a few rows tall is not a streak
    along = ndimage.uniform_filter((resid > thresh).astype(np.float32), size=(run, 1), mode="nearest")
    m = (vert > thresh) & (along >= 0.6) & (resid > 0)
    m = ndimage.binary_dilation(m, structure=np.ones((5, 3), bool))
    if keep is not None:
        m &= ~keep
    return m


def derain(rgb: np.ndarray, keep: np.ndarray | None = None, width: int = 7, run: int = 9,
           thresh: float = 0.010, passes: int = 2) -> tuple[np.ndarray, np.ndarray]:
    """(edited rgb, the union of the streak masks). Each masked pixel takes its row's `width + 4`-px median per
    channel; two passes catch the fainter streaks that sat beside a strong one."""
    out = rgb.astype(np.float32).copy()
    total = np.zeros(rgb.shape[:2], bool)
    for _ in range(passes):
        m = streak_mask(out, keep, width, run, thresh)
        if not m.any():
            break
        med = np.stack([ndimage.median_filter(out[..., c], size=(1, width + 4), mode="nearest") for c in range(3)], -1)
        # a soft edge (1 px) so the filled column never shows as a line of its own
        soft = cv2.GaussianBlur(m.astype(np.float32), (0, 0), 0.7)
        soft = np.maximum(soft, m)
        out = out * (1 - soft[..., None]) + med * soft[..., None]
        total |= m
    return out.clip(0, 1), total


def to_lab(rgb: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(np.ascontiguousarray(rgb, dtype=np.float32), cv2.COLOR_RGB2Lab)


def to_rgb(lab: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(np.ascontiguousarray(lab, dtype=np.float32), cv2.COLOR_Lab2RGB).clip(0, 1)


def lift(rgb: np.ndarray, keep: np.ndarray | None, L: float, p95: float | None, from_y: int, ramp: int,
         sky: float = 0.0) -> tuple[np.ndarray, dict]:
    """The cloud sea's lightness raised by `L` (CIELAB) and its spread stretched so its p95 lands near `p95`,
    measured on the rows from `from_y` down outside `keep` (applied everywhere); the gain eases in over `ramp` rows; the sky above
    gets `sky` (0..1) of the same lift. Returns the image and what was measured."""
    lab = to_lab(rgb)
    h = rgb.shape[0]
    rows = np.arange(h, dtype=np.float32)
    region = np.zeros(rgb.shape[:2], bool)
    region[from_y:] = True
    if keep is not None:
        region &= ~keep
    l0 = lab[..., 0]
    med, hi = float(np.median(l0[region])), float(np.percentile(l0[region], 95))
    gain = 1.0 if p95 is None else max((p95 - (med + L)) / max(hi - med, 1e-3), 1.0)
    lifted = med + L + gain * (l0 - med)
    w = sky + (1 - sky) * np.clip((rows - from_y) / max(ramp, 1) + 0.5, 0, 1)
    w = np.broadcast_to(w[:, None], l0.shape)       # everywhere: the isles and the smoke sit in the same lighter air
    lab[..., 0] = np.clip(l0 + (lifted - l0) * w, 0, 100)
    out = to_rgb(lab)
    l1 = to_lab(out)[..., 0]
    return out, {"median": [round(med, 1), round(float(np.median(l1[region])), 1)],
                 "p95": [round(hi, 1), round(float(np.percentile(l1[region], 95)), 1)], "gain": round(gain, 3)}


def warm(rgb: np.ndarray, island: np.ndarray, a: float, b: float, lo: float, hi: float) -> tuple[np.ndarray, float]:
    """The island's lit pixels warmed: CIELAB a and b raised by `a`, `b` times the matte (`island`, 0..1) times how lit
    the pixel is (smoothstep of lightness from `lo` to `hi`). Returns the image and the mean weight on the island."""
    lab = to_lab(rgb)
    t = np.clip((lab[..., 0] - lo) / max(hi - lo, 1e-3), 0, 1)
    w = island * t * t * (3 - 2 * t)
    lab[..., 1] += a * w
    lab[..., 2] += b * w
    return to_rgb(lab), float(w[island > 0.5].mean()) if (island > 0.5).any() else 0.0


def apply(rgb: np.ndarray, edits: list[dict], keep: np.ndarray | None = None, log=print,
          island: np.ndarray | None = None) -> np.ndarray:
    """The edits in order (hand data: each {"op": ..., parameters})."""
    out = rgb.astype(np.float32)
    for e in edits:
        args = {k: v for k, v in e.items() if k not in ("op", "why")}
        if e["op"] == "derain":
            out, m = derain(out, keep, **args)
            log(f"  derain: {int(m.sum()):,} px ({m.mean() * 100:.2f} %)")
        elif e["op"] == "warm":
            if island is None:
                raise SystemExit("warm needs the island's matte")
            out, wm = warm(out, island, args["a"], args["b"], args["lo"], args["hi"])
            log(f"  warm: a +{args['a']}, b +{args['b']} on the lit island (mean weight {wm:.2f})")
        elif e["op"] == "lift":
            out, info = lift(out, keep, L=args["L"], p95=args.get("p95"), from_y=args["fromY"], ramp=args.get("ramp", 120),
                             sky=args.get("sky", 0.0))
            log(f"  lift: median L {info['median'][0]} -> {info['median'][1]}, p95 {info['p95'][0]} -> {info['p95'][1]}")
        else:
            raise SystemExit(f"unknown edit {e['op']!r}")
    return out


def island_alpha(island: str, size: tuple[int, int], frame: dict) -> np.ndarray:
    """The island's committed matte on the take (x1), soft (0..1)."""
    from PIL import Image
    m = np.asarray(Image.open(PLATES / island / "matte-day-0.png").convert("L"), np.float32) / 255
    s = frame["scale"]
    w, h = round(m.shape[1] * s), round(m.shape[0] * s)
    small = cv2.resize(m, (w, h), interpolation=cv2.INTER_AREA)
    out = np.zeros((size[1], size[0]), np.float32)
    ox, oy = round(frame["offset"][0]), round(frame["offset"][1])
    x0, y0, x1, y1 = max(ox, 0), max(oy, 0), min(ox + w, size[0]), min(oy + h, size[1])
    out[y0:y1, x0:x1] = small[y0 - oy: y1 - oy, x0 - ox: x1 - ox]
    return out


def island_keep(island: str, size: tuple[int, int], frame: dict, grow: int = 16) -> np.ndarray:
    """The island's committed matte on the take (x1), grown by `grow` px (the take repaints the island a few px off the
    matte, and a streak's fill must never take the island's colours), plus the chimney's smoke (`beam`) and the
    distant isles' own mattes (`sprites`, grown by 3 px): what an edit of the sky leaves alone."""
    from PIL import Image
    m = np.asarray(Image.open(PLATES / island / "matte-day-0.png").convert("L"), np.float32) / 255
    s = frame["scale"]
    w, h = round(m.shape[1] * s), round(m.shape[0] * s)
    small = cv2.resize(m, (w, h), interpolation=cv2.INTER_LINEAR)
    out = np.zeros((size[1], size[0]), bool)
    ox, oy = round(frame["offset"][0]), round(frame["offset"][1])
    x0, y0, x1, y1 = max(ox, 0), max(oy, 0), min(ox + w, size[0]), min(oy + h, size[1])
    out[y0:y1, x0:x1] = small[y0 - oy: y1 - oy, x0 - ox: x1 - ox] > 0.02
    sky = json.loads((PLATES / island / "sky" / "sky.json").read_text())
    if sky.get("islandAdd"):                                 # where the matte stops short of the painted island
        ax0, ay0, ax1, ay1 = sky["islandAdd"]["box"]
        am = np.asarray(Image.open(PLATES / island / "sky" / sky["islandAdd"]["matte"]).convert("L"), np.float32) / 255
        am = cv2.resize(am, ((ax1 - ax0) // 2, (ay1 - ay0) // 2), interpolation=cv2.INTER_AREA) > 0.02
        out[ay0 // 2: ay0 // 2 + am.shape[0], ax0 // 2: ax0 // 2 + am.shape[1]] |= am
    out = ndimage.binary_dilation(out, iterations=grow)
    bx0, by0, bx1, by1 = (v // 2 for v in sky["beam"])       # sky.json is at x2
    out[by0:by1, bx0:bx1] = True
    for spr in sky.get("sprites", {}).values():             # the distant isles keep their painted columns
        sx0, sy0, sx1, sy1 = spr["box"]                     # x2, with the isle's own matte (`sprite_matte.py`)
        sm = np.asarray(Image.open(PLATES / island / "sky" / spr["matte"]).convert("L"), np.float32) / 255
        sm = cv2.resize(sm, ((sx1 - sx0) // 2, (sy1 - sy0) // 2), interpolation=cv2.INTER_AREA) > 0.02
        out[sy0 // 2: sy0 // 2 + sm.shape[0], sx0 // 2: sx0 // 2 + sm.shape[1]] |= ndimage.binary_dilation(sm, iterations=3)
    return out


def main(argv: list[str] | None = None) -> int:
    from PIL import Image
    args = list(sys.argv[1:] if argv is None else argv)
    if len(args) != 3:
        raise SystemExit(__doc__)
    island, light, dst = args
    frame = json.loads((PLATES / island / "objects.json").read_text())["portraitFrame"]
    spec = frame["lights"][light]
    im = np.asarray(Image.open(ROOT / spec["master"]).convert("RGB"), np.float32) / 255
    keep = island_keep(island, (im.shape[1], im.shape[0]), frame)
    out = apply(im, spec.get("edits", []), keep, island=island_alpha(island, (im.shape[1], im.shape[0]), frame))
    Image.fromarray(np.uint8(out * 255 + 0.5)).save(dst)
    print(f"wrote {dst}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
