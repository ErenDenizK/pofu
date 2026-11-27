# Texture budget v1: what a Home state may hold, and how sharp a look ships

**In three lines.** The "9 MB" is not a memory figure. It counts pixels at
one byte each, as if the textures were ASTC, but they ship as HEIC and
decode to 4 bytes a pixel. It also counts layers that never draw and leaves
out layers that do. The number was raised from 8 to 9 to fit the upscaled
plate; no device limit sets it. Under that rule, eight stations fit only
at 0.78 texture px per point, which is why the pond landed at 0.8. Count
what a state really holds in decoded pixels, set the limit at **12 million
pixels a state** (48 MB; a crossfade holds two states, 96 MB), and ship
every look at **2.0 texture px per plate point**, the plate's own density.

**Status:** spec, 2026-11-27, for the lead. The code is read on `main` at
`1a2b305f`; PR #528 is read at `8c41400b` (`art/station-levels`). Every
number below was measured on the shipped assets with the scripts named in
section 3. Sources: [main-flow plan](mainflow-plan-2026-11-26.md) step 1,
[season system](season-system-v1.md) section 6,
[ADR-0024](../adr/0024-shipped-plate-layers-are-heic.md),
[ADR-0027](../adr/0027-one-camera-free-near.md).

**The goal, checked.** The brief asks for memory savings so that eight
stations ship sharp. The code shows a cheaper goal that gives the player
the same result: **fix the count first**. The station looks are 10 % of
what a state holds. The plate and the sky set are 75 %. With a true count
and a reasoned limit, eight stations at 2.0 fit with 1.2 M pixels to
spare, and no memory work is needed now. The savings are measured in
section 4 and kept in reserve.

## 1. What "done" means

