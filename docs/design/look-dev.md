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

## Round 2 (2026-11-02): containment, harmony, true darks, depth in motion

Founder feedback on round 1: objects stick out past the island; night and
unwell look washed out; the terrarium rim does not look good; the
çaydanlık still looks cold; every asset must be tuned, matched and
measured; HD-2D depth should read in motion; the island base is too
squashed.

### Containment

`preblur.py app` measures both sides from the art: the plate's walkable
polygon (its lawn, eroded 6 units so nothing stands on the grass lip) and
every sprite's ground footprint (the convex hull of its bottom rows, the
station guide's ground ellipse). `IslandFootprint` checks every slot (each
level's art and the empty build spot), resident and Pofu;
`IslandFootprintTests` fails on any overhang, and the scene draws through
`clamped(_:footprint:)`. Round 1's garden, çay ocağı, pond, workshop and
windmill moved onto the lawn; Fındık stepped out of the workshop's wall.

### Asset harmony

`tools/assets/harmony.py` (`tools/assets/README.md`) measures every master
in CIELAB at one world scale: black and white point, chroma, white balance
of the neutrals, edge softness, detail, and named materials. The world is
matched to the approved island, characters to Pofu, and a station level
to its chain's L1 (each level was redrawn from its locked parent and lost
about 30 % chroma). Past each tolerance it plans what colour can fix
(levels, chroma with a soft ceiling, white balance, material hue) and
`preblur.py app` bakes it; edges and detail are reported for the next
generation; Pofu and the sky are measured, never corrected. QA scores
every take at promote time (`harmony` line) next to PR #67's
`edit_chroma`, which stops new chain losses. The contact sheet is
`harmony.jpg` on the screenshot branch; the uncorrected bake stays as
`WorldLook.ArtSet.unharmonized` to compare.

The cold çaydanlık, measured: its copper sat at hue 54 (rose), against
honey wood at 63. The copper material target (61, chroma 44, between the
palette's copper and tea-amber) turns it to 59 and chroma 40 → 45.

### True darks for night and unwell

The art is high-key: its darkest pixels sit near L* 50. Round 1 scaled
that down and lifted the blacks, so night sat in a band of mid-greys.
Measured over the Home band (`tools/assets/frame_metrics.py`): night p2 22,
range 0.68 × day, local contrast 0.66 × day; unwell local contrast
0.88–0.91 × day with day's black point. `WorldGrade` gains input levels
(black, white) ahead of lift, gamma and gain. Night drops the art's
shadows to true darks (black 0.32), turns blue-violet through the gain,
adds contrast around a low pivot and desaturates, so the warm practicals
(drawn after the grade) pop. Unwell deepens (black 0.14) instead of
lifting, cools and roughly halves saturation, keeping contrast. The sky
takes the grade without its levels. Targets live in
`design/art/harmony/grade-targets.json`; CI writes `grade-metrics.txt`.

### Depth in motion

While the camera moves, each layer is offset by its distance from the
focus plane times the camera's velocity (`DepthMotion`), so near layers
sweep past and far ones lag, and the depth of field strengthens with
speed. Velocity, not displacement: zero when a move starts and when the
springs rest, so the settled frame is the authored one and costs nothing.
Offsets cap at 8 units (the plate bands overlap by 8, so they never part); Reduce Motion has
none. `look-motion` shows six frames of a Home → Island flight with and
without it.

### The island's thickness

QA only capped the earth body, and the prompts asked for shallower
plates (island-main-l-v2 came back at 0.168 of its width). Batch 05's
`island-main-l-v3` (`tools/imagegen/manifest/batch-05-fixes-pilot.yaml`,
from the production queue) deepens only the earth body, lawn untouched;
the new `depth_floor` QA check now fails it if the body comes back too
thin, instead of the lower bound being read by hand.

## Round 3 (2026-11-02): the island as hero, real art, the colour script

The lead's review of round 2: at the Island framing the island was small
under about 45 % of empty sky with a dead cloud area below, and the
small plate's tips bled off the sides; the art was still stand-ins; at
night Pofu and the residents turned lavender; unwell read pale because
the sky stayed pale. The founder added: the rose copper was prettier
than round 2's warm shift, and colour needs a real light design.

### Framing

- **Island:** the plate, tip to tip, fills 88 % of the width with nothing
  cropped; the island's box (the windmill's top to the roots) is centred
  between the top chrome and the bottom band (`IslandFraming.islandStop`).
  A phone is about twice as tall as the plate's silhouette is wide, so
  the island can never fill the band: the band above it is composed with
  the batch-04 far isles and painted clouds (`FarSkyLayout`, per framing,
  each element keeping its side so a flight reads as parallax), the band
  below with the cloud sea, now with the painted cloud-sea master as its
  front row.
- **Home** keeps ADR-0018's diorama (Pofu 154 pt, feet at 600 pt), nudged
  sideways at most a quarter of the width so Mochi and Fındık are whole or
  out (`IslandFraming.homeStop`). What shows where: at Home, Pofu with
  Fındık and Mochi, the workshop and the windmill deep behind him, the
  pond at the left edge and the far isles over the lawn's horizon; at the
  Island, every station, Pofu and both residents.
