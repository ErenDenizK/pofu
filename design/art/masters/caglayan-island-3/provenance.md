# plate__caglayan-island-3

- **Approved:** 2026-11-06T16:39:49+00:00 from batch `batch-43-caglayan-production`, job `caglayan-island-3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T16:37:33+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `caglayan-island-3.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Both initial sources manually meet stage3: three separate ribbons, full pool, wet turning wheel with spray, two ferns and white/yellow/lilac bloom, no signature; root frame/props retained. Take2 WARN/no hard failure and lower lock_load2.0321 than take1 2.7847. Take1 actualFAIL onlypalette_drift/chroma_ceiling remains recorded within authored stage3 exception but is not selected. No force or retry needed for selected2; no prompt/threshold changes.

## References

- `design/art/masters/caglayan-island-0/caglayan-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7cd45944648ba64f)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 3: nearly
there. Three clear streams of water fall down the left, centre and
right of the cliff steps, each still a separate ribbon with dry
stone between them. The pool is full to its old rim with clear
blue-green water and soft ripples. The water wheel on the right is
turning: its paddles are wet and a little white spray lifts at the
bottom where they meet the water. The cliff steps are mossy green
around the water; the banks are lush green with clumps of white,
butter-yellow and soft lilac flowers, and two small ferns. A warm sun
from the upper left lights the cliff top and the near bank with
soft warm shadows. The picture is nearly fully colourful (chroma
about 85 percent). Every shape, prop, stone, outline, the island's
size, the camera and the composition stay exactly where they are in
the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a rainbow, a mist cloud, sparkles, a glow, one single wide waterfall, new props, characters, moving or resizing anything, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 58 (R1 51))
- warn: light_values (day/subject: L p2 39 (at most 22), p98 94 (at least 90), spread 55 (at least 60))
- pass: light_median (day/subject: median L 69 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.15 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 7.5 (at least 3.5))
- pass: detail_budget (detail at display size 4.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.0)
- warn: palette_drift (mean dE 3.7, p95 13.3, off-palette 6.5% (top: #BBBB44 (1.4%), #AAAA33 (0.7%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- pass: edit_stability (53% of the parent level unchanged)
- pass: edit_chroma (chroma x1.66 of the parent level (drift compounds along a chain))
