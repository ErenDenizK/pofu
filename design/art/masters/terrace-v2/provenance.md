# world__terrace-v2

- **Approved:** 2026-11-02T14:52:22+00:00 from batch `batch-03-home-island`, job `terrace-v2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:51:42+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `terrace-v2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-l-v2/island-main-l-v2.png`: The large island: match its style, colors, light, camera and scale exactly. Do not redraw it.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 081096b62702524d)

```text
REFERENCES (attached, in this order):
1. The large island: match its style, colors, light, camera and scale exactly. Do not redraw it.
2. The palette card: use only these colors (and mixes of them).

For the attached island, draw only a raised grassy terrace that
will sit on the back half of its lawn: a soft oval lawn about 75%
of the island's width, at the same scale as the attached island
and placed where it would sit on it, lifted on a low earthen step
with the same strata and colors, and a short flight of four cream
stone steps on its front left. The terrace lawn is empty. Nothing
else: not the island itself, no characters, no objects.

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

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 18 (R1 51))
- pass: value_floor (lightness p5 73 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 5.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.3, p95 4.6, off-palette 0.0%)
- pass: lawn_chroma (lawn chroma p95 15 (palette meadow 38))
