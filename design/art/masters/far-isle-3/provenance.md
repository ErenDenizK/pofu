# world__far-isle-3

- **Approved:** 2026-11-02T15:01:11+00:00 from batch `batch-04-sky`, job `far-isle-3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:58:42+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `far-isle-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/far-isle-1/far-isle-1.png`: The approved distant island: the silhouette family's look. Match its haze, values, colors and softness exactly (do not copy its shape).
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only (no characters): the hamster's soft airbrushed painting.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 1e420e695c88c1fb)

```text
REFERENCES (attached, in this order):
1. The approved distant island: the silhouette family's look. Match its haze, values, colors and softness exactly (do not copy its shape).
2. Style reference only (no characters): the hamster's soft airbrushed painting.
3. The palette card: use only these colors (and mixes of them).

A third distant view for the same hazy far layer, on its own: two
tiny floating islets side by side with a gap between them, the
right one smaller and a little higher, flat tops without trees,
soft rounded undersides, almost silhouettes in the same pale, hazy
sky-blue and cream. Centered, together filling about 75% of the
image width, with a clear transparent margin.

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

AVOID: saturated green grass, dark shadows, buildings, characters, water, clouds, a bridge, a sky or background color, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 12 (R1 51))
- pass: value_floor (lightness p5 84 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 2.9, off-palette 0.0%)
- pass: lawn_chroma (lawn chroma p95 12 (palette meadow 38))
