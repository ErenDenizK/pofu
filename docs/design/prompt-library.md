# Pofu Prompt Library

_Status: v1.0, for the founder's morning session of 2026-11-01. Anchors
v1 from the [art bible](art-bible.md)._

Ready-to-run GPT Image prompts, in priority order. Every prompt is complete
and copy-pasteable on its own: it repeats the style and character anchors
verbatim, says what to attach, and what to ask for. The rules behind them
are in the [art bible](art-bible.md); where each asset is used is in the
[design language](../archive/design-language.md).

No video prompts: Sora is discontinued and there is no budget for other
video tools. Motion comes from sprite sheets plus code.

## How to run the session

1. **Open one ChatGPT chat per family** and name it: "Pofu · Character",
   "Pofu · Animation", "Pofu · Icon & logo", "Pofu · Scenes",
   "Pofu · Badges & stickers", "Pofu · Onboarding & empty states".
   Long chats drift; when two results in a row drift, start a fresh chat
   and re-attach the references.
2. **Attach exactly what each prompt says.** References live in
   `design/reference/` (R0 concept, palette cards). R1 does not exist yet:
   prompt 1 creates it, and from then on R1 is attached to everything.
3. **Run each prompt 3–4 times** (volume is not the constraint; consistency
   is) and keep only the best. Never combine parts of different runs.
4. **Save winners into `design/art/inbox/`** with the file name in the
   prompt's "Save as" line, then run:

   ```sh
   python3 -I tools/assets/process_assets.py process --inbox design/art/inbox --out build/PofuArt.xcassets
   ```

   Sheets use the `slice` command shown with each sheet prompt; `sheet__`
   and `ref__` files are skipped by `process` on purpose.
5. **Check the acceptance checklist** in the art bible before approving.

### ChatGPT "Images" (Görseller) templates

The Images section offers ready-made templates. Use them where noted; the
prompts also work as plain chat messages. If a template's built-in style
fights the style anchor (for example, adds 3D or text), switch to a plain
chat with the same prompt.

| Template | Use for |
|---|---|
| _Plain chat_ or **İllüstrasyon** (Illustration) | Character, expressions, sprite sheets, scenes, onboarding, empty states |
| **Logo** | App icon directions, wordmark direction |
| **Simge** (Icon set) | Matching badge sets as a 2 × 2 exploration |
| **Uygulama taslağı** (App mockup) | Optional Home look-and-feel exploration (inspiration only) |
| **Promosyon ürünleri** (Promo merchandise) | Later: merch |

### Priority tiers

- **P0, this morning.** Unblocks the first build: the base, its face
  edits and celebration sheet (the companion motion system's asset
  contract), icon directions, Pofu's room, day and night meadows, the seed
  and the wheel.
- **P1, first build.** Needed before the friends beta: turnaround, sunset,
  badges, onboarding, empty states, wordmark direction.
- **P2, later.** Nice to have, post-launch, or only if the procedural
  motion falls short on device (the extra sprite sheets).

| # | Asset | Tier | Template | Attach | Output | Save as |
|---|---|---|---|---|---|---|
| 1 | The base (R1) | P0 | Plain / İllüstrasyon | R0, palette card | 1024 × 1536, transparent | `char__pofu-hamster-base.png` |
| 2 | Turnaround: front, ¾, back | P1 | Plain | R1 | 1536 × 1024, transparent | `ref__pofu-turnaround.png` |
| 3a–3f | Face edits of the base (6) | P0 | Plain | R1 | 1024 × 1536, transparent | `char__pofu-hamster-<variant>.png` |
| 3g | Celebration sheet 3 × 2 | P0 | Plain | R1 | 1536 × 1024, transparent | `sheet__pofu-hamster-celebrate-3x2.png` |
| 5a–5c | App icon, three directions | P0 | Logo | R1 | 1024², opaque | `appicon__app-icon--<dir>.png` |
| 6r | Pofu's room plate (Home) | P0 | İllüstrasyon | P-char, R1 (style only) | 1024 × 1536, opaque | `scene__room.png` |
| 6 | Day meadow plate | P0 | İllüstrasyon | P-day, R1 (style only) | 1024 × 1536, opaque | `scene__meadow-day.png` |
| 7 | Night plate (edit of 6) | P0 | Plain | Plate 6, P-night | 1024 × 1536 | `scene__meadow-night.png` |
| 8 | Wilting day plate (edit of 6) | P0 | Plain | Plate 6 | 1024 × 1536 | `scene__meadow-day-wilting.png` |
| 9 | Sunflower seed (energy) | P0 | Plain | R1, palette card | 1024², transparent | `sprite__seed.png` |
| 10 | Hamster wheel prop | P0 | Plain | R1 | 1024², transparent | `sprite__wheel.png` |
| 14 | Sunset plate (edit of 6) | P1 | Plain | Plate 6, P-sunset | 1024 × 1536 | `scene__meadow-sunset.png` |
| 15 | Pofu on the wheel, stepping off | P1 | Plain | R1, 3f, prop 10 | 1024², transparent | `sprite__pofu-wheel-*.png` |
| 16 | Badge medallion and first two badges | P1 | Simge, then plain | R1, seed 9 | 1024², transparent | `badge__*.png` |
| 17 | Onboarding (4) | P1 | İllüstrasyon | R1 | 1024², transparent | `sprite__onboarding-*.png` |
| 18 | Empty states (3) | P1 | İllüstrasyon | R1 | 1024², transparent | `sprite__empty-*.png` |
| 19 | Wordmark direction | P1 | Logo | R1 | 1536 × 1024 | reference only |
| 20 | Home look-and-feel exploration | Optional | Uygulama taslağı | R1, plate 6 | 1536 × 1024 | reference only |
| 21 | More badges (2 × 2 sets) | P2 | Simge | Badge 16a | 1024² | `badge__*.png` |
| 22 | Stickers: tea glass, simit | P2 | Plain | R1 | 1024², transparent | `sprite__tea-glass.png`, `sprite__simit.png` |
| 23 | Collectible species in Pofu style | P2 | Plain | R1 | 1024², transparent | later |
| 24 | Merch mockups | P2 | Promosyon ürünleri | R1, icon | any | reference only |
| 4 | Blink sheet 3 × 3 (if procedural blinks look fake) | P2 | Plain | R1, 3a | 1024², transparent | `sheet__pofu-blink.png` |
| 11 | Cheeks-filling sheet 3 × 3 (if the pouch shader falls short) | P2 | Plain | R1, 3e | 1024², transparent | `sheet__pofu-cheeks.png` |
| 12 | Happy bounce sheet 4 × 4 (small sizes) | P2 | Plain | R1, 3b | 1024², transparent | `sheet__pofu-bounce.png` |
| 13 | Celebration hop sheet 4 × 4 (small sizes) | P2 | Plain | R1, 3b | 1024², transparent | `sheet__pofu-hop.png` |

