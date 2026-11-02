# char__findik-base

- **Approved:** 2026-11-02T14:52:22+00:00 from batch `batch-03-home-island`, job `findik`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:51:33+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `findik-base.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
- `design/art/masters/mochi-v2/mochi-v2.png`: Mochi, a neighbor: Fındık stands next to her, so match her size on the canvas, her eyes and her finish (do not draw her).
- `design/reference/palette-card-character.png`: The character palette card.

## Prompt (fingerprint 7511002ce010ecc6)

```text
REFERENCES (attached, in this order):
1. The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
2. Mochi, a neighbor: Fındık stands next to her, so match her size on the canvas, her eyes and her finish (do not draw her).
3. The character palette card.

Draw Fındık, a neighbor of the attached hamster, in exactly the
same art style, lighting and level of fluff as the hamster and the
attached bunny. Same canvas rules as the hamster: full body,
sitting upright, front view, centered, feet on an invisible line
at 88% of the height, about 62% of the canvas width.
CHARACTER: Fındık, a baby hedgehog whose body is a soft round
ball. The back, the top and the sides of the head are covered in a
thick coat of soft, rounded quills in warm hazelnut brown with
cream tips, painted as short, soft tufts like a plush toy, never
sharp; the quills frame the face like a hood and stop at a
smooth, clean line around it. A creamy beige face, chest and
belly. A small, softly pointed snout with a tiny round cocoa-brown
nose and a small smiling "w" mouth. Big round glossy dark
espresso eyes with one large round catchlight and one tiny
sparkle each, soft blush ovals on the cheeks, two small round ears
with pink insides peeking out of the quills, two tiny cream front
paws together at the chest, two small feet peeking out; three
small toe creases on each paw and foot. No curl or swirl of fur on
top of the head (that belongs to Pofu alone). No clothes, no
accessories.

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

AVOID: sharp, spiky or wiry quills, a curl or swirl on top of the head, glasses, a hat, tools.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 49 (R1 51))
- warn: value_floor (lightness p5 44 (R1 59))
- pass: detail_budget (detail at display size 6.7 (R1 5.3))
- warn: palette_drift (mean dE 3.0, p95 12.9, off-palette 6.7% (top: #AA5533 (1.3%), #995522 (0.9%)))
- pass: ground_line (feet at 89.6% of the height (contract 88%))

Master downscaled from 1024x1536 to 870x1306 to meet the 600 KB upload cap; saved lossless WebP (598484 bytes).
