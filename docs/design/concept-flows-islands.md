# Concept flows: the four story islands

**Status:** lead design, 2026-11-07, from the founder's picks on the concept
board (Q-16; [decisions](../product/decisions.md) §3, §4 and §10.3;
[founder log](../product/founder-input.md), 2026-11-07 midday). The shared
rules (anchors, final-first, backgrounds, light) are in
[concept flows](concept-flows.md); the home island's flow is there too. Story
content per island: [story map](../product/story-map/book-one.md) §3 and
[island sheets](book-one-islands.md). Art: batches 67 to 70
(`tools/imagegen/manifest/batch-67-caglayan-flow.yaml` to
`batch-70-mehtap-flow.yaml`). Storyboards for the founder:
[`concept-flows/`](concept-flows/).

The founder picked one direction per island and asked for the liked parts of
the others to be folded in, because no concept set was connected from stage
to stage. Each island below is **one** flow: one plate, one layout, five
stages.

## 0. Rules for the four flows

1. **Nothing moves.** Every island has five numbered **landmarks** (the
   storyboards' dots) that keep their place, size and outline at every stage.
   A stage changes only **movable pieces** (water level, things on shelves,
   lamps, flowers, a tower frame on its fixed footing) and the light. A
   stage's big change may move a minor piece (a tower frame rising on its
   footing), never a landmark.
2. **Final-first chain.** Stage 4 is painted first, at the island camera, as
   the root (`x-<island>-flow-4`). Stage 3 is an edit of 4, 2 of 3, 1 of 2, 0
   of 1. Each edit only takes away, dims, dries, covers, drains or piles up,
   so the stages register and the game crossfades between them. Painting the
   healed state first fixes every landmark's place where it matters most.
3. **Leaves of the chain.** `-4-bare` and `-0-bare` are the plate without
   its movable pieces at both ends of the light range: the pair the layer cut
   needs ([concept match](../research/concept-match.md) §6 route; the bare
   plate plus the full plate, props = the difference). `-4-life` adds the
   resident, Pofu, Mochi and the critters for the founder's review only (the
   game draws them as sprites, so the chain never contains a character).
   `-4-up` paints the three upgrades (decisions G5) into their **reserved
   empty spots**, a fit check that the spots exist and work.
4. **Frame.** 1536 × 1024 plates in the home camera (about 20° above the
   horizon), the island about 88 % of the width, delivered at 768 × 512
   (`deliver: {scale: 0.5}`, under the upload cap). Code places islands from
   a traced matte (`CaglayanLayout.plateSize`, `artWidth`), so the frame
   only needs to be the same for all five stages.
5. **Promotion.** An edit attaches an approved parent, so the five chain
   jobs are promoted as concept targets (a header lead rule in each batch);
   the leaves are takes only. Nothing here is wired into the app.
6. **Wound and cure** (S8, Q-3 B). Stage 0's wound is sayable in one word
   and still magical: a full value range and one warm focal light the
   camera finds first. Stage 4 has motion, lights, residents and critters,
   and its signature reads from home (checked in a 28 pt thumbnail). Light
   per stage follows the sheets: chroma about 0.65 · 0.8 · 0.95 · 1.0 for
   stages 1-4, the first warm practical at stage 2, the signature only at 4.

## 1. The curve across the islands

Each island is a little better than the last (S7). The spectacle rises in
light, life and the size of the change:

| Island | Hour (cell) | Wound (one word) | Stage 4 signature | What it adds over the one before |
|---|---|---|---|---|
| Çağlayan | noon (day) | **donmuş** (frozen) | the falls pour, a mist rainbow, the wheel turns | water and green: the first island that moves |
| Revontuli | its own polar night (night) | **sönük** (unlit) | aurora curtains, a tail that ends in the post's lantern, the lake mirrors it | a light show and night colour; four lanterns rise one by one |
| Emanet | late afternoon (golden) | **sisli** (fog, unclaimed) | everything shelved and tagged, warm windows, bunting, steam, a kite | the most life and detail: the busiest, warmest island; fog you can part |
| Mehtap | blue hour → full moon (dusk) | **karanlık** (dark) | the dome opens, a huge full moon, seven faint trails and a bright new one home, a silver pool, a glowing crescent | the biggest gap of the game: from the darkest picture to the brightest finale |

## 2. Çağlayan (batch 67): C1 with C2's greens

