#!/usr/bin/env python3
"""The season gate (docs/design/season-system-v1.md section 8): what catches a season picture that does not sit on
the island before the founder sees it.

    python3 -I tools/plate/season_gate.py report [--season NAME]
    python3 -I tools/plate/season_gate.py s1 PARENT PICTURE        # frame held: block shift, plate px
    python3 -I tools/plate/season_gate.py s2 PICTURE MATTE         # outline held (PICTURE has a sky, MATTE the alpha)

Checks S1 to S5 and S8 are functions over two images, or over a state of `plate-home.json`; each returns a dict with
its measures and `ok`. Limits live in `season_gate.json`; a null limit is a measure that prints and never fails.
S6 and S7 are `plate_gate.py`'s. Images are RGBA at the plate texture (2 px per plate point); a shift is in plate
px. Dependencies: numpy, Pillow, OpenCV (pillow-heif for the shipped HEIC).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.append(str(REPO / "tools" / "art"))  # last: tools/art has its own ingest.py
sys.path.insert(0, str(REPO / "tools" / "assets"))
import heic  # noqa: E402
import ingest  # noqa: E402
from process_assets import srgb_to_lab  # noqa: E402

LIMITS = json.loads((HERE / "season_gate.json").read_text())
PLATE_JSON = REPO / "Packages" / "PofuKit" / "Sources" / "PofuWorld" / "Resources" / "Plates" / "plate-home.json"
TEX = 2           # texture px per plate point (the shipped plates)
BLOCK = 96        # plate px: S1's block (192 texture px)
FIT_NOTE = ("not limited: the section 3 fit numbers do not reproduce. Windmill 5.7 here (7.1 over the whole polygon) "
            "against 6.2, tea stall 6.0 (7.5) against 6.3; the scratch scripts' regions are not on file")

NO_SEASONS = "no season is listed in plate-home.json"


# ---------------------------------------------------------------- images

def load_asset(name: str) -> np.ndarray:
    """A shipped layer by catalog name, RGBA float 0..1."""
    folder = ingest.ASSETS / f"{name}.imageset"
    for f in sorted(folder.iterdir()):
        if f.suffix in (".png", ".jpg", heic.SUFFIX):
            return np.asarray(heic.open_image(f).convert("RGBA"), np.float32) / 255
    raise FileNotFoundError(name)


def as_rgba(x) -> np.ndarray:
    if isinstance(x, (str, Path)):
        x = np.asarray(heic.open_image(Path(x)).convert("RGBA"), np.float32) / 255
    x = np.asarray(x, np.float32)
    if x.shape[-1] == 3:
        x = np.concatenate([x, np.ones(x.shape[:2] + (1,), np.float32)], -1)
    return x


def lab(rgb: np.ndarray) -> np.ndarray:
    return srgb_to_lab(np.clip(rgb, 0, 1))


def de(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """CIELAB distance (dE76) between two (N, 3) sRGB arrays."""
    return np.linalg.norm(lab(a) - lab(b), axis=-1)


def poly_mask(shape: tuple[int, int], points, origin=(2, 434)) -> np.ndarray:
    """A polygon in plate points as a mask over a plate texture whose top-left is `origin` plate points."""
    pts = [((x - origin[0]) * TEX, (y - origin[1]) * TEX) for x, y in points]
    return ingest.poly_mask(shape, pts)


def _pct(a, q):
    return float(np.percentile(a, q)) if len(a) else float("nan")


# ---------------------------------------------------------------- S1, S5

def block_shifts(parent, picture, block: int = BLOCK) -> np.ndarray:
    """Phase-correlation shift, in plate px, of each block that is solid in both pictures, on the gradient magnitude of
    the luminance (an edit repaints colour, not the line); blocks are `block` plate px, not overlapping."""
    a, b = as_rgba(parent), as_rgba(picture)
    if a.shape != b.shape:
        raise ValueError(f"the pictures differ in size: {a.shape} against {b.shape}")

    def grad(x):
        g = cv2.cvtColor(x[..., :3], cv2.COLOR_RGB2GRAY)
        return np.hypot(cv2.Sobel(g, cv2.CV_32F, 1, 0), cv2.Sobel(g, cv2.CV_32F, 0, 1))

    ga, gb = grad(a), grad(b)
    solid = np.minimum(a[..., 3], b[..., 3])
    n = block * TEX
    win = cv2.createHanningWindow((n, n), cv2.CV_32F)
    out = []
    for y in range(0, a.shape[0] - n + 1, n):
        for x in range(0, a.shape[1] - n + 1, n):
            if solid[y:y + n, x:x + n].min() < 0.99:
                continue
            pa, pb = ga[y:y + n, x:x + n], gb[y:y + n, x:x + n]
            if pa.std() < 1e-3 or pb.std() < 1e-3:
                continue
            (dx, dy), _ = cv2.phaseCorrelate(pa, pb, win)
            out.append(np.hypot(dx, dy) / TEX)
    return np.array(out)


def s1_frame_held(parent, picture, limit: float | None = None, key: str = "s1") -> dict:
    """S1: the season picture keeps the spring parent's frame (block shift p90 within the limit, plate px). S5 is the
    same measure between a season's day and night picks."""
    s = block_shifts(parent, picture)
    limit = LIMITS[key]["p90"] if limit is None else limit
    if not len(s):
        return {"check": key.upper(), "ok": False, "blocks": 0, "why": "no block is solid in both pictures"}
    p90 = _pct(s, 90)
    return {"check": key.upper(), "ok": p90 <= limit, "blocks": len(s), "median": round(float(np.median(s)), 2),
            "p90": round(p90, 2), "max": round(float(s.max()), 2), "limit": limit}


