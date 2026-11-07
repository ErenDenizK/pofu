# Reference look: why the references cohere, and the look pipeline v2

Founder, 2026-11-07: copy the whole system from the references he likes
(I1's seven seasons, the batch-34 map plates and batch-31 home levels, the
gezgin f2 and Revontuli nights, the batch-50 gate postcards); understand *why*
their light, shadow, colour and consistency are so good, weigh every
technique, invent where needed. This note measures the references, names the
principles, diagnoses the game against each, surveys techniques and proposes
the pipeline. It builds on `concept-match.md` (PR in `wt-match`: DoF slab,
night cell, earth band, cut route; not repeated), `night-lighting-2d.md`
(relight maths) and `sky-weather-and-harmony.md` (craft rules). Tags: **[M]**
measured here, **[S]** sourced, **[K]** craft knowledge, **[D]** derived.

Sheets in `reference-look/`: `01-value-envelope`, `02-light-colour`,
`03-air-and-bounce`, `04-edges-contact`, `05-night`. Numbers: CIELAB, D65;
`loc` = RMS of L* minus its 3 px Gaussian blur; "dark-edge %" = pixels more
than 15 L* below their 6 px blur. Game frames: `screenshots/main`, 2026-11-07
(before the concept-match PR). Scripts were scratch; the targets in §6.4 are
what a tool should keep.

## 0. The answer in one paragraph

The references are one painting under one light, inside one envelope of
milky air: every value sits between L* 50 and 97 by day (only the night sky
goes dark), every colour leans to the key's hue, colour lives in the
halftones while lights bleach to cream, edges are found by value and hue and
never by dark lines, and the cloud sea lights the islands from below. Our
game assembles separately painted sprites under rules that **forbid** that
look: the enforced light standard demands true darks (day p2 <= 22) and
rejects milky air, so all three liked references *fail* it (`light.py`:
I1 summer p2 51, Çağlayan healed p2 52, gezgin f2 night median 78 against a
night band of 18-50); the runtime then adds contrast (day 1.16) and
saturation (1.32), a darkening vignette, crisp cast shadows and, at night, a
grade that crushes the frame to L* 11. The route: change the rule first, then
make the shipped pixels *painted* the way the references are (final-first
master per light state, island and assets together, cut into layers), bake
what a painter would bake, and keep the runtime to what must move (crossfade
of states, one LUT, airlight, practicals, characters).

## 1. Corpus

Day: I1 summer, spring, autumn, rain, snow (`batch-25-seasons`, t2); map
plates (`batch-34`, Çağlayan, Tam Çiçek); gate postcards (`batch-50`, six
lights). Golden: I1 summer evening, postcard golden. Night: gezgin f2 night
(`batch-22`), Revontuli stuck (`batch-34`), I1 snow night, postcard night;
Tam Çiçek night (`batch-31`) as the "too contrasty" counter-example. Game:
`weather-home-clear/-golden-haze/-rain/-mist`, `sky-home-2230`,
`light-night-home`, `caglayan-night-4`.

## 2. The principles (why the references work)

1. **A high-key value envelope** [M] (sheet 01). Day frames: p2 53-62,
   p50 79-90, p98 95-97, 0 % of pixels below L* 40; even the island-top
   props have p2 48-57. The darkest things (door holes, pond rims) are L* ~50.
   Form is carried by small value steps inside a light band, which reads as
   soft, airy and toy-like. Game day: p2 28-40, 2-4.5 % below L* 40.
2. **Night is a hue change, not a value drop** [M] (sheet 05). Liked nights:
   frame p50 72-77, island and clouds L* 70-90, only the sky is dark (L* 25-36),
   shadows violet (a* +10..+22, b* -25..-39), lights cream (b* 0..15). Game
   night: p50 11-14, 89-98 % of pixels below L* 30, neutral shadows (C 2).
   The founder's "too contrasty" Tam Çiçek night has the *most* dark pixels
   (11 % below 30), the highest chroma (27) and contrast (loc 2.7); the
   gezgin f2 night is the softest (0 %, 21, 1.7). He wants less contrast and
   chroma, not less light.
3. **One envelope of air** [M] (sheet 03). The postcards' horizon band is the
   lightest (L* 86-90), least saturated (C 9-13) and flattest band (loc ~0.2);
   contrast peaks at the focal mid-ground (loc ~1.0) and softens again in the
   extreme foreground. A veil of the sky's colour sits over everything, which
   lifts the black point (principle 1) and binds the layers.
