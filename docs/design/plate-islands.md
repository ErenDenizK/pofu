# Plate islands: implementation spec

Status: draft for ADR-0022 (Proposed). Executes the hybrid plate-first
technique for Revontuli. Two PRs that own disjoint files; merge (ii) first.
No judgement calls are left to the implementer: where a number is needed it
is given; where something is out of scope it says so.

Evidence and pictures: `docs/research/pale-assets.md`,
`docs/research/plate-pilot/` (pilot, light-fit, mechanisms); the reference
code is `tools/plate/pilot.py` and `tools/plate/proofs.py`.

## 0. The contract both PRs share

Art inputs (written by the art pipeline, read by ingest):

- Plates: `design/art/masters/<island>-plate-<light>-<stage>/<same>.png`,
  1536 x 1024, opaque, all stages and lights registered edits of one final.
  `<light>` is `day`, `night` or `golden`; Revontuli has `night` only.
- Upgrade edits: `design/art/masters/<island>-up-<id>-<light>/<same>.png`, an
  edit of the stage 4 plate with one upgrade painted in.
- Hand data: `design/art/plates/<island>/objects.json`:

```json
{
  "trace": [[3, 52], [8, 45]],
  "objects": [
    {"id": "sauna", "tap": true, "label": "revontuli.sauna", "points": [[12, 46], [12, 30]]},
    {"id": "spruce", "occluder": true, "sway": 4, "points": [[72, 44.5], [80, 10], [89, 44.5]]},
    {"id": "lantern", "emissive": true, "points": [[50, 12], [55, 12], [55, 24], [50, 24]]}
  ],
  "reveal": [[52, 18], [52, 18], [52, 18], [52, 18]],
  "lightDirection": [0.6, 0.35]
}
```

  Points are percent of the 1536 x 1024 plate. `trace` is the island's
  silhouette (as `TRACE` in `pilot.py`). `reveal[n]` is where the stage
  n → n+1 reveal starts. `sway` is the top's amplitude in points.

Outputs (written by ingest into `Packages/PofuKit/Sources/PofuWorld/Resources/`):

| Output | Name | Format |
|---|---|---|
| Plate | `World.xcassets/world-<island>-plate-<light>-<stage>.imageset` | RGBA PNG at full resolution, cropped to the matte's box plus 8 px, matte in alpha, `detail.keep` 1.0, no lock |
| Diff mask n → n+1 | `world-<island>-diff-<light>-<n>` | 8-bit grey PNG at half size of the plate |
| Occluder cut-out | `world-<island>-occ-<id>-<light>-<stage>` | RGBA PNG, the plate's pixels inside the object's mask, same box as the plate |
| Emissive | `world-<island>-emit-<light>-<stage>` | RGB PNG at half size, light only (black elsewhere) |
| Upgrade patch | `world-<island>-up-<id>-<light>` | RGBA PNG cropped to its diff box, alpha = diff mask |
| Fitted LUT | `world-lut-plate-<island>-<light>` | the 17³ strip format of `tools/looklab/bake_luts.py write_strip` |
| Metadata | `Plates/<island>.json` | schema below |

`Plates/<island>.json` (all coordinates in plate pixels of the cropped plate):

```json
{
  "island": "revontuli", "version": 1,
  "plateSize": [1480, 900], "stages": 5, "lights": ["night"],
  "islandBox": [0, 0, 1480, 900],
  "reveal": [[770, 160], [770, 160], [770, 160], [770, 160]],
  "lightDirection": [0.6, 0.35],
  "objects": [
    {"id": "sauna", "tap": true, "label": "revontuli.sauna",
     "polygon": [[180, 410], [180, 270]], "footY": 425,
     "occluder": false, "sway": 0, "emissive": false}
  ],
  "upgrades": [{"id": "bench", "box": [100, 380, 190, 445], "footY": 440}],
  "lightMap": {"night": [["#c9c2e0", "#cfc8e4"]]},
  "textureBytes": 5800000
}
```

`lightMap[light][stage]` is a 32 x 20 grid (rows of 32 hex colours): in each
cell the mean colour of the plate's lit pixels (L* at or above the cell's
60th percentile, alpha > 0.99), empty cells filled from neighbours. The
character light (§1.4) reads it.

## PR (ii): tooling, `tools/plate/ingest.py` (merge first)

