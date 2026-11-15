# App state at origin/main 83e2e394 (2026-11-15), raw facts

Read-only scout. Base: `git show origin/main:<path>` (main tip 83e2e394, #478).
Abbrev: PW=Packages/PofuKit/Sources/PofuWorld, PG=.../PofuGames, PD=.../PofuDesignSystem, PS=.../PofuSound.
"UNVERIFIED" = not confirmed in code or by a frame; nothing was run or rendered.

## 0. Things that differ from the brief or between docs
- Founder-input items 32 and 33 are NOT on main. main's log ends at item 31
  (docs/product/founder-input.md:782). 32 and 33 exist only on branch
  origin/claude/exciting-cori-1t8br2 (not merged). WP6's PR body (#479) cites "founder input 34";
  not checked (branch has only 32, 33).
- docs/now.md (Updated 2026-11-15) desk row "Game: days 17-21 flat; IL8 pacing in flight" (now.md:52) is STALE:
  bell road merged (#437 spec, #438, #440, #441, #444, #450; PS FarBellPrelude.swift exists in PofuCore/Game);
  IL8 step closed, "tester stays 2 levels short, no change" (commit ff7593b9, 11-13).
- docs/tracker.md is stale ("corrected 2026-11-07", tracker.md:3); now.md:62 says so too. docs/roadmap.md stale per now.md.
- docs/research/route-2026-11-13-day.md (11-13) is partly stale: its "island grows six times and never says so"
  was answered by #433 "the island grows in view" (6834bbf9) merged after.
- docs/design/asset-system-v1.md decision 10 "Glass is not a Pofu material" (asset-system-v1.md:79, :337) is
  overridden by founder items 24 and 26 ("the UI continues in the glass skin").
- PofuSkinViews.swift:7-24 comment says crafted faces are vector stand-ins and `PofuCraftedAsset.isPainted` returns false,
  but painted faces ship via `PofuKitArt.*.isPainted` (PofuSkinViews.swift:223-228); two switches coexist.
- feel-and-world-v1 says "two cues never play" and "Flow is a wireframe"; both changed since (hop/gulp wired,
  App/WorldSound.swift:118-119; flow stone tiles #476, grass/rock/pool #467).

## 1. UI grammar and the glass skin
- UI-grammar brief: docs/studio/briefs/fable-2026-11-14-ui-grammar.md, approved (founder-input 25), NOT run.
  Its output file docs/design/ui-grammar-v1.md is absent on main and on any branch (`git ls-tree`, `git branch -r | grep grammar`: none).
  now.md:37 "Paused: ... UI grammar after #461's choices". The brief names docs/design/ui-v3.md (exists), ADR-0022, ADR-0025.
- Skin switch: `PofuSkin` {glass, crafted}; default glass (PD/PofuSkin.swift, `defaultSkin: .glass`).
  Reduce Transparency forces crafted (PofuSkin.swift `skin`). Dev override `-PofuSkin crafted` (App/Home/HomeView.swift:24-25).
- Roles the switch touches: primaryAction, secondaryAction, iconButton, worldTag, glance (PofuSkin.swift). In glass
  only iconButton/worldTag/glance get `glassEffect` (PD/PofuSkinViews.swift:230-250); actions are styled elsewhere.
- Painted faces (clay disc, linen, bubble, tail, ribbon, plaque) draw only in the crafted skin:
  `pofuPaintedChrome` (PD/PofuSkinEnvironment.swift:25, comment "Only the crafted skin paints them; the glass skin
  draws what it drew before asset wave 0"). So with default glass the Wave 0 painted chrome is not what the player sees.
- Glass uses on main (grep): App/Home/HomeView.swift:230 (glance), PW/Home/WorldHome.swift:560, PW/Scene/PlaceControl.swift:85,
  PW/Scene/StationSheet.swift:401 (resident card), PD/PofuSheet.swift:102-104 (sheet glass below 0.8 height, paper above;
  PofuSheetSurfaceRule paperFraction 0.8, glass only when world frozen), PG/UI/GardenGameView.swift:259-284 (pause panel
  `.glassProminent`/`.glass`), App/Home/GardenPlayView.swift (debug "Ayar" chip, DEBUG only), RehearsalPanel, TuningLabPanel.
- `GlassEffectContainer` / `glassEffectID`: not found anywhere in App or Packages (grep empty) = no glass morphing.
- Hold-for-bar: `PlaceControl` is a SwiftUI `Menu` with a primaryAction (PW/Scene/PlaceControl.swift:29-70): list Pofu, each
  island, Archipelago. Order is not stated as "player's own islands" in code (`islands` input; not read further).
- ADR-0018 (2026-11-01): Glass++, "glass is always native, no painted button frames/bars/sheets", SF Symbols for system
  actions, painted icons >=28 pt beside a live label (docs/adr/0018-visual-system-v1.md). Three framings Home/island/Map.
- ADR-0020 (2026-11-06, Accepted, amends 0018): painted surfaces allowed (9-slice, one material family), behaviour native
  (44 pt, Dynamic Type, VoiceOver, Reduce Motion, contrast), all states, live text only (docs/adr/0020-...md:19-37).
- ADR-0022/0023/0024/0025 concern plates/colour/HEIC/sky sets, not UI skin. ADR-0027 (one camera, free near) does not exist yet
  (WP7 to write it, spec §5 end).
- Asset Wave 0: slice 1 Home chrome #446 merged; slice 2 (station sheet, resident card, celebration card) = #453 DRAFT,
  paused for the glass/painted decision (now.md:36-37; founder-input 24). #453: 49 files, updated 11-14.
- Ranked "what to replace" table, status at 11-14 (asset-system-v1.md:174-186): Home chrome, round buttons (#446), station sheet
  (#453 draft), app identity glyphs (needs duo sheets 3/4, queued pofu-art #65), Flow board (partly done), the Door/Hop
  screen (App desk paused: "not in app"), resident card, Settings rows, Map pills, empty states (nine vignettes never produced),
  celebration card.
- Onboarding: "four cream screens, none in the painted world" (route-2026-11-13-day.md:26-ish). App/Onboarding/OnboardingView.swift
  uses none of the kit painted types (grep PaperSurface/Kit* 0 hits).
- Kit (painted components): PD/Kit/{KitPaper,KitPlaque,KitSheet,KitMaterial,KitComponents,KitArt,BreathRing}.swift;
  used in App/Hop/BreathRoom.swift(5), HopView.swift(4), TodaySheet.swift(1) per grep counts.

## 2. Minigames (PofuGames: two games only, Garden and Flow)
Garden (sunflower garden, Home's skip-pot "Play" door): PG/UI/GardenGameView.swift (412 lines), GardenScene.swift (1158).
- Flow of screens: scene full screen -> HUD (round plate "Tur n / 5" + pips + bag bar; seed plate "+N"; pause button)
  (GardenGameView.swift:82-112,190-255) -> .playing; .paused -> glass PausePanel (:259-284); .roundEnd -> RoundCard (kicker,
  title, seeds, rows bloomed, "next round", "enough for today") (:117-137); .setEnd -> RoundCard with stamps (:141-160).
  No start/intro card: the round starts when the view appears (no `.intro` phase in the `switch model.phase`).
- Set = `GardenSet.roundsPerSet = 5` (PG/Core/GardenSet.swift:9). Reward: each round credited `model.creditRound(seeds:)`
  (App/Home/GardenPlayView.swift:onRoundEnd); finish returns to Home (`isPlayingGarden=false`).
- Painted: tiles (6 colours), tray, soil, bed rim, blooms (front/left/right/small), Pofu/Mochi/Findik, combo stamp (PG/Resources/garden-*.png).
  Plain/code: sky is a code gradient (GardenArt skyTop/skyBottom, GardenArt.swift:16-17), HUD plates are code `PaperSurface`
  paper + stitch, `ClayButtonStyle`, `SeedGlyph` Canvas (PG/UI/GardenCrafted.swift:10-98), SF "pause.fill". Pause is native glass.
- Frame rate: SKView 60, or 30 at thermal serious/critical (GardenGameView.swift:177).
Flow (Çağlayan's water-channel puzzle): PG/Flow/UI/FlowGameView.swift (314), FlowScene.swift (650).
- Screens: board (tap tiles), HUD (X leave, board "n of N" pips, target drops "x/y"), bottom round buttons undo + hint,
  caption layer ("board done"), finished state "doneTitle" + ClayButton "Done" (FlowGameView.swift:hud, controls, captionLayer).
  No pause, no seeds/reward display. Reward = advance the island one stage (`AppModel.finishCaglayanFlow`,
  App/Home/CaglayanFlowView.swift:5-8 comment); leaving keeps the round (`savedFlowRound`); after healing it is free play, pays nothing.
- Boards: 8 hand boards, stages 1-4 x 2 (PG/Resources/flow-boards.json; stages 1..4 via FlowLibrary.round).
- Painted: stone tiles (flow-stone, flow-stone-2, #476 merged), grass, rock, pool (#467). Code-drawn: channels, banks, wheel? (a
  `flow-tile-wheel` name is reserved, FlowArt.swift:59-62), palette sky gradient (FlowArt skyTop/Mid/Bottom), HUD same paper plates.
- Frame rate: SKView fixed 30 (FlowGameView.swift:303). `FrameState.minigame` in policy = 60 (FramePolicy minigameRate 60).
- Both games: sound via GameSoundPlaying/FlowSoundPlaying bridges (PS/GardenSoundBridge.swift; App/Home/CaglayanFlowView passes
  `FlowSoundBridge()`); haptics GardenHaptics/FlowHaptics. Founder: "fit the theme but feel empty; all their UI needs a pass;
  flow needs fully custom assets" (item 26.3). feel-and-world-v1.md §1 row 3: "flat gradient where the world should be, no ambient life".
- Other interactive surfaces besides games: the Hop breath room (App/Hop/BreathRoom.swift, BreathScene), Gate scene (GateScene.swift;
  both use TimelineView at 1/30 s, see §4).

## 3. Upgrades and progression
- Station level is data: StationLedger/Archipelago (PofuCore/Game); build errors incl. `capped` until an island level lifts it
  (StationLedger.swift:284, Archipelago.swift:289 islandLevel(allowingStationLevel:)).
- What the player sees on the plate: the picture is chosen by ISLAND level, not station level. `PlateIsland.Object.stages` says which
  stages paint an object (PW/Plate/PlateIsland.swift:62-64 `isPresent`); a station's own level changes nothing on the plate
  (spec §3 row "Station levels"; feel-and-world-v1.md §0 finding 1: about five distinct tea-stall paintings across the 10 day plates;
  island level rises about one build in four).
- `PlateIsland.diffArt` and `upgradeArt` exist as name builders (PlateIsland.swift:198-207) and are used only by PlateTests.swift:126-128
  (git grep): no runtime consumer. => per-station look layers: not implemented.
- Island growth: the island grows in view (#433, 6834bbf9; IslandGrowMoment.swift in PW/Moments). Tester IL2 d2, IL3 d3, IL4 d4, IL5 d7,
  IL6 d11, IL7 d16, ends d21 at "Ada 8 için: 2 seviye daha" (route-2026-11-13-day.md; IL8 decision ff7593b9). Re-run since: UNVERIFIED.
- Build moment: sparkles + bloom, BuildMoment.swift / BuildEffects.swift; "at 1:1 the bloom reads as fog blobs" over an unchanged picture
  (feel-and-world-v1.md §1 row 1b, frame path-d04-build-burst). Sheet motion is system sheet.
- Station sheet UI: PW/Scene/StationSheet.swift (level "n of max", seeds/day, cost, "Build · N", cap reason, Play · rounds left).
  Wave 0 painting of this sheet = #453 draft (not merged).
- Planned fix (not merged): WP8 "looks, bases and mask data" (needs WP4 + pofu-art batch 117 picks), WP10 compositor (D7: looks at 2x plate
  texture, budget 14,000,000 B, `tools/plate/ingest.py` BUDGET); spec gap G5 "Building does not show". Neither started
  (no WP8/WP10 PR open: `gh api pulls` open list = #480, #479, #461, #453, #442, #317, #135, #108).
- Jar/pots/lantern: "gone from the painted Home" per spec G1 (props gated `plate == nil`, PW/Scene/IslandScene.swift:849, :947).
  `SkipPotsView` is drawn from PW/Home/WorldHome.swift:339 and got a painted sunflower in #467 (7a126ce7). Whether pots/jar/lantern
  appear on the plate at runtime: UNVERIFIED (no frame viewed). WP5 "props come back" not started.

## 4. Motion and feel
- Frame policy: `PofuFrameRate` drift 15, idle 20, event 30, direct 60, touch 120 (PD/PofuTimeline.swift:11-24).
  `PofuFrameRule.isPaused`: ambient stops under Reduce Motion and Low Power; essential does not (:33-41).
  `PofuTimeline` wraps `TimelineView(.animation(minimumInterval:))` (:86). 18 `PofuTimeline(` call sites on main (git grep count).
  Test `PofuFrameRuleTests` scans for bare `TimelineView(.animation` (PofuTimeline.swift:9; Tests/PofuDesignSystemTests/PofuFrameRuleTests.swift).
- Bare timelines still on main (git grep): App/Hop/BreathScene.swift:46 (1/30), App/Hop/GateScene.swift:111 (1/30, paused on reduceMotion/inactive),
  App/Rehearsal/TuningLab/TuningLabPanel.swift:472 (1/30). All have minimumInterval, none unbounded.
- FramePolicy (PW/Scene/FramePolicy.swift): states direct, moment, ambient, settled, covered, minigame, background; defaults
  direct 60, touch 120, moment 60, ambient 30, minigame 60 (:27-37); ambient visit window 8 s (:138); ambient -> settled in Low Power (:178-180);
  thermal fair caps to 60, serious 30 (:72-76). Scene reads it at IslandScene.swift:91 (`PofuTimeline(hz: policy.hz ...underFinger`).
- #460 (0cf03ca1, fix/heat-still-redraws) merged: every timeline through one rule. #464 (803241b3, direct-tier-120) merged:
  120 Hz under the finger; Config/Info.plist:31 has `CADisableMinimumFrameDurationOnPhone`. FrameMeter.swift:55 asks 60-120.
  No on-device measurement exists (feel-and-world-v1 §2.4 point 3; spec §0.7). Phone-heat result after #460/#464: UNVERIFIED.
- Games bypass PofuTimeline: Garden SKView 60/30, Flow SKView 30 (see §2).
- Sky motion: one `Canvas` through PofuTimeline at `drift` 15 Hz (spec §0.7; PW/Sky/SkySet.swift:181). Doc comment SkySetView.swift:15 says 30 Hz = wrong.
- Camera: three stops Map / Island (0.9 widths, no chrome) / Home (1.15 widths, 1.40 pt/unit, chrome) (spec §3; PW/Plate/HomePlate.swift:420-424,
  PW/Layout/IslandFraming.swift:42). Pinch past Home band x1.25 (CameraRail.swift:123-124); top zoom 1.75 pt/unit; zoom about the anchor not fingers
  (CameraRig.swift:331). No held near, no vertical pan. Depth blur off on any painted plate (IslandScene.swift:532,665).
  ADR-0019: "no free camera and no placement" still stands until ADR-0027 (WP7).
- Far/mid/near transitions: island art cross-fades between half-size `mapisle` cut and plate over z 0.55-0.95 (PlateHomeViews.swift:54-58;
  IslandScene.swift:567-569); the Map sky has its own camera, parallax 0.06 (PaintedSky.swift:163,362-372; IslandScene.swift:703-712).
  Founder: "near and far blend instead of moving as one camera" (item 26.2).
- WP2 merged (#478, b07a57f5): `DepthLayer.pose` one-camera depth function in PW/Camera/WorldDepth.swift, consumed by SkySetView.swift:103,116.
  Backdrop below level 10 still a static JPG (PlateHomeViews.swift:101-106 per spec). Five different sky rules before WP2 (feel doc §1 row 2c);
  how many remain after #478: UNVERIFIED.
- WP3 merged (#477): ScreenBands.swift, WorldMap.swift, CompositionRules.swift, world-map.json. No consumer in Sources outside tests
  (git grep of WorldMap/ScreenBands/CompositionRules: only their own files) until WP6 (#479).
- Hops: #462 (4eb56ffa) idle resident hops on the painted Home plus hop/gulp sounds, merged. Walks parked. Six systems dropped on the plate path
  (station art per level, resident life, critters, cloud shadows, code water, build art swap; feel doc §0) - state after #462: only hops restored.
- Water: baked into plates, still (spec G8); region shader = WP13, not started. Çağlayan sets have no `fall` detail (feel doc §1 quick wins).
- feel-and-world-v1.md (branch design/feel-and-world, PR #461 DRAFT "do not merge"): plan = one technique per kind of motion (§2.3), four power
  tiers Still/Ambient/Moment/Direct (§2.4), proofs 1-4 (made, outputs in scratchpad; #463/#465/#466 Python tools CI failing per now.md:29).
  Heat target "<=15 % above a still photo" is a proposal, not measured.

## 5. Sound and music
- Engine: PS/SoundEngine.swift (plays pre-rendered .caf, `.ambient` category mixes under the user's music), SoundPolicy (min gaps),
  AmbienceConductor (beds + gulls).
- Cues (20, PS/SoundCue.swift): seedPop, bloom(step), comboRise, piecePickup/Snap/Drop/PutBack, deal, cheek, roundEnd, collect, skipChime,
  pofuHop, gulp, levelUp, doorKnock, kettle, waterWheel, waterSplash, waterPour. Files in PS/Resources: 11 bloom notes, 5 seed pops, 3 combo-rise,
  4 ambience beds (wind, crickets, rain, hush), 2 gulls, breath-pad.
- Call sites (App/WorldSound.swift:78,110-119): kettle (morning, tea stall built), doorKnock (visitor), levelUp (island grew), pofuHop, gulp;
  `collect` at App/Home/HomeView.swift:182,362; flow cues via FlowSoundMap (PS/WorldMoments.swift); breath chime via BreathPhaseCue.
- Music: none ships. `git grep -i music` hits only Settings copy ("Tiny sounds... ambience") and unrelated strings. design/sound/proof/ holds 4
  island .m4a proofs + pofu voice .wav proofs, not in the bundle. sound-identity.md plans "Ada müziği" off by default (line ~96).
  Founder item 28(d): Zelda/Genshin inspiration, "do not start it"; mood and source to be discussed later. Status: not started.
- Weather ambience: AmbienceWeather {clear, overcast, lightRain, mist, goldenHaze} -> bed mix (Ambience.swift:7-68).
- Games: Garden has full cue set; Flow borrows the garden's snap/thunk + bloom ladder for the trickle (WorldMoments.swift FlowSoundMap).
- Founder wants "more music, sound effects and motion" (item 26.6): sound additions since: hop and gulp only (#462).

## 6. World presentation spec (docs/design/world-presentation-build-spec.md, base b424f1bd, 812 lines)
- 13 PRs, order 1,2,3,4,5,6,7,8,9,10,12,11,13 (spec §8). Status by live check (`gh api pulls`, `git log origin/main`):
  WP1 #475 merged (tools/proof: 22 files on main). WP2 #478 merged. WP3 #477 merged.
  WP4 #480 `feat/plate-mattes` OPEN, ready, mergeable_state unstable, 155 files, created 11-15 21:55.
  WP6 #479 `feat/map-journey` OPEN, ready, unstable, 16 files; body: Koke/Çağlayan to tier-1 slots, cloud towers (batch 115 pick 1),
  far isles, bob 2 pt; "frames posted once CI renders them". 1528 tests pass locally per body.
  WP5, WP7, WP8, WP9, WP10, WP11, WP12, WP13: no branch/PR seen on origin (branch list has feat/island-grows, feat/pace-il8 only for similar names).
- §0 false premises: tools/proof absent on main at base (now landed by WP1); match-proof outputs only in scratch (now committed at
  docs/design/assets/world-concepts/: target-/match-{map,mid,near}.jpg, edges-r3b-4x.jpg, layout-wireframes.jpg: present on main);
  r3b mattes checked on 4 of 21 Home states; matte as own texture busts 9 MB budget (Home uses 8,028,622 B), so matte = plate alpha (D1);
  backdrop holds a copy of the island (halo; WP4 inpaints); lower levels share the level-10 matte (ghosts); life cost unmeasured; ADR-0019 conflicts with near.
- §11 corrections list: 11 items (e.g. SkySetView.swift:15 says 30 Hz but runs 15; KokeLayout.swift:74-78 comment false after WP6;
  pofu-art QUEUE.md rows 0-b4..0-b8 read READY after delivery).
- §12 could not verify: batch 111/115/117 `pick:` values are the lead's; r3b on 17 untested Home states; real chrome boxes on device;
  ImageRenderer of the full composite on phone; render-server motion cost.
- Gaps G1-G9 (spec §4): props gone (WP5), cropped top-heavy everyday screen (WP7), Map two pictures stacked (WP6), edges (WP4),
  building does not show (WP8/WP10), sky weightless (WP2 done partly/WP9), no close look (WP7/WP11), water still (WP13), unlocks off-screen (WP12).
- Player-path frames: 21 days, Map frames days 1,3,6,7,11,13 (spec §3; Tests/WorldScreenshots/PlayerPathScreenshotTests.swift:40-65; branch screenshots/main).

## 7. Founder's open feedback (items 26, 28, 32, 33) vs merged PRs
Item 26 (11-14, first phone session; he may not have had newest build):
1. Upgrades do not show (station name levels, object does not): OPEN (WP8/WP10). Upgrade screen/effects/sheet animation weak: OPEN.
   Code-drawn sunflower bad: ANSWERED for skip pots (#467 painted sunflower); other code blooms (HomeObjectViews `Bloom`): UNVERIFIED.
2. Camera three distances (far/mid/near), free zoom/pan to Pofu: OPEN (WP7, WP11). Backdrop/clouds drift across islands: PARTLY (#478 one depth function
   for sky; static JPG below IL10 and per-island sets: UNVERIFIED after #478). Small clouds vanish zooming out: OPEN (WP9 / art fix).
3. Minigames empty, UI pass, flow fully custom assets: PARTLY (flow stone #476, grass/rock/pool #467; no UI pass, no start card, no ambient life).
4. Glass: hold control for a bar to jump anywhere, ordered to his islands: OPEN (PlaceControl is a Menu; no GlassEffectContainer). "Small build, judged on device".
5. Constant 120 fps / heat: ANSWERED in code (#460 rule, #464 120 Hz under finger only); not measured on a device.
6. More music/sfx/motion/effects (bloom, camera): PARTLY (hop+gulp sounds, hops #462); music, sky/cloud/light motion: OPEN (WP9).
7. Water motion technique, residents hop, where did the motion systems go: hops ANSWERED (#462); water OPEN (WP13; proof 4 picked region shader);
   Çağlayan `fall` detail not added (UNVERIFIED).
Item 28 (11-14 evening): (a) stations wear own level: OPEN (WP8/WP10; proof 1 shows technique). (b) he chooses near look and mid fit from proof 2:
   picks committed under docs/design/assets/world-concepts/ (near-locked t2 per spec header); build OPEN (WP7/WP11). (c) 120 Hz under finger only: DONE #464.
   (d) music Zelda/Genshin: NOT STARTED by instruction. (e) Codex check: done (founder-input 29: 32 PRs awaiting review then; #64, #65, #67 merged).
Item 32 (11-15, on proofs; branch-only text): (1) everything too high, empty lower third, per-unlock balanced layout: WP3 data merged, WP6 #479 OPEN.
   (2) more life in clouds/backdrop: OPEN (WP9). (3) clean edges, level-up station cut-outs without ghosts: WP4 #480 OPEN; cut-outs = WP8/WP10 OPEN.
   (4) real-camera depth of field, tuned per shot: OPEN (WP11; D10 four blur levels). (5) water c, single camera b accepted: camera b = #478 merged; water WP13 OPEN.
Item 33 (11-15): far/mid/near as choreography incl. transitions, each screen one image; Codex concept frames as targets; he picks:
   concept targets and matches committed (see §6); transition storyboard: no file found on main (UNVERIFIED); integration = WP6/WP7/WP10.

## 8. Rehearsal days 1-21
- Path: PofuCore/Rehearsal/PlayerPath.swift (`horizon = 21`, `tester()`: one resisted reach a day, collect, cheapest builds, banked garden rounds,
  "Next day"; 09:00 / 09:07 / 23:00 snapshots; day 1 = 2 Nov 2026). DemoRunTests guards it. Founder trial planned Mon 2026-11-16 evening (days-17-21-v1.md:3).
- Days 17-21: bell road MERGED, content per docs/design/days-17-21-v1.md table: d17 humming "Mırıldan" four notes; d18 "Dinle" answer;
  d19 two notes back; d20 all four, third wrong; d21 bell plays right + "Ben de duydum". Extras merged: bell in the sky (#440), cold-launch cue (#441),
  bell seen (#444), warm gold ring (#450 + bde1f584). now.md:35 still lists "bell polish: pale side strips at the whole-island pose are backdrop art".
  "Flat" claim in now.md:52 is stale; whether days 17-21 still feel flat to the founder: UNVERIFIED (no phone session on them; founder last played 11-05 per now.md:11,
  though item 26 describes a later session on 11-14).
- Level cadence (route-2026-11-13-day.md): IL2 d2, IL3 d3, IL4 d4, IL5 d7, IL6 d11, IL7 d16; no island level change d17-21 for the tester; from day 8
  one station level a day, d17-21 "nothing new but Çağlayan free play" (route-2026-11-12-codex-pause.md:78) - pre-bell-road text. IL8: tester 2 levels short on d21;
  two "Boş ver" a day reach IL8 on d21, three on d20 (ff7593b9).
- Arrivals: Koke heals d10, Çağlayan d16 (route-2026-11-12), Map changes frames days 1,3,6,7,11,13.
- Known flat/unfinished (from docs, not re-rendered): same morning line "Yanaklarım kocaman oldu!" on days 2-21 (route-2026-11-13-day.md:36-40; milestone round
  e25ad9c7 "cheek line rarer" merged since, effect UNVERIFIED); Today sheet "one card, one line, a small Pofu, then an empty page"; onboarding in old cream look;
  Door (Hop) screen is postcard + capsules; empty-state vignettes (nine, batch 63) never produced; day-17-21 spec PR 2 (warm star light) status: #440/#444 merged = likely done.
- now.md open items: device-check answers (five pending, now.md:62-ish), Wave 0 slice 3 flow board then duo sheet/stickers (§4.2), side-by-side glass vs painted pass, bell polish, route §5.3
  (seeds-and-minutes check; App desk "reopens"). App desk "paused until after the demo" (now.md:51).
- Open PRs not about the above: #442 route doc (superseded by #461 per now.md:12), #317, #135, #108 (old).
