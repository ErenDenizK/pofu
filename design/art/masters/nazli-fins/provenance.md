# char__nazli-fins

- **Approved:** 2026-11-05T23:42:53+00:00 from batch `batch-37-nazli-rig-pilot`, job `nazli-fins`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:31:00+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `nazli-fins.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked initial takes pass independent content and actual published-body comparison: exactly two pectoral fins, broad rounded cream near fin low just behind the head angled gently back and down, with the far fin showing only its rounded tip below the far belly. Neither covers face or eyes. Camera-facing head, faint smile, blush, paper-lantern scar, body placement and rounded tail-stock tip remain visually registered on shared1536x1024 canvas; no flukes, island patch, scenery, text or other objects. Canonical hard QA passes both, edit_stability0.9777/0.9636 and edit_chroma1.0132/0.9687 pass. No lock_load is reported for char takes; equal-load fallback selects higher Harmony take2 (46.6 versus46.5). Light and Harmony warnings advisory. No stricter invented stability criterion or manual geometry, palette or alpha cleanup. Direct whole-whale body edit, not cumulative with tail. Stable consumer links unchanged. Founder review pending.

## References

- `design/art/masters/nazli-body/nazli-body.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/takes/batch-34-islands-in-game/x-gezgin-f1-harbor/plate__x-gezgin-f1-harbor--t1.webp`: The approved Nazlı: copy her broad, rounded, cream flipper only.

## Prompt (fingerprint 30301c2ea48db9a3)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. The approved Nazlı: copy her broad, rounded, cream flipper only.

Edit the attached whale. Add her two pectoral fins: the nearer fin
hangs from the low near side of the body just behind the head,
broad, rounded and cream, angled gently back and down, and the
farther fin shows only its rounded tip below the belly on the far
side, in the same three-quarter view and the same painting. Neither
fin covers her face or her eye. Only the two fins are added: her
head, face, body, scar and everything else stay exactly as in the
attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: fins over her face, changing the face or the body, flukes, an island patch, clouds, a pier, a shadow, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 17 (R1 51))
- warn: light_values (day/subject: L p2 71 (at most 22), p98 94 (at least 90), spread 24 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 84 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.62 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.1 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: palette_drift (mean dE 1.5, p95 3.1, off-palette 0.0%)
- pass: ground_line (feet at 89.0% of the height (contract 88%))
- warn: harmony (harmony score 47 against the char reference (outliers: C_p95, L_p2, tint_b))
- pass: edit_stability (96% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
