# char__mochi-proud

- **Approved:** 2026-11-06T00:51:57+00:00 from batch `batch-41-resident-reactions`, job `mochi-proud`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:28:42+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `mochi-proud.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent read-only review accepts take1: tall upright ears are expressly requested, warm half-closed catchlit eyes, small closed confident smile and lifted chin; no curl, smirk or teeth. Parent lower-body/paws/feet remain visually registered. Exclude take2 because official alignment scale1.1769 visibly enlarges the torso and shifts front paws, violating unchanged body/size; this is not an invented stability threshold or an objection to upright ears. Independently, its best exact lossless WebP767690 bytes exceeds614400; all failed encodings are preserved. Take1 exact full-canvas lossless593344 bytes fits. Both numerical QA reports and advisory warnings remain available. No further pair is justified because take1 is fully eligible. Independent evidence: independent-reviews/review-mochi-proud-goat-surprised.json.

## References

- `design/art/masters/mochi-v2/mochi-v2.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 5647a447b66ce90f)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi, into a proud reaction. Change only the face and ears: the chin lifts a touch, both eyes become calm, content half-closed lids with the catchlights kept, the small mouth becomes a quietly confident closed smile, the blush deepens a little, and the long ears stand tall and upright. Body, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a smirk, a sneer, tears, a worried look, teeth, a ground shadow, text, motion lines.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- warn: light_values (day/subject: L p2 64 (at most 22), p98 97 (at least 90), spread 33 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 91 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.43 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 2.2 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 3.4 (R1 5.3))
- pass: palette_drift (mean dE 0.8, p95 1.9, off-palette 0.6% (top: #441100 (0.1%), #EE7766 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: harmony (harmony score 72 against the char reference (outliers: C_p95, L_p2))
- warn: edit_stability (71% of the parent level unchanged)
- pass: edit_chroma (chroma x1.10 of the parent level (drift compounds along a chain))
