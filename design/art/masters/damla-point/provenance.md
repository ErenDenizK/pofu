# char__damla-point

- **Approved:** 2026-11-10T16:50:32+00:00 from batch `batch-64-flow-pieces`, job `damla-point`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-10T16:44:27+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `damla-point.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Auto-picked by actual canonical normalized-to-locked mean DeltaE (char QA omits that check); unchanged canonical QA replay exactly matches original checks. Both candidates preserve pointing paw, glass and Damla identity. Exact registration/app rig not certified. Founder review pending.

## References

- `design/art/masters/damla/damla.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint defc7c4e214779df)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached Damla into a new pose: one front paw is stretched out ahead and a little down, a single soft finger-paw pointing at something in front of her (the player's board), while the other paw still holds the small tea glass at her chest. Her eyes look where she points, with an encouraging little smile. Everything else, the fur, face, tail, size and ground line, stays exactly.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- warn: light_values (day/subject: L p2 25 (at most 22), p98 94 (at least 90), spread 69 (at least 60))
- pass: light_median (day/subject: median L 62 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.12 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.4 (at least 3.5))
- pass: detail_budget (detail at display size 6.6 (R1 5.3))
- warn: palette_drift (mean dE 3.2, p95 8.9, off-palette 1.4% (top: #441100 (0.2%), #773322 (0.1%)))
- pass: ground_line (feet at 88.3% of the height (contract 88%))
- warn: no_ground_shadow (a ground shadow seems painted in)
- pass: harmony (harmony score 83 against the char reference (outliers: detail))
- pass: edit_silhouette (94% of the parent's shape kept)
- pass: edit_stability (77% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))

Delivery: pixel-identical lossless WebP twin (492616bytes), including hidden RGB at alpha0; canonical PNG exceeds upload cap and is retained outside upload.
