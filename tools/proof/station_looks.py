#!/usr/bin/env python3
"""Proof 1 of docs/design/feel-and-world-v1.md: a station wears its own level.

Cuts a station's painted look (tea stall, garden) out of one Home plate and composites it into another,
in both directions (richer look on an early plate, humbler look on a later one), day and night, then
renders stills at 1206 x 2622 at the Map distance, the island fit and a 2.7 pt per unit near cap.
Script only: the shipped plates (2048 x 3072 HEIC, `World.xcassets`) are read and nothing is written to
the repository. Needs pillow-heif (tools/plate/requirements.txt), numpy, scipy and opencv.

    python3 -I tools/proof/station_looks.py build OUT_DIR        # mattes, matrix sheets, the stills
    python3 -I tools/proof/station_looks.py polys LIGHT OUT.png  # the hand polygons drawn on the plates

Plate stage s is island level 10 - s (stage 0 = level 10, stage 9 = level 1). Polygons are hand data in
plate pixels of the 2048 x 3072 texture (twice `plateSize` of plate-home.json), read off 1:1 crops.
"""
from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw
import pillow_heif

pillow_heif.register_heif_opener()
REPO = Path(__file__).resolve().parents[2]
ASSETS = REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
SCREEN = (1206, 2622)
UNIT = 999.4  # device px of the plate's width per pt-per-unit (Pofu 83.4 of 1024 px is 27 units wide)
SCALES = {"far": 0.76, "mid": 0.9 * 1206 / UNIT, "near": 2.7}  # Map; island 0.9 screen widths; near cap
FEATHER = 2.5

# station -> stage -> polygon (2048 x 3072 plate px). Looks are the stages named in LOOKS.
POLYS = {
    "tea": {
        0: [(1470, 1296), (1515, 1322), (1536, 1348), (1498, 1360), (1527, 1400), (1525, 1430), (1513, 1440),
            (1514, 1485), (1545, 1495), (1548, 1560), (1535, 1585), (1532, 1630), (1525, 1660), (1480, 1672),
            (1440, 1690), (1385, 1692), (1340, 1680), (1300, 1668), (1260, 1665), (1255, 1630), (1258, 1604),
            (1272, 1592), (1281, 1560), (1281, 1470), (1278, 1430), (1268, 1405), (1300, 1385), (1380, 1360), (1440, 1360),
            (1474, 1362)],
        3: [(1305, 1362), (1475, 1368), (1507, 1425), (1496, 1440), (1496, 1500), (1500, 1540), (1525, 1600),
            (1522, 1650), (1480, 1668), (1420, 1672), (1400, 1690), (1345, 1690), (1330, 1665), (1300, 1665),
            (1262, 1660), (1258, 1620), (1262, 1590), (1275, 1500), (1278, 1440), (1262, 1430)],
        6: [(1290, 1388), (1485, 1398), (1505, 1430), (1500, 1458), (1486, 1470), (1488, 1600), (1490, 1650),
            (1470, 1670), (1400, 1678), (1320, 1680), (1270, 1665), (1262, 1600), (1272, 1570), (1278, 1450),
            (1245, 1435), (1250, 1415)],
        7: [(1320, 1365), (1490, 1368), (1506, 1400), (1498, 1430), (1490, 1470), (1500, 1570), (1505, 1600),
            (1480, 1655), (1400, 1668), (1335, 1658), (1265, 1628), (1258, 1590), (1262, 1560), (1282, 1425),
            (1262, 1418), (1285, 1385)],
    },
    "garden": {
        0: [(150, 1350), (240, 1345), (300, 1395), (320, 1470), (345, 1520), (395, 1560), (415, 1600), (405, 1640),
            (380, 1668), (300, 1690), (170, 1690), (60, 1690), (25, 1650), (30, 1590), (30, 1520), (75, 1450),
            (110, 1390)],
        3: [(130, 1360), (220, 1325), (330, 1318), (400, 1355), (405, 1400), (405, 1470), (410, 1560), (415, 1585),
            (405, 1640), (385, 1670), (300, 1692), (180, 1692), (100, 1680), (65, 1650), (80, 1590), (110, 1500),
            (120, 1420)],
        6: [(130, 1350), (230, 1335), (300, 1340), (345, 1380), (415, 1370), (450, 1400), (455, 1520), (470, 1560),
            (465, 1640), (430, 1690), (300, 1700), (200, 1695), (90, 1690), (35, 1650), (45, 1600), (55, 1530),
            (50, 1470), (70, 1420), (100, 1380)],
    },
}
# Sky and hill seen through the stall between its posts (hand seeds, plate px): cut as well, the host shows its own.
SEEDS = {"tea": {6: [(1420, 1472, 26), (1455, 1470, 26), (1335, 1462, 26), (1460, 1510, 34), (1450, 1535, 34), (1462, 1556, 34)], 7: [(1400, 1440, 24), (1440, 1450, 24), (1330, 1440, 24)]}}
ROI = {"tea": (1180, 1250, 1620, 1730), "garden": (0, 1290, 520, 1730)}  # x0, y0, x1, y1
DONORS = {"tea": [7, 6, 3], "garden": [6, 3]}  # plates whose own look does not cover a pixel fill a hole with it
NEAR_CENTRE = {"tea": (1400, 1540), "garden": (230, 1520)}
ISLAND_CENTRE = (1023, 1668)  # islandBox of plate-home.json, doubled


