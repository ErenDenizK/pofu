# plate__koke-island-2

- **Approved:** 2026-11-06T02:01:37+00:00 from batch `batch-39-koke-production`, job `koke-island-2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T01:45:01+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `koke-island-2.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Take2 is the only fully eligible initial candidate. Both hard-pass; take1 shows the peeking dormouse with both eyes visible, contrary to the explicit one-eye peek, so it is manually excluded despite lower load1.48. Take2 shows one warm dark eye behind the left boulder, the two nearest groups open in butter-yellow and blush-pink, all three remaining groups still closed, the same sleeping Koke, a leafy crown shoot, greener moss and first warm crown/flower light with cooler far side. Four stones, five total flower groups, two ferns, rake, boulders, outline/camera and rooted positions remain. No rays/halo/petals/open Koke eye or new prop. Take2 load1.5244; source-bound edit of the actual uploaded stage0 with canonical half-size delivery, no extra generation.

## References

- `design/art/masters/koke-island-0/koke-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 8207684eeaf1a027)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 2: the first
warm light. Repaint about two thirds of the moss on Koke's hump and
on the lawn a fresh living green, with a few brighter patches on its
back; only the underside and the far side stay grey. The two
flower clusters nearest the viewer are open: soft round blossoms
in butter yellow and blush pink with green leaves; the other three
clusters have swollen buds, still shut. The first warm light of the
picture appears: a soft low warm sun from the upper left lands on
the crown of Koke's hump and on the open flowers, warming them to
honey and gold, while the rest stays in cooler light. Behind the
boulder on the left a tiny round grey-brown dormouse with big round
ears peeks out with one eye, at the size of a bagel, curious and
shy. The sprout on the crown is now a small leafy shoot. The picture
is more colourful overall (chroma about 70 percent of a healthy
meadow). Koke is still asleep, eyes closed, its mouth now a calm
straight line. Every shape, prop, stone, outline, the island's size,
the camera and the composition stay exactly where they are in the
attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow or halo, petals in the air, an open eye, new props, moving or resizing anything, scary details, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 60 (R1 51))
- warn: light_values (day/subject: L p2 39 (at most 22), p98 93 (at least 90), spread 55 (at least 60))
- pass: light_median (day/subject: median L 71 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.19 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.3 (at least 3.5))
- pass: detail_budget (detail at display size 2.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.5)
- warn: palette_drift (mean dE 3.3, p95 12.2, off-palette 5.2% (top: #BBBB44 (0.9%), #CCBB44 (0.7%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- warn: edit_stability (40% of the parent level unchanged)
- pass: edit_chroma (chroma x2.60 of the parent level (drift compounds along a chain))
