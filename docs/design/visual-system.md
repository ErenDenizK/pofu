# Visual system: how a Pofu screen is made

The single description of a Pofu screen. Decisions: ADR-0022 (plate-first)
and ADR-0023 (colour lives in the painting). Spec for the plate runtime:
[plate-islands.md](plate-islands.md).

## One painting per state

Each island state is one painted picture. The picture is final. The runtime
adds only life.

In the painting:

- terrain, buildings, plants and water bodies
- sky, far islands and the cloud sea
- painted light and shadow

Separate layers exist only for:

- characters and critters: sprites with contact pads and occluder masks cut
  from the plate
- motion cut from the plate itself: water glints, cloud drift, sway masks.
  These are pieces of the painting, never repainted objects
- light that switches on: night glow masks
- UI

Anything static that is painted separately and pasted on the plate is
forbidden. That is the old collage that made the game look like mud.

## Change is a new painting

Levels, upgrades, time of day and weather are whole-plate edits of the
master. The app shows them by crossfade. Patches are cut from those edits by
a diff mask, so every pixel on screen comes from a whole painting. A state is
never made by a filter, a fog layer or a vignette.

## Colour

ADR-0023 in practice:

- Plates are painted at their final colour and contrast.
- The runtime is identity for a plate: no grade, LUT, fog or vignette, in any
  state.
- Plate prompts use `plate-style-v1`. They ban neon, HDR and washed-out
  pastel, not saturation.
- The style lock for kind `plate` is `plate-final`: alpha snap and edge
  feather only.
- Characters take the plate's light map, so they sit in the same light. The
  plate never takes the character's.
- A pale plate is painted again or edited. It is never graded.

## Resolution

- Generate at the image model's largest portrait size.
- Use the full take: `deliver` scale 1.0, no half-size copy.
- A x2 upscale step is a pilot (`tools/plate/upscale.py`). It may not exist
  yet. Do not depend on it.
- Textures are ASTC.

## Composition

- Plates are painted at phone aspect, at the in-app framing. No extension of
  sky or cloud sea is needed.
- The UI lives in the bottom band and one top-right button.
- Nothing covers the island.

## Checks before the founder sees anything

1. Colour metrics are within bands of the I1 reference. Run
   `python3 -I tools/plate/colour_metrics.py compare REF IMG...` with REF =
   `design/art/takes/batch-25-seasons/x-season-summer/plate__x-season-summer--t2.webp`.
   Flags: "pale" when C* p90 is under 0.85 x REF or accent share is under
   0.7 x REF; "hot" when C* p99 is over 1.25 x REF.
2. A real in-app screenshot from CI (not a mock-up or a bare file).
3. The lead looks at it. Metrics do not replace eyes.

## The ladder (now)

The colour level is chosen once, on the home root (`batch-66-home-flow`),
then held by the bands above. Three root jobs paint the same picture, 2 takes
each:

- `x-home-flow-final`: the control. The old block and half-size delivery, as
  first written.
- `x-home-flow-final-clear`: `plate-style-v1`, full size.
- `x-home-flow-final-rich`: `plate-style-rich-v1`, full size. The deliberate
  upper bracket.

The lead names the pick by eye plus metrics, and says which root is the
master. A naming PR repoints the 13 edit jobs (`edit_of`) to that root. Every
other plate batch (67 to 70) already uses the clear level.