def plate(light: str, stage: int) -> np.ndarray:
    p = ASSETS / f"world-home-plate-{light}-{stage}.imageset/world-home-plate-{light}-{stage}.heic"
    return np.asarray(Image.open(p).convert("RGB"), np.float32) / 255.0


def pocket_cut(img: np.ndarray, m: np.ndarray, seeds) -> np.ndarray:
    """Flood fill from the seeds, inside the polygon only: what is seen through the stall."""
    i8 = (np.clip(img, 0, 1) * 255).astype(np.uint8)
    h, w = m.shape
    lock = np.zeros((h + 2, w + 2), np.uint8)
    lock[1:-1, 1:-1] = (m < 0.5).astype(np.uint8)  # 1 = may not enter
    for x, y, tol in seeds:
        cv2.floodFill(i8, lock, (x, y), 0, (tol,) * 3, (tol,) * 3, 4 | (255 << 8) | cv2.FLOODFILL_MASK_ONLY | cv2.FLOODFILL_FIXED_RANGE)
    cut = (lock[1:-1, 1:-1] == 255).astype(np.float32) * (m >= 0.5)
    return cv2.GaussianBlur(cut, (0, 0), 1.5)


def poly_matte(station: str, stage: int, shape: tuple[int, int]) -> np.ndarray:
    """The hand polygon as a 0..1 matte, edge softened, full plate size."""
    img = Image.new("L", (shape[1], shape[0]), 0)
    ImageDraw.Draw(img).polygon(POLYS[station][stage], fill=255)
    return cv2.GaussianBlur(np.asarray(img, np.float32) / 255.0, (0, 0), FEATHER)


def look_matte(station: str, light: str, stage: int, cache: dict) -> np.ndarray:
    """The clean matte of a station's look on one plate, ROI sized: polygon, minus the sky around it
    and what is seen through it. Cached."""
    key = ("matte", station, light, stage)
    if key not in cache:
        img = get_plate(light, stage, cache)
        x0, y0, x1, y1 = ROI[station]
        m = poly_matte(station, stage, img.shape[:2])[y0:y1, x0:x1]
        im = img[y0:y1, x0:x1]
        if station == "tea":
            m = m * (1 - sky_cut(im, m))
            if stage in SEEDS[station]:
                m = m * (1 - pocket_cut(im, m, [(x - x0, y - y0, t) for x, y, t in SEEDS[station][stage]]))
        cache[key] = m
    return cache[key]


def get_plate(light: str, stage: int, cache: dict) -> np.ndarray:
    if (light, stage) not in cache:
        cache[(light, stage)] = plate(light, stage)
    return cache[(light, stage)]


def sky_cut(img: np.ndarray, m: np.ndarray, tol: float = 0.11) -> np.ndarray:
    """Sky-coloured pixels inside the polygon that connect to sky outside it are not the object: 0..1 to remove.
    (Pockets of sky closed in by the object, between the posts, stay: the host's sky is the same sky.)"""
    blue = img[..., 2] - (img[..., 0] + img[..., 1]) / 2
    outer = (grow(m, 16) - grow(m, 6) > 0.5) & (blue > 0.08)
    if outer.sum() < 50:
        return np.zeros_like(m)
    ref = np.median(img[outer], 0)
    near = (np.abs(img - ref).max(-1) < tol) & (blue > 0.05)
    cand = (near | outer).astype(np.uint8)
    n, lab = cv2.connectedComponents(cand, connectivity=4)
    keep = np.unique(lab[outer]); keep = keep[keep > 0]
    sky = np.isin(lab, keep).astype(np.float32)
    sky = cv2.erode(sky, np.ones((3, 3), np.uint8))  # keep the object's outline pixels
    return cv2.GaussianBlur(sky, (0, 0), 1.5)


def grow(m: np.ndarray, px: int) -> np.ndarray:
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * px + 1, 2 * px + 1))
    return cv2.dilate(m, k)


