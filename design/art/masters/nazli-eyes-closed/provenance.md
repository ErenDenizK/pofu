# char__nazli-eyes-closed

- **Approved:** 2026-11-05T23:55:15+00:00 from batch `batch-37-nazli-rig-pilot`, job `nazli-eyes-closed`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:34:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `nazli-eyes-closed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked initial takes were directly reviewed by the operator against the actual published body after environment recovery. The nearer eye and the far visible eye edge are peacefully closed with soft downward-curved lid lines and skin filling the former eye openings, at the same observed eye locations and shapes. Blush, faint smile, paper-lantern skin scar, smooth bare body, rounded stock tip, camera and shared1536x1024 registration remain visually consistent with root. No tears, frown, eyebrows, new fins, tail flukes, island patch, text or unrelated object. Canonical hard QA passes both; edit_stability0.9814 both and edit_chroma1.024/1.0959 pass. No char lock_load metric is reported; both Harmony scores44.8 tie, so deterministic earliest take1 wins. Light/Harmony warnings advisory. No invented stricter eye-geometry or stability threshold and no manual alignment, palette or alpha cleanup. Invisible surrounding RGB is not painted background. Exact source, packet and post identities survived the interruption; no duplicate dispatch or retry. Direct whole-whale edit of body, not cumulative with other parts. Stable consumer links unchanged. Founder review pending.

## References

- `design/art/masters/nazli-body/nazli-body.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/takes/batch-34-islands-in-game/x-gezgin-f1-harbor/plate__x-gezgin-f1-harbor--t1.webp`: The approved Nazlı: her eye shape and heavy kind lid (copy the whale only).

## Prompt (fingerprint 208c59aca91c31f8)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. The approved Nazlı: her eye shape and heavy kind lid (copy the whale only).

Edit the attached whale. Close her eyes: the nearer eye and the
farther eye (or its visible edge) become peacefully closed, a soft
downward-curving lid line with the lid's skin color filling the eye,
calm and sleepy and kind. The eyes keep exactly the same positions,
sizes and shapes as the open eyes. Only the eyes change: the
blush, the smile, the scar and the whole rest of the whale stay
exactly as in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: open eyes, tears, a frown, changed eye positions, eyebrows, any change to the body, text

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
- warn: light_values (day/subject: L p2 71 (at most 22), p98 94 (at least 90), spread 23 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 84 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.63 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 0.9 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.4 (R1 5.3))
- pass: palette_drift (mean dE 1.4, p95 3.1, off-palette 0.0%)
- warn: ground_line (feet at 85.9% of the height (contract 88%))
- warn: harmony (harmony score 45 against the char reference (outliers: C_p95, L_p2, detail, tint_b))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.02 of the parent level (drift compounds along a chain))
