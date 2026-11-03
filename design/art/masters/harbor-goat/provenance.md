# char__harbor-goat

- **Approved:** 2026-11-03T14:57:40+00:00 from batch `retry-2026-11-03`, job `harbor-goat`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `harbor-goat.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained pair re-posted under main9ede62e; no new image generation. Both takes depict a cream plush baby goat with a warm tan eye patch, tiny rounded horn buds, floppy ears, beard tuft and indignant expression. No head curl, sharp horns or rectangular pupils. Both pass every current automated check. The existing saved t1 remains the QA pick by Harmony97.6 versus95.6; characters have no lock-load check. The previous partial master remains untouched in its old worktree; this master is rebuilt from the retained original and current pipeline.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
- `design/art/masters/mochi-v2/mochi-v2.png`: Mochi, a neighbor: match her size on the canvas, her eyes and her finish (do not draw her).
- `design/reference/palette-card-character.png`: The character palette card.

## Prompt (fingerprint ff2a45afcaf6ec93)

```text
REFERENCES (attached, in this order):
1. The hamster, Pofu: match his art style, lighting, level of fluff and scale exactly (do not draw him).
2. Mochi, a neighbor: match her size on the canvas, her eyes and her finish (do not draw her).
3. The character palette card.

Draw a baby goat in exactly the same art style, lighting and level
of fluff as the attached hamster and bunny. Same canvas rules:
full body, sitting upright, front view, centered, feet on an
invisible line at 88% of the height, about 62% of the canvas width.
CHARACTER: a baby goat whose body is a soft round ball of cream
plush fur, a warm tan patch over one eye, two tiny rounded horn
buds, two soft floppy ears, a small beard tuft, big round glossy
dark espresso eyes with a catchlight each, and a very indignant
expression: the brows low, the small mouth pressed in a flat, soft
line, the chin lifted. Two small cream front paws at the chest.
No curl on top of the head.

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

AVOID: realistic goat anatomy, sharp horns, rectangular pupils, a hat, text, a ground shadow.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- pass: value_floor (lightness p5 65 (R1 59))
- pass: detail_budget (detail at display size 3.3 (R1 5.3))
- pass: palette_drift (mean dE 0.9, p95 2.9, off-palette 0.6% (top: #662211 (0.1%), #441100 (0.0%)))
- pass: ground_line (feet at 89.3% of the height (contract 88%))
- pass: harmony (harmony score 98 against the char reference (outliers: none))
