# sheet__critter-bird

- **Approved:** 2026-11-05T23:30:27+00:00 from batch `batch-35-experience`, job `critter-bird`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:13:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `critter-bird.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes show exactly four separated matching dusty-blue birds with cream bellies and honey beaks: left perch, right-facing open-beak chirp, raised wings, lowered wings. Original and official locked images independently reviewed. Small floating honey chirp accents beside the second beak are disclosed; they are non-letter sound accents, not text or speech bubbles. No floor, cast shadow or background. Select the lowest eligible style-lock load using canonical QA reports; advisory light warnings remain for founder review.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).
- `design/art/masters/dressing-meadow/dressing-meadow.png`: The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

## Prompt (fingerprint 75dff31685151cdb)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).
3. The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

A sheet of one small round bird drawn four times in a single row, left to right, evenly spaced with wide empty
space between them: (1) perched, body upright, head turned to the left; (2) perched, head turned to the
right with a small chirp, beak slightly open; (3) mid-flap with the wings raised high; (4) mid-flap with the
wings lowered. A plump, round little bird in soft dusty blue with a cream belly and a small honey beak, a
short tail, tiny dot eyes. Chunky and toy-like, seen from the side in the same low camera.

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
- pass: chroma_ceiling (chroma p95 19 (R1 51))
- warn: light_values (day/subject: L p2 58 (at most 22), p98 89 (at least 90), spread 31 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 72 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.5 (at least 3.5))
- pass: detail_budget (detail at display size 3.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- pass: palette_drift (mean dE 0.9, p95 1.9, off-palette 0.0%)
