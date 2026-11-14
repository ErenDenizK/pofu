#!/usr/bin/env python3
"""Home's level 1 plates as IL2's earlier self: a committed, deterministic edit of two picked takes.

The founder's trial read Home's first growth (IL1 to IL2) as a loss: the shipped IL1 carries a whale
with a town, a hilltop tree, a bridge to an islet, four doors and full-colour far isles, and IL2 takes
all of them away. The takes are pixel-registered (sky within a pixel), so IL1 keeps what IL2 keeps:

* the sky above the island, the hilltop cloud and the fog bank over the bridge and the islet come from
  a donor take (day: batch 71's IL1 v2 t1; night: IL2's night take), each through a feathered mask;
* the blue and green doors are patched with IL2's plain earth at the same pixels, gain-matched on a ring;
* a donor is first matched to the base where both show plain sky (a smooth colour field), so no mask
  edge shows a step; the night donor's tea stall and bagel cart, which belong to IL2, stay out.

The takes are never overwritten (docs/studio.md section 9): this script reads them and writes
`design/art/plates/home/derived/plate-il1-<light>.webp` (lossless); `objects.json` points IL1's plate
there and `docs/state/plates.yaml` records it as `edited`. Hand data (polygons, feathers) is
`design/art/plates/home/il1-composite.json`, in plate pixels. Run before `ingest.py`:

    python3 -I tools/plate/il1_composite.py build [day|night]   # writes the derived plates
    python3 -I tools/plate/il1_composite.py check               # fails if a committed plate is stale
    python3 -I tools/plate/il1_composite.py preview OUT_DIR     # masks and the three plates side by side
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
PLATES = REPO / "design" / "art" / "plates" / "home"
HAND = PLATES / "il1-composite.json"
DERIVED = PLATES / "derived"
LIGHTS = ("day", "night")


def load_hand(path: Path = HAND) -> dict:
    return json.loads(path.read_text())


def load_rgb(path: Path | str) -> np.ndarray:
    p = Path(path)
    p = p if p.is_absolute() else REPO / p
    return np.asarray(Image.open(p).convert("RGB"), np.float64) / 255.0


def derived_path(light: str) -> Path:
    return DERIVED / f"plate-il1-{light}.webp"


# ---------------------------------------------------------------- masks

def poly_mask(shape: tuple[int, int], pts, sigma: float) -> np.ndarray:
    """A polygon (plate pixels) as a 0..1 mask, its edge softened by a Gaussian of `sigma` pixels."""
    h, w = shape
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).polygon([tuple(p) for p in pts], fill=255)
    m = np.asarray(img, np.float64) / 255.0
    return ndimage.gaussian_filter(m, sigma) if sigma > 0 else m


def ellipse_mask(shape: tuple[int, int], cx: float, cy: float, rx: float, ry: float, sigma: float) -> np.ndarray:
    h, w = shape
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
    m = np.asarray(img, np.float64) / 255.0
    return ndimage.gaussian_filter(m, sigma) if sigma > 0 else m


def region_mask(shape: tuple[int, int], region: dict) -> np.ndarray:
    """One region: its polygon, minus the polygons it `exclude`s, each edge feathered by its sigma."""
    m = poly_mask(shape, region["poly"], region.get("feather", 12))
    for ex in region.get("exclude", []):
        m = m * (1 - poly_mask(shape, ex["poly"], ex.get("feather", 6)))
    return m


def donor_mask(shape: tuple[int, int], regions: list[dict]) -> np.ndarray:
    """The union of the regions (1 - the product of what each leaves out)."""
    keep = np.ones(shape)
    for r in regions:
        keep *= 1 - region_mask(shape, r)
    return 1 - keep


# ---------------------------------------------------------------- colour matching

def skyish(rgb: np.ndarray) -> np.ndarray:
    """Plain sky, day or night: blue leads red and green (lawn, earth, wood and warm cloud fail)."""
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    return (b > r + 0.06) & (b > g + 0.02)


def norm_conv(diff: np.ndarray, valid: np.ndarray, sigma: float) -> tuple[np.ndarray, np.ndarray]:
    """Normalised convolution: the smooth field of `diff` over the `valid` pixels, and its support."""
    w = valid.astype(np.float64)
    den = ndimage.gaussian_filter(w, sigma)
    num = np.stack([ndimage.gaussian_filter(diff[..., c] * w, sigma) for c in range(diff.shape[-1])], -1)
    return num / np.maximum(den, 1e-6)[..., None], den


def sky_bias(base: np.ndarray, donor: np.ndarray, mask: np.ndarray, sigmas=(60, 240)) -> np.ndarray:
    """A smooth colour field (donor minus base) over where both show plain sky, extrapolated across
    the plate with a wide kernel where the sky is not near (`mask` keeps the regions themselves out of the
    estimate): removing it makes the donor's sky and its
    fog sit on the base's colour, so a feathered edge shows no step."""
    valid = skyish(base) & skyish(donor) & (mask < 0.01)  # outside the regions: there the pictures differ for real
    diff = donor - base
    field, den = norm_conv(diff, valid, sigmas[0])
    wide, _ = norm_conv(diff, valid, sigmas[1])
    t = np.clip(den / 0.05, 0, 1)[..., None]
    return field * t + wide * (1 - t)


