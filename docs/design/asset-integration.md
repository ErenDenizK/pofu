# Asset integration

Founder, 2026-11-05: "Most of those assets never arrived; I want to see them all." This is the
inventory of every approved master under `design/art/masters`, `stations` and `ui` (not the `x-`
explorations, not a node whose status is `cut`) against the app's asset catalogs
(`Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets`, `PofuGames/Resources`,
`App/Resources/Assets.xcassets`) and the Swift that draws them. Status after PR
`feat/integrate-approved-art`.

## How art gets in

- World art (stations, residents, poses, the harbor, lit overlays): add the master to `APP_SOURCES` in
  `design/prototypes/interactions/tools/preblur.py`, list it in `tools/assets/integration_map.json`
  (so `integrate.py check` fails when its imageset is missing), then
  `python3 -I tools/assets/integrate.py run` bakes the sharp, soft and deep variants and the
  generated table `WorldArt+Generated.swift`. `harmony.py measure` records its colour correction.
- UI art for the garden game: `integrate.py` bakes it into `PofuGames/Resources` at 3x.
- Sizes: stations are capped at 6 px per world unit, characters at 7.5, the harbor's stations and
  dressing at 4 (the harbor is only seen between the map and the island framing, under 1x, so 4 px
  is at most 1.3 times the 3x screen). Nothing is upscaled. The whole new art adds 2.7 MB.

## What this change integrates

| Art | Where it shows |
|---|---|
| bagel-cart-1 to -5, pier-1, lighthouse-1 | The harbor plate (`IslandLayout.scenery`, slots in `harborStationSlots`), at 0.7 of a station's size; a built station appears at its level |
| harbor-crates-1, decor-bench, harbor-horn-1, harbor-lamp-1, harbor-ferry-1 | Harbor dressing that comes with a built station (`harborProps`), baked at 0.45 to 1.0 of the guide |
| simit-happy, -sleepy, -surprised | `SimitPose` (happy from cart level 3, sleepy at bedtime, surprised in a cart build pop) |
| mochi-work, -surprised, -eyes-happy, -eyes-closed; findik-work, -eyes-happy, -eyes-closed | `ResidentPose` (`Resident.art(for:)`): work while the camera is on them or their station, surprised then happy through a build pop (`BuildMoment.residentPose`), eyes shut at bedtime; a missing pose (Findik surprised) falls back to the base |
| workshop-1-lit, pond-5-lit, windmill-5-lit | Night glows `workshop-1-glow`, `pond-5-glow`, `windmill-5-glow` through the existing `IslandLayout.litOverlay` hook, like `tea-stall-1-glow` |

## Not integrated, and why

- **workshop-2 to -5**: their opaque pixels run to the left edge of the canvas, so the shed's left
  wall and roof are clipped (the cut comes from the clipped workshop-1 they were edited from;
  `relock.py --pad` cannot recover what the raw never had). Regenerate them from the padded
  `workshop-1--lock-light.png`. The art plan's "home ladder 25 of 25" counts them as done.
- **bagel-cart-1 to -5** are clipped by a few pixels at the right edge of their canvas (the cart's
  right wall). They are integrated because the cut is small at harbor size; regenerating with the
  padded parent would clean them.
- **Pofu rig layers** (`pofu-eyes-*`, `pofu-mouth-*`, `pofu-paws-*`, `pofu-cheeks-puff-*`,
  `pofu-ears-droop`, `pofu-fur-matted`, `pofu-rig-clean`): the live companion draws one painted
  body and its lids; there is no layer consumer yet (`tools/rig`).
- **cloud-1, -3, -5, bridge-east, islet-east, sun-glow, terrace-v2**: no consumer. The living sky
  uses cloud-2 and cloud-4; its layout and the framing and look constants belong to PR #180.
- **UI art** (`icon-*`, `ui-face-*`, `ui-jar-full`, `ui-lantern-on`, `ui-pot-*`, the paper panels):
  the sheet and menu UI is `feat/painted-menus`, not this change.
- **pier-2 to -5, lighthouse-2 to -5, harbor-ferry-2, decor-lanterns, decor-sailboat,
  decor-mailbox**: not generated yet (art plan row 1).
- The pier and lighthouse have one level of art each: higher levels show it as the stand-in. The
  ferry is drawn alongside the new planks once the pier is built; pier-3's own sprite will show it
  moored.

## Inventory

`in catalog?` means an imageset or flat PNG exists; `used in code?` means a Swift path draws it.

