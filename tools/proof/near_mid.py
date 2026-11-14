#!/usr/bin/env python3
"""Proof 2 of docs/design/feel-and-world-v1.md: the near look and the mid fit.

Renders 1206 x 2622 stills from art already in the repository: the Home plate
(day and night), its backdrop, Pofu's art, Mochi's art and the sprite-island
dressing. No Swift, no new art. Run:

    python3 tools/proof/near_mid.py --out <dir>

Needs Pillow, pillow-heif, numpy and scipy. Coordinates are plate points
(1024 x 1536); the texture is 2x that. Camera scale `s` is device pixels per
plate point: pt/unit x 3 x 0.3253 units per plate point.
"""
import argparse
import json
import math
import pathlib
import subprocess

import numpy as np
import pillow_heif
from PIL import Image
from scipy.ndimage import gaussian_filter

pillow_heif.register_heif_opener()

W, H = 1206, 2622
UPP = 0.3253                      # world units per plate point (facts doc)
def s_of(pt_per_unit): return pt_per_unit * 3 * UPP

ROOT = pathlib.Path(subprocess.check_output(
    ["git", "rev-parse", "--show-toplevel"], cwd=pathlib.Path(__file__).parent, text=True).strip())
SRC = ROOT / "Packages/PofuKit/Sources"
XC = SRC / "PofuWorld/Resources/World.xcassets"
cfg = json.load(open(SRC / "PofuWorld/Resources/Plates/plate-home.json"))
BACKDROP_BOX = cfg["backdropBox"]            # x0, y0, x1, y1 in plate points
ISLAND = cfg["islandBox"]
POFU_FEET = cfg["characters"]["pofu"]
MOCHI_FEET = cfg["characters"]["mochi"]
POFU_W = cfg["pofuWidth"]                    # plate points, art bbox width
MOCHI_W = 58.0                               # estimate: same px/pt as Pofu's art (see hand-back)


def load(path): return Image.open(path).convert("RGBA")
def xc(name): return load(XC / f"{name}.imageset" / f"{name}.png")
def tight(im): return im.crop(im.getchannel("A").getbbox())


def place(canvas, img, box, cx, cy, s):
    """Draw img over plate-point `box` into the device canvas, camera (cx, cy) at scale s."""
    x0, y0, x1, y1 = box
    d0x, d1x = (x0 - cx) * s + W / 2, (x1 - cx) * s + W / 2
    d0y, d1y = (y0 - cy) * s + H / 2, (y1 - cy) * s + H / 2
    vx0, vx1 = max(0, math.floor(d0x)), min(W, math.ceil(d1x))
    vy0, vy1 = max(0, math.floor(d0y)), min(H, math.ceil(d1y))
    if vx1 <= vx0 or vy1 <= vy0:
        return
    fx = img.width / (d1x - d0x)
    fy = img.height / (d1y - d0y)
    sb = (max(0, (vx0 - d0x) * fx), max(0, (vy0 - d0y) * fy),
          min(img.width, (vx1 - d0x) * fx), min(img.height, (vy1 - d0y) * fy))
    res = Image.LANCZOS if fx > 1 else Image.BICUBIC
    tile = img.resize((vx1 - vx0, vy1 - vy0), res, box=sb)
    canvas.alpha_composite(tile, (vx0, vy0))


_cache = {}
def ground(light, cx, cy, s):
    key = light
    if key not in _cache:
        plate = Image.open(XC / f"world-home-plate-{light}-0.imageset/world-home-plate-{light}-0.heic").convert("RGBA")
        bd = Image.open(XC / f"world-home-backdrop-{light}-0.imageset/world-home-backdrop-{light}-0.jpg").convert("RGBA")
        _cache[key] = (plate, bd)
    plate, bd = _cache[key]
    c = Image.new("RGBA", (W, H), tuple(np.array(bd.resize((1, 1), Image.BOX))[0, 0]))
    place(c, bd, BACKDROP_BOX, cx, cy, s)
    place(c, plate, (0, 0, 1024, 1536), cx, cy, s)
    return c


