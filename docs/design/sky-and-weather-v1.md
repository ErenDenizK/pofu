# Sky and weather v1: the living background, real fog, one light

**Status:** spec by the lead, 2026-11-06. Research:
[sky, weather and harmony](../research/sky-weather-and-harmony.md) (rules E1-E15).
Builds on the [colour script](colour-script.md) (the five hour cells, the
unwell overlay) and [light and shadow v2](light-and-shadow-v2.md).

The founder (2026-11-06): study the background (the day cycle, islands,
colours, clouds, weather, the sky cycle); fog can be real fog; arriving at
a new place must keep its magic, so even the bad state is impressive, not
pale; and start on colour and light harmony.

## 1. What is wrong today

- **One weather.** The sky changes with the hour (`SkyModel.palette`, five
  cells blended over 30 minutes) and darkens when unwell, but it never
  rains, mists, glows gold or shows a rainbow. Days look the same.
- **Fog is a tint.** The far isles and Koke's hump are mixed toward a fog
  colour (`look.fog`), one amount for everything. There is no depth, no
  height fog hugging the cloud sea and nothing that moves, so "fog" reads as
  pale, which is what the founder saw.
- **The wound is pale.** The arc rule says stage 0 is "chroma ~40 %, flat
  cool light". Flat plus desaturated is dull, and dull kills the arrival.
