# Asset inventory: every visual element the player can see

Neutral inventory, gathered 2026-11-14 as the first step of an asset system. Facts only: no quality judgement, no recommendation.

- **Commit read:** `origin/main` `dbcfd8248dda40f155b1447e26cd9d3386eb4830` (code read with `git archive`, not from docs).
- **Frames:** `screenshots/main` tip `8a981ab31945d8a1f7077edce091effb3ec28b52` (its commit message says "for main at dbcfd82"). The Frame column gives a file name from that branch's listing. Frames opened and looked at (16): `sprite-01/02/05/07/08/11/12`, `15-menu-today-light`, `16-menu-settings-light`, `17-sheet-station-v3-day-large`, `19-shield-day`, `06-shield-replica-light`, `20-gate-1200`, `breath-2-hold`, `20-garden-midround-light`, `40-flow-stage1-start`, `20-launch-sky`, `path-onboarding-welcome`, `path-onboarding-apps`, `look-celebration-card`, `caglayan-plaque`, `weather-sheet`. Every other Frame cell is matched by file name only and was not opened.
- **Paths:** `App/...` and `Extensions/...` are repo paths. A bare `PofuWorld/...`, `PofuDesignSystem/...`, `PofuGames/...`, `PofuCompanion/...`, `PofuCore/...` path is under `Packages/PofuKit/Sources/`.
- **Drawn-with kinds (first word of the cell):** `painted` (a bundled image), `code shape` (SwiftUI/CoreGraphics/SpriteKit drawing), `SF Symbol`, `emoji`, `text only`, `missing` (code names an asset that is not in any bundle). "fallback:" names what draws when the painted file is absent.
- **Builds:** `project.yml` defines `Pofu` and `PofuLive` (both use the same Home) and `PofuWorldScreenshots` (test target). `FeatureFlags.worldHome = true` and `islandHome = true` (`App/Support/FeatureFlags.swift:6,13`), so Home is `WorldHome`; the old Home chrome in `App/Home/HomeView.swift:48-70` (top bar, `TodayCard`, `QuietStreak`, `CollectButton`, `PofuIconButton` ticket) is behind `if !FeatureFlags.worldHome` and does not draw. Those rows are marked "not drawn (flag off)".
- **Emoji:** none in any `.swift` file or any `.xcstrings` file (scanned with a Unicode range search).
- **Widgets / Live Activities:** none (no `WidgetKit`/`ActivityKit` import in `App/`, `Extensions/`, `Packages/`). Notifications carry text only (`Extensions/Shared/GateNotificationContent.swift:11-27`, `title`/`body`, no attachment or icon).
- **Not traced:** which of the 4 baked "light" sets (`day`, `night`, `golden`, `rain`, plus `dawn`/`dusk`/`mist` in some families) show at which hour was not traced for every family; the Frame column cites a frame where a state is visible by name.

## 1. Launch and onboarding

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Launch screen (Info.plist) | Dawn sky behind launch | painted `launch-sky` (App catalog) over `LaunchBackground` colour | Config/Info.plist:12-22 | 20-launch-sky.jpg |
| Launch curtain | Dawn sky | painted `launch-sky` (fallback: code gradient) | App/Launch/LaunchCurtain.swift:116-120 | 20-launch-sky.jpg |
| Launch curtain | Cloud banks 1-3 | painted `cloud-curtain-1..3` (fallback: code ellipses `CloudBank`) | App/Launch/LaunchCurtain.swift:139-195 | 21-launch-curtain-and-line.jpg |
| Launch curtain | "Pofu is waking up…" line | text only | App/Launch/LaunchCurtain.swift:49 | 21-launch-curtain-and-line.jpg |
| App icon | Light / Dark / Tinted 1024 icons | painted `AppIcon.png`, `AppIcon-Dark.png`, `AppIcon-Tinted.png` | App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json | none |
| Onboarding welcome | Pofu portrait | painted `pofu-hamster.png` via `CompanionView` (rig + lids + parts) | App/Onboarding/OnboardingView.swift:139 | path-onboarding-welcome.png |
| Onboarding welcome | "Hi, I'm Pofu." / body text | text only | App/Onboarding/OnboardingView.swift:141-145 | path-onboarding-welcome.png |
| Onboarding welcome | Primary button | code shape (`PofuPrimaryButtonStyle` capsule) | App/Onboarding/OnboardingView.swift:151 | path-onboarding-welcome.png |
| Onboarding screen-time step | Reason rows (3) | SF Symbol `hand.raised`, `eye.slash`, `switch.2` | App/ScreenTime/ScreenTimeSetupView.swift:125-127 | none |
| Onboarding screen-time step | Picker-help rows | SF Symbol `chevron.right.circle`, `bubble.left.and.bubble.right` | App/ScreenTime/ScreenTimeSetupView.swift:144-145 | none |
| Onboarding screen-time step | Apple app picker | system UI (`familyActivityPicker`); Rehearsal stand-in in section 14 | App/ScreenTime/ScreenTimeSetupView.swift:85 | none |
| Onboarding apps | App rows (Instagram, YouTube, TikTok, others) | SF Symbol `camera`, `play.rectangle`, `music.note` (+ `text.bubble`, `bolt.horizontal.circle`, `bubble.left.and.bubble.right`, `person.2`, `app`) | App/Onboarding/OnboardingView.swift:331; App/Support/AppPresentation.swift:31-42 | path-onboarding-apps.png |
| Onboarding apps | Selected tick | SF Symbol `checkmark.circle.fill` | App/Onboarding/OnboardingView.swift:335 | path-onboarding-apps.png |
| Onboarding apps | Title, footnote, choice rows | text only; `PofuChoiceStyle` rounded rectangle | App/Onboarding/OnboardingView.swift:310-364 | path-onboarding-apps.png |
| Onboarding name | Pofu portrait | painted `pofu-hamster.png` via `CompanionView` | App/Onboarding/OnboardingView.swift:374 | path-onboarding-name.png |
| Onboarding name | Text field, suggestion chips | code shape (`RoundedRectangle`, `PofuChoiceStyle` capsule) + text | App/Onboarding/OnboardingView.swift:380-408 | path-onboarding-name.png |
| Onboarding notifications | Bell | SF Symbol `bell.badge` | App/Onboarding/OnboardingView.swift:188 | path-onboarding-notifications.png |
| Onboarding notifications | Pofu portrait | painted `pofu-hamster.png` via `CompanionView` (line 226 is the next step) | App/Onboarding/OnboardingView.swift:226 | path-onboarding-notifications.png |
| Onboarding try-it | Pofu portrait, copy, buttons | painted `pofu-hamster.png`; text; capsules | App/Onboarding/OnboardingView.swift:226-261 | none |
| Onboarding try-it (Rehearsal only) | "Reach for Instagram" button + badge | SF Symbol `camera`; `RehearsalBadge` (`theatermasks.fill`) | App/Onboarding/OnboardingView.swift:275-282 | none |
| Onboarding caught | Pofu portrait, "Got you!" | painted `pofu-hamster.png`; text | App/Onboarding/OnboardingView.swift:291-303 | none |
| Setup guide (Shortcuts steps) | Per-step screenshot of Apple's Shortcuts app | missing: code asks `SetupStep-<step>` (App catalog has none), draws `ShortcutsSchematic` instead | App/Setup/SetupGuideView.swift:264,362 | none |
| Setup guide | Schematic of Shortcuts (tabs, rows, toggles, ring) | code shape + SF Symbol `square.grid.2x2`, `checkmark.circle`, `square.stack`, `clock`, `alarm`, `envelope`, `app`, `plus.square.dashed`, `hare`, `magnifyingglass`, `xmark`, `plus`, `checkmark`, `chevron.right`, `circle` | App/Setup/SetupGuideView.swift:382-640 | none |
| Setup guide | Step number disc, note icon | code shape `Circle`; SF Symbol `exclamationmark.circle` | App/Setup/SetupGuideView.swift:323-337 | none |
| Setup guide | App picker ticks; works / not-working status | SF Symbol `checkmark.circle.fill`, `checkmark.seal.fill`, `circle.dashed` | App/Setup/SetupGuideView.swift:211,231,239 | none |
| Setup guide | Nav title, buttons, text | text only; `PofuPrimaryButtonStyle`/`PofuQuietButtonStyle` | App/Setup/SetupGuideView.swift:137-176 | none |

