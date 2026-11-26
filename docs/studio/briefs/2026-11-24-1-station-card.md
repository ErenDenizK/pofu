builder

# Brief 1: the station card, two native glass variants (2026-11-24)

Stage 2.1 of `docs/design/assessment-2026-11-24-path.md`. The founder
rejected the station sheet on 11-17 ("nefret ettim") and chose a small
glass card by the station, to be tried in the app in two variants on his
phone (founder-input 43 and 44). Start when stage 0
(`feat/day1-pass-pill`) is merged; branch from that `origin/main`.
Branch: `feat/station-card`.

Every fact below is a lead. Open it before you build on it.

## What is there

- The sheet: `StationSheet`,
  `Packages/PofuKit/Sources/PofuWorld/Scene/StationSheet.swift:13-355`.
  It shows the station's name, an owner line, five pots for the level,
  the rate now and at the next level, one action (build, with its cost
  or the reason it is refused; play, for the garden) and a jar line.
- It is presented from `IslandScene.swift:311-327` as a system sheet
  with detents, over the lower half of the island (frame
  `path-sheet-station`: the sheet covers 53 % to 100 % of the height and
  most of it is empty cream).
- The model: `IslandSceneModel.swift:91` (`sheet`), `:111`
  (`sheetDetent`), `:852` (set on focus), and `plateFocusPose`
  (`:858`) which centres the station between the top band and a sheet
  of 0.42 of the height.
- A small native glass card already exists and is the pattern to grow
  from: `ResidentCard`, `StationSheet.swift:361-411`, placed under the
  resident's feet with a tail and kept on screen by
  `IslandScene.swift:2546-2562`. It uses `.glassEffect(.regular, in:)`.
- The frame: `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift:236`.

## What to build

The sheet goes. In its place, one small glass card that hangs by the
station, in two variants. Both carry the same four things and nothing
else: the station's name; its level as a row of small marks (`n` of
`m`, drawn in code for now; a painted mark comes from pofu-art batch
159 and drops into the same slot); the rate now and at the next level
in monospaced digits; one action, or the reason it is refused in the
action's place. The owner line, the flavour line and the jar line are
cut: the resident's own card says whose stall it is, and "12 çekirdek
daha" already says what the jar lacks.

- **A, Etiket (the default):** a card about 232 pt wide beside or under
  the station, with a tail pointing at it, like `ResidentCard`. All four
  things show at once.
- **B, Hap:** a pill under the station with the name and the level
  marks. A tap on the pill opens it in place into the same card as A; a
  tap outside closes it back to the pill, and a second tap outside
  dismisses it.

Rules for both:

- Real glass: `.glassEffect`, no painted panel, no cream paper. Text
  must stay readable over the lawn, the sky and the night plate.
- The card never covers the station it belongs to and never leaves the
  screen. Choose its side by where the station sits.
- The camera frames the station with room for the card, not for a
  sheet: `plateFocusPose` no longer reserves 0.42 of the height.
- No dimming and no modal. A tap on another station moves the card; a
  tap on empty ground dismisses it.
- While the station's build moment runs, the card is hidden; it returns
  with the new level when the moment ends.
- At accessibility text sizes nothing is clipped; the card may grow to
  the screen's width less 24 pt.
- `ResidentCard`'s "Go to the stall" opens the new card.
- The founder switches variants on his phone without Xcode: a plain
  two-way picker in Settings, in its own short section, not behind
  `DeveloperFlag`. It and the losing variant are deleted when he has
  picked. Strings are written natively in Turkish and in English.
- Delete `StationSheet` and what only it used (the detents, the paper
  sheet styling if nothing else uses it). Leave `InviteSheet` alone.

## Not yours

`App/Home/` (the pass pill has just landed there), the camera's stops
(`CameraRail`, `HomePlate.midStop`: brief 2 owns them), the flow game.

## Acceptance, in frames at 1206 x 2622

Add player-path frames and judge each in a 1:1 crop of the card:

1. `path-card-station-a` and `path-card-station-b`: the tea stall, day 5,
   as `path-sheet-station` is today. The whole island is visible; the
   card covers no more than a seventh of the frame.
2. `path-card-station-b-open`: Hap opened.
3. `path-card-station-a-edge-left` and `-edge-right`: the leftmost and
   the rightmost station; the card is whole on screen and its tail
   points at the station.
4. `path-card-station-a-refused`: not enough seeds; the reason sits
   where the action would.
5. `path-card-station-a-night`: readable on the night plate.
6. `path-card-garden-a`: the garden with rounds left; the action is
   play.
7. `path-sheet-station` is removed.

CI frames may draw glass flat; say in the hand-back what the frames can
and cannot show, because the founder judges the glass on his phone.
Add `changes/feat-station-card.md`.

## Hand back

PR, CI state, the crops of frames 1 to 3, what you deleted, anything the
glass does in CI that it will not do on the phone. At most 15 lines.
