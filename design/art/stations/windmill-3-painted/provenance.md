# station__windmill-3-painted

- **Approved:** 2026-11-06T00:23:09+00:00 from batch `batch-40-home-ladder-gaps`, job `windmill-3-painted`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:16:56+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `windmill-3-painted.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and independent source plus locked review. All four cloth sails each carry two sage long-edge bands, one honey center band and one round honey sun at its outer end. Four sail frames, tower, closed door, three seed sacks, camera and geometry are retained without exterior haze or glow. Auto-pick take2 by lower lock load0.7221 versus0.9405; Harmony79.5 versus67.9 also favors2. Declared region acceptance is honored without a borrowed stability gate. Three existing planned windmill variant nodes were prelinked once before this first successful family promotion; actual images/status remain per-job and this consumer stays byte-identical afterward. Founder review pending.

## References

- `design/art/stations/windmill-3/windmill-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 0b077f77a26fa8a5)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Paint the four cream sail cloths with a simple painted pattern: each sail cloth gets two soft sage-green bands along its long edges, a honey band in the middle and a round honey sun on its outer end, drawn as broad flat shapes. The sail frames, the tower, the door, the sacks of seeds and everything else stay exactly as they are.

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
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- warn: light_values (day/subject: L p2 62 (at most 22), p98 91 (at least 90), spread 29 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 80 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.39 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- pass: light_contrast (day/subject: p75 local contrast 4.0 (at least 3.5))
- pass: detail_budget (detail at display size 2.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 5.3, off-palette 0.3% (top: #888866 (0.2%), #998866 (0.1%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 80 against the world reference (outliers: edge))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_stability (82% of the parent level unchanged)
- warn: edit_chroma (chroma x1.39 of the parent level (drift compounds along a chain))
