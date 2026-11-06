# char__findik-happy

- **Approved:** 2026-11-06T00:23:39+00:00 from batch `batch-41-resident-reactions`, job `findik-happy`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:12:48+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 1.008, "cx": 431.5, "cy": 1172.0, "dx": 5, "dy": 2}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `findik-happy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take2 is the only fully eligible initial take; take1 fails hard palette drift with13.6 percent off-palette and is never selected. Closed upward smiling arcs and the slightly wider closed smile read clearly; spines, body, paws, colors and framing remain the approved hedgehog family, no teeth/tears/text/motion or cast shadow. Official canvas870x1306 is exactly the declared parent canvas; edit stability.9251, central belly/paws kept.9418 and alpha IoU.9797 support the registered body review, with normal resampled fur rather than a new pose. Full-size lossless WebP573014 bytes is RGBA-identical to official locked output; no local resize or recolor. Advisory light/palette warnings retained. All three planned Findik reaction links are added to the existing character consumer with this first success and then kept byte-stable; pending assets remain planned, with no fake image links.

## References

- `design/art/masters/findik-base/findik-base.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9b9ac7c1ffdec7ac)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hedgehog, Fındık, into his happy face. Change only the eyes and mouth: both eyes become happy closed arcs, the classic smiling ^ shape, each a thick soft dark upward-curved arc at the height of the top of the original eye; the small mouth widens into a slightly bigger smile. His spines, body, paws, colors and size stay exactly as they are.

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
- pass: canvas (1024x1536 scaled x0.850 into 870x1306)
- pass: edit_alignment (the edit rescaled the object x0.992 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- warn: light_values (day/subject: L p2 42 (at most 22), p98 96 (at least 90), spread 54 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 85 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.13 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 9.2 (at least 3.5))
- pass: detail_budget (detail at display size 6.6 (R1 5.3))
- warn: palette_drift (mean dE 3.1, p95 13.7, off-palette 7.9% (top: #AA5533 (2.3%), #BB6633 (1.1%)))
- pass: ground_line (feet at 89.9% of the height (contract 88%))
- pass: harmony (harmony score 75 against the char reference (outliers: L_p2, detail))
- pass: edit_stability (93% of the parent level unchanged)
- pass: edit_chroma (chroma x1.01 of the parent level (drift compounds along a chain))
