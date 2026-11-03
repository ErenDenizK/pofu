# ui__game-bloom-front

- **Approved:** 2026-11-03T00:43:58+00:00 from batch `batch-12-minigame-art`, job `game-bloom-front`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:42:47+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-bloom-front.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Automated QA has non-failing chroma warnings on both takes. Manual content review excludes take1: the three dark arcs read as a smiling face rather than seed-swirl marks. Take2 has a plain brown centre with seed-swirl marks, plump petals, the required upper-right gap, and no stem/leaves. Four-background alpha composites and native44pt review pass. Take2 is the lowest-load complete-QA eligible take,0.5564; warning retained.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 8adb5d2d8893171f)

```text
REFERENCES (attached, in this order):
1. The family look of the game's pieces: same softness, same light, same finish. Do not draw this tile.
2. The palette card for props.

A single sunflower head seen straight on, filling most of the
canvas: a round, soft brown center with a few simple darker
seed-swirl marks, ringed by plump rounded petals of warm
sunflower yellow, with one small gap between two petals at the
upper right. No stem, no leaves.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

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

AVOID: glossy or metallic shine, specular glints, reflections, hammered
or dimpled metal, wood grain, fine surface texture, photorealism, a 3D
render look, plastic or vinyl, high contrast, black or near-black
shadows, saturated or neon colors, outlines, cel shading, text, letters,
numbers, logos, watermarks, characters or animals, a floor, a background,
a ground shadow.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 60 (R1 51))
- pass: value_floor (lightness p5 49 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: palette_drift (mean dE 1.8, p95 5.2, off-palette 0.0%)
