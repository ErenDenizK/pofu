# Sky, weather, fog and colour harmony

Research for the founder feedback of 2026-11-06 (background study; real fog and a
beautiful bad state; colour and light harmony). Written 2026-11-06.

**Evidence tags.** `[S]` = backed by a source fetched/searched this session (URL
inline). `[K]` = established craft knowledge (art fundamentals, public talks I
know but could not re-fetch). `[D]` = a derived number or proposal for Pofu,
to be tuned on device, not a fact about any game. Network note: `WebFetch` could
not reach blog.camposanto.com or blog.runevision.com (not in the session's
allowed hosts), so several claims rest on search summaries only and are marked.
No source gave hex palettes or exact transition durations for the named games;
all durations/numbers below are `[D]` unless tagged.

## A. Sky and day cycle in acclaimed stylised work

### A1. What the sources actually say

- **Firewatch.** Art lead Jane Ng: the sky sets most of the game's colour because
  outdoors it is the largest coloured area on screen `[S]`. A colour script
  aligned to narrative beats kept the look consistent `[S]`. The sky was built in
  Marmoset Skyshop as a **three-colour gradient (top, middle, bottom) + sun disc +
  sun halo + horizon halo**, and two skies could be interpolated A to B over a set
  time to make a real sunset `[S]`. Much of the final colour comes from "lighting
  + fog + colour correction" `[S]`. Olly Moss's key painting took its palette and
  flat shapes from New Deal-era National Park posters `[S]`.
  <https://blog.camposanto.com/post/112703721804/this-blog-post-is-an-in-detail-explanation-of-part>,
  <https://www.thumbsticks.com/gdc-2015-the-art-of-firewatch>
  Lesson: a sky is only ~6 parameters (3 gradient stops, sun disc, sun halo,
  horizon halo); time of day = lerp between keyed parameter sets, not new art.
- **GRIS.** Developers made a colour script first, checking each area's palette
  against the story `[S]`. Starts near-monochrome, colour returns chapter by
  chapter (reports differ on order: red, green, blue, yellow vs grey to blue to
  gold; verify in-game) `[S]`. Interview:
  <https://intothespine.com/2018/12/12/interview-nomada-studio-on-gris-inspiration-aspiration-and-aesthetic/>
- **Animal Crossing NH.** Weather is seeded per island: clear day = cloudless
  bright blue, clear night = many stars; **shooting stars only on clear nights**
  (light showers: a few bursts/hour; heavy: every few minutes); **a rainbow fills
  the sky for 1 hour after rain ends**; double rainbow exceptionally rare;
  auroras only in winter on clear nights `[S]`. Rain "darkens the lighting to
  simulate dense rain clouds" `[S]`.
  <https://nookipedia.com/wiki/Rain>,
  <https://animalcrossingworld.com/2020/06/predict-meteor-showers-rainbows-auroras-in-animal-crossing-new-horizons-with-weather-forecaster-tool/>
  Lesson: **rare weather is a reward gated by a precondition** (rainbow needs
  rain first; meteors need clear night). Cheap to build, big delight.
- **Ghibli / Kazuo Oga.** Skies and feathered clouds done with a large flat
  brush on pre-wetted paper for soft edges; base coat (ji-nuri) laid fast while
  wet `[S, secondary]`; Oga says it is "a way of seeing and feeling" more than a
  technique `[S]`. Totoro's backgrounds drew on Akita country life `[S]`.
  <https://animationobsessive.substack.com/p/what-kazuo-oga-thinks-about-when>,
  <https://gurneyjourney.blogspot.com/2018/05/painting-in-ghibli-style.html>
  Lesson `[K]`: cumulus has a **warm lit top, cool blue-violet underside, and a
  soft but not blurry edge on the lit side, sharper on the shadow side**; the sky
  near the horizon is lighter and warmer than the zenith; clouds are not white.
- **Pixar colour scripts.** One small image per sequence mapping palette to
  emotion; Nemo mutes colour on dark beats and brightens on happy ones; Up
  contrasts "real world" with Paradise Falls `[S]`.
  <https://www.slashfilm.com/503975/cool-stuff-lou-romanos-color-script-for-pixars-up/>
  Lesson: the script is an **ordered table of (hue family, value, saturation)
  per beat**, authored once, then every asset is graded to it.
