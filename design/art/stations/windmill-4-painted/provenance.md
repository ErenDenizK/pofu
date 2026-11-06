# station__windmill-4-painted

- **Approved:** 2026-11-06T00:34:48+00:00 from batch `batch-40-home-ladder-gaps`, job `windmill-4-painted`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:25:01+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `windmill-4-painted.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent source and locked review verifies take1: all four sails each have two sage long-edge bands, one honey central band and one round honey sun at the outer end; all four frames/hub, six cap lanterns, tower/door and three seed sacks retain their same-level reference geometry and colors. No broad haze, glow or background. Take2 remains excluded by official hard edit_chroma1.4667, not a borrowed manual threshold. Take1 is the only eligible initial candidate. Stable prelinked windmill consumer remains byte-identical. Founder review pending.

## References

- `design/art/stations/windmill-4/windmill-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 956ec14d9d672f5b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Paint the four cream sail cloths with a simple painted pattern: each sail cloth gets two soft sage-green bands along its long edges, a honey band in the middle and a round honey sun on its outer end, drawn as broad flat shapes. The sail frames, the tower, the string of lanterns along the cap, the door, the sacks and everything else stay exactly as they are.

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
- pass: chroma_ceiling (chroma p95 35 (R1 51))
- warn: light_values (day/subject: L p2 67 (at most 22), p98 90 (at least 90), spread 23 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 81 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.47 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 3.1 (at least 3.5))
- pass: detail_budget (detail at display size 2.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 4.0, off-palette 0.0% (top: #888866 (0.0%), #998866 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 64 against the world reference (outliers: C_p95, L_p2, edge))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_stability (84% of the parent level unchanged)
- warn: edit_chroma (chroma x1.37 of the parent level (drift compounds along a chain))
