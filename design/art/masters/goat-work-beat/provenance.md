# char__goat-work-beat

- **Approved:** 2026-11-06T11:19:14+00:00 from batch `batch-59-resident-walks`, job `goat-work-beat`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:24:03+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-work-beat.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 is eligible: ONE small rope coil hangs directly from the mouth, not held only in the paws, with the approved goat identity, face, colour, scale and registered framing retained except named pose/sway. Full source/locked and proper-alpha 28px views reviewed. Exclude take2 ONLY for a new broad faint alpha backing that persists in official locked above the goat, distinguished from inherited side fringe and hidden alpha0 RGB. Both otherwise satisfy the mouth-coil brief. Manual exclusions precede ranking, so choose take1 PASS despite take2 slightly higher Harmony; no retry, force or invented numeric/style gate.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6adf28476d0afff8)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached character, the harbor goat, into one animation frame: with a small coil of rope hanging from its mouth, as if tidying the pier. Keep the face, the colours, the fur, the size and the exact position on the canvas the same; change only the legs and paws and a slight sway, as a cute cartoon step, never a realistic gait.

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
- pass: chroma_ceiling (chroma p95 44 (R1 51))
- pass: light_values (day/subject: L p2 20 (at most 22), p98 96 (at least 90), spread 76 (at least 60))
- pass: light_median (day/subject: median L 88 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.13 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.6 (at least 3.5))
- pass: detail_budget (detail at display size 4.0 (R1 5.3))
- pass: palette_drift (mean dE 1.3, p95 5.2, off-palette 1.0% (top: #AA5522 (0.1%), #773311 (0.1%)))
- pass: ground_line (feet at 89.7% of the height (contract 88%))
- pass: harmony (harmony score 92 against the char reference (outliers: detail))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_stability (87% of the parent level unchanged)
- pass: edit_chroma (chroma x1.11 of the parent level (drift compounds along a chain))