def depth_blur(img, yf, sigmas=(2.5, 6, 10, 16, 24), up=1100, down=700):
    """Out-of-focus ground: sharpest on the row `yf`, more blur above (far) and below (near)."""
    a = np.asarray(img.convert("RGB"), np.float32)
    levels = [a if sg == 0 else gaussian_filter(a, (sg, sg, 0)) for sg in sigmas]
    y = np.arange(H, dtype=np.float32)
    t = np.where(y < yf, np.clip((yf - y) / up, 0, 1) ** 0.8, np.clip((y - yf) / down, 0, 1) ** 0.8)
    pos = t * (len(sigmas) - 1)
    lo = np.floor(pos).astype(int).clip(0, len(sigmas) - 2)
    fr = (pos - lo)[:, None, None]
    out = np.empty_like(a)
    for i in range(len(sigmas) - 1):
        m = lo == i
        out[m] = levels[i][m] * (1 - fr[m]) + levels[i + 1][m] * fr[m]
    return Image.fromarray(out.clip(0, 255).astype(np.uint8)).convert("RGBA")


NIGHT = np.array([0.60, 0.68, 0.98], np.float32)
def grade(im, light):
    if light != "night":
        return im
    a = np.asarray(im, np.float32).copy()
    a[..., :3] = a[..., :3] * NIGHT * 0.82
    return Image.fromarray(a.clip(0, 255).astype(np.uint8))


def shadow(canvas, fx, fy, w, light, strength=0.40):
    lay = Image.new("L", (W, H), 0)
    ys, xs = np.mgrid[0:H, 0:W].astype(np.float32)
    rx, ry = w * 0.46, w * 0.075
    e = ((xs - fx) / rx) ** 2 + ((ys - (fy - ry * 0.2)) / ry) ** 2
    a = np.clip(1 - e, 0, 1) ** 0.7 * strength * 255
    lay = Image.fromarray(a.astype(np.uint8)).filter(__import__("PIL.ImageFilter", fromlist=["x"]).GaussianBlur(max(2, w * 0.02)))
    col = (28, 40, 20) if light != "night" else (8, 12, 34)
    sh = Image.new("RGBA", (W, H), col + (0,))
    sh.putalpha(lay)
    canvas.alpha_composite(sh)


def stand(canvas, art, fx, fy, width_px, light, blur=0, shadow_k=0.40):
    """Paste tight art with its bottom-centre at device (fx, fy), bbox `width_px` wide."""
    art = tight(art)
    h = round(width_px * art.height / art.width)
    im = grade(art.resize((round(width_px), h), Image.LANCZOS), light)
    if blur:
        sh_lay = Image.new("RGBA", (W, H))
        shadow(sh_lay, fx, fy, width_px, light, shadow_k)
        sh_lay = sh_lay.filter(__import__("PIL.ImageFilter", fromlist=["x"]).GaussianBlur(blur))
        canvas.alpha_composite(sh_lay)
        pad = int(blur * 3)
        big = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad))
        big.paste(im, (pad, pad))
        im = big.filter(__import__("PIL.ImageFilter", fromlist=["x"]).GaussianBlur(blur))
        canvas.alpha_composite(im, (round(fx - im.width / 2), round(fy - im.height + pad)))
    else:
        shadow(canvas, fx, fy, width_px, light, shadow_k)
        canvas.alpha_composite(im, (round(fx - im.width / 2), round(fy - im.height)))


def grain(img, amount=1.6, seed=7):
    a = np.asarray(img.convert("RGB"), np.float32)
    n = np.random.default_rng(seed).normal(0, amount, (H, W, 1)).astype(np.float32)
    return Image.fromarray((a + n).clip(0, 255).astype(np.uint8))


# ---- art ---------------------------------------------------------------------
POFU = load(SRC / "PofuCompanion/Resources/pofu-hamster.png")
MOCHI = load(SRC / "PofuGames/Resources/garden-mochi.png")
def match(im):
    """The sprite-island dressing is flatter than the plate paint: lift its saturation and light."""
    a = np.asarray(im, np.float32).copy()
    g = a[..., :3].mean(-1, keepdims=True)
    a[..., :3] = (g + (a[..., :3] - g) * 1.45) * 1.10
    return Image.fromarray(a.clip(0, 255).astype(np.uint8))
def dress(n): return match(xc(f"world-dressing-{n}"))
WILD, WILD2, TUFT, TUFT3, PEB, PEB3, MUSH, CAN = (
    dress("wildflowers"), dress("wildflowers-3"), dress("grass-tuft-2"), dress("grass-tuft-4"),
    dress("pebbles"), dress("pebbles-3"), dress("mushroom-ring"), dress("watering-can"))