4. **One key colour that everything leans to** [M] (sheet 02). Greens are
   yellow-greens close to the warm key (summer L* 74, hue 107; spring 84/106;
   autumn 77/88); the game's are darker and bluer (65/118; lawn proper
   61-63 L*, hue 128-138). At evening every surface and the cloud sea shift
   pink-peach together (sea a* +10); in rain the light stays warm-cream on a
   lilac sky.
5. **Colour lives in the halftones; lights bleach to cream** [M] (sheet 02).
   Chroma peaks at L* 70-85 and falls in the lightest band (spring: darks C 37,
   lights C 9; autumn 43 vs 11). Light cores roll to cream-white (lantern core
   b* 21, ring 36). Darks keep chroma (C 29-37), never grey.
6. **Soft, enveloping light** [K, M]. A big sky dome with a weak key from the
   upper front: round forms turn with wide, warm terminators (felt, plush,
   clay), cast shadows are short and soft, directly under objects. Light
   direction is consistent across every prop because one model painted them
   in one pass.
7. **Occlusion pads, not cast shadows** [K] (sheet 04). Every object sits on
   a soft warm-grey pad; crevices darken a little; the lawn's lip throws a
   soft band on the earth face (earth just below the lip L* 65-74, belly 83-91).
8. **The cloud sea is the world's reflector** [M] (sheet 03). The island's
   underside stays light and peach to the bottom (L* 70-81) because the sea
   below is the brightest large surface (day L* 82-92; night still 73-85).
   It is the giant fill light; game sea at night is L* 14.
9. **No ink** [M] (sheet 04). Edges are found by value and hue shifts; edge
   pixels are no darker than their surroundings (mean -0.3..-2.5 L*), dark-
   edge pixels 2.0-2.6 %. Silhouettes are found against the sky, internal
   edges are lost. Game: 7.5 % dark-edge pixels (black grass fringe at
   L* 22, door holes, outlines).
10. **One texture scale, low micro-contrast** [M]. Island-top loc 2.6-4.0
    against the game's 3.8-5.2 (even with its blur); gradient energy 10-16
    against 14-26. Plate, props and characters share one brush and one grain,
    because they were painted together.
11. **Glow is atmosphere** [M] (sheet 05). A practical's halo spreads 3-4x
    its body radius, lifts the air around it by ~10 L* and warms it (b* -22 to
    -10); its pool lights the snow and the objects beside it. Few lights,
    small and warm, carry the night.
12. **Characters share the world's light** [M]. Pofu's fur already matches
    (game L* 88, C 17; reference hamster 85, 20). In the references the ground
    around characters is pale and quiet (L* 80-89, low variance), so they read
    by shape and face, sit on a pad and take the same bounce. In the game they
    stand on a dark, busy, saturated lawn.
13. **The whole island in focus** [M]. Only the far sky and the extreme
    foreground blur (postcards); every reference island is crisp end to end.
    Addressed by concept-match (`islandSharpSlab`).

## 3. Diagnosis: the game against each principle

| # | What the pipeline does today (file, parameter) | Effect |
|---|---|---|
| 1, 3 | **Light standard** (`docs/design/light-standard.md`, `design/art/light-standard.json`, enforced for production): day subject p2 <= 22, spread >= 60, haze <= 0.20, "never lifted blacks or a milky veil" | Codex art is pushed away from the references at generation time; the liked plates fail it |
| 1 | `style_lock.json` lock-light: value floor 14, knee 30 | keeps darks down to L* 14 in every sprite |
| 1, 5 | `colour-script.json` day grade: contrast 1.16, saturation 1.32 (golden 1.12 / 1.30); luma-based saturation in `pofuWorldGrade` (`WorldShaders.metal`) | widens the range and saturates highlights and shadows alike, the opposite of 1 and 5 |
| 3 | Vignette 0.12 day to 0.32 night (`shape.w`), darkening | references have no dark corners: the frame edge is sky and cloud, the lightest values |
| 3 | Fog only on the far band (`fog.far` 0.24-0.42); no airlight on the island | layers do not share an envelope |
| 4 | Art painted "neutral", lawn art L* ~62, hue ~130; grade gain neutral by day | greens are cool and dark against a warm key |
| 6, 7 | `ShadowTuning`: day cast-shadow opacity 0.50, softness 0.25, length by sun height; pad 0.38 | crisp directional shadows the references do not have |
| 8 | `LivingSky` sea: day light `#FFFFFF`; night via the night cell (L* 14); nothing lights the island from below | the underside is dark at night and brown by day (earth L* 54-68) |
| 2 | Night cell: black 0.32, gain 0.44/0.50/0.90, saturation 0.72 (concept-match lifts earth to L* ~38; liked nights are 74-85) | night is a value drop |
| 9 | Earth band art: black grass fringe, door holes (`concept-match` §4.4); `style_lock` alpha snap + feather 0.8 | dark lines, sticker edges |
| 10 | Assets from separate jobs, scales and `detail.keep` 0.5 | several textures and grains in one frame |
| 11 | Sprite halos (`HD2DLayer`, `glow-warm-halo`), pools from `LightField`; grade crushes the air around them | glows read as stickers on black |
| 12 | Characters' own grade (`WorldLight.character`); relight spike off (`GraphicsSpike.normalLighting`) | good on Pofu; the ground around him is the problem |
| 13 | `GraphicsSpike.field` slab 34 | fixed by concept-match |

