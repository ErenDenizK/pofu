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

## Flags

`WorldLook` (environment value `worldLook`): `art` (lock-light,
soft-lock, unharmonized), `grade`, `hd2d`, `depthMotion`, `hourOverride`,
`gradeOverride`, `frameMeter`. The default is everything on,
in the world scene only. `WorldLook.legacy` is the look before look-dev.
`FeatureFlags.worldHome` is unchanged (off).
