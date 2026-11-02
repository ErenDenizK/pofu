# station__simit-3

- **Approved:** 2026-11-02T18:56:55+00:00 from batch `batch-05-fixes`, job `simit-3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:56:25+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/simit-2/simit-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 135efb39d9fac2ed)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a short upright wooden pole at the cart's front left corner
with eight golden-brown simit rings stacked on it, the same rings
as on the tray, the pole's top below the umbrella.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 47 (R1 51))
- pass: value_floor (lightness p5 52 (R1 59))
- pass: detail_budget (detail at display size 2.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 5.4, off-palette 0.4% (top: #995522 (0.1%), #884411 (0.1%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 78 against the world reference (outliers: L_p98, edge))
- pass: edit_stability (99% of the parent level unchanged)
- pass: edit_chroma (chroma x1.05 of the parent level (drift compounds along a chain))
