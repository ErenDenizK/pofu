# plate__caglayan-island-4

- **Approved:** 2026-11-06T16:48:48+00:00 from batch `batch-43-caglayan-production`, job `caglayan-island-4`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T16:42:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `caglayan-island-4.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Both initial takes manually meet healed-stage core: full soft water curtain, small pastel foot rainbow and low mist, full clear pool/lily pads, wet bright wheel spray, lush multicolour bloom/ferns and upright full bucket; root framing/props retained. Take2 WARN/no hard failure and lowest lock_load1.8597 versus1.9129. Official canonical halfscale master/raw cap preflight passes; no force/retry or prompt/threshold/source changes.

## References

- `design/art/masters/caglayan-island-0/caglayan-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 8a030e7ddcb1677a)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 4: healed. The
waterfall pours again: one full, soft, glassy curtain of water falls
down all four cliff steps into the pool, white where it breaks on
each step. At its foot a soft cloud of fine mist rises, and in the
mist a gentle pastel rainbow arcs, small and soft. The pool is full,
clear blue-green, with gentle ripples and a few lily pads. The water
wheel turns, its paddles bright with spray. The cliff is covered in
living moss and small ferns; the banks are in full bloom with white,
butter-yellow, blush pink and lilac flowers; the bucket now stands
upright by the pool, full of water. Full warm afternoon light, soft
and golden on the water and the cliff, cool clear shadows. Full
colour. Every shape, prop, stone, outline, the island's size, the
camera and the composition stay exactly where they are in the
attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a harsh or neon rainbow, a huge mist cloud hiding the cliff, water falling off the island's edge, new buildings, characters, moving or resizing anything, sparkles, text

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
- warn: light_values (day/subject: L p2 40 (at most 22), p98 95 (at least 90), spread 55 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 75 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.15 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 7.8 (at least 3.5))
- pass: detail_budget (detail at display size 5.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.9)
- warn: palette_drift (mean dE 3.0, p95 10.8, off-palette 3.3% (top: #CCBB44 (0.4%), #BBAA33 (0.3%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- pass: edit_stability (62% of the parent level unchanged)
- pass: edit_chroma (chroma x1.38 of the parent level (drift compounds along a chain))
