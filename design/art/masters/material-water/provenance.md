# prop__material-water

- **Approved:** 2026-11-05T23:30:14+00:00 from batch `batch-33-home-showcase`, job `material-water`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:22:11+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `material-water.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial sources and locked canvases show the exact round-bellied flask, short neck, cream cork and single pale-aqua drop on the cork, with matte tinted water and no ground, text or extraneous objects. Widths287/360px compare to family moss340px; take2 width+5.9percent reasonably matches family scale for this taller flask silhouette. Both hard-pass; take2 lower lock load.4108 vs.4668. Advisory light/Harmony warnings retained; no local fit or resize.

## References

- `design/art/masters/material-moss/material-moss.png`: The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 613cc328a88d1ea0)

```text
REFERENCES (attached, in this order):
1. The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
2. The palette card for props: use only these colors (and mixes of them).

A single small painted object for a cozy game, a crafting material:
a little round-bellied glass flask with a short neck and a cream
cork, full of clear pale turquoise water, the glass painted as a
soft tinted shape, with one small water drop resting on the cork.
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
- pass: chroma_ceiling (chroma p95 23 (R1 51))
- warn: light_values (day/subject: L p2 74 (at most 22), p98 94 (at least 90), spread 21 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.56 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.2 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 2.3, p95 4.8, off-palette 0.0%)
- warn: harmony (harmony score 54 against the world reference (outliers: C_p95, L_p2, edge))