- **Measured:** `frame_metrics.py` counts the near-uniform rows below the
  top chrome (`empty`) and the longest such run (`run`); targets in
  `grade-targets.json` (`framing`). `look-framing.jpg` puts round 2's
  frames beside this round's with both numbers.

### Real art

The large plate is batch 05's `island-main-l-v3` (the same lawn as v2 over
the deeper body the founder asked for; `APP_PLATE_MASTER` switches back to
v2 in one line), 480 units across. Its lawn is 0.18 as deep as it is wide,
so depth, not width, limits the layout; a search over the real footprints
found the smallest plate that holds every station at every level, Pofu and
both residents without overlap. Every generated level ships: çay 1–5,
garden 1–5, pond 1–5, windmill 1–5, workshop 1 (workshop-2 is cut on the
left like its parent's master; regenerate it from the padded re-lock).
Mochi v2 and Fındık replace the stand-ins. Simit is İskele's, not the home
island's, so it is not placed here.

### Night and unwell, and the colour script

See `colour-script.md`: Pofu and the residents are drawn in their own
layer under the cell's character light (never the world's saturation cut)
with a rim from the nearest practical or the key; the ember lights the
rose copper; the cloud sea is pre-graded and lifted at night; the unwell
sky turns overcast. Frame checks: Pofu's hue at night and unwell within
20° of the day's and his chroma at least 0.6 × day's at night; the unwell
sky 0.80–0.94 × day's lightness and cooler.

### One full-screen grade pass

The sky and the cloud sea are pre-graded on the CPU (`SkyPalette.graded`,
`CloudSea.Colours`), so the sky's own shader pass is gone; the vignette is
one gradient overlay instead of a term in each pass; the characters are
graded per sprite (their rects only). The world layer's grade is the only
full-screen shader pass left.

### Re-locks

Re-locked from their kept takes with `lock-light` where it scored better
after harmony than the soft-lock master: island-main-l-v2 87.2 → 95.8,
pond-1 74.0 → 86.3, garden-3 69.6 → 87.2, garden-4 60.6 → 77.9,
windmill-3 69.6 → 87.5, windmill-4 64.7 → 70.9; workshop-1 (86.6 → 80.4,
lower) only to recover its clipped roof (`relock.py --pad`). The sky
masters, the characters, pond-2..5 and windmill-1, -2, -5 measured the
same or worse re-locked and stay on their masters. `relock.py` now applies
a level edit's alignment (it silently failed every chain level before).

## Round 4 (2026-11-02): the island pan, live Ayar, the lit flame

- **The Island framing pans.** Round 3 fitted the whole plate to the
  width, so Pofu was 46 pt and every station tiny. The world now stays at
  ×1.25 (Pofu 80 pt) and the Island framing is a horizontal pan across the
  island (`CameraRig.panDrag` / `endPan`): it follows the finger, a release
  coasts about a third of a second of its velocity and settles on the
  nearest snap point (each station, Pofu), and the ends rubber-band
  (60 pt). It opens centred on Pofu and every flight back re-centres. The
  whole island at 88 % of the width is the establishing shot on arrival
  (`IslandSceneModel.establish`, 0.9 s, skipped under Reduce Motion) and
  what a pinch out passes through. The cloud sea rises to the island's
  roots at any pose (`CloudSea.rise(z:pose:height:)`).
- **Ayar acts live.** Camera springs, parallax and tilt-shift reach the
  scene through `WorldLook.tuning` (`WorldTuning`, `CameraSprings`); Pofu's
  breath and blinks reach the companion through `companionLife`
  (`CompanionLife`). Defaults change nothing.
- **cay-1-lit** (batch 07) is the night overlay: its painted flame, cut
  from the burner's opening and drawn after the grade, fading in with the
  ember from dusk (`IslandLayout.litOverlay`). Nothing was regenerated.
- **Plate v2 vs v3** for the founder: `look-plates.jpg` (v2 baked as
  `WorldLook.ArtSet.plateV2`).
- Motion beat `06-island-pan`: arrival, drag, flick, rubber band, back to
  Pofu.

## Flags

`WorldLook` (environment value `worldLook`): `art` (lock-light,
soft-lock, unharmonized, round 2's copper), `grade`, `hd2d`, `depthMotion`, `hourOverride`,
`gradeOverride`, `frameMeter`. The default is everything on,
in the world scene only. `WorldLook.legacy` is the look before look-dev.
`FeatureFlags.worldHome` is unchanged (off).

## Decision: depth-map depth of field ships, normal lighting stays optional (2026-11-03)

PR #119 spiked two graphics ideas behind Ayar toggles. Decision:

- **Depth of field from a depth map is the default** (`GraphicsSpike`,
  `depthOfField` on). It was clearly better than whole-layer blur: the
  blur follows each pixel's true depth from the focal object, so a layer
  is no longer sharp or soft as a slab. The old per-layer blur is not
  removed: it is still the fallback where `WorldShaders` is unavailable,
  and the pre-spike look (`GraphicsSpike.off`) the screenshot tests
  compare against.
- **Normal-map lighting stays off by default but available in Ayar.**
  Its gain was modest: the art is already painted with baked light, so
  relighting mostly adds on top of it. Revisit with flat-lit art and tuned
  normal maps, where it should earn its cost.
