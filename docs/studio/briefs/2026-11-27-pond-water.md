# Brief: the pond's water made right (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `fix/pond-water`.

The pond's levels (#528) are on the island. Two defects remain in the
water. Both are in-app only: the static layers (base and looks) are
clean.

1. **Ghosts in the water.** Three pale, rounded-top rectangles sit in the
   pond, right of centre, in every pond level. Reference:
   `path-pond-reveal-1600` and `path-pond-l1..l5` on the screenshots
   branch of main.
2. **The water outline is the old pond's.** The `water` key of
   `plate-home.json` still holds the old, small pond's polygon (feather
   3, flow [[110,870],[300,890]], glint 0.12). The new pond looks are
   bigger and differ by level.

## Facts to check first (a false premise is a result)

- The lead's lead (not checked by running): `PlateWaterPatch`
  (`Plate/PlateRegionEffects.swift`, about l.170-215) copies the plate's
  own pixels (`drawnPlateArt`) round the water and draws them again,
  displaced, over the island content. If that copy is the old plate,
  not the pond look on top of it, the old pond's pieces would show
  through the new pond, moving. That would be the ghosts. Prove or
  disprove it first.
- If it is not the patch, the other suspects are, in order:
  - `FarSnapshot.swift` around l.138;
  - the sky set or the Map cut;
  - the pond pieces of `IslandDressing.swift` (l.122-124).
- The fastest proof is frames with one layer turned off at a time:
  - the water effect off;
  - the far picture forced off.

  Only CI can render them. Spend push 1 on those diagnostic frames, then
  delete them before the last push.

## The fix

- The moving water shows the water the player sees: the pond look of
  the current level, never the old plate under it.
- Each pond level has its own outline, fitted to its look's water and
  feathered inside the shore. It stops short of lily pads, the islet,
  the pavilion, the bridge and the boat, so nothing solid wobbles.
- If the data model can hold only one outline per island, give it one
  per station level, the smallest change that does it. Record the shape
  in the PR body.
- Level 0 and stages where the pond look is not drawn keep the plate's
  own water and its outline.
- Hold the water budget (`PlateRegionEffects.coverage`, at most 5 %) at
  every level. Report the worst.

## Others in the same files

- #543 (`art/station-levels-2`) owns `plate-home.json`'s `stations` key.
- The New Year kit (`feat/special-day-kit`) owns `props`.
- You own only `water`. The file is one line: resolve a conflict key by
  key, never by regenerating it from your branch.
- Stay out of `Voyage/`, `Gezgin/` and `Camera/`.

## Acceptance

- Frames `path-pond-l1..l5` and `path-pond-reveal-1600`.
  - 1:1 crops of the whole pond in each.
  - Two frames of one level at different water times, to show the water
    moves and nothing solid does.
- No ghost in any of them.
- The pond's frames otherwise unchanged against the frame before.
  Compare frame to frame and list each diff's bbox. Separate noise from
  real change with a baseline pair of two refs that share the assets.
- Tests:
  - the water region follows the pond's level;
  - the patch samples the drawn look;
  - the budget holds at every level.
- Every existing test, via `tools/swift/test-linux.sh`.

## Process

- Your own worktree.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command; loops under 600 s, re-run,
  are fine.
- Add a `changes/fix-pond-water.md` line.
- Disk floor is 5 GB and the disk is near it: fetch only the frames you
  need with `tools/review/fetch_frames.sh`, and remove `.build` and the
  frames when you are done.
- Do not merge.

Hand back:
- the PR number, head SHA and CI result;
- which layer the ghosts came from, with the diagnostic frame that shows
  it;
- the crops' paths;
- the defects you can still see.
