# The Archipelago System: Islands You Want to Play

_Status: proposal for discussion with the founder. Date: 2026-11-02;
**revised 2026-11-03** after his review of the concept deck (section 1A).
Builds on [game-design.md](game-design.md) (v2), [ADR-0015](../adr/0015-care-over-currency.md),
[ADR-0016](../adr/0016-pre-planned-idle-archipelago.md),
[ADR-0017](../adr/0017-pofu-never-dies.md), [app-game-boundary.md](app-game-boundary.md)
(rules A15–A21), [decision-audit.md](decision-audit.md), the pricing
work in PR #60, and the content graph in [`content/`](../../content/README.md).
Founder inputs of 2026-11-02 (Hub answers and a later voice note, his
views rather than orders, but they set the direction): economy scale A
(small numbers, about 10–40 seeds a day, prices 5–200); archipelago B
(two islands at launch, more as seasonal updates) with "a main loop plus
a system that could go on forever"; "each island should keep curiosity
alive, in content and in story"; "a waterfall pouring off an island";
**no procedural or kit-built islets** ("everything must have craft in
it"); **every island playable** ("turn the project more into a game:
learning something, a different loop inside, a mini game"); 5–10 minute
play sessions are fine; free decor spots; a question about
Roblox-style scaling; markets beyond Türkiye; and Plus opening the islands
after the free pair, with the cut point decided by data. Nothing here
changes code; numbers are illustrative until the economy pass and
`tools/sim` confirm them._

## 0. The answer in one paragraph

Pofu's archipelago becomes **a long run of hand-made islands, each a
small game of its own**, joined by one shared loop. Every island has a
silhouette nobody has seen before, a **signature motion** done in code (a
waterfall pouring off its edge into the clouds, an island hanging upside
down beneath the cloud sea, an aurora painted by a fox's tail), a
resident, a **secret** told in five stages, a **toy** for ten seconds of
pure play, and an **island game**: its own verb (route leaf boats, draw
constellations, rake a moss garden, fish through ice) played in short
rounds. **Resisting the reach earns the rounds; playing them is the
reward.** Rounds yield the island's own **material** (water drops, star
dust, clay), which, with a few seeds, opens the island's next stage and
its **decor spots**. Rumours (a sound from the fog, a bottle the ferry
brings, a light at the map's edge) tease the next island on a fair,
deterministic schedule driven by the user's own calm. Numbers stay small
forever because income is real behaviour and each island has its own
material. Play is allowed to be a deliberate 5–10 minutes, because it is
finite, earned, and ends on its own; the guardrail moves from "visits are
short" to "the game never becomes the new reflex". Islands come from
many cultures, so someone in Helsinki or Kyoto finds their own place in
the sky. The thin myth over all of it is the product's thesis: **islands
drift toward quiet.**

What changes from game-design v2:

| v2 today | Proposed |
|---|---|
| Every island: three stations × five levels, one ritual (about 27 images) | One **home** cluster (Ayçiçeği and its harbor, free; 1A.2); every later island is a **wonder island** with a game, a secret, decor spots (about 12–16 images plus one game) |
| Islands are places you build | Islands are places you **play**: one game per island, one shared loop |
| Yıldız, Kaplıca, Kitap carry station ladders (45 vignettes, 1.5 M seeds) | They become wonder islands with games; the ladders are retired |
| One currency for everything | Seeds stay universal; each wonder island adds one local, non-convertible **material** earned by playing it |
| Visits only: median under 90 s | **Visits** stay short; **play sessions** of 5–10 minutes are allowed, finite and earned (section 6) |
| Placement is never the player's | **Decor spots**: fixed sockets where the player chooses what goes (section 5) |
| Arrival is a bubble and a cloud pass | A **rumour ladder** before, a choreographed **arrival**, a **secret** after |
| Mostly Turkish settings | A sky of many cultures; Turkish warmth at home |

**Revision of 2026-11-03 in one paragraph (section 1A).** İskele is no
longer a second island: it becomes **Ayçiçeği's harbor district**, so the
free part is one home cluster where everything meets. Wonder islands sign
a **uniqueness contract**: no lawn-oval plates; the island *is* the idea
(a whale, a bell spire, a crescent moon, a bonsai in the rain, a glass
bell jar, a kiln of fairy chimneys, a nest carried by storks), and each
changes at least three axes including its silhouette. Islands work **in
parallel**: each keeps a job through **goods** that later islands request
(materials stay local), **awake islands** rotate daily, and every island
leaves a **permanent gift on Ayçiçeği**. Home changes daily through time,
simulated weather (real weather opt-in later), seasons, events, growth
and visitors. The first wonder island arrives on **day 4**, Gezgin on day
8, then each wait is a day longer than the last.

## 1. The problem, stated precisely

The founder's fear is the content treadmill and the "+1" feeling:
"second island, wow; third, oh it's an island too". Four forces produce
that feeling:

1. **Sameness of function.** If every island is "three more stations",
   island four is a bigger number. Fix: every island has its own verb.
2. **Sameness of arrival.** A new island that simply appears is a
   notification. Wonder needs anticipation, a reveal, and an unanswered
   question.
3. **Nothing to do.** "A plus, not a game": an island you can only look
   at is visited once. Fix: every island is playable and teaches
   something.
4. **Cost.** At 30–40 images per island a small team ships two a year.
   "Fifty hand-made islands" needs reuse that the player never sees.

And it must not break the product: the game must never become the new
reflex (decision audit §3). Section 6 states how play can be longer and
still safe.

## 1A. Revision after the founder's review (2026-11-03)

The founder reviewed the concept deck (batches 10 and 15). His views, in
short: islands must work **in parallel**, each staying useful as you move
between them; Ayçiçeği and İskele are too far apart and İskele feels
empty; Ayçiçeği is the hub, simple in design but **always changing**, and
"everything meets on the home island"; wonder islands must not be flat
green copies of the home plate; the first wow should come sooner. His
ratings: Gezgin 10, Çanlar and Emanet "great", Revontuli 7, Koke 6,
Çömlek 4, Yıldız 3, Leylek 2, Ayna "must change" (full entry in
[founder-input.md](founder-input.md)). This section is the answer; the
sections after it are edited to match.

### 1A.1 Diagnosis: why most concepts read as copies

Seen side by side, eight of eleven concepts share one object: **a lawn
oval on a sandy soil bowl with dangling roots, pebbles and Pofu's round
door**. Only Gezgin (a whale), Çanlar (a spire) and Revontuli (a night
palette) escape it, and they are exactly the three he rated highest. Two
causes, both ours: the brief gave every island the same landform with a
prop on top ("an island *with* an observatory"), and the batch-15 manifest
attached the home island with the role "the same painting, the same
camera, the same scale of a floating island", which the model read as
"the same island". The fix is not more assets; it is a contract (1A.3)
and briefs where **the island is the idea**, not a carrier for it.

### 1A.2 Decision A: one home cluster; İskele becomes Ayçiçeği's harbor

**Decision.** İskele is no longer a separate island. It is **Ayçiçeği's
harbor district**: a pier that grows from the plate's right edge (the
ferry-pier notch the İskele plate already planned) into the cloud sea,
unfolding over the first days. Name in the UI: *İskele*, "Ayçiçeği'nin
iskelesi". It keeps everything the founder liked: Simit and her cart, the
vapur, the postcards, the horn, the sort-puzzle game.

| Option | For | Against | Verdict |
|---|---|---|---|
| **Harbor district on the home plate** | One place, one pan; the Island framing already pans with snap points per station (look round 4), so the pier is one more stop; the vapur docks *at home*, so every visitor and parcel lands where Pofu lives ("everything meets at home"); İskele's emptiness disappears because it shares Ayçiçeği's life | The home plate grows wider (one extra pan stop; a pier edit, not a new plate) | **Chosen** |
| Two islets joined by a rope bridge, same frame | Keeps "a second island" for the map | A second plate to keep in harmony; the bridge is already home stage 5's east islet; still two places | Rejected |
| Keep İskele separate, move it closer and give it more | Least change | Treats the symptom; a free "yield island" is still a +1 island, the exact feeling we are removing | Rejected |

**How it unfolds** (tended days, cumulative): day 1, a lone mooring post
at the right edge and a bell; day 2, the planks and Simit's cart (Simit
moves in; the **sort game** opens: loading the vapur); day 3, the vapur's
first run (the first postcard, and the first rumour object); later, the
lighthouse (home stage 4) and the cargo shed (when the first export good
exists, 1A.4). The harbor's stations (simit cart, pier, lighthouse) stay
yield stations with the same price ladder; the home cluster is the only
place that produces seeds.

**What the vapur becomes.** The archipelago's one ferry: it carries
visitors to the çay ocağı, goods between islands, postcards and rumour
objects, and Pofu himself when he visits a wonder island (the travel
transition is the vapur leaving the pier, then the cloud pass). The map's
routes are its routes. The harbor is the hub's front door.

### 1A.3 Decision B: the uniqueness contract for wonder islands

A wonder island enters production only if it signs this contract.

**The banned template.** No wonder island may use: a lawn oval top, the
soil bowl underside with roots and pebbles, the round door (Pofu's, home
only), a flat lawn as its main surface, or the home palette (honey, sage,
sunflower) as its dominant colours. The home island owns that look; it is
what makes home feel like home.

**The seven axes.** Each wonder island must differ from home **and from
every other island** on at least **three** axes, and **silhouette is
mandatory** among them:

| Axis | Question | Example of a pass |
|---|---|---|
| 1. Silhouette and landform | Filled black at 60 pt, can a child name it? | A whale, a bell spire, a crescent moon, a bonsai |
| 2. Palette | Does a 3-colour swatch alone identify it? | Revontuli's night blue, snow and aurora green |
| 3. Weather and time (its own sky) | Does it have its own climate or hour, independent of home's? | Koke always in soft rain; Mehtap always at blue hour |
| 4. Mechanic | Is its game a different proven verb? | Merge, glide, slide, picross, echo |
| 5. Signature motion | Is there one continuous movement nothing else has? | The whale breathing; the crescent waxing with the real moon |
| 6. Culture | Is it lovingly *from* somewhere, written natively? | Finland, Japan, Cappadocia |
| 7. Scale | Does it break the standard island size or orientation? | The whale is huger than any island; Çanlar is tall and thin |

**Checklist for a concept review** (all yes, or it goes back): the black
silhouette test at 60 pt; the swatch test; none of the banned template;
three axes including silhouette; one sentence lore hook that is a
question; a resident of a new species; the toy's second answer; the game
playable in one round without text; a permanent gift to Ayçiçeği (1A.4);
a scale cue in the painting (Pofu, a door, a person-sized object) so it
reads as a place, not an ornament.

**Rubric (10 points)**, calibrated so the current concepts land on his
ratings:

| Criterion | Points |
|---|---|
| Silhouette and landform (0 = the template; 1 = template plus a big prop; 2 = its own landform; 3 = the island *is* the object) | 0–3 |
| Palette and its own sky (weather, time) | 0–2 |
| Signature motion | 0–2 |
| Heart: resident, story, a verb that is fun | 0–2 |
| Surprise: something never seen in a cozy game | 0–1 |

| Concept (batches 10, 15) | Sil. | Pal. | Mot. | Heart | Surp. | Score | His |
|---|---|---|---|---|---|---|---|
| Gezgin | 3 | 1 | 2 | 2 | 1 | **9** | 10 |
| Çanlar | 3 | 1 | 2 | 1 | 1 | **8** | great |
| Emanet | 1 | 1 | 1 | 2 | 1 | **6** | great (the heart; the plate is the template) |
| Revontuli | 1 | 2 | 2 | 1 | 1 | **7** | 7 |
| Koke | 0 | 1 | 2 | 2 | 1 | **6** | 6 |
| Çağlayan | 1 | 1 | 2 | 1 | 0 | **5** | (not rated) |
| Çömlek | 0 | 0 | 1 | 2 | 1 | **4** | 4 |
| Yıldız | 0 | 2 | 1 | 0 | 0 | **3** | 3 |
| Ayna | 1 | 1 | 1 | 0 | 0 | **3** | must change |
| Leylek | 0 | 0 | 1 | 1 | 0 | **2** | 2 |

**Bars:** 8 or more to enter production; silhouette at least 2 always; a
concept under 6 is redesigned, not repainted. Every redesign in section
11 targets 8+.

**Under the hood this changes the art plan.** The first plan's
five shared landform blockouts become **one blockout per island**
(section 3.3 is updated), built from
a shared camera rig and light, not a shared landform. The camera, light
and painting style stay common (that is the family); the outline never
is.

### 1A.4 Decision C: the living web (islands in parallel)

Islands stop being a ladder (finish one, move on) and become a **web**:
each keeps a job forever, and the home island is where the jobs meet.

**Resolving "local materials" versus "cross-island needs".** The two
ideas conflict only if one thing does both jobs. So there are two things:

