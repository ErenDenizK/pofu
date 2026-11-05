# char__goat-work

- **Approved:** 2026-11-05T20:06:10+00:00 from batch `batch-33-home-showcase`, job `goat-work`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T19:57:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `goat-work.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes are eligible by official hardQA and independent parent comparison. Only two forepaws now hold a neat coral rope coil against the chest with one loose end; indignant head/expression, horn buds, ears, beard, eyes, torso, feet, canvas/camera remain stable. No hat, text, ground cast shadow or added curl. Editstability0.9242/0.9316 passes. Character reports omit lock_load, so use equalzero then higherHarmony94.8versus93.5: selecttake1. Source-viewer halo is hidden RGB atalpha0, independently sampled athead/body/underfeet againstparent; no invented opaque-background or workshop-specific zero-border requirement. Full1024x1536 lockedtake1PNG747689bytes, exactlosslessWebPmethod6 fits472600bytes anddecodedRGBAhashmatches; no size/quality/pixel change. Lightwarnings advisory. OwnHarmonymeasure/check, losslessmaster/raw/provenance/contentnode inthisjobcommit. Auto-pickedbyQA; founderreviewpending.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7fb690540ec015c9)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached baby goat into his working pose. Change only his two front paws: they now hold a small, neat coil of soft coral rope against his chest, one loose end hanging down. His head, horn buds, ears, beard, eyes, indignant face, body and feet stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a ground shadow, a hat, text, a different expression.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 43 (R1 51))
- pass: light_values (day/subject: L p2 21 (at most 22), p98 97 (at least 90), spread 75 (at least 60))
- pass: light_median (day/subject: median L 88 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.20 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.0 (at least 3.5))
- pass: detail_budget (detail at display size 3.9 (R1 5.3))
- pass: palette_drift (mean dE 1.3, p95 4.2, off-palette 2.1% (top: #DD7755 (0.3%), #CC6644 (0.2%)))
- pass: ground_line (feet at 89.3% of the height (contract 88%))
- pass: harmony (harmony score 95 against the char reference (outliers: detail))
- pass: edit_stability (92% of the parent level unchanged)
- pass: edit_chroma (chroma x1.12 of the parent level (drift compounds along a chain))
