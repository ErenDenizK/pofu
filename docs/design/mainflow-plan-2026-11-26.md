# The main flow: the full plan (2026-11-26)

**Status:** plan by Fable for founder-input 46. The founder's short page,
in Turkish, is [mainflow-plan-2026-11-26-tr.md](mainflow-plan-2026-11-26-tr.md);
why the studio slowed and what to change is
[../studio/speed-2026-11-26.md](../studio/speed-2026-11-26.md).

**Amended 2026-11-26 (night)** for founder-input 47 and 48: section 11
at the end. Rows it changes are marked "(amended, 11)".

**Basis:** pofu `origin/main` 87e4745e (#517), pofu-art `origin/main`
ee7ec96 (#169), frames on `screenshots/main` (4112443e). Raw facts by two
scouts are on the lead branch (`docs/research/mainflow-2026-11-26/`).
Marks: **[seen]** I opened the file or the frame in this session;
**[scout]** taken from the raw files and not re-opened. Paths are under
`Packages/PofuKit/Sources/` unless they start with `App/`, `Tests/`,
`tools/` or `docs/`.

## 0. The goal, restated

The founder listed eight areas and asked that each be flawless. Read
against the app, that list is not eight polishing jobs. Home at rest is
already a good picture [seen: `path-d21-0900` at 1:1; clean edges, no
seams]. What the main flow lacks is four things that do not exist yet,
and one loop:

1. A station's level does not show on the island (one station of eight,
   by day, on four island stages of ten).
2. There is no travel: going to an island is a camera flight, and the
   Gezgin is a painted decoration in the sky.
3. Up close there is nothing to see: one sharp Pofu on a blurred lawn.
4. The islands he approved beyond Köke and Çağlayan are painted and not
   in the app.
5. He last played a build on 11-14. Every verdict since then was given on
   concept sheets through a relay, days late. "Flawless" can only be
   judged on his phone, and nothing has been.

So the plan is six steps, each a whole vertical piece that ends in a
build on his phone, ordered along one play session: open Home, build a
station, watch the island grow, look close, board the Gezgin, arrive
somewhere, come home. "Camera" and "what makes it feel alive" are not
steps of their own: each step carries its own camera work, sound and
motion, because that is the only way they come out whole.

The cheaper goal I set beside his: not "all eight flawless", but **"one
session, start to end, with no placeholder in it"**, then widen. Steps 1
to 3 are that session on Home; steps 4 to 6 widen it.

## 1. What "done" means

A step is done when the founder has played it on his iPhone from `main`
(the free build, Rehearsal mode, `docs/local/ucretsiz-kurulum.md`; this
needs no paid membership) and has not vetoed it within a day of the
lead's note. Until then it is "merged", not "done". Each step below
names the three things he is asked to look at.

The whole plan is done when a player can do this with nothing code-drawn
as a stand-in, nothing unreachable and nothing silent:

1. Build any station to any level and see that level on the island, by
   day, at golden hour and at night, with a reveal that feels like an
   event.
2. Pinch in and find a place worth looking at: sharp where the eye is,
   soft behind, characters doing something.
3. Tap the Gezgin (or the button at the bottom right), choose an island
   from a row, ride there, land, and ride back.
4. Find Köke, Çağlayan and Revontuli (then Emanet and Mehtap) whole:
   their own stages, light, resident, game and mooring.
5. Open Today, Settings, a card and onboarding and see one interface.
6. See the island change with the season.

## 2. Where the main flow stands

| Area (his list) | Today | Evidence |
|---|---|---|
| Camera | Three framings on one rail, pinch, one-thumb zoom, flights of 0.9 to 1.6 s: built and tested. Mid sits well since #513. Near is empty: the patch, dressing and foreground art are not in | `PofuWorld/Camera/CameraRail.swift:7,126`; `CameraFlight.swift:8-10`; `PofuWorld/Plate/NearLayers.swift:10` [seen]; `path-d04-near-rest` [seen: Pofu sharp, flat blurred lawn, a blurred wheel across the bottom] |
| Island level | Works: the whole plate swaps by stage, 10 day and 10 night plates, with a grow moment. Golden hour is painted only at level 10, so from 17:30 to 20:00 a level 1 to 9 island borrows the night plate | `plate-home.json` `stageLevels`, `lightStages` {day 10, golden 1, night 10} [seen]; `PofuWorld/Plate/HomePlate.swift:85-86,100` [seen] |
| Station levels | Only the tea stall wears its level: 5 looks, `light: day`, erased bases for stages 3, 4, 6, 7 only. The other seven stations never change. The reveal is coded | `plate-home.json` `stations` (one key) [seen]; `PofuWorld/Plate/PlateIsland.swift:309-336` [seen]; `PofuWorld/Scene/StationReveal.swift:1-14` [seen]; `path-stall-l1/l3/l5`, `path-stall-i7-l5` [seen at 1:1: cut-outs clean] |
| Themes | Nothing. `Season` is defined and no view reads it | `PofuWorld/Sky/Weather.swift:40-56`; `grep Season` finds only tests [seen] |
| Travel, the Gezgin | A camera flight. The Gezgin is a gliding whale in the sky set and a visitor who sends a postcard. Her sprite parts are in the bundle and nothing draws them | `PofuWorld/Scene/IslandSceneModel.swift:549,682`; `PofuWorld/Sky/SkySet.swift:21-34`; `PofuCore/Game/VisitorSchedule.swift:70`; `grep nazli` [seen] |
| Islands on the map | Home low, Köke and Çağlayan small in the upper third, most of the frame empty sky and cloud | `path-d13-map-0900` [seen] |
| Characters | Pofu, Mochi and Fındık hop between three spots each, two moves a minute at most; no poses, no walk on the plate; lines exist for two residents | `PofuWorld/Scene/PlateMoves.swift:5-25` [seen]; `WorldStrings.swift:126` [scout] |
| Feels alive | Pond water, drifting sky, five weathers, three lights, ambience and six Pofu cues. No music. No water on Çağlayan's falls | raw-mainflow section 7 [scout] |
| Menus | Glass skin; the station card is new (#512, two variants in Settings). Today, Settings, the celebration card and onboarding are from the v3 pass. The UI grammar (#490) is not applied | `path-card-station-a` [seen]; `15-menu-today-v3-day`, `16-menu-settings-v3-day` [seen, small] |
| Other islands | In the app: Köke (code layout, 5 stage plates) and Çağlayan (plate, 5 stages). Revontuli, Emanet, Mehtap: 14 to 15 cells painted each, none in the app; board kits delivered; their residents not painted | `path-d10-koke-0907`, `path-d16-caglayan-0907` [seen]; `docs/state/plates.yaml` [scout] |

Art that is ready and unused: the Gezgin at three levels, awake and
asleep, as cut-outs (pofu-art batch 160) and her moorings at Home, Köke
and Çağlayan (164) [seen: both read as one character, fluffy, with a
tail, never from behind]; the voyage frames (148) [seen]; season plates
(batch 25) [listed, not judged]; menu grounds (165) and card marks and
ornaments (159, 162) [scout].

## 3. Gaps, ranked by what the player feels

| # | Gap | Evidence | Closed by |
|---|---|---|---|
| G1 | **I pay for an upgrade and nothing changes.** His first complaint on 11-14 (fi 26, 1); still true for seven of eight stations | section 2, row 3 | Step 1 |
| G2 | **At 17:30 my island turns to night.** Levels 1 to 9 have no golden plate | `HomePlate.swift:100` | Step 1 |
| G3 | **Going somewhere is a cut, and the whale is wallpaper.** The story's road between islands has no part in play | section 2, row 5 | Step 2 |
| G4 | **The far view is mostly empty.** His 11-16 words: about 60 % cloud, islands far from the thumb | `path-d13-map-0900` | Step 2 |
| G5 | **Close up there is nothing.** Depth of field reads as "Pofu sharp, the rest blurred", which he rejected (fi 32, 4) | `path-d04-near-rest` | Step 3 |
| G6 | **The characters stand.** Hops of 24 to 30 px; no pose, no work at a station, no reaction to a build | `PlateMoves.swift`; `docs/now.md` | Step 3 |
| G7 | **Menus do not look like one game.** "Menüler genel olarak iyi değil" (fi 43) | section 2, row 9 | Step 4 |
| G8 | **The approved islands are not there.** Three main islands painted, zero in the app | section 2, row 10 | Step 5 |
| G9 | **The island never changes with the year** | section 2, row 4 | Step 6 |
| G10 | **No music** | `grep -i music` [scout] | his decision (section 8, Q3) |

Not gaps, though they were treated as such: Home's composition (#513
fixed it [seen]); the sprite island at Home (dead code, not a look the
player can reach); Pofu's body (the bundle name `pofu-hamster` is old,
the picture is the painted Pofu [seen: `path-d04-near-rest`]).

