# station__workshop-5-green

- **Approved:** 2026-11-06T00:52:35+00:00 from batch `batch-40-home-ladder-gaps`, job `workshop-5-green`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:36:32+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-5-green.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent original and locked review selects take2: four separate sage shutters in the two explicitly named pairs, round cut-outs and cream edges; exact actual gear sign, chimney, four-blade pinwheel, five tools, doorway, bench and vice remain. Historical left-edge clipping is preserved from the frozen approved parent, not corrected or treated as a new failure. The actual parent has no visible clock, so none is invented. Take1 adds unrequested solid wood across the protected open bench gap outside shutter outlines and is excluded. Take2 has lower eligible lock0.7456 and Harmony81.9. Three existing planned workshop nodes were linked once before this first success; failed variants remain cut with no images. Founder review pending.

## References

- `design/art/stations/workshop-5/workshop-5.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint e03ecc1bb7a90f41)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a pair of small rounded sage-green wooden shutters, open flat against the wall, one on each side of the arched doorway, and a third pair on the lower wall at the right. Each shutter is a chunky rounded panel with a small round cut-out, painted sage green with a cream edge. The big gear sign, the chimney, the clock and everything else stay exactly as they are.

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
- warn: chroma_ceiling (chroma p95 53 (R1 51))
- warn: light_values (day/subject: L p2 49 (at most 22), p98 90 (at least 90), spread 41 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 77 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.22 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.7 (at least 3.5))
- pass: detail_budget (detail at display size 2.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.7, p95 7.7, off-palette 0.5% (top: #BB7722 (0.1%), #BB6622 (0.1%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 82 against the world reference (outliers: edge))
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_stability (91% of the parent level unchanged)
- pass: edit_chroma (chroma x1.01 of the parent level (drift compounds along a chain))