**Picks folded in:** C1's layout and plate (batch-34 `x-caglayan-stuck` t1,
`x-caglayan-healed` t2); C2's grass and flowers (lead-picks
`caglayan-island-4` t2) as greenery only, the cream stone stays visible;
the stone spout is the source (Q-2); the map's frozen fall at stage 0 (I3).

**Landmarks (never move):** ① the cream rock knoll with the stone spout
(back centre) · ② the big round pool at its foot · ③ the mill hut, its
waterwheel and the grindstone where Söz 1 is read (left) · ④ the stream and
the round basin on the front lip · ⑤ the three saucer pools and the
stepping stones (right).

**Movable:** the water (level, fall width), the three leaf boats, grass
carpets, moss, flower clumps, the mill window light and smoke; the
rainbow, mist and light shaft (code effects in the bare plates); Damla and
the critters (sprites).

**Reserved spots:** Damla's seat on top of the knoll above the spout (stage
4, Q-2) · U1 lily pads (and frogs, sprites): the front-right half of the big
pool · U2 a second wheel and a mill lantern: the flat step on the stream
bank in front of the mill · U3 Damla's slide: the knoll's right shoulder
into the pool.

| Stage | What is there | Beat (wound → cure) | Fed by |
|---|---|---|---|
| 0 | the water hangs frozen under the spout as a glassy curtain with still drops; the pool low and mirror-still; stream, basin and saucers dry; boats aground; pale moss; one shaft of sun on the drops | **donmuş**: Damla with an empty glass, puzzled | `x-caglayan-stuck` t1 (the frozen curtain) + the chain |
| 1 | one thin trickle; the pool half full; stream damp, basin dry; saucers dry; wheel dry, window dark | the first sound of water | chain |
| 2 | a thin ribbon; pool full; the top saucer full (boat afloat), the two lower dry; small grass patches; **the mill window lit** | the wheel turns; the first warm light | chain |
| 3 | a strong ribbon; every pool full, boats afloat; flowers in bud; no rainbow, no smoke | DÖNÜM: Mochi spills tea on the grindstone, reads Söz 1 | chain |
| 4 | a full curtain into the full pool, mist rainbow; turquoise pools; wheel spray; window and smoke; green carpets and flowers (C2) | ÇÖZÜLME: Damla on top with a full glass | root: C1 healed t2 (layout) + C2 t2 (greens) |

**Stage 4, lively:** the falls and the stream move (code over the painted
water); the wheel turns with spray; the rainbow shimmers; leaf boats drift;
the mill window glows and its chimney smokes; Damla on the knoll top with
her full glass; two dragonflies and a butterfly; the falls pour off the
underside (code, the roots §5). From home: the rainbow and the green.

**Code note:** `CaglayanLayout`'s anchors (`damlaFeet`, `damlaTop`, `pool`,
`note`, `trickle`) were fitted to batch-43's stepped cliff. Building C1
means re-measuring them from the picked `-4` (Damla's top seat, the
grindstone for Söz 1, the drops for the stage 0 shaft) and moving the
"wall" line to the grindstone (S14).

## 3. Revontuli (batch 68): the ruin → the ice island → the lake → the tail

**Picks folded in:** R1's ice island (batch-34 `x-revontuli-stuck` t1,
`-healed` t2: snow top, glowing ice body, sauna cabin, curved lamp post,
spruce); R2's tower design and ruin mood (batch-45
`x-revontuli-stage0-night` t2); the ice lake and the aurora tail (batch-17
`x2-revontuli-b` t2); Q-4 C (three toppled lantern towers, one rises per
stage). **Joining them:** the island is R1's at every stage; the ruin is its
three fallen towers; the lake is there from stage 0 under snow and is
swept clear as the towers rise; the tail arrives last.

**Landmarks:** ① the sauna on stilts (back left; the one warm light at 0,
"ama sauna hâlâ sıcak") · ② the tall aurora post with its lantern (back
centre) · ③ the snowy spruce (back right) · ④ the ice lake with the fishing
hole and stool (centre left; Olta happens here) · ⑤ the three round stone
footings of towers A (front right), B (mid right, by the spruce), C (back
left, between sauna and post).

**Movable:** the three tower frames (fallen or standing on their fixed
footings), the snow on the lake, drifts, the stool, bucket and towel; the
aurora curtains and tail (code cards, `revontuli-aurora-1`, `-2`).

**Reserved spots:** U1 a lantern path: the trodden lane from the sauna
steps along the lake to the front lip · U2 a sauna bench: the snow by the
sauna's left wall (Söz 4's bench is the one inside the sauna) · U3 an ice
slide: the island's right flank, a smooth stretch of ice body between tower
A and the spruce, curling down the outside of the body.

