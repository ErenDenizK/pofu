# Brief: 3a-2, near ground polish (2026-11-28)

Role: `.claude/agents/builder.md`. Branch `art/near-polish`. Desk: `[world]`.

## Where it stands

#561 (merged, 04685125) gave the near camera its ground: the batch 206
tile as a soft-light detail over the plate, masked per stage, dressing in
data, the foreground strip clipped to the island. Code:
`PofuWorld/Plate/NearLayers.swift`, `NearGroundViews.swift`,
`tools/plate/near_ground.py`, `near_ground_data.py`, `plate-home.json`
`near`. The builder's own crops (while the scratchpad lasts):
`/tmp/claude-0/-home-user/ab6e36fd-b860-546d-a17d-cd7bb5d5a61b/scratchpad/w/f/c-{wheel,night,strip,autumn}.jpg`.
The frames are on `screenshots/main` after the merge publishes: `path-near-*`.

The lead's 1:1 review left four defects:

1. **Strip bottom olive-tan.** In the stall frame the foreground strip's
   lower part reads olive-tan, not lawn green.
2. **The wheel contour.** Where the sharp band meets a blurred foreground
   object (the stall's wheel), the band's edge follows the object's
   outline as a wavy line. The 6 pt feather softened it; the shape still
   reads.
3. **Night grass pale.** At `patch.night` 0.5 the band reads silvery,
   paler than the night plate's lawn beside it.
4. **Autumn leaf-pile rings.** The autumn mask leaves the piles out, but
   each pile has a faint lighter ring around it.

## Facts to check first (a false premise is a result)

- Each defect on the published `path-near-*` frames at 1:1, before you
  change anything. Measure, do not trust this list.
- Where the strip's bottom colour comes from (the plate's mean lawn
  colour, per #561), and why it lands olive.

## Change and targets

- Strip: its bottom within 3 L* and 5 degrees of hue of the plate's lawn
  just above the lip, in every light.
- Band edge at objects: no readable object outline. Fade the band out
  with distance from the object (or a much wider feather) rather than a
  sharp cut along it.
- Night: the band's mean L* and C* within 2 of the night plate's lawn
  beside it.
- Autumn: no ring. L* in a 10-30 px ring around each pile within 2 of
  the lawn farther out.

Stay out of `plate-home.json`'s `stations`, `lights`, `water`, `mooring`,
`props` and `seasons` keys and `tools/plate/station_looks.py` (N1b, #563,
is open there).

## Acceptance

- `path-near-*` in day, golden, night and autumn: before and after 1:1
  crops of the four spots, with the measured numbers.
- Mid and map frames unchanged against `screenshots/main`.
- Rule v1: the worst state at most 12,000,000 px. Report the number.
- A `changes/art-near-polish.md` line starting `[world]`.

## Process

- Your own worktree at a new path.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command.
- No local `.build`; disk is tight (about 5 GB). Delete frames as you go.
- Do not merge.

Hand back: the PR number, head SHA and CI result; the crops' paths; the
numbers; the frame-diff list; the budget; the defects you can still see.
