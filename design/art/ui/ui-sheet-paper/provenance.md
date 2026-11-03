# ui__sheet-paper

- **Approved:** 2026-11-03T14:03:03+00:00 from batch `retry-2026-11-03`, job `ui-sheet-paper`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:55:12+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-sheet-paper.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes are inset cream cards with rounded top and bottom corners, a lighter top paper lip, stitches just inside the whole edge, and an unmarked calm cream centre. Rounded edges and stitching remain in the shipping slice caps. The revised brief permits an inset bottom; no obsolete off-canvas gate applied.

## References

- `design/art/ui/ui-jar-empty/ui-jar-empty.png`: The material: the same milky cream glaze and warm lights.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 702e521dbf3db862)

```text
REFERENCES (attached, in this order):
1. The material: the same milky cream glaze and warm lights.
2. The palette card for props.

A tall sheet of cream paper seen straight on, centered with a
small margin of empty canvas all round: its top corners softly
rounded with a thin lighter paper lip along the top, its bottom
corners also softly rounded, a faint darker paper edge just outside
a thin row of small, even, warm-brown stitches running just inside
the whole edge. The middle is plain, flat, even cream paper with
no stains and no texture variation. Nothing written on it.

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
- pass: chroma_ceiling (chroma p95 18 (R1 51))
- pass: value_floor (lightness p5 87 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: palette_drift (mean dE 0.4, p95 0.7, off-palette 0.0%)