def ring_gain(a: np.ndarray, b: np.ndarray, ring: np.ndarray) -> np.ndarray:
    """Per-channel gain taking `a` to `b` over the ring pixels (median of the ratio), clamped."""
    sel = ring > 0.5
    if sel.sum() < 200:
        return np.ones(3, np.float32)
    g = np.median(b[sel], 0) / np.maximum(np.median(a[sel], 0), 1e-3)
    return np.clip(g, 0.9, 1.1).astype(np.float32)


def sky_offset(host: np.ndarray, donor: np.ndarray, exclude: np.ndarray) -> np.ndarray:
    """A smooth quadratic fit, per channel, of (host - donor) over the pixels where both are sky and outside
    `exclude`. Added to the donor's sky it makes the donor's sky the host's sky, with the donor's own structure
    (the horizon glow) kept. Same shape as the inputs; zeros when too few pixels."""
    def is_sky(a):
        return (a[..., 2] - (a[..., 0] + a[..., 1]) / 2) > 0.1
    h, w = host.shape[:2]
    both = is_sky(host) & is_sky(donor) & (exclude < 0.01)
    sub = np.zeros_like(both)
    sub[::3, ::3] = True
    ok = both & sub
    if ok.sum() < 300:
        return np.zeros_like(host)
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    x, y = xs / w, ys / h
    A = np.stack([np.ones_like(x), x, y, x * x, x * y, y * y], -1)
    coef = np.linalg.lstsq(A[ok], (host - donor)[ok], rcond=None)[0]
    return (A.reshape(-1, 6) @ coef).reshape(h, w, 3)


def composite(station: str, light: str, host: int, look: int, cache: dict):
    """The host plate with its own `station` look removed and the look of plate `look` put in.
    The removed look's hole is filled from donor plates (where their own look is not), then by inpainting."""
    P = lambda st: get_plate(light, st, cache)
    x0, y0, x1, y1 = ROI[station]
    sl = (slice(y0, y1), slice(x0, x1))
    hostp = P(host)[sl]
    full = P(host).copy()
    if host == look:
        return full, {"hole": 0.0}
    mh, ml = look_matte(station, light, host, cache), look_matte(station, light, look, cache)
    hole = np.clip(grow(mh, 5) - ml, 0, 1)
    hole = np.clip(cv2.GaussianBlur(grow(hole, 4), (0, 0), 2.5) * 1.2, 0, 1)
    ring = np.clip(grow(mh, 40) - grow(mh, 12), 0, 1) * (1 - grow(ml, 12))
    excl = np.maximum(grow(mh, 10), grow(ml, 10))
    fill, filled = hostp.copy(), np.zeros(hostp.shape[:2], np.float32)
    for d in DONORS[station]:
        if d == host:
            continue
        free = 1 - grow(look_matte(station, light, d, cache), 3)
        take = np.clip(free - filled, 0, 1) * (hole > 0.02)
        if take.sum() < 1:
            continue
        dp = P(d)[sl]
        dp = dp * ring_gain(dp, hostp, ring)
        if station == "tea":  # the donor's sky, shifted to the host's sky
            dsky = ((dp[..., 2] - (dp[..., 0] + dp[..., 1]) / 2) > 0.1).astype(np.float32)
            dsky = cv2.GaussianBlur(dsky, (0, 0), 2)[..., None]
            dp = dp + sky_offset(hostp, dp, excl) * dsky
        fill = fill * (1 - take[..., None]) + dp * take[..., None]
        filled = np.clip(filled + take, 0, 1)
    rest = ((hole > 0.02) & (filled < 0.5)).astype(np.uint8) * 255
    if rest.any():
        f8 = (np.clip(fill, 0, 1) * 255).astype(np.uint8)
        fill = cv2.inpaint(f8, rest, 6, cv2.INPAINT_TELEA).astype(np.float32) / 255.0
    out = hostp * (1 - hole[..., None]) + fill * hole[..., None]
    lp = P(look)[sl]
    gain = ring_gain(lp, hostp, ring)
    out = out * (1 - ml[..., None]) + lp * ml[..., None]  # the look is not re-lit: `gain` is only reported
    full[sl] = np.clip(out, 0, 1)
    return full, {"hole_px": int((hole > 0.5).sum()), "inpainted_px": int((rest > 0).sum()), "gain": [round(float(g), 3) for g in gain]}


# ------------------------------------------------------------------ camera

