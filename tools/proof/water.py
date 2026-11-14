#!/usr/bin/env python3
"""Proof 4, water: three 6 s loops of Çağlayan's pool and falls at the island's mid framing.

    python3 tools/proof/water.py --out DIR [--stills DIR] [--masks DIR]

  a  still, as today: the painted water does not move (the plate carries the falls baked in).
  b  the sky set's `fall` detail, as Home's two falls use it (`SkySetView.drawFall`): a streak tile
     (Home's `fall-c` flow tile, alpha-only lighter and darker streaks) scrolls down inside the fall's
     mask at 0.7 strength, a faint mist breathes at its foot. Only the falls move; the pools stay painted.
  c  a region shader emulated offline: inside masks derived from the plate by script, a flow-map scroll
     (two phases blended, so the pattern never visibly jumps) along a direction from
     `tools/proof/water_regions.json`, plus a slow ripple. The shader samples a copy of the water with
     the pixels outside the mask replaced by the nearest water pixel, so nothing from the grass, the
     stones or the boats is dragged into the water, and the result is composited through the mask:
     outside it every pixel equals the still (checked and printed).

The sky and clouds are held still in all three clips (the sky set's own drift is not a loop of 6 s),
so the only difference between the clips is the water. Every motion has a period that divides 6 s, so the
last frame leads into the first without a jump (the loop is checked by rendering t = 6 s against t = 0).
Layers are the app's: the Çağlayan sky set `day-4` (`Plates/skyset-caglayan.json`) at the island stop's
framing (`plate-caglayan.json` framing: island 0.9493 screen widths, top at 348.7 pt).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import cv2
import numpy as np
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import FPS, H, RESOURCES, W, Encoder, Sprite, contact_sheet, load_rgba  # noqa: E402

REGIONS = Path(__file__).resolve().parent / "water_regions.json"
LAYERS_KEY = "day-4"
LOOP = 6.0

# framing: master px of the sky set (2048 x 3072) to the 1206 x 2622 screen
PLATE_TO_MASTER = (4 / 3, 850.0)                      # skyset-caglayan.json plateFrame, scale 1.3333, offset (0, 850)
ISLAND_W_SCREENS, ISLAND_TOP_PT, CENTER_X = 0.9493, 348.7, 0.5
PLATE_BOX = (13.0, 28.0, 1517.0, 1000.0)              # plate-caglayan.json islandBox, plate px (1536 x 1024)


def framing() -> tuple[float, float, float]:
    """(device px per master px, screen x of master x 0, screen y of master y 0)."""
    px_per_plate = ISLAND_W_SCREENS * W / (PLATE_BOX[2] - PLATE_BOX[0])
    k = px_per_plate / PLATE_TO_MASTER[0]
    cx_plate = PLATE_BOX[0] + CENTER_X * (PLATE_BOX[2] - PLATE_BOX[0])
    mx = cx_plate * PLATE_TO_MASTER[0]
    my_top = PLATE_BOX[1] * PLATE_TO_MASTER[0] + PLATE_TO_MASTER[1]
    return k, W / 2 - mx * k, ISLAND_TOP_PT * 3 - my_top * k


def plate_to_layer(pt: tuple[float, float], layer_pos: tuple[float, float]) -> tuple[float, float]:
    """A plate px (1536 space) in the island layer's own pixels."""
    return pt[0] * PLATE_TO_MASTER[0] - layer_pos[0], pt[1] * PLATE_TO_MASTER[0] + PLATE_TO_MASTER[1] - layer_pos[1]


# ---------------------------------------------------------------- the set (still)