- **Spiritfarer.** Day/night shapes route planning (ship anchors at nightfall,
  sails only with sun) `[S]`; Ghibli-influenced hand-drawn look `[S]`. No sky
  numbers found. **A Short Hike**: flat cohesive shading, soft outline to help
  objects stand out `[S]` (<https://www.gamedeveloper.com/disciplines/road-to-the-igf-adam-robinson-yu-s-i-a-short-hike-i->).
  **Alba, Tunic, Journey, Children of the Light**: nothing found; any claims
  below about them are `[K]` only (Journey: dusk gold to deep violet night, warm
  light is the goal marker; do not cite as sourced).
- **Implementation pattern** (S&box breakout `SkyController`): a palette struct
  (sky top, horizon, clouds, two hill layers) blended day to night by lerp,
  **cosine-eased** (slow at ends, fast in the middle), and displayed colours
  drift toward target each frame so changes never snap `[S]`.
  <https://sbox.game/facepunch/breakout/source?file=Game%2FSkyController.cs>

### A2. Rules distilled for a keyed sky (all `[D]` unless noted)

1. **Key 6 times of day**, each a full parameter set: dawn, morning, noon,
   golden hour, dusk, night. Interpolate in a perceptual space (OKLab/OKLCH),
   never raw sRGB (muddy midpoints, e.g. blue to orange passes through grey).
2. **Sky gradient = zenith / mid / horizon**, horizon lightest and warmest at
   dawn/dusk, zenith deepest and most chromatic. Noon: zenith L~62 C~0.10 hue
   ~245; horizon L~90 C~0.04 hue ~220. Dusk: zenith L~35 hue ~290 (violet), mid
   magenta-rose, horizon L~80 C~0.13 hue ~55 (peach/amber).
3. **Transitions**: ease-in-out (cosine/smoothstep) between keys; real-time
   mapping, e.g. 20 to 40 min of wall-clock per hour-block change; for a
   *scripted* change (weather, arrival) 3 to 6 s. Never a hard cut on screen.
4. **Cloud light is per-hour**: lit side takes the sun/key colour, shade side
   takes sky-zenith colour darkened by ~15 to 25 L; at dusk the *undersides*
   catch the horizon glow first (rose/amber underlit, violet tops).
5. **Horizon glow** = a separate additive/soft-light band + a sun/moon halo
   (Firewatch's "horizon halo" `[S]`), 2 to 4x wider than the sun disc.
6. **Night is not black**: deep blue-violet (L 12 to 22, C 0.05 to 0.08), moon
   halo, stars at 1 to 3 px with slow twinkle (0.1 to 0.3 Hz, a few dozen stars
   only), rare shooting star on clear nights only (ACNH precedent `[S]`).
7. **Cheap aliveness** (ranked by value per watt): (a) 2 to 3 cloud layers
   drifting at different speeds (far 1x, mid 1.8x, near 3x, ~0.5 to 3 px/s) at
   parallax; (b) cloud colour and sky colour change with the hour (free:
   multiply/tint a pre-painted cloud); (c) a slow sun glint/sparkle on cloud
   rims; (d) occasional rare event (bird flock, shooting star, rainbow). For a
   battery-first renderer, motion at 30 Hz is plenty for drift under 3 px/s;
   settled frames at 0 Hz means the *colour change itself* should be applied as
   a tint/LUT, computed every N seconds, not per frame.

## B. Weather in cozy mobile games

### B1. What ships and how often

- ACNH ships: clear, cloudy, light/heavy rain, snow (winter), shooting stars,
  rainbow (post-rain), aurora (winter clear night), thunder (heavy rain); weather
  is deterministic from a per-island seed `[S]`. Rainbow and double rainbow are
  deliberately scarce; auroras and meteors have preconditions `[S]`.
- Happy Home Paradise lets designers set weather/time: sunny or rainy to start `[S]`.
- Pattern across the genre `[K]`: 55 to 65% clear, 20 to 25% cloudy/overcast,
  10 to 15% precipitation, <5% special. Gloomy weather is short (30 to 90 min),
  followed by a bright payoff.

### B2. How weather changes light (what to move, by how much; `[D]`)

| Weather | Key light | Fill/ambient | Saturation | Contrast | Sky/clouds |
|---|---|---|---|---|---|
| Clear | 100% warm | cool blue | 100% | 100% | sparse bright cumulus |
| Overcast | 55% | 120% (soft, neutral-cool) | 85% | 70% | broad pearl layer, no sun disc |
| Light rain | 45% | 110% | 80% | 65% | blue-grey, darker undersides |
| Mist | 60% | 130% | 70% (toward fog hue) | 50% far / 80% near | see C |
| Snow | 50% | 130% | 65% | 60% | pale lilac-grey; brightest overall |
| Golden haze | 110% (low, orange) | 90% | 110% warm / 80% cool | 90% | amber horizon, long shadows |
| Rainbow | clear + 15% brighter after rain | | 110% | | rainbow = soft arc, alpha 0.25 to 0.4 |

How to avoid gloom `[K]`: never drop *value* below the "readable floor"
(ground L >= 55); darken with **colour not black** (shift key toward cool-violet,
keep shadows chromatic); keep one warm accent lit (window, lantern, the hamster's
own glow); rain should be bright-grey-blue, wet surfaces get *specular glints*;
always play a short reward (rainbow, sun break) as the weather ends.

### B3. Cheap rendering (budget for 30 Hz ambient / battery-first)

Sources are thin: forum advice only `[S]` (Unreal forum, Construct forum,
PC Gamer overview <https://www.pcgamer.com/uk/how-developers-make-perfect-rain-in-games/>).
Supported: **batch many droplets in one texture/atlas**; **scrolling tiled
streak texture** replaces 10 to 30x as many particles; **2 to 3 rain layers with
different fall angles/speeds** for depth; ripples by particles or painted dots;
one dev dropped reflective puddles because they distracted from gameplay `[S]`.
Proposed `[D]`:
- Rain: 2 tiled streak cards (far: small, low alpha 0.25, slow; near: long,
  alpha 0.45, fast, angle +/-4 degrees apart), no per-drop particles. Splash/ripple
  decals: <= 12 live, 4-frame sprites, only on ground planes.
- Puddle glints: 3 to 6 static sparkle sprites on water tiles that twinkle at
  1 Hz; no real reflection.
- Snow: <= 60 flakes in 2 depth bands (size 2 and 4 px), sine drift.
- Mist: 2 to 4 large soft cards (see C), moving < 4 px/s.
- Overcast/rain tint: one screen-space multiply + gradient (top darker/cooler),
  reused from the time-of-day grade; no extra full-screen pass beyond one.
- Weather change: crossfade 6 to 10 s; stop drawing a layer at alpha < 0.02.
- Audio pairing `[K]`: rain bed is a loop of 20+ s with 3 s crossfade, thunder
  rare and soft, mist = near-silence + low pad, snow = muffled; sound
  precedes visuals by ~1 s to prepare the change.

## C. Fog as atmosphere, and the beautiful bad state

### C1. Real fog vs pale

Sources: search summaries (the runevision article "Notes on atmospheric
perspective" and Campo Santo posts could not be fetched):
- Aerial perspective: distant things are paler, bluer, lower contrast; nearer
  things keep more chroma and darker values `[S]`
  (<https://blog.runevision.com/2025/06/notes-on-atmospheric-perspective-and.html>,
  <https://gamedev.net/tutorials/visual-arts/easy-atmospheric-perspective-in-photoshop-r2521>).
  Also: desaturating distance can steer the player's eye to important elements `[S]`.
- Fog guides: layered fog, **each layer hides more detail; foreground darker,
  sharper; mid lighter, softer** `[S]` (a drawing-tutorial summary, weak source).
- Firewatch: much of its colour is "lighting + fog + colour correction" `[S]`.
- The decisive rule `[K]`: **fog is a mix toward a luminous, tinted fog colour
  (usually the sky's horizon colour), not toward grey.** The thing "pale" misses:
  fog adds *light* (in-scatter), so shadows lift toward the fog colour and
  contrast collapses, but the scene gets *more* luminous, not duller.

What distinguishes real fog from "paleness" (checklist):
1. Per-depth: opacity rises with distance; two islands at different depths must
   differ in fog amount by a visible step (>= 0.15 mix per depth tier).
2. Fog colour = horizon-sky colour of the current hour (warm peach at dusk, cool
   milky blue at dawn), and *objects shift toward it*, shadows most of all.
3. **Height fog**: densest at the cloud-sea surface and in hollows, thinning
   upward; islands emerge from it (their bases are lost, tops are clear).
4. **Moving cards**, not a static veil: 2 to 4 large soft-edged fog sprites at
   different speeds/depths, some *in front of* an island and some *behind*,
   so parallax proves volume. Overlap with islands must be partial.
5. **Light inside fog is visible**: god rays/soft shafts (additive, narrow
   cone, low alpha 0.08 to 0.18), halo around lamps and the sun.
6. Silhouettes: the far islands become flat value shapes, cooler and lighter
   than near ones, with edges still readable.
7. One warm focal light (lantern, window, ember, the hamster's glow) that
   punches through; it is the "come in" signal.

### C2. Beautiful dark/ruined/fogged states (what they do right)

Sourced facts are few; the rest is `[K]`.
- **GRIS**: an almost colourless start is kept alive by a colour script `[S]`,
  watercolour textures, strong shapes, and layered depth `[S, weak: halabaojia
  analysis]`. `[K]` the early grey scenes are not grey: they are warm white, dusty
  rose, ash-blue; one saturated accent per scene.
- **Ori**: "an abundance of light sources all radiating in harmony", character
  small in frame to show scale `[S]` (<https://www.thesixthaxis.com/2014/10/22/deep-into-the-woods-with-ori-and-the-blind-forest/>).
  `[K]` even the dark Mouldwood Depths has bioluminescent teal/orange accents
  against deep purple-black, so value contrast stays high.
- **Limbo / Inside**: grayscale where "light and shadow define the playing field
  and direction"; the unseen is the threat `[S]` (<https://www.girlsongames.ca/2017/04/27/art-examination-playdead-limbo/>).
  Beauty = soft fog gradient in the background (huge value range in one image),
  hard black silhouette in front, bright misty horizon.
- **Hollow Knight**: hand-drawn, muted gothic palette `[S]`; `[K]` each area has
  its own hue (blue Crossroads, teal Greenpath, violet Fungal) so "dark" never
  means "one colour"; light pools (lumafly, lamps) mark safety.
- **Spirited Away / Ghibli** `[K]`: mist is lit and tinted (blue-violet to warm
  amber from lanterns), lanterns on the far bank glow through it; the "bad" evening
  town is the most gorgeous image in the film.
- **Journey dark section, Spiritfarer, Alba**: nothing sourced; `[K]` Journey's
  buried-ruins/snow scenes keep a warm-white light source and cool teal air.

### C3. Rules for lowering chroma/brightness without losing "come in"

Keep HIGH (all `[D]`, informed by the above):
- **Value contrast**: ground-to-shadow >= 35 L* steps; focal object vs its
  surroundings >= 25 L*; island silhouette vs sea >= 12 L* even at stage 0.
- **A single focal light** warmer than everything (hue 50 to 80, C 0.12 to
  0.18, L 80+), 1 per island, with a halo and a soft shaft in the fog.
- **Rich cool hues**: lower chroma by moving toward *blue-violet-teal*, never
  toward neutral grey: target chroma never below 0.03 in mids, 0.015 in far
  fog; hue shifts (not just L/C) make it feel designed.
- **Texture/detail** on the near plane (grass tufts, cracks, moss): bad state
  should read as "textured and interesting", not "blurred and flat".
- **Shape language**: crisp readable silhouettes; the wound is a *shape*
  (broken arch, hollow, cracked edge), not a dim filter.
Lower: overall chroma (~35 to 50% on mids), key brightness (~15%), warm accents
(except the focal light), detail in the far plane.

## D. Colour and light harmony for composited sprites

Sources for this section were not found by search this session; everything is
`[K]` (industry practice, e.g. Pixar colour scripts `[S]` above for the idea of a
script) or `[D]`. Treat numbers as starting tolerances.

1. **One key colour, one fill colour per scene**; every layer (plate, props,
   characters, clouds, FX) gets the same two lights. Practical: after drawing, a
   **global multiply (shadows) + soft-light/overlay tint (highlights)** per time
   of day; props painted in neutral light (about 6500 K, slightly desaturated),
   then lit in-engine. Painting pre-baked warm sunlight into sprites breaks every
   other hour.
2. **Ambient bounce**: props adjacent to coloured ground pick up 5 to 12% of it
   in their shadow side (green lawn gives a olive-teal bounce, never grey).
3. **Value hierarchy** (L*, `[D]`): background sky/far L 75 to 92 (light by
   aerial perspective) > ground mid L 55 to 70 > props mid-dark L 35 to 60 >
   focal accent either darkest or lightest locally. Values squinted to
   greyscale must still read focal > ground > background.
4. **Saturation hierarchy** (`[D]`): chroma ratio **focal : props : ground :
   background = 1.0 : 0.7 : 0.45 : 0.25** (OKLCH C). The founder's complaint
   (props too saturated against a pale lawn) means props are at >= 1.0 of focal
   and ground at <= 0.3: the fix is *raise lawn chroma* (+ darker, richer green)
   and *lower prop chroma 15 to 25%* so only the focal item is the loudest.
5. **Hue unification**: pull all hues 5 to 10% toward the key hue (a global
   tint) and keep shadows in a single cool hue family (blue-violet) so shaded
   regions agree across sprites.
6. **Edges and contact**: every prop gets a **contact shadow** (soft ellipse,
   multiply, opacity 0.25 to 0.4, cool-tinted, blur ~ prop height/6) and a
   **sky rim** on edges facing the sky (1 to 2 px, sky-zenith colour, 20 to 30% on
   clear, 10% overcast). Matching edge softness (A Short Hike used a soft outline to
   unify `[S]`) avoids the "sticker" look.
7. **Colour script + LUT**: author one table (time x weather x stage) of
   (key, fill, ambient, saturation, contrast), and one **3D LUT or 5-param grade**
   per row; apply to all layers, so assets stay time-neutral (Firewatch: colour
   from lighting, fog and grade `[S]`; Pixar/GRIS colour scripts `[S]`).
8. **Shadow side saturation**: shadows should be slightly *more* saturated and
   cooler than lit side in painted style (Oga/Ghibli practice `[K]`), never grey.
9. **Measurement** `[D]`: compute OKLCH mean (L, C, h) per layer on a contact
   sheet each render; fail CI-style checks if ground C < 0.5x prop C, or
   background C > ground C, or any layer's L overlaps the next by < 8.

## E. Recommendations for Pofu

(Numbers are starting values to tune on the iPhone; each ties to a source.)

1. **Keyed sky, six keys, perceptual lerp.** Dawn, morning, noon, golden hour,
   dusk, night; each key = zenith/mid/horizon gradient + sun/moon disc + sun halo
   + horizon halo (6 parameters), interpolated in OKLCH with a cosine ease; real
   transitions 20 to 40 min, scripted ones 3 to 6 s, never a hard cut. (Firewatch
   sky build + two-sky interpolation; S&box cosine-eased palette lerp.)
2. **One lighting table drives every layer.** Time x weather x stage rows hold
   key colour, fill colour, saturation, contrast; sprites are painted
   time-neutral and graded in-engine by multiply (shadow) + soft-light (highlight)
   so sky, plate, props, clouds and FX share light. (Firewatch "lighting + fog +
   colour correction"; Pixar/GRIS colour scripts.)
3. **Cloud layers carry the time of day.** Three drifting layers at 1x/1.8x/3x
   parallax, lit side takes key colour, shade side takes zenith colour darkened
   15 to 25 L, undersides catch horizon glow at dusk; a sun glint on rims. Motion
   under 3 px/s at 30 Hz; colour changes applied as tint every few seconds, not
   per frame. (Oga cloud practice; Firewatch horizon halo; battery rules.)
4. **Night stays luminous.** Deep blue-violet (L 12 to 22), moon halo, a few dozen
   twinkling stars (0.1 to 0.3 Hz), a rare shooting star on clear nights only.
   (ACNH shooting stars gated to clear nights.)
5. **Weather list and rarity.** Clear 55%, overcast 20%, light rain 10%, mist
   8%, golden haze (dusk only) 4%, snow (winter/story only) 2%, rainbow 1%
   (**only as the 1-hour-class payoff after rain**, `2.0x` rarer when doubled).
   Specials are preconditioned: rainbow needs rain just ended, shooting star
   needs clear night. (ACNH weather rarity and preconditions.)
6. **Weather moves light, never gloom.** Rain: key 45%, fill 110%, sat 80%,
   contrast 65%; ground L never below 55; darken toward cool violet, keep shadows
   chromatic, keep one warm accent lit, end with a payoff. Crossfade 6 to 10 s.
   (ACNH rain darkens lighting; genre practice.)
7. **Cheap rain/snow/mist.** Two tiled streak cards at different angle and speed,
   <= 12 splash decals, 3 to 6 puddle glints, <= 60 snow flakes in 2 bands, 2 to 4
   fog cards; one screen-space tint pass. Weather runs in the 30 Hz ambient tier
   only; settled frames stay 0 Hz. (Tiled-texture and layered-rain advice;
   dropped reflective puddles.)
8. **Fog is a per-depth mix toward the horizon-sky colour, not grey.**
   `layer = mix(layer, fogColor, f)`, with f by depth tier: island front 0.00,
   mid 0.18, far 0.38, farthest 0.55 (plus +0.15 in mist weather), and shadows
   mix 1.25x as much as lights (contrast collapse, in-scatter). Fog colour =
   current horizon colour; farther layers also lighten and cool. (Atmospheric
   perspective notes; Firewatch fog.)
9. **Height fog + moving cards give real volume.** Density densest at the cloud
   sea and in hollows; islands' bases dissolve, tops stay clear; 2 to 4 soft
   cards drifting 1x/2x/3.5x speeds with some in front of and some behind the
   island; soft light shafts alpha 0.08 to 0.18. (Layered fog guide; Limbo
   gradient depth; Ori abundance of light.)
10. **Stage 0 keeps "come in": value over chroma.** Lower mids' chroma to 50% and
    key to 85%, but hold ground-to-shadow >= 35 L*, focal vs surroundings >= 25
    L*, island silhouette vs sea >= 12 L*; move hue toward blue-violet-teal (min
    chroma 0.03 mids); keep texture on the near plane. (GRIS colour script;
    Limbo value structure; Hollow Knight hue-per-area.)
11. **One warm focal light per wounded island.** Hue 50 to 80, C 0.12 to 0.18, L
    80+, halo + a shaft through the fog, the only warm high-chroma element on
    stage 0; it grows with each stage. Arrival: the camera finds this light first
    (silhouettes of far islands, the lit one in front). (Ori light sources; Spirited
    Away lanterns in mist; GRIS accent.)
12. **Healing returns colour in a scripted order.** One colour script row per
    stage (0 to 4): chroma 0.5/0.65/0.8/0.95/1.0 x base, key 0.85 to 1.0, fog
    mix 0.55/0.4/0.28/0.15/0.08, new hue families unlocked per stage rather than
    only more saturation; stage change plays a 3 to 6 s eased reveal.
    (GRIS chapter colour return; Pixar Nemo muting on dark beats.)
13. **Saturation hierarchy of 1.0 : 0.7 : 0.45 : 0.25** (focal : props :
    ground : background, OKLCH C). Fix the pale-lawn problem by raising lawn
    chroma and darkening it (L 55 to 68), lowering prop chroma 15 to 25%,
    and letting the sky/far plane be the palest and lightest. (Colour hierarchy
    craft; Pixar colour script for intent.)
14. **Seat every sprite in the light.** Cool contact shadow (multiply 0.25 to
    0.4, blur ~ height/6), 5 to 12% ground bounce on the shadow side, sky rim
    1 to 2 px at 10 to 30% by weather, shadows slightly cooler and more saturated
    than lights, one global hue pull of 5 to 10% toward key. (A Short Hike soft
    outline unification; painted-style practice.)
15. **Make harmony measurable.** On every render sheet compute mean OKLCH per layer
    and flag: ground C < 0.5 x prop C, background C > ground C, adjacent-layer
    L gap < 8, focal vs ground L gap < 25. Treat as a lint on art, not a
    taste debate. (Colour-script/LUT unification principle.)

## Open items

- Verify hex/duration numbers against Jane Ng's GDC 2016 talk "The Art of
  Firewatch" and the GRIS artbook; neither reachable this session.
- Allow blog.camposanto.com and blog.runevision.com in the cloud network if the
  fog sections should be re-checked against the primary posts.
- Nothing found on Alba, Tunic, Journey, Children of the Light skies; do not
  quote them as evidence.
