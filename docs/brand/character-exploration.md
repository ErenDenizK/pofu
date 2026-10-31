# Character Exploration: Species and Rendering Style

_Status: **decided**: illustrated hamster ([ADR-0010](../adr/0010-illustrated-hamster-art-direction.md)). Last updated: 2026-10-31._

## Why we are revisiting the character

Founder feedback on the v0.1 rig ([snapshot](assets/pofu-states-v0.1.png)):

1. **No species identity.** Pofu reads as "a fluffy thing", neither a cloud
   nor a creature. It is cute but does not feel alive. An animal-like
   character (the founder mentioned a cat or a mouse) would create more
   attachment.
2. **Code-drawn faces look simple.** Eyes, mouth, and cheeks lack the
   craft of professional illustration.
3. **The lilac color was a surprise.** The founder expected a white fluffy
   character. Lilac was pleasant, but it is not what "pofuduk" evokes.
4. **The app's overall UI feel matters more than the character alone.** The
   character must serve a coherent design language.

Director's critique of our own work: the feedback is correct. The v0.1 rig
solved geometry (silhouette, states, motion) but not character design. A
mascot people love has a recognizable species, a signature trait tied to the
product's story, and a drawing quality beyond a blob with a face. The
code-native approach is not the root cause; the art direction was too thin.
We fix both: first species, then rendering style.

## Part 1: Species

Each candidate is judged on how well its natural traits map onto the
product's mechanics, not only on cuteness.

| Candidate | Story fit | Signature trait | Risks |
|---|---|---|---|
| **Hamster** | The **hamster wheel** is the doomscroll: running endlessly and going nowhere. Pofu steps off the wheel when you live. | **Cheek pouches store energy**: Pofu's cheeks visibly puff up as you earn. | Hamtaro-style comparisons (manageable with a distinct design). |
| **Bunny** | "Down the rabbit hole" is the English idiom for losing an hour to a feed. | **Ears as mood antenna**: up when thriving, flopped when wilting. | Very crowded mascot space (Molang, Miffy). The idiom is weaker in Turkish. |
| **Kitten** | Istanbul's street cats give it cultural warmth; cats are the internet's animal. | Tail and ears for expression. | Pusheen-style round grey cats are a strong existing association. Weak link to the mechanics. |
| **Original creature** | A chinchilla and dandelion-puff hybrid: fully ownable IP. | Fluff that scatters like dandelion seeds when wilting. | The founder already noted that a non-animal lacks warmth; a hybrid can drift back into "fluffy thing". |
| ~~Lamb~~ | "Pofuduk kuzu" is natural Turkish, and the wool maps well onto fluff. | Wool. | **Rejected.** In Türkiye a lamb carries a strong Kurban (sacrifice) association, and a "wilting lamb" state would read darkly. |

### Recommendation: the hamster

The hamster is the only candidate where **both** core mechanics have a
natural visual:

- **Doomscrolling is the wheel.** The wilting state shows Pofu exhausted on a
  spinning wheel; resisting an impulse shows Pofu hopping off. The metaphor
  works in both languages ("hamster gibi çarkta dönmek" and "hamster wheel").
- **Earning energy fills the cheeks.** Hamsters stuff their cheek pouches; Pofu
  stores energy the same way. When you earn, the cheeks puff up; when you
  spend, they deflate. This is the economy made visible and funny.
- A round, fluffy body matches "pofuduk" and keeps the v0.1 silhouette work.
- Creamy white fur with warm golden-peach patches matches the founder's
  intuition of a white, fluffy Pofu. Lilac can remain an accent color of the
  app's UI rather than the character's body.

## Part 2: Rendering style and pipeline

Three radically different pipelines, all able to animate.

| | A. Upgraded vector rig | B. Illustrated 2D puppet | C. 3D plush (Blender) |
|---|---|---|---|
| How | Parametric shapes in SwiftUI with a far stronger art direction: deliberate shape language, flat shading with one shadow tone, hand-tuned eye and mouth shapes per state. Duolingo proves vector characters can be world-class. | Master art produced with AI image tools from a fixed character sheet, split into layers (body, eyes, mouth, cheeks, ears, tuft) and animated in code with transforms, layer swaps, and springs. | A procedurally built 3D model with fur, rendered in Blender, shipped as pre-rendered loops or layered stills. |
| Quality ceiling | Medium-high; depends on shape design skill | High (illustration grade) | Very high (designer-toy, premium) |
| Animation freedom | Total | Medium (puppet-style) | Low in real time; high in pre-rendered loops |
| Consistency | Perfect | The hard part: AI drifts between generations | Perfect (same model) |
| App size | Tiny | Medium | Large if pre-rendered |
| Who can iterate | The agent, fully | The founder (image generation) and the agent (rigging) | The agent, via Blender scripts |
| Ownership | Full | Weak for purely AI-generated art | Full |

