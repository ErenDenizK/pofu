# Game plan v1

**Status:** accepted; built in part (lead, 2026-11-05). This file is the single
source of truth for what the game is and when things happen. Where an older
doc disagrees (game-design, archipelago-system, island-curation,
story-delivery, minigames, design-loop 1 and 2), this file wins; those
stay as reference for the reasoning. Numbers come from `PofuCore` (scale A)
unless a row says "code follows the plan". Open choices are in section 9
with a recommendation each; unanswered ones proceed with it.

Why it exists: the founder (2026-11-05) found the loop, progression,
day-by-day pacing, story islands and UI not clearly planned. They were
planned, in about 16,000 lines across 30 docs written in rounds that
overwrite each other, and his 2026-11-04 notes (rising curve, about three
minigames, not every island a game, social early, life after day 50,
Çağlayan simpler, real character turns) were not folded into any of them.
The code also still runs the older archipelago (Yıldız, Kaplıca and Kitap
as station islands) while the design moved to wonder islands.

## 1. The game in five lines

1. **The moment.** A reflexive reach for Instagram, YouTube or TikTok meets
   Pofu. Resisting earns a seed and a play round; opening is allowed, never
   punished, but resets calm. Seeds never buy screen time (ADR-0015) and
   Pofu never dies (ADR-0017).
2. **Home works for you.** Ayçiçeği and its harbor are the only economy:
   stations level 1 to 5, producing seeds while you are away. A visit is one
   to two minutes: collect, see Pofu, build, maybe one round.
3. **Wonder islands are the story.** Hand-made, few, each a little better
   than the last. Each one is a story island, a game island or an upgrade
   island, never a seed sink.
4. **Three games, not fifteen.** Place (the garden), connect (flow) and
   recall (bells). Later islands reuse an engine with one new twist.
5. **Two voices.** Pofu and Mochi travel together and change: each has a
   turn the player sees.

## 2. Structure: two layers

| Layer | What | Pays in | Code today | Change |
|---|---|---|---|---|
| Home cluster | Ayçiçeği (garden, tea stall, pond, workshop, windmill) and İskele harbor (bagel cart, pier, lighthouse) | seeds, 2,788 to finish both | built | harbor opens day 3, not day 8 |
| Wonder islands | Section 4 | gifts to home (decor, a visible change), stamps, story | not built | new model: arrival day, stages, engine, beats |
| Station islands | Yıldız, Kaplıca, Kitap | seeds | built | **retire.** Yıldız becomes Mehtap; Kaplıca and Kitap park for year two |

Why retire them: home and harbor alone cost 2,788 seeds, more than the
typical user earns in 60 days (about 1,700), so they are enough seed sink
for Book One. A second kind of island that is "more stations" is exactly
the copy-feel the founder rejected.

How the home cluster grows from day 1 to the long tail (island level and
station caps, the re-budgeted ladders, pairs, residents, decor, materials,
the full bloom near day 60, seasons and mastery) is in
[home-progression.md](home-progression.md).

## 3. Day by day (the typical user)

Typical user: about one reach an hour awake, 60 % resisted, three short
visits a day (`GameScenarioTests`, `typical`). Seeds a day: about 15 in week
1, 24 in week 2, 29 by week 4, 37 by week 8. "Tended day" is any day with an
observed minute; days below are tended days, so a skipped day only pauses.

| Day | Seeds | Build (typical) | New | Story beat | Social |
|---|---|---|---|---|---|
| 1 | ~15 | garden L2 (5) | onboarding: pick the apps, first resisted reach, Pofu wakes; two garden rounds | Pofu and Mochi meet the player | none |
| 2 | ~15 | tea stall L1 (8) | tea stall opens (stage 2); the morning change starts (one visible change every morning) | a bell from the fog to the south | invite a friend (optional, once) |
| 3 | ~16 | bagel cart L1 (25, often day 4) | **the harbor's fog lifts**: Simit and the goat arrive | Simit's first request on the noticeboard | a friend's boat can dock at your pier |
| 4 | ~16 | tea stall L2 | pond opens (stage 3); first calm-night bonus noticed | Pofu brags (his cocky start) | |
| 5 | ~17 | garden L3 | | a snoring mossy hump on the horizon (Koke rumour) | |
| 6 | ~17 | pier L1 (40) over two days | **Koke arrives** (story island) | the sleeper: visit it to wake it | |
| 7 | ~18 | | week page in the Seyir defteri; first stamps | | the weekly postcard to friends |
| 8 | ~22 | bagel cart L2 | Koke wakes on the third visit and leaves moss decor at home | water noise stops somewhere (Çağlayan rumour) | |
| 9 | ~23 | pond L2 | | Mochi worries about the silence | |
| 10 | ~24 | workshop L1 (30) | **Çağlayan arrives**: the flow game debuts; workshop (stage 4) and lighthouse open | reconnect the stopped streams, one stage a day at most | |
| 11-13 | ~24 | one level a day | Çağlayan stages 2 to 4 | | |
| 14 | ~25 | | Çağlayan restored: a waterfall pours off home's edge (the signature animation) | week 2 page | shared streak opens if a friend is paired |

