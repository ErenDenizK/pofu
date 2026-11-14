# Asset system v1, section 7: facts (scout)

Commit checked: `origin/main` 3186e74d, read with `git show`/`git grep`. Pofu-art read with
`gh api repos/ErenDenizK/pofu-art/git/trees/HEAD?recursive=1` (sizes) and `contents/`. No code run.
Facts only. Items 4 (§7.4) and 1 (§7.1) were not asked.

## 1. (§7.2) Code growth pieces, dandelion, help item, frog, ladybug on the plate Home

Answer: NOT dead as a whole. The code art lives on the sprite-island branch, which draws when no plate resolves.
On the plate branch none of the five draws anything. Wave 4 is not empty by this test.

Plate Home path: `FeatureFlags.islandHome = true`, `worldHome = true` (`App/Support/FeatureFlags.swift:5,11`)
-> `WorldHome.body` `IslandScene(...)` (`Packages/PofuKit/Sources/PofuWorld/Home/WorldHome.swift:87`)
-> `IslandScene` object list `objects` (`Scene/IslandScene.swift:1103-1107`): `if let plate { return plateObjects(plate) }`.
Gate for everything below: `HomePlate.resolve` (`Plate/HomePlate.swift:140-152`) is `nil` when `look.homePlates` is false
(default `true`, `Look/WorldLook.swift:76`) or the island level is under the plate's lowest stage
(`stageLevels` min = 1, `Resources/Plates/plate-home.json`; `PlateIsland.dayStage`, `Plate/PlateIsland.swift:225-228`)
or no light is painted for the hour/weather (`paintedState`, `HomePlate.swift:112-121`; day, golden and night all borrow).

- `GrowthArt` (`GrowthView`): dead on the plate path. Only call: `IslandScene.swift:1140-1141` (`IslandGrowth.pieces`) and the
  view at `:1385-1386`, both inside the `plate == nil` branch. `plateObjects` (`:1175-1214`) has no growth.
  Live only on the sprite island (`plate == nil`). No baked `world-growth-*` imageset exists in `World.xcassets`.
- Frog and ladybug: dead on the plate path. Only call: `Critters.critters(atLevel:)` at `IslandScene.swift:1156-1157`
  (`plate == nil` branch); code stand-in `LifeArt.drawCritter` `Scene/LifeArt.swift:192,199` via `CritterView` `LifeViews.swift:106-108`.
  The comment at `IslandScene.swift:1172-1173` says "The sprite island's critters are not drawn on the plate."
  No `world-critter-frog` or `-ladybug` imageset exists (snail and bird do).
- Dandelion visitor: plate path draws it only if a painted sprite exists. `PlateVisitorPartView.dandelion` (`IslandScene.swift:1747-1749`)
  -> `piece(...)` (`:1756-1758`) draws only if `WorldArt.sprite("visitor-dandelion")?.sharp != nil`, else nothing
  (comment `:1752-1754`: "the plate shows no code-drawn stand-in"). No `world-visitor-dandelion` imageset exists, so on the plate: nothing.
  Live code stand-in on sprite island: `VisitorPartView.dandelion` `LifeViews.swift:195-206` (`LifeArt.drawDandelion` `LifeArt.swift:247`).
- Help item: same rule. Plate: `piece("help-kite", ...)` `IslandScene.swift:1717-1718`; no `world-help-kite` imageset, so nothing.
  Sprite island: `LifeViews.swift:163-166` (`LifeArt.drawKite`).
- Flag or condition: no feature flag. The only gates are `plate == nil` (above) and the sprite-exists check (`:1757`).
  Plate visitor parts are also skipped on the Map (`z >= WorldHitTest.archipelagoZ`, `:1178`).
- Doc wrong: `asset-system-v1.md:354-356` ("dead since ADR-0022") is half right: dead on the plate, live on the fallback island.

## 2. (§7.3) Lossless originals of batch 58's door layers

Answer: yes, in `ErenDenizK/pofu-art`, but at half size, not 1024 x 1536. The 1024 x 1536 takes are WebP only (q not stated in files).
Batch 58 itself skipped the five layers (`design/art/takes/batch-58-gate-round-door/gate-door-leaf/review.yaml`, `asset-gate-door-leaf.yaml` notes:
"Skipped without generation"). The layers that shipped are the retained takes of `gate-door-repost-2026-11-06`, approved as batch 58 job t1 (`ui-gate-door-leaf/provenance.md`).

| Path (pofu-art, same in pofu only where marked) | Format | Bytes |
|---|---|---|
| `design/art/ui/ui-gate-door-scene/raw.webp` (also in pofu) | WebP lossless, 512x768 | 413832 |
| `design/art/ui/ui-gate-door-scene/ui-gate-door-scene.png` (also in pofu) | PNG, 512x768 | 515714 |
| `design/art/ui/ui-gate-door-bank/raw.webp` / `.png` | WebP lossless / PNG | 226762 / 270530 |
| `design/art/ui/ui-gate-door-leaf/raw.webp` / `.png` | WebP lossless / PNG | 43928 / 65282 |
| `design/art/ui/ui-gate-door-grass/raw.webp` / `.png` | WebP lossless / PNG | 95974 / 109357 |
| `design/art/ui/ui-gate-door-interior/raw.webp` / `.png` | WebP lossless / PNG | 115978 / 139373 |
| `design/art/ui/ui-gate-door-plaques/raw.webp` / `.png` | WebP lossless / PNG | 44752 / 55334 |
| `design/art/takes/gate-door-repost-2026-11-06/gate-door-{bank,grass,interior,leaf,plaques}/ui__*--t1..t4.webp` | WebP, 1024x1536 takes | bank 129906-149084; grass 69960-79178; interior 71998-86364; leaf 32794-34624; plaques 45832-48060 |
| `.../gate-door-repost-2026-11-06/gate-door-scene/ui__gate-door-scene--t2.webp` (also pofu) | WebP, 1024x1536 | 149374 |