**Must-have for the first build:** 1, 3a–3g, one approved icon from 5,
6r, 6, 7, 8, 9, 10, 16 (first resist and 7-day streak), 17. Everything else
can follow.

---

## P0: this morning

### 1. The base (R1)

The single most important image. Everything else is an edit of it, and
the companion motion system animates it directly
([companion-motion.md](companion-motion.md), section 5). Spend the most
time here.

- **Chat:** Pofu · Character. **Template:** plain chat (or İllüstrasyon).
- **Attach:** `docs/brand/assets/concepts/hamster-gpt-image.png` (R0) and
  `design/reference/palette-card-character.png`.
- **Ask for:** transparent background PNG, 1024 × 1536 (portrait).

```text
Redraw the attached hamster character as the clean master reference for
our app mascot. Keep its design, proportions, colors and charm exactly; it
is already approved. The second attachment is a palette card: use only
these colors.

Pose: front view, sitting upright, full body, calm and content, mouth
closed in a small smile, eyes open, looking at the viewer. Centered on a
1024 x 1536 portrait canvas, about 70% of the canvas width, feet resting
on an invisible line at 88% of the height, empty space above the tuft.
Nothing is cropped.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

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

AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, watermarks, signatures,
motion blur, film grain, paper texture, vignette.

Output: one image, transparent background PNG, 1024 x 1536, portrait.
```

**Save as** `char__pofu-hamster-base.png` and, once approved, also as
`design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png` (R1). If the
background is not transparent, reply: _"Same image, but on a fully
transparent background, PNG."_ If that fails, ask for a flat `#00FF00`
background instead (the pipeline keys it).

### 2. Turnaround: front, three-quarter, back

- **Attach:** R1. **Ask for:** transparent PNG, 1536 × 1024 (landscape).

```text
Using the attached image as the exact character reference, create a
character turnaround sheet of the same character: three views side by side
in one row, left to right: front view, three-quarter view facing left, back
view. All three at the identical size and scale, feet on the same
invisible ground line, generous empty space between the views. Same colors,
same fur, same tuft, same ears, same proportions as the reference. In the
back view the golden-peach back fur and the cream curl on top of the head
are visible; no tail.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

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

AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, labels, watermarks,
signatures, motion blur, film grain, paper texture, vignette.

Output: one image, transparent background PNG, 1536 x 1024.
```

### 3. Face edits of the base (the motion contract)

The motion system composites these over the base by region (eyes, mouth,
cheeks, fur), so each edit must change **only** its region and line up
with the base pixel for pixel everywhere else. Posture, lean, squash, hops,
lids, and the vitality grade are procedural; do not ask for them. The
set and names follow [companion-motion.md](companion-motion.md), section 5.
The asset pipeline keeps edits of one canvas locked to the base's
registration.

Run each in the Character chat. **Attach R1 every time. Ask for:
transparent background PNG, 1024 × 1536, same canvas as the reference.**
Start each prompt with the shared preamble, then the change line.

**Shared preamble** (put first in every 3x prompt):

```text
Edit this exact image. Keep everything identical: the same character,
pose, size, position on the canvas, framing, lighting, fur strands,
colors, and transparent background. Do not redraw, move, or restyle
anything except the change below. The result must line up with the
original pixel for pixel outside the changed area.

STYLE (unchanged from the reference): soft painterly 2D digital
illustration, gentle airbrushed shading, no outlines, fine soft fur
strands, warm light from the upper left, pastel cream, golden peach and
blush palette, dark espresso-brown eyes. No text, no watermark, no ground,
no cast shadow, no sticker outline.

Output: one image, transparent background PNG, 1024 x 1536.
```