Branch `feat/plate-ingest`. Owns `tools/plate/ingest.py`,
`tools/plate/test_ingest.py`, `tools/plate/README.md` and one step in
`.github/workflows/ci.yml`. Python 3, numpy, Pillow, scipy; OpenCV only in
`matte` (as `tools/assets/caglayan_matte.py`). Reuse, do not copy:
`pilot.matte`, `pilot.bbox`, `pale.register`, `tools/looklab/lab.de2000`,
`tools/looklab/grade.lut_from_pairs`, `tools/looklab/bake_luts.write_strip`.

Commands (`python3 -I tools/plate/ingest.py <command> <island> [options]`):

1. `matte`: GrabCut each stage's plate inside a band around `trace` (as
   `pilot.matte`, sky-ish pixels forced to background), keep pixels at least
   3 of 5 stages agree on, fill holes, feather 1.2 px. Writes
   `design/art/plates/<island>/matte.png` (committed; later commands need no
   OpenCV).
2. `deliver`: every plate × matte → crop to the matte box + 8 px → imageset.
   Refuses a plate that is not 1536 x 1024.
3. `diff`: for each light and n in 0..3: `de2000(stage n, stage n+1)`,
   Gaussian 3 px, `smoothstep(6, 16)`, inside the matte, dilate 6 px, blur
   6 px, half size, 8-bit (as `pilot.diff_mask`).
4. `objects`: polygons from percent to cropped plate pixels; `footY` = the
   polygon's lowest y; occluder cut-outs (polygon ∩ matte, feather 1 px) per
   light and stage; emissive: for `emissive` objects, the plate's pixels with
   L* > 70 and hue 40°..90° inside the polygon, blurred 2 px; for islands with
   a day plate, emissive = max(0, night − day) in linear light instead.
5. `lightmap`: the 32 x 20 grid per light and stage.
6. `lut`: for each light without a painted plate at some stage: fit
   `lut_from_pairs(day stage 4, painted light stage 4, matte)` and write the
   strip. Never fit across islands (light-fit: 11 to 13 dE2000).
7. `upgrade`: diff of the upgrade edit against stage 4 of the same light
   (as `diff`), crop to the mask box + 4 px, alpha = mask.
8. `json`: writes `Plates/<island>.json`; `textureBytes` = sum over plates
   and cut-outs of width × height (ASTC 4x4, 1 byte per pixel) + masks at
   1 byte per pixel.
9. `check`: fails (exit 1, one line per problem) when: plates differ in
   size; outside the diff masks, two stages of one light differ by mean
   dE2000 > 3 ("moved"); a polygon leaves the matte by more than 4 px;
   `textureBytes` > 8 MB; a referenced asset is missing.
10. `check-frame FRAME.jpg --stage N --light L`: registers the plate in a CI
    frame (`pale.register`) and fails when the per-channel fit has gain < 0.9
    or lift > 0.05 over the island's top 70 %, i.e. any veil (today's
    Çağlayan frame fails with 0.64 / 0.32).
11. `all`: 1 to 9 in order.

Tests (`test_ingest.py`, `unittest`, synthetic images only, no art files):
matte agreement keeps a disc drawn in 3 of 5 images and drops one drawn in
1; `diff` of identical images is all zero and of a moved square is non-zero
only around both squares; polygon conversion round-trips; `footY` is the max
y; the light map of a flat image is that colour everywhere; `check` flags a
2 px shift outside the diff mask as "moved"; `check-frame` passes an image
pasted unchanged and fails one mixed 30 % toward white; `json` matches the
schema keys above.

CI: in `.github/workflows/ci.yml`, next to the `tools/assets` step, add
`python3 -I -m unittest discover -s tools/plate -p "test_*.py"`.

## PR (i): Swift runtime in PofuWorld

