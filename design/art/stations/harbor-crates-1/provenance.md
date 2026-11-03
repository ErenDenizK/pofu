# station__harbor-crates-1

- **Approved:** 2026-11-03T14:00:40+00:00 from batch `retry-2026-11-03`, job `harbor-crates-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:21+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 17, "dy": -46}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `harbor-crates-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes contain two rounded honey-wood crates, one tied cream sack with coral cord and one kraft parcel with cream string. No labels, lettering, guide or cast shadow. Both pass all automated checks. Select t2 by lower lock load 0.6081 versus 0.7289.

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, light, colors, finish and scale exactly (do not draw the stall).
- `design/art/masters/harbor-island-s/harbor-island-s.png`: The harbor island: its coral, cream and sea-blue colors and its light (do not draw the island).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 04a0ba32e5311834)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its painting, light, colors, finish and scale exactly (do not draw the stall).
3. The harbor island: its coral, cream and sea-blue colors and its light (do not draw the island).
4. The palette card for props: use only these colors (and mixes of them).

A small stack of cargo for the island diorama: two plump honey-wood
crates and one round cream sack tied with a coral cord, with a
small parcel wrapped in kraft paper and cream string on top. Chunky,
toy-like, rounded corners, no labels, no letters. It fills about
the lower half of the height bar.

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
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- pass: value_floor (lightness p5 64 (R1 59))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.7, off-palette 0.0%)
- pass: station_anchor (on the anchor)
- pass: harmony (harmony score 82 against the world reference (outliers: edge))
