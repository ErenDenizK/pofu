# station__windmill-5-painted

- **Approved:** 2026-11-06T00:39:19+00:00 from batch `batch-40-home-ladder-gaps`, job `windmill-5-painted`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:25:22+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `windmill-5-painted.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent source and locked review verifies take2: all four sails each carry two sage long-edge bands, one honey middle band and one round honey sun at outer end. Existing four frames/hub, flag, two round crossbar windows with flower boxes, six cap lanterns, door and three sacks preserve same-level positions and shapes. No extra jars are invented where actual parent has none, and no haze or background is added. Take1 hard-fails declared edit_chroma1.4447. Take2 is the only eligible initial candidate. Stable windmill consumer remains unchanged. Founder review pending.

## References

- `design/art/stations/windmill-5/windmill-5.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 3ab299838149f675)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Paint the four cream sail cloths with a simple painted pattern: each sail cloth gets two soft sage-green bands along its long edges, a honey band in the middle and a round honey sun on its outer end, drawn as broad flat shapes. The sail frames, the tower, the flag, the windows and their flower boxes, the jars, the door, the sacks and everything else stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: changing the shape, size or position of any part, new props, a different camera, a baked shadow, a glow, text.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 43 (R1 51))
- warn: light_values (day/subject: L p2 65 (at most 22), p98 90 (at least 90), spread 25 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.40 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- pass: light_contrast (day/subject: p75 local contrast 4.0 (at least 3.5))
- pass: detail_budget (detail at display size 2.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.3, p95 3.0, off-palette 0.0% (top: #AA9966 (0.0%), #888866 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 76 against the world reference (outliers: edge))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_stability (82% of the parent level unchanged)
- warn: edit_chroma (chroma x1.41 of the parent level (drift compounds along a chain))
