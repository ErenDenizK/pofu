# The Archipelago System: Islands You Want to Play

_Status: proposal for discussion with the founder. Date: 2026-11-02.
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
| Every island: three stations × five levels, one ritual (about 27 images) | Two **yield** islands (the free pair); every later island is a **wonder island** with a game, a secret, decor spots (about 12–16 images plus one game) |
| Islands are places you build | Islands are places you **play**: one game per island, one shared loop |
| Yıldız, Kaplıca, Kitap carry station ladders (45 vignettes, 1.5 M seeds) | They become wonder islands with games; the ladders are retired |
| One currency for everything | Seeds stay universal; each wonder island adds one local, non-convertible **material** earned by playing it |
| Visits only: median under 90 s | **Visits** stay short; **play sessions** of 5–10 minutes are allowed, finite and earned (section 6) |
| Placement is never the player's | **Decor spots**: fixed sockets where the player chooses what goes (section 5) |
| Arrival is a bubble and a cloud pass | A **rumour ladder** before, a choreographed **arrival**, a **secret** after |
| Mostly Turkish settings | A sky of many cultures; Turkish warmth at home |

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
| **Monument Valley** | Impossible architecture; paid expansion chapters | The "ah" when geometry turns | Hand-made; premium plus chapters | **Steal** impossible geometry (Ayna) and clean paid chapters |

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
| **Kind** | `yield` (stations, seeds; the free pair) or `wonder` (a game, a secret; everything after). A wonder island may be a `wanderer` (it moves) | Only yield islands produce seeds |
| **Origin** | The culture or place it is lovingly from, and who writes it | Native writer; never a postcard cliché |
| **Biome and feel** | One line: "a spring that never stops", not "water island" | Distinct from every earlier island |
| **Colour key** | Two or three dominant palette colours | Art bible palette; runtime grade can shift it |
| **Silhouette** | What reads at map scale (about 60 pt) | Never repeated |
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
| Plate | 1 | Painted from one of five **landform blockouts** (Blender gray boxes in the fixed camera), so the camera and light never drift; the outline is always new |
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
| **Landform blockouts** | Consistent camera and light; every outline different |
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

