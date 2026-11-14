# Feel and motion facts, 2026-11-14

Facts only, read from `origin/main` at 7f4e99c0. Paths are under `Packages/PofuKit/Sources/` (`W` = `PofuWorld`, `G` = `PofuGames`) or `App/`.
Sizes are bytes. Nothing here was measured on a device.

## 1. Frame rate and heat

- `CADisableMinimumFrameDurationOnPhone` is `true` in `Config/Info.plist:29-30` (main app only; the three extension plists lack it). The key is in the main target's plist, so the app may run at 120 Hz.
- `FramePolicy` (`W/Scene/FramePolicy.swift`) maps a demand to a state and a rate: direct 60, moment 60, ambient 30, minigame 60, settled/covered/background 0 (`:123-135`, `:152-189`). Ambient becomes settled under Low Power, thermal serious, or Reduce Motion (`:168-175`). `directRate` is 60 "for the beta" (`:122`); nothing in the policy asks for more than 60.
- Applied in exactly one place: the island `TimelineView` (`W/Scene/IslandScene.swift:91`: `minimumInterval: policy.timelineInterval, paused: !model.needsFrames && !moment`). It also gates critters/residents (`:480`, `:667`) and the sky layers through `worldAmbientPaused` (`:658`: `look.hd2d && !model.needsFrames && build == nil`).
- `needsFrames` (`W/Scene/IslandSceneModel.swift:159-167`) is true while springs move or a visit window (8 s, `FramePolicy.visitSeconds`) is open. `isDeviceTiltEnabled` defaults false (`IslandSceneModel.swift:115`); no assignment to true found.
- Not under the policy (run while the screen is still; each pauses only on its own flags):
  - `W/Sky/SkySetView.swift:43`: the painted sky set (clouds, isles, whale, stars, falls, sways), a 30 Hz `Canvas`; paused only when `scenePhase != .active` (static under still/Reduce Motion/Low Power, `:34-38`). Used for Home's plate (`W/Plate/PlateHomeViews.swift:103`) and the painted skies (`W/Plate/PaintedSky.swift:496`). It ignores `ambientPaused` and `needsFrames`.
  - `PofuCompanion/CompanionView.swift:60`: Pofu, `TimelineView(.animation(minimumInterval: 1/30))`, no `paused:`, so it redraws 30 Hz whenever on screen (Home, `IslandScene.swift:2060`, Earn, Hop, onboarding).
  - `W/Plate/FarBellSky.swift:80`: night glow pulse, `.animation(paused: reduceMotion || still)`, no interval, so display rate; only when `plate.light == "night"` and a glow exists. `:88`: bell rings, display rate, only while a stage age exists.
  - `W/Scene/ResistSeals.swift:120`, `W/Home/HomeObjectViews.swift:493`: display rate, paused when the animation is over.
  - `PofuDesignSystem/PofuResistPayoff.swift:182`: `paused: false`, display rate, while the payoff view is up.
  - `App/Launch/LaunchCurtain.swift:37`: 30 Hz while loading, `nil` (display rate) afterwards.
- Gated by `ambientPaused`/`still`/Reduce Motion/Low Power, 30 Hz (20 for clouds): `W/Scene/LivingSky.swift:51` (stars, cloud layers, used when no painted sky) and `:240` (1/20); `W/Scene/WeatherLayer.swift:204`, `:367`; `W/Scene/FogCards.swift:86`. `W/Scene/IslandScene.swift:1833` (`FocusLife`, 30 Hz, only while a station is focused).
- Collect-only (paused unless a collect runs): `W/Home/WorldHome.swift:706`, `:733`; `W/Home/HomeObjectViews.swift:210`; all `minimumInterval: nil`.
- Clock timers, not redraw loops: `TimelineView(.periodic/.everyMinute)` at `App/Home/HomeView.swift:448`, `App/Home/PassesSheet.swift:76`, `App/Earn/EarnSheet.swift:138`.
- `CADisplayLink`: one, `W/Scene/FrameMeter.swift:54`, `preferredFrameRateRange` min 60 / max 120 / preferred 120. It is the debug meter; `look.frameMeter` defaults false (`W/Look/WorldLook.swift:105`) and `RehearsalFrameMeter.swift:12-18` needs Rehearsal mode and a developer flag.
- SpriteKit: `G/UI/GardenGameView.swift:177` (60, or 30 at thermal serious/critical); `G/Flow/UI/FlowGameView.swift:303` (30). Both pause the `SKView` when settled/backgrounded (`GardenGameModel.swift:93-102`, `FlowGameModel.swift:99`). No SceneKit, no `CAEmitterLayer`, no Metal view found. `.animation(.repeatForever)`: only `App/Hop/HopView.swift:307` (idle, 2 s). SKAction `repeatForever`: `G/Scene/GardenScene.swift:392`, `:1006`; `G/Flow/Scene/FlowScene.swift:349` (wheel, while wet).
- Ranking of likely always-on redraws on a still Home (my reading of the code; unmeasured):
  1. `SkySetLayers` 30 Hz `Canvas`, always while active (not under `FramePolicy`).
  2. `CompanionView` 30 Hz, always while visible (not under `FramePolicy`).
  3. Night only: `FarBellSky` pulse at display rate.
  4. The island timeline: only during a visit window or motion; then 30/60 Hz.
  5. LivingSky/Weather/Fog layers: paused when settled in hd2d (`WorldLook.hd2d` default true, `:101`).