| id | kind | master path | in catalog? | used in code? | action |
|---|---|---|---|---|---|
| bridge-east | master | `design/art/masters/bridge-east` | no | no | deferred: no consumer (map bridge, not designed) |
| cloud-1 | master | `design/art/masters/cloud-1` | no | no | deferred: the living sky uses cloud-2 and cloud-4 (framing and look constants are PR #180) |
| cloud-2 | master | `design/art/masters/cloud-2` | yes | yes | none (shipped) |
| cloud-3 | master | `design/art/masters/cloud-3` | no | no | deferred: as cloud-1 |
| cloud-4 | master | `design/art/masters/cloud-4` | yes | yes | none (shipped) |
| cloud-5 | master | `design/art/masters/cloud-5` | no | no | deferred: as cloud-1 |
| cloud-sea | master | `design/art/masters/cloud-sea` | yes | yes | none (shipped) |
| decor-bench | master | `design/art/masters/decor-bench` | yes | yes | integrated in this PR: harbor dressing (lighthouse built); no home decor slot yet |
| far-isle-1 | master | `design/art/masters/far-isle-1` | yes | yes | none (shipped) |
| far-isle-2 | master | `design/art/masters/far-isle-2` | yes | yes | none (shipped) |
| far-isle-3 | master | `design/art/masters/far-isle-3` | yes | yes | none (shipped) |
| findik-base | master | `design/art/masters/findik-base` | yes | yes | none (shipped) |
| findik-eyes-closed | master | `design/art/masters/findik-eyes-closed` | yes | yes | integrated in this PR: `ResidentPose.eyesClosed` |
| findik-eyes-happy | master | `design/art/masters/findik-eyes-happy` | yes | yes | integrated in this PR: `ResidentPose.eyesHappy` |
| findik-work | master | `design/art/masters/findik-work` | yes | yes | integrated in this PR: `ResidentPose.work` |
| harbor-goat | master | `design/art/masters/harbor-goat` | yes | yes | none (shipped) |
| harbor-island-s | master | `design/art/masters/harbor-island-s` | yes | yes | none (shipped) |
| island-main-l-v2 | master | `design/art/masters/island-main-l-v2` | yes | no | comparison bake (`--v2` bands); v3 is the shipped plate |
| island-main-l-v3 | master | `design/art/masters/island-main-l-v3` | yes | yes | none (shipped) |
| island-main-s | master | `design/art/masters/island-main-s` | no | no | superseded by island-main-l-v3 (earlier small plate) |
| islet-east | master | `design/art/masters/islet-east` | no | no | deferred: no consumer (map islet) |
| mochi-eyes-closed | master | `design/art/masters/mochi-eyes-closed` | yes | yes | integrated in this PR: `ResidentPose.eyesClosed` (bedtime) |
| mochi-eyes-happy | master | `design/art/masters/mochi-eyes-happy` | yes | yes | integrated in this PR: `ResidentPose.eyesHappy` (build hop) |
| mochi-surprised | master | `design/art/masters/mochi-surprised` | yes | yes | integrated in this PR: `ResidentPose.surprised` (build pop) |
| mochi-v2 | master | `design/art/masters/mochi-v2` | yes | yes | none (shipped) |
| mochi-work | master | `design/art/masters/mochi-work` | yes | yes | integrated in this PR: `ResidentPose.work` (camera on her or her station) |
| pofu-cheeks-puff-1 | master | `design/art/masters/pofu-cheeks-puff-1` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-cheeks-puff-2 | master | `design/art/masters/pofu-cheeks-puff-2` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-cheeks-puff-3 | master | `design/art/masters/pofu-cheeks-puff-3` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-ears-droop | master | `design/art/masters/pofu-ears-droop` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-eyes-closed | master | `design/art/masters/pofu-eyes-closed` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-eyes-happy | master | `design/art/masters/pofu-eyes-happy` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-eyes-matte | master | `design/art/masters/pofu-eyes-matte` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-eyes-side | master | `design/art/masters/pofu-eyes-side` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-fur-matted | master | `design/art/masters/pofu-fur-matted` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-hamster-base-v1 | master | `design/art/masters/pofu-hamster-base-v1` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-chew | master | `design/art/masters/pofu-mouth-chew` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-o | master | `design/art/masters/pofu-mouth-o` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-open | master | `design/art/masters/pofu-mouth-open` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-pout | master | `design/art/masters/pofu-mouth-pout` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-smirk | master | `design/art/masters/pofu-mouth-smirk` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-mouth-worried | master | `design/art/masters/pofu-mouth-worried` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-paws-belly | master | `design/art/masters/pofu-paws-belly` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-paws-seed | master | `design/art/masters/pofu-paws-seed` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-paws-up | master | `design/art/masters/pofu-paws-up` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-paws-wave | master | `design/art/masters/pofu-paws-wave` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| pofu-rig-clean | master | `design/art/masters/pofu-rig-clean` | no | no | deferred: rig layer; the live companion draws `pofu-hamster.png` and its lids, no consumer for layers yet |
| simit-happy | master | `design/art/masters/simit-happy` | yes | yes | integrated in this PR: `SimitPose.happy` (cart level 3+) |
| simit-kitten | master | `design/art/masters/simit-kitten` | yes | yes | none (shipped) |
| simit-kitten-ears | master | `design/art/masters/simit-kitten-ears` | yes | yes | none (shipped) |
| simit-kitten-work | master | `design/art/masters/simit-kitten-work` | yes | yes | none (shipped) |
| simit-sleepy | master | `design/art/masters/simit-sleepy` | yes | yes | integrated in this PR: `SimitPose.sleepy` (bedtime) |
| simit-surprised | master | `design/art/masters/simit-surprised` | yes | yes | integrated in this PR: `SimitPose.surprised` (cart build pop) |
| sun-glow | master | `design/art/masters/sun-glow` | no | no | deferred: no consumer (sky light is code) |
| terrace-v2 | master | `design/art/masters/terrace-v2` | no | no | deferred: no consumer (concept) |
| bagel-cart-1 | station | `design/art/stations/bagel-cart-1` | yes | yes | integrated in this PR: harbor station slot, level sprite by `IslandLayout.scenery` |
| bagel-cart-2 | station | `design/art/stations/bagel-cart-2` | yes | yes | integrated in this PR: same |
| bagel-cart-3 | station | `design/art/stations/bagel-cart-3` | yes | yes | integrated in this PR: same |
| bagel-cart-4 | station | `design/art/stations/bagel-cart-4` | yes | yes | integrated in this PR: same |
| bagel-cart-5 | station | `design/art/stations/bagel-cart-5` | yes | yes | integrated in this PR: same |
| garden-1 | station | `design/art/stations/garden-1` | yes | yes | none (shipped) |
| garden-2 | station | `design/art/stations/garden-2` | yes | yes | none (shipped) |
| garden-3 | station | `design/art/stations/garden-3` | yes | yes | none (shipped) |
| garden-4 | station | `design/art/stations/garden-4` | yes | yes | none (shipped) |
| garden-5 | station | `design/art/stations/garden-5` | yes | yes | none (shipped) |
| harbor-crates-1 | station | `design/art/stations/harbor-crates-1` | yes | yes | integrated in this PR: harbor dressing (cart built) |
| harbor-ferry-1 | station | `design/art/stations/harbor-ferry-1` | yes | yes | integrated in this PR: harbor dressing (pier built) |
| harbor-horn-1 | station | `design/art/stations/harbor-horn-1` | yes | yes | integrated in this PR: harbor dressing (pier built) |
| harbor-lamp-1 | station | `design/art/stations/harbor-lamp-1` | yes | yes | integrated in this PR: harbor dressing (pier built) |
| lighthouse-1 | station | `design/art/stations/lighthouse-1` | yes | yes | integrated in this PR: harbor station slot |
| pier-1 | station | `design/art/stations/pier-1` | yes | yes | integrated in this PR: harbor station slot (carries on past the plate pier) |
| pond-1 | station | `design/art/stations/pond-1` | yes | yes | none (shipped) |
| pond-2 | station | `design/art/stations/pond-2` | yes | yes | none (shipped) |
| pond-3 | station | `design/art/stations/pond-3` | yes | yes | none (shipped) |
| pond-4 | station | `design/art/stations/pond-4` | yes | yes | none (shipped) |
| pond-5 | station | `design/art/stations/pond-5` | yes | yes | none (shipped) |
| pond-5-lit | station | `design/art/stations/pond-5-lit` | yes | yes | integrated in this PR: night glow `pond-5-glow` (three lanterns) |
| tea-stall-1-lit | station | `design/art/stations/tea-stall-1-lit` | yes | yes | none (shipped) |
| tea-stall-2 | station | `design/art/stations/tea-stall-2` | yes | yes | none (shipped) |
| tea-stall-3 | station | `design/art/stations/tea-stall-3` | yes | yes | none (shipped) |
| tea-stall-4 | station | `design/art/stations/tea-stall-4` | yes | yes | none (shipped) |
| tea-stall-5 | station | `design/art/stations/tea-stall-5` | yes | yes | none (shipped) |
| windmill-1 | station | `design/art/stations/windmill-1` | yes | yes | none (shipped) |
| windmill-2 | station | `design/art/stations/windmill-2` | yes | yes | none (shipped) |
| windmill-3 | station | `design/art/stations/windmill-3` | yes | yes | none (shipped) |
| windmill-4 | station | `design/art/stations/windmill-4` | yes | yes | none (shipped) |
| windmill-5 | station | `design/art/stations/windmill-5` | yes | yes | none (shipped) |
| windmill-5-lit | station | `design/art/stations/windmill-5-lit` | yes | yes | integrated in this PR: night glow `windmill-5-glow` (two windows) |
| workshop-1 | station | `design/art/stations/workshop-1` | yes | yes | none (shipped) |
| workshop-1-lit | station | `design/art/stations/workshop-1-lit` | yes | yes | integrated in this PR: night glow `workshop-1-glow` (doorway) |
| workshop-2 | station | `design/art/stations/workshop-2` | no | no | blocked: clipped on the left (opaque pixels on the canvas edge); regenerate from the padded workshop-1 |
| workshop-3 | station | `design/art/stations/workshop-3` | no | no | blocked: same clip |
| workshop-4 | station | `design/art/stations/workshop-4` | no | no | blocked: same clip |
| workshop-5 | station | `design/art/stations/workshop-5` | no | no | blocked: same clip |
| icon-breath | ui | `design/art/ui/icon-breath` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-calm | ui | `design/art/ui/icon-calm` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-decor | ui | `design/art/ui/icon-decor` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-friend | ui | `design/art/ui/icon-friend` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-game-seed | ui | `design/art/ui/icon-game-seed` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-mood-content | ui | `design/art/ui/icon-mood-content` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-plus | ui | `design/art/ui/icon-plus` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-round | ui | `design/art/ui/icon-round` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-rumour | ui | `design/art/ui/icon-rumour` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-seed | ui | `design/art/ui/icon-seed` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| icon-station-tea-stall | ui | `design/art/ui/icon-station-tea-stall` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-face-disc | ui | `design/art/ui/ui-face-disc` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-face-primary | ui | `design/art/ui/ui-face-primary` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-face-secondary | ui | `design/art/ui/ui-face-secondary` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-face-secondary-pressed | ui | `design/art/ui/ui-face-secondary-pressed` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-game-bed-rim | ui | `design/art/ui/ui-game-bed-rim` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-bloom-front | ui | `design/art/ui/ui-game-bloom-front` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-bloom-left | ui | `design/art/ui/ui-game-bloom-left` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-bloom-right | ui | `design/art/ui/ui-game-bloom-right` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-combo-stamp | ui | `design/art/ui/ui-game-combo-stamp` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-honey | ui | `design/art/ui/ui-game-plot-tile-honey` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-lilac | ui | `design/art/ui/ui-game-plot-tile-lilac` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-mint | ui | `design/art/ui/ui-game-plot-tile-mint` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-rose | ui | `design/art/ui/ui-game-plot-tile-rose` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-sage | ui | `design/art/ui/ui-game-plot-tile-sage` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-plot-tile-terracotta | ui | `design/art/ui/ui-game-plot-tile-terracotta` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-game-soil-cell | ui | `design/art/ui/ui-game-soil-cell` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
| ui-jar-empty | ui | `design/art/ui/ui-jar-empty` | yes | yes | none (shipped) |
| ui-jar-full | ui | `design/art/ui/ui-jar-full` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-lantern-off | ui | `design/art/ui/ui-lantern-off` | yes | yes | none (shipped) |
| ui-lantern-on | ui | `design/art/ui/ui-lantern-on` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-menu-paper | ui | `design/art/ui/ui-menu-paper` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-panel-paper | ui | `design/art/ui/ui-panel-paper` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-pot-bloom | ui | `design/art/ui/ui-pot-bloom` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-pot-bud | ui | `design/art/ui/ui-pot-bud` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-pot-empty | ui | `design/art/ui/ui-pot-empty` | yes | yes | none (shipped) |
| ui-sheet-paper | ui | `design/art/ui/ui-sheet-paper` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-tag-paper | ui | `design/art/ui/ui-tag-paper` | no | no | UI: feat/painted-menus (sheet, paper panels, icons) |
| ui-ui-game-tray | ui | `design/art/ui/ui-ui-game-tray` | yes | yes | none (shipped by integrate.py, `GardenArt`) |
