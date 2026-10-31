# Pofu Art Bible: Governing AI-Generated Imagery

_Status: v1.0. Last updated: 2026-10-31._
_Read with the [design language](design-language.md) (where art is
allowed) and the [prompt library](prompt-library.md) (what to make)._

Pofu's illustrations are generated with GPT Image in ChatGPT and curated by
a human. Generated art drifts: eyes change shape, colors warm up, a paw
grows a sixth toe, a sticker border appears. This bible is the contract
that keeps a hundred generations looking like one artist made them. If an
image breaks a rule here, it does not ship, however charming it is.

## 1. The reference set

Every prompt starts from references, never from words alone.

| ID | File | What it is | Status |
|---|---|---|---|
| **R0** | [`docs/brand/assets/concepts/hamster-gpt-image.png`](../brand/assets/concepts/hamster-gpt-image.png) | The founder's approved concept crop (532 × 739, opaque) | Approved 2026-10-31 (ADR-0010) |
| **R1** | `design/art/masters/pofu-master-v1/pofu-master-v1.png` | The master: R0 redrawn at 1024 × 1024, transparent, front view | **To make first** ([prompt 1](prompt-library.md#1-the-master-r1)) |
| **R1-lids** | `design/art/masters/pofu-master-v1/pofu-master-v1-lids.png` | R1 with the eyes painted out in fur: the lid plate the motion system reveals for blinks and happy eyes | Prompt 3i |
| **R2** | `design/art/masters/pofu-turnaround-v1/` | Front, three-quarter, back | Prompt 2 |
| **P-char** | [`design/reference/palette-card-character.png`](../../design/reference/palette-card-character.png) | Locked character palette as unlabeled swatches | Ready |
| **P-day / P-sunset / P-night** | `design/reference/palette-card-world-*.png` | Locked scene palettes | Ready |

Once R1 is approved, **R1 replaces R0 as the reference for everything**.
R0 is history. The species lineup that led to the hamster is kept at
[`docs/brand/assets/concepts/species-lineup-gpt-image.jpg`](../brand/assets/concepts/species-lineup-gpt-image.jpg).

## 2. The anchors

Two paragraphs are pasted **verbatim** into every prompt. Do not paraphrase
them, reorder them, or "improve" them in the moment: identical words are
one of the few levers we have for consistency. Change them only by editing
this file (and bumping the version below).

### Style anchor v1

```text
STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.
```

### Character anchor v1

```text
CHARACTER: Pofu, a baby hamster whose body is an almost perfect, extremely
fluffy ball, very slightly wider than tall. Creamy white fur on the face,
chest and belly; warm golden-peach fur on the top of the head, the back and
the sides; a cream blaze running from the forehead down between the eyes.
A single soft cream curl of fur on top of the head, shaped like a small
cinnamon-roll swirl rising out of the blaze: Pofu's signature tuft. Two
small round ears with pink insides. Big round glossy eyes, dark espresso
brown with a lighter warm-brown lower iris, set low and wide, each with one
large round white catchlight in the upper half and one tiny sparkle. Soft
peach-pink blush ovals under the eyes with two or three faint whiskers on
each side. A tiny rounded pink nose and a small smiling "w" mouth. Two
tiny cream front paws held together at the chest and two small pink feet
peeking out under the body; each paw and foot shows exactly three small toe
creases and no claws. No tail visible, no clothes, no accessories.
```

### Negative list (append to every prompt)

```text
AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, watermarks, signatures,
motion blur, film grain, paper texture, vignette.
```

## 3. Palette lock

The locked palettes live in
[`design/tokens/pofu-tokens.json`](../../design/tokens/pofu-tokens.json)
under `artPalettes` and are attached to prompts as swatch cards. The asset
pipeline measures every generation against them.

| Palette | Key colors | Used for |
|---|---|---|
| `character` | fur cream `#FEF2E3` / `#FAE1CE` / `#F4D3BD`, fur peach `#F4C7A4` / `#ECA96E` / `#D69069` / `#B87650`, ear `#F6A290`, blush `#FDC1B0`, nose `#FD9B86`, paw `#F0C4AE`, iris `#40251C`, eye `#241511`, highlight `#FFFFFF` | Pofu, stickers |
| `character-wilting` | ash cream `#EDE6DF` / `#D9CEC5`, ash peach `#CDB8A6` / `#B09C8E`, ash blush `#E3C3BA` | The wilting frames: warm ash, **never blue-gray, never green** |
| `world-day` | sky `#BFE1F0`, haze `#E6F2EE`, horizon `#FCEBDD`, meadow `#CFE6B0` → `#5E9E6A`, path `#F3DCC8`, flowers in blush, honey, lilac | Day plate |
| `world-sunset` | sky `#8F74F0` → `#C79BD8` → `#F2A38A` → `#FFD3A1`, meadow gold `#C9C27E` → shadow `#5B6E5A`, sun `#FFE7B8` | Golden hour plate |
| `world-night` | sky `#15111C` → `#3A3070`, moon `#FFF1D6`, fireflies `#F7E08A`, meadow `#2F4A45` / `#1F302F`, window glow `#F5B83D` | Night plate |

Rules: Pofu's colors never change with time of day in the source art (the
app grades them); lilac belongs to the UI and the sunset sky, never to
Pofu's fur; no pure black anywhere (darkest is `#15111C` or the eye ink).

## 4. Lighting

- One light setup for everything: soft key from the upper left, faint warm
  rim on the right, no hard shadows.
- Eyes: one large round catchlight in the upper half of each eye plus one
  tiny sparkle; both eyes lit consistently. More highlights read as anime,
  fewer read as dead.
- Scenes are lit to match Pofu: the sun (or moon) sits upper left in every
  plate, so the character's lighting is plausible in every scene without
  repainting him.
- Night: Pofu's source art stays the same; the app adds a cool grade and a
  warm window glow. Do not generate "night versions" of Pofu.

## 5. Line and texture

- **No outlines.** Shapes are defined by value and color, never by a line.
  (Whiskers, toe creases, and the mouth are the only drawn lines.)
- Fur: fine strands only at the silhouette and at color boundaries; the
  interior is velvety and smooth. Strand density is the "fluff" dial:
  thriving is airy and full, wilting is clumped (matted) and flatter.
- No grain, no paper texture, no visible brush noise: they compress badly,
  shimmer when animated, and change from generation to generation.

## 6. Anatomy lock (what must never drift)

Measured on R0; R1 inherits it.

| Feature | Lock |
|---|---|
| Silhouette | Ball, width : height ≈ 1.05 : 1 without ears and tuft; ears and tuft add about 15 % height |
| Eyes | Centers at about 47 % of body height; gap between eyes about 1.3 eye widths; round, never almond or oval |
| Tuft | Exactly one curl, centered, same spiral direction as R1 |
| Ears | Small, round, pink inside, at about 10 and 2 o'clock |
| Front paws | Two, at the chest, touching or nearly touching |
| Feet | Two, pink, at the bottom, about one eye width apart |
| Toes | Three creases per paw and foot |
| Nose and mouth | Tiny rounded pink nose; small "w" mouth; no teeth except a single tiny open-mouth shape for "Hop!" |
| Proportion of face | Face blaze and belly cream cover about half the front |

## 7. Composition rules by asset type

| Asset | Canvas | Composition | Background |
|---|---|---|---|
| **Character frame** | 1024 × 1024 | Full body, centered, feet on an imaginary ground line at about 90 % height, body about 80 % of canvas width, nothing cropped | **Transparent**; no ground, no shadow |
| **Turnaround** | 1536 × 1024 | Three poses in a row, same size, feet on one line, generous gaps | Transparent |
| **Sprite sheet** | 1024 × 1024 (3 × 3 or 4 × 4) or 1536 × 1024 (4 × 3) | One frame per cell, identical scale, feet on the same line in every cell, clear empty gutters, no overlap across cells | Transparent |
| **Sticker / prop** | 1024 × 1024 | Object centered, 8 % margin, three-quarter view, same light | Transparent |
| **Badge** | 1024 × 1024 | A circular medallion filling 92 % of the canvas: a cream rim, an inner disc in a pastel color, one centered object or Pofu pose inside. Identical rim for every badge | Transparent outside the circle |
| **Empty state / onboarding** | 1024 × 1024 | One idea, one star; Pofu small-to-medium with at most one prop; 10 % margin | Transparent |
| **Scene plate** | 1024 × 1536 portrait | Horizon at about 60 % height; **top 22 % calm sky, bottom 18 % calm grass** (glass chrome sits there); an empty **stage** of flat grass at center, 68–85 % height, where the app places Pofu; sun or moon upper left; no characters | Opaque, full bleed |
| **Room plate** (Home) | 1024 × 1536 portrait | Inside the burrow, straight-on view. A round window centered at about 28 % height, about 50 % of the width wide; walls above, floor from about 58 % height; an empty round rug centered at about 62 % height where the app places Pofu; **top 12 % and bottom 30 % calm** (glass buttons, the Today card, and the actions sit there); no wheel, no bowl, no plant (they are sprites); the window glass painted as a flat pale sky, because the app replaces it with the meadow | Opaque, full bleed |
| **App icon** | 1024 × 1024 | Focal shape inside the central 80 % circle; no detail in the corners (the system masks them); readable at 60 px | Opaque |

## 8. Background rules

- **Sprites are generated on transparency.** Ask for "transparent
  background PNG" every time.
- If a generation comes back opaque, **regenerate on flat chroma green
  `#00FF00`**, never on cream, peach, or white. The pipeline keys green
  cleanly; it cannot reliably key a cream hamster off a cream background
  (it fails such files on purpose).
- Scenes (the room and the meadow) are opaque plates and never contain
  Pofu: the app composes him in, so one hamster asset serves every scene,
  time, and vitality.

## 9. Do and don't gallery

Describe-only gallery (add real thumbnails here as approved and rejected
examples accumulate in `design/art/masters/`).

| Do | Don't |
|---|---|
| R0's soft painterly fur with fine silhouette strands | Glossy 3D vinyl-toy render (a different art style, even if cute) |
| Two eye highlights, espresso eyes | Anime eyes with stars, hearts, or five highlights |
| Cream belly, golden-peach back, one cream curl | Lilac or gray fur; two tufts; tuft turned into a flame or a leaf |
| Feet planted on an invisible ground line | A painted floor, a cast shadow, a pink ellipse under the feet |
| Sad-but-cute wilting: flatter, clumped, ash-tinted, droopy curl | Sick, crying, bandaged, sweating, or dirty Pofu |
| Pofu next to a wheel, stepping off it | Pofu inside a cage, or holding a phone (Pofu never holds a phone) |
| Badges as one medallion family | Ribbons, shields, stars, and medals mixed in one set |
| Generous transparent margin | Cropped ears, tuft, or feet |
| No text anywhere | "POFU" painted into an icon, labels on badges |
| Calm sky and grass bands in scenes | Busy detail behind where the tab bar will float |

## 10. Consistency techniques for GPT Image

What actually keeps generations consistent, in order of power:

1. **Attach the reference image every time.** R1 (and the palette card for
   a new asset family). Words alone re-invent the character.
2. **Edit, don't regenerate.** Variants (expressions, poses, badge
   contents) are edits of an approved image: "Edit the attached image.
   Change only … Keep everything else identical: …". In ChatGPT, use the
   image's edit/select tool to brush over just the eyes or mouth when the
   change is local.
