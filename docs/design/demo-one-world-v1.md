# Demo one world v1: every Home and wonder-island frame is painted, days 1 to 21

**Status:** spec by the look desk, 2026-11-12, for the lead. Base: `origin/main` at
`1364ac01` (code identical to `3d053570`). The founder's demo is around 2026-11-24;
everything here is meant to be on his iPhone by 2026-11-22. A fresh-eyes critic ranked
"two different games stitched together" (the painted plate and the old sprite island
taking turns) as the most visible defect of the demo. This spec makes the
Rehearsal path one painted world with **five core PRs, two art-gated PRs and four new
art jobs**.

Sources: the code at `1364ac01` (cited `path:line`); `docs/state/plates.yaml`;
`pofu-art` `QUEUE.md` at `769f709` and branch `art/batch-76-redo-picks` at `5e2e73f`;
the demo run log of `DemoRunTests` (`printsTheTestersDays`, run by the lead on
2026-11-12); CI frames on `screenshots/main`; the critic's crops in the session
scratchpad (`rehearsal/path-sheet.jpg`, `k_row.jpg`, `rum.png`).
[game-solid-v1](game-solid-v1.md) is the shape this follows.

## 1. What "done" means (as the founder will see it)

On his iPhone, in Rehearsal mode, days 1 to 21:

1. Every Home frame is a painting: at 09:00 after "Next day", at 06:00 after
   "Morning", at 23:00 after "Night", every hour the "1 hour ahead" button walks
   through, and in every weather. No frame shows the sprite island.
2. Koke and the harbor stop sit under the same painted sky as Home, at the hour's
   light; Koke's stages 0 to 2 are painted at final colour like stages 3 and 4.
3. Çağlayan is a painting at every stage, hour and weather.
4. A level-up, an hour change or a weather change is a crossfade between two
   paintings (`PlateHomeLayer.crossfade`, 1.4 s), never a cut to another style.

## 2. Where we stand (evidence)

