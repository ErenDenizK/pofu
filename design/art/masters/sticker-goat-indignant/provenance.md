# char__sticker-goat-indignant

- **Approved:** 2026-11-06T06:28:33+00:00 from batch `batch-42-stickers`, job `sticker-goat-indignant`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-06T02:22:20.778Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `sticker-goat-indignant.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained-only re-post of four historical originals on the author-fixed native 1024 square canvas with ground_line:false; original ordinals/account/generation timestamps preserved; no new generation. Manual full-body/expression/identity and proper light/dark 28 px checks passed. Official advisory light/palette/Harmony warnings remain advisory; hard QA failures are excluded.

## References

- `design/art/masters/harbor-goat/harbor-goat.webp`: The harbor goat: its exact look, fur, colors and eyes.

## Prompt (fingerprint 649f35a2e6771bb5)

```text
REFERENCES (attached, in this order):
1. The harbor goat: its exact look, fur, colors and eyes.

A single full-body sticker of the harbor goat in the exact attached look, chin lifted, a closed-eyed huff, indignant and a little proud, a reluctant half-smile. Centred on a plain transparent background with wide empty space around it, drawn complete with the whole body. No text, no speech bubbles, no floating hearts, no sticker border, no ground shadow.

AVOID: text, a white outline, a background, teeth, tears, motion lines, a different design.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- warn: light_values (day/subject: L p2 62 (at most 22), p98 97 (at least 90), spread 34 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 88 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.40 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 2.1 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 3.3 (R1 5.3))
- pass: palette_drift (mean dE 1.1, p95 2.8, off-palette 0.4% (top: #552211 (0.1%), #441100 (0.0%)))
- pass: harmony (harmony score 80 against the char reference (outliers: L_p2))

Retained-source QA re-post, no new generation. Original run batch-42-stickers, take 4. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
