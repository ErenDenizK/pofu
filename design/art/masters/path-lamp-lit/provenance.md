# prop__path-lamp-lit

- **Approved:** 2026-11-06T01:30:26+00:00 from batch `batch-36-lit-ladder-pilot`, job `path-lamp-lit`, take t1
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T23:11:16.560Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 5, "dy": 10}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `path-lamp-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. All four full locked images and region crops retain the plump paper-glass lantern, coral cap, hook, wood post and stone foot. Soft warm candle-amber fills the glass with a small broad central flame impression, no sharp flame, rays, ground pool or exterior halo. The warm light remains visible in light/dark 28 px diagnostics; full-canvas rendering is small, and the same fixed-parent-bounds 28 px rendering also stays distinct from unlit parent. Every outside-mask RGBA pixel exactly equals the day parent. All four manually eligible; use unchanged official QA ranking.

## References

- `design/art/masters/path-lamp/path-lamp.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 2d396615642dc8f9)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the path lamp: the plump round paper-glass lantern now glows
from inside, a soft warm candle-amber filling the whole glass shape,
a little brighter toward its middle, with a tiny soft flame shape
suggested at its center, painted as soft broad shapes. Only the
lantern glass changes: the coral cap, the curled hook, the wooden
post and the stone foot keep their exact day colors (the app adds
the glow and the pool of light on the ground).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow or halo outside the glass, a light pool on the ground, light on the post or the cap, a sharp bright flame, blown yellow-white highlights, text.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 57 (R1 51))
- warn: light_values (day/subject: L p2 56 (at most 22), p98 88 (at least 90), spread 32 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 74 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.2 (at least 3.5))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 2.1, p95 7.1, off-palette 0.7% (top: #BB6633 (0.5%), #CC7744 (0.1%)))
- pass: harmony (harmony score 74 against the world reference (outliers: C_p95, L_p98, edge))
- pass: emit_leak (100% of the parent unchanged outside the emit region (masked out of the master))

Retained-source QA re-post, no new generation. Original run batch-36-lit-ladder-pilot, take 1. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
