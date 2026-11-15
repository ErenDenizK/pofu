# World presentation v2: scout facts (2026-11-15)

**Asked by:** the lead, brief for `docs/design/world-presentation-v2.md` §11 (branch `origin/design/feel-and-world`, commit `04151bc8`).
**Checked against:** `origin/main` at `5196def1`, sparse worktree. Paths are relative to the repo root. Facts 8 and 11 are not answered here.
**Method:** code read with `grep`/`sed`; plate and registry checks with Python/PIL on the files in `Packages/PofuKit/Sources/PofuWorld/Resources` (`World.xcassets`, `Plates/plate-home.json`). Image hashes are MD5 of the file bytes, so they count byte-identical files only. Nothing was rendered or run on a device or simulator.

## 1. Safe-area insets read at iPhone 17; the Home chrome boxes

Answer: the island scene reads only the top inset, at runtime. The default is 59 pt. The Home chrome boxes are not stored as numbers in code; they are measured at runtime. I could not tell the iPhone 17 values.

- Top inset read: `Packages/PofuKit/Sources/PofuWorld/Scene/IslandScene.swift:229-235` (`onGeometryChange` reads `proxy.safeAreaInsets.top` into `safeTop`). It is the only `safeAreaInsets` read in `App/` and `Packages/`.
- Default before the first read: `IslandScene.swift:40` (`= 59`) and `IslandSceneModel.swift:1296` (`var safeTop = 59.0`).
- Bottom, leading and trailing insets: not read. The jar gets `leadingInset: 0, trailingInset: 0` at `WorldHome.swift:367-368`.
- Chrome is the World Home chrome in `WorldHome.swift`; `FeatureFlags.worldHome = true` (`App/Support/FeatureFlags.swift:13`). The old chrome in `App/Home/HomeView.swift:40-58` is behind `!FeatureFlags.worldHome`, so it does not render at Home.
- Prop frames are measured at runtime: `WorldHome.swift:381-391` reports each prop's `frame(in: .global)` through `frame.report`. The place control's frames are stored in `IslandSceneModel.swift:76-83`.
- Constants that do exist: gutter `PofuSpacing.screen = 20` (`Packages/PofuKit/Sources/PofuDesignSystem/PofuTokens.swift:12`); minimum touch `44` (`Packages/PofuKit/Sources/PofuWorld/Scene/WorldHitTest.swift:53`); row `minHeight` 44, 40 or 34 at `WorldHome.swift:297, 312, 677`.
- Not found: any stored box value for the line card, action, glance, gear or place control. The real boxes need a device or simulator frame.

## 2. Island box per level; free spans of the front lip

Answer: the code has one island box for all levels, not one per level. The per-level free spans are not computed anywhere in code. I could not tell them.

- `IslandFraming.swift:127-129`: `islandBox = union([stationRow, plateBox])`. `stationBox` (`IslandFraming.swift:85-92`) unions the art of every generated level of a station, so the box does not change with the island level.
- Plate value: `plate-home.json` key `islandBox` = `[4, 438, 1019, 1230]` (units).
- Front lip: the stone path runs at y 34, and at y 33 where the walkable lip narrows at x 111 (`Packages/PofuKit/Sources/PofuWorld/Layout/IslandGrowth.swift:146-147`). No span table per level exists in code.

## 3. Per station, per level plate, day and night: paintings and levels

Answer: the Home plate has 10 day paintings, 10 night paintings and 1 golden painting, for stages 0 to 9 (stage 0 is level 10, stage 9 is level 1). The station occupant paintings are a subset of stages. Stations outside the plate have no day/night split in their names.

- Mapping: `plate-home.json` `stageLevels` = `[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]`. `PlateIsland.swift:225-227` (`dayStage`) picks the first stage whose level is at or below the island level. The asset name is `world-<island>-plate-<light>-<stage>` (`PlateIsland.swift:169-171`).
- Plate paintings (registry, distinct by MD5, HEIC):
  - `world-home-plate-day-0..9`: 10 files, 10 distinct, stages 0-9.
  - `world-home-plate-night-0..9`: 10 files, 10 distinct, stages 0-9.
  - `world-home-plate-golden-0`: 1 file, stage 0 only (`plate-home.json` `lightStages.golden = 1`).
