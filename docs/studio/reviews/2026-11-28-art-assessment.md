# Pofu art assessment: does it read as one hand-painted world?

> Crops and the q4 sheet are not committed (scratchpad only); the frames are on `screenshots/main` as of 2026-11-28.

Critic pass, 2026-11-28. Frames: `screenshots/main`, 1206 x 2622. Reference: pofu-art `origin/main`
(art bible v1.1, world-concept-picks batch 112, flow board, palette cards, colour-script v1).
Crops are in `crops/`. Coordinates are full-frame pixels (x, y). Numbers are CIELAB medians
(L*, C*, hue in degrees). The scripts that produced them are in `scripts/`.

## Verdict: fix

The day Home island is the concept made real. It is one hand: a coherent pastel palette, a
pink-clay belly, a lilac cloud sea that matches the concept (app L88 C11 h297, concept L85 C12 h302),
and residents that sit in the same light (`crops/day-island-half.png`, `crops/koke-close.png`).
Everything around that moment breaks the promise. Night is grey mud with day-lit characters pasted
on. Winter is summer. The day and golden skies are not the colours the script asks for. The golden
sky has flat cut-out cloud shapes. The near camera spends a third of the screen on blur. None of
these needs new art except winter. Most are grade or layer fixes.

Frames judged (15): `path-d21-0900`, `-1800`, `-2300`; `path-season-autumn-i10`, `-winter-i10`,
`-summer-i10` (plus `-i3` and night pairs for the winter check); `path-near-pofu`, `-golden`,
`-night`, `-autumn`; `path-near-stall`; `path-stall-pofu-front`; `path-d10-koke-0907`;
`path-d13-map-0900`.

## Findings, ranked by what each costs the look

### 1. Night is grey fog, and the characters keep their day colour (high certainty)
- **Frames:** `path-d21-2300` (`crops/night-island-half.png`, `crops/night-lawn-pond.png`);
  `path-near-pofu-night` (`crops/near-night-pofu.png`, right panel of
  `crops/pofu-pair-concept-day-night.png`).
- **What is wrong:** the night lawn measures L58 C5, a neutral grey. The bible's night meadow is
  `#2F4A45` (L29 C11.5, teal). So the lawn is about twice as light as it should be and has no
  colour. Pofu stays warm cream-peach at full day value (near camera: Pofu L71, ground L67, ΔL 4.2).
  The flowers and clover sprigs keep vivid day greens and lilacs. On the grey ground they read as
  stickers. No lantern throws a warm pool on the ground. This is "the same mud" the founder warns
  about.
- **Likely cause (checked in the script, not in Swift):** the night grade in `colour-script.json`
  lifts blue by 0.5, lifts red and green by 0.04 to 0.05, and sets contrast 0.9. That combination
  produces a lifted grey veil. The `character` block at night is nearly neutral (gain .97/.94/.90,
  saturation 1.0), so Pofu is not graded into the moonlight.
- **Smallest fix (grade, in `colour-script.json` night cell):**
  - blue lift 0.5 to about 0.12;
  - contrast 0.9 to about 1.05;
  - character gain to about (0.86, 0.88, 1.0) with a cool fill;
  - raise `poolGain` so lanterns light the ground;
  - put the protected local-colour sprites through the world grade at night.
  - Re-render and compare against meadow `#2F4A45`.
- **Check:** in the night frame, the lawn-mask median must be L ≤ 40 and C ≥ 8, and Pofu's mean
  must fall within ΔE 15 of the graded ground's key.

### 2. Winter is the summer island (certain)
- **Frames:** `path-season-winter-i10` against `path-season-summer-i10`
  (`crops/winter-island-half.png`).
- **What is wrong:** the two frames differ by a mean of 0.25 levels. Only 0.27 % of pixels change,
  and those are the falling particles. The same holds for `-i3` (0.22) and for both night pairs
  (0.56). Autumn does change (mean 11.9, lawn hue 105 to 90). Winter has no snow, no frost and no
  cold light. A player in December sees June.
- **Smallest fix:** a cold winter grade cell as a stopgap (lower saturation on greens, a blue-white
  key, frosted cloud-sea tint). The real fix is a Codex edit-keep pass: snow-dusted lawn and roofs
  over the existing plate, aligned to its parent.
- **Check:** for every season pair, mean |Δ| against summer must be > 5 levels, or the season fails.

