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
- Characters take the plate's light, so they sit in the same light (see
  "Characters"). The plate never takes the character's.
- A pale plate is painted again or edited. It is never graded.

## Characters

Pofu, Mochi and Findik are sprites painted for the level-10 day plate. In every
other state they get two numbers from the plate, no more, stored per state in
`Plates/plate-home.json` (`harmony`, written by `tools/plate/ingest.py`) and
applied in Swift (`HomePlate.harmony`, `PlateCharacter`, `ContactPad`):

- **tint**: one multiply colour. A is the plate's lawn light: the geometric
  mean of the walkable lawn's mid-tone (25th to 75th L* percentile) and the
  mid-tone within 0.9 Pofu widths of the three contact points, in linear RGB.
  tint = A(state) / A(level-10 day) per channel, at most 1 (a multiply only
  darkens), at least 0.25, with half of its colour cast kept (its luminance
  follows the lawn in full; a night lawn is nearly grey and a full cast made
  white characters louder than it). A lee on the lawn still darkens a character further
  (`PlateMath.characterGain`).
- **contact**: the contact shadow's opacity factor. The lawn's own shadow depth
  (L* p90 minus p10) around the contact points over the level-10 day's,
  0.5 to 1.2; it scales the pad's two ellipses.

Measured, not judged: `python3 -I tools/plate/harmony_check.py
home-plate-full-<state>.png` takes a full-resolution app frame, finds each
body from the app's own geometry (the island is `homeWidths` screen widths
wide, Pofu's art is `pofuWidth` plate pixels wide, the body is the rig's body
ellipse shrunk to 0.75; Mochi and Findik by their sprite boxes), and compares
its mean L* and C* with the surrounding lawn (walkable lawn in a ring 0.8 to
2.4 character widths out, 25th to 75th percentile mean). With dL* and dC* =
character minus lawn:

- dL* within 10 of the level-10 day frame's (Pofu +6.6, Mochi +12.4, Findik
  +1.7 in the CI frame): as much lighter than the lawn as by day. Calibration:
  across the day plates (levels 10, 5, 2) dL* moves 5.1 (Pofu), 8.2 (Mochi)
  and 3.7 (Findik);
- dC* at most +6 (never louder than the lawn: the night lawn is nearly grey)
  and at least the day's minus 12. Calibration: across the day plates dC*
  moves 11.2 (Pofu: -37.5, -39.3, -28.1), 10.0 (Mochi) and 9.6 (Findik).

Any new plate state runs the check on its CI frame before the founder sees it.

## Resolution

- Generate at the image model's largest portrait size.
- Use the full take: `deliver` scale 1.0, no half-size copy.
- Plates ship upscaled x2 with a 0.8/0.2 blend (in-app A/B 2026-11-10, #352):
  `ingest.py` runs `tools/plate/upscale.py` (Real-ESRGAN general-x4v3 with a
  colour match; `docs/research/plate-upscale.md`) and mixes 0.8 of it with 0.2
  of Lanczos. It fails loudly without the model; `--no-upscale` ships the
  original on purpose. The texture budget is 9 MB (the x2 home set is 8.27 MB).
- Frames shown to the founder are at full device resolution (1206 x 2622 for
  the iPhone 17), not the reduced CI size, so softness in them is real.
- Textures are ASTC.

## Composition

- Plates are painted at phone aspect, at the in-app framing. No extension of
  sky or cloud sea is needed.
- The UI lives in the bottom band and one top-right button.
- Nothing covers the island.
- Characters: Pofu 33 pt at the home framing; Mochi and Fındık in proportion.

## Checks before the founder sees anything

1. Colour metrics are within bands of the reference. Run
   `python3 -I tools/plate/colour_metrics.py compare REF IMG...`. **Each island's
   REF is its own picked root** (the ladder is decided; the old I1 floor no
   longer applies):
   - home: `design/art/takes/batch-66-home-flow/x-home-flow-final-rich/plate__x-home-flow-final-rich--t1.webp`
   - Çağlayan: `design/art/takes/batch-67-caglayan-flow/x-caglayan-flow-4/plate__x-caglayan-flow-4--t1.webp`
   - Revontuli: `design/art/takes/batch-68-revontuli-flow/x-revontuli-flow-4/plate__x-revontuli-flow-4--t1.webp`
   - Emanet: `design/art/takes/batch-69-emanet-flow/x-emanet-flow-4/plate__x-emanet-flow-4--t1.webp`
   - Mehtap: `design/art/takes/batch-70-mehtap-flow/x-mehtap-flow-4/plate__x-mehtap-flow-4--t1.webp`

   Flags: "pale" when C* p90 is under 0.85 x REF or accent share is under 0.7 x REF;
   "hot" when C* p99 is over 1.25 x REF. **Cross-island accent floor:** for day
   states the accent share is also at least 0.15 whatever the island's REF, so
   a quiet root cannot lower the bar. Weather and night states (rain, snow,
   mist, night) are meant to be calmer and get their own bands from their
   first picked plate of that island.
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