- Occupant paintings (`world-home-occ-<station>-<light>-<stage>`, each distinct by MD5). Their stage list is `plate-home.json` `objects[].stages`:
  - teaStall: day 0-8 (9), night 0-8 (9), golden 0 (1). Stages 0-8 (`objects[0]`).
  - workshop: day 0-4 (5), night 0-4 (5), golden 0 (1). Stages 0-4.
  - windmill: day 0-2 (3), night 0-2 (3), golden 0 (1). Stages 0-2.
  - Wheel, mailbox, bushes: 9, 4, 4, 4 stages, not in the brief.
- Backdrop and island sets follow the same pattern: `world-home-backdrop-*` and `world-home-island-*`, day 0-9, night 0-9, golden 0.
- Stations drawn as PNG sprites (`IslandLayout.stationArt`, `IslandLayout.swift:117-121`, clamped to `generatedLevels` at `IslandLayout.swift:109-112`):
  - teaStall 5, garden 5, pond 5, windmill 5, bagelCart 5: each `-1` to `-5` is distinct (5 each). teaStall, windmill and bagelCart also have variant names (`--normal`, `--round2`, `--softlock`, `--unharmonized`, `-blue`, `-glow`). Only `--normal` is referenced in code (`DepthImage.swift:103`); the others are not referenced by `stationArt`.
  - workshop 1, pier 1, lighthouse 1 (lighthouse also has `-3-blue` and `-4-blue`, not referenced by `stationArt`).
  - No day/night pair exists for these names.

## 4. `plate-home.json`: pier and garden stages

Answer: as the doc says. Pier is present at stages 0, 1, 2 and 5. Garden is present at stages 0-6, 8 and 9, so it is missing only at 7. Whether this is intended is not stated anywhere I searched.

- `plate-home.json` `objects`: pier `stages [0, 1, 2, 5]`; garden `stages [0, 1, 2, 3, 4, 5, 6, 8, 9]`.
- Intent: not found in `docs/design/*.md` or `tools/plate/`. The only pier reference in `tools/plate/` is `tools/plate/map_cut.py:118` (`islet_painted` includes `pier`).

## 5. Camera elevation of the Home, Koke and Çağlayan paintings

Answer: the code states about 17 degrees for the Home plate. The lawn ellipse gives about 10.5 degrees if the lawn is a ground circle. These two disagree. No elevation is given for Koke or Çağlayan.

- Home lawn ellipse: `lawnRadiusX = 240.0`, `lawnRadiusY = 43.67` (`Packages/PofuKit/Sources/PofuWorld/Geometry/WorldArt+Generated.swift:3495-3496`). Ratio 43.67 / 240 = 0.182.
- Code comment: "the camera looks down at about 17°" (`Packages/PofuKit/Sources/PofuWorld/Layout/IslandLayout.swift:27-28`).
- Derived: if the lawn is a circle on the ground, the ratio is sin(elevation), so elevation ≈ asin(0.182) ≈ 10.5°. sin(17°) = 0.292, which does not match 0.182. I did not resolve this; it is a derivation, not a stated value.
- Koke: `KokeLayout.swift:63-66` (`focusDepth = depth(ofY: center.y)`), centre `(-100, 410)` at `Packages/PofuKit/Sources/PofuWorld/Koke/KokeLayout.swift:62`. No lawn ellipse or elevation found.
- Çağlayan: centre `(150, 440)` at `Packages/PofuKit/Sources/PofuWorld/Caglayan/CaglayanLayout.swift:63`. No lawn ellipse or elevation found.

## 6. Does any text place Koke or Çağlayan below Home?

Answer: no text found that places Koke or Çağlayan below Home. The only height statement puts Home above, on the Koke stop.

