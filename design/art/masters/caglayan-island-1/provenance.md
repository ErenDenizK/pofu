# plate__caglayan-island-1

- **Approved:** 2026-11-06T15:48:44+00:00 from batch `batch-43-caglayan-production`, job `caglayan-island-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T15:46:20+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `caglayan-island-1.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Initial takes1/2 both manually eligible and no hard QA failure; take2 has lowest style-lock load1.2325. Single left ribbon, wet near pool edge, dry stationary wheel, unchanged root framing/props; advisory colour/light warnings preserved. Own current source/locked seals and manual receipt b68e6e85 retained. No retry, force, prompt or threshold change.

## References

- `design/art/masters/caglayan-island-0/caglayan-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 826bf77c199dbf38)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 1: one stream
is back. The trickle on the left grows into one thin, clear ribbon
of water falling step by step down the left side of the cliff into
the pool. The stones it runs over are darker and wet, with a little
fresh green moss. The pool's near edge is wet and a little darker,
with a few soft ripples where the ribbon lands; the rest of the pool
stays dull. A few tufts of grass near the water turn green. The
picture is a little more colourful (chroma about 55 percent of a
healthy meadow); the light, the cool haze and the single shaft stay as in stage 0. The wheel and the
rest of the cliff stay dry. Every shape, prop, stone, outline, the
island's size, the camera and the composition stay exactly where
they are in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: warm sunlight, a full waterfall, a rainbow, mist, a turning wheel, new props, characters, moving or resizing anything, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 57 (R1 51))
- warn: light_values (day/subject: L p2 37 (at most 22), p98 92 (at least 90), spread 55 (at least 60))
- pass: light_median (day/subject: median L 73 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.23 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.7 (at least 3.5))
- pass: detail_budget (detail at display size 2.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.2)
- warn: palette_drift (mean dE 2.9, p95 9.9, off-palette 3.0% (top: #DDCC55 (1.2%), #CCCC55 (1.1%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- pass: edit_stability (74% of the parent level unchanged)
- pass: edit_chroma (chroma x1.21 of the parent level (drift compounds along a chain))
