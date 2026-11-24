# Scout: when does Home draw the sprite island? (origin/main 2230b67e, 2026-11-24)
Paths: PW = Packages/PofuKit/Sources/PofuWorld.

## 1. Sprite-island fallback states
Gate: `IslandScene.swift:268` calls `HomePlate.resolve(...)` on every change and
`model.setHomePlate` (IslandSceneModel.swift:504); `homePlate == nil` is the sprite island.
`resolve` (PW/Plate/HomePlate.swift:142-157) returns nil only when:
- `look.homePlates == false` (HomePlate.swift:149). Default true (Look/WorldLook.swift:80).
  Set false only in tests: Tests/WorldScreenshots/WorldScreenshotTests.swift:238 (`spriteLook`),
  PlateTests:431, MapSkyTests:38, PaintedSkyTests:102. No App/ code sets it. TuningLab
  (App/Rehearsal/TuningLab/TuningLab.swift:121) builds a WorldLook with the default (true).
  Path frames assert it is true (Tests/WorldScreenshots/PlayerPathScreenshotTests.swift:91).
- `HomePlate.shipped == nil`, i.e. plate-home.json fails to load (HomePlate.swift:77,
  PlateIsland.swift:289-295, `try?` decode). Missing images are not checked here.
- `state(...)` is nil (HomePlate.swift:155): `dayStage(islandLevel:)` nil when level < lowest stage
  level (PlateIsland.swift:275-277). Data: stageLevels [10..1], minLevel 1 (Resources/Plates/plate-home.json),
  so only islandLevel < 1 falls back. GameState default is 1 (PofuCore/Game/GameState.swift:452).
  DOC WRONG: HomePlate.swift:16 says "from island level 2"; and IslandScene.swift:264 "by day, in clear weather".
- No painted light borrowable at that hour (`paintedState`, HomePlate.swift:116-125). Home paints day at
  all 10 stages, night 10, golden 1 (`lightStages`); golden borrows night then day, night borrows golden
  only (HomePlate.swift:102-106). Night at stage s: night is painted at all 10 per lightStages, so never nil.
  I did not read per-stage `painted` for home (the key is absent from plate-home.json; it uses lightStages).
Time of day / bedtime / weather: never force the sprite island (paintedState falls back to day/rain-less).
Level trailing: `model.presenting(world)` (IslandScene.swift:268) delays the level during the growth moment.
Other islands:
- Çağlayan: `resolveCaglayan` (PW/Plate/CaglayanPlate.swift:42-52) is nil when `look.homePlates` false,
  plate-caglayan.json missing, or `!world.caglayan.isArrived`; stage clamped 0...4, day and night painted at
  all five (plate-caglayan.json), so once arrived it is never nil. Sprite Çağlayan = before arrival.
- Koke: no plate data (only plate-home.json and plate-caglayan.json exist under Resources/Plates); drawn by
  code (KokeLayout, IslandScene.swift:657, :561). It does not use `homePlate`.
Map: not a fallback. At the Map the Home plate stays set and is cut to the island alone (`isleFade`,
IslandScene.swift:588-593; `mapSky` needs plate != nil, :577).
Flags: FeatureFlags.islandHome/worldHome are both true (App/Support/FeatureFlags.swift); they pick the
room vs island, not plate vs sprite. HomeView.swift:154 and WorldHome.swift:90 both build `IslandScene`.
Previews: Not found (no #Preview checked); screenshot tests above are the only sprite users I found.

## 2. residentSteps on the plate path
Computed every frame regardless of plate: IslandScene.swift:723 (`residents: residentSteps(directive:)`),
no `homePlate` guard in 484-509. Only early outs: bedtime (:486), pinned time, and `still` / Reduce
Motion / Low Power / non-moving directive returns [:] (:488-495).
The brief's premise is partly false: the plate does NOT discard it. The plate draw reads `life.residents`
at :1483: `step.hop`, `step.pose`, `step.breath`, `step.lean` all feed ResidentView (:1484-1500).
Only `step.dx/dy` (the walk) are sprite-only (:1237); plate feet come from `plate.residentFeet` (:1313-1314).
So the walk target search is the only wasted part, and it uses the SPRITE island's feet and walkable
polygon (:497-505), not the plate's.
Cost, by reading (not measured), per frame while Ambient:
- `IslandLayout.residents` = 2 (Layout/IslandLayout.swift:87-92); `maxMovers` 2 (ResidentLife.swift).
- `cycle(at:)`, then `plans`: per resident one FNV hash over the id's unicode scalars, a SplitMix RNG,
  with p=0.55 a `walkTarget` of up to 16 tries, each 9 `walkable.contains` ray-casts (O(polygon points))
  plus a few distance checks (ResidentLife.swift walkTarget). Worst case about 2 x 16 x 9 = 288 polygon tests.
- `WorldArt.walkable("island-main")` rebuilds a WorldPolygon from the generated array each call
  (Geometry/WorldGeometry.swift:141-143, IslandFootprint.swift:20); array copy of a points list.
- Allocations: specs array, drafts, a [String: Step] dictionary, `avoid` arrays per resident.
- `step(of:)` x2: a few sin/cos. Nothing is cached between frames: the plan is re-derived from
  (day, cycle, id) each frame, so it is deterministic and repeated.
Not found: any measurement or profile of it.

## 3. CI durations, last five successful runs of "CI" on main (workflow push runs)
Source: gh api repos/ErenDenizK/pofu/actions/runs?branch=main&status=success, then .../runs/<id>/jobs
(completed_at - started_at, whole minutes). Timeouts from .github/workflows/ci.yml:26,102,209,379,477.
Run (UTC):            changes | build-and-test (45) | path-frames (45) | python-tools (15) | publish (10)
44193150493 11-17 22:45:   0   | 9 | skipped | skipped | skipped
43984705293 11-17 00:05:   0   | 31 | 11 | 10 | 8
43966759188 11-16 22:06:   0   | 31 | 18 | 7 | 5
43878434128 11-16 13:42:   0   | 36 | 15 | skipped | 9
43861091405 11-16 11:49:   0   | 33 | 13 | skipped | 4
Nearest the 45-minute limit: "Test PofuKit and build the app" at 31 to 36 min (36 = 80% of 45, a 9 min
margin) in four of five runs; one run was 9 min (changes filter skipped the rest). path-frames max 18.
python-tools max 10 of 15 (67%); publish max 9 of 10 (90%, but not a 45 job).
Note: the newest successful main run is 11-17, seven days before today; later main runs were not
successful or not push runs (I did not check why).
