# Art Direction Study: Keeping Pofu's World Hand-Made

_Status: v1, 2026-11-01. Inputs: art test 01
([`design/art/tests/2026-11-01/`](../../design/art/tests/2026-11-01/README.md)),
R1, the [art bible](art-bible.md). Visual proof:
[`design/prototypes/art-study/`](../../design/prototypes/art-study/index.html)
(phone-friendly, Turkish captions). Tools:
[`tools/imagegen/style_lock.py`](../../tools/imagegen/style_lock.py)._

## The answer

1. **Do not change the style; simplify the world, not Pofu.** R1's soft
   painterly look is the anchor and it works. What reads as "AI" in art
   test 01 is the props: darker, far more saturated, glossy, and covered in
   micro-texture that R1 does not have. Props and plates move toward R1;
   R1 does not move.
2. **Fix it at the source first.** New prompt blocks (prop style v2, view
   v2, edit-keep v1, below) ask for matte, chunky, high-key props seen from
   the island's low camera. Post-processing is the last 20 %, not a rescue.
3. **Lock the rest with a measured, light post-process: the soft lock.**
   Values lifted to R1's key, chroma rolled off into the locked palette's
   range, half of the fine detail removed, one warm light direction, a
   softened cut edge. Pofu and residents are not locked.
4. **Do not go flat by filter.** Gouache (B) and storybook (C) treatments
   were built and judged: they look like filters and kill Pofu's charm. If
   a flatter style is ever wanted, it is a re-draw at the source, a
   different project.

## 1. What art test 01 actually shows (measured)

Measured on the opaque pixels of each image (CIELAB). "Detail" is the
mean absolute Laplacian of luminance (×100) after the object is scaled
to 390 px, about its size on the phone: fine texture as the eye sees it.

