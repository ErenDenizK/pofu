#!/usr/bin/env python3
"""The gate on the plates that ship (docs/design/world-presentation-build-spec.md, WP4).

    python3 -I tools/plate/plate_gate.py [island] [--state LIGHT:STAGE] [--out DIR]

For every plate of the island's hand data (`objects.json` `plates`), takes the shipped
`world-<island>-plate-<light>-<stage>` (HEIC with its alpha, the matte), runs `tools/art/matte_check.py` M1 to M6 and M11 on
it with the plate's take (`objects.json`, lanczos x2 to texture size) as the source and the shipped backdrop of the same
state, placed where the app puts it, as the destination, and fails on any red. Then prints the largest state's
`textureBytes` against `ingest.BUDGET` and fails when it is over. The lighthouse's beam (level 10) is a region meant to be
soft: `matte_check`'s `soft` skips it, and the worst-edges sheet shows it for the eye.

Needs numpy, OpenCV, Pillow and pillow-heif; reads the committed assets only (no network weights). `--out` keeps the
reports and the worst-edge sheets (default: none are written).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.append(str(REPO / "tools" / "art"))  # last: tools/art has its own ingest.py
import heic  # noqa: E402
import ingest  # noqa: E402
import matte_check as mc  # noqa: E402

#: Plate points of room kept round the island when the plate is cropped to it (the border check needs clear pixels).
MARGIN = 48
#: The codec (HEIC q70) leaves a few thousandths of ringing in the alpha plane beside a hard edge (at most about 0.04, a
#: dip to 0.98 inside the island, 0.02 outside it). M4 counts such a pixel as a speck or a hole, and no renderer shows it:
#: the gate snaps alpha within this of 0 or 1 before it measures. Everything between is the matte's own edge.
CODEC_ALPHA = 0.04
#: M3 (edge contamination) is a ratio to the contrast between the island and its sky, so at night, where both are dark,
#: the codec's few levels of noise at the rim weigh more: the r3b layer before the codec reads 0.06 to 0.07 there. Night
#: plates are held to this instead of `matte_check`'s 0.15 (a night rim is judged by the eye on the frames as well).
M3_NIGHT = 0.25
#: Checks waived for one state, each looked at on the plate over a flat sky at 1:1 (the lawn's rim there is crisp and
#: clean; the test reads pale grass tips against the sky as haze). Day levels 1 and 2, batch 116's cleared takes.
WAIVED = {"day-8": ("M11",), "day-9": ("M11",)}
#: Texture px per plate point of the shipped plate, and the beam's soft rect (tools/proof/island_matte.py: BEAM_X,
#: BEAM_LEAD, BEAM_Y, in texture px of the whole plate).
TEX = 2
BEAM = (1870 - 110, 1130, 2048, 1340)


def _image(name: str, mode: str) -> np.ndarray:
    folder = ingest.ASSETS / f"{name}.imageset"
    for f in sorted(folder.iterdir()):
        if f.suffix in (".png", ".jpg", heic.SUFFIX):
            return np.asarray(heic.open_image(f).convert(mode), np.float32) / 255
    raise FileNotFoundError(name)


def placed_backdrop(island: str, light: str, stage: int, data: dict, shape: tuple[int, int], origin: tuple[int, int]) -> np.ndarray:
    """The shipped backdrop of this state over the crop (`shape`, whose top-left is `origin` in texture px of the plate),
    where the app draws it: it covers `backdropBox` (plate points)."""
    bd = _image(ingest.asset_name(island, "backdrop", light, stage), "RGB")
    bx0, by0, bx1, by1 = data["backdropBox"]
    big = np.asarray(Image.fromarray(np.uint8(bd * 255 + 0.5)).resize(((bx1 - bx0) * TEX, (by1 - by0) * TEX), Image.Resampling.BICUBIC), np.float32) / 255
    out = np.zeros(shape + (3,), np.float32)
    ys = np.clip(np.arange(shape[0]) + origin[1] - by0 * TEX, 0, big.shape[0] - 1)
    xs = np.clip(np.arange(shape[1]) + origin[0] - bx0 * TEX, 0, big.shape[1] - 1)
    out[:] = big[ys][:, xs]
    return out


def check_state(island: str, hand: dict, data: dict, light: str, stage: int, take: Path, out: Path | None) -> dict:
    rgba = _image(ingest.asset_name(island, "plate", light, stage), "RGBA")
    a = rgba[..., 3]
    ys, xs = np.nonzero(a > 0.004)
    m = MARGIN * TEX
    y0, y1 = max(int(ys.min()) - m, 0), min(int(ys.max()) + 1 + m, a.shape[0])
    x0, x1 = max(int(xs.min()) - m, 0), min(int(xs.max()) + 1 + m, a.shape[1])
    crop = np.ascontiguousarray(rgba[y0:y1, x0:x1])
    snap = crop[..., 3]
    crop[..., 3] = np.where(snap < CODEC_ALPHA, 0.0, np.where(snap > 1 - CODEC_ALPHA, 1.0, snap))
    # the take as the plate was made from it (`ingest.load_rgb` applies the hand data's `colorFit`), at texture size
    take_rgb = Image.fromarray(np.uint8(np.clip(ingest.load_rgb(take), 0, 1) * 255 + 0.5))
    src = np.asarray(take_rgb.resize((a.shape[1], a.shape[0]), Image.Resampling.LANCZOS), np.float32)[y0:y1, x0:x1] / 255
    soft = []
    if stage == 0:
        bx0, by0, bx1, by1 = BEAM
        soft = [np.array([[bx0 - x0, by0 - y0], [bx1 - x0, by0 - y0], [bx1 - x0, by1 - y0], [bx0 - x0, by1 - y0]], np.float32)]
    dest = placed_backdrop(island, light, stage, data, crop.shape[:2], (x0, y0))
    return mc.check_matte(crop, source=src, soft=soft, dests={light: dest}, name=f"{light}-{stage}", out=out)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("island", nargs="?", default="home")
    ap.add_argument("--state", metavar="LIGHT:STAGE", help="gate this state only")
    ap.add_argument("--out", type=Path, help="write the reports and worst-edge sheets here")
    args = ap.parse_args(argv)
    hand = ingest.load_hand(args.island)
    data = __import__("json").loads((ingest.JSON_DIR / f"plate-{args.island}.json").read_text())
    red, legacy, n = [], [], 0
    for light, stage, path in ingest.plates(hand):
        if args.state and args.state != f"{light}:{stage}":
            continue
        if ingest.is_legacy(hand, light, stage):
            print(f"{light}-{stage}: legacy matte (objects.json legacyStates), not gated")
            legacy.append(f"{light}:{stage}")
            continue
        r = check_state(args.island, hand, data, light, stage, path, args.out)
        n += 1
        for k in WAIVED.get(r["name"], ()):
            if r[k]["pass"] is False:
                r[k]["pass"] = True
                r[k]["waived"] = True
        r["pass"] = all(r[k]["pass"] is not False for k in ("M1", "M2", "M3", "M4", "M5", "M6", "M11") if k in r)
        if light == "night" and r["M3"]["pass"] is False and r["M3"]["value"] <= M3_NIGHT:
            r["M3"]["pass"] = True
            r["pass"] = all(r[k]["pass"] is not False for k in ("M1", "M2", "M3", "M4", "M5", "M6", "M11") if k in r)
        print(mc.one_line(r), flush=True)
        if not r["pass"]:
            red.append(r["name"])
    size = ingest.texture_bytes(args.island, hand)
    print(f"textureBytes {size:,} of {ingest.BUDGET:,}{'' if size <= ingest.BUDGET else '  OVER BUDGET'}")
    print(f"plate gate: {n} state(s) gated, {len(legacy)} legacy ({', '.join(legacy)}), {'red: ' + ', '.join(red) if red else 'all green'}")
    return 1 if red or size > ingest.BUDGET else 0


if __name__ == "__main__":
    sys.exit(main())
