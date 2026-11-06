# char__nazli-tail

- **Approved:** 2026-11-05T23:31:45+00:00 from batch `batch-37-nazli-rig-pilot`, job `nazli-tail`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:29:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `nazli-tail.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked initial takes pass independent content and parent comparison: two wide rounded cloud-white tail-fluke lobes join smoothly only at the far upper-right stock tip and stay within the shared1536x1024 canvas. Camera-facing eyes, smile, blush, paper-lantern skin scar and body placement visually retain the published body root; no fins, patch, pier, clouds, text or unrelated objects. Canonical hard QA passes both, edit_stability0.9777/0.9812 and edit_chroma1.0306/1.082 pass. No lock_load metric is reported for these char takes, so the equal-load fallback selects higher Harmony take2 (49.4 versus47.9). Light/Harmony warnings remain advisory. No invented100percent pixel identity or extra geometry threshold, and no manual alignment, palette or alpha cleanup. This is an independent whole-whale edit of nazli-body, not cumulative with other rig parts. Existing stable consumer links preserved. Founder review pending.

## References

- `design/art/masters/nazli-body/nazli-body.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/takes/batch-34-islands-in-game/x-gezgin-f1-harbor/plate__x-gezgin-f1-harbor--t1.webp`: The approved Nazlı: copy her tail fluke (wide, rounded, cloud-white, two lobes) only.

## Prompt (fingerprint f3a0275ea0a84c0a)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. The approved Nazlı: copy her tail fluke (wide, rounded, cloud-white, two lobes) only.

Edit the attached whale. Add her tail flukes: at the soft rounded
tip of the tail stock (the far upper right of the body) grow a wide,
rounded, cloud-white two-lobed fluke, soft and chunky, in the same
three-quarter view and in the same painting, joined smoothly to the
tail stock so it reads as one animal, and small enough to stay
inside the canvas. Only the tail tip changes: her head, face, body,
scar and everything else stay exactly as in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: changing the face or the body, fins, an island patch, clouds, a pier, a shadow, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 16 (R1 51))
- warn: light_values (day/subject: L p2 71 (at most 22), p98 96 (at least 90), spread 25 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 85 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.61 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.1 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: palette_drift (mean dE 1.7, p95 3.8, off-palette 0.0%)
- warn: ground_line (feet at 85.8% of the height (contract 88%))
- warn: harmony (harmony score 49 against the char reference (outliers: C_p95, L_p2, tint_b))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.08 of the parent level (drift compounds along a chain))
