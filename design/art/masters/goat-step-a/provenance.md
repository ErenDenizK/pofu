# char__goat-step-a

- **Approved:** 2026-11-06T11:03:17+00:00 from batch `batch-59-resident-walks`, job `goat-step-a`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:14:03+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-step-a.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 preserves the approved goat face, horns, beard, colours, scale and framing, with viewer-right foot raised and opposite foot planted. Full source/locked and 28px alpha composites reviewed. Exclude take2 ONLY for a genuinely new broad faint alpha backing surviving official locking above the character, distinguished from inherited side fringe and alpha0 hiddenRGB. No sole-colour/anatomy or new numeric/style gate. Take1 is eligible and also has the higher normal Harmony score.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9ccc26e7962b6b3f)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached character, the harbor goat, into one animation frame: its left foot (the viewer's right) lifted and stepping forward, the right foot planted, the body leaning a tiny bit forward, its ears and beard swaying slightly back. Keep the face, the colours, the fur, the size and the exact position on the canvas the same; change only the legs and paws and a slight sway, as a cute cartoon step, never a realistic gait.

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
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- pass: light_values (day/subject: L p2 22 (at most 22), p98 96 (at least 90), spread 74 (at least 60))
- pass: light_median (day/subject: median L 89 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.27 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.3 (at least 3.5))
- pass: detail_budget (detail at display size 3.3 (R1 5.3))
- pass: palette_drift (mean dE 1.1, p95 3.1, off-palette 0.7% (top: #441100 (0.1%), #662211 (0.1%)))
- pass: ground_line (feet at 89.2% of the height (contract 88%))
- pass: harmony (harmony score 96 against the char reference (outliers: none))
- pass: edit_silhouette (94% of the parent's shape kept)
- pass: edit_stability (86% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
