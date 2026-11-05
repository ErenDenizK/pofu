# sheet__dressing-meadow

- **Approved:** 2026-11-05T21:44:21+00:00 from batch `batch-35-experience-pilot`, job `dressing-meadow`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T19:34:29.092Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `dressing-meadow.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. All four retained originals now pass hard QA with the authoritative world-props/world-foliage extension; light warnings remain advisory. Exact-lossless delivery eligibility excludes t1 and t2: best tested full-canvas encodings972426 and672900 bytes exceed614400; t3 and t4 fit496762 and539982 bytes. Among eligible candidates t3 has the lowest lock-load .0660 versus t4 .3580; selected evaluation t3. Manual review confirms twelve separate pieces in the requested4x3 grid: small grass, tall grass, two-seed-head tuft, clover; four daisies, four cornflowers, four buttercups, one foxglove; three pebbles, flat stone, exact five-toadstool ring, mossy stone. Clear silhouettes at28px, no added ground/objects/text or touching pieces. Tiny alpha tails are retained, no manual cleanup/quantization/downscale. Original generation identity, prompts and references preserved; current context is QA salvage, not new generation.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint fd59c3c29567540d)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).

A sheet of twelve small lawn-dressing pieces for a cozy island diorama, in a grid of four columns by three
rows, each piece complete and separate with wide empty space around it, none touching or overlapping: row 1,
three grass tufts of different sizes (a small one, a taller one, a tuft with two seed heads) and a clump of
clover; row 2, three wildflower clumps (daisies, cornflowers, buttercups: each four or five chunky flowers on
short stems) and a single tall foxglove; row 3, a group of three smooth pebbles, a single flat stone, a small
ring of five toadstools with cream caps and warm rose spots, and a half-buried mossy stone. Each piece is
small and chunky, seen from the same low front three-quarter camera, standing on nothing.

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

AVOID: a floor, a ground shadow, cast shadows, text, letters, outlines, characters or animals, pieces touching or overlapping, a background

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 53 (R1 51))
- warn: light_values (day/subject: L p2 52 (at most 22), p98 91 (at least 90), spread 39 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 70 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 14.0 (at least 3.5))
- pass: detail_budget (detail at display size 4.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.1)
- pass: palette_drift (mean dE 1.0, p95 2.6, off-palette 0.1% (top: #776688 (0.0%), #665577 (0.0%)))

Retained-source QA re-post, no new generation. Original run batch-35-experience-pilot, take 3. Current fingerprint identifies evaluation context only; original prompt/reference hashes and callback are preserved in salvage-source.json.
