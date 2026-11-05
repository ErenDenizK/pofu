# station__pier-4

- **Approved:** 2026-11-05T06:21:11+00:00 from batch `batch-21-harbor-ladders`, job `pier-4`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:15:16+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pier-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and the parent station-anchor check. Select take1 for lowest style-lock load1.0700 versus1.0973; Harmony74.9. Visual review counts exactly two tiny tulip tea glasses of amber tea on a small round cream tray beside a honey wooden bench at the inner end, facing the view. Original ferry, rope, lantern, planks/posts, frame and scale remain; no water, wake, smoke or ground shadow. Edit stability0.9242, chroma1.0114. Chroma/light/palette warnings stay advisory; no width-growth warning or root guide fit. Founder review pending.

## References

- `design/art/stations/pier-3/pier-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9736eafde2b54184)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small honey wooden bench on the inner end of the pier, facing the view, and on the planks beside it two tiny tulip tea glasses of warm amber tea on a small round cream tray. Nothing else changes.

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
- warn: chroma_ceiling (chroma p95 54 (R1 51))
- warn: light_values (day/subject: L p2 43 (at most 22), p98 91 (at least 90), spread 48 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 74 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.13 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 7.0 (at least 3.5))
- pass: detail_budget (detail at display size 3.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 2.8, p95 13.2, off-palette 6.3% (top: #557788 (1.2%), #558899 (0.8%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 75 against the world reference (outliers: detail, edge))
- pass: edit_stability (92% of the parent level unchanged)
- pass: edit_chroma (chroma x1.01 of the parent level (drift compounds along a chain))
