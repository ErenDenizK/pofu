# Brief: PR 1c-3, the bagel cart and lighthouse levels (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `art/station-levels-3`. Desk: `[world]`.

Spec: `docs/design/mainflow-plan-2026-11-26.md` row **1c**. Your
templates are the merged PRs #528 (pond), #521 (windmill) and #543
(workshop): their PR bodies and their entries in
`tools/plate/station_looks.py`.

This PR does two stations, the **bagel cart** (pofu-art batch 190) and
the **lighthouse** (batch 192), plus one fix to the pond's look.

The tea stall (batch 196) waits for S3, which is deriving its autumn
looks from today's. The pier waits for its batch.

## Facts to check first (a false premise is a result)

- Batches 190 and 192 are on pofu-art main, levels 1-5, day and night.
  QA picked t1 for every job; the lead has not looked yet.
  - Check every pick at 1:1 against the level before.
  - A take that moves the foot, changes the lawn, rim or sky, or redraws
    the level before is not used: try t2, else stop that station at the
    level before and name it.
  - The clone is /home/user/pofu-art; read blobs with
    `git cat-file blob origin/main:<path>`.
- Where each station stands, against the islet gap and the bridge.
  - If a look box or a base window crosses the gap line, cut the look
    inside the gap line (the lead's standing note). Name the box.
  - No look may paint over the bridge, the harbour isle, the mooring or
    the New Year props (`props` key, stages 4-9).
- An unbuilt station (level 0) shows its bare erased plot, as the pond,
  windmill and workshop do. Say what the plate showed there before.

## Also in this PR

**The pond look's front edge.** At pond levels 1-5 the look's lower
edge cuts straight across the foreground hydrangeas and flowers, and
the hydrangea tops are washed out. It shows in `path-pond-l3` at plate
px about (60..330, 905..935), and the frames with the water switched off
(#545) show the same, so the look's cut causes it, not the water.

Fix it with any of:
- a matte that follows the flowers;
- the look ending above them;
- the flowers as an occluder over the look.

Show before and after at 1:1.

## Stay out of

- `plate-home.json`'s `water`, `mooring`, `props` and `seasons` keys;
- `Plate/PlateRegionEffects.swift`.

S3 (`art/season-slice`) is changing `station_looks.py`, `stations.json`
and `plate-home.json` in parallel:
- keep your edits to new entries;
- if S3 merges first, merge main and resolve key by key.

## Acceptance

- Frames `path-bagel-cart-l1..l5` and `path-lighthouse-l1..l5`, by day
  and night.
- `path-levels-i<stage>` sheets, judged whole: no station takes over the
  island.
- 1:1 crops of each look's foot and edge, every base window's seam and
  the pond's front edge.
- Rule v1 budget: worst state at most 12,000,000 px. Report the number.
- Every check #543 ran, and the Swift suite via `tools/swift/test-linux.sh`.
- The other stations' frames unchanged, frame to frame (compare CI
  frames, not file hashes; #543's "unchanged" was wrong once).

## Process

- Your own worktree, at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Add a `changes/art-station-levels-3.md` line starting `[world]`.
- Disk floor is 5 GB: remove `.build`, takes and frames when done.
- Do not merge.

Hand back: PR number, head SHA, CI result, picks with reasons, crops'
paths, the defects you can still see.
