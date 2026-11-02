# station__garden-1

- **Approved:** 2026-11-02T14:36:50+00:00 from batch `batch-01-slice`, job `garden-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:36:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -11, "dy": 15}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `garden-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/cay-1/cay-1.png`: P-station, the approved tea stall: match its style, camera, light and colors exactly (do not draw the stall).
- `design/art/masters/island-main-s/island-main-s.png`: The island this garden stands on: same camera and softness.

## Prompt (fingerprint e63f1d3ceadd2835)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. P-station, the approved tea stall: match its style, camera, light and colors exactly (do not draw the stall).
3. The island this garden stands on: same camera and softness.

A small oval garden bed of soft brown soil with three plump,
cheerful sunflowers of slightly different heights, for the same
island diorama. Big, round, simple honey-yellow petals around warm
brown centers, two soft leaves on each stem, thick stems. Room on
the bed for more flowers later.

VIEW: the same fixed front three-quarter view as the attached island: a
low camera about 20 degrees above the horizon, so you see the front of
the object fully and only a narrow sliver of its top (a round tabletop
reads as a flat oval about a third as tall as it is wide). Follow the
attached guide exactly: the object stands on the magenta ground ellipse,
centered on the magenta cross, its front edge on the front of the
ellipse, no taller than the magenta height bar. Then remove the guide
completely: no ellipse, no cross, no bar, no magenta, no grid may remain
in the output.

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
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- pass: value_floor (lightness p5 57 (R1 59))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- warn: lock_load (the lock moved colors by mean dE 12.5 (prefer a take that needs less))
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.7, p95 5.0, off-palette 0.2% (top: #888866 (0.1%), #998866 (0.1%)))
- warn: station_anchor (width 863 px wider than the footprint (720))