def background_and_island() -> tuple[np.ndarray, dict]:
    """The sky set without its island layer at t = 0, on a 1206 x 2622 float canvas; and the island layer."""
    data = json.loads((RESOURCES / "Plates" / "skyset-caglayan.json").read_text())
    layers = data["lights"][LAYERS_KEY]["layers"]
    k, ox, oy = framing()
    canvas = np.zeros((H, W, 4), np.float32)
    island = None
    for e in layers:
        if e["role"] == "island":
            island = e
            continue
        if e["role"] in ("stars",):
            continue
        sp = Sprite(load_rgba(e["asset"]))
        x, y = ox + e["pos"][0] * k, oy + e["pos"][1] * k
        w, h = e["size"][0] * k, e["size"][1] * k
        if e["role"] == "sky":
            sp.draw(canvas, x, y, w, h, replicate=True)
        elif e["role"] == "tile":
            sp.draw(canvas, x, y, w, h, wrap_x=w)
        else:
            sp.draw(canvas, x, y, w, h)
    return canvas, {"entry": island, "rgba": load_rgba(island["asset"])}


# ---------------------------------------------------------------- masks from the plate

def hsv_water(rgb: np.ndarray, alpha: np.ndarray, spec: dict) -> np.ndarray:
    hsv = cv2.cvtColor(np.ascontiguousarray(rgb), cv2.COLOR_RGB2HSV_FULL)      # H 0..255
    hue = hsv[..., 0].astype(np.float32) * 360 / 255
    s, v = hsv[..., 1], hsv[..., 2]
    return (alpha > 0.95) & (hue >= spec["hue"][0]) & (hue <= spec["hue"][1]) & (s >= spec["sat"]) & (v >= spec["val"])


def body_masks(island: dict, regions: dict) -> dict[str, np.ndarray]:
    """One float mask 0..1 per water body, from the plate's own colour inside the body's rough gate."""
    rgba = island["rgba"]
    pos = island["entry"]["pos"]
    h, w = rgba.shape[:2]
    rgb8 = (rgba[..., :3] * 255 + 0.5).astype(np.uint8)
    water = hsv_water(rgb8, rgba[..., 3], regions["colour"])
    out = {}
    for body in regions["bodies"]:
        gate = np.zeros((h, w), np.uint8)
        poly = np.float32([plate_to_layer(p, pos) for p in body["gate"]])
        cv2.fillPoly(gate, [np.round(poly).astype(np.int32)], 1)
        m = water & (gate > 0)
        close = body.get("close", 5)
        if close:
            m = cv2.morphologyEx(m.astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (close, close))) > 0
        m = ndimage.binary_fill_holes(m) & (gate > 0)
        lab, n = ndimage.label(m)
        if n:
            sizes = ndimage.sum(m, lab, range(1, n + 1))
            keep = [i + 1 for i, s in enumerate(sizes) if s >= regions["minArea"]]
            m = np.isin(lab, keep)
        er = body.get("erode", 1)
        if er:
            m = cv2.erode(m.astype(np.uint8), cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * er + 1, 2 * er + 1))) > 0
        soft = cv2.GaussianBlur(m.astype(np.float32), (0, 0), regions.get("feather", 1.2))
        out[body["id"]] = np.clip(soft * 1.0, 0, 1) * (rgba[..., 3] > 0.95)
    return out


def flow_field(shape: tuple[int, int], body: dict, pos) -> np.ndarray:
    """Unit direction per pixel from the body's polyline in the JSON (the nearest segment's tangent),
    smoothed. Shape (h, w, 2) as (dx, dy)."""
    h, w = shape
    poly = [plate_to_layer(p, pos) for p in body["flow"]]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    best = np.full((h, w), 1e18, np.float32)
    fx = np.zeros((h, w), np.float32)
    fy = np.zeros((h, w), np.float32)
    for (x0, y0), (x1, y1) in zip(poly[:-1], poly[1:]):
        dx, dy = x1 - x0, y1 - y0
        ln = math.hypot(dx, dy) or 1.0
        t = np.clip(((xx - x0) * dx + (yy - y0) * dy) / (ln * ln), 0, 1)
        d = (xx - (x0 + t * dx)) ** 2 + (yy - (y0 + t * dy)) ** 2
        take = d < best
        best = np.where(take, d, best)
        fx = np.where(take, dx / ln, fx)
        fy = np.where(take, dy / ln, fy)
    s = body.get("smooth", 25)
    return np.stack([cv2.GaussianBlur(fx, (0, 0), s), cv2.GaussianBlur(fy, (0, 0), s)], -1)


