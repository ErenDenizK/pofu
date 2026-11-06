# char__goat-happy

- **Approved:** 2026-11-06T00:37:17+00:00 from batch `batch-41-resident-reactions`, job `goat-happy`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:20:00+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-happy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes hard-pass and show closed happy arcs, relaxed brows and a small reluctant closed smile, without a wide grin or teeth. Horn buds, floppy ears, beard tuft, tan patch, body and paws preserve the approved goat. Both global edit stability .9546 and central belly/paws kept .9999 support the visual identity review. Character-guard applies no grading; take1 wins Harmony79.7 vs79.4. Exact full-canvas lossless WebP455890 bytes fits the cap. Light warnings remain visible; no local pixel edits or further generation. The existing harbor consumer receives only its four planned reaction links with this first family success, with no invented goat character node.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 95a237d2bcb5c7f5)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached baby goat into a happy reaction. Change only the eyes, brows and mouth: both eyes become happy closed arcs, the classic smiling ^ shape, each a thick soft dark upward-curved arc at the height of the top of the original eye; the low indignant brows relax; the flat, pressed mouth turns into a small, slightly reluctant smile. The horn buds, floppy ears, beard tuft, tan patch, body, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: teeth, a wide grin, tears, a worried look, a ground shadow, text, motion lines.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- warn: light_values (day/subject: L p2 60 (at most 22), p98 96 (at least 90), spread 36 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 89 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.34 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 3.1 (at least 3.5))
- pass: detail_budget (detail at display size 3.0 (R1 5.3))
- pass: palette_drift (mean dE 1.0, p95 2.7, off-palette 0.7% (top: #552211 (0.1%), #662211 (0.1%)))
- pass: ground_line (feet at 89.3% of the height (contract 88%))
- pass: harmony (harmony score 80 against the char reference (outliers: L_p2))
- pass: edit_stability (95% of the parent level unchanged)
- pass: edit_chroma (chroma x1.02 of the parent level (drift compounds along a chain))
