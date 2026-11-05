# sheet__gift-parcel

- **Approved:** 2026-11-05T23:05:02+00:00 from batch `batch-35-experience`, job `gift-parcel`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T22:59:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `gift-parcel.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes satisfy the two-state parcel sheet: a closed kraft-cream wrap with cream twine and dried sprig, and an open wrap with loose twine, paper shreds and an empty warm-honey hollow. No visible gift object, text, floor or cast shadow; the apparent RGB haze outside the parcels is fully transparent. Take 2 has the lowest style-lock load (0.0000 versus 0.0012). Light-profile warnings remain recorded for founder review.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 24e688aa13ca04ef)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).

A sheet of one small gift parcel drawn twice in a single row, evenly spaced with wide empty space between
them: (1) closed: a plump square parcel wrapped in warm kraft-cream paper tied with cream twine in a simple
bow, a small dried sprig tucked under the knot; (2) open: the same parcel with the paper folded back and
the twine untied and lying loose, the inside a soft empty nest of cream paper shreds with a small round
warm-honey hollow in it. Chunky, matte, toy-like, seen from the same low front three-quarter camera.

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

AVOID: a ribbon with a pattern, text, glitter, a floor, a ground shadow, cast shadows, outlines, a background, a visible gift item

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- warn: light_values (day/subject: L p2 60 (at most 22), p98 93 (at least 90), spread 33 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 77 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.27 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.6 (at least 3.5))
- pass: detail_budget (detail at display size 3.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- warn: palette_drift (mean dE 2.7, p95 4.7, off-palette 0.0%)
