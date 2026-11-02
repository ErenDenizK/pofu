# world__islet-east

- **Approved:** 2026-11-02T14:52:22+00:00 from batch `batch-03-home-island`, job `islet-east`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:51:56+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `islet-east.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-l-v2/island-main-l-v2.png`: The large island: match its painting, colors, light, camera, lawn, strata, pebbles and roots exactly (do not draw it).
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 90d444c8776abdee)

```text
REFERENCES (attached, in this order):
1. The large island: match its painting, colors, light, camera, lawn, strata, pebbles and roots exactly (do not draw it).
2. The palette card: use only these colors (and mixes of them).

A small floating islet for the same diorama, as if it had drifted
close to the attached island: a soft oval lawn, completely empty,
with the same darker front lip; underneath, a shallow rounded
earth body of the same honey and caramel strata, no deeper than
30% of the islet's width, with three cream pebbles and two short
dangling roots. No door. Seen from the same low camera (the lawn
oval about 0.3 times as tall as it is wide). Centered, filling
about 65% of the canvas width, with a generous transparent
margin.

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

AVOID: characters, plants, trees or objects on the lawn, a door, water, sky, clouds, background, ground shadow, saturated grass, a cone-shaped underside, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 19 (R1 51))
- pass: value_floor (lightness p5 74 (R1 59))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 5.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 4.3, off-palette 0.0%)
- pass: lawn_chroma (lawn chroma p95 15 (palette meadow 38))