| Asset | Lightness p5 (dark end) | Lightness p50 | Chroma p50 | Chroma p95 | Detail |
|---|---|---|---|---|---|
| **R1, Pofu (the target)** | **59** | **89** | **12** | **51** | **5.3** |
| Island take 1 (founder's pick) | 52 | 80 | 46 | 52 | 5.6 |
| Island take 2 | 46 | 76 | 57 | 69 | 9.7 (at 390 px of the island) |
| Çay ocağı L1 take 1 | **27** | 56 | **61** | **82** | 7.3 |
| Çay ocağı L2 take 1 | 30 | 61 | 58 | 78 | 7.8 |
| Locked palette, most saturated swatch | | | | 49 | |

The founder's eye was right twice. Take 1 of the island is measurably
closer to R1 than take 2 (lighter, 20 % less chroma, half the detail).
The tea stall is the outlier: its darkest tones are as dark as R1's eye
ink, its median chroma is five times R1's, and it carries 40 % more fine
texture. That is the "mobile game render" the founder saw.

Two more findings from replaying the test through the new pipeline
([contact sheet](assets/art-pipeline-replay-contact.jpg)):

- **The L2 edit did not keep the stall in place.** Visually "unchanged",
  but GPT Image zoomed out by 15 % to fit the awning and shifted the
  stall. In the app the counter would visibly shrink between levels.
  Per-pixel stability was 39 %; after automatic alignment to L1 it is
  98 %. The pipeline now aligns every edit to its parent, and the
  prompts reserve headroom in L1 and forbid reframing (edit-keep v1).
- **Neither cay take respects the height bar** once aligned (the awning
  reaches y = 30 on a 1024 canvas; the guide allows 150).

## 2. Why generated art reads as "AI"

A synthesis of practitioner write-ups and critics (sources at the end)
and our own measurements. None of these are glitches; they are defaults
the model falls back on when the prompt does not forbid them.

1. **Uniform detail density.** Every surface is rendered to the same
   high level, so the eye never settles; human illustrators spend detail
   only where they want attention.
2. **Material over-rendering.** Hammered copper, wood grain, specular
   glints, "injection-molded" smoothness: materials are rendered
   physically rather than designed.
3. **Contrast and saturation pushed to pop.** Deep darks and saturated
   mid-tones, regardless of the intended key.
4. **Sourceless or inconsistent light** between assets made separately.
5. **Camera and scale drift** between assets of one world (our props sit
   on a higher camera than the island).
6. **Texture that does not survive display size.** Detail at 1254 px
   becomes noise or shimmer at 130 pt.
7. **Over-smoothing and merged forms** at the other extreme: everything
   soft, nothing designed.

## 3. How cozy games keep a coherent, hand-made feel

| Reference | What it does (source or observation) | Lever for Pofu |
|---|---|---|
| A Short Hike | Rendered at low resolution: flat, cohesive shading, no anti-aliasing, a soft outline for readability; assets need little detail to read (developer post-mortem) | Design for display size; detail budget measured at 390 px |
| Alba: a Wildlife Adventure | Solid colors, getting the most from gradients and decals (ustwo environment write-up) | Broad value changes, no micro-texture |
| Monument Valley | Deliberately limited palettes and textures, one theme color per level | A locked props palette; chroma ceiling |
| Dorfromantik | "Very basic shapes, carefully composed", minimal yet warm | Fewer, larger shapes per prop |
| Ghibli backgrounds (gouache) | Value structure established across the whole painting first; limited palette; soft washes | High, shared value key; one light |
| Cats & Soup | Soft, Ghibli-esque painterly characters; calm animation carries the mood (reviews) | Keep R1 painterly; let motion do the rest |
| Neko Atsume, Finch, Unpacking, Pocket Camp | _Observation:_ simple silhouettes, near-flat color, charm from pose and expression rather than rendering; one consistent camera per world | Charm is in Pofu's face and motion, not in prop rendering |

The common thread: **a small number of decisions applied everywhere**
(one palette, one light, one camera, one detail budget) beats any single
beautiful asset.

## 4. The levers, decided for Pofu

| Lever | Decision |
|---|---|
| Shape simplification | Props: chunky, rounded, few parts ("fewer, larger shapes"). Pofu unchanged. |
| Detail density budget | Measured at display size: R1 is 5.3; props and plates ≤ 6.0 (warn), ≤ 7.5 (fail). Soft lock keeps 50 % of fine detail. |
| Value structure | High key like R1: props' dark end at or above L 35 (fail below 25); the darkest accent is warm mid-brown, never near black. |
| Limited palette | Character and world-day palettes plus a new **world-props** palette ([`tools/imagegen/palettes.json`](../../tools/imagegen/palettes.json), card in `design/reference/`). Drift measured on every take. |
| Consistent light | One warm key from the upper left (art bible §4), reinforced by the lock's ±4 L gradient over each object's box. |
| Camera | The island's: about 20° above the horizon (ground ellipses 0.3 tall : wide). View block v2 attaches the approved island as the camera reference. |
| Edge quality | Props come back razor-cut; R1's edge is soft fur. The lock feathers the cut edge inward by 0.8 px (at 1024). No outlines. |
| Texture and grain | **No baked grain** (art bible §5 stands: grain shimmers in animation and compresses badly). If a shared paper feel is wanted, test a screen-space overlay at ≤ 3 % in the app, once, for everything. |
| Hyper-specular materials | Banned in the prompt ("at most one small, soft highlight per object") and halved by the lock's detail split. |
| Intentional imperfection | Comes from Pofu's motion and the human selection, not from fake brush noise. |
| Human curation and paintover | Every master is picked by the founder on a contact sheet; the lock, registration and alignment are documented in each master's provenance. Paint-over stays allowed and must be recorded. |

## 5. The three treatments (and the recommendation)

All four are presets in [`style_lock.json`](../../tools/imagegen/style_lock.json)
and run on the same sources; the page shows the full scene, every asset,
and close-ups.

| | A · Harmonize | B · Gouache simplification | C · Storybook flat | **Recommended: soft lock** |
|---|---|---|---|---|
| What it does | Value lift, chroma clamp, warm grade, fine grain, soft edge | Edge-preserving smoothing, Kuwahara patches, 6 soft value steps, brush grain | Smoothing, 9 flat colors (k-means in CIELAB), soft colored outline | A's grade and clamps, half of the fine detail removed, no grain, no steps, no outline |
| Applied to | Everything | Everything | Everything | Props and plates; Pofu untouched |
| Keeps Pofu's charm | Yes | No: fur turns to felt | No: eyes lose their catchlights | Yes (Pofu is the reference) |
| Hides generator fingerprints | Partly: hammered copper and grain remain | Replaces them with filter artifacts (blotchy bands) | Yes, but looks like a vector filter | Mostly: texture halved, glints calmed, palette and key unified |
| World coherence | Good color, mixed texture | Coherent, muddy | Most coherent, different game | Good |
| Cost / risk | Low | Medium; looks processed | High; a re-draw would be needed to do it properly | Low; reversible (raw kept) |

Metrics after each treatment are in `design/prototypes/art-study/assets/metrics.json`.
For the tea stall L1: chroma p95 82 → 46, dark end 27 → 42, detail
7.3 → 4.6 under the soft lock; for the island: lawn chroma p95 52 → 37
(palette meadow is 38).

### Should the style be simplified?

Yes for props and the world, at the source: simpler, chunkier, matte,
high-key. No for Pofu: his painterly fur and eyes are the brand, and the
study shows every filter that simplifies him makes him worse. A future
flat style is not ruled out, but it would be a different art direction
drawn from scratch, not a post-process.

## 6. Style-lock parameters (recommendation, v1)

Preset `soft-lock` in [`tools/imagegen/style_lock.json`](../../tools/imagegen/style_lock.json).
Pixel values are for a 1024 px canvas and scale with the image.

| Step | Parameter | Value | Why |
|---|---|---|---|
| Alpha snap | `alpha_snap` | 0.97 | Quantized GPT Image PNGs top out at alpha 250–254 inside the object |
| Detail split | guided filter `radius` / `eps` / `keep` | 4 px / 0.004 / 0.5 | Keeps silhouettes and material borders; halves micro-texture and glints |
| Values | `floor` / `gamma` / `contrast` / `pivot` | 12 / 0.95 / 0.9 / 70 | Lifts the dark end toward R1's key without washing out |
| Highlights | `highlight_knee` / `highlight_ceiling` | 93 / 98 | No paper-white glare |
| Chroma | `scale` / `knee` / `ceiling` | 0.7 / 40 / 60 | Rational roll-off keeps color modulation; lands in the palette's range |
| Greens (hue 135 ± 40) | `knee` / `ceiling` | 24 / 36 | Soft sage lawn (palette meadow C 38) |
| Reds (hue 38 ± 22) | `knee` / `ceiling` / `hue_shift` | 34 / 50 / +10° | Tea red reads as honey amber, not salmon pink |
| Light | `amount` / `warmth` | 4 L / 1.0 | One warm key from the upper left across the object |
| Edge | `feather_px` | 0.8 | Softens the cut inward; nothing grows outside |
| Grain, posterize, outline | | off | See section 4 |

Characters use `char-guard` (alpha snap and a high chroma guard only):
on R1 it changes nothing measurable. Change a parameter only with a
before/after contact sheet in the PR.

## 7. Prompt-level fixes (at the source)

All blocks live in [`tools/imagegen/blocks/`](../../tools/imagegen/blocks/)
and are pasted verbatim by the pipeline.

**Prop style block v2** (replaces the v1 prop block for props, stations,
plates and UI objects):

```text
STYLE: soft painterly 2D illustration from the same picture book as the
attached hamster: the same gentle airbrushed shading, the same light,
high-key values and the same milky pastel colors. Simple, rounded, chunky
shapes with few parts; fewer, larger shapes, because this is seen small on
a phone. Every material is painted matte, as a soft form with broad,
smooth value changes: wood without grain, metal without hammering or
reflections, glass as a soft tinted shape, cloth without weave. At most
one small, soft highlight per object; no glints, no shine. Colors are
muted and lifted toward cream; the darkest shadow is a warm mid-brown,
never near black. Warm diffused key light from the upper left, a faint
warm rim light along the right edge, soft ambient shadow only where forms
touch. Clean, calm, uncluttered. No outlines, no hard edges. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.
```

**View block v2** (stations; the approved island is attached as the
camera reference):

```text
VIEW: the same fixed front three-quarter view as the attached island: a
low camera about 20 degrees above the horizon, so you see the front of
the object fully and only a narrow sliver of its top (a round tabletop
reads as a flat oval about a third as tall as it is wide). Follow the
attached guide exactly: the object stands on the magenta ground ellipse,
centered on the magenta cross, its front edge on the front of the
ellipse, no taller than the magenta height bar. Then remove the guide
completely: no ellipse, no cross, no bar, no magenta, no grid may remain
in the output.
```

**Edit-keep block v1** (every level edit) and the **prop avoid list v2**
are in the same folder. Other fixes in the batch-01 manifest: the island
is an edit of the founder's take 1 (flatter, earth no deeper than 30 % of
the width, sage lawn without blades); L1 stations fill only the lower
half of the height bar so later levels fit without reframing.

