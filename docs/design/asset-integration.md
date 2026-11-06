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

## Showcase art (feat/integrate-showcase-art)

| Art | Where it shows |
|---|---|
| `dressing-meadow` (sheet of twelve) | Cut into twelve sprites (`MEADOW_CELLS` in `preblur.py`, one cell per piece, one shared scale). `DressingPiece.variant` picks one: tufts and clover, daisy / cornflower / buttercup clumps and the foxglove, pebbles, the flat stone and the mossy stone, the toadstool ring. They replace the code-drawn stand-ins of the meadow family; the garden and harbor families still draw stand-ins. |
| `door-mochi`, `door-findik` | `HomeFixtures.doors`: in the plate's earth face at H2 (IL2) and H3 (IL6), at the plate's own door scale. |
| `hive-1` to `hive-3` | `HomeFixtures.hiveArt`: the hive is a gift station with no levels in the game yet, so the island carries it: hive 1 at IL9, hive 2 at IL10, hive 3 at IL10 once every home station is at its top level. The slot moved from S6's (-32, -6) to (74, -6): the workshop's painted ground reaches x -55, so nothing between the pond and the workshop is free (`HomeFixturesTests`). |
| `goat-work` | `GoatPose.work` on the harbor, from the pier's first level (the goat coils the rope). |
| `harbor-bell` | Harbor dressing that comes with the bagel cart (`harborProps`), L4's bell on its post at the lawn's left end. |

## Experience art (feat/integrate-experience-art)

Batch 35 (`docs/design/experience-v1.md` sections 2, 3 and 6): each piece replaced a code-drawn stand-in by name.

| Art | Where it shows |
|---|---|
| `glow-window-spill`, `glow-warm-halo`, `glow-pond-shimmer` | White-on-alpha `glow` imagesets (like `glow-ground-pool`), tinted per source and added. The window spill is the lit windows' trapezoid on the grass in the baked light map (`PoolMapArt`), the pond shimmer the pond's ellipse at pond level 5, the warm halo the bloom round the ember, the path lamps and the calm lantern (`HD2DLayer.drawHalo`; the tight cores stay code). Sizes and opacities are `LookTuning`. |
| `firefly` (sheet of four frames) | `firefly-1` to `-3` (dim, warming, bright; the fourth repeats the first), cut by `integrate.py` (target `sprite`). They replace the code dots at night: same 18 flies and blink, battery-gated by the frame policy's `particles`, drawn over the graded world with the painted halo, mirrored by their drift. |
| `launch-sky`, `cloud-curtain-1` to `-3` | The app's own catalog (target `app`, `@3x`). The sky was delivered at half scale and is restored to its declared 1290 x 2796 (the only upscale; it is a soft sky) with harmony's correction; `UILaunchScreen` and `LaunchCurtain` already looked them up by name. |
| `shield-pofu-door` (three scenes) | `shield-pofu-door-calm`, `-proud`, `-sleepy` (target `shield`): the scene cut from the sheet, halation cleared, trimmed, on a square 360 px canvas, in `PofuCompanion/Resources` and listed in `project.yml` for the shield extension. `ShieldIconImage` already loads them by name and keeps its drawn door as the fallback. The shield is one still per mood. |
| `dressing-garden` | Six of its ten pieces (`dressing-watering-can`, `-seed-sack`, `-twine`, `-crate`, `-crate-2` the stack, `-trowel`), cut by `GARDEN_CELLS` in `preblur.py` at 13 source px per unit. The pot, bucket, gloves and rake wait for a slot. |
| `dressing-harbor` | `dressing-rope` and `dressing-barrel` (`HARBOR_CELLS`) at the bridge's foot. The buoy, net, oar, lantern, bollard, trays and pail wait for a slot. |
| `critter-butterfly`, `-snail`, `-bird` | Frames cut by `CRITTER_CELLS` (one scale and one baseline per sheet; the left-facing frames mirrored so every sprite faces right). `CritterKind.spriteFrames` maps a pose's `frame` to the sheet: four wing poses, the snail's stretch and crouch, the bird's wings up, down and song; `CritterView` mirrors by the pose's facing. Rest is frame 0. The ladybug and the frog keep their stand-ins. |

