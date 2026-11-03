# Design loop 2: every island its own light

_Status: **proposal**, 2026-11-03. Creative director pass (Opus) of the
[design loop](README.md), building on [loop 1](loop-1.md). Inputs:
the takes of batch 17 (islands v2) and batch 18 (loop 1's concept round)
on `main`, the lead's review of both, the founder-input log since loop 1,
[`content/islands/profiles.yaml`](../../../content/islands/profiles.yaml).
Checked by [`tools/content/island_metrics.py`](../../../tools/content/island_metrics.py).
**Nothing here is dialogue:** beats are placeholders `[ID: speaker,
intent]`; the founder and friends write the words. Story changes reach
[lore-bible](../lore-bible.md) and [story-delivery](../story-delivery.md)
only through their own PR, after the founder agrees._

## 0. The answer

- **The problem moved from shape to light.** Batch 17 gave every island
  its own silhouette (whale, bell jar, crescent, travertine, pot, nest).
  But every take sits in one pastel daylight, one cream haze, one white
  cloud sea and one 3/4 hero view. The palette deltas of loop 1 are
  invisible because a palette delta graded under the same light reads as
  the same place.
- **Two causes are in our pipeline, not in the painter.** The prompt block
  `prop-style-v2` that every island job used asks for "the same light,
  high-key values and the same milky pastel colors", a warm key light
  from the upper left and "colors lifted toward cream". And batches 17 and
  18 attached the cloud-sea plate with "paint clouds like this". Both are
  right for home's props and wrong for a wonder island. Batch 19 uses a
  new block, `island-light-v1`, that keeps the finish and hands light,
  sky, shadow colour, haze and value range to the brief, and it attaches
  no cloud sea.
- **Each cluster gets an atmosphere, not only a palette.** Eight fields
  (hour, sky, key light, shadow colour, haze, the floor below, weather,
  value key) per cluster, in `profiles.yaml`, quoted by every concept
  prompt. The tool now checks them: any two clusters differ on at least 5
  of 8, and home's warm-brown shadow, cream haze and white cloud sea
  belong to home alone (section 3.1).
- **The water cluster becomes hard Aegean noon.** It was "home in
  pastel" (chalk cream on the same cloud sea). It is now a deep cerulean
  sky, a hard white sun overhead, turquoise shadows, a spray halo and no
  cloud sea in view, only a bright wall of spray with a rainbow in it. Its
  palette delta goes to the bound (hue −50°, saturation +0.2, value −0.1).
- **The story frame for all of it: every island keeps the hour it went
  quiet in; only home runs on the player's clock.** A visit moves you to
  another hour, which is why the sky changes (Revontuli's R1, now a
  rule). Below the waterline, home is on your clock because the Bekçi
  lives there (section 2).
- **Çağlayan's pools are windows that hold other hours.** At hard noon a
  cleared pool is a piece of aurora night or a dusk with a whale in it.
  The island's gimmick becomes the light system itself, and the rung-1
  moment (a far window going dark) is now literally a night inside noon.
- **Decisions on the takes:** Koke is the sleeping moss creature (read
  first as a mound; one breath at stage 3 sets up Gezgin); Mehtap keeps
  the crescent and loses the face; Leylek is the nest, back as a
  **seasonal visitor** outside the Book One order; Çömlek is the giant
  red-clay pot (Avanos, not İznik blue), lit from below by its kiln.
- **Concept round: batch 19**, 12 images, pilot of 3 (the nine-cell
  atmosphere board, Çağlayan at noon, Koke the sleeper), queued READY
  in [PR #131](https://github.com/ErenDenizK/pofu/pull/131).

## 1. The loop log

### 1.0 Step 0: ingest

- **Founder scores: none new this round.** The Hub's `islandScores` holds
  only the loop-1 chat scores (Revontuli 10, Gezgin 7), already in
  `profiles.yaml`. The founder has now been asked to score in the Hub;
  those scores feed loop 3. Nothing was invented: every island but
  Revontuli still shows "awaiting the founder's score of the current
  design" in the tool's report.
- **New input that justifies the loop:** the takes of batches 17 and 18
  and the lead's review of them. No new founder-input entries since loop
  1's (2026-11-03 night), so no founder-input entry is added.

### 1.1 Pass 1 (data): measuring light

The six island axes and the palette deltas passed in loop 1 and still
pass, yet the takes look alike. The axes are about the island (what it
is); nothing measured what the frame around it is. Pass 1 added the
`atmospheres` block and the `atmosphere` rule (fields, `min_diff: 5`,
`home_only: [shadow, haze, floor]`) with three tests, and wrote the nine
atmospheres from the formula of loop 1 §3.0, pushing every cluster away
from home's light first and from each other second.

Two honest findings of the pass:

- **The water delta was the one cluster still graded toward home**
  (value +0.12, saturation −0.15: lighter and paler, i.e. pastel). The
  fix is by design, not by number: the cluster's root is the Aegean noon
  at Pamukkale, where the light is hard and the shadows on white
  travertine go turquoise. The numbers followed (section 3.2).
- **Three dusks in a row:** Pervane, Emanet and Çömlek arrive back to back
  at dusk. Loop 1 chose that link on purpose (the chapter of lamps being
  lit). A `run_max.sky: 3` rule now caps it, and the three are made into
  three different dusks by their atmospheres: a clear violet dusk with one
  candle, a drizzle dusk with many lamps and no sun, a smoky dusk lit from
  below by a kiln. Whether three dusks still feel the same is the
  question the atmosphere board answers (section 6).

Metrics after pass 1: **no violations**; the closest two clusters
(craft and memory, water and ear) differ on 7 of 8 atmosphere fields.

### 1.2 Pass 2 (story)

The light decision needed a reason inside the world, or it is a style
choice the player feels as random. Section 2's hour rule gives it one and
makes home special without a new mechanic. Koke's new form needed a rung
(it now pays into Gezgin), and Leylek's return needed a place that does
not crowd the Book One schedule (a seasonal visitor). Metrics after the
pass (Martı's stork beat moved to a traded feather): **no violations**.

### 1.3 Pass 3 (islands and clusters)

Each island the lead's review named, weakest first (section 3.3), then
the formula check for every island in the concept round (section 3.4).
Final run: **no violations**; 26 tests pass.

## 2. The big story: what loop 2 adds

### 2.1 The hour rule

**Above the waterline:** every wonder island lives at its own hour and
weather, always: Çağlayan at noon, Revontuli at night, Mehtap at blue
hour. Going there by vapur is going to another time of day. Home is the
only island whose sky follows the real clock and real weather.

**Below the waterline (writers only):** an island goes quiet at the hour
a light below was switched off for it, and it keeps that hour, the way a
photograph keeps its light. Home runs on the player's own clock because
the Bekçi lives there: it is the one island that is not a memory. This is
never said. It is re-read at Mehtap: of all the sky, only home is on
_your_ time.

**Beats (intents only):**

| ID | Where | Beat | Intent | Subtext |
|---|---|---|---|---|
| `DUO-02b` | First vapur home from Çağlayan | `[DUO-02b: Pofu, puzzled, notices it was noon there and it is evening at home; Mochi answers as if it were obvious]` | Wonder, made ordinary | She knows why and does not say |
| `CAG-S0b` | Çağlayan arrival | `[CAG-S0b: Damla complains the island is "always noon"; she has never seen a sunset except in a pool]` | Comedy with a want | Her want to keep pictures is a want for other hours |

Budget: `DUO-02b` replaces nothing; it is the day-5 exchange (one a day,
loop 1 §2.5).

### 2.2 Changes to the reveal ladder

| Island | Was (loop 1) | Now |
|---|---|---|
| Çağlayan | The deepest pool shows a far window whose light goes out | Same rung, now **a pool of night inside noon**: a far night of small warm windows, and one goes dark. Re-read at Emanet: that night was the player's day one |
| Koke | A dormouse who apologises for sleeping; she rakes thank-you letters | The **island** is the sleeper (an old moss creature); Sumi rakes around it so as not to wake it; the letters thank whoever keeps it quiet. At S3 it breathes once: **the sky is alive**, which Gezgin pays off three days later at scale. Re-read at Mehtap |
| Martı Kayası | Storks rest on the rock; Lale remembers | A gull trades a **stork's feather** with the story; Lale tells it herself only when Leylek passes in season |
| Leylek (new, seasonal) | Cut (curation §3.11) | The nest the old Bekçi rode south in. Seasonal late secret, never required for the reveal |
| Home | Seeds; the sunflower turns to the fog | Plus: the only sky on the real clock (the hour rule) |

### 2.3 Story decisions that need the founder (for the lore PR)

The loop-1 decisions he accepted (the Bekçi mystery, the Pofu and Mochi
duo, Çağlayan "the falls that remember") and the hour rule above go into
[lore-bible](../lore-bible.md) and [story-delivery](../story-delivery.md)
in a separate PR, left open until the founder agrees (section 7).

## 3. Islands and clusters

### 3.1 The atmospheres

What a visit repaints, edge to edge (data: `profiles.yaml` →
`atmospheres`). Satellites inherit their cluster's atmosphere; their own
weather is in 3.3.

| Cluster | Hour | Sky | Key light | Shadow | Haze | Floor (below the island) | Weather | Value key |
|---|---|---|---|---|---|---|---|---|
| Home | real time | pastel blue | warm, soft, upper left | warm brown | cream | white cloud sea | fair | high, soft |
| **Water** | noon | deep cerulean | hard white, overhead | **turquoise** | spray halo | a wall of spray with a rainbow; no cloud sea in view | spray | high contrast |
| Journey | dusk | periwinkle fog strait | orange sun slit, from behind | periwinkle | fog banks | dark cloud swell | passing shower, moonbow | mid |
| Cold | night | aurora | cool moon plus one warm window | deep blue | diamond dust | dark floes | snow | low |
| Glass | winter afternoon | frost, pale gold | low gold, refracted (caustics) | violet | frost breath | rime crust | frost sparkle | high, soft |
| Craft | dusk | smoke amber | **kiln underlight** | plum | ochre smoke | red-dust cloud | sparks | mid, warm |
| Moon | blue hour | indigo stars with gaps | silver from above | ink blue | crystal clear | mirror-flat cloud | still | low, silver |
| Ear | morning after rain | washed blue, racing clouds | hard sun, moving shadows | cool grey-blue | none | cloud sea torn by wind | wind | high contrast |
| Memory | dusk | drizzle grey | many small lamps, no sun | sepia grey | rain mist | rain-dark cloud | drizzle | low, mid |

**The light test** (added to the review rubric of every wonder take):
cover the island with your thumb. Can you still name the place by its
light? If not, the take fails, however good the island is.

**Engineering consequence** (later; nothing built now): loop 1's island
sky cells become **atmosphere cells**: a sky gradient, a key-light
direction and colour, a shadow tint, a haze colour and density, a floor
material for the cloud sea and a weather particle system per cluster,
applied by `WorldGrade` when the camera is on that island. In the
backdrop, each far island carries a soft **pocket** of its atmosphere
into home's sky (a spray halo, a flurry, a fog bank, kiln smoke) instead
of all sharing one haze; `cl2-backdrop-pockets` tests the look.

### 3.2 The water cluster, bolder

| | Loop 1 | Loop 2 |
|---|---|---|
| Delta | hue −30°, sat −0.15, value +0.12 | **hue −50°, sat +0.2, value −0.1** (at the hue bound) |
| Accent | mineral turquoise | deep mineral turquoise |
| Light | late-morning mist (shared haze) | hard white noon, turquoise shadows |
| Floor | the shared cloud sea | a bright wall of spray; the cloud sea is not visible |
| Home anchors kept | cream, sunflower | cream (as chalk white), sunflower (Damla's tea glass, the sun on wet rims) |

Why it stays kin to home: home's cream survives as chalk, the sunflower
gold as glints, and the R2 "one warm light" is Damla's tea glass. Why it
reads as its own place at thumbnail: it is the only cluster at noon, the
only one with coloured shadows of a cool hue in daylight, and the only
one with no cloud sea in view.

### 3.3 The islands the review named (weakest first)

**Koke (satellite, water; scored 6 on the old design).** _Mercilessly:_
the bonsai on a boulder was a Japanese garden on a rock, the home
template in miniature. Koke-b's sleeping moss creature is the better
idea, but a creature island three days before Gezgin's god-tier "the
island is alive" would steal the hook. _Design:_ Koke reads as **a mossy
mound** with a bonsai, raked gravel and one paper lantern; only on a
second look does a crease become a closed eye. It never wakes in Book
One. At S3 it **breathes once**, when Çağlayan pours and its drizzle
grows. That breath is a whisper of the hook, not the hook: small, still
and hidden, where Gezgin is huge, moving and announced. _Weather:_ a
constant drizzle from Çağlayan's spray, teal shadows. _Landform:_
`sleeping-mound` (differs from Gezgin's `creature`: the tool's pair
check passes on five axes; the design argument is above). _Never:_ a
mascot face, torii, sakura, Fuji.

**Çömlek (big, craft; scored 4 as a postcard).** _Design:_ the giant pot
of x2-comlek-b, in unglazed red Avanos clay (İznik blue is another city's
craft and the obvious souvenir), lying on its side, its mouth a workshop.
Cold on the horizon from day one; when it arrives, its kiln is the scene's
key light, **from below**: the only island lit that way. Balloons stay a
bloom-only beat. _Landform:_ `giant-pot` (was `cones`).

**Mehtap (big, moon; scored 3 as Yıldız).** The crescent stays (unique
at 60 pt), **the face goes**: a face makes the moon a character and the
moon a sticker; Nane the owl is the character, Mehtap is a place. The
starfield has **gaps** (the dark stars of the chart) and the cloud sea is
a mirror (the moon cluster's floor), which also sets up Yakamoz.

**Leylek (cut in curation; nest take kept).** x2-leylek-a's nest carried
by ribbons is a unique silhouette; the tower (b) is weak. Curation cut it
because Gezgin owns "flying animals carry an island". Loop 2 keeps the
cut **for Book One's order** and brings the nest back as a **seasonal
visitor**: it passes over during the real stork migration windows, stays
a few days, and leaves; it carries Lale and the late secret of how the old
Bekçi went south. Its atmosphere: backlit, hot windy dusk with amber dust
(the only contre-jour island). It is not in `order`, so the schedule is
unchanged; loop 3 profiles its season rule.

**Çağlayan (big, water; not scored by the founder).** _Build on the best
idea of the round:_ the pools are windows, and in loop 2 **they hold
other hours**. Damla's island is stuck at noon (the hour rule); a cleared
pool shows another island in its own light. The island's wow is
contrast inside one frame (R2 at its strongest): the brightest noon in
the sky with small deep pieces of night and dusk set into it. At home,
the çeşme's basin becomes the only place where the player can see
another hour without travelling. The arrival keeps the milky pools (no
windows yet: the island is only noon). The bloom: every pool clear at
once, every hour of the sky in one island.

**Gezgin (big, journey; scored 7 on the old design).** Batch 18's night
crossing fixed the composition (portholes, barnacle village, spout) but
was still painted in pastel lilac under `prop-style-v2`. It is re-run
under the journey atmosphere (an orange sun slit behind a fog bank, cool
periwinkle front, a dark cloud swell): `cl2-gezgin-dusk`.

**Emanet (parallel).** Keep the umbrella; borrow only three suitcases
from x2-emanet-b as its base (the pile was cluttered). Fewer, larger
objects; lamps are the only light.

### 3.4 The formula check for the concept round

At least five of loop 1's seven points (R1 own sky, R2 one temperature
plus one warm light, R3 moving light, R4 a material in two states, R5 a
simple silhouette, R6 a real place's mood, R7 small warmth in a vast
space) per island in batch 19:

| Job | R1 | R2 | R3 | R4 | R5 | R6 | R7 | Points |
|---|---|---|---|---|---|---|---|---|
| Çağlayan at noon | noon | turquoise + tea glass | glitter, pool light | travertine, falling water | column | Pamukkale | otter on a column | 7 |
| Çağlayan deepest pool | noon | night pool in noon | ripple | water | — (a close-up) | — | duo at a rim | 5 |
| Koke the sleeper | drizzle | teal + lantern | rain rings | wet moss, gravel | mound | Japanese garden | dormouse on a sleeper | 7 |
| Mehtap | blue hour | silver + gold window | stars | moonstone, mirror cloud | crescent | mehtap sefası | owl on a crescent | 7 |
| Leylek | backlit dusk | gold rim + one window | storks, ribbons | twig, ribbon | nest | the flyway | nest in a big sky | 7 |
| Gezgin | dusk strait | periwinkle + portholes | freckles, moonbow | living cloud | whale | the evening vapur | duo on a whale | 7 |
| Çanlar | after rain | washed + bronze | racing shadows | bronze, wet stone | spire | bell villages | a mouse atop a spire | 7 |
| Çömlek | dusk | plum + kiln | sparks, smoke | clay, fire | pot | Avanos | mole at a wheel | 7 |
| Emanet | drizzle dusk | sepia + lamps | rain, lamps | oilcloth, paper | umbrella | a han's lost-and-found | magpie under one umbrella | 7 |
| Fanus | frost afternoon | frost + meadow gold | caustics | glass, frost | bell jar | Nordic glass, midsummer | frog in a jar | 7 |

The board and the backdrop test the system, not one island, and are
judged by the light test only.

### 3.5 Every big and parallel island (stopping criteria)

Unforgettable thing, rung, gift to home and satellite stand as in loop 1
§3.2–3.4 for every big and parallel island; loop 2 changed the
unforgettable thing of Çağlayan (windows hold hours), Koke (the sleeper)
and Çömlek (lit from below) in `profiles.yaml`, and none lost its rung,
gift or satellite.

## 4. The light standard (for every future island brief)

1. A wonder island's brief states its cluster's eight atmosphere fields
   and uses `island-light-v1`, never `prop-style-v2`.
2. Never attach the cloud-sea plate to a wonder island; the floor is the
   cluster's.
3. Shape references from earlier takes are attached as **SHAPE ONLY**.
4. Every review adds the light test (3.1) to the 60 pt silhouette test.
5. Washed-out takes are fixed by grading (`WorldGrade`, harmony), not by
   regenerating, as the lead ruled; a take whose light is wrong in kind
   (a pastel noon where the brief says night) is the only reason to
   regenerate.

## 5. Concept round 2 (batch 19, exploration, 12 images)

The manifest is [`tools/imagegen/manifest/batch-19-loop-2-concepts.yaml`](../../../tools/imagegen/manifest/batch-19-loop-2-concepts.yaml)
(full prompts); this is its spec.

```yaml
batch: batch-19-loop-2-concepts
title: Design loop 2 concept round (12 images; exploration, never promoted)
status: READY (queue row 18)
spec: docs/product/design-loop/loop-2.md
pilot: [cl2-atmosphere-board, cl2-caglayan-noon, cl2-koke-sleeper]   # continue only if 2 of 3 pass
defaults:
  variants: 2
  canvas: 1536x1024
  chat: "Pofu · Exploration"
  style_block: island-light-v1        # not prop-style-v2
  attach_style: approved:island-main-s (STYLE ONLY: finish and shapes, never its light)
  cloud_sea: not attached             # the floor is the cluster's
  review: [60 pt black silhouette, the light test (loop-2 §3.1), archipelago 1A.3 rubric]
jobs:
  - id: cl2-atmosphere-board
    tests: nine cluster atmospheres read as nine places at thumbnail (3x3 board, far-view islands, no characters)
  - id: cl2-caglayan-noon
    tests: the bolder water delta; pools holding other islands' hours (night and dusk inside noon)
  - id: cl2-koke-sleeper
    tests: Koke as a mound that is asleep on second look; drizzle, teal shadows, one lantern
  - id: cl2-caglayan-deep-pool
    tests: rung 1 as an image (a far night window going dark; Pofu's ears flat, Mochi watching him)
  - id: cl2-mehtap-crescent
    tests: the crescent with no face; indigo starfield with gaps; mirror-flat cloud sea
  - id: cl2-leylek-nest
    tests: the nest carried by storks; backlit hot windy dusk (the only contre-jour island)
  - id: cl2-gezgin-dusk
    tests: the night crossing in the journey cluster's real light (beyond batch 18's pastel lilac)
  - id: cl2-canlar-washed
    tests: the ear cluster's windy morning after rain; torn cloud sea; no church iconography
  - id: cl2-comlek-kiln
    tests: the giant red-clay pot lit from below by its kiln; no İznik blue, no balloons
  - id: cl2-emanet-drizzle
    tests: a calmer umbrella silhouette; lamps the only light
  - id: cl2-fanus-frost
    tests: two skies in one frame (frost afternoon outside, midsummer inside), caustics
  - id: cl2-backdrop-pockets
    tests: home's sky with each far island carrying a pocket of its own atmosphere
```

## 6. Self-critique

- **The tool checks labels, not pixels.** Eight distinct strings per
  cluster prove that the design _asks_ for different light, not that the
  paintings deliver it. The atmosphere board is the real test; if two
  cells read alike, the atmospheres change, not the labels.
- **Three dusk clusters remain** (journey, craft, memory) plus two dusk
  satellites (Martı, Pervane). They differ in key light, weather and
  floor, but dusk is still over-used. If the board shows it, the first
  candidate to move is craft to **dawn** (a night firing is opened at
  dawn; Cappadocia's balloons rise at dawn; Mochi sits down when the
  night watch ends), which needs a new link between Emanet and Çömlek.
- **Strong atmospheres fight the cozy brief.** Hard noon, night and
  smoke can tip into harsh or gloomy, and the founder already warned
  about night grades. The block keeps "wonder, not danger" and one small
  warm light in every frame; the review must still reject anything
  cold-hearted.
- **The hour rule costs engineering.** Per-island atmosphere cells,
  particles and backdrop pockets are real work for `PofuWorld`; it is the
  right cost (it is what makes Revontuli a 10), but it is not small, and
  Book One's first island needs it on day 4.
- **Koke's breath must stay small.** If the painting makes the sleeper
  cute or obvious, Gezgin's hook loses its surprise; the review should
  pick the take where you have to look twice.
- **Leylek as a seasonal visitor** adds a rule the schedule does not yet
  model; until loop 3 profiles it, it is a promise, not a design.

## 7. Questions for the founder (with recommendations)

| # | Question | Options | Recommendation |
|---|---|---|---|
| 1 | Every island in its own hour, home alone on the real clock | A yes, always · B islands follow the real clock too, with a tint · C a mix: bigs keep their hour, satellites follow home | **A**: it is what made Revontuli a 10, and it gives home a quiet meaning |
| 2 | Çömlek's look | A the giant red-clay pot (Avanos) · B the fairy-chimney kiln (x2-comlek-a) · C the blue-patterned pot of x2-comlek-b as painted | **A** |
| 3 | Leylek | A a seasonal visitor in the real migration windows · B a Book Two island · C stays cut (storks as a home event only) | **A** |
| 4 | The lore PR (loop-1 decisions and the hour rule into lore-bible and story-delivery) | A merge as written · B change something first | Review it; it stays open until he agrees |
| 5 | Scores | Score batch 19's takes in the Hub, 1–10 with one line, per island | They are step 0 of loop 3 |
