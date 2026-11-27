# Brief: N1, the stations keep their level at night (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `art/night-stations`. Desk: `[world]`.

## The defect

By day each station draws its look for the player's level over an erased
base. At night nothing does that. `PlateIsland.drawnPlateArt` falls back
to the painted night plate (`PlateIsland.swift:265-276`), because no
station lists `night` in `plate-home.json` `stations.*.lights`. The
plate shows the painted stations of the island's stage, not the player's
levels, so at 20:00 every built station jumps to another look. Golden
(from 17:30) does the same; that is N2, not this PR.

A scout read this at a93b5128 (lead's summary):
- Night erase takes already exist in pofu-art:
  `design/art/takes/batch-117-station-erase-volume/x-base-erase-l01..l10-night`,
  two takes each. Their picks are QA auto-picks, not the lead's:
  l01 t2, l02 t1, l03 t2, l04 t2, l06 t2, l07 t1, l08 t1, l09 t2,
  l10 t2. l05 was skipped; no station stands on stage 5.
- `build_base` / `accumulate_base` / `cmd_bases` in
  `tools/plate/station_looks.py` write day bases only, but the season
  path already calls `accumulate_base` with a light key.
- Painted night looks exist only for the pond (pofu-art batch 197, lead
  picks t2, t1, t1, t2, t2 for forms 1-5, in `review.yaml`). The
  windmill's (batch 188) are unreviewed. #549's `season_looks` derives
  looks per level by `sg.colour_fit`.

## Facts to check first (a false premise is a result)

- Each of the above, with file and line.
- Check each night erase take at 1:1 against its night plate (stage s =
  level 10-s). Pick per level the take that erases the stations and
  moves nothing else. If neither take works for a stage, that stage
  keeps the painted night plate. Record your picks with reasons; the
  lead confirms them.
- The scout's risks:
  - a base with no look erases the station: bases and looks ship
    together;
  - `lookLevel(stationLevel:light:)` with no `lookLevels` entry for
    night;
  - the night lamps (`lamps`; two stand in the pond box; they open at
    island level 6);
  - `lightMap` and `shadowMap` night keys;
  - `painted-light.json` (`painted_light.py --check`);
  - null `plateCrop.night` at stages 8-9;
  - the rule v1 budget.

## Change

- Night bases for every stage a station stands on, from the picked
  batch 117 takes.
- Night looks:
  - the pond's from batch 197's lead picks, cut like its day looks;
  - every other station's derived in code from its day looks by a
    colour fit to the night plate's surround (#549's method). No
    windows or lanterns are lit; painted relights replace them later
    (D51, D68).
- `plate-home.json`: `lights` and `lookLevels` for `night`, per
  station.
- Screenshot tests: add the night frames below.

Stay out of:
- `plate-home.json`'s `water`, `mooring`, `props` and `seasons` keys;
- every autumn asset;
- `PofuWorld/Scene/*`, `PofuWorld/Sky/*` and `PofuSound/*`, where
  C2 season air is in flight;
- `App/Rehearsal/*`, where MU3 #556 is open.

## Acceptance

- Frames:
  - `path-<station>-night-l1..l5` for all six stations;
  - `path-levels-i<stage>-night` at mixed levels, judged whole;
  - one frame at 19:59 and one at 20:01 with the same levels: the
    stations must not change, only the light.
- 1:1 crops:
  - each night base window's seam;
  - each look's foot and edges;
  - the lamps.
  No halo, no ghost of the painted station, no grey veil, and no look
  that glows brighter than the plate around it.
- Every day and autumn frame unchanged, compared frame to frame against
  `screenshots/main`.
- Rule v1: the worst state is at most 12,000,000 px. Report the number.
- Every check #554 ran: station_looks pytest, `ingest check`,
  `plate_gate`, `painted_light --check`, `check_plates`,
  `check_assets`.
- A `changes/art-night-stations.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- **Local Swift:** `tools/swift/test-linux.sh`. If the stale lock waits
  more than 10 minutes, kill nothing: say so and lean on CI. Read your
  Swift diff twice before each push.
- Disk floor 5 GB: remove `.build`, takes and frames when done.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- your picks with reasons;
- the crops' paths;
- the frame-diff list;
- the budget number;
- the defects you can still see.