From week 3 the rhythm is set: a rumour two days before each island, one
stage a day at most, a gift to home when an island is done, a week page
every seventh day. About 50 levels are built by day 60 with rounds, 36
without.

## 4. Book One: the islands (rising curve)

The canonical order, stages, residents and layouts are in
[book-one-islands](../design/book-one-islands.md); this section is its
summary. The rules come from the founder (2026-11-05): Gezgin (the whale
Nazlı) comes early as the travel companion and carries the player, growing
toward her godlike form; islands split into main-story and filler (Çanlar is
a filler); arrival days are not fixed, the gates are order, the previous
bloom and quiet days, so "around day N" is only the typical day. The story
rules are in
[story-references](../research/story-references.md#synthesis-the-story-rules-these-give-pofu).

Each wait is a little longer, and each island a little bigger than the one
before (peak score 3 to 6; the founder's 10 is Gezgin's grown form, never
day 8).

| # | Around day | Island | Type | The one idea | Turn | Peak |
|---|---|---|---|---|---|---|
| 0 | 1-3 | Ayçiçeği + İskele | home | the garden puzzle; the harbor wakes | | |
| 1 | 6 | Koke | main, story | a moss creature asleep; three visits wake it | | 3 |
| 2 | 10 | Çağlayan | main, game: **flow** debut | a waterfall that stopped; reconnect its streams (only this; the windows-into-hours idea is cut) | Mochi is afraid of the drop | 4 |
| 3 | 16 | Emanet | main, story | the lost-and-found; return things to residents | **Mochi lets go** of something kept | 4 |
| f | 23 | Çanlar | **filler**, game: **recall** debut | the four-note call of the bells; one or two visits | **Pofu learns to wait** (a feeling, never lore) | 3 |
| 4 | 30 | Revontuli | main, game: flow + light | a ruin under the aurora, night only; carry the sauna's warm light to the lantern | | 5 |
| 5 | 37 | Arı | main, upgrade (place + bees) | the hive comes to home: bees over Ayçiçeği, flowers change | | 5 |
| 6 | 41 | Mehtap | main, game: flow (moon line) | the dark stars; the last main island | the darkest night before the release | 6 |
| - | 45 | Gezgin finale | finale, none (the four notes are heard) | Nazlı's grown form; the finale is the night of Mehtap's stage 4 | **both**: the duo's promise | 6 |

Gezgin is not only a destination at the end: she carries the player from
early on, one detail grows on her back with each main island, and her grown
form arrives on Mehtap's finale night. Four islands play (Çağlayan, Çanlar,
Revontuli, Mehtap), Koke and Emanet tell, Arı changes home, and the book
ends around day 45, as the founder asked; few reach it, and nothing on it
is required to keep the shield working.

## 5. The three games

