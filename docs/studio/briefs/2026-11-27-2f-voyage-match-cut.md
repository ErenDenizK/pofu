# Brief: PR 2f, one Home through the voyage's handover (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `fix/voyage-match-cut`. Desk: `[world]`.

The founder asked for travel with the Gezgin to be flawless (fi 46).
#541 polished the ride and #548 gave her a berth at every island. One
seam is left: the handover from the row (the board view she leaves
from) to the ride scene.

## What the frames show (main at #548, `screenshots/art-moorings`)

The lead's sheet, voyage-1.0 / 1.5 / 2.0 side by side at 460 x 1000:
`/tmp/claude-0/-home-user/ab6e36fd-b860-546d-a17d-cd7bb5d5a61b/scratchpad/handover-548.png`.

1. At **1.5** a faint second Home shows at lower centre (about y
   650-760 of 1000) while the row's Home is still fully drawn up top
   (y about 380-540).
2. By **2.0** Home has jumped to the lower place (y about 650-790), and
   she has jumped from below-right of it to above it.
3. At **2.0** the scene's Köke is faintly visible at top left. It starts
   to fade in at fly progress 0.22.
4. The place control (bottom right) stays during the ride.

#548 multiplies the scene's Home plate by `sceneIslandOpacity` in both
branches of `plateFade`, and its test says row and scene never both
exceed 0.05. The ghost at 1.5 is still there, so it is **not** drawn
through that path. #548's builder suspects Home's sky set or the map's
far-view layers (`FarSnapshot`?), not `PlateHomeLayer`. Find the layer
first and name it, with a frame where it alone is switched off.

## Change

**A match cut.** At the handover, the scene's first frame frames Home
at the same screen position and scale as the row, and places her where
the row has her. From then on the scene's camera moves
(`CameraFlight`). Home never shows twice, and neither Home nor she ever
teleports. The destination island fades in only once it is the
camera's subject, not as a ghost in the sky.

If an exact match cannot be made, the row fades fully out before any
scene layer shows. No frame may show both, and no island may jump.

The place control hides with the rest of the focus UI for every ride
and returns when the passengers are off (as #548 did for the chip and
tags).

Stay out of:
- `plate-home.json` and `tools/plate/*`;
- the rope (`GezginData.Rope`), which is merged and judged.

## Acceptance

- Frames `voyage-0.0` to `-4.0`:
  - every 0.25 s from 0.5 to 2.5;
  - every 0.5 s elsewhere;
  - the same for `voyage-back-*`.
- One strip of 0.5-2.5 at 1:1 height, to judge the handover as motion.
- A test that, across the handover in 1/30 s steps:
  - the departure island's screen position and scale, and hers, move by
    less than a small bound;
  - no island is drawn twice with alpha above 0.05, on every layer you
    found.
- The berth frames (`path-gezgin-koke`, `-caglayan`, `-moored-l2`) are
  unchanged.
- Every existing test passes, via `tools/swift/test-linux.sh`.

## Process

- Your own worktree, at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- Add a `changes/fix-voyage-match-cut.md` line starting `[world]`.
- Disk floor is 5 GB: fetch frames only with
  `tools/review/fetch_frames.sh`, and remove `.build` and frames when
  done.
- Do not merge.

Hand back: PR number, head SHA, CI result, the layer that made the
ghost, crops' paths, the defects you can still see.
