# ui__sheet-deckle

- **Approved:** 2026-11-06T16:37:13+00:00 from batch `batch-61-ui-kit-v3`, job `ui-sheet-deckle`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T15:57:10+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-sheet-deckle.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass every hard automated check and manual proper-alpha/two-tile junction review; normal lowest style-lock load selects take2 (0.4319 vs0.4545). Full-width blank cream paper strip, irregular lifted top edge and flat lowerpaper, no endcaps/text/icons/background. Unmodifiedhorizontal repeat previews show no visible gap/abrupt seam; half-alpha top edge diagnostic differs1AApixel forboth and bottoms agree, not a claim of exacttexelperiodicity or lead cap approval/appintegration. Both retain canonical canvas0.7072 warning: tool returned2172x724 panorama and officialpost normalized todeclared1536x1024, originalPNG/RGBA retained. Rawpreview fragments are hiddenRGB underalpha0 and absent from proper composites. Selected native lossless PNG158559B fits cap. Manualproof root-deckle-initial-manual-review.json, INITIAL2processingseal, orderedrefs/sourceordinals/QA/slice metadata unchanged. Required real complete172source canonical Harmony measure/check and exact foreign restoration; UIexcluded/no fabricated shard. No retry, force or profile edit. auto-picked by QA; founder review pending.

## References

- `design/art/ui/ui-sheet-paper-v3/ui-sheet-paper-v3.png`: The same cream paper and light: this strip is its top edge. Match the color of the paper exactly.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 73cf8532cff8dfe8)

```text
REFERENCES (attached, in this order):
1. The same cream paper and light: this strip is its top edge. Match the color of the paper exactly.
2. The palette card for props: use only these colors (and mixes of them).

A single horizontal strip about twelve times as wide as it is tall, centered on a transparent background and spanning the full canvas width: the top edge of a sheet of cream paper. The upper edge is a soft, irregular deckled edge with a thin lighter lifted lip, the lower half is solid flat cream paper. The strip repeats seamlessly: the left and right ends are the same edge at the same height.

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
- warn: canvas (2172x724 scaled x0.707 into 1536x1024 (aspect off by 100%, padded); source smaller than the canvas (upscaled))
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 84 (R1 59))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: palette_drift (mean dE 0.6, p95 0.9, off-palette 0.0%)