3. **One chat per asset family.** Long chats accumulate drift. Start a new
   chat for each family (expressions, scenes, badges) and re-attach the
   references. If two consecutive results drift, start a new chat rather
   than arguing with the old one.
4. **Fixed phrasing.** Paste the anchors verbatim. ChatGPT exposes no seed
   parameter, so identical references and identical words are the
   substitute for a seed. (Via the API, keep the same model snapshot and,
   for edits, request high input fidelity where available.)
5. **Whole sequences in one image.** For animation, ask for the whole
   sprite sheet in one prompt: frames drawn together drift less than
   frames drawn one by one.
6. **Generate wide, select hard.** Volume is not a constraint on the Pro
   plan; consistency is. Ask for each prompt 3–4 times, keep the single
   best, and never "average" by mixing parts from different runs.
7. **Name on download.** Save winners straight into `design/art/inbox/`
   using the pipeline's naming (`char__pofu-curious.png`), then run
   `process_assets.py process`. The tool catches resolution, alpha, keying
   leaks, painted shadows, and palette drift; the human catches the rest.

### Resolution and aspect conventions

| Asset | Request | Minimum accepted | Output points |
|---|---|---|---|
| Character, sticker, badge, empty state, onboarding | 1024 × 1024, transparent | 1024 px (sticker 512) | 320 pt (character), 96 pt (sticker), 120 pt (badge) |
| Turnaround | 1536 × 1024, transparent | 1024 px short side | Reference only |
| Sprite sheet | 1024 × 1024 (3 × 3 or 4 × 4) or 1536 × 1024, transparent | Cells of at least 256 px | Small and medium animations (up to about 85 pt with 256 px cells) |
| Scene plate | 1024 × 1536, opaque | 1024 px wide | 440 pt wide; @3x is a 1.29× upscale, within tolerance; above 1.5× upscale the master first |
| App icon | 1024 × 1024, opaque | Exactly 1024 | Icon Composer on the Mac |

