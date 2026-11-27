# Brief: PR 2d-2, the ride made flawless (2026-11-27)

Role: `.claude/agents/builder.md`. Branch `feat/voyage-ride-polish`.

The ride (2d, #539) is merged; read its PR body and
`Voyage/VoyageRide.swift`, `VoyageRideView.swift`. The founder asked
for travel with the Gezgin to be flawless (fi 46). The lead reviewed
#539's frames at 1:1 and found the defects below. Fix each, or name in
the hand-back why it cannot be fixed.

## Defects (frames from #539's screenshots run)

1. **Boarding cannot be seen.** In `voyage-0.0` to `-1.0` she is tiny
   and half cut at the left edge with Home as the cut neighbour, so the
   hop aboard happens off stage. The board beat must frame the island
   she leaves, with her moored beside it, the way `path-gezgin-wake`
   does: whole, centred, readable.
2. **Her size jumps.** In `voyage-1.0` she is a small sprite; at `-1.5`
   she is wider than the Home island under her. She and the islands
   share one world scale in every frame: moored, she is about a third
   of an island's width, and she is that in the air too. The camera may
   push in, but then the islands grow with her. No frame-to-frame jump
   in her on-screen size bigger than the camera's own.
3. **The plaque collides.** From `voyage-3.0` Köke's focus plaque
   ("Köke · Uykuda", from the scene's focus UI) sits under her and the
   passengers, and at `-3.5` Pofu hops through its text. The focus UI
   (plaque, card, bubble) stays hidden for the whole ride and appears
   only once the passengers are off.
4. **The rope is tied to air.** At Home it is a thin gold line from her
   mouth to a point off the rim, and reads as an antenna. Tie it to a
   post on the rim. Batch 160's `x4-gez-mooring-post` exists in
   pofu-art; if its pick is not in this repository, draw a simple post
   in the plate's style or name why not. It must be thick enough to
   read as rope at 1:1.

## Also in this PR

5. A tap on a far island and `PlaceControl` ride too; today only the
   row's verb rides. Every trip is one ride.
6. If S1 (#540) is merged when you start, read the plate by
   `plate.key` instead of `plate.light` at:
   - `Voyage/VoyageRowView.swift:178`, `:244` and `:249`;
   - `Scene/IslandScene.swift:1458`;
   - the Map path in `HomePlateCrop.swift`.

   If S1 is not merged, leave these and say so.

Not in this PR:
- Mooring at Köke and Çağlayan: that is row 2e. Keep the hover and
  fade, but the fade must not cut a passenger mid-hop.
- The chime.
- MapSlots removal.

## Acceptance

- Frames `voyage-0.0` to `-4.0` every 0.5 s, `voyage-back-2.0`, and the
  rope at Home.
- 1:1 crops of `-0.5` (boarding), `-1.5` (in the air, with an island in
  frame for scale), `-3.5` (arrival, no plaque) and the rope.
- A small strip of her on-screen width per frame, to show there is no
  jump.
- Every existing test, plus tests for the hidden focus UI and the
  single-ride entry points.

## Process

- Your own worktree.
- Swift tests only through `tools/swift/test-linux.sh`.
- At most three pushes after the PR opens, with label `screens`.
- Wait for CI with one background command (a loop under 600 s per
  call, re-run, is fine).
- Add a `changes/feat-voyage-ride-polish.md` line.
- Remove `Packages/PofuKit/.build` when you are done: the disk floor is
  5 GB and the disk is near it.
- Do not merge.

Hand back: PR number, head SHA, CI result, the crops' paths, the
defects you can still see.