- `Packages/PofuKit/Sources/PofuWorld/Koke/KokeLayout.swift:76-78`: at the Koke stop, "the home island (187 units above the plate's roots) is above the top edge".
- Undersides (`docs/design/island-undersides.md:89-92`): Çağlayan has an underside. The falls "pour off the island's underside into the cloud sea… seen as a long fall below the plate". This places a fall below Çağlayan, not Çağlayan below Home.
- Story-map order (`docs/product/story-map/book-one.md:74, 80, 316`): "1 Çağlayan", "4 Revontuli"; Koke is the "first filler, first visitor". This is story order, not height.
- Search: `grep -i` for below/beneath/above/tier with Koke, Çağlayan and home in `docs/` and `Packages/PofuKit/Sources/`. No tier assignment.

## 7. `pofuDepthBlur`, multi-image shaders, blur caching

Answer: `pofuDepthBlur` reads the SwiftUI layer and one depth texture, in two passes. It is off on any painted Home plate. SwiftUI shaders can read several images (the grade shader reads three). Caching of a blurred still layer is not found in code.

- Shader: `Packages/PofuKit/Sources/PofuWorld/Resources/SpikeShaders.metal:119-122` takes `SwiftUI::Layer layer` and `texture2d<half> depthTex`, plus lens, setup and direction float parameters.
- Call: `Packages/PofuKit/Sources/PofuWorld/Scene/GraphicsSpikeLayers.swift:101-121` (`SpikeDepthOfFieldEffect`), two `layerEffect` passes (horizontal, then vertical, the second disabled when showing depth). Applied at `IslandScene.swift:922`.
- Gate: `IslandScene.swift:665` `depthMap = !painted && ((spikeDOF && rack > 0.001) || spike.debug == .depth)`. `painted` is `plate != nil` for Home (`IslandScene.swift:532`). So the depth blur is off on a painted plate.
- Switches: `GraphicsSpike.standard` has `depthOfField: true` (`Packages/PofuKit/Sources/PofuWorld/Look/GraphicsSpike.swift:35`); `spikeDOF` also needs `WorldShaders.isAvailable` (`IslandScene.swift:544`).
- Several images: `pofuWorldGrade` takes `lut0`, `lut1`, `lut2` (`Packages/PofuKit/Sources/PofuWorld/Resources/WorldShaders.metal:72-74`); `WorldLookLayers.swift:37-50` passes three `.image(...)` arguments. `pofuRelight` takes `normalTex` (`SpikeShaders.metal:78-81`).
- Caching of a blur on a still layer: not found. The only pause/cache statement is for the timeline (`IslandScene.swift:1841-1842`), not for blur.

## 9. Most pots a day can show; lantern and jar states

Answer: at most 8 pots are drawn; reaches beyond 8 cluster with a badge, with no daily cap in the pot code. Lantern and jar have one painted "off/empty" state each, and the fill or glow is drawn in code.

- Pots: `Packages/PofuKit/Sources/PofuWorld/Home/HomeObjects.swift:161` (`SkipPots.maxVisible = 8`). `perPot` groups reaches so pots ≤ 8 (`HomeObjects.swift:174`). Clustering and badge at `HomeObjects.swift:182-184`.
- Reaches per day: `beads` is one per reach of the local day (`Packages/PofuKit/Sources/PofuCore/Gate/ImpulseMetrics.swift:70-80`); no cap found there. The `PofuResistPayoff.maxPots = 8` (`Packages/PofuKit/Sources/PofuDesignSystem/PofuResistPayoff.swift:26`) is a second cap for the payoff animation.
- Pot art: `ui-pot-empty` and `ui-pot-bloom` exist in the registry; a skip is a bloom and an open is a bud (`HomeObjects.swift:153-170`).
- Lantern: painted `ui-lantern-off` (`Packages/PofuKit/Sources/PofuWorld/Home/HomeObjectViews.swift:395-396`). Glow in code: `CalmLantern.glow` goes from 0.15 at calm 1.0 to 1.0 at calm 2.0 (`HomeObjects.swift:135-146`). No lit painting found in the registry.
- Jar: painted `ui-jar-empty` (`HomeObjectViews.swift:48-49`). Fill is a code mask: `SeedJarFill.fraction`, capacity 120, minimum visible 0.08 (`HomeObjects.swift:118-130`). No full-jar painting found.

