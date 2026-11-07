"""Look lab: the home scene as layers with ids, ungraded art and a layered depth buffer.

Uses lookdev's scene format and loaders (`tools/assets/lookdev.py`: `Layer`, `load_background`),
so the same recipe (`home-lab.json`) renders under the game's current light in lookdev ("before")
and through the lab's passes here ("after"). On top of lookdev it adds what a relight needs:

  ids      0 sky, 1 cloud sea, 2 plate, 3.. layers (back to front)
  depth    0..1, larger is nearer (the convention of the monocular model in depth.py):
           sky 0, cloud sea 0.12 to 0.3 rising toward the bottom, the plate's lawn a plane
           tilted toward the camera, its earth face a rounded wall below the front lip, each
           sprite at its foot's depth plus a dome from its silhouette (`normals.height_map`).
  ground   the same without the sprites (the plate, sea and sky): AO measures height above it.
  height   each sprite's dome height alone, 0 elsewhere.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lab  # noqa: E402,F401  (puts tools/assets on the path)
import lookdev as ld  # noqa: E402
import normals as nm  # noqa: E402

HERE = Path(__file__).resolve().parent
SCENE = HERE / "home-lab.json"
CLOUD_SEA = lab.REPO / "design" / "art" / "masters" / "cloud-sea" / "cloud-sea.png"


class Scene:
    def __init__(self, path: Path = SCENE):
        self.spec = ld.load_scene(path)
        self.w, self.h = self.spec["canvas"]
        w, h = self.w, self.h
        self.bg, _ = ld.load_background(self.spec["background"], (w, h))
        self.layers = sorted((ld.Layer(s, (w, h)) for s in self.spec.get("layers", [])), key=lambda l: l.y)
        self.sea = self._cloud_sea()
        self._plate_geometry()
        self._depth()

    # ------------------------------------------------------------ parts

    def _cloud_sea(self) -> np.ndarray:
        """The cloud-sea master, full width, its top at 70 % of the frame (behind the island)."""
        w, h = self.w, self.h
        im = Image.open(CLOUD_SEA).convert("RGBA")
        im = im.crop(im.getbbox())
        th = round(h * 0.34)
        im = im.resize((w, th), Image.Resampling.LANCZOS)
        out = np.zeros((h, w, 4))
        ld.paste(out, np.asarray(im, np.float64) / 255, 0, h - th)
        return out

    def _plate_geometry(self) -> None:
        a = self.bg[..., 3] > 0.5
        ys, xs = np.nonzero(a)
        self.px0, self.px1 = xs.min(), xs.max()
        self.cx = (self.px0 + self.px1) / 2
        self.rx = (self.px1 - self.px0) / 2
        lawn = (self.bg[..., 1] - self.bg[..., 0] > 0.0) & a
        ly = np.nonzero(lawn)[0]
        self.lawn = ndimage.binary_opening(lawn, iterations=2)
        self.y_top, self.y_front = np.percentile(ly, 1), np.percentile(ly, 99.5)
        self.y_bottom = ys.max()

    def lawn_depth(self, y):
        """The lawn plane: 0.55 at its far edge to 0.80 at its front lip."""
        t = np.clip((y - self.y_top) / max(self.y_front - self.y_top, 1), 0, 1)
        return 0.55 + 0.25 * t

    def _depth(self) -> None:
        w, h = self.w, self.h
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
        d = np.zeros((h, w))
        ids = np.zeros((h, w), np.int32)
        sea_a = self.sea[..., 3]
        d = np.where(sea_a > 0.3, 0.12 + 0.18 * (yy - h * 0.66) / (h * 0.34), d)
        ids[sea_a > 0.3] = 1
        a = self.bg[..., 3] > 0.5
        u = np.clip((xx - self.cx) / self.rx, -1, 1)
        round_x = 0.06 * (1 - u ** 2)
        below = np.clip((yy - self.y_front) / max(self.y_bottom - self.y_front, 1), 0, 1)
        lawn_d = self.lawn_depth(yy)
        face_d = 0.80 + round_x - 0.10 * below ** 2
        plate_d = np.where(yy <= self.y_front, lawn_d + 0.4 * round_x * (yy - self.y_top) / max(self.y_front - self.y_top, 1), face_d)
        d = np.where(a, plate_d, d)
        ids[a] = 2
        self.ground = ndimage.gaussian_filter(d, 0.7)
        self.height = np.zeros((h, w))
        for i, l in enumerate(self.layers):
            la = l.rgba[..., 3] > 0.5
            if not la.any():
                continue
            hm = nm.height_map(l.rgba[..., :3], l.rgba[..., 3], dome=0.6, detail=0.06)
            hm = hm / max(hm.max(), 1e-6)
            foot = float(self.lawn_depth(l.foot[1]))
            thick = 0.05 * l.height_px / h  # a dome about as deep as a fifth of its height
            if l.name == "pond":  # flat on the ground
                thick = 0.0
            d = np.where(la, foot + thick * hm, d)
            self.height = np.where(la, (0.2 if thick else 0.0) * l.height_px / h * hm + (thick > 0) * 1e-3, self.height)
            ids[la] = 3 + i
        self.depth = ndimage.gaussian_filter(d, 0.7)
        self.ids = ids

    # ------------------------------------------------------------ composites

    def sky(self, zenith, horizon) -> np.ndarray:
        h, w = self.h, self.w
        t = np.clip(np.linspace(0, 1, h) / 0.75, 0, 1)[:, None, None]
        z, hz = np.asarray(zenith, float), np.asarray(horizon, float)
        return np.broadcast_to(z * (1 - t) + hz * t, (h, w, 3)).copy()

    def raw(self, sky_rgb: np.ndarray, layer_fn=None) -> np.ndarray:
        """Sky, cloud sea, plate, then layers back to front (ungraded art, straight over)."""
        f = sky_rgb.copy()
        ld.over(f, self.sea[..., :3], self.sea[..., 3])
        ld.over(f, self.bg[..., :3], self.bg[..., 3])
        for l in self.layers:
            rgb = l.rgba[..., :3] if layer_fn is None else layer_fn(l)
            ld.over(f, rgb, l.rgba[..., 3])
        return f

    def mask(self, *names: str) -> np.ndarray:
        idx = {l.name: 3 + i for i, l in enumerate(self.layers)}
        m = np.zeros((self.h, self.w), bool)
        for n in names:
            if n == "sky":
                m |= self.ids == 0
            elif n == "sea":
                m |= self.ids == 1
            elif n == "plate":
                m |= self.ids == 2
            elif n == "sprites":
                m |= self.ids >= 3
            else:
                m |= self.ids == idx[n]
        return m

    def lights(self) -> list[dict]:
        """Point lights from the recipe's `light` entries, in canvas pixels, at the source's depth."""
        out = []
        for l in self.layers:
            if not l.light:
                continue
            ys, xs = np.nonzero(l.rgba[..., 3] > 0.3)
            x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
            at = l.light.get("at", [0.5, 0.18])
            x, y = x0 + at[0] * (x1 - x0), y0 + at[1] * (y1 - y0)
            # At the depth of the source's foot (its sample point may fall on a hole in the sprite).
            out.append({"name": l.name, "x": float(x), "y": float(y), "depth": float(self.lawn_depth(l.foot[1])) + 0.01,
                        "colour": np.array(ld.hex_rgb(l.light.get("color", "#FFB060"))),
                        "radius": float(l.light.get("radius", 0.08)) * self.w,
                        "intensity": float(l.light.get("intensity", 1.0))})
        return out
