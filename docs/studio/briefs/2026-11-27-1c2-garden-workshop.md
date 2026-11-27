# Brief: PR 1c-2, the garden and the workshop levels (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `art/station-levels-2`.

Spec: `docs/design/mainflow-plan-2026-11-26.md` row **1c**: "as 1b for
the six other stations ... breadth first by level". The pond PR #528 is
merged. It is your template: its PR body, the `POND` entry in
`tools/plate/station_looks.py`, shared erased bases, `excludeOccluders`
and `flowersOnly`. So are the windmill's (#521).

This PR does two stations: the **garden** (pofu-art batch 189) and the
**workshop** (batch 191). Both stand inland, away from the islet gap.
The bagel cart, lighthouse, tea stall and pier come in later PRs.

## Facts to check first (a false premise is a result)

- The takes are on pofu-art main under
  `design/art/takes/batch-189-plot-ladder-garden/` and
  `batch-191-plot-ladder-workshop/`, two takes per job, levels 1 to 5
  day and night, all valid WebP. The clone is /home/user/pofu-art; read
  blobs with `git cat-file blob origin/main:<path>`.
- No lead pick exists for them. Pick each job's take yourself, by eye at
  1:1, and record why in the PR body.
  - A take that moves the foot, changes the lawn, rim or sky, or redraws
    the level before is not used.
  - If neither take of a level is usable, stop that station at the
    level before and name it.
- Batch 117's bases fill the islet gap. Check whether either station's
  base window touches the gap. If one does, report it before you build.

## Tool debt to pay first, as its own commit

The pond builder found two traps:

1. `ingest.py json home` regenerates `plate-home.json` without
   `mooring` and `spots`, and writes `characters` differently. Make the
   tool keep every hand key it does not own, with a test. Then nobody
   re-applies keys by hand.
2. `station_looks.py bases` clears occluders cumulatively, so the
   island, mapisle and occ assets had to be restored from main before
   each run. Make the run idempotent from main's assets, with a test, or
   name why not.

## Acceptance (the row's)

- Frames `path-garden-l1..l5` and `path-workshop-l1..l5`, by day and by
  night.
- `path-levels-i<stage>` sheets, judged whole: no station takes over the
  island.
- 1:1 crops of each look's foot and edge, and of every base window's
  seam.
- Rule v1 budget: worst state at most 12,000,000 px. Report the number.
- Every check the pond ran: `unittest discover tools/plate`,
  `plate_gate`, `painted_light --check`, `shadows check`,
  `il1_composite check`, `check_plates`, `check_assets`, and the Swift
  suite via `test-linux.sh`.
- The pond and windmill frames unchanged, frame to frame (compare the CI
  frames, not only the cut-outs).

## Process

- Your own worktree.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command; loops under 600 s, re-run,
  are fine.
- Add a `changes/art-station-levels-2.md` line.
- Disk floor is 5 GB: remove `.build` and frames when you are done.
- Do not merge.

Hand back: PR number, head SHA, CI result, picks with reasons, crops'
paths, the defects you can still see.
