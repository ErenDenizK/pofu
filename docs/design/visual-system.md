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

## Sky sets

A world screen is an island plate over a **sky set** (gradient sky, far and mid
clouds, distant isles, a cloud sea) split from one painted portrait master per
island and light, so at rest it equals the painting and motion is code only
(off under Reduce Motion; the island never moves). It is not the old collage:
the sky shares only atmosphere with the island and comes from the same
painting. Decision, checks and consequences: [ADR-0025](../adr/0025-sky-sets-split-from-the-painting.md).

Home's level-10 day, golden hour and night draw theirs (`PofuWorld/Sky/`, motion constants in
`Plates/skyset-home.json`): far, mid and sea clouds drift 4, 9 and 14 px/s (at a 1206 px screen, scaled by
width) and breathe 3 px over 8 s, the isles bob 2 px, the whale glides and wraps off screen, and at night the
stars the sky layer already paints brighten in beats (no star is drawn by code). Everything is at time zero
under Reduce Motion, Low Power Mode and in screenshots; the island and the characters never move with it.
One 30 Hz timeline, paused in the background and not drawn toward the Map. The other home states keep their
plate until they are split.

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
other state the runtime puts them in the plate's light with three terms and a
two-layer contact shadow, from numbers stored per state in
`Plates/plate-home.json` (`harmony`, written by `tools/plate/ingest.py`) and
applied in Swift (`HomePlate.characterLight`, `PlateCharacter`,
`CharacterLightLayers`, `LampPool`, `ContactPad`). The plate is never graded
(ADR-0023): the characters go to the plate, never the plate to them.

- **ambient** (a multiply). A is the plate's lawn light: the geometric mean of
  the walkable lawn's mid-tone (25th to 75th L* percentile) and the mid-tone
  within 0.9 Pofu widths of the three contact points, in linear RGB. tint =
  A(state) / A(level-10 day) per channel, at most 1, at least 0.25. By day half
  of its colour cast is kept (the day plates differ little); at golden hour and
  at night **all of it** (the cast is the light; no half-cast rule). At night
  the tint is also capped so that a sprite's top (L* 97) sits `STONE_MARGIN`
  (7) L* under the brightest lawn stone around any character (the margin is the
  rim's and the pool's lift), and each character takes its own `scale` of it
  where its stones are darker. A lee on the lawn still darkens (`characterGain`).
- **key light** (golden hour and night). The key colour is read from the plate
  (golden: the lit stones, the walkable lawn's top 10 % L*; night: the lamps'
  glow). It is mixed over the sprite's own silhouette (normal blending, never
  past the colour) through a gradient across the sprite from the lit side:
  `rim` at the lit edge (golden 0.40, night 0.40), 0.5 of it at 40 % across,
  `fill` on the far side (golden 0.20, night 0). The sun lights from the plate's
  `lightDirection` (upper left); at night the nearest painted lamp does
  (`lamps` in `design/art/plates/home/objects.json`, the glow `lampHeight`
  above its ground point), and the rim fades to 40 % when a character is two
  widths or more from every lamp.
- **lamp pool** (night). A warm ellipse (1.9 x 0.68 of the sprite's width), the
  key colour screened over the grass at `pool` 0.35, under a character standing
  near a lamp; it fades to nothing at two widths from the lamp, and never
  touches the plate beyond the character.
- **bounce**. Every state: the lawn's own lit colour (the light map at the
  feet) mixed into each sprite's lower third at `bounce` 0.12.
