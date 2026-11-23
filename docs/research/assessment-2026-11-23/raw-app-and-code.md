# Raw facts: the app and the code (gathered 2026-11-23)

Source: `origin/main` = a8d07c7e (#508, 2026-11-18 01:45 +03). Nothing has
merged to main in the 5 days since. Paths are on that commit. Counts come
from `git grep` / `git show` on that tree. UNCHECKED = not verified.

## 1. Apple kits

Entitlements and targets
- Two entitlement files, both used only by `PofuLive`: `Config/Entitlements/PofuLive.entitlements`
  and `Config/Entitlements/ScreenTimeExtension.entitlements`. Each holds
  `com.apple.developer.family-controls`, `com.apple.developer.usernotifications.time-sensitive`
  and App Group `group.com.erendenizk.pofu`. No HealthKit, no Associated Domains,
  no ActivityKit/WidgetKit entitlement anywhere.
- `project.yml:92-148`: target `PofuLive` = same `App/` sources + `Extensions/Shared`,
  `CODE_SIGN_ENTITLEMENTS`, compile flag `POFU_SCREEN_TIME_LIVE`, bundle id `$(POFU_BUNDLE_ID_BASE)`,
  and three extension dependencies (`PofuShieldConfiguration`, `PofuShieldAction`, `PofuActivityMonitor`).
  Target `Pofu` (free) has no entitlements and no extensions.
- Extension sources (652 lines total): `Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift`
  (ManagedSettingsUI), `Extensions/ShieldAction/ShieldActionExtension.swift` (ManagedSettings),
  `Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift` (DeviceActivity),
  `Extensions/Shared/{GateNotificationContent,ShieldStyle}.swift`.
- The only compile switch for live Screen Time is `POFU_SCREEN_TIME_LIVE`
  (`App/ScreenTime/ScreenTimeGate.swift:46`, `App/Rehearsal/RehearsalMode.swift:28`, `project.yml:129`).
  Without it no code path touches FamilyControls/ManagedSettings/DeviceActivity at run time (`docs/development.md:141-146`).

What is implemented (not stubs)
- `Packages/PofuKit/Sources/PofuScreenTime/LiveScreenTimeService.swift` (real calls): `requestAuthorization`,
  `updatePickedSelection(FamilyActivitySelection)`, `applyShield/removeShield`, `liftShields`/`restoreShields`
  (passes), `scheduleThreshold` via `DeviceActivitySchedule`, `reconcile`, `events()` stream, quick-check lift
  (`liftForQuickCheck`, line ~365). Also `LiveShieldState`, `ShieldExtensionCore` (shared by extensions), `SimulatedScreenTimeService`.
- Extension behaviour is written: usage thresholds every 15 guarded minutes recorded to the App Group inbox;
  pass monitor ends restore the shield; the shield action handles "Boş ver", "Bitti, kapat", a 3-minute quick look
  (iOS 26.4 submenu), and "Pofu'yla aç" (cannot open Pofu, so it posts a time-sensitive notification and defers).
  `ShieldCopy.swift` is 613 lines (shield text).
- App side: `App/ScreenTime/{ScreenTimeGate,ScreenTimeSetupView,ScreenTimeSettingsSection}.swift`; onboarding steps
  `welcome, screenTime, apps, name, setup, notifications, tryIt, caught` (`App/Onboarding/OnboardingView.swift:20-28`).
- CI compiles it: `.github/workflows/ci.yml` builds scheme `PofuLive` for the simulator with
  `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`, so the extensions compile; it cannot run them (no entitlement in the simulator build).
- Tests: `Packages/PofuKit/Tests/PofuScreenTimeTests` (40 `@Test`, 552 lines) cover the simulated/core logic.
- Nothing has run on a device with the entitlement: no membership-day-1 report exists. `ls docs/archive/local-reports`
  was not listed here; `docs/local/membership-day-1.md` is a script with no results section. UNCHECKED on the founder's phone.

Stubbed / mocked / flagged
- Free `Pofu` build runs the same gate on `RehearsalScreenTime` (`App/Rehearsal/RehearsalScreenTime.swift`, 420 lines;
  `RehearsalSystemMocks.swift` 181; `ShieldReplicaView.swift`) writing to its own folder `Pofu-Rehearsal`, never the App Group
  (`App/Rehearsal/RehearsalMode.swift:37-41`). `isDefault` is true in `Pofu`, false in `PofuLive`; user toggle in Settings,
  Developer section, only when launch argument `-PofuDeveloper YES` is set (`App/Settings/SettingsView.swift:78`,
  `App/Settings/DeveloperFlag.swift`).
- `ScreenTimeGate.isAvailable` false when neither live nor rehearsal: "the soft gate runs alone" (doc comment, ScreenTimeGate.swift:33-37).
- Other Apple frameworks imported in the code: UserNotifications (7 files), AppIntents (3), CoreHaptics (2), AVFoundation (2),
  MetricKit (1), CoreMotion (1), SpriteKit (8). Not imported anywhere: HealthKit (only a comment, `PofuCore/Economy/Activity.swift:20`),
  WidgetKit, ActivityKit, StoreKit, CloudKit.
- Live Activity for passes: "not started" (`docs/tracker.md:85`). Widgets: not started (founder-input line 678). Confirmed: no import.

The request and the day it is granted (docs)
- `docs/local/membership-day-1.md`: Part 1 founder enrolls, notes team ID (only in git-ignored `Config/Local.xcconfig`),
  bundle ids fixed (`com.erendenizk.pofu`, `.ShieldConfiguration`, `.ShieldAction`, `.DeviceActivityMonitor`),
  requests Family Controls (Distribution) for all four; Part 2 build `PofuLive` to the iPhone; Part 3 device cases incl. gate v2 section 15.
- Same doc and `docs/development.md:148-150`: development builds can use Family Controls on day 1 of the paid team; only TestFlight/App Store
  wait for Apple's Distribution approval ("reportedly takes weeks").
- `docs/roadmap.md:32`, `docs/tracker.md:25`: membership "expected after 2026-11-24". No doc in the files read states that the account is paid yet.
- Day-1 changes listed: set `DEVELOPMENT_TEAM`, drop the `.dev` bundle id line, `xcodegen generate`, run `PofuLive`, then "merge `Pofu` and `PofuLive`" (`docs/tracker.md:89`, queued).
- Docs mention HealthKit and Associated Domains to be enabled on day 1 (`docs/roadmap.md:162`) but no code or entitlement uses them.

Free `Pofu` build and the Shortcuts path today
- Shortcuts path: `App/Intents/{CheckInIntent,PofuShortcuts,TargetApp}.swift` (an App Shortcut "Hop in"), the guide in
  `App/Setup/SetupGuideView.swift` (642 lines), localised in `App/Resources/AppShortcuts.xcstrings`. Works with Rehearsal off
  (`docs/development.md:236-246`). Rule: no new features.
- Free build default is Rehearsal mode on, so the gate is simulated; Hop! and the world are fully playable.
- Info.plist `LSApplicationQueriesSchemes` for the hand-off back to the guarded app (`project.yml` comment on `Config/Info.plist`).
  Target apps (`ShieldedApp.swift:97` shows TikTok bundle id); Instagram/YouTube/TikTok catalog in `App/Rehearsal/RehearsalCatalog.swift`.

## 2. Systems inventory

Scale: 487 Swift files, ~98.6k lines (sources + tests). PofuWorld is 35.2k lines (incl. a 3,500-line generated
`PofuWorld/Geometry/WorldArt+Generated.swift`), App 9.8k, PofuCore 8.9k, PofuGames 7.2k, WorldScreenshots tests 5.4k.

- **Character movement, Pofu**: shipped. `PofuCompanion` (rig, springs, lids, squash, blink, breathing; `CompanionLife.swift`).
  On the painted Home Pofu does not walk; he stands (`IslandLayout.pofu`) and hops/reacts. Camera moves, Pofu does not travel.
- **Character movement, residents**: partial. Sprite island: `ResidentLife.swift` (cycle, `walkSeconds` 2.6, `walkFPS` 6,
  step-a/base/step-b frames from `ResidentPose.swift`) moves residents out and back. Painted plate: residents are baked into the
  plate and "Walks stay parked (no art, no path); a hop is only a lift" (`Scene/PlateHops.swift:3-5`).
  The discarded walk: `IslandScene.swift:723` still passes `residents: residentSteps(directive:)` (computed at lines 484-508,
  with `ResidentLife.steps(...)` over `IslandLayout.residents`) every frame, but `plateObjects` (line 1289) draws no residents and
  the only readers of `life.residents` are lines 1236 and 1483, which are the sprite path and the `.resident` case. So on the plate
  the walk loop is computed and its result is not used (confirmed by reading; per-frame cost not measured).
- **Visitors**: shipped. `PofuCore/Game/{VisitorLedger,VisitorSchedule}.swift` (reasons gift/help/festival/news/stayOver/justSitting;
  slots v1,g1,v2,h4; states arriving/present/greeted/departed; invitation; hearts; decor), `PofuWorld/Visit/VisitQueue.swift`,
  `Layout/VisitorStage.swift`, `Plate/PlateLife.swift` (`visitorParts`), arrival styles dandelion and pier. 10 `ResidentID`s declared.
- **Navigation and screens**: Home is one screen with a camera rail (Near, Mid, Map; `PofuWorld/Camera/*`, `PlaceControl.swift`),
  not tabs. Sheets: `HomeSheet` = earn, passes, settings, setup, today (`App/AppModel.swift:1323`). Covers: Hop! (`App/RootView.swift`),
  garden game, flow game. Onboarding: 8 steps. Settings: Screen Time, sound, breath haptics, developer/Rehearsal. Map: the Archipelago zoom
  (Home, Koke, Çağlayan, harbor); "voyage" appears only in open PR #503 (design), no code (`git grep -i voyage` finds nothing in App or Sources).
- **Earn and Passes sheets are unreachable in the shipped configuration**: their openers (`HomeView.swift:214, 383, 390`) are in
  `topBar`/`bottomActions`, which render only under `!FeatureFlags.worldHome` (`HomeView.swift:40`), and `worldHome = true`
  (`App/Support/FeatureFlags.swift`). `requestHomeSheet` has one caller (onboarding, `.settings`). WorldHome's actions offer only
  collect/build/settings/repair/today/play/visitor (`HomeView.swift:178-191`). So honor-session earning (`EarnSheet`) and the passes list
  cannot be opened from Home by reading the code. UNCHECKED in a running app.
- **Audio and music**: partial. `PofuSound` (1,061 lines): 20 cue kinds, 49-ish `.caf` files (seed-pop, bloom, combo, piece, deal, cheek,
  round-end, collect, skip-chime, pofu-hop, gulp, level-up, door-knock, kettle, water-wheel/splash/pour, gulls, breath-pad), 4 ambience beds
  (wind, crickets, rain, hush; 3 s seamless loops), `AmbienceConductor` by hour/weather/level. No music anywhere (grep "music" finds only TikTok).
  No voice: Pofu voice proofs (`pofu-giggle`, `-chew`, `-poke`, `-sniff`, `-sleepy-sigh`) exist only under `design/sound/proof/`, not in the bundle.
  Sound is app-only (extensions never link it).
- **Haptics**: shipped, partly. `PofuDesignSystem/PofuHaptics.swift`, `PofuGames/Flow/Scene/FlowHaptics.swift`, `Scene/GardenHaptics.swift`,
  `App/Hop/BreathHaptics.swift` (CoreHaptics breath). One TODO: last island level's three-transient celebration falls back to `.success`
  (`PofuWorld/Home/WorldHome.swift:144`).
- **Minigames**: Garden (tile-tray puzzle; `PofuGames/Core/Garden*`, `UI/GardenGameView`, `Scene/GardenScene` 1,158 lines): shipped, rounds per day via
  `RoundLedger`. Flow (water channels on a board; 8 boards in `Resources/flow-boards.json`; solver `FlowSolver.swift`; scene `FlowScene` 789, art
  `FlowArt` 977): shipped, used as Çağlayan's stage game (`App/Home/CaglayanFlowView.swift`, saved round, free play after healing).
  Hop! breath room (`App/Hop/BreathRoom/BreathScene/GateScene`): shipped. No third arcade game in code.
- **Station sheet**: shipped. `PofuWorld/Scene/StationSheet.swift` (423 lines): grabber, header plate with level pips, rate now/next, one build
  action, one flavour line, play door for the garden. PR #507 (open, docs) proposes redoing it from scratch.
- **Seeds and economy**: shipped. `PofuCore/Economy/{Economy,Wallet,Energy,QuietTime,EconomyConfiguration}`; quiet-time seeds collected from
  Pofu's cheeks (`AppModel.collectWorldSeeds`), round yields (`creditRound`), honor sessions (`economy.earn`, AppModel.swift:1041). Pay-for-minutes
  code still exists and is tested but has no caller outside Economy.swift: `purchaseUnlock`, `quote(s)`, `cheapestQuote`, `canAffordAnyUnlock`,
  `grantEmergencyPass`, `escalationSteps`, `creditSteps` (0 hits in App/ and Sources/ elsewhere; 1-15 test hits each). `refund` has 3 non-test callers
  (ending a pass early). Gate comments: "seeds never buy screen time" (`Gate/Gatekeeper.swift:105`, `FrictionLadder.swift:5`).
- **Stations and island levels**: shipped. `PofuCore/Game/Archipelago.swift:323-355`: home levels 1-10 (tended-day floors 1,2,3,4,6,10,14,20,30,36;
  growth 0..40), 8 stations x 5 levels (garden, teaStall, pond, workshop, windmill on home; bagelCart, pier, lighthouse on harbor), costs 5-130 seeds.
  Art: tea stall only has looks at stages 3,4,6,7 (`docs/now.md`); 16 growth pieces use baked sprites "when the pipeline has one, otherwise code stand-ins"
  (`Scene/GrowthArt.swift`, `Layout/IslandGrowth.swift`; which pieces still use stand-ins: UNCHECKED).
  Wonder islands: Koke and Çağlayan (`PofuCore/Game/WonderIslands.swift`, `PofuWorld/{Koke,Caglayan}`), phases hidden/rumoured/arrived; far bell on tended day 21
  (`PofuCore/Game/FarBell.swift`).
- **Story and dialogue delivery**: partial. Strings are in Swift and xcstrings, not read from `content/`: `PofuWorld/Scene/WorldStrings.swift`
  (135 `String(localized:)`), `App/Support/PofuLines.swift`, `PofuCore/ScreenTime/ShieldCopy.swift`. All 3 catalogs have a Turkish entry for every key
  (App 277/277, PofuWorld 179/179, PofuGames 58/58). `residentLines` returns 3 lines only for Mochi and Fındık; every other resident returns `[]`
  (`WorldStrings.swift:126-142`). Delivery surfaces: Pofu's speech bubble and visit card (`VisitBeat`, `beatLine`, listening/prelude lines), Koke/Çağlayan lines,
  island-grow lines, far bell. `content/` has 47 moments, 40 character files, 20 island files, 17 station files, 52 ideas, 51 systems, validated by
  `tools/content/validate.py` in CI but no Swift code loads them (grep `content/(moments|characters|islands|stations)` finds only python tools).

## 3. Health

CI, last 15 runs on main (`gh api .../actions/runs?branch=main&per_page=15`), newest first; duration = updated - started:
- a8d07c7e 11-17 success 9m | a1dd2885 success 40m | 85a50d8e success 37m | 74ab2182 cancelled 45m | 350b5941 success 46m | cbabb326 success 39m
- 0e354a15 success 1m | 8120aa75 cancelled 2m | e238f367 cancelled 17m | 54914d6c success 44m | 445fb55f cancelled 21m | d89b37fe success 42m
- 3e5618c9 success 38m | fa255b00 cancelled 21m | 5c44d1b5 success 8m
- Result: 10 success, 5 cancelled (superseded by newer pushes, `cancel-in-progress: true`), 0 failed. Job split on run a1dd2885:
  PofuKit tests + build 31m, python tools 10m, player-path frames 11m, publish screenshots 8m. Run a8d07c7e: macOS job 9m, others skipped (docs-only).
- CI steps (ci.yml): `swift test` with `-warnings-as-errors`; builds `Pofu` and `PofuLive` for the simulator with warnings as errors; renders world screenshots
  and motion beats; python tools job (asset/plate/colour/content gates). macOS job timeout 45m (runs of 44-46m are at the ceiling).

Tests (counts of `@Test` / `func test*` on main; parametrised tests run more):
- PofuCore 532 (38 files), PofuWorld 799 (64 files), PofuGames 77, PofuDesignSystem 48, PofuScreenTime 40, PofuCompanion 38, PofuPersistence 29,
  PofuSound 28, PofuTuning 15, WorldScreenshots (app-hosted, `Tests/WorldScreenshots`) 55. Total about 1,661. No test target for `App/` or `Extensions/`.
- Test code is ~23k lines of ~98.6k.

TODO/FIXME/HACK: 1 in all Swift (`PofuWorld/Home/WorldHome.swift:144`, haptics). 0 in Python tools (`git grep -nE 'TODO|FIXME|HACK' -- tools '*.py'`).

Feature flags and switches
- `FeatureFlags.islandHome = true`, `worldHome = true` (`App/Support/FeatureFlags.swift`); the else-branches in `HomeView.swift:30-60` are dead (see Earn/Passes above).
- `POFU_SCREEN_TIME_LIVE` compile condition (PofuLive only).
- `POFU_FLOW_GROUND=keycaps` launch env, default `lawn` (`PofuGames/Flow/Core/FlowGround.swift:13-18`); only other env var in Swift.
- Launch args/UserDefaults: `-PofuDeveloper YES` (`DeveloperFlag`), `-PofuSkin`, `rehearsal.enabled`.
- `WorldLook` (`PofuWorld/Look/WorldLook.swift`): `homePlates = true`, `hd2d`; `WorldLook.legacy` (line 124) keeps the old sprite look.
- 12 `#if DEBUG` blocks in App+Sources.

Parallel / dead paths
- Two Home renderers: painted plates (`HomePlate.resolve`, "at its level, by day, in clear weather; otherwise the sprite island", IslandScene.swift:264-269)
  and the sprite island (`IslandLayout`, `IslandDressing`, `IslandGrowth`, `GrowthArt`, `ResidentLife`). Both are live: the sprite island shows below the plate's lowest
  level (plate `minLevel` 1) or when no painted state exists (weather/hour not painted).
- Sprite-path-only code that runs per frame on the plate: `residentSteps` (above).
- Pay-for-minutes economy (above), `!worldHome` Home branch with `topBar`/`bottomActions`, `EarnSheet`, `PassesSheet` (reachability above).
- Flow ground method A (`keycaps`) kept as a switch for comparison frames.
- Shortcuts path kept alongside the live gate.

Largest files (lines)
- 3,500 `PofuWorld/Geometry/WorldArt+Generated.swift` (generated) | 2,564 `PofuWorld/Scene/IslandScene.swift` | 1,650 `Scene/IslandSceneModel.swift` |
  1,331 `App/AppModel.swift` | 1,158 `PofuGames/Scene/GardenScene.swift` | 977 `Flow/Scene/FlowArt.swift` | 871 `Home/HomeObjectViews.swift` |
  845 `Scene/WorldLookLayers.swift` | 835 `Home/WorldHome.swift` | 789 `Flow/Scene/FlowScene.swift` | 763 `GameScenarioTests.swift` | 642 `App/Setup/SetupGuideView.swift`
  | 613 `PofuCore/ScreenTime/ShieldCopy.swift` | 605 `TuningLabPanel.swift`.
- Repo: 1,161 commits on main, 142 remote branches; `design/art` 6,081 files, `Packages/PofuKit` 2,681 files, `content/assets` 882.

## 4. Open PRs (9, as of 2026-11-23 14:10 UTC; `gh api repos/ErenDenizK/pofu/pulls?state=open`)

| # | Opened | Last update | Age | Size (+/- files) | State | Title / waiting on |
|---|---|---|---|---|---|---|
| 507 | 11-17 | 11-17 | 6d | +813/-1, 12 | clean, CI green | docs(design): flow board as a tabletop toy, station sheet from scratch (two week plan); waits for review/founder |
| 503 | 11-16 | 11-16 | 7d | +1068/-0, 36 | conflicts (dirty) | design(world): island progression v1, a voyage in place of the Map; 1 comment; needs rebase and founder picks |
| 490 | 11-16 | 11-16 | 7d | +410/-1, 8 | mergeable unknown | docs(design): UI grammar v1, two planes; now.md says "no app change until the founder has seen it" |
| 461 | 11-14 | 11-15 | 9d | +1227/-0, 13 | clean, draft | docs(design): feel and world v1, "proposal, do not merge" |
| 453 | 11-14 | 11-14 | 9d | +1129/-261, 49 | conflicts (dirty), draft | feat(assets): Wave 0 slice 2, station sheet, resident card, celebration cards; 9 check runs cancelled |
| 442 | 11-14 | 11-14 | 9d | +240/-0, 1 | clean | docs(research): route for 2026-11-14 through the cut line |
| 317 | 11-06 | 11-06 | 17d | +1/-0, 1 | unknown | docs: tracker notes Çağlayan and follow-ups |
| 135 | 11-03 | 11-03 | 20d | +173/-25, 2 | unknown | docs(story): fold design-loop decisions into lore and delivery |
| 108 | 11-03 | 11-03 | 20d | +1048/-0, 3 | unknown | feat(imagegen): persist operator recovery evidence |

- All 9 are docs/design/tooling; only #453 touches app/package code (49 files, conflicted, cancelled). No open PR carries a player-facing app change.
- Whether each is waiting on the founder or on the lead is not recorded in the PRs themselves (UNCHECKED beyond `docs/now.md` for #490).

## 5. Docs drift

- `docs/now.md` is dated 2026-11-16 (last commit touching it 11-16); main has moved through #508 (11-18). Its "Merged" line stops at #498; main also
  has #499-#502, #505, #506, #508 merged. It lists WP10 compositor (#500) and the near lens (WP11, #502) as in flight / next; both are merged.
  Last play recorded "11-14 (main 0cf03ca1)"; no later entry. now.md itself says roadmap.md and tracker.md are stale.
- `docs/tracker.md:25,71`: "the gate still lets seeds buy minutes (R1)" / "seeds still buy minutes". Code: no caller buys minutes (`purchaseUnlock` and
  quotes are unused in App/Sources; `Gatekeeper.swift:105`: only a free pass or leaving). Tracker last touched 11-12.
- `docs/tracker.md:26`: "night relight is a spike off by default" and "all 16 growth pieces are code stand-ins"; the code has `RelightMath`/`pofuRelight`
  and `GrowthView` prefers baked sprites when they exist; the current state of each: UNCHECKED.
- `docs/tracker.md:26`: "founder has not tested on the phone since 2026-11-05"; `docs/now.md` says he last played 11-14. The two pages disagree.
- `docs/roadmap.md:162`: day-1 checklist enables HealthKit and Associated Domains; no HealthKit/associated-domains use or entitlement exists in code.
- `docs/roadmap.md:32` / `docs/tracker.md:25` "membership expected after 2026-11-24" vs `docs/local/membership-day-1.md`, which treats the paid team as the
  trigger and Distribution approval as a later weeks-long wait; the roadmap's order (enroll, then request) matches, no doc says whether enrollment has happened.
- `docs/now.md` goal "Now: world presentation (#474)": all of #474 steps up to near lens merged; PRs #490, #503, #507 (open, unmerged) pivot to UI grammar,
  island progression/voyage and a station sheet rebuild, none of which `now.md` mentions as in flight.
- `docs/studio.md` (last touched 11-15) and the PR table above: 5 of the 9 open PRs are 9-20 days old with no row in `now.md`'s "In flight".

## Could not check
- Whether the membership has been bought or the Distribution request filed (no source in the repo); no on-device result for `PofuLive` exists in the files read.
- Runtime behaviour: per-frame cost of the discarded `residentSteps`, whether Earn/Passes are truly unreachable in a running build, which growth pieces still use stand-ins.
- CI step-level timing for runs other than a8d07c7e and a1dd2885; swift test totals as executed (counted only `@Test`/`func test` declarations).
- Whether PRs wait on the founder or the lead beyond what `now.md` states.
