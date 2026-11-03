# ui__game-soil-cell

- **Approved:** 2026-11-03T00:29:22+00:00 from batch `batch-12-minigame-art`, job `game-soil-cell`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:23:44+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-soil-cell.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass automated QA. Four-background composites and native41pt side-by-side comparison with sage pass: warm matte soil, two round crumbs, darker rim and a clearly darker plain cell. Median L is46.3/42.0 versus sage76.4. Take1 has the lowest passing lock load1.6128 versus2.1344. Full palette/value checks pass.

## References

- `design/art/stations/cay-1/cay-1.png`: Style reference for objects: how a prop is painted in this world.
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint bace2983c22db22f)

```text
REFERENCES (attached, in this order):
1. Style reference for objects: how a prop is painted in this world.
2. The palette card for props.

One square tile-sized cell of soft brown garden soil seen from
straight above with a very slight tilt, rounded corners, filling
most of the canvas: a gently mounded surface of dark warm brown,
two tiny round crumbs on it, a slightly darker rim. Matte and
calm; clearly darker and duller than a glazed clay tile.

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
- pass: chroma_ceiling (chroma p95 31 (R1 51))
- pass: value_floor (lightness p5 38 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.6)
- pass: palette_drift (mean dE 0.9, p95 1.4, off-palette 0.0%)
