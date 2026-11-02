#!/usr/bin/env python3
"""Check that pushed art arrived whole: re-download every file and decode it.

The GitHub connector Codex cloud tasks push through cuts files off at
768 KB without an error (batch 01's takes arrived as 786,443-byte stubs).
So every uploaded file must stay under 600 KB, and every push is checked
by reading the files back from the remote branch (AGENTS.md, "Uploads").

    git fetch origin art/batch-03-home-island/pond
    python3 -I tools/imagegen/check_upload.py --branch art/batch-03-home-island/pond \\
        design/art/takes/batch-03-home-island/pond-1 design/art/stations/pond-1

Exit status 0 when every file under the given paths on the remote branch is
under 600 KB, matches the local copy byte for byte, and (for images)
decodes completely.
"""
from __future__ import annotations

import argparse
import io
import subprocess
import sys
from pathlib import Path

from PIL import Image

LIMIT = 600 * 1024
IMAGE_SUFFIXES = (".png", ".webp", ".jpg", ".jpeg")


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
    print(f"\n{len(names) - bad} of {len(names)} file(s) arrived whole." + (" Re-upload the bad ones." if bad else ""))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
