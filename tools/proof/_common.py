"""Shared helpers of the feel-and-world proofs (docs/design/feel-and-world-v1.md, section 3).

Scripts only, no Swift: layers are the app's own (the HEIC/PNG imagesets under `World.xcassets` and
`Plates/*.json`), composited offline into 1206 x 2622 frames at 30 fps and piped to ffmpeg, so no
intermediate frames are kept on disk. Needs numpy, OpenCV, Pillow, pillow-heif and ffmpeg.
"""
from __future__ import annotations

import math
import subprocess
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "plate"))
import heic  # noqa: E402

RESOURCES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
W, H = 1206, 2622
FPS = 30


def asset_path(name: str) -> Path:
    d = ASSETS / f"{name}.imageset"
    for ext in ("heic", "png", "jpg"):
        p = d / f"{name}.{ext}"
        if p.exists():
            return p
    raise FileNotFoundError(name)


def load_rgba(name: str) -> np.ndarray:
    """An imageset as float32 RGBA, straight alpha, 0..1."""
    p = asset_path(name)
    im = heic.open_image(p) if p.suffix == ".heic" else Image.open(p)
    return np.asarray(im.convert("RGBA"), np.float32) / 255


def premultiply(rgba: np.ndarray) -> np.ndarray:
    out = rgba.copy()
    out[..., :3] *= out[..., 3:4]
    return out


class Sprite:
    """A premultiplied RGBA picture with a mip chain, drawn through an affine placement."""

    def __init__(self, rgba: np.ndarray):
        self.mips = [premultiply(rgba)]

    @property
    def w(self) -> int:
        return self.mips[0].shape[1]

    @property
    def h(self) -> int:
        return self.mips[0].shape[0]

    def mip(self, scale: float) -> tuple[np.ndarray, int]:
        level = 0 if scale >= 1 else min(int(math.floor(math.log2(1 / scale))), 6)
        while len(self.mips) <= level:
            m = self.mips[-1]
            self.mips.append(cv2.resize(m, (max(m.shape[1] // 2, 1), max(m.shape[0] // 2, 1)), interpolation=cv2.INTER_AREA))
        return self.mips[level], level

    def draw(self, canvas: np.ndarray, x: float, y: float, w: float, h: float, *, alpha: float = 1.0,
             wrap_x: float | None = None, rows: np.ndarray | None = None, replicate: bool = False,
             fx: float = 1.0, fy: float = 1.0) -> None:
        """Draw with the picture's top-left at (x, y) screen px and size (w, h). `wrap_x`: the picture
        repeats across the whole width, its left edge at x modulo w (a drift tile, seamless by wrap).
        `rows`: an alpha per picture row 0..1 (a window), by dst row, length = the rows drawn.
        `replicate`: the picture's edge pixels extend past it (a sky gradient)."""
        if w < 0.5 or h < 0.5:
            return
        sx, sy = w / self.w, h / self.h
        src, level = self.mip(min(sx, sy))
        k = 2 ** level
        ax, ay = sx * k, sy * k                     # dst px per mip px
        if replicate:
            ya, yb = 0, canvas.shape[0]
            xa, xb = 0, canvas.shape[1]
            border = cv2.BORDER_REPLICATE
        else:
            ya, yb = max(int(math.floor(y)), 0), min(int(math.ceil(y + h)), canvas.shape[0])
            xa, xb = (0, canvas.shape[1]) if wrap_x else (max(int(math.floor(x)), 0), min(int(math.ceil(x + w)), canvas.shape[1]))
            border = cv2.BORDER_WRAP if wrap_x else cv2.BORDER_CONSTANT
        if yb <= ya or xb <= xa:
            return
        m = np.float32([[ax, 0, x - xa], [0, ay, y - ya]])
        part = cv2.warpAffine(src, m, (xb - xa, yb - ya), flags=cv2.INTER_LINEAR, borderMode=border, borderValue=0)
        if border == cv2.BORDER_WRAP:
            # wrap repeats vertically too: keep only the picture's own rows
            r0, r1 = max(int(math.ceil(y)) - ya, 0), min(int(math.floor(y + h)) - ya, yb - ya)
            part[:r0] = 0
            part[r1:] = 0
        if rows is not None:
            full = np.ones(yb - ya, np.float32)
            idx = np.arange(ya, yb)
            full = np.interp(idx, rows[0], rows[1], left=rows[1][0], right=rows[1][-1]).astype(np.float32)
            part *= full[:, None, None]
        if alpha != 1.0:
            part *= alpha
        dst = canvas[ya:yb, xa:xb]
        dst[...] = part + dst * (1 - part[..., 3:4])


def window_rows(top: float, bottom: float, top_fade: float, bottom_fade: float):
    """Piecewise-linear alpha over screen rows: 0 outside [top, bottom], ramps of the fades inside."""
    h = bottom - top
    if h <= 0:
        return None
    a = min(max(top_fade / h, 0), 1) * h
    b = min(max(bottom_fade / h, 0), 1) * h
    ys = [top - 1, top, top + a, bottom - b, bottom, bottom + 1]
    vs = [0, 0 if a > 0 else 1, 1, 1, 0 if b > 0 else 1, 0]
    return np.float32(ys), np.float32(vs)


def smoothstep(x: float) -> float:
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def ease_z(t: float, total: float, hold: float = 0.4) -> float:
    """0..1 over the clip: a hold at each end, a smootherstep between (the same for every clip)."""
    x = min(max((t - hold) / max(total - 2 * hold, 1e-6), 0.0), 1.0)
    return x * x * x * (x * (6 * x - 15) + 10)


class Encoder:
    """Raw RGB24 frames piped to ffmpeg: H.264 MP4, yuv420p, no frame ever hits the disk."""

    def __init__(self, path: Path, fps: int = FPS, crf: int = 17):
        path.parent.mkdir(parents=True, exist_ok=True)
        self.p = subprocess.Popen(
            ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(fps),
             "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", str(crf), "-pix_fmt", "yuv420p",
             "-movflags", "+faststart", str(path)], stdin=subprocess.PIPE)

    def write(self, rgb01: np.ndarray) -> None:
        self.p.stdin.write(np.ascontiguousarray((np.clip(rgb01, 0, 1) * 255 + 0.5).astype(np.uint8)).tobytes())

    def close(self) -> None:
        self.p.stdin.close()
        self.p.wait()


def contact_sheet(frames: list[np.ndarray], path: Path, labels: list[str] | None = None, cell_w: int = 400) -> None:
    """6 frames in 3 x 2, each shrunk to `cell_w` wide (a map of the clip, not a place to judge seams)."""
    from PIL import ImageDraw
    cell_h = round(cell_w * H / W)
    sheet = Image.new("RGB", (cell_w * 3 + 8 * 4, cell_h * 2 + 8 * 3), (24, 24, 24))
    for i, f in enumerate(frames[:6]):
        im = Image.fromarray((np.clip(f, 0, 1) * 255 + 0.5).astype(np.uint8)).resize((cell_w, cell_h), Image.LANCZOS)
        if labels:
            ImageDraw.Draw(im).text((8, 8), labels[i], fill=(255, 255, 255))
        sheet.paste(im, (8 + (i % 3) * (cell_w + 8), 8 + (i // 3) * (cell_h + 8)))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path, quality=90)
