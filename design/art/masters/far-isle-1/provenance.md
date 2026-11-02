# world__far-isle-1

- **Approved:** 2026-11-02T14:35:04+00:00 from batch `batch-04-sky`, job `far-isle-1`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:34:31+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `far-isle-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-s/island-main-s.png`: The home island: the distant islands are its far-away cousins. Match its silhouette language (flat lawn, rounded underside) and camera, but not its detail (do not draw it).
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 48dc38ea86e147f7)

```text
REFERENCES (attached, in this order):
1. The home island: the distant islands are its far-away cousins. Match its silhouette language (flat lawn, rounded underside) and camera, but not its detail (do not draw it).
2. The palette card: use only these colors (and mixes of them).

A distant floating island seen far away through soft morning
haze, on its own: a long, low island with a flat top and a soft,
rounded underside, and two tiny round trees on its top, at the
same low camera as the attached island. It is almost a
silhouette: painted in pale, hazy sky-blue and cream with only a
faint warmer tint on the top and a slightly lighter left side, low
contrast, no small details (no door, no pebbles, no roots, no
blades of grass). Centered, filling about 80% of the image width,
with a clear transparent margin.

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

AVOID: saturated green grass, dark shadows, buildings, characters, water, clouds, a sky or background color, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 17 (R1 51))
- pass: value_floor (lightness p5 79 (R1 59))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 4.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 3.6, off-palette 0.0%)
- pass: depth_ratio (earth depth / width 0.22 (target <= 0.30))
- pass: lawn_chroma (lawn chroma p95 17 (palette meadow 38))
