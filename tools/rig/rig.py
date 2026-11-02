#!/usr/bin/env python3
"""Pofu's layered rig: cut parts out of R1 edits and composite them on the plate.

docs/design/art-production-plan.md ("Pofu's reactions are a rig"). Every
rig part is an edit of R1 that changes one region and lines up with R1
everywhere else (batch-06-pofu-rig-pilot, batch-06-pofu-rig). This tool
cuts each region out with soft masks drawn once on R1 (`rig.json`) and
composites them, in layer order, over the clean plate (`pofu-rig-clean`:
no ears, no front paws), so the review sees exactly what the app will
draw. Code motion (breathing, squash, hops) is not simulated; an ear flick
is, because it is what the clean plate exists for.

Two mask modes per region:
- `region`: the ellipses as they are, feathered (eyes, mouth: the part
  changes inside a known place).
- `envelope`: where the part differs from what is already composited,
  inside the ellipses (paws and pouches change shape; drooped ears move).
  Regions marked by what the plate lacks (ears, paws) are restored from R1
  when no part replaces them.

Every layer gets a seam score: the mean Delta E between the part and what
it lands on, measured in the feather ring. A high score is a visible seam.

    python3 -I tools/rig/rig.py preview                # the regions drawn on R1
    python3 -I tools/rig/rig.py sheet                  # the pilot's expressions
    python3 -I tools/rig/rig.py sheet --all            # every expression in rig.json
    python3 -I tools/rig/rig.py compose happy --out build/rig/happy.png

Output goes to build/rig/ (git-ignored) unless --out says otherwise.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "tools" / "imagegen"))
import style_lock as sl  # noqa: E402

CONFIG = HERE / "rig.json"
MASTERS = REPO / "design" / "art" / "masters"
SKY = (198, 222, 240)


# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

def load_config(path: Path = CONFIG) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def load_rgba(path: Path) -> np.ndarray:
    with Image.open(path) as im:
        return np.asarray(im.convert("RGBA"), dtype=np.float64) / 255.0


def master_path(name: str, root: Path = MASTERS) -> Path | None:
    """A promoted master: <root>/<name>/<name>.png, or its lossless WebP twin."""
    for ext in ("png", "webp"):
        p = root / name / f"{name}.{ext}"
        if p.exists():
            return p
    return None


# ---------------------------------------------------------------------------
# Masks
# ---------------------------------------------------------------------------

def ellipse_mask(size: tuple[int, int], ellipses: list, full: bool = False) -> np.ndarray:
    """Hard 0/1 mask of the union of (cx, cy, rx, ry) ellipses on a (w, h) canvas."""
    w, h = size
    if full:
        return np.ones((h, w))
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    for cx, cy, rx, ry in ellipses:
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    return np.asarray(im, dtype=np.float64) / 255.0


def feather(mask: np.ndarray, px: float) -> np.ndarray:
    if px <= 0:
        return mask
    im = Image.fromarray(np.clip(np.round(mask * 255), 0, 255).astype(np.uint8), "L")
    return np.asarray(im.filter(ImageFilter.GaussianBlur(px)), dtype=np.float64) / 255.0


def delta_e(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Per-pixel difference of two RGBA images: Lab Delta E plus alpha change (x100)."""
    lab = np.linalg.norm(sl.srgb_to_lab(a[..., :3]) - sl.srgb_to_lab(b[..., :3]), axis=-1)
    both = np.minimum(a[..., 3], b[..., 3])
    return lab * both + 100.0 * np.abs(a[..., 3] - b[..., 3])


def diff_mask(src: np.ndarray, base: np.ndarray, threshold: float, grow_px: int = 4) -> np.ndarray:
    """Where src differs from base, grown a little so the feather lands outside the change."""
    hard = (delta_e(src, base) > threshold).astype(np.uint8) * 255
    im = Image.fromarray(hard, "L")
    if grow_px:
        im = im.filter(ImageFilter.MaxFilter(2 * grow_px + 1))
    return np.asarray(im, dtype=np.float64) / 255.0


# ---------------------------------------------------------------------------
# Compositing
# ---------------------------------------------------------------------------

