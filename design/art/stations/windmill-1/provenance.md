# station__windmill-1

- **Approved:** 2026-11-02T14:35:53+00:00 from batch `batch-03-home-island`, job `windmill-1`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:35:35+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -15, "dy": -25}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `windmill-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: P-station, the approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
- `design/art/masters/island-main-s/island-main-s.png`: The island this station stands on: same camera and softness.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 53f0a54407351207)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. P-station, the approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
3. The island this station stands on: same camera and softness.
4. The palette card for props: use only these colors (and mixes of them).

A small, stout windmill for the island diorama: a round, gently
tapering tower of soft cream and pale honey stones painted as
broad, smooth shapes (no mortar lines), a small round wooden door
at its base, a rounded cap of caramel wood on top, and four bare
sail frames on the front of the cap arranged as an X, each sail a
simple ladder of a few broad wooden slats, no cloth yet. Friendly,
toy-like proportions with few parts. The tower stands on the
center of the ground ellipse and is about a third of its width;
the top sail tip stays below the top of the height bar and
nothing touches the canvas edges. Leave a little room above the
cap for a small flag later.

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
- pass: chroma_ceiling (chroma p95 31 (R1 51))
- pass: value_floor (lightness p5 60 (R1 59))
- pass: detail_budget (detail at display size 2.2 (R1 5.3))
- warn: lock_load (the lock moved colors by mean dE 10.6 (prefer a take that needs less))
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.8, off-palette 0.0%)
- warn: station_anchor (top y 59 above the height bar (150))