def ring_patch(base: np.ndarray, source: np.ndarray, mask: np.ndarray, ring_in: float, ring_out: float,
               solid: np.ndarray) -> np.ndarray:
    """`source` at the masked pixels, matched to `base` on a ring round them: a per-channel gain on
    the ring's medians, then the ring's remaining smooth difference (shading) as an additive field."""
    inner = ndimage.binary_dilation(solid, iterations=int(ring_in))
    outer = ndimage.binary_dilation(solid, iterations=int(ring_out))
    ring = outer & ~inner & ~(base[..., 1] > base[..., 0] * 1.02)  # earth only: grass (greener than red) stays out
    gain = np.array([np.median(base[..., c][ring]) / max(np.median(source[..., c][ring]), 1e-6) for c in range(3)])
    patch = np.clip(source * gain, 0, 1)
    resid, _ = norm_conv(base - patch, ring, 14)
    return np.clip(patch + resid, 0, 1)


# ---------------------------------------------------------------- the composite

def composite(light: str, hand: dict | None = None, base: np.ndarray | None = None,
              donor: np.ndarray | None = None, earth: np.ndarray | None = None) -> np.ndarray:
    """The derived plate of `light` as RGB floats: base, donor regions, door patches."""
    hand = hand or load_hand()
    cfg = hand[light]
    base = load_rgb(cfg["base"]) if base is None else base
    donor = load_rgb(cfg["donor"]) if donor is None else donor
    earth = load_rgb(cfg["earth"]) if earth is None else earth
    shape = base.shape[:2]

    # 1. donor regions, the donor first moved onto the base's sky colour
    m = donor_mask(shape, cfg["regions"])
    matched = np.clip(donor - sky_bias(base, donor, m), 0, 1)
    for fill in cfg.get("fills", []):  # the donor's own props (a cart, a stall): taken out
        matched = _sky_fill(matched, fill) if fill.get("kind") == "sky" else _fill(matched, fill)
    out = base * (1 - m[..., None]) + matched * m[..., None]

    # 2. doors: IL2's plain earth at the same pixels
    for door in cfg.get("doors", []):
        solid = ellipse_mask(shape, door["cx"], door["cy"], door["rx"], door["ry"], 0) > 0.5
        soft = ellipse_mask(shape, door["cx"], door["cy"], door["rx"], door["ry"], door.get("feather", 4))
        patch = ring_patch(out, earth, soft, door.get("ringIn", 4), door.get("ringOut", 22), solid)
        out = out * (1 - soft[..., None]) + patch * soft[..., None]
    return np.clip(out, 0, 1)


