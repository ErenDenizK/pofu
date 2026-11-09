# ui__bubble-tail

- **Approved:** 2026-11-09T21:58:46+00:00 from batch `batch-61-ui-kit-v3`, job `ui-bubble-tail`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:49:50+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-bubble-tail.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass all hard checks. Proper-alpha cream and dark composites show no broad halo or painted background; the apparent raw-view glow is hidden RGB at alpha 0, with only a tiny soft edge shadow. Three cream-paper tails have open flat top edges and lean left/down/right. Take 2 wins on normal lowest lock load (0.3167 versus 0.3508). Source pixels, prompt, ordered references, and authored manifest remain unchanged; app integration and exact slice fit are not claimed.

## References

- `design/art/ui/ui-bubble-paper/ui-bubble-paper.png`: The bubble body the tails attach to: the same paper color, cocoa edge and light.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint f915fdd978fe5411)

```text
REFERENCES (attached, in this order):
1. The bubble body the tails attach to: the same paper color, cocoa edge and light.
2. The palette card for props: use only these colors (and mixes of them).

A sheet of three small speech-bubble tails on a transparent background, in a row of three with wide empty space between them, each centered in its third: warm cream paper (#FFF7E8) with a thin soft cocoa-brown edge on the two long sides only, the flat top edge open and edgeless so it can join a bubble. The first tail leans to the lower left, the second points straight down, the third leans to the lower right. Soft curved wedge shapes, a little shadow beneath each.

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
- pass: chroma_ceiling (chroma p95 23 (R1 51))
- pass: value_floor (lightness p5 67 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.4, p95 1.0, off-palette 0.0%)
