# 0026. The art factory lives in its own repository

- **Status:** Accepted
- **Date:** 2026-11-12

## Context

Codex chats on this repository drop and new ones will not load. The likely
cause is its size: a 713 MB checkout (538 MB of it `design/art`) and about
2.7 GB of history, mostly past takes, contact sheets and deliveries. The art
line must never idle (ADR-0022, `AGENTS.md`), so the factory moves.

## Decision

- **`ErenDenizK/pofu-art` (private) is the factory and the archive of everything
  Codex makes from now on.** Codex works only there. Its `main` stays small
  (target under 150 MB checkout; first commit about 23 MB).
- **Same relative paths, a smaller set of files.** pofu-art holds `tools/imagegen`
  with its tests, every manifest, the style and prompt blocks, the files the pipeline
  reads at run time, and the **reference closure**: every file a queue-runnable manifest
  attaches, edits (`edit_of`, external `master:`), outpaints or aliases, worked out from
  `pipeline.py`'s own ref resolution (`tools/art/art_closure.py`).
  `tools/art/check_closure.py` fails when a ref cannot be resolved there.
- **The queue moves** to `pofu-art/QUEUE.md`, verbatim; the art production plan here
  keeps a pointer. `AGENTS.md` in pofu-art is the Codex brief (Factory mode unchanged,
  delivery PRs against pofu-art `main`, one branch per batch); `AGENTS.md` here is a pointer.
- **Tools: pofu is the source of truth** (its CI tests them). `tools/art/sync_to_art.py`
  copies tools and closure to a pofu-art checkout, idempotently, and writes
  `SYNCED_FROM.txt`. Codex may fix a tool in place if a run is blocked and names the fix in
  the delivery's `review.yaml` (`tool_fix:`); the lead ports it back.
- **Picks come back.** `tools/art/ingest.py` copies a picked job's folder
  (`design/art/takes/<batch>/<id>/`, plus a promoted master folder) from pofu-art to the same
  path here, where #386 put the batch-74 and 75 picks.

## Consequences

- Two repositories: art PRs, review and merges happen in pofu-art; the lead ingests picks
  into pofu and then records them (`docs/state/plates.yaml`, `tools/content/sync_assets.py`,
  `tools/assets/harmony.py`). Codex no longer writes harmony or content nodes.
- A queue row whose references are not in the closure needs a re-sync before Codex runs it.
- The old art stays in pofu and its history, untouched; nothing is deleted here. Past
  takes, contact sheets and delivery folders are not copied to pofu-art.
- The imagegen tests skip the fixtures only the full tree has when run in pofu-art.
