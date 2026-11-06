# char__koke-one-eye

- **Approved:** 2026-11-06T02:16:12+00:00 from batch `batch-39-koke-production`, job `koke-one-eye`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T01:54:36+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `koke-one-eye.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes clear every hard check and retain the approved1024x1024 moss body, tucked paws, crown leaves/clover, ears, palette and baseline. Exactly one eye opens as a small sleepy warm-brown half-moon with a catchlight while the other stays closed, and the mouth becomes a small soft breath-o. The near-front camera does not identify a literal viewer side; selected take1 uses the viewer-right eye and does not invent a side requirement for take2. No teeth, extra eye, ground, shadow, head curl, flower or text. Character-guard lock loads are equal0; take1 wins higher Harmony66.0 versus64.4. Full locked review supports face-only registration, with ordinary resampled fur retained rather than claiming byte-identical texture. Source binds to actual re-promoted/upload-verified asleep parent.

## References

- `design/art/masters/koke-asleep/koke-asleep.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint f7eff8365388b226)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached moss creature, Koke. Change only the face: the
nearer eye opens a sliver, a soft sleepy half-moon of warm brown
iris with a small catchlight under a heavy lid; the farther eye
stays gently closed; the mouth relaxes into a small soft "o" of a
sleepy breath. The body, the moss, the sprout, the ears, the paws,
the colours and the size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: both eyes open, a wide awake look, teeth, a frown, a glow, tears, any change to the body, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 56 (R1 51))
- warn: light_values (day/subject: L p2 49 (at most 22), p98 94 (at least 90), spread 45 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 79 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.13 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.8 (at least 3.5))
- pass: detail_budget (detail at display size 5.9 (R1 5.3))
- warn: palette_drift (mean dE 3.5, p95 12.3, off-palette 5.7% (top: #BBBB55 (0.5%), #AABB44 (0.5%)))
- pass: ground_line (feet at 88.1% of the height (contract 88%))
- warn: no_ground_shadow (a ground shadow seems painted in)
- warn: harmony (harmony score 66 against the char reference (outliers: C_p95, L_p2, detail))
- pass: edit_stability (99% of the parent level unchanged)
- pass: edit_chroma (chroma x0.96 of the parent level (drift compounds along a chain))