| # | Variant | Change line (after the preamble) | Used for | Save as |
|---|---|---|---|---|
| 3a | Eyes closed | `Change: close both eyes gently and calmly, as if peacefully asleep. Each closed eye is a thin, soft, slightly downward-curved dark line where the lower edge of the eye was, with the eyelid area above it covered by the same short cream fur as the surrounding face. No eyelashes sticking out, no tears, no wrinkles. Nothing else changes.` | Sleeping, focused, blinks at hero size | `char__pofu-hamster-eyes-closed.png` |
| 3b | Eyes happy | `Change: make both eyes happy closed arcs, the classic smiling ^ shape: each eye becomes a thick, soft, dark upward-curved arc at the height of the top of the original eye, with fur below it. The cheeks lift very slightly. Nothing else changes.` | Joy, celebration, petting | `char__pofu-hamster-eyes-happy.png` |
| 3c | Mouth open | `Change: open the mouth into a small, happy laugh: a soft rounded opening under the nose with a hint of pink tongue, the same width as the current smile. The muzzle fur moves only around the mouth. Nothing else changes.` | Laugh, celebration | `char__pofu-hamster-mouth-open.png` |
| 3d | Mouth "o" | `Change: make the mouth a small round "o" of surprise and curiosity under the nose, about a third the width of the current smile. Nothing else changes.` | Curious "Hop!" (with a procedural lean) | `char__pofu-hamster-mouth-o.png` |
| 3e | Cheeks full | `Change: puff out both cheek pouches as if stuffed with sunflower seeds, so the cheeks bulge outward and slightly down and the face looks rounder and wider at cheek height. Keep the same blush, eyes, and expression. Do not add any visible food. Nothing else changes.` | Reference for the pouch shader; small sizes | `char__pofu-hamster-cheeks-full.png` |
| 3f | Matted | `Change: make the fur look tired: flatter and smoother, lying close to the body in soft clumps, with fewer fluffy wisps on the outline, and the colors gently washed toward warm ash (warm grayish cream and muted beige-peach, never blue-gray, never green). Same pose, same size, same face and expression. Sad but still cute and clean, never dirty, wet, sick, or injured.` | Wilting (blended by vitality) | `char__pofu-hamster-matted.png` |

How the character bible's moods map onto this set: **content** is the
base; **curious** is 3d plus a lean; **happy and celebrating** are 3b and 3c;
**tired** is procedural sleepy lids; **wilting** is 3f plus squash and the
vitality grade; **sleeping** and **focused** are 3a with slow breathing;
**cheeks puffed** is the pouch shader, checked against 3e.

### 3g. Celebration sprite sheet (3 × 2)

The one sheet the motion contract requires: a short flourish that
procedural motion cannot fake. 3 × 2 keeps the cells large (512 px wide
at 1536 × 1024).

- **Attach:** R1. **Ask for:** transparent PNG, 1536 × 1024 (landscape).

```text
Using the attached character as the exact reference, create a sprite sheet
of a single short animation: a 3x2 grid of 6 equal cells (3 columns, 2
rows) on a fully transparent background, read left to right, top to
bottom. The same character in every cell: identical design, colors, fur,
proportions, size, and front-facing camera, centered horizontally, with
the feet on the same baseline near the bottom of every cell. Leave empty
transparent margin around the character in every cell; nothing touches a
cell edge. No grid lines, no numbers, no text, no motion blur, no ground,
no cast shadow.

Animation, 6 frames, joyful celebration while staying seated:
1. content, eyes open, small smile;
2. eyes squeeze into happy ^ arcs, cheeks lift, mouth opens in a laugh;
3. tiny wiggle to the left, ears flop slightly right, tuft swings right;
4. tiny wiggle to the right, ears flop slightly left, tuft swings left;
5. arms raised a little in a cheer, biggest laugh, rosy cheeks;
6. settling back, happy ^ eyes, closed smile.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left.
Pastel warm palette of cream, golden peach and blush pink with dark
espresso-brown eyes. No text, no letters, no numbers, no logos, no
watermark, no border, no frame, no sticker outline.

AVOID: outlines, 3D plastic render, anime sparkle eyes, extra limbs, extra
toes, claws, teeth, lilac or gray fur, a floor, a cast shadow, motion
blur, a white sticker border, frame numbers, watermarks.

Output: one image, transparent background PNG, 1536 x 1024.
```

**Slice:**

```sh
python3 -I tools/assets/process_assets.py slice --sheet design/art/inbox/sheet__pofu-hamster-celebrate-3x2.png \
  --name pofu-hamster-celebrate --grid 3x2 --fps 12 --no-loop --out build/animations
```

### 5. App icon: three radically different directions

- **Chat:** Pofu · Icon & logo. **Template:** Logo.
- **Attach:** R1. **Ask for:** opaque PNG, 1024 × 1024.
- Run all three, put them on the iPhone home screen (as wallpapers or with
  a test build), and judge at real size next to Instagram, YouTube, and
  TikTok. The winner is redrawn into layers for Icon Composer.