def extend(img: np.ndarray, top: int, bottom: int, side: int) -> np.ndarray:
    """The plate with sky margins: edge rows and columns repeated and smoothed, so a far frame has a backdrop.
    Not the real sky stack; the proof is about the station."""
    h, w = img.shape[:2]
    big = cv2.copyMakeBorder(img, top, bottom, side, side, cv2.BORDER_REPLICATE)
    soft = cv2.GaussianBlur(big, (0, 0), 90)
    keep = np.zeros(big.shape[:2], np.float32)
    keep[top:top + h, side:side + w] = 1
    keep = cv2.GaussianBlur(keep, (0, 0), 6)
    keep[top + 12:top + h - 12, side + 12:side + w - 12] = 1
    return big * keep[..., None] + soft * (1 - keep[..., None])


def frame(img: np.ndarray, scale: float, centre: tuple[float, float], lock_x: bool = False) -> np.ndarray:
    """One 1206 x 2622 frame: the plate drawn at `scale` pt per unit, `centre` (plate px) at the screen centre."""
    h, w = img.shape[:2]
    f = UNIT * scale / w
    sw, sh = SCREEN
    cx, cy = centre
    if lock_x:
        half = sw / 2 / f
        cx = min(max(cx, half), w - half)
    need_x = int(max(0, (sw / 2 / f) - cx, (sw / 2 / f) - (w - cx)) + 4)
    need_t = int(max(0, sh / 2 / f - cy) + 4)
    need_b = int(max(0, sh / 2 / f - (h - cy)) + 4)
    big = extend(img, need_t, need_b, need_x) if (need_x or need_t or need_b) else img
    cx, cy = cx + need_x, cy + need_t
    src = big.astype(np.float32)
    if f < 1:
        src = cv2.resize(src, None, fx=f, fy=f, interpolation=cv2.INTER_AREA)
        cx, cy, f2 = cx * f, cy * f, 1.0
    else:
        f2 = f
    M = np.float32([[f2, 0, sw / 2 - cx * f2], [0, f2, sh / 2 - cy * f2]])
    out = cv2.warpAffine(src, M, (sw, sh), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    return np.clip(out, 0, 1)


def save(a: np.ndarray, path: Path) -> None:
    Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)).save(path)


# ------------------------------------------------------------------ drivers

# (still name, station, host stage, look stage)
STILLS = [
    ("tea-rich-on-early", "tea", 7, 0),
    ("tea-humble-on-late", "tea", 0, 6),
    ("garden-humble-on-late", "garden", 0, 6),
]


def sheet_matrix(station: str, light: str, out: Path, cache: dict) -> None:
    stages = sorted(POLYS[station])
    x0, y0, x1, y1 = ROI[station]
    w, h = x1 - x0, y1 - y0
    S = Image.new("RGB", (w * (len(stages) + 1), h * len(stages)), "white")
    for r, host in enumerate(stages):
        S.paste(Image.fromarray((plate(light, host)[y0:y1, x0:x1] * 255).astype(np.uint8)), (0, r * h)) if False else None
        for c, look in enumerate(stages):
            img, _ = composite(station, light, host, look, cache)
            S.paste(Image.fromarray((img[y0:y1, x0:x1] * 255).astype(np.uint8)), (c * w, r * h))
    S.crop((0, 0, w * len(stages), h * len(stages))).save(out)


def build(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    cache: dict = {}
    for light in ("day", "night"):
        for st in ("tea", "garden"):
            sheet_matrix(st, light, out / f"matrix-{st}-{light}.png", cache)
        for name, st, host, look in STILLS:
            img, info = composite(st, light, host, look, cache)
            print(light, name, info)
            for dist, s in SCALES.items():
                if dist == "near":
                    c, lock = NEAR_CENTRE[st], True
                else:
                    c, lock = ISLAND_CENTRE, False
                save(frame(img, s, c, lock), out / f"{name}-{light}-{dist}.png")
            save(img[slice(ROI[st][1], ROI[st][3]), slice(ROI[st][0], ROI[st][2])], out / f"crop-{name}-{light}.png")


def polys(light: str, out: Path) -> None:
    ims = []
    for st, per in POLYS.items():
        x0, y0, x1, y1 = ROI[st]
        for s, pts in per.items():
            im = Image.fromarray((plate(light, s) * 255).astype(np.uint8))
            ImageDraw.Draw(im).line(pts + [pts[0]], fill=(255, 0, 0), width=2)
            ims.append(im.crop((x0, y0, x1, y1)))
    w = max(i.width for i in ims)
    h = max(i.height for i in ims)
    S = Image.new("RGB", (w * 4, h * 2), "white")
    for i, im in enumerate(ims):
        S.paste(im, ((i % 4) * w, (i // 4) * h))
    S.save(out)


if __name__ == "__main__":
    if len(sys.argv) >= 3 and sys.argv[1] == "build":
        build(Path(sys.argv[2]))
    elif len(sys.argv) >= 4 and sys.argv[1] == "polys":
        polys(sys.argv[2], Path(sys.argv[3]))
    else:
        raise SystemExit(__doc__)
