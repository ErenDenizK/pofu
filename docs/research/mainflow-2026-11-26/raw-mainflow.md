# Raw facts: the main flow today (gathered 2026-11-26, scout)

Sources, read only: pofu `origin/main` = 87e4745e (#517, 2026-11-25 06:14 UTC; 29 commits and 8 merged PRs after the 11-23 baseline's a8d07c7e);
pofu-art `origin/main` = ee7ec96 (#169, 2026-11-26). Paths in pofu are under `Packages/PofuKit/Sources/` unless they start with `App/`, `Tests/` or `docs/`
(PW = PofuWorld). "Plate" = the painted Home picture. UNCHECKED = not verified. No frame was opened: frame names come from the tree listing of
`screenshots/main` (head "world screenshots and motion beats for main at 87e4745", 2026-11-25 03:49 UTC, 456 blobs, 826 MB).
Baseline = `docs/research/assessment-2026-11-23/raw-*.md`.

## 0. What changed since the baseline, and what it got wrong

Merged on main since a8d07c7e: #510 pass pill (honor session cut, `App/Earn/EarnSheet.swift` deleted), #512 station card (replaces `StationSheet.swift`,
`PotPips.swift`), #513 Home composition, #514 + #518 stream board as blocks and dials (flow kit PNGs replaced; `flow-board-edge/channel/lawn/...` deleted),
#515 sound on + Pofu voice, #516 OpenCV pin, #517 characters hop between spots, #511/#509 assessment docs. Each has a `changes/*.md` line.
- Still open PRs (REST `pulls?state=open`): the same nine (#507, #503, #490, #461, #453, #442, #317, #135, #108); none updated since 11-17. Open issues: none (0 issues in
  `issues?state=all`). `docs/now.md` still reads "Updated: 2026-11-16" (`docs/now.md`, line 'Updated: 2026-11-16').
- Baseline wrong, and fixed by the round-2 doc (`docs/design/assessment-2026-11-24-path.md` section 1) or by me: sprite island at Home is not a player risk (scout-sprite-fallback.md);
  the resident walk is not discarded (only dx/dy unused); residents are not baked into the plate (`IslandScene.swift:1313`); "Pofu has no voice in the bundle": now 6 voice `.caf`
  (`PofuSound/Resources/pofu-*.caf`). Baseline "Earn sheet unreachable": now deleted. `PassesSheet` is still unreachable: its only opener is `HomeView.swift:225` inside `topBar`
  (`HomeView.swift:222`), drawn only when `!FeatureFlags.worldHome` (flag true).
- A stray `sheet2.png` was added at the repo root in this range (`git diff --name-status a8d07c7e origin/main`: `A sheet2.png`).
- `plates.yaml` unchanged since 11-16; counts reproduce the baseline: home 66 cells, 23 painted, 21 in app; Çağlayan 54/16/12; Revontuli 54/15/0; Emanet 54/14/0; Mehtap 54/15/0
  (`docs/state/plates.yaml`, parsed with yaml; `founder_ok` null everywhere).

## 1. Camera (map, near lens, pinch, transitions)

Code
- Three framings Map/mid/near on one rail: `PW/Camera/CameraRail.swift:5-45` (`WorldFraming`), near rests at `nearRestScale` 4.5, limit 7.4 (`world-map.json` `near`); chrome fades 1.05-1.25 x mid.
- Gestures: single tap, double tap (one framing in, or rest near on a character), `MagnifyGesture` pinch, one-finger drag/peek/brush, one-thumb zoom (double tap-hold-drag):
  `PW/Scene/IslandScene.swift:164-225`, `PW/Camera/OneThumbZoom.swift`. Place control (52 pt disc, tap or long-press menu): `PW/Scene/PlaceControl.swift`.
- Transitions: `CameraFlight` rise/travel/descend 0.35/0.30/0.35, 0.9-1.6 s (`PW/Camera/CameraFlight.swift:7-9,31-35`); `IslandSceneModel.go(to:)` :549, `fly(to:)` :682.
- Near lens: `PW/Plate/NearLensViews.swift`, `NearLayers.swift`, `PW/Camera/NearShot.swift` (feet at 0.60 of height). Shots numbers in `plate-home.json` `near.shots`.
- Changed since baseline (#513): mid centre row 383 -> 416, `youngFill` 0.72 -> 0.82 (now data), tier pitch 470 -> 478, whale box moved (`world-map.json`, `CameraRail.swift:111`).
Tests: `PofuWorldTests` CameraRail 15, CameraFlight 15, CameraRelease 13, RailV2 13, Lens 18, ThinLens 13, WorldMap 12 (counts of `@Test`). Frames (names only): `path-d01-0900`, `path-d01-map-0900`,
  `path-d10-*`, `path-d21-*`, `motion-0.00..2.00`, `water-day/night-near-*`, `spike-dof-*`; `Tests/WorldScreenshots/MapPaintedScreenshotTests`, `MotionBeatTests`, `PlayerPathScreenshotTests` (16 tests).
Art: near patch and near dressing are empty in the shipped data: `plate-home.json` `near` has `shots`, `lipRow`, `flat`, `dressing: []` and no `patch` key; `NearLayers.swift:9-11` says the patch, dressing and
  foreground are "art that is not in yet (batches 110, 107 and 119)". pofu-art PRs #74 (110) and #89 (119) are still open.
Planned, not built: WP12 unlock/tier reveals (`docs/design/world-presentation-build-spec.md:141`, row WP12 at :284; code comments "its reveal is WP12's", `MapSlots.swift:9,92,355`; no `world-reveals` code found);
  the Map as a voyage (ADR-0028 only in open #503, `git grep -i voyage` on main finds nothing in App/Sources/Tests).

## 2. Home and station levels, growth objects, island progression

How a level is earned (code): island level = f(tended days, growth) where growth is built station levels (`PofuCore/Game/Archipelago.swift:272-277`); 10 levels, tended-day floors 1,2,3,4,6,10,14,20,30,36,
  growth 0,2,3,6,10,15,20,26,34,40 (`:326-337`); 8 stations x 5 levels (garden, teaStall, pond, workshop, windmill on home; bagelCart, pier, lighthouse on harbor), costs 5-130 seeds, 1,950 in all (`:315-355`).
  Seeds come from Pofu's cheeks and game rounds; the honor session is gone (`changes/feat-day1-pass-pill.md`). Pay-for-minutes code: not re-checked (baseline).
What changes on screen at an island level: the whole Home plate swaps by stage with a cross-fade, bloom and "Ada n" card, timed 0-4.6 s (`PW/Moments/IslandGrowMoment.swift:1-20`); stage from `stageLevels [10..1]`
  (`plate-home.json`). Shipped Home plate imagesets: 21 = day 10 stages + night 10 stages + golden 1 (`World.xcassets world-home-plate-*`). Golden is painted only for the final level
  (plates.yaml `final.golden` in_app; `lightStages golden 1`); golden hour (17:30-20:00, `HomePlate.swift:79-82`) borrows night first at levels 1-9 (`HomePlate.swift:102-106`).
  Bare (level 0 state) day plate is painted, not in app. Minimum level 1 (`plate-home.json` `minLevel`).
What changes on screen at a station level: only the tea stall has per-level looks: `plate-home.json` `stations` holds only `teaStall`, 5 looks, `light: day`, `baseStages [3,4,6,7]`; imagesets
  `world-home-look-teaStall-1..5-day` and `world-home-base-day-3..7` (day only). By `stageLevels` those stages are levels 7,6,4,3 (derived). Other stations: no look data; they keep the painted plate
  (`PW/Plate/PlateCompositor.swift:13-16`). Station level-up reveal (ring, dip, settle) is coded for looked stations (`PW/Scene/StationReveal.swift:1-14`).
Growth objects: the 15 `GrowthKind` pieces (`PW/Layout/IslandGrowth.swift`) are drawn only in the sprite-island branch (`IslandScene.swift:1241`, after `if let plate { return plateObjects }` at :1206-1208);
  on the painted Home growth is the plate itself. `tracker.md` claim "16 growth pieces are code stand-ins" is about that branch.
Docs planned, not built: per-station painted levels for 7 of 8 stations (`docs/studio/briefs/codex-2026-11-26-mainflow-queue.md` item 2; pofu-art batch 123/129/137: 129 DROPPED, 137 BLOCKED, `pofu-art QUEUE.md` Blocked table);
  pond ladder concepts batch 142 (11 jobs) and 150 (9) delivered as takes, not shipped; windmill "progression approved earlier" (`docs/design/assessment-2026-11-23.md` status table, "Island and stations" row); roots grow (`decisions.md` H11).
Open PRs: #503 (island progression v1, `mergeable_state` dirty), #453 (draft, station sheet/cards, superseded in practice by #512). Issues: none.
Station card (#512): `PW/Scene/StationCard.swift` (353 lines), variants Etiket (`tag`, default) and Hap (`pill`), switch in Settings (`App/Settings/SettingsView.swift:79,168-190`); level marks/ornaments (pofu-art 159, 162) are NOT in the app
  (no `mark-`/`orn-` file in pofu `App` or `Packages`).

## 3. Home themes

Code: nothing themed exists. `Season` enum and `Season.of(...)` are defined (`PW/Sky/Weather.swift:40-60`) and used only by `WeatherTests.swift:132-142`; no view reads it (`git grep Season` over App, Packages, Tests).
  Home hour bands: day from 06:00, golden 17:30, night 20:00 (`HomePlate.swift:79-82`); weather: clear, overcast, lightRain, mist, goldenHaze (`Weather.swift:10-15`); rain over a plate is code streaks
  (`HomePlate.swift:112-117`).
Docs: seasons "follow the real calendar plus a small weekly theme" (`docs/product/home-layout.md:17`); decisions H10: "L, not F", founder said "bilmiyorum... değerlendirelim" (`docs/product/decisions.md:112`);
  seasons table with looks per season and "season sets" (`docs/product/home-progression.md:360-380`); Plus "Island themes (cherry, autumn, snow-globe)", free seasonal touches (`docs/product/game-design.md:383-397`).
  No ADR or brief defines "Home themes" as a feature beyond these (grep `theme` over docs/design, docs/studio, docs/decisions found only these and unrelated hits). The 11-26 Codex queue brief says "search pofu docs for theme / tema" (`codex-2026-11-26-mainflow-queue.md:26`).
Art: pofu-art has `batch-25-seasons` (7 jobs: autumn, rain, snow, snow-night, spring, summer, summer-evening); `x-season-summer` t2 was the stand-in Home plate on 11-10 (`founder-input.md:613`); `batch-32-weekly-themes*` is referenced in
  `docs/design/concept-inventory.md:285-300` but has no takes folder in pofu-art main. None of this is in the app.

## 4. Travel between islands; the Gezgin at every stage

In the app: camera flight to an island from the Map or the place-control menu (section 1). Islands reachable: Home, harbor (İskele), Koke, Çağlayan (`WonderIslands.swift`, `Archipelago.swift:28`); Koke and Çağlayan phases hidden/rumoured/arrived,
  far bell on tended day 21 (`PofuCore/Game/FarBell.swift`). No voyage, no Gezgin vehicle, no mooring in code.
The Gezgin in code is a visitor: a postcard "drifts in on a dandelion seed" before any island is healed (`PofuCore/Game/VisitorSchedule.swift:220-235`), visiting residents shipped = Damla and Gezgin (`:70`). Arrival style `pier` ("Gezgin lands them")
  exists as an enum case (`PW/Layout/VisitorStage.swift:27-33`). Gezgin on the Map is the painted whale in the sky set, gliding (`PW/Sky/SkySet.swift:21-34`, `world-home-sky-whale-*`).
  Nazlı sprite pieces (`world-nazli-body/eyes-closed/fins/tail/island-patch`) are in `WorldArt+Generated.swift:2537-2629`; no code draws them (`git grep nazli-body` finds only the generated table).
Docs: Gezgin = Nazlı, the cloud whale, form 1 early at the harbor, form 2 at the finale (`docs/product/story-map/book-one.md:124-135,219`); decided 11-24: island choice opens both by tapping the Gezgin and the bottom-right button, built
  with the voyage; 2-3 levels, front view, tail, fluffy, mooring matters (`founder-input.md:799,801`); #503 proposes the voyage, Nazlı three beats, mooring under Home's harbor (`gh api pulls/503` body). Path doc: voyage waits for stage 1 and 2 (`assessment-2026-11-24-path.md` stage 4, "Held").
Art in pofu-art (takes, nothing shipped): batch 143 (16 jobs, round 1), 148 voyage (13), 151 Gezgin models + levels 1-7 (15), 154 concept3 Gezgin (8: lv1, lv1-bead, lv1-front, lv2, lv3, moor-home, moor-caglayan, moor-row), 160 Gezgin source cut-outs (7: lv1-3 cut and awake, mooring-post),
  164 moorings (12: home/koke/caglayan x lv1-3 + front). QA auto-picks only; no founder pick recorded for any (QUEUE-LOG "EXPLORATIONS, never promoted"). Founder-input 43 says her level 1 must have a tail, fluffy; QUEUE.md says batch 154 redid it.
  The 20 shipped `world-nazli-*` imagesets: which batch they came from is UNCHECKED.

## 5. Islands on the map and in the voyage, visual state

Map slots by progress (`world-map.json` `stages`, `slotStates cloud/veiled/island`; `PW/Scene/MapSlots.swift:36-47`): stage 1 Koke veiled + Çağlayan cloud; stage 2 Koke island + Çağlayan veiled; stage 3 both islands; three tier-2 slots with states veiled/cloud/cloud and no art.
  Map frames: tier 0 Home alone (`homeAloneWidth` 0.70), tier 1, tier 2 (`MapSlots.swift:50-60`). Home's own map art: 21 `world-home-mapisle-*` imagesets. Far isles generic `world-far-isle-1..3`.
Koke: code-drawn, no plate (`PW/Koke/KokeLayout.swift`; no `plate-koke.json`; only `plate-home.json` and `plate-caglayan.json` under `PW/Resources/Plates`), 36 `world-koke-*` imagesets.
Çağlayan: plate `plate-caglayan.json`, imagesets day 5, night 5, golden 1, rain 1; no `water` polygons (the `water` key is empty or absent); frames `caglayan-plate-*` 12, `caglayan-stage-*` 5.
Harbor: sprite island `harbor-island-s` at `IslandLayout.swift:159`; its three stations also appear as objects in the Home plate data (`plate-home.json` objects: bagelCart, pier, lighthouse). How the harbor reads on the Map today: UNCHECKED.
Revontuli, Emanet, Mehtap: only far-sky marks (`PW/Sky/FarSkyLayout.swift:35-45`), visitor profiles (`VisitorSchedule.swift:95-98`), plates painted not shipped (14-15 cells each, in_app 0).
Open PRs: #503 (voyage view), #461 draft (feel and world v1). pofu-art: batch-120 far isles PR #90 open.

## 6. Characters: movement, animation, interaction

- Pofu: bundled body is still the placeholder hamster, `pofu-hamster.png` (`PofuCompanion/CompanionArt.swift:33-35`, `CompanionRig.swift:59`). Rig with springs, lids, squash, blink, breath (baseline). Tap: poke or giggle (2nd tap within 2.5 s) or sleepy sigh at bedtime
  (`PofuSound/PofuVoice.swift:5-24`); sniff and chew cues wired (`App/WorldSound.swift:130,148`). pofu-art batch 156 "front" concept: 1 of 6 delivered.
- Movement on the painted Home (#517): Pofu, Mochi, Fındık hop between 3 spots each (`plate-home.json` `spots`), 2-4 hops of 0.42 s, one mover at a time, at most 2 moves a minute over all three (`PW/Scene/PlateMoves.swift:1-30`);
  not during card, build, bedtime, focus, near (`IslandScene.swift:467-489`); the visitor has one spot. Test: no spot behind a taller occluder at any stage/light/level (`PlateMovesTests.swift:37-59`); 13 tests. Frames: `path-life-d10-1..5`, `path-card-resident-moved`, `life-residents-walk-*`.
  No walk cycle on the plate (`PlateHops.swift:3-5`); the walk exists only on the sprite island (`ResidentLife.swift`). Çağlayan, Koke: no character movement code found beyond lines in their scenes (UNCHECKED).
- Residents on the plate: 2 (Mochi, Fındık), shown once their station level > 0 (`IslandScene.swift:1303-1308`). `residentLines` returns 3 lines only for those two; other `ResidentID`s return `[]` (`PW/Scene/WorldStrings.swift:126-142`); 10 `ResidentID`s declared.
  Visitors shipped with a sprite: Damla, Gezgin (`VisitorSchedule.swift:70`); Koke and Çağlayan have their own residents in their scenes (UNCHECKED beyond baseline).
- Interaction: tap resolver for stations, residents, Pofu, visitor, islands (`WorldHitTest.swift`; 228 lines; tests `WorldHitTestTests`); resident card `PW/Scene/ResidentCard.swift` (70 lines) with "Go to the stall";
  brush the island by dragging (`IslandScene.swift:201-221`). Pofu behind a station: occluder cuts (`plate.occluders`, `IslandScene.swift:1315-1319`).
- Unshipped: only Damla and Gezgin may visit (`VisitorSchedule.swift:70`; `VisitorArtTests` holds `visiting` to baked art; baseline counted 7 of 9 residents without art); pofu-art S3 `batch-84-hidden-visitors` 3 jobs left (Boncuk, Tuli, Nane), Yosun in PR #36.

## 7. What makes it feel alive

- Water: Home pond only, region shader over a polygon (`plate-home.json` `water`: `pond` stages 0-5, `pond-small` stage 6; `PW/Plate/PlateRegionEffects.swift:1-25`). Çağlayan falls: no water polygon (see 5). Stream board water is code (`FlowArt`). Frames `water-day/night-{mid,near,pond}-t0/t1`.
- Sky: painted sky sets with drifting clouds, bobbing isles, gliding whale (`PW/Sky/SkySetView.swift:10`); cloud floor (WP9, #491) merged per `docs/now.md` item 2 (docs/now.md is stale, UNCHECKED in frames).
- Weather: five kinds from a seeded calendar bag; weather never replaces the painting, rain is code streaks (`HomePlate.swift:108-117`); `WeatherLayer.swift` 478 lines; frames `weather-home-*` 8.
- Time: three painted lights by hour (see 2); night and golden fallbacks; bedtime forces night (`HomePlate.light`).
- Sound (#515): ambience (wind, crickets, rain, hush; 4 beds) now defaults ON when never chosen, stored off stays off (`PofuSound/SoundPolicy.swift:5-24`, diff vs a8d07c7e); 48 `.caf` in `PofuSound/Resources` including 6 Pofu cues; cues kettle,
  water-wheel/pour/splash, gulls, door-knock, level-up. Music: none (`git grep -i music` finds only the Settings string and TikTok). Settings footer still says ambience is optional (`App/Settings/SettingsView.swift:141`: UNCHECKED whether that text changed).
- Haptics: unchanged (baseline, one TODO at `WorldHome.swift:144`).
- Heat/frame policy: `PW/Scene/FramePolicy.swift` (408 lines), `FrameMeter.swift`; founder's 120 fps heat complaint is `founder-input.md:777` item (5). Measurement on device: UNCHECKED.
- Code-drawn effects (baseline list, unchanged): build particles, level-up bloom, light swells.

## 8. Menus: Settings, Today, cards, onboarding

- Settings (`App/Settings/SettingsView.swift`, 248 lines): Screen Time section, per-app, Sound, Breath haptics, Station card picker (temporary), Developer/Rehearsal only with `-PofuDeveloper YES` (:75-83). Glass skin default (`PofuSkin.swift:44`).
- Today: `App/Home/TodaySheet.swift` (268 lines), opened from Home chrome (`HomeView.swift:192`). HomeSheet cases now passes/settings/setup/today (`AppModel.swift:1270-1273`); `.earn` removed.
- Cards: station card (section 2), resident card, visit card, celebration card (`PW/Scene/CelebrationCard.swift`, "painted" style, 161 lines), "Ada n" card. Level-up card code-drawn (baseline).
- Onboarding: 8 steps welcome, screenTime, apps, name, setup, notifications, tryIt, caught (`App/Onboarding/OnboardingView.swift:20-28`, 444 lines). Frames in tree: `path-onboarding-{welcome,apps,name,notifications}` only 4.
- Pass pill: `App/Home/PassPill.swift` (81 lines), top-leading beside the gear, tap asks once then ends the pass (`HomeView.swift:42-60`). Frames `15-menu-today-*` (6), `16-menu-settings-*` (5) date from the v3 pass; whether regenerated at 87e4745: UNCHECKED.
- Docs: UI grammar v1 (#490, open, "no app change until the founder has seen it"); menu grounds batch 165 (6: cream, lilac, night, sage, cream-pattern, linen-tile) delivered, not in the app (only older `ui-card-linen(-night).png`).
  Founder: "menus generally not good", wants small glass objects tried in the app (`founder-input.md:799`).
- Screen Time gate/shield: not in this brief; no on-device result exists in the repo (baseline).

## 9. Islands planned and approved, with art ready

- Approved base: the Book One story map (the founder: "elimdeki en iyi dokümantasyon ... birebir uymak zorunda değiliz", `book-one.md:3-8`); main islands Çağlayan, Revontuli, Emanet, Mehtap (`decisions.md:45`, S2);
  order Ayçiçeği, Gezgin early, Koke, Çağlayan, Çanlar, Martı Kayası, Revontuli, Olta, Fanus, Pervane, Emanet, Çömlek, Arı, Mehtap finale (`decisions.md:44`); fillers Koke, Çanlar, Martı Kayası, Fanus, Pervane, Çömlek, seasonal Leylek (S5); Yıldız, Kaplıca, Kitap dropped (S4).
  I found no document that lists "the already approved islands" the 11-26 message names (`founder-input.md:805`): UNCHECKED which he means. `content/islands/*.yaml` status: aycicegi in-app, iskele planned, 3 cut (ayna, kaplica, kitap) plus yildiz cut, rest `idea`.
- In the app: Home (10 levels), harbor stations, Koke, Çağlayan. Çağlayan's design may change (`founder-input.md:805`).
- Art ready, by island (pofu-art takes, QA auto-picks, none promoted; plates.yaml cells painted / in app): Çağlayan 16/12; Revontuli 15/0; Emanet 14/0; Mehtap 15/0 (stages 0-4, bare/life/up variants, day/night/golden/rain per cell).
  Board kits for Koke, Emanet, Revontuli, Mehtap: batch 163 (12 jobs: plain tile, socket, straight dial each) + 166-169 (8 each: bend/tee dials, goal, spring, gate, wheel, rock, flowers): delivered 11-25/26, merged #164-#167, not ingested in pofu.
  Characters: only Mochi, Fındık, Simit, goat, Damla, Gezgin, Lut, Nazlı sprites and Koke's in the bundle; Tuli (Revontuli), Boncuk (Emanet), Nane (Mehtap) not delivered (S3).
  Island sheets/designs: `docs/design/book-one-islands.md`; Revontuli `content/islands/island-revontuli.yaml` (status idea). `batch-38-island-arcs` (Koke, Çağlayan, Emanet, Revontuli stages 0,2,4 in game camera) BLOCKED, manifest not in pofu-art.

## 10. Mini-games and the effort spent

Code now: Flow board (8 boards, all Çağlayan: `PofuGames/Resources/flow-boards.json`; docs promise 16 (Çağlayan 8, Revontuli 4, Mehtap 4, `docs/design/flow-game.md:65`)), Garden tile game, Hop breath room. No third arcade game.
Since 11-10 in pofu (`git log --since=2026-11-10`): 155 first-parent merges; 501 non-merge commits; 28 non-merge commits touch `PofuGames`/game views (from the log: flow painted scene, rocks, kit v2, dial board, ring). Flow-related code PRs: #457, #467, #476, #483, #486, #489, #501 (overhaul),
  #506, #514, #518. The newest two (#514, #518, 2026-11-25) rebuilt the board as raised blocks and dials, replacing the kit v2 PNGs (49 files, +318/-1179 in PofuGames since a8d07c7e). Garden: no dedicated PR since #501 (11-16).
  Open: #507 (flow board tabletop + station sheet from scratch, docs, not merged, +813).
Art in pofu-art, board/game batches since batch 66 (job folders under `design/art/takes`): 114 (4), 121 (7), 130 (4), 131 (2), 132 (1), 135 (5), 138 (10), 144 (8), 146 (14), 155 (6), 157 (3), 158 (12), 161 (4), 163 (12), 166-169 (32) = 124 jobs
  of 514 job folders in batches 66-170 (my regex-free sum; takes folders, not manifests). 132 is 1 job; 136 (flow lawn v3) BLOCKED. Shipped from these: the dial/block/bed kit (`PofuGames/Resources/flow-{block,dial,bed}-*.png`, `flow-backdrop.png`, `tools/art/ingest_flow_board_kit.py`).
Planning docs: `docs/design/minigames-overhaul-v1.md` (11-16), `game-solid-v1.md`, #507. Founder 11-26: "mini game gibi ufak tefek şeylere takıldık" (`founder-input.md:805`).

## 11. pofu-art state

`QUEUE.md`: Demand D29-D33 (batches 166-170) were READY at fetch; D33 = batch 170 redo of the workshop ornament (1 job; takes folder exists, 2 images). Merges of #164-#167, #169 are on main 2026-11-26 22:06 UTC; #168 earlier (redo-170).
Batches 154-170 on main: 17 batches, 144 job folders (sum of listing: 8,6,1,3,12,8,7,4,8,12,12,6,8,8,8,8,1). Standing S2 clouds v3 (PR #132 open), S3 hidden visitors. Open pofu-art PRs: 59 (oldest #6, 11-12). Codex idle about 16 h since batch 170 per `founder-input.md:805` (founder message 11-26);
  a mainflow queue brief exists: `docs/studio/briefs/codex-2026-11-26-mainflow-queue.md`. Manifest count on main and QUEUE-LOG currency: UNCHECKED beyond the above.

Friction: pofu `git grep -A` is not accepted after a revision argument; used `git show` + sed instead. GitHub GraphQL blocked, REST worked.