## 4. Decisions

Each with the alternative not taken. None needs a new ADR except D5.

| # | Decision | Not taken, and why |
|---|---|---|
| D1 | **Station levels are looks over erased bases, reused across island stages by per-stage place data.** This is the compositor that ships (`PlateCompositor.swift:1-18`); the tea stall proves the cut is clean at 1:1. It needs one schema change: looks per light | *A full plate per combination:* 5 levels to the power of 8 stations. *A diff patch per stage:* 8 x 5 x 10 x 3 edits, and each stage drifts. *Station levels shown only on the card:* cheapest, and exactly what he called bad |
| D2 | **Five levels per station stay.** The economy, its tests and the tea stall are built on five, and one visible reward a day is worth more to a habit app than fewer, bigger ones. The bar moves to review: a level is accepted only if the station's outline changes when seen at Map size; the tea stall's levels 4 and 5 (lights, a flower pot) fail that bar today and are repainted in step 1 | *Three big levels:* each step would be bigger for free, but it retunes the ladder and costs and throws away approved work (the windmill) |
| D3 | **Night looks are painted as a relight edit of the picked day look; golden looks are the day look under a code grade.** Same outline in all three lights, 40 jobs instead of 80 | *All three painted:* the golden plate exists for one island level only, so 40 golden looks would stand on nine borrowed plates |
| D4 | **Home's golden plates for levels 1 to 9 are painted** (nine relight edits of the day plates; pofu-art has an unrun `batch-87-home-golden` manifest to start from) | *Leave the borrow:* G2 stays |
| D5 | **The far view becomes the voyage row** (ADR-0028 from #503, rewritten to his answers of fi 40, 43, 44): she is moored at the island and stays still while the player chooses; the camera pulls back to a row with one island large; a swipe changes the island; "Yola çık" brings the characters onto her back and she flies. The Map stop and its tier frames go. **ADR-0028, accepted in step 2's first PR** | *Keep the Map and add her to it:* G4 stays, and every new island needs a new balance. *#503 as written* (she carries the camera and the world slides under her): he asked that she not move during the choice |
| D6 | **She is one cut-out per level and state, moved by code** (bob, a squash on landing, eyes by swapping the awake and asleep cut-outs, a separate tail piece that sways) | *Frame animation painted by Codex:* frames do not hold her shape from one to the next. *A skeletal rig:* days of work for a character seen at 150 pt |
| D7 | **Her level is data:** level 1 when she arrives, 2 when the first island is healed, 3 when the first main island is healed. In `world-map.json`, retuned when islands are added | *Tie her level to seeds:* a ninth station by another name |
| D8 | (amended, 11) **A theme is a grade, a sky set, particles and one small painted dressing set. It never repaints the island.** With D1, a repainted theme is 21 bases and about 90 looks each | *Whole-island theme plates* (the queue brief's item 3): kept only as three target frames to grade towards |
| D9 | **Characters get pose cut-outs (sit, sleep, work, cheer), not walk cycles.** Hops stay as the way they move (decided, fi 44) | *Walk cycles:* decided against |
| D10 | (amended, 11) **Çağlayan is frozen:** bug fixes only, no water work on its falls, no new boards, until he says what changes (Q2) | *Finish its water now:* he said not to |
| D11 | (amended, 11) **Mini-games are frozen.** The four delivered island kits are ingested only when step 5 brings their island | *One more board pass:* 39 % of the art line's deliveries since 11-15 already went there |
| D12 | **The islands he approved are read as:** Köke and Çağlayan (in the app), then the main islands Revontuli, Emanet, Mehtap (`docs/product/decisions.md` S2). Fillers without art (Çanlar, Martı Kayası and later) are out of this plan | *Ask him which:* the documents agree, and he can correct a list faster than answer a question |
| D13 | **Verdicts are given on the phone.** Each step has one pilot of two to five jobs judged in the app, then the build; no concept round precedes code (see the speed page, change 3) | *Concept first, then native* (fi 40): three rounds, 205 jobs, two things in the app |

## 5. The steps

Order is by the ranked gaps and by what must exist first. Estimates are
agent working days at the 11-24 pace (seven PRs in 7.5 hours) and are
guesses.

### Step 1: stations grow on the island (about 2 days)

*Art:* erased bases, looks for seven stations by day, night looks for
all eight, golden plates 1 to 9. *Code:* looks per light, the nearest
lower look as fallback, golden grade. *Feel:* the reveal for every
station, its sound, the resident's hop, the card's level mark.

*Done when:* he builds the windmill from level 1 to 5 on his phone and
sees five different windmills, by day and at night; then the same for
every station. He is asked to look at: (1) does each level feel like a
step, (2) any edge or ghost round a station, (3) the island at 18:00.

### Step 2: the Gezgin and the voyage (about 4 days)

*Art:* her cut-outs (160, front views from the queue), the mooring post,
row islands (the shipped Map isle art is reused), a cloud wake.
*Code:* she lives at Home's pier as a character (sleeps at night, wakes
to a tap, has lines); tap her or the bottom-right control; the row; the
ride; arrival at the island's mooring; her arrival beat with her shadow
first (fi 39). *Feel:* her voice cue, wind on the ride, a haptic on
landing, the camera following her.

*Done when:* from Home he taps her, swipes to Köke, rides, lands, and
rides home, with no cut. He is asked to look at: (1) her look moored and
flying, (2) the row, (3) the ride's length.

### Step 3: up close, and the characters (about 3 days)

*Art:* the near patch and dressing (pofu-art #74 and #89, open since
11-15), four poses each for Pofu, Mochi and Fındık. *Code:* focus by
plane (things at the focused depth are sharp together), poses chosen by
hour and station, a cheer when a station is built, lines for every card
that opens. *Feel:* a tap answers with voice and motion every time.

*Done when:* he pinches in on each of three places and each is a
picture; a character is doing something in each. Asked to look at: (1)
what is sharp, (2) the poses, (3) frame rate and heat after five minutes.

### Step 4: menus as one interface (about 2 days; runs beside step 2)

*Art:* grounds (165), marks and ornaments (159, 162), already delivered.
*Code:* one sheet style and one card style from #490, applied to Today,
Settings, the celebration and island cards and onboarding; the unused
variant of the station card deleted once he names one. *Feel:* one
motion and one sound for open and close.

*Done when:* he opens each of the five on his phone and none looks older
than the station card. Asked: (1) Etiket or Hap, (2) Today, (3) onboarding.

### Step 5: Revontuli, then Emanet and Mehtap (about 3 days each)

Revontuli is built once as a template and the other two follow it:
plate stages and lights, its place in the row, its mooring, its
resident, its healing arc, its game from the delivered kit. Starts when
step 2 is merged and Q2 is answered, because the template is Çağlayan's.

*Done when:* he rides to Revontuli, heals it over the rehearsal days
and plays its game. Asked: (1) the island at stages 0, 2 and 4, (2) its
resident, (3) its board.

### Step 6: seasons (about 2 days) (amended, 11)

As D8, autumn or winter first, after his answer to Q1.

*Done when:* he sets the rehearsal date into another season and Home is
the same island in that season at every level. Asked: (1) does it still
read as a painting, (2) the sky, (3) the particles.

### Beside all steps

- **The device days** (brief `2026-11-24-0-device-day-fixes.md`) outrank
  everything from the hour his membership opens. Nothing above waits for
  them. Round 2 held the voyage behind them; that was my mistake, and it
  left the studio without approved work 7.5 hours after it started.
- **Cleanup** of dead paths goes in with the step that touches the file,
  not as a job of its own.

## 6. Pull requests

Three in flight at most; one Swift build at a time. "test" is accepted
by named tests, "eye" by a named frame against a named reference. Steps
3 to 6 are listed at the grain a builder brief needs to be written
from; the lead writes those briefs when the step before merges.

### Step 1

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| 1a | `feat/looks-per-light` | test | `PofuWorld/Plate/PlateIsland.swift`, `PlateCompositor.swift`, `HomePlate.swift`, their tests | `StationLooks.light` becomes `lights: [String: [Int]]` (light to base stages); golden draws the day look under `harmony`'s golden grade; a missing look draws the nearest lower one; the old key still decodes | New cases in `PlateCompositorTests`, `HomePlateDataTests`; `path-stall-*` frames unchanged byte for byte | If the old key cannot decode beside the new one, bump the plate `version` and migrate the one station in the same PR |
| 1b | `art/windmill-levels` | eye | `tools/plate/station_looks.py`, `plate-home.json` `stations.windmill`, `World.xcassets` windmill looks and bases, `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift` | Ingest the windmill pilot: 5 day and 5 night looks, erased bases for every stage it stands on | Frames `path-mill-l1..l5`, `path-mill-night-l1..l5`, `path-mill-i<stage>-l3`; 1:1 crops show no halo and no ghost of the painted mill. Reference: `path-stall-l3` for cut quality, the windmill takes of pofu-art batch 134 for the look | A level whose cut fails is left out of the data; the fallback of 1a draws the level below |
| 1c | `art/station-levels` | eye | as 1b for the six other stations and the tea stall's night looks and remaining stages | The same, breadth first by level | `path-<station>-l1..l5` by day and night; one sheet of the whole island at mixed levels per island stage (`path-levels-i<stage>`), judged whole: no station takes over the island | As 1b, per station |
| 1d | `art/home-golden` | eye | `World.xcassets` golden plates 1 to 9, `plate-home.json` `lightStages` | Ingest nine golden plates | `path-d01-1800`, `path-d10-1800` against `path-d21` at golden (level 10) | A stage whose take fails keeps the borrow |
| 1e | `feat/reveal-all-stations` | eye | `PofuWorld/Scene/StationReveal.swift`, `StationCard.swift`, `App/WorldSound.swift` | The reveal runs for every station; the card shows the level mark (159); one sound per station kind | `path-<station>-reveal-740` and `-1600`; reference `path-stall-reveal-740` | Stations without a mark keep the dots |

1a starts now and has no art in it. 1b waits for the pilot delivery
(section 7, row C1). 1d is independent.

### Step 2

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| 2a | `docs/adr-0028-voyage` | test | `docs/adr/0028-the-far-view-is-a-voyage.md`, `docs/adr/README.md` | The ADR as D5; closes #503 | link check | none |
| 2b | `feat/gezgin-moored` | eye | new `PofuWorld/Gezgin/` (layout, rig, view), `plate-home.json` `mooring`, `WorldHitTest.swift`, `WorldStrings.swift`, the sky set's baked whale removed (`PofuWorld/Sky/SkySet.swift`) | She is moored at the pier at her level, asleep at night; tap wakes her, a line and a cue; before she arrives, her shadow crosses the cloud | `path-gezgin-moored-l1..l3`, `-night`, `-shadow`. Reference: `x5-gez-moor-home-lv1` t1 (pofu-art batch 164) | If her cut-out reads soft at mid scale, ingest at the density of the station looks (3 px per point) |
| 2c | `feat/voyage-row` | eye | new `PofuWorld/Voyage/` (route data, row view, model), `CameraRail.swift` (the Map stop becomes the row), `MapSlots.swift` and its tier frames deleted, `PlaceControl.swift` | The row as D5: one island at 0.7 of the width, neighbours cut by the edges, a glass bar with the name, one state line and the verb | `path-row-home`, `path-row-koke`, `path-row-locked`; `VoyageRouteTests`. Reference: `x2-voy-row-big` t1 (batch 148) for layout only; the bar is native glass, never the painted one | If the swipe fights the island's own drag, the row takes horizontal drags only and a tap on a neighbour glides |
| 2d | `feat/voyage-ride` | eye | `PofuWorld/Voyage/` (ride), `CameraFlight.swift`, `IslandSceneModel.swift` (`fly(to:)` becomes the ride), `App/WorldSound.swift` | Characters hop aboard, she flies with the camera on her, she moors; 3 to 5 s, Reduce Motion cross-fades | Motion beats `voyage-0.0..4.0`; `CameraFlightTests`. Reference: `x2-voy-fly-clean` t1 | If the ride drops frames on the render server, the cloud wake goes first |
| 2e | `art/moorings` | eye | Köke and Çağlayan mooring data and art | Her place at each island | `path-gezgin-koke`, `path-gezgin-caglayan`. Reference: batch 164 `moor-koke-lv1` t2, `moor-caglayan-lv1` t1 | An island without a mooring shows her hovering beside it |

2b and 2c own separate folders and run together; 2d follows both.

### Steps 3 to 6 (one line each; briefs are written when the step before merges)

| PR | Kind | Owns | Acceptance |
|---|---|---|---|
| 3a near art | eye | `plate-home.json` `near`, near imagesets | `path-near-pofu`, `-stall`, `-pond` at 1:1; reference: the near concept he locked on 11-15 (`docs/product/founder-input.md` item 34) |
| 3b focus by plane | test + eye | `PofuWorld/Depth/`, `NearLensViews.swift` | `ThinLensTests`; in the three frames, everything within one body of the focus is sharp |
| 3c poses | eye | pose imagesets, `PlateMoves.swift`, `LifeViews.swift` | `path-life-pose-<who>-<pose>`; no pose behind a taller thing (`PlateMovesTests`) |
| 3d reactions and lines | test | `WorldStrings.swift`, `ResidentCard.swift`, strings written with the `pofu-story` skill | every `ResidentID` that can open a card returns three lines |
| 4a sheet and card style | eye | `App/Home/TodaySheet.swift`, `App/Settings/`, `PofuWorld/Scene/CelebrationCard.swift` | `15-menu-*`, `16-menu-*` regenerated; reference `path-card-station-a` |
| 4b onboarding | eye | `App/Onboarding/` | `path-onboarding-*` for all eight steps |
| 5a Revontuli plate and row | eye | `plate-revontuli.json`, its imagesets, route data | `revontuli-plate-full-s0..s4-day/night` |
| 5b (amended, 11) Revontuli arc and game | test | `PofuCore/Game/WonderIslands.swift`, `flow-boards.json`, kit ingest | `FlowAuditTests` reach and heal it; 4 boards solvable |
| 6a (amended, 11) seasons | eye | `PofuWorld/Look/`, `Weather.swift`, a season dressing set | `path-season-autumn-i3`, `-i10`; reference: `x-season-autumn` t2 (batch 25) |

## 7. Codex

The queue PR being written now (`chore/queue-mainflow-1126`, batches 171
to 174 so far: the Gezgin's front views and states, station levels 2 and
3) fits steps 1 and 2 and should merge as it is. Rows to add after it,
in this order. I wrote no manifests, so as not to collide with its batch
numbers.

| Row | Jobs | What | Serves |
|---|---|---|---|
| C1 | 4 | **Pilot:** the Home plate at two stages (3 and 10), day and night, with every station erased to its empty plot in one edit | 1b; the method for C2 |
| C2 | 17 | The other erased bases, once C1's cut is accepted in the app | 1c |
| C3 | 9 | Golden plates for levels 1 to 9 (from `batch-87-home-golden`) | 1d |
| C4 | 16 | Station levels 4 and 5 (the queue has 2 and 3); the brief for each names what changes the outline | 1c |
| C5 | 40 | Night relights of the picked day looks, a row per level so it follows the picks | 1b, 1c |
| C6 | 12 | Poses for Pofu, Mochi and Fındık: sit, sleep, work, cheer | 3c |
| C7 | 6 | A tail piece per Gezgin level, and her shadow on cloud | 2b |
| C8 | 3 | Season targets: the level 10 plate in autumn, winter and spring. Not whole-island sets (D8) | 6a |
| C9 | 3 | The residents of the three main islands (Tuli, Boncuk, Nane; standing row S3) | 5 |

Themes as whole-island variants (the queue brief's item 3) should stop
at C8 until Q1 is answered.

## 8. What is the founder's

Three questions; the Turkish page asks them with the pictures named
here. Everything else in this plan is decided by the lead or by me, and
he vetoes on his phone.

| # | Question | My pick | Picture to send |
|---|---|---|---|
| Q1 | (answered, 11) **What is a theme?** The season, changing by itself with the calendar for everyone, or a look the player chooses? | The season, by itself; autumn and winter first. A chosen look can come later on the same parts | pofu-art `design/art/takes/batch-25-seasons/x-season-autumn/plate__x-season-autumn--t2.webp` beside `.../x-season-snow/plate__x-season-snow--t2.webp` |
| Q2 | (answered, 11) **What changes on Çağlayan?** Only that island's picture, or the stream game too? The other islands' games are built from the same game | Only the picture; the game stays | `path-d16-caglayan-0907` and `path-game-flow-stage1` from `screenshots/main` |
| Q3 | (answered, 11) **Music now?** He set it for "with the voyage" (fi 44) and the voyage is step 2 | Yes: one calm loop for Home by day and one for night, licensed or commissioned, his choice of source; he sends two tracks he likes | none |

And one request, not a question: **play `main` for five minutes after
each step's note.** That is the plan's clock.

## 9. Out of scope

The Screen Time gate beyond the device-day brief; StoreKit, the Door,
the widget; the free build's features; new mini-games and any board
work (D11); Çağlayan beyond bug fixes (D10); filler islands without art;
walk cycles; a skeletal rig for anyone; whole-island theme repaints;
player-chosen themes; the roots; decor spots and sets; the resident
assign sheet; music production before Q3; TestFlight.

## 10. Corrections

- `docs/now.md` on `main` reads "Updated: 2026-11-16"; the lead branch's
  copy is current. The lead branch lacks #511's files
  (`docs/design/assessment-2026-11-24-path.md` is not in its tree).
- `docs/design/assessment-2026-11-24-path.md` stage 4, "held until stage
  1 is done": superseded by this plan.
- `docs/studio.md` section 7: "no TestFlight before the membership
  (about 2026-11-24)" is past its date; and the free build is how he
  plays, with or without it.
- Founder-input 46 says Codex was idle about 16 hours; the commits show
  about 40 (raw-studio-speed, section 4).
- `docs/design/flow-game.md:65` promises 16 boards; `flow-boards.json`
  holds 8, all Çağlayan [seen].
- `docs/tracker.md`, "16 growth pieces are code stand-ins": true only of
  the sprite branch (`IslandScene.swift:1206-1208` [seen]), which no
  save reaches.
- `PofuCompanion/CompanionArt.swift:36` loads `pofu-hamster`: an old
  name, not a placeholder picture.
- A stray `sheet2.png` sits at the repository root.
- `docs/design/world-presentation-build-spec.md` WP12 (unlock reveals on
  the Map) is void if D5 stands.

## 11. Not verified

- A white smear on the harbour islet's lawn in `path-stall-l1`, `-l3`
  and `-l5` (about x 870 to 1000, y 1230 to 1300): mist drawn by the
  weather, or residue of the erase. It must be read before 1b copies the
  method.
- Whether the batch 160 cut-outs hold at the row's scale (330 pt wide);
  I saw them at 400 px.
- Frame rate, heat, sound and haptics: nothing on a device since 11-14.
- The season takes of batch 25, the near art in pofu-art #74 and #89 and
  the menu grounds of batch 165: listed, not judged.
- The day estimates.

## 11. Amendments (2026-11-26, night; founder-input 47 and 48)

This plan is amended, not replaced (the speed page's change 4). Three
specs carry the detail:
[island-calendar-v1.md](island-calendar-v1.md),
[motion-vocabulary.md](motion-vocabulary.md) and
[music-system-v1.md](music-system-v1.md).

**How his words answer section 8.**

- **Q1** (what is a theme): neither of my two options. He wants both
  special days on the real calendar and seasons that are the island's
  own. No document planned such a season; it is designed now (the
  island year: seven days a season, counted from the player's first
  day). One confirming question remains, with a default (calendar Q-A).
- **Q2** (what changes on Çağlayan): the island's design may change
  from scratch; the stream game does not change and is frozen. My pick
  ("only the picture") stands and goes further: the picture is painted
  again, to the list of what the app can move.
- **Q3** (music now): yes, and as a line of work of its own, not two
  bought loops. My pick is withdrawn.
- **The speed page's change 3** is decided in part. Founder-input 48
  settles that no work waits for an answer: what agrees with what he
  has said and can be built is applied, and his large questions come
  with a picture and a recommendation. It does not settle "no concept
  rounds": a large direction still gets a picture first (batch 185 is
  one), and everything else is judged on his phone.

**Decisions changed.**

| Row | Now reads |
|---|---|
| D8 | Replaced by the calendar's C3 and C4. A special day is a kit of props, a sky event, a line and a tune, never a repaint. A season is the air, then dressing, then (after a pilot at level 10) the painted island in autumn and winter. A grade alone was tried on the shipped plate and does not read as a season |
| D10 | Replaced by the motion page's M3 to M5. Çağlayan is painted again to the motion vocabulary, after step 2, as the first job of step 5. The shipped plate stays untouched until then |
| D11 | Widened by M1 and M2. The stream game is frozen as it is; the four delivered island kits are not ingested; islands arrive without a game |

**Steps changed and added.**

| Step | Change |
|---|---|
| 5 | Begins with Çağlayan painted again, once he has chosen from batch 185; Revontuli follows that template. Row 5b loses its kit ingest and its boards |
| 6 | Becomes the island calendar: C1 (the island year and the special days, tests only), C2 (the season's air), C3 (the New Year kit, on `main` by 20 December), C4 (the painted-season pilot), C5 (dressing). Row 6a is C4 |
| 7, new | Music: MU1 (the score, the band and three Home tunes) starts now beside the Swift lane; MU2 to MU6 as in the music spec. G10 is closed by this step |
| beside | V1, the rotor pilot: the Home windmill's sails turn. It answers his question about the wheel on his phone |

**The Swift lane's order from here** (one build at a time): step 1's
remaining rows; C1 (small, and C3 needs it); step 2; C3 (it has a
date); V1; step 3; MU2 and MU3; C2; C4; step 4; step 5. MU1, the art
ingests and every Codex row run beside it.

**Out of scope, added:** board and kit work of any kind; national days;
seasons on other islands' plates; game music; a sampler or a generator
for music.

