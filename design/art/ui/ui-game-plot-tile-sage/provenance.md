# ui__game-plot-tile-sage

- **Approved:** 2026-11-03T00:23:16+00:00 from batch `batch-12-minigame-art`, job `game-plot-tile-sage`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:20:23+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-plot-tile-sage.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass automated QA with non-failing palette warnings. Four-background alpha composites are clean; rounded sage clay tile, top highlight, darker lip and two-leaf sprout relief read at native41pt on cream/dark backgrounds. Take1 has lowest non-failing lock load0.2978 versus0.3039. Pilot visual review passed; no check waived.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: Style reference for objects: how a prop is painted in this world.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 495d8dfd87cbe707)

```text
REFERENCES (attached, in this order):
1. Style reference for objects: how a prop is painted in this world.
2. The palette card for props.

One square tile of glazed clay seen from straight above with a
very slight tilt, rounded corners, filling most of the canvas: a
soft sage-green matte-to-soft-gloss glaze, a soft cream highlight
along the top edge, a slightly darker rounded lip along the other
edges, and in the middle a small, simple sprout (two round leaves
on a short stem) pressed into the clay in the same glaze, only a
little lighter than the tile.

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
- pass: chroma_ceiling (chroma p95 20 (R1 51))
- pass: value_floor (lightness p5 68 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- warn: palette_drift (mean dE 2.6, p95 4.0, off-palette 0.0%)