- Nothing in the code requests 120 outside the debug meter. The display-rate timelines in the list above are the ones that can run at 120 Hz with the plist key on.

## 2. Motion now

- Sky/clouds: painted layers moved in code. Home and Çağlayan: sky set (`W/Sky/SkySet.swift` `SkyMotion`): far/mid/sea clouds drift as wrapping tiles, isles bob, the whale glides, stars twinkle, all pure sine/linear functions drawn in one `Canvas` (`SkySetView.swift`). Constants come from `W/Resources/Plates/skyset-home.json` and `skyset-caglayan.json`. Sprite-island look: `LivingSky.swift` (gradient from `SkyModel` palette by minute, `StarField`, cloud tiles as images, `period 640`, `speed 3` `:215-216`).
- Light: `WorldShaders` grade (`W/Scene/WorldLookLayers.swift:143`, `.colorEffect`), night relight (`GraphicsSpikeLayers.swift:87`, `.colorEffect`), depth blur (`GraphicsSpikeLayers.swift:108-112`, `.layerEffect`), sun shafts/bloom/particles flags in `W/Look/WorldLight.swift:45`, `CloudShadows` (`W/Moments/CloudShadows.swift`), lantern flicker (ambient only), `FarBellSky` night pulse.
- Weather: rain tile and haze, code `Canvas` (`W/Scene/WeatherLayer.swift`); mist/fog cards (`FogCards.swift`).
- Pofu: `CompanionView` redraws a rigged art stack each frame with `.distortionEffect` (`CompanionView.swift:172`, `CompanionShaders.metal` `pofuCompanionDeform`), blinks, breath, hop offset (`:181`). Code animation plus shader.
- Residents: breath, glance, work beat, walks (see below); on Home's plate only tap/build hops.
- Visitors: arrival beat in code (`W/Layout/VisitorStage.swift:195-212`; dandelion drift or two hops), idle bob in Ambient. Plate path uses it (`IslandScene.swift:1281`).
- Metal/shader files: `W/Resources/WorldShaders.metal` (`pofuWorldGrade`), `SpikeShaders.metal` (`pofuRelight`, `pofuDepthBlur`), `PofuCompanion/Resources/CompanionShaders.metal`. `.colorEffect` 2, `.layerEffect` 2, `.distortionEffect` 1; no `MTKView`. No video, no image sequences, no `UIImage.animated`.
- Çağlayan's water:
  - On a painted plate (the case whenever `model.caglayanPlate != nil`, `IslandScene.swift:1554`) `CaglayanIsleView(painted: true)` skips all code water (`W/Caglayan/CaglayanScene.swift:159-163`, `:183`); the falls are baked into the painting.
  - The sky set for Çağlayan (`skyset-caglayan.json`) has one detail only: a `sway` blossom (`id: blossom`, amp 1.6, period 4.6). No `fall` detail; the `fall` kind exists (scrolling streak tile plus breathing mist, `SkySetView.swift:164-177`) and Home's two falls use it (`skyset-home.json`: `fall-a`, whale `fall`, speed 20).
  - Unpainted fallback: `CaglayanFalls` (`CaglayanScene.swift:356-428`), code `Canvas` ribbons, sliding dash highlights (`CaglayanLayout.fallPhase`), mist puffs, driven by the ambient clock (30 Hz while visiting). Also `HomeFountainView` (`:430-`), arcs plus ripples.
  - Flow game water: code-drawn fill along wet channels (`G/Flow/Scene/FlowScene.swift:28`).
