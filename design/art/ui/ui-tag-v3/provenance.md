# ui__tag-v3

- **Approved:** 2026-11-09T22:08:49+00:00 from batch `batch-61-ui-kit-v3`, job `ui-tag-v3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T22:00:44+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-tag-v3.png` is the locked master the app and later edits use.
- **Review note:** Take 1 is QA warn only for canvas; take 2 passes automated QA but is manually excluded because its left hole reads filled and its extra stitches conflict with the requested inventory. Take 1 visually has the blank tag, punched left hole with brown loop, and clipped right corners. Pick take 1; disclose canvas warning.

## References

- `design/art/ui/ui-card-stitched/ui-card-stitched.png`: The family: the same cream paper, rim and light.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 33a7bd3c53d51527)

```text
REFERENCES (attached, in this order):
1. The family: the same cream paper, rim and light.
2. The palette card for props: use only these colors (and mixes of them).

One blank paper luggage tag lying flat and seen straight on, a wide strip about five times as wide as it is tall, filling the canvas width and centered: warm cream paper (#FBF1DE), the left end rounded with a small punched hole, a reinforcing ring around it and a short loop of brown string, the right end with two clipped corners, a thin darker paper edge and a soft shadow beneath. The middle is flat and even.

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
- pass: chroma_ceiling (chroma p95 24 (R1 51))
- pass: value_floor (lightness p5 82 (R1 59))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.5, p95 0.9, off-palette 0.0% (top: #774411 (0.0%)))
