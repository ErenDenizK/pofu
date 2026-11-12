#!/usr/bin/env python3
"""Copy the art factory's tools and references from this repo into a pofu-art checkout.

    python3 -I tools/art/sync_to_art.py /path/to/pofu-art [--dry-run] [--prune]

Copies, at the same relative paths: `tools/imagegen` (code, tests, every manifest,
style and prompt blocks), the files its code reads at run time, and the reference
closure of the runnable queue rows (the rows of the checkout's `QUEUE.md`; see
`art_closure.py`). Only files whose bytes differ are written, so a second run
prints "nothing changed". Writes `SYNCED_FROM.txt` (the pofu commit) when the
content changed. Never touches `QUEUE.md`, `AGENTS.md`, `README.md`, `setup.sh`,
takes, masters or anything else this script does not own; never deletes unless
`--prune` is given, and then only under `tools/imagegen/`.

pofu is the source of truth for the tools: change them here, test them in CI, sync.
If Codex fixed a tool in pofu-art, port the fix back here first (the fix is named in
that delivery's review.yaml), or the sync overwrites it.
"""
from __future__ import annotations

import argparse
import hashlib
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import art_closure as ac  # noqa: E402

STAMP = "SYNCED_FROM.txt"


def git_commit(root: Path) -> str:
    try:
        sha = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
        dirty = subprocess.run(["git", "-C", str(root), "status", "--porcelain", "--", "tools", "design", "docs"],
                               capture_output=True, text=True, check=True).stdout.strip()
        return sha + (" (with uncommitted changes)" if dirty else "")
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def same(a: Path, b: Path) -> bool:
    return b.is_file() and a.stat().st_size == b.stat().st_size and a.read_bytes() == b.read_bytes()


def content_id(source: Path, files: list[str]) -> str:
    h = hashlib.sha256()
    for f in files:
        h.update(f.encode() + b"\0" + hashlib.sha256((source / f).read_bytes()).digest())
    return h.hexdigest()[:16]


def sync(source: Path, art: Path, dry_run: bool = False, prune: bool = False, out=print) -> dict:
    source, art = Path(source).resolve(), Path(art).resolve()
    if source == art:
        raise SystemExit("source and destination are the same folder")
    files, closure = ac.wanted_files(source, art)
    files = sorted(files)
    added, updated, pruned = [], [], []
    for f in files:
        src, dst = source / f, art / f
        if same(src, dst):
            continue
        (updated if dst.exists() else added).append(f)
        if not dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
    stale = sorted(
        p.relative_to(art).as_posix() for p in (art / "tools" / "imagegen").rglob("*")
        if p.is_file() and not ac.SKIP_PARTS & set(p.relative_to(art).parts) and p.relative_to(art).as_posix() not in set(files)
    ) if (art / "tools" / "imagegen").is_dir() else []
    if prune:
        for f in stale:
            pruned.append(f)
            if not dry_run:
                (art / f).unlink()
        stale = []
    stamp = art / STAMP
    changed = bool(added or updated or pruned)
    cid = content_id(source, files)
    stamp_text = (f"pofu commit: {git_commit(source)}\ncontent: {cid} ({len(files)} files, {ac.size_mb(source, files):.1f} MB)\n"
                  "Written by tools/art/sync_to_art.py in ErenDenizK/pofu. Do not edit.\n")
    if (changed or not stamp.exists()) and not dry_run:
        stamp.write_text(stamp_text, encoding="utf-8")
        changed = True
    elif not stamp.exists() or f"content: {cid} " not in stamp.read_text(encoding="utf-8"):
        changed = True
    for tag, items in (("added", added), ("updated", updated), ("pruned", pruned)):
        for f in items:
            out(f"{tag:8} {f}")
    for f in stale:
        out(f"stale    {f} (not in pofu; --prune removes it)")
    for ref, names in sorted(closure.missing.items()):
        out(f"MISSING  {ref} (used by {', '.join(sorted(names))}; not in pofu either)")
    for ref, names in sorted(closure.pending.items()):
        out(f"pending  {ref} (made by {', '.join(sorted(names))} itself; fine)")
    for name in closure.unmanifested:
        out(f"no manifest yet for queue row {name}")
    out(f"{len(files)} files, {ac.size_mb(source, files):.1f} MB, for {len(closure.manifests)} queue manifests; "
        + (f"{len(added)} added, {len(updated)} updated" + (f", {len(pruned)} pruned" if pruned else "") if (added or updated or pruned)
           else "nothing changed") + (" (dry run)" if dry_run else ""))
    return {"added": added, "updated": updated, "pruned": pruned, "stale": stale, "files": files,
            "missing": closure.missing, "pending": closure.pending, "changed": changed}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("art", type=Path, help="path to a pofu-art checkout")
    ap.add_argument("--source", type=Path, default=ac.SOURCE_ROOT, help="the pofu checkout (default: this one)")
    ap.add_argument("--dry-run", action="store_true", help="print what would change, write nothing")
    ap.add_argument("--prune", action="store_true", help="delete files under tools/imagegen/ that pofu no longer has")
    a = ap.parse_args(argv)
    if not a.art.is_dir():
        print(f"{a.art} is not a folder", file=sys.stderr)
        return 2
    res = sync(a.source, a.art, a.dry_run, a.prune)
    return 1 if res["missing"] else 0


if __name__ == "__main__":
    sys.exit(main())