- **contact** (two layers, each a multiply in the lawn's shadow hue, never grey):
  a soft pad (1.15 x 0.28 of the width, the lawn's shadow over its lit tone at
  0.55) and, right under the body, a tight occlusion core (0.6 x 0.11, the same
  shadow at 0.55 of its linear light, 0.9). Both scale with the state's
  `contact`: the lawn's shadow depth (L* p90 minus p10) around the contact
  points over the level-10 day's, 0.5 to 1.2.

A plate paler than the island's root asks one more thing: **saturation**. Çağlayan's dry
stages (a pale, nearly grey lawn) would put a full-colour otter on it, louder than the lawn, which a
multiply cannot fix. Its hand data turns on `characterLight.saturate`: a state's `saturation` is the
lawn's chroma over the reference plate's, to the power 0.6, at least 0.5 (omitted at 1, so Home's
data is untouched), and the sprite keeps that share of its colour (`PlateCharacter`). Çağlayan's
night also sets `stoneMargin` to 0 L* (Home 7; CI frame: 3 left the stage 2 otter 12.8 L* under her lawn, 0.2 outside the band): its tint was capped so far under the stones that its
otter read darker than any day plate allows. The golden rim is 0.5 there (Home 0.40).

Scale: Pofu keeps his size relative to the painted world (8.14 % of the plate width; 33 pt at the old 1.0 framing, about 38 pt at 1.15). Mochi and Findik are drawn at least 60 % of his
painted height (`residentBoosts`: Mochi 1.62, Findik 1.40 of his proportion;
62 % and 52 % +, measured on the sprites' boxes, 23.3 and 26.8 units against
his 60.8). Sharpness: measured at full resolution (Laplacian energy of the
body, registered against an ideal Lanczos downscale of the asset): Mochi and
Findik render 1.35 to 1.5 times *crisper* than ideal (aliasing from a 3x
minification, not softness), Pofu about 0.6 px softer (his rig is resampled by
the deform shader on top of the 5.3x minification of a 522 px portrait); the
companion art is shared by the whole app, so no density change was made for
Pofu here. Home framing: the island is 1.15 screens wide (`homeWidths`), its
mass centred at 54 % of the screen height (`homeTopY` 292) and the screen at
47 % of its width (`homeCenterX`); Pofu grows with the zoom.

Measured, not judged: `python3 -I tools/plate/harmony_check.py
home-plate-full-<state>.png ...` takes full-resolution app frames, finds each
body from the app's own geometry (the island is `homeWidths` screen widths
wide, Pofu's art is `pofuWidth` plate pixels wide, the body is the rig's body
ellipse shrunk to 0.75; Mochi and Findik by their sprite boxes), and compares
its mean L* and C* with the surrounding lawn (walkable lawn in a ring 0.8 to
2.4 character widths out, 25th to 75th percentile mean). With dL* and dC* =
character minus lawn:

- dL* within 10 of the level-10 day frame's (`REF` in the tool): as much
  lighter than the lawn as by day. Calibration: across the day plates (levels
  10, 5, 2) dL* moves 5.1 (Pofu), 8.2 (Mochi) and 3.7 (Findik);
- dC* at most +8 (never louder than the lawn, give or take the full cast of
  night's light on a nearly grey lawn) and at least the day's minus 12.
  Calibration: across the day plates dC* moves 11.2 (Pofu), 10.0 (Mochi) and
  9.6 (Findik);
- **night: no sticker.** Each character's L* 95th percentile is at or below
  the L* 95th percentile of the lawn ring around it (the brightest lawn stone),
  so by night the three are never the brightest things on the lawn;
- **golden hour: the fur follows the light.** The CIELAB hue angle of Pofu's
  mean fur colour moves from the level-10 day frame's at least half as far, in
  the same direction, as the lawn ring's does (a lawn that moves under 2 degrees
  asks nothing). A fur on the far side of the key light from the lawn (Damla's
  brown against Çağlayan's yellow-green, the key at 88 degrees) follows it by
  moving at least half as far *toward the key's hue* (the plate's `key`) as the
  lawn does.
- **Çağlayan's band is its own root's.** `--island caglayan --reference s4-day`
  anchors dL* and dC* on its stage 4 day frame (the picked root, as the colour
  check's REF is); every other shipped state is measured against it.

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
- Characters: Pofu about 38 pt at the home framing (his share of the painted world is fixed); Mochi and Fındık in proportion.
- A landscape plate (Çağlayan, 1536 x 1024) follows the same rule on the portrait screen: the
  island is 0.95 screens wide at the Island stop (`CaglayanLayout.closeScale`), its box centred at
  54 % of the screen's height (`IslandFraming.massY`), so a third of the screen is sky above it and
  a quarter sea below it, behind the bottom UI. The sky above deepens as Home's does; **the sea below
  is a calm continuation** (`backdrop: calm`: the plate's bottom band averaged across the rows,
  blurred and lightened to mist), never a cloud band repeated at growing sizes, which read as haze
  behind the buttons. Damla is the only resident drawn on it, at Pofu's painted proportion
  (`pofuWidth` 9.8 % of the plate, a tenth of the island) times 1.47 (about 9 % of the island's
  width, 34 pt wide), in the plate's light like Mochi and Fındık at Home.

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
