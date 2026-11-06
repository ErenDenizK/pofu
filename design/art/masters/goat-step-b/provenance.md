# char__goat-step-b

- **Approved:** 2026-11-06T11:14:48+00:00 from batch `batch-59-resident-walks`, job `goat-step-b`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:19:16+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-step-b.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and locked frames show viewer-left foot lifted and opposite foot planted, preserving the goat face asymmetry, horns, ears, beard, colours, scale and framing. Proper-alpha 28px views reviewed; broad raw-view glow is alpha0 hiddenRGB, with no persistent locked backdrop found. Inherited parent edge fringe is not a new exclusion. Both QA reports WARN/no hard failure, and normal equal-load/Harmony ranking selects take2.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint be030ba9a802adbe)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached character, the harbor goat, into one animation frame: its right foot (the viewer's left) lifted and stepping forward, the left foot planted, the mirror of the other step, its ears and beard swaying slightly back. Keep the face, the colours, the fur, the size and the exact position on the canvas the same; change only the legs and paws and a slight sway, as a cute cartoon step, never a realistic gait.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: motion lines, dust clouds, a ground, a shadow, a different size, moving the character on the canvas, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- warn: light_values (day/subject: L p2 23 (at most 22), p98 96 (at least 90), spread 74 (at least 60))
- pass: light_median (day/subject: median L 89 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.29 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.4 (at least 3.5))
- pass: detail_budget (detail at display size 3.3 (R1 5.3))
- pass: palette_drift (mean dE 1.1, p95 3.2, off-palette 0.8% (top: #441100 (0.1%), #BB6633 (0.1%)))
- pass: ground_line (feet at 89.6% of the height (contract 88%))
- pass: harmony (harmony score 95 against the char reference (outliers: none))
- warn: edit_silhouette (92% of the parent's shape kept)
- pass: edit_stability (83% of the parent level unchanged)
- pass: edit_chroma (chroma x1.07 of the parent level (drift compounds along a chain))
