# Concept match: why the game looks worse than its concepts in light and colour

Founder, 2026-11-07: the concepts look clean, development screens look
muddled; copy the single-image home concepts (day, dusk, night, weather)
one to one, find what does not match, and build the island and its assets
as one whole (register: `docs/product/decisions.md` §6 V2, V4, V8; §10 Q-7,
Q-10). This note measures the gap, ranks the causes and gives the fix route
for each. It does not repeat `sky-weather-and-harmony.md` (craft sources) or
`night-lighting-2d.md` (relight maths); it applies them to numbers.

## 1. Pairs

Concepts (all exploration takes, never promoted; the home direction is being
picked on a separate board, and the pipeline below applies whichever wins):

| State | Concept | Game frame (screenshots/main, 2026-11-07) |
|---|---|---|
| Day | `batch-25-seasons/x-season-summer` t2, `batch-34/x-home-tam-cicek` t4 | `weather-home-clear` (12:00), `sky-home-1200` |
| Golden / dusk | `batch-25/x-season-summer-evening` t2, `batch-18/cl1-backdrop-dusk` t1 | `weather-home-golden-haze`, `sky-home-1830` |
| Night | `batch-45/x-home-night-key` t1, `batch-18/cl1-backdrop-night` t1 | `sky-home-2230`, `light-night-home` |
| Rain, mist | `batch-45/x-home-rain` t1, `batch-45/x-home-mist` t1 | `weather-home-rain`, `weather-home-mist` |

Sheets: `concept-match/01-day.jpg`, `02-golden.jpg`, `03-night.jpg`,
`04-weather.jpg`, `05-back-row.jpg` (detail crop), `06-lookdev-before-after.jpg`
(the home lookdev row under the old and new colour script).

`cl1-backdrop-day` and `-dusk` are themselves washed (sky and sea L* 85 to 90,
chroma under 10); they are not targets for colour, only for layout.

## 2. Method

CIELAB over five boxes per image: sky, back row of the island, focal row
(Pofu or the front lawn), earth face, cloud sea. Concepts resized to 1024 px
wide so their props sit at the game's scale (Pofu about 90 px high at the
460 px published width). `loc` is local contrast (RMS of L* minus its
3 px Gaussian blur): crisp versus soft. `back/focal` ratios show how much
the back row loses against the front. The box numbers came from a scratch
script; `tools/assets/concept_match.py` keeps the whole-frame numbers per
state (L*, black and white points, chroma, shadow hue, sky and sea) and
CI runs it on every screenshots branch.

## 3. Measured gaps

| Measure | Concept | Game now | Gap |
|---|---|---|---|
| Back/focal local contrast, day | 1.09 (summer), 0.77 (tam-çiçek) | **0.42** (clear), 0.35 (seeded noon) | back row loses ~60 % of its detail |
| Back/focal local contrast, dusk / night / rain | 0.80 / 1.40 / 1.65 | 0.36 / 0.49 / 0.36 | same, every state |
| Back/focal chroma, day | 0.98 | 0.84 | back row paler |
| Night: focal / earth / sea / sky L* | 50 / 57 / 60 / 30 | **26 / 13 / 13 / 12** | 25 to 45 L* too dark |
| Night: focal / sky chroma | 32 / 42 | 11 / 14 | a third of the colour |
| Night: shadow a*, b* | +20, −41 (blue-violet) | −4, +2 (neutral grey) | shadows are grey, not coloured |
| Rain: earth / sky L* | 75 / 75 | 53 / 58 | ~20 L* too dark |
| Rain: sky chroma, hue | 15.5, lilac (a +10, b −14) | 7.6, steel blue-grey | half the chroma, wrong hue |
| Overcast noon (seeded): sky L*, C | (no overcast concept; rain is 75, 15) | 62, 6 | greyer than the rain concept |
| Golden haze: earth / sea chroma | 37 / 15 | 53 / 40 | over-orange |
| Day: cloud-sea chroma | 6 (summer), 20 (tam-çiçek) | 3 | white-grey, no blue or lilac shade |
| Earth face, day: L*, p2 | 82, 56 | 64, 17 | darker, muddier (art) |
| Earth band art itself (ungraded) | — | L* 60, p2 8 | the art is dark before any grade |
| Focal row, day clear: chroma | 36 | 34 | **no gap**: the centre is not pale |