If ChatGPT offers larger outputs, take the largest and let the pipeline
downsample.

## 11. Acceptance checklist

An image is approved only when every item holds. Check at 100 % zoom and
on the iPhone at real size.

1. Passes `process_assets.py` with no errors (warnings read and accepted).
2. Same character as R1 in a side-by-side flip test: eyes, tuft, ears,
   blaze, paws, feet, proportions (section 6).
3. Palette drift status `ok` (or `warn` with a stated reason, such as the
   wilting frame).
4. No defect from the list below.
5. Expression reads instantly at 64 pt (would a friend name the mood?).
6. Silhouette reads at 44 pt on both the day and the night scene.
7. Transparent edges are clean on violet `#6C4FD8` and on night
   `#15111C` (no halo, no fringe).
8. No text, signature, or watermark, including tiny artifacts in corners.
9. Composition follows section 7 for its type.
10. Provenance recorded (section 13).

## 12. Defect list

| Defect | How it shows up | Fix |
|---|---|---|
| Extra toes or fingers | Four or five creases, finger-like paws | Local edit: select the paw, "exactly three small toe creases, no fingers" |
| Eye drift | Eyes oval, larger, closer, or higher than R1 | Edit with R1 attached: "make the eyes exactly like the reference: round, same size and position" |
| Highlight drift | Star or heart highlights, many sparkles, missing catchlight | Local edit of the eyes |
| Color drift | Fur more orange or saturated, cream turns yellow or pink | Attach the palette card; "match the reference colors exactly"; pipeline flags it |
| Species drift | Rabbit-like ears, cat nose, long tail, mouse snout | Regenerate from R1 in a new chat |
| Tuft drift | Two curls, mirrored spiral, flame or leaf shape | Local edit of the tuft |
| Text artifacts | Letters in the background, fake signatures, gibberish labels | Regenerate; never ship a cleaned-up text artifact |
| Sticker border | White outline around the silhouette | "no outline, no sticker border"; regenerate |
| Painted ground shadow | Pink or gray ellipse under the feet | "no floor, no shadow"; or erase by hand (pipeline warns) |
| Fringe or halo | Light rim on dark backgrounds after keying | Regenerate on transparency or chroma green |
| Scale drift in sheets | Pofu grows or shrinks between cells | Regenerate the sheet; pipeline flags width changes above 12 % |
| Perspective drift | Some cells three-quarter, some front | Regenerate with "every frame front view" |
| Motion blur and smears | Smeared fur in action frames | "no motion blur, crisp frames" |
| Grotesque wilting | Tears, sickness, dirt, gray-green skin | Regenerate with the wilting wording from the prompt library |
| Over-detail | Busy fur noise, extra props, background clutter | Regenerate; simplicity is a requirement, not a preference |

