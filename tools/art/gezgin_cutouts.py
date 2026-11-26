#!/usr/bin/env python3
"""Ingest the Gezgin's moored cut-outs (pofu-art batches 160, 180) into World.xcassets.

One cut-out per level and state (asleep, awake), one tail piece and one shadow per level, all cut to
one shared box of the 1536 x 1024 take canvas so that code can stack them without registration data
(`PofuWorld/Gezgin`). The picks are the QA auto-picks recorded in each take's review.yaml.

    python3 -I tools/art/gezgin_cutouts.py <pofu-art checkout> [--width 760]

Prints the numbers `world-map.json` `gezgin.art` carries. Needs Pillow.
"""
import argparse, json, pathlib, re, sys
from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
ASSETS = HERE.parents[1] / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
# (kind, level) -> (batch, job); `awake` is eyes open, `cut` is eyes closed (asleep).
JOBS = {
    **{("awake", n): (f"batch-160-gezgin-source", f"x4-gez-lv{n}-awake") for n in (1, 2, 3)},
    **{("asleep", n): (f"batch-160-gezgin-source", f"x4-gez-lv{n}-cut") for n in (1, 2, 3)},
    **{("tail", n): ("batch-180-gezgin-tail-shadow", f"x8-gez-lv{n}-tail") for n in (1, 2, 3)},
    **{("shadow", n): ("batch-180-gezgin-tail-shadow", f"x8-gez-lv{n}-shadow") for n in (1, 2, 3)},
}


def pick(root: pathlib.Path, batch: str, job: str) -> pathlib.Path:
    folder = root / "design/art/takes" / batch / job
    text = (folder / "review.yaml").read_text()
    m = re.search(r"^selection:.*?^  pick: (\d+)", text, re.M | re.S)
    n = m.group(1) if m else "1"
    return next(folder.glob(f"*--t{n}.webp"))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("art", type=pathlib.Path)
    ap.add_argument("--width", type=int, default=760)
    args = ap.parse_args()
    ims = {key: Image.open(pick(args.art, *job)).convert("RGBA") for key, job in JOBS.items()}
    # The shared box: the union of the bodies' solid pixels (tails and shadows lie inside or are cut to it).
    boxes = [im.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()
             for (kind, _), im in ims.items() if kind in ("awake", "asleep")]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    pad = 6
    box = (max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, 1536), min(y1 + pad, 1024))
    scale = args.width / (box[2] - box[0])
    size = (args.width, round((box[3] - box[1]) * scale))
    for (kind, level), im in ims.items():
        out = im.crop(box).resize(size, Image.LANCZOS)
        name = f"world-gezgin-l{level}-{kind}"
        folder = ASSETS / f"{name}.imageset"
        folder.mkdir(exist_ok=True)
        out.save(folder / f"{name}.png", optimize=True)
        (folder / "Contents.json").write_text(json.dumps(
            {"images": [{"filename": f"{name}.png", "idiom": "universal"}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    # The body's solid box and the tail's root, in the shared box's pixels: where code pivots the tail.
    body = boxes[0]
    print(json.dumps({"canvas": list(size), "box": list(box), "body": [round((body[0] - box[0]) * scale), round((body[1] - box[1]) * scale), round((body[2] - box[0]) * scale), round((body[3] - box[1]) * scale)]}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
