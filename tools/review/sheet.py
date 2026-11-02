#!/usr/bin/env python3
"""Cheap visual review: montage, video keyframes, and image diff.

Every command writes one JPEG (quality 80) whose long side is at most
--max pixels (default 1400). See README.md for the review rule.
"""
from __future__ import annotations

import argparse
import math
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

LABEL_H = 18
PAD = 4
BG = (24, 24, 28)
FG = (235, 235, 235)


def _font(size: int = 12):
    for name in ("DejaVuSans.ttf", "Arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _fit(img: Image.Image, w: int, h: int) -> Image.Image:
    img = img.convert("RGB")
    scale = min(w / img.width, h / img.height)
    size = (max(1, round(img.width * scale)), max(1, round(img.height * scale)))
    return img.resize(size, Image.LANCZOS)


def _limit(sheet: Image.Image, max_side: int) -> Image.Image:
    long = max(sheet.size)
    if long <= max_side:
        return sheet
    s = max_side / long
    return sheet.resize((max(1, round(sheet.width * s)), max(1, round(sheet.height * s))), Image.LANCZOS)


def _save(sheet: Image.Image, out: Path, max_side: int) -> Path:
    sheet = _limit(sheet, max_side)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out, "JPEG", quality=80, optimize=True)
    return out


