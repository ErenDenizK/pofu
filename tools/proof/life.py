#!/usr/bin/env python3
"""Proof round 3, R2: life (docs/design/world-presentation-v2.md section 3).

    python3 tools/proof/life.py --out DIR --frames DIR --clip map|mid|today|still [--seconds 12]

12 s clips at 1206 x 2622 and 30 fps (H.264), every layer moved by its own transform as section 3's table says:
  map    the Map at stage 3 (tier-1 frame, journey order) with the table's motion
  mid    the island at level 4 at mid with the chrome (the island and the characters stay still: targets do not move)
  today  today's Map, the camera pull-out proof's frame (a) at z 0, with only today's motion (`SkyMotion`: drift, bob, glide)
  still  the Map's first frame held for 3 s (the Still tier: every layer at rest, so the meter must read 0)
Drawn: horizon band 2 pt/s, floors 5, 9, 16 pt/s with swell 3, 5, 8 pt over 11, 17, 23 s, far isles bob 2 pt over 9 to 13 s,
whale glide 5 pt/s with bob 4 pt and roll 1.5 degrees, towers billow 2 % over 20 s, islands at the Map bob 2 pt over 6 to 9
s, three birds crossing at 18 pt/s, a wisp crossing Home's foot at 14 pt/s, cloud shadows drifting 8 pt/s inside the island's
matte, sun shafts at opacity 0.25 to 0.45 over 12 s. Not drawn (region shaders, 5 % of the pixels by v1's own limit): water,
lamps, canopy sway. Not drawn: the 20 s hour change. Stand-in: the cloud puffs are the `mid` tile band, one moving layer
where the spec has five to seven cut-outs. Speeds are screen pt/s, never above 20; periods never under 5 s.
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import composition as C  # noqa: E402
from _common import FPS, H, W, Encoder, Sprite, contact_sheet  # noqa: E402

PT = C.PT


def island_mask(kind: str) -> np.ndarray:
    if kind == "map":
        slots = C.map_slots(3, 1, False)
        cam = C.map_camera(slots, 1, False)
        layer, (hx, hy, hw, hh) = C.home_layer(4)
    else:
        cam = C.Cam(C.MID_SCALE, (201.0, 383.0))
        layer, (hx, hy, hw, hh) = C.home_layer(C.STAGE_OF_LEVEL[4])
    px, py, sk = cam.pt(hx, hy)
    z = np.zeros((H, W, 4), np.float32)
    layer.draw(z, px * PT, py * PT, hw * sk * PT, hh * sk * PT)
    return z[..., 3].copy()


class Overlays:
    def __init__(self, kind: str):
        self.kind = kind
        self.mask = island_mask(kind)
        rng = np.random.default_rng(11)
        f = cv2.GaussianBlur(np.tile(rng.random((70, 32)).astype(np.float32), (3, 3)), (0, 0), 3.0)[70:140, 32:64]
        f = (f - f.min()) / (f.max() - f.min())
        self.field = np.clip((f - 0.45) / 0.25, 0, 1)                       # blobs of shade, about a third of the area
        beams = np.zeros((H, W), np.float32)
        for x0, wd in ((760, 120), (980, 90), (1160, 140)):
            pts = np.array([[x0, 0], [x0 + wd, 0], [x0 - 700 + wd, 1900], [x0 - 700, 1900]], np.int32)
            cv2.fillConvexPoly(beams, pts, 1.0, cv2.LINE_AA)
        self.beams = cv2.GaussianBlur(beams, (0, 0), 55)

    def apply(self, out: np.ndarray, t: float) -> None:
        rgb = out[..., :3]
        # cloud shadows inside the island's matte, 8 pt/s
        tx = 8.0 * t * PT * self.field.shape[1] / W
        fld = cv2.warpAffine(self.field, np.float32([[1, 0, tx], [0, 1, 0]]), (self.field.shape[1], self.field.shape[0]),
                             flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_WRAP)
        fld = cv2.resize(fld, (W, H), interpolation=cv2.INTER_LINEAR)
        rgb *= (1 - 0.20 * fld * self.mask)[..., None] * np.float32([1, 1, 1]) + 0 * rgb
        # sun shafts, opacity 0.25 to 0.45 over 12 s
        op = 0.35 + 0.10 * math.sin(2 * math.pi * t / 12.0)
        a = (self.beams * op * 0.30)[..., None]
        rgb[...] = 1 - (1 - rgb) * (1 - a * np.float32([1.0, 0.96, 0.82]))
        # three birds, 18 pt/s, wings beating about 1.3 Hz
        bl = np.zeros((H, W), np.float32)
        for i in range(3):
            x = (-30 + 18.0 * (t - 1.0 - 0.7 * i) + 12 * i) * PT
            if t < 1.0 + 0.7 * i or x > W + 60:
                continue
            y = (170 + 22 * i + 5 * math.sin(2 * math.pi * t / 7.0 + i)) * PT
            flap = math.sin(2 * math.pi * 1.3 * t + i)
            wing, rise = 14 * PT, (0.55 * flap - 0.1) * 12 * PT
            pts = np.int32([[x - wing, y - rise], [x, y], [x + wing, y - rise]])
            cv2.polylines(bl, [pts], False, 1.0, 4, cv2.LINE_AA)
        rgb[...] = rgb * (1 - 0.8 * bl[..., None]) + np.float32([0.30, 0.32, 0.42]) * 0.8 * bl[..., None]
        # one wisp across Home's foot (Map only), 14 pt/s
        if self.kind == "map" and t > 1.5:
            wx = 40 + 14.0 * (t - 1.5)
            for k in range(3):
                C.shade_ellipse(out, (wx + 22 * k) * PT, (640 + 5 * k) * PT, 70 * PT, 6 * PT, 0.45, (1, 0.98, 1))


def render(kind: str, t: float, ch: C.Chrome, ov: Overlays | None, mo_on: bool = True):
    mo = C.Motion(t, mo_on)
    if kind == "map":
        out, _ = C.render_map(ch, 3, 1, False, mo)
    else:
        out, _ = C.render_mid(ch, 4, mo)
    if ov is not None:
        ov.apply(out, t if mo_on else 0.0)
    return out[..., :3]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--frames", type=Path, required=True)
    ap.add_argument("--clip", required=True, choices=["map", "mid", "today", "still"])
    ap.add_argument("--seconds", type=float, default=12.0)
    args = ap.parse_args(argv)
    n = round(args.seconds * FPS)
    name = {"map": "life-map-stage3", "mid": "life-mid-level4", "today": "life-map-today", "still": "life-map-still"}[args.clip]
    enc = Encoder(args.out / f"{name}.mp4")
    picks = [round(i * (n - 1) / 5) for i in range(6)]
    kept = []
    if args.clip == "today":
        import camera_pullout as cp
        sc = cp.Scene()
        for i in range(n):
            fr = sc.frame_a(0.0, i / FPS)
            enc.write(fr)
            if i in picks:
                kept.append(fr.copy())
    else:
        ch = C.Chrome(args.frames)
        kind = "mid" if args.clip == "mid" else "map"
        ov = Overlays(kind)
        if args.clip == "still":
            fr = render("map", 0.0, ch, ov, mo_on=False)
            for i in range(round(3 * FPS)):
                enc.write(fr)
            kept = [fr.copy()] * 6
        else:
            for i in range(n):
                fr = render(kind, i / FPS, ch, ov)
                enc.write(fr)
                if i in picks:
                    kept.append(fr.copy())
                if i % 60 == 0:
                    print(name, i, flush=True)
    enc.close()
    contact_sheet(kept, args.out / f"{name}-sheet.jpg", [f"t={p / FPS:.1f}s" for p in picks])
    print(name, "done", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