## 8. QA thresholds (derived from R1)

Run on the locked take by [`tools/imagegen/qa.py`](../../tools/imagegen/qa.py):
chroma p95 (warn 52, fail 60), value floor (warn below 35, fail below
25), detail at display size (warn 6.0, fail 7.5), **lock load** (the
mean ΔE the lock had to move the take: warn 10, fail 18; the founder's
island take 1 scores 14.6, take 2 21.4, the cay takes about 21), palette
drift, guide-magenta remnants, the station anchor, island depth ratio
(target ≤ 0.30; take 1 is 0.38), lawn chroma, edit alignment and
stability, and for UI art: icon fill, thin parts at 24 pt, detail at
24 pt, separation on light and dark glass, app icon opacity and calm
corners. Lock load is the key "not too AI" signal: a take that needs a
heavy lock drifted at the source, so prefer the take that needs less.

## 9. Inconsistencies found in the game design spec (for the lead)

`docs/product/game-design.md` §15 is out of scope for this change; two
items need a fix there:

1. "Camera about 25° above the horizon; ground ellipses have a 0.3
   height-to-width ratio." A 0.3 ellipse is a camera at about 17.5°
   (sin⁻¹ 0.3). The guide and the island use 0.3; the prompts now say
   "about 20 degrees". Suggest "about 20° (ellipse ratio 0.3)".
