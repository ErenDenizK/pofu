#!/usr/bin/env python3
"""Approved masters into the app's asset folders, repeatably.

    python3 -I tools/assets/integrate.py run      # bake every mapped image
    python3 -I tools/assets/integrate.py check    # every entry has a master and an output

The map is tools/assets/integration_map.json (master folder -> imageset name and
target). `games` entries are copied, trimmed and resized here (Pillow only, deterministic:
same masters in, same pixels out); the home objects (pots, jar) and, inside preblur, the world
props and stations pass through the vividness regrade, tools/assets/vivid.py. `world` entries are sprites that need blur variants,
footprints and the generated Swift table, so `run` delegates them to
design/prototypes/interactions/tools/preblur.py app and then checks the imageset exists.
Only the slice's assets are mapped; the rest of the world catalog still comes from preblur.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vivid  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
FLAT = ("games", "ui", "glow")  # flat PNGs baked here, not through preblur
MAP = Path(__file__).resolve().parent / "integration_map.json"
PREBLUR = REPO / "design/prototypes/interactions/tools/preblur.py"


def load_map() -> dict:
    return json.loads(MAP.read_text(encoding="utf-8"))


def master_file(folder: str) -> Path | None:
    """A master folder's image: the lock-light re-lock when adopted, else the master (same order as
    preblur's `_master` and harmony.py)."""
    base = REPO / folder
    for candidate in (f"{base.name}--graded.webp", f"{base.name}--lock-light.png", f"{base.name}.png", f"{base.name}.webp"):
        if (base / candidate).is_file():
            return base / candidate
    return None


def output_path(entry: dict, targets: dict) -> Path:
    root = REPO / targets[entry["target"]]
    if entry["target"] == "glow":
        return root / f"{entry['name']}.imageset" / f"{entry['name']}.png"
    if entry["target"] in FLAT:
        return root / f"{entry['name']}.png"
    return root / f"world-{entry['name']}.imageset" / f"world-{entry['name']}.png"


def trim(image: Image.Image) -> Image.Image:
    box = image.getchannel("A").point(lambda a: 255 if a > 6 else 0).getbbox()
    return image.crop(box) if box else image


def glow_alpha(image: Image.Image) -> Image.Image:
    """An additive glow on black as white on alpha: alpha is the brightest channel, so the app tints it
    with the source's colour (`Canvas` shading) and adds it (plus-lighter) without a black box."""
    rgb = image.convert("RGB")
    alpha = max_channel(rgb)
    white = Image.new("RGBA", rgb.size, (255, 255, 255, 0))
    white.putalpha(alpha)
    return white


def max_channel(rgb: Image.Image) -> Image.Image:
    from PIL import ImageChops

    r, g, b = rgb.split()
    return ImageChops.lighter(ImageChops.lighter(r, g), b)


def bake_games(entry: dict, out: Path) -> None:
    src = master_file(entry["master"])
    if entry["target"] == "glow":
        image = Image.open(src).convert("RGBA")
        max_w, max_h = (v * entry.get("scale", 3) for v in entry["points"])
        f = min(1.0, max_w / image.width, max_h / image.height)
        if f < 1.0:
            image = image.resize((max(1, round(image.width * f)), max(1, round(image.height * f))), Image.LANCZOS)
        out.parent.mkdir(parents=True, exist_ok=True)
        glow_alpha(image).save(out, "PNG", optimize=True)
        contents = out.parent / "Contents.json"
        contents.write_text(json.dumps({
            "images": [{"filename": out.name, "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n", encoding="utf-8")
        return
    image = trim(Image.open(src).convert("RGBA"))
    scale = entry.get("scale", 3)
    max_w, max_h = (v * scale for v in entry["points"])
    f = min(1.0, max_w / image.width, max_h / image.height)  # never upscale
    if f < 1.0:
        image = image.resize((max(1, round(image.width * f)), max(1, round(image.height * f))), Image.LANCZOS)
    if entry["target"] == "ui":
        image = vivid.regrade_image(entry["name"], image, target="ui")  # home objects only (vivid.json)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG", optimize=True)


def problems(data: dict) -> list[str]:
    found, seen = [], set()
    for e in data["entries"]:
        key = (e["target"], e["name"])
        if key in seen:
            found.append(f"duplicate entry {key}")
        seen.add(key)
        if e["target"] not in data["targets"]:
            found.append(f"{e['name']}: unknown target {e['target']}")
            continue
        if master_file(e["master"]) is None:
            found.append(f"{e['name']}: no master in {e['master']}")
        out = output_path(e, data["targets"])
        if not out.is_file():
            found.append(f"{e['name']}: output missing ({out.relative_to(REPO)}); run integrate.py run")
    return found


def check(data: dict) -> int:
    found = problems(data)
    for line in found:
        print("FAIL", line, file=sys.stderr)
    return 1 if found else 0


def run(data: dict) -> int:
    if any(e["target"] == "world" for e in data["entries"]):
        subprocess.run([sys.executable, "-I", str(PREBLUR), "app"], check=True)
    for e in data["entries"]:
        if e["target"] in FLAT:
            bake_games(e, output_path(e, data["targets"]))
            print("baked", e["name"])
    return check(data)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("command", choices=["run", "check"])
    cmd = ap.parse_args().command
    data = load_map()
    return run(data) if cmd == "run" else check(data)


if __name__ == "__main__":
    sys.exit(main())