def s5_night_is_the_days(day, night, limit: float | None = None) -> dict:
    return s1_frame_held(day, night, limit, key="s5")


# ---------------------------------------------------------------- S2

def edge_bands(matte: np.ndarray, band: float) -> tuple[np.ndarray, np.ndarray]:
    """The inside and outside halves of the matte's edge band (`band` plate px each), as masks."""
    solid = (matte > 0.5).astype(np.uint8)
    k = int(round(band * TEX))
    kern = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * k + 1, 2 * k + 1))
    inside = (solid > 0) & (cv2.erode(solid, kern) == 0)
    outside = (solid == 0) & (cv2.dilate(solid, kern) > 0)
    return inside, outside


def local_sky(rgb: np.ndarray, matte: np.ndarray, band: float, sigma: float = 48.0) -> tuple[np.ndarray, np.ndarray]:
    """The picture's own sky colour at every pixel: a normalised blur of the pixels more than `4 x band` plate px
    outside the matte. Returns (colour, weight)."""
    solid = (matte > 0.5).astype(np.uint8)
    k = int(round(4 * band * TEX))
    far = cv2.dilate(solid, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * k + 1, 2 * k + 1))) == 0
    w = far.astype(np.float32)
    s = sigma * TEX
    num = cv2.GaussianBlur(rgb * w[..., None], (0, 0), s)
    den = cv2.GaussianBlur(w, (0, 0), s)
    return num / np.maximum(den[..., None], 1e-6), den


