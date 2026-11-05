# station__lighthouse-2

- **Approved:** 2026-11-05T05:54:53+00:00 from batch `batch-21-harbor-ladders`, job `lighthouse-2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T05:48:29+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass hard QA; choose take1 with lowest style-lock load1.4259 versus1.6698 and higher Harmony88.0. Visual review confirms the existing lamp room becomes broad honey-amber light, brightest centrally; original coral/cream tower, gallery, door/window, framing and footprint remain. No painted beam, rays, halo, ground shadow or guide. Edit stability0.9171 and chroma1.2429; source of the additional chroma is the requested lamp. Advisory warnings remain recorded. No root guide fit applies to edits. Founder review pending.

## References

- `design/art/stations/lighthouse-1/lighthouse-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint cc0ae3a20a7c02bb)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the lamp room: the dark glass becomes a warm honey-amber glowing lantern, brightest in the middle, painted as soft broad shapes. Only the lamp room changes: no glow or color change on the tower, the gallery or anything else (the app adds the beam and the halo).

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
- pass: chroma_ceiling (chroma p95 51 (R1 51))
- warn: light_values (day/subject: L p2 51 (at most 22), p98 91 (at least 90), spread 40 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 78 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.19 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.6 (at least 3.5))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.4)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.7, p95 7.7, off-palette 1.7% (top: #EE9933 (0.3%), #DD9933 (0.3%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 88 against the world reference (outliers: edge))
- pass: edit_stability (92% of the parent level unchanged)
- warn: edit_chroma (chroma x1.24 of the parent level (drift compounds along a chain))
