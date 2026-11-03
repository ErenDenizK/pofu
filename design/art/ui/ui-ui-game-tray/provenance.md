# ui__ui-game-tray

- **Approved:** 2026-11-03T01:17:18+00:00 from batch `batch-12-minigame-art`, job `ui-game-tray`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T01:06:52+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-ui-game-tray.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass manual review: honey-wood tray with plain raised rim, no handles and a calm flat unmarked floor without directional grain. Unchanged24/32/24/32pt caps hold the edges at138pt content height and240/360pt widths on cream/dark; review-only content-bounds projection is documented. Take2 has lowest passing lock load0.3562 versus0.3563. Canonical master is not cropped or resized.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint b4429f0aab17422e)

```text
REFERENCES (attached, in this order):
1. The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
2. The palette card for props.

A wide wooden serving tray seen from above with a slight tilt:
soft honey wood, a low rounded raised rim all round (a plain rim,
no handles), a perfectly even flat wooden floor inside with no grain
pattern that varies across its width.

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
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- pass: value_floor (lightness p5 66 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: palette_drift (mean dE 1.2, p95 3.1, off-palette 0.0%)