## 10. Source of the blue band under the island

Answer: the blue band is opaque pixels of the Home plate itself (`world-home-plate-day-0`). The plate's alpha is 255 at those rows, so the backdrop cannot show through, and the feather or matte are not the source there. I did not compare backdrop pixels directly because the backdrop is a different size and crop.

- File: `world-home-plate-day-0.imageset/*.heic`, 2048 x 3072 RGBA (decoded with pillow_heif).
- Scan of the centre 40 % of columns, every 16 rows, "blue-dominant" share (blue beats red by 25 and green by 5): 0.52 at y 2360, 0.84 at 2376, 0.95 at 2392 and 2408, 0.80 at 2424, 0.61 at 2456, 0.50 at 2472, down to about 0.2 by 2504 and 0.3 to 0.4 below.
- Alpha at the same rows is 255. Alpha is 255 from about y 1100 to 2892 (sampled), and 126 at y 3020, so the plate's own edge is not at these rows.
- The warm earth above the band runs from about y 1150 to 2250 (R about 200, B about 120-150). The blue starts at about 2360.
- `plate-home.json` `feather = 48` (units not stated in the file); the feather is not checked against these rows.
- Not checked: no render; the backdrop jpg `world-home-backdrop-day-0` is 614 x 1585 and its registration to the plate was not established.

## 12. Residents' art sizes at Home

Answer: Home has two residents, Mochi and Fındık. Their base sprites are about 228 x 175 px (Mochi) and 215 x 203 px (Fındık), and their sharp boxes are about 30 x 23 and 29 x 27 world units. The code scales them to about 21 x 16 and 17 x 16 units at Home.

- Residents: `Packages/PofuKit/Sources/PofuWorld/Layout/IslandLayout.swift:87-93` (`mochi` at the tea stall, `findik` at the workshop).
- Base sprites (registry PNG, base frame, not `__soft`, `__deep` or `-shadow`):
  - `world-mochi`: 228 x 175 px. Frames 221-243 x 174-180 px. `world-mochi-proud` is 196 x 285.
  - `world-findik`: 215 x 203 px. Frames 214-215 x 201-205 px.
- Sharp boxes in world units: findik `WorldArt+Generated.swift:1028-1029`, width 28.67, height 27.07. mochi `WorldArt+Generated.swift:2285-2286`, width 30.4, height 23.33.
- Scale: `residentScale = characterScale * (residentBoosts[id] ?? residentBoost)` (`Packages/PofuKit/Sources/PofuWorld/Plate/HomePlate.swift:208-209`). `characterScale = pofuWidth * unitsPerPixel / pofuArtWidth` (`HomePlate.swift:197-199`), `pofuArtWidth = 64` (`HomePlate.swift:48`).
- `unitsPerPixel` at Home = `framing.homeWidths * 402 / 1.40 / islandBox.width` = 1.15 * 402 / 1.40 / 1015 = 0.3253 (`HomePlate.swift:57-61`; `plate-home.json` `framing`, `islandBox`).
- With `pofuWidth = 83.4`: `characterScale` = 0.424. Mochi boost 1.62 gives 0.687; Fındık boost 1.40 gives 0.594 (`plate-home.json` `residentBoosts`).
- The draw code multiplies the sharp width and height by `residentScale` (`Packages/PofuKit/Sources/PofuWorld/Scene/IslandScene.swift:1282-1283`): Mochi about 20.9 x 16.0 units; Fındık about 17.0 x 16.1 units.
- Open point: the sharp box is already in world units, and the code multiplies it by a scale again. I did not verify whether that is intended, and I did not find a comment on it.