Vividness: the garden's and the harbor's dressing are `prop`s (the meadow's stay `plant`s); the critters are left as painted, with harmony's correction only.

## Lit masters, reactions and style options (feat/integrate-lit-and-reactions)

| Art | Where it shows |
|---|---|
| `lighthouse-1-lit`, `path-lamp-lit`, `door-mochi-lit` | Masked lit edits (everything outside the edit's `emit_region` is the day master, pixel for pixel), so the night glows `lighthouse-1-glow`, `path-lamp-glow`, `door-mochi-glow` are the difference against the day master inside the padded region (`_emissive_diff` in `preblur.py`, no colour key). One `LitSources` row each: `lamp-lighthouse` (island `.harbor`: its overlay is drawn on the harbor's slot with the harbor's fade, `HD2DLayer.harborFade`; it throws no light on the home lawn), `lamp-1` to `lamp-3` and `window-mochi` (overlay on the door's centre). |
| `path-lamp` | The day master of the lamp, which had no consumer: `HomeFixtures.lampFeet`, three lamps from island level 6 (home layout L1 to L3), 0.8 of the decor guide (`LAMP_SIZE`). |
| mochi-happy/-sleepy/-proud, findik-happy/-sleepy/-proud/-surprised, goat-happy/-surprised/-sleepy/-proud, simit-proud | Poses that swap in place on the base's canvas and feet. `ResidentEvent` (level-up hop, visitor arrived, ceremony done, first tap of the day) to `ResidentPose` and `ResidentReactions` (each lapses by itself); bedtime is `.sleepy`; `SimitPose` and `GoatPose` take the same events. The older eye poses are the fallback of happy and sleepy. |
| `bagel-cart-3-blue`, `lighthouse-3-blue`, `lighthouse-4-blue` | Baked under these names (the second L3 style option, home progression 4.2); no consumer yet. Follow-up: a saved per-station style (old saves default to the first option), a two-swatch picker in the station sheet at L3, and the remaining batch 40 options (tea stall, workshop, windmill, the L5s) once promoted; a picker that offers a style with no art at a level would show a hole. |

## Koke (feat/koke-art-and-framing)

| Art | Where it shows |
|---|---|
| `koke-island-0` to `-2` | `world-koke-island-N`: the plates were delivered at half scale (768 x 512 for 1536 x 1024; `deliver.original_size`) and are drawn 250 units wide on Koke's centre. They are opaque on their own sky, so `preblur.py` cuts them out (`matte`: not sky, not cloud, largest piece, holes filled, 1.5 px feather) and the world draws its own sky and cloud sea behind. The plates already carry Koke (sleeping, then waking), so the colour arc is painted: `KokeLayout.saturation` leaves stages 0 to 2 as painted. |
| stages 3 and 4 | Stand-ins until their plates are painted: the stage 2 plate, lifted by the grade (1.1, 1.2), code-drawn blossoms at stage 4 (`KokeLayout.hasBlossoms`) and a pose drawn over the plate's Koke (`KokeLayout.overlay`): `koke-stretch` and `koke-standing` fall back to `koke-one-eye`, the standing one 1.1 larger with a gentle bounce (`KokeLayout.bounce`; still under Reduce Motion and in still frames). `koke-island-3` and `-4` replace the plate and stand-in as soon as an imageset exists (raise `KokeLayout.paintedStages`). |
| `koke-asleep`, `koke-one-eye` | `world-koke-asleep`, `world-koke-one-eye`: 114 units wide, feet on the anchor, one scale. Today only `koke-one-eye` shows (the stage 3 and 4 overlay), because the plates carry Koke for stages 0 to 2. |

Colour: `koke-*` is never regraded (`vivid.json` `never`) and is guarded in harmony (`config.json`), so the stage 0 grey stays grey.

## Shadow silhouettes

`python3 -I tools/assets/shadows.py run` writes `<imageset>-shadow.imageset` for every casting sprite
(stations at every level, residents and their poses, decor, dressing, critters, visitors and the jar and
lantern): black, alpha = the sprite's alpha at 1/4 size, blurred by 3 % of its height. `ShadowBake` flattens
and shears them at runtime (light and shadow v2, `docs/design/light-and-shadow-v2.md` section 3). New art that
casts (a regenerated station, a new critter) needs `shadows.py run`; CI runs `shadows.py check` and fails on a
missing or stale shadow. The sidecar `tools/assets/shadows.json` holds the source hashes.

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
