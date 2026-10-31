"""Slice, register, and check a GPT Image sprite sheet.

The asset contract (docs/design/companion-motion.md, "Sprite sheets") asks
the image model for short animations as one grid image (for example 4x4
frames on a transparent background, generated from the base reference in a
single prompt). Image models do not keep a grid's cells registered: the
character drifts a few pixels, changes size slightly, and the palette
wanders. This tool makes a sheet usable and tells you when it is not.

Steps:
1. Cut the sheet into `cols x rows` cells (equal cells, optional gutter).
2. Get alpha: use the PNG's alpha if present, else key a flat background
   estimated from the cell border (same idea as key_background.py, simpler).
3. Register every frame to the reference (the base image, or frame 0):
   - scale so the body width (alpha extent in the lower half, which ears,
     tuft, and arms do not affect) matches the reference;
   - translate so the baseline (lowest opaque row) and the body's
     horizontal center match.
   Hops must be authored in code, not in the sheet; the baseline lock
   removes any vertical drift on purpose.
4. Check each frame against the reference and report:
   - palette drift: CIE76 delta E between mean Lab colors of opaque pixels
     (warn > 4, fail > 8);
   - silhouette IoU after registration (warn < 0.85, fail < 0.75);
   - residual baseline error after registration (fail > 1 px);
   - scale correction more than 10% off the sheet's median (fail: the
     model resized the character);
   - opaque pixels within 4 px of a cell edge (fail: clipped).
5. Write registered frames as `NAME_00.png ...`, a contact sheet, and a
   JSON manifest with per-frame transforms and scores.

Usage:
  python3 slice_sprite_sheet.py SHEET.png --grid 4x4 --out DIR \
      [--reference BASE.png] [--size 1024] [--name blink] [--frames 12]

Requires numpy, scipy, Pillow.
"""

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as nd


def srgb_to_lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def ensure_alpha(cell: np.ndarray) -> np.ndarray:
    """Return RGBA float; key a flat background if the cell is opaque."""
    if cell.shape[2] == 4 and cell[..., 3].min() < 250:
        return cell.astype(float)
    rgb = cell[..., :3].astype(float)
    border = np.concatenate([rgb[:3].reshape(-1, 3), rgb[-3:].reshape(-1, 3),
                             rgb[:, :3].reshape(-1, 3), rgb[:, -3:].reshape(-1, 3)])
    bg = np.median(border, 0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(-1))
    hard = nd.binary_fill_holes(nd.binary_closing(dist > 22, iterations=2))
    labels, n = nd.label(hard)
    if n > 1:
        sizes = nd.sum(hard, labels, range(1, n + 1))
        hard = labels == (1 + int(np.argmax(sizes)))
    alpha = nd.gaussian_filter(hard.astype(float), 0.8)
    return np.dstack([rgb, alpha * 255])