def s2_outline_held(picture, matte, limit: float | None = None, band: float | None = None, sky_dE: float = 6.0, parent=None, ignore=None) -> dict:
    """S2: the share of the matte's (or a look alpha's) edge band where the picture is sky on the inside or paint on
    the outside. `picture` is the season picture with its sky; `matte` the spring alpha, same size, 0..1. Sky is what
    lies within `sky_dE` of the picture's own sky colour nearby, so a cloud edge or a gradient does not count.

    `parent` (the spring picture with its sky, the matte's own): the band is then judged by what the season changed. A band
    pixel counts only where the season picture's sky-or-paint differs from the parent's. Without it the cloud sea that
    stands against an island's rim reads as paint outside the outline and even the spring takes score 0.36 to 0.39
    (measured on the three spring takes of day 0, night 0 and day 7), so the 1 % limit holds only relative to the parent."""
    pic = as_rgba(picture)[..., :3]
    m = np.asarray(matte, np.float32)
    if m.ndim == 3:
        m = m[..., 3] if m.shape[-1] == 4 else m[..., 0]
    if m.shape != pic.shape[:2]:
        raise ValueError(f"the matte is {m.shape}, the picture {pic.shape[:2]}")
    band = LIMITS["s2"]["band"] if band is None else band
    limit = (LIMITS["s2"]["relative_share"] if parent is not None else LIMITS["s2"]["share"]) if limit is None else limit
    inside, outside = edge_bands(m, band)
    if ignore is not None:                       # a region meant to be soft (the lighthouse's beam), as `plate_gate.py` skips it
        inside, outside = inside & ~ignore, outside & ~ignore
    outside &= m <= 0.02  # the matte's own soft fringe is the outline, not paint outside it
    sky, wt = local_sky(pic, m, band)
    ok_sky = wt > 0.05
    is_sky = de(pic.reshape(-1, 3), sky.reshape(-1, 3)).reshape(m.shape) < sky_dE
    bad_in = inside & ok_sky & is_sky
    bad_out = outside & ok_sky & ~is_sky
    if parent is not None:
        par = as_rgba(parent)[..., :3]
        psky, pwt = local_sky(par, m, band)
        p_is_sky = de(par.reshape(-1, 3), psky.reshape(-1, 3)).reshape(m.shape) < sky_dE
        bad_in &= ~(inside & p_is_sky)          # the parent had sky there too: not the season's cut
        bad_out &= ~(outside & ~p_is_sky)       # the parent had paint there too: not the season's growth
    n = int((inside & ok_sky).sum() + (outside & ok_sky).sum())
    if not n:
        return {"check": "S2", "ok": False, "why": "no edge band has a sky to compare with"}
    share = float(bad_in.sum() + bad_out.sum()) / n
    return {"check": "S2", "ok": share <= limit, "share": round(share, 4), "sky_inside": int(bad_in.sum()),
            "paint_outside": int(bad_out.sum()), "limit": limit}


# ---------------------------------------------------------------- S3

def median_lab(rgba, mask: np.ndarray) -> np.ndarray:
    a = as_rgba(rgba)
    m = mask & (a[..., 3] > 0.5)
    if not m.any():
        raise ValueError("the mask holds no solid pixel")
    return np.median(lab(a[m][:, :3]), axis=0)


def s3_one_palette(picture, reference, mask: np.ndarray, limit: float | None = None) -> dict:
    """S3: the picture's median CIELAB over `mask` (the lawn: the walkable polygon) against the reference's, dE. Used
    for a stage's lawn against the season master's, and for a base against its own plate."""
    limit = LIMITS["s3"]["dE"] if limit is None else limit
    d = float(np.linalg.norm(median_lab(picture, mask) - median_lab(reference, mask)))
    return {"check": "S3", "ok": d <= limit, "dE": round(d, 2), "limit": limit}


def lawn_mask(shape: tuple[int, int], data: dict) -> np.ndarray:
    return poly_mask(shape, data["walkable"])


# ---------------------------------------------------------------- S4

def look_on(plate: np.ndarray, look: np.ndarray, box) -> tuple[np.ndarray, np.ndarray]:
    """The look's pixels and the plate's under them: the look resized to `box` (plate points) on the plate texture."""
    x0, y0 = round((box[0] - 2) * TEX), round((box[1] - 434) * TEX)
    w, h = round((box[2] - box[0]) * TEX), round((box[3] - box[1]) * TEX)
    lk = cv2.resize(as_rgba(look), (w, h), interpolation=cv2.INTER_AREA)
    pl = as_rgba(plate)
    xa, ya = max(x0, 0), max(y0, 0)
    xb, yb = min(x0 + w, pl.shape[1]), min(y0 + h, pl.shape[0])
    lk, pl = lk[ya - y0:yb - y0, xa - x0:xb - x0], pl[ya:yb, xa:xb]
    keep = (lk[..., 3] > 0.5) & (pl[..., 3] > 0.5)
    return lk[keep][:, :3], pl[keep][:, :3]


