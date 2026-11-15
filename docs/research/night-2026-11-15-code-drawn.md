# Code-drawn visuals: inventory at origin/main 83e2e394 (2026-11-15)

Method: read the code at that commit (worktree /tmp/claude-0/scout-code-drawn/wt), checked 6 player-path frames
(path-game-flow-stage1, path-d05-0900, others fetched to /tmp/claude-0/scout-code-drawn/frames), and used
docs/research/asset-inventory-2026-11-14.md as a lead only. Paths below are under
`Packages/PofuKit/Sources/` (shortened `PK/`) unless they start with `App/` or `Extensions/`.
Sizes: tiny (< ~40 pt), medium, hero (fills a good part of the screen).
"Painted exists" = a file in `design/art/**` (pofu) or a batch named in pofu docs; "shipped" = in an app/package resource catalog.

Three facts that shape the whole list:
- Default skin is `.glass` (PK/PofuDesignSystem/PofuSkin.swift:44, PofuSkinEnvironment.swift:8). Every "painted chrome" path
  (`paintsChrome`) is off by default, so the code-drawn seed, bubble, plaque, panel are what shows.
- Home/Map/Koke/Caglayan use the painted plate when one resolves (PK/PofuWorld/Plate/HomePlate.swift:140; Home plate paints
  levels 1 to 10, design/art/plates/home/objects.json stageLevels). When a plate is on, the sprite-island code art (dressing,
  growth, critters, wax seals, jar/lantern/pots, CloudSea, fog, haze, vignette) is NOT drawn (IslandScene.swift:1126, 1197, 777, 880).
  Those rows are marked "fallback only".
- Doc wrong: asset-inventory-2026-11-14 §9 says no `flow-*` file is in any bundle; PK/PofuGames/Resources now has
  flow-stone, flow-stone-2, flow-pool, flow-grass, flow-rock. Doc wrong: now.md "rain streaks drawn in code":
  `world-rain-tile` is shipped (World.xcassets) and WeatherLayer.swift:94 loads it first.

## 1. Flow board (Caglayan rounds) - frame path-game-flow-stage1 confirms

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Grass cell (pale green square, three "v" blades) | PK/PofuGames/Flow/Scene/FlowArt.swift:460 `drawGrass`; off-switch :67 `paintsBankTiles = false` | Core Graphics fill + strokes | Yes, shipped but switched off: PK/PofuGames/Resources/flow-grass.png (batch-64-flow-pieces `flow-grass`, `flow-grass-2`); master design/art/ui/ui-flow-grass | medium (a cell, up to ~5 per board) |
| Rock cell (grey ellipse with a highlight) | FlowArt.swift:478 `drawRock`; :104 gate | CG ellipses | Yes, shipped but switched off: flow-rock.png (batch-64 `flow-rock`; ui-flow-rock-2) | medium (up to ~5 per board) |
| Source tile (blue water ball in green ring) and mouth tile (brown ring) | FlowArt.swift:302, :391, :434 | CG circles over the painted stone | Master only: design/art/ui/ui-flow-tile-source, ui-flow-tile-mouth, ui-flow-tile-straight (not shipped; `flow-tile-*` hooks FlowArt.swift:83-92) | medium |
| Carved channel in each stone (brown groove, bends, splits) | FlowArt.swift:235 `channelPath`, :319 `paintedStone` | Code carves a groove into painted `flow-stone` (by design: data-shaped) | Stone shipped (flow-stone.png, flow-stone-2.png); groove stays code | medium |
| Water fill in the channel (blue stream, highlight, ripple ellipse at the edge) | FlowArt.swift:417 `drawWater`; FlowScene.swift:325 | CG paths | none | medium |
| Mill wheel tile and spinning wheel (later stages) | FlowArt.swift:62 `wheelArt`, :162 `wheel(blurred:)` | CG drawing, rotated by code | Master design/art/masters/flow-wheel (not shipped); `flow-tile-wheel` hook :61 | medium |
| Gate board (later stages) | FlowArt.swift:187 `gateBoard` | CG drawing | none found | medium |
| Hint ghost channel and ring | FlowArt.swift:135 `ghost`, :152 `ring` | CG strokes | none | tiny |
| Sky behind the board (cream to blue gradient and glow) | FlowScene.swift:178 `backdropTexture` (:186, :192) | CG linear and radial gradient | Partial: design/art/masters/x-caglayan-flow-4, x-home-flow-final-rich (concept frames, not shipped); batch-64 `flow-frame-caglayan` | hero (whole screen) |
| Cliff lip with green moss strip above the board; bank behind tiles | FlowScene.swift:206, :212-215, :221 | `SKShapeNode` rounded rects | batch-64 `flow-frame-caglayan` (takes dir); not shipped | hero-ish (board frame, always on screen) |
| Pool under the board | painted: FlowScene.swift:256 (`flow-pool.png`); code fallback :274 `drawnPool` | painted in use; code only if PNG missing | Shipped | medium |
| Spill, drips, puddle, splash drops on solve | FlowScene.swift:500-536, :565 | `SKShapeNode` circles and ellipses | batch-64 `flow-dribble-1..4` (design/art/takes/batch-64-flow-pieces); not shipped | tiny |
| Close X, undo arrow, hint bulb (SF Symbols on paper discs) | PK/PofuGames/Flow/UI/FlowGameView.swift:143, :234-236, :281 | SF Symbol + `PaperSurface` circle | duo sheet `paint-duo-*` has close (`paint-duo-close.png`); hint/undo none | tiny |
| "Pano 1/2" pill with progress dots; "0/1" counter with drop | FlowGameView.swift:169-208 | Circle/Capsule + SF Symbol `drop.fill`, `checkmark.circle.fill` | none | tiny |

