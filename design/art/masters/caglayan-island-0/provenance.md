# plate__caglayan-island-0

- **Approved:** 2026-11-06T15:23:51+00:00 from batch `batch-43-caglayan-production`, job `caglayan-island-0`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T06:51:11+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `caglayan-island-0.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** lead-selected retained take3; founder review pending. Queue row0-r: lead-selected retained take3; founder review pending. All four original sources, original account/backend/times and unchanged official QA retained; no root generation. Canonical half-scale delivery; historical trickle exclusions preserved as history and superseded only by this named lead selection. Queue row 0-r: lead-selected retained root take3; canonical promote --force is explicit lead authority, not a new QA pass or regeneration. Original tool and ingestion timestamps and historical manual exclusions remain preserved. 

## References

- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home island: copy ONLY its camera, its plate proportions (shallow top, rounded banded body) and its soft painting. Do not copy its lawn, its colors, its round door or its pebbles.
- `design/art/masters/island-main-s/island-main-s.png`: The small island plate: Çağlayan is about this size in the frame. Copy the size and the earth body's proportions only.
- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished station of the game: every prop on the island is at this scale and in this finish (do not draw this stall).
- `design/art/masters/cloud-sea/cloud-sea.png`: The sea of clouds below every island: paint the clouds like this.

## Prompt (fingerprint ce10548ce61df11f)

```text
REFERENCES (attached, in this order):
1. The home island: copy ONLY its camera, its plate proportions (shallow top, rounded banded body) and its soft painting. Do not copy its lawn, its colors, its round door or its pebbles.
2. The small island plate: Çağlayan is about this size in the frame. Copy the size and the earth body's proportions only.
3. A finished station of the game: every prop on the island is at this scale and in this finish (do not draw this stall).
4. The sea of clouds below every island: paint the clouds like this.

A game plate for a cozy mobile game: Çağlayan, a small island whose
waterfall has stopped, in the game, on a still overcast-bright noon.
STAGE 0, STUCK. The island is a floating diorama plate with a
shallow top about a fifth as deep as it is wide, over a soft rounded
earth body with gentle bands, a small plate about 62 percent of the
image width, centered. At the back centre rises a low cliff of
rounded stone in four broad steps, about as tall as a windmill,
where a waterfall should pour: the steps are pale and dust-dry,
sun-bleached sand-grey, with dry moss in the cracks. At its foot a
round shallow pool lies still, its surface a dark still mirror with a
dry pale rim where the water used to reach. On the right bank a
small wooden mill with a round water wheel stands still, its
paddles dry and mossy. A path of flat stones runs from the front
lip to the pool. A few rounded boulders, two dry tufts of grass,
and a small wooden bucket lying on its side.
STUCK STATE, HUSHED AND BEAUTIFUL, NOT PALE: the warm colours are
drained (the grass straw-dry, the wood grey, the flowers shut), but
the picture keeps a full range from deep shade to bright light and
rich cool colour. The cliff's shaded faces are a deep soft
blue-violet; the still pool is a dark teal mirror reflecting the sky;
a soft cool haze sits behind the cliff so it stands out in layers.
ONE focal light: a single slanting shaft of pale morning light falls
through the haze onto the cliff, dust motes floating in it, and lands
on a single thin trickle of clear water running down one step on the
left, which glints brightly. A hushed, beautiful stillness that
invites you in, like a place waiting for you; never washed out,
never flat grey, never ruined, never eerie.
GAME CAMERA: exactly the camera of the attached home island, a low
front three-quarter view about 20 degrees above the horizon, a pale
sky with soft far clouds above and the sea of clouds below rising to
the island's underside. Every prop is at the scale of the attached
tea stall. No characters.

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

AVOID: cracks like an earthquake, ruins, broken buildings, skulls, bones, dead trees, fog, gloom, darkness, a pointed or spiky underside, water falling off the island, a copy of the home island's lawn and round door, text, letters, a border, harsh shadows, outlines, photorealism, a 3D render look

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- warn: light_values (day/subject: L p2 50 (at most 22), p98 93 (at least 90), spread 43 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 77 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.41 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- pass: light_contrast (day/subject: p75 local contrast 3.7 (at least 3.5))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: palette_drift (mean dE 2.0, p95 4.2, off-palette 0.0%)