def reference_stage(st: dict) -> int:
    """The stage whose painted station the station's looks were drawn against: the one whose placement is the
    station's own (`box` at the top of its entry), the tea stall's stage 7, the windmill's stage 0."""
    for stage, p in st.get("stages", {}).items():
        if p.get("box") == st["box"]:
            return int(stage)
    return 0


def s4_look_sits(plate, look, box, limit: float | None = None) -> dict:
    """S4, first half: the look's mean CIELAB against the plate's under it (the same station on the season plate), dE."""
    a, b = look_on(plate, look, box)
    if not len(a):
        return {"check": "S4", "ok": False, "why": "the look does not overlap the plate"}
    limit = LIMITS["s4"]["mean_dE"] if limit is None else limit
    d = float(np.linalg.norm(lab(a).mean(0) - lab(b).mean(0)))
    return {"check": "S4", "ok": d <= limit, "mean_dE": round(d, 2), "limit": limit}


def _lin(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _gam(c):
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.maximum(c, 0) ** (1 / 2.4) - 0.055)


def colour_fit(src: np.ndarray, dst: np.ndarray) -> np.ndarray:
    """A 3 x 4 affine map in linear RGB from `src` to `dst` ((N, 3) sRGB), least squares."""
    x = np.hstack([_lin(src), np.ones((len(src), 1))])
    return np.linalg.lstsq(x, _lin(dst), rcond=None)[0]


def apply_fit(m: np.ndarray, rgb: np.ndarray) -> np.ndarray:
    return _gam(np.clip(np.hstack([_lin(rgb), np.ones((len(rgb), 1))]) @ m, 0, 1))


def fit_residuals(parent, picture, data: dict, stations=None, stage_objects=None) -> dict:
    """S4, second half (a measure, not a limit: FIT_NOTE): each station's colour fit learned on the others (leave one
    out), from `parent` to `picture`; per station the dE median and p90 before and after the fit."""
    a, b = as_rgba(parent), as_rgba(picture)
    objs = {o["id"]: o for o in data["objects"] if o.get("station") and o["station"] != "pond"}
    ids = list(stations or objs)
    solid = (a[..., 3] > 0.99) & (b[..., 3] > 0.99)
    pairs = {}
    for i in ids:
        m = poly_mask(a.shape[:2], objs[i]["polygon"]) & solid
        pairs[i] = (a[m][:, :3], b[m][:, :3])
    out = {}
    for i in ids:
        src = np.vstack([pairs[j][0] for j in ids if j != i])
        dst = np.vstack([pairs[j][1] for j in ids if j != i])
        m = colour_fit(src, dst)
        x, y = pairs[i]
        e0, e1 = de(x, y), de(apply_fit(m, x), y)
        out[i] = {"before": [round(float(np.median(e0)), 1), round(_pct(e0, 90), 1)],
                  "after": [round(float(np.median(e1)), 1), round(_pct(e1, 90), 1)]}
    return {"check": "S4 fit", "ok": True, "limit": LIMITS["s4"]["fit_median"], "stations": out}


# ---------------------------------------------------------------- S8

def season_key(season: str | None, light: str) -> str:
    return light if not season or season == "spring" else f"{season}-{light}"


def has_asset(name: str, assets: Path | None = None) -> bool:
    folder = (assets or ingest.ASSETS) / f"{name}.imageset"
    return folder.is_dir() and any(f.suffix in (".png", ".jpg", heic.SUFFIX) for f in folder.iterdir())


