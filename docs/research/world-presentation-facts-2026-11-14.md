# World presentation: facts for the Fable plan

Facts only, no recommendations. Read from `origin/main` `7f4e99c0be9b33b7ea11077e6ff00f972e16db1d` (code, not docs). No frames were opened; pixel sizes were read from the asset files (HEIC `ispe` box, PNG/JPG headers). Numbers marked "computed" are my arithmetic from the cited constants, not measured on a device.

- **Path prefix:** `PW/` is `Packages/PofuKit/Sources/PofuWorld/`.
- **Device:** iPhone 17, 402 x 874 pt, 3x (1206 x 2622 px). `CameraRail.referenceWidth = 402` (`PW/Camera/CameraRail.swift:103`).
- **What ships at Home:** `WorldLook.homePlates = true` (`PW/Look/WorldLook.swift:76`), `FeatureFlags.worldHome = true` (`App/Support/FeatureFlags.swift:13`). Home is drawn from painted plates; the sprite island draws only where no plate state is painted.

## 1. Camera

- **Three rail stops plus whole-island pose.** `WorldFraming` map=0, island=1, home=2 (`PW/Camera/CameraRail.swift:4-7`). Stops while a plate shows: `[mapStop, islandStop, homeStop]` (`PW/Plate/HomePlate.swift:468-470`). The "whole island" is a fourth pose, `wholeStop` (0.95 screen widths), used only for the 0.9 s establishing shot on arrival, the "Ada büyüdü" pull-back and `holdEstablishingShot` (`PW/Scene/IslandSceneModel.swift:1133-1141, 1121, 1376`).
- **Framing of each** (reference 402 pt; plate JSON `framing` in `PW/Resources/Plates/plate-home.json`: homeWidths 1.15, islandWidths 0.9, wholeWidths 0.95):
  - Map: Home, Koke and Çağlayan fitted between the chrome bands, scale about 0.76 pt/unit (computed from `PW/Plate/HomePlate.swift:449-466`).
  - Island ("mid"): island 0.9 screen widths wide, 1.096 pt/unit (computed), centred in the band; a horizontal pan runs across it.
  - Home ("near" today): island 1.15 widths wide, `IslandFraming.homeScale = 1.40` pt/unit (`PW/Layout/IslandFraming.swift:42`), Pofu about 38 pt wide on the plate (computed: 83.4 plate px x 0.3253 units/px x 1.4).
- **One camera or crossfades: both.** The rail itself is one continuous camera: `ln(scale)` and the look point interpolate linearly with `z` (`PW/Camera/CameraRail.swift:161-175`), so stations, residents and the plate move as one. But the painted layers around it are separate views faded by `z` or by zoom, not one transform:
  - Plate, backdrop and Home's sky set fade in from z 0.55 to 0.95 (smoothstep): `PlateHomeLayer.opacity(z:)` (`PW/Plate/PlateHomeViews.swift:54-58`). Below that, the island is the half-size cut `mapisle` (`:97`).
  - On the Map and in flights the sky is drawn with its own camera: `PaintedSky.mapPose` fixes the scale to fill the screen height ("never zooms") and follows the world camera's look point by `mapParallax = 0.06` (`PW/Plate/PaintedSky.swift:163, 358-372`). It is drawn when `max(plateFade, isleFade, skyFade) < 0.999` (`PW/Scene/IslandScene.swift:685-693`).
  - Koke, harbor and Çağlayan fade their plates by zoom against the stop's scale and by distance (`HomePlate.isleFade`, `PW/Plate/CaglayanPlate.swift:59-68`).
  - Flights between islands: rise, travel, descend in 0.35/0.30/0.35 of the duration, apex at z 0.15 (`PW/Camera/CameraFlight.swift:8-12`).
