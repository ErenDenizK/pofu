# char__simit-kitten

- **Approved:** 2026-11-03T13:46:53+00:00 from batch `retry-2026-11-03`, job `simit-kitten`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:45:45+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `simit-kitten.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes depict a honey tabby with coral neckerchief, soft small ears, upright plump tail, no head curl, and the same plush resident family. t1 ground-line WARN at 92.4% versus 88% retained without a waiver; t2 is 89.6%. Characters have no lock-load check, so the Harmony tie-break selects t1 (86.3 versus 84.8).

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
- `design/art/masters/mochi-v2/mochi-v2.png`: Mochi, a neighbor: match her size on the canvas, her eyes and her finish (do not draw her).
- `design/reference/palette-card-character.png`: The character palette card.

## Prompt (fingerprint d3a0b69f834ba4a6)

```text
REFERENCES (attached, in this order):
1. The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
2. Mochi, a neighbor: match her size on the canvas, her eyes and her finish (do not draw her).
3. The character palette card.

Draw Simit, a neighbor of the attached hamster, in exactly the same
art style, lighting and level of fluff as the hamster and the
attached bunny. Same canvas rules as the hamster: full body,
sitting upright, front view, centered, feet on an invisible line
at 88% of the height, about 62% of the canvas width.
CHARACTER: Simit, a baby tabby kitten whose body is a soft round
ball of plush fur in warm honey-gold with soft darker honey
stripes on the forehead, the cheeks and the tail, a cream muzzle,
chest and belly. Two small, softly rounded triangular ears with
pink insides. Big round glossy dark espresso eyes with one large
round catchlight and one tiny sparkle each, soft blush ovals, a
tiny rounded pink nose and a small smiling "w" mouth. A short,
plump tail curls up beside her. Two tiny cream front paws together
at the chest, two small feet peeking out. No curl or swirl of fur
on top of the head (that belongs to Pofu alone). A tiny coral
neckerchief. No other clothes or accessories.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, watermarks, signatures,
motion blur, film grain, paper texture, vignette.

AVOID: realistic cat anatomy, sharp ears or claws, a curl on top of the head, a hat, text, a ground shadow.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 55 (R1 51))
- pass: value_floor (lightness p5 58 (R1 59))
- pass: detail_budget (detail at display size 4.9 (R1 5.3))
- pass: palette_drift (mean dE 1.4, p95 3.9, off-palette 0.8% (top: #441100 (0.1%), #CC5533 (0.1%)))
- warn: ground_line (feet at 92.4% of the height (contract 88%))
- pass: harmony (harmony score 86 against the char reference (outliers: C_p95, detail))