def s8_missing(data: dict, season: str, light: str, stage: int, assets: Path | None = None) -> list[str]:
    """S8: what the state (`season`, `light`, `stage`) still lacks: its plate or base, cuts (island, Map), every present
    object's occluder, a tint, both maps and a crop, and a look for every station level that has a spring look."""
    key = season_key(season, light)
    isl = data["island"]
    name = lambda kind, oid=None: ingest.asset_name(isl, kind, key, stage, oid)  # noqa: E731
    need = [name("plate"), name("island"), name("mapisle")]
    for o in data["objects"]:
        if o.get("occluder") and (o.get("stages") is None or stage in o["stages"]):
            need.append(name("occ", o["id"]))
    miss = [n for n in need if not has_asset(n, assets)]

    def table(t):
        rows = data.get(t, {}).get(key)
        return rows is not None and stage < len(rows) and rows[stage] is not None

    miss += [f"{t}[{key}][{stage}]" for t in ("harmony", "lightMap", "shadowMap", "plateCrop") if not table(t)]
    for sid, st in data.get("stations", {}).items():
        stages = st["lights"].get(key, []) if "lights" in st else (st.get("baseStages", []) if st.get("light", "day") == key else [])
        if stage not in stages:
            continue                                 # a look is drawn only over a base: the station stays painted in the plate
        if not has_asset(name("base"), assets):
            miss.append(name("base"))
        levels = st.get("lookLevels", {}).get(key) or range(1, st["levels"] + 1)
        for lv in levels:
            n = f"world-{isl}-look-{sid}-{lv}-{key}"
            if not has_asset(n, assets):
                miss.append(n)
    return miss


def s8_complete(data: dict, season: str, assets: Path | None = None) -> dict:
    """S8 over every state a season lists in `seasons.<season>.states` (light -> stages)."""
    spec = data.get("seasons", {}).get(season)
    if spec is None:
        return {"check": "S8", "ok": False, "why": f"{season} is not listed", "missing": {}}
    miss = {}
    for light, stages in spec.get("states", {}).items():
        for s in stages:
            m = s8_missing(data, season, light, s, assets)
            if m:
                miss[f"{light}-{s}"] = m
    return {"check": "S8", "ok": not miss, "missing": miss}


# ---------------------------------------------------------------- a season's states

def season_take(key: str, stage: int):
    """The take a state was ingested from, as the picture the gate reads: RGBA at the shipped plate's crop and texture size
    (Lanczos x2 of the take over the state's matte). The sky is the take's own."""
    hand = ingest.load_hand("home")
    path = ingest.REPO / hand["plates"][key][str(stage)]
    m = ingest.load_matte_full("home", key, stage)
    cx0, cy0, cx1, cy1 = ingest.plate_crop(m)
    rgb = np.asarray(Image.open(path).convert("RGB").resize((m.shape[1], m.shape[0]), Image.LANCZOS), np.float32) / 255
    return np.dstack([rgb, m.astype(np.float32)])[cy0:cy1, cx0:cx1]


