#!/usr/bin/env python3
"""Look lab, experiment 5 (design): harmonise by repaint, the inputs for a Codex edit job and the cut back.

No grade or relight gives the references' density (flowers, stones, painted contact shadows, one
brush over everything). An image model can repaint the composed frame as one picture; the lab
cannot call it, so this prepares the job and the way back into layers:

  inputs   frame.webp      the composed home frame (lab scene, best pipeline, the state's light)
           layout.png      the layout mask: one flat colour per layer id (sky, sea, lawn, earth, each
                           sprite), so the edit can be told what must not move
           the reference   a take already in the repo (lab.REF), attached by path
  job      repaint-job.yaml  a manifest job in tools/imagegen's format (edit of an attached frame)
  cut      `cut(B, A, scene)` splits the repainted picture B back into layers: each sprite = B inside
           the sprite's own alpha (silhouettes and rigs stay the game's), the plate = B outside
           the sprites with the sprite holes filled from A (the bare-island job, concept-match.md
           section 6) or inpainted, and a contact-shadow layer = min(1, B / A) around each foot
           (multiply). Recomposited, it must equal B where every layer is opaque.

  python3 -I tools/looklab/repaint.py OUT_DIR [--frame best-day.png] [--state day]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lab  # noqa: E402
import scene as sc_mod  # noqa: E402

PALETTE = {"sky": (150, 200, 255), "sea": (235, 235, 245), "lawn": (60, 170, 70), "earth": (215, 160, 110)}
SPRITE_COLOURS = [(230, 60, 60), (240, 160, 30), (150, 70, 200), (40, 120, 220), (230, 90, 180), (20, 170, 170),
                  (120, 80, 40), (90, 90, 90)]

PROMPT = """REFERENCES (attached, in this order):
1. The image to edit: the game's home island, composed from its separate parts. Edit it; do not redraw its layout.
2. The layout mask of image 1: one flat colour per part. Every coloured shape is a part that must stay exactly where it is, at exactly its size and outline.
3. The look to match: a finished concept of the same island in the {light}. Copy ONLY its light, colour, softness and finish, never its layout or its props.

Repaint image 1 as one painting under one light, as if the whole island and everything on it had been painted together in the look of image 3: the same {light_words}; soft painted contact shadows under every building, prop and character where they touch the lawn; the lawn as a dense soft carpet with tiny flowers and stepping stones between the parts; the earth body under the lawn light honey and cream like image 3, with its round door lit warmly from inside; the cloud sea below soft and luminous. The windmill, the house, the garden, the pond, the tea stall, the lamp, Pofu the hamster and Mochi the bunny stay exactly where they are, at exactly their size, outline, pose and face, and keep their own colours: only their light and their finish join the rest of the picture.

KEEP: the canvas, the camera, the island's outline and position, every part's position, size and outline (image 2), Pofu's and Mochi's faces and eyes.

AVOID: moving, adding or removing any building, prop or character; new buildings; text; a border; outlines; harsh shadows; neon or saturated colours; a 3D render look; changing the camera or the framing.

Output: one image, landscape 1536 x 1024, the same framing as image 1."""

LIGHT_WORDS = {
    "day": ("summer noon", "clear warm noon light from the upper left, pale blue sky, white clouds, colour and value"),
    "golden": ("summer evening", "low peach evening light, pink and lilac sky, warm rims, colour and value"),
    "night": ("night", "moonlit night: indigo sky, the island still light and pastel, the lamp, the stall and the door lit warm"),
    "rain": ("rain", "soft rain light: lilac-grey sky, the island bright and fresh, wet glints"),
}


def layout_mask(s) -> np.ndarray:
    out = np.zeros((s.h, s.w, 3), np.uint8)
    lawn = (s.ids == 2) & s.lawn
    out[s.ids == 0] = PALETTE["sky"]
    out[s.ids == 1] = PALETTE["sea"]
    out[lawn] = PALETTE["lawn"]
    out[(s.ids == 2) & ~lawn] = PALETTE["earth"]
    for i, l in enumerate(s.layers):
        out[s.ids == 3 + i] = SPRITE_COLOURS[i % len(SPRITE_COLOURS)]
    return out


def job_yaml(state: str, frame_path: str, mask_path: str) -> str:
    light, words = LIGHT_WORDS[state]
    ref = lab.REF[state][0].relative_to(lab.REPO)
    body = PROMPT.format(light=light, light_words=words)
    indented = "\n".join("          " + ln if ln else "" for ln in body.splitlines())
    return f"""# Draft job (not queued): the look lab's harmonise-by-repaint test (docs/research/look-lab.md, section 7).