## 4. Technique survey

| Technique | Gives (principles) | Precedent and source | Fit, cost, battery |
|---|---|---|---|
| **Final-first painted states**: paint the island with its assets at the game camera under one light, per light state, then cut layers | all, at once | Ori: lighting painted by hand, "scripts look cheap and plasticky", 30,000 hand-painted light maps [S] thegamer; Monument Valley: "apply colour directly instead of a true lighting system" [S] creativebloq | Highest fit: our references *are* such paintings. Cost: art batches and a cut tool (`integrate.py`). Runtime: textures only |
| **AI harmonise pass**: render our frame, have the image model repaint it in the reference look with the layout locked, bake as plate | 1-12 for existing art | Intrinsic Harmonization (Careaga, Miangoleh, Aksoy, SIGGRAPH Asia 2023) [S]; IC-Light background-conditioned relighting (ICLR 2025) [S] | Codex edit with the frame as input and a reference as style; risk: shape drift, so gate on layout IoU. Offline only |
| **3D LUT grade per cell**, fitted to reference statistics | 1, 2, 4, 5 | Don't Starve colour cubes [S] (night doc); Reinhard Lab transfer (2001) [S]; Pitié OT grading (2007) [S] | One texture sample in the existing grade shader; two LUTs lerped by hour. Fit on region statistics (content differs) |
| **Chroma by luminance + hue pull to key** | 4, 5 | painterly practice [K] | Part of the LUT; no extra cost |
| **Airlight by depth** (mix toward the sky's horizon colour, constant floor plus depth term; shadows mix more) | 1, 3 | Firewatch fog and grade (sky doc) [S]; Days Gone screen-space shadows as depth-buffer reuse [S] bendstudio | Reuses the depth map the DoF already samples |
| **Hemisphere light: sky above, cloud sea below** | 6, 8 | Sky: environment light from a dynamic cube map around the player (GDC 2026, via recap) [S, weak]; night doc §B5 | Baked into plates per state; at runtime a vertical gradient mask on the island and a bounce term on characters |
| **AO and contact pads** from depth (AI or banded), and from layer stacking | 7 | Bend contact shadows [S]; SSAO family [K] | Offline bake into plate and pads; zero runtime. Being prototyped in `wt-lab` |
| **Soft day shadows** (short, soft, warm) | 6, 7 | references [M] | `ShadowTuning` numbers |
| **Edge clean-up and light wrap** (lift dark fringes toward local colour; 1-2 px of the air colour on silhouette edges) | 9, 3 | compositing practice [K]; A Short Hike's soft outline unifies sprites (sky doc) [S] | Offline in `style_lock`/`integrate`; light wrap as a baked rim mask tinted at runtime |
| **Detail and grain unification** (guided filter to a loc target per kind) | 10 | `style_lock` detail budget exists | Tune per kind to loc 2.6-4.0 at display scale |
| **Practical glow as atmosphere** (halo 3-4x, air lift, pool on objects) | 11, 2 | Spirited Away lanterns, Ori light sources (sky doc) [K]; Eastward pools [S weak] | Halo sprites and pools exist; resize and stop the grade crushing them |
| **Dual-filter bloom / halation** | 11, 5 | Bjørge, Bandwidth-efficient rendering (ARM, SIGGRAPH 2015) [S] | Needs offscreen passes; SwiftUI layer effects make multi-pass awkward. Bake highlights' bloom into plates; runtime only on practicals |
| **Per-sprite normals + 2.5D relight** (alpha-dome, AI normals: Marigold [S], depth from Depth Anything V2 [S]) | 6, 11, 12 at night | Sea of Stars, Octopath (night doc); Cult of the Lamb, 2D sprites in a 3D scene with a custom lighting solution [S] Unity | Spike exists, off. Real value only for practicals on characters at night; plastic risk by day |
| **HD-2D** (sprites in a lit 3D scene, point lights, DoF, bloom) | 6, 11 | Octopath, UE4 [S] | Wrong look (crisp, contrasty) and heavy; reject |
| **Palette quantisation** | none measured | references use 2-6 hue sectors, like the game [M] | Reject: palette size is not the gap; risks banding |
| **MetalFX** (upscaling; frame interpolation in Metal 4, A14+) [S] WWDC25 | none | | Not a look tool; our frames are cached at 0 Hz when settled. Tile shading only matters if we leave SwiftUI layer effects |

No primary pipeline sources were found for Hollow Knight, Alba, Unpacking,
Spiritfarer, Cozy Grove or Cats & Soup; they are not cited.

## 5. Ranking (impact on matching the references, cost, battery, fit)

| Rank | Technique | Expected impact | Cost | Battery |
|---|---|---|---|---|
| 0 | **Rewrite the light standard to the reference envelope** (an ADR superseding the "no lifted blacks" rule; new targets §6.4; style_lock floor 14 -> ~45 for world art by day) | Unblocks everything; without it every new batch drifts back | 1 day | none |
| 1 | **Final-first painted states, cut into layers** (concept-match §6 route, extended to all states), with the **AI harmonise pass** as the bridge for existing art | Very high: principles 1-12 come from the paint | High: art per island and state, a `cut` source in `integrate.py` | lowest (images) |
| 2 | **Reference-fitted LUT per cell** with chroma-by-L and hue pull; day contrast and saturation back to ~1.0; vignette off or light | High (1, 2, 4, 5), immediate on current art | Low | ~0 (replaces maths) |
| 3 | **Air and bounce**: airlight by depth, cloud-sea underfill, sea light per cell (night sea L* >= 70) | High on cohesion (3, 8) | Low-medium | low (one depth sample) |
| 4 | **Night re-key as a hue change** to the liked nights' numbers, practicals at 3-4x halos lighting objects; a painted night state per island | Very high at night (2, 11) | Low (cells) to medium (paint) | low |
| 5 | **Seat pass**: soft day shadows, warm pads, AO bake, dark-fringe clean-up, light wrap, grain unification | Medium-high on the "sticker" look (6, 7, 9, 10) | Medium (offline) | none |
| later | Normals + relight for characters by practicals at night; dual-filter bloom | Medium | Medium-high | medium |

## 6. Look pipeline v2

### 6.1 Painted (Codex)
- **One master per island per light state**, final-first, at the game's
  camera (Home portrait and the whole-island pose), island and assets in one
  picture, characters' slots marked: **day** first; **golden, night, rain** as
  edits of the day master (edit-from-parent, same seed); dawn and dusk only
  if the crossfade fails. Wellbeing stages are edits of the same master.
- Prompt block "reference look" replaces the light block: soft diffuse
  pastel light, lifted shadows in the key's hue, no dark outlines, plush
  felt and clay surfaces, warm peach bounce from the cloud sea below, the
  whole island in focus; night: indigo sky, moonlit lavender island, cream
  practicals. A reference image (I1 of the state) rides with every job.
- **Characters stay sprites** (they animate), painted under the day cell in
  the reference envelope (their L* already matches), lit at runtime.

### 6.2 Baked offline (`tools/assets`, Python)
- **Cut**: A (bare plate) / B (A plus assets) difference matte, chroma-key
  take for alpha, bands from `generatedPlate` (concept-match §6.3); harmony
  correction zero for cut layers.
- **Harmonise pass** for anything not painted together (a new prop added
  later): composite, AI-edit to the master's look, re-cut; accept only if
  layout IoU >= 0.95 and §6.4 holds.
- Per state: depth (banded from layout, or AI depth for the plate), AO and
  pads, sea-bounce mask, light-wrap rim masks, emissive masks; a **LUT per
  cell** fitted from the painted master against the runtime render.
- Edge clean-up and grain to the loc target; the plate's highlight bloom
  painted in.

### 6.3 Runtime (SwiftUI + Metal, cached to 0 Hz when settled)
- **Time**: crossfade the two nearest painted states (two plate textures),
  lerp their LUTs; the sky keyed as today.
- **Weather**: rain streaks, mist cards, wet sheen as overlays over the rain
  state; overcast = rain state at low strength; no darkening grade.
- **Air**: one pass with the depth map: airlight (constant floor plus depth),
  far blur only.
- **Light that moves**: practicals (flicker, halo, pools on objects),
  characters' key, fill, sea bounce, rim and pad from `LightField`; relight
  with normals only where a lamp touches a character at night.
- **Grade** last and small: the LUT; no contrast push, no darkening vignette.

### 6.4 Verify: the reference envelope as metrics
Extend `tools/assets/concept_match.py` (CI on every screenshots branch) with
these targets, measured on the frame and the island-top region:

| Metric | Day | Golden | Rain, mist | Night |
|---|---|---|---|---|
| Frame L* p2 / p50 / p98 | >= 50 / 78-90 / 92-97 | >= 50 / 72-80 / 88-93 | >= 50 / 75-82 / 92-96 | sky 25-36; island p50 70-80 |
| Pixels below L* 40 (30 at night) | 0 % | 0 % | 0 % | <= 8 %, sky only |
| Mean chroma | 13-25 | 25-32 | 13-17 | 19-22 |
| Island-top loc | 2.6-4.0 | 2.6-3.5 | 2.6-3.5 | 1.7-2.4 |
| Dark-edge pixels | <= 3 % | <= 3 % | <= 3 % | <= 3 % |
| Earth face / cloud sea L* | 74-84 / 82-92 | 70-80 / 80-86 | 75-84 / 85-90 | 70-80 / >= 70 |
| Greens L*, hue | 66-84, 88-118 | 66-76, 85-100 | 66-75, 100-118 | lavender-teal |
| Darks a*, b* | warm, C >= 25 | warm | warm-lilac | violet: a* +10..+22, b* -25..-40 |

Every look change ships with the side-by-side sheet (reference, game before,
game after) and these numbers; the founder sees the sheet, never a prototype.

## 7. Prototypes wanted from the look lab (`wt-lab`), and decisions

Prove offline, on the Home clear, golden, rain and 22:30 frames, scored by §6.4:
1. **LUT fit** (region statistics, not pixels) with chroma-by-L and hue pull:
   can the current art reach the day envelope without mud?
2. **Airlight + sea underfill** from the depth map, alone and with 1.
3. **Night re-key**: the current night cell versus a cell fitted to gezgin
   f2 night (p50 >= 70, loc <= 2.2, C ~21).
4. **AI harmonise pass** on the current Home frame (layout locked): layout
   IoU and the §6.4 distance to I1 summer.
5. **Cut** from an A/B pair (one island, day): clean alpha, pads kept.

Decisions for the lead: (a) an ADR that replaces the light standard's value
rules with §6.4 (the 2026-11-03 standard and ADR-0018's reading "never lifted
blacks" are the opposite of what the founder now asks for); (b) Q-10 reframed
with the numbers: the liked nights are light with only the sky dark, and the
"too contrasty" one is the darkest and most saturated; (c) final-first states
as the production route (pilot: Home day + night, then Çağlayan).

## Sources

- Ori: hand-painted light maps — https://www.thegamer.com/ori-and-the-will-of-the-wisps-artists-hand-painted-30000-light-maps/
- Monument Valley, colour applied directly — https://www.creativebloq.com/computer-arts/making-monument-valley-71412213
- Octopath HD-2D — https://www.unrealengine.com/en-US/spotlights/octopath-traveler-s-hd-2d-art-style-and-story-make-for-a-jrpg-dream-come-true ; https://en.wikipedia.org/wiki/HD-2D
- Cult of the Lamb, 2.5D and custom lighting — https://unity.com/blog/games/recipe-behind-smash-hit-cult-of-the-lamb
- Sky, dynamic environment lighting (GDC 2026; secondary summary) — https://gamedev.net/news/994-dynamic-environment-lighting-in-sky-children-of-the-light-gdcrewind-gdc2026/
- Bend Studio, screen-space shadows — https://www.bendstudio.com/blog/inside-bend-screen-space-shadows/
- Bjørge, Bandwidth-efficient rendering (dual filter) — https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_slides.pdf
- Reinhard et al., Color transfer between images (2001) — https://users.cs.northwestern.edu/~bgooch/PDFs/ColorTransfer.pdf
- Pitié, Advances in colour transfer (2020 review) — https://mural.maynoothuniversity.ie/15125/
- Careaga et al., Intrinsic Harmonization (SIGGRAPH Asia 2023) — https://arxiv.org/abs/2312.03698
- Zhang et al., IC-Light — https://github.com/lllyasviel/IC-Light
- Depth Anything V2 — https://arxiv.org/abs/2406.09414 ; Marigold normals — https://huggingface.co/prs-eth/marigold-normals-v0-1
- Metal 4 / MetalFX frame interpolation, WWDC25 session 211 — https://developer.apple.com/videos/play/wwdc2025/211/
