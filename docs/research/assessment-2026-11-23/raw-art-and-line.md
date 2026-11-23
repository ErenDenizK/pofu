# Raw facts: the art, the frames and the production line (2026-11-23)

Gathered read-only. pofu-art `origin/main` = e36b30a (2026-11-23, merge of #142), fetched today.
pofu `origin/main` = a8d07c7 (2026-11-17 22:45), same as GitHub's `main` today (checked by `gh api .../commits`);
I did not `git fetch` pofu (a plain fetch could pull `screenshots/main`). Evidence tags: [art] = pofu-art tree, [pofu] = pofu tree.

## 1. Concept rounds

Method: manifest job count (`tools/imagegen/manifest/batch-N-*.yaml`, count of `id:`) vs job folders and images under
`design/art/takes/batch-N-*/` [art]. Every delivered job folder holds 2 webp takes + contact.jpg + review.yaml.
Every review.yaml take entry (about 400 across batches 138-153) carries `qa: warn` (0 `qa: fail`, counted by grep); every pick is a provisional "QA auto-pick" (review.yaml `selection.method`),
"neither promoted". Account line in each review.yaml: founder's uncle's ChatGPT plan, source `codex-cloud`.

Round 1 (PRs #124-#131, all merged 2026-11-18; manifest jobs = delivered jobs):
| Batch | Topic | Jobs | Delivered | Notes (QUEUE-LOG.md "Delivered 2026-11-18") |
|---|---|---|---|---|
| 138 | board | 10 | 10 (#124) | `x-board-key-fall` copied the flat board of its format guide |
| 139 | panel | 8 | 8 (#125) | four jobs name the tea stall over a glowing windmill |
| 140 | voyage | 10 | 10 (#126) | Nazli drawn with heavy half-closed lids |
| 141 | island growth | 10 | 10 (#127) | film to be rebuilt down from the shipped plate |
| 142 | pond ladder | 11 | 11 (#128) | none noted |
| 143 | Gezgin | 16 | 16 (#129) | takes of `x-moor-under` and `x-moor-berth` sit in each other's folders |
| 144 | board blocks | 8 | 8 (#130) | called "the best thing in the round" in batch-152 manifest header |
| 145 | UI materials | 15 | 15 (#131) | none noted |
Round 1 total: 88 jobs, 88 delivered, 0 skipped/failed.

Round 2 (queued 2026-11-18 as D9-D16, 102 jobs; PRs #135-#142 were opened 11-18, merged 2026-11-23 14:06 UTC):
| Batch | Topic | Jobs | Delivered | Notes |
|---|---|---|---|---|
| 146 | board height | 14 | 14 (#135) | |
| 147 | panel strip | 15 | 15 (#136) | |
| 148 | voyage, eyes fixed | 13 | 13 (#137) | PR body: "Quota-skipped jobs were retried on this same branch" |
| 149 | island film | 12 | 12 (#138) | PR body: earlier blocker-only close recorded three spaced `usage_limit_reached` retries, later retries completed all 12 |
| 150 | pond crowns | 9 | 9 (#141) | review.yaml of `x2-pond-w5-night`: two takes "after the quota reset" |
| 151 | Gezgin models + levels 1-7 | 15 | 15 (#139) | commits dated 2026-11-19 are the last Codex commits on main |
| 152 | blocks | 15 | 0 (#140, closed unmerged) | PR body: `usage_limit_reached` before the first take of `x2-block-straight-dry`; all 15 jobs have "skipped" records; no images; branch to be retried "after 15 minutes". `batch-152` has no `design/art/takes/` folder on main, only its manifest |
| 153 | grounds and effects | 9 | 9 (#142) | |
Round 2 total: 102 jobs, 87 delivered, 15 skipped (all of batch 152, quota). Both rounds: 190 jobs, 175 delivered.
Round-2 has no review sheet on main. QUEUE.md rows D9-D16 still read READY (QUEUE.md last edited 2026-11-18, 807ca0f), even for the seven merged batches.
QUEUE.md text still says "he has not picked yet" (round 1). I found no recorded pick in pofu `docs/now.md` or `docs/product/founder-input.md` at a8d07c7 (grep for "concept.round" hit only `docs/design/concept-round-2026-11-18.md` and `changes/design-concept-round.md`) — UNCHECKED beyond that, pofu main is 6 days old.

Review sheets that exist [art]: `design/review/concept-round-1/1-tahta.jpg`, `2-panel.jpg`, `3-yolculuk.jpg`, `4-istasyonlar.jpg` (1-tahta is 1856 x 3754), built by `tools/review/sheet.py` (PR #133). No round-2 sheets.

## 2. What is in the app

Bundle catalogs [pofu]: `App/Resources/Assets.xcassets` (13 entries: AppIcon + dark/tinted, LaunchBackground, AccentColor, `cloud-curtain-1..3`, `gate-postcard-{dawn,day,golden,mist,night,rain}`, `launch-sky`) and
`Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets` (1,051 imagesets). Loose PNG resources: `PofuGames/Resources` (47 files, `flow-*`, `garden-*`), `PofuDesignSystem/Resources` (58, `paint-duo-*`, `paint-icon-*`, `paint-face-*`, ui chrome), `PofuCompanion/Resources` (17: `pofu-hamster*.png`, `pofu-part-*`, `shield-pofu-*`), `PofuWorld/Resources/Plates/*.json` (7 plate/skyset/cloud-kit manifests).
World.xcassets by prefix (imagesets): home 264, caglayan 98, dressing 80, island 60, mochi 53, critter 44, findik 38, koke 36, tea 35, simit 32, goat 32, harbor 27, windmill 24, bagel 24, pond 21, nazli 20, garden 20, lighthouse 13, cloud 13, lut 12, isle 12, hive 12, gift 12, visitor 8 (`world-visitor-damla`, `-gezgin`), damla 6, fog 3, far 3, plus glow/firefly/rain.

Per area (source = what the repo says; "Codex" = pofu-art `source: codex-cloud` takes):
- Home plates: shipped plates are Codex takes (plates.yaml: home `in_app` 21 of 66 cells, painted 23; caglayan in_app 12 of 54, painted 16; revontuli/emanet/mehtap painted 14-15 each, **in_app 0**; `founder_ok` is null in every cell). `docs/state/plates.yaml` [pofu]. Home IL1 day/night are scripted composites (`edited:` derived plates, `tools/plate/il1_composite.py`), not raw takes.
- Stations (tea stall, windmill, pond, garden, lighthouse, bagel cart, hive, workshop): painted imagesets `world-tea-stall-*`, `world-windmill-*`, `world-pond-*` etc. (counts above). Per `docs/state/plates.yaml` the station looks are being painted in place on the island plate (batch 129 DROPPED 2026-11-16, QUEUE.md Blocked). Which exact takes each imageset came from: UNCHECKED (no per-imageset provenance file found; `content/assets/*.yaml` has 882 rows: 684 in-production, 145 cut, 49 planned, 4 in-app).
- Pofu: the bundled body is `pofu-hamster.png` (522x496), which `CompanionRig.swift` calls "the bundled placeholder hamster ... keyed out of the founder's first GPT Image concept" (masters provenance: founder generated it in ChatGPT, 2026-11-01, "to be filled in"); lids and mouth/ears/paws parts are PNGs; face blush, lashes, halo are code (`CompanionView.swift`). Not a Codex-batch asset.
- Residents/visitors: painted sprites for Mochi (53 imagesets), Simit, Fındık, goat, Koke, Nazlı (20), Damla, Lut. Per `docs/research/night-2026-11-15-code-drawn.md` (older, at 83e2e394): only `world-visitor-damla` and `world-visitor-gezgin` are shipped visitor sprites; 7 of 9 residents "draw nothing" on the plate path when unpainted. UNCHECKED at today's main.
- Gezgin: `world-visitor-gezgin` (+ soft/deep shadows) is the one shipped sprite. The round 1/2 Gezgin concepts (batches 143, 151) are explorations, not in the app.
- Flow kit: shipped PNGs in `PofuGames/Resources/` (checked in tree): `flow-backdrop, flow-board-edge, flow-channel, flow-gate, flow-grass(-2), flow-lawn, flow-lip-{end-left,end-right,run,spill}, flow-outlet, flow-pool, flow-rock(-2), flow-rock-cut(-2,-3,-4), flow-spout-dry` (list truncated at 20 by my `head`). Water fill, hints, counters stay code-drawn (older inventory, FlowArt.swift). Kit v2 fit merged as pofu #506.
- Icons: `paint-duo-*` 28 files in PofuDesignSystem (batch 46 sheet t2 for 11 older ones, batch 128 singles for 17; `docs/state/assets.yaml`: many "baked, not wired: no place asks for it yet"); `paint-icon-*` (seed, calm, island, friend, ...). App icon is `AppIcon.png` (+Dark, Tinted); its source: UNCHECKED.
- Menus/UI: default skin is `.glass`; painted chrome (`paintsChrome`) is off by default so code-drawn seed, bubble, plaque, panel show (night-2026-11-15 doc, at 83e2e394; UNCHECKED today). `docs/state/assets.yaml`: 83 hooks: 58 in_bundle, 21 in_repo (e.g. all 13 `sticker-*` masters "not bundled yet"), 1 picked (`ui-sheet-paper-v3-night`), 3 unpainted (`ui-plaque-honey-pressed`, `sticker-simit-happy`, `sticker-findik-happy`); no row is `in_frame`.
- Code-drawn per that inventory: Flow water/hints/counters, Garden backdrop and effects, build-moment particles, level-up card, wax seals, Station sheet pips, resident card shell, close/undo/hint glyphs (SF Symbols), sky gradients, Koke far hump, light swells.

## 3. The queue

QUEUE.md [art] (120 lines, rewritten 2026-11-18): Demand D9-D16 8 rows READY (stale: seven were delivered and merged 11-23; D14 batch 152 is the real undelivered one);
Standing work 2 rows READY (S2 `batch-126-cloud-kit-volume-v3`, S3 `batch-84-hidden-visitors` 3 jobs left; note PR #132 for 126 v3 is open since 11-18);
Blocked 5 rows BLOCKED: `0-d10` batch-137 plot ladder v2 (founder 11-17: station levels go to concept first), `0-d9` batch-136 flow lawn v3 (waits on the board redesign), `0-x` hive-4/hive-5 (waits on lead palette/profile fix; all four takes failed chroma and palette), `4` batch-11-ui (waits on the UI audit's icon list), `B-G` batch-38-island-arcs (its manifest is not in pofu-art).
DONE: no table; finished rows live in QUEUE-LOG.md (280 lines).
QUEUE-LOG.md last 10 entries in order (file ends with the "Delivered 2026-11-18" table; there is no round-2 or quota entry): D1-D8 (the eight round-1 rows above), preceded by the 2026-11-16 block "0-d1..S1" (batches 121-135, merges #93-#118; S1 `batch-129` DROPPED), and the 2026-11-15-night "0-b/0-c" block (batches 105-120, PRs #69-#90 open).
Quota/usage_limit mentions since 11-15: 6 PR bodies #110 (11-16), #115 (11-16, HTTP 429 four retry rounds), #137, #138, #140 (batch 152, nothing delivered), #141; plus review.yaml of `x2-pond-w5-night`. Whether each was a separate Codex run that "ended on quota": UNCHECKED beyond those bodies. Only #140 ended with nothing. Last Codex commit on main: 2026-11-19 (c2cb485, batch-151 level seven). No art commits 11-20 to 11-23 apart from the merges.

## 4. Drift and risk

- Manifests: pofu-art has 154 files in `tools/imagegen/manifest/`; pofu `origin/main` has 88. **66 exist only in pofu-art**: `batch-77` to `batch-153` (every manifest from 77-92, 105-153; list via `comm` of the two trees). Nothing in pofu is missing from pofu-art. Non-manifest difference: `tools/imagegen/blocks/flow-stone-style-v1.txt` exists only in pofu-art.
- Sync script `tools/art/sync_to_art.py [--dry-run] [--prune]` [pofu]: copies pofu's `tools/imagegen` etc. into pofu-art; header says "pofu is the source of truth for the tools ... If Codex fixed a tool in pofu-art, port the fix back or the sync overwrites it". `--prune` deletes every file under `tools/imagegen/` that pofu does not have (the code lists them as `stale`). Run against today's pofu main with `--prune` it would match the 66 art-only manifests plus `flow-stone-style-v1.txt`. I did not run it. The "pruned" delete only touches `tools/imagegen/`.
- `SYNCED_FROM.txt` [art]: pofu commit 4029005 (2026-11-12), 460 files, 20.6 MB; that commit is 613 commits behind pofu main. The art repo's `tools/imagegen` code is thus synced from a commit 11 days old, while manifests 77-153 were authored art-side.
- Open pofu-art PRs: 59 open (`gh api pulls?state=open`): #6-#12, #19-#21, #32-#33, #35-#63 (most), #66, #69-#74, #76, #78-#79, #83-#86, #88-#90, #132. Oldest #6 (2026-11-12). QUEUE-LOG says several are reviewed with lead picks yet still open: #71, #72, #73, #74, #76, #78, #83, #84, #85 (lead picks recorded); #69, #88, #89, #90 "no lead review yet"; #70 delivered nothing; #53-#66 are Home golden/night plate attempts closed out "for good"; #6/#19/#45/#86 batch-31 "Stock is retired". Whether their content was superseded in pofu (e.g. plates shipped from other takes, 0-b..0-c picks landed): UNCHECKED per PR; partial evidence: plates.yaml cites batches 66/74/80 takes, not the batch 93-104 PRs.
- Repo size: pofu-art API `size` 282,341 KB (about 276 MiB); local packed 259.5 MiB; checked-out tree 184.6 MB over 2,168 files, of which `design/art/takes` 139 MB (1,462 files), masters 13.1 MB, ui 12.9 MB. pofu API `size` 18,476,235 KB (about 17.6 GiB; main tree 11,302 files).
- Both repos' main last commit dates: pofu 2026-11-17, pofu-art 2026-11-23.

## 5. Frames

`gh api repos/ErenDenizK/pofu/git/trees/screenshots/main?recursive=1` (not truncated): 451 blobs, all in the root (no folders), 784.6 MB total, 286 jpg + 155 png + 8 txt + 2 json. Largest: `harmony.jpg` 8.8 MB, `path-game-flow-stage1-solved.png` 7.9 MB.
Branch head commit 2026-11-17 00:44 UTC: "world screenshots and motion beats for main at a1dd288" (a1dd288 = pofu merge #506, 2026-11-17 00:05; pofu main now a8d07c7, docs-only newer, so frames are current for code).
Name families (count): home-plate 28, path-stall 20, caglayan-plate 12, spike-light 12, home-whole 11, path-game 10 (incl. flow stage1), 17-sheet 8, path-d04 8, sprite-levelup 8, weather-home 8, water-day 7, 15-menu 6, 20-gate 6, life-residents 6, water-night 6, 16-menu 5, caglayan-stage 5, koke-stage 5, motion 5, payoff-door 5, plate-life 5, 19-shield 4, kit-v3 4, koke-sky 4, path-d03/d07/d13/d16/d20 4-5 each. Text/data: README.txt, README-flow.txt, README-garden.txt, concept-match.json/.txt, d6-measurement.txt, frame-regions.json, frame-times.txt, grade-metrics.txt, harmony.txt.
Per-file dates are not in the tree listing; only the branch head date above. Whether names match device size (1206 x 2622): UNCHECKED (no image opened).
