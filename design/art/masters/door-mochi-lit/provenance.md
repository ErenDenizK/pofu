# prop__door-mochi-lit

- **Approved:** 2026-11-06T01:36:40+00:00 from batch `batch-36-lit-ladder-pilot`, job `door-mochi-lit`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T23:22:12.633Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `door-mochi-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. All four full locked images and region crops retain the four glass panes, cream crossbar, rose door, honey frame, knob, step, tea-glass sign and existing peach earth-ring halo. The four panes glow soft candle-amber, while the crossbar remains visibly cream and no new shape or spill reaches sign/door. Warm light remains distinct against light/dark at 28 px. Every outside-mask RGBA pixel exactly equals the day parent. Independent peer review agrees all four eligible; use unchanged official QA ranking.

## References

- `design/art/masters/door-mochi/door-mochi.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1d672a6f9de0aaa6)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light Mochi's door from inside: the small round window with its cream
cross bar now glows warm candle-amber, the four panes of glass soft
and a little brighter toward the middle, painted as soft broad
shapes. Only the window glass changes: the cross bar keeps its cream
color, and the rose door, the honey frame, the knob, the doorstep,
the hanging tea-glass sign and the earth ring keep their exact day
colors (the app adds the glow around the door).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow outside the window, a halo, light on the door or the sign, a changed cross bar, blown yellow-white highlights, text.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 45 (R1 51))
- warn: light_values (day/subject: L p2 54 (at most 22), p98 89 (at least 90), spread 34 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 73 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.30 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.4 (at least 3.5))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.0, p95 2.2, off-palette 0.0%)
- pass: harmony (harmony score 76 against the world reference (outliers: L_p98, edge))
- pass: emit_leak (100% of the parent unchanged outside the emit region (masked out of the master))

Retained-source QA re-post, no new generation. Original run batch-36-lit-ladder-pilot, take 3. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
