# 0031. The texture budget counts what a Home state draws or keeps, in pixels, against one limit

- **Status:** Proposed (the lead accepts it when PR 1 of `docs/design/texture-budget-v1.md` merges)
- **Date:** 2026-11-27

## Context

The old rule counted ASTC bytes (one byte a pixel) against 9 MB, in four
places with comments that no longer matched. Nothing ships as ASTC: the
layers are HEIC and decode to 4 bytes a pixel (ADR-0024). The count was a
quarter of the real memory, included layers that never draw (the island
cut of a matted state, the occluders of a station standing on its base)
and missed what does (the props and the far picture). At 9 M the rule
forced 0.78 texture px per plate point at eight stations. Measurements
and the PR plan are in `docs/design/texture-budget-v1.md`.

## Options considered

1. **Keep the ASTC byte count and 9 M.** Forces soft looks to stay under
   a number no device imposes; the count still misses props and the far
   picture.
2. **Count the union of a crossfade's two states.** Exact, but the worst
   crossfade (an hour change) shares almost nothing, so twice the state
   limit bounds it with less code.
3. **No limit.** Memory grows with each station, season and sky without
   anyone seeing it.
4. **Rule v1 (chosen).** Count what one state draws or keeps, in texture
   pixels, against one limit in one file.

## Decision

- **D1.** Count what one Home state draws or keeps, in texture pixels; a
  pixel is 4 bytes decoded (8-bit RGBA). Per state: the drawn picture (the
  base where a station has one, else the plate), the sky set without its
  island layer (matted) or the backdrop, the island cut and the Map cut
  (non-matted only), the occluders that can draw (minus stations on this
  base), each station's current look at its largest, one more look for the
  one reveal, the props' worst frame, and the far picture (matted).
- **D2.** The limit is 12,000,000 pixels a state (48 MB decoded). A
  crossfade holds two states: 96 MB. It lives in
  `Packages/PofuKit/Sources/PofuWorld/Resources/Plates/texture-budget.json`
  (`statePixels`, `bytesPerPixel`, `lookDensity`) and the tools read it.
- **D3.** Every look ships at 2.0 texture px per plate point, the plate's
  own density, so no look is upscaled and a look is as sharp as the ground
  it stands on. The tea stall keeps its approved 3.0.
- **D4.** No GPU compression: the layers stay HEIC (ASTC would be a
  quarter of the memory, but download and repo size are the scarce
  resource, and encoding from shipped HEIC is lossy on lossy, ADR-0024).

## Consequences

- Eight stations at 2.0 fit (about 10.8 M at the worst state) with room
  for the Gezgin and a season's edits; the pond and later stations ship
  at 2.0, not 0.8.
- `plate_gate.py` prints pixels and decoded MB and fails above the limit.
- The JSON key `textureBytes` and the Swift names stay; their docs say
  "texture pixels" (PR 2 changes the Swift side). `plate-home.json` takes
  the new value at its next `ingest.py json home`.
- Savings that stay in reserve, used only when the gate reports a state
  over: tight per-look crops, banded bases, a cut sky set.
- It reverses the 9 MB limit; reversing D3 means re-cutting every look.
