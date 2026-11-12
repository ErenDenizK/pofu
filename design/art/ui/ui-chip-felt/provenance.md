# ui__chip-felt

- **Approved:** 2026-11-09T22:08:44+00:00 from batch `batch-61-ui-kit-v3`, job `ui-chip-felt`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T22:00:22+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-chip-felt.png` is the locked master the app and later edits use.
- **Review note:** Both takes pass. Manual review confirms a blank warm-sand capsule with cream stitching and no icon or text. Take 2 wins on official lock load 0.3119 versus 0.3268. Shape appears about 3.2:1 versus the brief’s approximate 5:1; no slice-fit or app integration claim.

## References

- `design/art/ui/ui-plaque-quiet/ui-plaque-quiet.png`: The family: the quiet felt strip. This chip is smaller, rounder and a bit thicker, with a visible sewn edge.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 4a79797d37683eb0)

```text
REFERENCES (attached, in this order):
1. The family: the quiet felt strip. This chip is smaller, rounder and a bit thicker, with a visible sewn edge.
2. The palette card for props: use only these colors (and mixes of them).

One wide felt chip, blank: a capsule about five times as wide as it is tall, filling the canvas width and centered, soft warm sand felt (#F0E1C8) with a fine row of tiny cream stitches just inside the rim, a slight felt thickness at the edge and a soft shadow beneath. The middle is flat and even.

CRAFTED FACE: a painted surface for a control that the app slices and
stretches (the crafted skin of the Home A/B, ADR-0018 timing amendment).
Paint only the material, never the control's content: no text, no letters,
no numbers, no symbols, no icons, no glass, no frosted or transparent
parts. The face is lit from straight above, so the centre is perfectly flat
and even from left to right and top to bottom of its middle (no gradient
that would stretch badly, no spots, no texture that varies along the
width). Every rounded edge, lip and shadow sits inside the outer margin
that the slice caps will hold; the middle is a plain, calm area. A clean
silhouette on a transparent background, centered, with no ground shadow,
no cast shadow, no outline and no border. Material is matte-to-soft-gloss
clay glaze or paper, painted in the same soft, milky, high-key picture-book
style as the world's props.

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

AVOID: text, letters, numbers, symbols, icons, glass, frosted or transparent parts, a drop shadow or cast shadow on the ground, an outline, a border around the canvas, a background, gloss or specular glints, texture that varies along the width, pure black, neon or saturated colors, a 3D render look

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 22 (R1 51))
- pass: value_floor (lightness p5 83 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.5, p95 1.1, off-palette 0.0%)
