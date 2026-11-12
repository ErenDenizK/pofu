#!/usr/bin/env python3
"""Check the art queue of a pofu-art checkout: every READY row can really run.

    python3 -I tools/art/check_queue.py /path/to/pofu-art

`QUEUE.md` lists only work that can run; finished and dropped rows live in `QUEUE-LOG.md`.
On 2026-11-12 the queue was moved with twenty delivered rows still marked READY and Codex
began redoing one. This check fails when:

- a READY row names a batch with no manifest (`tools/imagegen/manifest/<batch>.yaml`), or
  whose manifest `status` is not `open`;
- every job of a READY row's manifest already has takes under
  `design/art/takes/<batch>/<job>/` in the checkout (the row was delivered and merged:
  move it to `QUEUE-LOG.md`);
- a row whose state is done, delivered or dropped is still in `QUEUE.md`.

Run it on the checkout's `main` before merging any edit of the queue. Rows are read as
`art_closure.runnable_batches` reads them: the second cell names the batch in backticks,
the last cell is the state.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml

QUEUE = "QUEUE.md"
MANIFESTS = Path("tools/imagegen/manifest")
TAKES = Path("design/art/takes")
BATCH = re.compile(r"`(batch-[a-z0-9-]+|retry-[0-9-]+)`")
FINISHED = ("done", "delivered", "dropped")


def rows(text: str) -> list[tuple[list[str], str]]:
    """(batch names, state in lower case) of every table row that names a batch."""
    out = []
    for line in text.splitlines():
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| #"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        names = BATCH.findall(cells[1])
        if names:
            out.append((names, re.sub(r"[*_`]", "", cells[-1]).strip().lower()))
    return out


def delivered_jobs(art: Path, batch: str, jobs: list[str]) -> list[str]:
    return [j for j in jobs if any((art / TAKES / batch / j).glob("*.webp"))]


def problems(art: Path) -> list[str]:
    queue = art / QUEUE
    if not queue.is_file():
        return [f"no {QUEUE} in {art}"]
    found: list[str] = []
    for names, state in rows(queue.read_text(encoding="utf-8")):
        for batch in names:
            if state.startswith(FINISHED):
                found.append(f"{batch}: a finished row ({state.split()[0]}) is still in {QUEUE}; move it to QUEUE-LOG.md")
                continue
            if not state.startswith("ready"):
                continue
            manifest = art / MANIFESTS / f"{batch}.yaml"
            if not manifest.is_file():
                found.append(f"{batch}: READY, but {MANIFESTS / (batch + '.yaml')} does not exist")
                continue
            data = yaml.safe_load(manifest.read_text(encoding="utf-8")) or {}
            if data.get("status") != "open":
                found.append(f"{batch}: READY, but its manifest status is {data.get('status')!r}, not 'open'")
            jobs = [j["id"] for j in data.get("jobs") or [] if isinstance(j, dict) and "id" in j]
            if jobs and len(delivered_jobs(art, batch, jobs)) == len(jobs):
                found.append(f"{batch}: READY, but all {len(jobs)} jobs already have takes in this checkout; "
                             "move the row to QUEUE-LOG.md")
    return found


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    found = problems(Path(argv[1]))
    for line in found:
        print(line)
    print(f"{'FAIL' if found else 'ok'}: {len(found)} problem(s)")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
