#!/usr/bin/env python3
"""Build Pofu Atlas: content/ -> design/atlas/index.html plus design/atlas/thumbs/.

    python3 -I tools/content/build_atlas.py

The page is one self-contained file (inline CSS and JS, the content graph as
one inline JSON blob) that loads only its thumbnails: WebP files in
design/atlas/thumbs/, 320 px for cards and 720 px for the detail drawer.
Thumbnails are build output (git-ignored); images that live on an art branch
(`art.images: [{path, branch}]`) are read with `git show` when the branch is
fetched. The page is published as an Artifact with the capabilities
{db: {}, user: {}, comments: {"composer_only": true}}; see content/README.md.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate import REPO, image_path, validate  # noqa: E402

OUT_DIR = REPO / "design" / "atlas"
TEMPLATE = Path(__file__).resolve().parent / "atlas_template.html"
SIZES = {"s": 320, "l": 720}
KEEP = ("id", "type", "title_tr", "title_en", "status", "horizon", "summary", "notes", "links",
        "sources", "source", "kind", "group", "board", "act", "sequence", "unlock", "stages",
        "levels", "residents", "resident", "home", "station", "theme_en", "ritual_en", "opens_en",
        "species_en", "line_tr", "batch", "size")


def read_image(path: str, branch: str | None) -> bytes | None:
    f = REPO / path
    if f.is_file():
        return f.read_bytes()
    if branch:
        for ref in (f"origin/{branch}", branch):
            r = subprocess.run(["git", "-C", str(REPO), "show", f"{ref}:{path}"], capture_output=True)
            if r.returncode == 0:
                return r.stdout
    return None


def make_thumbs(path: str, branch: str | None, out: Path, force: bool) -> dict | None:
    key = hashlib.sha1(f"{branch or ''}:{path}".encode()).hexdigest()[:12]
    names = {k: f"thumbs/{key}-{k}.webp" for k in SIZES}
    meta_file = out / "thumbs" / f"{key}.json"
    if not force and meta_file.is_file() and all((out / n).is_file() for n in names.values()):
        return json.loads(meta_file.read_text())
    raw = read_image(path, branch)
    if raw is None:
        return None
    try:
        im = Image.open(io.BytesIO(raw))
        im.load()
    except Exception as e:  # a truncated upload must not stop the build
        print(f"warning: cannot read {path}: {e}")
        return None
    im = im.convert("RGBA")
    bbox = im.getchannel("A").getbbox()  # trim transparent margins so small props fill the card
    if bbox:
        pad = round(max(im.size) * 0.02)
        im = im.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                      min(im.width, bbox[2] + pad), min(im.height, bbox[3] + pad)))
    meta = {"w": im.width, "h": im.height}
    for k, side in SIZES.items():
        t = im.copy()
        t.thumbnail((side, side), Image.LANCZOS)
        t.save(out / names[k], "WEBP", quality=82, method=6)
        meta[k] = names[k]
    meta["w"], meta["h"] = Image.open(out / names["s"]).size
    meta_file.write_text(json.dumps(meta))
    return meta


def git_stamp() -> str:
    r = subprocess.run(["git", "-C", str(REPO), "log", "-1", "--format=%cs %h"], capture_output=True, text=True)
    return r.stdout.strip() or date.today().isoformat()


def build(force_thumbs: bool = False) -> tuple[Path, dict]:
    errors, warnings, nodes = validate()
    if errors:
        for e in errors:
            print(f"error: {e}")
        raise SystemExit("Content does not validate; fix it before building the atlas.")
    for w in warnings:
        print(f"warning: {w}")

    (OUT_DIR / "thumbs").mkdir(parents=True, exist_ok=True)
    by_id = {n["id"]: n for n in nodes}
    thumbs: dict[str, dict] = {}
    images_of: dict[str, list[str]] = {}

    for n in nodes:
        keys = []
        for img in (n.get("art") or {}).get("images") or []:
            path, branch = image_path(img)
            meta = make_thumbs(path, branch, OUT_DIR, force_thumbs)
            if meta:
                thumbs[path] = {**meta, **({"branch": branch} if branch else {})}
                keys.append(path)
        images_of[n["id"]] = keys

    out_nodes = []
    for n in nodes:
        o = {k: n[k] for k in KEEP if k in n}
        o["links"] = {k: list(v) for k, v in (n.get("links") or {}).items()}
        if n.get("art"):
            o["jobs"] = n["art"].get("jobs") or []
        o["images"] = images_of[n["id"]]
        # A station uses the art of its levels.
        for lv in n.get("levels") or []:
            if lv.get("asset"):
                o["links"].setdefault("uses_asset", [])
                if lv["asset"] not in o["links"]["uses_asset"]:
                    o["links"]["uses_asset"].append(lv["asset"])
        out_nodes.append(o)

    # A card's thumbnail: its own art, its highest painted level, then assets it uses or was inspired by.
    for o in out_nodes:
        cand = list(o["images"])
        for lv in reversed(o.get("levels") or []):
            cand += images_of.get(lv.get("asset"), [])
        for edge in ("uses_asset", "inspired_by"):
            for t in o["links"].get(edge, []):
                cand += images_of.get(t, [])
        if cand:
            o["thumb"] = cand[0]

    data = {"nodes": out_nodes, "thumbs": thumbs, "stamp": git_stamp(),
            "repo": "https://github.com/ErenDenizK/pofu"}
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    html = TEMPLATE.read_text(encoding="utf-8").replace("/*__ATLAS_DATA__*/{}", blob)
    out = OUT_DIR / "index.html"
    out.write_text(html, encoding="utf-8")

    # Drop thumbnails no node uses any more.
    used = {v for meta in thumbs.values() for k, v in meta.items() if k in SIZES}
    used |= {f"thumbs/{Path(v).name.split('-')[0]}.json" for v in used}
    for f in (OUT_DIR / "thumbs").iterdir():
        if f"thumbs/{f.name}" not in used:
            f.unlink()
    return out, data


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--force-thumbs", action="store_true", help="regenerate every thumbnail")
    args = ap.parse_args()
    out, data = build(args.force_thumbs)
    files = sorted({v for m in data["thumbs"].values() for k, v in m.items() if k in SIZES})
    size = out.stat().st_size + sum((OUT_DIR / f).stat().st_size for f in files)
    print(f"Wrote {out.relative_to(REPO)} ({out.stat().st_size // 1024} KB), {len(data['nodes'])} nodes, "
          f"{len(files)} thumbnails; {size // 1024} KB in all.")
    print("The page loads: index.html and " + ", ".join(files[:4]) + (" …" if len(files) > 4 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
