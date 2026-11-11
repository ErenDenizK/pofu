#!/usr/bin/env python3
"""Render the shipped sky set offline, frame by frame, with the app's motion.

    python3 tools/plate/skyset_render.py home day --out clip.mp4 [--seconds 6] [--fps 30] [--vivid 1.09]
    python3 tools/plate/skyset_render.py home night --still frame.png --t 12

The layers are the app's own (`skyset_export.py`: the HEIC imagesets under `World.xcassets` and
`Plates/skyset-<island>.json`, the one source of the motion constants), composited at the Home framing
(`screen_check.framing`, 1206 x 2622). The motion functions below are the Swift runtime's
(`PofuWorld/Sky/SkySet.swift`, `SkyMotion`) formula for formula, in screen px at the 1206 px
reference screen, so a frame here is the frame the app draws at the same time t (the simulator
cannot record in CI, so the review clips come from this renderer):

  tile x       (drift * t) mod tileWidth, towards +x, the tile wrapping seamlessly
  bob y        sign * amp * sin(2 pi t / period), 0 at t = 0
  whale x      glides at `drift` and wraps once fully off screen (`glide_left`)
  star light   peak * sin^2(pi t / period) of the star's own pixels, added on the sky
  detail       (`skyset_detail.py`) on the isles and the whale, each amount rising from 0 over `ramp` s
               (`ease`, so t = 0 is the painting): a waterfall's streak texture scrolls down inside its
               mask (`flow_offset`) with a breathing mist at its foot (`mist_level`), a canopy's inside
               shears (`sway_top`), a lantern or window flickers (`flicker`)

`--vivid F` raises the chroma (CIELAB a, b) of the sky, star and cloud layers by F before
compositing: an offline edit of the layer pixels, never a runtime filter. Needs numpy, OpenCV, Pillow,
pillow-heif and ffmpeg for a clip.
"""
from __future__ import annotations

import argparse
import json
import math
import subprocess
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import screen_check  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources"
ASSETS = RESOURCES / "World.xcassets"
SCREEN = screen_check.SCREEN
#: The whale stays this many screen px beyond an edge before it wraps (the app's `SkyMotion.glideMargin`).
GLIDE_MARGIN = 40.0
CHROMA_LAYERS = ("sky", "stars", "tile")        # roles whose chroma `--vivid` raises


# ---------------------------------------------------------------- motion (the Swift formulas)

def bob_y(bob: dict | None, t: float) -> float:
    if not bob:
        return 0.0
    return bob["sign"] * bob["amp"] * math.sin(2 * math.pi * t / bob["period"])


def drift_x(layer: dict, t: float, tile_screen: float) -> float:
    return math.fmod(layer.get("drift", 0) * t, tile_screen) if tile_screen > 0 else 0.0


def glide_left(rest_left: float, width: float, speed: float, t: float, screen_width: float,
               margin: float = GLIDE_MARGIN) -> float:
    """The whale's left edge: it starts at rest, glides right, and re-enters from the left only once it
    has left the screen by `margin`, so the wrap never shows."""
    span = screen_width + 2 * margin + width
    start = rest_left + margin + width
    return math.fmod(start + speed * t, span) - margin - width


def twinkle(tw: dict, t: float) -> float:
    return tw["peak"] * math.sin(math.pi * t / tw["period"]) ** 2


