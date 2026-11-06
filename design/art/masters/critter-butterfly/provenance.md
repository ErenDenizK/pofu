# sheet__critter-butterfly

- **Approved:** 2026-11-05T23:12:21+00:00 from batch `batch-35-experience`, job `critter-butterfly`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:07:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `critter-butterfly.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes show exactly five separated cream-yellow butterflies with warm rose tips, four distinct wing apertures of a flap cycle followed by an upright closed resting pose, plain plump bodies and two short antennae. Original and locked alpha-composited images independently reviewed: no text, fur, floor, cast shadow or opaque background. Both hard QA pass with style-lock load 0.0000 and no Harmony ranking check; deterministic take-number tie selects take 1. The flatter body angle of its flat-open frame is disclosed as an advisory visual variation, not an invented registration failure. Light-profile warnings remain for founder review.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).
- `design/art/masters/dressing-meadow/dressing-meadow.png`: The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

## Prompt (fingerprint 4b67325af57bbd65)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).
3. The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

A sheet of one small butterfly drawn five times in a single row, left to right, evenly spaced with wide empty
space between them: four wing positions of one flap cycle seen from slightly above and the side (wings
fully up, half open, flat open, half closed), and a fifth resting pose with the wings closed upright. Soft
cream-yellow wings with warm rose tips and a plain plump body, two short antennae. Chunky and gentle, about
the same size in every frame.

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

AVOID: a floor, a ground shadow, cast shadows, text, letters, outlines, realistic or scary detail, thin legs, big eyes with highlights, speech bubbles, a background, pieces touching or overlapping

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- warn: light_values (day/subject: L p2 59 (at most 22), p98 89 (at least 90), spread 30 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 81 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.38 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 3.5 (at least 3.5))
- pass: detail_budget (detail at display size 3.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- pass: palette_drift (mean dE 0.9, p95 3.0, off-palette 0.0%)
