# char__mochi-work-beat

- **Approved:** 2026-11-06T10:47:18+00:00 from batch `batch-59-resident-walks`, job `mochi-work-beat`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:22:32+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-work-beat.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 is manually eligible: ONE physical tea glass on ONE saucer held in BOTH paws at chest height, offering it, with preserved Mochi face, cream fur, long curl-free ears, scale and framing except named paw/leg pose and slight sway. Full sources/official locked and 28px proper-alpha views reviewed. Exclude take2 ONLY for a new broad faint real-alpha side backing outside the approved silhouette that survives canonical locking, distinguished from alpha0 hiddenRGB and normal fine fur fringe. Both tea poses otherwise match the brief; no nativeUIglass or style-WARN exclusion. Normal eligible ranking therefore chooses take1 (Harmony88.3), no extra generation or force.

## References

- `design/art/masters/mochi-v2/mochi-v2.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7b4d026962dfc23b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached character, the bunny Mochi, into one animation frame: holding a small tea glass on a saucer in both paws in front of her chest, offering it. Keep the face, the colours, the fur, the size and the exact position on the canvas the same; change only the legs and paws and a slight sway, as a cute cartoon step, never a realistic gait.

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
- pass: chroma_ceiling (chroma p95 37 (R1 51))
- pass: light_values (day/subject: L p2 21 (at most 22), p98 97 (at least 90), spread 77 (at least 60))
- warn: light_median (day/subject: median L 91 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.07 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.1 (at least 3.5))
- pass: detail_budget (detail at display size 4.4 (R1 5.3))
- pass: palette_drift (mean dE 1.3, p95 4.1, off-palette 2.8% (top: #992211 (0.2%), #AA3322 (0.2%)))
- pass: ground_line (feet at 88.0% of the height (contract 88%))
- pass: harmony (harmony score 88 against the char reference (outliers: detail))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_stability (90% of the parent level unchanged)
- pass: edit_chroma (chroma x1.17 of the parent level (drift compounds along a chain))
