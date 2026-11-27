# The season system v1: how a season enters the painted island

**Status:** spec by Fable for founder-input 49 (2026-11-26), written
2026-11-27. Builds on the island year
([island-calendar-v1.md](island-calendar-v1.md), C1, merged as #526) and
replaces that page's decision C4 (c) and its PR C4. The founder's page is
[season-system-v1-tr.md](season-system-v1-tr.md). The decision that
would cost days to reverse is
[ADR-0030](../adr/0030-a-season-is-an-edit-of-spring.md).

**Basis:** pofu `origin/main` b3a7d77d (#522), pofu-art `origin/main`
a747f4f. Every claim below was read in the code or measured on pixels in
this session unless it is marked **[unverified]**. Paths are under
`Packages/PofuKit/Sources/` unless they start with `App/`, `Tests/`,
`tools/` or `docs/`. "Plate px" is the plate's own point (the plate is
1024 x 1536); one plate px is 1.37 device px at Home (`framing.homeWidths`
1.15 x 1206 / 1015).

## 0. The goal, restated

The brief asks how a season enters the system "so that changing the
season swaps every visible piece at once and in harmony". The founder's
wording is sharper: the cut-and-compose technique exists so that colour
and shadow never mismatch, and he wants to see that pay off; build the
system first, one season first, with no time spent on merges and small
colour fixes.

**The goal is right. One premise under it needed measuring, and one in
the brief is false.**

- *Measured:* friction.md (2026-11-27) and the queue log say whole-plate
  edits "drift" and "stations shift". They do not shift. Five takes of
  batches 173 to 176 against the shipped plate hold the frame to a median
  of 0.2 plate px (p90 0.4). What changes is the paint: a third of the
  island's pixels come back repainted (dE over 6 on 33 to 37 %). So a
  *diff* cannot cut them, and a *shared shape* can. The season system
  rests on the second fact and never needs the first.
- *False:* "looks per light (#520)" is code only. In the data every look
  and every erased base is a day one (`plate-home.json` `stations.*.light`
  is `"day"`; nine `world-home-look-*-day`, seven `world-home-base-day-*`).
  At golden hour and at night the island shows its painted stations, not
  the player's levels. A season has to be designed for the state the app
  is really in.

## 1. What "done" means

1. In Rehearsal mode he taps the season control and the island turns
   autumn in one crossfade: the lawn, the tree and bushes, every station
   at the level he built it, the tap shapes, the shadows under Pofu. He
   taps an upgrade and the autumn windmill grows to its next autumn look.
   He drags the hour to night and it is the same autumn, the same leaves
   in the same places. Nothing is half spring.
2. A season that is not finished for a state never shows there in parts:
   the state shows spring, whole, with the season's air.
3. Painting the next season needs no Swift: Codex paints, the tools cut
   and check, one art PR lands.

## 2. Where it stands

| Thing | Today | Evidence |
|---|---|---|
| The season | Computed and carried, drawn nowhere | `PofuCore/Game/IslandYear.swift:56-68`; `WorldSnapshot.season` at `PofuCore/Game/GameState.swift:405`; no reader in `PofuWorld` (`git grep season` there: no hit) |
| A painted state | `(light, stage)`; assets are named from the two | `PofuWorld/Plate/HomePlate.swift:34-35`, `PlateIsland.swift:206-250` |
| Which state shows | Hour to light, level to stage, borrow chain per light | `HomePlate.swift:95-138` |
| A change of state | One crossfade between two whole paintings; each painting builds its own compositor, so its looks belong to it | `PofuWorld/Plate/PlateHomeViews.swift:39-47,79-112` |
| Painted Home | Day 10 stages, night 10, golden 6 (stages 0, 3 to 7) | `Resources/Plates/plate-home.json` `painted` |
| Stations as looks | Tea stall (5 looks; bases at stages 3, 4, 6, 7), windmill (looks 2 to 5; bases at stages 0, 1); day only | same file, `stations`; `tools/plate/station_looks.py:57-134` |
| How a base is made | The shipped plate with one window taken from a whole-plate erase take, colour-matched on a ring and feathered | `tools/plate/station_looks.py:17-19,77-92` |
| How a look's colour is set | Per level, a measured chroma and lightness factor that brings the cut to the painted station's mean colour | `tools/plate/station_looks.py:102-104,116` |
| Derived per state by the tool | Matte, crop, island cut, Map cut, occluders, light and shadow maps, the characters' tint | `tools/plate/ingest.py:508,743,803,849,995` |
| Gates | Matte checks M1 to M6 on shipped plates; characters against their lawn | `tools/plate/plate_gate.py`, `tools/plate/harmony_check.py` |
| Season art | Seven concept frames of another layout (batch 25); eight whole-plate season edits queued, none delivered (batches 177, 178) | pofu-art `design/art/takes/batch-25-seasons/`; `QUEUE.md` D40, D41 |
| Bundle | Home's painted pieces are 28 MB of a 104 MB world catalog: plates 11.5, bases 2.9, occluders 2.7, cuts 3.2, looks 0.4 | `du` on `World.xcassets/world-home-*` |

## 3. What I measured

The sheet is
[assets/season-system/proof-2026-11-27.jpg](assets/season-system/proof-2026-11-27.jpg).
No season take exists yet, so each claim is tested on the nearest thing
that does: an edit of the same plate that changes all of it (golden,
night), or repaints all of it (the level edits, the erase take).

| # | Claim the plan rests on | Test on existing pixels | Result |
|---|---|---|---|
| M1 | An edit of the whole plate keeps the frame | Block phase correlation on gradients, 96 px blocks, shipped level-10 day plate against: shipped golden; shipped night; five takes of batches 173 to 176 | Golden: median 0.40 plate px, p90 0.69, max 0.92. Night: 0.35, 0.58, 1.20. Level edits: 0.18 to 0.28, p90 0.36 to 0.50 (larger only inside the edited station) |
| M2 | An edit repaints, so nothing may be cut by difference | Same takes, CIELAB difference over the whole island | Median dE 4.3 to 4.6; 33 to 37 % of island pixels over dE 6 |
| M3 | A plot crop holds better still | Batch 134's windmill levels 2 to 5 against level 1, outside the mill | 0.3 to 0.4 take px (0.1 plate px); median dE 2.1 to 2.7 |
| M4 | A look stands on a base that is another painting of the island | The shipped windmill look 5 over the shipped base (A1) and over batch 117's whole erase take, a full repaint (A2) | Foot, door and path meet; the same picture at 1:1. Sheet, A1 beside A2 |
| M5 | A look painted in one state can be brought into another by a fitted grade | A 3 x 4 colour fit in linear RGB from the day plate to the golden plate, learned on six stations, applied to the seventh, against that station as painted in golden | Windmill: dE median 10.8 to 6.2, p90 39.4 to 14.4. Tea stall: 7.1 to 6.3, p90 23.3 to 10.7. Lighthouse: 8.5 to 5.7, p90 16.2 to 9.4. The shipped tint alone: 10.3, 7.0, 7.7. Sheet, B1 to B3 |
| M6 | The same fit does not make a night | Same test, day to night | dE 10.2, 7.6, 9.2 after the fit: lit windows are content, not colour |

What this proves: geometry is shared for free, and colour can be carried
by a fit where a season changes light and not content. What it does not
prove: that a *season* edit, which reshapes crowns and lays snow, holds
the frame as a relight does. That is what batch 194 is for (section 7),
and nothing past the pilot is built before it is measured.

## 4. Gaps, ranked by what the player feels

| # | Gap | Evidence | Closed by |
|---|---|---|---|
| G1 | The island never changes with its year | No reader of `season` in `PofuWorld` | S1, S3 |
| G2 | A season could show half done: an autumn lawn under a spring station | A state is `(light, stage)`; nothing ties a look to its base's season | S1 (one key, all or nothing), S2 (the gate) |
| G3 | A season painted the last way would freeze every station at its top level | The calendar's PR C4 drew a season *plate*; the plate paints stations in | S3 (bases and looks, not plates) |
| G4 | Each new season would cost a Swift build and hand colour fixes | Windmill grades were measured by hand per level (`station_looks.py:116`) | S2, S3 (fit and gate are tools) |
| G5 | Nobody can see a season on a phone today | Rehearsal shows the season as text only (`App/Rehearsal/RehearsalPanel.swift:245-253`) | S1 |

## 5. Decisions

| # | Decision | Not taken, and why |
|---|---|---|
| D1 | **Spring is the source of every season's geometry.** Every painted season picture is an edit of its spring counterpart in the same frame: plate from plate, look from look. Tap shapes, walkable ground, feet, slots, look boxes, sort order and the level-to-stage table are one set for all seasons. ADR-0030 | *A season painted from scratch as its own island:* every shape, slot and foot again per season, and the island would jump when the season turns. *Layers over spring* (only crowns and snow): autumn and winter change nearly every pixel of the ground |
| D2 | **A season picture is cut with the spring picture's shape, never by difference.** A season look takes the spring look's alpha; a season plate takes the spring state's matte as its start. So the prompt forbids growing past an outline: leaves and snow lie on things | *Cut each season look against a season bare crop:* two repaints never agree pixel for pixel (M2); that is exactly how batches 173 to 176 failed |
| D3 | **A season is a third key on the painted state:** `(season, light, stage)`. Spring's key is today's, so every shipped asset name and every `path-*` frame stays byte for byte. Another season's key is `<season>-<light>` wherever the data and asset names are keyed by light today | *A `seasonPlates` side table* (calendar PR C4): a second lookup beside `painted`, and looks, bases, occluders and tints would each need their own |
| D4 | **All or nothing per state.** The data lists the states a season is complete for. The app draws a season at a state only if it is listed; otherwise the whole state is spring. A season is switched on for players (`complete: true`) only when every state spring paints is listed; until then only Rehearsal and the screenshot tests can show it | *Show what exists:* a player at level 4 in spring art and at level 5 in autumn. *Borrow across seasons piece by piece:* that is G2 |
| D5 | **What is painted per season:** the island (one plate per stage and light spring paints) and, from each plate, its erased base (the batch 117 edit applied to the *season* plate, so a base and its plate are one painting). Night and golden are relights of the season's own day pick, so the fallen leaves do not move at dusk | *Erase from spring's bare take and repaint it to the season:* the base and the plate would be two readings of "autumn" joined at a feather. *Paint only bare islands:* stations still painted into a plate (six of eight today) would have no season |
| D6 | **Station looks: derived where the season changes only light, painted where it changes content.** Derived: the spring look through the fit of M5, learned per season and light on the stage-0 pair, baked at ingest into its own asset. Painted: an edit of the spring look's take, graded to the season plate's station by the windmill's mean-colour method. The app cannot tell them apart: both are `world-home-look-<station>-<n>-<season>-<light>`. First split: autumn derives all but the garden; winter paints all (snow). The pilot paints the windmill in autumn too, so the split is decided on a side-by-side | *Paint every look in every season:* 80 edits a season before one has been seen. *Tint at runtime:* a multiply cannot do M5's fit (the shipped tint leaves dE 10.3 where the fit reaches 6.2), and a baked look is checked by the same gate as a painted one |
| D7 | **Shared by every season, painted once:** the sky sets, the characters, the props, the special-day kits. They take the state's light from data the tool derives per state (tint, light maps), as they do for night | *A sky per season:* three more sky sets each; the air (calendar C2) already tints the sky |
| D8 | **Summer is spring with the air** (calendar C4, unchanged). Painted seasons are autumn and winter, autumn first | *Four painted seasons:* twice the art for the two looks that differ least |
| D9 | **The thresholds are config** (`tools/plate/season_gate.json`), set from what shipped art measures today, and the gate prints the measured value beside each | Hard-coded numbers; a threshold nobody can see |

## 6. The numbers

**One painted season of Home, at full parity with spring's states, when
all eight stations are looks:**

| Painted (Codex jobs, 2 takes each) | Autumn | Winter |
|---|---|---|
| Island plates: day 10, night 10, golden 6 | 26 | 26 |
| Erased bases: day 10, night 10 | 20 | 20 |
| Station looks, painted (8 stations x 5 levels x day and night = 80 at most) | 10 (the garden) | 80 |
| **Jobs** | **56** | **126** |

| Derived by the tools, no job | Count per season |
|---|---|
| Mattes, crops, island cuts, Map cuts | 26 each |
| Occluders | about 98 (as spring) |
| Light and shadow maps, character tints | 26 each |
| Derived looks | autumn 70, winter 0 |
| Look alpha, contact shade, look boxes, feet | reused from spring |

| Shared, nothing per season | |
|---|---|
| Geometry data, sky sets (77 images), characters, props, kits | 0 |

**For the state the app is in today** (two stations as looks, day only):
26 plates, 7 bases, 9 looks, of which the pilot paints 4 plates, 3 bases
and 6 looks.

**Cost.** Codex delivered 32 whole-plate jobs in one night (batches 173
to 176), so autumn is about two nights and winter about four
**[unverified: one sample]**. Swift: one PR (S1), then none per season.
Bundle: about 20 MB a painted season if a state with a base ships its
base and not its plate (bases 8, cuts 3, occluders 3, looks 4, golden
plates 3) **[estimate from today's bytes per piece]**; two seasons add
about 40 MB to a 104 MB catalog. Memory does not grow: one state is
loaded at a time and the 9 MB budget per state stands
(`tools/plate/ingest.py:68`).

## 7. The painting order (one source)

Each picture has exactly one parent. Nothing is painted before its parent
has passed the gate.

```
spring plate, stage 0, day          (shipped)
  -> SEASON MASTER: season plate, stage 0, day        <- the one picture he approves
       -> season plate, stage 0, night and golden     (relights; target: spring's night, golden)
       -> season base, stage 0, day and night         (stations erased from the season plate)
spring plate, stage k, day          (shipped), colour source: the season master
  -> season plate, stage k, day -> its night, golden, bases, as above
spring look take (station, level)   colour source: the season master
  -> season look, day -> its night
```

Colour has one source too: every job after the master attaches the
master as "colour only". The gate then holds each picture to it (S3 of
section 8).

**The pilot (pofu-art batch 194, row D57, 13 jobs):** one thin slice
through all of it before any volume. Autumn at island levels 10 and 3 by
day, level 10 by night, both erased bases, the windmill's looks 2 to 5
and the tea stall's look 5 in autumn; and three winter probes (level 10,
its base, windmill look 5), because snow is the case most likely to break
D2. Batch 25's autumn and snow frames are attached as palette only: they
are the palette he said feels right.

## 8. The checks (what catches a mismatch before he sees it)

One tool, `tools/plate/season_gate.py`, run on takes at review and on
shipped assets in CI. Limits live in `season_gate.json`; the starting
values come from section 3.

| # | Check | Measure | Start limit | Today's art |
|---|---|---|---|---|
| S1 | Frame held | Block shift of the season picture against its spring parent, p90 | 1.0 plate px | 0.4 to 0.7 |
| S2 | Outline held | Share of the spring matte's or look alpha's 4 px edge band where the season picture is sky on the inside or paint on the outside | 1 % | new |
| S3 | One palette | Lawn's median CIELAB against the season master's lawn, per stage; and base against its own plate | dE 4 | 4.3 to 4.6 between two repaints of one plate |
| S4 | Look sits in its season | Mean CIELAB of each look against the same station on the season plate; fit residual per station | dE 8 mean; fit median dE 7 | 5.7 to 6.3 |
| S5 | Night is the day's night | S1 between a season's day and night picks | 1.0 plate px | 0.35 to 0.58 |
| S6 | Seam | The existing paste-back ring test on each base window | as spring | shipped |
| S7 | Matte and budget | `plate_gate.py` on every season state | as spring | shipped |
| S8 | Complete | For each listed state: its plate or base, cuts, every present object's occluder, a tint, both maps, and a look for every station level that has a spring look | none missing | new |

In the app, two tests hold the same line: `SeasonStateTests` (a state not
listed resolves to spring's key for every piece; a listed state never
names a spring asset) and `HomePlateDataTests` (every asset a listed
state can ask for exists in the catalog).

## 9. Pull requests

S1 and S2 own different files and run together; S3 follows both and
batch 194. S3 touches `station_looks.py`, `ingest.py` and
`plate-home.json`, which the pond builder (1c) is in: S3 starts after 1c
merges. S1 touches `PlateIsland.swift`'s decoding, which 2b may also
touch: whichever merges second rebases.

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| S0 | `docs/season-system-v1` | test | this page, its Turkish page, ADR-0030, the sheet | The spec | link check | none |
| S1 | `feat/season-state` | test | `PofuWorld/Plate/PlateIsland.swift`, `HomePlate.swift`, `PlateCompositor.swift`, `PofuWorld/Look/WorldLook.swift`, `App/Rehearsal/RehearsalPanel.swift`, new `Tests/PofuWorldTests/SeasonStateTests.swift`, `PlateStateTests.swift` | `HomePlate` gains `season`. `PlateIsland.key(season:light:)` returns `light` for spring and `<season>-<light>` otherwise; every asset-name function and every per-light table (`painted`, `harmony`, `lightMap`, `shadowMap`, `plateCrops`, `stations.lights`, `lookLevels`) is read through it. `plate-home.json` may carry `seasons: {<season>: {complete: Bool, states: {<light>: [stage]}}}`; absent means none. `HomePlate.resolve` reads `world.season`, asks for the season's state when `complete` (or when `WorldLook.seasonOverride` is set) and it is listed, else spring's. `light` stays `day`, `golden` or `night` for the twelve places that compare it. Rehearsal gains a season stepper that sets the override | `SeasonStateTests`: spring's key equals today's names for all 26 states; an unlisted state returns spring for plate, base, look, occluder and Map cut; a listed state returns none of spring's; `complete: false` without the override is spring. Every existing `path-*` frame byte for byte (no season data ships in S1) | If the stepper does not compile in CI on the second push, drop it from S1: he reaches autumn with "next day" fourteen times |
| S2 | `tools/season-gate` | test | new `tools/plate/season_gate.py`, `season_gate.json`, `test_season_gate.py` | Checks S1 to S5 and S8 of section 8 as functions over two images or a state; a `report` command that prints measure and limit per picture. Method as in section 3 (the scratch scripts' numbers must reproduce: golden 0.40 and 0.69, windmill fit 6.2) | `test_season_gate.py`: the shipped golden and night plates pass S1; a plate shifted by 2 px fails it; a look pasted on the wrong plate fails S4; the section 3 numbers within 0.05 | If a check cannot reproduce its section 3 number, it ships as a printed measure without a limit and says so in its output |
| S3 | `art/season-slice` | eye | `tools/plate/ingest.py` (hand data may key `plates` by `<season>-<light>`), `tools/plate/station_looks.py` (season looks: spring alpha, fit or mean-colour grade; season bases from the season erase take), `design/art/plates/home/objects.json`, `stations.json`, `plate-home.json`, the slice's imagesets, `docs/state/plates.yaml` and `tools/state/check_plates.py` (a `seasons` block), `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift` | Ingest batch 194's picks: autumn at stage 0 by day and night and stage 7 by day, with bases, the windmill's looks painted and derived, the tea stall's looks derived and look 5 painted. `complete: false` | Gate report with every limit met. Frames `path-season-autumn-i10-0900` at windmill levels 2 and 5, `-i10-2300`, `-i03-0900` at tea stall levels 1 and 5, and `path-season-turn-0000`, `-0750`, `-1500` (the crossfade from spring); 1:1 crops of the windmill's foot, the stall's roof edge and one base window. Reference: the picked `x-season-autumn-l10-day` take; the island sits where `path-d21-0900` has it | A picture that fails a limit is not ingested and its state is not listed (it stays spring). If the master itself fails S1 or S2, nothing ships: the lead returns the measures to the manifest and the batch runs again |
| S4 | `art/season-autumn` | eye | `plate-home.json`, `stations.json`, `objects.json`, imagesets, `plates.yaml` | The rest of autumn in section 7's order; `complete: true` in the last commit | Gate report; `path-season-autumn-i01..i10` by day, night and golden on one sheet at Map size and three 1:1 crops per stage; S8 clean | A stage that fails twice keeps autumn at `complete: false` and the season stays in Rehearsal only |
| S5 | `art/season-winter` | eye | as S4 | Winter, after he has seen autumn on his phone | as S4 | as S4 |

Not built until its trigger: S4 waits for his word on the phone after S3.
S5 waits for S4.

## 10. What the founder sees

| When | Picture | The question |
|---|---|---|
| Now | [assets/season-system/proof-2026-11-27.jpg](assets/season-system/proof-2026-11-27.jpg): A1 beside A2, B1 beside B3 | None. It shows why one look can stand on two paintings |
| When batch 194 lands | One sheet: the shipped island, `x-season-autumn-l10-day`, batch 25's autumn; then the same for winter | "Sonbahar bu mu?" It is the only season picture he is asked to choose; every other autumn picture takes its colour from it |
| After S3 | His phone, Rehearsal, the season stepper at island level 10 and level 3; upgrade the windmill in autumn; drag to night | "Devam?" Yes starts S4 |

## 11. Out of scope

Seasons on other islands (calendar C6); a painted summer or a painted
spring other than the shipped island; a sky set per season; season looks
for a station that has no spring look yet (it follows the station's own
ladder: D52 to D56); golden bases and night looks for spring (main-flow
step 1); the air, the weather and the ambience (calendar PR C2); season
props (calendar PR C5) and special-day kits (C3); the frozen pond's water
shader (the pond is 1c's; winter lists it when its look exists); a
season's music; shrinking the bundle with on-demand resources; the
`HomePlateCrop` thumbnail, which keeps spring's plate.

## 12. Corrections

- `docs/studio/friction.md` (2026-11-27), pofu-art `QUEUE-LOG.md` D36 to
  D39 and the headers of batches 189 to 193: "stations shift between
  levels" and "nothing lines up". Measured: the frame holds to 0.2 to 0.3
  plate px; the takes are repainted, which defeats a cut by difference.
  They are sound position references.
- The brief: "looks per light (#520)". Code only; all looks and bases in
  the data are day ones.
- `PofuWorld/Plate/HomePlate.swift:16-18`: "golden hour and night are
  painted at level 10". The data paints night at ten stages and golden at
  six.
- [island-calendar-v1.md](island-calendar-v1.md) C4 (c) and PR C4: a
  season *plate* drawn in place of the shipped plate would hide station
  levels wherever looks stand. Replaced by D5, D6 and S3 here. Its
  out-of-scope line "station looks painted per season" no longer holds
  for winter.
- pofu-art `batch-177-themes-seasons.yaml` header: "the island's look
  follows the real calendar". Superseded by calendar C1.

## 13. Not verified

- No season take exists. M1 to M5 are measured on relights, level edits
  and an erase take. Batch 194 is the test of the real thing.
- That a relight of a plot crop keeps the look's outline (batch 188, the
  windmill's night, is delivered but not yet reviewed by the lead; batch
  197, the pond's night, is picked).
- The characters' tint on snow: `harmony_state` and `harmony_check.py`
  are calibrated on a green lawn. If a winter frame fails
  `harmony_check`, winter takes spring's tint for the same light and
  stage; S5's builder applies that without asking.
- The contact shade under a look is a dark green (`station_looks.py:48`)
  and may read wrong on snow; it becomes a per-season number in
  `season_gate.json`'s sibling data when S5 measures it.
- Codex's pace and the bundle estimate (section 6).
