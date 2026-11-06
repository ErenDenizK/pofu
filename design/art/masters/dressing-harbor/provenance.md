# sheet__dressing-harbor

- **Approved:** 2026-11-06T00:04:46+00:00 from batch `batch-35-experience`, job `dressing-harbor`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:32:26+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `dressing-harbor.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked initial takes are independently visually eligible: exactly ten separated units in five columns/two rows, thick cream rope coil, red-cream buoy, slatted crate, coarse sage folded net, single diagonal oar, barrel with two honey bands, unlit paper lantern buoy, mooring post with rope loop, two flat fish crates as one stack, pale blue-grey tin bucket. Matte toy-like materials; no fish, text, floor, cast shadow, fine net weave or metallic shine. Both hard QA pass with lock_load0 and no Harmony ranking check, deterministic tie selects take1. Exact RGBA lossless-cap preflight fits614400 without resizing. Advisory light warnings retained.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).
- `design/art/masters/dressing-meadow/dressing-meadow.png`: The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

## Prompt (fingerprint 9023a0afe50a7033)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).
3. The approved meadow sheet: the same finish, scale and chunkiness (do not draw its pieces).

A sheet of ten small harbor props for a cozy island diorama, in a grid of five columns by two rows, each piece
complete and separate with wide empty space around it, none touching: row 1, a coil of thick cream rope, a
round red-and-cream buoy, a small wooden shipping crate with plain slats, a folded fishing net in soft
sage-green mesh shown as a plump pile, and a single wooden oar leaning on nothing (drawn lying at a gentle
diagonal); row 2, a small barrel with two honey-wood bands, a lantern buoy with a cream paper shade (unlit),
a short wooden mooring post with a rope loop, a stack of two flat fish crates, and a small tin bucket of
soft pale blue-grey. Chunky, toy-like, matte, each small, seen from the same low front three-quarter
camera, standing on nothing.

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

AVOID: a floor, a ground shadow, cast shadows, text, letters, outlines, characters or animals, pieces touching or overlapping, a background, real fish, fine rope or net weave, metallic shine, glossy surfaces

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
- warn: light_values (day/subject: L p2 48 (at most 22), p98 91 (at least 90), spread 43 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 70 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 8.9 (at least 3.5))
- pass: detail_budget (detail at display size 5.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- pass: palette_drift (mean dE 1.1, p95 2.7, off-palette 0.0%)
