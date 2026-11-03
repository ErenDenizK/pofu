# ui__face-disc

- **Approved:** 2026-11-03T00:13:25+00:00 from batch `batch-11-ui-pilot`, job `ui-face-disc`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:11:38+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-face-disc.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass automated QA and manual material/shape review. Four-background alpha composites have clean circular silhouettes; centres are plain, flat and empty, with top highlight and bottom lip confined to the edge. Native44x44pt and52x52pt previews on cream/dark backgrounds are legible. Take1 is selected for lower passing lock load0.2268 versus0.2306. This disc is scaled, with no slice caps.

## References

- `design/art/ui/ui-jar-empty/ui-jar-empty.png`: The glaze: paint the disc in this same milky cream ceramic glaze.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 4c58baea4f90db7e)

```text
REFERENCES (attached, in this order):
1. The glaze: paint the disc in this same milky cream ceramic glaze.
2. The palette card for props.

A round, chunky disc of cream-glazed clay seen straight on, a
perfect circle filling most of the canvas, a soft lighter highlight
along the top edge and a slightly darker rounded lip along the
bottom edge, the middle flat and empty. Nothing on it.

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
- pass: chroma_ceiling (chroma p95 19 (R1 51))
- pass: value_floor (lightness p5 86 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.2)
- pass: palette_drift (mean dE 0.8, p95 1.1, off-palette 0.0%)