# (art, dx, dy from the character's feet in px, width px, blur sigma). Sharp ones sit on the
# focal row; blurred ones stand in front of and behind it. Sprite-island dressing is the stand-in
# for the Codex props; it is smaller and flatter than the plate paint (see defects).
DRESSING = {
    "pofu": [(MUSH, -330, -170, 150, 9), (WILD, -400, 30, 250, 0), (PEB, 330, 70, 230, 0),
             (TUFT, 250, -120, 210, 4), (TUFT3, -150, 260, 300, 7), (WILD2, 440, 420, 520, 20),
             (TUFT, -440, 600, 430, 14)],
    "mochi": [(MUSH, 340, -170, 150, 9), (WILD2, 400, 30, 250, 0), (PEB3, -330, 70, 240, 0),
              (TUFT3, -250, -130, 210, 4), (TUFT, 150, 260, 300, 7), (WILD, -440, 420, 520, 20),
              (TUFT3, 440, 600, 430, 14)],
}


def near(who, light, pt_per_unit, look, feet_y=0.64, fixed=False):
    """look: raw | macro | dress.  `raw` and the 2.7 cap draw the plate as it is."""
    feet = POFU_FEET if who == "pofu" else MOCHI_FEET
    art, wpl = (POFU, POFU_W) if who == "pofu" else (MOCHI, MOCHI_W)
    if who == "mochi" and not fixed:      # Mochi is the subject: half the screen wide, like Pofu, so the camera is closer
        pt_per_unit *= POFU_W / MOCHI_W
    s = s_of(pt_per_unit)
    fy = feet_y * H
    cx, cy = feet[0], feet[1] - (fy - H / 2) / s
    g = ground(light, cx, cy, s)
    if look in ("macro", "dress"):
        g = depth_blur(g, fy)
    fx = W / 2
    if look == "dress":
        far = [d for d in DRESSING[who] if d[2] < 0]
        nearer = [d for d in DRESSING[who] if d[2] >= 0]
        for sp, dx, dy, w, bl in far:
            stand(g, sp, fx + dx, fy + dy, w, light, bl, 0.25)
    stand(g, art, fx, fy, wpl * s, light)
    if look == "dress":
        for sp, dx, dy, w, bl in nearer:
            stand(g, sp, fx + dx, fy + dy, w, light, bl, 0.30)
    return grain(g, 1.4 if look != "raw" else 0.0) if look != "raw" else g.convert("RGB")


def mid(widths, light="day"):
    isl_w = ISLAND[2] - ISLAND[0]
    s = widths * W / isl_w
    cx, cy = (ISLAND[0] + ISLAND[2]) / 2, (ISLAND[1] + ISLAND[3]) / 2 + 40
    g = ground(light, cx, cy, s)
    for feet, art, w in ((MOCHI_FEET, MOCHI, MOCHI_W), (POFU_FEET, POFU, POFU_W)):
        fx, fy = (feet[0] - cx) * s + W / 2, (feet[1] - cy) * s + H / 2
        stand(g, art, fx, fy, w * s, light, 0, 0.35)
    return g.convert("RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    o = pathlib.Path(ap.parse_args().out)
    o.mkdir(parents=True, exist_ok=True)
    def save(name, im): im.save(o / f"{name}.png"); print(name)
    for who in ("pofu", "mochi"):
        save(f"near_{who}_a_plate_cap2.7", near(who, "day", 2.7, "raw", fixed=True))
        save(f"near_{who}_a_plate_raw_full", near(who, "day", 7.4, "raw"))
        save(f"near_{who}_b_macro", near(who, "day", 7.4, "macro"))
        save(f"near_{who}_c_macro_dressing", near(who, "day", 7.4, "dress"))
        save(f"night_{who}_b_macro", near(who, "night", 7.4, "macro"))
        save(f"night_{who}_c_macro_dressing", near(who, "night", 7.4, "dress"))
    save("near_pofu_b_macro_4.5", near("pofu", "day", 4.5, "macro"))
    save("mid_day_0.90", mid(0.90))
    save("mid_day_1.15", mid(1.15))


if __name__ == "__main__":
    main()
