# 0030. A season is an edit of spring: shared geometry, one key on the painted state

- **Status:** Proposed (the lead accepts it when the season slice, PR S3 of `docs/design/season-system-v1.md`, passes its gate)
- **Date:** 2026-11-27

## Context

The island year turns every seven days (`PofuCore/Game/IslandYear.swift`)
and nothing drawn follows it. Home is composed from one painting per
island stage and light, an erased base under the stations and a look per
station level (ADR-0022, `PofuWorld/Plate/PlateCompositor.swift`). The
founder wants a season to switch all of it at once and in harmony, with
no hand merges or colour fixes (founder-input 49).

Measured on shipped art and on batches 173 to 176 (season system v1,
section 3): an edit of the whole plate keeps its frame to under one plate
pixel (p90 0.4 to 0.7) and repaints a third of its pixels. A look cut in
one painting stands on another painting of the same island. A colour fit
learned on a plate pair carries a look from one state into another to a
median dE of about 6.

## Options considered

1. **Each season its own painted island.** Free composition per season.
   Every tap shape, foot, slot and look box again per season; the island
   jumps when the season turns; no check can compare a season to
   anything.
2. **Season layers over spring** (crowns, snow, leaves as overlays).
   Small files. Autumn and winter change nearly every ground pixel, so
   the overlay is the island.
3. **A grade.** No art. Tested and rejected in island-calendar-v1: it
   reads as a filter.
4. **Every season picture is an edit of its spring counterpart in the
   same frame, cut with spring's shapes, and a season is a third key on
   the painted state.**

## Decision

Option 4. Spring owns the geometry: tap shapes, walkable ground, feet,
slots, look boxes, alpha and mattes' starting shape. A painted state is
`(season, light, stage)`; spring's key and asset names are today's. A
season picture is never cut by difference from another picture. A state
shows a season only when every piece of it is listed as complete,
otherwise it shows spring whole.

## Consequences

- A season cannot change an outline: no taller tree, no new object, snow
  only on what is there. A season that needs a new shape needs a new
  spring shape first.
- Adding a season is art and data. Checks compare every season picture
  with its spring parent, so they can be numeric.
- Repainting a spring plate or a spring look invalidates its season
  children; they are re-derived or repainted with it.
- Reversing this after two seasons are painted means repainting them and
  their geometry: weeks. Reversing it before PR S3 costs one Swift PR.
