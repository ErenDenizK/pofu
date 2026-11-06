# char__mochi-sleepy

- **Approved:** 2026-11-06T00:44:46+00:00 from batch `batch-41-resident-reactions`, job `mochi-sleepy`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:23:11+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-sleepy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes hard-pass and show genuinely closed thin lower eyelids with fur above, a calm small mouth line, and the long soft ears folded subtly outward/down from the base; no open eyes, tears, worried look, teeth, zzz or motion lines. Body and paws remain registered: central kept .9950/.9966, global edit kept .8597/.8659 includes the requested face/ear changes. No invented global stability gate. Character-guard applies no grading, so take1 wins Harmony70.6 vs69.8. Exact full-canvas lossless WebP440158 bytes preserves official locked RGBA. Advisory light warnings retained; no local resize/recolor. Remaining planned Mochi reaction links are added only with this success and kept stable afterwards; the original happy consumer receipt remains immutable.

## References

- `design/art/masters/mochi-v2/mochi-v2.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7b39413d27dd0b93)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi, into a sleepy nap face. Change only the eyes and ears: both eyes become gently closed, a thin soft slightly downward-curved dark line where the lower edge of each eye was, with fur above it; both long ears fold a little down and outward. The mouth relaxes into a calm small line. Everything else stays exactly as it is.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, open eyes, teeth, a ground shadow, text, motion lines, zzz.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 31 (R1 51))
- warn: light_values (day/subject: L p2 66 (at most 22), p98 98 (at least 90), spread 32 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 93 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.36 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 3.0 (at least 3.5))
- pass: detail_budget (detail at display size 3.6 (R1 5.3))
- pass: palette_drift (mean dE 0.6, p95 1.3, off-palette 0.5% (top: #552211 (0.1%), #CC6644 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: harmony (harmony score 71 against the char reference (outliers: C_p95, L_p2))
- pass: edit_stability (86% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
