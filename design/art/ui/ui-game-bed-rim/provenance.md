# ui__game-bed-rim

- **Approved:** 2026-11-03T00:51:42+00:00 from batch `batch-12-minigame-art`, job `game-bed-rim`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:47:32+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-game-bed-rim.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass automated QA. Manual 9-slice review with unchanged28pt caps at180pt content height excludes take1: its border invades10.99% of the central tile. Take2 keeps the centre visibly transparent (no alpha>16 in the central tile; max3 edge antialiasing), with even peach-stone border and corners held in the caps at180/260pt widths on cream/dark. Review uses alpha content-bounds projection only; master canvas/pixels stay canonical and unchanged. Eligible take2 lock load0.8543; take1 excluded regardless of lower load0.5303.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 86b4e0b2cf79ccf7)

```text
REFERENCES (attached, in this order):
1. The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
2. The palette card for props.

A square frame of chunky, rounded peach-colored clay stones set
side by side, seen from straight above with a slight tilt, a soft
cream highlight on the top edge of each stone, a slightly darker
rounded lip. The frame is a border of equal width on all four
sides; the whole inside of the frame is empty and transparent (a
hole), and the stones near each corner are a rounded corner.

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
- pass: chroma_ceiling (chroma p95 37 (R1 51))
- pass: value_floor (lightness p5 62 (R1 59))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.9)
- pass: palette_drift (mean dE 0.6, p95 1.2, off-palette 0.0%)