def ease(t: float, ramp: float) -> float:
    """0 at t = 0, 1 from `ramp` s on (smoothstep): the detail motion's envelope."""
    if ramp <= 0:
        return 1.0
    x = min(max(t / ramp, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def flow_offset(speed: float, t: float, period: float) -> float:
    """How far a waterfall's streak tile has scrolled down, in screen px, kept within one tile."""
    return math.fmod(speed * t, period) if period > 0 else 0.0


def mist_level(mist: dict, t: float, e: float) -> float:
    return e * mist["peak"] * math.sin(math.pi * t / mist["period"]) ** 2


def flicker(d: dict, t: float) -> float:
    """A lamp's signed luminance change, -amp .. +amp, two slow sines (0.6 and 0.4), enveloped."""
    p0, p1 = d["periods"]
    return ease(t, d["ramp"]) * d["amp"] * (0.6 * math.sin(2 * math.pi * t / p0) + 0.4 * math.sin(2 * math.pi * t / p1))


def sway_top(d: dict, t: float) -> float:
    """The canopy top's horizontal displacement in screen px."""
    return ease(t, d["ramp"]) * d["amp"] * math.sin(2 * math.pi * t / d["period"])


# ---------------------------------------------------------------- layers

def boost_chroma(rgba: np.ndarray, factor: float) -> np.ndarray:
    lab = cv2.cvtColor(np.ascontiguousarray(rgba[..., :3]), cv2.COLOR_RGB2Lab)
    lab[..., 1:] *= factor
    out = rgba.copy()
    out[..., :3] = np.clip(cv2.cvtColor(lab, cv2.COLOR_Lab2RGB), 0, 1)
    return out


def load(island: str, light: str, vivid: float = 1.0) -> dict:
    data = json.loads((RESOURCES / "Plates" / f"skyset-{island}.json").read_text())
    spec = data["lights"][light]
    layers = []
    for entry in spec["layers"]:
        path = ASSETS / f"{entry['asset']}.imageset" / f"{entry['asset']}.heic"
        rgba = np.asarray(heic.open_image(path).convert("RGBA"), np.float32) / 255
        if vivid != 1.0 and entry["role"] in CHROMA_LAYERS:
            rgba = boost_chroma(rgba, vivid)
        layers.append({**entry, "rgba": rgba})
    man = {"island": island, "islandBox": spec["islandBox"], "size": spec["master"]}
    return {"data": data, "spec": spec, "layers": layers, "manifest": man, "master": spec["master"]}


def _scaled(layer: dict, g: dict, master: tuple[int, int]) -> tuple[np.ndarray, float, float]:
    """The layer at screen scale, premultiplied, and where its top-left sits on the screen at rest
    (cached). A layer that carries detail is placed on a canvas the size of the painting (plus the rows
    past it) and the canvas is area-resized whole, exactly as `screen_check.compose` does, so its
    sub-pixel phase registers with the painting instead of being shifted and blurred per layer; the soft
    sky gradient and the star light are resized on their own."""
    key = (g["sx"], g["sy"], g["ox"], g["oy"])
    if layer.get("_key") == key:
        return layer["_img"], layer["_x"], layer["_y"]
    w, h = master
    top, rows = g["top"], g["rows"]
    dw, dh = layer["size"]
    px, py = layer["pos"]
    pre = layer["rgba"].copy()
    pre[..., :3] *= pre[..., 3:4]
    if layer["role"] in ("sky", "stars"):
        size = (max(round(dw * g["sx"]), 1), max(round(dh * g["sy"]), 1))
        img = cv2.resize(pre, size, interpolation=cv2.INTER_AREA if size[0] <= pre.shape[1] else cv2.INTER_LINEAR)
        x, y = px * g["sx"] - g["ox"], (py + top) * g["sy"] - g["oy"]
    else:
        pre = cv2.resize(pre, (round(dw), round(dh)), interpolation=cv2.INTER_LINEAR if round(dw) > pre.shape[1] else cv2.INTER_AREA)
        canvas = np.zeros((rows, w, 4), np.float32)
        x0, y0 = round(px), round(py) + top
        part = pre[: max(rows - y0, 0), : max(w - x0, 0)]
        canvas[y0: y0 + part.shape[0], x0: x0 + part.shape[1]] = part
        full = cv2.resize(canvas, (round(w * g["sx"]), round(rows * g["sy"])), interpolation=cv2.INTER_AREA)
        c0, r0 = max(math.floor(x0 * g["sx"]) - 2, 0), max(math.floor(y0 * g["sy"]) - 2, 0)
        c1, r1 = min(math.ceil((x0 + part.shape[1]) * g["sx"]) + 2, full.shape[1]), min(math.ceil((y0 + part.shape[0]) * g["sy"]) + 2, full.shape[0])
        if layer["role"] == "tile":
            c0, c1 = 0, full.shape[1]                    # a tile is the whole width: it wraps
        img = full[r0:r1, c0:c1]
        x, y = c0 - g["ox"], r0 - g["oy"]
    layer.update(_img=img, _x=x, _y=y, _key=key)
    return img, x, y


def _paste(canvas: np.ndarray, img: np.ndarray, x: float, y: float, mode: str = "over") -> None:
    """Paste premultiplied `img` with its top-left at (x, y) screen px, sub-pixel."""
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = x - ix, y - iy
    if fx or fy:
        m = np.float32([[1, 0, fx], [0, 1, fy]])
        img = cv2.warpAffine(img, m, (img.shape[1] + 1, img.shape[0] + 1), flags=cv2.INTER_LINEAR,
                             borderMode=cv2.BORDER_CONSTANT, borderValue=0)
    h, w = img.shape[:2]
    x0, y0, x1, y1 = max(ix, 0), max(iy, 0), min(ix + w, canvas.shape[1]), min(iy + h, canvas.shape[0])
    if x1 <= x0 or y1 <= y0:
        return
    src = img[y0 - iy: y1 - iy, x0 - ix: x1 - ix]
    dst = canvas[y0:y1, x0:x1]
    if mode == "add":
        dst[..., :3] += src[..., :3] * src[..., 3:4]
    else:
        dst[..., :3] = src[..., :3] + dst[..., :3] * (1 - src[..., 3:4])


def _shift_tile(img: np.ndarray, shift: float) -> np.ndarray:
    """A wrapping tile moved right by `shift` px, sub-pixel (a blend of two whole-pixel rolls)."""
    i = math.floor(shift)
    f = shift - i
    a = np.roll(img, i, axis=1)
    if f < 1e-6:
        return a
    return a * (1 - f) + np.roll(img, i + 1, axis=1) * f


def _png(name: str) -> np.ndarray:
    f = ASSETS / f"{name}.imageset" / f"{name}.png"
    return np.asarray(Image.open(f).convert("RGBA"), np.float32) / 255


def _detail_prep(d: dict, g: dict) -> dict:
    """The detail's assets at screen scale (cached): its rect's top-left in screen px and the images."""
    key = (g["sx"], g["sy"], g["ox"], g["oy"])
    if d.get("_key") == key:
        return d
    sx, sy = g["sx"], g["sy"]
    d["_x"] = d["pos"][0] * sx - g["ox"]
    d["_y"] = (d["pos"][1] + g["top"]) * sy - g["oy"]
    w, h = max(round(d["size"][0] * sx), 1), max(round(d["size"][1] * sy), 1)

    def fit(img: np.ndarray, size: tuple[int, int]) -> np.ndarray:
        pre = img.copy()
        pre[..., :3] *= pre[..., 3:4]
        return cv2.resize(pre, size, interpolation=cv2.INTER_AREA if size[0] <= img.shape[1] else cv2.INTER_LINEAR)

    if d["kind"] == "fall":
        d["_mask"] = fit(_png(d["mask"]), (w, h))[..., 3]
        d["_flow"] = fit(_png(d["flow"]), (w, max(round(d["flowHeight"] * sy), h)))      # premultiplied
        m = d["mist"]
        d["_mist"] = {"c": ((m["centre"][0]) * sx - g["ox"], (m["centre"][1] + g["top"]) * sy - g["oy"]),
                      "r": (m["radius"][0] * sx, m["radius"][1] * sy)}
    elif d["kind"] == "sway":
        d["_mask"] = fit(_png(d["mask"]), (w, h))[..., 3]
        d["_crop"] = fit(_png(d["crop"]), (w, h))
    else:
        d["_glow"] = fit(_png(d["asset"]), (w, h))
    d["_key"] = key
    return d


def _paste_detail(canvas: np.ndarray, d: dict, t: float, dx: float, dy: float, g: dict) -> None:
    """One detail at time t, the app's formulas (`SkyMotion`), over the layer drawn at the offset (dx, dy)."""
    d = _detail_prep(d, g)
    e = ease(t, d["ramp"])
    x, y = d["_x"] + dx, d["_y"] + dy
    if d["kind"] == "fall":
        k = d["strength"] * e
        if k > 0.002:
            m, tile = d["_mask"], d["_flow"]
            period = tile.shape[0]
            s = flow_offset(d["speed"], t, period)
            i = math.floor(s)
            f = s - i
            rolled = np.roll(tile, i, axis=0) * (1 - f) + np.roll(tile, i + 1, axis=0) * f
            body = rolled[: m.shape[0]]
            _paste(canvas, (body * (k * m)[..., None]).astype(np.float32), x, y)
        mist = d["mist"]
        level = mist_level(mist, t, e)
        if level > 0.002:
            cx, cy = d["_mist"]["c"]
            rx, ry = d["_mist"]["r"]
            x0, y0 = math.floor(cx - rx), math.floor(cy - ry)
            yy, xx = np.mgrid[y0: math.ceil(cy + ry) + 1, x0: math.ceil(cx + rx) + 1]
            r = np.hypot((xx - cx) / rx, (yy - cy) / ry)
            a = (level * np.interp(r, [0, 0.5, 1], [1, 0.45, 0]))[..., None].astype(np.float32)
            col = np.float32(mist["color"])
            _paste(canvas, np.concatenate([col * a, a], -1), x0 + dx, y0 + dy)
    elif d["kind"] == "sway":
        top = sway_top(d, t)
        if abs(top) > 0.01:
            m, crop = d["_mask"], d["_crop"]
            h, w = m.shape
            shear = -top / h
            mat = np.float32([[1, shear, -shear * h], [0, 1, 0]])
            moved = cv2.warpAffine(crop, mat, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)
            a = m[..., None]
            _paste(canvas, np.concatenate([moved[..., :3] * a, moved[..., 3:4] * a], -1), x, y)
    else:
        v = flicker(d, t)
        glow = d["_glow"]                       # premultiplied by the mask (alpha = mask)
        if v > 0.002:
            rgb = glow[..., :3]
            h, w = rgb.shape[:2]
            _paste(canvas, np.concatenate([rgb / np.maximum(glow[..., 3:4], 1e-4), glow[..., 3:4] * v], -1).astype(np.float32), x, y, "add")
        elif v < -0.002:
            _paste(canvas, np.concatenate([np.zeros_like(glow[..., :3]), glow[..., 3:4] * -v], -1), x, y)


def geometry(man: dict, fr: dict) -> dict:
    """The master's scale and the window's origin exactly as `screen_check.compose` and `master_frame`
    place them (the painting is scaled whole, then windowed), so a layer registers with its master."""
    w, h = man["size"]
    c = 1 / fr["k"]
    top = max(int(np.ceil(-fr["y0"])), 0) + 4
    bot = max(int(np.ceil(fr["y0"] + SCREEN[1] * fr["k"] - h)), 0) + 4
    sw, sh = round(w * c), round((h + top + bot) * c)
    return {"sx": sw / w, "sy": sh / (h + top + bot), "ox": round(fr["x0"] * c), "oy": round((fr["y0"] + top) * c),
            "top": top, "rows": h + top + bot}


def render(s: dict, t: float, fr: dict | None = None, upto: str | None = None, snap: bool = False, detail: bool = True) -> np.ndarray:
    """The sky-set frame at time t: float RGB 0..255, screen (1206 x 2622), the plate framing (`snap` is
    kept for callers; the geometry is always the master's own)."""
    fr = fr or screen_check.framing(s["manifest"])
    g = geometry(s["manifest"], fr)
    canvas = np.zeros((SCREEN[1], SCREEN[0], 4), np.float32)
    for layer in s["layers"]:
        img, x, y = _scaled(layer, g, tuple(s["master"]))
        xi, yi = math.floor(x), math.floor(y)
        fx, fy = x - xi, y - yi
        dy = bob_y(layer.get("bob"), t)
        left = x
        role = layer["role"]
        if role == "tile":
            # copies repeat at the scaled tile's whole width (the app's spacing is exact and its copies
            # overlap by a point, so no hairline shows at a seam)
            tw = img.shape[1]
            body = _shift_tile(img, drift_x(layer, t, tw))
            n0, n1 = math.floor((0 - xi) / tw) - 1, math.ceil((SCREEN[0] - xi) / tw) + 1
            for n in range(n0, n1 + 1):
                _paste(canvas, body, xi + n * tw, y + dy)
        elif role == "whale":
            left = glide_left(x, img.shape[1], layer.get("drift", 0), t, SCREEN[0])
            _paste(canvas, img, left, y + dy)
        elif role == "stars":
            _paste(canvas, img * np.float32([1, 1, 1, twinkle(layer["twinkle"], t)]), x, y + dy, "add")
        else:
            _paste(canvas, img, x, y + dy)
        if detail:
            for d in layer.get("details", []):
                _paste_detail(canvas, d, t, left - x, dy, g)
        if upto == layer["id"]:
            break
    return np.clip(canvas[..., :3], 0, 1) * 255


def to_uint8(rgb: np.ndarray) -> np.ndarray:
    return np.uint8(rgb + 0.5)


def encode(frames, path: Path, fps: int, max_bytes: int = 8 * 1024 * 1024) -> None:
    """H.264 High yuv420p 1206 x 2622 (frames: iterable of uint8 RGB), re-encoded smaller until it fits."""
    frames = list(frames)
    for crf in (20, 23, 26, 29, 32, 35):
        cmd = ["ffmpeg", "-loglevel", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{SCREEN[0]}x{SCREEN[1]}",
               "-r", str(fps), "-i", "-", "-c:v", "libx264", "-profile:v", "high", "-preset", "slow", "-crf", str(crf),
               "-pix_fmt", "yuv420p", "-movflags", "+faststart", "-an", str(path)]
        p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
        for f in frames:
            p.stdin.write(f.tobytes())
        p.stdin.close()
        if p.wait() != 0:
            raise SystemExit("ffmpeg failed")
        if path.stat().st_size <= max_bytes:
            return
    raise SystemExit(f"{path.name} is still over {max_bytes} bytes")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island")
    ap.add_argument("light")
    ap.add_argument("--out", help="the clip (mp4)")
    ap.add_argument("--still", help="one frame (png) at --t")
    ap.add_argument("--t", type=float, default=0.0)
    ap.add_argument("--seconds", type=float, default=6.0)
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--start", type=float, default=0.0, help="the clip starts at this time (s)")
    ap.add_argument("--vivid", type=float, default=1.0)
    ap.add_argument("--no-detail", action="store_true", help="skip the isles' and the whale's painted-detail motion")
    a = ap.parse_args(argv)
    s = load(a.island, a.light, a.vivid)
    fr = screen_check.framing(s["manifest"])
    if a.still:
        Image.fromarray(to_uint8(render(s, a.t, fr, detail=not a.no_detail))).save(a.still)
    if a.out:
        n = round(a.seconds * a.fps)
        encode((to_uint8(render(s, a.start + i / a.fps, fr, detail=not a.no_detail)) for i in range(n)), Path(a.out), a.fps)
        print(f"{a.out}: {Path(a.out).stat().st_size / 1e6:.2f} MB, {n} frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
