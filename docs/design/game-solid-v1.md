# Game solid v1: a playable demo, days 1 to 21

**Status:** spec by the game lead, 2026-11-12. The founder's call: by the
demo (around 2026-11-24) the **game** is solid and playable end to end in
Rehearsal mode, ahead of the app side (gate, onboarding, the Door,
StoreKit). Art and plates keep flowing on their own track; nothing here
touches art or plate data. Six PRs, small enough for Sonnet builders to
execute without judgement calls.

Sources: [tracker](../tracker.md) §1–2.7, [roadmap](../roadmap.md),
[game plan](../product/game-plan.md) §3–5, §10,
[story map](../product/story-map/book-one.md) §2–3,
[home progression](../product/home-progression.md) §3, §4.4, §12.3,
[Koke prototype](koke-prototype.md), [flow game](flow-game.md) §1–2,
[decisions](../product/decisions.md) S, G, H, I rows; the code on `main` at
`068ee88f`.

## 1. What "solid" means (the bar)

1. Days 1–21 play in Rehearsal mode with no dead day, no dead end, no crash
   path and no state that cannot be left.
2. Every action gives visible feedback.
3. Home visibly changes as the island level rises.
4. Koke and Çağlayan are reachable and finishable.
5. Saves survive relaunch.
6. Seeds never buy screen time; Pofu never dies (ADR-0015, ADR-0017).

## 2. Scope

