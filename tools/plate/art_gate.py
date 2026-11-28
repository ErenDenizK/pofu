#!/usr/bin/env python3
"""The art gate (docs/design/art-pass-2026-11-28.md section 5): measures real in-app frames against the bar.

    python3 -I tools/plate/art_gate.py report <frames-folder> [--config art_gate.json]

One line per check: measure, limit, then pass, FAIL, pending or measure. Boxes and limits live in `art_gate.json`; a
null limit prints its measure only, a `pending` tag (a PR id) never fails. Exit 1 when any check fails. Frames are
`<name>.png` (or `.heic`) in the folder; fetch them with `tools/review/fetch_frames.sh`. Dependencies: numpy,
Pillow, OpenCV (pillow-heif for HEIC).
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
import heic  # noqa: E402

CONFIG = HERE / "art_gate.json"


# ------------------------------------------------------------------ pixels

def load(folder: Path, name: str) -> np.ndarray | None:
    """RGB uint8 of `<name>.png` / `.heic` in `folder`, or None."""
    for suffix in (".png", ".heic"):
        p = Path(folder) / (name + suffix)
        if p.exists():
            return np.asarray(heic.open_image(p).convert("RGB"))
    return None


def crop(frame: np.ndarray, box) -> np.ndarray:
    x0, y0, x1, y1 = box
    return frame[y0:y1, x0:x1]


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    """Inverse of `heic._lab`: Lab (D65) to sRGB 0-255, float."""
    fy = (lab[..., 0] + 16) / 116
    fx, fz = fy + lab[..., 1] / 500, fy - lab[..., 2] / 200
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f ** 3 > 216 / 24389, f ** 3, (116 * f - 16) / (24389 / 27)) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[0.4124564, 0.2126729, 0.0193339],
                  [0.3575761, 0.7151522, 0.1191920],
                  [0.1804375, 0.0721750, 0.9503041]])
    lin = xyz @ np.linalg.inv(m)
    c = np.where(lin <= 0.0031308, 12.92 * lin, 1.055 * np.clip(lin, 0, None) ** (1 / 2.4) - 0.055)
    return np.clip(c, 0, 1) * 255


def lch_to_rgb(L: float, C: float, h: float) -> np.ndarray:
    return lab_to_rgb(np.array([L, C * np.cos(np.radians(h)), C * np.sin(np.radians(h))]))


def hex_to_rgb(s: str) -> np.ndarray:
    return np.array([int(s.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def measure(frame: np.ndarray, box) -> dict:
    """Median L and C, h of the median a*, b*, and the C 90th percentile of the pixels in `box`."""
    return measure_pixels(crop(frame, box))


def measure_pixels(rgb: np.ndarray) -> dict:
    lab = heic._lab(rgb.reshape(-1, 3).astype(np.float64))
    c = np.hypot(lab[:, 1], lab[:, 2])
    a, b = np.median(lab[:, 1]), np.median(lab[:, 2])
    return {"L": float(np.median(lab[:, 0])), "C": float(np.median(c)),
            "h": float(np.degrees(np.arctan2(b, a)) % 360), "C_p90": float(np.percentile(c, 90))}


def pool(frame: np.ndarray, boxes) -> np.ndarray:
    return np.concatenate([crop(frame, b).reshape(-1, 3) for b in boxes])


def luminance(rgb: np.ndarray) -> np.ndarray:
    return rgb.astype(np.float64) @ np.array([0.2126, 0.7152, 0.0722])


def highpass(gray: np.ndarray, sigma: float) -> np.ndarray:
    return gray - cv2.GaussianBlur(gray, (0, 0), sigma)


def band_variances(rgb: np.ndarray, band_px: int = 8) -> np.ndarray:
    """Laplacian variance of every `band_px`-tall row band (full width), luminance in 0-255 levels."""
    lap = cv2.Laplacian(luminance(rgb), cv2.CV_64F)
    n = lap.shape[0] // band_px
    return lap[:n * band_px].reshape(n, band_px, -1).var(axis=(1, 2))


def lap_var(rgb: np.ndarray) -> float:
    return float(cv2.Laplacian(luminance(rgb), cv2.CV_64F).var())


# ------------------------------------------------------------------ results

def result(name: str, measure_text: str, limit_text: str, ok: bool | None, pending: str | None = None,
           why: str = "") -> dict:
    """ok None = a measure only (null limit). `pending` never fails."""
    if pending:
        status = "pending"
    elif ok is None:
        status = "measure"
    else:
        status = "pass" if ok else "FAIL"
    return {"check": name, "measure": measure_text, "limit": limit_text, "status": status,
            "pending": pending, "ok": ok, "why": why}


def _lim(text: str, value, cfg: dict) -> str:
    """`text value`, or `null (why)` when the limit is null."""
    return f"{text} {value}" if value is not None else "null" + (f" ({cfg['why']})" if cfg.get("why") else "")


def no_frame(name: str, frames, limit_text: str, pending=None) -> dict:
    return result(name, "no frame: " + ", ".join(frames), limit_text, False, pending, "missing frame")


def _have(folder, names):
    frames = {n: load(folder, n) for n in names}
    return frames, [n for n, f in frames.items() if f is None]


# ------------------------------------------------------------------ checks

def night_lawn(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = f"L {cfg['L'][0]}-{cfg['L'][1]}, C >= {cfg['C_min']}, h {cfg['h'][0]}-{cfg['h'][1]}"
    if miss:
        return no_frame("night.lawn", miss, lim, cfg.get("pending"))
    m = measure_pixels(pool(frames[cfg["frame"]], cfg["boxes"]))
    ok = cfg["L"][0] <= m["L"] <= cfg["L"][1] and m["C"] >= cfg["C_min"] and cfg["h"][0] <= m["h"] <= cfg["h"][1]
    return result("night.lawn", f"L {m['L']:.1f} C {m['C']:.1f} h {m['h']:.0f}", lim, ok, cfg.get("pending"))


def night_near(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = f"ground C >= {cfg['ground_C_min']}, band C >= {cfg['band_C_min']}"
    if miss:
        return no_frame("night.near", miss, lim, cfg.get("pending"))
    f = frames[cfg["frame"]]
    g = [measure(f, b)["C"] for b in cfg["ground"]]
    band = measure(f, cfg["band"])["C"]
    ok = min(g) >= cfg["ground_C_min"] and band >= cfg["band_C_min"]
    return result("night.near", f"ground C {g[0]:.1f} / {g[1]:.1f}, band C {band:.1f}", lim, ok, cfg.get("pending"))


def _ground_L(frame, boxes):
    return float(np.mean([measure(frame, b)["L"] for b in boxes]))


def night_pofu(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = f"Pofu L - ground L <= {cfg['dL_max']}"
    if miss:
        return no_frame("night.pofu", miss, lim, cfg.get("pending"))
    f = frames[cfg["frame"]]
    d = measure(f, cfg["pofu"])["L"] - _ground_L(f, cfg["ground"])
    return result("night.pofu", f"dL {d:.1f}", lim, d <= cfg["dL_max"], cfg.get("pending"))


def season_band(cfg, folder, plate: dict):
    """mean |delta| (RGB levels) of each season against the baseline, day and night; a pass is required only for
    seasons `plate-home.json` lists as complete."""
    out = []
    listed = plate.get("seasons", {}) if plate else {}
    base = cfg["baseline"]
    for s in cfg["seasons"]:
        lim = f"mean |d| > {cfg['mean_abs_min']}"
        name = f"season.band.{s}"
        spec = listed.get(s)
        pending = None
        if spec is None:
            pending = "S5 (not listed in plate-home.json)"
        elif not spec.get("complete"):
            pending = "S5 (listed, not complete)"
        vals, miss = {}, []
        for tag, suffix in (("day", ""), ("night", "-night")):
            a, b = load(folder, f"path-season-{s}-i10{suffix}"), load(folder, f"path-season-{base}-i10{suffix}")
            if a is None or b is None:
                miss.append(f"path-season-{s if a is None else base}-i10{suffix}")
                continue
            box = cfg["box"]
            vals[tag] = float(np.abs(crop(a, box).astype(np.float64) - crop(b, box).astype(np.float64)).mean())
        if miss:
            out.append(result(name, "no frame: " + ", ".join(miss), lim, False if not pending else None,
                              pending or None, "missing frame"))
            continue
        ok = all(v > cfg["mean_abs_min"] for v in vals.values())
        out.append(result(name, ", ".join(f"{k} {v:.2f}" for k, v in vals.items()), lim, ok, pending))
    return out


def sky_golden(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = f"dE2000 to {cfg['target_hex']} <= {cfg['dE_max']}"
    if miss:
        return no_frame("sky.golden", miss, lim, cfg.get("pending"))
    med = np.median(crop(frames[cfg["frame"]], cfg["box"]).reshape(-1, 3), axis=0)
    d = float(heic.delta_e2000(med, hex_to_rgb(cfg["target_hex"])))
    return result("sky.golden", f"dE {d:.2f}", lim, d <= cfg["dE_max"], cfg.get("pending"))


def sky_day(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    t = cfg["target_lch"]
    lim = f"dE2000 to L{t[0]} C{t[1]} h{t[2]} <= {cfg['dE_max']}"
    if miss:
        return no_frame("sky.day", miss, lim, cfg.get("pending"))
    med = np.median(crop(frames[cfg["frame"]], cfg["box"]).reshape(-1, 3), axis=0)
    d = float(heic.delta_e2000(med, lch_to_rgb(*t)))
    return result("sky.day", f"dE {d:.2f}", lim, d <= cfg["dE_max"], cfg.get("pending"))


def mirror_correlation(left: np.ndarray, right: np.ndarray, sigma: float) -> float:
    """Pearson correlation of the luminance high-pass of `left` with `right` mirrored left-right."""
    a = highpass(luminance(left), sigma).ravel()
    b = highpass(luminance(right[:, ::-1]), sigma).ravel()
    a, b = a - a.mean(), b - b.mean()
    den = np.sqrt((a * a).sum() * (b * b).sum())
    return float((a * b).sum() / den) if den else 0.0


def sky_mirror(cfg, folder):
    frames, miss = _have(folder, cfg["frames"])
    lim = _lim("corr <", cfg["corr_max"], cfg)
    if miss:
        return no_frame("sky.mirror", miss, lim, cfg.get("pending"))
    r = {n: mirror_correlation(crop(f, cfg["left"]), crop(f, cfg["right"]), cfg["sigma"]) for n, f in frames.items()}
    ok = None if cfg["corr_max"] is None else max(r.values()) < cfg["corr_max"]
    return result("sky.mirror", ", ".join(f"{n[-4:]} {v:.2f}" for n, v in r.items()), lim, ok, cfg.get("pending"))


def sky_contour(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = "null" if cfg["share_max"] is None else f"share <= {cfg['share_max']}"
    if miss:
        return no_frame("sky.contour", miss, lim, cfg.get("pending"))
    hp = highpass(luminance(crop(frames[cfg["frame"]], cfg["box"])), cfg["sigma"])
    share = float((np.abs(hp) > cfg["levels"]).mean())
    ok = None if cfg["share_max"] is None else share <= cfg["share_max"]
    return result("sky.contour", f"share {share:.3f}", lim, ok, cfg.get("pending"))


def near_blur(cfg, folder):
    frames, miss = _have(folder, cfg["frames"])
    lim = f"share of bands with lap var < {cfg['lap_var_min']} <= {cfg['share_max']}"
    if miss:
        return no_frame("near.blur", miss, lim, cfg.get("pending"))
    r = {n: blur_share(f, cfg["band_px"], cfg["lap_var_min"]) for n, f in frames.items()}
    ok = max(r.values()) <= cfg["share_max"]
    return result("near.blur", ", ".join(f"{n.replace('path-near-', '')} {v:.2f}" for n, v in r.items()), lim, ok,
                  cfg.get("pending"))


def blur_share(rgb: np.ndarray, band_px: int = 8, lap_var_min: float = 5) -> float:
    return float((band_variances(rgb, band_px) < lap_var_min).mean())


def near_subject(cfg, folder):
    frames, miss = _have(folder, sorted({s["frame"] for s in cfg["subjects"]}))
    lim = f"subject / sharpest band >= {cfg['ratio_min']}"
    if miss:
        return no_frame("near.subject", miss, lim, cfg.get("pending"))
    r = {}
    for s in cfg["subjects"]:
        f = frames[s["frame"]]
        r[s["frame"]] = lap_var(crop(f, s["box"])) / float(band_variances(f, cfg["band_px"]).max())
    ok = min(r.values()) >= cfg["ratio_min"]
    return result("near.subject", ", ".join(f"{n.replace('path-near-', '')} {v:.2f}" for n, v in r.items()), lim, ok,
                  cfg.get("pending"))


def pofu_separation(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = f"Pofu L - ground L >= {cfg['dL_min']}"
    if miss:
        return no_frame("pofu.separation", miss, lim, cfg.get("pending"))
    f = frames[cfg["frame"]]
    d = measure(f, cfg["pofu"])["L"] - _ground_L(f, cfg["ground"])
    return result("pofu.separation", f"dL {d:.1f}", lim, d >= cfg["dL_min"], cfg.get("pending"))


def pofu_peach(cfg, folder):
    frames, miss = _have(folder, [cfg["frame"]])
    lim = _lim(f"C p90 (h {cfg['h'][0]}-{cfg['h'][1]}) >=", cfg["C_p90_min"], cfg)
    if miss:
        return no_frame("pofu.peach", miss, lim, cfg.get("pending"))
    lab = heic._lab(crop(frames[cfg["frame"]], cfg["pofu"]).reshape(-1, 3).astype(np.float64))
    c, h = np.hypot(lab[:, 1], lab[:, 2]), np.degrees(np.arctan2(lab[:, 2], lab[:, 1])) % 360
    sel = c[(h >= cfg["h"][0]) & (h <= cfg["h"][1])]
    if sel.size == 0:
        return result("pofu.peach", "no peach pixels", lim, False, cfg.get("pending"))
    p = float(np.percentile(sel, 90))
    ok = None if cfg["C_p90_min"] is None else p >= cfg["C_p90_min"]
    return result("pofu.peach", f"C p90 {p:.1f}", lim, ok, cfg.get("pending"))


def pofu_pad(cfg, folder):
    names = [cfg[k]["frame"] for k in ("near", "home")]
    frames, miss = _have(folder, names)
    lim = f"near >= {cfg['near']['dL_min']}, home >= {cfg['home']['dL_min']}"
    if miss:
        return no_frame("pofu.pad", miss, lim, cfg.get("pending"))
    d = {}
    for k in ("near", "home"):
        f = frames[cfg[k]["frame"]]
        d[k] = _ground_L(f, cfg[k]["beside"]) - measure(f, cfg[k]["under"])["L"]
    ok = all(d[k] >= cfg[k]["dL_min"] for k in d)
    return result("pofu.pad", f"near {d['near']:.1f}, home {d['home']:.1f}", lim, ok, cfg.get("pending"))


# ------------------------------------------------------------------ report

def run(folder: Path, cfg: dict, plate: dict) -> list[dict]:
    rs = [night_lawn(cfg["night.lawn"], folder), night_near(cfg["night.near"], folder),
          night_pofu(cfg["night.pofu"], folder)]
    rs += season_band(cfg["season.band"], folder, plate)
    rs += [sky_golden(cfg["sky.golden"], folder), sky_day(cfg["sky.day"], folder),
           sky_mirror(cfg["sky.mirror"], folder), sky_contour(cfg["sky.contour"], folder),
           near_blur(cfg["near.blur"], folder), near_subject(cfg["near.subject"], folder),
           pofu_separation(cfg["pofu.separation"], folder), pofu_peach(cfg["pofu.peach"], folder),
           pofu_pad(cfg["pofu.pad"], folder)]
    return rs


def format_line(r: dict) -> str:
    tag = r["status"] + (f" {r['pending']}" if r["pending"] else "")
    return f"{r['check']:<22} {tag:<10} measure: {r['measure']}  |  limit: {r['limit']}"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    rp = sub.add_parser("report", help="print one line per check for a folder of frames")
    rp.add_argument("folder", type=Path)
    rp.add_argument("--config", type=Path, default=CONFIG)
    args = ap.parse_args(argv)
    cfg = json.loads(args.config.read_text())
    pj = REPO / cfg["plate_json"]
    plate = json.loads(pj.read_text()) if pj.exists() else {}
    rs = run(args.folder, cfg, plate)
    for r in rs:
        print(format_line(r))
    fails = [r["check"] for r in rs if r["status"] == "FAIL"]
    print(f"{len(rs)} checks, {len(fails)} fail" + (f": {', '.join(fails)}" if fails else ""))
    return 1 if fails else 0


if __name__ == "__main__":
    raise SystemExit(main())