What did not differ: the day focal chroma and contrast, the day sky's zenith
(the game's is more saturated than the summer concept's), the props' raw
chroma (windmill C 34, garden 36 against concept props 36).

## 4. Root causes, ranked

1. **Depth of field blurs the island's own back row (code).** The default
   depth-map blur (`GraphicsSpike.field`, slab 34 around Pofu's depth 54)
   reaches the windmill (depth −50) at 2.3 pt and the back lawn at ~5 pt.
   Every concept keeps the whole island crisp; only the far isles and the
   sky soften. This is the founder's "paleness grows toward the back" and
   "no detail shows": the sunflowers and the windmill are not pale in the
   art, they are blurred (`05-back-row.jpg`).
2. **Night grade crushes value and colour (code).** Round 3's night
   (black 0.32, gain 0.44/0.50/0.90, saturation 0.72) subtracts an equal
   black point from all channels, so every shadow becomes neutral black
   and the earth lands at L* 13. The concept's night is a lit, coloured
   world: rose earth, teal lawn, indigo sky, lilac clouds.
3. **The default "day" frame is overcast (harness), and overcast and rain
   darken instead of tinting (code).** `sky-home-*`, `grade-*` and most
   review shots use the seeded weather of the test clock, which is
   overcast; `grade-day-home` is pixel-identical to `weather-home-overcast`.
   So the frames everyone reviews as "day" are grey. The overcast and rain
   rows cut the gain to 0.80 and pull the sky to steel grey; the rain
   concept keeps the island bright and makes the sky lilac.
4. **Earth face and some props are dark or flat in the art (art).** The
   earth band is L* 60 with doors as near-black holes (p2 8) and patched
   earth-face doors (batch 60) that sit on the plate rather than in it;
   the windmill and workshop are beige on beige. A grade cannot fix these
   without lifting everything.
5. **Composition (art and framing).** The concepts are landscape dioramas
   with the whole island in frame; Home is a portrait close-up of a plate
   wider than the screen, and the whole-island shot leaves the island small
   in a large empty sky (`03-night.jpg`, right). Q-7 (whole on open, tap to
   come close) is the framing answer; the art answer is in §6.
6. **Golden hour over-orange (code).** Golden saturation 1.30 with a 0.85
   blue gain takes the earth to chroma 53 and the cloud sea to orange; the
   evening concept is pink-lilac with peach light.
7. **Cloud sea near white by day (code).** The day sea's light is pure
   white and its shade almost white after the day grade's contrast.
8. **Night light comes from pools, not sources (code + art, open).** Pofu
   is still evenly lit at night; the per-pixel relight exists but is off
   (`GraphicsSpike.normalLighting`), with normals for three sprites only.
   Not changed here: it waits on Q-10 and the night ADR (V4).

## 5. What this change does (code, parameters and two small rules)

- **Rule: the in-focus slab spans the island** when nothing is focused
  (`LookTuning.islandSharpSlab` = 150, `GraphicsSpike.field`): the back row
  is as sharp as Pofu, the blur only takes the sky and what lies past the
  island. A focused station still pulls focus. Test:
  `theDepthOfFieldKeepsTheWholeIslandSharp`.
- **Night cell** (`design/art/colour-script.json`): black 0.04, lift
  (0.05, 0.04, 0.18), gain (0.62, 0.64, 0.86), saturation 1.0. On the raw
  art: earth L* 14 → 38, lawn 16 → 42, windmill 28 → 52; shadows from grey
  to mauve-violet. Sky, clouds, sea and fog re-picked so that, through the
  grade, they land near the night key (sky L* 14 to 32 indigo-violet, sea
  L* 46 to 61 lilac). Characters' night gain 0.64 → 0.76 so Pofu stays
  above the brighter ground. This is between "dark and real" and the
  concept's fairy-tale brightness, i.e. Q-10's recommended C; one table to
  move if he answers otherwise. Test rewritten:
  `nightIsReadableWithBlueVioletShadows` (replaces "true darks").
- **Dusk cell** re-keyed between golden and the new night (earth L* ~43),
  so the evening no longer dips darker than the night after it.
- **Golden cell**: saturation 1.30 → 1.15, blue gain 0.85 → 0.90, lilac sea
  shade: chroma on the art ~62 → ~52 (day's level).
- **Overcast and light rain rows**: gain 0.80 → 0.92 / 0.90, sky toward
  lilac-grey (`#B4AEC8`, `#A59EBB`) at a higher value; saturation and
  contrast as specified (the spec's numbers are kept).
- **Day sea**: warm-white light, a bluer shade (concept summer sea).
- **Harness**: `ConceptMatchScreenshotTests` renders Home and the whole
  island at each concept's hour and weather (clear weather pinned);
  `tools/assets/concept_match.py` lays each beside its concept with main's
  frames as "before" (`concept-match.jpg` on every screenshots branch).

All Reduce Motion and frame-policy behaviour is unchanged: these are
parameters of the existing passes. The blur pass still runs (sky and far
isles), at the same cost.

## 6. What needs art, and the Codex route

The founder's route is right, and it is the only one that fixes causes 4
and 5: **paint the island and the island with its assets as one picture,
under one light, at the game's camera, then cut layers from it.**

1. **Frame.** Portrait 1179 × 2556 (or the 1536 × 2732 max the tool gives),
   the game's Home camera: the plate's lawn ellipse, its band cuts (−0.32,
   0.32, 1.0 of the half-depth) and Pofu's slot drawn as a faint guide
   (`IslandLayout`, `WorldArt.generatedPlate`). A second take at the
   whole-island camera (`rail.wholeIslandPose`).
2. **Pair per light state, same seed.** Job A: the bare island (plate,
   earth face with its doors painted in, roots, cloud sea). Job B: an
   *edit of A* (edit-from-parent, same seed, A as the input image) that
   adds the stations, residents and props in their slots. Because B is
   painted over A, plate and props share the light, contact shadows and
   haze, and the plate pixels outside the props barely move.
3. **Cut.** Props = difference of B and A, thresholded in L*a*b* (ΔE > 6),
   cleaned with a 2 px close and the prop's own alpha from a third job
   (B with a flat chroma-key ground) when the difference is soft; the
   contact shadow stays as its own layer (B − A where only value drops).
   The plate is A, cut into the existing bands. `integrate.py` then needs:
   a `cut` source type (parent take + child take + key take), the band
   cuts from `generatedPlate`, and `harmony.py` run with a *zero* correction
   for cut layers (they already share the light; re-correcting each part
   separately is what made the patched doors stand out).
4. **Per light state.** Day is the base. Night, golden and rain are edits
   of the same pair ("same picture at night, lamp on"), used as the
   tuning targets for the colour script cells, not shipped, except hero
   night variants (house, door windows) where painting beats the grade.
5. **Fix list for the current art meanwhile:** the earth band (lift to
   L* ~75, doors with a lit inner rim instead of black holes), the batch-60
   earth-face doors (repaint into the band, not on top), windmill and
   workshop (white plaster and terracotta, as in the concepts).

## 7. Open

- Q-10 (night brightness) decides how far the night cell goes; Q-7 the
  framing. The night ADR (V4: light from real sources) is still owed.
- Pin clear weather in the other review shots (`sky-home-*`, `grade-*`),
  or name them as overcast; their grade metrics' "day" baseline is grey.