# ---------------------------------------------------------------- the three clips

class Water:
    def __init__(self, regions: dict):
        self.regions = regions
        self.bg, isl = background_and_island()
        self.island = isl
        self.rgba = isl["rgba"]
        self.pos = isl["entry"]["pos"]
        self.k, self.ox, self.oy = framing()
        self.h, self.w = self.rgba.shape[:2]
        self.masks = body_masks(isl, regions)
        self.union = np.clip(sum(self.masks.values()), 0, 1)
        self.yy, self.xx = np.mgrid[0:self.h, 0:self.w].astype(np.float32)
        # the water as a texture: outside every mask the nearest water pixel, so a displaced sample never
        # drags land into the water
        hard = self.union > 0.5
        idx = ndimage.distance_transform_edt(~hard, return_distances=False, return_indices=True)
        self.tex = self.rgba[..., :3][idx[0], idx[1]]
        self.fields = {b["id"]: flow_field((self.h, self.w), b, self.pos) for b in regions["bodies"] if b["kind"] == "flow"}
        self.fall_tile = None
        self._bbox: dict = {}

    # -- compositing the island layer on the still background
    def to_screen(self, rgb_island: np.ndarray) -> np.ndarray:
        layer = np.concatenate([rgb_island, self.rgba[..., 3:4]], -1)
        layer[..., :3] *= layer[..., 3:4]
        sw, sh = round(self.w * self.k), round(self.h * self.k)
        small = cv2.resize(layer, (sw, sh), interpolation=cv2.INTER_AREA)
        x0, y0 = round(self.ox + self.pos[0] * self.k), round(self.oy + self.pos[1] * self.k)
        out = self.bg.copy()
        ya, yb, xa, xb = max(y0, 0), min(y0 + sh, H), max(x0, 0), min(x0 + sw, W)
        src = small[ya - y0: yb - y0, xa - x0: xb - x0]
        dst = out[ya:yb, xa:xb]
        dst[...] = src + dst * (1 - src[..., 3:4])
        return out[..., :3]

    def frame_a(self, t: float) -> np.ndarray:
        return self.to_screen(self.rgba[..., :3].copy())

    # -- (b) the sky set's `fall` detail
    def frame_b(self, t: float) -> np.ndarray:
        rgb = self.rgba[..., :3].copy()
        spec = self.regions["fallDetail"]
        if self.fall_tile is None:
            tile = load_rgba(spec["flowTile"])                    # alpha-only streaks, as Home's falls
            self.fall_tile = tile
        for body in self.regions["bodies"]:
            if body["kind"] != "fall":
                continue
            m = self.masks[body["id"]]
            ys, xs = np.nonzero(m > 0.01)
            if not len(ys):
                continue
            x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
            bw = x1 - x0
            tile_h = max(round(bw * self.fall_tile.shape[0] / self.fall_tile.shape[1]), 8)      # the tile's own aspect
            tile = cv2.resize(self.fall_tile, (bw, tile_h), interpolation=cv2.INTER_LINEAR)
            # a scroll of whole tiles per loop: speed = n tiles over 6 s, nearest to the app's 20 px/s
            px_s = spec["speed"] / self.k                           # screen px/s to island-layer px/s
            tiles_per_loop = max(round(px_s * LOOP / tile_h), 1)
            shift = (t / LOOP * tiles_per_loop * tile_h) % tile_h
            ii = math.floor(shift)
            f = shift - ii
            rolled = np.roll(tile, ii, axis=0) * (1 - f) + np.roll(tile, ii + 1, axis=0) * f
            reps = int(math.ceil((y1 - y0) / tile_h)) + 1
            veil = np.tile(rolled, (reps, 1, 1))[: y1 - y0]
            a = veil[..., 3:4] * spec["strength"] * m[y0:y1, x0:x1, None]
            sub = rgb[y0:y1, x0:x1]
            sub[...] = veil[..., :3] * a + sub * (1 - a)
            # the mist breathes at the foot (period 3 s so that it loops in 6)
            level = spec["mistPeak"] * math.sin(math.pi * t / spec["mistPeriod"]) ** 2
            cx = (x0 + x1) / 2
            cy = y1 - 0.04 * (y1 - y0)
            rx = bw * spec["mistRadius"]
            ry = rx * 0.5
            self._puff(rgb, cx, cy, rx, ry, level, spec["mistColor"])
        return self.to_screen(rgb)

    @staticmethod
    def _puff(rgb: np.ndarray, cx: float, cy: float, rx: float, ry: float, level: float, colour) -> None:
        x0, x1 = max(int(cx - rx) - 1, 0), min(int(cx + rx) + 2, rgb.shape[1])
        y0, y1 = max(int(cy - ry) - 1, 0), min(int(cy + ry) + 2, rgb.shape[0])
        yy, xx = np.mgrid[y0:y1, x0:x1]
        r = np.hypot((xx - cx) / rx, (yy - cy) / ry)
        a = (level * np.interp(r, [0, 0.5, 1], [1, 0.45, 0]))[..., None].astype(np.float32)
        sub = rgb[y0:y1, x0:x1]
        sub[...] = np.float32(colour) * a + sub * (1 - a)

    # -- (c) the region shader
    def bbox(self, body_id: str, pad: int = 40) -> tuple[int, int, int, int]:
        b = self._bbox.get(body_id)
        if b is None:
            ys, xs = np.nonzero(self.masks[body_id] > 0.001)
            b = (-1,) * 4 if not len(ys) else (max(xs.min() - pad, 0), max(ys.min() - pad, 0), min(xs.max() + pad, self.w), min(ys.max() + pad, self.h))
            self._bbox[body_id] = b
        return b

    def frame_c(self, t: float) -> np.ndarray:
        out = self.rgba[..., :3].copy()
        for body in self.regions["bodies"]:
            x0, y0, x1, y1 = self.bbox(body["id"])
            if x0 < 0:
                continue
            m = self.masks[body["id"]][y0:y1, x0:x1]
            xx, yy = self.xx[y0:y1, x0:x1], self.yy[y0:y1, x0:x1]
            cycle, mag = body["cycle"], body["mag"]                  # cycle divides 6 s; mag in island-layer px
            if body["kind"] == "flow":
                field = self.fields[body["id"]][y0:y1, x0:x1]
            elif body["kind"] == "fall":
                field = np.zeros(m.shape + (2,), np.float32)
                field[..., 1] = 1
            else:
                field = np.zeros(m.shape + (2,), np.float32)
            acc = np.zeros(m.shape + (3,), np.float32)
            for off in (0.0, 0.5):
                p = (t / cycle + off) % 1.0
                wgt = 1 - abs(2 * p - 1)                            # 0 at the pattern's reset, 1 mid-cycle: the reset is hidden
                d = (p - 0.5) * mag
                rip = body.get("ripple", 0.0)
                ph = 2 * math.pi * t / body.get("ripplePeriod", 3.0)   # slow ripple, period divides 6 s
                wx = rip * np.sin(yy / 17.0 + ph) if rip else 0
                wy = rip * np.sin(xx / 23.0 - ph) if rip else 0
                samp = cv2.remap(self.tex, xx - field[..., 0] * d + wx, yy - field[..., 1] * d + wy, cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)
                acc += samp * wgt
            sub = out[y0:y1, x0:x1]
            sub[...] = sub * (1 - m[..., None]) + acc * m[..., None]
        return self.to_screen(out)

    def outside_diff(self, t: float) -> dict:
        """Largest per-channel difference of clip c from the still, outside the dilated union of the masks."""
        still = self.rgba[..., :3]
        c = self.frame_c_island(t)
        grow = cv2.dilate((self.union > 0.001).astype(np.uint8), np.ones((5, 5), np.uint8)) > 0
        d = np.abs(c - still).max(-1)
        return {"max_outside": float(d[~grow].max()), "max_inside": float(d[grow].max()), "mask_px": int((self.union > 0.5).sum())}

    def frame_c_island(self, t: float) -> np.ndarray:
        saved = self.to_screen
        cap = {}
        self.to_screen = lambda rgb: cap.setdefault("rgb", rgb)          # type: ignore[assignment]
        try:
            self.frame_c(t)
        finally:
            self.to_screen = saved                                       # type: ignore[assignment]
        return cap["rgb"]


