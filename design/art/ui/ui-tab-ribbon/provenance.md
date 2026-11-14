# ui__tab-ribbon

- **Approved:** 2026-11-12T11:35:52+00:00 from batch `batch-61-ui-kit-v3`, job `ui-tab-ribbon`, take t3
  of 1 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** retained-lead-pick;
  generated unknown.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-tab-ribbon.png` is the locked master delivered at 0.75 scale under QUEUE.md row 0-h4 the app and later edits use.
- **Review note:** Lead picked retained take 3 in QUEUE.md row 0-h4 / batch-77; promote --force authorized. Original PNG unavailable; decoded retained q90 WebP. Auto-picked by QA; founder review pending.

## References

- `design/art/ui/ui-bubble-paper/ui-bubble-paper.png`: The bubble the tab sits on: match the light, softness and warmth.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint e09ea5a2dc52eae0)

```text
REFERENCES (attached, in this order):
1. The bubble the tab sits on: match the light, softness and warmth.
2. The palette card for props: use only these colors (and mixes of them).

A sheet of five identical satin ribbon tabs on a transparent background, stacked in five rows with wide empty space between them, each a wide strip about seven times as wide as it is tall, with a small V notch cut into the left end and a softly rounded right end, a thin lighter edge on top and a soft shadow beneath. The five differ only in color, top to bottom: honey gold, rose pink, sage green, sky blue, soft lilac. The middle of each is perfectly flat and even.

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
- pass: chroma_ceiling (chroma p95 38 (R1 51))
- pass: value_floor (lightness p5 68 (R1 59))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: palette_drift (mean dE 2.4, p95 6.1, off-palette 0.5% (top: #AA88AA (0.3%), #AA99AA (0.2%)))
