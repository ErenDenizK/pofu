#!/usr/bin/env python3
"""Pre-blurred shadow silhouettes for the world's casters (light and shadow v2, section 3).

    python3 -I tools/assets/shadows.py run     # write every missing or stale <name>-shadow imageset
    python3 -I tools/assets/shadows.py check   # fail if a caster lacks a shadow or one is stale (CI)
    python3 -I tools/assets/shadows.py list    # the casters

A caster is a world sprite that stands on the ground and so throws a shadow: the stations at every
level, the residents and their poses, the decor, the dressing, the critters and the visitors. The
exclusions are listed below (plates, sky, islands, clouds, glows, depth-blur variants and the
debug/grade variants). For each caster the script writes `<imageset>-shadow.imageset` into the
same catalog: black RGB, alpha = the source alpha downscaled to 1/4 and blurred by 3 % of its
height. The app draws it flattened and sheared (`ShadowBake`, `MovingShadow`); there is no blur at
runtime. A caster with no PNG yet (Pofu is the live companion view) is skipped.

Deterministic: same sources and settings in, same pixels out. The sidecar `shadows.json` records
the source hash and settings of every shadow, so `check` needs no pixel comparison.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

from PIL import Image, ImageFilter

REPO = Path(__file__).resolve().parents[2]
CATALOG = REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
MANIFEST = Path(__file__).resolve().parent / "shadows.json"

# Bump when the algorithm or its numbers change: every shadow is then stale.
VERSION = 1
DOWNSCALE = 4
BLUR_FRACTION = 0.03  # of the downscaled height
MIN_BLUR = 0.6
SUFFIX = "-shadow"

# World imagesets that do not cast: plates and islands, the sky, the weather FX, the glow overlays, and the pipeline's
# variants (depth blur `__soft` / `__deep`, normals and the grade experiments `--...`) and the look LUTs (`world-lut-`).
EXCLUDE = re.compile(
    r"(^world-(island-|isle-|far-isle|cloud|harbor-island|fog-card|rain-tile|rainbow-arc|puddle-glint|light-shaft|lut-))|-standin|-glow|__|--"
)
# Home props from the UI catalog that stand on the lawn.
EXTRA_CASTERS = ("ui-jar-empty", "ui-lantern-off")


def casters(catalog: Path = CATALOG) -> list[str]:
    """The imageset stems (`world-mochi`, `ui-jar-empty`) that cast, sorted."""
    names = []
    for entry in sorted(catalog.glob("*.imageset")):
        stem = entry.name[: -len(".imageset")]
        if stem.endswith(SUFFIX):
            continue
        if stem in EXTRA_CASTERS or (stem.startswith("world-") and not EXCLUDE.search(stem)):
            names.append(stem)
    return names


def source_png(stem: str, catalog: Path = CATALOG) -> Path | None:
    path = catalog / f"{stem}.imageset" / f"{stem}.png"
    return path if path.is_file() else None


def source_hash(path: Path) -> str:
    h = hashlib.sha256()
    h.update(f"v{VERSION}/{DOWNSCALE}/{BLUR_FRACTION}/{MIN_BLUR}".encode())
    h.update(path.read_bytes())
    return h.hexdigest()


def silhouette(image: Image.Image) -> Image.Image:
    """The blurred black silhouette at 1/DOWNSCALE of the source's pixel size."""
    alpha = image.convert("RGBA").getchannel("A")
    w = max(1, round(alpha.width / DOWNSCALE))
    h = max(1, round(alpha.height / DOWNSCALE))
    small = alpha.resize((w, h), Image.BOX)
    blurred = small.filter(ImageFilter.GaussianBlur(max(MIN_BLUR, BLUR_FRACTION * h)))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.putalpha(blurred)
    return out


def contents_json(stem: str) -> str:
    return json.dumps(
        {
            "images": [{"filename": f"{stem}{SUFFIX}.png", "idiom": "universal"}],
            "info": {"author": "xcode", "version": 1},
        },
        indent=2,
    ) + "\n"


def output_dir(stem: str, catalog: Path = CATALOG) -> Path:
    return catalog / f"{stem}{SUFFIX}.imageset"


def load_manifest(path: Path = MANIFEST) -> dict:
    if not path.is_file():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def problems(catalog: Path = CATALOG, manifest_path: Path = MANIFEST) -> list[str]:
    """Everything `check` fails on: missing, stale and orphaned shadows."""
    manifest = load_manifest(manifest_path)
    found = []
    wanted = set()
    for stem in casters(catalog):
        src = source_png(stem, catalog)
        if src is None:
            continue
        wanted.add(stem)
        out = output_dir(stem, catalog) / f"{stem}{SUFFIX}.png"
        if not out.is_file():
            found.append(f"{stem}: no shadow")
        elif manifest.get(stem) != source_hash(src):
            found.append(f"{stem}: shadow is stale")
    for entry in sorted(catalog.glob(f"*{SUFFIX}.imageset")):
        stem = entry.name[: -len(SUFFIX + ".imageset")]
        if stem not in wanted:
            found.append(f"{entry.name}: no such caster")
    return found


def run(catalog: Path = CATALOG, manifest_path: Path = MANIFEST) -> int:
    """Writes every missing or stale shadow and removes orphans; returns how many it wrote."""
    manifest = load_manifest(manifest_path)
    written = 0
    kept: dict[str, str] = {}
    for stem in casters(catalog):
        src = source_png(stem, catalog)
        if src is None:
            continue
        digest = source_hash(src)
        kept[stem] = digest
        target = output_dir(stem, catalog)
        png = target / f"{stem}{SUFFIX}.png"
        if png.is_file() and manifest.get(stem) == digest:
            continue
        target.mkdir(parents=True, exist_ok=True)
        with Image.open(src) as image:
            silhouette(image).save(png, optimize=True)
        (target / "Contents.json").write_text(contents_json(stem), encoding="utf-8")
        written += 1
    for entry in sorted(catalog.glob(f"*{SUFFIX}.imageset")):
        stem = entry.name[: -len(SUFFIX + ".imageset")]
        if stem not in kept:
            for child in entry.iterdir():
                child.unlink()
            entry.rmdir()
    manifest_path.write_text(json.dumps(kept, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("command", choices=("run", "check", "list"))
    args = parser.parse_args(argv)
    if args.command == "list":
        print("\n".join(casters()))
        return 0
    if args.command == "run":
        print(f"wrote {run()} shadow(s)")
        return 0
    found = problems()
    for line in found:
        print(line, file=sys.stderr)
    if found:
        print("run: python3 -I tools/assets/shadows.py run", file=sys.stderr)
        return 1
    print(f"{len(casters())} casters, shadows current")
    return 0


if __name__ == "__main__":
    sys.exit(main())