**Shared icon block** (append to each direction):

```text
This is an iOS app icon: a 1024 x 1024 square, full bleed, with square
corners (iOS applies the rounded mask, so do not draw rounded corners or a
border). Keep all important shapes inside the central 80% circle and keep
the corners simple. It must read clearly at 60 pixels: one bold idea, big
simple shapes, strong silhouette, no small details. Absolutely no text, no
letters, no numbers. The character must match the attached reference
exactly: same face, eyes, colors, ears and cream curl on top of the head.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Warm diffused key light from the upper left.
Clean, calm, uncluttered. No text, no logos, no watermark.

AVOID: text, letters, rounded corners, borders, frames, drop shadows
outside the shape, 3D plastic render, tiny details, more than one
character, a phone, a screen.

Output: one image, opaque background (no transparency), PNG, 1024 x 1024.
```

| Dir | Idea | Change line | Save as |
|---|---|---|---|
| 5a | **Close-up**: emotional, warm | `Direction A, "close-up": a tight close-up of Pofu's face filling most of the icon, from the cream curl at the top to the blush cheeks at the bottom, slightly cropped at the sides by the fluffy cheeks; big glossy eyes looking at the viewer with a soft smile. Background: a soft warm blush-peach gradient (#FDC1B0 to #FEEEE6).` | `appicon__app-icon--a.png` |
| 5b | **Violet field**: owns the accent, stands out on a home screen | `Direction B, "violet field": Pofu's whole round body, front view, happy, centered and filling about 62% of the icon width, glowing softly against a deep violet background with a gentle radial gradient from lilac (#B9A2FF) in the center to deep violet (#6C4FD8) at the edges. A soft warm rim light separates the cream fur from the violet.` | `appicon__app-icon--b.png` |
| 5c | **The mark**: graphic, scalable, ownable | `Direction C, "the mark": a flat, graphic, almost logo-like Pofu: the round fluffy silhouette simplified into a smooth circle with two small round ears and the single cream curl on top, cream (#FEF2E3) on a golden-peach (#ECA96E) background, with only two big glossy dark eyes, two blush dots and a tiny smile. Minimal painterly texture, no fur strands, bold and iconic.` | `appicon__app-icon--c.png` |

For the winner, follow up in the same chat: _"Now give me this icon as two
separate layers for Apple's Icon Composer: (1) the background only, opaque,
1024 × 1024; (2) the character only on a fully transparent background,
1024 × 1024, in exactly the same position and size."_ Direction C, if
chosen, is redrawn by hand in vector before launch (it is also the
trademark candidate; see the art bible's legal notes).

### 6r. Pofu's room plate (Home)

Home is Pofu's room, the single root of the app
([information architecture](../archive/information-architecture.md)).
The meadow plates below show through its window and fill Hop! and focus.

- **Chat:** Pofu · Scenes. **Template:** İllüstrasyon.
- **Attach:** `palette-card-character.png` and R1 (for style only).
- **Ask for:** opaque PNG, 1024 × 1536 (portrait).

```text
A portrait background plate for the home screen of a mobile app, 1024 x
1536, painted in the same art style as the attached character (use the
character for style only: do NOT include it or any character in this
image). Use the warm colors of the attached palette card.

Scene: the cozy inside of a hamster's burrow, a small round room seen
straight on. Composition rules, follow them exactly:
- One large round window with a simple wooden frame and a cross-shaped
  mullion, centered horizontally at about 28% of the image height, about
  half the image width wide. Paint the window glass as a flat, plain pale
  sky with nothing in it (it will be replaced in the app).
- Soft warm cream plaster walls above, gently curved like the inside of a
  burrow; a warm honey wooden floor from about 58% of the height down.
- In the center of the floor, at about 62% of the height, an empty round
  blush-pink rug: a stage where a character will be placed later.
- The top 12% of the image is calm wall with no details; the bottom 30% is
  calm, plain floor with no details (interface elements sit there).
- Nothing else in the room: no furniture, no wheel, no bowl, no plants,
  no lamp (these are added separately).
- Soft daylight from the window, light from the upper left.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook. Gentle airbrushed shading, no outlines, no hard edges, pastel
warm colors, calm, uncluttered, plenty of quiet space. No text, no letters,
no numbers, no logos, no watermark, no border, no frame.

AVOID: any characters or animals, furniture, clutter, strong contrast,
dark corners, busy textures, text, signatures, film grain, vignette.

Output: one image, opaque, PNG, 1024 x 1536, portrait.
```

After approval, record the window's circle (center and radius, in unit
coordinates of the normalized plate) next to the master, so the app can
clip the meadow to it.

### 6. Day meadow scene plate

- **Chat:** Pofu · Scenes. **Template:** İllüstrasyon.
- **Attach:** `palette-card-world-day.png` and R1 (for style only).
- **Ask for:** opaque PNG, 1024 × 1536 (portrait).

