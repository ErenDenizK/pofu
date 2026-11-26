builder

# Brief 2: Home's composition (2026-11-24)

Stage 2.2 of `docs/design/assessment-2026-11-24-path.md`. The founder's
complaint since 11-16: the island sits in the upper half and more than
half the screen is cloud. This is a framing change on the plates that
exist. No new art. Start when stage 0 is merged. Branch:
`feat/home-composition`.

Every fact below is a lead. Open it before you build on it.

## What is there

- Home rests at the plate's mid stop: `HomePlate.midStop`,
  `Packages/PofuKit/Sources/PofuWorld/Plate/HomePlate.swift:556-567`.
  The level-10 island box is fitted to `CameraRail.midFitWidth` and its
  centre is put on row `CameraRail.midCentreY`.
- The numbers: `Camera/CameraRail.swift:121-124`. `midFitWidth` 378 of
  a 402 pt reference width, `midCentreY` 383 of 874, `youngFill` 0.72;
  the first two come from `WorldMap.shipped` when it loads.
- The sky set measures its depth from the same stop
  (`HomePlate.skyReference`, `HomePlate.swift:507-517`), so the sky
  follows the island when the stop moves. Check that it does.
- In the frames today (`path-d01-0900`, `path-d10-0900`,
  `path-d21-0900`, fetched with `tools/review/fetch_frames.sh`): the
  level-10 island spans about 33 % to 60 % of the height; the cloud sea
  runs from 60 % to Pofu's bubble at 72 % and on under the chrome; the
  far isles sit between 14 % and 26 %. At level 1 the island is 0.72 of
  the width and looks small in the frame.
- The island cannot be drawn wider: it already fills 94 % of the
  width. The room is in where it sits and in how large a young island
  is drawn.

## What to build

1. Render three candidates of the three frames above, side by side on
   one sheet, before you settle anything:
   - **now:** as shipped;
   - **low:** `midCentreY` moved down so the level-10 island's visible
     middle (lawn top to the roots' tips) is at 51 % of the height;
   - **low and full:** the same, and `youngFill` raised so the level-1
     island is at least 0.82 of the width.
   Hand the sheet to the lead and wait for the pick. My pick is the
   third.
2. Land the picked numbers where they live (the world map's data, not a
   second constant).
3. Follow the consequences and fix what moves wrongly: the cloud sea's
   top edge against the island's roots, Pofu's bubble and the collect
   button against the island's foot, the near lens's rest
   (`CameraRail.nearStop`, `CameraRail.swift:146`), a station focus, the Map stop's hand-off,
   the growth moment's bloom (`growCentre`, `IslandScene.swift:342`),
   Çağlayan's stop if it shares the number.

## Not yours

The station card and `plateFocusPose` (brief 1), `App/Home/`, any art
file. If the level-1 plate's ragged upper-left edge (visible in
`path-d01-0900` at 1:1) is in your way, report it; do not repaint it.

## Acceptance, in frames at 1206 x 2622

- `path-d01-0900`, `path-d10-0900`, `path-d21-0900`: the island's
  visible middle is between 50 % and 53 % of the height; nothing of the
  island is under Pofu's bubble, the collect button or the bottom bar;
  no far isle is cut by the top chrome.
- `path-d04-near-rest`, `path-d04-build-focus`, `path-stall-map-l3`:
  compared with main at 1:1, nothing is cut, doubled or left floating.
- One night frame and one rain frame of Home: the cloud sea's edge and
  the island's roots meet as they do on main.
- The framing tests that pin the old numbers are updated with the
  reason, not deleted.

Add `changes/feat-home-composition.md`.

## Hand back

The candidate sheet first (stop and wait). Then: PR, CI state, the
three Home frames before and after, what else moved. At most 15 lines.
