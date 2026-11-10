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
- A x2 upscale step exists as a tool (`tools/plate/upscale.py`, Real-ESRGAN
  general-x4v3 with a colour match; `docs/research/plate-upscale.md`). It is
  not wired into `ingest.py` until an in-app test on the first portrait plate
  compares, at full device resolution: Lanczos, the upscaler, and a 0.8 / 0.2
  blend of the two. The founder asked whether it feels "too AI"; the in-app
  view at real size decides, not a zoomed crop.
- Frames shown to the founder are at full device resolution (1206 x 2622 for
  the iPhone 17), not the reduced CI size, so softness in them is real.
- Textures are ASTC.

## Composition

- Plates are painted at phone aspect, at the in-app framing. No extension of
  sky or cloud sea is needed.
- The UI lives in the bottom band and one top-right button.
- Nothing covers the island.

## Checks before the founder sees anything

1. Colour metrics are within bands of the reference. Run
   `python3 -I tools/plate/colour_metrics.py compare REF IMG...`. REF is the picked
   home root, `design/art/takes/batch-66-home-flow/x-home-flow-final-rich/plate__x-home-flow-final-rich--t1.webp`
   (the ladder is decided; the old I1 floor no longer applies). Flags: "pale" when C* p90 is under 0.85 x REF or
   accent share is under 0.7 x REF; "hot" when C* p99 is over 1.25 x REF.
   Weather states (rain, snow, mist) are meant to be calmer and get their own
   bands from their first approved plate.
2. A real in-app screenshot from CI (not a mock-up or a bare file).
3. The lead looks at it. Metrics do not replace eyes.

## The ladder (result, 2026-11-10)

The colour level was chosen once, on the home root (`batch-66-home-flow`), and
is now held by the bands above. Three root jobs painted the same picture, 2
takes each:

- `x-home-flow-final`: the control (old block, half-size delivery). Pale and
  hazy: C* p90 39, accent share 0.08 to 0.09, flagged pale.
- `x-home-flow-final-clear`: `plate-style-v1`, full size. Good but flatter:
  C* p90 43.5 to 44, accent share 0.15.
- `x-home-flow-final-rich`: `plate-style-rich-v1`, full size. C* p90 47.2,
  p99 63.6, accent share 0.20, L* p50 80.2: the best depth and hierarchy
  without going neon.

**Picked: `x-home-flow-final-rich` take 1** (`pick: 1` in its review.yaml, 
concept master per the batch-66 lead rule). It is the master of the 13 phase 2
edit jobs (`edit_of` now points at it) and the `REF` of check 1: 
`design/art/takes/batch-66-home-flow/x-home-flow-final-rich/plate__x-home-flow-final-rich--t1.webp`.

`plate-style-rich-v1` is the house plate style. `plate-style-v1` stays in
`tools/imagegen/blocks/` (nothing is renamed) for calmer states such as rain,
snow and mist. The four island roots (batches 67 to 70) were picked at take 1
and their manifests now use the rich block.
