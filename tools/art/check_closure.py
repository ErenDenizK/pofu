#!/usr/bin/env python3
"""Fail when a manifest in a pofu-art checkout needs a file the checkout does not hold.

    python3 -I tools/art/check_closure.py /path/to/pofu-art [--source /path/to/pofu] [--all]

Loads the manifests of the queue's runnable rows (the rows of the checkout's `QUEUE.md`
that are not done, dropped or blocked; `--all` checks every manifest) with the
pipeline's own parser, resolves every attachment, edit parent, outpaint input and
external master the way `tools/imagegen/pipeline.py` does, and reports each ref that
cannot be found in the checkout. It also composes every job's prompt, so a missing
style or prompt block shows up. A parent that the same manifest makes itself
(`approved:<job>` of a job it generates) is not a failure: it is not on disk until the
job is promoted.

Exit 0: all resolved. Exit 1: something is missing (run `sync_to_art.py`, or add the file
to the closure). Exit 2: usage error.

Run from pofu, where CI tests the tools. The art repo has no CI.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import art_closure as ac  # noqa: E402


def check(art: Path, source: Path | None = None, everything: bool = False, out=print) -> int:
    art = Path(art).resolve()
    if not (art / ac.MANIFEST_DIR).is_dir():
        out(f"{art} has no {ac.MANIFEST_DIR}")
        return 2
    batches = [p.stem for p in ac.all_manifests(art)] if everything else ac.runnable_batches(ac.queue_text(art))
    if not batches:
        out("no runnable queue rows found (is QUEUE.md there?)")
        return 2
    c = ac.compute(art, batches, source)
    problems = 0
    for ref, names in sorted(c.missing.items()):
        out(f"MISSING {ref}  (needed by {', '.join(sorted(names))})")
        problems += 1
    for err in c.errors:
        out(f"MANIFEST {err}")
        problems += 1
    for name in c.manifests:
        if any(e.startswith(f"{name}:") for e in c.errors):
            continue
        for err in ac.prompt_errors(art, art / ac.MANIFEST_DIR / f"{name}.yaml"):
            out(f"PROMPT  {err}")
            problems += 1
    for name in c.unmanifested:
        out(f"note: queue row {name} has no manifest yet")
    out(f"{len(c.manifests)} manifests, {len(c.files)} reference files found, "
        f"{len(c.pending)} parents made by their own batch; "
        + (f"{problems} problems" if problems else "closure complete"))
    return 1 if problems else 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("art", type=Path, help="path to a pofu-art checkout")
    ap.add_argument("--source", type=Path, help="a pofu checkout, to tell 'not copied' from 'never existed' in the report")
    ap.add_argument("--all", action="store_true", help="check every manifest, not only the queue's runnable rows")
    a = ap.parse_args(argv)
    return check(a.art, a.source, a.all)


if __name__ == "__main__":
    sys.exit(main())