### 3. The day and golden skies are not the colours the script specifies (high certainty)
- **Frames:** `path-d21-0900`, `path-d13-map-0900`, `path-stall-pofu-front`, `path-d21-1800`
  (`crops/day-sky-band.png`, `crops/map-pair-concept-app.png`).
- **What is wrong:** measured at the zenith (x 200 to 1000, y 150 to 450):

  | Sky | App renders | Colour script | Pastel reference |
  |---|---|---|---|
  | Day | L66 C46 h278 | `#69CFFF` (L79 C36 h243) | Concept map sky L85 C15 h291; bible day sky `#BFE1F0` (L88 C14) |
  | Golden | L65 C36 h306 (violet) | `#E2ADC7` (L76 C24 h346, pink) | — |
  | Night | L32 C38 h289 | `#303E7A` (L28 C39 h291) | — |

  So by day and at golden hour the sky renders about 13 L darker and about 35° more violet than the
  script, and by day it is three times the chroma of the concept. Night matches the script. The
  sky is the largest area on Home and on the map, and it is the hottest, darkest colour on screen.
  It pulls the pastel island toward a saturated-poster read. The founder's "more pastel" instinct
  is right about the sky, and the pinks he wants are already in the script; the renderer is not
  delivering them.
- **Likely cause:** the world grade (day saturation 1.32, contrast 1.16; golden saturation 1.15)
  and the vignette are applied over the sky gradient. The violet shift suggests a blue lift or the
  shadow colour `#A99BC4` mixing in.
- **Smallest fix (code):** exempt the sky layer from the world grade's saturation and contrast, or
  pre-compensate it so the rendered zenith lands on the script colour. Separately, consider moving
  the day zenith toward about L80 C22, between the script and the concept.
- **Check:** render the sky alone per cell and fail when ΔE2000 from the script's zenith and
  horizon is > 6.

### 4. The golden-hour sky has flat, hard-edged cloud silhouettes, and its edges are mirrored (high certainty)
- **Frame:** `path-d21-1800` (`crops/golden-sky-stripes.png`, `crops/golden-sky-shape.png`).
- **What is wrong:** large cloud-shaped areas in a darker violet have crisp contours, for example
  around (620 to 1150, 600 to 800) and (60 to 350, 760 to 870). They read as cut-out stickers laid
  behind the painted clouds; they are probably the `cloudShade` layer drawn as unfeathered masks.
  At both screen edges (x 0 to 60 and 1150 to 1206, y 600 to 830), lilac posts and yellow glow
  patches appear as matching pairs. On the shipped Home frame the edge cloud stacks correlate 0.56
  mirrored against −0.07 repeated (`crops/sky-edges.png`, `crops/box-sky-highpass.png`). The same
  layer shows a rounded-rectangle edge in the day sky around y 930 (bottom of
  `crops/day-sky-band.png`).
- **Smallest fix (code):** feather the cloud-shade masks (blur ≥ 24 px at device scale) or drop the
  layer at golden hour. Re-place the edge clouds without symmetry. Extend the sky layer past the
  screen bounds so its rounded corners leave the frame.
- **Check:**
  - a high-pass of the sky region must show no closed contour above 3 levels outside the cloud
    sprites;
  - the left and right 120 px strips must correlate < 0.3 when mirrored.

### 5. Pofu reads pale and floats, at both distances (medium-high certainty)
- **Frames:** `path-near-pofu` and `path-d21-0900` (`crops/pofu-pair-concept-day-night.png`,
  `crops/day-pofu-zoom.png`, `crops/near-lawn-band.png`).
- **Measured** (body ellipse against the ground below it):

  | | Pofu L | Pofu C (median / p90) | Ground L / C | ΔL |
  |---|---|---|---|---|
  | Concept near t2 | 86.9 | 21 / 46 | 72.6 / 59 | 14.3 |
  | App near, day | 89.8 | 14 / 37 | 80.6 / 50 | 9.2 |
  | App near, golden | 88.0 | 15 / 33 | 80.3 / 42 | 7.7 |
  | App near, autumn | 78.0 | 25 / 42 | 69.1 / 54 | 8.9 |
  | App near, night | 71.4 | 10 / 22 | 67.2 / 7 | 4.2 |
  | App Home, day | 86.4 | 19 / 48 | 82.3 / 53 | 4.1 |

  Character card: peach2 `#ECA96E` is L74 C44 and cream3 is L87 C17.
