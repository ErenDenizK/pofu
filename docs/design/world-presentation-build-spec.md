# World presentation: the build spec

**Status:** spec, 2026-11-15. Turns the agreed world-presentation design
into PRs a builder can run without judgement calls.
**Base:** `origin/main` at `b424f1bd`. Every `path:line` below is at that
commit; `PW/` is `Packages/PofuKit/Sources/PofuWorld/`, `PT/` is
`Packages/PofuKit/Tests/PofuWorldTests/`.
**Design it builds** (branch `design/feel-and-world`, PR #461, not on main):
`docs/design/world-presentation-v2.md` (v2) as corrected by
`world-presentation-round3-look.md`, and `world-concepts-plan.md` with its
"Round 1 result". **Facts:** `docs/research/world-presentation-facts-2026-11-14.md`,
`feel-motion-facts-2026-11-14.md`, `world-v2-facts-2026-11-15.md`.
**Taken as decided:** Map order A (Home low in front, Koke and Çağlayan
rising behind); the targets are the picked concepts map-locked t1,
mid-locked t1, near-locked t2; stations show their own level; near is a
macro shot with a thin-lens depth model at a 10.5° camera; water is a
region shader (proof 4, option c); one camera with a depth function
(proof 3, option b); 120 Hz only under the finger (#464, merged); the heat
rule in `PofuTimeline` (#460, merged); the pots, jar and lantern come back
over the plate (v2 §6.3).

## 0. Premises that are false at the base commit

Read these before anything else; three of them change the order of work.

1. **The proof scripts are not on main.** `tools/proof/` does not exist at
   `b424f1bd`, and `tools/art/matte_check.py` is not there either. They
   live on seven open, stacked PRs: #463, #465, #466, #470, #471, #472,
   #473. `tools/proof/island_matte.py` exists in three versions: 126 lines
   (#463, #466), 587 lines (#471, #472, #473; the one `match.py` and
   `composition.py` import) and 743 lines (#470, the `r3b` matte that
   passed M1 to M11, a superset of the 587-line one). Nothing below can
   run these scripts in CI until they land. WP1 lands them.
2. **The match proof's outputs are only in a scratch folder** that a
   restart clears. This PR commits the three picked targets, the three
   match frames, the round-3 edge sheet and the layout wireframe under
   `docs/design/assets/world-concepts/` (section 9), so every "eye" PR has
   a reference that exists.
3. **The r3b mattes were checked on 4 of 21 Home states**, not 20: the
   checks folder holds `day-L4`, `day-L10`, `night-L4`, `night-L10` only.
   The round-3 fix pass ("run all 20 Home plates") is not done. WP4 runs
   all 21 and gates on them.
4. **A full-size matte as its own texture does not fit.** The per-state
   texture budget is 9 MB (`tools/plate/ingest.py:64`, ASTC at 1 byte a
   pixel, `:851-853`) and Home already uses 8,028,622 bytes
   (`plate-home.json` `textureBytes`). A 2048 x 3072 matte adds 6.3 MB.
   Decision D1 puts the matte in the plate's own alpha instead.
5. **The backdrop holds a copy of the island.** `backdrop()` says "Inside
   the plate's rectangle it is the plate" (`tools/plate/ingest.py:399-403`).
   With a tight matte, that low-resolution island would show round the
   rim as a halo. WP4 inpaints it.
6. **Every lower level shares the level-10 matte** (`load_matte`,
   `tools/plate/ingest.py:318-324`), which is where the ghosts below
   level 10 come from (`tools/plate/map_cut.py` exists only to remove
   them). The r3b matte is per stage.
7. **"Life costs no app frames" is unmeasured.** v2 §3 assumes render-server
   transforms; scout fact 8 was not answered (`world-v2-facts`, header).
   Today the sky set is one `Canvas` redrawn in the app through
   `PofuTimeline` at `SkyMotion.frameRate = PofuFrameRate.drift`, 15 Hz
   (`PW/Sky/SkySet.swift:181`, `PW/Sky/SkySetView.swift:43`). WP9 measures
   it first and has a fallback that needs no judgement.
8. **ADR-0019 forbids what near needs.** "There is still no free camera
   and no placement" (`docs/adr/0019-home-cluster-and-wonder-islands.md`,
   the island-framing bullet). v2's free near range with two-axis pan
   reverses it, and ADR-0018's three framings (Home, island, Map) become
   Map, mid, near. WP7 writes ADR-0027.

## 1. What "done" means (as the founder sees it on his iPhone 17)

1. **Opening the app (mid).** The whole island sits in the middle of the
   screen, nothing cut by an edge; the line card, Collect and the glance
   rest on a soft cloud bank, not on fog. The jar stands front centre,
   today's pots on the left lip, the lantern on the right. A resisted reach
   becomes a pot he can find without being told.
2. **Pinching out (Map).** One continuous move. Home sits low and large in
   front; Koke and Çağlayan rise behind it across the cloud sea; the far
   isles and the whale are hazed by distance; the cloud rows shrink toward
   the horizon. On day 1 the empty slots hold cloud towers, never a hole.
3. **Pinching in (near).** Past mid the chrome fades and the picture
   re-centres. A double tap on Pofu lands where he is about 122 pt wide:
   his row and the lawn round his feet sharp, the windmill behind softly
   out of focus, the sky soft, the island's rim hidden by a soft
   foreground.
4. **Building.** A station wears the look of its own level, at any island
   level, revealed by a ring from its foot; the Map shows the same island.
5. **Life.** At every distance the sky moves slowly; nothing slides like a
   conveyor. Under Reduce Motion, Low Power or a still frame, nothing
   moves.
6. **Edges.** In 1:1 crops at device size there is no rectangle, haze
   band, halo or ghost, over day, golden and night.
7. **Heat.** A still screen redraws no faster than today; the finger still
   gets 120 Hz.

Measured, as guards (numbers never clear a frame by themselves):
`tools/proof/frame_match.py` band RMS of each target frame against its
picked concept at or below the match proof's (Map L 5.5 / S 7.4, mid
L 3.8 / S 3.1, near L 2.9 / S 6.2) plus 1.0; C1 to C6 green on the three
target frames; `matte_check.py` green on every shipped matte and look.

## 2. Scope

**In:** Home's painted plate at Map, mid and near; Koke and Çağlayan as
they appear on Home's Map (positions, haze, bob); the cloud floor, lip,
towers, veils, far isles and whale; station looks for the eight Home
stations; the jar, pots and lantern; the thin lens; water, sway and
emissive region shaders on Home; the unlock, tier and level-up reveals.

**Out:** section 10.

## 3. Where we stand (evidence)

| Area | Today | Evidence |
|---|---|---|
| Framings | Three stops while the plate shows: Map, Island (0.9 widths, no chrome), Home (1.15 widths, 1.40 pt/unit, chrome) | `PW/Plate/HomePlate.swift:420-424, 438-439, 468-470`; `PW/Layout/IslandFraming.swift:42`; chrome only at `.home`: `PW/Home/WorldHome.swift:195-197` |
| Map fit | The union of Home, Koke and Çağlayan, every day, between the bands | `PW/Plate/HomePlate.swift:448-466` |
| Map order | Koke and Çağlayan below Home (+y is down; Home's box centre is at world (40, 19)) | `PW/Koke/KokeLayout.swift:62` `(-100, 410)`; `PW/Caglayan/CaglayanLayout.swift:63` `(150, 440)`; Home's box: `plate-home.json` `islandBox` [4, 438, 1019, 1230] at 0.3253 units/px (`PW/Plate/HomePlate.swift:57-62`) gives x -125 to 206, y -110 to 148 |
| Map sky | Its own camera, fixed scale, parallax 0.06 | `PW/Plate/PaintedSky.swift:163, 362-372`; drawn at `PW/Scene/IslandScene.swift:703-712` |
| Island art by distance | Half-size `mapisle` cut fades to the plate between z 0.55 and 0.95 | `PW/Plate/PlateHomeViews.swift:54-58`; `PW/Scene/IslandScene.swift:567-569` |
| Edge | Plate border feathered 48 px; lower levels use level 10's matte; matte masters 1024 x 1536 | `tools/plate/ingest.py:93, 486-492, 318-324`; `design/art/plates/home/matte-day-0.png` |
| Backdrop | Static JPG at levels 1 to 9; sky set at level 10 only | `PW/Plate/PlateHomeViews.swift:101-106` |
| Props | Not drawn and not tappable on the plate | `PW/Scene/IslandScene.swift:848, 946` (`if let props, plate == nil`); `PW/Scene/WorldHitTest.swift:134-135` |
| Station levels | Select nothing on the plate; presence follows the painted stage | `plate-home.json` `objects[].stages`; `PW/Plate/PlateIsland.swift:62-64` |
| Zoom | Pinch limit 1.40 x 1.25 = 1.75 pt/unit; zoom about the anchor, not the fingers | `PW/Camera/CameraRail.swift:128-129`; `PW/Camera/CameraRig.swift:331` |
| Depth blur | Off on any painted plate | `PW/Scene/IslandScene.swift:532, 665` |
| Lens model | Sprite-world slab lens, levels 0 to 2 | `PW/Depth/Lens.swift` |
| Frame rates | `drift` 15, `idle` 20, `event` 30, `direct` 60, `touch` 120 | `Packages/PofuKit/Sources/PofuDesignSystem/PofuTimeline.swift:11-24` |
| Player-path frames | 21 days; Map frames on days 1, 3, 6, 7, 11, 13 | `Tests/WorldScreenshots/PlayerPathScreenshotTests.swift:40-65`; branch `screenshots/main` |

## 4. Gaps, ranked by what the player feels

| # | Gap | Evidence | Closed by |
|---|---|---|---|
| G1 | **The pots, jar and lantern are gone from the painted Home.** A resisted reach leaves nothing on the island; the jar he collects is not there | `PW/Scene/IslandScene.swift:848, 946`; `PW/Scene/WorldHitTest.swift:134-135` | WP5 |
| G2 | **The everyday screen is cropped and top-heavy.** Home shows the island 1.15 widths wide with its sides cut; the chrome sits on fog | `plate-home.json` `framing.homeWidths` 1.15; `PW/Plate/HomePlate.swift:420-424` | WP7 |
| G3 | **The Map is two pictures stacked.** Home mid-screen, neighbours below it, 57 % cloud floor on day 1 | `PW/Plate/HomePlate.swift:448-466`; `PW/Koke/KokeLayout.swift:62`; `PW/Caglayan/CaglayanLayout.swift:63` | WP6 |
| G4 | **Edges.** Blue-grey band under the earth, a feathered rectangle, ghosts below level 10 | `world-v2-facts` §10 (opaque plate pixels at y 2360 to 2470); `tools/plate/ingest.py:93, 318-324` | WP4 |
| G5 | **Building does not show.** A station's level changes nothing on the plate; the windmill exists only at levels 8 to 10 | `plate-home.json` `objects` windmill `stages [0, 1, 2]` | WP8, WP10 |
| G6 | **The sky has no weight and no depth.** One floor texture, one puff size; a static JPG below level 10 | `PW/Plate/PlateHomeViews.swift:105-106`; match proof's Map list | WP2, WP9 |
| G7 | **There is no close look.** The closest held zoom is 1.75 pt/unit, Pofu 47 pt; no depth on the plate | `PW/Camera/CameraRail.swift:128`; `PW/Scene/IslandScene.swift:665` | WP7, WP11 |
| G8 | **Water is still.** The falls and pond are baked into the plate | `feel-motion-facts` §2 (Çağlayan, Home) | WP13 |
| G9 | **Unlocks and new tiers happen off-screen** | v2 §9.2 has no code | WP12 |

## 5. Decisions

| # | Decision | Alternative not taken |
|---|---|---|
| D1 | The full-size matte is the alpha of the shipped plate HEIC (`world-home-plate-<light>-<stage>`, later `-base-`); the RGB at edge pixels is decontaminated. No `matte` asset (v2 §6.1 is corrected) | A separate matte texture: +6.3 MB a state, past the 9 MB budget (section 0, item 4) |
| D2 | The backdrop JPG is inpainted inside the matte grown by 24 px with `tools/plate/inpaint.py`, so no copy of the island is behind it | Keep the backdrop as is: a low-resolution island halo round the rim |
| D3 | Mattes are made offline only (BiRefNet-lite ONNX, 224 MB, `POFU_BIREFNET`); the app never runs a segmentation network. Runtime derives only: blur masks from the mask's depth channel, the veil from the snapshot's alpha, the island shadow from data, cloud shadows clipped by plate alpha | Vision's foreground mask on device: not deterministic, not checkable by `matte_check.py`, costs time at launch |
| D4 | `WorldFraming` keeps three cases and raw values but becomes `map`, `mid`, `near`. On Home, today's Island stop (no chrome) and Home stop merge into `mid` (fit to the level-10 box, chrome); `near` is the free range from 1.25 x mid to 7.4 pt/unit, rest at 4.5. A wonder island's stop is its `mid`. ADR-0027 records it | Four stops (Map, Island, Home, near): two near-identical framings at Home, and v2's release table (0.5, 1.12) cannot express them |
| D5 | Map positions, tier pitch, frame fits and slot contents are data in `PW/Resources/Plates/world-map.json`, relative to Home's box centre; `KokeLayout.center` and `CaglayanLayout.center` read it | Swift constants: every tuning pass is a code PR |
| D6 | The life layers run as render-server animations only if WP9's measurement shows no body evaluations while they move; otherwise they are drawn in the sky set's `Canvas` through `PofuTimeline` at `PofuFrameRate.drift` | Assume render-server is free (the unmeasured premise, section 0, item 7) |
| D7 | Station looks ship at twice the plate texture (4 texture px per plate px); the per-state budget becomes 14,000,000 bytes (`BUDGET`, `tools/plate/ingest.py:64`); the station occluders retire when looks ship (a look is its own occluder, sorted by `footY`) | Looks at plate resolution: not sharp at near (0.46 texture px per device px). Loading the 2x look only when focused: a second asset path for one shot |
| D8 | The props come back first (WP5), drawn through today's `props.world` path at slots from the plate data and cut by today's occluders; WP10 later re-sorts them by `footY`. Painted art from batch 111; if its pick fails M2 to M6 or is not recorded, the shipped `ui-*` sprites with the plate's harmony tint | Wait for the compositor: the core loop's only visible payoff stays missing for weeks |
| D9 | Near blur goes by row: ground pixels by their own plate row, a standing thing (look, prop, character, dressing) by its `footY`; anything painted on the base that is not in the data blurs by its pixel's row | A per-pixel depth map: no Codex job can paint one and the plate has none (the match proof's near limit) |
| D10 | The blur is four cached levels (0, 2, 6, 14 pt) blended by masks from the depth channel, one shader reading the levels (v2 §5.4's choice made here) | A per-pixel kernel every frame: cost under a pinch |
| D11 | Eye PRs are judged against the **match** frame (what can be built) for acceptance and shown beside the **target** (the pick) for direction | Judging against the target: it contains what will not be built (the match proof's limits, section 6.4) |
| D12 | `PW/Scene/IslandScene.swift` (2,451 lines) and `PW/Scene/IslandSceneModel.swift` (1,592) are shared: a PR puts its code in new files and edits those two only at the call sites it names, rebasing before each push | Serialise every Swift PR behind one another |

**ADR:** D4 (and the free near camera) reverses ADR-0018's framings and
ADR-0019's "no free camera"; undoing it would cost days, so WP7 adds
`docs/adr/0027-one-camera-free-near.md`. D1 to D3 and D7 sit inside
ADR-0022 option (e) and ADR-0024; no ADR. Map order A is data (D5) and
costs an hour to reverse; no ADR.

**Tunable numbers go in data, not code:** `world-map.json` (positions,
pitch, fits, horizon 0.53, backdrop lanes), `skyset-*.json` (`k`, `delta`,
motion), `plate-home.json` `camera`, `near.shots`, `props`, `stations`,
`shadow`; `tools/plate/ingest.py` `BUDGET` and `LOOK_SCALE`.

## 6. The asset pipeline, from a pofu-art pick to the app

### 6.1 Steps

1. Codex delivers on `art/<batch>` in `pofu-art` with a `review.yaml` per
   job; the lead records the pick there.
2. `python3 -I tools/art/ingest.py <pofu-art> --batch <batch>` copies each
   picked job folder to `design/art/takes/<batch>/<job>/` here (WebP, both
   takes). It only copies.
3. The kind's offline tool (table) makes the shipped layer and its data.
4. `matte_check.py` gates every cut-out (kind `island`, `look` or `prop`);
   `tools/plate/plate_gate.py` (WP4) runs it in CI on what ships.
5. `tools/plate/heic.py` writes HEIC q70 with alpha (ADR-0024); masks stay
   PNG (data, lossless).
6. `python3 -I tools/plate/ingest.py json home` writes `plate-home.json`
   and `textureBytes`.

### 6.2 What is made where

| Layer | Source | Offline tool | Ships as | Size | Runtime does |
|---|---|---|---|---|---|
| Island matte | the plate, BiRefNet-lite + r3b solve | `tools/proof/island_matte.py` (WP1), ingested by `ingest.py deliver` (WP4) | alpha of `world-home-plate-*`, later `world-home-base-*` | 2048 x 3072; master PNG `design/art/plates/home/matte-<light>-<stage>.png` at the same size | composites only |
| Backdrop | the plate, island inpainted | `ingest.py deliver` + `inpaint.py` (WP4) | `world-home-backdrop-*` JPG | as today, 614 x 1585 (scale 0.38, `ingest.py:91`) | nothing |
| Island shadow | the matte | `island_shadow()` in `island_matte.py` gives an ellipse | `plate-home.json` `shadow` {centre, radii, opacity} | data | drawn on the near floor layer (WP9) |
| Erased base | batch 117 take, region pasted back on the parent | `tools/plate/base_paste.py` (WP8) | `world-home-base-<light>-<stage>`, alpha = matte | 2048 x 3072 | replaces the plate |
| Station look | plate minus base where a plate paints it; Codex looks later | `tools/plate/look_cut.py` (WP8), `upscale.py --scale 2` | `world-home-look-<station>-<level>-<light>` HEIC, box crop | 4 texture px per plate px: tea stall 580 x 828, windmill 724 x 1004 (from the `objects` boxes) | sorted by `footY` |
| Look shadow | difference at the foot | `look_cut.py` | `...-shadow` HEIC, grey + alpha | 2 texture px per plate px | multiply under the look |
| Mask | `objects` polygons, `water_regions.json`, matte | `tools/plate/mask.py` (WP8) | `world-home-mask-<stage>` PNG RGBA: R water, G sway, B emissive, A depth row | 512 x 768 | blur masks and region shaders read it |
| Props | batch 111 sheet (10 objects) | `tools/plate/props_slice.py` (WP5) | `world-home-prop-<id>-<state>` HEIC | jar 448 px tall (142 pt at the near limit), pots 360, lantern 600 | placed at `props[].slots[stage]` |
| Cloud kit | batches 109 (lip), 115 (tower), 118, 120, volume | `tools/plate/cloud_kit.py` (WP9): trim, seam check, `matte_check --kind prop` M1 to M4 | `world-cloud-<id>` HEIC; tiles 2048 wide | puffs 512 to 1024 px | transforms, k, haze by `k` |
| Near patch, lawn tile, foreground | batches 110 (pick 4), 119 | `tools/plate/near_layers.py` (WP11) | `world-home-near-patch-<light>` 1024 x 512, `world-home-near-lawn` 1024 x 1024, `world-home-near-fore` | as listed | tinted by the plate under it, clipped to the lawn |
| Far picture | the mid composite | none | nothing | half the mid composite | `ImageRenderer` snapshot, cached by a state hash (WP10) |
| Veil | the far picture's alpha | none | nothing | | blur and tint at runtime (WP12) |

### 6.3 Budget per Home state (ASTC estimate, 1 byte a pixel; mask counted at 4)

| Layer | Bytes |
|---|---|
| Base (or plate) 2048 x 3072 | 6,291,456 |
| Eight looks at 4 texture px per plate px (215,426 plate px² of station boxes x 16) | 3,446,816 |
| Their shadows at 2 per plate px | 861,704 |
| Backdrop | 973,190 |
| Mask 512 x 768 RGBA | 1,572,864 |
| Decor occluders (wheel, mailbox, two bushes) | 336,788 |
| **Total, every station built** | **13,482,818** |

`BUDGET` becomes 14,000,000. The `island` and `mapisle` cuts retire with
WP10. If a state is still over, `LOOK_SCALE` drops from 2 to 1.5 (looks
x 9 instead of x 16, 1.5 MB less): no judgement.

### 6.4 What will not be built (the match proof's limits)

The match proof (`tools/proof/match.py`, PR #473) re-rendered the picked
frames from parts the build can have. What it could not reach is a limit
of this spec, not a defect of a PR:

- **Map:** clouds with volume need the cloud kit (batch 118 and the
  volume batch); far isles with their own haze need batch 120; cloud rows
  shrinking toward the horizon need the floor tiles by puff size. Until
  they land, the Map matches the proof's frame, not the pick.
- **Mid:** cloud forms with volume behind the controls, and a bank with no
  seam (109's wrapping lip failed; 118's `x-cloud-bank` fades at its ends).
- **Near:** a sharp lawn at near resolution (batch 119 `x-near-lawn-tile`);
  a soft foreground layer (119 `x-near-foreground-strip`); no depth mask
  in the plate, so blur goes by row (D9). The free near pick (a lower
  camera, Pofu 2.3 times larger) is a painted near plate and is not built.

## 7. Codex art: delivered, and not yet painted

**Delivered on open pofu-art PRs, to ingest when the lead records a pick:**
107 near dressing (#71, three jobs), 108 erase pilot (#72), 109 cloud kit
pilot (#73, lip pick 2, tower none), 110 near patch (#74, pick 4), 111
home props (#76, pick 1), 112 concept frames (#78), 115 tower v2 (#83,
pick 1), 116 mist clear (#84, no pick), 117 station erase volume (#85, 17
of 20 jobs carry a pick; `l01-night`, `l04-night`, `l08-day` do not).
Whether those `pick:` values are the lead's or Codex's own I did not check.

**Not painted yet; these PRs are scheduled behind them:**

| Art | Queue state | PR that waits | What ships without it |
|---|---|---|---|
| `batch-118-cloud-forms` (forms sheet, bank) | READY row 0-c6 | WP9 (mid bank, Map forms) | 109 lip pick 2 and the scaled existing tiles |
| `batch-120-far-isles-haze` | READY row 0-c8 | WP9 (Map far isles) | today's isles hazed by `k` in code |
| `batch-119-near-lawn-and-foreground` | READY row 0-c7 | WP11 (lawn, foreground) | 110 patch only; WP11's foreground step is skipped and listed |
| `world-cloud-kit` volume (about 10 jobs) | no manifest; written after 118 | WP9 final pass, WP12 towers | pilots |
| `world-station-looks-<station>` (30 to 40 jobs) | no manifest; v2 §7 | a data follow-up to WP10 | levels share the nearest lower look, no badge (v2 §7) |
| Near dressing volume | not queued (waits on the near pick) | WP11 | 107 pilot picks |
| Props night set | only if the grade fails | WP5 | day art graded by the plate's night harmony |

Queue note for the pofu-art lead: rows 0-b4 to 0-b8 (batches 107 to 111)
still read READY in `QUEUE.md` though they were delivered.

## 8. The PRs, in merge order

Three in flight at most. Every Swift PR runs
`tools/swift/test-linux.sh -j 1` before each push (three pushes at most,
CI waited on with one background command); iOS-only code compiles only in
CI, warnings are errors. A user-visible PR adds `changes/<branch>.md`.
Every eye PR posts 1:1 crops at 1206 x 2622 beside its reference.

| PR | Branch | v2 | Model | Accept | Size | Wave | After |
|---|---|---|---|---|---|---|---|
| WP1 Proof tools land | `chore/proof-tools` | (R1-R5) | Sonnet | test | S | **1** | none |
| WP2 One camera: the depth function | `feat/world-depth-function` | W2 a | Opus | test | M | **1** | none |
| WP3 Composition model | `feat/world-composition-model` | W3 a | Sonnet | test | M | **1** | none |
| WP4 Mattes and backdrop | `feat/plate-mattes` | W1 | Sonnet | eye | M | 2 | WP1 |
| WP5 The props come back | `feat/home-props-back` | W7 (early) | Sonnet | eye | M | 2 | WP1; batch 111 ingested |
| WP6 The Map, journey order | `feat/map-journey` | W3 b | Opus | eye | M | 2 | WP2, WP3 |
| WP7 Rail v2: mid and near | `feat/rail-mid-near` | W2 b, W3 c | Opus | eye | L | 3 | WP6 |
| WP8 Looks, bases and mask data | `feat/station-looks-data` | W5 | Sonnet | test | L | 3 | WP4; batch 117 picks |
| WP9 Cloud floor and life | `feat/cloud-floor-life` | W4 | Sonnet | eye | L | 3 | WP2, WP6 |
| WP10 The plate compositor | `feat/plate-compositor` | W6 | Opus | eye | L | 4 | WP5, WP7, WP8 |
| WP11 Near: the thin lens | `feat/near-lens` | W8 | Opus | eye | L | 5 | WP10; batch 119 for its last step |
| WP12 Unlock and tier reveals | `feat/world-reveals` | W10 | Sonnet | eye | M | 4 | WP6, WP9 |
| WP13 Region shaders | `feat/region-shaders` | W9 | Opus | eye | M | 5 | WP8, WP10 |

Merge order: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 11, 13. A wave starts
when the PRs it depends on are merged and a slot is free.

### First wave (start now, disjoint files)

| PR | Owns | Touches nothing in |
|---|---|---|
| WP1 | `tools/proof/**`, `tools/art/matte_check.py`, `tools/art/test_matte_check.py`, `.github/workflows/ci.yml` | `Packages/`, `Tests/` |
| WP2 | `PW/Camera/WorldDepth.swift` (new), `PW/Sky/SkySet.swift`, `PW/Sky/SkySetView.swift`, `PW/Plate/PaintedSky.swift`, `PW/Resources/Plates/skyset-home.json`, `skyset-caglayan.json`, the two sky call sites in `PW/Scene/IslandScene.swift`, `PT/WorldDepthTests.swift` (new), `PT/MapSkyTests.swift`, `PT/SkySetTests.swift`, `PT/PaintedSkyTests.swift` | `tools/`, `Layout/` |
| WP3 | `PW/Layout/ScreenBands.swift`, `PW/Layout/WorldMap.swift`, `PW/Layout/CompositionRules.swift`, `PW/Resources/Plates/world-map.json` (all new), `PT/ScreenBandsTests.swift`, `PT/WorldMapTests.swift`, `PT/CompositionRulesTests.swift` (new), `Tests/WorldScreenshots/WorldTargetScreenshotTests.swift` (new) | `tools/`, `Sky/`, `Scene/` |

### WP1: the proof tools land (Sonnet, test)

**Files:** `tools/proof/` from PR #473's head (`3e40c31c`) plus
`tools/proof/island_matte.py` and `tools/proof/round3.py` from PR #470's
head (`08880108`) and `tools/proof/station_looks.py` and
`tools/proof/README.md` from PR #465; `tools/art/matte_check.py` from #470;
new `tools/art/test_matte_check.py`, `tools/proof/test_composition_check.py`,
`tools/proof/frame_match.py`, `tools/proof/test_frame_match.py`,
`tools/proof/requirements.txt`; `.github/workflows/ci.yml`.

- Take #470's `island_matte.py` (the superset) over #473's; run
  `composition.py` and `match.py --only mid` once locally to show the
  import still works.
- `matte_check.py`: reword the M11 header line "not in a patch of 16 px
  or more" to "a patch of `HAZE_PATCH` px or more fails" (round-3 look).
- `frame_match.py`: `--app FRAME --target JPG [--distance map|mid|near]`;
  the 13-band luminance and saturation table and RMS of `match.py`
  (imported, not copied) for one app frame; exit 0 always; prints the
  table and writes `frame-match-<distance>.json`.
- `requirements.txt`: `onnxruntime` only (the matte maker); CI does not
  install it, and no test imports `island_matte`.
- `ci.yml`, job `python-tools`: a step `python3 -I -m unittest discover -s
  tools/proof -p "test_*.py"`. Job `publish-screenshots`: after the
  download, for each of `world-target-map-1200`, `-mid-1200`, `-near-1200`
  present, run `frame_match.py` against
  `docs/design/assets/world-concepts/target-<d>.jpg` and append the tables
  to `$GITHUB_STEP_SUMMARY`; skip silently when the frame is absent.

**Tests:** `test_matte_check.py`: `test_hard_rectangle_fails_m1`,
`test_one_bit_edge_fails_the_m2_floor`, `test_sky_band_under_the_body_fails_m11`,
`test_soft_disc_passes_m1_to_m6`. `test_composition_check.py`:
`test_journey_tier1_stage3_passes`, `test_isle_on_a_slot_fails_c6`.
`test_frame_match.py`: `test_identical_frames_have_zero_rms`,
`test_thirteen_bands`. The existing `test_concept_fit.py` passes.
**Founder:** nothing. **Lead, after merge:** close #463, #465, #466,
#471, #472, #473 and #470 as landed here.
**Fallback:** if a test needs `onnxruntime`, mark it
`@unittest.skipUnless(importlib.util.find_spec("onnxruntime"))`.

### WP2: one camera, the depth function (Opus, test)

**Files:** first-wave table.

- `WorldDepth.swift`: `public struct DepthLayer { public static func pose(_ camera: CameraPose, reference: CameraPose, k: Double) -> CameraPose }`
  implementing v2 §2: `scale_k = s0 * (s / s0)^k`, `look_k = L0 + k * (L -
  L0)`, anchor from `camera`. `reference` is the mid stop of the island
  the camera is at (today `HomePlate.homeStop` for Home).
- `SkySet.Layer` gains `k: Double` (`decodeIfPresent`, default by role:
  `sky` and `stars` 0, `tile` 0.45, `sprite` 0.25, `whale` 0.35, `island` 1).
  `skyset-home.json` and `skyset-caglayan.json` get explicit `k` per layer
  from v2 §2's table (horizon/far tile 0.05, mid clouds 0.45, sea 0.85).
- `SkySetView` draws each layer at `DepthLayer.pose(..., k: layer.k)`.
- `PaintedSky.mapPose`, `mapParallax` and the Map's separate sky camera go;
  the Map draws the same sky set through the same function
  (`PW/Scene/IslandScene.swift:703-712` is the call site).
- **Not in this PR:** the plate/`mapisle` fade (`PlateHomeViews.swift:54`)
  and `isleFade` stay until WP10's snapshot replaces the `mapisle` art.

**Tests:** `WorldDepthTests`: `kOneIsTheCamera` (equals
`CameraPose.project` to 1e-9), `kZeroNeverMoves`,
`horizonMovesUnderAPointAcrossTheRail` (k 0.05, z 0 to 2),
`layerPosesAreContinuousAcrossTheRail` (100 samples, no jump over 2 pt).
`MapSkyTests` and `PaintedSkyTests` drop the `mapPose` cases and gain
`mapSkyIsTheSameSetThroughTheDepthFunction`. `SkySetTests`:
`kDecodesWithRoleDefaults`.
**Frames:** `path-d01/03/06/07/11/13-map-0900` and `flight-home-koke-mid`
change in the sky only; judged A/B against `screenshots/main` at 1:1: no
seam, no layer edge in frame, no doubled isle.
**Founder:** pinching from Home to the Map, the clouds and far isles keep
their depth instead of the sky snapping to its own camera.
**Fallback:** if a tile's edge enters the frame at the Map (a low-`k` layer
drawn smaller than the screen), scale that layer by `max(1, screen /
drawn)` about its own centre and add the case to the test.

### WP3: the composition model (Sonnet, test)

**Files:** first-wave table. No edit to any existing Swift file.

- `ScreenBands`: v2 §1.1 at 402 x 874 (top safe 0 to 59, top row 59 to
  118, mid chrome 628 to 840, corner 314 to 386 x 766 to 840, bottom safe
  840 to 874); other sizes scale by width, bands keep their pt heights;
  `safeTop` in, default 59 (`PW/Scene/IslandSceneModel.swift:1296`).
- `world-map.json` and `WorldMap`: origin = Home's box centre; Koke
  (-150, -470), Çağlayan (150, -540); tier pitch 470; tier-2 y -950 to
  -1100 at x -190, 20, 200; slot states `cloud`, `veiled`, `island`; the
  tier-1 frame fit (Home's foot at 0.80 of the height, x 16 to 386, below
  y 84, scale the smaller fit, at least 0.45); horizon 0.53; backdrop lane
  y 350 to 450 (tier 1, journey).
  `WorldMap.tierFrame(tier:, size:) -> CameraRail.Stop` and
  `WorldMap.center(of: IslandID) -> WorldPoint`.
- `CompositionRules`: C1 to C6 on projected boxes, ported one to one from
  `tools/proof/composition_check.py` (PR #473: chip sizes, the horizon
  run's 0.21, C6's 24 pt).
- `WorldTargetScreenshotTests` (iOS, CI only), three frames at 12:00 clear,
  island level 10, every station at level 5, Koke and Çağlayan arrived
  (`IslandSamples.world`, as `HomePlateScreenshotTests.swift:56-60`):
  `world-target-map-1200` (Map framing), `world-target-mid-1200` (Home
  framing with chrome), `world-target-near-1200` (Home at the pinch
  limit, centred on Pofu). These are the frames WP1's CI step measures.

**Tests:** `ScreenBandsTests`: `bandsMatchTheTableOnIPhone17`,
`bandsKeepTheirHeightsOnASmallPhone`. `WorldMapTests`:
`tierOneScaleIs0_70` (to 0.01), `homeIs230PtWideWithItsFootAt0_80`,
`kokeAndCaglayanMatchTheV2Table` (Koke 174 pt wide, y 224 to 340;
Çağlayan 148 pt, y 181 to 286; within 2 pt), `noNeighbourEntersTheMidFrame`.
`CompositionRulesTests`: C1 to C6 pass on the tier-1 frame at stages 1, 2,
3, on mid at levels 1, 4, 10 (`plate-home.json` box) and on near rest;
one failing case per rule.
**Founder:** nothing yet; the lead posts the three target frames beside
the picks with WP1's band numbers as the starting gap.
**Fallback:** if a v2 table value fails a test by more than 2 pt, the
test asserts the value the arithmetic gives and the PR body lists the
difference for the lead.

### WP4: mattes and backdrop (Sonnet, eye)

**Files:** `tools/plate/ingest.py`, `tools/plate/test_ingest.py`,
`tools/plate/plate_gate.py` (new), `design/art/plates/home/matte-<light>-<stage>.png`
(21, replacing the three), `design/art/plates/home/objects.json`,
`PW/Resources/World.xcassets/world-home-plate-*`, `world-home-backdrop-*`,
`world-home-island-*`, `world-home-mapisle-*`,
`PW/Resources/Plates/plate-home.json`, `PW/Plate/PlateIsland.swift`
(decode `shadow`), `PT/HomePlateDataTests.swift`, `.github/workflows/ci.yml`,
`changes/feat-plate-mattes.md`.

- Run `island_matte.py` (r3b) for all 21 states; write the masters at
  2048 x 3072; mist-clear (batch 116) is not an input.
- `load_matte` takes the state's own matte, never level 10's.
- `cmd_deliver`: plate alpha = the matte (`FEATHER` = 0, the RGB of edge
  pixels from `island_matte`'s decontaminated layer); backdrop inpainted
  inside the matte grown by 24 px; `map_cut.py` re-run so the `mapisle`
  cuts take the new mattes.
- `island_shadow()` parameters per stage into `plate-home.json` `shadow`.
- `plate_gate.py`: for each shipped plate, `matte_check` M1 to M6 and M11
  with `--source` the plate's take from `objects.json` `plates`; fails on
  any red; prints `textureBytes` against `BUDGET`. CI step in
  `python-tools`.

**Tests:** `test_ingest.py`: `test_plate_alpha_is_the_states_matte`,
`test_no_state_reads_level_10s_matte`, `test_backdrop_inside_the_matte_is_not_the_plate`
(mean ΔE to the plate's island colours above 10 inside the grown matte).
`plate_gate.py` green on 21 states. `HomePlateDataTests`:
`shadowDecodesForEveryStage`.
**Frames:** every Home frame changes at the rim. Judged on
`home-plate-full-l10-day`, `-l10-golden`, `-l10-night`, `-l5-day`,
`-l2-day` and `path-d01-0900`: 1:1 crops of the lower border, the
lighthouse and the string lights. **Reference:**
`docs/design/assets/world-concepts/edges-r3b-4x.jpg`.
**Founder:** no blue band under the island, no pale rectangle round it.
**Fallback:** if the sky right beside the rim reads soft against the
sharp island at 1:1, set `backdropScale` 0.6 in `objects.json` (the key
`cmd_deliver` already reads) and re-deliver; if a state fails M11, it
ships with its old matte and is listed in the PR body.

### WP5: the props come back (Sonnet, eye)

**Files:** `tools/plate/props_slice.py` (new), `tools/plate/test_props_slice.py`
(new), `PW/Resources/World.xcassets/world-home-prop-*` (new),
`PW/Resources/Plates/plate-home.json` (`props`), `PW/Plate/PlateIsland.swift`
(decode `props`), `PW/Plate/HomePlate.swift` (`propSlot(_:) -> WorldPoint?`),
`PW/Home/WorldHome.swift:335-395`, `PW/Home/HomeObjectViews.swift`,
`PW/Scene/WorldHitTest.swift` (`plateTargets`), `PW/Scene/IslandScene.swift:848, 946`
(drop `plate == nil`), `PT/HomeSlotsTests.swift`, `PT/WorldHitTestTests.swift`,
`PT/PlateTests.swift`, `changes/feat-home-props-back.md`.

- Slice batch 111's pick into ten objects (jar empty, third, two thirds,
  full; pot empty, sprout, bloom, resting; lantern unlit, lit), trim,
  `matte_check --kind prop`.
- Slots per stage from `round3.py`'s `slot_for` (with its `DECLARED`
  table for levels 2, 6 and 10), 12 pt clear of any painted object's foot;
  written as `props[].slots` in plate pts.
- `placed(_:_:)` (`WorldHome.swift:381`) reads `HomePlate.propSlot` when
  the plate shows. The jar's fill and the lantern's glow stay code
  (`SeedJarFill`, `CalmLantern.glow`); the painted jar state is the
  nearest third.
- `plateTargets` adds `.prop` targets from `props[].tap`, at least 44 pt
  at mid.
- Today's occluders (`HomePlate.occluders(over:box:)`,
  `PW/Plate/HomePlate.swift:367`) cut the props as they cut Pofu.

**Tests:** `HomeSlotsTests`: `propSlotsKeep12PtFromPaintedFeetAtEveryLevel`,
`propsSpreadAcrossTheLipThirds`. `WorldHitTestTests`:
`plateHomeHasTappableJarPotsAndLantern`, `propTargetsAreAtLeast44PtAtMid`.
`PlateTests`: `everyStageHasThreePropSlots`.
**Frames:** `path-d16-pots-1500` (four blooms, one bud), every
`path-dNN-0900` and `-2300` (jar and lantern). **Reference:**
`match-mid.jpg` for scale and light. Pass: on the pots frame the pots are
findable at mid at 1:1; no prop stands on a painted object.
**Founder:** the jar, the pots and the lantern are back on his island.
**Fallback:** if a sliced prop fails M2 to M6, or batch 111 has no
recorded pick, that prop uses its shipped `ui-*` image
(`HomeObjectViews.swift:48, 395, 535, 569`) multiplied by the plate's
`harmony` tint; the PR body lists which.

### WP6: the Map, journey order (Opus, eye)

**Files:** `PW/Koke/KokeLayout.swift` (`center` from `WorldMap`; the
comment at `:74-78`), `PW/Caglayan/CaglayanLayout.swift` (`center`),
`PW/Plate/HomePlate.swift` (`mapStop` from `WorldMap.tierFrame`),
`PW/Layout/IslandFraming.swift` (`mapStop`, `:292`),
`PW/Scene/MapSlots.swift` (new: slot drawing), the Map call site in
`PW/Scene/IslandScene.swift`, `PW/Resources/World.xcassets/world-cloud-tower-*`
(new), `PT/KokeLayoutTests.swift`, `PT/CaglayanLayoutTests.swift`,
`PT/MapSkyTests.swift`, `PT/CompositionRulesTests.swift` (real stops),
`changes/feat-map-journey.md`.

- Koke and Çağlayan move to their tier-1 slots; flights, stops and hit
  boxes follow `center` with no other change.
- The Map frame is the tier-1 frame from day 1 until Çağlayan blooms;
  then the tier-2 frame; it changes only when a tier is announced.
- A slot holds a cloud tower (not announced), a veiled tower (next to
  open, the island's matte blurred and tinted) or the island. Tower art:
  batch 115 pick 1 ingested as `world-cloud-tower-1`.
- Far isles and the whale sit in the 350 to 450 pt lane.
- Islands bob 2 pt over 6 to 9 s at the Map only.

**Tests:** `CompositionRulesTests`: C1 to C6 on `HomePlate.mapStop` for
stages 1 to 3; `KokeLayoutTests`: `kokeIsAboveHome`;
`CaglayanLayoutTests`: `caglayanIsAboveHomeAndRightOfKoke`.
**Frames:** `path-d01/03/06/07/11/13-map-0900`, every `-koke-0907` and
`-caglayan-0907` (their surroundings), `world-target-map-1200`.
**Reference:** `match-map.jpg`, shown beside `target-map.jpg`.
**Founder:** Home in front and low; Koke and Çağlayan rising behind.
**Fallback:** if batch 115 has no recorded pick, unannounced slots stay
empty and `CompositionRulesTests`' stage-1 C3 case is wrapped in
`withKnownIssue("the tower ships with WP12")`.

### WP7: rail v2, mid and near (Opus, eye)

**Files:** `PW/Camera/CameraRail.swift`, `PW/Camera/CameraRig.swift`,
`PW/Camera/CameraRelease.swift`, `PW/Camera/OneThumbZoom.swift`,
`PW/Plate/HomePlate.swift` (stops), `PW/Layout/IslandFraming.swift`
(bands from `ScreenBands`), `PW/Home/WorldHome.swift` (chrome fade),
`PW/Scene/IslandSceneModel.swift` (`go(to:)`, `stepIn`, `pansIsland`),
the gesture site `PW/Scene/IslandScene.swift:182`,
`docs/adr/0027-one-camera-free-near.md` (new), `PT/CameraRailTests.swift`,
`PT/CameraReleaseTests.swift`, `PT/IslandFramingTests.swift`,
`PT/PlateTests.swift`, `PT/RailV2Tests.swift` (new),
`changes/feat-rail-mid-near.md`.

- `WorldFraming`: `map`, `mid`, `near` (D4); a compiler-led rename.
- Mid: fit to the level-10 box (378 pt wide on iPhone 17, scale 1.145,
  box centre y 383); a young island under 0.72 of the width fits to 0.72.
- Rail: `ln s` linear in z; z 0 the tier frame, 1 mid, 2 the near limit
  7.4 pt/unit; rest 1.73 (4.5 pt/unit). Release: below 0.5 to the Map,
  0.5 to 1.12 to mid, above 1.12 it stays. Rubber band 0.85 x the Map
  scale and 1.12 x the limit.
- A pinch zooms about the fingers' midpoint (the world point under it
  stays under it).
- Chrome opacity falls from 1 to 0 between 1.05 and 1.25 x mid scale; the
  anchor eases from y 383 to y 437 with it. Replaces
  `showsHomeChrome`'s `projectedFraming == .home` test
  (`WorldHome.swift:195-197`).
- Near: free pan on both axes while the screen centre stays inside the
  island box grown 10 %; past it a 30 pt rubber band. Double tap on a
  character: rest, feet at 0.60 of the height, x 0.50 moved up to 0.12 of
  the width away from the side he faces. Only the back control shows.
- ADR-0027: one camera and the depth function, the three framings Map,
  mid, near, the free near range; supersedes ADR-0018's framing names and
  ADR-0019's "no free camera".

**Tests:** `RailV2Tests`: `pinchKeepsTheWorldPointUnderTheFingers`,
`releaseLandsOnMapMidOrStays`, `restIsZ1_73`, `nearPanRubberBandsPast10Percent`,
`chromeFadesBetween1_05And1_25`; existing camera tests updated to the new
names. C1 for mid (0.42 to 0.46) and near rest (0.58 to 0.62) on the real
stops.
**Frames:** every `path-dNN-0900` and `-2300` (Home is now mid),
`path-d04-build-focus`, `world-target-mid-1200`, `world-target-near-1200`.
**Reference:** `match-mid.jpg`. Near is judged for framing only
(`layout-wireframes.jpg`, rightmost); its look waits for WP11.
**Founder:** the whole island on opening; one smooth pinch from the Map to
Pofu's face.
**Fallback:** if the 120 Hz Direct tier drops frames on the pinch in CI's
`MotionBeatTests` clip, keep the gesture maths and fall back to today's
anchor zoom for the Map-to-mid half (z below 1).

### WP8: looks, bases and mask data (Sonnet, test)

**Files:** `tools/plate/base_paste.py`, `tools/plate/look_cut.py`,
`tools/plate/mask.py`, their `test_*.py` (all new); `tools/plate/ingest.py`
(`BUDGET` 14,000,000, `LOOK_SCALE` 2, looks and mask in
`texture_bytes`); `design/art/takes/batch-117-station-erase-volume/**`
(ingested); `PW/Resources/World.xcassets/world-home-base-*`,
`world-home-look-*`, `world-home-mask-*` (new);
`PW/Resources/Plates/plate-home.json` (`version` 2, `camera`, `base`,
`stations`, `mask`, `water`, `softEdges`); `PW/Plate/PlateIsland.swift`
(decode, all `decodeIfPresent`); `PT/HomePlateDataTests.swift`.

- `base_paste.py`: paste the erased region of each batch-117 pick onto
  its parent plate through a feathered mask (batch 108's review);
  M7 to M10 against the parent.
- `look_cut.py`: for each station and each stage that paints it, the
  look = parent minus base inside the station's polygon grown 8 px, x2 by
  `upscale.py`, with its shadow; levels map per `world-v2-facts` §3
  (tea stall 9 paintings, workshop 5, windmill 3; the rest from the sprite
  levels only where no painting exists: those levels use the nearest
  lower painted look, v2 §7).
- `mask.py`: R from `tools/proof/water_regions.json`, G from `objects[].sway`,
  B from `objects[].emissive`, A the depth row (ground: own row; inside a
  polygon: its `footY`), 512 x 768.
- No drawing in this PR.

**Tests:** `test_look_cut.py`: `test_look_plus_base_equals_parent_m7`,
`test_no_ghost_m9`; `test_base_paste.py`: `test_outside_the_region_is_the_parent`;
`test_mask.py`: `test_depth_row_is_monotonic_on_open_lawn`.
`HomePlateDataTests`: `version2DecodesAndVersion1StillDoes`,
`everyStationHasALookForEveryLevel`. `plate_gate.py` green with looks.
**Founder:** nothing yet.
**Fallback:** a state whose batch-117 job has no pick keeps its plate as
its base, and its stations stay painted (presence by stage, as today)
until the pick is recorded; listed in the PR body.

### WP9: cloud floor and life (Sonnet, eye)

**Files:** `PW/Sky/CloudFloor.swift` (new), `PW/Sky/SkySet.swift`
(`swell`, `breathe`, `delta`), `PW/Sky/SkySetView.swift`,
`PW/Moments/CloudShadows.swift`, `PW/Resources/Plates/skyset-home.json`,
`PW/Resources/World.xcassets/world-cloud-*` (new),
`tools/plate/cloud_kit.py` (new) and its test,
`Tests/WorldScreenshots/RenderServerMotionTests.swift` (new),
`PT/SkyMotionLimitsTests.swift` (new), `changes/feat-cloud-floor-life.md`.

- **Step 1, the measurement (D6):** `RenderServerMotionTests` renders a
  view whose body increments a counter, moved by a
  `.repeatForever` offset animation for 3 s, and the same layer drawn
  through `PofuTimeline` at `drift`. Body count at most 3 → the layers in
  step 2 are render-server animations; otherwise `Canvas` at 15 Hz. The
  result goes in the PR body.
- Floor middle (k 0.45, puffs about 40 pt), floor near (k 0.85, about
  90 pt, carries the island's `shadow`), lip (k 1.25, 160 pt and up, from
  y 600 at mid and y 740 at the Map), 5 to 7 single puffs (k 0.6), two
  wisps (k 1.1, below the lawn line only); haze by `k` (tint and contrast,
  from `match.py`'s `HAZE`).
- Motion per v2 §3: horizon 0.5 pt/s; floors 1.5, 3, 5 pt/s with swell
  3, 5, 8 pt over 11, 17, 23 s; puffs 2 to 5 pt/s, breathe 1.5 % over 14
  to 20 s; far isles bob 2 pt over 9 to 13 s; whale 5 pt/s. Still,
  Reduce Motion and Low Power: every layer eases to rest in 2 s.

**Tests:** `SkyMotionLimitsTests`: `noAmbientLayerOver8PtPerSecond`
(birds excepted), `noFullWidthLayerOver5`, `noPeriodUnder5Seconds`,
`periodsShareNoSmallMultiple`, `atMost24MovingLayersAtTheMap18AtMid10AtNear`.
`test_cloud_kit.py`: `test_tile_wraps_without_a_seam`.
**Frames:** every Map and Home frame (sky only); a 12 s clip at the Map
and at mid from `MotionBeatTests`; `world-target-map-1200`,
`-mid-1200`. **Reference:** `match-map.jpg`, `match-mid.jpg` for the stills; each
clip is judged beside the same clip from `main`'s last run.
**Founder:** the sea moves slowly and has weight; the chrome sits on a
cloud bank.
**Fallback:** if a floor tile shows a seam at 1:1, that layer drifts at
0 pt/s and keeps only its swell; listed in the PR body.

### WP10: the plate compositor (Opus, eye)

**Files:** `PW/Plate/PlateCompositor.swift`, `PW/Plate/FarSnapshot.swift`,
`PW/Scene/StationReveal.swift` (all new); `PW/Plate/PlateHomeViews.swift`;
`PW/Plate/HomePlate.swift` (presence = built); `PW/Moments/BuildMoment.swift`;
`PW/Scene/BuildEffects.swift`; `PW/Scene/WorldHitTest.swift`
(station targets once built); call sites in `PW/Scene/IslandScene.swift`
(`plateObjects`, `:1125, 1194`); `PW/Resources/World.xcassets/world-home-island-*`
and `world-home-mapisle-*` (removed); `PT/PlateLifeTests.swift`,
`PT/IslandGrowMomentTests.swift`, `PT/PlateCompositorTests.swift` (new),
`changes/feat-plate-compositor.md`.

- Draw order v2 §6.2: base, looks back to front by `footY` with shadows,
  props and characters sorted with them, then effects; station
  occluders retire (D7); decor occluders stay.
- Presence = built, at any island level.
- Far picture: `ImageRenderer` of the composite at half size, keyed by a
  hash of (stage, light, built levels); replaces `mapisle` and the
  `PlateHomeLayer.opacity(z:)` fade.
- Level-up reveal v2 §9.2, at most 3.2 s, Moment tier; Reduce Motion a
  0.4 s cross-fade.

**Tests:** `PlateCompositorTests`: `looksSortWithCharactersByFootY`,
`aBuiltStationShowsAtIslandLevel1`, `snapshotKeyChangesWithABuild`.
**Frames:** `path-d04-build-focus`, `path-d04-build-burst`, every
`path-dNN-0900`, the Map frames (the snapshot). **Reference:**
`match-mid.jpg`; the reveal is judged frame by frame against v2 §9.2's
sequence (a `MotionBeatTests` clip of the tea stall going from level 2
to 3).
**Founder:** what he builds is what stands on his island, and on the Map.
**Fallback:** if `ImageRenderer` misses a frame budget on the Map, keep
`mapisle` for the Map only and list it.

### WP11: near, the thin lens (Opus, eye)

**Files:** `PW/Depth/ThinLens.swift`, `PW/Depth/BlurLevels.swift`,
`PW/Plate/NearLayers.swift` (all new); `PW/Resources/WorldShaders.metal`
(the level blend); `PW/Resources/Plates/plate-home.json` (`camera.elevationDeg`
10.5, `near.shots`, `near.patch`, `near.dressing`);
`tools/plate/near_layers.py` (new); `PW/Resources/World.xcassets/world-home-near-*`
(new); the depth call site `PW/Scene/IslandScene.swift:665, 922`;
`PT/ThinLensTests.swift` (new), `PT/LensTests.swift`;
`changes/feat-near-lens.md`.

- `ThinLens`: `D = 1375 / s`; `delta = (rowFocus - row) * unitsPerPixel *
  cos(e) / sin(e)`; `r = N * s * |delta| / (D + delta)`, cap 14 pt; sharp
  at r ≤ 0.5, skip under 0.35. Shots from `near.shots` (v2 §5.2 values).
- Four levels (0, 2, 6, 14 pt) blended by masks from the mask's A channel
  (D10); sky layers and characters take a plain blur of their own radius.
- The patch under the focused character, the 107 dressing on and behind
  the focal row, a contact shadow; the foreground strip only when batch
  119 is in.

**Tests:** `ThinLensTests`: `skyAtRestIs7_2Pt` (N 1.6, s 4.5),
`midIsSharpFrontToBack` (every island row r ≤ 0.5 at s 1.145, N 0.25),
`twoRowsOnOneLineAreSharpTogether`, `blurIsCappedAt14`.
**Frames:** `world-target-near-1200`, `path-d04-build-focus` (station
focus N 0.8). **Reference:** `match-near.jpg`, beside `target-near.jpg`.
Pass: no band edge visible at 1:1; Direct stays 120 Hz in the pinch clip.
**Founder:** close to Pofu, the world has a lens.
**Fallback:** if a band edge shows at 1:1, add a fifth level at 4 pt; if
it still shows, the blend runs per pixel only while the camera rests.

### WP12: unlock and tier reveals (Sonnet, eye)

**Files:** `PW/Scene/MapReveals.swift` (new), `PW/Scene/MapSlots.swift`,
`PW/Visit/WorldHomeModel.swift` (the announce hook), the Map call site in
`PW/Scene/IslandScene.swift`, `PT/MomentTests.swift`,
`changes/feat-world-reveals.md`.

- Unlock: the veil's three cloud layers drift apart and thin (2 s), the
  bob starts, the chip fades in; 2.4 s. Tier announce: on the first Map
  visit after it, the camera eases to the new frame (1.2 s), then the
  towers rise from the horizon band. Reduce Motion: 0.4 s cross-fade.

**Tests:** `MomentTests`: `unlockRevealIs2_4Seconds`,
`tierAnnounceRunsOnceOnTheFirstMapVisit`. **Frames:** the day-6 to day-7
and day-11 to day-13 Map frames; a `MotionBeatTests` clip of each.
**Reference:** `match-map.jpg`. **Founder:** a new island appears out of
the clouds. **Fallback:** without the cloud-kit volume, the veil is the
island's own matte blurred and tinted (v2 §8 "not Codex").

### WP13: region shaders (Opus, eye)

**Files:** `PW/Scene/PlateRegionEffects.swift` (new),
`PW/Resources/WorldShaders.metal`, `PW/Resources/Plates/plate-home.json`
(`water[].flow`, `speed`), its call site in `PW/Scene/IslandScene.swift`,
`PT/PlateRegionEffectsTests.swift` (new), `changes/feat-region-shaders.md`.

- Water from the mask's R and `water[].flow` (proof 4, option c,
  `tools/proof/water.py`); sway from G; emissive from B at night; at most
  5 % of the pixels, 30 Hz, paused outside Ambient.

**Tests:** `PlateRegionEffectsTests`: `regionsCoverUnder5PercentOfThePixels`,
`pausedOutsideAmbient`. **Frames:** a 12 s mid clip; `path-dNN-2300`.
**Reference:** the proof-4 water clip from `tools/proof/water.py`.
**Founder:** the pond and the falls move.
**Fallback:** if the frame meter shows app frames over 30 Hz at Ambient,
the shader runs at 20 Hz (`PofuFrameRate.idle`).

## 9. Reference images

Committed with this spec under `docs/design/assets/world-concepts/`, at
device size (1206 x 2622) unless noted:

| File | What it is | Judges |
|---|---|---|
| `target-map.jpg`, `target-mid.jpg`, `target-near.jpg` | the founder's picks (pofu-art batch 112: map-locked t1, mid-locked t1, near-locked t2) cut to the phone frame with the real chrome (`concept_fit.fit_take`) | direction; `frame_match.py`'s target |
| `match-map.jpg`, `match-mid.jpg`, `match-near.jpg` | `match.py`'s re-render from buildable parts | eye acceptance (D11) |
| `edges-r3b-4x.jpg` | the round-3 worst-edges sheet, 4x | WP4, WP8 |
| `layout-wireframes.jpg` | v2's tier-1, tier-2, mid and near wireframes | WP3, WP6, WP7 |

Match proof gaps (RMS, band luminance / saturation, script still → match):
Map 7.5 / 13.3 → 5.5 / 7.4; mid 4.2 / 3.7 → 3.8 / 3.1; near 5.2 / 12.4 →
2.9 / 6.2. Subjects drift under 2 px from the picks in every distance.

## 10. Out of scope

- Home on top (order B) and the tier-2 frame's final look (no tier-2 island exists).
- Tier 3 and the Map's vertical pan.
- Koke's and Çağlayan's own mattes, looks, near shots and region shaders.
- A painted near plate (the free near pick) and any camera other than 10.5°.
- Key-colour masters (batch 113 failed; network mattes stay).
- Golden looks below level 10 (golden exists at stage 0 only).
- A night props set unless the grade fails (WP5's fallback covers it).
- Music and new sound; the feel track's other rows.
- New features for the free `Pofu` build or the Shortcuts path.
- Decor placement and seasons.
- The storyboard's ground-level camera (beats 4 and 5).

## 11. Corrections for the lead

- v2 §6.1 `"matte": "world-home-matte-<stage>"`: the matte is the plate's
  alpha (D1); there is no matte asset.
- v2 §3 "Still tier" is `FrameState.settled` (`PW/Scene/FramePolicy.swift:19`).
- v2 §5.2 "sky r 7" at rest is 7.2 (N s = 1.6 x 4.5; `match-report.json`
  `lens_r_pt.sky_inf`).
- v2 §12 W2 removes "the z fades": the plate/`mapisle` fade cannot go
  before the snapshot exists (WP10), so WP2 removes only the sky's.
- `world-concepts-plan.md`: the picks were to be committed under
  `docs/design/assets/world-concepts/`; this PR does it.
- `SkySetView.swift:15` says 30 Hz; it runs at `PofuFrameRate.drift`, 15
  (`SkySet.swift:181`). `feel-motion-facts` §1 ("30 Hz Canvas, not under
  the policy") predates #460.
- `world-presentation-facts` §1 cites the pinch at `CameraRig.swift:328-337`;
  it is `:331` at `b424f1bd`.
- `KokeLayout.swift:74-78` ("the home island … is above the top edge")
  is false once WP6 lands; WP6 rewrites it.
- The match proof's drift tables label the locked targets `free`
  (`drift-*.txt`): a label only; nothing in them is judged.
- `world-presentation-round3-look.md` says the r3b mattes pass "on the two
  plates tested"; the checks are four states (L4, L10, day and night).
- pofu-art `QUEUE.md` rows 0-b4 to 0-b8 read READY after delivery.

## 12. Could not verify

- Whether the batch-111, 115 and 117 `pick:` values are the lead's.
- Whether `island_matte.py` r3b passes on the 17 Home states it has not
  run on (WP4 finds out; its fallback covers a failure).
- The real chrome boxes on a device (scout fact 1): `ScreenBands` uses
  v2's measured values.
- Whether `ImageRenderer` of the full composite fits a frame on the
  phone (WP10's fallback).
- Render-server motion cost (WP9's step 1 measures it).