def s6_seam(base, plate, stage: int, margin: int = 80) -> dict:
    """S6: a base is its plate everywhere but the stations' windows (and `margin` texture px round them), and its alpha only
    shrinks: what the paste-back ring test (`test_station_looks.py`) holds for spring."""
    import station_looks as sl
    b, p = as_rgba(base), as_rgba(plate)
    boxes = [sp["bases"][stage]["window"] for sp in sl.stage_specs(stage)]
    x0, y0 = min(w[0] for w in boxes), min(w[1] for w in boxes)
    x1, y1 = max(w[2] for w in boxes), max(w[3] for w in boxes)
    cx, cy = (ingest.plate_crop_points("home", ingest.load_hand("home"), "day", stage)[i] * TEX for i in (0, 1))
    far = np.ones(p.shape[:2], bool)
    far[max(y0 - cy - margin, 0):y1 - cy + margin, max(x0 - cx - margin, 0):x1 - cx + margin] = False
    seen = far & ((p[..., 3] > 0.01) | (b[..., 3] > 0.01))
    # The shipped layers are HEIC: a plate and the base cut from its decode differ by the codec's noise (spring's own base
    # reads 3e-5 of the pixels beyond 0.04, its alpha 1e-6 beyond 0.02), so the test counts a share, not the worst pixel.
    off = float((np.abs(b[seen][:, :4] - p[seen][:, :4]).max(-1) > 0.04).mean()) if seen.any() else 0.0
    grew = float(((b[..., 3] - p[..., 3])[seen] > 0.05).mean()) if seen.any() else 0.0
    return {"check": "S6", "ok": off <= 1e-3 and grew <= 1e-4, "off_window_share": round(off, 6), "alpha_grew_share": round(grew, 6), "limit": "1e-3, 1e-4 (spring 3e-5, 0)"}


def season_report(data: dict, season: str) -> int:
    """Measure and limit per picture of a season's listed states: S1 against the spring state, S2 against the spring take
    (relative, see `s2_outline_held`), S5 of the night against the day, S3 of each base against its plate, S4 of each look on
    its season plate, S6 and S8; S7 is `plate_gate.py`'s. Returns the number of failures."""
    fails = 0
    entry = data["seasons"][season]
    states = [(f"{season}-{light}", light, st) for light, stages in entry["states"].items() for st in stages]
    print(f"{season}: states {', '.join(f'{l}-{s}' for _, l, s in states)}; complete {entry['complete']}")
    plates = {}
    for key, light, stage in [(k, l, s) for k, l, s in states]:
        plates[(key, stage)] = load_asset(ingest.asset_name("home", "plate", key, stage))
        spring = load_asset(ingest.asset_name("home", "plate", light, stage))
        rows = [("S1", f"{key}-{stage} against {light}-{stage}", s1_frame_held(spring, plates[(key, stage)]))]
        hand = ingest.load_hand("home")
        cx, cy = (v for v in ingest.plate_crop(ingest.load_matte_full("home", key, stage))[:2])
        beam = np.zeros(spring.shape[:2], bool)
        if stage == 0:
            import plate_gate
            bx0, by0, bx1, by1 = plate_gate.BEAM
            beam[max(by0 - cy, 0):max(by1 - cy, 0), max(bx0 - cx, 0):max(bx1 - cx, 0)] = True
        r2 = s2_outline_held(season_take(key, stage), spring[..., 3], parent=season_take(light, stage), ignore=beam)
        rows.append(("S2", f"{key}-{stage} against the spring take", r2))
        if light == "night" and (f"{season}-day", stage) in plates:
            rows.append(("S5", f"{key}-{stage} against {season}-day-{stage}", s5_night_is_the_days(plates[(f"{season}-day", stage)], plates[(key, stage)])))
        for sid, st in data["stations"].items():
            if stage not in st.get("lights", {}).get(key, []):
                continue
            if not any(r[0] == "S6" for r in rows):
                base = load_asset(ingest.asset_name("home", "base", key, stage))
                lawn = lawn_mask(base.shape[:2], data)
                rows.append(("S3", f"base {key}-{stage} lawn against its plate", s3_one_palette(base, plates[(key, stage)], lawn)))
                rows.append(("S6", f"base {key}-{stage} against its plate outside the windows", s6_seam(base, plates[(key, stage)], stage)))
            levels = st.get("lookLevels", {}).get(key) or range(1, st["levels"] + 1)
            for lv in levels:
                look = load_asset(f"world-home-look-{sid}-{lv}-{key}")
                box = st["stages"][str(stage)]["box"]
                r4 = s4_look_sits(plates[(key, stage)], look, box)
                # A station whose spring look already misses the limit on the spring plate (the pond's and the workshop's
                # are other paintings than the plate's own stations: spring measures 5 to 31) is held to the spring's measure
                # plus `s4.over_spring`: derived, it must sit no worse than the look it came from (the fit is linear).
                r_spring = s4_look_sits(load_asset(ingest.asset_name("home", "plate", light, stage)), load_asset(f"world-home-look-{sid}-{lv}-{light}"), box)
                if not r_spring["ok"]:
                    r4 = {**r4, "spring": r_spring["mean_dE"], "limit": round(r_spring["mean_dE"] + LIMITS["s4"]["over_spring"], 2), "ok": r4["mean_dE"] <= r_spring["mean_dE"] + LIMITS["s4"]["over_spring"]}
                rows.append(("S4", f"look {sid} {lv} on {key}-{stage}", r4))
        for _, label, r in rows:
            print(f"{label}\n{_line(r)}")
            fails += not r["ok"]
    r = s8_complete(data, season)
    print("every listed state has every piece (S8)")
    print(_line(r))
    for k, m in r["missing"].items():
        print(f"    {k}: {', '.join(m)}")
    return fails


