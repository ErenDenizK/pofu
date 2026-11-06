# char__goat-surprised

- **Approved:** 2026-11-06T01:07:03+00:00 from batch `batch-41-resident-reactions`, job `goat-surprised`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:25:52+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9902, "cx": 507.5, "cy": 1372.0, "dx": 2, "dy": -1}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-surprised.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent source/parent/locked review accepts both initial takes: small round o mouth, wider catchlit eyes, raised brows and slightly lifted floppy ears; two horn buds, beard, tan patch, body/paws/framing preserved, no backdrop, cast shadow, text or motion lines. Both pass every QA check. Character-guard applies no grading, so take1 wins higher Harmony92.8 vs91.4. Exact full-canvas lossless490630 bytes preserves locked RGBA. No added stability threshold or pixel edits. Independent evidence: independent-reviews/review-mochi-proud-goat-surprised.json.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 42711238fa21e26e)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached baby goat into a surprised reaction. Change only the face and ears: the flat pressed mouth becomes a small round soft "o", both eyes grow slightly rounder and wider with their catchlights kept, the brows lift, and the two floppy ears lift a little more upright. The horn buds, beard tuft, tan patch, body, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, teeth, a ground shadow, text, motion lines.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: edit_alignment (the edit rescaled the object x1.010 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- pass: light_values (day/subject: L p2 20 (at most 22), p98 96 (at least 90), spread 76 (at least 60))
- pass: light_median (day/subject: median L 89 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.18 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.7 (at least 3.5))
- pass: detail_budget (detail at display size 3.6 (R1 5.3))
- pass: palette_drift (mean dE 1.0, p95 2.8, off-palette 0.7% (top: #441100 (0.1%), #662211 (0.1%)))
- pass: ground_line (feet at 89.3% of the height (contract 88%))
- pass: harmony (harmony score 93 against the char reference (outliers: detail))
- pass: edit_stability (80% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
