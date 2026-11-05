# Light and shadow v2

**Status:** spec by the lead, 2026-11-05 (overnight). Builds on
[experience v1](experience-v1.md) §2 (the light field) and the
[day and night rule](art-production-plan.md#day-and-night-code-first)
("code does light; paint does shape"). The founder (2026-11-05): "improve
light and shadow in general".

## 1. What is wrong today

Measured from the code at `56b811fb`:

- **No sun shadow.** By day nothing casts a shadow. The sun has a position
  in the colour script (`ColourScript+Generated.swift`, `sun`) and the
  stations get a warm rim on the sun's side (`drawSunRims`), but the
  ground under every station, prop and character is unchanged. Objects
  float; the island reads flat and "static" (founder, 2026-11-05).
- **Contact shadows only at night, only near a source.** `drawRims` draws a
  feet ellipse when `sample.strength > 0.08`, so by day Pofu and the
  residents stand on nothing.
- **Night windows are four overlays.** Emissive overlays exist for
  `tea-stall-1`, `workshop-1`, `pond-5` and `windmill-5` only; every other
  level is dark at night, so "light from real sources" works at two
  levels of five.
- **Pools are code gradients.** The approved `glow-ground-pool` (#215)
  is not wired in yet.

## 2. The model: one sun, one moon, real practicals

| Time | Caster | Shadow length (× object height) | Softness | Opacity | Hue |
|---|---|---|---|---|---|
| Dawn (05:45-07:45) | sun, low east | 1.6-2.2 | very soft | 0.10-0.16 | cool (`cell.shadow`) |
| Day (07:45-17:15) | sun | 0.35 at noon to 0.9 | crisp | 0.22-0.28 | `cell.shadow` |
| Golden (17:15-19:45) | sun, low west | 1.4-2.4 | soft | 0.20-0.26 | warm violet (`cell.shadow`) |
| Dusk, night | moon (faint) | 1.2 | very soft | 0.06-0.10 | blue |
| Night | each practical (lamp, window, lantern) within reach | 0.6-1.4, away from the source | soft | ≤ 0.30 × the source's strength | `cell.shadow` |

Direction comes from the existing `sunX/sunY` (sun on screen) projected on
the ground plane: the shadow falls away from the sun and slightly toward
the camera (ground y is foreshortened by 0.5, as the contact shadow already
does). Length follows the sun's height (`sunY`). All numbers live in
`LookTuning` so they tune without code changes.

**Ambient occlusion pad.** Every object and character, always, also gets
a small dark pad at its base (radius from its footprint, opacity 0.18 by
day, 0.25 at night): this is what grounds things even at noon. It replaces
the night-only contact ellipse for characters; the cast-away offset stays.

## 3. How it is drawn (battery first)

- **Shadow silhouettes are baked offline.** `tools/assets/shadows.py`
  writes, for every world sprite that casts (stations, props, decor,
  residents, Pofu), a pre-blurred alpha silhouette at 1/4 resolution
  (`<name>-shadow`, a few KB each) into the world asset catalog. No blur
  at runtime, ever.
- **One world-space shadow layer.** `ShadowBake` renders all static
  casters' shadows (silhouette scaled flat by length, sheared by direction,
  plus the AO pads) into one offscreen image in world coordinates at half
  resolution, drawn as one image between the island plate and the objects.
  It is rebuilt only when its key changes: the sun bucket (direction and
  length quantised to 3°, so a rebuild every ~10 game minutes), the
  layout (a build, a level, decor moved), or the time band (day, golden,
  night). Panning and zooming the camera never rebuild it.
- **Moving casters draw their own.** Pofu, visitors and critters draw
  their silhouette shadow and pad at their feet each frame they move (one
  image draw each); when settled they are part of the frozen frame like
  everything else.
- **Shadows fall on the ground only.** They sit under the sprites, so a
  building never darkens the one behind it. Correct enough for a diorama
  and free of per-sprite masking.
- **Budget:** at most one extra full-screen image draw per frame plus one
  small draw per moving character. The frame policy (120 / 60 / 30 / 0 Hz)
  is unchanged; the frame meter in the screenshot harness must show no
  regression.

## 4. Night: real light from real things

- **Pools use the art.** The light field's round pools draw
  `glow-ground-pool` (additive, tinted by the source) instead of the code
  gradient; window spills stay code until `glow-window-spill` lands.
- **Every lit thing has an emissive overlay.** The pipeline already turns a
  lit edit into an overlay by difference against the day master. Codex
  paints the lit edits for the levels a player reaches in Book One
  (`batch-36-lit-ladder`, pilot first): lighthouse lamp, path lamp,
  windmill, doors, the tea stall's burner, the workshop and the pier
  lanterns. Each overlay registers itself as a `LightSource` (the source
  list in `LightField.make` reads from one table, not from per-station
  code).
- **Character shadows from the nearest light.** At night Pofu and the
  residents cast their silhouette away from the strongest source in
  reach (the field's sample already has the direction), plus the faint
  moon shadow when no source reaches.

## 5. Moments of light (after §2-§4)

- **Level-up ceremony** (founder, 2026-11-05: "lamps that emit light,
  flashy level-ups"): the station's lamps and windows switch on one after
  another (40 ms apart), a warm burst blooms from the building, the pad
  under it brightens for 1.2 s and the shadow layer rebuilds with the new
  silhouette while it is covered by the burst. Haptics from `PofuHaptics`
  (the build palette). 60 Hz moment tier, then back to 0.
- **Cloud shadows** by day: two or three very soft shapes drift across the
  island at the 30 Hz ambient tier only (frozen when settled, off in Low
  Power Mode and under Reduce Motion).

## 6. PRs (disjoint files)

| PR | Owns | Contents |
|---|---|---|
| **LS-1 sun shadows** | `tools/assets/shadows.py` (+ test), `Look/SunShadow.swift` (pure, tested), `Scene/ShadowBake.swift`, the shadow imagesets, the insertion point in `Home/WorldHome.swift` | §2 and §3 for the sun, AO pads, characters' moving shadows by day; tests for direction, length, the bucket key |
| **LS-2 night light** | `Look/LightField.swift`, `Scene/WorldLookLayers.swift`, `Look/WorldLight.swift` (`LookTuning`) | §4: pools from `glow-ground-pool`, the emissive overlay table, character shadows from sources, the moon shadow; removes the night-only contact ellipse |
| **LS-3 moments** | `Moments/BuildMoment.swift`, `Scene/BuildEffects.swift` | §5: the level-up ceremony and cloud shadows |

LS-2 starts after LS-1 merges (it reuses the silhouettes); LS-3 after
LS-2. Each PR's screenshot sheet shows home at 07:00, 12:00, 18:30 and
22:30 at the default zoom and one close-up of Pofu; the lead reviews the
sheet before merging.

## 7. Done when

- At noon every object sits on the ground; at 18:30 the long shadows read
  at a glance; at 22:30 each light visibly lights the ground and throws
  the characters' shadows away from it.
- The frame meter shows no regression; settled frames still render at
  0 Hz.
- The founder's next device test: no "floating" objects, no "pale and
  flat" island.