## 2. Home (WorldHome) and its overlays

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Home | Sky (sun, mid clouds, far isles, whale, moon, stars) | painted `world-home-sky-{sky,mid,sea,far,island,isle-crystal,isle-dome,isle-falls,isle-house,whale,moon,stars0-2}-<light>` via skyset JSON | PofuWorld/Sky/SkySetView.swift:17,159-248; PofuWorld/Plate/PaintedSky.swift:430 | sky-home-1200.jpg |
| Home | Sky effects (waterfall flow/mask, canopy crop/mask, lantern glow, windows glow) | painted `world-home-sky-fx-*` | PofuWorld/Sky/SkySetView.swift:159-248 | sky-home-1830.jpg |
| Home | Distant cloud sprites | painted `world-cloud-2`, `world-cloud-4` | PofuWorld/Sky/SkyModel.swift:266-282; PofuWorld/Scene/LivingSky.swift:146 | clouds-1200.jpg |
| Home | Cloud sea below the island | painted `world-cloud-sea` (+ code `SeaStrip`) | PofuWorld/Scene/LivingSky.swift:180,307,352 | sprite-02-home-settled-light.jpg |
| Home | Fog cards | painted `world-fog-card-1..3` (fallback: code-drawn card) | PofuWorld/Scene/FogCards.swift:17,63; PofuWorld/Sky/FogModel.swift:126 | sky-fog-sheet.jpg |
| Home | Sun glow, star field, vignette | code shape (`SunGlow`, `StarField`, `VignetteOverlay`) | PofuWorld/Scene/LivingSky.swift:97,401,425 | sky-home-2230.jpg |
| Home | Home island plate (the painted island, 10 growth stages x lights) | painted `world-home-plate-<light>-<stage>`, `world-home-island-*`, `world-home-backdrop-*`, `world-home-mapisle-*` | PofuWorld/Plate/PlateIsland.swift:170-195; PofuWorld/Plate/PlateHomeViews.swift:16-160 | home-plate-full-l5-day.png |
| Home | Occluders (bushes, mailbox, tea stall, wheel, windmill, workshop) | painted `world-home-occ-<id>-<light>-<stage>` | PofuWorld/Plate/PlateIsland.swift:195; PofuWorld/Plate/PlateHomeViews.swift:168 | home-plate-full-l5-day.png |
| Home | Stations on the plate (tea stall, workshop, garden, windmill, pond, bagel cart, pier, lighthouse), per level | painted sprites `world-<station>-<level>` (+ `__soft`, `__deep`, `-shadow`, `--normal`) | PofuWorld/Layout/IslandLayout.swift:117; PofuWorld/Scene/IslandScene.swift:1767 | home-il05.jpg |
| Home | Station with no art at some level | code shape: labelled rounded rectangle `PlaceholderVignette` | PofuWorld/Scene/IslandScene.swift:1863 | none |
| Home | Level badge on a station that wears a lower level's art | code shape (`Circle` + number) | PofuWorld/Scene/BuildEffects.swift:76; PofuWorld/Scene/IslandScene.swift:1793 | plate-life-build-l5.jpg |
| Home | Build spot marker | code shape (dashed `Ellipse`) + SF Symbol `plus` | PofuWorld/Scene/IslandScene.swift:1845-1852 | sprite-04-station-build-light.jpg |
| Home | Hive (3 levels) | painted `world-hive-1..3` | PofuWorld/Layout/HomeFixtures.swift (hiveArt); PofuWorld/Scene/LifeViews.swift:62 | home-il06.jpg |
| Home | Doors in the earth face (Mochi, Fındık) | missing: code names `door-mochi`, `door-findik` (no sprite or imageset); glows `door-mochi-glow` painted | PofuWorld/Layout/HomeFixtures.swift (Door ids); PofuWorld/Look/LitSources.swift (door glow) | none |
| Home | Path lamps and their glow | painted `world-path-lamp`, `world-path-lamp-glow` | PofuWorld/Layout/HomeFixtures.swift (lamp feet); PofuWorld/Look/LitSources.swift | light-night-home.jpg |
| Home | Dressing pieces (grass tufts, wildflowers, pebbles, mushroom ring, watering can, seed sack, twine, crate, trowel, rope, barrel) | painted `world-dressing-*` (fallback: code-drawn `LifeArt`) | PofuWorld/Layout/IslandDressing.swift; PofuWorld/Scene/LifeViews.swift:14; PofuWorld/Scene/LifeArt.swift:13 | dressing-il1-home.jpg |
| Home | Bench (IL10) | painted `world-decor-bench` | PofuWorld/Layout/IslandGrowth.swift:42 | home-il10.jpg |
| Home | Growth pieces: path stone, flag pole, gull, kettle steam, rope bridge, lily pad, reeds, stepping stone, dragonfly, terrace, lantern string, hill stone, gate, hilltop | code shape (`GrowthArt` stand-ins); no `growth-*` sprite exists | PofuWorld/Scene/GrowthArt.swift:39-86; PofuWorld/Layout/IslandGrowth.swift:12-47 | home-growth-il1-il10.jpg |
| Home | Critters: butterfly, snail, bird | painted `world-critter-{butterfly,snail,bird}-1..4` | PofuWorld/Layout/Critters.swift:7-27; PofuWorld/Scene/LifeViews.swift:80 | life-home-il6-settled.jpg |
| Home | Critters: frog, ladybug | missing: `critter-frog`, `critter-ladybug` (no sprite); code stand-in | PofuWorld/Layout/Critters.swift:7,82; PofuWorld/Scene/LifeArt.swift:5-8 | none |
| Home | Fireflies | painted `firefly-1..3` | PofuWorld/Scene/WorldLookLayers.swift:625 | light-night-home.jpg |
| Home | Warm halo, ground pool, pond shimmer, window spill | painted `glow-warm-halo`, `glow-ground-pool`, `glow-pond-shimmer`, `glow-window-spill` | PofuWorld/Scene/WorldLookLayers.swift:378,730,739,749 | light-night-home.jpg |
| Home | Light shaft | painted `world-light-shaft` | PofuWorld/Koke/KokeLook.swift:110; PofuWorld/Scene/WorldLookLayers.swift:796 | weather-home-clear.jpg |
| Home | Cast shadows (sun, moving, cloud shadows) | painted `world-<art>-shadow` silhouettes + code shape | PofuWorld/Scene/ShadowBake.swift:32,186,227; PofuWorld/Scene/BuildEffects.swift:235 | shadow-home-1830.jpg |
| Home | Colour grade LUTs | painted `world-lut-{characters,island}-{dawn,day,dusk,golden,night,rain}` | PofuWorld/Look/LookLUT.swift:53 | grade-day-home.jpg |
| Home | Rain, puddle glint, rainbow | painted `world-rain-tile`, `world-puddle-glint`, `world-rainbow-arc` (fallback: code-drawn image) | PofuWorld/Scene/WeatherLayer.swift:84-108,148,288 | weather-home-rain.jpg |
| Home | Screen haze, soft shaft | code shape | PofuWorld/Scene/WeatherLayer.swift:347,424 | weather-home-screen-haze.jpg |
| Home | Pofu (live companion over baked soft/deep) | painted `world-pofu` (+ `__soft`, `__deep`, `-shadow`, `--normal`) and the live rig `pofu-hamster.png` | PofuWorld/Scene/IslandScene.swift:1920-2112 | sprite-02-home-settled-light.jpg |
| Home | Pofu cheek paws (seeds waiting) | code shape (`Ellipse` paws) | PofuWorld/Home/HomeObjectViews.swift:562-583 | sprite-11-collect-paws-light.jpg |
| Home | Residents Mochi, Fındık, Simit, goat (poses) | painted `world-<name>-<pose>` sprites; see section 15 | PofuWorld/Scene/IslandScene.swift:1255,1306,1319,1881 | sprite-08-resident-card-light.jpg |
| Home | Contact shadow / pad under characters | code shape | PofuWorld/Scene/DepthImage.swift:117; PofuWorld/Plate/PlateHomeViews.swift:319 | shadow-pofu-1200.jpg |
| Home | Seed jar body | painted `ui-jar-empty` (+ `-shadow`) (fallback: code `VectorJar` rounded rectangles) | PofuWorld/Home/HomeObjectViews.swift:42-80 | sprite-02-home-settled-light.jpg |
| Home | Seeds in the jar (heap, window fill) | code shape (`SeedHeap`, `JarWindowFill`, `WavyTop`) | PofuWorld/Home/HomeObjectViews.swift:80-165 | sprite-02-home-settled-light.jpg |
| Home | Jar count tag ("20") | code shape (capsule) + text | PofuWorld/Home/HomeObjectViews.swift:167-188 | sprite-02-home-settled-light.jpg |
| Home | Jar tap target and label | code shape (`HomeJar`) | PofuWorld/Home/HomeObjectViews.swift:190-267 | sprite-02-home-settled-light.jpg |
| Home | Calm lantern (off) | painted `ui-lantern-off` (+ `-shadow`) (fallback: code `VectorLantern` capsules) | PofuWorld/Home/HomeObjectViews.swift:297-390 | sprite-02-home-settled-light.jpg |
| Home | Calm lantern glow (lit) | code shape (`Ellipse` glow) | PofuWorld/Home/HomeObjectViews.swift:318-355 | light-calm-compare.jpg |
| Home | Skip pots (today's skips) | painted `ui-pot-empty` | PofuWorld/Home/HomeObjectViews.swift:394-500 | sprite-02-home-settled-light.jpg |
| Home | Pot bloom, pot bud, pot count badge | code shape (`Bloom`, `Bud` capsules/circles, capsule badge) | PofuWorld/Home/HomeObjectViews.swift:494-560 | sprite-02-home-settled-light.jpg |
| Home | Pot pips (station level, in Station sheet) | code shape (`PotShape`, `PotPip`) | PofuWorld/Scene/PotPips.swift:9-66 | 17-sheet-station-v3-day-large.jpg |
| Home | Speech bubble (Pofu's line) | code shape (`SpeechBubble` / `BubbleShape` + tail) + text | PofuDesignSystem/PofuComponents.swift:246-292; PofuWorld/Home/WorldHome.swift:158-166 | sprite-01-home-visit-light.jpg |
| Home | Plate line (line card with "Pofu" label) | code shape (rounded rectangle) + text | PofuWorld/Home/WorldHome.swift:562-592 | plate-life-greeted-l5.jpg |
| Home | Daily-line pill ("Bugün 3 kez boş verdik…") | code shape (rounded rectangle, 86% card) + text | PofuWorld/Home/WorldHome.swift:284-292 | sprite-02-home-settled-light.jpg |
| Home | Gear button (top right) | painted `paint-duo-settings` (fallback: SF Symbol `gearshape`), glass capsule | PofuWorld/Home/WorldHome.swift:223; PofuDesignSystem/PofuSkinViews.swift:170-225 | sprite-01-home-visit-light.jpg |
| Home | Repair banner (when setup broken) | SF Symbol `exclamationmark.shield.fill` + text + gear button, glass capsule | PofuWorld/Home/WorldHome.swift:516-540 | none |
| Home | Contextual primary action ("Topla · 11" / beat action) | code shape (`pofuActionStyle(.primary)`) + text | PofuWorld/Home/WorldHome.swift:269-282; PofuWorld/Home/HomeObjectViews.swift:269-290 | sprite-01-home-visit-light.jpg |
| Home | Today glance card (bottom left) | code shape + text; `GuardedSteps` capsule segments; SF Symbol `chevron.up` | PofuWorld/Home/HomeObjectViews.swift:589-640; PofuWorld/Home/WorldHome.swift:544-560 | sprite-02-home-settled-light.jpg |
| Home | Place control (bottom right pill: Pofu face / island / archipelago glyph) | painted `paint-duo-island`, `paint-duo-map`, `paint-duo-home` (fallbacks: code `IslandSilhouette`, `ArchipelagoGlyph`, `PofuFaceGlyph`); glass circle | PofuWorld/Scene/PlaceControl.swift:13-170 | sprite-02-home-settled-light.jpg |
| Home | Pofu face glyph (crop of the base art) | painted `pofu-hamster.png` crop | PofuWorld/Scene/PlaceControl.swift:103-125 | sprite-07-map-light.jpg |
| Home | Island name chip ("Ayçiçeği", island framing) | code shape + text | PofuWorld/Home/WorldHome.swift:597-611 | integration-island-day.jpg |
| Home | Collect flight (seeds fly from Pofu to jar) | `SeedIcon` (painted `paint-icon-seed`, fallback code `SeedGlyph`) | PofuWorld/Home/WorldHome.swift:657; PofuDesignSystem/PofuComponents.swift:188 | sprite-12-collect-flight-light.jpg |
| Home | Jar overlay (tag/seed during collect) | code shape | PofuWorld/Home/WorldHome.swift:613-655 | sprite-12-collect-flight-light.jpg |
| Home | Greeting heart | SF Symbol `heart.fill` | PofuWorld/Scene/HomeFeedbackViews.swift:56-69 | visitor-v1-greeted.jpg |
| Home | Gift tag ("moss" / "fountain") | SF Symbol `leaf.fill` / `drop.fill` + text, tailed bubble code shape | PofuWorld/Scene/HomeFeedbackViews.swift:7-120 | caglayan-gift-home.jpg |
| Home | Resist wax seals on the earth face | code shape `ResistWaxSeal` (circles) + SF Symbol `leaf.fill`; "+N" text for overflow | PofuDesignSystem/PofuDoorStamp.swift:104-125; PofuWorld/Scene/ResistSeals.swift:109-160 | payoff-door-day-10.jpg |
| Home | Build particles, sparkle, level-up bloom, ground pad, build tag | code shape; painted `glow-ground-pool` | PofuWorld/Scene/BuildEffects.swift:9-235 | sprite-05-build-pop-light.jpg |
| Home | Island-grow bloom and celebration card ("YENİ SEVİYE / Çay ocağı 3") | code shape (paper card, `Ribbon`) + SF Symbol `sparkle` + text | PofuWorld/Scene/IslandGrowViews.swift:8-66; PofuWorld/Scene/CelebrationCard.swift:9-150 | look-celebration-card.jpg |
| Home (old chrome, not drawn: flag off) | Top bar seed pill, settings gear, `TodayCard`, `QuietStreak`, `CollectButton`, ticket button, Pofu halo | `SeedPill`; `PofuDuoIcon` / `gearshape`; SF Symbol `ticket`, `leaf` | App/Home/HomeView.swift:62-90,216-226,389-474 | none |
| Home (dev) | Frame meter overlay | code shape + text | PofuWorld/Scene/FrameMeter.swift:123 | none |

## 3. Visitors, gifts, letters (Home)

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Home visit | Visitor drifting down on a seed | missing: `visitor-dandelion` (no sprite); code stand-in | PofuWorld/Layout/VisitorStage.swift:17-25; PofuWorld/Scene/LifeViews.swift:128-205 | visitor-v1-day.jpg |
| Home visit | Visitor figure by id | painted `world-visitor-damla`, `world-visitor-gezgin` (looked up as `visitor-<id>`) | PofuWorld/Scene/LifeViews.swift:185 | none |
| Home visit | Gift parcel | painted `world-gift-parcel-closed` | PofuWorld/Layout/VisitorStage.swift:22; PofuWorld/Scene/LifeViews.swift:209 | visitor-v1-day.jpg |
| Home visit | Help item (kite in a tree) | code shape stand-in (`help` part has no named art) | PofuWorld/Layout/VisitorStage.swift:312-320; PofuWorld/Scene/LifeArt.swift | visitor-v1-help.jpg |
| Home visit | Quiet-day letter envelope | painted `world-guest-letter-envelope` | PofuWorld/Layout/VisitorStage.swift:24; PofuWorld/Scene/LifeViews.swift:209 | visitor-quiet-day.jpg |
| Home visit | Gift objects after opening (moss, fountain) | painted `world-gift-moss`, `world-gift-fountain` | PofuWorld/Scene/IslandScene.swift:1388,1390 | koke-gift-home.jpg |
| Home visit | Moss gift texture | missing: `material-moss` (not in any bundle); code ellipses | PofuWorld/Koke/KokeScene.swift:511-531 | none |
| Invite sheet | Title, empty state, rows, close | text only; `PofuTextButtonStyle` | PofuWorld/Scene/InviteSheet.swift:21-66 | none |
| Invite sheet | Header tea sticker | missing: `sticker-duo-tea` -> SF Symbol `cup.and.saucer` | PofuWorld/Scene/InviteSheet.swift:30; PofuDesignSystem/Sticker.swift:23,127 | none |
| Invite sheet | Visitor portrait per row | painted `world-visitor-<id>` | PofuWorld/Scene/InviteSheet.swift:39 | none |
| Invite sheet | Row panel, send icon | painted `paint-panel-paper` (light mode) via `PofuPaperPanel`; SF Symbol `paperplane` | PofuDesignSystem/PofuPaint.swift:143-160; PofuWorld/Scene/InviteSheet.swift:48-55 | none |

## 4. Map (archipelago) and island stops

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Map | Painted map plate | painted `world-home-mapisle-<light>-<stage>`, `world-home-plate-*` at map framing | PofuWorld/Plate/PlateIsland.swift:186; PofuWorld/Scene/IslandScene.swift:767 | map-plate-l5-day.png |
| Map | Home island + İskele (harbor) island | painted `world-home-mapisle-*`; `world-harbor-island-s` (1-3) | PofuWorld/Layout/IslandLayout.swift (`Isle`, harbor art `harbor-island-s`) | sprite-07-map-light.jpg |
| Map | Island label pills ("Ayçiçeği", "İskele") | code shape + SF Symbol `pawprint.fill` / `lock.fill` + text | PofuWorld/Scene/IslandScene.swift:2372-2380 | sprite-07-map-light.jpg |
| Map | Pofu pin | SF Symbol `pawprint.fill` on honey circle | PofuWorld/Scene/IslandScene.swift:2123-2135 | sprite-07-map-dark.jpg |
| Map | Far isles (Çağlayan, Emanet, Mehtap, Revontuli, Gezgin) | painted `world-far-isle-1..3` | PofuWorld/Sky/FarSkyLayout.swift:125-143; PofuWorld/Scene/FarSky.swift:12-87 | integration-map-day.jpg |
| Map | Far-isle art for Emanet, Mehtap, Revontuli | painted `far-isle-1/2` reused; comments say "art pending" | PofuWorld/Sky/FarSkyLayout.swift:125-131 | none |
| Map | Four extra isle sprites (hamam, harbor, library, stars "standin") | painted `world-isle-{hamam,harbor,library,stars}-standin` exist; no code reference found | PofuWorld/Geometry/WorldArt+Generated.swift:1958-2004 | none |
| Map | Far-bell sky (the bell at the edge) | painted layers via plate JSON | PofuWorld/Plate/FarBellSky.swift:45 | path-d21-bell-0900.png |
| Map | Place control (Pofu / archipelago glyph) | as Home place control | PofuWorld/Scene/PlaceControl.swift:13-170 | sprite-07-map-light.jpg |
| Koke island | Island plate by stage (0-4) | painted `world-koke-island-0..4`; fallback code shapes (`KokeIsleView`) | PofuWorld/Koke/KokeLayout.swift:142; PofuWorld/Koke/KokeScene.swift:136-440 | koke-stages.jpg |
| Koke island | Koke poses (asleep, one eye, stretch, stone) | painted `world-koke-{asleep,one-eye,stretch,stone}` | PofuWorld/Koke/KokeLayout.swift:167-176; PofuWorld/Koke/KokeScene.swift:174-178 | koke-stage-0.jpg |
| Koke island | Koke "standing" pose | missing: `world-koke-standing` (no imageset); falls back to `oneEye` | PofuWorld/Koke/KokeLayout.swift:152-170 | koke-stage-4.jpg |
| Koke island | Far hump of Koke seen from the harbor | code shape | PofuWorld/Koke/KokeScene.swift:450-505 | koke-rumour-harbor.jpg |
| Koke island | Bubble overlay (Pofu / Mochi / Koke lines) | code shape + text | PofuWorld/Koke/KokeScene.swift:103-130 | koke-beat-3.jpg |
| Koke island | Stage light and grade | code shape | PofuWorld/Koke/KokeLook.swift:74,160 | koke-stage0-0700.jpg |
| Çağlayan island | Island plate by stage x light (`island`, `plate`, `backdrop`, `sky-*`) | painted `world-caglayan-{island,plate,backdrop}-<light>-<stage>`, `world-caglayan-sky-*` | PofuWorld/Caglayan/CaglayanLayout.swift:126; PofuWorld/Plate/CaglayanPlate.swift | caglayan-stages.jpg |
| Çağlayan island | Falls and fountain ripples | code shape (`CaglayanFalls`, `HomeFountainView`) | PofuWorld/Caglayan/CaglayanScene.swift:356-465 | caglayan-stage-3.jpg |
| Çağlayan island | Damla (and glass state) | painted `world-damla`, `world-damla-glass` | PofuWorld/Caglayan/CaglayanLayout.swift:139,40003; PofuWorld/Caglayan/CaglayanScene.swift:467-490 | caglayan-beat-3.jpg |
| Çağlayan island | Placeholder island if plates absent | code shape (soft ellipse) | PofuWorld/Caglayan/CaglayanScene.swift:247-250 | none |
| Çağlayan island | Plaque button ("Akışı bağla") | code shape (`PofuPlaqueStyle(.primary)`) + text | PofuWorld/Caglayan/CaglayanScene.swift:131-156 | caglayan-plaque.jpg |
| Çağlayan island | Bubble overlay (Pofu / Mochi / Damla) | code shape + text | PofuWorld/Caglayan/CaglayanScene.swift:106-129 | caglayan-beat-0.jpg |
| Çağlayan island | Sky-fx dome blossom crop/mask | painted `world-caglayan-sky-fx-isle-dome-blossom-{crop,mask}-day-0` | PofuWorld/Sky/SkySetView.swift:159-248 | caglayan-plate-full-s0-day.png |
| Flights (camera between stops) | Camera flight Home <-> Map <-> Island | same layers as above, moving camera (no extra art) | PofuWorld/Camera/CameraFlight.swift | flight-home-koke-mid.png |

## 5. Sheets (Today, Station, Passes, Earn)

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Today sheet | Paper sheet background | code shape (`PofuPaperSheetBackground`; art hook `ui-sheet-paper-v3[-night]` missing) | PofuDesignSystem/Kit/KitPaper.swift:113-130; PofuDesignSystem/Kit/KitMaterial.swift:23-24 | 15-menu-today-light.jpg |
| Today sheet | Day card header picture | painted home-plate crop via `HomePlateCrop` (fallback: code `IslandStrip`: sky/orb/ellipses/capsule) | App/Home/TodaySheet.swift:96-135,182-228; PofuWorld/Plate/HomePlateCrop.swift:59 | 15-menu-today-light.jpg |
| Today sheet | Day card paper (stitched) | code shape (`PofuPaperSurface(kind: .stitched)`; art hook `ui-card-stitched` missing) | App/Home/TodaySheet.swift:172; PofuDesignSystem/Kit/KitPaper.swift:39 | 15-menu-today-light.jpg |
| Today sheet | Seal row (wax seals per bead) | code shape (`WaxSeal` circle) + SF Symbol `leaf.fill` ("batch-60 `seal-resist`" missing) | App/Home/TodaySheet.swift:230-266 | none |
| Today sheet | Pofu bubble with name tag | code shape (`PofuPaperBubble`) + small `CompanionView` portrait | App/Home/TodaySheet.swift:45-60 | 15-menu-today-light.jpg |
| Today sheet | Texts ("Bugün", "Kavanozda 0 çekirdek") | text only; seed icon painted `paint-icon-seed` | App/Home/TodaySheet.swift:118-165 | 15-menu-today-light.jpg |
| Station sheet | Sheet surface and handle | code shape (`PofuPaperSheetBackground`) | PofuWorld/Scene/IslandScene.swift:303-316; PofuDesignSystem/Kit/KitPaper.swift:113 | 17-sheet-station-v3-day-large.jpg |
| Station sheet | Close button | SF Symbol `xmark` on code `Circle` | PofuWorld/Scene/StationSheet.swift:180-185 | 17-sheet-station-v3-day-large.jpg |
| Station sheet | Pot pips (levels) | code shape (`PotPips`) | PofuWorld/Scene/StationSheet.swift:194; PofuWorld/Scene/PotPips.swift | 17-sheet-station-v3-day-large.jpg |
| Station sheet | Rate / state rows ("Günde 0,5 çekirdek…") | code shape (`PofuPaperSurface`) + text | PofuWorld/Scene/StationSheet.swift:205-230 | 17-sheet-station-v3-day-ready-medium.jpg |
| Station sheet | Build button ("13 çekirdek daha") | code shape (`PofuPlaqueStyle(.primary)`; art hooks `ui-plaque-*` missing) + `SeedGlyph` | PofuWorld/Scene/StationSheet.swift:280-305; PofuDesignSystem/Kit/KitPlaque.swift:115-190 | 17-sheet-station-v3-day-large.jpg |
| Station sheet | Play rounds link, reasons, "Every level is built." | text only; `PofuTextButtonStyle` | PofuWorld/Scene/StationSheet.swift:249-320 | 17-sheet-station-v3-day-ready-medium.jpg |
| Station sheet | States "Not open yet", "Building…" | text only | PofuWorld/Scene/StationSheet.swift:127,137 | path-sheet-station.png |
| Resident card | Card shell and tail | code shape (rounded rectangle, glass, `CardTail`) | PofuWorld/Scene/StationSheet.swift:349-405 | sprite-08-resident-card-light.jpg |
| Resident card | Mood sticker (top right) | missing: `sticker-mochi-happy` / `-simit-happy` / `-findik-happy` / `-goat-indignant` -> SF Symbol `face.smiling` / `star.circle` | PofuWorld/Scene/StationSheet.swift:370; PofuDesignSystem/Sticker.swift:11-40,63-70 | sprite-08-resident-card-light.jpg |
| Resident card | "Tezgâha git" button | code shape (`PofuPlaqueStyle`) + text | PofuWorld/Scene/StationSheet.swift:300-381 | sprite-08-resident-card-light.jpg |
| Passes sheet | Seed pill, rows, empty line | `SeedPill` code shape + `SeedIcon`; text | App/Home/PassesSheet.swift:18-55 | none |
| Passes sheet | App icon per pass | SF Symbol per app (`camera`, `play.rectangle`, `music.note`…) on code `Circle` | App/Home/PassesSheet.swift:81-84 | none |
| Passes sheet | "End now" button | code shape (`PofuSecondaryButtonStyle`) + text | App/Home/PassesSheet.swift:99-104 | none |
| Passes sheet | Home entry (ticket button) | SF Symbol `ticket` (old chrome, not drawn: flag off) | App/Home/HomeView.swift:389 | none |
| Earn sheet | Activity chips (Focus, Study, Exercise, Walk, Chores, Creative, Custom) | SF Symbol `scope`, `book`, `dumbbell`, `figure.walk`, `sparkles`, `pencil`, `plus` | App/Earn/EarnSheet.swift:32; App/Support/PofuLines.swift:72-85 | none |
| Earn sheet | Duration chips, start button, preview line | code shape (`PofuChoiceStyle`, `PofuPrimaryButtonStyle`) + text | App/Earn/EarnSheet.swift:45-97 | none |
| Earn focus session | Timer ring, "+N seeds" capsule | code shape (`Circle`, `Capsule`) + text | App/Earn/EarnSheet.swift:112-190 | none |
| Earn focus result | "+N" and lines | text only; `PofuPrimaryButtonStyle` | App/Earn/EarnSheet.swift:229-251 | none |
| Earn (reachability) | Whether the Earn sheet is reachable from `WorldHome` | not found: `homeSheet = .earn` is opened only from the old chrome (`CollectButton`/top bar) in `HomeView`; no `WorldHome.Actions` entry for it was found | App/Home/HomeView.swift:112-119 | none |

## 6. Settings

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Settings | Close button | SF Symbol `xmark` (`PofuSheetChrome`) | App/Support/SheetChrome.swift:26 | 16-menu-settings-light.jpg |
| Settings | Header: Pofu face disc + "Ayarlar" | painted `paint-icon-mood-content` on code `Circle` with dashed stitch | App/Settings/SettingsStyle.swift:92-110 | 16-menu-settings-light.jpg |
| Settings | Pofu name row | SF Symbol `pawprint.fill` in honey rounded square + text field | App/Settings/SettingsView.swift:25-27; App/Settings/SettingsStyle.swift:21-40 | 16-menu-settings-light.jpg |
| Settings | Shield row | painted `paint-duo-shield` (fallback: SF Symbol `hand.raised`) | App/ScreenTime/ScreenTimeSettingsSection.swift:42 | 16-menu-settings-light.jpg |
| Settings | "Allow Screen Time" | SF Symbol `hand.raised` | App/ScreenTime/ScreenTimeSettingsSection.swift:201 | 16-menu-settings-light.jpg |
| Settings | Guarded time, daily hour, readout rows | SF Symbol `hourglass`, `wind`, `list.number` | App/ScreenTime/ScreenTimeSettingsSection.swift:51,64,71 | none |
| Settings | Choose apps | SF Symbol `square.grid.2x2` | App/ScreenTime/ScreenTimeSettingsSection.swift:167 | none |
| Settings | Notification warnings | SF Symbol `bell.slash`, `moon` | App/ScreenTime/ScreenTimeSettingsSection.swift:98,107 | none |
| Settings | Guarded app toggles (Instagram, YouTube, TikTok) | code shape (system `Toggle`) + text | App/Settings/SettingsView.swift:188-207 | 16-menu-settings-light.jpg |
| Settings | "Set up automations" row | SF Symbol `wand.and.stars` | App/Settings/SettingsView.swift:50 | 16-menu-settings-light.jpg |
| Settings | Sounds / ambience / breath haptics toggles | SF Symbol `speaker.wave.2.fill`, `wind`, `waveform.path` | App/Settings/SettingsView.swift:116,127,146 | none |
| Settings | Privacy line, save error | SF Symbol `lock.fill`; `exclamationmark.triangle` | App/Settings/SettingsView.swift:78,80 | none |
| Settings | Rehearsal switch (test-only) | SF Symbol `theatermasks.fill` | App/Settings/SettingsView.swift:170 | none |
| Settings | Developer readout (test-only) | SF Symbol `theatermasks.fill`; code list | App/Settings/DeveloperReadout.swift:44 | none |
| Settings | Sheet background | code shape (`pofuSheetBackground`) | App/Home/HomeView.swift:122-135 | 16-menu-settings-light.jpg |

## 7. Hop (the door), Gate postcard, Breath

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Hop (full screen) | Gate postcard background (6 hours) | painted `gate-postcard-{dawn,day,golden,mist,night,rain}` (App catalog) | App/Hop/GateScene.swift:101-125 (asset name line 22) | 20-gate-1200.jpg |
| Hop | Scrim and glow | code shape (`GateScrim`, `GateGlow` circle) | App/Hop/GateScene.swift:135-190; App/Hop/HopView.swift:294 | 20-gate-0700.jpg |
| Hop | Pofu on the lawn | painted `pofu-hamster.png` via `CompanionView` | App/Hop/HopView.swift:279-316 | 20-gate-1200.jpg |
| Hop | Ellipse contact shadow | code shape | App/Hop/HopView.swift:298 | 20-gate-1200.jpg |
| Hop | "Hop!" title and question | text only (`PofuDisplayFont`) | App/Hop/HopView.swift:134-139 | 20-gate-1200.jpg |
| Hop | App chip ("Instagram · son bir saatte 3. kez") | SF Symbol per app + code capsule | App/Hop/HopView.swift:248-275 | 20-gate-1200.jpg |
| Hop | Primary "Boş ver" / secondary "5 dakikalığına aç" | code shape (`PofuPlaqueButtonStyle` capsule) + text | App/Hop/HopView.swift:206,233,241 | 20-gate-1200.jpg |
| Hop | Reason chips (why do you reach) | code shape + SF Symbol `checkmark` + text | App/Hop/HopView.swift:356-373 | none |
| Hop | Speech bubble line | code shape (`SpeechBubble`) | App/Hop/HopView.swift:160 | none |
| Breath | Breath ring and halo | code shape (`BreathRing`, `Circle`) | PofuDesignSystem/Kit/BreathRing.swift:19-70; App/Hop/BreathScene.swift:98-150 | breath-1-in.jpg |
| Breath | Sky clouds and petals | code shape (`Capsule`, `Path` ellipses `PetalCanvas`) | App/Hop/BreathScene.swift:23-95 | breath-3-out.jpg |
| Breath | Postcard, Pofu | painted `gate-postcard-*`; `pofu-hamster.png` | App/Hop/BreathRoom.swift:116-140 | breath-2-hold.jpg |
| Breath | "Nefes al…" line, "Şimdi değil" and open buttons | text only; `PofuPlaqueStyle(.primary/.quiet)` | App/Hop/BreathRoom.swift:86-214; App/Hop/HopView.swift:319-350 | breath-2-hold.jpg |
| Hop outcome: skipped | "Skipped.", count, bead row | text only; `BeadRow` code circles | App/Hop/HopOutcomes.swift:11-60; PofuDesignSystem/PofuComponents.swift:293 | none |
| Hop outcome: skipped | Swipe-up hint | SF Symbol `chevron.up` + text | App/Hop/HopOutcomes.swift:61-63 | none |
| Hop outcome: skipped | Resist payoff overlay + seed burst | code shape (`ResistPayoffOverlay`, `SeedBurst` capsules); comment: art `reward-seed-burst` not baked | PofuDesignSystem/PofuResistPayoff.swift:165-250; App/Hop/HopOutcomes.swift:71 | payoff-door-day-3.jpg |
| Hop outcome: handoff | App chip, copy, button | SF Symbol per app, code capsule, `PofuPrimaryButtonStyle` | App/Hop/HopOutcomes.swift:106-145 | none |
| Hop outcome: handoff failed | Copy, button | text only | App/Hop/HopOutcomes.swift:170-195 | none |

## 8. Shield, extensions, notifications, intents

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Shield (Apple shield UI) | Icon: Pofu in a round doorway, 6 moods (calm, curious, jealous, proud, relieved, sleepy) | painted `shield-pofu-<mood>.png` | Extensions/Shared/ShieldStyle.swift:135-158 | 19-shield-day.jpg |
| Shield | Icon fallback 1: door plate, 3 moods | painted `shield-pofu-door-{calm,proud,sleepy}.png` (used only if the round icon is absent) | Extensions/Shared/ShieldStyle.swift:160-200 | none |
| Shield | Icon fallback 2: warm-wood door with Pofu in front, z's or star | code shape (`placeholderDoor`), over painted `pofu-hamster.png` | Extensions/Shared/ShieldStyle.swift:220-275 | none |
| Shield | Title, subtitle, primary/secondary buttons, background colour | text only + colours (system `ShieldConfiguration`); palettes day/night | Extensions/ShieldConfiguration/ShieldConfigurationExtension.swift:80-118 | 19-shield-dusk.jpg |
| Shield (frames) | The frames named `19-shield-*` and `06-shield-replica-light` | `ShieldReplicaView` render of the copy (identical bytes, 21586 B each, for `19-shield-day` and `06-shield-replica-light`), not Apple's shield | App/Rehearsal/ShieldReplicaView.swift:13-90 | 19-shield-day.jpg |
| Shield action | Buttons' result (opens notification) | no visual of its own | Extensions/ShieldAction/ShieldActionExtension.swift | none |
| Device activity monitor | none | no visual | Extensions/DeviceActivityMonitor/DeviceActivityMonitorExtension.swift | none |
| Notification "Pofu'yla aç" | Banner | text only (title, body) | Extensions/Shared/GateNotificationContent.swift:11-27 | none |
| Shortcuts / Siri tile | "Hop in" App Shortcut | SF Symbol `hand.raised.fill` | App/Intents/PofuShortcuts.swift:14 | none |
| Live Activities / widgets | none | none exist | n/a | none |

## 9. Minigames

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Garden game | Board backdrop, creature row (3 painted creatures), tray | painted `garden-pofu`, `garden-pofu-puff`, `garden-mochi`, `garden-findik`, `garden-tray`, `garden-soil` (SpriteKit) | PofuGames/Scene/GardenArt.swift:70-130; PofuGames/Scene/GardenScene.swift:23 | 20-garden-midround-light.jpg |
| Garden game | Clay plot tiles (6 colours) | painted `garden-tile-{sage,honey,terracotta,lilac,mint,rose}` (fallback: drawn tile) | PofuGames/Scene/GardenArt.swift:88-110,134 | 20-garden-midround-light.jpg |
| Garden game | Blooms (large, small, front/left/right), combo stamp | painted `garden-bloom`, `garden-bloom-small`, `garden-bloom-front/left/right`, `garden-combo-stamp` | PofuGames/Scene/GardenArt.swift:85-99 | 21-garden-bloom-light.jpg, 22-garden-combo-light.jpg |
| Garden game | Glows, seeds, petals | code shape (Core Graphics textures) | PofuGames/Scene/GardenArt.swift:70-75 | 25-garden-bloom-frames.jpg |
| Garden game | Bed rim | painted `garden-bed-rim.png` exists; no code reference found | PofuGames/Resources/garden-bed-rim.png | none |
| Garden game | Pause button | SF Symbol `pause.fill` on `PaperSurface` circle | PofuGames/UI/GardenGameView.swift:89-96 | 20-garden-midround-light.jpg |
| Garden game | Round plate ("Tur 1 / 5" + dots) | code shape (`RoundPlate`, circles, capsule) + text | PofuGames/UI/GardenGameView.swift:190-235 | 20-garden-midround-light.jpg |
| Garden game | Seed plate ("+2") | `SeedGlyph` code shape + text | PofuGames/UI/GardenGameView.swift:237-259 | 20-garden-midround-light.jpg |
| Garden game | Goal line | text only | PofuGames/UI/GoalLine.swift:6-12 | 20-garden-midround-light.jpg |
| Garden game | Pause panel | code shape (glass rounded rectangle) + text | PofuGames/UI/GardenGameView.swift:261-290 | none |
| Garden game | Round-end / set-end card | code shape (`RoundCard`, `PaperSurface`) + painted bloom images + text | PofuGames/UI/GardenGameView.swift:292-410; PofuGames/UI/GardenCrafted.swift:113 | 23-garden-round-end-light.jpg |
| Garden game | Clay button, paper text button | code shape (`ClayButtonStyle`, `PaperTextButtonStyle`) | PofuGames/UI/GardenCrafted.swift:39-80 | 23-garden-round-end-light.jpg |
| Garden game | "Ayar" tuning pill (test-only) | SF Symbol `slider.horizontal.3` + text, glass capsule | App/Home/GardenPlayView.swift:53-64 | none |
| Flow game (Çağlayan stage rounds) | Stone tiles (straight, bend, split, gate, source, mouth, wheel), rock, grass, water, ghost | code shape (SpriteKit textures drawn in code) | PofuGames/Flow/Scene/FlowArt.swift:5-80; PofuGames/Flow/Scene/FlowScene.swift:36 | 40-flow-stage1-start.jpg |
| Flow game | Painted tile art `flow-tile-*`, `flow-rock`, `flow-grass`, `flow-wheel`, `flow-tile-wheel` | missing: names declared as hooks (`batch-64-flow-pieces`), no file in any bundle | PofuGames/Flow/Scene/FlowArt.swift:19-41,73 | none |
| Flow game | Cliff, bank, pool, drips, puddle | code shape (`SKShapeNode`) | PofuGames/Flow/Scene/FlowScene.swift:206-241,500-536 | 41-flow-stage1-mid.jpg |
| Flow game | Close, undo, hint buttons | SF Symbol `xmark`, `arrow.uturn.backward`, `lightbulb.fill` on `PaperSurface` | PofuGames/Flow/UI/FlowGameView.swift:143,234-236,281 | 40-flow-stage1-start.jpg |
| Flow game | Board counter ("Pano 1 / 2") and target counter ("0/1") | code shape + SF Symbol `drop.fill` / `checkmark.circle.fill` + text | PofuGames/Flow/UI/FlowGameView.swift:169-208 | 40-flow-stage1-start.jpg |
| Flow game | Done card | code shape + text | PofuGames/Flow/UI/FlowGameView.swift:220-226 | 42-flow-stage1-solved.jpg |
| Flow game | Hint text | text only | PofuGames/Flow/UI/FlowGameView.swift:270 | 40-flow-stage1-start.jpg |

## 10. Pofu as drawn (CompanionView)

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Everywhere Pofu is live (Home, Onboarding, Hop, Today bubble) | Body | painted `pofu-hamster.png` | PofuCompanion/CompanionView.swift:297; PofuCompanion/CompanionArt.swift:35 | path-onboarding-welcome.png |
| Same | Lid plate (blink, happy squint) | painted `pofu-hamster-lids.png` | PofuCompanion/CompanionView.swift:328 | life-pofu-moods.jpg |
| Same | Face parts: smirk, open mouth, O mouth, worried mouth, droop ears, wave paws | painted `pofu-part-{mouth-smirk,mouth-open,mouth-o,mouth-worried,ears-droop,paws-wave}.png` | PofuCompanion/Expression/PofuExpression.swift:19-75; PofuCompanion/CompanionView.swift:311 | life-pofu-moods.jpg |
| Same | Cheek puff, blush, lids, lashes | code shape + shader (`FallbackCheek`, `BlushLayer`, `LidShape`, `LashShape`) | PofuCompanion/CompanionView.swift:359-490 | life-pofu-moods.jpg |
| Same | Contact shadow | code shape | PofuCompanion/CompanionView.swift:254 | sprite-02-home-settled-light.jpg |
| Code comment | The base image is named "the bundled placeholder hamster" | `CompanionArt.placeholder` is the only art the rig loads | PofuCompanion/CompanionArt.swift:33-44; PofuCompanion/CompanionRig.swift:59 | none |

## 11. Design-system components (where they are drawn)

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Kit | Primary / quiet / secondary / text buttons | code shape (capsules) | PofuDesignSystem/PofuComponents.swift:8-130 | path-onboarding-welcome.png |
| Kit | Choice chip | code shape (rounded rectangle / capsule) | PofuDesignSystem/PofuComponents.swift:130 | path-onboarding-apps.png |
| Kit | Plaque buttons (`PofuPlaqueStyle`) | code shape; art hooks `ui-plaque-{honey,honey-pressed,bare,cream,cream-pressed}` missing | PofuDesignSystem/Kit/KitPlaque.swift:23-230; PofuDesignSystem/Kit/KitMaterial.swift:18-22 | 20-gate-1200.jpg |
| Kit | Paper surface / sheet / bubble / chip / toast strip / groove | code shape; art hooks `ui-card-stitched`, `ui-card-linen`, `ui-bubble-paper`, `ui-chip-felt[-selected]`, `ui-toast-strip`, `ui-groove-wood`, `ui-sheet-paper-v3[-night]` missing | PofuDesignSystem/Kit/KitComponents.swift; PofuDesignSystem/Kit/KitPaper.swift; PofuDesignSystem/Kit/KitMaterial.swift:23-31 | 15-menu-today-light.jpg |
| Kit | Toast | code shape + optional SF Symbol; only the kit preview presents it (no caller of `pofuToast(`) | PofuDesignSystem/Kit/KitComponents.swift:65-135 | none |
| Kit | Kit sheet (preview catalogue) | no reference from `App/` (`PofuKitSheet`) | PofuDesignSystem/Kit/KitSheet.swift:6 | none |
| Kit | Grain overlay | code shape (generated noise tile) | PofuDesignSystem/Kit/KitMaterial.swift:187 | none |
| Kit | Icon button (`PofuIconButton`) | painted `PofuPaint` when given, else SF Symbol | PofuDesignSystem/PofuSkinViews.swift:170-225 | sprite-01-home-visit-light.jpg |
| Kit | Paper tag / paper strip chrome | code shape (`PaperTag`, `PaperStrip`) | PofuDesignSystem/PofuSkinViews.swift:279-310 | none |
| Kit | Sheet header plate (`PofuHeaderPlate`, `PofuSheetScaffold`) with painted icon | no caller found | PofuDesignSystem/PofuSheet.swift:135-260 | none |
| Kit | `PaintedLabel` (title + painted icon) | no caller found | App/Support/SheetChrome.swift:35-52 | none |
| Kit | Stickers (13 poses of Pofu and residents) | missing: no `sticker-*.png` in any bundle; each draws an SF Symbol | PofuDesignSystem/Sticker.swift:3-40,92-130 | none |

## 12. Empty, loading and error states

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Launch | "Pofu is waking up…" | text only | App/Launch/LaunchCurtain.swift:49 | 21-launch-curtain-and-line.jpg |
| Home | Setup needed bubble ("I haven't heard from your apps…") | text in `SpeechBubble` (old chrome strings, `HomeView.swift:329-348`); world version in `WorldStrings` | App/Home/HomeView.swift:329-348 | none |
| Home | Repair banner | see section 2 | PofuWorld/Home/WorldHome.swift:516 | none |
| Today | "The door's been quiet today." | text only | App/Home/TodaySheet.swift:144 | 15-menu-today-light.jpg |
| Passes | "No passes running. Every app is guarded." | text only | App/Home/PassesSheet.swift:29 | none |
| Station | "No rounds left today.", "Building opens soon." | text only | PofuWorld/Scene/StationSheet.swift:255,309 | none |
| Invite | Empty invitation list | text only | PofuWorld/Scene/InviteSheet.swift:24 | none |
| Hop | Handoff failed | text only | App/Hop/HopOutcomes.swift:170-195 | none |
| Settings | Save error | SF Symbol `exclamationmark.triangle` + text | App/Settings/SettingsView.swift:80 | none |
| Setup | "Not working yet" | SF Symbol `circle.dashed` + text | App/Setup/SetupGuideView.swift:237-239 | none |
| Screen Time | Notifications off | SF Symbol `bell.slash` + text | App/ScreenTime/ScreenTimeSettingsSection.swift:98 | none |
| Garden | Pause panel / "enough for today" | text only | PofuGames/UI/GardenGameView.swift:261-290 | none |

## 13. Rehearsal mode (test-only; `Settings` > Developer switch, `App/Rehearsal/`)

| Screen | Element | Drawn with | File:line | Frame |
|---|---|---|---|---|
| Rehearsal | Prova panel (collapsed pill, expanded card) | SF Symbol `theatermasks.fill`, `chevron.up.circle.fill`, `gauge.with.dots.needle.33percent`; glass shapes | App/Rehearsal/RehearsalPanel.swift:47-210 | 07-prova-panel-light.jpg |
| Rehearsal | Per-app reach buttons | SF Symbol per app (`camera`, `play.rectangle`, `music.note`) | App/Rehearsal/RehearsalPanel.swift:80 | 07-prova-panel-light.jpg |
| Rehearsal | Shield replica (Pofu round icon + copy + buttons) | painted `shield-pofu-<mood>` image via `ShieldIconImage`; text; code rounded rectangle | App/Rehearsal/ShieldReplicaView.swift:13-90 | 06-shield-replica-light.jpg |
| Rehearsal | "Prova: gerçek cihazda Apple'ın ekranı" badge | SF Symbol `theatermasks.fill` + text on material capsule | App/Rehearsal/ShieldReplicaView.swift:157-175 | 06-shield-replica-light.jpg |
| Rehearsal | Stand-in guarded app screen (feed stand-in, hourglass, time) | SF Symbol per app, `hourglass`; code rounded rectangle | App/Rehearsal/RehearsalAppView.swift:44-80 | none |
| Rehearsal | Permission alert stand-in | code shape (regular material) + text | App/Rehearsal/RehearsalSystemMocks.swift:9-60 | none |
| Rehearsal | App picker stand-in (categories, ticks) | SF Symbol `bubble.left.and.bubble.right.fill`, `popcorn.fill`, `chevron.right/down`, `checkmark.circle.fill`, `circle` | App/Rehearsal/RehearsalSystemMocks.swift:65-170; App/Rehearsal/RehearsalCatalog.swift:35 | none |
| Rehearsal | Tuning lab panel | SF Symbol `slider.horizontal.3`, `square.and.arrow.up`, `arrow.counterclockwise`, `xmark.circle.fill`, `arrow.uturn.backward.circle`, section symbols `paintpalette`, `camera`, `square.3.layers.3d`, `pawprint`, `hand.tap`, `speaker.wave.2`, `leaf`, `square.grid.3x3`, `house`; sliders, toggles | App/Rehearsal/TuningLab/TuningLabPanel.swift:35-525 | 08-tuning-lab-panel-light.jpg |
| Rehearsal | Frame meter | code shape + text | App/Rehearsal/RehearsalFrameMeter.swift:9 | none |

## 14. SF Symbols used (name: where)

`camera`: AppPresentation.swift:35 (Instagram), TuningLabPanel.swift:518. `play.rectangle`: AppPresentation.swift:36 (YouTube). `music.note`: AppPresentation.swift:37 (TikTok). `text.bubble`, `bolt.horizontal.circle`, `bubble.left.and.bubble.right`, `person.2`, `app`: AppPresentation.swift:38-42 (X, Snapchat, Reddit, Facebook, other). `scope`, `book`, `dumbbell`, `figure.walk`, `sparkles`, `pencil`, `plus`: PofuLines.swift:72-85 (Earn kinds). `gearshape`: WorldHome.swift:223,535; HomeView.swift:226 (fallback). `ticket`: HomeView.swift:389,431 (flag off). `leaf`: HomeView.swift:453 (flag off), TuningLabPanel.swift:523. `leaf.fill`: TodaySheet.swift:259; PofuDoorStamp.swift:120; HomeFeedbackViews.swift:105; KitSheet.swift:59. `drop.fill`: HomeFeedbackViews.swift:105; FlowGameView.swift:196. `heart.fill`: HomeFeedbackViews.swift:69. `chevron.up`: HomeObjectViews.swift:620; HopOutcomes.swift:61. `exclamationmark.shield.fill`: WorldHome.swift:522. `xmark`: SheetChrome.swift:26; StationSheet.swift:180; PofuSheet.swift:196; FlowGameView.swift:143; SetupGuideView.swift:411. `pawprint.fill`: SettingsView.swift:25; IslandScene.swift:2125,2372. `pawprint`: TuningLabPanel.swift:520. `lock.fill`: SettingsView.swift:78; IslandScene.swift:2380. `paperplane`: InviteSheet.swift:48. `sparkle`: CelebrationCard.swift:49. `plus`: IslandScene.swift:1852; SetupGuideView.swift:433. `pause.fill`: GardenGameView.swift:89. `arrow.uturn.backward`, `lightbulb.fill`: FlowGameView.swift:234-236. `checkmark.circle.fill`: OnboardingView.swift:335; SetupGuideView.swift:211; RehearsalSystemMocks.swift:165; FlowGameView.swift:196. `circle`: RehearsalSystemMocks.swift:165; SetupGuideView.swift:604. `checkmark`: HopView.swift:370; SetupGuideView.swift:469,621. `checkmark.seal.fill`, `circle.dashed`: SetupGuideView.swift:231,239. `exclamationmark.circle`: SetupGuideView.swift:337; Sticker.swift:33. `exclamationmark.triangle`: SettingsView.swift:80. `bell.badge`: OnboardingView.swift:188. `bell.slash`, `moon`, `hourglass`, `list.number`, `square.grid.2x2`, `hand.raised`: ScreenTimeSettingsSection.swift:51-201 (`hourglass` also RehearsalAppView.swift:65). `hand.raised.fill`: PofuShortcuts.swift:14. `eye.slash`, `switch.2`, `chevron.right.circle`: ScreenTimeSetupView.swift:126-144. `wand.and.stars`, `speaker.wave.2.fill`, `wind`, `waveform.path`, `theatermasks.fill`: SettingsView.swift:50,116,127,146,170 (`theatermasks.fill` also ShieldReplicaView.swift:162, RehearsalPanel.swift:63,155, DeveloperReadout.swift:44). `slider.horizontal.3`: GardenPlayView.swift:55; TuningLabPanel.swift:54. `chevron.right`, `chevron.down`: SetupGuideView.swift:590; RehearsalSystemMocks.swift:135. `magnifyingglass`, `hare`, `square.stack`, `checkmark.circle`, `clock`, `alarm`, `envelope`, `plus.square.dashed`: SetupGuideView.swift:408-523. `gauge.with.dots.needle.33percent`, `chevron.up.circle.fill`: RehearsalPanel.swift:123,175. `square.and.arrow.up`, `arrow.counterclockwise`, `xmark.circle.fill`, `arrow.uturn.backward.circle`, `paintpalette`, `square.3.layers.3d`, `hand.tap`, `speaker.wave.2`, `square.grid.3x3`, `house`: TuningLabPanel.swift:69-525. `popcorn.fill`, `bubble.left.and.bubble.right.fill`: RehearsalCatalog.swift:35. Sticker fallbacks (only drawn, since no sticker file exists): `face.smiling`, `moon.zzz`, `exclamationmark.circle`, `star.circle`, `hand.wave`, `cup.and.saucer`, `ellipsis.bubble`, `cloud`: Sticker.swift:31-38.

## 15. Characters: painted poses and expressions

Counts of imagesets are in `World.xcassets` (each sprite also has `__soft`, `__deep` and `-shadow` imagesets; counted once). Pose names come from `ResidentPose`, `SimitPose`, `GoatPose`.

| Character | Painted assets that exist | Poses / expressions in code with no asset | File:line |
|---|---|---|---|
| Pofu (hamster, protagonist) | Live rig: `pofu-hamster.png`, `pofu-hamster-lids.png`, 6 face parts (`mouth-smirk`, `mouth-open`, `mouth-o`, `mouth-worried`, `ears-droop`, `paws-wave`); moods in code: calm, happy, sleepy, proud, curious, worried, relieved (7). World sprite `world-pofu` (+ normal map). Garden: `garden-pofu`, `garden-pofu-puff`. Shield: `shield-pofu-{calm,curious,jealous,proud,relieved,sleepy}` (6) + `shield-pofu-door-{calm,proud,sleepy}` (3). Face disc `paint-icon-mood-content`. | 6 stickers (`sticker-pofu-{happy,sleepy,surprised,proud,waving,tea}`); no sad/guilty mood by design (comment ADR-0017) | PofuCompanion/Expression/PofuExpression.swift:9-75; PofuDesignSystem/Sticker.swift:11-16 |
| Mochi (tea stall resident) | `world-mochi` base + poses `work`, `surprised`, `eyes-happy`, `eyes-closed`, `happy`, `sleepy`, `proud`, `step-a`, `step-b`, `work-beat` (+ normal maps); `garden-mochi` | `sticker-mochi-{happy,thinking,sulky}` (3); `door-mochi` sprite | PofuWorld/Layout/ResidentPose.swift:7-28; PofuWorld/Layout/HomeFixtures.swift |
| Fındık (workshop resident) | `world-findik` + `eyes-closed`, `eyes-happy`, `happy`, `proud`, `sleepy`, `surprised`, `work` (+ normal maps); `garden-findik` | poses `step-a`, `step-b`, `work-beat` (named in `ResidentPose`, no imageset); `sticker-findik-happy`; `door-findik` sprite | PofuWorld/Layout/ResidentPose.swift:7-28 |
| Simit (kitten, bagel cart) | `world-simit-kitten`, `-work`, `-ears`, `simit-happy`, `-sleepy`, `-surprised`, `-proud`, `simit-step-b` | `sticker-simit-happy`; `simit-step-b` exists with no case in `SimitPose` | PofuWorld/Layout/HarborCast.swift:15-30 |
| Goat (pier) | `world-harbor-goat`, `goat-work`, `-happy`, `-surprised`, `-sleepy`, `-proud`, plus `goat-step-a`, `goat-step-b`, `goat-work-beat` (these three have no case in `GoatPose`) | `sticker-goat-indignant` | PofuWorld/Layout/HarborCast.swift:54-67 |
| Koke (island creature) | `world-koke-{asleep,one-eye,stretch,stone}`, `world-koke-island-0..4` | `standing` pose (`world-koke-standing`) | PofuWorld/Koke/KokeLayout.swift:152-176 |
| Damla (Çağlayan) | `world-damla`, `world-damla-glass`, `world-visitor-damla` | no pose set; no sticker | PofuWorld/Caglayan/CaglayanLayout.swift:139 |
| Nazlı (Gezgin island) | `world-nazli-{body,eyes-closed,fins,island-patch,tail}` (5 parts) | no code reference found to any of them (code has only `nazliPoolHook = "nazli-pool"`) | PofuCore/Game (`nazli-pool` hook) |
| Gezgin (visitor) | `world-visitor-gezgin`, `world-far-isle-3` | none | PofuWorld/Scene/LifeViews.swift:185 |
| Visitor (generic) | gift parcel (`gift-parcel-closed`), letter envelope (`guest-letter-envelope`) | visitor figure `visitor-dandelion`, "help" item | PofuWorld/Layout/VisitorStage.swift:17-25 |
| Critters | butterfly (4), snail (3), bird (4) | frog, ladybug | PofuWorld/Layout/Critters.swift:7 |
| Whale (sky) | `world-home-sky-whale-<light>` + fx masks | none | PofuWorld/Sky/SkySetView.swift |

## 16. Image assets not referenced by code (unused)

Checked by searching the full source of `App/`, `Extensions/` and `Packages/` for each name or the pattern that builds it. Names built at runtime (`world-<station>-<level>`, `world-<island>-plate-<light>-<stage>`, `world-lut-*`, sky layers from skyset JSON) were matched by their pattern, not traced one by one.

- **No code reference found, exists in a catalog:**
  - `world-isle-hamam-standin`, `world-isle-harbor-standin`, `world-isle-library-standin`, `world-isle-stars-standin` (World.xcassets, 3 imagesets each).
  - `world-nazli-body`, `-eyes-closed`, `-fins`, `-island-patch`, `-tail` (4 imagesets each).
  - `world-goat-step-a`, `world-goat-step-b`, `world-goat-work-beat` (4 each), `world-simit-step-b` (4): `GoatPose`/`SimitPose` have no case for them.
  - `garden-bed-rim.png` (PofuGames/Resources).
- **Alternate "art set" variants that load only when the developer look switch selects them** (`ArtSet` is `lockLight` by default; `softLock`, `unharmonized`, `round2Copper`, `plateV2`): `world-tea-stall-1--softlock`, `--round2`, `world-tea-stall-3--unharmonized`, `world-windmill-4--unharmonized`, `world-island-main-band{0..3}--unharmonized`, `--v2` (PofuWorld/Scene/WorldLookLayers.swift ArtSet, lines near the `suffix` switch; `PofuWorld/Look/WorldLook.swift`).
- **Painted menu art in `PofuDesignSystem/Resources` with no case-name reference outside the `PofuPaint` enum (20 of 30):** `paint-jar-full`, `paint-lantern-on`, `paint-pot-bloom`, `paint-pot-bud`, `paint-face-disc`, `paint-tag-paper`, `paint-icon-calm`, `paint-icon-island`, `paint-icon-friend`, `paint-icon-skip`, `paint-icon-round`, `paint-icon-breath`, `paint-icon-rumour`, `paint-icon-decor`, `paint-icon-plus`, `paint-icon-tea`, `paint-duo-close`, `paint-duo-add`, `paint-duo-letter`, `paint-duo-gift` (PofuDesignSystem/PofuPaint.swift:9-37). The 10 referenced: `duo-home`, `duo-island`, `duo-map`, `duo-settings`, `duo-shield`, `icon-seed`, `icon-mood-content`, `face-primary`, `face-secondary`, `panel-paper`.
- **Shield door plates:** `shield-pofu-door-{calm,proud,sleepy}.png` load only when `shield-pofu-<mood>.png` is absent (Extensions/Shared/ShieldStyle.swift:171-200). Both sets are in the extension's resources (project.yml:184-204).
- **Not in any catalog but named by code (the opposite case, listed in "missing" rows):** `sticker-*` (13), `ui-plaque-*` (5), `ui-sheet-paper-v3[-night]`, `ui-card-stitched`, `ui-card-linen`, `ui-bubble-paper`, `ui-chip-felt[-selected]`, `ui-toast-strip`, `ui-groove-wood`, `seal-resist`, `material-moss`, `world-koke-standing`, `door-mochi`, `door-findik`, `critter-frog`, `critter-ladybug`, `visitor-dandelion`, `growth-*` (15 pieces), `flow-tile-*`/`flow-rock`/`flow-grass`/`flow-wheel`, `SetupStep-*` screenshots, `world-lut-plate-<island>-<light>`, `world-<island>-{diff,emit,up}-*` plate layers (PofuWorld/Plate/PlateIsland.swift:199-211).

## 17. Places where code draws a stand-in for missing or optional art

| Where | What is drawn | File:line |
|---|---|---|
| Launch | Code dawn sky and code cloud banks "until the Codex plates exist" (plates now exist) | App/Launch/LaunchCurtain.swift:16-17,113,137 |
| Shield | Code-drawn door with Pofu in front, "the stand-in for `shield-pofu-door-<mood>`" | Extensions/Shared/ShieldStyle.swift:183,220 |
| Setup guide | `ShortcutsSchematic` instead of per-step screenshots | App/Setup/SetupGuideView.swift:362-379 |
| Today sheet | Code `IslandStrip` below the painting's lowest level; "code-drawn until batch-60's `seal-resist`" for wax seals | App/Home/TodaySheet.swift:99,229 |
| Today sheet | Comment: Pofu's "stand-in was a teacup" | App/Home/TodaySheet.swift:45 |
| Stickers | SF Symbol for every sticker until files land | PofuDesignSystem/Sticker.swift:7,28 |
| Kit | "All code-drawn; each has an art hook in `PofuKitArt`" | PofuDesignSystem/Kit/KitComponents.swift:5; Kit/KitMaterial.swift:16 |
| Kit plaque | "Code-drawn until `ui-plaque-*` lands" | PofuDesignSystem/Kit/KitPlaque.swift:115 |
| Skin | "Crafted faces are clean vector stand-ins until the painted 9-slice" | PofuDesignSystem/PofuSkinViews.swift:7,27 |
| Resist payoff | Code overlay and seed burst "until the Codex art is baked" (`reward-seed-burst`) | PofuDesignSystem/PofuResistPayoff.swift:165,233 |
| Pot (station pips) | "Drawn in code until the batch-61 `ui-pip-pot` art" | PofuWorld/Scene/PotPips.swift:5 |
| Home jar / lantern / pots | Vector stand-in "when its switch in `HomeArt` is"; cheek paws "stand-in, with a switch when it lands" | PofuWorld/Home/HomeObjectViews.swift:9-13,561 |
| Life pieces | Code-drawn dressing, critters, visitor, gift parcel, guest letter | PofuWorld/Scene/LifeArt.swift:5-12; PofuWorld/Scene/LifeViews.swift:11,127 |
| Growth | Code-drawn path stone, flag, gull, steam, bridge, lily, reeds, dragonfly, terrace, lanterns, gate, hilltop "the Codex queue has not painted" | PofuWorld/Scene/GrowthArt.swift:39-41; PofuWorld/Layout/IslandGrowth.swift:6 |
| Station level art | `isStandIn` flag: a station wears a lower level's art with a badge; labelled placeholder when none | PofuWorld/Layout/IslandLayout.swift:83-117; PofuWorld/Scene/IslandScene.swift:1764-1798; PofuWorld/Layout/IslandFraming.swift:79-81 |
| Koke | Code placeholder island and far hump "for a stage without art"; `material-moss` placeholder | PofuWorld/Koke/KokeLayout.swift:55,72; PofuWorld/Koke/KokeScene.swift:8-9,134,202,314,510 |
| Çağlayan | Soft placeholder island if plates absent; code falls and ripples | PofuWorld/Caglayan/CaglayanScene.swift:247,352,427 |
| Far sky | Emanet, Mehtap, Revontuli: "art pending" | PofuWorld/Sky/FarSkyLayout.swift:125-129 |
| Weather | Code-drawn rain/puddle/rainbow "the painted art replaces them by name" | PofuWorld/Scene/WeatherLayer.swift:84,108 |
| Fog | Code-drawn card if the catalog lacks the painted one | PofuWorld/Scene/FogCards.swift:14-17 |
| Shadows | Code contact ellipses until the art has a silhouette | PofuWorld/Scene/ShadowBake.swift:224-225 |
| Garden game | "Drawn stand-ins" for clay buttons and tiles when the painted PNG is missing (all garden PNGs but `bed-rim` exist) | PofuGames/UI/GardenCrafted.swift:6; PofuGames/Scene/GardenArt.swift:108-124 |
| Flow game | "Code-drawn stand-ins until `batch-64-flow-pieces` lands" | PofuGames/Flow/Scene/FlowArt.swift:5-8 |
| Pofu | `CompanionArt.placeholder` is the name of the loaded hamster | PofuCompanion/CompanionArt.swift:33-44 |
| Harbor | Simit rule: "a placeholder rule until the harbor has its own beats" (behaviour, not art) | PofuWorld/Layout/HarborCast.swift:36 |
| Rehearsal | Stand-ins for Apple's permission alert, app picker, guarded app (test-only) | App/Rehearsal/RehearsalSystemMocks.swift:9,65; App/Rehearsal/RehearsalAppView.swift |
| Plates | JSON field `standIn` marks "a concept standing in for the island's real plate" | PofuWorld/Plate/PlateIsland.swift:124-125,265 |
| Sound (out of scope) | `GameSound` silence stand-in | PofuGames/Feel/GameSound.swift:31 |

## 18. Asset catalogs at a glance

- `App/Resources/Assets.xcassets`: `AppIcon` (3), `cloud-curtain-1..3`, `gate-postcard-{dawn,day,golden,mist,night,rain}`, `launch-sky`, colour sets (not counted).
- `Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets`: 1,027 imagesets in total across the repo (`Contents.json` count), 240 families after stripping light, stage and variant suffixes; 178 baked sprites in the generated table (`WorldArt+Generated.swift:7-17`), each with `__soft`, `__deep`, `-shadow` imagesets.
- Loose PNG resources: `PofuCompanion/Resources` (17), `PofuDesignSystem/Resources` (30), `PofuGames/Resources` (19 PNG + `flow-boards.json`), `PofuWorld/Resources/Plates` (5 JSON).

## 19. Counts (rows, by first word of the Drawn-with cell)

Rows per section: 1 Launch and onboarding 26; 2 Home 59; 3 Visitors 11; 4 Map and islands 23; 5 Sheets 25; 6 Settings 15; 7 Hop and Breath 18; 8 Shield and extensions 10; 9 Minigames 20; 10 Pofu 6; 11 Design system 12; 12 Empty/error 11; 13 Rehearsal 9. Total 245 (sections 12 repeats some rows from earlier sections).

By kind: code shape 82, painted 70, SF Symbol 41, text only 24, other/mixed 18 (system UI, "no art needed", "none exist", symbol+shape rows whose first word is not a kind), missing 10, emoji 0.