| Stage | What is there | Beat | Fed by |
|---|---|---|---|
| 0 | all three towers toppled beside their footings, dark, snow-covered; the post dark; the lake under deep snow, the hole frozen; indigo starry sky with a silver moon rim; **the sauna window and steam** | **sönük**: Tuli at the hole, her back to everyone | R2 t2 (ruin mood) + R1 stuck t1 + the chain |
| 1 | tower A stands, lit; B leans on the spruce; the lake a smooth dip in the snow | a whistle in the wind stops | chain |
| 2 | B stands, lit; C still down; the lake's right half swept clear; a faint low ribbon at the horizon | first warm practicals on the snow; the no-talking sauna | chain |
| 3 | C stands: three lanterns in a ring; the lake clear and glassy, mirroring stars and lanterns; the post still dark | DÖNÜM: Söz 4 in the bucket under the sauna bench | chain; the lake from `x2-revontuli-b` |
| 4 | aurora curtains; the tail sweeps down and ends in the post's lantern, gold; the lake mirrors green and violet; the ice body glows with aurora tint | ÇÖZÜLME: Tuli paints a stroke with her tail; the duo sit side by side, silent | root: R1 healed t2 + R2 t2 (towers) + `x2-revontuli-b` t2 (lake, tail) |

**Stage 4, lively:** the curtains ripple slowly; the tail's tip pulses at the
lantern; four gold lanterns flicker; sauna steam; soft snowfall; the lake's
reflection moves; Tuli's tail colours; two snow buntings and an arctic hare;
the icicles below hold the aurora's colour (the roots). From home: the
aurora is the brightest thing in the night sky.

## 4. Emanet (batch 69): EM1 with EM2's bureau, suitcases and fog

**Picks folded in:** EM1's tiled round plate with the teal rim and its places
(batch-34 `x-emanet-stuck` t1, `-healed` t1: heap → shelves, hand-cart, hook
post); EM2's stilted bureau (batch-17 `x2-emanet-a` t1) **and** suitcase pile
(`x2-emanet-b` t1); EM2's misty stuck state (batch-45 `x-emanet-stage0-fog`
t2). **Lead call:** the bureau and the suitcases become one landmark, the
office: the stilted bureau (teacup tank, top-hat chimney, spoon ladder,
scalloped teal roof) standing on a low plinth of stacked suitcases whose
bottom one has the round door of the back room. One building, both loved
pieces, no crowding.

**Landmarks:** ① the office on its suitcase plinth (back centre) · ② the
brass hook post, eight hooks, the eighth empty (back right; ESKİ BEKÇİ) ·
③ the three-bay shelf unit (mid right; the frame, not its contents) · ④ the
hand-cart (mid left) · ⑤ the counter with the brass scale (front right; Söz
7 under the scale).

**Movable:** the heaps (big at the front centre, small at the front left),
the things on the shelves and their tags, parcels, the tag bunting, the kite,
steam, the fog shape (a top hat on an open umbrella, on the cart); the fog
itself (code: it parts where you touch, so `-0-bare` is the stage 0 plate
with no fog at all).

**Reserved spots:** U1 a shelf bay: the tiles between the shelves and the
counter · U2 a bell and a queue: the bell on the counter's corner post, the
queue on the lane in front of the counter · U3 a parcel slide: the diagonal
from the office porch down to the cart.

| Stage | What is there | Beat | Fed by |
|---|---|---|---|
| 0 | thick layered lilac fog; the office, shelves and post fade to silhouettes; every shelf bare; things loom at the front (umbrella, boot, teacup, sailboat); the hat-on-umbrella on the cart; **one oil lantern on the counter sill** | **sisli**: Boncuk asleep on the heap with her duster | `x-emanet-stage0-fog` t2 + the chain |
| 1 | knee-deep fog; one bay full, nothing tagged; a big tumbled heap and a small one; windows dark | the first clean wooden knock | EM1 stuck t1 (the heap) + chain |
| 2 | two bays full; tags return; the small heap shrinks; fog only behind the shelves; **the office window lit** | Pofu pops the umbrella open and laughs | chain |
| 3 | three bays full; the back-room door glows; the cart empty; fog only under the plate | DÖNÜM: Söz 7 under the scale; Mochi gives the ıhlamur tin | chain |
| 4 | everything shelved and tagged; the cart full of ribboned parcels; bunting from roof to post; steam; porch and post lanterns; a kite; a small heap of the day's return | ÇÖZÜLME: Boncuk polishes a cup at the counter | root: EM1 healed t1 (plate, places) + `x2-emanet-a` t1 (office) + `x2-emanet-b` t1 (plinth) |