- **Player, at mid (Home's stop):** a built station is as sharp as the
  lawn beside it in a 1:1 crop of a 1206 x 2622 frame. No station is
  softer than the windmill on `main` (`path-mill-l3`, density 1.7). The
  pond and every later station ship at 2.0, never at 0.8.
- **Player, zoomed in (the station shot, near):** a look never reads
  softer than the plate around it, because both ship at 2 texture px per
  plate point.
- **Player, Today sheet:** the header shows the island as he built it.
  Today it shows the painted stations (section 2, row 6).
- **Founder / studio:** `plate_gate.py home` prints each state's texture
  pixels and their decoded MB against one limit from one config file, and
  CI fails above it. One CI log line compares the measured memory with
  the counted memory.

## 2. Where we stand (evidence)

| # | Claim | Evidence |
|---|---|---|
| 1 | **The budget is defined in four constants.** 9,000,000 per state, the largest one | `tools/plate/ingest.py:67-68`, `tools/plate/skyset_export.py:54`, `PofuWorld/Plate/PlateMath.swift:114-124` (two `budgetOK`), plus the props test `PofuWorldTests/HomePropsTests.swift:124` |
| 2 | **Why 9 MB:** it was 8 MB for the first take. When the plates went x2 the set measured 8.27 MB, so the limit became 9. No device, widget or extension limit is named anywhere | `ingest.py:67` comment; commit `e6b587f4` ("Texture budget 8 -> 9 MB (the x2 home set is 8.27 MB)"); the 8 MB came in `f801c8e7` with no reason given. No extension links `PofuWorld` (`project.yml` targets `PofuShieldConfiguration`, `PofuShieldAction`, `PofuActivityMonitor`) |
| 3 | **What it counts:** for each state, width x height of every imageset named for that state, at one byte a pixel (the comment says "ASTC 4 x 4"). It counts the plate (or the erased base in its place), the island cut, the occluders, the sky set without its island layer (matted states), and each station's base plus that station's **two largest looks**. It does **not** count props (only a Swift test adds them) or the far picture | `ingest.py:1171-1180` (`station_bytes`), `:1182-1203` (`state_texture_bytes`), `:1143-1157` (`sky_bytes`), `HomePropsTests.swift:112-125` |
| 4 | **The assets are not ASTC.** Plate layers are HEIC q70, 8-bit RGBA, with no ICC profile. None of the 1,088 imagesets in `World.xcassets` sets `compression-type`, so the asset catalog does no GPU compression. SwiftUI `Image(name, bundle:)` decodes them to 8-bit RGBA, **4 bytes a pixel** | `tools/plate/heic.py:33-35`; `grep -rl compression World.xcassets` gives 0 files; 239 HEIC all RGBA 8-bit (measured); `PofuWorld/Plate/PlateHomeViews.swift:254-262` |
| 5 | **The count overcounts what draws** in three places. (a) A matted state never draws its island cut: `islandArt` and `mapIslandArt` appear only in the non-matted branch. (b) A station's painted occluder retires on its base, yet it is still counted. (c) A build is one station, so only one old look fades at a time, yet the count adds a second look for every station | (a) `PlateHomeViews.swift:114-145` against `:146-170`; (b) `PofuWorld/Plate/HomePlate.swift:436`; (c) `PofuWorld/Moments/BuildMoment.swift:65`, `PofuWorld/Scene/StationReveal.swift:167,174` |
| 6 | **It undercounts what is held** in four places. (a) Props, 504,912 px at their worst frame. (b) The far picture: Home renders it once per state, 600 ms after the state rests, and caches two of them at 1 px per plate point, 822,120 px each at stage 0. (c) A crossfade draws two whole states. (d) The Today sheet's header draws the painted plate (`plateArt`) while Home holds the base, so a state with a base holds a second 3.29 M px copy, and the header shows the painted stations, not the built ones | (a) `HomePropsTests.swift:118-122`; (b) `PofuWorld/Plate/FarSnapshot.swift:9-12,45-46`, `PlateHomeViews.swift:137-142`; (c) `PlateHomeViews.swift:78-81`; (d) `PofuWorld/Plate/HomePlateCrop.swift:30,73`, `App/Home/TodaySheet.swift:102-106` |
| 7 | **Looks are already drawn and loaded one per station.** The compositor asks for the current level's art only. Image loading is lazy, by name. The brief's first option is the code as it stands | `PofuWorld/Plate/PlateCompositor.swift:85-98`; `PlateHomeViews.swift:231-263` |
| 8 | **The 8.955 MB of the brief** is the JSON's `textureBytes` 8,449,466 (day 0) plus the props' worst 504,912 = 8,954,378. `ingest.py check` does not add props; the Swift test does | `Resources/Plates/plate-home.json` `textureBytes`; `HomePropsTests.swift:124`; `ingest.py:1329` |
| 9 | **Density is texture px per plate point** (a pixel of the 1024 x 1536 master), not per screen point. The plate ships at 2. The tea stall ships at 3.0, the windmill at 1.7 on `main` (1.45 in #528), the pond at 0.8 in #528 | `tools/plate/station_looks.py:44-45,120-121`; `design/art/plates/home/stations.json`; #528 `station_looks.py:121,161-162` |
| 10 | **Sources allow 2.0 everywhere:** a take pixel is 0.30 plate points for the windmill (3.33 px/pt), 0.3445 for the pond (2.90 px/pt) and 0.147 for the tea stall (6.8 px/pt). At 3.0 the pond would be upscaled | `station_looks.py:62,120`; #528 `station_looks.py:161` |

**What one plate point is on screen** (iPhone 17, 402 pt at 3x). World
units per plate point `u = 1.15 x 402 / 1.40 / 1015 = 0.3253`
(`HomePlate.swift:63`, `IslandFraming.swift:42`, `islandBox` width 1015).
Scales are in points per unit (`CameraRail.swift:121-127`, `plate-home.json`
`near.shots`).

| Camera | pt / unit | Device px per plate point | Texels per device px at d = 0.8 / 1.45 / 1.7 / **2.0** / 3.0 |
|---|---|---|---|
| Mid (Home), level-10 island | 1.145 | 1.12 | 0.72 / 1.30 / 1.52 / **1.79** / 2.69 |
| Mid, youngest island (day 9, `youngFill`) | 1.286 | 1.25 | 0.64 / 1.16 / 1.36 / **1.59** / 2.39 |
| Station shot | 2.6 | 2.54 | 0.32 / 0.57 / 0.67 / **0.79** / 1.18 |
| Near rest | 4.5 | 4.39 | 0.18 / 0.33 / 0.39 / **0.46** / 0.68 |

Below 1.0 the texture is stretched. At mid, 0.8 is stretched 1.4x, which is
the softness the brief feared. Closer in, the plate itself is stretched
(2.0 in the bold column), so a look sharper than 2.0 is sharper than the
ground it stands on.

## 3. Measurements

Scripts (scratch, reproducible from the base commit with
`python3 -I <script> <repo> [density]`): a per-state breakdown with
`ingest.state_texture_bytes`, a rule-v1 count (section 5, D1), and alpha
crops of each layer. Pixels; decoded memory is x4.

**Home's largest states today**, under the old count and under rule v1:

| State | Old count (JSON) | Old + props | Rule v1 | Rule v1 decoded |
|---|---|---|---|---|
| day 0 | 8,449,466 | 8,954,378 | 9,395,830 | 37.6 MB |
| night 0 | 8,333,447 | 8,838,359 | **9,459,091** | 37.8 MB |
| golden 0 | 7,956,390 | 8,461,302 | 9,082,034 | 36.3 MB |
| Crossfade day 0 to night 0 (both states, the far cache, one reveal) | not counted | | 18.35 M | **73.4 MB** |

Rule v1 for day 0, in parts: sky set without its island 3,802,690; base
3,288,480; occluders 613,148 (the windmill's 179,280 retired); island cut
0 (201,388 left out); windmill look 182,240 plus one reveal 182,240; props
504,912; far picture 822,120. Rule v1 counts more than the old count
today because props and the far picture are real.

**Eight stations at stage 0, projected.** These are canvas areas in plate
points. The windmill is 63,000 (shipped) and the tea stall 30,960
(shipped). The pond is 99,875 (#528). The workshop is 54,830, the garden
50,327, the pier 17,248, the bagel cart 13,540 and the lighthouse 13,398.
The last five are the tap polygons of `plate-home.json` times 1.54, the
windmill's canvas-to-polygon ratio. In this projection every light gets
bases and its own looks.

| Density | Looks (current) | + one reveal | Worst state, rule v1 | Old count, day 0 |
|---|---|---|---|---|
| 0.78 | | | | 9.0 M: the most the old rule allows (section 2, row 2) |
| 1.7 | 991,781 | 288,638 | 10,282,630 (night 0) | 10.6 M |
| **2.0** | 1,372,712 | 399,500 | **10,774,423** (night 0) | 11.3 M |
| 3.0 | 3,088,602 | 898,875 | 12,989,688 (night 0) | 15.0 M |

**What Home holds in all** (all `world-home-*` imagesets): 156.3 M pixels,
26.1 MB of files. The plates are 75.5 M px and 11.5 MB of that; the sky
sets 22.7 M and 3.6 MB; the bases 18.7 M and 2.9 MB.

## 4. The options, measured

| Option | Saving, measured | Cost | Verdict |
|---|---|---|---|
| A. Draw and load only the current look | Already the code (row 7). What remains is the count's second look per station: 0.97 M px at eight stations, 2.0 | Count only (`ingest.py`) | **Take** as part of the rule (PR 1) |
| B. Leave out of the count what never draws: the island cut of matted states, retired station occluders | 380,668 px at day 0 today; 0.48 M px at eight stations (the teaStall, workshop and windmill occluders, 456,880, plus the island cut) | Count only | **Take** (PR 1) |
| C. Tight per-look crops (each look its own alpha box, not the shared canvas) | 20 % of look pixels (2,441,760 to 1,953,408 over the 14 shipped and #528 looks); pond 1 and 2 save 65 % | A per-look box in `stations.json` and `PlateCompositor.Look.box`, plus reveal anchoring. Two Swift files, one tool, every look re-exported | **Reserve.** About 0.3 M px at eight stations, not needed under 12 M |
| D. Tight base crops | 4 % (alpha box; the base is already cropped to its island, `plateCrop`) | none | **Nothing to take** |
| E. Split the base into bands, each cropped to its own row extent | 8 bands: 23 % of the base (757,422 px at day 0); 4 bands: 11 % | Eight images in place of one, eight seams through the painting at 1:1, every base and plate re-exported | **Reserve.** Seams on the island are the defect the founder sees first |
| F. Lower-resolution base where a look covers it | Under 3 % of the base sits under any look. The base is the island | n/a | **Rejected** |
| G. Sky set: cut the sparse cloud strips into their clouds | `sky-far` is 7 % opaque (64-px tiles touched: 45 %), `sky-mid` 8 % (33 %): about 0.8 M px of 3.8 M | Sky set export and `SkySet.swift` (2b is editing it now), ADR-0025 | **Reserve,** after 2b. Biggest single saving |
| H. ASTC through the asset catalog (`gpu-optimized-best`) | Memory / 4: the crossfade from 73 MB to 18 MB | Home's 156 M px weigh about 156 MB as ASTC 4 x 4 against 26 MB as HEIC, before any lzfse (not measured), and seasons multiply that. Encoding from the shipped HEIC is lossy on lossy (ADR-0024 forbids it), so the PNG sources would return to the tree. Reverses ADR-0024 | **Rejected.** Download is scarce; memory is not (D2) |
| I. HEIC | Already shipped (ADR-0024): 156 M px in 26 MB | | Kept |
| J. Fix the Today header (draw the base and the looks Home already holds, not the painted plate) | 3.29 M px while the sheet is open, and the header shows the player's island | Two files (PR 5) | **Take** (PR 5) |

## 5. Decisions (each with the alternative not taken)

| # | Decision | Not taken |
|---|---|---|
| D1 | **Rule v1: count what one Home state draws or keeps, in texture pixels; memory is 4 bytes a pixel** (8-bit RGBA, what HEIC and PNG decode to). Per state the count includes: the drawn picture (the base where a station has one, else the plate), the sky set without its island layer (matted) or the backdrop, the island cut and the Map cut (non-matted only), the occluders that can draw (minus stations on this base), each station's current look at its largest, one more look for the one reveal (the largest), the props' worst frame, and the far picture (matted, crop w x h). Its reason: it lists what `PlateHomeViews`, `PlateOccluders`, `StationReveal` and `FarSnapshotCache` hold, and nothing else | *Keep the ASTC byte count:* it is a quarter of the real memory, counts three layers that never draw, and misses props and the far picture. *Count the union of a crossfade's two states:* exact, but the worst crossfade (an hour change) shares almost nothing, so two times the state limit is the same bound with less code |
| D2 | **The limit is 12,000,000 px a state (48 MB decoded). A crossfade holds two: 96 MB.** Its reason is memory. 96 MB is about 7 % of the foreground limit of the smallest iPhone iOS 26 runs on (3 GB of RAM, a limit of about 1.4 GB; unverified, PR 3 measures). The rest is left for the games, the sound, the offscreen passes and the system's caches. Inside that line, step 1 at 2.0 fits with 1.2 M px to spare for the Gezgin and a season's edits. Tunable in `Resources/Plates/texture-budget.json` | *Keep 9 M:* forces 0.78 px/pt at eight stations, softness the player sees, to stay under a number no device imposes. *No limit:* memory grows with each station, season and sky without anyone seeing it. *16 M:* allows 3.0 for every look, but the pond would be upscaled and the headroom for seasons spent |
| D3 | **Every look ships at 2.0 texture px per plate point, the plate's own density.** At mid that is 1.79 texels per device px (1.59 on the youngest island), sharp at 1:1. Closer in it is exactly as sharp as the ground it stands on. It sits below every take's source density, so no look is ever upscaled. The tea stall keeps its approved 3.0 (it fits, and re-cutting costs a review). An ADR, because reversing it means re-cutting every look | *1.7 (the windmill on main):* sharp at mid, but 15 % softer than its own lawn at the station shot. *3.0 (the tea stall's):* above the pond's source (2.90), and eight stations at 3.0 cross 12 M (12.99 M). *Per-station densities:* a judgement call at each cut |
| D4 | **No GPU compression; the layers stay HEIC** | ASTC (option H): memory is not the scarce resource; download and repo size are |
| D5 | **Keep the JSON key `textureBytes` and the Swift names; their docs now say "texture pixels"** | *Rename to `texturePixels`:* it touches `SkySet.swift`, which 2b is editing, and eight tool files, all for a name |
| D6 | **One config, `Packages/PofuKit/Sources/PofuWorld/Resources/Plates/texture-budget.json`, read by the tools and by Swift** (`{"statePixels": 12000000, "bytesPerPixel": 4, "lookDensity": 2.0}`) | Four constants (row 1), already out of step with their comments |
| D7 | **Savings C, E and G are a reserve, in that order (C first), used only when `plate_gate.py` reports a state over the limit** | Doing them now: weeks of re-export and seam risk for memory the phone does not miss |

The product rules in `CLAUDE.md` are untouched. Nothing here changes what
seeds buy or how Pofu lives.

## 6. Gaps, ranked by what the player feels

| # | Gap | Evidence | Closed by |
|---|---|---|---|
| G1 | **The pond would ship soft.** At 0.8 it is stretched 1.4x at mid, beside a lawn at 1.79 texels a pixel, and the old rule pushes every later station to the same 0.78 | #528 `stations.json` pond density 0.8; section 3 | PR 1 (the rule), PR 4 (re-cut at 2.0) |
| G2 | **The windmill drops from 1.7 to 1.45** in #528 | #528 `station_looks.py:121` | PR 4 |
| G3 | **Today's header shows the painted stations,** not the ones the player built. On a state with a base it also holds a second copy of the plate | `HomePlateCrop.swift:30,73` | PR 5 |
| G4 | **Nothing measures what the phone holds.** The count says 8.45 M "bytes"; a crossfade holds about 73 MB decoded today. The player feels nothing yet; the risk is growth no one can see | section 3 | PR 1 (the gate prints MB), PR 3 (measured) |
| G5 | **The limit sits in four places with false comments** | row 1, Corrections | PR 1, PR 2 |

## 7. The PRs, in merge order

At most three in flight. **Wave A:** PR 1, PR 3 and PR 5 (no shared
files). **Wave B,** after PR 1 merges: PR 2 and PR 4. Merge order:
1 → 3 → 5 → 2 → 4. Every Swift PR runs `tools/swift/test-linux.sh` before
its push, then CI once; warnings are errors. User-visible PRs (4, 5) add
`changes/<branch>.md`, starting with its desk in brackets.

| PR | Branch | Accepted by | Size | Model, effort | Wave |
|---|---|---|---|---|---|
| 1 Rule v1 in the tools | `tools/texture-budget` | test | M | Sonnet high | A |
| 3 Measured memory | `test/texture-memory` | test | S | Sonnet medium | A |
| 5 Today header from the composite | `fix/today-header-composite` | eye | S | Sonnet medium | A |
| 2 Rule v1 in Swift | `fix/texture-budget-swift` | test | S | Sonnet medium | B |
| 4 Looks at 2.0 (1c resumes) | `art/station-levels` (#528) | eye | M | Opus high | B |

### PR 1: rule v1 in the tools (test)

**Files:** `Packages/PofuKit/Sources/PofuWorld/Resources/Plates/texture-budget.json`
(new), `tools/plate/ingest.py`, `tools/plate/skyset_export.py`,
`tools/plate/plate_gate.py`, `tools/plate/test_ingest.py`,
`docs/adr/0031-texture-budget-counts-what-draws.md` (new; the next free
number at the base commit).

- `texture-budget.json`: `{"statePixels": 12000000, "bytesPerPixel": 4,
  "lookDensity": 2.0, "note": "docs/design/texture-budget-v1.md"}`.
- `ingest.py:67-68`: `BUDGET = json.loads((JSON_DIR /
  "texture-budget.json").read_text())["statePixels"]`, and the comment
  becomes "texture pixels a Home state may hold; each decodes to 4 bytes
  (8-bit RGBA). Rule v1, docs/design/texture-budget-v1.md".
- `station_bytes` (`:1171-1180`) becomes exactly:

  ```python
  def station_bytes(island: str, light: str, stage: int) -> int:
      """Texture px of a state's station layers: its one erased base (shared by every station on it; it replaces the
      plate), each station's largest look (the one drawn, at any level), and once more the largest of those (the old look
      of the one reveal that can run: a build is one station, `BuildMoment.station`)."""
      base, looks = 0, []
      for st in stations_data(island).values():
          if stage not in station_stages(st, light):
              continue
          base = max(base, st.get("baseBytes", {}).get(str(stage), 0))
          looks.append(max(st.get("lookBytes", [0])))
      return base + sum(looks) + max(looks, default=0)
  ```

  with `station_stages(st, light)` returning `st["lights"][light]` when
  `lights` exists, else `st["baseStages"]` when `st["light"] == light`,
  else `[]`. `base_states` (`:1167-1168`) uses it too. If `lookBytes`
  becomes a per-light map, take the list for the look light (golden
  reads day, `PlateIsland.swift:350-352`).
- `state_texture_bytes` (`:1182-1203`): a matted state's kinds become
  `("plate", "occ")` (no island cut). A non-matted state's become
  `("plate", "island", "mapisle", "backdrop", "occ")`. Skip
  `world-<island>-occ-<id>-…` where the object's `station` has a base in
  the state. Add `props_pixels(island)` to every state: from
  `JSON_DIR / plate-<island>.json` `props`, the sum of `bytes // states x
  (1 if id == "jar" else states)`, with `states = max(len(states), 1)`
  (as `HomePropsTests.swift:118-122`; 0 without the file). Add the far
  picture to a matted state: `(x1 - x0) * (y1 - y0)` of its
  `plate_crop_points` (`FarSnapshot.pixelsPerPlatePixel` is 1). The
  docstring states rule v1 and "4 bytes a pixel decoded".
- `skyset_export.py:54`: `BUDGET = json.loads((JSON_DIR /
  "texture-budget.json").read_text())["statePixels"]`; its doc line 9 says
  "texture pixels, 4 bytes each decoded".
- `plate_gate.py:171-176`: print `texture px {size:,} of {BUDGET:,}
  ({size * 4 / 1e6:.1f} MB decoded)`, and per state the same.
- `test_ingest.py`:
  `test_a_matted_state_does_not_count_its_island_cut`,
  `test_a_station_on_its_base_retires_its_painted_occluder`,
  `test_one_reveal_counts_one_extra_look` (two stations with looks of 100
  and 60 px count 100 + 60 + 100 over their base),
  `test_props_worst_frame_and_far_picture_are_counted`,
  `test_the_limit_comes_from_texture_budget_json`; and in
  `test_check_flags_problems` `textureBytes=10_000_000` becomes
  `13_000_000`.
- ADR-0031 records D1 to D4 in the template's shape (`docs/adr/template.md`).

**Acceptance:** `python3 -I -m unittest discover -s tools/plate -p
"test_*.py"` is green. `python3 -I tools/plate/plate_gate.py home` prints
`night-0: 9,459,091` and `day-0: 9,395,830` (section 3) and ends green.
`plate-home.json` is **not** regenerated here, because #528 and 2b both
edit it; the next `ingest.py json home` writes the new value.
**Founder:** nothing on the phone.
**Fallback:** if `plate_gate.py` prints other numbers than section 3,
print the state's parts with the same labels as section 3. Fix the term
that differs to match the definition in D1, and if a term has no clear
fix, keep the code and put both numbers in the PR body.

### PR 3: measured memory (test)

**Files:** `Tests/WorldScreenshots/TextureMemoryTests.swift` (new),
`.github/workflows/ci.yml`.

- `TextureMemoryTests.testHomeHoldsWhatTheBudgetCounts`: read
  `phys_footprint` (`task_info`, `TASK_VM_INFO`) with an empty window
  hosted (F0). Host Home at mid, level 10, noon, the windmill at level 3,
  wait 1.5 s (the far picture renders at 0.6 s), and read again (F1). Host
  night 0 in a second window and read again (F2). Print one line:
  `texture-memory: day-0 <F1-F0> MB (counted 37.6), day-0+night-0 <F2-F0>
  MB (counted 75.4)`. The counts are taken from section 3 as constants.
  Assert `0.6 <= (F1-F0) / 37.6 <= 1.6`.
- `ci.yml`: add `-skip-testing:PofuWorldScreenshots/TextureMemoryTests`
  to the world screenshot run (`:304-315`). Add one step after it that
  runs `-only-testing:PofuWorldScreenshots/TextureMemoryTests` on the
  same simulator, so no earlier test has decoded a Home image. In the
  same step, print `xcrun assetutil --info` for the rendition
  `world-home-plate-day-0` of the built `PofuKit_PofuWorld.bundle/Assets.car`
  (found with `find "$HOME/Library/Developer/Xcode/DerivedData" -name
  Assets.car -path '*PofuWorld*'`), which shows how the catalog stores it.

**Acceptance:** the CI log holds the `texture-memory:` line and the
rendition's encoding. The test passes.
**Founder:** nothing.
**Fallback:** if the ratio is outside 0.6 to 1.6 (the simulator may not
count GPU surfaces), remove the assertion, keep the line, and the lead
puts the measured ratio under Corrections here. Rule v1 stands until
someone measures on a device.

### PR 5: Today header from the composite (eye)

**Files:** `Packages/PofuKit/Sources/PofuWorld/Plate/HomePlateCrop.swift`,
`App/Home/TodaySheet.swift`, `Tests/WorldScreenshots/MenuScreenshotTests.swift`.

- `HomePlateCrop` gains `stationLevels: [StationID: Int] = [:]`. Its body
  draws `drawnPlateArt` in place of `plateArt` (`:73`). Over it come the
  looks of `PlateCompositor(plate:levels:)` for that state. Each look is
  placed at its box converted to plate points with `HomePlate.plate(_:)`,
  scaled by the same `k` and offset as the base, with its `grade` as a
  `colorMultiply`. `artName` (used by `OneVoiceTests`) is unchanged.
- `TodaySheet.swift:106`: pass `stationLevels:
  HomePlate.stationLevels(model.world)` (`App/AppModel.swift:329`).
- A frame `path-today-header-mill-l2`: the Today sheet at level 10, noon,
  the windmill at level 2.

**Acceptance:** `path-today-header-mill-l2` shows the level-2 windmill.
The reference is Home's own frame of that state, `path-mill-l2`; at 1:1
the header's windmill is the same picture, cropped. `15-menu-today-v3-day`
is unchanged where no station has a base.
**Founder:** the Today card shows his windmill, not the painted one.
**Fallback:** if a look misregisters in the header, draw only
`drawnPlateArt` plus looks whose box lies wholly inside the header crop,
and list the dropped station in the PR. This PR must merge before 4a
(sheet and card style) starts on `TodaySheet.swift`.

### PR 2: rule v1 in Swift (test)

**Files:** `Packages/PofuKit/Sources/PofuWorld/Plate/TextureBudget.swift`
(new), `PofuWorld/Plate/PlateMath.swift`, `PofuWorld/Sky/CloudFloor.swift`
(comment), `Tests/PofuWorldTests/PlateTests.swift`,
`Tests/PofuWorldTests/HomePropsTests.swift`.

- `TextureBudget.swift`: `public enum TextureBudget { public static let
  statePixels: Int; public static let bytesPerPixel = 4 }`. It is loaded
  from `texture-budget.json` exactly as `CloudFloor.swift:30-37` loads
  `cloud-kit.json`, with 12_000_000 when the file is missing.
- `PlateMath.swift:114-124`: both `budgetOK` compare with
  `TextureBudget.statePixels`. The doc says "texture pixels of what a
  state holds (rule v1), 4 bytes each decoded".
- `CloudFloor.swift:40`: "ASTC, one a pixel" becomes "texture pixels".
- `PlateTests.swift:81-84`: the boundary at `TextureBudget.statePixels`
  and `+ 1`; a new `theBudgetComesFromItsConfig`: `#expect(TextureBudget.statePixels == 12_000_000)`.
- `HomePropsTests.swift:112-125`: keep `all > 0` and `worst > 0`. Replace
  `island.textureBytes + worst <= 9_000_000` with
  `#expect(PlateMath.budgetOK(island))`, because props are in the count
  now (PR 1).
- `SkySet.swift:182` stays until 2b merges (Corrections).

**Acceptance:** `tools/swift/test-linux.sh --filter
'PlateTests|HomePropsTests|SkySetTests|HomePlateDataTests|CaglayanPlateDataTests'`
is green, then CI.
**Founder:** nothing.
**Fallback:** if `Bundle.module` does not find the JSON on Linux, try the
`subdirectory: "Plates"` lookup as `CloudFloor.swift:33` does. If both
fail, use the constant 12_000_000 with a test that reads the JSON by
`#filePath` and expects the same value.

### PR 4: looks at 2.0, 1c resumes (eye)

**Branch:** `art/station-levels` (#528), rebased on PR 1.
**Files:** as #528, plus `tools/plate/station_looks.py`.

- `station_looks.py`: `DENSITY = 2.0` (`:45`). `TEA_STALL` gains an
  explicit `"density": 3.0`, so its looks stay byte for byte.
  `WINDMILL["density"]` and `POND["density"]` become `2.0`, and their
  comments say "rule v1: the plate's density (texture-budget-v1 D3)". The
  six remaining stations take the default.
- On the rebase, `ingest.station_bytes` is PR 1's. #528's "a shared base
  counted once" is the `max` in it already.
- Run `station_looks.py looks`, `json`, then `ingest.py json home`, then
  `plate_gate.py home`.
- Two new frames at the station shot (`plate-home.json`
  `near.shots.station`, s 2.6) centred on each foot: `path-mill-near-l5`
  and `path-pond-near-l5`. They follow the pattern of
  `path-d04-near-rest` in `PlayerPathScreenshotTests.swift`.

**Acceptance (eye):** `path-mill-l2..l5`, `path-pond-l1..l5`,
`path-levels-i10/9/8/7`, `path-mill-near-l5`, `path-pond-near-l5`. In
1:1 crops at mid, the mill is no softer than `path-mill-l3` on `main`
(the approved 1.7 windmill). Every look's cut is as clean as
`path-stall-l3` (no halo, no ghost). In the near frames, the look's
texture is no softer than the lawn beside it. `git diff --stat` shows no
`world-home-look-teaStall-*` change. `plate_gate.py home` is green with
the new per-state count in the PR body.
**Founder:** the windmill and the pond as sharp as the tea stall's
counter at mid. Zoomed in, the stations and the lawn soften together.
**Fallback:** if a cut at 2.0 shows a halo the 1.45 or 0.8 cut did not,
re-run that look's alpha clean-up unchanged (`ALPHA_LOW`, `ALPHA_HIGH`,
`SPECK`). If it still shows, ship that one look at 1.7 and list it. If
`plate_gate.py` reports a state over 12 M at any station, stop, post the
state's parts, and do not lower a density. The lead takes reserve C
(D7).

## 8. Out of scope

- The reserve savings C, E and G (section 4) until a state crosses 12 M.
- ASTC, on-demand resources and the download size of seasons (D4).
- Memory of the offscreen passes (`drawingGroup`, `compositingGroup`,
  the near lens's levels; one screen is 12.6 MB). PR 3's footprint
  includes them, and rule v1 does not count them.
- Decode time when a state changes (a hitch, not a budget).
- Re-cutting the tea stall at 2.0.
- Renaming `textureBytes` (D5).
- The Gezgin's density (2b's own spec, `mainflow-plan` row 2b).
- Other islands' plates and the Map's other islands. Their sky sets
  inherit the new limit through `skyset_export.py`; nothing else was
  re-measured.
- The cloud floor's own budget (`CloudFloor.textureBytes`,
  `SkyMotionLimitsTests.swift:103`).

## 9. Corrections (for the lead)

1. "ASTC" is false wherever it describes shipped textures. The layers are
   HEIC with no GPU compression and decode to 4 bytes a pixel:
   `tools/plate/ingest.py:67,1183`, `PlateMath.swift:114`,
   `SkySet.swift:182`, `CloudFloor.swift:40`, `skyset_export.py:9`,
   `docs/design/visual-system.md:188`,
   `docs/design/plate-islands.md:111-113,270-271`,
   `docs/adr/0022-plate-first-islands.md:89`,
   `docs/design/world-presentation-build-spec.md:44-46,205`.
2. `docs/adr/0024-shipped-plate-layers-are-heic.md:40`, "The texture
   budget check measures decoded size": it measures pixels at one byte,
   a quarter of the decoded size.
3. `docs/design/season-system-v1.md:156-157`, "one state is loaded at a
   time and the 9 MB budget per state stands": a crossfade holds two
   (`PlateHomeViews.swift:78-81`), and the count is pixels, not MB.
4. `PofuWorld/Plate/HomePlateCrop.swift:6-9`, "never a second drawing of
   it": it draws the painted plate, not the base and looks Home draws
   (G3).
5. The brief: `ingest.py check home` does not produce 8.955 MB. That is
   the JSON value plus the Swift props test (section 2, row 8). "Texture
   px per point" means per plate point, which is 1.12 device px at mid,
   not per screen point. "Draw and load only the current level's look"
   is already the code (row 7).
6. `tools/plate/station_looks.py:121` and #528 `:121,162`: "must fit 9 MB
   with its props" becomes rule v1 (PR 4 rewrites them).
7. `docs/design/mainflow-plan-2026-11-26.md:242`, "the density of the
   station looks (3 px per point)": the looks ship at 2.0. The tea stall's
   3.0 is the exception.

## 10. Done when

PRs 1 to 5 are merged on green CI. `plate_gate.py home` prints every
state under 12 M px with its decoded MB. The CI log carries the measured
`texture-memory:` line. The founder has seen the windmill and the pond at
2.0 at mid and at the station shot, and the Today header with his own
stations.

## Not verified here

- That the asset catalog keeps HEIC as HEIC and that SwiftUI decodes it to
  4 bytes a pixel on a device. This was read from the files and the code,
  not measured; PR 3 measures it on the simulator and prints the
  rendition.
- The foreground memory limit of a 3 GB iPhone (about 1.4 GB), and that
  the oldest iOS 26 phone has 3 GB. Apple publishes neither.
- The canvases of the five stations not yet cut (tap polygon x 1.54). The
  pond's canvas from #528 is 2.6 times its polygon, so a station's
  real canvas can exceed the projection. The 1.2 M px of headroom covers
  one more pond-sized surprise.
