# char__damla-glass

- **Approved:** 2026-11-06T07:46:17+00:00 from batch `batch-43-caglayan-production`, job `damla-glass`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T07:28:27+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 1.0403, "cx": 530.5, "cy": 893.0, "dx": 8, "dy": 8}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `damla-glass.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both native originals and the official aligned locked poses show the same soft cocoa and cream otter raising ONE tulip glass above the head in both paws, glass half full of clear water with one tiny glint, closed happy curved eyes, open toothless smile and lifted curled tail. Source, full locked alpha and original parent were reviewed; no floor, cast shadow, spill, text, new curl or identity drift. Take1 passes every hard QA check and has higher Harmony78.8 versus77.2. Take2 preserves its actual edit_silhouette FAIL and the authored pose exception is not used because the normally passing take1 wins. Exact native lossless492724byte master matches canonical RGBA under614400 without manual resize or cleanup. Existing planned two-asset character links remain unchanged. No extra retry or header force was needed.

## References

- `design/art/masters/damla/damla.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 703e6e2f3f6e8c03)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached otter: the same character, the same size, on the
same ground line, in the same place on the canvas. She now lifts the
little tea glass up with both paws above her head, proud and happy;
the glass is half full of clear water with a tiny glint. Her eyes are
closed in two happy upward curves and she has a big open smile. Her
tail curls up a little with joy. Everything else (fur colours,
proportions, style, lighting) stays exactly the same.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a full glass, spilled water, splashes, teeth, a different size, moving her on the canvas, a ground, a shadow, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: edit_alignment (the edit rescaled the object x0.961 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- warn: light_values (day/subject: L p2 32 (at most 22), p98 93 (at least 90), spread 61 (at least 60))
- pass: light_median (day/subject: median L 70 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.12 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.2 (at least 3.5))
- pass: detail_budget (detail at display size 6.2 (R1 5.3))
- warn: palette_drift (mean dE 3.2, p95 9.9, off-palette 2.9% (top: #441100 (0.2%), #993322 (0.2%)))
- pass: ground_line (feet at 88.0% of the height (contract 88%))
- warn: no_ground_shadow (a ground shadow seems painted in)
- pass: harmony (harmony score 79 against the char reference (outliers: L_p2, detail))
- warn: edit_silhouette (86% of the parent's shape kept)
- pass: edit_stability (62% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