- **Harmony.** The lookdev sheet (#254) shows the home plate's lawn as the
  outlier: pale and high-key, with props 1.6-1.9x its chroma. The same cast
  sits well on the IL4 concept, whose lawn is darker and greener.

## 2. Decisions

### 2.1 The sky (E1, E3, E4)

Keep the five cells (dawn, day, golden, dusk, night); a sixth "morning" key
adds nothing a 30-minute blend does not. Change three things:

- **Clouds in three layers** at 1x, 1.8x and 3x parallax (far, mid, near),
  drawn from the painted `cloud-1..4` art. The lit side takes the cell's key
  colour and the shade side the zenith colour darkened 15-25 L*; at dusk the
  undersides catch the horizon glow. Drift under 3 pt/s at the 30 Hz tier;
  their tint is recomputed every few seconds, not per frame.
- **Night stays luminous:** zenith L* 12-22, never black; a moon halo; 30 to
  40 stars that twinkle at 0.1-0.3 Hz; a shooting star at most once a clear
  night, with a soft haptic only if the app is open on that frame.
- **The transition** between cells eases with a cosine, never linear.

### 2.2 Weather (E5, E6, E7)

Weather is cosmetic and never a punishment: it never follows the player's
wellbeing (the unwell overlay stays its own thing) and never hides the
home's state. One weather per half day, picked by a seeded roll of the date,
so it is the same on every launch that day and testable.

| Weather | Share | When | Light change (key, fill, saturation, contrast) | Drawn as |
|---|---|---|---|---|
| Clear | 55 % | any | none | nothing |
| Overcast | 20 % | any | key 70 %, fill 105 %, sat 90 %, contrast 80 % | cloud layers denser and lower, soft cloud shadows off |
| Light rain | 10 % | not at night's deepest | key 50 %, fill 110 %, sat 82 %, contrast 68 %; ground L* never below 55 | two tiled streak cards at two angles and speeds, up to 12 splash decals, 3-6 puddle glints on the plate's flat ground; one warm practical stays lit |
| Mist | 8 % | dawn and morning | fog +0.15 at every depth tier, key 85 % | the fog cards of §2.3 thicken and drift |
| Golden haze | 4 % | golden hour only | key warmer, sat 108 %, a soft bloom on the horizon | a light-shaft card from the sun |
| Rainbow | payoff | only within an hour after rain ends, by day | none | one soft pastel arc sprite behind the island, fading in over 6 s |
| Snow | 0 % now | seasons and story only, later | | |

Weather crossfades over 6-10 s. Rain ends with a payoff, always: wet glints
on the plate, then a rainbow when it is day. Rain and snow are drawn at the
30 Hz ambient tier only, never in a settled 0 Hz frame (a settled frame
shows the last state frozen), and off in Low Power Mode and under Reduce
Motion (the light change stays, the particles go).

Sound follows weather once audio lands (rain on leaves, a hush in mist);
this spec reserves the hook only.

### 2.2b Weather for everyone, the sky for the player (founder, 2026-11-06)

The founder: weather and fog could follow the player, but a good player
must still experience everything, and a heavy doomscroller must see the
effect. Two layers that never mix:

- **Weather is the world's, and everyone gets all of it.** It never
  follows behaviour. The roll is a shuffled bag, not independent dice:
  every weather (and one rainbow) appears within the first 14 days, then
  the bag refills with the shares of §2.2. Weather-only life rewards it:
  snails and frogs in rain, a rainbow, the mist morning's light shafts.
- **The sky's health is the player's.** The unwell state (wellbeing 55 to
  30) becomes the **screen haze**: a cool grey-violet haze that rolls in
  from the harbor's side, thickens the depth fog, dims the practicals and
  drains the warm hues, under the §2.4 rule (value kept, beautiful, never
  punishing, never taking progress). It has its own visual language so it
  is never mistaken for weather: weather mist is pale peach and lies on
  the sea at dawn; screen haze is cool lilac-grey, comes from one side and
  sits over home at any hour. A resisted reach parts it a little, with a
  shaft of light (the clearing is the reward a doomscroller sees). A good
  player meets the same language on every wounded story island, so nobody
  misses the healing.
- **Night for everyone.** A player who only opens by day still sees the
  night: the bedtime wind-down shows home at night, and the shield's sky
  follows the real hour.
- **App surfaces share the sky:** the widget, the shield and the week page
  show the same weather and the same haze, so the effect follows the
  player outside the game; the week page names the clear days the player
  made.

### 2.3 Real fog (E8, E9)

Fog has two parts, both cheap.

- **Depth fog.** Every layer is mixed toward the **current horizon colour**
  (never grey) by its depth tier: the island in front 0.00, the mid isles
  0.18, the far isles 0.38, the farthest 0.55, plus 0.15 in mist. Shadows
  mix 1.25x as much as lights, so contrast collapses with distance the way
  air does. One table in `LookTuning`.
- **Height fog cards.** Two to four soft painted fog cards, densest at the
  cloud sea, drift at 1x, 2x and 3.5x speed, some behind the island and one
  in front of its base, so the island's foot dissolves and its top stays
  clear. Soft light shafts (alpha 0.08-0.18) cross them on mist and golden
  haze mornings. This is real fog: it has depth, it moves, and light passes
  through it.

Islands use fog as a mood, not as a filter: Emanet's eerie fog (the healing
arc's variety table) is the same system at its densest, parting where the
player looks, with one warm lantern inside it.

### 2.4 The beautiful wound (E10, E11, E12): the arc rule changes

The arc's stage 0 changes from "chroma ~40 %, flat cool light" to
**value over chroma, one warm light**:

- Warm hues are drained (mid chroma ~50 % of healed); the key light drops
  to ~85 %.
- But the value range stays full: ground to shadow at least 35 L*, the
  focal point at least 25 L* off its surroundings, the island's silhouette
  at least 12 L* off the sea. The hue moves toward blue-violet and teal
  (the colour lives in the cool shade), and the near plane keeps its texture.
- **One warm focal light** per wounded island, the only warm, saturated
  thing on stage 0: a shaft on a trickle, a lantern in fog, a sprout in a
  sunbeam. It grows with each stage. On arrival the camera finds this light
  first.
- Healing returns colour in a scripted order: chroma 0.5, 0.65, 0.8, 0.95,
  1.0; the depth fog's extra 0.55, 0.4, 0.28, 0.15, 0.08; each stage
  unlocks a hue family (moss green, then flower pinks, then gold), not just
  more saturation. A stage change plays a 3-6 s eased reveal.

Koke's painted stages 0-2 are pale and flat (made under the old rule).
They are not regenerated: code gives stage 0 the new look with what it
already has (the depth fog, a fog card across its foot, one warm shaft on
the sprout, a cooler shade grade), and Koke's stage 0 is re-checked on the
lookdev sheet. Çağlayan (#254) is already briefed under the new rule.

### 2.5 Harmony (E13, E14, E15)

- **Saturation hierarchy**, OKLCH chroma: focal 1.0, props 0.7, ground
  0.45, far background 0.25. The far plane is the palest and lightest.
- **Fix the home lawn, not the props:** the island plate's lawn goes darker
  and greener (L* 55-68), props come down 15-25 % in chroma, through the
  harmony manifest (`design/art/harmony/`), a correction baked by
  `preblur.py app`, with no regeneration. The characters stay guarded.
- **Seat every sprite:** the existing contact pads and sun shadows, plus a
  sky rim of 1-2 px at 10-30 % by weather and a 5-10 % pull of every
  layer toward the key colour.
- **The lint:** the lookdev sheet also flags ground chroma < 0.5x prop
  chroma, background chroma > ground chroma, an adjacent-layer L* gap < 8,
  and a focal-to-ground L* gap < 25. It runs on every new plate and island
  stage before the lead merges it.

## 3. PRs (disjoint files)

| PR | Owns | Contents |
|---|---|---|
| **SW-1 harmony** | `tools/assets/harmony.py` config and manifest, `design/art/harmony/`, `tools/assets/lookdev.py` lint, the rebaked plate and props | §2.5: the lawn and prop corrections, the lint; before and after lookdev sheets |
| **SW-2 weather** | `Sky/Weather.swift` (pure: the seeded roll, the shares, the light rows; tested), `Scene/WeatherLayer.swift`, the weather rows in `colour-script.json` and its generator | §2.2 with code-drawn fallbacks (streaks, glints, a code arc) until the art lands |
| **SW-3 sky and fog** | `Sky/SkyModel.swift`, `Scene/FarSky.swift`, `Sky/FarSkyLayout.swift`, `Look/WorldLight.swift` (`LookTuning` fog table), the Koke stage 0 look in `Koke/` | §2.1 and §2.3, and Koke's stage 0 per §2.4 |

SW-1 first (it changes what the others are judged against); SW-2 and SW-3
in parallel after it. Each sheet shows home at 07:00, 12:00, 18:30 and
22:30 in clear weather, then rain, mist and the rainbow at noon, and Koke at
stage 0 before and after.

**Art (Codex):** production `batch-44-weather-fx` (real ids): three soft fog
cards, a rain streak tile, a light-shaft card, a rainbow arc, a puddle
glint, as alpha or additive sprites. Exploration `batch-45-beautiful-wounds`
(x- ids): painted targets for the new stage 0 (Koke in mist with one shaft,
Emanet's fog with one lantern, Revontuli's ruin at night), and the home
island in rain and in mist, for the lookdev sheet to measure the code
against.

## 4. Done when

- Two days in a row can look different, and rain ends in a rainbow.
- Fog has depth and motion; the far isles fade into the horizon colour,
  not into grey.
- Koke's and Çağlayan's stage 0 make the founder want to land, not leave.
- The lookdev lint passes on home at all four hours.
- The frame policy holds: settled frames at 0 Hz, weather only at 30 Hz.
