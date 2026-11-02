# world__cloud-1

- **Approved:** 2026-11-02T14:17:54+00:00 from batch `batch-04-sky`, job `cloud-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:17:08+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `cloud-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-s/island-main-s.png`: The island this sky belongs to: match its soft painting, its warm light from the upper left and its milky pastel values (do not draw it).
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only (no characters): the hamster's soft airbrushed painting.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint f6d950180bce26ed)

```text
REFERENCES (attached, in this order):
1. The island this sky belongs to: match its soft painting, its warm light from the upper left and its milky pastel values (do not draw it).
2. Style reference only (no characters): the hamster's soft airbrushed painting.
3. The palette card: use only these colors (and mixes of them).

One large, soft cumulus cloud for a cozy pastel sky, on its own:
a wide, rounded cloud built from five or six big, plump billows,
with a gently flattened underside. Warm cream-white tops lit from
the upper left, undersides shaded in soft, pale sky blue with a
hint of warm cream bounce light, broad and smooth value changes.
The edges are soft but clean (a soft cutout, not a fading haze).
Centered, filling about 85% of the image width, with a clear
transparent margin.

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

AVOID: a sky, a background color or gradient, the sun, rays, birds, rain, gray or dark storm clouds, wispy noise, hard white outlines, a ground shadow, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 11 (R1 51))
- pass: value_floor (lightness p5 82 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 3.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.6, p95 4.7, off-palette 0.0%)
