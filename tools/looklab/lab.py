"""Look lab, shared parts: image IO, CIELAB, the three comparison numbers, region boxes, sheets.

The numbers every experiment reports against its reference (docs/research/look-lab.md section 2):

  dE      mean CIEDE2000 between the mean Lab of matching regions (sky, back row, focal row,
          earth face, cloud sea; boxes in `regions.json`, per image kind). Two pictures with
          different content cannot be compared pixel by pixel; their regions can.
  hist    Wasserstein-1 distance between the L* histograms of the island (back + focal + earth
          boxes), in L* units: how far the value distributions sit apart.
  bf      local contrast of the back row over the focal row (RMS of L* minus its blur at 1 % of
          the frame height): 1.0 means the back row is as crisp as the front.

Everything is numpy + Pillow + scipy; deterministic (fixed seeds).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
sys.path.insert(0, str(REPO / "tools" / "assets"))
import style_lock as sl  # noqa: E402

TAKES = REPO / "design" / "art" / "takes"
REGIONS = json.loads((HERE / "regions.json").read_text())
REF = {
    "day": [TAKES / "batch-25-seasons/x-season-summer/plate__x-season-summer--t2.webp"],
    "golden": [TAKES / "batch-25-seasons/x-season-summer-evening/plate__x-season-summer-evening--t2.webp"],
    "rain": [TAKES / "batch-25-seasons/x-season-rain/plate__x-season-rain--t1.webp"],
    # A calmer night than the Tam Cicek night key: the Gezgin whale, Revontuli and I1 snow night.
    "night": [TAKES / "batch-22-gezgin-forms/x-gezgin-f2-night/plate__x-gezgin-f2-night--t1.webp",
              TAKES / "batch-34-islands-in-game/x-revontuli-stuck/plate__x-revontuli-stuck--t1.webp",
              TAKES / "batch-25-seasons/x-season-snow-night/plate__x-season-snow-night--t1.webp"],
}
REGION_NAMES = ["sky", "back", "focal", "earth", "sea"]


# ---------------------------------------------------------------- io

def load_rgb(path: Path | str, width: int | None = None) -> np.ndarray:
    im = Image.open(path).convert("RGB")
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.Resampling.LANCZOS)
    return np.asarray(im, dtype=np.float64) / 255


def to_img(rgb: np.ndarray) -> Image.Image:
    return Image.fromarray(np.uint8(np.clip(rgb, 0, 1) * 255 + 0.5))


def lab(rgb: np.ndarray) -> np.ndarray:
    return sl.srgb_to_lab(np.clip(rgb, 0, 1))


def rgb_of(labv: np.ndarray) -> np.ndarray:
    return sl.lab_to_srgb(labv)


def to_lin(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.04045, x / 12.92, ((x + 0.055) / 1.055) ** 2.4)


def to_srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, 12.92 * x, 1.055 * np.power(x, 1 / 2.4) - 0.055)


def luma(rgb):
    return rgb @ np.array([0.2126, 0.7152, 0.0722])


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- CIEDE2000

def de2000(lab1: np.ndarray, lab2: np.ndarray) -> np.ndarray:
    """CIEDE2000 (Sharma 2005), vectorised over the last axis."""
    L1, a1, b1 = np.moveaxis(np.asarray(lab1, float), -1, 0)
    L2, a2, b2 = np.moveaxis(np.asarray(lab2, float), -1, 0)
    C1, C2 = np.hypot(a1, b1), np.hypot(a2, b2)
    Cb7 = ((C1 + C2) / 2) ** 7
    G = 0.5 * (1 - np.sqrt(Cb7 / (Cb7 + 25 ** 7)))
    a1p, a2p = a1 * (1 + G), a2 * (1 + G)
    C1p, C2p = np.hypot(a1p, b1), np.hypot(a2p, b2)
    h1p = np.degrees(np.arctan2(b1, a1p)) % 360
    h2p = np.degrees(np.arctan2(b2, a2p)) % 360
    dLp, dCp = L2 - L1, C2p - C1p
    dh = h2p - h1p
    dh = np.where(dh > 180, dh - 360, np.where(dh < -180, dh + 360, dh))
    dh = np.where(C1p * C2p == 0, 0, dh)
    dHp = 2 * np.sqrt(C1p * C2p) * np.sin(np.radians(dh / 2))
    Lbp, Cbp = (L1 + L2) / 2, (C1p + C2p) / 2
    hs = h1p + h2p
    hbp = np.where(np.abs(h1p - h2p) > 180, np.where(hs < 360, hs + 360, hs - 360) / 2, hs / 2)
    hbp = np.where(C1p * C2p == 0, hs, hbp)
    T = (1 - 0.17 * np.cos(np.radians(hbp - 30)) + 0.24 * np.cos(np.radians(2 * hbp))
         + 0.32 * np.cos(np.radians(3 * hbp + 6)) - 0.20 * np.cos(np.radians(4 * hbp - 63)))
    dth = 30 * np.exp(-(((hbp - 275) / 25) ** 2))
    Cb7p = Cbp ** 7
    Rc = 2 * np.sqrt(Cb7p / (Cb7p + 25 ** 7))
    Sl = 1 + 0.015 * (Lbp - 50) ** 2 / np.sqrt(20 + (Lbp - 50) ** 2)
    Sc, Sh = 1 + 0.045 * Cbp, 1 + 0.015 * Cbp * T
    Rt = -np.sin(np.radians(2 * dth)) * Rc
    return np.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))


# ---------------------------------------------------------------- regions and numbers

def kind_of(path_or_kind: str | Path) -> str:
    s = str(path_or_kind)
    for k in REGIONS:
        if k != "$note" and k in s:
            return k
    raise KeyError(f"no region boxes for {s}")


def region_mask(shape, kind: str, name: str) -> np.ndarray | None:
    boxes = REGIONS[kind].get(name)
    if not boxes:
        return None
    h, w = shape[:2]
    m = np.zeros((h, w), bool)
    for x0, y0, x1, y1 in boxes:
        m[int(y0 * h):int(y1 * h), int(x0 * w):int(x1 * w)] = True
    return m


def local_contrast(L: np.ndarray) -> np.ndarray:
    s = max(L.shape[0] * 0.01, 1.0)
    return (L - ndimage.gaussian_filter(L, s)) ** 2


def stats(rgb: np.ndarray, kind: str) -> dict:
    """Per-region mean Lab, island L* samples and local contrast."""
    lb = lab(rgb)
    lc = local_contrast(lb[..., 0])
    out = {"regions": {}, "island_L": [], "loc": {}}
    for name in REGION_NAMES:
        m = region_mask(rgb.shape, kind, name)
        if m is None or not m.any():
            continue
        out["regions"][name] = lb[m].mean(axis=0)
        out["loc"][name] = float(np.sqrt(lc[m].mean()))
        if name in ("back", "focal", "earth"):
            out["island_L"].append(lb[..., 0][m])
    out["island_L"] = np.concatenate(out["island_L"]) if out["island_L"] else np.zeros(1)
    return out


def pooled(stat_list: list[dict]) -> dict:
    """Several references as one target: mean region colours, pooled L* samples, mean contrast."""
    out = {"regions": {}, "island_L": np.concatenate([s["island_L"] for s in stat_list]), "loc": {}}
    for name in REGION_NAMES:
        vals = [s["regions"][name] for s in stat_list if name in s["regions"]]
        if vals:
            out["regions"][name] = np.mean(vals, axis=0)
        locs = [s["loc"][name] for s in stat_list if name in s["loc"]]
        if locs:
            out["loc"][name] = float(np.mean(locs))
    return out


def wasserstein(a: np.ndarray, b: np.ndarray, n: int = 256) -> float:
    q = (np.arange(n) + 0.5) / n
    return float(np.mean(np.abs(np.quantile(a, q) - np.quantile(b, q))))


def compare(s: dict, ref: dict) -> dict:
    names = [n for n in REGION_NAMES if n in s["regions"] and n in ref["regions"]]
    de = {n: float(de2000(s["regions"][n], ref["regions"][n])) for n in names}
    bf = s["loc"].get("back", 0) / max(s["loc"].get("focal", 1e-6), 1e-6)
    return {"dE": round(float(np.mean(list(de.values()))), 1), "dE_regions": {k: round(v, 1) for k, v in de.items()},
            "hist": round(wasserstein(s["island_L"], ref["island_L"]), 1), "bf": round(bf, 2)}


def ref_stats(state: str, width: int = 1024) -> dict:
    return pooled([stats(load_rgb(p, width), kind_of(p)) for p in REF[state]])


def ref_bf(ref: dict) -> float:
    return round(ref["loc"].get("back", 0) / max(ref["loc"].get("focal", 1e-6), 1e-6), 2)


def fmt(c: dict) -> str:
    return f"dE {c['dE']}  hist {c['hist']}  b/f {c['bf']}"


# ---------------------------------------------------------------- sheets

def font(size: int):
    for p in ("/usr/share/fonts/opentype/inter/Inter-Medium.otf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


PAPER = (246, 242, 236)
INK = (40, 36, 48)


def sheet(rows: list[list[tuple[Image.Image, str]]], out: Path, title: str = "", cell_h: int = 300,
          max_kb: int = 380, row_labels: list[str] | None = None) -> None:
    """A grid: each cell an image with a caption under it, rows fitted to one height."""
    f, fs = font(17), font(14)
    pad, lab_w = 8, (90 if row_labels else 0)
    cap = 6 + 17 * max(c.count("\n") + 1 for r in rows for _, c in r)
    widths = [sum(round(im.width * cell_h / im.height) for im, _ in r) + pad * (len(r) + 1) for r in rows]
    W = max(widths) + lab_w
    H = (cell_h + cap + pad) * len(rows) + pad + (34 if title else 0)
    can = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(can)
    y = pad
    if title:
        d.text((pad, 6), title, fill=INK, font=f)
        y += 34
    for ri, r in enumerate(rows):
        x = pad + lab_w
        if row_labels:
            d.text((pad, y + cell_h // 2 - 10), row_labels[ri], fill=INK, font=f)
        for im, caption in r:
            w = round(im.width * cell_h / im.height)
            can.paste(im.convert("RGB").resize((w, cell_h), Image.Resampling.LANCZOS), (x, y))
            d.multiline_text((x, y + cell_h + 3), caption, fill=INK, font=fs, spacing=2)
            x += w + pad
        y += cell_h + cap + pad
    out.parent.mkdir(parents=True, exist_ok=True)
    scale = 1.0
    while True:
        im = can if scale == 1.0 else can.resize((round(W * scale), round(H * scale)), Image.Resampling.LANCZOS)
        for q in (88, 82, 76, 70):
            im.save(out, quality=q, optimize=True)
            if out.stat().st_size <= max_kb * 1024:
                return
        scale *= 0.85