# To queue: copy into a batch manifest under tools/imagegen/manifest/, keep the attachment order.
  - id: x-lab-repaint-{state}
    kind: plate
    name: x-lab-repaint-{state}
    size: 1536x1024
    canvas: 1536x1024
    chat: "Pofu · Exploration"
    light: {{cell: {"day" if state == "rain" else state}, layer: subject}}
    notes: "Exploration. The lab's composed home frame repainted as one picture in the look of {ref.parent.name}. Review: no part moved or resized (overlay the layout mask), faces kept, contact shadows painted, one light."
    attach:
      - ref: {frame_path}
        role: "The image to edit. Edit it; do not redraw its layout."
      - ref: {mask_path}
        role: "The layout mask of the image to edit: every coloured shape stays exactly where it is."
      - ref: {ref}
        role: "The look to match: copy only its light, colour, softness and finish."
    prompt:
      - text: |
{indented}
"""


def cut(B: np.ndarray, s, A: np.ndarray | None = None) -> dict[str, np.ndarray]:
    """Split a repainted frame B (same canvas as the scene) back into the game's layers (RGBA, 0..1)."""
    layers = {}
    covered = s.ids >= 3
    for i, l in enumerate(s.layers):
        a = l.rgba[..., 3]
        rgba = np.concatenate([B, a[..., None]], -1) * (a[..., None] > 0)
        layers[l.name] = rgba
    plate_a = s.bg[..., 3]
    if A is not None:
        fill = A
    else:  # no bare-island take: fill the sprite holes from the surrounding plate (normalised blur)
        hole = covered.astype(float)
        keep = (1 - hole) * (plate_a > 0.5)
        fill = B.copy()
        for sig in (4, 12, 32):
            num = np.stack([ndimage.gaussian_filter(B[..., c] * keep, sig) for c in range(3)], -1)
            den = ndimage.gaussian_filter(keep, sig)[..., None]
            est = num / np.maximum(den, 1e-4)
            fill = np.where((covered & (den[..., 0] > 0.05))[..., None], est, fill)
    plate = np.where(covered[..., None], fill, B)
    layers["plate"] = np.concatenate([plate, plate_a[..., None]], -1)
    if A is not None:
        ring = ndimage.binary_dilation(covered, iterations=12) & ~covered & (plate_a > 0.5)
        ratio = np.clip(lab.luma(B) / np.maximum(lab.luma(A), 1e-3), 0, 1)
        layers["contact-shadow"] = np.stack([ratio] * 3 + [ring.astype(float)], -1)
    return layers


def recomposite(layers: dict, s, sky: np.ndarray) -> np.ndarray:
    f = sky.copy()
    p = layers["plate"]
    f = f * (1 - p[..., 3:]) + p[..., :3] * p[..., 3:]
    for l in s.layers:
        r = layers[l.name]
        f = f * (1 - r[..., 3:]) + r[..., :3] * r[..., 3:]
    return f


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("out_dir", type=Path)
    ap.add_argument("--frame", type=Path, help="the composed frame to repaint (default: the raw lab composite)")
    ap.add_argument("--state", default="day", choices=sorted(LIGHT_WORDS))
    ap.add_argument("--sheet", type=Path)
    a = ap.parse_args(argv)
    a.out_dir.mkdir(parents=True, exist_ok=True)
    s = sc_mod.Scene()
    if a.frame:
        frame = lab.load_rgb(a.frame)
    else:
        frame = s.raw(s.sky((0.56, 0.75, 0.95), (0.86, 0.92, 0.98)))
    # The edit runs at 1536 x 1024: the lab canvas (1200 x 800) has the same 3:2 aspect.
    big = (1536, 1024)
    lab.to_img(frame).resize(big, Image.Resampling.LANCZOS).save(a.out_dir / f"frame-{a.state}.webp", quality=90)
    mask = layout_mask(s)
    Image.fromarray(mask).resize(big, Image.Resampling.NEAREST).save(a.out_dir / "layout.png", optimize=True)
    rel = lambda p: str(p.resolve().relative_to(lab.REPO)) if p.resolve().is_relative_to(lab.REPO) else str(p)  # noqa: E731
    (a.out_dir / f"repaint-job-{a.state}.yaml").write_text(
        job_yaml(a.state, rel(a.out_dir / f"frame-{a.state}.webp"), rel(a.out_dir / "layout.png")))
    # Smoke test of the cut: B = the frame itself must recomposite to itself where layers are opaque.
    layers = cut(frame, s)
    rec = recomposite(layers, s, frame)
    opaque = (s.ids >= 2)
    err = float(lab.de2000(lab.lab(rec)[opaque], lab.lab(frame)[opaque]).mean())
    print(f"cut round trip: mean dE2000 {err:.2f} over the island")
    if a.sheet:
        ref = lab.to_img(lab.load_rgb(lab.REF[a.state][0], 1200))
        plate_only = lab.to_img(layers["plate"][..., :3] * layers["plate"][..., 3:] + (1 - layers["plate"][..., 3:]) * 0.95)
        m = Image.fromarray(mask)
        d = ImageDraw.Draw(m)
        for i, l in enumerate(s.layers):
            d.text((l.foot[0] - 20, l.foot[1] + 4), l.name, fill=(0, 0, 0), font=lab.font(14))
        lab.sheet([[(lab.to_img(frame), "1. frame to edit (lab scene)"), (m, "2. layout mask (one colour per layer)"),
                    (ref, f"3. look to match: {lab.REF[a.state][0].parent.name}")],
                   [(plate_only, "cut back: the plate with sprite holes filled\n(from the bare-island take A when it exists)"),
                    (lab.to_img(rec), f"recomposite of the cut layers\nround trip dE {err:.2f}")]],
                  a.sheet, "Experiment 5 (design): harmonise by repaint, the edit job's inputs and the cut back into layers",
                  cell_h=330)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
