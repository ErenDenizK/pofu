# ui__menu-paper

- **Approved:** 2026-11-03T15:20:47+00:00 from batch `retry-2026-11-03`, job `ui-menu-paper`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T14:07:53+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-menu-paper.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Resume from the fixed pre-stop original candidate, with zero image generation. Re-posted both retained PNGs under main9ede62e; both locked RGBA rasters match their retained versions exactly and the same eligible take remains lowest lock load. Fresh light/dark small-size visual review reconfirms the choice. Both takes are small landscape cream cards, differing from the tall sheet reference, with four rounded corners, inset warm-brown stitches, a faint darker paper edge and an unmarked plain even cream centre. Edge details fit the 20 pt shipping caps. Both pass every automated check; t1 has lower lock load 0.2786 versus 0.2859.

## References

- `design/art/ui/ui-sheet-paper/ui-sheet-paper.png`: The family look of the paper surfaces: the same cream paper, stitches and lights. Do not copy its shape.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 69c53f1a50d57e26)

```text
REFERENCES (attached, in this order):
1. The family look of the paper surfaces: the same cream paper, stitches and lights. Do not copy its shape.
2. The palette card for props.

A small cream paper card with four softly rounded corners, a thin
row of small, even, warm-brown stitches just inside its edge all
the way around, and a faint darker paper edge. The middle is plain,
flat, even cream paper, tileable. Seen straight on. Nothing
written on it.

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

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 16 (R1 51))
- pass: value_floor (lightness p5 86 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.5, p95 0.9, off-palette 0.0%)