- **What is wrong:** up close, Pofu's peach peaks at C37 against the card's C44 and the concept's
  C46. That is a third less median chroma. The sharp lawn band behind him is lifted to L88
  (concept near lawn: L68). He loses a third of his value separation. Nothing grounds him: the
  concept casts a soft shadow under the body, but the app has none, near or on Home. On Home he
  stands directly above the lantern post (around 540, 1290) and reads as perched on it. His fur
  hue (h71 to 78) is right; only the strength is down.
- **Smallest fix:**
  - **Grade:** pull the near sharp-lawn band down about 8 to 10 L, and give the character grade a
    peach-selective saturation of about 1.15, since global saturation also lifts the lawn.
  - **Code:** add a soft contact-shadow ellipse (warm mid-brown, about 25 % opacity, feathered)
    under every character.
  - **Layout:** nudge Pofu's Home spot off the lantern post line.
- **Check:** per frame, Pofu-vs-ground ΔL must be ≥ 10 and Pofu's peach p90 chroma ≥ 42.

### 6. The near camera: blur fills a third of the screen, smears the sky, and softens the hero (high certainty)
- **Frames:** `path-near-pofu` (`crops/near-pofu-whole.png`, `crops/near-bottom-right.png`,
  `crops/near-sky-topleft.png`); `path-near-stall` (`crops/near-stall-whole.png`,
  `crops/near-stall-focus.png`).
- **What is wrong:**
  - From y ≈ 1850 to the bottom, about 30 % of the screen is a shapeless olive wash (L70 C50 h108).
    The only thing in it is a stray thin vertical stalk at x ≈ 905, y 2250 to 2622, which reads as
    a scratch.
  - The top third is an empty blue sky. The far islands in it are Gaussian-blurred into rainbow
    blobs with green and orange fringes: a lens artefact, not paint.
  - In `path-near-stall` the tea stall is the subject, yet it is soft. Its Laplacian variance is
    12, against 157 on Pofu's face and 293 on the sharp lawn. Its edges are mushy, as if
    upscaled. The focus sits on the wrong plane.
  - The bunny is cut by the left screen edge, and the wheel sliver is cut in the stall view.
- **Blur verdict (question 2):**
  - **Keep** a soft foreground. The founder-picked concept `near-locked-t2-soft-foreground` has one,
    so blur itself is in the concept.
  - **Change its dose and its shapes:** cap the soft foreground at about 20 to 25 % of the height,
    and keep it as recognisable painted masses (flowers, wheel) rather than a colour field.
  - **Drop** the blur on the far islands; fade them into haze instead.
  - **Put the near subject in the sharp band.**
  - Home's own depth treatment (sharp island, soft cloud sea) reads as painted and should stay.
- **Check:**
  - in each near frame, the fraction of rows with Laplacian variance < 5 must be ≤ 0.25;
  - the named subject's box must score ≥ 0.5 of the sharp-band variance.

### 7. Map view: an empty top third and a white fog bank (medium certainty)
- **Frame:** `path-d13-map-0900` (`crops/map-pair-concept-app.png`, `crops/map-island.png`).
- **What is wrong:**
  - The concept map is a lilac cloud carpet to the top of the frame, with the far isles and the
    whale high in it. The app map is saturated blue sky for the top ~37 %, with tiny clouds.
  - A shapeless white fog bank swallows the lower third of the island belly and its windows, which
    reads as a glow without a source.
  - Köke's isle is a sliver at the right edge.
- **Smallest fix (code/camera):**
  - tilt or offset the map camera so the cloud sea reaches the upper third;
  - halve the under-island fog opacity;
  - pull the neighbouring isle fully in, or fully out.
- **Check:** in each view, the top-third mean local contrast must exceed a floor (empty-band test),
  and no object's bounding box may cross the screen edge by less than 40 % of its width.

### 8. The lighthouse beam is a hard, stepped rectangle (high certainty)
- **Frames:** `path-season-*-i10`, around (1110 to 1206, 1000 to 1090)
  (`crops/winter-beam.png`).
- **What is wrong:** a flat pale box with a notch on its top edge. It is hard-edged light in
  daylight.
- **Smallest fix (code):** a feathered cone gradient, and zero opacity by day.
- **Check:** a gradient-magnitude test along the beam layer's alpha (no step > 20 levels).

### 9. The golden island is still lit like day (medium certainty)
- **Frame:** `path-d21-1800` (`crops/golden-island-half.png`).
- **What is wrong:** the lawn is L69 C47 h98. The bible's sunset meadow `#C9C27E` is L78 C36 h102,
  so the hue is fine but there is no warm, low key light: no long shadows and no rim on the
  edge facing the sun. The pink sky sits behind a day island.
