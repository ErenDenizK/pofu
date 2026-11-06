# plate__caglayan-island-2

- **Approved:** 2026-11-06T15:54:25+00:00 from batch `batch-43-caglayan-production`, job `caglayan-island-2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T15:46:50+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `caglayan-island-2.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Initial take2 is manually eligible and QA WARN/no hard failure. Take1 actual edit_stability hard failure is excluded automatically and never waived; no palette/chroma force is needed for take2. Two left/centre ribbons, half-full blue-green pool with dry rim showing, wet still wheel, two white/yellow flower clumps and first warm cliff light. Root props/framing retained; current source/locked seals and manual receipt b68e6e85 preserved. No retry or prompt/threshold change.

## References

- `design/art/masters/caglayan-island-0/caglayan-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1840b2fd8598c57a)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 2: the first
warm light. Two clear ribbons of water now fall down the cliff, one
on the left and one in the centre, into the pool. The pool is half
full of clear blue-green water with soft ripples, its old dry rim
still showing above the water line. The stones beside the streams
are wet and mossy green; the grass along the banks is green again
and two small clumps of white and butter-yellow flowers open near
the water. The water wheel is wet and dark but still. The first
warm light of the picture appears: a soft low warm sun from the
upper left lands on the top of the cliff and the falling water,
warming them to honey, while the rest stays in cooler light. The
picture is more colourful (chroma about 70 percent). Every shape,
prop, stone, outline, the island's size, the camera and the
composition stay exactly where they are in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a rainbow, a mist cloud, light rays, a glow, a full waterfall, new props, characters, moving or resizing anything, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 56 (R1 51))
- warn: light_values (day/subject: L p2 27 (at most 22), p98 92 (at least 90), spread 65 (at least 60))
- pass: light_median (day/subject: median L 66 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.15 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.6 (at least 3.5))
- pass: detail_budget (detail at display size 3.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.8)
- warn: palette_drift (mean dE 3.4, p95 11.4, off-palette 4.0% (top: #AAAA44 (0.8%), #AABB44 (0.5%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- warn: edit_stability (49% of the parent level unchanged)
- pass: edit_chroma (chroma x1.50 of the parent level (drift compounds along a chain))