- **Pinch:** `MagnifyGesture` on the whole scene (`PW/Scene/IslandScene.swift:182`) drives `CameraRig.pinch` (`PW/Camera/CameraRig.swift:328-337`). Range is the rail, Map (z 0) to Home (z 2). Past Home the scale rubber-bands up to x1.25 (asymptote 1.75 pt/unit); past the Map down to x0.8 (`CameraRail.swift:128-129, 209-226`). On release it lands on one of the three stops (`CameraRig.swift:342-355`, `PW/Camera/CameraRelease.swift`). There is no held zoom between stops.
- **Pan:** one finger pans horizontally only at the Island stop, nothing focused (`pansIsland`, `PW/Scene/IslandSceneModel.swift:1029-1033`): momentum, snap points at each station and Pofu (`CameraRig.swift:415-444`, `IslandFraming.swift:225-234`). The pan weight is 0 at Home (`CameraRig.swift:396-404`). Everywhere else a drag is a "peek", limited to 30 pt with a rubber band (`CameraRig.swift:369-378`). No vertical pan, no free pan, no pan at Home or the Map. The pan range reads the sprite island's `plateBox` (`CameraRig.swift:408-410` -> `IslandFraming.swift:121-124`), not the painted plate's; I did not trace what that gives on the plate.
- **Other inputs:** double tap = `stepIn` (`IslandScene.swift:179`, `IslandSceneModel.swift:547`); one-thumb zoom (double tap, hold, drag; 160 pt per e-fold) feeds the same pinch (`PW/Camera/OneThumbZoom.swift:14`); accessibility zoom action.
- **Focus poses (off the rail):** station focus = painted station box centred above the sheet, scale up to 2.6 x width/402 (`IslandSceneModel.swift:762-769`); resident focus = rail scale x1.3, 35 % toward the resident (`:773-790`). These are springs blended over the rail by `focusAmount` (`CameraRig.swift:261-296`).
- **Owners:** `PW/Camera/` (`CameraRail`, `CameraRig`, `CameraFlight`, `CameraRelease`, `OneThumbZoom`, `WorldSpring`), `PW/Layout/IslandFraming.swift`, `PW/Plate/HomePlate.swift` (plate stops), `PW/Plate/PaintedSky.swift` (Map sky camera), `PW/Scene/IslandScene.swift` (gestures, layer stack), `PW/Scene/IslandSceneModel.swift` (state).
- **Doc drift:** the header of `IslandFraming.swift:8-16` says the Island stop is x1.5 / Pofu 96 pt; the code is `islandScale = 1.0` (`:188`) and on the plate the stop is `islandWidths` 0.9.

## 2. Plates and resolution

- **Home plate** (21 painted states: day x10 island levels, night x10, golden x1 at level 10; `plate-home.json` `lightStages`, `stageLevels [10..1]`): `world-home-plate-<light>-<n>`, 2048 x 3072 HEIC, all 21 the same size. The JSON's `plateSize` is 1024 x 1536; the texture is 2x that. Companion layers per state: `island` cut (about 508 x 396), `mapisle` (same size), `backdrop` JPG (614 x 1585 for 11 states, 527-537 x 1362-1389 for 9 states; one backdrop per state), occluders `world-home-occ-<id>-<light>-<stage>`.
- **Placement:** `unitsPerPixel = homeWidths x 402 / homeScale / islandPixels` = 0.3253 world units per plate-space px, so one texture px is 0.1627 units (`PW/Plate/HomePlate.swift:59-63`, computed).
- **Texture px per screen px (computed, plate texture, 3x device):**

  | Camera | pt/unit | texture px per device px | Pofu width |
  |---|---|---|---|
  | Island stop (0.9 widths) | 1.10 | 1.87 | 30 pt |
  | Home stop | 1.40 | 1.46 | 38 pt |
  | Pinch limit (x1.25, rubber band) | 1.75 | 1.17 | 47 pt |
  | Resident focus (Home x1.3) | 1.82 | 1.13 | 49 pt |
  | Station focus cap (2.6) | 2.60 | 0.79 | 71 pt |

