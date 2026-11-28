# Brief: painted nights round 2, the tea stall and windmill 3 (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `art/nights-round-2`. Desk: `[world]`.

## Where it stands

On main (after #566 and #568), `tools/plate/station_looks.py`:

- The tea stall keeps the derived (N1) night at every level
  (`DERIVED_NIGHT = ("teaStall",)`): batch 196 read lime or lilac at 1:1.
  Its redo is pofu-art batch `batch-208-tea-stall-night-redo`, jobs
  `x-plot-tea-stall-{1..5}-night-v2`. The lead's picks for levels 1 to 5
  are takes 1, 1, 2, 2, 1 (each job's `review.yaml` `lead_review:`).
- The windmill's form 3 night is its day look through the colour fit
  (`NIGHT_PAINT["windmill"]` has levels 2, 4, 5 only). Its redo is
  `batch-207-windmill-3-night-redo/x-plot-windmill-3-night-v2`, pick t1.
  The review: the station's mean sits on the il8 plate's mill (L* 57.9,
  C* 27.8 against 56.3, 27.0), but its darks are 11.6 L* deeper (p5 30.6
  against 42.2): lift the darks about 10 L*, and cut chroma only about 5 %.
- #566 added `LOOK_MATCH` (the bagel cart): the painted night is fitted to
  the derived look's mean L*/C* and its warm pixels' median hue is turned
  onto the derived look's (`turn_hue`). That is the method here for the
  tea stall.
- The takes are 1254 px sources normalised to 1536 (see the review's
  canvas warning); #568 found the pier's ladder at 1254, so check which
  size the mirrored files are and what scale the day looks were cut at.

## Facts to check first (a false premise is a result)

- The warm-pixel median hue (CIELAB, C* over 12, hue 30-150, L* over 55)
  of each tea stall pick, raw and after your build, and of the derived
  look, per level. The lead's review says the raw picks sit 13 to 17
  degrees warmer than the day; the lead's judgment is that night should
  match the derived look's hue (about 66 to 72), not the day's. Measure.
- The tea stall picks add a moon and change flowers, lawn and path outside
  the day outline. Confirm the day look's outline cut drops all of that.
- Windmill 3 t1: every tile within 1.2 px of the day pick, per the review.
  Check the cut by the form 3 day look's outline lands without a seam.

## Change and targets

- Tea stall nights 1 to 5 back on (out of `DERIVED_NIGHT`), through
  `LOOK_MATCH`: mean L* within 3 of the derived look's, warm-pixel hue
  within 5 degrees of it, the awning butter yellow and cream and the
  counter light warm wood at 1:1, never lime, lilac or olive. The awning
  gate (`restore_awning` / `awning_measure`) passes.
- Windmill night 3 painted (into `NIGHT_PAINT["windmill"]`), graded to the
  il8 plate's mill: mean L* within 3 of 56.3, C* within 3 of 27.0, p5 at
  least 38. Sails bare cloth, warm light only in the windows and door fan.
- A level that cannot meet its targets keeps what it has now. Say which
  and why.

Stay out of the bagel cart, workshop, lighthouse, pond and pier entries,
windmill levels 2, 4 and 5, and `plate-home.json`'s `near` and `seasons`
keys.

## Acceptance

- `path-tea-stall-night-l1..l5` and the windmill night frame at form 3
  (find its name in `PlayerPathScreenshotTests.swift`): 1:1 crops of the
  station before (main) and after, plus the derived look beside the tea
  stall, with mean L*, C*, warm hue (and the mill's p5) per level.
- Every other frame unchanged. `screenshots/main` was stale until #570
  (the publish job timed out); compare against the path-frames artifact of
  the latest green main run if `screenshots/main` is still at 302b8c2.
  Use `tools/review/screens_diff.py` if #565 has merged. List the frames
  that differ.
- `plate_gate home` green; report the worst state against 12,000,000 px
  (it was 11,334,498 after #568).
- `station_looks` pytest and the Swift tests (via
  `tools/swift/test-linux.sh`) green.
- A `changes/art-nights-round-2.md` line starting `[world]`.

## Process

- Your own worktree at a new path, from current `origin/main`.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Fetch frames only with `tools/review/fetch_frames.sh` or artifact range
  reads into the scratchpad, never into a `.git`. Disk floor 5 GB; delete
  frames as you go. No local `.build` beyond `test-linux.sh`'s.
- Do not merge.

Hand back: the PR number, head SHA and CI result; the crops' paths; the
per-level numbers; the frame-diff list; the budget; what you can still see.
