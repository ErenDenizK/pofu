# prop__sun-glow

- **Approved:** 2026-11-02T14:51:43+00:00 from batch `batch-04-sky`, job `sun-glow`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:49:42+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `sun-glow.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-s/island-main-s.png`: The island this sky belongs to: the same warm light and milky pastel values (do not draw it).
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 71b69bbf834ccfa1)

```text
REFERENCES (attached, in this order):
1. The island this sky belongs to: the same warm light and milky pastel values (do not draw it).
2. The palette card: use only these colors (and mixes of them).

A soft sun glow for a calm pastel morning sky, on its own: a
round, warm glow of pale honey and cream light, brightest and
almost cream-white in a small soft core at the center, fading
smoothly and evenly to fully transparent at its edge. No visible
disc edge, no face, no rays, no lens flare, no rings, no sparkle.
Centered, the glow fading out before it reaches the canvas edges.

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

AVOID: a sky or background color, clouds, a hard sun disc, rays, flares, rings, saturated yellow or orange, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 16 (R1 51))
- pass: value_floor (lightness p5 89 (R1 59))
- pass: detail_budget (detail at display size 0.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 5.2)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.8, off-palette 0.0%)
