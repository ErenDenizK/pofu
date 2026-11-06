# plate__koke-island-4

- **Approved:** 2026-11-06T07:18:45+00:00 from batch `batch-39-koke-production`, job `koke-island-4`, take t2
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-06T01:45:06.095Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `koke-island-4.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** lead-selected per queue row 0-k; founder review pending. lead-selected per queue row 0-k of docs/design/art-production-plan.md at main76d7d09a509202b464e48224f1d9e84f5da21bc4. The lead explicitly selected this retained original and requested official promote --force. No generation, source-pixel modification, prompt/palette/profile edit or QA threshold change. Original generating account, timestamps, callbacks, prompt/reference fingerprints and all four original takes are preserved; all historical CUT notes stay labelled and retained. This is a lead selection, not a QA auto-pick. Publish original take2 exactly. Historical hard failures remain chroma_ceiling p95=61.9 and palette_drift mean dE4.5290/off-palette13.3%. The selected original otherwise depicts the requested standing flowering creature, five open lawn groups, resident and petal/spore signature. Official half-size plate delivery768x512 is unchanged. Actual healed-vs-stuck chroma/light observations are recorded separately rather than claimed to meet a measured2x reward. Arc observations are archived in arc-measurements.json: immutable full-locked chroma ratio stage4/stage0 is2.8692; warm-bright observational proxy is not monotone and is not claimed to meet the authored light step. Current selected full-locked pixels equal those original measured files. Current selected-take canonical QA status: fail. Actual hard failures (recorded unchanged): chroma_ceiling: chroma p95 62 (R1 51); palette_drift: mean dE 4.5, p95 15.7, off-palette 13.3% (top: #AAAA33 (1.2%), #BBBB44 (0.9%)). The exact retained lead selection uses official promote --force; this is not an automatic QA pass.

## References

- `design/art/masters/koke-island-0/koke-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 45e36368520dd129)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 4, healed: the
signature moment. Koke stands up: the hump has risen onto four
sturdy stubby legs, standing on the lawn where it slept, its head
lifted and turned to the viewer, both eyes open, big round and
warm brown with catchlights, a soft happy smile, its small ears
perked. It is covered in rich living moss, thick like fur, and its
whole back is in flower: blossoms in butter yellow, blush pink, lilac
and white, with a tuft of leaves on its crown. It stands within the
hump's footprint and is about a third taller than the hump was, so it
fits well inside the picture. The island is in full bloom: all five
flower clusters open and lush, the moss deep and green on every
boulder, the ferns unfurled, the path of stepping stones bright. A warm
golden sun from the upper left lights everything, and the whole
island glows with warm light. The signature image: soft flower petals
and golden spores drift up in the air from all over the island,
catching the light. The small dormouse sits on a boulder beside the
rake, delighted, at the size of a bagel. Full colour (chroma about
100 percent of a healthy meadow). The island's size, outline, the
camera, the boulders, the path and the rake stay exactly where they
are in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: teeth, claws, a roar, a whale shape, glowing eyes, a dark sky, light rays, a halo, Koke crossing the island's edge, new props, moving or resizing the island, scary details, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- fail: chroma_ceiling (chroma p95 62 (R1 51))
- warn: light_values (day/subject: L p2 35 (at most 22), p98 95 (at least 90), spread 60 (at least 60))
- pass: light_median (day/subject: median L 72 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.09 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 7.9 (at least 3.5))
- pass: detail_budget (detail at display size 5.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.6)
- fail: palette_drift (mean dE 4.5, p95 15.7, off-palette 13.3% (top: #AAAA33 (1.2%), #BBBB44 (0.9%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- warn: edit_stability (45% of the parent level unchanged)
- pass: edit_chroma (chroma x2.41 of the parent level (drift compounds along a chain))

Retained-source QA re-post, no new generation. Original run batch-39-koke-production, take 2. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
