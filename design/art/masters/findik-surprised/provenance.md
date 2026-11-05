# char__findik-surprised

- **Approved:** 2026-11-05T05:43:37+00:00 from batch `batch-20-poses`, job `findik-surprised`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T23:20:32.003Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 1.0053, "cx": 435.5, "cy": 1172.0, "dx": 1, "dy": 2}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `findik-surprised.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Salvaged from the four original PNGs retained in PR157, with zero new image calls. The lead approved the parent canvas870x1306 in PR158; official post fits that manifest canvas, preserving the parent framing. Takes1/4 still fail real palette_drift; eligible takes2/3 pass. Characters have zero style-lock load, so take3 wins on Harmony87.0 versus85.1. Visual review confirms the small round o mouth, wide catchlit eyes, unchanged spines/body/paws and no curl or tears. Edit stability0.9191, chroma0.9862. Only palette warning remains advisory. Original source hashes and generation timestamps are retained. Replaces the historical delivery-cap skip without regeneration; founder review pending.

## References

- `design/art/masters/findik-base/findik-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 13f7633e600002b7)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hedgehog, Fındık, into a surprised reaction. Change only the face: the mouth becomes a small round soft "o", both eyes grow slightly rounder and wider with their catchlights kept. His spines, body, paws, colors and size stay exactly as they are.

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
- pass: canvas (1024x1536 scaled x0.850 into 870x1306)
- pass: edit_alignment (the edit rescaled the object x0.995 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 49 (R1 51))
- pass: light_values (day/subject: L p2 15 (at most 22), p98 96 (at least 90), spread 81 (at least 60))
- pass: light_median (day/subject: median L 84 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.12 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 9.5 (at least 3.5))
- pass: detail_budget (detail at display size 6.9 (R1 5.3))
- warn: palette_drift (mean dE 3.1, p95 13.1, off-palette 6.8% (top: #AA5533 (1.7%), #994422 (0.9%)))
- pass: ground_line (feet at 89.9% of the height (contract 88%))
- pass: harmony (harmony score 87 against the char reference (outliers: detail))
- pass: edit_stability (92% of the parent level unchanged)
- pass: edit_chroma (chroma x0.99 of the parent level (drift compounds along a chain))
