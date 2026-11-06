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
FLAT = ("games", "ui", "glow", "sprite", "shield", "shield-icons", "app", "postcard")  # flat PNGs baked here, not through preblur
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


def source_file(entry: dict) -> Path | None:
    """The entry's source image: a `postcard` names the exploration take it was cut from (`source`,
    the provenance); every other target has a master folder."""
    if entry["target"] in ("postcard", "shield-icons"):
        path = REPO / entry["source"]
        return path if path.is_file() else None
    return master_file(entry["master"])


def output_path(entry: dict, targets: dict) -> Path:
    root = REPO / targets[entry["target"]]
    if entry["target"] == "postcard":
        return root / f"gate-postcard-{entry['name']}.imageset" / f"gate-postcard-{entry['name']}.jpg"
    if entry["target"] in ("glow", "sprite"):
        return root / f"{entry['name']}.imageset" / f"{entry['name']}.png"
    if entry["target"] in ("shield", "shield-icons"):
        return root / f"{entry['name']}.png"
    if entry["target"] == "app":
        return root / f"{entry['name']}.imageset" / f"{entry['name']}@3x.png"
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


def _imageset_contents(out: Path, scale: str | None = None) -> None:
    image = {"filename": out.name, "idiom": "universal"}
    if scale:
        image["scale"] = scale
    (out.parent / "Contents.json").write_text(json.dumps({
        "images": [image],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n", encoding="utf-8")


def _cut(image: Image.Image, entry: dict) -> Image.Image:
    """The entry's cell of a sheet (source pixels x0, y0, x1, y1), with the faint halation below
    `alpha_floor` cleared so a neighbour's glow never comes along."""
    if "cell" not in entry:
        return image
    image = image.crop(tuple(entry["cell"]))
    floor = entry.get("alpha_floor", 0)
    if floor:
        r, g, b, a = image.split()
        a = a.point(lambda v: 0 if v <= floor else round((v - floor) * 255 / (255 - floor)))
        image = Image.merge("RGBA", (r, g, b, a))
    return image


def _fit(image: Image.Image, entry: dict) -> Image.Image:
    max_w, max_h = (v * entry.get("scale", 3) for v in entry["points"])
    f = min(1.0, max_w / image.width, max_h / image.height)  # never upscale
    if f < 1.0:
        image = image.resize((max(1, round(image.width * f)), max(1, round(image.height * f))), Image.LANCZOS)
    return image


def bake_app(entry: dict, out: Path) -> None:
    """A full-bleed or layer plate for the app's own asset catalog (the launch sky, the cloud curtain).
    Harmony's correction, when the manifest has one, is applied first; `size` restores a plate the
    pipeline delivered at half scale (`deliver.original_size`) to its declared size, the one place art is
    scaled up, because the launch screen is a soft sky."""
    sys.path.insert(0, str(REPO / "tools" / "assets"))
    import harmony

    image = Image.open(master_file(entry["master"])).convert("RGBA")
    image = harmony.correct_image(entry["name"], image)
    if "size" in entry:
        image = image.convert("RGB").resize(tuple(entry["size"]), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG", optimize=True)
    _imageset_contents(out, "3x")


def bake_shield(entry: dict, out: Path) -> None:
    """One mood of Pofu at his door for the shield: the cell cut from the sheet, trimmed and set on a
    square, transparent canvas of `points` x `scale` px (the shield draws its icon square)."""
    image = trim(_cut(Image.open(master_file(entry["master"])).convert("RGBA"), entry))
    side = entry["points"][0] * entry.get("scale", 2)
    f = min(side / image.width, side / image.height, 1.0)
    image = image.resize((max(1, round(image.width * f)), max(1, round(image.height * f))), Image.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((side - image.width) // 2, side - image.height))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG", optimize=True)


def bake_shield_icon(entry: dict, out: Path) -> None:
    """One round mood icon for the shield, cut from an exploration take's `grid` ([columns, rows], reading
    order) at `index`: the cell trimmed, fitted into a square canvas of `points` x `scale` px and stored as a
    palette PNG (the extension has a few MB; each icon stays under 30 KB). An exploration take, never
    promoted: the `source` path in the map is its provenance."""
    image = Image.open(source_file(entry)).convert("RGBA")
    cols, rows = entry["grid"]
    row, col = divmod(entry["index"], cols)
    w, h = image.width // cols, image.height // rows
    image = trim(image.crop((col * w, row * h, (col + 1) * w, (row + 1) * h)))
    side = entry["points"][0] * entry.get("scale", 1)
    f = min(side / image.width, side / image.height)
    image = image.resize((max(1, round(image.width * f)), max(1, round(image.height * f))), Image.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((side - image.width) // 2, (side - image.height) // 2))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.quantize(colors=entry.get("colors", 192), method=Image.FASTOCTREE, dither=Image.Dither.NONE).save(out, "PNG", optimize=True)
    assert out.stat().st_size <= 30_000, f"{entry['name']}: {out.stat().st_size} bytes is over the 30 KB shield icon budget"


def bake_sprite(entry: dict, out: Path) -> None:
    """A coloured, alpha sprite for the world catalog that the scene draws in screen space (a firefly
    frame): cut, trimmed, fitted into `points` at `scale`, never upscaled."""
    image = trim(_cut(Image.open(master_file(entry["master"])).convert("RGBA"), entry))
    out.parent.mkdir(parents=True, exist_ok=True)
    _fit(image, entry).save(out, "PNG", optimize=True)
    _imageset_contents(out)


def bake_postcard(entry: dict, out: Path) -> None:
    """A full-bleed painted postcard for the gate landing (Hop!): the take cropped to `crop` (source pixels
    x0, y0, x1, y1, a portrait slice), the long side capped at `max_long` (1600), JPEG under 400 KB. An
    exploration take, never promoted: the `source` path in the map is its provenance."""
    image = Image.open(source_file(entry)).convert("RGB").crop(tuple(entry["crop"]))
    f = min(1.0, entry.get("max_long", 1600) / max(image.size))
    if f < 1.0:
        image = image.resize((round(image.width * f), round(image.height * f)), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "JPEG", quality=entry.get("quality", 86), optimize=True)
    assert out.stat().st_size <= 400_000, f"{entry['name']}: {out.stat().st_size} bytes is over the 400 KB postcard budget"
    _imageset_contents(out)


def bake_games(entry: dict, out: Path) -> None:
    if entry["target"] == "postcard":
        return bake_postcard(entry, out)
    if entry["target"] == "app":
        return bake_app(entry, out)
    if entry["target"] == "shield":
        return bake_shield(entry, out)
    if entry["target"] == "shield-icons":
        return bake_shield_icon(entry, out)
    if entry["target"] == "sprite":
        return bake_sprite(entry, out)
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
        if source_file(e) is None:
            found.append(f"{e['name']}: no source image ({e.get('source') or e.get('master')})")
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
