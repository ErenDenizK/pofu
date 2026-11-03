# station__pond-5-lit

- **Approved:** 2026-11-02T23:35:26+00:00 from batch `batch-07-light`, job `pond-5-lit`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:20:04+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pond-5-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained take2 published without regeneration under the explicit overnight authorization. Only the three lantern interiors change; no water/pad spill or halo. Edit stability exceeds0.9; harmony warnings remain advisory.

## References

- `design/art/stations/pond-5/pond-5.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 07d62845d7e46c68)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the three floating paper lanterns from inside: each paper
glows a warm honey-gold, brightest at its center, with its ribs
unchanged. Light only inside each lantern's own outline: no halo,
no glow, no reflection on the water and no light on the pads (the
app draws the glow and the reflection).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: halos, rays, reflections, lit water, blown yellow-white highlights, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 19 (R1 51))
- pass: value_floor (lightness p5 72 (R1 59))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 5.3, off-palette 0.0% (top: #666644 (0.0%), #777755 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 55 against the world reference (outliers: C_p95, L_p98, edge))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.08 of the parent level (drift compounds along a chain))