def over(base: np.ndarray, src: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """Porter-Duff `over` with the layer's alpha = mask x src alpha."""
    a = (mask * src[..., 3])[..., None]
    ba = base[..., 3:4]
    out_a = a + ba * (1 - a)
    rgb = np.where(out_a > 1e-6, (src[..., :3] * a + base[..., :3] * ba * (1 - a)) / np.maximum(out_a, 1e-6), 0.0)
    return np.concatenate([rgb, out_a], axis=-1)


def rotate_about(rgba: np.ndarray, degrees: float, pivot: tuple[float, float]) -> np.ndarray:
    if not degrees:
        return rgba
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    im = im.rotate(degrees, resample=Image.Resampling.BICUBIC, center=pivot)
    return np.asarray(im, dtype=np.float64) / 255.0


def seam_score(src: np.ndarray, base: np.ndarray, mask: np.ndarray) -> float | None:
    """Mean Delta E between the part and what it lands on, in the feather ring."""
    ring = (mask > 0.15) & (mask < 0.85) & (src[..., 3] > 0.5) & (base[..., 3] > 0.5)
    if ring.sum() < 50:
        return None
    d = np.linalg.norm(sl.srgb_to_lab(src[..., :3][ring]) - sl.srgb_to_lab(base[..., :3][ring]), axis=-1)
    return float(d.mean())


@dataclass
class Composite:
    name: str
    image: np.ndarray
    used: dict = field(default_factory=dict)      # layer -> part name (or "R1")
    missing: list = field(default_factory=list)   # part names not on disk
    seams: dict = field(default_factory=dict)     # layer -> seam score
    masks: dict = field(default_factory=dict)     # layer -> final mask
    notes: list = field(default_factory=list)


class Rig:
    def __init__(self, r1: np.ndarray, plate: np.ndarray | None, parts: dict, config: dict):
        self.r1 = r1
        self.plate_missing = plate is None
        self.plate = r1 if plate is None else plate
        self.parts = parts          # part name -> image (only those on disk)
        self.cfg = config
        h, w = r1.shape[:2]
        self.size = (w, h)

    @classmethod
    def from_disk(cls, config: dict | None = None, masters: Path = MASTERS) -> "Rig":
        cfg = config or load_config()
        r1 = load_rgba(REPO / cfg["r1"])
        plate_p = master_path(cfg["plate"], masters)
        plate = load_rgba(plate_p) if plate_p else None
        names = {n for e in cfg["expressions"].values() for n in e.values()}
        parts = {}
        for n in sorted(names):
            p = master_path(n, masters)
            if p:
                parts[n] = load_rgba(p)
        return cls(r1, plate, parts, cfg)

    def envelope(self, layer: str) -> np.ndarray:
        reg = self.cfg["regions"][layer]
        return ellipse_mask(self.size, reg.get("ellipses", []), reg.get("full", False))

    def compose(self, name: str, ear_flick: float = 0.0) -> Composite:
        cfg = self.cfg
        want = cfg["expressions"][name]
        out = self.plate.copy()
        c = Composite(name=name, image=out)
        if self.plate_missing:
            c.notes.append(f"no {cfg['plate']} yet: R1 stands in as the plate (ears and paws cannot move)")
        fpx, thr = cfg.get("feather_px", 10), cfg.get("diff_threshold", 6.0)
        for layer in cfg["layers"]:
            reg = cfg["regions"][layer]
            part_name = want.get(layer)
            src, label = None, None
            if part_name:
                if part_name in self.parts:
                    src, label = self.parts[part_name], part_name
                else:
                    c.missing.append(part_name)
            if src is None and reg.get("restore"):
                src, label = self.r1, "R1"
            if src is None:
                continue
            env = self.envelope(layer)
            if reg["mode"] == "envelope":
                mask = feather(diff_mask(src, out, thr) * env, fpx) * feather(env, fpx / 2)
            else:
                mask = feather(env, fpx)
            if layer == "ears" and ear_flick and reg.get("pivots"):
                out = self._flick(out, src, mask, reg, ear_flick)
            else:
                score = seam_score(src, out, mask)
                if score is not None:
                    c.seams[layer] = round(score, 2)
                out = over(out, src, mask)
            c.used[layer] = label
            c.masks[layer] = mask
        c.image = out
        return c

    def _flick(self, out, src, mask, reg, degrees):
        for i, (cx, cy, rx, ry) in enumerate(reg["ellipses"]):
            one = mask * ellipse_mask(self.size, [[cx, cy, rx * 1.2, ry * 1.2]])
            cut = src.copy()
            cut[..., 3] *= one
            sign = 1 if cx < self.size[0] / 2 else -1
            rotated = rotate_about(cut, sign * degrees, tuple(reg["pivots"][i]))
            out = over(out, rotated, np.ones(rotated.shape[:2]))
        return out

    def fidelity(self, comp: Composite) -> float:
        """Mean Delta E of a composite against R1 over their opaque union (the neutral rig must be ~R1)."""
        solid = (comp.image[..., 3] > 0.5) | (self.r1[..., 3] > 0.5)
        return float(delta_e(comp.image, self.r1)[solid].mean())


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def to_image(rgba: np.ndarray, bg=SKY) -> Image.Image:
    im = Image.fromarray(np.clip(np.round(rgba * 255), 0, 255).astype(np.uint8), "RGBA")
    out = Image.new("RGBA", im.size, bg + (255,))
    out.alpha_composite(im)
    return out.convert("RGB")


def font(size: int):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def mask_overlay(comp: Composite, base: np.ndarray) -> Image.Image:
    colors = {"fur": (120, 120, 120), "paws": (40, 160, 90), "cheeks": (230, 120, 60), "ears": (130, 80, 200),
              "mouth": (220, 40, 120), "eyes": (40, 110, 220)}
    im = np.asarray(to_image(base), dtype=np.float64)
    for layer, m in comp.masks.items():
        col = np.array(colors.get(layer, (0, 0, 0)), dtype=np.float64)
        a = (m * 0.55)[..., None]
        im = im * (1 - a) + col * a
    return Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), "RGB")