```text
A portrait background plate for the home screen of a mobile app, 1024 x
1536, painted in the same art style as the attached character (use the
character for style only: do NOT include it or any character in this
image). Use only the colors of the attached palette card.

Scene: a gentle, cozy meadow hill on a soft sunny day. Composition rules,
follow them exactly:
- The horizon sits at about 60% of the image height.
- The top 22% of the image is calm open pale-blue sky with at most two
  small soft clouds and nothing else.
- The bottom 18% of the image is calm, soft, short grass with no details.
- In the center, between 68% and 85% of the height, there is a small flat
  clearing of short grass, completely empty: it is a stage where a
  character will be placed later.
- On the left hillside, a tiny round wooden door set into the hill: the
  entrance to Pofu's burrow (his room is inside).
- A few small wildflowers in blush pink, honey yellow and soft lilac
  scattered at the sides, a few tall grass blades in the foreground
  corners, soft rolling hills behind.
- The sun is out of frame at the upper left; light comes from the upper
  left.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook. Gentle airbrushed shading, no outlines, no hard edges, soft
atmospheric depth, pastel colors, calm and uncluttered, plenty of quiet
space. No text, no letters, no numbers, no logos, no watermark, no border,
no frame.

AVOID: any characters or animals, people, buildings other than the burrow
door, roads, fences, harsh contrast, strong saturated green, busy detail in
the top and bottom bands, text, signatures, film grain, vignette.

Output: one image, opaque, PNG, 1024 x 1536, portrait.
```

### 7. Night plate (edit of the day plate)

Same composition matters: the app cross-fades between times of day, so the
hills must not move.

- **Attach:** the approved day plate and `palette-card-world-night.png`.

```text
Edit the attached meadow background. Keep the exact same composition:
the same hills, horizon, burrow door, clearing, flowers and grass in
exactly the same places. Change only the time and light: a calm, cozy
night. Deep plum-to-indigo sky using the colors of the attached night
palette card, a soft glowing crescent moon at the upper left, a few gentle
stars in the upper sky (keep the top 22% calm), a handful of tiny warm
fireflies near the flowers, the burrow's round door glowing warmly from a
lit window. The clearing in the center stays empty and softly moonlit. The
mood is safe, peaceful and beautiful, never dark or scary. Same soft
painterly style, no outlines, no text, no characters, no animals.

Output: one image, opaque, PNG, 1024 x 1536, portrait.
```

### 8. Wilting day plate (edit of the day plate)

```text
Edit the attached meadow background. Keep the exact same composition:
the same hills, horizon, burrow door, clearing, flowers and grass in
exactly the same places, and the same daylight direction. Change only the
mood of nature, as if the meadow is a little tired: a soft overcast
pearl-gray sky with a faint lilac tint, the colors gently desaturated, the
flowers closed and drooping, the grass slightly flatter and less lush.
It must stay soft and gentle: never dead, never brown or dry, no rain, no
storm, no darkness. Same soft painterly style, no outlines, no text, no
characters, no animals.

Output: one image, opaque, PNG, 1024 x 1536, portrait.
```

### 9. Sunflower seed (energy)

- **Chat:** Pofu · Badges & stickers. **Attach:** R1 (style),
  `palette-card-character.png`.

```text
A single sunflower seed as a cute, slightly plump, rounded sticker-like
object in the same art style as the attached character (style only; do
not include the character). The seed is a soft teardrop shape with gentle
cream and warm brown stripes, a subtle soft highlight from the upper left,
three-quarter view, centered with a generous margin. It will be shown as
the app's energy icon, so it must read at small sizes: simple shape,
clear stripes, no tiny details.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Warm diffused key light from the upper left.
Clean, calm, uncluttered. No text, no letters, no numbers, no logos, no
watermark, no border, no frame, no sticker outline.

AVOID: a ground shadow, a floor, a white sticker border, more than one
seed, a face on the seed, text.

Output: one image, transparent background PNG, 1024 x 1024.
```

### 10. Hamster wheel prop

```text
A small wooden hamster wheel on a little stand, as a prop in the same art
style as the attached character (style only; do not include the
character). Rounded, friendly proportions, warm honey-toned wood with
cream inner slats, softly worn, three-quarter view from slightly to the
left, centered with a generous margin, empty. It is a freestanding wheel
outdoors, not part of a cage.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Warm diffused key light from the upper left.
Clean, calm, uncluttered. No text, no letters, no numbers, no logos, no
watermark, no border, no frame, no sticker outline.

AVOID: a cage, bars, metal, a ground shadow, a floor, a white sticker
border, any animal, text.

Output: one image, transparent background PNG, 1024 x 1024.
```

---

## P1: first build

### 14. Sunset plate (edit of the day plate)

- **Attach:** the approved day plate and `palette-card-world-sunset.png`.

```text
Edit the attached meadow background. Keep the exact same composition:
the same hills, horizon, burrow door, clearing, flowers and grass in
exactly the same places. Change only the time and light: golden hour. A
soft sky gradient from violet at the top through mauve and coral to warm
gold at the horizon, using the colors of the attached palette card, the
sun low at the upper left just above the hills, long soft shadows, warm
golden rim light on the grass and flowers, the burrow window starting to
glow. Keep the top 22% calm and the clearing in the center empty. Same
soft painterly style, no outlines, no text, no characters, no animals.

Output: one image, opaque, PNG, 1024 x 1536, portrait.
```

### 15. Pofu on the wheel, and stepping off

