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
  right for home's props and wrong for a wonder island. The next island
  brief must use a block that keeps the finish and hands light, sky,
  shadow colour, haze and value range to the brief, and attach no cloud
  sea (the light standard, section 4).
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
- **Every island is designed around what the player does there** (the
  founder's note, mid-loop): the painted concepts are identity, backdrop
  and marketing art; the playable island is a diorama plate with
  stations, like home. Each big and parallel island now has a playable
  island block (game, twist, a round, toy, stations, what it feeds, its
  far view), checked by the tool (section 3.6).
- **The three zooms, verbal (the founder's second note, section 8):**
  each island's strongest and weakest point with its fix; the sequence
  (strongest days 4–22, weakest Mehtap's wait, fixed by a moon-anchored
  arrival; a missed stack caught, Emanet's bloom moved to day 49); the
  real background lore (the Ring, the drift, the Bekçi as a job, the
  handover) and the plot as a sixteen-beat ladder, turning at Olta from
  _who is the Bekçi_ to _will Pofu leave_. A deck outline ends the doc.
- **No new images this loop** (the founder's note). The batch-19 concept
  round was written and then withdrawn unmerged (PR #131 closed); its
  spec is kept, deferred (section 5).

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
Metrics: **no violations**.

### 1.4 Pass 4 (the founder's note: play first, no images)

The founder asked that every island be designed around what the player
does there, that no new images be made unless blocking, and that the
loop finish on a tight budget. Pass 4 wrote a playable island block per
big and parallel island (`profiles.yaml` → `play`, section 3.6), added
the `play` check (every big and parallel island has a game, a twist, a
round of at most 120 s, a toy, at least three stations, what it feeds and
a far view) with two tests, withdrew batch 19 and deferred section 5.
Final run: **no violations**; 28 tests pass.

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
judged by the light test only. (The round is deferred; section 5.)

### 3.5 Every big and parallel island (stopping criteria)

Unforgettable thing, rung, gift to home and satellite stand as in loop 1
§3.2–3.4 for every big and parallel island; loop 2 changed the
unforgettable thing of Çağlayan (windows hold hours), Koke (the sleeper)
and Çömlek (lit from below) in `profiles.yaml`, and none lost its rung,
gift or satellite.

### 3.6 The playable islands

The painted concept is the island's identity (far view, rumour
silhouette, store art). **The playable island is a diorama plate with
stations, like home:** the game's station, the toy, the stage beats'
places and decor spots, all on one plate whose outline is the
concept's silhouette, simplified. Data: `profiles.yaml` → `play` (game,
genre reference, twist, round length, toy, stations, what it feeds, far
view). Here: one round in 30 seconds, and why it is fun on day 1 and on
day 20. A session is one to three rounds (60 to 90 s each), then the
island says "enough for today" ("bugünlük yeter" stays the rule).

| Island | One round, in 30 seconds | Fun on day 1 | Fun on day 20 |
|---|---|---|---|
| **Çağlayan** (Flow) | A 4×4 board of channel stones; rotate stones so water runs from the spring to the pool; the last stone clicks, boats race through and splash, and the pool on the plate clears to a window | Instant, tactile, the splash pays | Boards grow (locks at S3, the mill race at S4); what the cleared pool shows changes daily (the awake island, a rumour's silhouette), so a win always shows something new |
| **Gezgin** (sliding blocks) | Slide parcel tiles to open a lane from the post office to a barnacle house; tiles move only on the whale's out-breath, so you plan in the in-breath; the letter drops through a lit window | The breathing rhythm is novel and calming | The letters carry the Bekçi thread (rung 3); harder boards, and slow breathing lengthens the move window, the game rewarding calm without a meter |
| **Çanlar** (call and response) | A bell shivers through a motif of 3 to 6 notes; tap the bells back in order; each right bell swings and the bunting snaps | Readable muted (the shiver is the cue) | The motif is the awake island's, so it changes daily; at S3 the oldest tune begins with Pofu's four notes (rung 4) |
| **Revontuli** (Peggle, guarded) | Aim a lantern bubble under the ice; it bounces off frozen pegs and lights them; the lit pegs rise and become tonight's aurora strand | The bounce physics is a toy in itself | Tonight's sky is made of your rounds; after calm nights it is brighter (rung 5); no fanfare loops, no near-miss teasing (loop 1 guards) |
| **Fanus** (nonograms) | Frost clues on a pane; tap cells clear; the solved pane is a butterfly wing; the butterfly lifts off into the jar's meadow | A quiet first board, 5×5 | Wings fill a collection inside the jar; the dated sunflower row grows (rung 7) |
| **Emanet** (logic grid, daily) | Three kept things, three islands, three clues as objects and postmarks; drag each thing to its island; the magpie polishes and posts it | One puzzle, one minute, a satisfying click | A daily ritual (it is the parallel island's job); every return lands a small beat on the island it went to; the night-light at S3 (rung 8) |
| **Çömlek** (merge-drop) | Drop clay pieces into the pot-shaped well; equal pieces merge into bigger vessels; the fixed lump never merges; a round ends when the well fills; the best vessel goes on the drying shelf | Juicy merges, a funny cracked pot | Goods from four islands become glazes; Kil fires a glass for every island; Mochi's seat (her arc closes) |
| **Mehtap** (one-line logic) | Join the stars of a chart in one line without crossing; the line passes through dark stars, which light faintly when traced | Calm and short | The board shape follows the real moon phase, so the island changes nightly; the joined charts become the Bekçi's trail (the reveal) |

Satellites keep their loop-1 rituals (Koke's raked loop, Olta's wait,
Pervane's lantern, Arı's hive, Yakamoz's wade, Martı's toss); they are
untiered and not checked by `play`.

**Not done (listed honestly):** plate layouts as station coordinates
(the station-guide template per island), the round tuning numbers for
`PofuCore`, and each game's Rehearsal pilot. These come one island at a
time, Çağlayan first, as code-only work before any art.

## 4. The light standard (for every future island brief)

1. A wonder island's brief states its cluster's eight atmosphere fields
   and uses a light block (`island-light-v1`, drafted in closed PR #131,
   lands with the next island brief), never `prop-style-v2`.
2. Never attach the cloud-sea plate to a wonder island; the floor is the
   cluster's.
3. Shape references from earlier takes are attached as **SHAPE ONLY**.
4. Every review adds the light test (3.1) to the 60 pt silhouette test.
5. Washed-out takes are fixed by grading (`WorldGrade`, harmony), not by
   regenerating, as the lead ruled; a take whose light is wrong in kind
   (a pastel noon where the brief says night) is the only reason to
   regenerate.

## 5. Concept round 2: deferred

**Deferred by the founder's note (no new images this loop).** The spec
below was written and its manifest opened as PR #131, then closed
unmerged. It runs only when a playable island needs it; the first job to
revive is the atmosphere board, since it tests the whole light system in
one image. When revived, it also needs the `island-light-v1` block and
asset nodes for its jobs (`tools/content/sync_assets.py`; PR #131's CI
failed on that).

```yaml
batch: batch-19-loop-2-concepts
title: Design loop 2 concept round (12 images; exploration, never promoted)
status: deferred (PR #131 closed unmerged)
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
| 5 | Scores | Score the islands in the Hub (batch 17 and 18 takes), 1–10 with one line, per island | They are step 0 of loop 3 |
| 6 | Which island's playable plate first | A Çağlayan (day 4, the first wonder) · B Gezgin (the hook) · C Revontuli (the 10) | **A**: it is the first the player meets, and its pools-as-windows need the atmosphere cells anyway |

## 8. The founder's second note: three zooms, verbal and logical

The founder reshaped this loop's deliverable after section 7: no image
work; each island on its own, then the sequence, then the story, at the
bar of the best studio in the world. Pass 5 below. It changed one rule
and one island in data (8.2); everything else is decisions.

### 8.1 Close zoom: each island on its own

One strongest point, one weakest point, the fix. The playable-island
blocks of big and parallel islands are section 3.6 and `profiles.yaml` →
`play`; satellites get their play line here.

| Island | Strongest | Weakest | The fix (decided) |
|---|---|---|---|
| **Ayçiçeği** | It grows from a hamster's island into the harbor town where every island leaves a building | After day 3 it only _receives_: gifts arrive, its own play never deepens | Every cluster gift adds **one rule to home's garden game** (the çeşme waters a row; the greenhouse adds rare seeds; the oven turns a harvest into a feast dish; the bell post calls a visitor). Home's game is the only one that grows all book |
| **Çağlayan** | Pools are windows that hold other islands' hours | Flow is the most familiar puzzle in the set, and a solved board stays solved | Boards are **generated from the day's awake islands** (the channel must reach the pool that shows that island), and the last stone is placed by **dropping a leaf boat**: the toy becomes the finishing move |
| **Koke** (sat.) | The sleeper's single breath, a whisper of Gezgin's hook | The raked loop (Slitherlink-lite) is unproven and hard to teach in a minute | Play: rake one closed line round the stones, starting 3×3 with one rule shown. Rehearsal pilot before anything else; the fallback is "one line through every pebble", never a new genre |
| **Gezgin** | An island that is alive and breathes | Sliding blocks are generic, and breath-timed moves can frustrate | The tiles are **barnacles that drift on her breath**: you plan, she moves them. Breath sets the window but never fails a move; slow breathing (the player's calm) widens it |
| **Martı** (sat.) | A pure toy: toss simit, a gull trades back | Random trinkets read as a loot box | Play: toss and trade, **deterministic**: what you toss decides what returns, shown on the gulls' trade post; no rarity, no odds |
| **Çanlar** | The archipelago's ear: each morning's rumour | Simon is the shallowest game in the set | From S3 the player **composes a four-note call**; it summons a resident to home's square tomorrow, a real effect in the web. The ear becomes a voice |
| **Revontuli** | It replaces the sky (the 10) | Peggle's DNA is a casino's | One lantern per round, made by you; no multipliers, no fever, no score: the result is **tonight's aurora**, seen over home after calm nights. Physics as a gift, not a payout |
| **Olta** (sat.) | The only island whose game is waiting | Waiting is not felt as play | Play: set the line, **close the app**; the catch is waiting on the next open. The game is literally the product's behaviour, rewarded, never punished |
| **Fanus** | Two skies in one frame | Nonograms are slow for a casual player | 5×5 opening, 10×10 cap, clues as frost dots, the wing's picture previewed faintly so it reads as drawing, not arithmetic |
| **Pervane** (sat.) | A light kept for someone | Almost nothing to do | Play: a **dusk ritual**, a long press lights the lantern; the moths settle into a shape that points to the next rumour. Short on purpose |
| **Emanet** | The web's glue: one thing returned a day | Clutter, too many objects | Three objects a day, never more; the shelves fill over the book as the visible progress; its bloom moves into Mehtap's wait (8.2) |
| **Çömlek** | On the horizon since day one; the kiln lit from below | Suika is a clone | The fixed lump, glazes from four islands, and **the best vessel leaves**: it becomes a decor piece on the island whose glaze it wore |
| **Arı** (sat.) | The bees' dance points toward the viewer | It overlaps with home's garden | Play: **route bee flights over home's plate** to flowers; the only island whose game is played above home, so its rung (the dance) happens where you live |
| **Mehtap** | The real moon reshapes it | Waiting for a real full moon can feel like a timer | The board's shape follows the moon nightly (a new puzzle every night), the wait is filled by late secrets and Emanet's bloom, and its **arrival is moon-anchored** (8.2) |
| **Yakamoz** (sat.) | Wading in light | It comes after the climax | It is not an epilogue but **Book Two's door**: its one extra light is the next question. Play: wade; each step lights a shoreline that traces an island not yet arrived |

### 8.2 Group zoom: order, durations, overlaps

Days are the tool's derived schedule (section 4.2 of loop 1, re-run).

| Days | What arrives (runway) | Overlaps (rich at once) | Wows |
|---|---|---|---|
| 1–3 | Home (3) | — | — |
| 4–12 | Çağlayan d4 (2), Koke d6 (2), Gezgin d9 (4) | Çağlayan's stages run under both | d4, d9 (the hook), Koke's bloom d13 is quiet |
| 13–24 | Çanlar d13 (2; daily from d19), Martı d15 (2), Revontuli d17 (3; rumour d14), Olta d20 (3) | Gezgin's stages; Çanlar's daily starts | d14 Çağlayan bloom, d17, d22 Gezgin bloom |
| 25–40 | Fanus d25 (3), Pervane d28 (2), Emanet d30 (2; daily from d31), Çömlek d33 (3), Arı d36 (3) | Two dailies (rumour, puzzle) under everything | d25, d30 Revontuli bloom, d33, d38 Fanus bloom |
| 41–57 | Mehtap d41 (2), Yakamoz d43 (2) | Late secrets on old islands; **Emanet's bloom d49** | d41, d46 Çömlek bloom, **d49 Emanet bloom**, d57 Mehtap's full moon |

- **Strongest stretch: days 4–22.** An arrival every 2–4 days, the hook
  on day 9 inside the free-to-Plus window, Revontuli's rumour by day 14,
  and three different textures (juicy, brainy, rhythmic) in a row.
- **Weakest stretch: days 41–57, Mehtap's wait,** worse in reality than
  on paper: the full moon is real, so a player whose day 41 falls just
  after one would wait up to four weeks. **Fix (decided): Mehtap's
  arrival is moon-anchored.** It arrives when its stage 4 can land 3–7
  days before a real full moon; the slack before it (0–25 days) is
  absorbed by the elastic tail of chapter 4: Arı and the late secrets on
  old islands stretch, Book One never waits empty. The tool models the
  nominal case only; the elastic tail is a `PofuCore` rule (not done).
- **A stack the tool missed, now caught:** Emanet (a god-tier parallel)
  bloomed on day 44, two days before Çömlek's bloom, because parallel
  blooms were not counted as wows. The rule now counts a god-tier
  parallel's bloom (its arrival stays quiet: it arrives as
  infrastructure), and Emanet's bloom moved from +14 to **+19 (day 49)**,
  where it does the most good: the map in the back room, in the old
  Bekçi's hand, lands in the middle of Mehtap's wait. Test added.
- **The sag in chapter 3** (days 25–33): three dusks in a row and two
  brainy games in four arrivals. Accepted for now (3.3, 6); the Fanus →
  Emanet stretch must not both be logic at full size: Fanus's opening
  boards stay 5×5.

### 8.3 Whole zoom: the real background lore

What actually happened before the game starts (writers only; never put
in the game as exposition):

1. **The Ring.** The islands were once one archipelago, a ring in the
   sky above the loud world, held together by quiet. At dusk the
   bell-ringers of Çanlar rang the oldest tune and every island answered.
2. **The drift.** Below, the lights stopped going out: windows bright
   all night, rooms that never got dark. Every light left on is a little
   noise, and noise pushes islands apart (§1 of the lore bible). One by
   one they drifted off into the fog, and each went still at the hour the
   last light near it was switched off, and kept that hour: Çağlayan at
   noon, Revontuli at night, Mehtap at blue hour. Çanlar's tune lost its
   answers; the ringers grew old and forgot.
3. **The Bekçi.** It was never a person by birth; it is a job. Whoever
   switches off a light for someone's quiet is, that night, a Bekçi. For
   a long time one small Bekçi kept Ayçiçeği: he hummed four notes, wrote
   practical letters, drank his tea at Mochi's stall and walked the
   quiet. Every light he switched off below let one island hold on. He
   kept the Ring from coming apart entirely, alone, for years.
4. **The handover.** He grew tired. One autumn night, far below, a light
   went off that he had not switched off: someone else had done it, for
   themselves. A new Bekçi had woken. So he did what old night watchmen
   do when the next one arrives: he went to rest. Lale's nest carried him
   south. He left his glass upside down on Mochi's top shelf, which in
   her stall means _keep it for me_, and she has kept it ever since,
   believing he left; he did not leave, he handed over.
5. **The night the game starts.** The light that went off that night was
   in the player's room; it was the light Pofu ran beside. Pofu stopped,
   heard breath and a squeak (the four notes), and Ayçiçeği, the island
   nearest to the quiet, took him in. **The player is the new Bekçi and
   does not know it; nor does Pofu; Mochi suspects there is one.**
6. **What everyone is really doing.** The player switches off lights
   (every resist), and islands come home. Pofu thinks he is following
   the old Bekçi's trail to say thank you; the letters, the aurora and
   the dark stars all point to wherever the quiet is, i.e. to the
   player. Mochi travels to keep Pofu from leaving the way the old one
   did, and learns that people who go to rest are not people who leave.
7. **The open question for Book Two.** Beyond the Ring, one window is
   still lit: someone else's bright room. Book Two sails there, gently,
   to switch it off for them (the door to friends).

### 8.4 The plot as a ladder

Each beat is tied to an arrival (days nominal). _Learns_ is what the
player can piece together; _feels_ is the target emotion.

| Day | Arrival | Beat (intent) | The player learns | Feels |
|---|---|---|---|---|
| 1–3 | Home | Four notes hummed and cut off; a dusted wheel; an upside-down glass on Mochi's shelf; the sunflower turns to the fog at night | This place has a past | Cozy curiosity |
| 4 | Çağlayan | Pools become windows onto other hours | Islands are far apart and remember | Wonder |
| 6 | Koke | Thank-you letters raked "to whoever makes it quiet"; the mound breathes once (S3) | Someone makes it quiet, and is thanked | A small warmth |
| 9 | Gezgin | Every lost letter is addressed to "Bekçi", and the address moves | There is a Bekçi, and he moves | **The hook**: a question |
| 13 | Çanlar | The oldest tune begins with Pofu's four notes (S3) | Pofu is a listener, like the ones before | Pride (Pofu's cocky phase) |
| 14 | Çağlayan bloom | In the deepest pool a far night window goes dark | Lights going out matter | A shiver |
| 15 | Martı | A stork's feather and a story: a small one was carried south | The old Bekçi went south | Mochi's glass ripples; the player notices before Pofu does |
| 17 | Revontuli | The aurora is made of lights switched off below; brighter after the player's calm nights | The quiet is made somewhere, by someone, nightly | Awe, then a quiet "is that me?" |
| 20 | Olta | The line brings up the old Bekçi's lantern; Mochi admits she knew him | **Midpoint**: the question turns from _who_ to _will Pofu leave too_ | Tenderness, worry |
| 25 | Fanus | Sunflowers tagged with dates; the dates are the player's quiet days | The record is the player's | A recognition the player keeps to themself |
| 28 | Pervane | Mochi lights a lantern for Pofu; he goes one trip alone | A light kept for someone is not a light left on | Letting go |
| 30 | Emanet | Pofu's own night-light on the shelf, tagged with the player's day one in a **new** hand (S3, d39) | There is a new Bekçi, and close | The suspicion becomes near-certain |
| 33 | Çömlek | Mochi turns the old glass upright, pours and sits down | She has stopped waiting | Release (her arc closes) |
| 36 | Arı | The bees' dance and the sunflower point toward the viewer | It points at you | The player knows; Pofu does not yet |
| 41–57 | Mehtap | The chart of dark stars is the trail; it ends at Ayçiçeği, tonight. Mochi sets a full glass at the edge of the screen; Pofu looks at the camera, once | **The Bekçi is the player** | Being thanked, not praised |
| 43+ | Yakamoz | The reflection shows one light the sky does not | A window is still lit | Book Two's pull |

### 8.5 Critique of the story

- **Strongest point: the twist is literally true.** Every clue is built
  from the player's own data (day one, quiet days, calm nights), so the
  reveal is not a trick played on the player but a fact about them they
  can verify. No other habit app can say "you did this" and mean it.
- **Weakest point: the middle repeated one question.** Loop 1's rungs 5
  to 8 each added evidence to _who is the Bekçi_; evidence is not drama.
  **Fix (in 8.4):** at Olta the question turns from _who_ to _will Pofu
  leave like the last one did_. Chapter 3 then carries an emotional stake
  (Mochi's fear, Pervane's solo trip, Çömlek's release) while the
  evidence keeps arriving in the background, and the player is one step
  ahead of Pofu from Arı on, which turns the finale from a surprise into
  a recognition.
- **Risk to watch:** "you are the hero" tips into flattery if said more
  than once. One look, one glass, one human line, then good night.

### 8.6 Not done (budget)

Plate layouts as station coordinates; the elastic chapter-4 tail and the
moon-anchored arrival in `PofuCore`; the home garden's per-gift rules;
Rehearsal pilots for the raked loop, the breath slider and the lantern
Peggle; the lore bible's sections for 8.3 (the lore PR, #135, carries
loop 1 and the hour rule; 8.3 joins it once the founder agrees).

## 9. Deck outline (for the lead; one idea per slide)

1. **The problem we found:** every island has its own shape now, but all
   share one light. Two takes side by side.
2. **Why:** our own prompt asked for "the same light"; fixed by a rule:
   each cluster has its own hour, sky, light, shadow, haze and floor.
3. **The hour rule:** every island keeps the hour it went quiet in; only
   home runs on your clock.
4. **Play first:** the painted island is the poster; the playable island
   is a plate with stations. One slide per big island: game, one round,
   day 1 vs day 20 (eight slides, from 3.6 and 8.1).
5. **The weakest points, fixed:** Flow → boards from the awake islands;
   Peggle → no score, the aurora is the payout; Suika → your pot leaves.
6. **Home grows a rule per island:** the only game that deepens all book.
7. **The sequence:** the curve from day 1 to 57, strongest stretch (4–22)
   and weakest (Mehtap's wait), with the moon-anchored arrival.
8. **The world before the game:** the Ring, the drift, the Bekçi as a
   job, the handover.
9. **What everyone is really doing:** the player switches off lights;
   Pofu follows a trail to thank someone; Mochi keeps him from leaving.
10. **The ladder:** sixteen beats, one per arrival, what you learn and
    feel.
11. **The turn at Olta:** from _who is the Bekçi_ to _will Pofu leave_.
12. **The reveal:** one look at the camera, one glass, good night.
13. **Questions for you:** section 7's table plus the lore PR (#135).