**What the player reaches.** The Rehearsal tester (one resisted reach a day, "Next
day" to 09:00) plays: IL1 day 1, IL2 day 2, IL3 day 3 (harbor), IL4 days 4 to 6, IL5
days 7 to 10 (Koke rumour day 5, arrival day 6, stages 1 to 4 days 7 to 10), IL6 days
11 to 15 (Çağlayan stages 1 to 3 days 13 to 15), IL7 days 16 to 21 (Çağlayan healed
day 16). The heavy run stalls at IL3 from day 4. **IL8 needs 24 tended days and IL10
needs 36** (`Packages/PofuKit/Sources/PofuCore/Game/Archipelago.swift:328`, `:331`):
no demo player ever reaches the only level with painted golden and night.

**When Home is painted today.** `HomePlate.state`
(`Packages/PofuKit/Sources/PofuWorld/Plate/HomePlate.swift:102-116`) returns a plate
only in clear weather without a rainbow (`:109`), only in the bands day 07:45 to 17:30,
golden 17:30 to 19:30 and night from 20:00 to 05:45 or at bedtime (`:83-97`), by day
only from IL2 (`plate-home.json` `minLevel 2`, `stageLevels [10..2]`;
`PlateIsland.swift:214-217`), and at golden and night only at the final level
(`HomePlate.swift:115`; `lightStages {golden: 1, night: 1}`). Everything else is the
sprite island (`IslandScene.swift:486`, `:753-776`).

**The Rehearsal panel's landings.** "Next day" lands at 09:00
(`PofuCore/Rehearsal/RehearsalTime.swift:28`, `:53-54`); "Night" at bedtime start,
23:00; "Morning" at bedtime end, 06:00 (`RehearsalTime.swift:49-52`;
`PofuCore/Economy/EconomyConfiguration.swift:124-127`); the buttons are at
`App/Rehearsal/RehearsalPanel.swift:97-105` and `:175-186`. 06:00 is in no band, so
**every "Morning" press shows the sprite island at every level**.

**Weather at the hours the panel lands on.** The weather is a seeded bag of half days
(`PofuWorld/Sky/Weather.swift:103-105`: 16 clear, 6 overcast, 3 rain, 2 mist, 1 golden
haze in 28), trimmed by hour (`:107-112`, `:159-185`). A Python port of
`WeatherForecast.bag` over 120 start dates gives, per 21 days:

| Hour | Overcast | Mist | Rain | Rainbow | Golden haze | Not clear |
|---|---|---|---|---|---|---|
| 06:00 and 09:00 | 4.1 | 3.0 | 2.2 | 0 | 0 | **9.3 days** |
| 12:00 | 4.4 | 0 | 2.1 | 2.2 | 0 | 8.7 |
| 18:00 | 4.9 | 0 | 0 | 0 | 1.5 | 6.4 |
| 21:00 and 23:00 | 4.9 | 0 | 0 | 0 | 0 | 4.9 |

(Computed off-code; the bag is not behaviour-driven, so the shares hold for any
player.)

**Çağlayan** (`Plate/CaglayanPlate.swift:29-49`, `plate-caglayan.json` `painted`):
day at stages 0 to 4, night at 2 and 3, golden and rain at 4; overcast, mist and golden
haze always sprite (`:44-45`); rain at night sprite (`:42`).

**Koke and the harbor** are never "painted" stops (`IslandScene.swift:486`): they draw
the code sky (`LivingSky`, `:623-627`), the code cloud sea and height fog (`:629-636`,
`:753-766`) under the world's grade (`:555-565`). Koke's stages 0 to 2 are old
pale art lifted by code fog, shade and a deepened sky (`Koke/KokeLook.swift:4-8`,
`Look/WorldLight.swift:270-276`). From the harbor, Koke is a code hump in the far sky
(`IslandScene.swift:612-615`; the grey semicircle in the critic's `rum.png`).

**Painted and picked, not in the app** (`docs/state/plates.yaml`, all files present
under `design/art/takes/`): Home night IL2 to IL9 (batch-72, IL2 batch-74 v2), Home IL1
day (`batch-74-redo-states/x-home-flow-il1-v3` take 2), Çağlayan night stages 0 and 1
(batch-74 v2). On `pofu-art` branch `art/batch-76-redo-picks`: Çağlayan stage-4 sky
masters golden, night and rain v2 (portrait), Emanet night 1 v3, Home bare v4.

**What a 21-day Rehearsal sees today**, counting one 09:00 visit and one 23:00 visit a
day (the founder plays in the evening), plus Koke and Çağlayan visits from arrival:

| Frame | Sprite today | After this spec |
|---|---|---|
| Home at night (23:00) | 21 of 21 | 0 (IL1's night after A1; until then 1) |
| Home at 09:00 | 1 (IL1) + about 9 (weather) | 0 |
| Home after "Morning" (06:00) | every press | 0 |
| Home 17:30 to 20:00 | every visit | 0 |
| Koke (days 6 to 21) | every visit, code sky | painted sky; stages 0 to 2 repainted after A2 |
| Çağlayan at night (days 12 to 21) | stages 0, 1 and 4: about 8 nights | 0 |
| Çağlayan in overcast, mist, golden haze (days 12 to 21) | about 4 mornings | 0 |
| Harbor stop (rumours on days 5 and 11) | 2 views | painted sky; the harbor isle sprite stays |

## 3. Corrections

1. `game-solid-v1.md` §2 "Out" and §5 D2, and the comments at `HomePlate.swift:16-20`
   and `CaglayanPlate.swift:10-13`, credit ADR-0022 L1 with "the sprite island shows
   where no painted state exists". ADR-0022's L1 (`docs/adr/0022-plate-first-islands.md:110`)
   is a light ladder: day and night **painted at every stage**, golden, dusk, dawn and
   rain **fitted**. The sprite fallback is a code convention, not an ADR rule.
2. The brief calls `x-home-flow-bare-v4` an IL1 candidate. Its review on
   `art/batch-76-redo-picks` says it is an edit of IL1 v3 take 2 that removes the
   sunflower patch, the cart wheel and the rope bridge ("EXPLORATION: never
   promote"): a pre-IL1 "bare" state. No game state shows a bare island
   (`Archipelago.swift:270-275`: the level starts at 1). IL1 is `plates.yaml`
   `il1/day/clear` (batch-74 v3 take 2).
3. `game-solid-v1.md` §3: "the 16 growth stand-ins draw only on the sprite island
   (dawn, dusk, golden and night below IL10, rain, fog)". After PR 1 and PR 2 they
   draw in no demo frame.
4. `tools/plate/ingest.py:201-204` (`present`): "golden and night exist at level 10
   only, where everything is painted". False as soon as night ships per level (PR 2
   fixes it).
5. `QUEUE.md` row B-G (`batch-38-island-arcs`, blocked) is concept frames "in the game
   camera", not stage plates; nothing in this spec needs it.

## 4. Gaps, ranked by how often the player meets them

| # | Gap | Evidence | Closed by |
|---|---|---|---|
| G1 | **Home at night is the sprite island on every night of the demo.** Painted nights exist only at IL10, which needs 36 tended days | `HomePlate.swift:115`; `Archipelago.swift:328-331`; `plates.yaml` il2-il9 night picked, `in_app: false` | PR 1, PR 2 (A1 for IL1) |
| G2 | **Any weather but clear drops Home to the sprite island**: about 9 of 21 mornings at 09:00, 5 of 21 nights | `HomePlate.swift:109`; `Weather.swift:103-105`, `:173-184`; table in §2 | PR 1, PR 3 (rain streaks) |
| G3 | **Dawn, dusk and golden hour drop to the sprite island**: every "Morning" press (06:00), every visit 17:30 to 20:00 | `HomePlate.swift:83-97`, `:115`; `RehearsalTime.swift:49-52` | PR 1 |
| G4 | **Çağlayan at night and in grey weather is the sprite island**: night at stages 0, 1 (picked, not shipped) and 4 (not painted), overcast, mist and golden haze at every stage | `CaglayanPlate.swift:42-48`; `plate-caglayan.json` `painted.night [2, 3]` | PR 1, PR 4 (PR 5 stretch) |
| G5 | **Koke is in the other game**: code sky, code cloud sea and fog, world grade; stages 0 to 2 are the old pale art lifted by code fog | `IslandScene.swift:486`, `:555-565`, `:623-636`, `:753-766`; `KokeLook.swift:4-8`; `WorldLight.swift:270-276` | PR 3, A2 + PR 7 |
| G6 | **Day 1 is the sprite island at every hour** (IL1 is not painted in the app): the first impression | `plate-home.json` `minLevel 2`; `PlateIsland.swift:214-217`; `plates.yaml` il1 day picked | PR 2, A1 + PR 6 |
| G7 | **The harbor's rumour views** (Koke day 5, Çağlayan day 11) are the code sky with a grey code hump | `IslandScene.swift:612-615`, `:623-627`; `screenshots/main` `koke-rumour-harbor.jpg` | PR 3 (sky only) |

## 5. Decisions (each with the alternative)

| # | Decision | Alternative not taken |
|---|---|---|
| D1 | **A painted island never shows its sprite island while that stage has a painted light to borrow.** Each hour wants one light; an unpainted light borrows in a fixed order: day → day; golden → golden, night, day; night → night, golden (never day). Data, in `HomePlate.borrowed` | Keep the sprite fallback (today: "two games"); or paint every missing cell (36 jobs, over the gate) |
| D2 | **Weather never replaces the painting.** In any weather the hour's painting shows. Light rain by day or at golden hour shows the painted `rain` light where one exists (Çağlayan stage 4), else the hour's painting with the existing code rain streaks and splashes over it (no puddle glints, no grade). Overcast, mist, golden haze and the rainbow draw nothing over a plate until they are painted or baked (ADR-0025's founder-gated pilot) | Runtime overcast or mist grade over the plate (ADR-0023 (a) forbids it); keep the sprite island in grey weather (9 of 21 mornings) |
| D3 | **The hour bands close the gaps:** day from 06:00 (bedtime's end, so "Morning" shows morning), golden from 17:30, night from 20:00 and at bedtime. `HomePlate.dayStarts`, `goldenStarts`, `nightStarts` are the tunable numbers | Night until 06:45 (truer to the colour script's dawn cell, `design/art/colour-script.json` minute 345 to 465, but the "Morning" button would show the moon) |
| D4 | **Unpainted golden hour borrows the night** (lamps, moon, lit doors): in November in Istanbul it is dark by 17:30, and the founder plays in the evening | Borrow the day until 19:30 (a sunlit island at 19:00) |
| D5 | **Home nights IL2 to IL9 ship as whole plates plus backdrop** (like the IL2 to IL9 days); only IL10 keeps its sky set (`SkySet.swift:128-133`). About +12 MB of HEIC in the app | Split a sky set per night (ADR-0025 path, about 30 min of tooling and a screen check per state): after the demo |
| D6 | **IL1 is the batch-74 IL1 v3 take 2, with its own matte** (its harbour islet stands apart and its hill has a tree, so the level-10 matte does not fit it) | Use the bare v4 (an edit that removes the garden, wrong for IL1); or keep IL1 a sprite (day 1 is the first impression) |
| D7 | **Koke and the harbor stop draw Home's painted sky set** of the hour's light (day, golden or night at stage 0, which all exist), without its island layer, placed around the stop, instead of the code sky, cloud sea and height fog; depth of field off as on the plate. The island sprites keep the world's grade (they are sprites, not plates: ADR-0023 covers plates) | Koke plate-first (5 day and 5 night plates, a Koke plate path and ingest: about 10 jobs and an L PR; after the demo); or leave Koke as it is |
| D8 | **Koke's stages 0 to 2 are repainted at final colour** as edits of the picked stage 3 (A2, 3 jobs), the same asset names, and their code fog, shade, contrast and sky deepening go to neutral | Keep the code lift over the pale art (`KokeLook.swift:4-8` decided "not regenerated"; that was before the plate home) |
| D9 | **The harbor's sprite isle stays** for the demo; only its sky is painted. The rumour still happens at the harbor | Retarget the harbor stop onto the plate's painted harbour islet (H7, a camera change); or say the rumour at Home (a story-location change) |
| D10 | **No ADR.** D1 to D4 are a table and three numbers; reversing them is an edit of `HomePlate.swift`. The lead may promote D1 and D2 to ADR-0027 after the founder sees the demo | ADR-0027 now |
| D11 | **Art total: 4 new jobs** (A1, A2), under the 20-job gate. Golden per level is not painted: ADR-0022 L1 and ADR-0025 fit golden from each island's own painted pair, and D4 covers the demo | Paint golden IL1 to IL7 (+7), Koke plates (+10), Çağlayan golden and rain stages 0 to 3 (+8), Home rain IL1 to IL7 (+7): 36, over the gate |

## 6. Art jobs (manifest rows for `pofu-art`)

The lead adds these to `pofu-art` `QUEUE.md` Demand and writes their manifests; no
builder touches `pofu-art`.

| Row | Batch | Jobs | Method | Can run now | Order and fallbacks |
|---|---|---|---|---|---|
| A1 | `batch-79-home-il1-night` | 1: `x-home-flow-il1-night` | an edit of the picked IL1 v3 take 2 (`design/art/takes/batch-74-redo-states/x-home-flow-il1-v3/plate__x-home-flow-il1-v3--t2.webp`), night as `batch-72-home-night` painted it, with `x-home-flow-il2-night-v2` take 2 attached as the night reference. Existing method | yes | 2 takes; a take that moves the silhouette, a door or the harbour islet is kept with the failure noted; no third take |
| A2 | `batch-80-koke-final-colour` | 3: `koke-island-0-v2`, `-1-v2`, `-2-v2` | edits of the picked `koke-island-3` (`design/art/takes/koke-lead-picks-2026-11-06/koke-island-3`) back to stages 0 to 2 (asleep, moss thin, no warm light before stage 2), at final colour under `plate-style-v1`, same canvas and registration as stage 3. New for Koke, so the three are the pilot (2 to 5 jobs) | yes | stage 0 first; if stage 0 fails review, stop and do not run 1 and 2; 2 takes each; no third take |

Total: **4 jobs**, 8 takes. PR 5 (stretch) uses the existing batch-76 pick, no new job.

## 7. The PRs, in merge order

At most three builders at once. **Wave A** starts now: PR 1, PR 2, PR 4. **Wave B**:
PR 3 when PR 1 merges; PR 6 when A1 is picked and PR 2 has merged; PR 7 when A2 is
picked. PR 5 is a stretch (go/no-go below). Merge order: 1 → 2 → 4 → 3 → 6 → 7 → 5.
Every PR: `tools/swift/test-linux.sh -j 1` before the push, CI once (Swift warnings are
errors), at most three pushes. User-visible PRs add `changes/<branch>.md` (one line).
PR 2 and PR 4 both edit `docs/state/plates.yaml` (CI derives `in_app` from the shipped
plate files and fails on a mismatch: `tools/state/check_plates.py:10-14`,
`.github/workflows/ci.yml:101`): PR 2 edits only the `home:` block, PR 4 only the
`caglayan:` block, and the later one rebases.

| PR | Branch | Size | Model, effort | Accepted by | Wave |
|---|---|---|---|---|---|
| 1 Every hour and weather painted | `feat/plate-every-hour` | S | Sonnet medium | test | A |
| 2 Home nights and IL1 | `feat/home-nights` | L | Sonnet high | eye | A |
| 4 Çağlayan's early nights | `feat/caglayan-nights` | S | Sonnet medium | eye | A |
| 3 The painted sky everywhere | `feat/painted-sky-everywhere` | M | Sonnet high | eye | B |
| 6 Home IL1 night (art-gated) | `feat/home-il1-night` | S | Sonnet medium | eye | B |
| 7 Koke at final colour (art-gated) | `feat/koke-final-colour` | S | Sonnet medium | eye | B |
| 5 Çağlayan's healed night (stretch) | `feat/caglayan-healed-night` | M | Sonnet high | eye | B |

### PR 1: every hour and weather painted (test)

**Files:** `Packages/PofuKit/Sources/PofuWorld/Plate/HomePlate.swift`,
`Packages/PofuKit/Sources/PofuWorld/Plate/CaglayanPlate.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/PlateTests.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/PlateStateTests.swift` (new),
`Tests/WorldScreenshots/CaglayanPlateScreenshotTests.swift`,
`changes/feat-plate-every-hour.md`.

- `HomePlate.swift`: replace `dayHours`, `goldenHours` and `lightBand(hour:isBedtime:) -> String?`
  (`:83-97`) with `public static let dayStarts = 6.0`, `goldenStarts = 17.5`,
  `nightStarts = 20.0`; `isNightHour(h)` is `h >= nightStarts || h < dayStarts`;
  `public static func light(hour: Double, isBedtime: Bool) -> String` returns "night"
  at bedtime or a night hour, "day" before `goldenStarts`, else "golden" (D3). Add
  `public static let borrowed: [String: [String]] = ["day": ["day"], "golden": ["golden", "night", "day"], "night": ["night", "golden"]]` (D1, D4).
  Add `public static func paintedState(in plate: PlateIsland, stage: Int, hour: Double, weather: WeatherConditions, isBedtime: Bool) -> (light: String, stage: Int)?`:
  `wanted = borrowed[light] ?? [light]`; when `weather.weather.isRaining` and the light
  is not "night", insert "rain" first; return the first `w` in `wanted` with
  `plate.paints(light: w, stage: stage)` (D2). `state(in:islandLevel:...)` becomes:
  `guard let stage = plate.dayStage(islandLevel:)` else `nil`, then `paintedState`.
  Delete the `weather == .clear, !rainbow` guard (`:109`) and the final-level rule
  (`:115`); `paints` already says golden and night are painted at stage 0 only. Rewrite
  the doc comments at `:16-20` and `:78-101` to say this (and drop the "ADR-0022 L1"
  attribution, Correction 1).
- `CaglayanPlate.swift`: `caglayanState` clamps the stage as now (`:47`) and returns
  `paintedState`. Delete `:36-46`. Rewrite the comments at `:10-13` and `:25-28`.
- `PlateTests.swift`: delete `choosesItsPaintedStateByLevelHourAndWeather` (`:212`),
  `paintsTheDayOfEveryStageAndTheNightsGoldenAndRainThatExist` (`:441`),
  `everyOtherStateKeepsTheSpriteIsland` (`:458`), and in `resolvesFromTheLooksHourAndWeather`
  (`:236`) change the rain expectation to `?.light == "day"`.
- `PlateStateTests.swift`, suite `"Plate states, every hour"`. Fixture tests decode a
  minimal `PlateIsland` from inline JSON (`PlateIsland.decode`; keys `island`,
  `plateSize`, `lights`, `painted`, `stageLevels`, `islandBox`, `objects: []`).
  Shipped-data tests assert only facts that stay true after PR 2 and PR 4.
- `CaglayanPlateScreenshotTests.swift` (`:53-57`): the healed island at night now
  borrows golden: shot renamed `caglayan-plate-borrowed-s4-night`, `expecting: "golden"`
  (the `XCTAssertEqual(... stage)` at `:76` holds; the sky-set check at `:79` holds).

**Acceptance (named tests):** `everyHourHasALight` (hours 0 to 24 by 0.25: 05:59 night,
06:00 day, 17:30 golden, 20:00 night, bedtime night); `theMorningJumpLandsOnTheDay`
(`RehearsalTime` from 23:30 with `EconomyConfiguration().bedtime`, `.morning` →
`light` "day"); `theNightJumpLandsOnTheNight`; `goldenBorrowsTheNightThenTheDay`;
`nightBorrowsGoldenAndNeverTheDay` (night and golden unpainted → `nil`);
`everyWeatherShowsTheHoursPainting` (overcast, mist, golden haze, rainbow give the
clear result); `paintedRainWinsByDayAndNeverAtNight`;
`homeDaysAtLevelsTwoToTenAreAlwaysPainted` (shipped: IL 2 to 10, 06:00 to 17:15 by
0.25, every weather → "day"); `homeFinalLevelKeepsItsGoldenAndNight` (IL10 18:00 →
golden-0, 22:30 → night-0); `caglayanIsPaintedAtEveryStageByDayAndGolden` (shipped:
stages 0 to 4, 06:00 to 19:45, every weather → non-nil);
`caglayanHealedNightBorrowsGolden` (stage 4, 22:30 → golden-4). All other tests stay
green; the iOS CI shot `caglayan-plate-borrowed-s4-night` shows the golden painting.
**Founder:** grey mornings, rain and the "Morning" button show the painted island from
IL2; at IL2 to IL9 golden hour and night are still the sprite island until PR 2.
(`weather-home-*` CI frames turn into plates: expected.)
**Fallback:** if an existing test outside the four named above fails because it
expected the sprite island, change its expectation to the D1 result and name it in
the PR body; never add a weather or hour guard back.

### PR 2: Home nights IL2 to IL9 and the IL1 day (eye)

**Files:** `design/art/plates/home/objects.json`, `design/art/plates/home/matte-day-9.png`
(new), `tools/plate/ingest.py`, `tools/plate/test_ingest.py`,
`Packages/PofuKit/Sources/PofuWorld/Resources/Plates/plate-home.json`,
`Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets/world-home-*-night-{1..8}*`
and `world-home-*-day-9*` (new imagesets), `docs/state/plates.yaml` (`home:` block),
`Packages/PofuKit/Tests/PofuWorldTests/HomePlateDataTests.swift` (new),
`Tests/WorldScreenshots/HomeNightScreenshotTests.swift` (new), `changes/feat-home-nights.md`.

- `objects.json`: `plates.night` gains stages 1 to 8 = IL9 to IL2, each the
  `plates.yaml` `il<N>/night/clear` path; `plates.day` gains `"9"` = the `il1/day/clear`
  path; `stageLevels` becomes `[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]`, `minLevel` 1; add
  `"lampsFromLevel": 6` (`HomeFixtures.lampsOpenAtLevel`,
  `Layout/HomeFixtures.swift:38`). Object stages at IL1 (stage 9): `teaStall` gets
  `"stages": [0..8]` (it opens at IL2, `Archipelago.swift:341`), `wheel` gets
  `[0..8]` (IL1 paints a cart wheel lying down, not the upright wheel), `garden`
  appends 9; every other object already lists its stages.
- `ingest.py`: `present()` (`:201-204`) applies `stages` to every light (a night stage
  is the day stage's level); `problems()` (`:862-867`) the same; `cmd_matte` gains
  `--state <light>:<stage>` and writes only that matte; `harmony_state` sets `pool` only
  when the stage's level (`stageLevels[stage]`) is at least `lampsFromLevel` (`:695-697`).
  Tests in `test_ingest.py`: `test_present_honours_stages_for_every_light`,
  `test_matte_writes_only_the_named_state`, `test_pool_starts_at_the_lamp_level`.
- Run `pip install -r tools/plate/requirements.txt opencv-python-headless onnxruntime`,
  `python3 -I tools/plate/ingest.py matte home --state day:9`,
  `python3 -I tools/plate/ingest.py all home` (upscaled x2), `check home`. Existing
  states must come out byte-identical (the tools are deterministic): `git status` shows
  only new imagesets and `plate-home.json`.
- `HomePlateDataTests.swift`: `paintsTheNightOfEveryLevelFromTwo` (`painted["night"] == 0...8`);
  `paintsTheDayOfEveryLevelFromOne` (`painted["day"] == 0...9`, `stageLevels.last == 1`);
  `lowLevelNightsHaveNoLampPool` (night harmony `pool == 0` for IL2 to IL5);
  `theTestersTwentyOneDaysArePainted`: the tester's levels `[1, 2, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7]`,
  hours 06:00, 09:00, 12:00, 18:00, 19:45 and 23:00 (bedtime), every `Weather` and a
  rainbow → `HomePlate.state` non-nil; IL1 at 18:00, 19:45 and 23:00 inside
  `withKnownIssue("A1: IL1 night not painted yet")`.
- `HomeNightScreenshotTests.swift` (the render of `HomePlateScreenshotTests.swift:50-115`
  copied): `home-plate-full-l1-day`, `home-plate-full-l2-night`, `home-plate-full-l4-night`,
  `home-plate-full-l7-night`, `home-plate-full-l5-golden` (borrowed night),
  `home-plate-full-l5-dawn` (06:00, day).

**Acceptance:** the Swift tests above and `PlateTests` green; `python3 -I tools/plate/test_ingest.py`;
`python3 -I tools/plate/ingest.py check home` clean; `python3 -I tools/state/check_plates.py` clean;
`python3 -I tools/plate/harmony_check.py home-plate-full-l2-night.png home-plate-full-l4-night.png home-plate-full-l7-night.png`
passes the night rules. **Eye:** each new frame at 1:1 crops (lawn edge, harbour
islet, Pofu) matches its picked take in `design/art/takes/` (named in `plates.yaml`);
the characters' night read matches `home-plate-full-l10-night` on `screenshots/main`.
**Founder:** every evening of the demo is the painted night of his level; day 1 is the
painted IL1 by day.
**Fallback:** if `check home` or the `l1-day` crop shows IL1's matte failing (halo,
cut islet), remove `day "9"` and the stage-9 object edits, keep `minLevel` 2, ship the
nights, and drop IL1 from `theTestersTwentyOneDaysArePainted` with a known issue
"G6: IL1 matte". If the upscale model cannot be downloaded, stop and report; never
ship `--no-upscale` (it would re-deliver every state at half detail).

### PR 4: Çağlayan's early nights (eye)

**Files:** `design/art/plates/caglayan/objects.json`,
`Packages/PofuKit/Sources/PofuWorld/Resources/Plates/plate-caglayan.json`,
`Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets/world-caglayan-*-night-{0,1}*`
(new), `docs/state/plates.yaml` (`caglayan:` block),
`Packages/PofuKit/Tests/PofuWorldTests/CaglayanPlateDataTests.swift` (new),
`Tests/WorldScreenshots/CaglayanNightScreenshotTests.swift` (new),
`changes/feat-caglayan-nights.md`.

- `objects.json`: `plates.night` gains stages 0 and 1 from `plates.yaml`
  (`batch-74-redo-states/x-caglayan-flow-0-night-v2` and `-1-night-v2`, take 1). Run
  `python3 -I tools/plate/ingest.py all caglayan` and `check caglayan`; existing states
  byte-identical as in PR 2.
- Tests: `paintsTheNightOfEveryStageBeforeHealing` (`painted["night"] == [0, 1, 2, 3]`);
  `everyCaglayanFrameOfTheDemoIsPainted` (stages 0 to 4, the six hours of PR 2, every
  weather → non-nil). Screenshots: `caglayan-plate-full-s0-night`, `caglayan-plate-full-s1-night`
  (the render of `CaglayanPlateScreenshotTests.swift:60-90` copied).

**Acceptance:** tests green; `harmony_check.py --island caglayan --reference s4-day`
on the two frames. **Eye:** each frame matches its picked take; Damla's night read
matches `caglayan-plate-full-s2-night` on `screenshots/main`.
**Founder:** Çağlayan at night is painted from the day it arrives.
**Fallback:** if a stage fails `check` (polygon off the painted shape), ship the other
one alone and name the failure.

### PR 3: the painted sky everywhere (eye)

Starts when PR 1 has merged (it calls `HomePlate.light`).

**Files:** `Packages/PofuKit/Sources/PofuWorld/Plate/PaintedSky.swift` (new),
`Packages/PofuKit/Sources/PofuWorld/Scene/IslandScene.swift`,
`Packages/PofuKit/Sources/PofuWorld/Sky/SkySetView.swift`,
`Packages/PofuKit/Sources/PofuWorld/Scene/WeatherLayer.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/PaintedSkyTests.swift` (new),
`Tests/WorldScreenshots/PaintedSkyScreenshotTests.swift` (new),
`changes/feat-painted-sky-everywhere.md`.

- `PaintedSky` (pure): `public static let stops: [IslandID: (centre: WorldPoint, width: Double)]`
  for `.koke` (`KokeLayout.center`) and `.harbor` (the harbor isle's centre,
  `IslandLayout.swift:159`), widths tuned so the coverage tests pass (config);
  `public static func sky(for island: IslandID, world: WorldSnapshot, look: WorldLook, calendar: Calendar = .current) -> HomePlate?`
  returns `HomePlate(plate: home, light: HomePlate.light(...), stage: 0, placement: .island(...))`
  when `look.homePlates`, the island is in `stops` and `skySet != nil`; else `nil`.
- `SkySetView.swift`: `SkySetLayers` gains `var drawsIsland = true`; when false, layers
  of kind `.island` are skipped.
- `IslandScene.swift`: `let paintedSky = PaintedSky.sky(for: model.island, ...)`. When
  non-nil: draw `SkySetLayers(sky:, plate: paintedSky, ..., drawsIsland: false)`
  ungraded in place of `LivingSky` (`:623-627`); skip the rainbow and behind-fog
  (`:629-636`), `CloudSea` and the front `FogCards` (`:753-766`); set the lens gain to 0
  as for a plate (`:501`). Rain, the screen haze and the grade on the island sprites
  stay. On a painted Home or Çağlayan (`painted`), draw
  `WeatherRain(..., glints: false)` above the characters (D2); nothing else.
- `WeatherLayer.swift`: `WeatherRain` gains `var glints = true`; false skips the puddle
  glints.
- Tests: `kokeAndTheHarborTakeHomesSkyAtTheHoursLight` (12:00 day, 18:00 golden, 23:00
  night); `theSkyCoversTheScreenAtTheKokeStop`, `theSkyCoversTheScreenAtTheHarborStop`
  (as `PlateTests.theBackdropCoversTheScreenAtTheStop`, `:519`);
  `homeAndCaglayanKeepTheirOwnPainting` (`nil`); `noPaintedSkyWithoutPlates`.
- Screenshots: `koke-sky-s0-day`, `koke-sky-s2-night`, `koke-sky-s4-golden`,
  `harbor-sky-rumour-day`, `home-plate-full-l5-rain`, `home-plate-full-l5-overcast`.

**Acceptance:** tests green. **Eye:** the sky above Koke and the harbor isle equals the
sky of `home-plate-full-l10-day`, `-l10-golden`, `-l10-night` (`screenshots/main`) at
1:1 crops, with no seam where the island layer is skipped; Koke's island equals
`koke-stage-N` (`screenshots/main`) apart from its background; the rain streaks over
the plate are the size and density of `weather-home-rain` (`screenshots/main`);
`home-plate-full-l5-overcast` equals `home-plate-full-l5-day`.
**Founder:** Koke and the harbor stand in Home's painted sky; rain falls on the painted
island.
**Fallback:** if the skipped island layer leaves a hole in the sky set's cloud sea at
the Koke or harbor stop, draw the home `backdrop` image of that light behind the set
(it carries the painted sea); if that still shows the home island, ship Koke only, keep
the harbor on the code sky and name G7 as open.

### PR 6: Home IL1 night (eye, art-gated on A1)

**Files:** `design/art/plates/home/objects.json`, `plate-home.json`, the
`world-home-*-night-9*` imagesets, `docs/state/plates.yaml` (`home: il1`),
`HomePlateDataTests.swift` (remove the known issue), `HomeNightScreenshotTests.swift`
(add `home-plate-full-l1-night`), `changes/feat-home-il1-night.md`. Ingest the A1 pick
into `design/art/takes/` with `tools/art/ingest.py`, then as PR 2.
**Acceptance:** `theTestersTwentyOneDaysArePainted` green without the known issue;
**eye** against the A1 pick and `home-plate-full-l2-night`. **Founder:** day 1's evening
is painted. **Fallback:** if A1 is not picked by 2026-11-19, do not start; day 1's
night stays the sprite island (one evening).

### PR 7: Koke at final colour (eye, art-gated on A2)

**Files:** `Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets/world-koke-island-{0,1,2}*`
(the image and its `__deep`, `__soft`, `-shadow` variants, made by the command of the
commit that last touched `world-koke-island-3.imageset`, `501173b4`),
`Packages/PofuKit/Sources/PofuWorld/Look/WorldLight.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/KokeLayoutTests.swift`,
`changes/feat-koke-final-colour.md`.
- `WorldLight.swift:270-276`: `kokeFogAmount`, `kokeShaftAlpha`, `kokeShade`,
  `kokeCardOpacity`, `kokeSkyDeepen` become all zeros and `kokeContrast` all ones.
- Test `KokeLayoutTests.repaintedStagesAreNotLifted` (`KokeStageLook(stage:).isActive == false` for 0 to 4).
**Acceptance:** test green; **eye**: `koke-sky-s0-day` and `koke-stage-0..2` against
the A2 picks at 1:1. **Founder:** Koke's sleep reads in the painting, not under a
veil. **Fallback:** if only stage 0 is picked, do not start (no mixed set).

### PR 5: Çağlayan's healed night (stretch, eye)

Go only if PRs 1 to 4 have merged by 2026-11-18; otherwise out, and D1's golden
borrow stands. Ingest `x-caglayan-sky-night-v2` take 1 from `pofu-art`
`art/batch-76-redo-picks`; `portrait.py master` and `split.py caglayan --light night`
and `skyset_export.py caglayan --light night` as the day's (`tools/plate/README.md`);
a landscape `night-4` plate cut from the master by the inverse of `portraitFrame`
(scale 2/3 at (0, 425)) for `objects.json`. **Files:** `design/art/plates/caglayan/**`,
`plate-caglayan.json`, `skyset-caglayan.json`, `world-caglayan-*-night-4*`,
`plates.yaml`, `CaglayanNightScreenshotTests.swift` (`caglayan-plate-full-s4-night`),
`CaglayanPlateScreenshotTests.swift` (remove the borrowed shot).
**Eye:** `screen_check.py caglayan sky` thresholds and the master at 1:1.
**Fallback:** any check fails, close the PR.

## 8. Done when

PRs 1 to 4 are merged on green CI; `theTestersTwentyOneDaysArePainted` and
`everyCaglayanFrameOfTheDemoIsPainted` pass (with at most the A1 known issue); and one
screen recording on the founder's phone walks: day 1 at the real evening hour, "Next
day" in grey weather, "Morning", "Night" at IL4, a level-up crossfade, Koke at stage 0
and healed, Çağlayan at night, the harbor rumour. No frame of it is the sprite island
of Home or Çağlayan.

## 9. Out of scope

- Game feedback (greeting, gift and board-solve feedback, copy): another builder.
- App and onboarding work, the Door, StoreKit, the gate.
- The Map's zoomed-out frame (code sky with island cuts) and the flight between stops.
- The garden game and the flow board screens (their own UI).
- The screen haze (wellbeing) over a plate: not drawn today, unchanged.
- Overcast, mist, golden-haze and rainbow looks on a painted island; puddle glints on a
  plate; ADR-0025's rain and golden bake pilot.
- Painted golden hour below IL10; Home rain plates (the picked IL10 rain take is not
  shipped); sky sets for IL1 to IL9.
- Koke plate-first, Koke at night as a painting; the harbor isle's repaint or H7.
- The 16 growth stand-ins and the sprite island's code (left in place, unused in the
  demo path).
- Revontuli, Emanet, Mehtap and the batch-76 Emanet night.
- App size beyond noting it (+about 12 MB in PR 2).

## 10. Open decisions (default in bold) and what was not verified

- D2: the weather on a painted island is rain streaks only. **Default: yes**; the
  founder's "every weather within 14 days" (2026-11-06) is then only partly visible
  until the bake pilot.
- D3 and D4: dawn is day from 06:00 and unpainted golden is night. **Default: yes.**
- D7 and D8: Koke under Home's sky plus three repaints, not Koke plates. **Default: yes.**
- Not verified: what the harbor stop draws behind its isle once the code sky is gone
  (PR 3 fallback covers it); that `ingest.py all home` reproduces existing states byte
  for byte here (OpenCV and the upscale model are not installed in this container);
  that the IL1 matte separates the harbour islet cleanly; the 21-day weather counts
  come from a Python port of `WeatherForecast.bag`, not from a Swift test.
