# char__simit-surprised

- **Approved:** 2026-11-04T23:26:43+00:00 from batch `batch-20-poses`, job `simit-surprised`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T23:11:24+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-surprised.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take2 passes hard QA and best matches the requested small round soft o mouth, wide catchlit eyes and upright ears while preserving the tabby markings, coral scarf, body/tail/paws and frame. Exclude take1 manually because its mouth is a tall open oval rather than the requested small round o; take2 also keeps chroma closer to its parent. Edit stability0.8827, chroma1.0134 and Harmony80.6 pass; light/ground-line warnings remain advisory. Official post removes generated background, leaving a transparent sprite with no cast shadow. Characters are not style locked. Auto-picked by QA among semantically eligible takes; founder review pending.

## References

- `design/art/masters/simit-kitten/simit-kitten.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint d276a38e13e8c80b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached kitten, Simit, into a surprised reaction. Change only the face and ears: the mouth becomes a small round soft "o", both eyes grow slightly rounder and wider with their catchlights kept, both ears stand upright. Body, tail, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, a curl on the head, a ground shadow, text, motion lines.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 56 (R1 51))
- pass: light_values (day/subject: L p2 17 (at most 22), p98 96 (at least 90), spread 79 (at least 60))
- pass: light_median (day/subject: median L 82 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.09 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.0 (at least 3.5))
- pass: detail_budget (detail at display size 5.0 (R1 5.3))
- pass: palette_drift (mean dE 1.6, p95 4.9, off-palette 0.9% (top: #CC5544 (0.1%), #441100 (0.1%)))
- warn: ground_line (feet at 92.6% of the height (contract 88%))
- pass: harmony (harmony score 81 against the char reference (outliers: C_p95, detail))
- pass: edit_stability (88% of the parent level unchanged)
- pass: edit_chroma (chroma x1.01 of the parent level (drift compounds along a chain))