**Stage 4, lively:** the bunting flutters; the kite bobs; steam curls from
the teacup tank and the top hat; the bells on the hooks swing; warm windows
at golden hour; Boncuk at the counter, Pofu in a found top hat; sparrows on
the umbrella roof; below, the fog skirt thinned to mist and the nets of
found things (the roots). Later the queue (U2) brings visitors: the most
crowded island. From home: the warm windows and the bunting.

## 5. Mehtap (batch 70): M1, the flashiest island

**Picks folded in:** M1's crescent (batch-34 `x-mehtap-stuck` t1,
`-healed` t1: closed dome → telescope, star trail, owl perch, bench, chart
board), pushed at both ends because it is the last island: stage 0 is much
darker and colder than M1's stuck, stage 4 is the full-moon finale and the
most spectacular picture of the game.

**Landmarks:** ① the crescent plate and its two horns · ② the observatory
dome (back centre; its shell opens in place at stage 2) · ③ the moon pool
(front left; Söz 10 on its rim) · ④ Nane's perch with its lantern (mid
right) · ⑤ the bench and the chart board (front right).

**Movable:** the seven moonstone rim lamps (lit one by one), the moonflower
bushes, the blanket; the telescope (inside the dome until stage 2); the sky
(the moon's phase, the trails, shooting stars: code draws the trails from
the player's real calm nights).

**Reserved spots:** U1 telescope views: a brass viewer on the left horn's
ledge · U2 a hammock: between the right horn and Nane's perch · U3 the moon
pool reflects home: the pool's whole surface stays clear.

| Stage | What is there | Beat | Fed by |
|---|---|---|---|
| 0 | no moon, a thin cold sky, one star fading to an ember; chalky grey moonstone without glow; every lamp dark; the pool a dull pewter disc; the chart blank; bare twigs; the dome shut, lead grey; **the gold keyhole** | **karanlık**: Nane asleep; Mochi holds Pofu's paw | M1 stuck t1, pushed darker + the chain |
| 1 | one faint trail in the sky and on the chart; one lamp; a thin crescent moon; the dome still shut | the cold tone warms half a step | chain |
| 2 | **the dome opens, the telescope out; Nane's lantern lit**; two faint trails; three lamps; a half moon | Nane shows Pofu the telescope; he looks the wrong way | chain |
| 3 | seven faint trails on the sky and the chart; five lamps; a gibbous moon; the pool still silver-grey; a stub of the new trail stops short | DÖNÜM: Söz 10 at the pool; the newest trail ends at Ayçiçeği tonight | chain |
| 4 | a huge full moon; seven faint trails and a bright gold one from the telescope toward home; the pool liquid silver; the crescent glowing from within; seven lamps; glowing moonflowers; shooting stars; a starry underside | ÇÖZÜLME and the four closing beats | root: M1 healed t1 (layout), pushed |

**Stage 4, lively:** the new trail lights star by star toward home and the
camera follows it; the dome turns; shooting stars; the moonstone breathes a
slow glow; moon moths around the moonflowers and the lantern; Nane opens
her wings with the chart; the pool ripples silver; the underside fills
with tiny stars. From home: the trail ends over the sunflower every clear
night after the finale.

## 6. Order, counts and what reaches the founder

- **Jobs:** 9 per island (5 chain, 2 bare, 1 life, 1 upgrade fit), 36 in
  all, 2 takes each. Every batch is one track (`all`); the chain runs in
  order 4 → 0, the leaves as soon as their parent is promoted.
- **Order:** Çağlayan first (it is built; the plates replace batch-43's
  cliff), then Revontuli, Emanet, Mehtap. The queue rows are the lead's to
  add in `art-production-plan.md`.
- **Founder review:** the storyboards in [`concept-flows/`](concept-flows/)
  show today's closest pictures, labelled with what will change; once the
  batches land, the same boards are rebuilt from the five real stages and
  the `-4-life` take, and he answers per island.
- **Open:** whether the Emanet office reads as one building (review the
  `-4` take at 28 pt); whether the Mehtap stage 4 stays calm enough (the
  founder found the Tam Çiçek nights too contrasty; the Revontuli and
  Gezgin nights are the reference).