| Engine | Verb | Debut | Reused | Code |
|---|---|---|---|---|
| Garden | place | home, day 1 | home every day | built (`PofuGames`), in the home flow (the station sheet's Play opens it) |
| Flow | connect | Çağlayan, day 10 | Revontuli (light), Mehtap (moon line) | new |
| Recall | listen and repeat | Çanlar, day 23 | Book Two islands | new |

Rules for all three: 30 to 90 seconds, no failure, no timer pressure,
rounds come from resisting (2 a day, plus one per resisted reach up to
six, at most 12 played), none at night. A round pays 2 to 5 seeds today;
on a wonder island it pays that island's progress instead.

## 6. After day 45 (Book Two and the long tail)

- **Seasons.** Every six weeks one new wonder island (Fanus, Çömlek, then
  Kitap, which opens year two), delivered as app updates. Mehtap, tied to
  the real moon, is not here: it is Book One's last main island and its
  stage 4 is the finale night (section 4). Each reuses an engine with one twist.
- **Home keeps living.** Seasonal events on Ayçiçeği (storks in spring, the
  first snow), visitors, the decor collection, the last levels of the
  harbor (about 2,788 seeds in all means the typical user is still
  building in month three).
- **Friends grow.** Weekly postcards, shared streaks, later a small league
  (Phase 5).
- Nothing in the tail is a daily obligation. Missing a week costs nothing.

## 7. Social, from day 2

The founder wants friends early. The rule that keeps it calm: social never
gates progress and never asks for opens.

| Day | What |
|---|---|
| 2 | one optional invite (a link) |
| 3 | a paired friend's boat docks at your pier; tap to see their island postcard and wave |
| 7 | the weekly postcard: what each of you built and resisted, in words, no ranking |
| 14 | a shared streak: days you both kept your reaches under your own goal |
| Phase 5 | leagues, only if the dogfood shows they help |

Needs an ADR (CloudKit sharing, serverless pairing, ADR-0005 amended).

## 8. Screens and UI assets

Rule (ADR-0018): world objects are painted, chrome is native. A painted
master ships only where the player touches the world (jar, lantern, pots,
game pieces, stamps, the paywall plate); buttons, sheets and icons in
menus use SF Symbols and `PofuSkin`. So most `icon-*` masters stay unused
on purpose, and Codex stops drawing chrome.

| Surface | View today | Needs | Painted assets |
|---|---|---|---|
| Home | built | none for the garden (the station sheet's Play opens it) | jar, lantern, pots: 3 of 9 integrated; integrate the 6 approved |
| Harbor | map only | a walkable scene like home | plate, Simit, goat, ladders: masters exist |
| Map | none | islands, rumours, arrival | map plate (exists), rumour card |
| Wonder island | none | arrival, stages, the game door | per island, in its own batch |
| Game round | garden built | flow and recall engines | pieces per engine |
| Seyir defteri | none | week pages, stamps | stamps, page paper |
| Today and week | Today built | week page | none |
| Shield | built | mood images bundled | Pofu moods (exist) |
| Paywall | none (Phase 6) | | paywall plate |
| Widget, app icon | none (Phase 4, 6) | | widget art, app icon |

UI art still to make: game pieces for flow and recall, stamps, the
celebration card, the paywall plate, the widget and the app icon. Batch 11
in the art queue is rewritten to this list.

## 9. Open choices (recommendation first)

1. **Three engines: place, connect, recall.** Alternative: flow only, with
   twists. Recommend three; one engine for a year would feel thin.
2. **Gezgin early as the carrier, grown form at the finale (around day
   45, Mehtap's night).** Decided by the founder (2026-11-05). Alternative:
   her grown form at day 8 as the hook; a 10 at day 8 makes everything
   after it smaller, which the founder named.
3. **Two voices (Pofu and Mochi).** story-delivery recommended Pofu alone;
   the founder asked for a duo twice. Recommend the duo.
4. **Retire the station islands.** Recommend yes (section 2).
5. **Where the free part ends.** Decided by data (founder). Candidates:
   after Çağlayan (day 14) or after Emanet (day 20). Measure in the beta.

## 10. What changes in code and docs (in order)

1. `PofuCore`: harbor unlock to tended day 3 (tea stall L1); retire
   Yıldız, Kaplıca, Kitap; a wonder-island model (arrival day, stages,
   engine, beats, gift); tests re-banded (İskele day 3, islands by day).
2. Game round in the production home flow (done: the station sheet's Play opens it).
3. Map view with rumours; Koke as the first story island (no new engine).
4. Flow engine and Çağlayan.
5. Content: `content/stations/*.yaml` still carry pre-scale-A prices;
   regenerate them from code. Fix the `Archipelago.swift` rate comment
   (says 0.03, code is 0.02).
6. Art queue: rewrite batch 11 to section 8's list; island batches follow
   the order in section 4.