def overlay(wt: Water, path: Path) -> None:
    """The masks over the plate, for looking (not part of the clips)."""
    from PIL import Image
    base = wt.rgba[..., :3].copy()
    for i, (name, m) in enumerate(wt.masks.items()):
        col = np.float32([(1, 0, 0), (1, 0.6, 0), (1, 0, 1), (0, 0, 1), (0.3, 0.3, 0.3), (1, 1, 0)][i % 6])
        base = base * (1 - 0.55 * m[..., None]) + col * 0.55 * m[..., None]
    crop = base[int(wt.h * 0.0):, :]
    Image.fromarray((np.clip(crop, 0, 1) * 255).astype(np.uint8)).resize((crop.shape[1] // 2, crop.shape[0] // 2)).save(path)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--stills", type=Path)
    ap.add_argument("--masks", type=Path, help="write the mask overlay PNG here")
    ap.add_argument("--no-video", action="store_true")
    ap.add_argument("--which", nargs="+", default=["a", "b", "c"], choices=["a", "b", "c"])
    args = ap.parse_args(argv)
    regions = json.loads(REGIONS.read_text())
    wt = Water(regions)
    if args.masks:
        args.masks.mkdir(parents=True, exist_ok=True)
        overlay(wt, args.masks / "masks.png")
    n = round(LOOP * FPS)
    picks = [round(i * (n - 1) / 5) for i in range(6)]
    names = {"a": "water-a-still", "b": "water-b-falldetail", "c": "water-c-region-shader"}
    report = {"loop_error": {}}
    for which in args.which:
        fn = {"a": wt.frame_a, "b": wt.frame_b, "c": wt.frame_c}[which]
        enc = None if args.no_video else Encoder(args.out / f"{names[which]}.mp4")
        kept = []
        labels = []
        for i in range(n):
            fr = fn(i / FPS)
            if enc:
                enc.write(fr)
            if i in picks:
                kept.append(fr.copy())
                labels.append(f"{which} t={i / FPS:.2f}s")
                if args.stills:
                    from PIL import Image
                    args.stills.mkdir(parents=True, exist_ok=True)
                    Image.fromarray((np.clip(fr, 0, 1) * 255 + 0.5).astype(np.uint8)).save(args.stills / f"{names[which]}-{i:03d}.png")
        if enc:
            enc.close()
        # loop check: t = 6 s against t = 0, and one frame step against the step across the seam
        f0, f6, f1 = fn(0.0), fn(LOOP), fn(1 / FPS)
        report["loop_error"][which] = {"t6_vs_t0_max": float(np.abs(f6 - f0).max()),
                                       "step_across_seam_mean": float(np.abs(fn((n - 1) / FPS) - f0).mean()),
                                       "typical_step_mean": float(np.abs(f1 - f0).mean())}
        contact_sheet(kept, args.out / f"{names[which]}-sheet.jpg", labels)
        print(which, "done", flush=True)
    report["region_leak_c"] = wt.outside_diff(1.37)
    (args.out / "water-report.json").write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
