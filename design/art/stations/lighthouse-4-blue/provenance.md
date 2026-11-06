# station__lighthouse-4-blue

- **Approved:** 2026-11-06T01:05:49+00:00 from batch `batch-40-home-ladder-gaps`, job `lighthouse-4-blue`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:33:09+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-4-blue.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and independent original plus locked review. Only the coral cap/finial and two coral tower bands become soft sea-blue; cream bands, existing warm lamp glow, honey balcony and rail, round crossbar window, honey door, cream trim and base preserve actual approved same-level geometry and colors. No new glow, background or part drift. Auto-pick take2 by lower eligible lock1.0513 versus1.0937; Harmony79.9 versus78.9 also favors2. Declared recolor structure passes0.9817 and0.9788, without invented stricter gates. Lighthouse consumer remains byte-identical to its first-success receipt. Founder review pending.

## References

- `design/art/stations/lighthouse-4/lighthouse-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 615f9f8d05fd9445)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Recolor the lighthouse to its blue option. The coral stripes of the tower and the coral cap become soft sea-blue; the cream stripes stay cream. The lit lamp room's glow, the honey balcony and its rail, the round window, the door and the base keep their exact colors.

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
- warn: chroma_ceiling (chroma p95 58 (R1 51))
- warn: light_values (day/subject: L p2 49 (at most 22), p98 92 (at least 90), spread 43 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 80 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.14 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.7 (at least 3.5))
- pass: detail_budget (detail at display size 2.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 4.3, p95 11.3, off-palette 3.4% (top: #BB7722 (0.3%), #558899 (0.3%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 80 against the world reference (outliers: C_p95, detail, edge))
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_structure (light structure matches the parent (r 0.98))
- pass: edit_lightness (mean lightness moved by 0.7 L (the same lightness was asked))