- **Smallest fix (grade):** a stronger warm key and rim at golden hour on the plate, not only on the
  sky.
- **Check:** the lawn hue must move ≥ 6° toward gold, and key-side L must rise against shadow-side L
  compared with day.

### 10. The pond is too blue for the pastel set (medium certainty)
- **Frame:** `path-d21-0900` around (80 to 260, 1230 to 1300).
- **What is wrong:** the pond measures L63 C22 h261. The concept pond is L70 C7 h211, a soft teal
  grey. The app's pond reads as a hole in the palette.
- **Smallest fix:** protect it from the day saturation 1.32, or shift its local colour toward teal.
- **Check:** a per-material ΔE against `materials.json` water.

## Question 1, Palette, in short

- **Day:** one palette, except the sky (finding 3) and the pond (finding 10).
- **Golden:** the pinks are right in intent, but they render violet, sit on a day-lit island and
  carry cut-out shade shapes (findings 3, 4, 9).
- **Night:** grey and lifted, with characters and sprites not graded (finding 1).
- **Autumn:** works. The leaves sit on the lawn, and the ochre lawn (L67 C52 h90) holds together
  (`crops/autumn-island-half.png`).
- **Winter:** absent (finding 2).
- **Muddiest spots:**
  - the near night lawn, `path-near-pofu-night` around (300 to 900, 1550 to 1700);
  - the near bottom wash, `path-near-pofu` (0 to 1206, 1850 to 2622), which is olive.
- **Over-saturated:** the day sky, `path-d21-0900` (0 to 1206, 0 to 900).

## Question 3, Pofu and the characters, in short

Yes, they look washed out, though not grey: the hue is right and the strength is down. See the
table in finding 5. The residents (bunny, otter, hedgehog, whale) share Pofu's paleness and lack
contact shadows. Köke up close is the best-integrated character (`crops/koke-close.png`). At night,
every character keeps day light on a grey ground, which is the single worst character problem.

## Question 4, the pastel and Vice City test

- **Script:** `scripts/grade_mock.py`. It was applied to copies of `path-d21-0900`, `-1800` and
  `-2300`, never to app code. The outputs are in `q4/`; the sheet is `q4-comparison-sheet.png`.
- **The two grades:**
  - **Pastel:** Lab chroma × 0.82, L lifted 12 % toward white, slight warm shift.
  - **Vice City sky:** a violet `#7B5FD0` → pink `#FF7FB5` → peach `#FFB38F` gradient blended
    into the a*/b* channels above the island. Strength is 0.35 by day, 0.7 at golden and 0.45 at
    night.
- **Measured result:**
  - Global pastel costs Pofu everywhere:
    - Home day: p90 chroma 48 → 39, ΔL to ground 4.1 → 3.5;
    - golden: 51 → 42, 6.4 → 5.6;
    - night: 24 → 20, 5.2 → 4.6.
  - It moves the day sky the right way (C46 → C38), but only part of the way.
  - At night it thickens the fog that is already finding 1.
- **Verdict:**
  - **Harms, as a global grade.** The island and the characters are already a step paler than the
    concept. Making everything pastel is how this project gets "the same mud".
  - **Helps the day sky.** A paler, less violet zenith moves toward the concept's lilac-cream sky.
    This is the same change as finding 3.
  - **Belongs at golden hour, in the sky only, at about half strength.** The scripted golden
    zenith `#E2ADC7` (pink, h346) is already the founder's sunset pink; it is the renderer that
    turns it violet. The full Vice City gradient (sky C47) is hotter than the concept line and
    starts to read as synthwave. Pair it with finding 9 (warm light on the island), or the pink
    sky only shows how day-lit the island is.
  - **Nowhere at night.** Magenta replaces the navy that carries "safe, cozy".
  - **Not by day.** A pink-violet day sky reads as dusk and blurs the time of day.

## What is good

The day Home island, Köke's isle and the cloud sea are one painted world, close to the concept.
Keep them as the yardstick for every other light.

## Files

- Crops (26): `crops/`.
- Question 4 sheet: `q4-comparison-sheet.png`.
- Graded copies: `q4/`.
- Scripts: `scripts/grade_mock.py`, `measure.py`, `palette.py`, `sharp.py`. They read from the
  deleted `frames/` and `ref/`, so re-fetch the frames to rerun them.