| | **Material** (local) | **Goods** (travel) |
|---|---|---|
| What | A counter earned by the island's game: water drops, clay, frost | A named, crafted object made on an island from its material: a jar of falls water, a fired tea bowl, a block of clear ice |
| Where it is spent | Only on its own island's stages and decor (unchanged: each island is played and starts at a fresh zero) | Only by **requests** from other islands and from home; never sold, never converted, never touches the gate |
| How many | Small numbers on that island | **At most three of each** on the harbor's cargo shelf; no counter elsewhere |
| How it moves | It does not | The vapur carries it; loading it is the harbor's sort game |

So material keeps every island a game of its own, and goods make every
island needed by the others, without a shared currency.

**The dependency rule (never a wall).** A wonder island's request may only ask for
goods from islands that arrived **earlier** than the asker; home's
requests appear only once the island they name has arrived. Dependencies point
backward in time, so they always point at islands the player already
owns (also after a lapse in Plus), and no island ever waits for one the
player does not have. Requests fill **stage 4 or 5 extras, decor, and
gifts to home**, never a stage 1–3 step, so a player who ignores old
islands is slowed, never stopped.

**What keeps an old island relevant**, five mechanisms:

1. **Requests.** Each new island asks for goods from two or three older
   ones (Revontuli's sauna wants Çağlayan's falls water for its stones;
   Koke's tea house wants falls water and a Revontuli ice block; Çömlek's
   kiln wants Revontuli's ice to quench and Koke's moss to pack the
   pots). Home asks too, for goods of any island the player has (the
   çay ocağı wants Koke's matcha for Sumi's visit). The older island's
   game is the way to make them.
2. **New pieces in old games.** Every arrival adds one piece or rule to
   one older island's game (after Revontuli, ice blocks appear in
   Çağlayan's channels and slow the boats; after Gezgin, the vapur's
   sort game gets whale-mail sacks). Old games never go stale.
3. **Awake islands.** Each day **two or three islands are awake**: they
   have a request on their noticeboard, a resident visiting home, or a
   weather moment (Koke on a rainy day, Revontuli's aurora night, Mehtap
   at full moon). The choice is deterministic from the date and the
   islands the player has, one awake island is always at least three
   arrivals old, and nothing expires: an open request waits; a sleeping
   island is still fully playable. No checklist of ten islands a day.
4. **Visitors.** The awake island's resident takes the vapur to
   Ayçiçeği and drinks tea at the çay ocağı (Mochi serves each the way
   their culture does: the tea-customs learning thread finally has a
   stage).
5. **Gifts to home.** Every island, at arrival and at stage 5, adds one
   **permanent** thing to Ayçiçeği (table below).

**Each island's permanent gift to Ayçiçeği:**