| Grammar | The verb | Islands using it |
|---|---|---|
| **Serve** | Remember and fulfil small orders | Ayçiçeği (Mochi's tea orders) |
| **Pack** | Fit shapes into a space | İskele (loading the vapur) |
| **Flow** | Route something through a channel | Çağlayan (leaf boats) |
| **Connect** | Draw lines between points | Yıldız (constellations) |
| **Trace** | Draw a pattern along a guide | Koke (raking the moss garden), Revontuli (the fox's tail) |
| **Echo** | Repeat or answer a phrase | Çanlar (bells), Gezgin (whale song) |
| **Patience** | Set something up, put the phone down, come back | Revontuli (ice fishing) |
| **Deduce** | Infer from clues | Emanet (who lost this?) |
| **Shape** | Mould with a drag | Çömlek (the wheel) |
| **Guide** | Steer gently with taps | Leylek (storks on thermals) |

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
dust on Yıldız, clay on Çömlek, frost on Revontuli, moss on Koke. Seeds
stay the universal material (yield islands, stations, and a small seed
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
| **Ground** | A level patch of lawn | A hammock between two trees (a resident naps there at noon); a tiny telescope (at night it points at Yıldız); a sunflower-seed bird table (a specific bird visits) |
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
| Stations (yield islands) | 0.6 seeds a day per station level at calm ×1.0, × calm, only while no guarded app is open | 1 → 23 |
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
| Every 2–4 weeks | A rumour, then an island: the full arrival |
| Every season | New islands for the season; the archipelago changes clothes |
| The long arc | The map clears from fog; Pofu's shelf fills; decor across islands tells the user's own story; Çanlar's bells learn one more motif per island |
| Pofu himself | Gifts that stay: Simit's scarf, a ferry ticket in his cheek pouch, a satchel badge per island, a lantern from Yıldız; his den behind the round door gets a shelf |

### 7.6 The first 60 days for a typical user

About 10 reaches resisted a day, average calm, a Plus member (or a free
user if the first wonder island is free; open question 5). One or two
short visits a day plus one play set (about 5 minutes) on most days.

| Day | What happens | Feeling |
|---|---|---|
| 1 | The island wakes with the first gate catch. Garden L2, çay ocağı L1. Mochi arrives with her first tea order: the **Serve** game's tutorial round. About 15 seeds. | "I did something, and someone moved in." |
| 2–6 | A build almost every day; the island widens (stage 3, lily pond). Tea orders learn the residents' tastes; first learning card: how tea is drunk in Türkiye, Japan and Morocco. | |
| 8 | **İskele drifts close.** Simit; the **Pack** game: loading the vapur. | **Whoa 1** |
| 10–12 | Back terrace, Fındık. **Rumour 1**: "Did you hear water last night? Behind the fog, past the pier." | "Wait, what was that?" |
| 15–20 | The vapur's first run brings a postcard and, on day 18, a **bottle** (rumour 2): "the water never stops here". First decor spots open on Ayçiçeği: the user hangs lanterns on the çay ocağı. | |
| 24 | Home stage 5: the east islet and rope bridge; windmill L1. | |
| 28 | The lighthouse beam catches a **mist rainbow** at the map's edge (rumour 3). | |
| 36 | **Çağlayan arrives.** The waterfall starts pouring, on camera. Damla the otter; the **Flow** game: route leaf boats down the chute. | **Whoa 2** |
| 38–50 | Çağlayan's stages: the hidden spring (a new channel piece), the chute (boats can now be sent over the edge), the mill (a rule: water turns it). Learning: the water cycle, one card a stage. | A secret unfolding |
| 44 | The leaf boat sent over the falls on day 37 washes up on İskele's pier. | "It went all the way round!" |
| 46 | **Ayna** appears beneath the clouds (20 calm nights): the camera dips under and the world turns over. Pekmez. | **Whoa 3** |
| 50 | Çağlayan stage 5: the falls water every island. Keepsake: a jar of falls water. Morning rainbows at home after calm nights. | Closure, a new question |
| 55–60 | Stations keep levelling (26 builds in 60 days). Ayna's game opens. Day 60: **rumour 1 of Revontuli**: a green flicker in the north at dusk. | One open question, always |

## 8. Signature motion: what code can do

The world already has `TimelineView`, `Canvas` particles, a runtime
grade, a depth lens and a Metal `layerEffect` (the terrarium rim,
look-dev §C). Every signature motion is built from those over still
paintings.

| Motion | Technique | Island |
|---|---|---|
| A waterfall pouring off the edge into the clouds | A painted ribbon masked to the fall; a `layerEffect` scrolls two noise layers down it; `Canvas` mist where it meets the clouds; a mist rainbow at golden hour | Çağlayan |
| An island hanging upside down beneath the cloud sea | The home plate mirrored, a ripple `distortionEffect` along the cloud line, a moonlit grade; fireflies fall upward | Ayna |
| An aurora painted by a fox's tail | A `layerEffect` curtain of two noise fields in green and violet, its shape driven by the last tail stroke the player drew | Revontuli |
| A bamboo water clacker and moss that greens in the rain | A damped spring on the bamboo, a sound; the moss layer's grade shifts on rainy real-weather days | Koke |
| An island on the back of a breathing cloud-whale | Whole-plate scale and offset on a slow sine; a blowhole spray that makes a small rainbow; the map position moves at night only | Gezgin |
| Bells that swing and ring | Each bell a layer on a damped spring; ropes as curves; sound per bell | Çanlar |
| Storks circling on thermals | A flock on splines with soft cloud shadows, in migration months | Leylek |
| A slow wheel that turns only when it is quiet | Rotation tied to calm, pausing during a pass | Çömlek |
| A telescope tracking the real moon | The computed moon phase in `Canvas`; the telescope rotates to it | Yıldız |
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
| Will users run out? | Each island's stages need at least 14 tended days, and arrivals follow the user's own tended days, so an engaged user meets about one island every 2–4 weeks. Twelve a year matches that pace; a slower user has a backlog and never runs dry |
| What fills the gaps? | Rumours (always one open question), seasonal edits, each island's game (sets keep yielding material for decor), decor spots, wishes, and Yıldız-like rituals |

### 9.2 The sky map: rings and fog

| Ring | Contents | Visible as |
|---|---|---|
| Inner | The yield islands | Clear |
| Middle | Wonder islands as they arrive | Fog that recedes with every arrival |
| Outer, "Uzak Sular" (the far waters) | Islands to come; the wanderer's route | Fog with lights, sounds, silhouettes (rumours) |

The fog is the map's collection: it only recedes. It never shows an
empty slot, a count of islands left, or a date.

### 9.3 The curiosity engine: rumours

| Rung | Sense | Example (Çağlayan) | Carried by |
|---|---|---|---|
| 1. A sound | Its motif, faint, from the fog; Pofu mentions it in the morning | "Did you hear water last night?" | Morning bubble; the fog shimmers |
| 2. An object | Something arrives: a bottle, a feather, a leaf, a lost hat | A bottle: "the water never stops here" | The vapur, on İskele's pier (hand-painted, one per island) |
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
exposition dump: Pofu says it once at İskele's arrival; Çanlar's bells
and Kitap's archive explain it; it is true to the mechanics, because the
user's calm is what brings the islands.

## 10. Monetization: how the system carries Plus

**Decided (PR #60, founder-approved):** free is the gate, Pofu,
Ayçiçeği and İskele; Plus (349,99 TL a year, 999,99 TL lifetime) opens
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
   just after the island where completion and return visits peak. The
   strongest candidate to test: **the first wonder island free**
   (Çağlayan), because a free user who has never played a wonder island
   does not know what Plus is.
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
7. **The free game stays whole.** Two yield islands with their games,
   decor spots, the postcards, rumours, and every seasonal edit: a
   complete Turkish (and global) game, not a demo.

## 11. Island concepts

Twelve concepts: the free pair, ten wonder islands. Seven new, three
reworked from v2, two developed from idea nodes. Cultures: Turkish at
home and on the pier and in the spring; Finnish, Japanese, and a
European-African migration route in the sky; more to come from native
writers. Each passes the whoa test: a new silhouette, a never-used
motion, a toy with a second answer, a game with its own verb, a question
answered at stage 5.

| Island | Origin | Signature motion | Game (grammar) | Material | Learning thread | Tier |
|---|---|---|---|---|---|---|
| Ayçiçeği | Türkiye | The giant sunflower turns with the real sun | Mochi's tea orders (Serve) | seeds | Tea customs around the world | Free |
| İskele | Türkiye (Bosphorus) | The vapur docking and puffing | Loading the vapur (Pack) | seeds | Where the postcards come from | Free |
| Çağlayan | Anywhere with travertine | A waterfall pouring off the edge into the clouds | Leaf boats (Flow) | water drops | The water cycle | Plus (first; test free) |
| Ayna | The home island's reflection | Upside down beneath the clouds | Catch falling seeds in the mirror (Trace) | moonlight | The moon's phases | Plus |
| Revontuli | Finland | An aurora painted by a fox's tail | Ice fishing (Patience) and painting the aurora (Trace) | frost | Nordic sky lore, the real aurora | Plus |
| Koke | Japan | A bamboo clacker; moss greening in real rain | Raking the moss garden (Trace) | moss | The 72 Japanese micro-seasons | Plus |
| Yıldız | Above the clouds | A telescope tracking the real moon | Constellations (Connect) | star dust | One star, three cultures' names | Plus |
| Çanlar | The sky itself | Bells that swing and ring | Bell echoes (Echo) | — (bronze) | Folk melodies of the islands' cultures | Plus |
| Gezgin | The open sky | An island on a breathing whale | Whale song (Echo) | — (shells) | Whales, songs that travel | Plus |
| Emanet | The cloud current | Things floating home | Who lost this? (Deduce) | — (tags) | Objects and their stories | Plus |
| Çömlek | Anatolia (Avanos) | A wheel that turns only in quiet | The wheel (Shape) | clay | Pottery shapes across cultures | Plus |
| Leylek | The Europe–Africa flyway | Storks circling on thermals | Guiding storks (Guide) | feathers | Migration, the cities on the route | Plus |

Kaplıca (the hot spring) and Kitap (the library) stay in the pool with
the same treatment (a ritual plus a game: temperature mixing for
Kaplıca, story-ordering for Kitap); Arı (the bee island) is a candidate.

### 11.1 Ayçiçeği, home (yield, free)

Pofu's sunflower island; warm honey, sunflower yellow, sage. Signature:
the giant sunflower (garden L5) follows the real sun. Lore hook: "What is
behind the little round door?" (Pofu's den, which fills with keepsakes.)
Residents: Pofu, Mochi, Fındık, the frogs. **Toy:** boop Pofu; three fast
boops and he sneezes a seed off the edge into the clouds. **Game: Mochi's
tea orders** (Serve): residents arrive at the çay ocağı and you remember
how each takes their tea (strong, light, two sugars, a lemon slice for
the frogs); visitors from later islands bring their own customs (Tuli
wants it with a sugar cube in her teeth, the Finnish way; Sumi wants
matcha). Learning: tea around the world. Decor spots: the çay ocağı's
awning, the lawn, the pond edge, the door. Motif: a hummed four-note
lullaby that every later motif harmonises with.

### 11.2 İskele, the harbor (yield, free)

A tea-and-simit pier over the clouds; coral, cream, sea blue. Signature:
the little vapur docking after calm nights. Lore hook: "Where does the
ferry go?" (It is the route every returning island follows home.)
Resident: Simit, a honey tabby kitten who sells out by noon. **Toy:**
pull the horn cord: *düüüt*, the gulls lift, Simit covers her ears;
at dusk with a rumour active, a horn answers from the fog. **Game:
loading the vapur** (Pack): fit parcels, simit trays and a very
indignant goat into the hold; stage by stage the ferry gets bigger and
the cargo stranger. The ferry brings the postcards and every rumour
object: İskele is the archipelago's inbox. Learning: one line about the
place on each postcard.

### 11.3 Çağlayan, the island that pours (wonder)

A mossy limestone island in travertine cream, turquoise and moss, with a
waterfall pouring off its edge forever into the sea of clouds; the fall
is longer than the island is tall. **Lore hook:** "Where does the water
come from, and where does it go?" **Stages:** the fall starts; a hidden
spring behind it; Damla's leaf-boat chute; a mill under the falls that
grinds nothing, it just likes turning; the answer: the water falls into
the clouds, the clouds rain on every island, which is why the
archipelago is green. Keepsake: a jar of falls water that never empties.
**Resident:** Damla, an otter who tries to catch the waterfall in a cup.
**Toy:** drop a leaf boat in the stream; it goes over the edge, and days
later washes up on İskele's pier. **Game: leaf boats** (Flow): rotate
channel stones so boats reach the pools where Damla waits; later stages
add the spring (a second source), the mill (water must turn it), and
the edge (boats sent over it return in a few days). Material: water
drops. Echo: morning rainbows at home after calm nights. Unlock: 30
tended days and its rumours. Art: about 13 images; the water is code.
**Whoa:** water pouring off an island into the sky, and a boat that
comes back.

### 11.4 Ayna, the island under the clouds (wonder)

Ayçiçeği's reflection, hanging upside down beneath the cloud sea in
moonlight even at noon; moon blue, silver, lavender. **Lore hook:** "Why
is there a second round door, upside down, under the clouds?" **Stages:**
a dark mirror; it starts copying your stations in moonlight; a lantern
in its door; a rope ladder through the clouds; the answer: Ayna keeps
the island's quiet nights, and every calm night you have had is a lit
window. Keepsake: a small mirror. **Resident:** Pekmez, a fruit bat who
lives upside down and thinks you are. Polite about it. **Toy:** drop a
seed off the home island and it falls *up* onto Ayna. **Game: mirror
catch** (Trace): seeds fall from Ayçiçeği; trace the path of Ayna's
silhouette-Pofu so he catches them, in a world where up is down. Arrival:
the only camera flip in the game. Unlock: 20 calm nights. Art: the home
plate mirrored and regraded plus about 9 images. **Whoa:** impossible
geometry built from the user's own island.

### 11.5 Revontuli, the fox-fire island (wonder; Finland)

A snowy island with a lakeside sauna, a frozen pond and a single spruce;
night blue, snow, aurora green. In Finnish, *revontulet* (the northern
lights) means "fox fires": the old story says an arctic fox runs across
the fells and its tail sweeps sparks into the sky. **Lore hook:** "Who
paints the sky green?" **Stages:** the frozen pond; the sauna (steam
rises, Pofu emerges pink and proud); the ice-fishing hut; the fox's
tracks lead up the fell; the answer: the fox paints the aurora only on
nights when the island is quiet. Keepsake: a carved wooden fox.
**Resident:** Tuli, a small arctic fox, very serious about saunas.
**Toy:** brush snow off the spruce; it falls in a soft clump on Pofu.
**Game, two verbs:** *ice fishing* (Patience): drop a line, then put the
phone down; after 20 quiet minutes something has bitten (a fish, a lost
mitten, a message in a bottle); *painting the aurora* (Trace): swipe
Tuli's tail across the sky and your stroke becomes tonight's aurora,
which stays over the island until tomorrow. Learning: the real aurora,
Nordic sky lore, sauna customs. Signature: the aurora shader, shaped by
the player's own stroke. **Whoa:** you paint the sky, and the game rewards
putting the phone down.

### 11.6 Koke, the moss garden (wonder; Japan)

A small island of moss, maples and a dry stone garden, with a bamboo
water clacker (*shishi-odoshi*) that tips and clacks; moss green, maple
red, raked-gravel grey. **Lore hook:** "Why does the gravel move by
itself at night?" **Stages:** the stones; the clacker; a tiny shrine
gate; a maple that changes with the real season; the answer: a dormouse
rakes it every night, and the patterns are letters to the other islands.
Keepsake: a small rake. **Resident:** Sumi, a Japanese dormouse
(*yamane*) who sleeps through winter and apologises for it. **Toy:** tap
the clacker; it tips, clacks, and a koi rises. **Game: raking** (Trace):
trace calm wave patterns around stones to a template; each completed
garden is kept on the island until you rake the next. Learning: the 72
Japanese micro-seasons (*shichijūni kō*): every visit the garden's sign
names the real micro-season of the week ("the east wind melts the ice").
Moss greens on real rainy days. **Whoa:** calm made physical, and a
calendar that matches the world outside.

### 11.7 Yıldız, the star island (wonder; reworked)

A high, cold island above the cloud line with an observatory dome;
indigo, gold, snow. **Lore hook:** "Why are there more stars over Pofu's
island than anywhere else?" **Stages:** the dome; the telescope, which
tracks the real moon; the star book (a star per calm night: the v2
ritual, kept); seven stars make a constellation you name; the answer:
the constellations are a map of the outer ring. **Resident:** Nane, the
sleepy owl. **Toy:** spin the dome; on real meteor-shower nights the
shutter shows a shooting star. **Game: constellations** (Connect): join
stars to reveal a figure, then learn what three cultures saw in the same
stars (the Plough, the Great Bear, the Big Dipper, *Yedi Kardeş*).
Station ladders retired. Ritual kept (the 20-second stargazing, A21's
one exception).

### 11.8 Çanlar, the island of bells (wonder)

A narrow stone spire with wind bells of many sizes, bunting and poppies;
bronze, sky blue, poppy. **Lore hook:** "Who rings the bells in the fog?"
**Stages:** one bell; the frame; each bell turns out to play one island's
motif; a bell for every island you have; the answer: the bells were rung
long ago to call drifted islands home, and your calm has been ringing
them. **Resident:** Zil, a slightly deaf, very proud bell-ringer mouse.
**Toy:** tap bells; every combination resolves into harmony; ring them in
arrival order and they play the archipelago's song. **Game: echoes**
(Echo): Zil rings a phrase, you answer; phrases are folk tunes from the
islands' cultures. Every island's motif joins the bells when it arrives;
every later island's first rumour is heard as a new, unknown bell.
Unlock: three wonder islands.

### 11.9 Gezgin, the island on a whale (wanderer)

A little grassy island with one cottage, on the back of an enormous
sleeping cloud-whale; grey-blue, cream, dandelion. **Lore hook:** "The
map's edge moved. Something big is out there." **Stages:** the whale
stops at the outer ring; opens one eye; the cottage door opens; the whale
sings; the answer: she carries lost islands home, and now circles the
archipelago. **Residents:** Nazlı the whale, and Yosun, an old tortoise
postman who lodges in the cottage and brings the ferry's letters, slowly.
**Toy:** tap the blowhole: a cloud puff and a small rainbow. **Game:
whale song** (Echo, a call-and-response variant): answer Nazlı's song to
steer her to the next mooring. She moves only at night on a fixed tour,
is never highlighted, and nothing is gained by finding her. Unlock: 100
tended days, the archipelago's big milestone.

### 11.10 Emanet, the lost-and-found (wonder)

A crooked office on stilts at the end of the cloud current; weathered
teal, brass, brown paper. **Lore hook:** "Everything that falls off an
island ends up somewhere." **Stages:** a shack and an empty shelf; your
keepsakes arrive to be displayed; things you never knew were lost
arrive (Simit's umbrella, Mochi's spoon); a back room with a hand-drawn
map of the outer ring; the answer: it keeps what the archipelago lost
when it drifted apart. **Resident:** Boncuk, a magpie who loves shiny
things and must give every one back, which pains her beautifully.
**Toy:** ring the counter bell; Boncuk tells one keepsake's one-line
story. **Game: who lost this?** (Deduce): from small clues (a sesame
seed, a wet paw print, a smell of şerbet) return each object to its
owner on the right island. The museum, told through objects. Unlock: six
keepsakes.

### 11.11 Çömlek, the potter's island (wonder; from the idea node)

A red-clay island with a beehive kiln and a wheel; terracotta, ochre,
cream. Signature: the wheel turns only while the phone is down and stops
during a pass. **Lore hook:** "Something is being made slowly here."
**Stages:** the wheel; the kiln; the first pot (12 quiet hours); a shelf
of pots in a fixed sequence of shapes; the answer: Kil, a mole, has made
a pot for every island that came home. **Toy:** press a thumbprint into
wet clay; it stays forever. **Game: the wheel** (Shape): drag to pull a
pot up to a shape; shapes come from many cultures (an Avanos jug, a
Japanese tea bowl, a Greek amphora), each with one line.

### 11.12 Leylek, the stork island (wonder; from the idea node)

A reedy island with a chimney and a huge nest on the Europe–Africa
flyway; straw, white, black. Signature: storks circling on thermals in
spring and autumn. **Lore hook:** "The storks always come back. Where do
they go?" **Stages:** the chimney; the nest; the first feather; a lined
nest; the answer: Lale has seen every city on the route and leaves one
line about each. **Toy:** tap twice; the storks clatter their beaks
back. **Game: thermals** (Guide): tap to find rising warm air and lift a
young stork along the route, city by city. Returns every year; nothing
is missed (A7).

### 11.13 Proposed first year

| When | Islands | Why |
|---|---|---|
| Launch (free) | Ayçiçeği, İskele, with their games and decor; Çağlayan's rumours | The pair the founder chose; rumours open the first question |
| Season 1 | **Çağlayan**, **Ayna**, **Koke** | The founder's waterfall; the cheapest whoa; a first non-Turkish culture |
| Season 2 | **Revontuli**, **Yıldız**, **Emanet** | Winter: the aurora and the stars; by now everyone has six keepsakes |
| Season 3 | **Çanlar**, **Leylek**, **Çömlek** | Spring: the bells need three wonder islands; the storks return |
| Season 4 | Kaplıca, Kitap, and a native island for the next market | Autumn |
| Per user, around day 100 | **Gezgin** | The milestone wanderer |

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
| A21 nights are a dead end | Arrivals revealed after 06:00; no rounds at night; Yıldız's stargazing stays the exception |
| ADR-0017 | Nothing leaves; lapsed members keep everything |

## 13. Consequences for code and content

- **`PofuCore`:** yield ladders for the free pair (rescaled to scale A);
  Yıldız, Kaplıca and Kitap's nine ladders retired. New, all monotonic and
  tested: `IslandKind`, wonder stages (material, seeds, tended days),
  `RoundLedger` (earned, banked, daily cap, A26's automatic step-down),
  per-island `Material` balances, decor sockets and inventory, a
  `RumourLadder`, keepsakes. A `GameGrammar` protocol in a new
  `PofuGames` module, one type per grammar, deterministic and offline.
- **`PofuWorld`:** signature motions per island, the map's fog and rings,
  the arrival timeline, decor socket anchors.
- **Art:** five landform blockouts first; then 12–16 images per wonder
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
| 1 | Islands after the free pair produce nothing and are about play and secrets? | **Yes.** Small numbers forever, and Plus never sells progress |
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