# ---------------------------------------------------------------- report

def _line(r: dict) -> str:
    body = ", ".join(f"{k} {v}" for k, v in r.items() if k not in ("check", "ok", "stations", "missing"))
    return f"  {r['check']:7} {'ok  ' if r['ok'] else 'FAIL'} {body}"


def report(season: str | None = None) -> int:
    """Measure and limit for the shipped assets: S1 and S5 on the golden and night plates against the day plate,
    S3 on the lawn and S4 on every look, the fit residuals, and S8 for every listed season."""
    data = json.loads(PLATE_JSON.read_text())
    day, golden, night = (load_asset(f"world-home-plate-{l}-0") for l in ("day", "golden", "night"))
    fails = 0
    rows = [("golden-0 against day-0", s1_frame_held(day, golden)), ("night-0 against day-0", s5_night_is_the_days(day, night))]
    lawn = lawn_mask(day.shape[:2], data)
    rows += [("lawn, golden-0 against day-0 (a relight: expect a large dE)", s3_one_palette(golden, day, lawn))]
    for sid, st in data["stations"].items():
        for lv in st.get("lookLevels", {}).get("day") or range(1, st["levels"] + 1):
            stage = reference_stage(st)
            box = st["box"]
            look = load_asset(f"world-home-look-{sid}-{lv}-day")
            plate = load_asset(f"world-home-plate-day-{stage}")
            rows.append((f"look {sid} {lv} on day-{stage}", s4_look_sits(plate, look, box)))
    print("shipped assets (S1 and S5 gate; S3 and S4 on spring print what the spring art measures)")
    for label, r in rows:
        print(f"{label}\n{_line(r)}")
        fails += not r["ok"] and r["check"] in ("S1", "S5")  # S3 and S4 on spring are informational
    fit = fit_residuals(day, golden, data)
    print("station fit, day to golden (dE median, p90: before -> after; " + FIT_NOTE + ")")
    for sid, v in fit["stations"].items():
        print(f"  {sid:11} {v['before'][0]:5.1f} {v['before'][1]:5.1f} -> {v['after'][0]:5.1f} {v['after'][1]:5.1f}")
    seasons = [season] if season else list(data.get("seasons", {}))
    print("seasons: " + (", ".join(seasons) if seasons else NO_SEASONS))
    for s in seasons:
        fails += season_report(data, s) + (not s8_complete(data, s)["ok"])
    return 1 if fails else 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("report")
    r.add_argument("--season")
    for c in ("s1", "s2"):
        p = sub.add_parser(c)
        p.add_argument("a")
        p.add_argument("b")
    args = ap.parse_args(argv)
    if args.cmd == "report":
        return report(args.season)
    if args.cmd == "s1":
        res = s1_frame_held(args.a, args.b)
    else:
        res = s2_outline_held(args.a, as_rgba(args.b)[..., 3])
    print(_line(res))
    return 0 if res["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
