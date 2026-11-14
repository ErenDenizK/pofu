#!/usr/bin/env python3
"""Approved masters into the app's asset folders, repeatably.

    python3 -I tools/assets/integrate.py run      # bake every mapped image
    python3 -I tools/assets/integrate.py check    # every entry has a master and an output
    python3 -I tools/assets/integrate.py run --target kit   # one target only: never runs preblur or
                                                            # touches World.xcassets unless `world` is named

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
FLAT = ("games", "ui", "glow", "sprite", "shield", "shield-icons", "app", "postcard", "fx", "icons-duo", "kit")  # flat PNGs baked here, not through preblur
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
    """The entry's source image: an entry with a `source` names the exploration take it was cut from (the
    provenance: shield icons, weather FX, the two-tone icons); every other entry has a master folder."""
    if "source" in entry:
        path = REPO / entry["source"]
        return path if path.is_file() else None
    return master_file(entry["master"])


def output_path(entry: dict, targets: dict) -> Path:
    root = REPO / targets[entry["target"]]
    if entry["target"] == "postcard":
        return root / f"gate-postcard-{entry['name']}.imageset" / f"gate-postcard-{entry['name']}.jpg"
    if entry["target"] in ("glow", "sprite", "fx"):
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
    """A full-bleed painted postcard for the gate landing (Hop!): a gate master (batch 50, `master`, restored
    to `size`) or an exploration take (`source`, cropped to `crop`, a portrait slice), the long side capped at
    `max_long` (1600), JPEG under 400 KB."""
    image = Image.open(source_file(entry)).convert("RGB")
    if "crop" in entry:
        image = image.crop(tuple(entry["crop"]))
    if "size" in entry:  # a master delivered at half scale, restored to its declared size (a soft painted sky)
        image = image.resize(tuple(entry["size"]), Image.LANCZOS)
    f = min(1.0, entry.get("max_long", 1600) / max(image.size))
    if f < 1.0:
        image = image.resize((round(image.width * f), round(image.height * f)), Image.LANCZOS)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "JPEG", quality=entry.get("quality", 86), optimize=True)
    assert out.stat().st_size <= 400_000, f"{entry['name']}: {out.stat().st_size} bytes is over the 400 KB postcard budget"
    _imageset_contents(out)


def _luminance_alpha(image: Image.Image, colour: bool) -> Image.Image:
    """Light on black as an alpha image: alpha is the brightest channel; `colour` keeps the hue (the pixel
    divided by its alpha), else the light is white and the app tints it."""
    import numpy as np

    rgb = np.asarray(image.convert("RGB"), dtype=np.float64)
    alpha = rgb.max(axis=2)
    if colour:
        out = rgb / np.maximum(alpha, 1.0)[..., None] * 255.0
    else:
        out = np.full_like(rgb, 255.0)
    return Image.fromarray(np.dstack([np.clip(out, 0, 255), alpha]).round().astype("uint8"), "RGBA")


def _seamless(image: Image.Image) -> Image.Image:
    """Makes a tile wrap: the tile blended with itself rolled by half in both axes, weighted so the seams
    show only the rolled copy (whose own edges are the tile's continuous middle). An RGBA tile is blended
    through premultiplied colour: blended straight, a streak met the black colour of the clear pixels and came
    out as a dark half-alpha twin (the rain's dark smeared streaks, 2026-11)."""
    import numpy as np

    a = np.asarray(image, dtype=np.float64)
    h, w = a.shape[:2]
    ramp = lambda n: np.sin(np.pi * (np.arange(n) + 0.5) / n) ** 2
    weight = (ramp(h)[:, None] * ramp(w)[None, :])[..., None]
    alpha = image.mode == "RGBA"
    if alpha:
        a = np.concatenate([a[..., :3] * a[..., 3:] / 255.0, a[..., 3:]], -1)
    rolled = np.roll(a, (h // 2, w // 2), axis=(0, 1))
    out = a * weight + rolled * (1 - weight)
    if alpha:
        al = out[..., 3:]
        out = np.concatenate([np.where(al > 0.5, out[..., :3] * 255.0 / np.maximum(al, 0.5), 0), al], -1)
    return Image.fromarray(np.clip(out, 0, 255).round().astype("uint8"), image.mode)


def bake_fx(entry: dict, out: Path) -> None:
    """A weather or light FX plate from a light-on-black exploration take (batch 44): the light becomes alpha
    (`colour` keeps its hue, else white for the app to tint), trimmed where `trim` (a luminance floor) says
    and either stretched to `canvas` (the fog cards, which the app lays out at one ratio) or fitted into
    `points` x `scale`; `tile` makes a rain tile wrap (centre-cropped to `crop` first). The `source` take is
    the provenance."""
    image = Image.open(source_file(entry)).convert("RGB")
    if "crop" in entry:
        image = image.crop(tuple(entry["crop"]))
    image = _luminance_alpha(image, entry.get("colour", False))
    if entry.get("tile"):
        image = _seamless(image.resize(tuple(entry["canvas"]), Image.LANCZOS))
    else:
        floor = entry.get("trim", 8)
        box = image.getchannel("A").point(lambda v: 255 if v > floor else 0).getbbox()
        image = image.crop(box)
        if "canvas" in entry:
            image = image.resize(tuple(entry["canvas"]), Image.LANCZOS)
        else:
            image = _fit(image, entry)
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG", optimize=True)
    _imageset_contents(out)


def bake_icon_duo(entry: dict, out: Path) -> None:
    """One two-tone icon of the 3x3 sheet (reading order, `index`): the cell trimmed and centred on a square
    canvas of `points` x `scale` px, all icons at one shared scale so they weigh the same. The `source`
    take is the provenance."""
    image = Image.open(source_file(entry)).convert("RGBA")
    cols, rows = entry["grid"]
    w, h = image.width // cols, image.height // rows
    cells = [trim(image.crop((c * w, r * h, (c + 1) * w, (r + 1) * h))) for r in range(rows) for c in range(cols)]
    biggest = max(max(cell.size) for cell in cells)
    side = entry["points"][0] * entry.get("scale", 3)
    f = side * 0.94 / biggest
    cell = cells[entry["index"]]
    cell = cell.resize((max(1, round(cell.width * f)), max(1, round(cell.height * f))), Image.LANCZOS)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(cell, ((side - cell.width) // 2, (side - cell.height) // 2))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG", optimize=True)


def _recolour(image: Image.Image, pair: list[str]) -> Image.Image:
    """Night as a recolour of the picked day piece (asset system v1 section 2.1): each channel's
    mean and spread over the opaque pixels are moved from the day master of `pair` to its night
    master. Used only where a night twin was never painted (the bubble's tail)."""
    import numpy as np

    def stats(path: Path):
        px = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64).reshape(-1, 4)
        px = px[px[:, 3] > 200][:, :3]
        return px.mean(axis=0), px.std(axis=0)

    (dm, ds), (nm, ns) = (stats(master_file(folder)) for folder in pair)
    a = np.asarray(image, dtype=np.float64)
    a[..., :3] = np.clip((a[..., :3] - dm) / np.maximum(ds, 1e-6) * ns + nm, 0, 255)
    return Image.fromarray(np.rint(a).astype(np.uint8), "RGBA")


def _lift(image: Image.Image, lift: dict) -> Image.Image:
    """Lighten a face toward a warm tone: every colour moves `by` of the way to `toward`; alpha is
    untouched. The night linen was a heavy slab under Home's daily line (a lighter slab, same grain)."""
    import numpy as np

    a = np.asarray(image, dtype=np.float64).copy()
    target = np.array(lift["toward"], dtype=np.float64)
    a[..., :3] += (target - a[..., :3]) * float(lift["by"])
    return Image.fromarray(np.rint(np.clip(a, 0, 255)).astype(np.uint8), "RGBA")


def bake_kit(entry: dict, out: Path) -> None:
    """A kit face under its `PofuKitArt` hook name: the sheet's cell (when the master is a sheet),
    trimmed to the painted silhouette and fitted inside `points` at 3x. The Swift side slices it
    (`PofuKitArt.slicing`), so the bake never pads or crops into the paint."""
    image = _cut(Image.open(master_file(entry["master"])).convert("RGBA"), entry)
    if entry.get("trim", True):  # a set that must share one canvas (the pip pots) keeps it
        image = trim(image)
    image = _fit(image, entry)
    if "recolour" in entry:
        image = _recolour(image, entry["recolour"])
    if "lift" in entry:
        image = _lift(image, entry["lift"])
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG", optimize=True)


def bake_games(entry: dict, out: Path) -> None:
    if entry["target"] == "kit":
        return bake_kit(entry, out)
    if entry["target"] == "fx":
        return bake_fx(entry, out)
    if entry["target"] == "icons-duo":
        return bake_icon_duo(entry, out)
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


def select(data: dict, targets: list[str] | None) -> dict:
    """The map narrowed to the named targets (`None`: all). A kit bake never touches the world assets."""
    if not targets:
        return data
    unknown = [t for t in targets if t not in data["targets"]]
    if unknown:
        raise SystemExit(f"unknown target {', '.join(unknown)}; known: {', '.join(data['targets'])}")
    return {**data, "entries": [e for e in data["entries"] if e["target"] in targets]}


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
    ap.add_argument("--target", action="append", metavar="NAME",
                    help="only this target's entries (repeatable); preblur runs only when `world` is among them")
    args = ap.parse_args()
    data = select(load_map(), args.target)
    return run(data) if args.command == "run" else check(data)


if __name__ == "__main__":
    sys.exit(main())
