# char__goat-sleepy

- **Approved:** 2026-11-06T01:12:04+00:00 from batch `batch-41-resident-reactions`, job `goat-sleepy`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:32:55+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-sleepy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent read-only comparison evidence: independent-reviews/review-findik-proud-goat-sleepy-goat-proud.json. Both initial takes are visually eligible: genuinely closed thin eyelid lines, relaxed small mouth/brows and drooped ears, with two horn buds, beard tuft, tan patch, body and paws kept. No zzz, tears, worried look, teeth, text or cast shadow. Both hard-pass; character-guard applies no grading, so take2 wins higher Harmony79.8 vs78.8. Exact full1024x1536 lossless467802 bytes fits. Body diagnostics supplement visual review without inventing a global stability threshold; all advisory light warnings retained.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 03f8e66fdd8c5d5b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached baby goat into a sleepy nap face. Change only the eyes, brows, mouth and ears: both eyes become gently closed, a thin soft slightly downward-curved dark line where the lower edge of each eye was, with fur above it; the indignant brows soften; the mouth relaxes into a calm small line; both floppy ears droop a little lower. The horn buds, beard tuft, tan patch, body, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, open eyes, teeth, a ground shadow, text, motion lines, zzz.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 39 (R1 51))
- warn: light_values (day/subject: L p2 65 (at most 22), p98 96 (at least 90), spread 31 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 90 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.39 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 3.0 (at least 3.5))
- pass: detail_budget (detail at display size 3.1 (R1 5.3))
- pass: palette_drift (mean dE 0.8, p95 1.9, off-palette 0.4% (top: #552211 (0.1%), #441100 (0.0%)))
- pass: ground_line (feet at 89.2% of the height (contract 88%))
- pass: harmony (harmony score 80 against the char reference (outliers: L_p2))
- pass: edit_stability (86% of the parent level unchanged)
- pass: edit_chroma (chroma x0.93 of the parent level (drift compounds along a chain))