## 2. Garden game (match game)

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Bed behind the board (clay rim, sunken soil floor) | PK/PofuGames/Scene/GardenArt.swift:211 `bed(size:padding:)`, used GardenScene.swift:173 | CG rounded rect, shadows | Yes: PK/PofuGames/Resources/garden-bed-rim.png shipped but no code references it (grep: 0 hits); master ui-game-bed-rim | hero (the board) |
| Sky/backdrop (cream to honey gradient, sun glow, vignette) | GardenArt.swift:351; GardenScene.swift:168 | CG gradients | none | hero |
| Empty-cell soil mound (fallback only when `garden-soil` missing) | GardenArt.swift:184-186 | CG | garden-soil.png shipped (in use) | medium |
| Line-about-to-bloom glow; lifted-tile drop shadow; resident ground shadow | GardenArt.swift:376, :393, :404; GardenScene.swift:192 | CG radial gradients | none | medium |
| Flying seed, petals, sparkle, soil crumb, cheek blush | GardenArt.swift:419, :449, :461, :479, :489; GardenScene.swift:592, :607, :628 | CG-drawn textures | `design/art/ui/icon-game-seed`, `paint-icon-seed.png` (seed only) | tiny |
| Round plate ("Tur 1/5" and dots), seed plate "+2", pause panel | PK/PofuGames/UI/GardenGameView.swift:190-235, :237-259 (`SeedGlyph` :242, :317), :261-290 | Circle/Capsule + code `SeedGlyph` shape | `paint-icon-seed.png` | tiny to medium |
| Pause button (SF `pause.fill`) | GardenGameView.swift:89 | SF Symbol | none | tiny |
| Clay and paper buttons, round-end card | PK/PofuGames/UI/GardenCrafted.swift:39-113 | Shapes, gradients | `ui-face-primary`, `ui-card-stitched` masters (not shipped as used) | medium |
| Piece shapes (the 6 tile families' silhouettes) | PK/PofuGames/Core/PieceShape.swift (Path logic); tiles themselves painted `garden-tile-*` | tiles painted | Shipped | n/a (painted) |

## 3. Home (plate path; frame path-d05-0900)

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Pofu's line card ("Pofu / Konusamiyorum...") | PK/PofuWorld/Home/WorldHome.swift:614 `PlateLine`, :596-611 surface; glass branch :176-181 `SpeechBubble` (PK/PofuDesignSystem/PofuComponents.swift:246) | RoundedRect fill + `BubbleShape`; painted `PofuPaperBubble` only when `paintsChrome` | ui-bubble-paper, ui-bubble-tail shipped in PofuDesignSystem/Resources (used only in crafted skin) | hero-ish (full-width card, every open) |
| "Topla . 26" honey capsule with flat dark seed | PK/PofuWorld/Home/HomeObjectViews.swift:269 `CollectAction`, seed :293-300 (`SeedGlyph` Shape PofuComponents.swift:163) | Capsule + `SeedGlyph` path (painted seed only if `paintsChrome`) | paint-icon-seed.png, ui-plaque-honey.png shipped; design/art/ui/ui-plaque-honey | medium |
| "Bugun sessiz . 0 dk" today glance pill, grey bead capsules, chevron | HomeObjectViews.swift:629 `HomeGlance`; WorldHome.swift:565 `GuardedSteps`; `chevron.up` HomeObjectViews.swift:660 | Capsules, SF Symbol | ui-card-linen shipped (crafted only); ui-pip-pot master | medium |
| Daily-line pill | WorldHome.swift:305, :39 `DailyLineSurface` | RoundedRect | ui-card-linen | medium |
| Gear disc (top right, blue glass) | WorldHome.swift:242, :556; PK/PofuDesignSystem/PofuSkinViews.swift:156-235 | Painted `paint-duo-settings` glyph on `.glassEffect` circle | Glyph painted (shipped); disc is glass (allowed) | tiny |
| Place control (bottom right: island silhouette, map glyph, face crop) | PK/PofuWorld/Scene/PlaceControl.swift:140-190 `IslandSilhouette`, `ArchipelagoGlyph` | Canvas paths; face crop of pofu-hamster.png | Painted duo shipped: paint-duo-island/map/home.png (used when available) | tiny |
| Seed-count pill (when shown) | PofuComponents.swift:222 `SeedPill`; seed icon :188 | Capsule; painted seed if `PofuPaint.iconSeed` available else `SeedGlyph` | paint-icon-seed.png shipped | tiny |
| Contact shadows under Pofu/residents/visitors | PK/PofuWorld/Scene/DepthImage.swift:117; PlateHomeViews.swift:319; CompanionView.swift:254 | Squashed radial gradient | baked `world-*-shadow` imagesets (sprites only) | tiny |
| Pofu's blush, lash line, lids, halo glow behind him | PK/PofuCompanion/CompanionView.swift:266, :401, :429, :468; App/Home/HomeView.swift:305 (`Circle` halo, old chrome) | Ellipse/RadialGradient/Shape over painted body | Body, lids, parts painted (pofu-hamster.png, pofu-hamster-lids.png, pofu-part-*) | tiny to medium |
| Build moment dust puffs, sparkles, level badge, ground pad | PK/PofuWorld/Scene/BuildEffects.swift:6-235 (`LevelBadge` :76); IslandScene.swift:1664 `PlateBuildBloom` | Circle/Path/gradient particles | glow-ground-pool shipped; no painted dust/sparkle found | medium (every build) |
| Island grow bloom, "Ada buyudu" card, ribbon, sparkle | PK/PofuWorld/Scene/IslandGrowViews.swift:8-66; CelebrationCard.swift:9-150 (`sparkle` :49) | Radial bloom, paper card Shape, `Ribbon` path, SF `sparkle` | ui-pin-ribbon, ui-card-stitched, ui-swash masters (not shipped) | hero (level-up moment) |
| Rain streaks over the plate | WeatherLayer.swift:148, :226 | Painted tile `world-rain-tile`, scrolled and drawn in Canvas; code tile :117 only as fallback | Shipped (batch-44-weather-fx) | hero (rainy days) |
| Greeting heart bubble over a visitor; gift tag (leaf/drop) | PK/PofuWorld/Scene/HomeFeedbackViews.swift:56-120 | SF `heart.fill`, `leaf.fill`, `drop.fill` in tailed bubble | none | tiny |
| Far-bell note light and rings (days 17-21) | PK/PofuWorld/Plate/FarBellSky.swift (`FarBellSkyLayer`) | Radial gradients/rings over the plate | none | medium |
| Cloud-shadow drift, sun-shadow bake | PK/PofuWorld/Moments/CloudShadows.swift; Scene/ShadowBake.swift | Code shapes/offscreen image | baked sprite shadows only | hero (large, faint) |
| Fireflies, window spill, lamp pools | PK/PofuWorld/Scene/WorldLookLayers.swift:625-749 | Painted sprites (firefly-1..3, glow-*), code placement | Shipped | tiny |

### Home fallback only (sprite island, below plate level 1 or `homePlates` off; not on player path now)
| Thing | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Grass tuft, wildflowers, pebbles, mushroom ring, watering can, seed sack, twine, crate, trowel, rope, barrel | PK/PofuWorld/Scene/LifeArt.swift:44-146; LifeViews.swift:14 | Canvas shapes | Shipped `world-dressing-*` (all 11) | tiny |
| Frog, ladybug critters (no sprite); butterfly/snail/bird fall back too | LifeArt.swift:158-210; Layout/Critters.swift:81-82 | Canvas | Butterfly/snail/bird shipped; frog and ladybug: not found anywhere | tiny |
| 14 growth pieces: path stone, flag pole, gull, steam, rope bridge, lily pad, reeds, dragonfly, terrace, lantern string, gate, hilltop, hill/stepping stone | PK/PofuWorld/Scene/GrowthArt.swift:47-382; Layout/IslandGrowth.swift:41 (names `growth-*`) | Canvas paths | none shipped (no `growth-*` imageset); batch-57-home-growth-strip exists in design/art/takes (not verified as these pieces) | medium (bridge 100x46, terrace 220x50, lantern string 200x76 world units) |
| Visitors without a sprite (7 of 9 residents), dandelion, help kite, parcel, letter | LifeArt.swift:219-318; LifeViews.swift:128-205 | Canvas | Shipped only: world-visitor-damla, world-visitor-gezgin, gift-parcel-closed, guest-letter-envelope; on the plate path an unpainted visitor draws nothing (IslandScene.swift:1777) | tiny |
| Jar contents (heap, wavy top), calm lantern glow, pot bloom/bud, pot badge, cheek paws | PK/PofuWorld/Home/HomeObjectViews.swift:80-165, :318-355, :494-583; `paintedPaws = false` :23 | Gradients, capsules, ellipses over painted jar/lantern/pot | paint-jar-full, paint-lantern-on, paint-pot-bloom, paint-pot-bud shipped (crafted only) | medium |
| Build spot (dashed ellipse and plus), labelled placeholder box | IslandScene.swift:1866, :1884 | Ellipse, RoundedRect, SF `plus` | none | tiny |
| Wax seals on the earth face | PK/PofuWorld/Scene/ResistSeals.swift; PK/PofuDesignSystem/PofuDoorStamp.swift:104-125 | Circles + SF `leaf.fill` | design/art/ui/ui-seals master; batch-60 `seal-resist` named in code, not found | tiny |
| Cloud sea, fog cards, screen haze, vignette, sun glow, star field | PK/PofuWorld/Scene/LivingSky.swift:97, :180, :401, :425; FogCards.swift; WeatherLayer.swift:347 | Gradients/Canvas | world-cloud-sea, world-fog-card-1..3 shipped (used first) | hero |

## 4. Map and flights

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Island name pills ("Aycicegi", "Iskele") with paw and lock | PK/PofuWorld/Scene/IslandScene.swift:2386-2410 `mapLabel` | Capsule/RoundedRect + SF `pawprint.fill`, `lock.fill` | ui-tag-v3, paint-tag-paper shipped (crafted only) | tiny |
| Pofu pin on the Map | IslandScene.swift:2144-2155 `PofuPin` | SF `pawprint.fill` on honey Circle | paint-icon-friend / duo set; no map pin art | tiny |
| Place control | see section 3 | | | tiny |
| Koke's far hump on the harbor sky, with warm glow | PK/PofuWorld/Koke/KokeScene.swift:450-505 `KokeFarHump` | Path + gradient + plusLighter glow | none found (koke plates paint Koke only on his island) | medium |
| Far isles | painted (`world-far-isle-1..3`); no code | | | n/a |

## 5. Koke and Caglayan stops

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Light swell on a beat (warm radial) | KokeScene.swift:437; CaglayanScene.swift:341 | Radial gradient | none | hero (flash) |
| Koke stone contact shadow/rim even with painted stone | KokeScene.swift:174 `drawStone` | Canvas ellipses, gradient, glow | world-koke-stone shipped | tiny |
| Koke plate/body fallback (mound with face, lawn, flowers) | KokeScene.swift:208, :185, :246-418 | Canvas | world-koke-island-0..4, koke-asleep/one-eye/stretch shipped; code only if missing | hero (fallback only) |
| Moss gift on Home lawn (sprite island) | KokeScene.swift:511-531 `MossGiftView` | 3 ellipses | world-gift-moss shipped (used on plate); `material-moss` not in a bundle (design/art/masters/material-moss exists) | tiny |
| Caglayan falls, mist, fountain jet (when not painted) | CaglayanScene.swift:356-465, :428 `HomeFountainView` | Canvas paths/gradients | Painted in plate (CaglayanScene.swift:158 comment); world-gift-fountain shipped | hero (fallback only) |
| Caglayan "Akisi bagla" plaque; speech bubbles over Koke/Caglayan | CaglayanScene.swift:106-156; KokeScene.swift:103-130 | `PofuPlaqueStyle`/`SpeechBubble` code | ui-plaque-honey, ui-bubble-paper (crafted only) | medium |
| Placeholder soft ellipse island if plates absent | CaglayanScene.swift:248 | Ellipse | plates shipped | fallback only |

## 6. Sheets (Today, Station, resident card, Passes, Earn)

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Today sheet: paper background, stitched day card, header strip fallback (sky, orb, ellipses) | App/Home/TodaySheet.swift:113-135, :182-228; PK/PofuDesignSystem/Kit/KitPaper.swift:39, :113 | Gradients, Circle/Ellipse/Capsule | Header uses painted plate crop; masters ui-sheet-paper-v3, ui-card-stitched (not shipped) | medium |
| Today wax seals per bead | TodaySheet.swift:230-266 | RadialGradient Circle + SF `leaf.fill` | ui-seals master; batch-60 `seal-resist` not found | tiny |
| Station sheet: pot pips (levels), rate rows, build plaque with seed | PK/PofuWorld/Scene/PotPips.swift:9-66; StationSheet.swift:194, :205-230, :280-308 | Rounded Path pots, Capsule/Circle flowers, `SeedGlyph` | ui-pip-pot master; ui-plaque-honey shipped | medium |
| Close X on sheets | StationSheet.swift:183; PofuSheet.swift:196 | SF `xmark` on Circle | paint-duo-close.png shipped | tiny |
| Resident card shell and tail; mood sticker | StationSheet.swift:349-414; PK/PofuDesignSystem/Sticker.swift:11-130 | RoundedRect + `CardTail` path; stickers fall back to SF `face.smiling`, `star.circle` | design/art/masters sticker-* (mochi-happy, goat-indignant, pofu-*); none shipped | medium |
| Passes: app icon discs, seed pill | App/Home/PassesSheet.swift:81-84 | SF symbol per app on Circle | none | tiny |
| Earn: activity chips, timer ring, "+N" capsule | App/Earn/EarnSheet.swift:32, :157-185; Support/PofuLines.swift:72-85 | SF symbols, Circle ring, Capsule (not reachable from WorldHome per prior doc) | none | medium |

## 7. Hop (the Door), Breath, resist payoff

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Scrim and glow over the postcard | App/Hop/GateScene.swift:135, :172-190 | Gradient, Circle radial | postcards painted (gate-postcard-*, shipped) | hero |
| App chip (SF symbol per app on circle, capsule) | App/Hop/HopView.swift:248-275 | SF `camera`/`play.rectangle`/`music.note` | none | tiny |
| Pofu contact shadow | HopView.swift:298 | Ellipse | none | tiny |
| Primary/secondary plaque buttons, reason chips with check | HopView.swift:206-241, :356-373 | `PofuPlaqueButtonStyle` capsule, SF `checkmark` | ui-plaque-honey/cream masters | medium |
| Breath ring, halo, spark | PK/PofuDesignSystem/Kit/BreathRing.swift:19-70; App/Hop/BreathScene.swift:98-150 | Circle/Ellipse gradients | design/art/ui/ui-breath-halo, ui-breath-petals, ui-breath-ring-spark masters (not shipped) | hero |
| Breath clouds and petals | BreathScene.swift:59-61 (Capsule clouds), :84-90 (ellipse petals/glow) | Capsule, Path ellipses | ui-breath-petals master; cloud-1..5 masters | hero |
| Resist payoff: seed burst, wax seal | PK/PofuDesignSystem/PofuResistPayoff.swift:165-250 (`SeedBurst` :234 "stand-in for reward-seed-burst") | Capsules, `SeedGlyph` | `reward-seed-burst` not found | medium |
| Swipe hint chevron | App/Hop/HopOutcomes.swift:61 | SF `chevron.up` | none | tiny |

## 8. Onboarding, Settings, Setup, Shield, Launch, widgets

| Player sees | file:line | Drawn how | Painted exists | Size |
|---|---|---|---|---|
| Onboarding app rows (Instagram, YouTube, TikTok) and tick | App/Onboarding/OnboardingView.swift:331-335; App/Support/AppPresentation.swift:31-42 | SF `camera`, `play.rectangle`, `music.note`, `checkmark.circle.fill` | none (asset-system-v1 row 4 queues duo sheet 2, `batch-88-duo-icons-pilot`) | medium |
| Onboarding notifications bell; reasons rows | OnboardingView.swift:188; App/ScreenTime/ScreenTimeSetupView.swift:125-127 | SF `bell.badge`, `hand.raised`, `eye.slash`, `switch.2` | none | medium |
| Onboarding name field, suggestion chips, buttons | OnboardingView.swift:380-408; PofuComponents.swift:8-130 | RoundedRect, Capsule | ui-face-primary/secondary shipped (crafted only) | medium |
| Settings rows (icons on honey squares), header disc, toggles | App/Settings/SettingsStyle.swift:21-110; SettingsView.swift:25-146; App/ScreenTime/ScreenTimeSettingsSection.swift:42-201 | SF Symbols (`pawprint.fill`, `hand.raised`, `hourglass`, `wind`, `bell.slash`, `speaker.wave.2.fill`...) | duo icons shipped for shield/settings only | medium |
| Setup guide (Shortcuts path, frozen free build): schematic of Apple Shortcuts | App/Setup/SetupGuideView.swift:264, :362 | Shapes + ~15 SF Symbols | no per-step screenshots | hero (frozen path, no new work) |
| Launch curtain cloud banks (fallback) | App/Launch/LaunchCurtain.swift:167-195 | Ellipses | cloud-curtain-1..3 and launch-sky shipped (used first) | fallback only |
| Shield icon, last fallback (warm door + Pofu) | Extensions/Shared/ShieldStyle.swift:223 `placeholderDoor` | UIKit drawing | shield-pofu-<mood> PNGs shipped (used first) | fallback only |
| Shortcuts tile glyph | App/Intents/PofuShortcuts.swift:14 | SF `hand.raised.fill` | n/a (system) | tiny |
| Widgets / Live Activities | Not found: no widget extension in Extensions/ (DeviceActivityMonitor, Shared, ShieldAction, ShieldConfiguration only) | | | n/a |

## 9. Design-system kit (what every screen above leans on)

| Thing | file:line | Drawn how | Painted exists |
|---|---|---|---|
| Buttons, chips, paper surfaces, plaques, toasts, grain | PK/PofuDesignSystem/PofuComponents.swift:8-130; Kit/KitComponents.swift; KitPaper.swift; KitPlaque.swift:23-230; KitMaterial.swift:16-24 | "All drawn in code first" with art-hook names (`PofuKitArt`) | Shipped: ui-plaque-honey, ui-card-linen, ui-bubble-paper, ui-face-disc-v2, ui-tab-ribbon, paint-panel-paper, paint-tag-paper (PofuDesignSystem/Resources). Masters not shipped: ui-chip-felt, ui-toast-strip, ui-groove-wood, ui-plaque-cream/quiet/bare, ui-sheet-paper-v3, ui-card-stitched |
| Stickers (13) | PK/PofuDesignSystem/Sticker.swift | SF Symbol per sticker | design/art/masters sticker-* (10) |

Allowed by ADR-0018 (listed, no detail): `.glassEffect` capsules/circles (HomeView.swift:230, WorldHome.swift:560, PlaceControl.swift:85, PofuSkinViews.swift:233-247, StationSheet.swift:401); SF Symbols `xmark`, `gearshape` fallback, `chevron.*`, `checkmark`, `plus`, `pause.fill`, `exclamationmark.shield.fill`; system `Toggle`, app picker, Apple shield, alerts.

## Ten most visible code-drawn things (by frequency times size)
1. Home chrome surfaces, every open: Pofu's line card (WorldHome.swift:614 / PofuComponents.swift:246), "Topla" capsule with flat code seed (HomeObjectViews.swift:269-300), today glance pill (HomeObjectViews.swift:629). Painted equivalents shipped but gated off by the glass default.
2. Flow board banks: grass and rock cells (FlowArt.swift:460, :478; painted PNGs shipped, `paintsBankTiles = false` :67), the largest share of cells on every round.
3. Flow channel groove, water, source and mouth rings, wheel and gate (FlowArt.swift:235-478, :162, :187): code on every tile.
4. Flow board frame and sky: cliff lip, moss strip, bank, gradient backdrop (FlowScene.swift:178-221).
5. Garden game bed rim and sky (GardenArt.swift:211, :351); painted bed-rim PNG shipped, unreferenced.
6. Build moment dust and sparkles, level badge (BuildEffects.swift:6-235), each station build.
7. Level-up celebration card, ribbon, bloom (CelebrationCard.swift:9-150, IslandGrowViews.swift:8-66).
8. Hop screen: scrim, glow, app chip, plaque buttons, reason chips (GateScene.swift:135-190, HopView.swift:206-373), every "Acmam lazim".
9. Breath room: ring, halo, cloud capsules, petals (BreathScene.swift:23-150, BreathRing.swift:19-70).
10. Station sheet: pot pips, rate rows, build plaque with code seed (PotPips.swift:9-66, StationSheet.swift:194-308), and onboarding/settings SF-symbol icon rows (OnboardingView.swift:331, SettingsStyle.swift:21) tie for this slot by how often they open.
Not on the player path now but large if the plate drops: sprite-island growth pieces and critters (GrowthArt.swift, LifeArt.swift) and the code CloudSea/fog (LivingSky.swift).
