# char__mochi-surprised

- **Approved:** 2026-11-04T15:48:28+00:00 from batch `batch-20-poses-pilot`, job `mochi-surprised`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T15:41:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.99, "cx": 517.5, "cy": 1349.0, "dx": -2, "dy": 0}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-surprised.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and depict the required surprised face: small round o mouth, widened catchlit eyes and long softly raised ears, no head curl or worried/crying face. Both preserve the body and paws with acceptable edit stability0.8240/0.8341 and chroma1.0230/1.1415. Characters have no style lock, so their equal zero lock load is resolved by higher Harmony: take2 at88.6 versus84.5. Light median/haze warnings are advisory under v1; no failed QA is waived. Official post removes the generated background halo; delivery is transparent with no baked cast shadow.

## References

- `design/art/masters/mochi-v2/mochi-v2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6cb3c4faf8cfacad)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi, into a surprised reaction. Change only the face and ears: the mouth becomes a small round soft "o", both eyes grow slightly rounder and wider with their catchlights kept, the long ears lift a little more upright. Body, paws, colors and size stay exactly as they are.

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
- pass: edit_alignment (the edit rescaled the object x1.010 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 34 (R1 51))
- pass: light_values (day/subject: L p2 17 (at most 22), p98 97 (at least 90), spread 80 (at least 60))
- warn: light_median (day/subject: median L 92 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.20 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.7 (at least 3.5))
- pass: detail_budget (detail at display size 3.7 (R1 5.3))
- pass: palette_drift (mean dE 0.9, p95 2.3, off-palette 0.9% (top: #441100 (0.1%), #551100 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: harmony (harmony score 89 against the char reference (outliers: C_p95))
- pass: edit_stability (83% of the parent level unchanged)
- pass: edit_chroma (chroma x1.14 of the parent level (drift compounds along a chain))