def measure(rgba: np.ndarray) -> dict:
    a = rgba[..., 3] > 128
    ys, xs = np.nonzero(a)
    if ys.size == 0:
        raise ValueError("empty frame")
    top, bottom = ys.min(), ys.max()
    lower = a[(top + bottom) // 2: bottom + 1]
    lys, lxs = np.nonzero(lower)
    return {
        "baseline": float(bottom),
        "top": float(top),
        "body_width": float(lxs.max() - lxs.min() + 1),
        "body_center": float((lxs.max() + lxs.min()) / 2),
    }


def place(rgba: np.ndarray, scale: float, dx: float, dy: float, size: tuple) -> np.ndarray:
    """Scale about the origin, then translate, into a canvas of `size`."""
    h, w = size
    img = Image.fromarray(np.clip(rgba, 0, 255).astype(np.uint8), "RGBA")
    # Premultiply for clean resampling at fur edges.
    arr = np.asarray(img).astype(float)
    arr[..., :3] *= arr[..., 3:4] / 255
    img = Image.fromarray(arr.astype(np.uint8), "RGBA")
    inv = (1 / scale, 0, -dx / scale, 0, 1 / scale, -dy / scale)
    out = np.asarray(img.transform((w, h), Image.AFFINE, inv, resample=Image.BICUBIC)).astype(float)
    a = np.maximum(out[..., 3:4], 1e-3)
    out[..., :3] = np.where(out[..., 3:4] > 0, out[..., :3] * 255 / a, 0)
    return out


def main():
    p = argparse.ArgumentParser()
    p.add_argument("sheet")
    p.add_argument("--grid", default="4x4", help="COLSxROWS")
    p.add_argument("--gutter", type=int, default=0, help="pixels between cells")
    p.add_argument("--frames", type=int, default=0, help="use only the first N cells")
    p.add_argument("--reference", help="base image the frames must match (default: frame 0)")
    p.add_argument("--size", type=int, default=0, help="output canvas size (default: reference size)")
    p.add_argument("--name", default="frame")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    cols, rows = (int(v) for v in args.grid.lower().split("x"))
    sheet = np.asarray(Image.open(args.sheet).convert("RGBA"))
    sh, sw, _ = sheet.shape
    cw = (sw - args.gutter * (cols - 1)) // cols
    ch = (sh - args.gutter * (rows - 1)) // rows
    cells = []
    for r in range(rows):
        for c in range(cols):
            y0, x0 = r * (ch + args.gutter), c * (cw + args.gutter)
            cells.append(ensure_alpha(sheet[y0:y0 + ch, x0:x0 + cw]))
    if args.frames:
        cells = cells[:args.frames]

    if args.reference:
        ref = ensure_alpha(np.asarray(Image.open(args.reference).convert("RGBA")))
    else:
        ref = cells[0]
    rh, rw = ref.shape[:2]
    if args.size:
        k = args.size / max(rh, rw)
        ref = place(ref, k, 0, 0, (int(round(rh * k)), int(round(rw * k))))
        rh, rw = ref.shape[:2]
    target = measure(ref)
    ref_mask = ref[..., 3] > 128
    ref_lab = srgb_to_lab(ref[..., :3][ref_mask]).mean(0)

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    report = {"sheet": args.sheet, "grid": [cols, rows], "reference": args.reference or "frame 0",
              "canvas": [rw, rh], "frames": []}
    registered = []
    scales = [target["body_width"] / measure(cell)["body_width"] for cell in cells]
    median_scale = float(np.median(scales))
    for i, cell in enumerate(cells):
        m = measure(cell)
        scale = scales[i]
        edge = cell[..., 3] > 128
        clipped = bool(edge[:4].any() or edge[-4:].any() or edge[:, :4].any() or edge[:, -4:].any())
        scale_off = abs(scale / median_scale - 1)
        dx = target["body_center"] - m["body_center"] * scale
        dy = target["baseline"] - m["baseline"] * scale
        frame = place(cell, scale, dx, dy, (rh, rw))
        fm = measure(frame)
        mask = frame[..., 3] > 128
        iou = float((mask & ref_mask).sum() / max((mask | ref_mask).sum(), 1))
        lab = srgb_to_lab(frame[..., :3][mask]).mean(0)
        delta_e = float(np.sqrt(((lab - ref_lab) ** 2).sum()))
        baseline_err = abs(fm["baseline"] - target["baseline"])
        status = "pass"
        if delta_e > 4 or iou < 0.85:
            status = "warn"
        if delta_e > 8 or iou < 0.75 or baseline_err > 1 or scale_off > 0.10 or clipped:
            status = "fail"
        name = f"{args.name}_{i:02d}.png"
        Image.fromarray(np.clip(frame, 0, 255).astype(np.uint8), "RGBA").save(out / name, optimize=True)
        registered.append(frame)
        report["frames"].append({
            "file": name, "scale": round(scale, 4), "dx": round(dx, 2), "dy": round(dy, 2),
            "delta_e": round(delta_e, 2), "iou": round(iou, 3),
            "baseline_error_px": round(baseline_err, 2), "scale_off_median": round(scale_off, 3),
            "clipped": clipped, "status": status,
        })
        flags = (" clipped" if clipped else "") + (" resized" if scale_off > 0.10 else "")
        print(f"{name}: scale {scale:.3f} shift ({dx:+.1f}, {dy:+.1f})  dE {delta_e:4.1f}  IoU {iou:.3f}  {status}{flags}")

    # Contact sheet on a neutral checker for review.
    tile = 256
    sheet_out = Image.new("RGB", (tile * min(len(registered), 8), tile * ((len(registered) + 7) // 8)), (240, 240, 240))
    for i, f in enumerate(registered):
        im = Image.fromarray(np.clip(f, 0, 255).astype(np.uint8), "RGBA")
        im.thumbnail((tile, tile))
        bg = Image.new("RGBA", im.size, (253, 237, 229, 255))
        bg.alpha_composite(im)
        sheet_out.paste(bg.convert("RGB"), ((i % 8) * tile, (i // 8) * tile))
    sheet_out.save(out / f"{args.name}_contact.png")
    worst = max((f["status"] for f in report["frames"]), key=["pass", "warn", "fail"].index)
    report["status"] = worst
    (out / f"{args.name}.json").write_text(json.dumps(report, indent=2))
    print(f"overall: {worst}")


if __name__ == "__main__":
    main()