Two frames, both edits combining R1 with the approved wheel (prop 10).
They are standalone illustrations (a moment, not the rig), so they are
sprites, not character frames.
**Attach:** R1, 3f (matted), and the wheel. **Output:** transparent PNG,
1024 × 1024 each. Append the style anchor, character anchor, and
negative list from the [art bible](art-bible.md) to both.

- **15a** `sprite__pofu-wheel-running.png`:
  `Combine the attached character and the attached wheel: Pofu is running inside the wheel, tired and dazed, eyes half-closed and slightly unfocused, fur a little flat, mid-stride, the wheel spinning (no motion blur). Pofu is the same size relative to the wheel as a real hamster: the wheel is about 1.4 times Pofu's height. Sad but cute, never distressed.`
- **15b** `sprite__pofu-wheel-hop-off.png`:
  `Same scene: Pofu hops out of the wheel to the right, mid-air just outside it, eyes bright and happy again, the tuft springing up, paws forward, the wheel still turning behind. Joyful relief.`

### 16. Badges: the medallion, then the first two badges

Consistency comes from one medallion. Make it once, then edit it.

**16-0. Set exploration (optional, Simge template).** Attach R1 and the
seed (9):

```text
A matching set of four circular achievement badges for a mobile app, in a
2x2 grid, all four sharing the exact same medallion design: a soft cream
rim with a subtle inner bevel, and an inner disc in a different soft pastel
per badge (blush, honey, meadow green, lilac). Inside each disc one simple
centered motif in the art style of the attached character: 1 the attached
character hopping out of a small wooden hamster wheel; 2 a small sunflower
in bloom with exactly seven petals glowing softly; 3 the character
meditating calmly on a leaf; 4 the character asleep in a half walnut
shell under a tiny crescent moon. Soft painterly 2D illustration, no
outlines, warm light from the upper left. No text, no numbers, no
ribbons, no stars, no banners. Transparent background, PNG, 1024 x 1024.
```

Use it to pick the direction; then make production badges one at a time:

**16a. Medallion base** (plain chat, attach the chosen set image):

```text
From the attached badge set, create only the empty medallion: the same
cream rim and an empty inner disc in soft blush (#FDD9CF), front view,
perfectly circular, centered, filling 92% of the image. Same soft painterly
style, light from the upper left. No motif inside, no text, no numbers, no
ribbons, no shadow outside the circle. Transparent background PNG,
1024 x 1024.
```

**16b and 16c** are edits of 16a (attach 16a and R1; save as
`badge__first-resist.png` and `badge__streak-7.png`):

```text
Edit the attached medallion. Keep the medallion exactly identical (same
rim, same size, same position). Change only the inner disc: [MOTIF].
Same soft painterly style as the attached character, no outlines, light
from the upper left. No text, no numbers, no ribbons, no stars.
Transparent background PNG, 1024 x 1024.
```

- First resist: `inner disc in soft meadow green; inside it, the attached character hopping happily out of a small wooden hamster wheel, eyes bright, tuft springing up`
- 7-day streak: `inner disc in soft honey; inside it, a small sunflower in full bloom with exactly seven glowing petals, on a short stem with two leaves`

Streak badges grow one sunflower: 3 days a sprout, 7 days a bloom, 30 days
a tall sunflower, 100 days a sunflower field. The motif ties streaks to the
seed economy and avoids the category's ubiquitous flame.

### 17. Onboarding illustrations (4)

- **Chat:** Pofu · Onboarding & empty states. **Template:** İllüstrasyon.
- **Attach:** R1. **Output:** transparent PNG, 1024 × 1024 each.

**Shared block** (append to each):

```text
One single idea, one character, at most one prop, generous empty margin
(10% on every side), centered. The character must match the attached
reference exactly. Soft painterly 2D illustration with the polish of a
premium storybook and a top-tier mobile app mascot; gentle airbrushed
shading, no outlines, warm light from the upper left, pastel cream, golden
peach and blush palette. No text, no letters, no numbers, no logos, no
watermark, no ground shadow, no floor, no sticker border, no phone, no
screens. Transparent background PNG, 1024 x 1024.
```

| # | Step | Scene line | Save as |
|---|---|---|---|
| 17a | Meet Pofu | `Pofu waves hello with one front paw raised, a warm happy smile, sitting on a small tuft of meadow grass with two tiny wildflowers.` | `sprite__onboarding-hello.png` |
| 17b | The reflex | `Pofu in the curious "Hop!" pose, leaning forward with both front paws raised gently as if saying "wait a second", eyes wide and kind.` | `sprite__onboarding-hop.png` |
| 17c | Earn by living | `Pofu with cheeks happily stuffed with sunflower seeds, holding one more seed in both front paws, proud and delighted.` | `sprite__onboarding-earn.png` |
| 17d | Grow together | `Pofu, extra fluffy and glowing, sitting next to a small sunflower in bloom that is as tall as Pofu, both turned toward a soft warm light at the upper left.` | `sprite__onboarding-grow.png` |

### 18. Empty states (3)

Same chat and shared block as 17.

