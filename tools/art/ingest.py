#!/usr/bin/env python3
"""Bring picked takes from a pofu-art checkout back into this repo.

    python3 -I tools/art/ingest.py /path/to/pofu-art x-home-flow-bare-v4:2 x-caglayan-sky-golden-v2
    python3 -I tools/art/ingest.py /path/to/pofu-art --batch batch-76-redo-picks [--dry-run]

Picks live where PR #386 (batches 74 and 75) put them: the job's folder
`design/art/takes/<batch>/<job-id>/` holds the WebP takes, `contact.jpg` and the
`review.yaml` sidecar whose `pick:` names the chosen take. This script copies that
whole folder (both takes stay, as in #386) to the same path here. When Codex promoted
the job in pofu-art (a production row), the master folder `design/art/{masters,stations,ui}/<name>/`
comes along too.

A selector is a job id, or `<job-id>:<take>` to name the pick; the take must exist, and
a different `pick:` in the sidecar is reported, not rewritten (the lead records the pick).
`--batch` takes every job of that batch whose sidecar carries an integer pick. Idempotent:
files already identical are left alone. It only copies; it never deletes.

After ingesting, the lead records the pick in `docs/state/plates.yaml` and runs
`tools/content/sync_assets.py` (and `tools/assets/harmony.py measure` for a promoted master),
as for any picked art.
"""
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
DEST_DEFAULT = HERE.parents[1]
TAKES = Path("design/art/takes")
CAP = 600 * 1024  # the upload cap AGENTS.md sets; a bigger file is copied but flagged


def read_review(folder: Path) -> dict:
    f = folder / "review.yaml"
    if not f.is_file():
        return {}
    return yaml.safe_load(f.read_text(encoding="utf-8")) or {}


def job_pick(folder: Path) -> int | None:
    """The sidecar's integer pick for the job this folder is named after, else None."""
    job = (read_review(folder).get("jobs") or {}).get(folder.name) or {}
    p = job.get("pick")
    return p if isinstance(p, int) and not isinstance(p, bool) else None


def find_folders(art: Path, job_id: str, batch: str | None = None) -> list[Path]:
    base = art / TAKES
    pattern = f"{batch}/{job_id}" if batch else f"*/{job_id}"
    return sorted(p for p in base.glob(pattern) if p.is_dir())


def master_folders(art: Path, folder: Path) -> list[Path]:
    """The promoted master folder(s) of the job, found through the sidecar's manifest."""
    review = read_review(folder)
    man = review.get("manifest") or (f"tools/imagegen/manifest/{review['batch']}.yaml" if review.get("batch") else None)
    if not man:
        return []
    try:
        sys.path.insert(0, str(HERE.parents[1] / "tools" / "imagegen"))
        import pipeline as pl
        pl.ART_ROOT = art / "design" / "art"
        pl.REPO_ROOT = art
        cfg = yaml.safe_load((art / "tools/imagegen/config.yaml").read_text(encoding="utf-8"))
        job = pl.load_manifest(art / man, cfg).job(folder.name)
        d = pl.approved_dir(job)
    except Exception:  # an old sidecar or a manifest the checkout lacks: no master to bring
        return []
    return [d] if d.is_dir() else []


def copy_tree(src: Path, art: Path, dest: Path, dry_run: bool, out) -> tuple[int, int]:
    new = changed = 0
    for f in sorted(p for p in src.rglob("*") if p.is_file()):
        rel = f.relative_to(art)
        target = dest / rel
        if target.is_file() and target.read_bytes() == f.read_bytes():
            continue
        if target.exists():
            changed += 1
            tag = "updated"
        else:
            new += 1
            tag = "added  "
        out(f"{tag} {rel.as_posix()}" + ("  (over the 600 KB upload cap)" if f.stat().st_size >= CAP else ""))
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(f, target)
    return new, changed


def ingest(art: Path, dest: Path, selectors: list[str], batch: str | None = None, dry_run: bool = False, out=print) -> int:
    """Copy the picked jobs; returns the number of problems (unknown job, missing take)."""
    art, dest = Path(art).resolve(), Path(dest).resolve()
    jobs: list[tuple[Path, int | None]] = []
    problems = 0
    if batch and not selectors:
        for folder in sorted((art / TAKES / batch).glob("*")):
            if folder.is_dir() and job_pick(folder) is not None:
                jobs.append((folder, None))
        if not jobs:
            out(f"no job of {batch} carries a pick in its review.yaml")
            return 1
    for sel in selectors:
        job_id, _, take = sel.partition(":")
        found = find_folders(art, job_id, batch)
        if len(found) != 1:
            out(f"{sel}: " + ("no such job folder under design/art/takes/" if not found else
                              "found in several batches (" + ", ".join(p.parent.name for p in found) + "); add --batch"))
            problems += 1
            continue
        n = int(take) if take.isdigit() else None
        if take and n is None:
            out(f"{sel}: the take must be a number")
            problems += 1
            continue
        if n is not None and not list(found[0].glob(f"*--t{n}.*")):
            out(f"{sel}: no take {n} in {found[0].relative_to(art).as_posix()}")
            problems += 1
            continue
        jobs.append((found[0], n))
    new = changed = 0
    for folder, n in jobs:
        recorded = job_pick(folder)
        label = folder.relative_to(art / TAKES).as_posix()
        if n is not None and recorded is not None and recorded != n:
            out(f"note: {label} review.yaml says pick {recorded}, you named take {n}; the lead records the pick")
        elif n is None and recorded is None:
            out(f"note: {label} carries no pick yet (copying the takes anyway)")
        a, b = copy_tree(folder, art, dest, dry_run, out)
        new, changed = new + a, changed + b
        for m in master_folders(art, folder):
            a, b = copy_tree(m, art, dest, dry_run, out)
            new, changed = new + a, changed + b
    out(f"{len(jobs)} jobs: {new} files added, {changed} updated" + (" (dry run)" if dry_run else "") if (new or changed)
        else f"{len(jobs)} jobs: nothing changed")
    return problems


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("art", type=Path, help="path to a pofu-art checkout")
    ap.add_argument("jobs", nargs="*", help="job id, or job-id:take")
    ap.add_argument("--batch", help="a batch name: with no job ids, every job whose review.yaml carries a pick")
    ap.add_argument("--dest", type=Path, default=DEST_DEFAULT, help="the pofu checkout (default: this one)")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args(argv)
    if not a.jobs and not a.batch:
        ap.error("name job ids or --batch")
    if not (a.art / TAKES).is_dir():
        print(f"{a.art} has no {TAKES.as_posix()}", file=sys.stderr)
        return 2
    return 1 if ingest(a.art, a.dest, a.jobs, a.batch, a.dry_run) else 0


if __name__ == "__main__":
    sys.exit(main())
