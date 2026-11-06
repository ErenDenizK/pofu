# Book One island sheets

**Status:** design by the game designer for the lead, 2026-11-06. The founder asked whether every island and everything in it was designed step by step, with positions and levels, until it is complete. Home was ([home progression](../product/home-progression.md), [home layout](../product/home-layout.md)); story islands were only at the arc level, with Koke ([prototype](koke-prototype.md)) and Çağlayan (`batch-43`) in detail. This file is the rest: one sheet per island, in the same convention, ready for briefs, code and lines.

Sources: [game plan](../product/game-plan.md) §3-§5, [healing arc](island-healing-arc.md), [sky and weather v1](sky-and-weather-v1.md) §2.4, the roots proposal (`docs/design/island-undersides.md`, branch `docs/island-undersides`, not yet on main), [lore bible](../product/lore-bible.md) §4, [deep lore](../product/deep-lore.md) §3.2, §4, §5, §6, [home layout](../product/home-layout.md) §1, §3, §5, §10, [home progression](../product/home-progression.md) §7-§8, [monetization v2](../product/monetization-v2.md) §2.1.

**Where docs disagree** (the game plan wins; one line each):

1. **Mehtap.** Game plan §6 calls Mehtap "the year's finale"; §4's own superseding note points to the story rules, where Mehtap's night *is* Book One's finale. Followed: §4's note. Mehtap is the last main island, and its stage 4 is the finale night with Nazlı's grown form.
2. **Çanlar.** §4's table gives it five stages and Pofu's turn; the note makes it a filler (one or two visits, no lore). Kept both: five stages played inside two visits; the turn is a feeling, never lore.
3. **Days.** §4's arrival days are kept as the *typical* day; the note says no fixed days, so the gates are order, the previous bloom and quiet days.
4. **Arı.** Deep lore §6.3 lists Arı as a filler; the game plan makes it the upgrade island of Act III carrying the wax material. Game plan wins. (`content/islands/island-ari.yaml` is older still.)
5. **Revontuli.** Home layout §10 paints it whole; the variety table (newer, the founder's view) makes it a ruin. Followed: the ruin (batch-45's `x-revontuli-stage0-night` already explores it).

## 0. Shared conventions

**The wonder plate frame** (home layout §1, scaled to a plate about the size of `island-main-s`, framed by the camera like home):

| Zone | World box (wu, origin = lawn centre, +y toward the viewer) | Use |
|---|---|---|
| Lawn | ellipse ±150 × ±30 | everything that stands |
| Back band | y −30…−12 | only the landmark (tall, ≥ 110 wu) and props taller than whatever stands in front; at ~17° the rest is hidden |
| Mid band | y −12…10 | the props the stages change |
| Front lip | y 10…30 | the duo (Pofu, Mochi), the resident, every tap target that matters (≥ 44 pt) |
| Earth face | x −130…130, y 32…90 | the plate's body; the resident's door if they live in the earth |
| Underside | below y 90 | only where the roots proposal says yes |

**Stage rules for every sheet** (healing arc, sky and weather §2.4, Koke prototype §1): a visit advances one stage, at most one a day, only on a day with a resisted reach; nothing expires; islands never pay seeds. Light per stage: chroma 0.5 · 0.65 · 0.8 · 0.95 · 1.0, the depth fog's extra 0.55 · 0.4 · 0.28 · 0.15 · 0.08, one hue family unlocked per stage; stage 0 has a full value range and **one warm focal light** that the camera finds first and that grows. First warm practical at stage 2. The signature only at stage 4. A stage change is a 3-6 s eased reveal. Stage 3 is the turn beat; stage 4 is wordless.

**Columns of the stage tables:** *Mended* = the one named element; *Plate* = what the edit of `-island-0` changes; *Light*; *Motion · sound*; *Beat* = what the resident or the duo does (lines are written later with `pofu-story`); *Game* = what is played that day.

**Art ids** follow batch-39/43: `<island>-island-0` is the root plate (1536 × 1024, the home camera), `-1`…`-4` are edits of `-0` only; characters are a root plus rig edits on the same canvas and ground line. Batch numbers from 50 are proposals (49 is the roots).

## 1. Emanet, the lost-and-found

| | |
|---|---|
| Wound | **unclaimed** (lost things piled in fog, unlabelled) |
| Register | eerie fog: muffled sound, a shape that moves in the fog; the first hint of unease |
| Experiment | **the fog parts where you touch**: a press-and-hold thins it in a ~60 wu radius for 4 s and shows what is under it (only lost things, never a face) |
| Healed signature | lantern-lit shelves, every thing in its place, and at golden hour **parcels lift off on dandelion seeds**, drifting to their owners over the horizon |
| Act, day | Act II opener; typical arrival day 16, healed ~20 |
| Engine | none (story island). The day's act is **one return**: drag one found thing from the heap to its shelf or tag (5 s, cannot fail; a wrong shelf just slides it to the right one) |