| # | Screen | Scene line | Save as |
|---|---|---|---|
| 18a | No activities yet | `Pofu holding a single sunflower seed in both front paws, looking up hopefully, a little curious.` | `sprite__empty-activities.png` |
| 18b | No friends yet | `Pofu sitting on one end of a tiny wooden bench, the other end of the bench empty, glancing at the empty seat with a hopeful smile.` | `sprite__empty-friends.png` |
| 18c | Quiet day, no impulses | `Pofu lying on its back in soft grass, totally relaxed and content, eyes closed, a tiny flower beside it.` | `sprite__empty-quiet.png` |

### 19. Wordmark direction "Pofu" (exploration only)

- **Chat:** Pofu · Icon & logo. **Template:** Logo. **Attach:** R1.

```text
Six lettering explorations of the word "Pofu" (exactly these four letters:
capital P, lowercase o, f, u) for a mobile app's wordmark, arranged in a
2x3 grid on a plain cream background (#FFF6EC), each in dark plum ink
(#2A1F2D). Chunky, soft, rounded letterforms, friendly and warm, matching
the attached mascot's personality. In some versions, the top of the "f"
curls into a small swirl like the mascot's signature curl of fur; in one,
the "o" is a soft round shape with a tiny blush; keep the others purely
typographic. Flat vector-like shapes, no texture, no 3D, no shadows, no
other words, no taglines. PNG, 1536 x 1024.
```

Treat the result as a mood board: image models misspell and wobble. The
real wordmark is drawn by hand in vector from Baloo 2 ExtraBold (see the
design language) and becomes the trademark filing.

### 20. Home look-and-feel exploration (optional, inspiration only)

**Inspiration only.** The real UI stays native SwiftUI, SF Symbols, and
Liquid Glass per the [design language](../archive/design-language.md); nothing in
these mockups is traced or shipped, and any text in them is placeholder.
Use it to react to art direction, not layout.

- **Template:** Uygulama taslağı (App mockup). **Attach:** R1 and the day
  plate (6). **Output:** 1536 × 1024.

```text
Three iPhone home screen mockups side by side for a calm wellbeing app
whose mascot is the attached hamster character, exploring three radically
different art directions for the same screen (the companion, today's
energy, and one main button):
1 "Storybook window": the attached meadow painting fills the whole screen
edge to edge, the hamster stands in the center clearing, and only a few
frosted-glass floating controls sit at the top and bottom.
2 "Cozy burrow": the inside of the hamster's warm round burrow, soft cream
walls and a round window, the hamster on a little cushion, warm cream
cards for information.
3 "Paper journal": a clean cream paper page with the hamster as a large
die-cut sticker, generous white space, bold rounded typography and a
single violet (#6C4FD8) button.
Modern iOS 26 look with Liquid Glass bars, soft rounded shapes, painterly
illustration only for the world and the character, simple native-looking
controls. The hamster must match the attached reference exactly.
```

---

## P2: later

### 21. More badges

Use the 16a medallion and the 16b/16c edit prompt with these motifs, or
explore new families as 2 × 2 sets with the Simge template:

- 3-day streak: `a tiny green sprout with two leaves`
- 30-day streak: `a tall sunflower in full bloom`
- 100-day streak: `a small field of sunflowers under a soft sun`
- First focus session: `the attached character meditating calmly on a large leaf`
- Bedtime kept: `the attached character asleep in half a walnut shell under a tiny crescent moon`
- First walk: `a gentle winding path of sunflower seeds across a small green hill`
- Friend approval: `two small hamster paw prints side by side inside a soft heart shape`

### 22. Stickers: tea glass and simit

Use prompt 9 with the object line replaced:

- `a Turkish tea glass (ince belli bardak) on a tiny saucer, amber tea, a soft highlight`
- `a simit, a round sesame bread ring, golden brown with sesame seeds`

### 23. Collectible species in Pofu's style

Later collectibles (bunny, kitten, chinchilla from the
[species lineup](../brand/assets/concepts/species-lineup-gpt-image.jpg)) are generated as
edits of R1 so they share its anatomy and style: _"Edit the attached
character into a [species] friend of Pofu: keep the exact same body
shape, size, eyes, blush, paws, feet, art style and lighting; change only
the ears, the fur colors to [colors], and add [species trait]."_ They get
their own palette lock before production.

### 24. Merch mockups

**Template:** Promosyon ürünleri. Attach R1 and the chosen icon; explore
plush toys, stickers, tote bags, and mugs. For the record only, until the
trademark is filed.

---

## P2 sprite sheets (only if procedural motion falls short)

The motion system already blinks, breathes, squashes, hops, and fills the
cheeks procedurally. The sheets below are ready in case a moment looks fake
on the iPhone, and for small sizes (widgets, list rows) where a few drawn
frames read better than shaders.

### Shared rules for sheets 4 and 11–13

Sprite sheets are drawn in one image because frames drawn together drift
less than frames drawn one by one. Know the limit: a 4 × 4 sheet at
1024 × 1024 gives 256 px cells, enough for about 85 pt on screen at @3x.
Use them for celebrations, stickers, and widgets; for hero-size moments,
generate the key poses as single 1024 px edits (section 3) and let code do
the in-betweens.

**Shared sheet block** (append to 11–13):