**In the demo:** the free `Pofu` build in Rehearsal mode (the Prova
panel's reaches and time controls), days 1–21 for a typical player: home
IL1 to about IL7, the stations and their sheets, the harbor on day 3, the
daily visitor (greeting, parcel, help, the quiet day's letter), the garden
game, Koke (rumour about day 5, healed about day 10), Çağlayan with the
flow game (rumour about day 10, healed about day 16), Çağlayan's free play
after healing, the level-up ceremony, the care beat, the weekly recap.

**Out (explicitly):** the live Screen Time gate and its "seeds buy
minutes" fix (gate track), onboarding redo, the Door, StoreKit, widget and
week page, decor spots and sets (phase E), the resident assign sheet
(phase C), island materials and upgrades (G4's "upgrade"), Çanlar and the
recall game, Revontuli onwards, the roots, the Gezgin rig, night relight,
H7 (İskele joining the home frame), new art of any kind, painted states
for golden hour, night and weather below IL10 (ADR-0022 L1 keeps the
sprite island there until the art lands).

## 3. Where we stand (evidence)

- **Linux logic tests:** 1,289 tests in 158 suites pass
  (`tools/swift/test-linux.sh -j 1`; `-j 4` runs out of memory compiling
  `PofuWorld`). CI on `main` is green.
- **The flow audit already exists and passes:** `FlowAuditTests` plays days
  1–21 for typical, heavy and perfect players through `WorldClock`. Typical:
  harbor day 3, Koke healed day 10, Çağlayan healed day 17, IL7 by day 19.
  Heavy: Koke day 11, Çağlayan day 19, IL6 by day 20, wellbeing never under
  22. The roadmap's "Game flow" row is done; what it counts as "visible" is
  not all on screen (gap G1, G8).
- **Corrections to the tracker:** Koke stages 3–4 are in the app since
  `f9043412` (2026-11-06; five `world-koke-island-N` plates ship). Home
  changes by day: the painted plate has one day state per level IL2–IL10
  (`plate-home.json` `stageLevels`). The 16 growth stand-ins draw only on
  the sprite island (dawn, dusk, golden and night below IL10, rain, fog).
- **Seeds and screen time:** `Economy.purchaseUnlock`
  (`PofuCore/Economy/Economy.swift:207`) has no caller outside tests; the
  game's jar is spent only by `WorldClock.build`. Pofu's wellbeing clamps
  at `CareRules.floor` (5).

## 4. Gaps, ranked by player impact

| # | Gap | Evidence | Fixed by |
|---|---|---|---|
| G1 | **The plate home hides the game's living layer.** By day in clear weather (where Rehearsal's "Next day" lands, 09:00) the daily visitor is neither drawn nor tappable, the Koke moss and Çağlayan fountain gifts are not drawn, and a station build has no moment on screen (no dust, no tag, no burst). Hearts, parcels, help and the quiet-day letter are out of reach most of the day | `IslandScene.swift:996-998` returns `plateObjects` (residents and occluders only, `:1059-1062`); gifts and stations are added only on the sprite path (`:1001`, `:1033-1040`); `WorldHitTest.swift:128-133` ("the visit is not drawn on the plate"); `IslandSceneModel.swift:808` passes no visitor to `plateTargets` | PR 6 |
| G2 | **Koke and Çağlayan say the wrong thing when they wait.** The rest lines promise "come back after a quiet day", but a stage needs a resisted reach today. A Rehearsal tester who only taps "Next day" never advances an island and is never told why | `koke.rest`, `caglayan.rest` in `PofuWorld/Resources/Localizable.xcstrings`; `WonderIslands.swift:172` | PR 4 |
| G3 | **Ignoring a filler blocks the main road.** Çağlayan's rumour needs Koke healed; a player who never taps Koke never meets Çağlayan, though fillers carry no main story (story map §2) | `WonderIslands.swift:161` | PR 2 |
| G4 | **The next goal never shows.** Rule 2 of home progression §3 ("Ada 6 için: 2 seviye daha", always visible) has its string but no caller | `WorldStrings.swift:181` (`nextIslandLevel`, unused); `WorldSnapshot.nextIslandLevel` is computed (`WorldClock.swift:217`) | PR 5 |
| G5 | **Çağlayan's game vanishes once healed.** G4 (accepted with Q-6) says the island keeps its game | `CaglayanScene.swift:62-71` (healed tap: a line only); `AppModel.swift:382-386` (guard `canAdvance`) | PR 3, PR 4 |
| G6 | **A half-played flow board is lost on relaunch** (flow game §2: "resumes the same day or any later day") | `AppModel.swift:68` (in memory); `CaglayanFlowView.swift:5-7` | PR 3 |
| G7 | **Two seed counts disagree.** The Today sheet shows the old wallet; Home's glance shows the jar | `App/Home/TodaySheet.swift:129` (`model.balance`) | PR 3 |
| G8 | **A decor parcel opens into nothing.** Visitors give decor ids that nothing can place; the flow audit counts them as visible change | `VisitorSchedule.swift:261-263`; no `.decor(` in `PofuWorld`; `FlowAuditTests.swift:73` | PR 2 |
| G9 | **The islands do not sleep.** Koke and Çağlayan advance, and the flow round opens, at bedtime (A21; G8: no rounds at night) | `WorldClock.swift:453`; `AppModel.swift:382` | PR 2, PR 4 |
| G10 | **Two story slips on screen.** S12: Koke bounces and says "Mmmh." at stage 4, which gives away Book Two's breathing hill; S14: Söz 1 is read off "the wall", not the mill stone through spilled tea | `KokeLayout.swift:177-186`, `koke.line.4`; `caglayan.line.3` | PR 4 |
| G11 | **Untested: relaunch mid-game and the Rehearsal path.** No test round-trips a mid-game `GameState`; `PofuStoreTests` has no game; an unreadable game silently starts fresh (`PofuSnapshot.swift:47`). No test plays the Prova panel's moves (`RehearsalTime` jumps, one reach a day) | `Tests/PofuPersistenceTests`; `Tests/PofuCoreTests` | PR 1 |
| G12 | **"Next day" alone pauses the world after three days** (72 h observation window) with only the repair banner to show for it | `EconomyConfiguration.swift:242`; `WorldClock.swift:136` | PR 1 (pinned by a test), PR 3 (panel hint) |

No crash path was found in the game code: the one `precondition` on the
flow side (`FlowRound.swift:31`) is guarded by `FlowLibrary.round` returning
`nil` for an empty stage; PR 3 must discard (not decode into) a saved round
with no boards.

## 5. Decisions (each with the alternative)

| # | Decision | Alternative not taken |
|---|---|---|
| D1 | The demo is Rehearsal mode in the free build, days 1–21. Every change lands in shared code (`PofuCore`, `PofuWorld`, `App/` used by both targets; Rehearsal is also `PofuLive`'s developer mode), so the rule "no new features for the free build" holds | `PofuLive` with the real gate (needs the membership) |
| D2 | ADR-0022 L1 stands: where no painted state exists the sprite island shows. The game's layer (visitor, gifts, build moment) draws on **both** paths | Grade the day plate for golden, night and weather (breaks "the plate is the final picture"; art track) |
| D3 | An island stage still needs a resisted reach that day; the copy says so ("Boş ver") | Count a quiet day with no opens: lets "Next day" heal islands without the core verb the demo must teach |
| D4 | Çağlayan's rumour: Koke healed **or** tended day 12, whichever comes first | Drop the Koke gate (rumour on day 8): loses the gentle tutorial order for the typical player |
| D5 | Decor parcels are off until decor spots exist (phase E): a gift parcel holds seeds. Saved decor ids still decode | Build one decor spot now (needs art) |
| D6 | Çağlayan "live" = free play after healing: it pays nothing, needs no reach, uses no round; the boards cycle stage 1→4 by day; finishing plays Damla's stage-4 line and the swell. No material, no upgrades | Nothing after healing (the best mini-game disappears around day 17) |
| D7 | The wonder islands sleep at bedtime: no stage, no flow round; each says a night line | Let Koke advance at night (it is not a game round): one rule reads simpler |
| D8 | Koke's stage 4 is wordless and still (S12; Koke spec §1 already says "wordless"); a healed tap answers with the soft swell only | Keep "Mmmh." and the bounce |
| D9 | A half-played flow round is saved in `UserDefaults` under a per-mode key (`flow.savedRound.rehearsal` / `.live`) | A file beside the snapshot (`PofuCore` cannot see `PofuGames`' `FlowRound`) |
| D10 | The Prova panel shows "Gün N" and, while Pofu hears nothing, "Adayı uyandırmak için bir kez uzan" | Make "Next day" a sign of life: the live gate cannot fake one, so Rehearsal must not |
| D11 | On the plate the visitor stands at a spot computed from `walkable` (the lawn point farthest from Pofu and the residents), not hand-placed in `plate-home.json` | Edit plate data (art track's file) |
| D12 | New Turkish lines are final as written here (voice checked against the existing `koke.*`, `caglayan.*` lines and the app's "Boş ver") | Run the `pofu-story` skill per line (the founder sees them on the phone and can ask for a pass) |

## 6. The simulated player, first (PR 1)

`Packages/PofuKit/Tests/PofuCoreTests/DemoRunTests.swift`, suite
`"Demo run, days 1 to 21"`. It runs on today's `main` and stays green; it
is the net every later PR keeps green.

**Runs.**

- `typical`: `GameScenarioTests.play(.typical, seed: 7, roundsPerVisit: [2, 1, 2], greetsVisitors: true, relaunch: true, horizon: 21)`.
- `heavy`: `GameScenarioTests.play(.heavy, seed: 7, roundsPerVisit: [1, 0, 1], greetsVisitors: true, relaunch: true, horizon: 21)`.
- The same two with `relaunch: false`, to compare.
- `tester`: the Prova panel's path, written in the test (no behaviour
  model): day 1 starts at 09:00 local (`instant(2026, 11, 2, 9)`, Istanbul
  calendar) with `.signOfLife` and `.foregroundBegan`; each day:
  `reaches` × (`.signOfLife`, `.resisted`) one minute apart from 09:01;
  collect at 09:05; build up to two cheapest open, uncapped, affordable
  levels (the same rule as `play`); play every `playableRounds` garden round
  at yield 3; at 09:07 `.tendedWonder(.koke)`, `.tendedWonder(.caglayan)`,
  `.greetedVisitor`, `.openedGift`, `.helped`; leave at 09:10; the next day
  starts at `RehearsalTime(bedtime: rules.bedtime, calendar: .istanbul).destination(of: .nextDay, from: leave)`
  with `RehearsalTime.awayEvents(leaving:returning:)`. `reaches` is 1 every
  day for `tester`; for `nextDayOnly` it is 1 on day 1 and 0 after.

**Asserts (names are the test names).**

| Test | Asserts |
|---|---|
| `everyDayIsTended(player:)` (typical, heavy) | at the end of simulated day *i* (0-based), `tendedDays == i + 1` |
| `aSaveSurvivesEveryRelaunch(player:)` | `outcome.relaunchMismatches == 0` (each of the day's three visits encodes and decodes `GameState` with `JSONEncoder` `.sortedKeys`, and the result `==` the original) and the `relaunch: true` log equals the `relaunch: false` log |
| `somethingNewOnScreenEveryThreeDays(player:)` | no window of three days without one of: a station level, an island level, the harbor, a Koke or Çağlayan phase or stage, a heart. **Decor does not count** (G8) |
| `theNextGoalIsAlwaysNear(player:)` | from day 4: `cheapestNextCost ≤ 3 ×` the mean of the previous three days' seeds (passive plus rounds); when nothing is open under the cap, `nextIslandLevel.tendedDaysLeft ≤ 3` |
| `kokeAndCaglayanAreFinishable(player:)` | typical: Koke healed by day 11, Çağlayan by day 18; heavy: Koke by day 13, Çağlayan by day 21 |
| `seedsOnlyEverBuildLevels(player:)` | each day, jar at the end `==` jar at the start `+` seeds collected `−` the costs of that day's `BuildReceipt`s |
| `pofuNeverDies(player:)` | every hourly wellbeing sample `≥ CareRules().floor` |
| `testerSeesTheHarborOnDayThree` | `tester`: harbor open at day 3's visit, not at day 2's |
| `testerHealsKokeByDayTen` | `tester`: Koke stage 4 by day 10's visit |
| `testerHealsCaglayanByDaySixteen` | `tester`: Çağlayan stage 4 by day 16's visit |
| `testerTendsEveryDay` | `tester`: `tendedDays == d − 1` at day *d*'s visit |
| `nextDayOnlyTesterPausesWithoutLoss` | `nextDayOnly`: `tendedDays` stops growing by day 5 and never falls; no level, island level, harbor or stage ever falls |

It prints one line per day per run (the format of `FlowAuditTests.render`)
so the pacing can be read in CI logs.

**Fallback (no judgement):** if an assert fails on `main`, do not loosen
it. Wrap only that `#expect` in `withKnownIssue("G<n>: <one line>")`, name
the number and the observed value in the PR body, and finish the PR.

## 7. The PRs, in merge order

At most three builders at once. **Wave A** starts now: PR 1, PR 2, PR 6.
**Wave B** starts as PR 1 and PR 2 merge: PR 3 and PR 4, then PR 5 when a
slot frees. Merge order: 1 → 2 → 3 → 4 → 5 → 6. Every PR: run
`tools/swift/test-linux.sh -j 1` before the push, then CI once; Swift
warnings are errors. User-visible PRs add `changes/<branch>.md` (one line).

| PR | Branch | Size | Model, effort | Wave |
|---|---|---|---|---|
| 1 Demo run test | `test/demo-run` | M | Sonnet high | A |
| 2 Wonder and visitor rules | `fix/wonder-rules` | S | Sonnet medium | A |
| 3 App wiring for the demo | `fix/app-demo-wiring` | M | Sonnet medium | B |
| 4 Wonder islands: lines and night | `fix/wonder-lines` | S | Sonnet medium | B (after 2) |
| 5 The next goal on Home | `feat/home-next-goal` | S | Sonnet medium | B |
| 6 The plate's living layer | `feat/plate-living-layer` | L | Sonnet high | A |

### PR 1: the demo run test

**Files:** `Packages/PofuKit/Tests/PofuCoreTests/DemoRunTests.swift` (new);
`Packages/PofuKit/Tests/PofuCoreTests/GameScenarioTests.swift`;
`Packages/PofuKit/Tests/PofuPersistenceTests/GameSaveTests.swift` (new).

- `GameScenarioTests.swift`: `DayLog` becomes `Equatable` and gains
  `jarEnd: Int`, `collected: Int`, `spent: Int`, `cheapestNextCost: Int?`,
  `nextLevelsLeft: Int?`, `nextDaysLeft: Int?`, `lowestWellbeing: Double`.
  `play` gains `relaunch: Bool = false`, `horizon: Int = days` (stop after
  `horizon` days) and `tapsKoke: Bool = true` (skips `.tendedWonder(.koke)`);
  `Outcome` gains `relaunchMismatches: Int`. Encoding failures are
  `Issue.record`, never `try!`. Defaults keep every existing test unchanged.
- `DemoRunTests.swift`: section 6, exactly.
- `GameSaveTests.swift`: `aMidGameSnapshotSurvivesTheStore`: drive a fresh
  `GameState` through `WorldClock.advance` for 14 days (a `.signOfLife` and
  a `.resisted` at 10:00, `.tendedWonder(.koke)` at 20:00, a build of the
  cheapest affordable level at 20:05), save it in a `PofuSnapshot` through
  `PofuStore` in a temporary folder (the pattern of `PofuStoreTests`),
  reload, and expect `==`.

**Acceptance:** the twelve tests of section 6 and
`aMidGameSnapshotSurvivesTheStore` pass on Linux and in CI.
**Founder:** nothing on the phone; the lead posts the day-by-day log.

### PR 2: wonder and visitor rules

**Files:** `Packages/PofuKit/Sources/PofuCore/Game/WonderIslands.swift`,
`Packages/PofuKit/Sources/PofuCore/Game/WorldClock.swift`,
`Packages/PofuKit/Sources/PofuCore/Game/VisitorSchedule.swift`,
`Packages/PofuKit/Tests/PofuCoreTests/WonderIslandsTests.swift`,
`Packages/PofuKit/Tests/PofuCoreTests/VisitorScheduleTests.swift`,
`Packages/PofuKit/Tests/PofuCoreTests/FlowAuditTests.swift`,
`changes/fix-wonder-rules.md`.

- D4: `public static let caglayanFallbackTendedDays = 12`; in `roll`,
  Çağlayan's rumour needs `tendedDays >= caglayanRumourTendedDays`, the
  harbor, and either Koke healed or `tendedDays >= caglayanFallbackTendedDays`.
- D7: `WonderStatus` gains `public var isAsleep: Bool` (init parameter,
  default `false`). In `WorldClock.snapshot`, at bedtime both statuses get
  `isAsleep = true` and `canAdvance = false`. In `apply`, `.tendedWonder`
  at bedtime (`isBedtime(at)`) changes nothing.
- D5: `VisitorRules` gains `public var decorGifts = false`; `gift(...)`
  returns `.decor` only when `rules.decorGifts`. Tests that expect a decor
  gift build their schedule with `decorGifts = true`.
- `FlowAuditTests.changes`: drop the `decor` line (it is not on screen).

**Acceptance:** new tests in `WonderIslandsTests`:
`caglayanComesAtTendedDayTwelveWhenKokeIsIgnored` (a scripted `World`: a
resisted reach every day, Koke never tended: rumour at tended day 12,
arrival two days later), `kokeStillGatesCaglayanBeforeDayTwelve`,
`wondersSleepAtBedtime` (no advance at 23:30, `isAsleep` in the snapshot);
in `VisitorScheduleTests`: `giftParcelsHoldSeedsWhileDecorIsOff`. All
existing tests stay green.
**Founder:** nothing to see yet.

### PR 3: app wiring for the demo

**Files:** `App/AppModel.swift`, `App/Home/CaglayanFlowView.swift`,
`App/Home/TodaySheet.swift`, `App/Rehearsal/RehearsalPanel.swift`,
`App/Resources/Localizable.xcstrings`, `changes/fix-app-demo-wiring.md`.

- D6: `playCaglayanFlow(stage:)` opens when `world.caglayan.canAdvance ||
  world.caglayan.isHealed`, never when `world.isBedtime`. When healed,
  `flowStage = (days from game.firstDay to today) % 4 + 1`.
  `finishCaglayanFlow()`: when the stage was already 4, apply no event and,
  after the same 450 ms, call `island.caglayan.roundFinished(newStage: 4, in: island)`.
- D9: `savedFlowRound` is written as JSON (`stage`, `round`) to
  `UserDefaults` key `flow.savedRound.rehearsal` in Rehearsal mode and
  `flow.savedRound.live` otherwise; read in `init`; removed on finish and
  in `resetRehearsal()`; a decode failure or a round with no boards removes
  the key and resumes nothing.
- G7: the Today sheet shows `model.world.jar.units` with the new string
  "%lld seeds in the jar" (tr: "Kavanozda %lld tohum").
- D10: the panel header shows "Day %lld" (tr: "Gün %lld") with
  `model.world.tendedDays + 1`; while `model.isAwaitingSignOfLife`, a caption
  under the reach buttons: "Reach once to wake the island" (tr: "Adayı
  uyandırmak için bir kez uzan").

**Acceptance:** CI builds the app; screenshots `07-prova-panel-light` (shows
"Gün N") and `15-menu-today-v3-day` (shows the jar count).
**Founder:** relaunch mid-board on Çağlayan and the board is where he left
it; the Prova panel shows the day.

### PR 4: wonder islands, lines and night

**Files:** `Packages/PofuKit/Sources/PofuWorld/Koke/KokeLayout.swift`,
`Packages/PofuKit/Sources/PofuWorld/Koke/KokeScene.swift`,
`Packages/PofuKit/Sources/PofuWorld/Caglayan/CaglayanLayout.swift`,
`Packages/PofuKit/Sources/PofuWorld/Caglayan/CaglayanScene.swift`,
`Packages/PofuKit/Sources/PofuWorld/Resources/Localizable.xcstrings`,
`Packages/PofuKit/Tests/PofuWorldTests/KokeLayoutTests.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/CaglayanLayoutTests.swift`,
`changes/fix-wonder-lines.md`.

- D7: `KokeLineKind` and `CaglayanLineKind` gain `.night` (keys
  `koke.night`, `caglayan.night`; speakers Pofu and Damla). `tapped(in:)`
  checks `status.isAsleep` first and says `.night`.
- D6: Çağlayan's healed tap calls `model.onPlayFlow?(WonderIslands.healedStage)`
  instead of saying the stage-4 line.
- D8: `KokeLayout.bounce` returns 0 at every stage (remove `bounceHeight`
  and `bouncePeriod`); stage 4 shows no bubble (`koke.line.4` removed); the
  healed tap only sets `swellStart`.
- Lines (D12), Turkish first:

| Key | tr | en |
|---|---|---|
| `koke.rest` | Uykusu derin. Bugün bir kez "Boş ver" de, sonra gel; birlikte dürteriz. | Still deep asleep. Say "Skip it" once today, then come back; we'll nudge it together. |
| `caglayan.rest` | Su acele etmez. Bugün bir kez boş ver, sonra gel. | The water isn't in a hurry. Skip one app today, then come back. |
| `koke.night` | Gece oldu; tepe uyuyor, biz de. Sabah gel. | It's night; the hill is asleep, and so are we. Come in the morning. |
| `caglayan.night` | Gece su da dinlenir. Sabah gel. | At night the water rests too. Come in the morning. |
| `caglayan.line.3` | Değirmen taşına biraz çay döktüm. Islanınca yazı çıktı: "Birinin uykusu için ışığı söndüren, o gece bekçidir." | I spilled a little tea on the mill stone. Wet, it shows writing: "Whoever puts out the light for someone's sleep is the night's keeper." |

**Acceptance:** `KokeLayoutTests.stageFourIsStill` (bounce 0 for times 0,
0.6, 1.2), `KokeLayoutTests.nightLineKey`,
`CaglayanLayoutTests.nightLineKey`; screenshots `koke-stage-4` (no bubble),
`caglayan-beat-3` (the mill-stone line).
**Founder:** tap Koke without a skip that day and it says what to do; at
night both islands say good night; Çağlayan plays again after healing.

### PR 5: the next goal on Home

**Files:** `Packages/PofuKit/Sources/PofuWorld/Home/HomeObjectViews.swift`
(`HomeGlance`), `Packages/PofuKit/Sources/PofuWorld/Home/WorldHome.swift`,
`Tests/WorldScreenshots/HomePlateScreenshotTests.swift`,
`changes/feat-home-next-goal.md`.

- `HomeGlance` gains `nextGoal: String?`, drawn as one footnote line under
  the glance in its secondary ink (`lineLimit(1)`, `minimumScaleFactor(0.8)`),
  hidden when `nil`; VoiceOver reads it after the glance.
- `WorldHome` passes `world.nextIslandLevel.map(WorldStrings.nextIslandLevel)`
  (nil at IL10, so the line goes away at Tam Çiçek).
- The test's `l5-day` state sets `world.nextIslandLevel =
  IslandLevelRequirement(level: 6, tendedDaysLeft: 0, levelsLeft: 2)`.

**Acceptance:** screenshot `home-plate-full-l5-day` shows "Ada 6 için: 2
seviye daha" under the glance; `home-plate-full-l10-day` shows no line.
**Founder:** Home always says what the next island level needs.

### PR 6: the plate's living layer

**Files:** `Packages/PofuKit/Sources/PofuWorld/Plate/PlateLife.swift` (new),
`Packages/PofuKit/Sources/PofuWorld/Scene/IslandScene.swift`,
`Packages/PofuKit/Sources/PofuWorld/Scene/IslandSceneModel.swift`,
`Packages/PofuKit/Sources/PofuWorld/Scene/WorldHitTest.swift`,
`Packages/PofuKit/Tests/PofuWorldTests/PlateLifeTests.swift` (new),
`Tests/WorldScreenshots/PlateLifeScreenshotTests.swift` (new),
`changes/feat-plate-living-layer.md`.

- `PlateLife` (pure, Linux-tested):
  - `visitorSpot(_ plate: HomePlate) -> WorldPoint` (D11): sample
    `plate.plate.walkable` on a 10-plate-pixel grid (`PlateMath.contains`);
    keep the point whose smallest distance to `plate.plate.characters`
    (Pofu, Mochi, Fındık) is largest; ties go to the smaller x, then y;
    return `plate.world(point)`.
  - `visitorParts(plate:visitor:invitationOpen:isBedtime:)`: the parts of
    `VisitorStage.parts(...)`, each moved by `visitorSpot − VisitorStage.feet(of:)`.
  - `visitorTargets(...)`: `VisitorStage.hitTargets(...)`, boxes moved the same way.
  - `mossSpot(_:)`: the walkable grid point nearest `KokeLayout.homeGift`
    that is at least 30 plate pixels from every character and from the
    visitor spot. `fountainSpot(_:)`: the top centre of
    `plate.stationBox(.pond)`, or `nil`.
  - `buildAnchor(_:station:)`: the top centre of `plate.stationBox(station)`.
- `IslandScene.plateObjects`: add the visitor's parts (drawn at
  `plate.residentScale` with the plate's harmony, as residents are at
  `:1115`), the moss when `world.koke.giftUnlocked`, the fountain when
  `world.caglayan.giftUnlocked` and the pond is built. While a build moment
  runs on the plate, draw `BuildParticles`, `BuildTag` and `LevelUpBloom`
  at `buildAnchor` with the moment's own timing (the cues `StationView`
  uses).
- `WorldHitTest.plateTargets` gains `visitor:invitationOpen:isBedtime:`
  (defaults `nil`, `false`, `false`) and appends `PlateLife.visitorTargets`;
  `IslandSceneModel.swift:808` passes them.

**Acceptance:** `PlateLifeTests`: `visitorSpotIsOnTheLawnAndClearOfEveryone`
(inside `walkable`, at least 40 plate pixels from each character),
`plateTargetsIncludeTheVisitorAndTheParcel`,
`noVisitorTargetsAtBedtimeOnThePlate`, `giftSpotsLieOnTheLawn`,
`everyHomeStationOnThePlateHasABuildAnchor`. Screenshots (IL5, noon,
clear): `plate-life-visitor-l5` (a gift visit), `plate-life-gifts-l5` (moss
and fountain), `plate-life-build-l5` (the tea stall's moment at its burst).
The lead checks the three against the plate concept before merging.
**Founder:** by day the visitor stands on the painted lawn and can be
greeted; Koke's moss and Çağlayan's fountain appear at home; building a
level shows dust, light and "Seviye N!".

## 8. Done when

All six are merged on green CI, the demo run prints days 1–21 with no
known issue left, and one screen recording of the Rehearsal path (day 1,
day 3 harbor, a visitor greeted on the plate, Koke healed, a Çağlayan board
and its replay, a relaunch mid-board) reaches the founder.