FACE = (230, 640, 830, 1300)   # crop of R1's face and paws (left, top, right, bottom)


def sheet(rig: Rig, names: list[str], out_path: Path) -> list[Composite]:
    """One row per expression: full figure, face at 1:1, the masks, and the numbers."""
    row_h, full_w = 560, 373
    face_w = int((FACE[2] - FACE[0]) * row_h / (FACE[3] - FACE[1]))
    text_w = 520
    rows = [(n, 0.0) for n in names] + ([("neutral", 14.0)] if "neutral" in names else [])
    W = full_w + face_w * 2 + text_w + 50
    canvas = Image.new("RGB", (W, 70 + row_h * len(rows)), (250, 247, 243))
    d = ImageDraw.Draw(canvas)
    d.text((16, 18), "Pofu rig composites", fill=(40, 30, 40), font=font(28))
    d.text((360, 26), "full figure · face and paws · where each part came from · parts and seams", fill=(110, 100, 110), font=font(18))
    comps = []
    for i, (name, flick) in enumerate(rows):
        comp = rig.compose(name, ear_flick=flick)
        comps.append(comp)
        y = 70 + i * row_h
        full = to_image(comp.image).resize((full_w, row_h), Image.Resampling.LANCZOS)
        canvas.paste(full, (10, y))
        face = to_image(comp.image).crop(FACE).resize((face_w, row_h), Image.Resampling.LANCZOS)
        canvas.paste(face, (20 + full_w, y))
        mo = mask_overlay(comp, comp.image).crop(FACE).resize((face_w, row_h), Image.Resampling.LANCZOS)
        canvas.paste(mo, (30 + full_w + face_w, y))
        tx = 40 + full_w + 2 * face_w
        title = name + (f"  (ears flicked {flick:.0f} degrees)" if flick else "")
        d.text((tx, y + 14), title, fill=(40, 30, 40), font=font(26))
        lines = [f"{k}: {v}" for k, v in comp.used.items()] or ["plate only"]
        lines += [f"missing: {m} (R1 stands in)" for m in comp.missing]
        warn = rig.cfg.get("seam_warn", 6.0)
        lines += [f"seam {k}: dE {v:.1f}" + ("  <- visible?" if v > warn else "") for k, v in comp.seams.items()]
        if name == "neutral" and not flick:
            lines.append(f"neutral vs R1: mean dE {rig.fidelity(comp):.2f} (target < 1)")
        lines += comp.notes
        for j, line in enumerate(lines):
            d.text((tx, y + 56 + j * 24), line[:60], fill=(80, 70, 80), font=font(18))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out_path, quality=88)
    return comps


def preview(rig: Rig, out_path: Path) -> None:
    base = to_image(rig.r1)
    d = ImageDraw.Draw(base)
    colors = {"paws": (40, 160, 90), "cheeks": (230, 120, 60), "ears": (130, 80, 200), "mouth": (220, 40, 120),
              "eyes": (40, 110, 220)}
    for layer, reg in rig.cfg["regions"].items():
        for cx, cy, rx, ry in reg.get("ellipses", []):
            d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=colors.get(layer, (0, 0, 0)), width=4)
        for px, py in reg.get("pivots", []):
            d.ellipse((px - 8, py - 8, px + 8, py + 8), fill=(130, 80, 200))
        if reg.get("ellipses"):
            cx, cy = reg["ellipses"][0][:2]
            d.text((cx - 30, cy - 10), layer, fill=colors.get(layer, (0, 0, 0)), font=font(22))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    base.save(out_path, quality=90)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("preview", help="draw the regions on R1")
    p.add_argument("--out", type=Path, default=REPO / "build" / "rig" / "regions.jpg")
    p = sub.add_parser("sheet", help="composite contact sheet")
    p.add_argument("--all", action="store_true", help="every expression, not only the pilot's")
    p.add_argument("--out", type=Path, default=REPO / "build" / "rig" / "rig-contact.jpg")
    p = sub.add_parser("compose", help="one expression as a PNG")
    p.add_argument("expression")
    p.add_argument("--ear-flick", type=float, default=0.0)
    p.add_argument("--out", type=Path)
    args = ap.parse_args(argv)

    rig = Rig.from_disk()
    if args.cmd == "preview":
        preview(rig, args.out)
        print(f"wrote {args.out}")
    elif args.cmd == "sheet":
        names = list(rig.cfg["expressions"]) if args.all else rig.cfg["pilot"]
        comps = sheet(rig, names, args.out)
        for comp in comps:
            seams = ", ".join(f"{k} {v:.1f}" for k, v in comp.seams.items()) or "-"
            print(f"{comp.name}: parts {comp.used or '-'}; missing {comp.missing or '-'}; seams {seams}")
        print(f"wrote {args.out}")
    else:
        comp = rig.compose(args.expression, ear_flick=args.ear_flick)
        out = args.out or REPO / "build" / "rig" / f"{args.expression}.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(np.clip(np.round(comp.image * 255), 0, 255).astype(np.uint8), "RGBA").save(out)
        print(f"wrote {out}; missing {comp.missing or '-'}; seams {comp.seams or '-'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
