# 0023. Colour lives in the painting

- **Status:** Accepted
- **Date:** 2026-11-08

## Context

The first in-app plate (PR #338) looks clean, but the founder says the colours
are still pale. The paleness is baked in on purpose, in three places, from an
older decision to keep files "near neutral" and grade at runtime:

1. Prompt blocks: `style-anchor-v2` ("pastel warm palette of cream, golden
   peach and blush pink"), `prop-style-v2` ("milky pastel", "muted and lifted
   toward cream") and the manifests' AVOID line "saturated or neon colours".
2. Style lock: preset `lock-light` (used for kind `plate`) clamps green chroma
   at knee 34 / ceiling 48, lifts the value floor to 14 and keeps half the
   detail (blur).
3. The runtime grade (identity for plates since #338).

Plates are also delivered at half size (`deliver: {scale: 0.5}`), which softens
them on a 3x phone. The founder's rule: never fix a bad picture with filters;
make a good picture and keep it.

## Options considered

1. **Grade harder at runtime.** Reversible, but it is a filter on a picture
   that is not good, and it breaks night, rain and mist.
2. **Loosen the lock a little.** Still two competing colour authorities.
3. **Colour lives in the painting.** One authority, measurable, no runtime fix.

## Decision

Option 3.

- (a) Plates are painted at their final colour and contrast. The runtime
  applies no grade, LUT, fog or vignette to a plate in any state.
- (b) Every state (day, golden, night, rain, mist, each level and upgrade) is a
  painted edit of the master plate, never a filter.
- (c) Kind `plate` uses the new style-lock preset `plate-final`: it only snaps
  alpha and feathers edges. No chroma clamp, no value floor, no detail blur.
- (d) Plate prompts use the new block `plate-style-v1` instead of
  `style-anchor-v2`. Their AVOID lines ban neon or oversaturated colour and
  washed-out pastel, not saturation in general.
- (e) Plates are delivered at full take size (scale 1.0).
- (f) The colour level is chosen once by a ladder (control / clear / rich, the
  last using `plate-style-rich-v1`) on the home root, then held by measured
  bands against the founder-approved concept: the I1 day picture
  (`design/art/takes/batch-25-seasons/x-season-summer/plate__x-season-summer--t2.webp`),
  measured with `tools/plate/colour_metrics.py`.

Pofu's character art keeps `char-guard`. Sprite props that are not plates are
out of scope.

## Consequences

- Earlier notes that `lock-light` keeps files neutral do not apply to plates.
  ADR-0022 is amended, not replaced.
- A pale plate is regenerated or edited, never graded. Reviews add a metrics
  check (`docs/design/visual-system.md`).
- Files are larger (full size); textures use ASTC.
- Batches 66 to 70 use the new block and full-size delivery.
