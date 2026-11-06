# char__mochi-happy

- **Approved:** 2026-11-06T00:09:33+00:00 from batch `batch-41-resident-reactions`, job `mochi-happy`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:01:51+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-happy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass all hard QA and preserve the approved 1024x1536 body, long soft ears, paws, colors and framing. The happy closed upward arcs, wider closed smile and deeper blush read clearly on the official checkerboard sheet; no head curl, teeth, tears, text, motion lines or cast shadow. Parent edit stability is .9486/.9436; char-guard applies no style grading, so equal load is resolved by higher Harmony71.1/70.4, selecting t1. Exact full-size lossless delivery probes fit at432164/438924 bytes; no resizing or pixel changes. Tiny off-subject t1 alpha specks are at most2/255 with none>=8; the apparent raw RGB backdrop is not opaque content, and the official transparency composite is clean. Light warnings remain advisory.

## References

- `design/art/masters/mochi-v2/mochi-v2.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 99960c0c3e9a7418)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi, into her happy face. Change only the eyes and mouth: both eyes become happy closed arcs, the classic smiling ^ shape, each a thick soft dark upward-curved arc at the height of the top of the original eye, with fur below it; the small mouth widens into a slightly bigger smile and the blush deepens a little. Everything else stays exactly as it is.

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
- pass: chroma_ceiling (chroma p95 33 (R1 51))
- warn: light_values (day/subject: L p2 62 (at most 22), p98 98 (at least 90), spread 36 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 92 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.29 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.2 (at least 3.5))
- pass: detail_budget (detail at display size 3.7 (R1 5.3))
- pass: palette_drift (mean dE 0.8, p95 1.8, off-palette 1.2% (top: #441100 (0.2%), #662211 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: harmony (harmony score 71 against the char reference (outliers: C_p95, L_p2))
- pass: edit_stability (95% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
