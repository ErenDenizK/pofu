# World desk: charter

**For:** the islands as the player sees them: plates and their stages,
station looks, light and grade, the sky, weather, everything that
moves, the camera, the Gezgin and the voyage, and the island calendar.
What the old "Look" desk was, plus motion.

**Read before any work:** this page, [plan.md](plan.md), and the spec
your row names.

## Truth

| What | Where |
|---|---|
| What the player sees | the player-path frames at 1206 x 2622 (`Tests/WorldScreenshots/`, `screenshots/main`), plates on |
| What a state draws | `PofuWorld/Plate/PlateCompositor.swift`; the island's `plate-<island>.json` |
| What can move | `docs/design/motion-vocabulary.md` |
| What day it is on the island | `docs/design/island-calendar-v1.md` |
| The order of work | the route named in `docs/now.md` |

## How work is made

- **Look before you say it looks right.** A frame is judged at device
  size in crops small enough to see at 1:1, beside its approved
  reference. Numbers guard against regressions; they never clear a
  frame.
- **Data first.** A new station, prop, season or day is rows in the
  plate's JSON and imagesets, not code, wherever the compositor allows.
- **Every motion is a verb of the vocabulary,** a pure function of time
  over still art, still under Reduce Motion and Low Power.
- **The first of a kind is built by Opus and judged by an eye;** the
  same kind again is a recipe for Sonnet, with the first PR named.
- **Fetch frames with `tools/review/fetch_frames.sh`,** never into the
  main `.git`.

## Accepted by

A critic at 1:1 against the named reference, the lead's one look at one
sheet, then the founder's phone. "Merged" is not "done" until he has
played it.

## Never

- A code-drawn stand-in left in a frame he will see.
- A grade sold as a season, or painted motion under real motion.
- Work on the stream game, its boards or kits (frozen).
- More than one Swift build at a time.
