# char__simit-happy

- **Approved:** 2026-11-04T15:42:56+00:00 from batch `batch-20-poses-pilot`, job `simit-happy`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T15:40:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9996, "cx": 546.5, "cy": 1421.0, "dx": 0, "dy": 0}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-happy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 keeps the required widened w-shaped mouth and thick closed happy eye arcs, the tabby markings, scarf and paws. Take2 is excluded because its mouth becomes a plain U rather than preserving the w. Official post removes the generated background halo; the delivered transparent master has no baked cast shadow. Edit stability0.9529 and edit chroma1.0266 pass. Light-standard and ground-line/harmony warnings remain advisory; no failed check is waived. Characters are not style locked.

## References

- `design/art/masters/simit-kitten/simit-kitten.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 726ce6ca8e861b5d)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached kitten, Simit, into her happy face. Change only the eyes and mouth: both eyes become happy closed arcs, the classic smiling ^ shape, each a thick soft dark upward-curved arc at the height of the top of the original eye, with fur below it; the "w" mouth widens into a slightly bigger smile. Everything else stays exactly as it is.

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
- pass: edit_alignment (the edit rescaled the object x1.000 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 55 (R1 51))
- warn: light_values (day/subject: L p2 56 (at most 22), p98 95 (at least 90), spread 40 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.19 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.4 (at least 3.5))
- pass: detail_budget (detail at display size 4.9 (R1 5.3))
- pass: palette_drift (mean dE 1.4, p95 4.1, off-palette 0.5% (top: #552211 (0.1%), #BB4433 (0.1%)))
- warn: ground_line (feet at 92.5% of the height (contract 88%))
- warn: harmony (harmony score 70 against the char reference (outliers: C_p95, L_p2, detail))
- pass: edit_stability (95% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
