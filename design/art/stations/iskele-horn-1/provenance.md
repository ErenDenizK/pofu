# station__iskele-horn-1

- **Approved:** 2026-11-03T13:53:57+00:00 from batch `retry-2026-11-03`, job `iskele-horn-1`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:48:22+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 34, "dy": -35}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `iskele-horn-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes show a brass-colored horn pointing right on a chunky honey-wood post and round stone foot, with a cream pull cord and round wooden toggle. No text, guide, ground shadow or new dependency on the failed ferry. All automated checks pass; t1 has the lowest lock load0.5229 versus0.5468.

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/cay-1/cay-1.png`: The approved tea stall: match its painting, light, colors, finish and scale exactly (do not draw the stall).
- `design/art/masters/iskele-island-s/iskele-island-s.png`: The harbor island: its coral, cream and sea-blue colors and its light (do not draw the island).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint c406f026e69facaa)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its painting, light, colors, finish and scale exactly (do not draw the stall).
3. The harbor island: its coral, cream and sea-blue colors and its light (do not draw the island).
4. The palette card for props: use only these colors (and mixes of them).

A small harbor signal post for the island diorama: a short, chunky
post of honey wood on a round stone foot, a plump brass-colored
horn pointing out to the right on top, and a thick cream cord with
a round wooden toggle hanging straight down from the horn. Few
parts, toy-like proportions; it fills about the lower half of the
height bar.

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
- pass: value_floor (lightness p5 60 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.3, p95 3.7, off-palette 0.0%)
- pass: station_anchor (on the anchor)
- pass: harmony (harmony score 79 against the world reference (outliers: L_p98, edge))
