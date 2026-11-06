# char__goat-proud

- **Approved:** 2026-11-06T01:17:00+00:00 from batch `batch-41-resident-reactions`, job `goat-proud`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:36:52+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-proud.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent read-only comparison evidence: independent-reviews/review-findik-proud-goat-sleepy-goat-proud.json. Both initial takes are visually eligible: the exact detailed prompt asks a high lifted chin, content half-closed eyes WITH catchlights and a small symmetric satisfied closed smile, with ears perked. These details take precedence over the abbreviated header; no sneer, smirk, teeth, tears or motion. Two horn buds, beard, tan patch, lower body and paws remain visually registered. Global stability.6593/.6326 is advisory for the requested large face/chin edit; central body kept.9920/.9917 supports the identity review, without a new threshold. Both hard-pass; char-guard applies no grading, so take1 wins higher Harmony78.1 vs76.9. Exact full1024x1536 lossless473432 bytes fits. No retry or pixel alteration needed.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 138d6a093f3ea207)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached baby goat into a proud reaction. Change only the face and ears: the chin lifts high, both eyes become calm, content half-closed lids with the catchlights kept, the brows relax, the flat mouth becomes a small, satisfied closed smile, and the floppy ears perk up a little. The horn buds, beard tuft, tan patch, body, paws, colors and size stay exactly as they are.

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
- pass: chroma_ceiling (chroma p95 38 (R1 51))
- warn: light_values (day/subject: L p2 61 (at most 22), p98 96 (at least 90), spread 35 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 89 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.36 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 2.9 (at least 3.5))
- pass: detail_budget (detail at display size 3.0 (R1 5.3))
- pass: palette_drift (mean dE 1.0, p95 2.9, off-palette 0.8% (top: #EE7766 (0.1%), #441100 (0.1%)))
- pass: ground_line (feet at 89.4% of the height (contract 88%))
- pass: harmony (harmony score 78 against the char reference (outliers: L_p2))
- warn: edit_stability (66% of the parent level unchanged)
- pass: edit_chroma (chroma x1.00 of the parent level (drift compounds along a chain))