## 13. Provenance and storage

- `design/art/inbox/` is git-ignored scratch space for raw downloads.
- Approved masters go to `design/art/masters/<asset-name>/` with the
  approved PNG and a `provenance.md` containing: the exact prompt, the date,
  the tool and model as shown in ChatGPT, the attached references (by ID),
  the number of generations considered, and every human edit made
  afterwards (crop, paint-over, color correction).
- Exported catalogs are build output (`build/`); copying one into
  `App/Resources` is a reviewed pull request.

## 14. Legal notes (brief, not legal advice)

- **Ownership of purely AI-generated images is weak.** The US Copyright
  Office registers only human-authored expression, and courts have upheld
  that (Thaler v. Perlmutter, 2025). Other jurisdictions, Türkiye
  included, likewise tie copyright to a human author. OpenAI's terms assign
  output rights to the user, but cannot create copyright that the law does
  not grant. Expect competitors to be able to copy individual raw images.
- **Mitigations we use:**
  - **Human authorship on top:** curated selection and arrangement,
    hand edits, the character bible and copy, and the code-driven
    animation are human work; document them (section 13).
  - **Trademark, not copyright, protects the brand:** register the name
    "Pofu" and the logo (a **hand-drawn vector** wordmark and glyph, not raw
    generations) with TÜRKPATENT first, then the EUIPO and the USPTO, before
    public launch.
  - **Documented process:** prompts, references, and edit history are kept
    in the repository.
  - **Clean prompts:** never name living artists, studios, or existing
    characters in prompts ("in the style of …" is banned).
  - **Clearance:** before launch, reverse-image-search the master and the
    icon against existing mascots (Hamtaro and other hamster characters)
    and keep the result in the provenance file.
- Revisit with a lawyer before spending on trademark filings or merch.

_Version history: v1.0 (2026-10-31) first version; anchors v1._