- **Today's closest zoom:** the station focus at 2.6 pt/unit, 0.79 texture px per device px (the plate upscaled about 1.27x). The closest a pinch can hold is Home, 1.46.
- **"Near" on Pofu** (Pofu about 201 pt wide, half of 402): 201 / 27.13 units = **7.41 pt/unit** (computed). That is 5.3x Home and 2.85x the station focus cap. The plate at that scale is 0.83 texture px per pt, **0.28 per device px** (about 3.6x upscaled). Pofu's art, `pofu-hamster.png` 522 x 496 (`PofuCompanion/Resources`), at 603 device px wide is 0.87 art px per device px (about 1.16x upscaled).
- **Other islands:**
  - Çağlayan: `world-caglayan-plate-<light>-<n>` 3072 x 2048 (`plateSize` 1536 x 1024), island box placed 212 units wide, `closeScale = 1.8` (`PW/Caglayan/CaglayanLayout.swift:75`): 7.88 texture px per pt, 2.63 per device px (downsampled; computed).
  - Koke: no plate or backdrop; `world-koke-island-<0..4>` PNG, 1277 x 847 up to 1302 x 930, drawn 250 units wide at `closeScale = 1.8` (`PW/Koke/KokeLayout.swift`): 450 pt, about 0.96 art px per device px (computed).

## 3. Upgrades