Evidence: `raw.webp` "(webp lossless) ... delivered at x0.5 (512x768, Lanczos, lossless)" (`ui-gate-door-leaf/provenance.md`, `meta.json` `raw_encoding: "webp lossless"`).
In pofu, only the scene layer is stored: `design/art/ui/ui-gate-door-scene/*`, `design/art/takes/batch-58-gate-round-door/gate-door-scene/ui__gate-door-scene--t1..t4.webp` (142590-175816 B),
`design/art/takes/gate-door-repost-2026-11-06/*` (webp + contact.jpg + review.yaml; the same takes as pofu-art), `batch-48-gate-scenes/x-gate-round-door/ui__...--t1.webp` (187272), `--t2.webp` (157334).
pofu has no layer PNGs (`git ls-tree` finds none besides the scene). `tools/imagegen/manifest/batch-58-gate-round-door.yaml:372-377`: shipped PNG is "a 0.5 Lanczos delivery of the exact retained t1 WebP pixels", `retained_source_sha256` 68820afb... (leaf).
Not found: any PNG or lossless file at 1024 x 1536 for the layers, in either repo or in `Assets`/`tools/imagegen`.

## 3. (§7.5) Hop chip and passes rows: token or name

Answer: name and SF Symbol only. No `ApplicationToken` reaches either view.
- Model: `ProtectedApp`, a String enum (`instagram, youtube, tiktok, x, snapchat, reddit, facebook, other`), `PofuCore/Gate/ProtectedApp.swift:9-18`.
  `Pass.target` is `TargetGroupID` (a String wrapper), `PofuCore/Gate/Pass.swift:41-46`.
- Hop chip: `HopAppChip(app: ProtectedApp, reachOrdinal: Int)` `App/Hop/HopView.swift:248-249`; drawn with `Image(systemName: app.symbolName)` `:254` and `Text(app.displayName)`; created at `:97` from `session.app` (`App/Hop/HopSession.swift:18`, type `ProtectedApp`).
- Passes row: `PassRow` `App/Home/PassesSheet.swift:66-72` maps `pass.target.rawValue` to `ProtectedApp`; `Image(systemName: app?.symbolName ?? "app")` `:81`; `Text(verbatim: app?.displayName ?? pass.target.rawValue)` `:87`.
- Where a token does exist: `PofuScreenTime.ApplicationToken` (a Data wrapper, `LiveScreenTimeService.swift:409-416`) in the live Screen Time selection and `LiveShieldState` (`:153`). No `Label(token)` use anywhere (`git grep "Label(.*token"` returns nothing).

## 4. (§7.6) Kit resizable caps vs batch-61 painted caps

Code rule: `PofuKitFace` (`PofuDesignSystem/Kit/KitMaterial.swift:204-225`) uses `caps` if given, else `image.size.height / 2` on all four sides (`:220-224`), `.stretch`.
Only one call passes caps: `PofuPaperSurface` (`Kit/KitPaper.swift:63`), `cornerRadius` on all four sides (default `PofuRadius.large` = 24, `KitPaper.swift:48`, `PofuTokens.swift:23`). Every other face passes none.
Painted caps: `tools/imagegen/manifest/batch-61-ui-kit-v3.yaml` `slice:` per job, equal to the promoted `design/art/ui/<id>/meta.json` `slice` in pofu. Units pt; `ship_height` = delivered image height in pt.
Default cap from the code = ship_height / 2 on all sides. No kit PNG exists in `PofuDesignSystem/Resources` (`ui-*`/`seal-*` absent), so every face currently draws its code fallback.
Painted caps are [top, left, bottom, right].

| PofuKitArt face | Code insets (pt) | Painted caps (ship_height) | Match |
|---|---|---|---|
| plaqueHoney, HoneyPressed, Bare, Cream, CreamPressed (`KitPlaque.swift:132`) | default: 28 all sides | [0,28,0,28] (56) | left/right yes; top/bottom no (28 vs 0) |
| plaqueBare as `.wood` card (`KitPaper.swift:63,72-76`) | cornerRadius (24 default) all sides | [0,28,0,28] (56) | no |
| sheetPaper, sheetPaperNight (`KitPaper.swift:124`) | default: 170.5 all sides | [32,32,32,32] (341) | no |
| cardStitched, cardStitchedNight (as sheetPaperNight, `:72-74`), cardLinen | cornerRadius, default 24 | [24,24,24,24] (160) | yes at default radius 24; other radii no |
| bubblePaper (`KitComponents.swift:211`) | default: 60 all sides | [28,28,28,28] (120) | no |
| chipFelt, chipFeltSelected (`KitComponents.swift:36`) | default: 18 all sides | [0,18,0,18] (36) | left/right yes; top/bottom no |
| grooveWood (`KitComponents.swift:255`) | default: 10 all sides | [0,10,0,10] (20) | left/right yes; top/bottom no |
| toastStrip | no `PofuKitFace` caller found | [0,32,0,32] (64) | n/a |
| sealResist (`PofuDoorStamp.swift:116`) | default: height/2 | none: `ui-seals/meta.json` slice is `None` (one sheet of three seals, not sliced) | n/a |

Left/right "yes" holds only if the delivered image is `ship_height` pt tall (3x); not measured, no kit PNG in the package.
