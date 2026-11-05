# prop__material-light

- **Approved:** 2026-11-05T23:43:39+00:00 from batch `batch-33-home-showcase`, job `material-light`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:25:44+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `material-light.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial sources and official locked takes preserve one small round jar, cream cloth lid tied with string, a soft pale-gold interior core with faint mint-green edge, and no glow outside the jar. Clean transparent margins, no text or ground. Widths 355/365 px reasonably match the approved 340 px material family; take2 has the lowest complete eligible lock load .5289 vs .5559. Hard QA passes; advisory light warnings remain visible. No additional generation, local fit or pixel changes.

## References

- `design/art/masters/material-moss/material-moss.png`: The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 3e2672ff519b44b5)

```text
REFERENCES (attached, in this order):
1. The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
2. The palette card for props: use only these colors (and mixes of them).

A single small painted object for a cozy game, a crafting material:
a small round glass jar with a cream cloth lid tied with string,
holding a soft pale-gold light with a faint mint-green edge, painted
as a warm soft core inside the jar (nothing glows outside the jar).
Same camera, size and finish as the attached moss. Centered on an
empty transparent background.

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

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- warn: light_values (day/subject: L p2 63 (at most 22), p98 92 (at least 90), spread 29 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.35 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.9 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 2.5, p95 6.4, off-palette 0.0% (top: #AA9966 (0.0%)))
- pass: harmony (harmony score 83 against the world reference (outliers: edge))