- **Home plate: only the island level changes the picture.** The plate is chosen by `islandLevel` -> `dayStage` (`PW/Plate/PlateIsland.swift:225-228`, `HomePlate.state` `:126-135`). Station levels (1 to 5) select nothing on the plate. `StationView`, the per-level sprite path, is built only when `plate == nil` (`IslandScene.swift:1104-1107, 1109-1115`; `plateObjects` `:1177-1210` makes no station object). On the plate a station is a tap polygon, present or absent by stage (`plate-home.json` `objects[].stages`, e.g. windmill stages [0,1,2] = levels 10 to 8; `PlateIsland.Object.isPresent`, `:64-66`).
- **Island level rule:** a function of tended days and the sum of built station levels (`PofuCore/Game/Archipelago.swift:275-280, 323-335`, `StationLedger.swift:172`); level 2 needs growth 2 and tended day 2, level 10 needs growth 40.
- **Per-station art that exists:** sprite island only, `world-<station>-<1..5>` for tea stall, garden, pond, windmill, bagel cart; one level only for workshop, pier, lighthouse (`PW/Layout/IslandLayout.swift:109-112`). A station without its own level art wears a lower one with a level badge (`IslandScene.swift:1790-1796`).
- **Trace, sheet button to screen:** `StationSheet` "Build" button (`PW/Scene/StationSheet.swift:299-302`) -> `onBuild` -> `WorldHome.build` (`PW/Home/WorldHome.swift:95, 503-506`) -> `WorldHomeModel.buildStation` commits via `WorldClock.build`, spends seeds, starts a `BuildMoment` (`PW/Visit/WorldHomeModel.swift:297-326`). On screen, on the plate: sheet drops to the 132 pt detent, camera pushes in (`beginBuildFraming`, `IslandSceneModel.swift:1491-1511`), seeds/particles and a warm radial bloom at the painted object (`IslandScene.swift:1329-1334, 1643-1677`, 40 % of the sprite burst), "Level n!" tag (`BuildEffects.swift:92`, `IslandScene.swift:2187`), residents hop. No station art swaps. If the island level rose, `releaseGrowAfterBuild` then plays "Ada büyüdü" (below), the only moment the picture changes.
- **Sunflower, code-drawn:** `Bloom` in `PW/Home/HomeObjectViews.swift:562-584`: 8 honey `Capsule`s (5 x 9) round a `Circle` (8 x 8) on a capsule stem, folded 70 degrees at night. It is the bloom in `PotView`/`SkipPotsView` (today's skips on the island lip; `:445-470`), placed from `PW/Home/WorldHome.swift:339`. Other sunflower code: `GardenArt.petal()` (8 x 14 ellipse, SpriteKit particle, `PofuGames/Scene/GardenArt.swift:449`); a carved sunflower in the sprite-island IL9 gate (`PW/Scene/GrowthArt.swift:370`). The garden minigame blooms are painted PNGs (`PofuGames/Resources/garden-bloom*.png`). I could not tell which one the founder saw.

## 4. Backdrop and clouds

- **Home, levels 1 to 9 (stages 1 to 9):** static `world-home-backdrop-<light>-<n>` JPG behind the whole plate; nothing moves (`PlateHomeViews.swift:105-106`). **Level 10 (stage 0), day, golden, night:** a sky set instead, `skyset-home.json`, 9 to 13 layers: sky, far (tile, drift 4), isles (bob), whale (drift 5), mid clouds (tile, drift 9), sea (tile, drift 14), island (`PW/Sky/SkySet.swift:165-171`, `PlateHomeViews.swift:101-103`). Layers sit in world space at the camera scale, so they zoom with the island and drift against it in time; each layer's own bob/drift is not tied to the camera (`PW/Sky/SkySetView.swift:80-109`).
- **Çağlayan:** its own `skyset-caglayan.json` for every painted state (sky 2304 x 4968 vs Home's 3072 x 4096; tiles 2240 wide vs 2048; the plate sits on the master at `plateFrame` scale 1.3333, offset (0, 850)), plus a `backdrop` JPG 506 x 1306 per state. Sky source images are small and upscaled: Home sky 384 x 512 drawn 3072 x 4096; far 1024 x 456 -> 2048 x 910; mid 1230 x 658 -> 2048 x 1096.
- **Koke and the harbor** draw Home's level-10 sky set (island layer left out, cleaned by `stopSet`) placed around each stop: island width 290 units at Koke, 520 at the harbor (`PW/Plate/PaintedSky.swift:20-23`), so the same clouds are drawn at a different scale at each stop, fading by `isleFade`. The Map draws the same set via `mapSky`, at `mapPose` (section 1).
- **Why they differ or drift (code facts):** (1) Home levels 1 to 9 have a static backdrop, level 10 a drifting sky set; (2) Çağlayan has a different set and master; (3) Koke/harbor reuse Home's set at other placement widths; (4) the Map sky has its own camera with 0.06 parallax, the island layers use the world camera; (5) tile drift 4/9/14 px/s differs per layer and runs on its own timeline, not the camera's (`SkyMotion`, `SkySet.swift:177-200`); a settled frame under Reduce Motion, Low Power Mode and screenshots is time 0 (`SkySetView.swift:30-32`).
- **Small clouds that vanish zooming out (candidates; I did not see the frame):**
  - Home's mid-cloud tile (`world-home-sky-mid-*`, master rows 679 to 1775, behind the island layer) is drawn only inside the sky set, which fades out by z 0.55 to 0.95. On the Map `cleanSet` keeps it only above master row 1100, fading over 60 rows (`PaintedSky.swift:178-181, 240-243`; comment: below that "the tile carries the cut residue of Home's island"). So the clouds around the island are cut on the Map by design.
  - Levels 1 to 9: any clouds are painted into the static backdrop/plate and fade with them.
  - Code cloud shadows (`CloudShadows`, `PW/Moments/CloudShadows.swift`) draw only when `plate == nil` (`IslandScene.swift:1015-1038`), so not on the plate.
  - No per-cloud level-of-detail or visibility rule exists in code; fading is by layer (z) and the row window above.

## 5. Sheets

- **Native SwiftUI sheets, no custom presentation.** Station sheet: `.sheet(item: $model.sheet)` with `.presentationDetents([.height(132) while building, .fraction(0.42), .large])`, `presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.42)))`, `.presentationContentInteraction(.resizes)`, a custom paper background (`IslandScene.swift:302-320, 361-365`; `PofuDesignSystem/Kit/KitPaper.swift:145`). `.transition(.opacity)` is set on the content at `:314`. Inside: `.animation(.spring(duration: 0.25, bounce: 0), value: isBuilding)` (`StationSheet.swift:102`). The in/out motion is the system's; no `UIViewControllerTransitioning`, `UISheetPresentationController` or matched-geometry code exists in `App/` or `Packages/`.
- **Other sheets:** Invite sheet `[.medium, .large]` (`IslandScene.swift:321-328`); Home sheets earn `[.fraction(0.68), .large]`, passes and today `[.medium, .large]`, settings, setup (`App/Home/HomeView.swift:112-139`); `fullScreenCover` for garden, flow and hop (`HomeView.swift:140-144`, `App/RootView.swift:73`). The world freezes and flattens while a sheet is up (`IslandScene.swift:160`).
- **Camera with the sheet:** station focus on open; build drops the sheet to the 132 pt detent, camera spring 0.60 s (`buildPush`), sheet returns to medium and camera refocuses at 1.75 s (`BuildMoment` `sheetBack`; `IslandSceneModel.swift:1519-1540`). Springs: focus 0.52 s / bounce 0.14, refocus 0.60 s (`PW/Camera/WorldSpring.swift:86-91`).
- **Build moment** (`PW/Moments/BuildMoment.swift:1-30, 98-111`): squash 0.30, art swap 0.42 (sprite path only), 7 sparkles 0.45, tag 0.60 (lives 2.6 s), Pofu hop 0.72, resident hop 0.84, settle 1.02, sheet back 1.75, end **3.2 s** (2.7 s under Reduce Motion: 200 ms cross-fade, no particles or hops).
- **"Ada büyüdü"** (`PW/Moments/IslandGrowMoment.swift:1-60`): pull-back to the whole island 0, bloom from 0.6 (peak opacity 0.22), plate cross-fade 0.9 to 1.7 (0.8 s, two whole paintings), "Ada n" `CelebrationCard` rises 1.7, ends **4.6 s**; Reduce Motion: no camera move or bloom; Low Power: no bloom. It waits for a build's ceremony or the visit's news (`IslandSceneModel.swift:1328-1352`).

## 6. Inventory (all on main)

| Island | Drawn from | Painted states | Pixel size | Sky |
|---|---|---|---|---|
| Home | plate, `world-home-*` | 21 (day 10, night 10, golden 1) x plate, island cut, mapisle, backdrop = 84 images, plus 74 sky-set files and 83 occluder files | plate 2048 x 3072; cuts about 508 x 396; backdrop 527-614 x 1362-1585 | Home sky set at level 10 only; static backdrop otherwise |
| Çağlayan | plate, `world-caglayan-*` | 12 (day 0-4, night 0-4, golden 4, rain 4), each plate, island cut, backdrop; 42 sky-set files | plate 3072 x 2048; cut 752 x 486; backdrop 506 x 1306 | own sky set per state |
| Koke | sprite cut, `world-koke-island-<0..4>` | 5 (one light) | 1277 x 847 to 1302 x 930 | Home's sky set at its stop |
| Harbor (İskele) | sprite `world-harbor-island-s` | 1 | 1475 x 689 | Home's sky set at its stop |
| Others | `world-isle-{hamam,harbor,library,stars}-standin` | 1 each, stand-ins | e.g. hamam 492 x 435 | none; `IslandLayout.isles` lists only the harbor (`PW/Layout/IslandLayout.swift:158-160`) |

Station stages: 5 Home stations x 5 sprite levels and 3 x 1 exist only on the sprite island (section 3). Koke and Çağlayan each have 5 story stages (`KokeLayout.stages`, `CaglayanLayout.stages = 5`).