### 1.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| The office | back centre | (0, −22), ~120 tall | crooked house on short stilts built of lost things: an upturned umbrella roof, a teacup water tank, a top-hat chimney, a spoon ladder; the counter window faces the camera |
| Hook post | back right | (100, −18), ~75 tall | eight hooks; seven hold small covered objects; the seventh holds a lantern under a cloth; the eighth is empty |
| Shelves | mid right | (70, 0), 3 bays | empty at 0, one bay per stage 1-3 |
| Hand-cart | mid left | (−85, −4) | carries the fog shape at stage 0 |
| The Big Heap | front centre | (5, 18) | the drag source; shrinks per stage; Boncuk sits on top at 0 |
| Counter and scale | front right | (110, 16) | a little outdoor counter with a brass scale; line 7 is under the scale |
| Small heap | front left | (−115, 20) | gone at stage 2 |
| Duo | front lip | Pofu (−45, 24), Mochi (−22, 26) | |
| Underside | **yes** | below y 90 | the fog pools under the plate as a cloud skirt; nets of lost things dangle from the roots; the cure gathers them and the skirt thins to mist |

Taps: the heap (drag), the shelf bays (targets), Boncuk, the fog (hold), the hook post (from stage 4, plays the memory line), the lower shelf (stage 4: Pofu's night-light, below).

### 1.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | knee-deep lilac fog over the lawn; heaps everywhere; blank tags; window dark; shelves bare; **the fog shape**: a tall hat on an open umbrella, standing on the hand-cart, drifting across the back | late afternoon drained to amber-grey; shade violet; **one warm light: an oil lantern on the counter window sill** (the camera finds it first) | fog drifts 1 pt/s; the shape crosses every ~40 s; every sound low-passed, one far creak | Boncuk asleep on the heap, a duster in her claws; she wakes, startled, and polishes the duo's feet | none; first tap on the heap surfaces one object |
| 1 | the heaps become shelves | first shelf bay full; the big heap a third smaller | chroma 0.65; the lantern's pool reaches the shelf | things hop onto the shelf one by one; **the first unmuffled sound**: a clean wooden knock | Boncuk polishes the first thing, shelves it, checks it twice | one return |
| 2 | labels return | second bay; cream tags with handwriting on everything shelved; small heap gone | chroma 0.8; **first warm practical**: the office window lights; the sun breaks low through the fog | the fog shape stops: it is an umbrella in a hat on a cart; Pofu pops it open and laughs (the creep solved) | Boncuk ties tags; Pofu wears the hat | one return |
| 3 | the office opens | third bay; door open; the back room glows; fog only under the plate | chroma 0.95; warm interior spill | the scale lifts; tea ripples | **turn, Mochi lets go:** she reads line 7 under the scale in a glass of tea, reads her own upside-down-glass custom right at last, and gives Boncuk her ıhlamur tin on purpose | one return |
| 4 | (signature) | every thing in place, lantern-lit shelves, the cart loaded with parcels | full; warm practicals; golden key | **parcels rise on dandelion seeds**, a slow stream to the horizon; the skirt below thins to mist | wordless: Sumi and Damla collect at the counter; Boncuk lifts the cloth on hook 7, shows the lantern tagged "Nazlı", and puts the cloth back (not yet) | none |

**The quiet secret (stage 4, unsaid):** on the lowest shelf, Pofu's own night-light, its tag in a new hand showing the player's real first day. Found only by tapping that shelf. Nobody comments.

### 1.3 Residents and gifts

| | |
|---|---|
| Resident | **Boncuk**, magpie, soft teal sheen; polishes every object before she gives it back (granddaughter of Gümüş, never said in Book One) |
| Apprentice who stays | proposal: **Kabuk**, a hermit crab living in a lost teacup, who sorts by size and is always wrong in a charming way |
| Visit | Wednesday; works the workshop S4; guest stall: polished found things on tags |
| Material | keepsake (*emanet*), ~day 20 (home progression §7) |
| Decor (set 2) | **the lost umbrella**, the fog shape itself, open over the D1 bench (lawn spot); the hat hangs on its handle |
| Under the roots | a small net of found things hanging from a root, each labelled; memory: Boncuk recalls the first thing the player returned, by name |
| Week page | stamp: a cream luggage tag on a teal string; the page draws the five things returned that week, in a row |

### 1.4 Art (`batch-51-emanet`)

- `emanet-island-0` … `-4`: plate chain — **concept first**: one layout concept, stage 0 and 4 side by side, rooted in `x-emanet-stage0-fog`
- `boncuk`, `boncuk-duster`, `boncuk-polish`: character rig — no (lore bible look is enough)
- `kabuk`: apprentice
- `emanet-found-1` … `-8`: drag sprites (cup, glove, key, kite, spoon, sock, compass, bell)
- `emanet-fog-shape`: sprite (hat on umbrella on cart)
- `emanet-roots-nets`: underside sprite — rides with batch-49
- `decor-lost-umbrella`, `keepsake-emanet-net`, `stamp-emanet`, `nightlight-tagged`: home and UI

### 1.5 Risks

1. **The fog shape reads as a stranger** (a hat and a tall figure). Test: a contact sheet at 28 pt to five people; if anyone says "a man", widen the umbrella.
2. **The return act blurs "story, not game".** Test: the act on Koke's placeholder plate; it must take under 6 s with no instruction.
3. **Press-to-part fog nobody discovers.** Test: does anyone touch the fog in the Koke pilot unprompted? If not, Pofu parts it once on arrival.

## 2. Çanlar (filler), the bells

| | |
|---|---|
| Wound | **mute** (bells tangled and silent) |
| Register | odd, funny; **a wrong note**: at night one "bell" rings off-key by itself |
| Experiment | a playful creep solved with a joke: the fourth bell is missing and Zil hung his **copper kettle** in its place; at night his brazier warms it and it sings off-key. The real fourth bell is his bed, upside down, with a quilt in it |
| Healed signature | **sound first**: the screen holds still for one beat, then the four-note chord rings and the bells swing in a wave around the frame |
| Act, day | filler between Emanet's bloom and Revontuli's rumour (typical day 23, window ~21-28, never the day before a main beat) |
| Engine | **recall debut** (listen and repeat). Filler pacing: stages 1-3 advance one per recall round, so one visit can reach stage 3; stage 4 needs a second visit on a later day, at dusk or after |

### 2.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| The spire | back centre | (0, −22), ~160 tall | the tallest landmark of Book One so far; terracotta roof, verdigris trim; ropes run down from it |
| Bell frame | mid, across | x −75…75, y 2 | a low timber frame; bells at x −60, −20, 20, 60, graded big to small; the four tap targets of the game |
| The kettle | in slot 4 | (60, 2) | until stage 3 |
| The rope knot | mid centre | (0, −8) | the tangle; one rope freed per stage |
| Zil's door | spire base, left | (−40, −12) | a bell-shaped door, a candle in its window |
| Brazier and bed | front right | (95, 18) | the brazier; beside it the upturned fourth bell with a quilt |
| Duo | front left | Pofu (−70, 24), Mochi (−48, 26) | |
| Zil | on the frame, barefoot | (0, 6) | he rings by the buzz in his feet, so he feels the player's taps |
| Underside | **small** | below y 90 | the ropes hang down through the body, tangled; untangled per stage |

### 2.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | ropes in one knot; three bells mute and askew; the kettle in slot 4 | dusk drained; **one warm light: the candle in Zil's bell-shaped window** | at dusk or night the kettle goes "dooonk", off-key, every ~25 s; steam puffs | Zil stamps on the frame to feel a ring that is not there; Pofu tries to ring a bell with his paw: nothing | none |
| 1 | rope 1 | bell 1 hangs straight | chroma 0.65 | bell 1 rings (low note) | Pofu jumps in before the phrase ends; the bells clunk (no fail; the phrase replays). Mochi: tea | recall, 3 notes |
| 2 | rope 2 | bell 2 straight | 0.8; first warm practical: the brazier glows | two notes ring true | Pofu still early, a little less | recall, 3 notes |
| 3 | rope 3 and the real bell | bell 3 straight; **the bed is a bell**: Zil climbs out, the duo rehang it; Zil moves into the kettle | 0.95 | three true notes and a squeak from the kettle bed | the joke lands: Zil sleeps in the kettle, lid as a hat | recall, 4 notes |
| 4 | (signature; second visit, dusk or later) | all four bells hung | full; lanterns on the frame | Zil rings the four notes once; the player repeats; **the chord**, then the wave | wordless: **Pofu waits** the whole phrase before he moves, for the first time. He hums along | recall, the four-note call |

### 2.3 Residents and gifts

| | |
|---|---|
| Resident | **Zil**, bell-ringer mouse, proud, hard of hearing (his secret stays unsaid; Book Two re-reads him). He is never the joke; the kettle is |
| Apprentice | none (a filler) |
| Visit | no weekday (fillers are not on the roster); comes only by the quiet-day invitation and rings the harbor bell L4 |
| Material | none (fillers leave decor only) |
| Decor | Zil's red-and-cream bell rope on the harbor bell L4; tapped at dusk it rings the four notes |
| Under the roots | one small bell on a root; memory: Zil, too loud, praising the player's patience |
| Week page | stamp: a bell with four dots; the page prints the notes the player rang |

### 2.4 Art (`batch-52-canlar`)

- `x-canlar-concept-a/b/c`: three layouts (spire + frame) — **concept first**, no concept exists
- `canlar-island-0` … `-4`: plate chain (bells drawn askew, then straight) — after concepts
- `canlar-bell-1` … `-4`, `canlar-kettle`: swing rig sprites over the plate
- `zil`, `zil-ringing`, `zil-kettle-bed`: character rig
- `recall-glint`: game UI piece (bell flash)
- `decor-bell-rope`, `keepsake-canlar-bell`, `stamp-canlar`: home and UI

### 2.5 Risks

1. **Audio has not landed** and the signature is sound-first. Test: four tones in an AVAudioEngine sketch on the founder's phone before any art.
2. **A random filler carries the recall debut and Pofu's turn.** Test: `GameScenarioTests` with light and heavy users: Çanlar must fall in its window for all of them, or it becomes a main island.
3. **Hard-of-hearing as comedy.** Test: the `pofu-story` editorial pass on Zil's five beats; the laugh is on the kettle, never his ears.

## 3. Revontuli, the ruin under the aurora

| | |
|---|---|
| Wound | **fallen** (lantern towers broken) |
| Register | ruin: wind through broken lantern towers; the most visible repair in the book |
| Experiment | the island **keeps its own polar night** at any clock hour (a cosmetic dome of night, not the real night; rounds still follow the no-rounds-at-night rule by the real clock); and **the sound heals by subtraction**: the wind loses one whistle per tower rebuilt |
| Healed signature | green and violet aurora curtains move over the island; Tuli's tail turns colour and paints a stroke into the sky; the fishing hole mirrors it |
| Act, day | Act II closer; typical arrival day 30, healed ~33 |
| Engine | **flow + light** (reuse of the flow engine): rotate ice-prism and chain pieces to carry the sauna's warm light to a tower's lantern |

### 3.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| Aurora post | back centre | (0, −24), ~140 tall | the aurora's lantern on a tall post; dark until stage 4 |
| Sauna on stilts | back left | (−75, −20) | warm window from day one (Ayaz sleeps under its stone, unsaid); line 4 under the bench |
| Tower A (stump) | front right | (115, 12) | broken to a stump; rebuilt at 1 |
| Tower B (leaning) | mid right | (70, −14) | leaning on the spruce; righted at 2 |
| Tower C (fallen) | mid left | (−110, −6) | lying across the snow; raised at 3 |
| Snowy spruce | back right | (118, −22) | |
| Fishing hole, stool | front left | (−55, 20) | the mirror of the signature |
| Tuli | at the hole | (−30, 18) | back to the camera at 0 |
| Duo | front centre | Pofu (20, 24), Mochi (42, 26) | |
| Underside | **yes** | below y 90 | broken lantern chains hang below; healed: the icicles become crystal lanterns holding the aurora's colour |

### 3.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | three broken towers, dark lantern post, snow drifts; deep indigo sky (zenith L* ≥ 12, never black), stars | ice body glows faint cold; **one warm light: the sauna window** | three whistles in the wind; gentle snow | Tuli sits at the hole with her back to everyone, tail plain white | none |
| 1 | tower A | the stump stacks up into a tower, its lantern lit | 0.65; a warm amber pool on the snow at A | blocks lift and settle; whistle 3 stops | Tuli's ear turns | flow + light: sauna → A (short board) |
| 2 | tower B | B upright and lit | 0.8; first warm practicals on the path; **a faint low aurora ribbon**, still, at the horizon | whistle 2 stops | Tuli turns around and sits with the duo, saying nothing; Pofu tries to talk, Mochi shushes him | sauna → B |
| 3 | tower C | C raised and lit; three lanterns in a ring | 0.95 | one whistle left, softer | **Mochi reads line 4** in the sauna bucket's still water ("a light put out is not lost") | sauna → C |
| 4 | (signature) | the post's lantern lit, pale gold; curtains of aurora | full | the last whistle becomes a soft chord; curtains move slowly; Tuli's tail colours | wordless: Tuli paints a stroke into the air; the hole mirrors it | the long board: A, B, C → the post |

### 3.3 Residents and gifts

| | |
|---|---|
| Resident | **Tuli**, round white arctic fox, tail tip a soft brush; wants someone to sit the whole sauna without talking |
| Apprentice | proposal: **Pamuk**, a fox kit who carries the paint bucket and spills it |
| Visit | Friday; works the lighthouse S9; guest stall: a jar of painted aurora |
| Material | light (*ışık*), ~day 33 |
| Decor (set 2) | the light jar, on the pond-edge spot D3 |
| Home change | **the morning after a calm night**, a thin aurora ribbon hangs over Ayçiçeği until noon (deep lore: aurora is received quiet); it makes the calm-night bonus visible without a number |
| Under the roots | a cluster of ice crystals holding a faint aurora at night; memory: Tuli, one line, about sitting |
| Week page | stamp: a green-violet brush stroke; the page marks each calm night with a tiny ribbon |

### 3.4 Art (`batch-53-revontuli`)

- `revontuli-island-0` … `-4`: plate chain (towers broken at 0; edits rebuild) — **concept first**: stage 0 and 4 at the same camera, rooted in `x-revontuli-stage0-night`
- `revontuli-aurora-1`, `-2`: light-on-black curtain cards, two layers
- `tuli`, `tuli-back`, `tuli-paint`: character rig (tail plain and coloured)
- `pamuk`: apprentice
- `flow-prism`, `flow-chain`: flow pieces in light skin
- `revontuli-roots-icicles` (dark and lit): underside sprites — rides with batch-49
- `decor-light-jar`, `keepsake-revontuli-ice`, `stamp-revontuli`, `home-aurora-ribbon`: home and UI

### 3.5 Risks

1. **Day at home, night on the island**: a pan across the clock can jar. Test: a crossfade through the cloud sea in the Koke build with a night grade.
2. **The ruin depresses rather than enchants.** Test: batch-45's take on the lookdev sheet; the sauna window must be the first thing seen.
3. **Flow with a new skin feels like a repeat.** Test: the prism piece (light splits to two outputs) on Çağlayan's engine; keep it only if a tester notices the difference.

## 4. Arı, the tired hive

| | |
|---|---|
| Wound | **tired** (an empty hollow, closed flowers, a low hum with no bees) |
| Register | tired: a breather before the end |
| Experiment | none on the wound. The new thing is **the signature happens at home**: the camera pans from Arı to Ayçiçeği and the swarm dances over the sunflower |
| Healed signature | the swarm's dance over Ayçiçeği; on Arı, the flower bands in full colour and the linden humming |
| Act, day | Act III opener; typical arrival day 37, healed ~40 |
| Engine | **place** (the garden engine) with one twist: plant one colour per band; a band of one colour becomes a **flight path** the bees fly in real time while you place |

### 4.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| The old linden | back centre | (0, −24), ~150 tall | a hollow linden with a wild comb in its hollow (the tree is *ıhlamur*; never said) |
| Band 1 (lavender) | front arc | y 16, x −120…120 | mended at 1 |
| Band 2 (sunflower yellow) | mid arc | y 2 | mended at 2 |
| Band 3 (white clover) | back arc | y −12 | mended at 3; low, so the tree reads above it |
| Old skeps | mid left | (−105, −6) | two straw skeps, empty |
| Stone trough | front right | (105, 18) | dry at 0; honey-gold water at 4 |
| The keeper | front centre-left | (−35, 14) | asleep in a closed flower |
| Duo | front right | Pofu (55, 24), Mochi (78, 26) | |
| Underside | **no** | | the story is above |

### 4.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | every flower closed; the bees in one sleeping ball under the hollow; the trough dry | morning drained, cool lilac shade; **one warm light: a single honey drop at the hollow's lip, catching the sun** | a low hum that does not move | the keeper sleeps; Pofu boops a closed flower; it stays shut | none |
| 1 | band 1 | lavender open | 0.65; violet family | a dozen bees wake and work the band | the keeper opens one eye and counts them, out loud | place: lavender band |
| 2 | band 2 | yellow open | 0.8; first warm practical: the hollow glows amber inside | the hum gains a second pitch | the keeper wakes, stops counting when Mochi hands her tea | place: yellow band |
| 3 | band 3 | clover open; the comb fills; the trough wet | 0.95 | bees busy on all bands; no dance yet | turn beat (light): Pofu notices the bees all face one way, toward home | place: clover band |
| 4 | (signature) | every band, the skeps humming, honey in the trough | full | the swarm rises, the camera pans home, the **dance over the sunflower** (it points at the sunflower's heart; never said) | wordless | none |

### 4.3 Residents and gifts

| | |
|---|---|
| Resident | the bees' keeper. Unnamed in the lore bible; proposal: **Petek**, an old round bumblebee who counts her bees out loud and naps in flowers. Want: to see the dance once more. Need: to stop counting |
| Apprentice | the swarm itself, which stays and works |
| Visit | Saturday; works the hive S6; guest stall: honey jars |
| Material | wax and honey (*bal mumu*), ~day 40 |
| Station | the hive S6 opens at IL9 when Arı is done (home progression §7); before IL9 the bees live in the keepsake comb |
| Decor (set 2, proposed) | a bee skep on the tea stall awning's line D2 |
| Under the roots | a small wild comb between roots, bees in and out by day; memory: Petek, counting, then stopping |
| Week page | stamp: a hexagon with a bee; the page shows the three bands as the player planted them |

### 4.4 Art (`batch-54-ari`)

- `x-ari-concept-a/b`: linden + bands layout — **concept first** (no island concept; the hive concepts of batch-28 are home's)
- `ari-island-0` … `-4`: plate chain — after concepts
- `ari-bee-ball`, `ari-bee` (sprite sheet, 4 frames): motion
- `petek`, `petek-asleep`: character rig
- `place-flower-lavender/-yellow/-clover`: garden pieces
- `decor-skep`, `keepsake-ari-comb`, `stamp-ari`: home and UI

### 4.5 Risks

1. **A breather that reads as filler** right after the ruin. Test: lead review of the concepts next to Revontuli's; if Arı looks smaller, enlarge the linden.
2. **The place engine away from home feels like a copy of the garden.** Test: bees following a band live while placing must be the first thing a tester mentions.
3. **The signature off the island** (pan to home). Test: the pan in the Koke build; home layout's "nothing new appears off camera" holds.

## 5. Mehtap, the dark stars

| | |
|---|---|
| Wound | **dark** (stars missing from a dull sky) |
| Register | dread, quiet: the darkest moment of the book |
| Experiment | **a star dims while you watch** on arrival (a 6 s fade to a faint ember, never to black, with a cold glassy tone; lead, 2026-11-06: dims, not dies). The braver version; the cure is that they were never lost: they are dark stars, remembered lights, and they join into trails |
| Healed signature | **the new bright trail draws itself from Mehtap across the sky and ends at Ayçiçeği**; the camera follows it home. Its stars are **the player's real calm nights of Book One**, one star each, from the record |
| Act, day | Act III, the last main island; typical arrival day 41, stages ~42-44; stage 4 is the finale night (~45) |
| Engine | **flow (moon line)**: the board is the sky above the island (the camera tilts up); connect stars by rotating thread segments |
| Moon gate | **a blessing, not a gate** (lead, 2026-11-06: a hard wait of up to ~15 days could stall the finale): stage 4 opens on the next resisted day as usual; if the real moon is at least half lit that evening, the trail is drawn under it and Nane names the moon; if not, the trail glows on its own and the moon joins it on its first half-lit night after. Pofu's waiting is still paid (Çanlar's turn) without blocking anyone |

### 5.1 Layout

| Prop | Place | World (wu) | Notes |
|---|---|---|---|
| Crescent horns | back left and right | (−135, −10), (135, −10), ~70 tall | the plate's two ends rise like a cradle |
| Observatory dome | back centre | (0, −22), ~110 tall | closed at 0; a pale-gold keyhole |
| Moon pool | front left | (−55, 18) | dull pewter at 0, silver at 3; line 10 on its rim |
| Nane's perch and lantern | mid right | (95, −6), ~90 tall | |
| Bench and chart board | front right | (60, 20) | the chart blank at 0 |
| Duo | front centre | Pofu (−5, 26), Mochi (18, 27) | |
| Nane | at the perch's foot | (88, 10) | asleep in a ball at 0 |
| Underside | **small** | below y 90 | a dark underside that fills with tiny stars as constellations join |

### 5.2 Stages

| Stage | Mended | Plate | Light | Motion · sound | Beat | Game |
|---|---|---|---|---|---|---|
| 0 | (the wound) | dome shut, pool dull, chart blank, a thin sky | blue hour gone cold, silver drained; **one warm light: the dome's pale-gold keyhole** | on arrival one star fades out; a cold descending tone; then nothing moves | Nane asleep; Mochi holds Pofu's paw (the only time) | none |
| 1 | the first faint trail | the stars stop going out; one old trail joined | 0.65 | the cold tone warms half a step | Nane wakes long enough to say good morning, at dusk | flow: one trail |
| 2 | the dome opens | the telescope out; a second trail | 0.8; first warm practical: Nane's lantern lit | the dome's slow turn | Nane shows Pofu the telescope; he looks the wrong way | flow: second trail |
| 3 | the chart drawn | seven faint trails on the chart and in the sky; the pool turns silver | 0.95 | the pool stills | **Mochi reads line 10** on the pool's rim; she turns the old glass upright | flow: the last five faint trails at once; the seventh (the old keeper's) stops short of home |
| 4 | (finale; moon gate) | the bright new trail from Mehtap to home; the pool full of stars | full; moonlight | the trail draws (8-10 s), the camera follows it home; Nazlı's grown form begins (section 6) | Nane says "günaydın" to the player | none |

### 5.3 Residents and gifts

| | |
|---|---|
| Resident | **Nane**, tiny round grey-and-cream owl; says "günaydın" at sunset |
| Apprentice | proposal: an owlet who copies the chart, badly (name in the `pofu-story` pass) |
| Visit | Sunday; works the windmill S5 at dusk; guest stall: a star chart |
| Material | none (sea glass comes from Gezgin at the same night) |
| Home change | from then on, **the player's trail** is in home's night sky every clear night; it ends over the sunflower |
| Later | Mehtap's moon telescope replaces the lookout's telescope at T1 when the Tepe opens (IL10) |
| Under the roots | a tiny moon lamp, the last light to come on at night; memory: Nane, good morning at dusk |
| Week page | the finale page: the chart with the player's trail, each star dated |

### 5.4 Art (`batch-55-mehtap`)

- `mehtap-island-0` … `-4`: plate chain — **concept first**: stage 0 and 4, rooted in batch-17's crescent (`x2-mehtap-a`)
- `mehtap-trail`, `mehtap-star` (lit and dark): light-on-black sprites; code draws the trail from data
- `nane`, `nane-asleep`, `nane-lantern`: character rig
- `flow-thread`: flow piece in the moon skin
- `keepsake-mehtap-moon`, `stamp-mehtap`: home and UI

### 5.5 Risks

1. **The fading star frightens.** Test: five people, the 6 s fade at 28 pt; if anyone says "sad" not "eerie", fade it to dim, not out.
2. **The moon gate waits too long.** Test: a `PofuCore` scenario over a year of start dates: median and worst wait; above 7 days median, drop to "moon above the horizon".
3. **The trail from real nights is thin for a player with few calm nights.** Test: the record of the light user; floor of seven stars, the rest filled from resisted days.

## 6. The Gezgin finale: Nazlı's forms

| | |
|---|---|
| Wound | **tired** (form 1: faded, thin, the lantern hook empty) |
| Register | humble, wilful; a tired cloud that thinks she got too heavy |
| Experiment | **the island that moves and grows with the bond**: one detail on her back per main island, never bought (deep lore §8.1 rule 7) |
| Healed signature | form 2 at the pier, golden then moonlit: fuller, eye open, a lush back garden with a young sunflower from home's soil, Ihlamur's lantern lit on the hook, the scar glowing gold; **she sings the four notes, low enough to move water**; far off, Koke breathes once |
| Act, day | carries the player from early on; the finale is the night of Mehtap stage 4 (~day 45) |
| Engine | none. The four notes are heard, not played |

### 6.1 Layout (at the harbor)

| Piece | World (wu) | Notes |
|---|---|---|
| Nazlı | sky east, (520, −40), about three islet widths | moored beside the pier S8 |
| Back patch | her back, ±90 wu around (520, −70) | bench, mooring post, grass tuft, the lantern hook, the scar |
| Detail sockets N1-N5 | along the back patch, left to right | one per main island (below); none needs a menu |
| Yosun | on the bench | the tortoise postman, a satchel |

### 6.2 Forms (stages)

| Stage | After | Added on her back | Light | Motion · sound | Beat |
|---|---|---|---|---|---|
| 0 | start | form 1: grey-blue, cream belly, head low, heavy-lidded eye; empty hook; a faint scar shaped like a switched-off bulb | cool, drained | slow breath (8 s) that slows further near a slow breather | she will not leave the pier until Pofu has packed; wilful |
| 1 | Koke and Çağlayan (Act I) | N1 a moss tuft with Koke's sprout; N2 a palm-sized pool | 0.65 | her breath 9 s | she takes the long way on purpose |
| 2 | Emanet | N3 a cream tag on the hook in old handwriting: "Nazlı" (the promise of the lantern) | 0.8 | she rolls a little in the wind | she lets Mochi sit on her head |
| 3 | Revontuli and Arı | N4 an ice crystal that holds aurora at night; N5 a clump of lavender with two bees | 0.95; the scar warms | she hums under the sound floor (felt as a haptic) | Yosun reads his own satchel, finds nothing for himself, shrugs |
| 4 | Mehtap's finale night | form 2: the soil pocket blooms into a young sunflower; three round trees; the pool falls into a second pool; the five materials tucked among the plants; **Boncuk arrives on the night and hangs Ihlamur's lantern on the hook**; the scar glows gold | full; the lantern is a light kept for someone | the four notes, low; water moves in every pool; far off, Koke breathes once | she chooses the keeper: lowers her head to the player's side of the screen; Mochi sits; the book ends on good night |

### 6.3 Residents, gifts, art

| | |
|---|---|
| Resident | **Yosun**, tortoise postman (visit Thursday, pier S8, a satchel of letters); his want (a letter for himself) waits in Book Two |
| Material | sea glass (*deniz camı*), at the finale (~45) |
| Home change | from the finale Nazlı moors lit at the pier every night |
| Under the roots | the hook where her lantern hangs when she docks; memory: none spoken, the lantern sways |
| Week page | Book One's last page: every island's stamp in a row, then a blank page (Book Two) |
| Art (`batch-56-nazli-forms`) | masters exist (`nazli-body`, `-fins`, `-tail`, `-eyes-closed`, `-island-patch`; batch-22 forms). New: `nazli-eyes-open`, `nazli-detail-1` … `-5` (each ships with its island), `nazli-form-2-patch` (**concept first**), `lantern-ihlamur` (unlit, lit), `nazli-scar-glow` |

### 6.4 Risks

1. **"The grown form chosen once"** (story rule 4) is undefined. Recommendation: one tap, three back gardens (tree, pool, flowers), default after 10 s; cheapest test: a three-card paper choice to the founder.
2. **The finale needs every main island**; a player who stalls on Arı never sees it. Test: scenario tests for the light user; ≤ day 70.
3. **Song without audio.** Same as Çanlar: the tone sketch first.

## 7. Filler template (one page per filler)

| Field | Rule |
|---|---|
| Wound | one funny or odd word; no lore the main story needs (a secret may sit unsaid for a later book) |
| Arrival | drifts in on a random quiet day inside a stated window, never the day before a main beat; never expires |
| Pacing | complete in one or two visits; stages may advance per round; no counter, no material |
| Layout | the shared plate frame; one landmark back centre; one prop the joke lives in; the duo front; underside only if the joke is below |
| Stages | 0 the oddity with one warm light; 1-3 the oddity undone, one piece per round; 4 the joke's payoff, wordless |
| Engine | reuse an engine with its Book One skin; never debut one (Çanlar is the single exception, by the game plan) |
| Resident | one, no apprentice, no weekday; comes by invitation only |
| Gifts | one decor piece; a keepsake under the roots only if the roots proposal names it |
| Art | `<filler>-island-0` … `-4`, one character root and one edit, the decor piece, a stamp; a concept only if no silhouette exists |
| Risk check | does it duplicate a neighbour's register, colour or hour? |

## 8. The Book One arc across islands

**Fear and strength** (0 = none, 5 = the most Book One allows; peak score from game plan §4):

| # | Island | Day | Act | Register | Fear | Wound strength | Peak | Hour | Colours (dominant, then accent) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Koke | 6 | I | sleepy | 0 | 1 | 3 | morning | moss grey to green; flower pink |
| 2 | Çağlayan | 10 | I | dry | 1 | 2 | 4 | noon | cream stone; teal water, rainbow |
| 3 | Emanet | 16 | II | eerie fog | 2 | 3 | 4 | late afternoon | honey amber, lilac fog; teal planks as accent only |
| f | Çanlar | ~23 | II | odd, funny | 1 | 2 | 3 | dusk | terracotta, verdigris bronze |
| 4 | Revontuli | 30 | II | ruin | 3 | 4 | 5 | its own night | indigo, ice white; aurora green-violet |
| 5 | Arı | 37 | III | tired | 0 | 2 | 5 | bright morning | gold and ochre; lavender, clover white |
| 6 | Mehtap | 41 | III | quiet dread | 4 | 5 | 6 | blue hour | moonstone silver, deep blue; one pale gold |
| — | Gezgin finale | ~45 | III | release | 0 | 2 | 6 | golden, then moonlit | grey-blue to cream; scar gold |

The fear curve rises 0, 1, 2, 1, 3, 0, 4, 0: each dip is a breath before the next step, the darkest night sits right before the release. No two neighbours share a dominant colour or an hour; the two blue islands (Revontuli, Mehtap) are split by Arı's gold.

**The order of games:** place (home, day 1) → none (Koke) → **flow** debut (Çağlayan) → the return act (Emanet) → **recall** debut (Çanlar) → flow + light (Revontuli) → place + bees (Arı) → flow + moon (Mehtap) → the four notes heard (finale). No engine twice in a row; each reuse adds one twist.

**The turns:** Mochi is afraid of the drop (Çağlayan), Mochi lets go (Emanet, stage 3), Pofu learns to wait (Çanlar, stage 4; paid at Mehtap's moon gate), both at the finale (Mochi sits, Pofu stops where he always stops).

## 9. Build order

1. **Generalise the Koke model** in `PofuCore`: `WonderIslandID` gains `emanet`, `canlar`, `revontuli`, `ari`, `mehtap`; a `filler` pacing flag (stage per round, two visits); a per-island spec (anchors, stage props, gift) as data so islands 3-6 add content, not code.
2. **Çağlayan and the flow engine** (in flight, batch-43). Build the flow engine with skins from the start (water, light, thread).
3. **Emanet** (day 16, no new engine): the return act and the press-to-part fog; `batch-51` layout concept, then production.
4. **Çanlar concepts now** (`batch-52` concepts; none exist) and the **recall engine + a four-tone audio sketch** in parallel; this is the long pole (audio identity has not landed).
5. **Revontuli** (`batch-53`): the light skin, the prism piece, the island's own night grade.
6. **Arı** (`batch-54` concepts, then production): the place engine's band twist; the hive S6 at IL9.
7. **Mehtap** (`batch-55`): the moon phase in `PofuCore` (pure, from the date; tested on Linux), the trail drawn from the player's calm nights.
8. **Nazlı** (`batch-56`): one back detail ships with each island; form 2 and the finale last.
9. **Keepsakes** ride with the roots (`batch-49`), one sprite per island, shipped with that island.

## Lead decisions on the open risks (2026-11-06)

1. **Mehtap's star:** it dims to a faint ember, never goes out; test the 6 s fade with five people before the art.
2. **The moon gate:** a blessing, not a gate (§5 table); no finale waits on the calendar.
3. **Çanlar's sound first:** keep it; the healed state also shows visually (the bells swing in time) so it never depends on audio alone.
4. **Nazlı's form:** one tap between three back gardens, default after 10 s, as recommended.
5. **Batch numbers** shifted by one (`batch-50` is the gate's postcards); names marked as proposals go through the `pofu-story` pass.
