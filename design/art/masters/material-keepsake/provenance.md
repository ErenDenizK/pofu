# prop__material-keepsake

- **Approved:** 2026-11-05T23:34:29+00:00 from batch `batch-33-home-showcase`, job `material-keepsake`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:24:00+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `material-keepsake.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both source and locked takes show one small square soft-brown paper parcel, cream string in a neat bow and one hanging blank round cream tag, no letters or background. Widths338/344px match approved moss340px family; take1 has lowest eligible lock load.6445 vs.6783. All hard QA passes; advisory light warnings retained. No extra generation or local pixel changes.

## References

- `design/art/masters/material-moss/material-moss.png`: The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint bddb1941c27ca484)

```text
REFERENCES (attached, in this order):
1. The first material of this family: match its size on the canvas, camera, painting and finish exactly (do not draw the moss).
2. The palette card for props: use only these colors (and mixes of them).

A single small painted object for a cozy game, a crafting material:
a small square parcel wrapped in soft brown paper, tied with cream
string in a neat bow, with a blank round cream paper tag hanging
from the string (no letters on it). Same camera, size and finish
as the attached moss. Centered on an empty transparent background.

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
- pass: chroma_ceiling (chroma p95 39 (R1 51))
- warn: light_values (day/subject: L p2 54 (at most 22), p98 92 (at least 90), spread 38 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 74 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.28 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.8 (at least 3.5))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.7, p95 1.5, off-palette 0.0%)
- pass: harmony (harmony score 78 against the world reference (outliers: C_p95, edge))