Branch `feat/plate-islands`. Owns new files under
`Packages/PofuKit/Sources/PofuWorld/Plate/`, new tests under
`Packages/PofuKit/Tests/PofuWorldTests/`, a new screenshot test in
`Tests/WorldScreenshots/`, and the listed edits to `IslandScene.swift`,
`WorldHitTest.swift` and `WorldShaders.metal`. It must build and pass with no
plate assets present (placeholder as Çağlayan's), so it does not wait for
art.

### 1.1 Pure model (Linux-tested)

`Plate/PlateIsland.swift`:

- `public struct PlateIsland: Codable, Hashable, Sendable` mirroring the JSON
  (`plateSize`, `stages`, `lights`, `islandBox`, `reveal`, `lightDirection`,
  `objects: [PlateObject]`, `upgrades: [PlateUpgrade]`, `lightMap:
  [String: [[[String]]]]`, `textureBytes`).
- `static func load(_ island: IslandID) -> PlateIsland?` from
  `Bundle.module` `Plates/<id>.json`; `nil` when absent.
- Asset names: `plateArt(light:stage:)`, `diffArt(light:from:)`,
  `occluderArt(id:light:stage:)`, `emissiveArt(light:stage:)`,
  `upgradeArt(id:light:)`, `lutArt(light:)`, all matching §0.

`Plate/PlateMath.swift` (`public enum PlateMath`, all pure):

- `contains(_ polygon: [PlatePoint], _ p: PlatePoint) -> Bool` (even-odd).
- `hit(_ island: PlateIsland, at p: PlatePoint) -> PlateObject?`: the tap
  objects containing p, the one with the largest `footY` (nearest) wins.
- `revealAlpha(distance d: Double, progress t: Double) -> Double`:
  `smoothstep(r, r - 0.08, d)` with `r = 1.1 t` (pilot), and
  `globalFade(t) = smoothstep(0.3, 0.9, t)` for unchanged pixels.
- `drawOrder(characters: [(id: String, footY: Double, box: PlateRect)],
  occluders: [PlateObject]) -> [PlateLayer]`: a character goes under an
  occluder when its `footY` < the occluder's `footY` and their boxes overlap;
  returns layers back to front.
- `light(at p: PlatePoint, map: [[String]], plateSize:) -> PofuRGB`:
  bilinear in the 32 x 20 grid.
- `characterGain(light: PofuRGB) -> PofuRGB`: as `pilot.lit_from_plate`:
  linear(light) / linear(0.95, 0.95, 0.96), normalised to max 1, times
  min(1, sqrt(mean ratio)).
- `contactRatio(lit: PofuRGB, shadow: PofuRGB) -> PofuRGB`: linear
  shadow / lit, clamped 0.15...1.
- `castShadowShear(direction:) -> (dx: Double, scaleY: Double)`: shear
  0.5 × dx, scaleY 0.35.
- `swayOffset(y:footY:topY:amplitude:time:) -> Double`:
  `amplitude × ((footY − y) / (footY − topY))^1.6 × sin(2π × 0.25 × time)`,
  0 below the foot.
- `framing(plateWidthUnits:screenWidthPoints:) -> Double`: the close scale
  that makes the island 1.35 screen widths.
- `budgetOK(_ island:) -> Bool`: `textureBytes <= 8_000_000`.

`Plate/RevontuliLayout.swift`: `IslandID.revontuli`, `CameraPlace.revontuli
(z: 1)`, `center = WorldPoint(x: 150, y: 660)`, `plateWidthUnits = 212`,
`closeScale = PlateMath.framing(...)` for 402 pt, `stages = 5`, `light =
"night"` (its own polar night: no day plate, no LUT), aurora strength by
stage `[0, 0, 0.25, 0.4, 1.0]`.

### 1.2 Views (iOS only, `#if os(iOS)`)

`Plate/PlateIsleView.swift`, modelled on `CaglayanIsleView`
(`Caglayan/CaglayanScene.swift`), back to front:

1. code layers behind the plate: `PlateAuroraView` (two curtain images
   `world-revontuli-aurora-1/-2` when present, else nothing), drawn with
   `.blendMode(.screen)`, opacity = the stage's aurora strength;
2. the plate `Image(plateArt)`; during a stage change the old plate, then the
   new one masked by `ZStack { Color.white.opacity(globalFade(t));
   Image(diffArt).luminanceToAlpha().mask(RadialGradient(...)) }` where the
   gradient's stops follow `revealAlpha` from `reveal[n]`; 2.4 s
   (`CaglayanLayout.crossfadeSeconds`); Reduce Motion: plain 0.3 s opacity;
3. sway: the plate gets `.distortionEffect(ShaderLibrary.bundle(.module)
   .pofuPlateSway(...))` with up to 4 objects' (minX, maxX, topY, footY,
   amplitude) as a float array and the time; add `pofuPlateSway` to
   `WorldShaders.metal`: offset x by `swayOffset` times a soft ellipse weight
   of the object's box (the plate is transparent around it, so only the
   object moves; `proofs.py sway` shows it);