| Island | At arrival | At stage 5 (the larger gift) |
|---|---|---|
| Çağlayan | A spring that bubbles up beside the pond | **New weather:** morning rainbows over home after calm nights |
| Gezgin | Yosun the tortoise postman lodges at the harbor | **Resident visitor:** Nazlı the whale moors at the pier on full-moon nights |
| Revontuli | A sauna hut at the end of the pier (steam ribbon) | **New weather:** on calm winter nights the aurora reaches home |
| Çanlar | A small bell on the çay ocağı that rings the awake island's motif | **Station upgrade:** the çay ocağı's bell set (every arrived island's motif) |
| Koke | A bamboo water clacker at the pond | **New weather:** rain greens moss on the roof stones; frogs sing in rain |
| Emanet | A lost-and-found box at the harbor | **Station upgrade:** Pofu's den gets a display shelf for every keepsake |
| Mehtap | A tiny brass telescope on the lawn (decor spot) | **New sky:** the real moon phase over home at night, and meteor showers on their real nights |
| Çömlek | Avanos tea glasses and a jug at the çay ocağı | **Souvenir:** a hot-air balloon that drifts past home at dawn on calm mornings |
| Leylek | A stork nest on the windmill cap | **Resident visitor:** a stork pair nests there each spring and autumn, every year |
| Fanus | A glass cloche over a flower on the windowsill | **Station upgrade:** a small greenhouse by the garden that blooms rare flowers in the garden game |

The home island is drawn once; gifts are small edits, sockets and code
effects, so the hub fills up over a year **without changing its simple
outline**: the founder's "simple in design, always changing".

### 1A.5 Decision D: Ayçiçeği always changing

Simple in design (one plate, one outline); never the same two days in a
row. Six layers, each cheap because each is a grade, an overlay, a
particle system or a small edit, never a repaint:

| Layer | How | Cadence |
|---|---|---|
| **Time of day** | The colour script's five hour cells (exists) | Hourly |
| **Weather** | **Simulated by default**: a deterministic daily weather drawn from the date, the hemisphere and a mild climate table (clear, cloudy, light rain, fog, wind; snow only in winter), with fronts lasting one to three days so it feels like weather, not dice. **Real local weather is opt-in later** (WeatherKit, settings only, never during onboarding; coarse location, fetched at most every three hours and cached; falls back to simulated) | Daily |
| **Seasons** | Four edits by real calendar and hemisphere (spring blossom, summer fireflies, autumn leaves, winter snow), plus Koke's micro-season line once Koke has arrived | Seasonal |
| **Events** | A free, recurring calendar: Hıdırellez's wish-ribbon tree (5–6 May), the first snow, the Perseids (around 12 Aug) and Geminids (around 14 Dec), the solstices, the new year's lanterns, Pofu's own anniversary with the player. Each returns every year; its decor stays (A7) | A few a year |
| **Growth** | Stations, stages, decor spots, the harbor's unfolding | Every few days |
| **The web** | The awake island's visitor at the çay ocağı, cargo on the pier, gifts from every island | Daily |

**Weather is flavour, never income.** Rain never pays more seeds or more
rounds; it changes what is beautiful and which island is awake (a rainy
day wakes Koke, a clear night Mehtap). That keeps real weather fair for
someone in a rainy city.

**The daily diff.** Every morning shows **at least one noticeable change**
on home, drawn in a fixed order from the layers above (a visitor, a
weather turn, a bloom, a postcard, a gift). Pofu points at it in the
morning bubble. This is the "never boring" guarantee, and it is
deterministic (A17).

### 1A.6 Decision E: pacing, and where the free part ends

**The curve.** The first wonder island arrives on **day 4** (tended days,
cumulative), with its rumour ladder compressed into the first days: a
sound on day 2, a bottle on the vapur's first run on day 3. After that
the cadence slows gently: **each wait is one tended day longer than the
one before** (4, then 4, 5, 6, 7… days apart), settling at about two
weeks per island once releases set the pace.

| Wonder island | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Tended days | 4 | 8 | 13 | 19 | 26 | 34 | 43 | 53 | 64 | 76 |
| Island | Çağlayan | **Gezgin** | Revontuli | Çanlar | Koke | Emanet | Fanus | Çömlek | Mehtap | Leylek* |

\* Leylek arrives by the calendar (the first spring or autumn migration
after day 26), whatever its place in the order; it is the only seasonal
island.

Why this order: the first wow comes inside the founder's 2–4 days for a
quick player and by day 5–6 for a slow one; **the end of the first week
lands on the best island we have** (Gezgin, his 10), so a week never ends
on an underwhelming island; Revontuli changes the colour world third;
Çanlar needs three islands to have bells for. Between arrivals, the daily
diff on home, the stages of the newest island and the web's requests
carry the days. An engaged player outruns releases near island 5–7; the
fog holds at the third rumour until the next season, while the web and
home keep changing.

**Monetization reconciled.** PR #60's decision was "free: the gate, Pofu,
Ayçiçeği and İskele; Plus opens the further islands, the cut decided by
data". With İskele inside the home cluster, the cut candidates become:

| Cut | Free part | Plus starts at | Day | For | Against |
|---|---|---|---|---|---|
| C1 | The home cluster | Çağlayan | 4 | Clearest promise | A free user never feels a wonder island; the first wow sits behind a wall |
| **C2** | Home cluster + Çağlayan | **Gezgin** | 8 | The free user feels the whole loop, the web and one wonder; the whale arriving as a huge silhouette in the fog is the most honest "want more" we can make | The best island is paid |
| C3 | Home cluster + Çağlayan + Gezgin | Revontuli | 13 | Most generous; retention signal strongest | Two weeks of free play; weaker conversion pull |

**Recommendation:** test C2 against C3 in the friends beta (the signals
of section 10: stage completion, sets per day, return visits, rumour
taps), prior **C2**. The rules of section 10 hold: cut only at an island
boundary, tell the shape from day one, never at the gate, nothing taken
away. If Plus gets a free trial, islands opened in it stay (ADR-0017):
a kept whale is the best advert we have. Gifts to home come only from
islands the player has; a free player's home still changes daily through
the other five layers.

## 2. Research

### 2.1 How other games make places feel like wonder, and how they afford it

| Game | Mechanism | Why it delights | Cost model | Pofu: steal / avoid |
|---|---|---|---|---|
| **Animal Crossing: New Horizons** | Mystery Island Tours from templates; the museum fills room by room | "Where will I land?"; the museum's slow completion | Template islands from shared tiles | **Steal** the museum (Emanet). **Avoid** random tickets and rare draws (A17), and template islands: the founder is right that they feel cheap after the third |
| **A Short Hike** | One hand-made island; the summit visible from everywhere; dense small secrets | The far landmark you will reach later; noticing pays | Tiny team, stylised look hides budget | **Steal** the visible far silhouette (the map's fog) and density over size |
| **Spiritfarer** | Each island one spirit with a story; the boat grows with them | Characters with arcs make places matter | Hand-made, high | **Steal** one resident with a small arc per island. **Avoid** farewells, grind |
| **Alba: A Wildlife Adventure** | One island, a camera, cataloguing animals | The verb is noticing | One dense place | **Steal** noticing and real-world learning (real species) |
| **Cozy Grove** | Ghost bears' stories unlock a day at a time; colour returns as you help; the studio says log off | Grey-to-colour restoration; daily gating | Time-gating stretches content | **Steal** restoration as colour (runtime grade) and "the game tells you to stop". **Avoid** chore lists |
| **Neko Atsume** | Cats visit while the app is closed; mementos | Absence creates the surprise | Small sprite set | **Steal** absence play (Revontuli's ice fishing). **Avoid** rare random cats |
| **Viridi** | Succulents grow in real time; a snail visits | Slow change noticed days later | Very small | **Steal** slow time made visible. **Avoid** paid seedlings |
| **Islanders** | Reach a score and a new island appears | A fresh island is a fresh start | Procedural | **Steal** "a new island" as the reward of finishing one. **Avoid** procedural sameness, score chasing |
| **Townscaper** | Tap and the town answers with arches and gardens | Simple gesture, surprising answer | One clever system | **Steal** the toy. **Avoid** unbounded building |
| **Tiny Glade** | Reactive procedural building, no goals | Discovering the system's quirks is the endgame | Two developers | **Steal** the hidden second answer in every toy |
| **Dorfromantik** | Tiles of a few biomes, quests, later biome packs | Combinations feel endless | Modular | **Steal** that a small **rule set** yields many puzzles (our game grammars). **Avoid** player-visible repetition |
| **Kind Words** | Letters to strangers; paper airplanes | Warmth from a message | Moderation-heavy | **Steal** the bottle that arrives (authored by us). **Avoid** user text |
| **Finch** | A pet goes on adventures and returns with stories | The pet as narrator | 2D, big shop | **Steal** Pofu as narrator. **Avoid** shop clutter |
| **Forest** | Stay off the phone and a tree grows; leave and it dies | Time becomes landscape | Small | **Steal** time as landscape. **Avoid** death (ADR-0017) |
| **Pokémon Sleep** | Islands unlock by cumulative Sleep Dex entries (Cyan Beach at 20 styles, Taupe Hollow at 70…); a morning reveal | Morning reveal; collecting unlocks places | Huge existing asset library | **Steal** cumulative unlocks, the morning reveal. **Avoid** weekly resets, events with FOMO |
| **Stardew Valley** | Bundles restore the town; secret notes; Ginger Island arrives late | Restoration with a list; secrets; a late surprise island | One developer, years | **Steal** restoration chapters, notes as rumours. **Avoid** energy and clock stress |
| **Wylde Flowers** | A serialized story with a mystery across seasons | Hooks pull you to tomorrow | Writing and voice | **Steal** a secret per island. **Avoid** nagging cliffhangers |
| **Sky: Children of the Light** | Seasons of 9–11 weeks add spirits, areas, cosmetics; free with a paid season pass | Music and vistas create awe | Large studio | **Steal** music as the emotional core, places that stay. **Avoid** limited-time items |
| **Ooblets** | Whimsy; disputes settled by dance-offs | Silliness makes a world lovable | Mid | **Steal** whimsy, a playful verb instead of combat |
| **Unpacking** | Story told only through objects | Inference is delight | Object art | **Steal** lore through objects (Emanet, keepsakes) |
| **Monument Valley** | Impossible architecture; paid expansion chapters | The "ah" when geometry turns | Hand-made; premium plus chapters | **Steal** impossible geometry (Mehtap's waxing crescent) and clean paid chapters |

### 2.2 How cozy games make places playable (added for the founder's "turn it into a game")

| Game | Mechanism | Pofu: steal / avoid |
|---|---|---|
| **Animal Crossing: Pocket Camp** | A cozy mobile game with short visits, requests from animals, campsite decor | **Steal** resident requests as the shape of a round; decor as the reward. **Avoid** its timers and paid shortcuts |
| **Hidden Folks** | Hand-drawn scenes, find the hidden things, every tap answers with a sound | **Steal** "every tap answers" and search as a verb (Emanet). Craft at small scale is the whole game |
| **Pikmin Bloom** | Real walking grows flowers; postcards from real places | **Steal** real-world behaviour feeding a gentle world; postcards. **Avoid** event pressure |
| **Duolingo** | Lessons in tiny rounds, a character with a personality | **Steal** rounds of 30–90 s and a learning thread. **Avoid** streak pressure (A19) |
| **Alto's Odyssey (Zen mode)** | The same game with no score, no fail | **Steal** play without failure: island games have no losing state |
| **Mini Metro** | One clear rule set, many calm puzzles | **Steal** one readable rule set per island game, deepened by stages |

### 2.3 Markets: why idle games come from the East, and what that means for Pofu

- **The numbers.** Korea is the strongest RPG market (about 58 % of its
  mobile revenue), and idle RPGs there grew from 1.7 % to 4.4 % market
  share between 2019 and 2023. Idle RPG revenue concentrates in Japan and
  Korea: Pixel Hero earns about 32 % in Japan and 29 % in Korea; Legend of
  Mushroom gets about 70 % of its purchases from those two countries.
- **Why there.** Mobile-first play, long commutes, tolerance of auto-play,
  hardware-light design, and (reported for Korea) a taste for cute
  characters and less aggressive monetization. Japan also has the cute
  care lineage: Tamagotchi, Neko Atsume, Pokémon Sleep.
- **The catch.** Most of that revenue is gacha. Pofu refuses gacha (A6,
  A17), so its edge there is cuteness, calm and craft, not monetization.
- **Europe and the Nordics.** Higher willingness to pay for
  subscriptions and a strong digital-wellbeing culture; the "why" of Pofu
  lands there more than the "idle".
- **For the archipelago.** Islands from many cultures, each written
  natively by someone from there (the content idea
  `idea-route-regional-islands`): a Finnish aurora island, a Japanese
  moss garden, a Mediterranean stork island next to the çay ocağı. The
  home stays Turkish; the sky belongs to everyone. Recommendation: after
  Türkiye, test **Japan** (cute-care affinity) and **the Nordics**
  (wellbeing, purchasing power) before a broad English launch, each with
  one native island (open question 9).

### 2.4 Lessons

1. **Wonder is anticipation plus a reveal**, not a bigger number.
2. **A place needs one thing nothing else does**: one signature motion
   and one verb per island, never reused in view.
3. **Toys delight; games return.** Pofu needs both: a toy for ten seconds,
   a game for a few minutes.
4. **Absence is the best surprise engine.** Arrivals, rumours and some
   games (ice fishing) work while the phone is down.
5. **Craft must be visible; reuse must not.** The founder's rule. Reuse
   lives under the hood: rule sets, motion engines, rigs, sockets.
6. **Randomness is where cozy turns into casino.** Fixed orders,
   deterministic rewards; timing varies only with the user's behaviour.
7. **Paid content works when it is clearly "more", never "the rest"**,
   and when nothing already earned is taken away.

## 3. The island schema

Every island is described by the same fields: the brief a designer fills
in and the checklist a reviewer uses.

| Field | What it is | Rules |
|---|---|---|
| **Kind** | `home` (Ayçiçeği with its harbor: stations, seeds) or `wonder` (a game, a secret; everything after). A wonder island may be a `wanderer` (it moves) or `seasonal` (Leylek) | Only home produces seeds |
| **Origin** | The culture or place it is lovingly from, and who writes it | Native writer; never a postcard cliché |
| **Biome and feel** | One line: "a spring that never stops", not "water island" | Distinct from every earlier island |
| **Colour key** | Two or three dominant palette colours | Art bible palette; runtime grade can shift it |
| **Silhouette** | What reads at map scale (about 60 pt) | Never repeated; the uniqueness contract (1A.3) |
| **Its own sky** | The island's climate or hour, independent of home | One of the contract's axes |
| **Goods and requests** | The good it makes from its material; the goods it asks for | Requests point only to earlier islands (1A.4) |
| **Gift to home** | What it adds to Ayçiçeği at arrival and at stage 5 | Permanent; a small edit, socket or code effect |
| **Signature motion** | One continuous movement it owns (section 8) | Code over paintings; never reused |
| **Lore hook** | One sentence that raises a question | Asked by the first rumour, answered by stage 5 |
| **Secret (stages)** | Five stages, each an edit of the whole plate and a chapter | Each stage also deepens the game (a new piece, rule, or place) |
| **Resident** | One character with a small arc | Base plus two pose edits; never a species twice |
| **Toy** | One gesture, one answer, a hidden second answer | Ten seconds; earns nothing |
| **Island game** | A verb, a rule set, rounds of 30–90 s, no failure (section 4) | Built on a shared grammar, skinned and ruled uniquely |
| **Learning thread** | One real thing taught per stage or set | True, sourced, culturally native |
| **Material** | The island's own world material | Local, non-convertible, never touches the gate |
| **Decor spots** | Three to six sockets and the families they accept (section 5) | Open with stages |
| **Contribution to the loop** | `none`, `echo` (a cosmetic effect elsewhere), `ritual` (once a day, earned by calm), or `yield` | No seeds, calm, wellbeing or speed from a wonder island |
| **Unlock trigger** | Cumulative tended days, calm nights, a heard rumour ladder, a release, a tier | Monotonic, never consecutive (A4, A19) |
| **Rumour ladder** | Three rumours: a sound, an object, a sight | Fixed order, progress-driven, never dated |
| **Arrival choreography** | The 15–20 s reveal (section 3.2) | Its signature motion starts on camera |
| **Sound motif** | Three to five notes plus an ambient bed | Heard first from the fog; joins Çanlar's bells |
| **Keepsake** | One object for Pofu's shelf at stage 5 | Fixed, named, never random |
| **Art budget** | Image count by type | Section 3.3 |
| **Tier** | Free or Plus (section 10) | Cut only at island boundaries |

### 3.1 The toy (ten seconds, pure play)

One gesture (tap, drag, flick), an answer in 2–6 seconds with motion,
sound and a resident's reaction, and a hidden second answer found on the
fifth play or by doing it differently (Tiny Glade's lesson). No score,
no counter, no reward. The toy is always free to play, also outside
rounds and inside "A minute with Pofu" (app-game-boundary §3.3).

### 3.2 The arrival moment

| Beat | What happens | Time |
|---|---|---|
| 0. The night before | Nothing. Nights are a dead end (A21); the island arrives in the night | — |
| 1. Morning bubble | Pofu, delighted, refers to the last rumour: "Did you hear the water last night? Look!" One action: "See it" | 2 s |
| 2. Cloud pass | ADR-0018's one cinematic move, toward the island's place on the map | 1.2 s |
| 3. First motion | The island is still; then its signature motion starts on camera for the first time; the motif from the fog plays complete | 3–4 s |
| 4. Resident | One line | 2 s |
| 5. Toy | Glows once; one touch answers | 0–5 s |
| 6. First page | A painted `CelebrationCard` with the lore hook as a question, and "Play" (the first round is a free tutorial) | 3 s |
| 7. Done | "All caught up", or the first round if the user taps Play | — |

Played once, skippable from beat 2.

### 3.3 Art budget: craft visible, reuse invisible

The founder's rule: every island must read as hand-made and unique; kits
are fine under the hood. A wonder island targets **12–16 images**:

| Item | Images | Reuse under the hood |
|---|---|---|
| Plate | 1 | Painted from **its own blockout** (a Blender grey box) in the shared camera rig and light, so the camera and light never drift and the outline is always new (1A.3) |
| Stage edits | 4 | Each an edit of the plate ("add the rope bridge; change nothing else") |
| Resident | 3 | Base plus two pose edits; expressions by the face-kit method |
| Game pieces | 2–4 | Small props on one sheet; the rule set is code |
| Decor items native to the island | 1–3 | Each fits a decor family usable on every island |
| Keepsake | 1 | — |

What makes 50 affordable without anything looking reused:

| Under the hood | Visible result |
|---|---|
| **Motion engines** (a fluid ribbon, a particle emitter, a damped swing, a flock on a spline, a grade cycle) retuned per island | A waterfall, steam, bells, storks, an aurora: never the same thing twice |
| **Game grammars** (about eight rule engines, section 4.3) | Each island's game has its own pieces, rules and story |
| **One camera rig and light** (a blockout per island) | Consistent camera and light; every outline different |
| **Resident rig** (base, two poses, face kit) | Every resident a new species and personality |
| **Decor families** (sockets by shape) | A chair bought on İskele also fits Koke's porch |
| **Runtime grade** | Night, seasons, restoration from grey to colour without repaints |

**The rule for reviewers:** the player must never see the same
silhouette, motion, resident species, game skin or decor item native to
two islands. If they do, the island is not finished.

## 4. Island games: one core loop, a different game on every island

### 4.1 The core loop (shared)

```
 resist a reach / quiet hours / calm nights
            │  earn
            ▼
        play rounds ──────► the island's game (30–90 s a round, no failure)
                                   │ yields
                                   ▼
                    the island's material (+ a few seeds)
                                   │ opens
                                   ▼
          the next stage: a chapter of the secret, a deeper game,
          a new decor spot, one real thing learned
```

**Resisting earns the round; playing it is the reward.** That keeps the
gate the source of everything (A9: looking earns nothing), and makes
play the healthy substitute at the moment of a skip.

### 4.2 Rounds (TR *tur*)

| Rule | Default (illustrative) |
|---|---|
| Daily baseline | 2 rounds a day, for everyone, so a heavy scroller still plays (behaviour changes how much, never whether) |
| A resisted reach | +1 round, at most 6 a day |
| A calm night | +1 round |
| A quiet afternoon (3 observed calm hours) | +1 round |
| Banking | Rounds never expire (A2), but **at most 12 are played a day**; the rest wait for tomorrow |
| A set | Five rounds make a set (about 4–6 minutes); a set ends with a story beat and "Enough for today?" |
| Plus | Never sells rounds, never more rounds a day (that would sell time in the app) |

A round takes 30–90 seconds, so the daily maximum is about 10–15
minutes of play; a typical user plays one set a day, about 5 minutes.

### 4.3 Game grammars

Under the hood, about eight rule engines. Each island instantiates one
with its own pieces, rules, art and story, and each stage adds a twist,
so the game deepens as the secret unfolds.

| Grammar | The verb (proven model) | Island |
|---|---|---|
| **Fit** | Place shapes, clear rows (Block Blast) | Ayçiçeği (the garden) |
| **Sort** | Sort by kind (Goods Sort) | The harbor (loading the vapur) |
| **Route** | Rotate pieces to connect (Flow, Pipe) | Çağlayan (leaf boats) |
| **Slide** | Slide blocks to clear a path (Rush Hour) | Gezgin (cloud banks) |
| **Patience** and **Trace** | Put the phone down; draw a stroke | Revontuli (ice fishing; the aurora) |
| **Echo** | Repeat a phrase (Simon) | Çanlar (bells) |
| **Match** | Match in threes, no fail bar (Triple Tile) | Koke (moss stones) |
| **Deduce** | One puzzle a day from clues (Wordle's shape) | Emanet (who lost this?) |
| **Picross** | Fill the grid from edge numbers | Fanus (fogged panes) |
| **Merge** | Merge into larger (Suika) | Çömlek (pots) |
| **One stroke** | Draw without lifting the finger | Mehtap (constellations) |
| **Glide** | Dip and rise on hills or air (Tiny Wings) | Leylek (thermals) |

No verb repeats between two islands (the contract's mechanic axis); the
mapping follows [minigames.md](minigames.md) §8, extended to the new
islands. Serve (tea orders) lives on as the visitors' tea at the çay
ocağı, not as a round game.

Rules for every island game:

1. **No failure.** A round always ends well; skill earns a little more
   material (a deterministic bonus, never a random one).
2. **Readable in one round.** One rule, shown by doing; text only for
   the learning card.
3. **Deepens with stages.** Stage 2 adds a piece, stage 3 a rule, stage 4
   a place, stage 5 the secret's twist.
4. **Learning thread.** Most sets end with one real thing: a star's name
   in three cultures, the Japanese micro-season of the week, how a stork
   finds a thermal, how tea is drunk in five countries. True, short,
   written natively.
5. **Plays offline, ends on its own,** and is fully accessible (VoiceOver
   labels, no timing-critical input, Reduce Motion variants).

### 4.4 Materials

Each wonder island has **one** material, earned only by its game and
spent only there, on its stages and decor: water drops on Çağlayan, star
dust on Mehtap, clay on Çömlek, frost on Revontuli, moss on Koke. Seeds
stay the universal material (home, stations, and a small seed
part of every stage cost).

- **Why not one currency:** a single pool lets a rich home island buy a
  new island's whole secret in one visit. Local materials mean each
  island is **played**, and each new island starts at a small, legible
  zero.
- **Guardrails:** materials never touch the gate (A13 extends to them),
  never convert into seeds or each other, are never sold, and are shown
  only on their island.

## 5. Decor spots (TR *köşeler*)

Besides fixed stations (the çay ocağı is certain; its style is ours),
every island has **three to six decor spots**: sockets in fixed places
where the player chooses what goes. Sockets, not free placement, so the
art stays composed and the camera fixed (an amendment to ADR-0016's
"never the placement").

| Spot family | Where | Example items (and what they do) |
|---|---|---|
| **Ground** | A level patch of lawn | A hammock between two trees (a resident naps there at noon); a tiny telescope (at night it points at Mehtap); a sunflower-seed bird table (a specific bird visits) |
| **Hanging** | A branch, an awning, an eave | A wind chime that plays the island's motif at golden hour; a string of lanterns that light on calm nights; a nazar-blue glass mobile |
| **Water** | A pond edge, a spring, a pier | A floating lantern; a toy sailboat that drifts on its own; a bamboo water clacker from Koke |
| **Sky** | A post above the island | A kite whose tail grows on calm days; a weather vane shaped like Pofu; a paper lantern balloon |
| **Wall** | Beside a door or a station | A little mailbox where residents' notes arrive; a shelf for one keepsake; a hand-painted sign in the island's script |
| **Seat** | Facing the view | A bench where a visiting resident sits and reads; a pouf; a sauna bench from Revontuli |

Rules: items come from island stages, games' milestones, wishes,
keepsakes, seasons and Plus cosmetic sets; any item fits any spot of its
family on any island (cultures meet: a Japanese lantern on the Turkish
pier); swapping is one tap; every item has a tiny behaviour, because
living decor is more charming than furniture; decor never produces
anything. Art: one image per item, drawn in the fixed view.

## 6. Play time without a new reflex: a revised session guardrail

The founder believes 5–10 minute play sessions are fine: "at worst you
are playing a game instead of doomscrolling". The current guardrail
(median visit under 90 s; Pofu opens outside Hop! below reaches; A10,
A20) was written for a game with nothing to play. I agree with him **on
one condition**: we must be able to tell deliberate play from a new
reflex, and we must measure it.

### 6.1 The argument

What makes a feed harmful is not minutes. It is four things together:
**reflexive entry** (the thumb goes before the decision), **no end**
(infinite scroll), **variable reward** (the next one might be great), and
**nothing earned** (it costs no effort, so it fills every gap). A
finite, deliberate, earned game of five minutes has none of the four.
Swapping 40 minutes of Reels for 5 minutes of raking a moss garden is the
product working, and it is the healthy substitute the decision audit
asked about. The danger is the other direction: Pofu itself becoming the
thing the thumb reaches for. So the rules separate **visits** (short,
reflex-safe) from **play** (deliberate, finite) and measure the reflex
directly.

### 6.2 Proposed rules (amend A10 and A20; add A22–A26)

| # | Rule |
|---|---|
| **A10′ Two kinds of time** | A **visit** (collect, look, build) keeps the old budget: median ≤ 90 s. A **play session** (rounds) may last 5–10 minutes and ends by itself after a set. Total Pofu foreground: median ≤ 12 minutes a day, p90 ≤ 20 |
| **A20′ The world waits while you play** | During rounds the world clock is paused: playing never grows the island faster than being away. Outside play, the 2-minute rule stays |
| **A22 Play is earned and finite** | Rounds come from behaviour plus a small baseline; at most 12 played a day; no endless mode, no score chase, no leaderboard |
| **A23 Play is entered on purpose** | Opening Pofu lands on Home, never in a game. Play starts from an island's "Play" door. No auto-start, no "next round" countdown |
| **A24 Natural ends** | Every set ends with a story beat and "Enough for today?"; after the daily cap the games rest ("the tea's all served"), and toys still answer |
| **A25 The substitute moment** | After a resisted reach, Hop! may offer one round, once ("Play a round with Mochi instead?"). Never after an open, never at night |
| **A26 Reflex watch** | If the rules below are breached for a week, the daily cap drops automatically (12 → 8 → 5 rounds) for that user, and the founder's dashboard flags it |

### 6.3 What we measure

| Signal | Healthy | Why |
|---|---|---|
| Pofu opens outside Hop! per day | Below resisted reaches (kept from the decision audit) | The app must not out-pull the feed it replaces |
| **Reflex opens**: Pofu opens under 10 s with no action | Low and falling week over week | The signature of a checking habit |
| Play minutes per day | At most a third of the guarded minutes saved against the user's baseline | Play is a dividend of quitting, not a new sink |
| Play sessions per day | Median ≤ 2 | Deliberate play, not grazing |
| Longest session | p95 ≤ 15 minutes | Natural ends work |
| Opens of a guarded app right after a play session | Not higher than after a visit | Play must not prime the scroll |

This is a direction change (from "interrupter only" to "interrupter plus
a bounded game") and touches accepted rules, so it should be recorded in
an ADR after the founder's dogfood week, with these thresholds.

## 7. Progression with small numbers

### 7.1 Can a progression feeling come out of small numbers?

Yes. Every seed is legible (at 15 a day, "+1 for that skip" is a seed
you watch land); the world is the progress bar (stages, games that
deepen, decor, the map, Pofu's shelf); and nothing inflates, so a price
of 150 in month 6 means what it meant in week 3.

### 7.2 Roblox-style proportional scaling, evaluated

The founder's musing: early upgrades cost 100 and take 5 minutes to earn;
late ones cost a million and you earn a million in 5 minutes. He doubted
it fits. He is right, for three reasons:

1. **Income is real behaviour, and behaviour is capped.** A day has a
   fixed number of quiet hours and resisted reaches. Exponential income
   would have to come from multipliers on buildings, so the morning
   number would reflect stations, not calm. The link between "I put the
   phone down" and "my island grew" is the whole product.
2. **Big numbers are a currency mindset.** ADR-0015 removed prices from
   the gate precisely because numbers turned the emotional moment into
   math. Millions would bring the math back.
3. **Proportional scaling is a treadmill by design.** Its feeling of
   progress comes from numbers outrunning numbers, which needs ever-new
   tiers to stay alive: the content treadmill in another form.

What Roblox scaling gets right is that **every tier feels fresh, and
early effort is not dwarfed by late effort**. Pofu gets that from
**per-island materials**: every new island starts at a small, legible
zero with a new verb, so island 20 feels like island 2 felt, without any
number growing. **Recommendation: flat small numbers plus per-island
materials.** Prices stay 5–200 on every island, forever.

### 7.3 Income (illustrative, for the economy pass)

| Source | Scale A proposal | Typical user, week 1 → day 60 |
|---|---|---|
| Pofu's quiet gathering | 1 seed per quiet waking hour, at most 8 a day | 6 → 7 |
| A resisted reach | +1 seed (and +1 round), at most 6 a day | 6 → 6 |
| A calm night | +2 seeds (and +1 round) | about 1.3 a day |
| Stations (home and harbor) | 0.6 seeds a day per station level at calm ×1.0, × calm, only while no guarded app is open | 1 → 23 |
| **Seeds total** | | **about 15 → 37 a day**; saturates near 40 |
| Rounds | Section 4.2 | about 7 → 8 a day earned; a typical user plays 5 |
| Island material | About 4 a round (+1 for a good round) | About 20 a day on the island in play |

A skip is a large share of seed income at this scale (about 40 % on day
1, 16 % by day 60); the cap keeps it from being a reason to trigger the
gate, and the economy pass should check it.

### 7.4 Prices (illustrative)

Yield ladders (seeds):

| | L1 | L2 | L3 | L4 | L5 |
|---|---|---|---|---|---|
| Sunflower garden | built | 5 | 9 | 15 | 25 |
| Çay ocağı | 8 | 14 | 24 | 38 | 60 |
| Lily pond | 15 | 25 | 40 | 60 | 85 |
| Workshop | 30 | 50 | 75 | 105 | 140 |
| Windmill | 50 | 80 | 110 | 150 | 190 |
| Simit cart | 25 | 40 | 60 | 85 | 115 |
| Ferry pier | 40 | 60 | 85 | 115 | 150 |
| Lighthouse | 60 | 85 | 115 | 150 | 200 |

A wonder island's stages: material 20 · 40 · 60 · 80 and seeds 15 · 25 ·
35 · 50 for stages 2–5, with at least 2, 5, 9 and 14 tended days since
arrival, so a secret unfolds over about two weeks for anyone. Decor
items: 10–40 of the island's material.

### 7.5 What grows, at each timescale

| Timescale | What the user feels growing |
|---|---|
| Every visit | The morning number, Pofu's mood, one noticed change |
| Every day (if they play) | A set: material, a story beat, maybe a learning card |
| Every 2–3 days | A build: a station's next level |
| Every week | An island stage: the island changes shape, its game deepens, a decor spot opens |
| Days 4, 8, 13, 19… then about every two weeks | A rumour ladder, then an island: the full arrival (1A.6) |
| Every season | New islands for the season; the archipelago changes clothes |
| The long arc | The map clears from fog; Pofu's shelf fills; decor across islands tells the user's own story; Çanlar's bells learn one more motif per island |
| Pofu himself | Gifts that stay: Simit's scarf, a ferry ticket in his cheek pouch, a satchel badge per island, a lantern from Mehtap; his den behind the round door gets a shelf |

### 7.6 The first 60 days for a typical user

Revised 2026-11-03 (pacing in 1A.6). About 10 reaches resisted a day,
average calm, a Plus member. One or two short visits a day and one play
set on most days. Days are tended days.

| Day | What happens | Feeling |
|---|---|---|
| 1 | The island wakes with the first gate catch. Garden L2. The garden game's first round. A mooring post and a bell at the right edge. About 15 seeds | "I did something, and someone noticed." |
| 2 | The harbor's planks; Simit moves in; the sort game. Morning: "Did you hear water last night?" (rumour 1) | "Home is getting bigger." |
| 3 | The vapur's first run: the first postcard and a bottle ("the water never stops here", rumour 2); the lighthouse beam catches a mist rainbow (rumour 3). First rain on home (simulated weather) | "Wait, what was that?" |
| 4 | **Çağlayan arrives**, the waterfall starts on camera; Damla; leaf boats; a spring bubbles up beside home's pond | **Whoa 1** |
| 5–7 | Çağlayan stages 2–3; Damla visits the çay ocağı; the first daily diffs (a fog morning, a frog chorus); a whale-sized shadow under the fog on the map | |
| 8 | **Gezgin**: the map's edge moves; a sleeping whale with a cottage on her back. Yosun lodges at the harbor | **Whoa 2**, at the end of week one |
| 9–12 | The first request: Gezgin's cottage asks for a jar of falls water; old island, new reason. A leaf boat sent over the falls on day 5 washes up on the pier | "Everything is connected." |
| 13 | **Revontuli**: the first night-blue world; Tuli; ice fishing | **Whoa 3**: a new colour world |
| 14–18 | Çağlayan stage 5: morning rainbows at home after calm nights. Revontuli's sauna wants falls water; ice blocks appear in Çağlayan's channels | Closure, a new question |
| 19 | **Çanlar**: a spire of bells, one per island so far; a small bell on the çay ocağı | **Whoa 4** |
| 20–25 | A free calendar event if one falls here; the full moon brings Nazlı to the pier | |
| 26 | **Koke**: a bonsai in the rain; on rainy days at home, the frogs sing | **Whoa 5** |
| 34 | **Emanet**: things you never knew were lost come home | **Whoa 6** |
| 43 | **Fanus**, if season 1 has shipped; otherwise the fog holds at its third rumour while the web and home carry the days | **Whoa 7** |
| 44–60 | Stages, requests and awake islands; Gezgin stage 5 (the whale moors on full moons); the first migration may bring Leylek | One open question, always |

## 8. Signature motion: what code can do

The world already has `TimelineView`, `Canvas` particles, a runtime
grade, a depth lens and a Metal `layerEffect` (the terrarium rim,
look-dev §C). Every signature motion is built from those over still
paintings.

| Motion | Technique | Island |
|---|---|---|
| A waterfall pouring off the edge into the clouds | A painted ribbon masked to the fall; a `layerEffect` scrolls two noise layers down it; `Canvas` mist where it meets the clouds; a mist rainbow at golden hour | Çağlayan |
| Condensation on a glass bell jar, wiped by a finger | A `layerEffect` droplet field over the glass rim shader; the touch path clears it and it beads back | Fanus |
| An aurora painted by a fox's tail | A `layerEffect` curtain of two noise fields in green and violet, its shape driven by the last tail stroke the player drew | Revontuli |
| Steady rain on a bonsai; rings on the gravel pond; a bamboo clacker | `Canvas` rain and ring particles; a damped spring on the bamboo | Koke |
| An island on the back of a breathing cloud-whale | Whole-plate scale and offset on a slow sine; a blowhole spray that makes a small rainbow; the map position moves at night only | Gezgin |
| Bells that swing and ring | Each bell a layer on a damped spring; ropes as curves; sound per bell | Çanlar |
| A nest carried by a flock | A flock on splines with ribbon curves to the nest; the nest swings on a damped pendulum | Leylek |
| Balloons rising at dawn; a kiln that glows like a lantern | Balloon sprites on slow paths; the kiln windows' glow breathes with calm | Çömlek |
| A crescent island that waxes and wanes with the real moon | The computed moon phase drives a mask over the painted moon | Mehtap |
| Things floating home on the cloud current | Keepsake sprites drift along a curve and settle on a shelf | Emanet |

Cost at rest stays near zero (look-dev §B): full rate only while that
island is in the Island framing, about 15 fps while visible on the map,
a settled frame otherwise. Reduce Motion turns each into a still painting
with one gentle transition.

## 9. The endless structure

### 9.1 Fifty hand-made islands

No procedural or kit-built islets: the founder's rule, and the right
one. The system goes on as **a steady run of hand-made wonder islands**,
arriving in seasonal updates, each with its own secret, game and small
story.

| Question | Answer |
|---|---|
| How many? | A design horizon of **50**: enough for four years at about 12 a year. The template, rumours and map have no end, so the run can continue if it is loved |
| How often? | A season (about 13 weeks) brings **three islands**: one big (a wanderer or a showpiece motion), two smaller. Each ships only when it passes the whoa test |
| Can a small team make one in ~3 weeks? | With the reuse in section 3.3 (blockouts, motion engines, grammars, rig, decor families) and the art pipeline (Codex under the art bible): one plate, 4 edits, a 3-image resident, 2–4 game pieces, 1–3 decor items, a keepsake, one grammar instance with new rules, a motif, about 30 lines of story and learning cards. Yes, if the grammars exist first |
| Will users run out? | Each island's stages need at least 14 tended days, and arrivals follow the user's own tended days, so an engaged user meets islands on the 1A.6 curve (days 4, 8, 13, 19, 26…) and then about one every two weeks. Twelve a year matches that later pace; launch ships five to cover the fast first month; a slower user has a backlog and never runs dry |
| What fills the gaps? | Rumours (always one open question), seasonal edits, each island's game (sets keep yielding material for decor), decor spots, wishes, Mehtap-like rituals, the living web (1A.4) and the home island's daily diff (1A.5) |

### 9.2 The sky map: rings and fog

| Ring | Contents | Visible as |
|---|---|---|
| Inner | Ayçiçeği and its harbor | Clear |
| Middle | Wonder islands as they arrive | Fog that recedes with every arrival |
| Outer, "Uzak Sular" (the far waters) | Islands to come; the wanderer's route | Fog with lights, sounds, silhouettes (rumours) |

The fog is the map's collection: it only recedes. It never shows an
empty slot, a count of islands left, or a date.

### 9.3 The curiosity engine: rumours

| Rung | Sense | Example (Çağlayan) | Carried by |
|---|---|---|---|
| 1. A sound | Its motif, faint, from the fog; Pofu mentions it in the morning | "Did you hear water last night?" | Morning bubble; the fog shimmers |
| 2. An object | Something arrives: a bottle, a feather, a leaf, a lost hat | A bottle: "the water never stops here" | The vapur, on the home harbor's pier (hand-painted, one per island) |
| 3. A sight | A silhouette, a light, a rainbow at the map's edge | A mist rainbow caught by the lighthouse beam | The map's outer ring |

Rumours advance with the next island's cumulative arrival conditions (a
third, two thirds, then all but the release), so the timing varies with
the user's life and stays deterministic (A17).

- A rumour never names a date, never counts down, never says "soon",
  never expires.
- At most one per visit, never with an arrival or a stage.
- If the island waits for a release, the ladder holds at rung 3.
- Heard rumours are listed on the map's "Söylentiler" page.
- For Plus islands, see section 10.

### 9.4 The myth

"The sky sea is full of islands that drifted apart when the world got
loud. **Islands drift toward quiet.** When it is calm long enough, they
hear it and come home." (TR *Adalar sessizliğe yanaşır.*) Never an
exposition dump: Pofu says it once, on the vapur's first run; Çanlar's bells
and Kitap's archive explain it; it is true to the mechanics, because the
user's calm is what brings the islands.

## 10. Monetization: how the system carries Plus

**Decided (PR #60, founder-approved):** free is the gate, Pofu,
Ayçiçeği and İskele (since 2026-11-03 one home cluster; cut candidates in
1A.6); Plus (349,99 TL a year, 999,99 TL lifetime) opens
the further islands. This amends ADR-0016's "Plus never sells islands";
the amendment is clean only because **wonder islands produce nothing**:
paying never buys seeds, calm, wellbeing, speed, rounds or time.

The founder wants the cut point decided by data and is not sure users
must know it in advance. Recommendations:

1. **Cut only at island boundaries.** Never in the middle of an island's
   secret, game or stage. A user never loses access to a game they have
   started.
2. **Tell the shape, not the number.** From onboarding and the App Store
   page: "Ayçiçeği and İskele are free forever; more islands come with
   Plus." Users need not know which island number is the line, but they
   must never feel tricked (and Apple's subscription rules expect the
   paid content to be described clearly).
3. **Let data place the line, within those rules.** In the friends beta,
   instrument the "happy and want more" signals per island: stage
   completion, sets played per day, return visits to the island, rumour
   taps, decor placed, and the founder's Hub feedback. The line belongs
   just after the island where completion and return visits peak. Test
   **C2 against C3** (1A.6), prior C2: the first wonder island free
   (Çağlayan), because a free user who has never played a wonder island
   does not know what Plus is, and the whale arriving at the line is the
   honest "want more".
4. **Rumours are the honest "want more".** Rumours play for everyone. A
   free user sees the Plus island arrive as a silhouette that clears from
   the fog, with one card, once ("Çağlayan came close. It opens with Pofu
   Plus."). After that the island waits quietly on the map; no repeat
   prompts, no countdowns.
5. **Never at the gate.** No paywall on the shield, Hop!, a breath, the
   emergency pass, or the morning a free island grows.
6. **Nothing is taken away.** A lapsed member keeps every island, stage,
   decor item and keepsake they unlocked, and can still play those
   islands' games; only new stages of Plus islands wait (ADR-0017).
7. **The free game stays whole.** The home cluster with its two games,
   the harbor, decor spots, postcards, rumours, weather, seasons, events,
   and (in C2) Çağlayan: a complete game, not a demo.

## 11. Island concepts

Revised 2026-11-03 (section 1A). One home cluster and ten wonder islands.
Kept: Çağlayan, Gezgin, Revontuli, Çanlar, Emanet, each with a stronger
silhouette. Redesigned: Koke, Çömlek, Leylek, and Yıldız as **Mehtap**.
Replaced: Ayna by **Fanus**. Every wonder island signs the uniqueness
contract (1A.3); the "Axes" column lists the axes it changes against
home.

| # | Island | The island *is* (silhouette) | Palette · its own sky | Signature motion | Game (proven verb) | Gift to home | Axes |
|---|---|---|---|---|---|---|---|
| — | **Ayçiçeği** + harbor | Home: the lawn oval, sunflower, round door, a pier into the clouds | Honey, sage, sunflower · real time, simulated or real weather | The giant sunflower follows the real sun | Garden block puzzle; at the harbor, sorting cargo onto the vapur | — | — |
| 1 | **Çağlayan** | A stack of white travertine terraces; the fall pours off the lowest one, longer than the island is tall | Travertine cream, turquoise, mist white · late morning, mist rainbows | The waterfall into the clouds | Path-connect: leaf boats | Spring; morning rainbows | sil, pal, mot, scale |
| 2 | **Gezgin** | A cottage on the back of a sleeping cloud-whale | Grey-blue, cream, dandelion · moonlit when travelling | The whale breathing; it moves at night | Slide puzzle: clear cloud banks for the whale | Yosun; the whale moors on full moons | sil, mot, scale, mech |
| 3 | **Revontuli** | An ice floe: a clear blue-white ice shelf, a single spruce, a sauna, a fishing hole | Night blue, snow, aurora green · always a winter night | An aurora painted by the player's stroke | Ice fishing (patience) and aurora painting (trace) | Sauna; winter aurora at home | sil, pal, sky, culture |
| 4 | **Çanlar** | A tall, thin stone spire hung with bells | Bronze, sky blue, poppy · windy bright noon | Bells on damped springs | Simon echo | The çay ocağı's bell set | sil, scale, mot, mech |
| 5 | **Koke** | A great bonsai pine whose roots cradle a moss and gravel garden; the tree is larger than the land | Deep moss, wet slate, one maple red · always soft rain | Rain rings on the raked gravel pond; the clacker | Tile matching (three moss stones) | Water clacker; rain greens home | sil, pal, sky, culture |
| 6 | **Emanet** | An office on stilts built out of lost things: an upturned umbrella roof, a teacup water tank, a hat for a chimney | Weathered teal, brass, brown paper · overcast, lamplit | Lost things floating home on the cloud current | Daily deduction | Den display shelf | sil, pal, mech |
| 7 | **Fanus** | A glass bell jar floating in the sky with a tiny cloud forest inside | Emerald, glass teal, orchid pink · warm rain inside, clear sky outside | Condensation that beads, runs and is wiped by a finger | Picross: wipe the fogged panes | Greenhouse by the garden | sil, pal, sky, mech |
| 8 | **Çömlek** | A cluster of Cappadocia fairy chimneys; the tallest is hollowed into a glowing kiln | Rose tuff, ochre, dawn apricot · always dawn, balloons rising | Hot-air balloons rising past; the kiln's glow breathing | Merge: clay into larger pots | Avanos cups; a dawn balloon | sil, pal, sky, culture |
| 9 | **Mehtap** | A sleeping crescent moon resting in the clouds, an observatory in its inner curve, a ladder to its tip | Indigo, moon silver, pale gold · always blue hour | The crescent waxes and wanes with the real moon | One-stroke constellation drawing | Telescope; the real moon over home | sil, pal, sky, mot |
| 10 | **Leylek** | A giant woven nest carried across the sky by a V of storks on ribbons | Straw gold, white, black, sunset coral · warm windy dusk, Saharan haze | The flock flying, the nest swaying | Glide on thermals (Tiny Wings) | A stork pair nests on the windmill each migration | sil, pal, mot, scale |

Kaplıca (the hot spring) and Kitap (the library) stay in the pool and
must pass the contract before they are briefed (Kaplıca as a steaming
teacup-shaped caldera; Kitap as an island that is an open book whose
pages are terraces). Arı (bees) stays a candidate.

### 11.1 Ayçiçeği, home, with its harbor (yield, free)

Pofu's sunflower island; warm honey, sunflower yellow, sage. The only
island with the lawn oval, the soil bowl and the round door: that look
*is* home. Signature: the giant sunflower (garden L5) follows the real
sun. Lore hook: "What is behind the little round door?" (Pofu's den,
which fills with keepsakes.) Residents: Pofu, Mochi, Fındık, the frogs,
and Simit at the harbor. **Toy:** boop Pofu; three fast boops and he
sneezes a seed off the edge into the clouds. **Games:** the garden block
puzzle ([minigames.md](minigames.md)); at the harbor, sorting cargo onto
the vapur. **Always changing** (1A.5): time, weather, seasons, events,
growth, the daily visitor and the gifts of every island (1A.4). Decor
spots: the çay ocağı's awning, the lawn, the pond edge, the door, the
pier's end. Motif: a hummed four-note lullaby every later motif
harmonises with.

### 11.2 İskele, Ayçiçeği's harbor (a district of home, free)

No longer an island (1A.2). A tea-and-simit pier that grows from home's
right edge into the cloud sea; coral, cream, sea blue as accents on the
home palette. Signature: the vapur docking. Lore hook: "Where does the
ferry go?" (It is the route every returning island follows home.)
Resident: Simit, a honey tabby kitten who sells out by noon. **Toy:**
pull the horn cord: *düüüt*, the gulls lift, Simit covers her ears; at
dusk with a rumour active, a horn answers from the fog. **Game: loading
the vapur** (sort puzzle): parcels, simit trays, the goods of the web and
a very indignant goat. The harbor is the archipelago's inbox and outbox:
postcards, rumour objects, visitors and goods all pass here. Unfolds on
days 1–3 (1A.2).

### 11.3 Çağlayan, the island that pours (wonder 1)

**Silhouette:** a stack of three white travertine terraces (Pamukkale's
cream rims, turquoise pools), the island narrowing downward to a point,
and a waterfall pouring off the lowest rim into the clouds, longer than
the island is tall. No lawn: moss only on the rims. **Lore hook:** "Where
does the water come from, and where does it go?" **Stages:** the fall
starts; a hidden spring behind it; Damla's leaf-boat chute; a mill under
the falls that grinds nothing, it just likes turning; the answer: the
water falls into the clouds, the clouds rain on every island, which is
why the archipelago is green. Keepsake: a jar of falls water that never
empties. **Resident:** Damla, an otter who tries to catch the waterfall
in a cup. **Toy:** drop a leaf boat in the stream; it goes over the edge
and a few days later washes up on the home pier. **Game: leaf boats**
(path-connect): rotate channel stones so boats reach Damla's pools.
**Goods:** jars of falls water. Material: water drops. Unlock: day 4.
Free in cut C2. **Whoa:** water pouring off an island into the sky, and
a boat that comes back.

### 11.4 Gezgin, the island on a whale (wonder 2, a wanderer)

Kept as rated (10). A little grassy island with one cottage on the back
of an enormous sleeping cloud-whale; grey-blue, cream, dandelion. The
grass is the whale's back, not a plate. **Lore hook:** "The map's edge
moved. Something big is out there." **Stages:** the whale stops at the
outer ring; opens one eye; the cottage door opens; the whale sings; the
answer: she carries lost islands home, and now circles the archipelago.
**Residents:** Nazlı the whale, and Yosun, an old tortoise postman who
lodges in the cottage and brings the vapur's letters, slowly. **Toy:**
tap the blowhole: a cloud puff and a small rainbow. **Game: the way
home** (slide puzzle, Rush Hour's verb): slide drifting cloud banks
aside so Nazlı can swim to the next mooring; each solved board moves her
one mooring along a fixed tour. She moves only at night, is never
highlighted, and nothing is gained by finding her. **Goods:** whale-mail
sacks (letters from far islands). Material: shells. Unlock: day 8, at
the end of the first week. **Whoa:** the island is alive.

### 11.5 Revontuli, the fox-fire island (wonder 3; Finland)

**Silhouette strengthened:** not a snowy lawn oval but **an ice floe**: a
flat shelf of clear blue-white ice, thick and glassy at its edge (the
underside glows blue, never soil), with one spruce, a lakeside sauna on
stilts and a round fishing hole. Night blue, snow, aurora green; always
a winter night, whatever the season at home. In Finnish *revontulet*
means "fox fires": an arctic fox sweeps sparks into the sky with its
tail. **Lore hook:** "Who paints the sky green?" **Stages:** the frozen
pond; the sauna (steam rises, Pofu emerges pink and proud); the fishing
hut; the fox's tracks lead up the snow drift; the answer: the fox paints
the aurora only on nights when the island is quiet. Keepsake: a carved
wooden fox. **Resident:** Tuli, a small arctic fox, very serious about
saunas. **Toy:** brush snow off the spruce; it falls in a soft clump on
Pofu. **Games:** *ice fishing* (patience): drop a line, put the phone
down; after 20 quiet minutes something has bitten; *painting the aurora*
(trace): your stroke becomes tonight's aurora. **Goods:** clear ice
blocks. Requests: Çağlayan's water for the sauna stones. **Whoa:** a new
colour world, and you paint the sky.

### 11.6 Çanlar, the island of bells (wonder 4)

Kept (great). A narrow stone spire, taller than any island is wide, hung
with wind bells of many sizes, bunting and poppies; bronze, sky blue,
poppy; always a windy, bright noon. **Lore hook:** "Who rings the bells
in the fog?" **Stages:** one bell; the frame; each bell turns out to play
one island's motif; a bell for every island you have; the answer: the
bells were rung long ago to call drifted islands home, and your calm has
been ringing them. **Resident:** Zil, a slightly deaf, very proud
bell-ringer mouse. **Toy:** tap bells; every combination resolves into
harmony. **Game: echoes** (Simon): Zil rings a phrase, you answer;
phrases are folk tunes of the islands' cultures. **Goods:** small
hand bells. Requests: Gezgin's whale-mail (tunes from far islands). Every later island's first rumour is heard
as a new, unknown bell. **Whoa:** the archipelago has a song, and you
made it.

### 11.7 Koke, the bonsai in the rain (wonder 5; Japan; redesigned from 6)

**Silhouette:** a great, wind-shaped bonsai pine floating in the sky; its
roots grip a moss and raked-gravel garden that is smaller than the tree.
At 60 pt it reads as a tree, not an island. **Its own sky:** always soft
rain (the *tsuyu* season), rings on the gravel pond, mist in the
branches. Deep moss, wet slate, one maple-red accent. **Lore hook:** "Why
does the gravel move by itself at night?" **Stages:** the stones; the
clacker; a tiny tea house on a root; a maple branch that changes with
the real season; the answer: a dormouse rakes it every night, and the
patterns are letters to the other islands. Keepsake: a small rake.
**Resident:** Sumi, a Japanese dormouse (*yamane*) who sleeps through
winter and apologises for it. **Toy:** tap the clacker; it tips, clacks,
and a koi rises through the rain rings. **Game: moss stones** (tile
matching without a fail bar); raking is the toy between rounds.
Learning: the 72 micro-seasons, the real one named on the garden sign.
**Goods:** matcha tins. Requests: Çağlayan's falls water and a Revontuli ice block for the tea
house.
**Whoa:** a tree you can live in, in rain that sounds like calm.

### 11.8 Emanet, the lost-and-found (wonder 6)

Kept (great), **silhouette strengthened:** the office on stilts is built
*from* lost things: an upturned umbrella for a roof, a giant teacup as
its water tank, a top hat as its chimney, a ladder of mismatched spoons,
all on a raft of drifted things at the end of the cloud current; no lawn.
Weathered teal, brass, brown paper; always a soft overcast with lamplit
windows. **Lore hook:** "Everything that falls off an island ends up
somewhere." **Stages:** a shack and an empty shelf; your keepsakes
arrive; things you never knew were lost arrive (Simit's umbrella,
Mochi's spoon); a back room with a hand-drawn map of the outer ring; the
answer: it keeps what the archipelago lost when it drifted apart.
**Resident:** Boncuk, a magpie who loves shiny things and must give every
one back. **Toy:** ring the counter bell; Boncuk tells one keepsake's
story. **Game: who lost this?** (daily deduction, Wordle's shape): from
three clues return the object to its owner on the right island; the
answer sends a visitor to home. **Goods:** returned objects (each a
request fulfilled for another island). **Whoa:** the island is the
archipelago's memory, made of its things.

### 11.9 Fanus, the bell jar (wonder 7; replaces Ayna)

Ayna was the home plate mirrored, the purest copy of all; the impossible
geometry it promised is kept for Mehtap's waxing crescent and Gezgin's
motion. **Silhouette:** a tall glass bell jar floating in the sky, its
brass knob catching the sun; inside, a tiny cloud forest of ferns,
orchids and a waterfall the size of a thumb, in warm rain that never
leaves the glass. The terrarium rim shader of look-dev §C becomes the
island's glass. Emerald, glass teal, orchid pink. **Lore hook:** "Who
put a forest under glass, and why is it so warm in there?" **Stages:**
fogged glass; the first orchid; a hummingbird's nest; the door in the
glass; the answer: the jar keeps the archipelago's rarest seeds safe
until the sky is quiet enough to plant them (each one later blooms in
home's greenhouse). Keepsake: a glass seed. **Resident:** Zümrüt, a
tiny glass frog who is shy and therefore see-through. **Toy:** wipe the
glass with a finger; the condensation clears and beads back slowly.
**Game: fogged panes** (picross): number clues on the edges tell which
panes hide flowers; wiping the right panes reveals the picture.
**Goods:** orchid cuttings. Requests: Revontuli's ice to cool the jar
in summer. Origin: a cloud forest under Victorian glass; native writer
to choose its home (Costa Rica or Borneo). **Whoa:** a world inside a
jar, and the glass is real.

### 11.10 Çömlek, the fairy-chimney kiln (wonder 8; Cappadocia; redesigned from 4)

The founder liked the mole and the wheel, not the island. **Silhouette:**
a cluster of three to five Cappadocia fairy chimneys, soft rose-tuff
cones with dark caps, rising from the clouds; the tallest is hollowed
into a kiln whose little windows glow like a lantern; a wheel on a
ledge; pots on carved shelves. **Its own sky:** always dawn, with two or
three hot-air balloons rising past. Rose tuff, ochre, dawn apricot.
**Lore hook:** "Something is being made slowly here." **Stages:** the
wheel; the kiln lit (it turns only while the phone is down); the first
pot; the shelf of pots in a fixed sequence of shapes; the answer: Kil, a
mole, has made a pot for every island that came home. **Toy:** press a
thumbprint into wet clay; it stays forever. **Game: the wheel** (merge,
Suika's verb): a fixed lump of clay a round; merge into larger shapes
from many cultures (an Avanos jug, a tea bowl, an amphora). **Goods:**
fired pots, jugs, tea bowls (wanted by every later island and by home,
so Çömlek stays relevant for good). Requests: Revontuli's ice to quench,
Koke's moss to pack the pots. **Whoa:** the island is a lantern, and the sky
fills with balloons.

### 11.11 Mehtap, the crescent (wonder 9; redesigned from Yıldız 3)

**Silhouette:** the island **is a sleeping crescent moon**, pale
moonstone with soft craters, resting in the cloud sea; a small
observatory dome nestles in its inner curve, a rope ladder climbs to its
upper tip where Nane perches. **Its own sky:** always blue hour, many
small stars, a faint Milky Way. Indigo, moon silver, pale gold.
**Signature motion:** the crescent's lit part follows the **real moon
phase**: on a new-moon night the island is a dark sliver; at full moon
it glows whole for one night. **Cultural care:** never paint a single
star beside the crescent's tip (that reads as a flag); the stars are
always many. **Lore hook:** "Why does the moon sleep here?" **Stages:**
the dome; the telescope; the star book (a star per calm night, the v2
ritual, kept); seven stars make a constellation you name; the answer:
the moon rests here between nights, and the constellations are a map of
the outer ring. **Resident:** Nane, the sleepy owl. **Toy:** rock the
crescent; it rocks like a cradle and a star slides down to the dome.
**Game: one-stroke constellations** (one-line drawing): draw a
constellation without lifting the finger, then learn what three cultures
saw (the Plough, the Great Bear, the Big Dipper, *Yedi Kardeş*).
**Goods:** star charts (each opens a route on the map). Ritual kept: the
20-second stargazing, A21's one exception. **Whoa:** the island changes
shape with the sky outside your window.

### 11.12 Leylek, the flying nest (wonder 10; seasonal; redesigned from 2)

**Silhouette:** a giant woven nest of reeds and twigs, big enough for a
cottage, carried across the sky by a V of storks holding ribbons; a
chimney pot and a lantern in the nest; the island never touches the
cloud sea. **Its own sky:** warm, windy dusk with a Saharan haze. Straw
gold, white, black, sunset coral. **Seasonal:** it arrives with the real
spring or autumn migration and crosses the map for about six weeks, then
flies on and returns next season (it stays in the collection; A7).
**Lore hook:** "The storks always come back. Where do they go?"
**Stages** (one per migration): the nest; the first feather; a lined
nest; the route map; the answer: Lale has seen every city on the
Europe–Africa flyway and leaves one line about each. **Toy:** tap twice;
the storks clatter their beaks back. **Game: thermals** (glide, Tiny
Wings' verb): dip and rise on warm air to carry a young stork city by
city. **Goods:** feathers for quills and fletching. **Whoa:** an island
that flies away and comes back.

### 11.13 Proposed first year

| When | Ships | Why |
|---|---|---|
| Launch | Ayçiçeği with its harbor; Çağlayan, Gezgin, Revontuli, Çanlar, Koke complete | Covers the first month of an engaged player (islands 1–5 by day 26) |
| Season 1 (about launch + 6 weeks) | Emanet, Fanus, Çömlek | Lands as engaged players reach island 6 (day 34) |
| Season 2 | Mehtap, Kaplıca, Kitap (if they pass the contract) | Winter skies |
| First spring or autumn | Leylek | The migration |
| Season 3 | A native island for the next market (Japan or the Nordics already have one; the third market gets theirs) | Expansion |

Launch needs five wonder islands, not two: the cost of the faster first
month. The art plan (one blockout per island, about 12–16 images each)
holds; the five launch islands are the critical path.

## 12. Guardrail check

| Rule | How this system keeps it |
|---|---|
| A1 finite visits; A10′ two kinds of time | One beat per visit; play is a set of five rounds, at most 12 a day, natural ends |
| A2 no timers, no caps that pressure | Rounds never expire; Revontuli's 20 quiet minutes is a minimum, never a deadline |
| A4 monotonic; A19 no streaks | Stages, decor, keepsakes, fog only advance; all triggers cumulative |
| A6 no paid acceleration | Plus opens islands, never rounds, materials, seeds or speed |
| A7 no FOMO | Islands stay; storks return yearly; rumours never expire |
| A9 looking earns nothing | Rounds come from behaviour; toys earn nothing |
| A13 seeds never touch the gate | Extended to materials and rounds |
| A17 deterministic | Fixed orders; skill bonuses fixed; no random drops |
| A18 glances never ask | Widgets never show rounds, rumours or "new island" |
| A20′ | The world waits while you play |
| A21 nights are a dead end | Arrivals revealed after 06:00; no rounds at night; Mehtap's stargazing stays the exception |
| Fairness of weather | Weather never pays seeds or rounds; simulated by default, real weather opt-in |
| The living web | Requests point only to earlier islands, fill only stage 4–5 extras, decor and gifts; nothing expires |
| ADR-0017 | Nothing leaves; lapsed members keep everything |

## 13. Consequences for code and content

- **`PofuCore`:** yield ladders for the home cluster (rescaled to scale A);
  Yıldız (now Mehtap), Kaplıca and Kitap's nine ladders retired. New, all monotonic and
  tested: `IslandKind`, wonder stages (material, seeds, tended days),
  `RoundLedger` (earned, banked, daily cap, A26's automatic step-down),
  `Goods` and `Request` (backward-only, never expiring), the awake-island
  schedule and the simulated `Weather` (all deterministic from the date
  and the player's islands),
  per-island `Material` balances, decor sockets and inventory, a
  `RumourLadder`, keepsakes. A `GameGrammar` protocol in a new
  `PofuGames` module, one type per grammar, deterministic and offline.
- **`PofuWorld`:** signature motions per island, the map's fog and rings,
  the arrival timeline, decor socket anchors.
- **Art:** the shared camera rig and a blockout per island first; then 12–16 images per wonder
  island; one image per decor item.
- **Sound:** one motif per island and the bell set; a composer before
  season 1.
- **Measurement:** reflex opens, play minutes, sessions and the other
  section 6.3 signals as on-device aggregates for the dogfood dashboard.
- **Docs:** an ADR after the dogfood for the session-rule change (A10′,
  A20′, A22–A26), materials and decor spots; game-design.md and
  app-game-boundary.md updated in that PR.
- **Content graph:** this PR adds the new islands, residents and the
  system nodes (rumours, island toys, island games, decor spots, island
  materials, the cloud field), all `horizon: maybe` until the founder
  picks them up.

## 14. Open questions for the founder

| # | Question | Recommendation |
|---|---|---|
| 1 | Islands after the home cluster produce nothing and are about play and secrets? | **Yes.** Small numbers forever, and Plus never sells progress |
| 2 | Every wonder island has its own game from a shared grammar, rounds earned by resisting? | **Yes.** "Resisting earns the round; playing it is the reward" |
| 3 | The revised session rule (A10′, A20′, A22–A26): visits short, play 5–10 min, finite and earned, with a reflex watch? | **Yes, as an experiment** during the dogfood, with the section 6.3 thresholds; an ADR afterwards |
| 4 | Per-island materials instead of Roblox-style scaling? | **Yes.** Flat 5–200 prices everywhere; each island starts at a fresh zero |
| 5 | The Plus line: should the first wonder island be free? | **Test it in the friends beta.** My prior: yes, Çağlayan free, because a free user cannot want what they have never felt |
| 6 | Do users need to know the exact cut point? | **No, but they must know the shape** from day one ("two islands free forever; more with Plus") and never meet a wall mid-island |
| 7 | Decor spots as sockets (not free placement)? | **Yes.** Player choice, composed art, a fixed camera |
| 8 | Three islands a season, a 50-island horizon? | **Yes as the plan; ship only what passes the whoa test.** Build the grammars and blockouts first |
| 9 | Markets after Türkiye? | **Test Japan and the Nordics** with one native island each (Koke, Revontuli) before a broad English launch |
| 10 | Skip seeds at scale A (+1, at most 6: up to 40 % of day-1 income)? | **Keep, and let the simulation confirm** skips stay under a quarter of income from week 2 |
| 11 | The myth "islands drift toward quiet"? | **Yes.** True to the mechanics and to the product |
| 12 | Gezgin, the moving whale: delight or a checking risk? | **Ship it,** moving only at night, never highlighted; cut it if reflex opens rise after it arrives |
| 13 | İskele as Ayçiçeği's harbor district, not a separate island? | **Yes** (1A.2) |
| 14 | The uniqueness contract and rubric as the bar (8+ to produce)? | **Yes** (1A.3) |
| 15 | Gezgin second (day 8) rather than a day-100 milestone? | **Yes:** the first week ends on the best island |
| 16 | Ayna replaced by Fanus; Yıldız redesigned as Mehtap? | **Yes;** judge on the batch-17 concepts |
| 17 | Real local weather via WeatherKit? | **Later, opt-in;** simulated weather ships first |

## 15. Self-critique

- **The biggest risk is the session change.** A good game is exactly what
  can become the new reflex. The design bets on finite rounds, entry on
  purpose and an automatic step-down; the bet is only honest if section
  6.3 is measured from the first day of the dogfood.
- **Fifty hand-made islands is a production promise.** It holds only if
  the grammars, blockouts and motion engines exist before island three;
  otherwise every island is a fresh build and the cadence collapses to
  three or four a year.
- **Twelve games is a lot of design.** Each must be fun in one round
  without text. Prototype two first: Çağlayan's leaf boats (Flow) and
  Koke's raking (Trace); if they are not fun on the founder's phone, the
  grammar is wrong, not the island.
- **Materials add a number per island.** They stay small and local, but
  every number invites optimising. Keep them off Home and out of glances.
- **Learning can turn into homework.** One card, after a set, skippable,
  never quizzed.
- **Cultural islands can become postcards.** Each needs a native writer
  and a resident whose personality is not the stereotype (Tuli is serious
  about saunas, not "a Viking").
- **The economy numbers are a hand model.** The economy pass must rerun
  `tools/sim` with rounds, materials and these ladders.
- **The paid line contradicts a written rule** (ADR-0016 "never
  islands"); PR #60's decision needs the ADR amendment to land with it.

- **The faster curve costs content.** Five wonder islands at launch
  instead of two; an engaged player reaches island 6 around day 34, so
  season 1 must land about six weeks after launch or the fog waits. The
  web and the daily diff are what make waiting bearable; if they are not
  built, the early wows only move the cliff.
- **The web can turn into chores.** Requests and awake islands are the
  first thing to become a to-do list. Hence: at most three awake, nothing
  expires, requests only for extras, and no badge counts on the map.
- **The rubric is calibrated to one person's taste.** It matches the
  founder's ratings by construction; the friends beta should score the
  batch-17 concepts blind to test it.

## 16. Sources

- Animal Crossing: New Horizons mystery islands:
  [Nookipedia](https://www.nookipedia.com/wiki/Mystery_Island),
  [Nintendo Life](https://www.nintendolife.com/guides/animal-crossing-new-horizons-nook-miles-ticket-mystery-island-tours-how-to-visit-other-islands-and-mystery-island-types-explained)
- Cozy Grove: [Vice](https://www.vice.com/en/article/bvx9vw/cozy-grove-is-ok-telling-players-to-log-off-its-delightful),
  [GameCritics](https://gamecritics.com/cody-bolster/cozy-grove-review/)
- Neko Atsume: [Wikipedia](https://en.wikipedia.org/wiki/Neko_Atsume),
  [TV Tropes](https://www.tvtropes.org/pmwiki/pmwiki.php/VideoGame/NekoAtsume)
- Pokémon Sleep islands: [Pokémon GO Hub](https://pokemongohub.net/post/sleep/pokemon-sleep-the-islands-and-snorlax/)
- Finch: [Bustle](https://www.bustle.com/wellness/finch-app-review-features-price)
- Sky: Children of the Light: [Pocket Gamer](https://www.pocketgamer.com/sky-children-of-the-light/remembrance-season/),
  [GameSpot](https://gamespot.com/articles/sky-children-of-the-light-reveals-a-challenging-new-season/1100-6483011/)
- Viridi: [Wikipedia](https://en.wikipedia.org/wiki/Viridi)
- Spiritfarer: [Wikipedia](https://en.wikipedia.org/wiki/Spiritfarer),
  [GameSkinny](https://www.gameskinny.com/culture/thunder-lotus-on-spiritfarer-death-hugs-and-legacies/)
- Dorfromantik: [Game Developer](https://www.gamedeveloper.com/disciplines/sparking-joy-through-tile-placement-in-idyllic-village-builder-i-dorfromantik-i-),
  [80.lv](https://80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design)
- Tiny Glade: [80.lv](https://80.lv/articles/exclusive-tiny-glade-developers-discuss-bevy-proceduralism-publishers-cozy-games/),
  [PC Gamer](https://pcgamer.com/games/city-builder/tiny-glade-wont-stop-delighting-me-with-new-discoveries);
  Townscaper: [PC Gamer](https://pcgamer.com/townscapers-developer-on-how-its-radically-casual-design-is-inspiring-a-new-wave-of-low-stress-builders-to-adapt-the-blueprint)
- Idle games in Asia: [Sensor Tower, APAC 2024](https://sensortower.com/blog/state-of-mobile-games-in-apac-2024-report),
  [Pocket Gamer.biz, RPGs in Korea](https://www.pocketgamer.biz/rpgs-account-for-60-of-koreas-mobile-games),
  [Airbridge, idle RPG trend](https://www.airbridge.io/en/blog/idle-rpg-trend-2023),
  [Game Dev Reports, Pixel Hero](https://gamedevreports.substack.com/p/sensor-tower-pixel-hero-is-the-leader),
  [Asia Economy, Chinese idle games](https://view.asiae.co.kr/en/article/2024082316435408322)
- A Short Hike, Alba, Islanders, Kind Words, Forest, Stardew Valley,
  Wylde Flowers, Ooblets, Unpacking, Monument Valley, Pocket Camp, Hidden
  Folks, Pikmin Bloom, Duolingo, Alto's Odyssey, Mini Metro: from play
  knowledge of the shipped games; no claim above depends on a number from
  them. Revontulet's "fox fires" etymology and the 72 Japanese
  micro-seasons are common cultural knowledge, to be checked by the native
  writers.

## 17. Codex exploration spec: wonder islands under the contract, and the living hub

A spec for the next exploration batch (to be turned into a manifest by
the art-queue owner; the job format follows `batch-15-explore.yaml`).
Two concepts per wonder island, each a different reading of the same
contract, plus four Ayçiçeği hub variants. Exploration only: never
promoted. **Pilot first** (AGENTS.md): `x2-mehtap-a`, `x2-comlek-a`,
`x2-leylek-a`, `x2-hub-grown`; scale to the rest only after review.

The key change from batch 15 is the **attach roles**: the home island is
a style reference, never a shape reference.

```yaml
batch: batch-17-uniqueness-explore   # number assigned by the queue owner
kind: plate
size: 1536x1024
variants: 2
review: >-
  Score every take with the rubric of archipelago-system.md 1A.3; reject any
  take with a lawn oval, a soil bowl, dangling roots or a round door (wonder
  islands only). Check the 60 pt black-silhouette test on the contact sheet.

attach_wonder:            # every wonder-island job
  - ref: approved:island-main-s
    role: >-
      STYLE ONLY: the soft painterly finish, the gentle light and the low
      camera height. Do NOT copy its shape: no lawn oval, no sandy soil bowl,
      no dangling roots, no pebbles, no round door. This is a different place.
  - ref: approved:cloud-sea
    role: The sea of clouds below; paint clouds like this (unless the sky says otherwise).
  - ref: R1
    role: Style reference only for softness and pastel handling; no characters unless named.
attach_hub:               # every hub job
  - ref: approved:island-main-s
    role: >-
      THIS is the island to paint: keep its exact shape, lawn, sunflower,
      çay ocağı, pond and round door; change only what the prompt names.
  - ref: cay-1
    role: The çay ocağı as built.

avoid_wonder: >-
  a lawn oval island, a soil or sand bowl underside, roots hanging below,
  pebbles in the soil, a round door, sunflowers, honey-and-sage palette,
  text, a border, harsh shadows, neon, dark moods
avoid_hub: text, a border, harsh shadows, neon, dark moods, a new island shape

jobs:
  # ---------------------------------------------------------- Çağlayan
  - id: x2-caglayan-a
    island: Çağlayan
    silhouette: three stacked white travertine terraces narrowing downward to a point
    palette: [travertine cream, turquoise, mist white]
    sky: late morning, mist, a faint mist rainbow where the fall meets the clouds
    landmark: a waterfall from the lowest rim, falling far below the island into the clouds
    scale_cue: a tiny wooden waterwheel and a leaf boat on one pool
    prompt: >-
      A concept painting for a cozy mobile game: Çağlayan, a floating island
      made of three stacked terraces of white travertine with scalloped
      cream rims and still turquoise pools, the island narrowing downward to
      a point; from the lowest rim a ribbon waterfall pours down past the
      island and far into a sea of clouds, longer than the island is tall,
      with a soft mist rainbow. Moss only on the rims. A tiny waterwheel and
      one leaf boat for scale. Low front three-quarter camera.
  - id: x2-caglayan-b
    island: Çağlayan
    silhouette: a tall travertine column like a frozen fountain, pools spilling in rings
    palette: [cream, turquoise, pale jade]
    sky: bright mist, sun behind the falls
    landmark: a curtain fall wrapping half the column
    scale_cue: a small otter-sized stone hut behind the fall
    prompt: >-
      A concept painting for a cozy mobile game: Çağlayan, a tall floating
      column of white travertine shaped like a frozen fountain, turquoise
      pools spilling over in rings, and a wide curtain of water wrapping
      half the column and falling into a sea of clouds; behind the curtain a
      tiny stone hut glows. Bright soft mist, the sun behind the water.

  # ---------------------------------------------------------- Gezgin
  - id: x2-gezgin-a
    island: Gezgin
    silhouette: an enormous sleeping cloud-whale; a cottage on her back
    palette: [grey-blue, cream, dandelion]
    sky: moonlit night travel, silver-edged clouds
    landmark: the blowhole puffing a tiny cloud with a moonbow
    scale_cue: a cottage with one lit window, smaller than the whale's eye
    prompt: >-
      A concept painting for a cozy mobile game: Gezgin, an enormous
      sleeping cloud-whale in grey-blue and cream swimming slowly through a
      moonlit sea of clouds, only part of her body in frame; on her back a
      patch of dandelions and a tiny cottage with one warm window; her
      blowhole puffs a small cloud with a soft moonbow. Calm, huge, gentle.
  - id: x2-gezgin-b
    island: Gezgin
    silhouette: the whale surfacing beside the home pier, seen from the side
    palette: [grey-blue, cream, coral accents]
    sky: dawn, pink light
    landmark: the whale's open eye, a mooring rope to a post
    scale_cue: a small tortoise postman with a satchel on her back
    prompt: >-
      A concept painting for a cozy mobile game: a vast gentle cloud-whale
      surfacing from a sea of clouds at dawn, one kind eye just opening, a
      mooring rope from her flipper to a little wooden post; on her back a
      tiny cottage and an old tortoise postman with a satchel. Pink dawn.

  # ---------------------------------------------------------- Revontuli
  - id: x2-revontuli-a
    island: Revontuli
    silhouette: a flat ice floe with a thick, glassy blue edge, glowing from inside
    palette: [night blue, snow white, aurora green]
    sky: winter night, aurora curtains, falling snow
    landmark: a sauna on stilts with a steam ribbon; a round fishing hole
    scale_cue: a tiny arctic fox beside the fishing hole
    prompt: >-
      A concept painting for a cozy mobile game: Revontuli, a floating ice
      floe of clear blue-white ice with a thick glassy edge that glows softly
      from within, no soil underneath; on it one snowy spruce, a small
      wooden sauna on stilts with a ribbon of steam, and a round fishing
      hole; a tiny arctic fox sits by the hole. Green and violet aurora
      curtains, gentle falling snow, deep night blue.
  - id: x2-revontuli-b
    island: Revontuli
    silhouette: a snow-capped frozen lake in a ring of ice, like a frozen drop
    palette: [ice blue, snow, aurora green, violet]
    sky: polar twilight
    landmark: an aurora shaped like a fox's tail sweeping from a snow drift
    scale_cue: a sauna door and a lantern
    prompt: >-
      A concept painting for a cozy mobile game: a floating frozen lake shaped
      like a teardrop of ice, a ring of snow around it, a wooden sauna with a
      lantern at its edge; above, the aurora sweeps from a snow drift in
      the shape of a fox's tail. Polar twilight, ice blue and violet.

  # ---------------------------------------------------------- Çanlar
  - id: x2-canlar-a
    island: Çanlar
    silhouette: a tall thin stone spire, many times taller than wide
    palette: [bronze, sky blue, poppy red]
    sky: bright windy noon, bunting streaming
    landmark: bronze bells of many sizes on wooden arms, ropes swaying
    scale_cue: a mouse-sized rope ladder and door
    prompt: >-
      A concept painting for a cozy mobile game: Çanlar, a tall slender
      floating stone spire, many times taller than it is wide, hung with
      bronze wind bells of many sizes on wooden arms, poppies in the cracks,
      bunting streaming in a bright wind, a mouse-sized door and rope ladder.
  - id: x2-canlar-b
    island: Çanlar
    silhouette: a ring of thin spires around one great bell
    palette: [bronze, pale stone, sky blue]
    sky: golden hour
    landmark: one great bell hanging between the spires
    scale_cue: a tiny bell-ringer's platform
    prompt: >-
      A concept painting for a cozy mobile game: a ring of thin floating stone
      spires joined by rope bridges, one great bronze bell hanging between
      them, smaller bells on every spire; golden hour light.

  # ---------------------------------------------------------- Koke
  - id: x2-koke-a
    island: Koke
    silhouette: a great wind-shaped bonsai pine larger than the land under it
    palette: [deep moss, wet slate, one maple red]
    sky: soft steady rain, mist in the branches
    landmark: a raked gravel pond with rain rings; a bamboo water clacker
    scale_cue: a tiny tea house on a root
    prompt: >-
      A concept painting for a cozy mobile game: Koke, a great wind-shaped
      bonsai pine floating in the sky, its sweeping branches larger than the
      small moss and raked-gravel garden its roots hold; soft steady rain,
      rain rings on a tiny gravel pond, a bamboo water clacker, a tiny tea
      house on a root, one red maple branch. Deep moss and wet slate.
  - id: x2-koke-b
    island: Koke
    silhouette: one huge moss-covered stone shaped like a sleeping animal
    palette: [moss green, slate, lantern amber]
    sky: misty rain at dusk
    landmark: a stone lantern lit on the stone's back
    scale_cue: a dormouse-sized raked garden
    prompt: >-
      A concept painting for a cozy mobile game: a single huge mossy stone
      floating in misty rain, shaped like a curled sleeping animal, a raked
      gravel garden and a lit stone lantern on its back, a thin stream of
      rain water running off one edge. Dusk, amber lantern glow.

  # ---------------------------------------------------------- Emanet
  - id: x2-emanet-a
    island: Emanet
    silhouette: an office on stilts built from lost things
    palette: [weathered teal, brass, brown paper]
    sky: soft overcast, lamplit windows
    landmark: an upturned umbrella roof, a giant teacup water tank, a top-hat chimney
    scale_cue: a magpie at the counter window
    prompt: >-
      A concept painting for a cozy mobile game: Emanet, a crooked little
      lost-and-found office on tall stilts built from lost things: an upturned
      umbrella for a roof, a giant teacup as its water tank, a top hat for a
      chimney, a ladder of mismatched spoons, on a raft of drifted things at
      the end of a cloud current; a magpie at the counter window. Overcast,
      warm lamplight.
  - id: x2-emanet-b
    island: Emanet
    silhouette: a tall pile of lost luggage and parcels forming a tower
    palette: [brown paper, teal, brass, red string]
    sky: drifting fog
    landmark: tagged objects floating in on a current
    scale_cue: a little door in the side of a suitcase
    prompt: >-
      A concept painting for a cozy mobile game: a floating tower of lost
      suitcases, parcels and hatboxes tied with red string, a little door in
      the side of a suitcase, a brass bell, tagged lost objects drifting in
      on a current of cloud. Soft drifting fog.

  # ---------------------------------------------------------- Fanus
  - id: x2-fanus-a
    island: Fanus
    silhouette: a tall glass bell jar floating in the sky, a brass knob on top
    palette: [emerald, glass teal, orchid pink]
    sky: clear outside; warm rain and condensation inside the glass
    landmark: a thumb-sized waterfall and orchids inside
    scale_cue: a tiny glass frog on a leaf
    prompt: >-
      A concept painting for a cozy mobile game: Fanus, a tall glass bell jar
      floating in a clear sky, a brass knob on top catching the sun; inside a
      tiny cloud forest of ferns, orchids and a thumb-sized waterfall, warm
      rain falling only inside, droplets beading on the glass; a tiny glass
      frog on a leaf. Emerald and orchid pink.
  - id: x2-fanus-b
    island: Fanus
    silhouette: a glass greenhouse dome on a brass base, hanging from a chain into the clouds
    palette: [glass teal, brass, fern green, pink]
    sky: sunbeams through cloud
    landmark: fogged panes, some wiped clear showing flowers
    scale_cue: a little brass door in the base
    prompt: >-
      A concept painting for a cozy mobile game: a round glass greenhouse dome
      on a brass base hanging on a long chain from above the clouds, its
      panes fogged with condensation, a few wiped clear to show orchids
      inside; a small brass door; sunbeams through the clouds.

  # ---------------------------------------------------------- Çömlek
  - id: x2-comlek-a
    island: Çömlek
    silhouette: a cluster of Cappadocia fairy chimneys; the tallest is a glowing kiln
    palette: [rose tuff, ochre, dawn apricot]
    sky: dawn, three hot-air balloons rising
    landmark: kiln windows glowing like a lantern; a potter's wheel on a ledge
    scale_cue: pots on carved shelves, a mole-sized door
    prompt: >-
      A concept painting for a cozy mobile game: Çömlek, a floating cluster of
      soft rose-tuff fairy chimneys from Cappadocia with dark caps, the
      tallest hollowed into a kiln whose little windows glow like a lantern,
      pots on carved shelves, a potter's wheel on a ledge, a mole-sized door;
      dawn sky with three hot-air balloons rising. Rose, ochre, apricot.
  - id: x2-comlek-b
    island: Çömlek
    silhouette: the island is a giant clay pot lying on its side, its mouth a workshop
    palette: [terracotta, cream glaze, cobalt pattern]
    sky: warm dawn haze
    landmark: smoke curling from a chimney in the pot's neck
    scale_cue: the wheel and a tiny mole in the mouth
    prompt: >-
      A concept painting for a cozy mobile game: a floating island that is a
      giant terracotta pot lying on its side, cream-glazed with a cobalt
      pattern, its open mouth a cosy potter's workshop with a wheel, smoke
      curling from a chimney in its neck; warm dawn haze, a balloon far off.

  # ---------------------------------------------------------- Mehtap
  - id: x2-mehtap-a
    island: Mehtap
    silhouette: a sleeping crescent moon resting in the clouds
    palette: [indigo, moon silver, pale gold]
    sky: blue hour, many small stars, a faint Milky Way (never a single star by the tip)
    landmark: an observatory dome in the inner curve; a rope ladder to the tip
    scale_cue: a small owl on the upper tip
    prompt: >-
      A concept painting for a cozy mobile game: Mehtap, a sleeping crescent
      moon of pale moonstone with soft craters resting in a sea of clouds, a
      small observatory dome with a warm window in its inner curve, a rope
      ladder up to its upper tip where a tiny owl perches; blue hour, many
      small stars and a faint Milky Way. Indigo, silver, pale gold.
  - id: x2-mehtap-b
    island: Mehtap
    silhouette: a crescent moon hanging like a cradle from a star-chain
    palette: [deep blue, silver, warm lamp gold]
    sky: deep night, constellations faintly joined by thin gold lines
    landmark: a telescope and a hammock on the crescent
    scale_cue: a lantern and a book
    prompt: >-
      A concept painting for a cozy mobile game: a crescent moon hanging like a
      cradle from a long chain of tiny stars above the clouds, a telescope,
      a hammock, a lantern and an open star book on it; faint constellations
      joined by thin gold lines. Deep night blue, silver, lamp gold.

  # ---------------------------------------------------------- Leylek
  - id: x2-leylek-a
    island: Leylek
    silhouette: a giant woven nest carried by a V of storks on ribbons
    palette: [straw gold, white, black, sunset coral]
    sky: warm windy dusk, light Saharan haze
    landmark: a chimney pot and a lantern in the nest
    scale_cue: a cottage door woven into the nest
    prompt: >-
      A concept painting for a cozy mobile game: Leylek, a giant woven nest of
      reeds and twigs big enough for a cottage, with a little door, a chimney
      pot and a lantern, carried across a warm windy dusk sky by a V of white
      storks holding ribbons in their beaks; the nest never touches the
      clouds below. Straw gold, white, black, sunset coral, light haze.
  - id: x2-leylek-b
    island: Leylek
    silhouette: a nest atop an impossibly tall brick chimney rising from the clouds
    palette: [brick, straw, white, apricot]
    sky: spring morning, storks circling on a thermal
    landmark: a spiral of storks rising above the nest
    scale_cue: a small window in the chimney
    prompt: >-
      A concept painting for a cozy mobile game: one impossibly tall, thin brick
      chimney rising out of a sea of clouds with a huge stork nest on top and
      a small window halfway up; a spiral of white storks circling on a
      warm thermal above. Spring morning, apricot light.

  # ---------------------------------------------------------- Ayçiçeği hub
  - id: x2-hub-rain
    island: Ayçiçeği
    edit_of: island-main-s
    prompt: >-
      The same island on a soft rainy afternoon: gentle rain, rain rings on
      the pond, wet glossy leaves, the sunflower drooping a little, the
      çay ocağı's window glowing warm, a frog on a lily pad delighted, the
      moss on the roof stones greener. Keep everything else the same.
  - id: x2-hub-winter
    island: Ayçiçeği
    edit_of: island-main-s
    prompt: >-
      The same island on a calm winter evening: soft snow on the lawn and
      roofs, the sunflower bowed under a cap of snow, smoke from the çay
      ocağı, warm windows, a faint green aurora low in the sky. Keep the
      island's shape exactly.
  - id: x2-hub-festival
    island: Ayçiçeği
    edit_of: island-main-s
    prompt: >-
      The same island on a festival night: strings of paper lanterns from the
      çay ocağı to the sunflower, a ribbon wish-tree, floating lanterns on
      the pond, small visitors from other islands (an otter, an arctic fox,
      a dormouse) gathered around the çay ocağı. Warm, joyful, quiet.
  - id: x2-hub-grown
    island: Ayçiçeği
    edit_of: island-main-s
    prompt: >-
      The same island a year later, grown: a wooden harbor pier reaching from
      its right edge into the clouds with a little ferry docked and a kitten's
      simit cart; a sauna hut at the pier's end with a steam ribbon; a small
      bell set on the çay ocağı; a bamboo water clacker at the pond; a stork
      nest on the windmill cap; a glass greenhouse by the garden; a small
      brass telescope on the lawn; and an enormous gentle cloud-whale moored
      beyond the pier. Busy but calm; the island's outline unchanged.
```
