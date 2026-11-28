# Brief: N2, the stations keep their level in golden hour (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `art/golden-stations`. Desk: `[world]`.

## The defect

N1 (#559, merged) gave every station its level at night. From 17:30
(`HomePlate.goldenStarts`) to 20:00 the plate still falls back to its
painted golden plate. That plate shows the painted stations of the
island's stage, not the player's levels, so each built station jumps at
17:30 and again at 20:00. Golden lasts two and a half hours of the
player's evening, his most likely time to open the app.

What the lead read (a scout at a93b5128 and N1's report, not checked
again):
- Golden plates are painted at stages 0 and 3-7. Stages 1-2 borrow the
  night plate (`HomePlate.swift:~113`).
- `PlateIsland.swift:~360` has a comment saying golden draws the day
  look over a golden base, but no station lists `golden`.
- No golden erase takes exist.
- Decision D3 (`docs/design/mainflow-plan-2026-11-26.md`): golden looks
  are the day look under a code grade.

## Facts to check first (a false premise is a result)

- Each claim above, with file and line.
- What stages 1-2 draw at golden now that night has bases and looks.
  Find out whether they already keep their level (borrowed night
  bases) or show something broken.
- Which of these is right, judged on frames, not on argument:
  - **(a)** golden bases derived in code: the golden plate outside the
    stations' windows, and inside them the day base colour-fitted to
    the golden plate's surround (#549 and #559 have the fit). Looks are
    the day looks under the same fit.
  - **(b)** at golden, draw the day composite (day bases and looks)
    under a code golden grade instead of the painted golden plate.
  Build (a) unless its seams fail at 1:1. Say which you chose and show
  the frames that decided it.

## Change

- Golden bases and looks for every stage a station stands on, by the
  method chosen.
- `plate-home.json`: `lights`, `lookLevels` and `lightBaseBytes` for
  `golden`.
- `painted-light.json`, re-measured. Only golden entries may move.
- Screenshot tests:
  - `path-<station>-golden-l1..l5`;
  - `path-levels-i<stage>-golden`;
  - frames at 17:29, 17:31, 19:59 and 20:01 with the same levels.

Stay out of:
- `PofuWorld/Scene/SeasonAir.swift`, `PofuWorld/Sky/Weather.swift`,
  `PofuSound/*` and `App/WorldSound.swift`, where C2 #557 is open;
- `plate-home.json`'s `water`, `mooring`, `props` and `seasons` keys.

## Acceptance

- The 17:29 / 17:31 / 19:59 / 20:01 frames show the same station
  levels; only the light changes.
- 1:1 crops of each golden base window's seam and each look's foot and
  edges:
  - no halo, no ghost of the painted station;
  - no look brighter, or more saturated, than the plate around it.
- Every day, night and autumn frame unchanged, compared frame to frame
  against `screenshots/art-night-stations`, which is the newest full
  set.
- Rule v1: the worst state is at most 12,000,000 px. Report the number.
- Every check #559 ran.
- A `changes/art-golden-stations.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- **Local Swift:** `tools/swift/test-linux.sh`. If the stale lock waits
  more than 10 minutes, kill nothing and lean on CI. Read your Swift
  diff twice before each push.
- Disk floor 5 GB (6.2 GB now): delete takes and frames as you go.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- the method you chose and why;
- the crops' paths;
- the frame-diff list;
- the budget number;
- the defects you can still see.
