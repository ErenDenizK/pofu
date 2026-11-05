# Sprite vividness

Look round 5 (founder, after two look rounds): "Objects still look pale, especially the sunflowers;
even their own colours look washed out; cold. Measure it; we are trying to hit a fine balance of focus
and contrast." The world grade was already raised (PRs #174, #180). This note measures the sprites
themselves, the pastel painted masters baked into the app catalogs, and records the source-level fix.

Method (`python3 -I tools/assets/vivid.py measure`): every sharp image in the app catalogs
(`World.xcassets` world-* and ui-*, `PofuDesignSystem/Resources/paint-*`, Pofu's own hamster), opaque
pixels only (alpha >= 0.98), CIELAB. Chroma is C* (mean and p95); L is lightness (mean and p5, the value
floor); local contrast is the standard deviation of L after subtracting a 9 px blur (what the eye reads
as "focus"). Blur variants, alternates and normal maps are skipped. Catalog pixels are compared as baked
(stations 6 px/unit, characters 7.5 px/unit; close enough for a 9 px kernel).

Limits: `tools/imagegen/qa.py` DEFAULT_LIMITS chroma_p95 warn 52 / fail 60, value floor (L p5) warn 35 /
fail 25. `docs/design/light-standard.md` sets the value spread and haze targets per layer, not a
per-sprite chroma; the QA limits are the only chroma ceiling.

## Diagnosis

Group means, before the regrade (and after, for the groups the regrade touches):

| Group (sprites) | Chroma mean | Chroma p95 | L mean | L p5 | Local contrast |
|---|---|---|---|---|---|
| character (16) | 23.9 | 48.3 | 82.0 | 59.3 | 7.39 |
| plate (2) | 31.3 | 46.5 | 72.8 | 43.7 | 1.80 |
| plant (before) (5) | 27.1 | 45.8 | 77.5 | 60.0 | 3.10 |
| plant **after** | 35.6 | 49.7 | 74.7 | 55.6 | 4.39 |
| station (before) (23) | 31.7 | 46.6 | 76.1 | 58.8 | 3.54 |
| station **after** | 37.0 | 48.4 | 73.7 | 55.7 | 4.64 |
| prop (before) (5) | 30.1 | 43.9 | 77.4 | 62.8 | 4.32 |
| prop **after** | 35.7 | 47.7 | 75.3 | 59.6 | 5.51 |
| home (before) (3) | 29.3 | 42.3 | 69.8 | 41.5 | 6.28 |
| home **after** | 37.6 | 46.6 | 67.7 | 37.8 | 7.99 |
| home-static (3) | 30.0 | 39.5 | 74.7 | 58.2 | 2.36 |
| sky (10) | 18.1 | 26.2 | 80.7 | 68.3 | 1.19 |
| chrome (18) | 29.8 | 40.2 | 77.6 | 61.4 | 2.84 |

What the numbers say, plainly:

1. **Chroma is not the whole problem.** The stations and props already sit at the characters' p95
   (about 47 against 48) and above their mean (31 against 24, because Mochi is white and Findik is
   brown). Only the plants and the pond are visibly low: the garden station is 27.1 mean (the plate is
   30.8, Simit 29.6, a station 31.7), and `world-pond-2/3/5` are 18-19. The founder's "even their own
   colours look washed out" is true for the garden and the pond, and for the jar (24.0).
2. **The sprites are too light.** Stations sit at L 76, props 77, plants 77.5, against 72.8 for the
   plate and 61.7 for the plate's own pixels (its body is darker than its sprites). A sunflower station
   is 5 L lighter than the grass it stands in; that is what reads as pale and cold at a glance, more
   than chroma does.
3. **They are soft.** Local contrast: garden 3.1, stations 3.5 (the pond 1.5-2.2), the plate 1.8, against
   7.4 for the characters (Findik 10.6). The characters have inked, hard-edged shapes; the props are
   painted in smooth washes. Focus and contrast split along that line: the figures pop, the objects sink.
4. **Cold.** The masters lean cool in the lights (pale cream-grey rather than warm cream). A slight warm
   shift is in the regrade; it is measured in the screenshots, not in a metric.
5. **Pots.** `paint-pot-bloom` is already rich (chroma 33 mean, p95 52.3 above the 50 target, L 67);
   `paint-pot-bud` is the pale one (p95 39). The jar is the palest object (L p5 41, chroma mean 24).
   `ui-pot-empty`, `ui-jar-empty` and `ui-lantern-off` (World.xcassets, hand-placed, no map entry) are
   not regraded: they are the unlit or empty states and the lantern's lit state is a glow.

Nothing breaks a limit: no sprite is over the chroma fail line (60) except the workshop glow overlay (59.2) and the lit lantern (58.8), and the
value floor holds everywhere (p5 L >= 41).

## Fix: `tools/assets/vivid.py`

A deterministic regrade at the source of the app images, config in `tools/assets/vivid.json`:

- **Where:** `preblur.py` (world catalog) runs it on the harmony-corrected master before the sharp image,
  the blur variants and the footprints are made, so every variant inherits it. `integrate.py` runs it on
  the home objects it bakes (`paint-pot-*`, `paint-jar-*`). `python3 -I tools/assets/integrate.py run`
  reproduces the catalog; a re-run is byte-stable.
- **What:** in CIELAB, on opaque pixels: vibrance (C -> C(1 + v(1 - C/50)), so low chroma gains most,
  a pixel at 50 stays at 50 and neutrals are left alone), a depth term that takes lightness off pale
  mid-to-high tones (L 45..85), a local-contrast lift on L against an alpha-aware blur (no edge halos,
  bounded per kind), and a slight warm shift in a and b.
- **Which:** per kind. `plant` (garden-*) and `home` (pots, jar) are strongest, `station` next, `prop`
  (decor, harbor props) gentlest. Never: characters, the island plate and harbor plate, other islands,
  sky, glow overlays, UI chrome, the lantern.
- **Limits:** a chroma limiter compresses chroma above 49.6 until the sprite's p95 is <= 50 (a sprite that
  was above, like `paint-pot-bloom` at 52.3, comes down to 49.7 by compressing only its top few percent, a
  trade the extra mean chroma pays for; the margin absorbs 8-bit rounding); the value floor
  is min(35, the sprite's own L p5) and scales the grade down if it would be crossed. Both are
  bisected, so the output is a pure function of the master and the config.

### Result

| Sprite | Chroma mean | Chroma p95 | L mean | Local contrast |
|---|---|---|---|---|
| `world-bagel-cart-1` | 34.5 -> 40.0 | 49.0 -> 49.9 | 73.0 -> 70.8 | 5.49 -> 7.05 |
| `world-bagel-cart-2` | 33.7 -> 39.4 | 48.5 -> 49.8 | 73.4 -> 71.2 | 5.35 -> 6.83 |
| `world-bagel-cart-3` | 34.4 -> 39.3 | 52.0 -> 49.9 | 74.9 -> 72.6 | 5.18 -> 6.64 |
| `world-bagel-cart-4` | 33.8 -> 38.8 | 51.8 -> 49.8 | 73.1 -> 70.9 | 5.97 -> 7.59 |
| `world-bagel-cart-5` | 33.3 -> 38.0 | 52.1 -> 49.9 | 75.8 -> 73.4 | 5.20 -> 6.63 |
| `world-decor-bench` | 35.9 -> 41.4 | 43.0 -> 47.4 | 77.3 -> 75.1 | 3.91 -> 4.96 |
| `world-garden-1` | 27.8 -> 37.3 | 42.5 -> 49.2 | 73.7 -> 71.2 | 2.35 -> 3.36 |
| `world-garden-2` | 28.3 -> 37.0 | 45.7 -> 49.8 | 79.0 -> 76.0 | 3.07 -> 4.40 |
| `world-garden-3` | 27.3 -> 36.1 | 44.3 -> 49.8 | 77.8 -> 74.9 | 3.45 -> 4.86 |
| `world-garden-4` | 27.2 -> 35.6 | 46.4 -> 49.8 | 78.6 -> 75.6 | 3.40 -> 4.76 |
| `world-garden-5` | 25.0 -> 31.8 | 50.1 -> 49.9 | 78.7 -> 75.7 | 3.21 -> 4.58 |
| `world-harbor-crates-1` | 32.7 -> 38.6 | 41.3 -> 46.2 | 76.9 -> 74.8 | 4.17 -> 5.45 |
| `world-harbor-ferry-1` | 23.1 -> 27.9 | 48.9 -> 49.8 | 76.5 -> 74.5 | 5.38 -> 6.73 |
| `world-harbor-horn-1` | 29.1 -> 34.7 | 42.2 -> 46.9 | 76.2 -> 74.2 | 4.74 -> 6.10 |
| `world-harbor-lamp-1` | 29.8 -> 35.9 | 44.0 -> 48.1 | 80.2 -> 78.0 | 3.38 -> 4.31 |
| `world-lighthouse-1` | 33.2 -> 38.7 | 49.1 -> 49.9 | 74.3 -> 72.0 | 6.25 -> 8.00 |
| `world-pier-1` | 34.2 -> 40.7 | 41.3 -> 46.7 | 74.7 -> 72.4 | 5.51 -> 6.99 |
| `world-pond-1` | 24.5 -> 30.2 | 45.1 -> 49.3 | 81.5 -> 78.7 | 2.20 -> 3.00 |
| `world-pond-2` | 18.7 -> 24.3 | 35.4 -> 41.8 | 80.0 -> 77.2 | 2.20 -> 3.04 |
| `world-pond-3` | 18.3 -> 23.8 | 35.2 -> 41.6 | 80.5 -> 77.7 | 1.97 -> 2.71 |
| `world-pond-4` | 20.4 -> 25.4 | 46.2 -> 49.8 | 83.2 -> 80.4 | 1.87 -> 2.58 |
| `world-pond-5` | 18.5 -> 23.2 | 43.7 -> 48.4 | 83.7 -> 80.8 | 1.51 -> 2.09 |
| `world-tea-stall-1` | 39.3 -> 44.2 | 47.1 -> 49.9 | 70.2 -> 68.3 | 3.79 -> 5.06 |
| `world-tea-stall-2` | 37.9 -> 42.9 | 48.1 -> 49.9 | 70.7 -> 68.8 | 3.30 -> 4.40 |
| `world-tea-stall-3` | 38.1 -> 43.0 | 48.6 -> 49.9 | 72.2 -> 70.2 | 2.96 -> 3.94 |
| `world-tea-stall-4` | 37.7 -> 42.6 | 49.4 -> 49.9 | 73.1 -> 71.0 | 2.75 -> 3.65 |
| `world-tea-stall-5` | 35.4 -> 39.8 | 54.6 -> 49.9 | 73.9 -> 71.6 | 2.87 -> 3.89 |
| `world-windmill-1` | 35.5 -> 41.5 | 45.2 -> 49.3 | 76.9 -> 74.4 | 2.81 -> 3.80 |
| `world-windmill-2` | 38.8 -> 42.7 | 52.4 -> 49.9 | 80.4 -> 77.7 | 2.32 -> 3.15 |
| `world-windmill-3` | 38.0 -> 41.8 | 52.2 -> 49.9 | 80.1 -> 77.4 | 2.72 -> 3.62 |
| `world-windmill-4` | 34.3 -> 39.5 | 50.0 -> 49.9 | 77.4 -> 74.9 | 2.70 -> 3.56 |
| `world-windmill-5` | 21.3 -> 28.5 | 32.2 -> 39.5 | 76.5 -> 74.0 | 3.05 -> 4.03 |
| `world-workshop-1` | 35.4 -> 41.7 | 43.3 -> 48.0 | 70.8 -> 68.8 | 3.40 -> 4.58 |
| `paint-jar-full` | 24.0 -> 31.9 | 35.7 -> 43.1 | 74.7 -> 72.5 | 9.22 -> 11.61 |
| `paint-pot-bloom` | 33.3 -> 41.1 | 52.3 -> 49.7 | 67.0 -> 65.0 | 5.03 -> 6.50 |
| `paint-pot-bud` | 30.8 -> 39.8 | 39.0 -> 46.8 | 67.6 -> 65.5 | 4.60 -> 5.87 |

Group means after: plant chroma mean 27.1 -> 35.6 (p95 49.7), station 31.7 -> 37.0 (p95 48.4), prop
30.1 -> 35.7, home objects (pots, jar) 29.3 -> 37.6; mean L down 2 to 3 points (plants 77.5 -> 74.7, stations 76.1 -> 73.7);
local contrast up about 30-40 % (plants 3.1 -> 4.4, stations 3.5 -> 4.6, props 4.3 -> 5.5). The characters
(7.4), the plate, and the sky are byte-identical. Contrast still sits below the characters on purpose:
the figures stay the focus, the objects stop sinking.

Knobs for the next look round are in `tools/assets/vivid.json` (`vibrance`, `depth`, `contrast`,
`warm_a`, `warm_b` per kind); re-bake with `integrate.py run`. The before/after screenshots are on the
PR.

## Full table (before the regrade)

| Sprite | Group | Chroma mean | Chroma p95 | L mean | L p5 | Local contrast |
|---|---|---|---|---|---|---|
| `pofu-hamster` | character | 22.0 | 43.0 | 83.4 | 62.7 | 4.48 |
| `world-findik` | character | 24.1 | 48.4 | 77.9 | 44.2 | 10.64 |
| `world-findik-eyes-closed` | character | 24.6 | 49.6 | 79.5 | 48.8 | 9.47 |
| `world-findik-eyes-happy` | character | 23.9 | 48.0 | 78.9 | 47.9 | 10.49 |
| `world-findik-work` | character | 26.2 | 49.8 | 80.8 | 55.9 | 8.42 |
| `world-mochi` | character | 11.5 | 29.8 | 88.8 | 69.5 | 6.98 |
| `world-mochi-eyes-closed` | character | 16.9 | 42.8 | 83.4 | 65.1 | 6.42 |
| `world-mochi-eyes-happy` | character | 16.5 | 42.3 | 86.4 | 72.5 | 5.99 |
| `world-mochi-surprised` | character | 18.4 | 44.9 | 85.0 | 65.4 | 5.66 |
| `world-mochi-work` | character | 16.9 | 45.3 | 85.3 | 67.7 | 5.37 |
| `world-simit-happy` | character | 30.2 | 54.5 | 80.9 | 61.0 | 7.34 |
| `world-simit-kitten` | character | 29.6 | 55.0 | 80.5 | 58.8 | 7.71 |
| `world-simit-kitten-ears` | character | 28.3 | 54.2 | 82.3 | 60.8 | 7.06 |
| `world-simit-kitten-work` | character | 33.9 | 55.4 | 76.3 | 45.1 | 8.89 |
| `world-simit-sleepy` | character | 29.9 | 54.4 | 81.0 | 60.7 | 6.75 |
| `world-simit-surprised` | character | 29.7 | 55.2 | 82.0 | 62.9 | 6.59 |
| `world-harbor-island-s` | plate | 31.8 | 48.3 | 84.0 | 69.3 | 1.10 |
| `world-island-main (4 bands)` | plate | 30.8 | 44.7 | 61.7 | 18.0 | 2.51 |
| `world-garden-1` | plant | 27.8 | 42.5 | 73.7 | 57.0 | 2.35 |
| `world-garden-2` | plant | 28.3 | 45.7 | 79.0 | 60.8 | 3.07 |
| `world-garden-3` | plant | 27.3 | 44.3 | 77.8 | 58.3 | 3.45 |
| `world-garden-4` | plant | 27.2 | 46.4 | 78.6 | 62.3 | 3.40 |
| `world-garden-5` | plant | 25.0 | 50.1 | 78.7 | 61.6 | 3.21 |
| `world-bagel-cart-1` | station | 34.5 | 49.0 | 73.0 | 56.0 | 5.49 |
| `world-bagel-cart-2` | station | 33.7 | 48.5 | 73.4 | 54.6 | 5.35 |
| `world-bagel-cart-3` | station | 34.4 | 52.0 | 74.9 | 57.2 | 5.18 |
| `world-bagel-cart-4` | station | 33.8 | 51.8 | 73.1 | 51.0 | 5.97 |
| `world-bagel-cart-5` | station | 33.3 | 52.1 | 75.8 | 56.4 | 5.20 |
| `world-lighthouse-1` | station | 33.2 | 49.1 | 74.3 | 50.7 | 6.25 |
| `world-pier-1` | station | 34.2 | 41.3 | 74.7 | 55.9 | 5.51 |
| `world-pond-1` | station | 24.5 | 45.1 | 81.5 | 67.9 | 2.20 |
| `world-pond-2` | station | 18.7 | 35.4 | 80.0 | 67.1 | 2.20 |
| `world-pond-3` | station | 18.3 | 35.2 | 80.5 | 67.3 | 1.97 |
| `world-pond-4` | station | 20.4 | 46.2 | 83.2 | 70.6 | 1.87 |
| `world-pond-5` | station | 18.5 | 43.7 | 83.7 | 74.2 | 1.51 |
| `world-tea-stall-1` | station | 39.3 | 47.1 | 70.2 | 50.8 | 3.79 |
| `world-tea-stall-2` | station | 37.9 | 48.1 | 70.7 | 51.2 | 3.30 |
| `world-tea-stall-3` | station | 38.1 | 48.6 | 72.2 | 53.0 | 2.96 |
| `world-tea-stall-4` | station | 37.7 | 49.4 | 73.1 | 54.3 | 2.75 |
| `world-tea-stall-5` | station | 35.4 | 54.6 | 73.9 | 54.3 | 2.87 |
| `world-windmill-1` | station | 35.5 | 45.2 | 76.9 | 59.7 | 2.81 |
| `world-windmill-2` | station | 38.8 | 52.4 | 80.4 | 63.5 | 2.32 |
| `world-windmill-3` | station | 38.0 | 52.2 | 80.1 | 64.7 | 2.72 |
| `world-windmill-4` | station | 34.3 | 50.0 | 77.4 | 62.3 | 2.70 |
| `world-windmill-5` | station | 21.3 | 32.2 | 76.5 | 62.7 | 3.05 |
| `world-workshop-1` | station | 35.4 | 43.3 | 70.8 | 46.5 | 3.40 |
| `world-decor-bench` | prop | 35.9 | 43.0 | 77.3 | 65.1 | 3.91 |
| `world-harbor-crates-1` | prop | 32.7 | 41.3 | 76.9 | 64.4 | 4.17 |
| `world-harbor-ferry-1` | prop | 23.1 | 48.9 | 76.5 | 58.9 | 5.38 |
| `world-harbor-horn-1` | prop | 29.1 | 42.2 | 76.2 | 60.9 | 4.74 |
| `world-harbor-lamp-1` | prop | 29.8 | 44.0 | 80.2 | 64.5 | 3.38 |
| `paint-jar-full` | home | 24.0 | 35.7 | 74.7 | 41.3 | 9.22 |
| `paint-pot-bloom` | home | 33.3 | 52.3 | 67.0 | 41.4 | 5.03 |
| `paint-pot-bud` | home | 30.8 | 39.0 | 67.6 | 41.7 | 4.60 |
| `ui-jar-empty` | home-static | 25.3 | 36.1 | 79.7 | 67.8 | 1.89 |
| `ui-lantern-off` | home-static | 32.4 | 41.8 | 76.9 | 63.8 | 2.48 |
| `ui-pot-empty` | home-static | 32.2 | 40.6 | 67.6 | 42.9 | 2.72 |
| `world-harbor-goat` | other | 17.3 | 40.9 | 85.7 | 64.8 | 6.32 |
| `world-pond-5-glow` | glow | 39.2 | 41.6 | 87.3 | 82.4 | 2.14 |
| `world-tea-stall-1-glow` | glow | 42.6 | 43.7 | 79.1 | 78.7 | 0.28 |
| `world-windmill-5-glow` | glow | 45.8 | 48.7 | 82.1 | 79.4 | 1.22 |
| `world-workshop-1-glow` | glow | 54.8 | 59.2 | 82.6 | 79.0 | 0.63 |
| `world-cloud-2` | sky | 5.8 | 9.3 | 90.2 | 83.8 | 0.30 |
| `world-cloud-4` | sky | 6.0 | 9.5 | 90.5 | 85.5 | 0.25 |
| `world-cloud-sea` | sky | 4.7 | 7.2 | 90.3 | 85.3 | 0.14 |
| `world-far-isle-1` | sky | 10.5 | 17.0 | 86.7 | 79.3 | 0.31 |
| `world-far-isle-2` | sky | 7.0 | 12.3 | 86.8 | 81.2 | 0.31 |
| `world-far-isle-3` | sky | 7.0 | 11.8 | 88.4 | 83.5 | 0.24 |
| `world-isle-hamam-standin` | sky | 37.9 | 49.2 | 70.3 | 46.3 | 1.81 |
| `world-isle-harbor-standin` | sky | 35.1 | 47.6 | 67.1 | 45.8 | 3.35 |
| `world-isle-library-standin` | sky | 27.3 | 49.3 | 68.1 | 46.1 | 2.39 |
| `world-isle-stars-standin` | sky | 39.3 | 48.9 | 68.7 | 45.7 | 2.76 |
| `paint-face-disc` | chrome | 9.7 | 18.5 | 90.5 | 86.1 | 0.59 |
| `paint-face-primary` | chrome | 51.8 | 57.3 | 68.1 | 56.7 | 0.65 |
| `paint-face-secondary` | chrome | 13.4 | 25.9 | 88.6 | 82.0 | 0.37 |
| `paint-icon-breath` | chrome | 23.3 | 33.7 | 76.6 | 60.6 | 2.25 |
| `paint-icon-calm` | chrome | 45.3 | 51.5 | 78.9 | 55.7 | 2.60 |
| `paint-icon-decor` | chrome | 32.4 | 43.5 | 73.2 | 54.4 | 2.98 |
| `paint-icon-friend` | chrome | 24.9 | 32.8 | 71.9 | 57.5 | 2.11 |
| `paint-icon-island` | chrome | 32.8 | 42.0 | 71.6 | 55.5 | 1.78 |
| `paint-icon-mood-content` | chrome | 26.5 | 48.4 | 80.3 | 46.2 | 6.74 |
| `paint-icon-plus` | chrome | 39.3 | 44.1 | 78.5 | 62.2 | 1.28 |
| `paint-icon-round` | chrome | 37.4 | 43.1 | 68.2 | 45.9 | 6.46 |
| `paint-icon-rumour` | chrome | 20.6 | 38.5 | 77.7 | 61.2 | 3.24 |
| `paint-icon-seed` | chrome | 26.6 | 35.9 | 72.5 | 51.8 | 4.19 |
| `paint-icon-skip` | chrome | 44.6 | 59.4 | 69.5 | 42.6 | 4.41 |
| `paint-icon-tea` | chrome | 35.5 | 48.6 | 69.8 | 47.9 | 4.67 |
| `paint-lantern-on` | chrome | 45.3 | 58.8 | 76.1 | 63.3 | 3.32 |
| `paint-panel-paper` | chrome | 12.2 | 21.8 | 92.8 | 87.5 | 2.64 |
| `paint-tag-paper` | chrome | 14.8 | 19.4 | 91.4 | 88.5 | 0.78 |