2. "The lowest opaque row sits within ±12 px of y = 800." The anchor is
   the center of the footprint ellipse; an object standing on it has its
   lowest pixels on the ellipse's front half (y 800–908). QA checks that
   band and registers chain roots to a ground line of y = 900.

## 10. Self-critique

- The study post-processes four images; it is evidence for direction,
  not a guarantee. The real test is batch 01 generated with the new
  blocks: if the lock load stays above 10 on most takes, the prompts
  need another pass before any bulk generation.
- The thresholds are calibrated on one hero and a handful of takes.
  Expect to retune them after the first batch; every change goes through
  a PR with a contact sheet.
- "Detail at display size" is a proxy (Laplacian energy), not perception.
  It ranks the takes the way the founder did, which is the bar for now.
- The soft lock still leaves visible hammering on copper at 100 % zoom.
  That is acceptable at 130 pt and is exactly why the prompt must ask for
  matte metal.
- The target-island panel on the page is a deformation mock (the door
  gets squashed). It shows proportions only.
- Research access was limited: several primary pages (ustwo, PlayStation
  Blog, Gurney Journey, OpenAI developer docs) could not be fetched from
  this environment; their claims here come from search summaries and are
  marked as such where it matters.

## Sources

- Keith Kisser, [Why does all AI art look like that?](https://medium.com/@keithkisser/why-does-all-ai-art-look-like-that-f74e2a9e1c87)
- OpenArt, [Visual clichés that scream "made by AI"](https://openart.ai/blog/visual-cliches-that-scream-made-by-ai/)
- Rewarx, [Why AI product images look plastic](https://www.rewarx.com/blogs/why-ai-product-images-look-plastic)
- PlayStation Blog, [Crafting a tiny open world: A Short Hike](https://blog.playstation.com/2021/08/05/crafting-a-tiny-open-world-a-look-behind-the-scenes-at-the-creation-of-a-short-hike/)
- ustwo games, [The environment art of Alba](https://ustwogames.co.uk/news/the-environment-art-of-alba-a-wildlife-adventure/)
- 80.lv, [How Dorfromantik expands its cozy world through minimalist design](https://80.lv/articles/how-dorfromantik-expands-its-cozy-world-through-minimalist-design)
- Game Developer, [Crafting the striking art style of Monument Valley](https://gamedeveloper.com/production/video-crafting-the-striking-art-style-of-i-monument-valley-i-)
- Open Culture, [Inside the painting process of Studio Ghibli artist Kazuo Oga](https://www.openculture.com/2021/01/a-look-inside-the-painting-process-of-the-studio-ghibli-artist-kazuo-oga.html)
- Gurney Journey, [Painting in Ghibli style](https://gurneyjourney.blogspot.com/2018/05/painting-in-ghibli-style.html)
- POPSUGAR and Mechanics of Magic on [Cats & Soup](https://mechanicsofmagic.com/2024/04/06/mda-cats-and-soup/)
- He, Sun, Tang, "Guided Image Filtering" (2010), the edge-preserving filter used by the lock.