Work in progress:

- **C** is being tested now: a procedural Blender feasibility spike rendering a
  plush hamster Pofu.
- **B** needs concept art. The founder will generate it with the prompts below.
- **A** gets reworked once the species is fixed.

The decision will be recorded as a new ADR that either confirms or supersedes
[ADR-0006](../adr/0006-code-native-companion-rendering.md).

## Part 3: Prompts for AI concept generation

To be run by the founder in ChatGPT (GPT Image) or Gemini (Nano Banana).
English prompts produce more reliable results.

### Step 1: species lineup (one image, same style for a fair comparison)

```
A character design lineup of four candidate mascots for a mobile app, all
named "Pofu", shown side by side on a plain soft pastel background, same
art style and same size for a fair comparison:
1) a chubby baby hamster with creamy white fur and warm golden-peach patches,
   cheeks slightly puffed;
2) a round baby bunny with short floppy ears, white fur;
3) a round fluffy kitten like a little Istanbul street kitten, cream with
   soft ginger stripes;
4) an original fluffy creature, a cross between a chinchilla and a dandelion
   puff, white with a faint lilac tint, small rounded ears and a tiny tail.
Every mascot has: an almost spherical, extremely fluffy body; a single
curled tuft of fur on top of the head as a signature feature; big glossy
dark eyes set low and wide; soft pink blush cheeks; tiny feet peeking out.
Style: soft, high-quality 2D illustration with gentle shading and visible
fluffy fur texture, warm and premium, the polish of a top-tier app mascot.
No text, no labels, no logos.
```

### Step 2: the chosen species in three styles (three separate images)

Replace `[SPECIES]` with the chosen description from step 1.

**Style A: flat vector**

```
Character sheet of an original mobile app mascot named Pofu: [SPECIES].
Almost spherical, extremely fluffy body, a single curled tuft of fur on top
of the head, big glossy dark eyes set low and wide, soft blush cheeks, tiny
feet. Show four expressions in a 2x2 grid: thriving and happy; curious and
leaning in as if saying "Hop!"; tired and sad with flat, matted, duller fur
(sad but cute, never sick); asleep. Style: clean flat vector illustration,
bold simple shapes, limited palette, one subtle shadow tone, crisp and
geometric, the polish level of leading mobile app mascots. Plain white
background. Consistent proportions across all four. No text.
```

**Style B: soft illustrated 2D**

```
Character sheet of an original mobile app mascot named Pofu: [SPECIES].
Almost spherical, extremely fluffy body, a single curled tuft of fur on top
of the head, big glossy dark eyes set low and wide, soft blush cheeks, tiny
feet. Show four expressions in a 2x2 grid: thriving and happy; curious and
leaning in as if saying "Hop!"; tired and sad with flat, matted, duller fur
(sad but cute, never sick); asleep. Style: soft painterly 2D illustration,
gentle gradients, visible fluffy fur texture, warm storybook feel, premium
quality. Plain soft pastel background. Consistent proportions across all
four. No text.
```

**Style C: 3D designer plush**

```
Character sheet of an original mobile app mascot named Pofu: [SPECIES].
Almost spherical, extremely fluffy body, a single curled tuft of fur on top
of the head, big glossy dark eyes set low and wide, soft blush cheeks, tiny
feet. Show four expressions in a 2x2 grid: thriving and happy; curious and
leaning in as if saying "Hop!"; tired and sad with flat, matted, duller fur
(sad but cute, never sick); asleep. Style: 3D render of a premium designer
plush toy, soft fuzzy fabric and fur texture, gentle studio lighting, pastel
background, high-end animated film quality. Consistent proportions across
all four. No text.
```

## Decision process

1. The founder generates the step 1 lineup and states a gut preference.
   Unless the images change our minds, the recommendation is the hamster.
2. The founder generates step 2 for the chosen species.
3. The agent compares B against the Blender spike (C) and a reworked vector
   rig (A) side by side, judging quality, animatability, consistency, and
   cost.
4. The result is recorded in an ADR. The character bible is updated to v0.2
   with the species and style.

## Outcome

- Step 1 lineup generated by the founder with GPT Image:
  [species-lineup-gpt-image.jpg](assets/concepts/species-lineup-gpt-image.jpg).
  All four were well received. The hamster leads, and the white bunny was a
  close favorite, so it is a candidate for the first collectible friend.
- The 3D Blender spike (PR #6) reached designer-toy quality but is parked as
  a reference because of its iteration cost and limited real-time motion.
- Decision recorded in [ADR-0010](../adr/0010-illustrated-hamster-art-direction.md).
