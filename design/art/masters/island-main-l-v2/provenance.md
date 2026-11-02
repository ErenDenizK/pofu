# world__island-main-l-v2

- **Approved:** 2026-11-02T14:36:22+00:00 from batch `batch-03-home-island`, job `island-main-l-v2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:35:47+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `island-main-l-v2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-s/island-main-s.png`: The small island, approved: the same island before it grows. Match its painting, colors, light, camera, lawn, front lip, strata, door, pebbles and roots exactly.
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only (no characters): the hamster's soft painting, light and pastel colors.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint a911cdfdf8ff754c)

```text
REFERENCES (attached, in this order):
1. The small island, approved: the same island before it grows. Match its painting, colors, light, camera, lawn, front lip, strata, door, pebbles and roots exactly.
2. Style reference only (no characters): the hamster's soft painting, light and pastel colors.
3. The palette card: use only these colors (and mixes of them).

Draw the large version of the attached floating island: the same
island after it has grown, for a cozy mobile game diorama.
- The lawn is about 40% wider, side to side, and about 15% deeper,
  front to back, than the attached island's: a longer, wider
  oval, still completely empty, at the same low camera (the oval
  about 0.3 times as tall as it is wide).
- To fit the canvas, the camera is a little farther away: the
  island fills about 94% of the image width, and the round door,
  its window, the pebbles and the roots are drawn at about 70% of
  their size in the attached image (the same real size on a
  bigger island). The door stays on the lower left of the earth
  body; add two or three more pebbles and one more root along the
  longer earth body.
- Relative to its own width, the earth body is a little shallower
  than in the attached image (about 17% of the island's width),
  because the island grew more in width than in depth: the same
  soft, rounded underside, never a cone.
- The same soft, muted sage lawn painted as a smooth velvety
  surface, the same darker front lip with a hint of short grass,
  the same light honey and caramel earth with gentle strata.

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

AVOID: characters, plants or objects on the lawn, water, sky, clouds, background, ground shadow, saturated or yellow-green grass, a deep cone-shaped underside, a door as large as in the attached image, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 71 (R1 59))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 7.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 4.4, off-palette 0.0%)
- pass: depth_ratio (earth depth / width 0.17 (target <= 0.30))
- pass: lawn_chroma (lawn chroma p95 19 (palette meadow 38))