- Residents and visitors, what happened:
  - Built: `W/Scene/ResidentLife.swift` (333 lines), a seeded 8 s cycle per resident (idle/work/walk, max 2 movers, `walkFPS 6`, step hops every 0.45 s, hop at the far end `:264`, work bob `:245`, tap reaction `reaction(age:)` `:328`). `W/Layout/CritterMotion.swift`, `Critters.swift` (butterflies etc., sprite loops). PR #277 (`17f9596e`, `60caff4a`); tracker row `docs/tracker.md:231` says built, missing walk-cycle sprites for Simit and the goat.
  - Wired: `IslandScene.swift:472-492` computes steps only if `!still`, Ambient, Reduce Motion off, not bedtime (`:474`, `:480`). Consumed at `:1345-1347` (`life.residents[...]`, `step.hop`) only in the sprite-island branch.
  - On Home's painted plate (the default; `HomePlate.resolve` `W/Plate/HomePlate.swift:140`, set at `IslandScene.swift:266`) the branch is `case .resident ... where plate != nil` (`:1246`): lift is only `build lift + reaction?.hop` (`:1249`), pose from `idlePose`; `life.residents` is never read. The plate path does not draw critters (`:1172-1174`). So walks, work beats and step hops do not run on the painted Home.
  - "Hops chosen over walks": no doc line found stating that choice. Hop code that exists: `ResidentLife` step hop/reaction hop (above), `VisitorStage` pier hops, Pofu's `pose.hop`. `SoundCue.pofuHop` exists but has no call site.
  - `App/Hop/*` is "Hop!", the shield/breath cover (`RootView.swift:73`), unrelated to hopping motion.

## 3. Sound

- No music track exists. No `.m4a`/`.mp3` in the app bundle; the four `design/sound/proof/island-*.m4a` files (`design/sound/proof/`, ~367 kB each: home-day-calm1.0, home-day-calm2.0, kaplica-evening, yildiz-night) plus `arrival-harbor.wav` (288044) and wav cues are proofs, not referenced by the app. Source tooling: `tools/sound/render.py`, `world.py`.
- 43 `.caf` files in `PofuSound/Resources/` (mono 16-bit; sizes bytes, durations from the CAF header):
  - Cues at 32 kHz: `seed-pop-0..4` (12930, 0.20 s); `bloom-00..10` (44290, 0.69 s each, D major pentatonic D4 up); `combo-rise-0..2` (53890, 0.84); `piece-pickup` (11010, 0.17); `piece-snap` (10370, 0.16); `piece-drop` (15490, 0.24); `piece-putback` (12930, 0.20); `deal` (24450, 0.38); `cheek` (12930, 0.20); `round-end` (79490, 1.24); `collect` (50690, 0.79); `skip-chime` (89090, 1.39); `pofu-hop` (29570, 0.46); `gulp` (11650, 0.18); `level-up` (48770, 0.76); `door-knock` (41090, 0.64); `kettle` (47490, 0.74); `water-wheel` (28290, 0.44); `water-splash` (24450, 0.38); `water-pour` (47490, 0.74).
  - 8 kHz loops/calls: `ambience-wind|crickets|rain|hush` (48130, 3.0 s seamless beds); `gull-0|1` (17730, 1.1 s); `breath-pad` (16130, 1.0 s).
- Where each plays: Garden cues via `PofuSound/GardenSoundBridge.swift:5-17` (lift/snap/plant/putBack/bloom/comboRise/cheek/deal/roundEnd; call sites `G/Scene/GardenScene.swift:267-807`). Flow via `WorldMoments.swift:31-38` (click to snap, thunk to drop, trickle to bloom steps, wheel, splash, pour; `FlowScene.swift:380-525`). Home: `collect` (`App/Home/HomeView.swift:182`, `:362`), `skip-chime` (`App/RootView.swift:144`, `App/Hop/HopOutcomes.swift:85`), `door-knock` on visitor arrival and `level-up` on island growth (`App/WorldSound.swift:110-113`), `kettle` in the morning if owed (`:78`), Far Bell song as `bloom` notes (`:45`), breath pad `breath-pad` (`:63-67`). Beds by `AmbienceMixer.mix` (`Ambience.swift:59-85`): bedtime hours 23-4 silent; mist = hush; light rain = rain + wind; clear/overcast/golden haze = wind by day, crickets 20-23; gulls at island level >= 3, 6-19 h, 28-75 s apart. `pofu-hop` and `gulp` have no call site; `cheek` plays only in the garden.
- Mixing: no mixer UI or bus graph, but a ducking layer exists. `AmbienceDucking` (`Ambience.swift:102-117`): beds drop to 0.45 on any cue, hold 0.5 s, return over 1.2 s. Gains = `master * group` (seeds/pieces/pofu, `SoundPolicy.swift:125-133`) with per-cue rate limits (`:60-67`). `SoundEngine` and `AmbienceConductor` each own an `AVAudioEngine` (`SoundEngine.swift:38`, `AmbienceConductor.swift:24`); session `.ambient` (`:273`). Bed gain 0.16, gull 0.2, breath 0.22; VoiceOver 0.316 factor; beds stop after 300 s idle (`Ambience.swift:97`, `:150`); yields to other audio via `secondaryAudioShouldBeSilencedHint` (`AmbienceConductor.swift:135`).

## 4. Minigames

