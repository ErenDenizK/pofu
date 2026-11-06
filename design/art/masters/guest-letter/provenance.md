# sheet__guest-letter

- **Approved:** 2026-11-05T23:09:02+00:00 from batch `batch-35-experience`, job `guest-letter`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:00:50+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `guest-letter.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes show exactly two separated letter states, with a cream folded envelope, round honey wax dot containing one sunflower seed, and open blank cream paper with faint horizontal shading bands and curled corners. No letters, numbers, handwriting, scribbles, floor, cast shadow or background. Independent original and locked alpha-composited review confirms eligibility; take 2 has lower style-lock load (0.0000 versus 0.0029). Advisory light-profile warnings are retained for founder review.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint b2637f415ad4867e)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).

A sheet of one small handwritten letter drawn twice in a single row, evenly spaced with wide empty space
between them: (1) folded: a small cream envelope-style fold sealed with a round honey-colored wax dot, a
tiny sunflower seed pressed into the wax; (2) open: the same letter unfolded flat as a soft cream sheet with
slightly curled corners and a few faint blank horizontal bands where lines of writing would be, no letters
or marks. Chunky, matte, toy-like, seen from the same low front three-quarter camera.

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

AVOID: text, letters, numbers, scribbles, handwriting, a floor, a ground shadow, cast shadows, outlines, a background

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 27 (R1 51))
- warn: light_values (day/subject: L p2 70 (at most 22), p98 94 (at least 90), spread 24 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 90 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.38 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.5 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- pass: palette_drift (mean dE 1.3, p95 3.3, off-palette 0.0% (top: #BB7733 (0.0%), #AA6633 (0.0%)))