def _fill(img: np.ndarray, fill: dict) -> np.ndarray:
    """Removes a prop by filling its polygon from the picture round it (Telea inpainting), then adds
    back the cloud's own fine grain so the fill does not read as a smooth patch."""
    import cv2

    h, w = img.shape[:2]
    m = (poly_mask((h, w), fill["poly"], 0) > 0.5).astype(np.uint8) * 255
    m = cv2.dilate(m, np.ones((5, 5), np.uint8))
    u8 = np.uint8(np.clip(img, 0, 1) * 255 + 0.5)
    filled = cv2.inpaint(u8[..., ::-1].copy(), m, fill.get("radius", 7), cv2.INPAINT_TELEA)[..., ::-1]
    soft = ndimage.gaussian_filter((m > 0).astype(np.float64), 2.0)[..., None]
    f = np.asarray(filled, np.float64) / 255
    f = ndimage.gaussian_filter(f, (fill.get("blur", 5), fill.get("blur", 5), 0))
    return img * (1 - soft) + f * soft


def _sky_fill(img: np.ndarray, fill: dict) -> np.ndarray:
    """Takes a prop out of plain sky: a plane (per channel, in x and y) fitted to the `samples` boxes
    [x0, y0, x1, y1] of clear sky round it fills the polygon, blended in by the polygon's feather."""
    h, w = img.shape[:2]
    ys, xs, vals = [], [], []
    for x0, y0, x1, y1 in fill["samples"]:
        yy, xx = np.mgrid[y0:y1, x0:x1]
        ys.append(yy.ravel())
        xs.append(xx.ravel())
        vals.append(img[y0:y1, x0:x1].reshape(-1, 3))
    ys, xs, vals = np.concatenate(ys), np.concatenate(xs), np.concatenate(vals)
    design = np.stack([np.ones_like(xs), xs / w, ys / h], -1).astype(np.float64)
    coef, *_ = np.linalg.lstsq(design, vals, rcond=None)
    yy, xx = np.mgrid[0:h, 0:w]
    plane = np.stack([np.ones((h, w)), xx / w, yy / h], -1) @ coef
    m = poly_mask((h, w), fill["poly"], fill.get("feather", 10))[..., None]
    return img * (1 - m) + plane * m


# ---------------------------------------------------------------- commands

def to_image(rgb: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255 + 0.5))


def save(light: str, rgb: np.ndarray) -> Path:
    DERIVED.mkdir(parents=True, exist_ok=True)
    path = derived_path(light)
    to_image(rgb).save(path, "WEBP", lossless=True, quality=100, method=6)
    return path


def cmd_build(lights) -> None:
    hand = load_hand()
    for light in lights:
        print("wrote", save(light, composite(light, hand)).relative_to(REPO))


def cmd_check() -> int:
    hand = load_hand()
    bad = 0
    for light in LIGHTS:
        path = derived_path(light)
        if not path.is_file():
            print(f"{path.relative_to(REPO)}: missing; run il1_composite.py build")
            bad += 1
            continue
        want = np.uint8(np.clip(composite(light, hand), 0, 1) * 255 + 0.5)
        got = np.asarray(Image.open(path).convert("RGB"))
        diff = int(np.abs(want.astype(int) - got.astype(int)).max())
        if diff > 1:
            print(f"{path.relative_to(REPO)}: stale (max diff {diff}); run il1_composite.py build")
            bad += 1
    print(f"{'FAIL' if bad else 'ok'}: {bad} problem(s)")
    return 1 if bad else 0


def cmd_preview(out: Path, lights) -> None:
    out.mkdir(parents=True, exist_ok=True)
    hand = load_hand()
    for light in lights:
        cfg = hand[light]
        m = donor_mask(load_rgb(cfg["base"]).shape[:2], cfg["regions"])
        to_image(np.repeat(m[..., None], 3, -1)).save(out / f"mask-{light}.png")
        to_image(composite(light, hand)).save(out / f"composite-{light}.png")


def main(argv: list[str] | None = None) -> int:
    a = list(sys.argv[1:] if argv is None else argv)
    cmd = a[0] if a else ""
    if cmd == "build":
        cmd_build(a[1:] or LIGHTS)
    elif cmd == "check":
        return cmd_check()
    elif cmd == "preview" and len(a) >= 2:
        cmd_preview(Path(a[1]), a[2:] or LIGHTS)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
