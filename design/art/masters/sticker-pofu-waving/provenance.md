# char__sticker-pofu-waving

- **Approved:** 2026-11-06T06:03:12+00:00 from batch `batch-42-stickers`, job `sticker-pofu-waving`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-06T02:18:46.994Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `sticker-pofu-waving.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained-only re-post of four historical originals on the author-fixed native 1024 square canvas with ground_line:false; original ordinals/account/generation timestamps preserved; no new generation. Manual full-body/expression/identity and proper light/dark 28 px checks passed. Official advisory light/palette/Harmony warnings remain advisory; hard QA failures are excluded.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Pofu, the hamster: his exact look, fur, colors, eyes and signature curl.

## Prompt (fingerprint 49206bd4043f38db)

```text
REFERENCES (attached, in this order):
1. Pofu, the hamster: his exact look, fur, colors, eyes and signature curl.

A single full-body sticker of Pofu the hamster in the exact attached look, one paw raised in a friendly wave, a warm smile, eyes open. Centred on a plain transparent background with wide empty space around it, drawn complete with the whole body. No text, no speech bubbles, no floating hearts, no sticker border, no ground shadow.

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
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- pass: light_values (day/subject: L p2 18 (at most 22), p98 97 (at least 90), spread 79 (at least 60))
- pass: light_median (day/subject: median L 88 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.24 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.6 (at least 3.5))
- pass: detail_budget (detail at display size 4.8 (R1 5.3))
- pass: palette_drift (mean dE 2.0, p95 7.2, off-palette 2.8% (top: #DD8844 (0.3%), #EE7766 (0.2%)))
- pass: harmony (harmony score 86 against the char reference (outliers: detail, tint_b))

Retained-source QA re-post, no new generation. Original run batch-42-stickers, take 4. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
