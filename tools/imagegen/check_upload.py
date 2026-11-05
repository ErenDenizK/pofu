#!/usr/bin/env python3
"""Check that pushed art arrived whole: re-download every file and decode it.

The GitHub connector Codex cloud tasks push through cuts files off at
768 KB without an error (batch 01's takes arrived as 786,443-byte stubs).
So every uploaded file must stay under 600 KB, and every push is checked
by reading the files back from the remote branch (AGENTS.md, "Uploads").

The unlocked source is never dropped: every promoted master folder keeps
`raw.webp`, lossless when that fits under 600 KB and lossy WebP q95
otherwise (`encode_raw`). The style lock is a choice that can be redone
only from the raw, so a master folder without one fails the check.

    git fetch origin art/batch-03-home-island/pond
    python3 -I tools/imagegen/check_upload.py --branch art/batch-03-home-island/pond \\
        design/art/takes/batch-03-home-island/pond-1 design/art/stations/pond-1

Exit status 0 when every file under the given paths on the remote branch is
under 600 KB, matches the local copy byte for byte, and (for images)
decodes completely, and every master folder among them keeps its raw.
"""
from __future__ import annotations

import argparse
import io
import subprocess
import sys
from pathlib import PurePosixPath, Path

from PIL import Image

LIMIT = 600 * 1024
IMAGE_SUFFIXES = (".png", ".webp", ".jpg", ".jpeg")
# The raw's file names, best first. raw.png is what older jobs kept.
RAW_NAMES = ("raw.webp", "raw.png")
# Lossy steps tried, in order, when the lossless raw is too large.
RAW_LOSSY_QUALITIES = (95, 92, 90)


def problems(name: str, data: bytes, local: bytes | None) -> list[str]:
    """What is wrong with one file as the remote holds it (empty when fine)."""
    out = []
    if len(data) >= LIMIT:
        out.append(f"{len(data):,} bytes, not under 600 KB")
    if local is not None and local != data:
        out.append(f"differs from the local file ({len(data):,} remote, {len(local):,} local bytes)")
    if name.lower().endswith(IMAGE_SUFFIXES):
        try:
            with Image.open(io.BytesIO(data)) as im:
                im.load()
        except Exception as err:  # noqa: BLE001 - any decode failure is the finding
            out.append(f"does not decode: {err}")
    return out


def encode_raw(image: Image.Image) -> tuple[bytes, str]:
    """The raw as it is kept in the repo: lossless WebP when that is under
    600 KB, otherwise lossy WebP at the highest quality that fits (q95
    first). Returns the bytes and a description of the encoding."""
    im = image.convert("RGBA")
    buf = io.BytesIO()
    im.save(buf, "WEBP", lossless=True, method=6)
    if buf.tell() < LIMIT:
        return buf.getvalue(), "webp lossless"
    for q in RAW_LOSSY_QUALITIES:
        buf = io.BytesIO()
        # exact keeps the color under transparent pixels, as the take had it.
        im.save(buf, "WEBP", quality=q, method=6, exact=True)
        if buf.tell() < LIMIT:
            return buf.getvalue(), f"webp q{q}"
    raise ValueError(f"the raw does not fit under 600 KB even at q{RAW_LOSSY_QUALITIES[-1]} ({buf.tell():,} bytes)")


def downscale(image: Image.Image, scale: float | None) -> Image.Image:
    """Soft delivery: the image scaled by `scale` (0 < scale <= 1) with Lanczos.
    None or 1 returns it unchanged. RGBA is premultiplied while resampling so
    transparent edges do not pick up halo colour."""
    if not scale or scale >= 1:
        return image
    size = (max(1, round(image.width * scale)), max(1, round(image.height * scale)))
    im = image.convert("RGBA")
    return im.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")


def save_raw(src: Path, dest_dir: Path, scale: float | None = None) -> tuple[Path, str]:
    """Writes `dest_dir/raw.webp` from the take at `src` (downscaled by `scale`
    for soft delivery); drops an older raw.png."""
    with Image.open(src) as im:
        data, encoding = encode_raw(downscale(im, scale))
    dest_dir.mkdir(parents=True, exist_ok=True)
    out = dest_dir / RAW_NAMES[0]
    out.write_bytes(data)
    old = dest_dir / "raw.png"
    if old.exists():
        old.unlink()
    return out, encoding


def master_folders(names: list[str]) -> set[str]:
    """Folders that hold a promoted master: they contain a meta.json."""
    return {str(PurePosixPath(n).parent) for n in names if PurePosixPath(n).name == "meta.json"}


def missing_raws(names: list[str]) -> list[str]:
    """Master folders among `names` that keep no raw (a dropped source)."""
    present = set(names)
    return sorted(
        folder for folder in master_folders(names)
        if not any(f"{folder}/{raw}" in present for raw in RAW_NAMES)
    )


def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], check=True, capture_output=True).stdout


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--branch", required=True, help="the pushed branch, e.g. art/batch-03-home-island/pond")
    ap.add_argument("--remote", default="origin")
    ap.add_argument("paths", nargs="+", help="folders or files to check, as committed")
    args = ap.parse_args(argv)
    ref = f"{args.remote}/{args.branch}"
    names = git("ls-tree", "-r", "--name-only", ref, "--", *args.paths).decode().split()
    if not names:
        print(f"Nothing under {' '.join(args.paths)} on {ref}: was it pushed, and fetched?")
        return 1
    bad = 0
    for name in names:
        data = git("show", f"{ref}:{name}")
        local = Path(name).read_bytes() if Path(name).is_file() else None
        found = problems(name, data, local)
        bad += bool(found)
        print(("BAD " if found else "ok  ") + name + (": " + "; ".join(found) if found else f" ({len(data) // 1024} KB)"))
    for folder in missing_raws(names):
        bad += 1
        print(f"BAD {folder}: no raw.webp; the unlocked source must be kept (AGENTS.md, Uploads)")
    print(f"\n{len(names)} file(s) checked, {bad} problem(s)." + (" Fix and re-upload." if bad else " Everything arrived whole."))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