- Entry: Home presents full-screen covers (`App/Home/HomeView.swift:140` garden, `:144` flow); `App/Home/GardenPlayView.swift`, `CaglayanFlowView.swift`. Flow opens from Çağlayan's stage via `onPlayFlow` (`IslandSceneModel.swift:190`, wired at `App/Home/HomeView.swift:109`).
- Garden (`G/UI`, `G/Scene`, 5 rounds per set `GardenSet.swift:9`, 18 plots per round `GardenRound.swift:25`, 8x8 bed `GardenBoard.swift:8`, 3-piece tray). Phases playing/paused/roundEnd/setEnd (`GardenGameModel.swift:15-22`).
  - Painted PNGs (`G/Resources`, 21 files): bed rim (437 kB), tray (481 kB), soil, 6 tile glazes, 5 blooms, combo stamp, Pofu, Pofu puff, Mochi, Findik.
  - Code-drawn: sky gradient and sun texture (`GardenScene.swift:168`, `GardenPalette`), paper plates, stitched edges, clay buttons (`UI/GardenCrafted.swift`, "drawn stand-ins until the painted faces are generated").
  - HUD (`GardenGameView.swift`): round plate with dots (`:199-231`), seed plate "+N" (`:244`), pause button `pause.fill` (`:89`), pause card with Resume and "Enough for today" (glass: `.glassProminent`, `.glass`, `.glassEffect` `:273-284`), round and set cards with bloom stamps and "to cheeks" count (`:307-357`).
- Flow (`G/Flow`, hand-made boards `Resources/flow-boards.json`: 8 boards, 4 stages x 2, all skin `water`, Çağlayan only). Phases playing/pouring/finished (`FlowGameModel.swift:15-22`).
  - Painted: none. No `flow-*` image in `G/Resources`; `FlowArt.swift:5-8` says code-drawn stand-ins until `batch-64-flow-pieces`; `FlowTextures.artName` (`:73-83`) names the hooks (`flow-tile-straight|bend|split|gate|source|mouth`, `flow-rock`, `flow-grass`, wheel).
  - Code-drawn: sky gradient, stone tiles, grooves, water fill, rocks, grass, wheel (`FlowArt.swift`, `FlowScene.swift`).
  - HUD (`FlowGameView.swift`): leave `xmark` (`:143`), board counter "n of total" (`:169`), targets `drop.fill`/`checkmark.circle.fill` with "x/y" (`:196-204`), undo `arrow.uturn.backward` and hint `lightbulb.fill` round buttons (`:234-236`), done card "Done" (`:220-228`, `ClayButtonStyle`).
- No other games found in `PofuGames` (Garden and Flow only).

## 5. Glass UI

- Deployment target iOS 26.0 (`project.yml:7-8`; `Packages/PofuKit/Package.swift:15` `.iOS(.v26)`).
- Used: `.glassEffect(.regular...)` at `W/Home/WorldHome.swift:560`, `W/Scene/StationSheet.swift:401`, `W/Scene/IslandScene.swift:2405`, `W/Scene/PlaceControl.swift:85` (`.interactive()`, circle), `App/Home/HomeView.swift:230` (settings capsule), `App/Home/GardenPlayView.swift:64`, `PofuDesignSystem/PofuSkinViews.swift:233-247`, `PofuSheet.swift:104`, `G/UI/GardenGameView.swift:284`; Rehearsal panels. Button styles `.glass`/`.glassProminent` at `PofuSkinViews.swift:142-144`, `GardenGameView.swift:273-279`. The default skin is `.glass` (`PofuSkin.swift:44`, `PofuSkinEnvironment.swift:8`); Reduce Transparency falls back to the crafted skin (`PofuSkin.swift:55,61,67`).
- Not used anywhere (grep over `Packages` and `App`): `GlassEffectContainer`, `glassEffectID`/`glassEffectUnion`/`glassEffectTransition` (no glass morphing), `TabView`, `tabViewBottomAccessory`, `tabBarMinimizeBehavior`, `safeAreaBar`, `scrollEdgeEffect`, `UIGlassEffect`.
- Navigation today: no tab bar. One scene with a camera rail of stops (Home, Island, Close, Archipelago/Map) moved by pinch (`MagnifyGesture` `IslandScene.swift:182`) and drag. `PlaceControl` (`W/Scene/PlaceControl.swift`), a 52 pt disc bottom trailing, is a SwiftUI `Menu` with a `primaryAction`: tap goes out one stop (`placeControlTapped` `IslandSceneModel.swift:561`); long press opens a native menu listing Pofu, each arrived island and the Archipelago (`:29-44`), which calls `go(to:)` / `fly(to:)` (`:472`, `:568`). Top bar: seed pill opens Passes, gear opens Settings (`HomeView.swift:212-237`) as sheets (`:112-135`). Hop! is a full-screen cover (`RootView.swift:73`). Minigames are full-screen covers.