```text
Every cell contains the same character, identical in size and scale, front
view, centered horizontally, with its feet on the same invisible ground
line near the bottom of the cell unless the frame description says the
feet leave the ground. Equal cells, clear empty transparent gutters
between cells, no overlap between cells, no motion blur, no speed lines,
no numbers, no text, no grid lines, no ground shadow.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge. Pastel warm palette of cream,
golden peach and blush pink with dark espresso-brown eyes. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.

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

AVOID: outlines, 3D plastic render, anime sparkle eyes, extra limbs, extra
toes, claws, teeth, lilac or gray fur, a floor, a cast shadow, motion
blur, a white sticker border, text, frame numbers, watermarks.
```

### 4. Blink sprite sheet (3 × 3)

- **Chat:** Pofu · Animation. **Attach:** R1 and 3a (eyes closed).
- **Ask for:** transparent PNG, 1024 × 1024.

```text
Create a 3x3 sprite sheet for a short blink animation of the character in
the first attached image; the second attached image shows the fully closed
eyes. Nine frames, read left to right, top to bottom:
1 eyes fully open, 2 eyes fully open, 3 upper lids one third down,
4 lids two thirds down, 5 eyes fully closed, 6 eyes fully closed,
7 lids two thirds down, 8 lids one third down, 9 eyes fully open.
Only the eyelids change between frames. In every cell the character is
identical in size, scale, pose and position: front view, centered
horizontally, feet on the same invisible ground line near the bottom of
the cell. Equal cells, clear empty transparent gutters between cells, no
overlap between cells, no motion blur, no numbers, no text, no grid lines.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

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

AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, frame numbers, watermarks,
signatures, motion blur, film grain, paper texture, vignette.

Output: one image, transparent background PNG, 1024 x 1024, a 3x3 grid.
```

**Slice:**

```sh
python3 -I tools/assets/process_assets.py slice --sheet design/art/inbox/sheet__pofu-blink.png \
  --name pofu-blink --grid 3x3 --fps 24 --no-loop --out build/animations
```

A 3 × 3 sheet gives 341 px cells, enough for blinks up to about 110 pt
(widgets, list rows). At hero size the motion system blinks procedurally
with the lid plate, and 3a covers fully closed eyes.

### 11. Cheeks filling with energy (3 × 3)

- **Attach:** R1 and 3e (cheeks full). **Output:** transparent PNG,
  1024 × 1024.

```text
Create a 3x3 sprite sheet showing the character from the first attached
image gradually filling its cheek pouches with sunflower seeds, ending
exactly like the second attached image. Nine frames, read left to right,
top to bottom: 1 normal cheeks (like the first image), 2 to 8 the cheeks
grow rounder and wider step by step in even increments, the eyes slowly
squinting happier, 9 cheeks fully stuffed (like the second image). Only
the cheeks, eyes and blush change; the body, feet and pose stay identical.
```

Then append the shared sheet block. **Slice:**
`slice --sheet design/art/inbox/sheet__pofu-cheeks.png --name pofu-cheeks --grid 3x3 --fps 12 --no-loop --out build/animations`.
The app scrubs this sequence by energy earned instead of playing it.

### 12. Happy bounce in place (4 × 4)

- **Attach:** R1 and 3b (happy). **Output:** transparent PNG, 1024 × 1024.

```text
Create a 4x4 sprite sheet of a happy bounce in place for the character in
the first attached image, with the happy face of the second attached image.
Sixteen frames, read left to right, top to bottom, forming a smooth loop:
1-2 neutral happy pose; 3-4 squash down (body wider and shorter, eyes in
happy arcs); 5-7 stretch up (body taller and narrower, paws rising, the
tuft lagging behind); 8-9 overshoot slightly taller; 10-12 settle back
with a small squash; 13-16 return smoothly to the neutral happy pose.
The feet never leave the ground line in any frame: this is a bounce in
place; the body volume stays the same when squashing and stretching.
```

Append the shared sheet block. **Slice:**
`slice --sheet design/art/inbox/sheet__pofu-bounce.png --name pofu-bounce --grid 4x4 --fps 24 --out build/animations`
(default `--register feet`: perfectly planted).

### 13. Celebration hop (4 × 4)

- **Attach:** R1 and 3b. **Output:** transparent PNG, 1024 × 1024.

```text
Create a 4x4 sprite sheet of a joyful celebration hop for the character in
the first attached image, with the happy face of the second attached image.
Sixteen frames, read left to right, top to bottom: 1 happy stand;
2-3 anticipation squash; 4-5 launch, stretched tall, feet leaving the
ground; 6-9 in the air, body round, paws raised high, tuft and fur
flowing upward slightly, the highest point at frame 7; 10-11 falling,
slightly stretched; 12-13 landing squash, wide and short; 14-16 settle
back to the happy stand. In frames 4 to 11 the feet are above the ground
line, the height following a smooth arc; in all other frames they rest on
the same ground line.
```

Append the shared sheet block. **Slice with the drawn height kept:**
`slice --sheet design/art/inbox/sheet__pofu-hop.png --name pofu-hop --grid 4x4 --fps 24 --no-loop --register cell --out build/animations`.
If the arc looks uneven, slice with `--register feet` instead and let the
app animate the hop path with the `hop` spring: usually the better result.
