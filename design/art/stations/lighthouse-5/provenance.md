# station__lighthouse-5

- **Approved:** 2026-11-05T06:30:05+00:00 from batch `batch-21-harbor-ladders`, job `lighthouse-5`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:28:19+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-5.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Exactly4 takes after one allowed retry. Take1 fails hard chroma/palette; takes2/4 fail hard height geometry; take3 is the only hard-QA-passing candidate, load1.6257 and Harmony75.2. Visual review confirms a small plain coral flag on a thin cap pole, soft green leaves, cream/coral flowers and exactly two rounded pebbles inside the existing base footprint. Tower, balcony, lamp bands/reflector, door/window and scale remain; no rays, beam, exterior halo or shadow. Edit stability0.9334 and chroma1.1946. Growth report: requested flag raises top to52 versus parent bar140, an existing station_anchor warning rather than hard failure; no whole-object shrinking or edit guide fit is applied. Chroma/light/palette/edit-chroma warnings are recorded, not silently discarded; all hard gates pass unchanged. Founder review pending.

## References

- `design/art/stations/lighthouse-4/lighthouse-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 96f5ddfed886b42e)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small coral flag on a thin pole at the lamp room's cap, and at the tower's foot a little garden patch of soft green leaves with a few round cream and coral flowers and two round pebbles, inside the footprint.

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
- warn: chroma_ceiling (chroma p95 59 (R1 51))
- warn: light_values (day/subject: L p2 46 (at most 22), p98 93 (at least 90), spread 47 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 78 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.11 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.6 (at least 3.5))
- pass: detail_budget (detail at display size 3.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 3.0, p95 11.8, off-palette 4.8% (top: #CC7733 (0.4%), #778844 (0.4%)))
- warn: station_anchor (top y 52 above the parent's bar (140))
- pass: harmony (harmony score 75 against the world reference (outliers: C_p95, detail, edge))
- pass: edit_stability (93% of the parent level unchanged)
- warn: edit_chroma (chroma x1.19 of the parent level (drift compounds along a chain))
