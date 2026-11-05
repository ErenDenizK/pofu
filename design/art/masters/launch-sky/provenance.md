# plate__launch-sky

- **Approved:** 2026-11-05T23:20:39+00:00 from batch `batch-35-experience-pilot`, job `launch-sky`, take t2
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T19:28:13.735Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `launch-sky.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1290x2796 take; the master and raw are delivered at x0.5 (645x1398, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. All four retained originals pass hard QA at the declared full1290x2796 canvas; t2 has the lowest eligible lock load .6304. Manual source/locked/delivered review verifies clear top12 percent, calm dawn sky, sparse edge wisps and low cloud bank with open central crop; no objects, letters or horizon land. Advisory dawn subject light-values/haze/contrast warnings are retained explicitly. Official declared half delivery is645x1398; all four lossless previews fit under600 KB. No new generation, local pixel edits or threshold waiver.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/masters/cloud-sea/cloud-sea.png`: The sea of clouds below every island: paint the clouds like this (do not draw the sea).

## Prompt (fingerprint 75176df43501613b)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The sea of clouds below every island: paint the clouds like this (do not draw the sea).

A tall full-bleed dawn sky for a cozy mobile game's launch screen, a portrait image. Top to bottom: a soft
lilac-blue sky at the top, melting through pale peach and warm cream to a glowing honey horizon about two
thirds down; a few long, soft, slightly flat clouds in thin calm bands across the sky, lit warm from below;
a gentle bank of puffy cream clouds along the bottom third, lit pink-gold on their tops. The light is
calm and hopeful, a quiet new morning. Keep the middle of the image open and uncluttered so a small
island can sit there; keep anything important within the central two thirds of the width and nothing
within the top 12 percent. No island, no sun disc, no birds, no stars, no characters.

Painted in the same soft airbrushed picture-book finish as the attached art, milky pastel colors lifted toward cream, no outlines, no hard edges.

AVOID: a border, text, harsh shadows, saturated or neon colors, dark moods, outlines, photorealism, a 3D render look, an island, a sun disc, birds, stars, characters, banding

LIGHT (hour: dawn, layer: subject). Hush, promise.
Key light #F4C7A4 from the left, a little above; fill #C9B8F0; rim #FFD9BC along the edge facing away from the key. Shadows are tinted #B9A2FF (never grey or black) and fall toward the right, a little below; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1024x1536 scaled x1.820 and center-cropped to 1290x2796 (the job's declared size: crop and upscale are by design))
- pass: chroma_ceiling (chroma p95 35 (R1 51))
- warn: light_values (dawn/subject: L p2 82 (at most 26), p98 93 (at least 88), spread 11 (at least 55) (warn-only until the founder has seen the light pilot))
- pass: light_median (dawn/subject: median L 86 (band 50-88))
- warn: light_haze (dawn/subject: dark-channel haze 0.60 (at most 0.24; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (dawn/subject: p75 local contrast 0.3 (at least 3.2) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: palette_drift (mean dE 1.8, p95 3.5, off-palette 0.0%)

Retained-source QA re-post, no new generation. Original run batch-35-experience-pilot, take 2. Current fingerprint identifies evaluation context only; original prompt/reference hashes and callback are preserved in salvage-source.json.
