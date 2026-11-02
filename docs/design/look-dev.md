# Look-dev: reversible color, painted HD-2D lite

Status: implemented behind flags (2026-11-02); the founder chooses from
the screenshots. Code: `Packages/PofuKit/Sources/PofuWorld/Look` and
`Scene/WorldLookLayers.swift`; shaders in `Resources/WorldShaders.metal`.

## Why

The founder's concerns: the art looks washed out, because the style lock
baked desaturation and a contrast cut into the files; he loves Octopath
Traveler's HD-2D (sprites in a diorama, tilt-shift, bloom, light shafts,
vignette, particles, time-of-day light); and Liquid Glass in a game must
become a signature, not a weakness. He is afraid of a choice that cannot
be undone. So the choice is made undoable first.

## A. Reversible color: grade at runtime, not in the files

- **Bake only what must be baked.** The `lock-light` preset
  (`tools/imagegen/style_lock.json`, the default for new jobs) keeps the
  value floor (a soft toe at L 14–30, so mids and highs keep their
  contrast), the detail budget, the green and red hue fixes, the alpha
  snap and the edge feather. Saturation and contrast stay near neutral.
  `soft-lock` remains for comparison.
- **Grade at runtime.** `WorldGrade` is lift, gamma, gain per channel,
  contrast around a pivot, saturation, and a vignette, applied by the
  `pofuWorldGrade` Metal color effect to the world layer only (sky,
  plates, stations, residents, Pofu), never to the UI. Presets are data:
  `day`, `goldenHour`, `night`, `unwell` (a mild desaturation layered over
  the hour) and `calmGlow` (layered at calm 1.6–2.0). `WorldLight`
  derives the blend from the snapshot's clock (dawn 5:30–7:00, golden
  17:30–19:30, night from 20:30, bedtime always night) and wellbeing
  (unwell from 55 down to 30); the scene eases between grades over 2.5 s.
- **Never lose the sources.** `promote` keeps every raw as `raw.webp`
  (lossless under 600 KB, else q95), and `check_upload.py` fails a master
  folder without one. `tools/imagegen/relock.py` re-locks a master from its
  raw with any preset and refuses a result that does not register with the
  master (alpha IoU < 0.97).
- **Today's masters.** `island-main-s--lock-light.png` and
  `cay-1--lock-light.png` were re-locked from the takes kept on
  `art/batch-01-slice/all` (`world__island-main-s--t2.webp`,
  `station__cay-1--t1.webp`; lossy q90, the original PNGs were not kept),
  now `raw.webp` in each folder. Both registered with IoU 1.000. Mochi and
  Pofu are characters (`char-guard`, never desaturated), so they did not
  change. The prototype stand-ins (garden, pond, workshop, windmill, the
  other isles) are unchanged until their batch-03 masters land.
- **Comparing.** The app carries the soft-lock bake of the two masters as
  `<name>--softlock` sprites (`WorldLook.ArtSet.softLock`) until the
  founder chooses; then delete them and the `softlock` entries in
  `preblur.py`.

## B. Painted HD-2D lite

On top of the depth lens, all in one Canvas plus the grade pass:

- **Bloom** on emissive points (`IslandLayout.emitters`: the ember under
  the çaydanlık, the door's round window) and the sun's glow: additive
  halos, stronger at golden hour and night.
- **Light shafts** from the sun at golden hour: five blurred additive
  beams.
- **Vignette**, part of the grade (0.16 day, 0.26 golden, 0.40 night).
- **Tilt-shift per framing** (`LookTuning.tiltShift`): the lens gain ×1.7
  at the Island, ×1.3 at Home, ×1 on the map; the focus plane stays sharp.
- **Particles**: pollen by day, fireflies at night, in world space.

**Cost at rest is zero.** The scene's timeline runs only while the camera
moves or during a visit (`LookTuning.visitSeconds`, 6 s after the scene
appears); otherwise SwiftUI keeps the settled frame and nothing redraws.
`FrameMeter` (a debug overlay, `WorldLook.frameMeter`) records frame
intervals and process CPU; the screenshot run writes `frame-times.txt`.
GPU time is not readable in-app for SwiftUI rendering, so GPU-bound work
shows as long frame intervals; Instruments has the GPU timeline.

## C. Glass and paint

The terrarium rim (a Metal pass bending the world at the screen's edge
under a lip of system glass) was tried in round 1 and removed in round 2:
the founder judged it did not look good, and the code is deleted, not
flagged. **The rule stays: system UI is glass, celebration is painted.**
Controls, sheets and map labels are native glass; a station's new level
or a new island is a `CelebrationCard`: warm paper, a torn edge, a
painted border and a ribbon.

## Flags

`WorldLook` (environment value `worldLook`): `art`, `grade`, `hd2d`,
`hourOverride`, `frameMeter`. The default is everything on,
in the world scene only. `WorldLook.legacy` is the look before look-dev.
`FeatureFlags.worldHome` is unchanged (off).