4. emissive: `Image(emissiveArt).blendMode(.plusLighter)` with opacity
   0.85 + 0.15 × flicker (the existing lantern flicker), only at night;
5. characters (the duo, residents, critters) via `PlateCharacterView`;
6. occluder cut-outs above the characters that `drawOrder` puts behind them;
7. upgrade patches owned by the player (`Image(upgradeArt)` at its box),
   revealed with the same mask math when bought;
8. the tap highlight: the tapped object's polygon as a `Path`, filled white
   at 6 % and stroked 2 pt warm (#FFE0A0) where outside the plate's alpha
   (draw it, then `.mask(Image(plateArt))` inverted for the rim), 0.25 s in,
   0.4 s out.

`Plate/PlateCharacterView.swift`: wraps a sprite: `.colorMultiply(gain)`
from `characterGain(light(at: feet))`; a contact pad ellipse (0.92 × 0.18 of
the sprite width) filled with the `contactRatio` colour, `.blendMode
(.multiply)`, opacity 0.75; a cast shadow: the sprite's silhouette
(`.renderingMode(.template)`) in the ratio colour, sheared by
`castShadowShear`, multiply, opacity 0.35. Gain updates when the feet move,
not per frame.

### 1.3 Scene wiring (edits)

- `IslandScene.swift`: add `revontuliIsle` next to `caglayanIsle` (line ~1190),
  drawn only when `Plates/revontuli.json` loads and the island is present.
  The plate island is drawn **outside** the world's `GradeEffect`, the depth
  of field and the LUT, in its own layer above the cloud sea's back rows;
  when `model.island` is a plate island, `FogCards(layer: .front)` (line
  ~703) and `ScreenHazeLayer` (line ~711) are not drawn. Wellbeing at a plate
  island acts on the sky, the sea and the aurora strength only.
- `WorldHitTest.swift`: `HitTarget.Kind.plateObject(IslandID, String)`; at
  a plate island's stop the targets are its tap polygons through
  `PlateMath.hit` (the box-based targets stay for every other island).
- Frame rate: settled at a plate island is 0 Hz like elsewhere
  (`FramePolicy`); the aurora, sway and flicker tick only in the Ambient
  state; Reduce Motion stops sway and aurora drift.

### 1.4 Tests (Linux: `tools/swift/test-linux.sh -j 1 --filter Plate`)

`PofuWorldTests/PlateMathTests.swift`: point in a concave polygon and out of
its notch; `hit` prefers the larger `footY`; `revealAlpha` is 1 inside the
ring, 0 outside, monotonic in t; `globalFade(0) == 0`, `(1) == 1`;
`drawOrder` puts a character with smaller `footY` under an overlapping
occluder and leaves a non-overlapping one on top; `light(at:)` of a constant
map is that colour and interpolates between two cells; `characterGain` of
white is 1; `contactRatio` clamps; `swayOffset` is 0 at the foot and
largest at the top; `framing` gives 1.35 widths; `budgetOK` at 8 MB.
`PofuWorldTests/PlateIslandTests.swift`: decodes the §0 example (a string in
the test); asset names match §0; `load` returns nil without the resource.
`PofuWorldTests/RevontuliLayoutTests.swift`: its box does not overlap
Çağlayan's, Koke's or the home plate's; stages clamp to 0...4.

Screenshot test (CI): `Tests/WorldScreenshots/PlateScreenshotTests.swift`
renders `revontuli-stage-0..4`, `revontuli-reveal-0..3` (t = 0, 1/3, 2/3, 1)
and `revontuli-tap`; the lead runs `ingest.py check-frame` on them (no veil).

### 1.5 Memory and battery

At most two plates and one diff mask resident (old and new during a reveal),
everything else loaded on arrival: under 8 MB per island (`budgetOK`). Plates
in the asset catalog with GPU compression (ASTC). No per-frame CPU work at
rest.

## Out of scope

Revontuli's gameplay (flow round, bubbles, Söz 4), the Tuli rig, the
aurora curtain art (batch 53), repainting old islands, removing the veil
from Çağlayan and the home (a separate fix, `pale-assets.md` §3), and any
Codex manifest change.
