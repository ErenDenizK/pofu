# Brief: N1b, painted night looks for four stations (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `art/station-nights-painted`. Desk: `[world]`.
Start after N2 (`art/golden-stations`) merges, because both edit
`tools/plate/station_looks.py` and `plate-home.json` `stations`.

## Why

N1 (#559) shipped night bases and night looks. For the workshop, tea
stall, bagel cart and lighthouse, the night look is the day look
colour-fitted to night. It is muted and unlit. Painted night takes
already exist for all four, and the lead's picks are on pofu-art main:

| Station | Batch | Night picks L1-L5 | Grade to apply (light, darks, chroma) |
|---|---|---|---|
| Bagel cart | 190 | t1 t1 t1 t1 t1 | x1.15 (~+8 L*), darks +11, x0.5 |
| Workshop | 191 | t1 t1 t1 t1 t1 | L1-2: x1.17, darks +11, x0.9; L3-5: x1.07, darks +6, x0.8 |
| Lighthouse | 192 | t2 t1 t2 t1 t1 | x1.25 (~+15 L*), darks +19, x0.65 |
| Tea stall | 196 | t2 t2 t2 t2 t1 | measure it as the others were measured |

- The grades are from pofu-art #228. Each reviewer target is the day
  pick under its day grade, carried through the level 8 plate's own
  day-to-night change at that station. The darks need a lift on top of
  the multiply. `stats.json` and the 1:1 sheets are in
  `/tmp/claude-0/-home-user/ab6e36fd-b860-546d-a17d-cd7bb5d5a61b/scratchpad/out/`
  while that folder lasts.
- **Workshop 1 and 2:** both nights drop the bulb hanging inside the
  opening, and level 2 also drops both wall lamps. Paste them back: the
  wall lamps from `workshop-1-night` t1, and the bulb from the day look
  through the night fit. The boxes are in each `lead_review`. Lit
  sources stay lit at night, because the day form has them.

## Facts to check first (a false premise is a result)

- Each pick in its `review.yaml` on pofu-art main.
- How N1 cut the pond's and the windmill's painted nights. Cut these
  four the same way: the day outline, then the grade.
- The tea stall at stages 3 and 4 (scale 0.81, foot 711,839; #554).

## Change

- The painted nights for the four stations replace their derived looks.
- The windmill's level 3 stays derived; its redo is pofu-art D72.
- Update the `night_looks` docstring: it says no window or lantern is
  lit.

Stay out of:
- `plate-home.json`'s `near`, `water`, `mooring`, `props` and `seasons`
  keys;
- `PofuWorld/Plate/NearLayers.swift`, where 3a is open.

## Acceptance

- `path-<station>-night-l1..l5` for the four stations, and
  `path-levels-i<stage>-night`.
- 1:1 crops of each look's foot and edges, and of the lit sources:
  - warm light small, with no halo into the sky;
  - no look brighter or more saturated than the night plate around it.
- Before and after: the same crops from `screenshots/art-night-stations`.
- Every day, golden and autumn frame unchanged.
- Rule v1: the worst state is at most 12,000,000 px. Report the number.
- Every check #559 ran.
- A `changes/art-station-nights-painted.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes, with label `screens`.
- Wait for CI with one background command.
- **Disk is tight** (about 5 GB). Delete takes and frames as you go, and
  do not start a local `.build`; lean on CI.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- the crops' paths;
- the frame-diff list;
- the budget number;
- the defects you can still see.
