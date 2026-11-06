# plate__koke-island-1

- **Approved:** 2026-11-06T01:53:23+00:00 from batch `batch-39-koke-production`, job `koke-island-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T01:43:53+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `koke-island-1.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes clear hard QA and preserve the approved stage0 composition: the same sleeping face/body, five closed flower groups, four stepping stones, two ferns, boulders and rake. About one third of the moss/lawn greens in irregular patches while most remains grey; the crown sprout has exactly three leaves. No new resident, open flower, open eye, glow, petal or text. Take2 wins the lower style-lock load0.7487 versus0.8072. Full locked source review confirms the sparse early healing stage; the day/cool-light warnings remain advisory. Source parent is the actual re-promoted/upload-verified stage0, independently edited, not a previous growth stage.

## References

- `design/art/masters/koke-island-0/koke-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint b1ee76fee46761ef)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 1: the moss is
waking. Repaint about a third of the moss on Koke's hump and on the
lawn, in irregular soft patches (one on its shoulder, one along its
back, one near its snout, a few on the lawn and the boulders), from
dull grey-sage to a fresh living moss green; the rest stays grey.
The sprout on its crown has grown a third leaf. The flower buds
swell a little and show a hint of their colour at the tips, but all
stay closed. The picture is a little more colourful overall (chroma
about 55 percent of a healthy meadow); the light stays flat and
cool, with no warm light. Koke is still fast asleep, eyes closed.
Every shape, prop, stone, outline, the island's size, the camera and
the composition stay exactly where they are in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: warm sunlight, glow, open flowers, an open eye, new props, new characters, moving or resizing anything, scary details, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 30 (R1 51))
- warn: light_values (day/subject: L p2 46 (at most 22), p98 94 (at least 90), spread 48 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 75 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.34 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- pass: light_contrast (day/subject: p75 local contrast 4.5 (at least 3.5))
- pass: detail_budget (detail at display size 2.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: palette_drift (mean dE 2.3, p95 4.1, off-palette 0.0%)
- pass: edit_silhouette (100% of the parent's shape kept)
- pass: edit_stability (62% of the parent level unchanged)
- pass: edit_chroma (chroma x1.91 of the parent level (drift compounds along a chain))
