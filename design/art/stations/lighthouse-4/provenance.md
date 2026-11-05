# station__lighthouse-4

- **Approved:** 2026-11-05T06:14:50+00:00 from batch `batch-21-harbor-ladders`, job `lighthouse-4`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:12:18+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 is the only hard-QA-passing candidate; take2 fails station_anchor with top0 and width945, so cannot be promoted. Visual review of take1 confirms exactly two thin cream lens bands around the existing lamp room and a small round reflector disc behind the lamp, with no painted beam, rays, exterior halo or changes outside the lamp room. Existing balcony, tower, door/window, footprint and framing remain. Edit stability0.9668, chroma0.9355, style-lock load1.1504, Harmony84.1. Parent station-anchor passes; only chroma/light warnings remain advisory. No root guide fit or threshold change. Founder review pending.

## References

- `design/art/stations/lighthouse-3/lighthouse-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7859bfcf722e4247)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

The painted change is small, the beam is code: add two tiny cream glass-lens bands around the lamp room and a small round reflector disc behind the lamp so a beam can be anchored there. Nothing is painted outside the lamp room; no beam, no rays.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 56 (R1 51))
- warn: light_values (day/subject: L p2 51 (at most 22), p98 93 (at least 90), spread 42 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 79 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.14 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.8 (at least 3.5))
- pass: detail_budget (detail at display size 2.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.2)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 8.3, off-palette 1.9% (top: #DD9933 (0.2%), #CC8822 (0.2%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 84 against the world reference (outliers: detail, edge))
- pass: edit_stability (97% of the parent level unchanged)
- pass: edit_chroma (chroma x0.94 of the parent level (drift compounds along a chain))
