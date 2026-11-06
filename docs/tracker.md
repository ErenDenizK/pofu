# Tracker: every thread, decision and half-finished item

_Producer's view, 2026-11-06 (main at #265). For the founder, who asked for
one clear picture of everything discussed since 2026-11-01. The spine is the
[founder input log](product/founder-input.md); statuses were checked against
the code in `Packages/PofuKit/Sources` and `App/`, the open PRs and the
[art queue](design/art-production-plan.md). The lead updates this page when a
status changes; the [roadmap](roadmap.md) keeps the next step per track._

Status words: **built** (on main, in the app) · **in PR** (open PR) ·
**queued** (a READY art row or a named next step) · **designed only** (a spec,
no code) · **talked only** (in the log, no spec) · **dropped**.

## 1. Where we are

- A playable Rehearsal build: home island IL1-IL10 with stations, the harbor, daily visitors and the quiet-day letter, the garden game, Koke as the first wonder island (stages 0-2 painted), light and shadow v2, sky and fog (SW-1, SW-3), a painted gate landing (#265).
- The Screen Time gate (`PofuLive`) is built and waits for the membership (after 2026-11-24).
- Art: Codex has delivered about 50 batches; production rows P1-P4 are done; nine art PRs and two doc PRs are open (§2.14).
- The founder has not tested on the phone since 2026-11-05. Everything since then (shadows, night light, ceremony, Koke, sky, gate) is unchecked on the device.
- Biggest gaps: Pofu's own emotions (the rig art exists, the code shows one face), residents never move, the world is almost silent, and Çağlayan and the flow game are not started.
- Plans are strong for home growth, but phases C-G of [home progression](product/home-progression.md#123-build-order) (residents, decor, pairs, bloom, seasons) have no code.
- The Book One story map ("Bekçi kim?", two pages) was made and shown to the founder on 2026-11-05, but not committed; this tracker then wrongly called it never made. Committed and made canonical on 2026-11-06: [story map](product/story-map/book-one.md).

## 2. Threads

### 2.1 Light and colour

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Colour script and material library (rose copper stays) | the hour grades, five cells | built | none | 2026-11-02 · [colour script](design/colour-script.md) |
| Harmony grade instead of regenerating | measure and grade before regenerating | built (`harmony.py`) | none | 2026-11-02 |
| Paleness and vividness | vivid regrade, less haze in the centre | built (#174, #200); founder still found it soft | a device check of the vivid round | 2026-11-04, 2026-11-05 |
| Light standard thresholds | warn-only until the light pilot | built, **still warn-only** | flip `enforce` or record why not | [light standard](design/light-standard.md) |
| Sun shadows, ambient pads | LS-1 | built (#222); faint at the default zoom | tune on the device | [light and shadow v2](design/light-and-shadow-v2.md) |
| Harmony with near-game concepts | lookdev sheet, hierarchy lint | built (#254, #258) | run it on every promoted prop | 2026-11-06 |
| No hard-edged light, round falloff | a rule | built for Koke (#256) | apply to every source | 2026-11-06 midday |

### 2.2 Night

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Light from real sources (lantern, window) | yes | built (#229, #247: lighthouse, path lamp, Mochi's door) | the rest of the stations' lights | 2026-11-05 night |
| Night as its own system (relight with normals, hemisphere ambient, bounce) | prototype offline first, then an ADR, then Metal | nightlab built (#257); light-direction takes in PR #270; night key merged (#262) | tune nightlab to the night key and real normals; write the ADR | 2026-11-06 third · [research](research/night-lighting-2d.md) |
| Every structure carries a light | a design rule | designed only | add to the station sheets in home layout | 2026-11-06 fourth |
| Pofu's normal map too angular | his own tuning | queued (batch-47) | after the pilot's normals | 2026-11-06 midday |
| The island's underside lit as a volume | yes | designed only | with the roots (#267) and nightlab | 2026-11-06 midday |
| Hero night variants for a few structures | tiered: relight first | talked only | after the ADR | 2026-11-06 fourth |

### 2.3 Sky and weather

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Sky layers, luminous night, depth fog | SW-3 | built (#256) | device check | [sky and weather v1](design/sky-and-weather-v1.md) |
| Weather (shuffled bag, every weather within 14 days) | SW-2 | designed only; sprites in PR #266 | merge #266, then `Sky/Weather.swift` | 2026-11-06 fourth |
| The screen haze is the player's (unwell state) | yes | designed only (SW-2) | with SW-2 | 2026-11-06 fourth |
| Real-world weather | opt-in later | talked only | none before launch | 2026-11-03 |
| The beautiful wound (bad state impressive, not pale) | a rule | built for Koke stage 0; targets merged (#262) | repaint Koke 0-2 under the rule | 2026-11-06 later |

### 2.4 The gate and the shield (top design priority)

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Gate v2 day-1 flow, onboarding, shield anatomy | the 2026-11-01 spec | built in `PofuLive` (#34, #41); waits for the membership | membership day 1 | [gate v2](product/ux/gate-v2.md) |
| The gate as a design masterpiece | a painted living scene | landing built (#265); concepts in PR #268 | pick a direction from #268; the "gate v2 (masterpiece)" spec named in the log was never written as a doc (§5) | 2026-11-06 midday later |
| Shield icon: Pofu's mood at his door | three moods | built (calm, sleepy, proud); six in #268 | merge #268, choose | gate v2 §5.3 |
| Breathing break, the hard limit | ADR-0015 | built | none | ADR-0015 |
| Loading screen | an honest launch | built (#192) | none | 2026-11-05 night |

### 2.5 App flows

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Onboarding (pick apps, first resisted reach, Pofu wakes) | gate v2 §3 | partly built (old `OnboardingView`) | redo in the gate's look | roadmap App track |
| Today page | a sticker for the day's mood | built (#239) | real stickers (#253) | UI audit |
| Week page sharing the sky | yes | **talked only**: the weekly recap opens Today | a design note, then build | 2026-11-06 fourth |
| Widget | shares the sky | **not started** (no widget extension) | after the week page | roadmap Later |
| Live Activity for passes | gate v2 §7.1 | not started | after membership day 1 | gate v2 |
| Map and navigation (one camera, no three-way dial) | experience v1 §1 | built (#193); the map frame shows home and Koke | rumours on the map for the next islands | 2026-11-05 night |
| Direct touch, brushing | yes | built (#193) | none | 2026-11-05 night |
| Menus: painted plus glass | both | built (#183, #192, #239) | the garden game's chrome (§3) | 2026-11-05 night |
| Merge `Pofu` and `PofuLive` | after day 1 | queued | membership day 1 | roadmap |

### 2.6 Home growth

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Island level 1-10 caps the stations | ADR-0019 | built (#182) | none | [home progression](product/home-progression.md) |
| Every level a living, visible change | yes | partly: art for most steps (#235) | the IL1-IL10 sheet (§3) | 2026-11-05 overnight later |
| Level-up ceremony with glowing lights | yes | built (#240) | device check; a sound | 2026-11-05 |
| Level-up card, capped sketch, IL banner | phase B | celebration card built (`CelebrationCard`); capped sketch and banner not checked | check against §4.4 | home progression §12.3 |
| Residents assigned to stations, hearts | phase C | hearts count visits; **no assign sheet** | phase C after the dogfood | home progression §6 |
| Free decor spots, decor sets | phase E | **gifts store decor ids, nothing can be placed** | a decor-spot model in `PofuCore` | 2026-11-02 · home progression §8 |
| Pairs, full bloom (Tam Çiçek), the hilltop | phases E-F | designed only; concepts merged | after decor | home progression §4.5, §5 |
| Mastery L6-L10, seasons | phase G | designed only | Book Two | home progression §9-§10 |
| Station style options | Codex art (batch-40) | three baked; **no picker** (#247) | a picker once every level has art | handoff 2026-11-06 |
| The roots (the island's underside grows) | proposed | in PR #267 | founder view, then batch-49 | 2026-11-06 |
| Island base too squashed | a deeper earth body (`island-main-l-v3`) | queued in 2026-11-02 notes; not re-checked since | fold into the roots (#267) | 2026-11-02 · art plan "What batch 03 taught" |

### 2.7 Story islands

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Koke, first wonder island | playable prototype | built (#244, #250); stages 3-4 and stretch art promoted (#263) but **not in the app** | integrate them; repaint 0-2 | [Koke prototype](design/koke-prototype.md) |
| Çağlayan and the flow game | day 10, flow debut | art in PR #264; **no game-design note, no engine** | the flow note | game plan §4-§5 |
| Healing arc per island, never one rule for all | variety table | designed (#223) | used by #271 | [healing arc](design/island-healing-arc.md) |
| Book One island sheets | under the story map | merged (#271), **rewritten to the story map** 2026-11-06 (Arı a home upgrade, Olta the midpoint, six fillers) | one template page per filler when scheduled | [book-one-islands](design/book-one-islands.md) |
| Main islands vs fillers; Çanlar is a filler | yes | done: game plan §4 follows the story map | none | 2026-11-05 |
| Book One story map (main islands, fillers as branches) | **canonical** | made and shown 2026-11-05; committed and reconciled 2026-11-06 | the open decisions in its §8 | [story map](product/story-map/book-one.md) |
| Constellations, a design language per cluster | working draft | designed only | in the island sheets | 2026-11-03 night |
| About 50 hand-made islands over time, no procedural islets | yes | standing | none | 2026-11-02 |
| Wonder-island model in `PofuCore` | game plan §10 | built (`WonderIslands.swift`) | Çağlayan as the second entry | game plan §10 |

### 2.8 Residents and visitors

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Someone visits every day, one reason a visit | experience v1 §5 | built (#201, #212) | device check over three days | 2026-11-05 night |
| Invitations and the quiet-day letter | yes | built | a gift card when a parcel opens (UI audit "no") | experience v1 §5 |
| Resident reactions by mood | rig poses | built (#236, #247) | none | P3 |
| Residents at natural work, walking, moving | residents at work concepts | **not built**: residents swap still poses and never move | §3 | 2026-11-05 overnight later |
| Animal Crossing relationships (talk, visit each other) | wave 3 | **not started** | ten scenes with `pofu-story` | 2026-11-05 late night |
| New residents (Damla, Tuli, Boncuk, Nane, Yosun) | concepts | concepts merged; Damla in #264 | with their islands | backlog B5 |

### 2.9 Pofu (and Nazlı)

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Procedural life (breath, blink, squash) | ADR-0011 | built (`PofuCompanion`) | none | [companion motion](design/companion-motion.md) |
| More reactions, a rig of parts | a rig like the residents' | **rig masters exist (mouths, ears, paws, cheeks: about 20) but the app draws one base image with lids**; only cheeks-puff is used, in the garden | wire the rig (§3) | 2026-11-02 |
| Pofu and Mochi as a duo | yes | in lore; scenes not written | resident scenes | 2026-11-05 |
| Gezgin (Nazlı) as a layered rig | yes | rig masters merged (#232); **not in the app** | a rig view on the harbor | 2026-11-05 late night |
| Gezgin form 1 faces the camera, clear of the pier | yes | queued as a note for the next variation | next Gezgin batch | 2026-11-05 late night |
| Gezgin comes early; two forms | yes | decided; game plan table still says finale (§5) | rewrite the table | 2026-11-05 |

### 2.10 Mini-games

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Three engines: place, connect, recall | about three are enough | place built; flow and recall not started | flow note | 2026-11-04 night · game plan §5 |
| The garden reachable without the dev menu | yes | built (station sheet "Play") | none | 2026-11-05 test |
| Garden pause and result buttons | in-game chrome | **left raw glass** (UI audit "no") | a game-UI pass | UI audit |
| Not every island needs a game | yes | standing | none | 2026-11-04 night |
| 5-10 minute sessions vs the 90 s guardrail | open | talked only | decide (§6) | 2026-11-02 |

### 2.11 Story and lore

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Lore bible, deep lore | drafts | merged (#177) | founder's questions (Ihlamur, Koke as Nazlı's mother) | 2026-11-05 evening |
| Loop decisions folded into lore and delivery | needs his yes | **PR #135 open since 2026-11-03** | close it (§3) | 2026-11-03 |
| Characters should turn more (Pofu, Mochi arcs) | yes | in game plan §4 turns | write the beats | 2026-11-04 night |
| Simple surface, a bigger mystery behind | yes | in deep lore | none | 2026-11-03 night |
| Social layer early in the story | yes | Gezgin postcards only; friends are "Later" | a design note | 2026-11-04 night |
| Human writing (he and friends write banter) | yes | `pofu-story` skill, story tests | his friends' first pass | 2026-11-03 |
| Research: Genshin, Zelda, Naruto, One Piece | done | merged (#165, #169) | none | 2026-11-05 |

### 2.12 UI system, icons, stickers

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| No makeshift controls | audit | built (#239), three "no" rows left | §3 | [UI audit](design/ui-audit-2026-11-06.md) |
| Flat menu icons (not glass) | Codex draws, vectorise later | in PR #269 | choose, then replace the place control's glyph | 2026-11-06 midday |
| Stickers and emoji in the game | letters, reactions, week page | code with SF stand-ins built (#239); art in **PR #253, open** | merge #253 | 2026-11-05 overnight later |
| Codex's concepts in use | inventory | built (concept inventory); top 15 not wired | wire the first five | [inventory](design/concept-inventory.md) |
| App icon | ready for the build | built (#167); candidates in inventory | App Store pass | 2026-11-05 |
| Dynamic Type, VoiceOver | full pass | partial (labels on main views) | §3 | roadmap |

### 2.13 Sound and haptics

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Sound B (tiny sounds on, ambience optional, procedural music) | yes | garden cues and collect only; **the world is silent** | §3 | 2026-11-02 · [sound identity](design/sound-identity.md) |
| Haptics confirm, never decorate | `PofuHaptics` | applied in sheets, Koke, Hop | the remaining moments | experience v1 §3.3 |

### 2.14 Art pipeline and Codex

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Codex never idles; production before explorations | yes | running | lead merges in rounds | 2026-11-05 |
| Open art PRs | | #253 stickers, #259 props v2, #264 Çağlayan, #266 weather, #268 gate, #269 icons, #270 light direction | one review round, merge in that order | open PRs |
| hive-4/5, windmill-1 lit, frog, guest door, simit sticker | parked | blocked on a lead review | a palette or profile fix | queue row 0-x |
| Queue rows 4 (`batch-11-ui`) and 5 (`batch-08-decor`) | | blocked with no manifest since 2026-11-02 | rewrite or drop (§5) | art plan |
| Imagegen recovery tool | | **PR #108 open since 2026-11-03** | close (§3) | #108 |
| Art account provenance | before launch | standing | Phase 6 | standing |

### 2.15 Performance and battery

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Stutter and heat on the device | optimise | fixed in #166; frame policy (#194) | **re-measure on device after shadows, sky and night** | 2026-11-05 test |
| 60 fps beta, 120 Hz when touching | yes | 60 built; 120 waits for measurement | frame meter run | 2026-11-05 night |

### 2.16 Business

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Prices 349,99 a year, 999,99 for life | approved by the founder | in v2 | none | 2026-11-02 |
| One membership, 129,99 a month, nothing taken back | proposal | waits for him | §6 | [monetization v2](product/monetization-v2.md) |
| Where the free part ends | by data | beta | TestFlight | 2026-11-02 |
| Türkiye first, priced abroad | yes | standing | App Store pass | 2026-11-02 |
| Why idle games win in Asia | research | **talked only** | one short study, or drop | 2026-11-02 |
| App Store assets, privacy, domain | launch | not started | after the beta | roadmap |

### 2.17 Process and tooling

| Thread | Decided | Status | Next step | Source |
|---|---|---|---|---|
| Opus plans, Sonnet builds, Haiku looks; three agents | yes | in CLAUDE.md | none | 2026-11-05 |
| No dated phases; tracks in parallel | yes | roadmap table | keep it current | 2026-11-06 |
| English identifiers everywhere | at a quiet window | **map on `refactor/english-rename-map` (2026-11-03), never opened as a PR** | §3 | 2026-11-03 |
| Pofu Hub (questions, status, roadmap) | most questions in chat | **frozen since 2026-11-03**; chat is the channel | none | CLAUDE.md |
| Hub dictation | Whisper | built (#66), then simplified away (dfcb5685) | none unless he asks | 2026-11-02 |
| Housekeeping, stale docs | one pass | done (#213); a second pass running | none | 2026-11-05 |

## 3. Half-finished and forgotten

The founder asked for each of these. None has a built result, or its next
step is not on any track. Ordered by what he would notice first.

| # | Item | Where it stands | Why it stalled | Cheapest next step |
|---|---|---|---|---|
| 1 | **Shadow tuning on the device** | Sun shadows read faint at the default zoom (handoff). | No device test since 2026-11-05. | Add the shadow, ceremony, sky and gate checks to the next install note; tune `ShadowTuning` from his screenshots. |
| 2 | **Residents' natural work, movement, animation** | **Built (#277):** a seeded 8 s loop per resident (work beat, short walk out and back on the walkable polygon, breath, glance), a 1.2 s tap reaction; only in the Ambient state. Missing: walk-cycle sprites, Simit and the goat. | Every wave chose light and art integration first. | Walk-cycle art for the residents who walk; then Simit and the goat. |
| 3 | **Pofu's emotions** | **Built (#277):** Pofu's face changes by mood (seven moods compose six rig parts: mouths, droop ears, a waving paw; `tools/art/pofu_rig_patches.py`). Missing: stronger expression art; cheeks, eyes and the other paws are not wired. | The rig was published, then the work moved to the world. | Stronger expression art, then wire cheeks and eyes by mood. |
| 4 | **Home growth seen level by level (IL1 to IL10)** | A roadmap step; no sheet exists. | Asked twice; always behind light work. | A screenshot-harness target that renders IL1-IL10 at noon. One test file. It also answers "IL1 sparse". |
| 5 | **IL1 sparse** | Known gap since the 2026-11-06 handoff. | It needs decor that has no placement model. | Place 3-4 existing approved props as fixtures at IL1 (no decor system needed); check them on the IL strip. |
| 6 | **Sound** | Garden cues and collect only. No sound for level-ups, visitors, the ceremony, Koke or ambience. Sound B was decided 2026-11-02. | No owner; not on the tracks table. | Render 5 cues with `tools/sound/render.py` (level-up, visitor arrives, gift opens, Koke wakes, the evening bell); play them through `SoundEngine`. |
| 7 | **Stickers and emoji in the game** | The code and slots are built; the art is promoted in **PR #253**, not merged. | A Codex PR waiting for the lead's round. | Merge #253. The swap is by file name, so no code is needed. |
| 8 | **Visitors** | Built. Missing: a card when a gift opens, resident-to-resident scenes (wave 3) and a sound. | Wave 3 never started. | A gift card (stickers ready); then ten scenes with `pofu-story`. |
| 9 | **The level-up ceremony** | Built (#240). He has not seen it on the device, and it has no sound. | Device test. | The install note plus the level-up cue from item 6. |
| 10 | **The station sheet clipping** | Level card clipped (handoff 2026-11-06). Not fixed. | Small, and fell between waves. | One SwiftUI fix in `StationSheet.swift` with a screenshot. |
| 11 | **The garden game buttons** | Pause and result still use raw glass (UI audit "no"). | Left for a game-UI pass that was never scheduled. | Move them to `ClayButtonStyle`, the game's own style. One PR. |
| 12 | **The style-option picker** | Three options baked; no picker (#247). | Only 3 of the batch-40 options are on main. | Decide: offer styles only at levels with art, or drop the picker until Book Two. |
| 13 | **The Gezgin rig** | Body, tail, fins, patch and eyes-closed masters merged (#232). No code. | Gezgin's place in the story moved (early vs finale), and nobody owns her. | A `NazliRig` view: parts with code motion (tail and fin sine, body bob). Show her at the harbor on postcard days. |
| 14 | **The week page** | The weekly recap opens Today. No week page exists. The sky-sharing widget waits for it. | No spec. | A half-page note: what a week shows (resisted reaches, visitors, stickers, the week's sky strip). |
| 15 | **The map** | The archipelago frame shows home and Koke. No rumours appear for the islands to come. | The island order is now fixed by the [story map](product/story-map/book-one.md). | Show one rumour marker for the next island from `WonderIslands`. |
| 16 | **Letters** | The quiet-day letter is built. Emanet's letters and Gezgin's postcard as a readable letter are not. | Waits for Emanet. | Give the postcard a letter card (the invite sheet's layout with a sticker). |
| 17 | **Seasons** | Concepts merged (B-D, B4, v2s). No code. Real calendar recommended, not confirmed. | Phase G, after the dogfood. | Confirm the real calendar (§6). Then a `Season` value in `WorldClock` that tints the grade, before any art. |
| 18 | **Haptics** | Partly applied. | Not reviewed since experience v1. | A table of every moment against `PofuHaptics`, then fill the gaps. |
| 19 | **Accessibility** | Reduce Motion is honoured widely; VoiceOver and Dynamic Type are partial. Never audited. | Always "later". | A Haiku audit of the screenshots plus a VoiceOver label sweep. Required before the beta. |
| 20 | **Lore PR #135** | Open since 2026-11-03, "needs the founder's agreement". The game plan and deep lore have moved past it. | It was never put to him, and it is now stale. | Close it with a note. Carry its two live ideas (the duo's delivery rules, the Bekçi spine) into the lore bible in one fresh PR. |
| 21 | **Imagegen PR #108** | Operator recovery tool, open since 2026-11-03. The pipeline has run without it for 3 days. | Not needed in practice. | Close it unmerged. Reopen only if a Codex run loses work. |
| 22 | **The story map** | Made and shown 2026-11-05 (two pages), never committed; wrongly listed here as never made. | Not committed the day it was shown. | Done 2026-11-06: committed as the canonical Book One doc; island sheets, roots, game plan and deep lore reconciled to it. |
| 23 | **Koke stages 3-4 and stretch** | Promoted (#263), not in the app (code fallbacks show). | Landed after #250. | Add them to `integrate.py` targets; delete the fallbacks. |
| 24 | **Çağlayan and the flow game** | Art in PR #264. No design note, no engine. | Waiting on the note. | The flow note (one Opus pass), then `PofuGames` flow. |
| 25 | **English identifier rename** | The map branch has existed since 2026-11-03; there is no PR. | Codex never drains, so no quiet window comes. | Plan the window: one Codex pause after a batch, three PRs (assets, Swift, docs). Or drop it and keep Turkish ids as proper names. |
| 26 | **Decor placement** | Gifts store decor ids that can never be placed. | Phase E. | A minimal `DecorSpot` model with three spots, so a gift ends up somewhere. |

## 4. Improvements we should make

| # | Area | Improvement | Value | Cost | Grounded in |
|---|---|---|---|---|---|
| 1 | Process | **A weekly device ritual**: every Friday one TestFlight or Xcode install, a fixed checklist and his screenshots back. | Everything since 11-05 is unchecked on the device; it closes items 1 and 9 of §3 at once. | Low | handoff "the founder's device test sets priorities" |
| 2 | Animation | Wire Pofu's rig parts by mood. | His main character gains emotions; the biggest feel gain per hour. | Low-medium, no art | masters `pofu-mouth-*`, `pofu-ears-*` |
| 3 | Animation | Resident idle loops and short walks on the walkable polygon. | The island feels alive; Cats & Soup's core charm. | Medium, no art | `WorldGeometry.walkable` |
| 4 | Sound | Five world cues, plus one ambience bed per hour (procedural chords). | The world is silent; sound doubles the ceremony. | Low-medium | `tools/sound/render.py`, Sound B |
| 5 | Visual | An IL1-IL10 strip in the screenshot harness, run on every PR that touches home. | It makes "every level a living change" testable. | Low | roadmap Home growth |
| 6 | Logic | The flow audit test: days 1-21 for a typical player and a heavy scroller; fail on a dead day. | It guards the pacing he cares about most ("no waiting"). | Low | roadmap Game flow |
| 7 | System | A `Season` and `Weather` value in `WorldClock` before any art (grade tint, fog density). | It unlocks SW-2, seasons and the week page's sky with one model. | Medium | sky and weather §2.2, home progression §10 |
| 8 | Pipeline | Auto-integrate promoted masters that already have an `integrate.py` target, in the same PR. | Promoted art stops waiting in limbo (Koke 3-4, Nazlı, stickers). | Medium | #263 vs #250 |
| 9 | Pipeline | Light standard: switch `enforce` on for production jobs. | Catches washed art at QA, not by eye. | Low | light standard (warn-only "until the pilot") |
| 10 | Design | Gift card and letter card as one component with a sticker slot. | Closes two UI audit rows and the postcard letter. | Low | UI audit |
| 11 | Design | Pick one gate direction from #268 within a day, then build it fully before more concepts. | The top design priority stops being concepts. | Low decision | 2026-11-06 midday later |
| 12 | Technical | Profile the frame meter with night relight and sky on an A-series iPhone before the Metal port. | Avoids a repeat of the 11-05 heat. | Low | roadmap Health track |
| 13 | System | `PofuHaptics` and `SoundEngine` behind one `Feedback.moment(_:)` call. | Every moment gets both at once; no gaps. | Low | experience v1 §3.3 |
| 14 | Logic | A minimal `DecorSpot` model (three spots) and placing gifts. | Visitor gifts start to mean something; opens phase E. | Medium | `VisitorLedger.decor` |
| 15 | Docs | Rewrite game plan §4's table to the 2026-11-05 decisions (Gezgin early, Çanlar a filler, no fixed days). | The canonical doc no longer contradicts itself. | Low | game plan §4 note |
| 16 | Accessibility | A VoiceOver pass on the world (stations, visitors, Koke) with `accessibilityLabel` from `WorldStrings`. | Required for App Review quality and the ADA bar he cited. | Medium | roadmap App track |
| 17 | Codex | Retire queue rows 4 and 5 (no manifest since 11-02), or write their manifests. | The queue stops showing dead rows. | Low | art plan |
| 18 | Visual | Wire the inventory's top five concepts (Tam Çiçek, IL10, night party, Gezgin f2 night, duo arrival) into the level-up card, the gate and onboarding. | His ask to use Codex's concepts, done visibly. | Low-medium | concept inventory |
| 19 | Product | Write the week page note. | It is the meeting point of app and game (stickers, sky, the readout). | Low | 2026-11-06 fourth |
| 20 | Process | A tracker refresh at each handoff (this page), not a new summary. | He keeps one picture. | Low | this request |

## 5. Conflicts and drift

| Where | Conflict | Resolution |
|---|---|---|
| [Game plan](product/game-plan.md) §4 and §9.2 vs the log (2026-11-05) | The table still has Gezgin as the day-45 finale, Çanlar as main island 4 and fixed days. The note on top says they are superseded. | Rewrite §4 from #271's arc; drop the days column. |
| Game plan §5 and §8 vs the code | They say the garden is "only reachable from Rehearsal". The station sheet's "Play" opens it in the production flow. | Change the row to "built, in the home flow". |
| Log 2026-11-06 midday later vs the docs | The log says "handled: the gate v2 spec". No such doc exists. [gate v2](product/ux/gate-v2.md) is from 2026-11-01, and #265 cites "section 5" of a spec that is not on main. | Write a short "gate v2.1: the painted gate" section in gate-v2.md, or correct the log. |
| Roadmap Book One track | It said the story map was never made and #271 fixed the order. | Done 2026-11-06: the roadmap points at the [story map](product/story-map/book-one.md). |
| CLAUDE.md "Pofu Hub ... status/now and roadmap/main" | The Hub was last changed 2026-11-03. | Done: the Hub is frozen and chat is the channel (docs/README.md; CLAUDE.md no longer mentions it). |
| [Light standard](design/light-standard.md) | Still warn-only "until the founder has seen the light pilot"; the lit-ladder pilot shipped (#231). | Enforce for production, or restate the gate. |
| Art queue rows 4 and 5 | BLOCKED with no manifest since 2026-11-02. Decor now runs through backlog rows B-C and B-D. | Drop row 5. Rewrite row 4 against the UI audit. |
| Experience v1, home progression, game plan status lines | They still say "proposal" while most of it is built. | Mark them "accepted; built in part". |
| Monetization v2 vs ADR-0016 | v2 replaces the "Plus" clause, but there is no ADR yet. | Leave it until he answers (§6), then write the ADR. |
| #271, #267, #281 vs the story map | Arı as an island, Emanet before Revontuli, invented names and back details, keepsakes under the roots, Mehtap's moon softened. | Done 2026-11-06: all reconciled to the [story map](product/story-map/book-one.md) (its §7 lists each change). |
| Founder input log vs #267 and #271 | The 2026-11-06 questions on undersides and island sheets are logged only inside #267. | Merge #267 before #271 so the log stays whole. |

## 6. Decisions waiting on the founder

Each has a recommendation. Silence means yes, except item 1, which needs the founder's explicit yes.

1. **Monetization v2 (needs his explicit yes; pricing is hard to reverse, so silence does not count):** one membership at 129,99 / 349,99 / 999,99 TL, gate always free, nothing taken back. Recommend yes. The monthly price is the only new number.
2. **Gate direction: decided 2026-11-06.** The round door (lead's pick, shown to the founder); it matches the shield icon at the door.
3. **The roots (#267): decided yes 2026-11-06**, with keepsake memories (yes): the underside grows with the island and keeps a keepsake from each healed island.
4. **Seasons follow the real calendar** (home progression §13.5). Recommend yes.
5. **Session length:** allow a 5-10 minute session when the player chooses it, keeping a 90 s median as the target. Recommend yes.
6. **English rename:** do it in one planned window, or keep the Turkish ids. Recommend doing it after the Çağlayan wave.


## Added 2026-11-06 (afternoon)

- **The gate flow consolidated** ([the Door](design/the-door.md)): six in-app screens become one scene with states; the shield stays Apple's. Next: build `DoorScene` when batch-58 lands; the wave-1 breath pieces become its Breath state.
- **Weather and the screen haze built** (#275): seeded weather bag, rain, mist, golden haze, rainbow after rain, the screen haze. Open: wire `ScreenHazeClearing.part()` to the resisted-reach handler (with the Door build); tune golden haze and rain visibility on device.
- **UI v3 wave 2 merged** (#293: station sheet never clips, pot pips; Today day card; Settings header and Nefes section). Follow-ups when batch-61 art lands: Settings night rows warm (not purple-indigo), drop the duplicate "Ayarlar" title, a warm sticker for Today's empty day, motion on Today and the station sheet (ui-v3 principles 6 and 8), the build flow without the spinner sheet (not started).
- **Flow game built** (#297: engine, 8 Çağlayan boards, 23 tests). Next: Çağlayan's island on the wonder-island model (stages 0-4, batch-43 art), FlowTextures hooks for `flow-wheel` and `flow-tile-wheel`, the painted pieces (batch-64, #301).
- **Home growth not readable** (growth sheet, #295): camera too close, most IL steps invisible. Fix in flight (`feat/growth-readable`).
- **Codex art reviewed and merged (afternoon):** weather FX (#266), flat icons (#269: pick the two-tone take 2 as the app's icon style), light-direction studies (#270, feed nightlab's photometric normals), the roots (#276: IL10 take 1, IL6 take 1, Çağlayan 4 take 2 are the targets), the home growth strip (#279: the target for every island level), the gate postcards without characters (#285), the earth face plates and the Koke stone (#292), the stickers (#253), Damla (#264). Next integrations: earth-face plates by island level and the koke-stone sprite; the six postcards replace the exploration ones; weather FX hooks; the two-tone icons sliced into the place control and menus; nightlab normals from the four light studies.
- **Payoff merged** (#303): the day's resist seals stamp as a gentle row on the earth under Pofu, below the doors, and stay all day; the screen haze parts. Open: Pofu's own door (H1, x −107) is off-screen at the readable home framing (look x 36); try look x ≈ 10 so his door shows without cutting the tea stall; the seal art (batch-61 `seal-resist`).

## Added 2026-11-06 (evening): the story map restored

- **Done:** the Book One story map ("Bekçi kim?", shown 2026-11-05) is committed as the canonical Book One doc ([story map](product/story-map/book-one.md), with both pages as images); the island sheets, the roots, game plan §4/§6/§9/§10, deep lore's placement notes, the roadmap and the docs map now agree with it. Rule added to `CLAUDE.md`: anything shown to the founder is committed the same day.
- **Open decisions (lead):** (1) Koke's scope: the map makes it the first filler and Monday visitor, but it is built as a five-stage island; recommended: keep the arc as the first filler's longer visit. (2) Mehtap's real full moon vs the 11-06 "blessing" fallback; recommended: time Mehtap's door to the moon. (3) The seventh filler in "+ 7 filler". (4) Arı island art: none is queued (the old sheet's `batch-54-ari` was only a proposal and is dropped); the home hive (`hive-4`, `-5`) is what Arı needs. Decided by the lead (story map §9). Follow-ups done the same day: home progression §7, monetization v2 §2.1 (free cut after Act I, at Olta), art queue row B-A, `content/islands/*.yaml`.
- **Çağlayan playable** (#315): the story map's Çağlayan (Damla, the mill note, Mochi's Söz 1 at stage 3, the home pool fountain and Damla on Tuesdays, Nazlı's pool hook), flow rounds advance the stages. Follow-ups: the underside falls read as thin blue bars (needs the batch-64/weather water art or a softer ribbon), the home fountain is barely visible, Damla is out of focus atop the falls at stage 4 (depth row), Çağlayan arrives ~day 12 in the sim vs ~day 10 in the plan.
