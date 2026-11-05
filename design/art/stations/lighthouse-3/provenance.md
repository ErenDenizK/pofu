# station__lighthouse-3

- **Approved:** 2026-11-05T06:04:21+00:00 from batch `batch-21-harbor-ladders`, job `lighthouse-3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:02:39+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and the parent station-anchor check, with no width-growth warning. Take1 has lowest style-lock load1.2306 versus1.6051 and higher Harmony83.4. Visual review confirms the gallery is widened into a continuous honey wooden balcony floor and rounded low railing, a little wider than the tower but inside the existing base footprint. Lit lamp room, tower/coral-cream bands, door, window, camera and framing remain; no painted beam, halo, shadow, water or guide. Edit stability0.9023 and chroma0.9234 pass. Chroma/light warnings remain advisory; no root guide fit on edits. Founder review pending.

## References

- `design/art/stations/lighthouse-2/lighthouse-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 0608716f14e1774a)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Widen the gallery under the lamp room into a full round balcony all around the tower: a honey wooden floor ring with a low rail of rounded posts, a little wider than the tower. Nothing else changes.

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
- warn: light_values (day/subject: L p2 51 (at most 22), p98 92 (at least 90), spread 41 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 78 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.15 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.4 (at least 3.5))
- pass: detail_budget (detail at display size 2.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.2)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 8.1, off-palette 1.9% (top: #DD9933 (0.2%), #CC7722 (0.2%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 83 against the world reference (outliers: edge))
- pass: edit_stability (90% of the parent level unchanged)
- pass: edit_chroma (chroma x0.92 of the parent level (drift compounds along a chain))