def grid(items: list[tuple[str, Image.Image]], cols: int, max_side: int) -> Image.Image:
    """Lay labeled images out in a grid no larger than max_side on its long side."""
    cols = max(1, min(cols, len(items)))
    rows = math.ceil(len(items) / cols)
    cell_w = (max_side - PAD * (cols + 1)) // cols
    cell_h = cell_w
    if rows * (cell_h + LABEL_H + PAD) + PAD > max_side:
        cell_h = (max_side - PAD * (rows + 1) - rows * LABEL_H) // rows
    cell_w, cell_h = max(cell_w, 16), max(cell_h, 16)
    # Shrink cells to the content so a few small images do not make a huge sheet.
    biggest_w = max(im.width for _, im in items)
    biggest_h = max(im.height for _, im in items)
    cell_w, cell_h = min(cell_w, biggest_w), min(cell_h, biggest_h)
    sheet = Image.new("RGB", (cols * (cell_w + PAD) + PAD, rows * (cell_h + LABEL_H + PAD) + PAD), BG)
    draw, font = ImageDraw.Draw(sheet), _font()
    for i, (label, img) in enumerate(items):
        r, c = divmod(i, cols)
        x, y = PAD + c * (cell_w + PAD), PAD + r * (cell_h + LABEL_H + PAD)
        draw.text((x + 2, y + 2), label[: max(4, cell_w // 7)], fill=FG, font=font)
        thumb = _fit(img, cell_w, cell_h)
        sheet.paste(thumb, (x + (cell_w - thumb.width) // 2, y + LABEL_H + (cell_h - thumb.height) // 2))
    return sheet


def montage(paths: list[Path], cols: int, max_side: int, out: Path) -> Path:
    items = []
    for p in paths:
        with Image.open(p) as im:
            items.append((p.stem, im.copy()))
    if not items:
        raise SystemExit("montage: no images given")
    if cols <= 0:
        cols = math.ceil(math.sqrt(len(items)))
    return _save(grid(items, cols, max_side), out, max_side)


# ---- keyframes -------------------------------------------------------------

def ffmpeg_exe() -> str:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        raise SystemExit("ffmpeg not found: apt-get install ffmpeg, or pip install imageio-ffmpeg")


def _duration(ffmpeg: str, video: Path) -> float:
    r = subprocess.run([ffmpeg, "-hide_banner", "-i", str(video)], capture_output=True, text=True)
    m = re.search(r"Duration:\s*(\d+):(\d+):([\d.]+)", r.stderr)
    if not m:
        raise SystemExit(f"keyframes: cannot read the duration of {video}")
    return int(m[1]) * 3600 + int(m[2]) * 60 + float(m[3])


def _grab(ffmpeg: str, video: Path, t: float, dest: Path, width: int) -> bool:
    subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-ss", f"{t:.3f}", "-i", str(video),
                    "-frames:v", "1", "-vf", f"scale='min({width},iw)':-2", str(dest)], check=False)
    return dest.exists() and dest.stat().st_size > 0


def _scene_times(ffmpeg: str, video: Path, threshold: float = 0.3) -> list[float]:
    r = subprocess.run([ffmpeg, "-hide_banner", "-i", str(video), "-vf",
                        f"select='gt(scene,{threshold})',showinfo", "-an", "-f", "null", "-"],
                       capture_output=True, text=True)
    return [float(t) for t in re.findall(r"pts_time:([\d.]+)", r.stderr)]


def pick_times(duration: float, scenes: list[float], n: int) -> list[float]:
    """The first frame, then scene changes, topped up with evenly spaced times."""
    if n <= 1:
        return [0.0]
    if len(scenes) >= n - 1:
        step = len(scenes) / (n - 1)
        return [0.0] + [scenes[min(len(scenes) - 1, int(i * step))] for i in range(n - 1)]
    chosen = [0.0] + list(scenes)
    for t in (duration * (i + 0.5) / n for i in range(n)):
        if len(chosen) >= n:
            break
        if all(abs(t - c) > duration / (4 * n) for c in chosen):
            chosen.append(t)
    for t in (duration * (i + 0.5) / n for i in range(n)):  # still short: ignore spacing
        if len(chosen) >= n:
            break
        if t not in chosen:
            chosen.append(t)
    return sorted(chosen)[:n]


def keyframes(video: Path, n: int, max_side: int, out: Path, cols: int = 0) -> Path:
    ffmpeg = ffmpeg_exe()
    duration = _duration(ffmpeg, video)
    times = pick_times(duration, _scene_times(ffmpeg, video), n)
    items = []
    with tempfile.TemporaryDirectory() as tmp:
        for i, t in enumerate(times):
            dest = Path(tmp) / f"k{i}.png"
            if _grab(ffmpeg, video, min(t, max(duration - 0.05, 0)), dest, 700):
                with Image.open(dest) as im:
                    items.append((f"{t:.2f}s", im.copy()))
    if not items:
        raise SystemExit("keyframes: no frames could be extracted")
    if cols <= 0:
        landscape = items[0][1].width >= items[0][1].height
        cols = math.ceil(len(items) / 2) if landscape and len(items) > 3 else len(items)
    return _save(grid(items, cols, max_side), out, max_side)


# ---- diff ------------------------------------------------------------------

def _delta(a: Image.Image, b: Image.Image) -> np.ndarray:
    x = np.asarray(a.convert("RGB"), dtype=np.int16)
    y = np.asarray(b.convert("RGB").resize(a.size, Image.LANCZOS), dtype=np.int16)
    return np.abs(x - y)


def diff_stats(a: Image.Image, b: Image.Image) -> dict:
    d = _delta(a, b)
    peak = d.max(axis=2)
    return {
        "mean_abs": float(d.mean()),
        "max_abs": int(peak.max()),
        "changed_pct": float((peak > 16).mean() * 100),
        "rmse": float(np.sqrt((d.astype(np.float32) ** 2).mean())),
    }


def heatmap(a: Image.Image, b: Image.Image) -> Image.Image:
    d = np.clip(_delta(a, b).max(axis=2).astype(np.float32) / 255.0 * 4, 0, 1)  # amplify
    rgb = np.stack([np.clip(d * 3, 0, 1), np.clip(d * 3 - 1, 0, 1), np.clip(d * 3 - 2, 0, 1)], axis=2)
    return Image.fromarray((rgb * 255).astype(np.uint8), "RGB")  # black, red, yellow, white


def diff(path_a: Path, path_b: Path, max_side: int, out: Path) -> dict:
    with Image.open(path_a) as ia, Image.open(path_b) as ib:
        a, b = ia.convert("RGB"), ib.convert("RGB")
    stats = diff_stats(a, b)
    label = f"diff mean {stats['mean_abs']:.2f} max {stats['max_abs']} changed {stats['changed_pct']:.1f}%"
    items = [(path_a.name, a), (path_b.name, b.resize(a.size, Image.LANCZOS)), (label, heatmap(a, b))]
    _save(grid(items, 3, max_side), out, max_side)
    return stats


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("montage", help="labeled contact sheet of images")
    m.add_argument("images", nargs="+", type=Path)
    m.add_argument("--cols", type=int, default=0, help="columns (default: near square)")
    k = sub.add_parser("keyframes", help="N keyframes from a video in one strip")
    k.add_argument("video", type=Path)
    k.add_argument("-n", type=int, default=6)
    k.add_argument("--cols", type=int, default=0)
    d = sub.add_parser("diff", help="side by side with a difference heatmap")
    d.add_argument("a", type=Path)
    d.add_argument("b", type=Path)
    for p in (m, k, d):
        p.add_argument("--max", type=int, default=1400, help="long side limit in px")
        p.add_argument("-o", "--out", type=Path, required=True)
    args = ap.parse_args(argv)

    if args.cmd == "montage":
        out = montage(args.images, args.cols, args.max, args.out)
    elif args.cmd == "keyframes":
        out = keyframes(args.video, args.n, args.max, args.out, args.cols)
    else:
        stats = diff(args.a, args.b, args.max, args.out)
        print("  ".join(f"{k}={v:.3f}" if isinstance(v, float) else f"{k}={v}" for k, v in stats.items()))
        out = args.out
    with Image.open(out) as im:
        print(f"{out} {im.width}x{im.height} {out.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
