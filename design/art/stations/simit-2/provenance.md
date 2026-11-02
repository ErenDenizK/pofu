# station__simit-2

- **Approved:** 2026-11-02T17:56:26+00:00 from batch `batch-05-fixes-pilot`, job `simit-2`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** salvage-batch-03;
  generated 2026-11-02T17:55:44+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Salvaged from batch 03 lossy WebP q90 take; original PNG was not kept. No new image generated.

## References

- `design/art/stations/simit-1/simit-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6f09ad93fd8c6afb)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small round sun umbrella above the cart on a wooden pole
fixed to the cart's back: a scalloped canopy of soft coral and
cream segments, matte cloth. The umbrella's top stays below the
top of the canvas with a clear margin.

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
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- pass: value_floor (lightness p5 54 (R1 59))
- pass: detail_budget (detail at display size 2.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.0)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.6, off-palette 0.0%)
- warn: station_anchor (top y 116 above the height bar (150))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.00 of the parent level (drift compounds along a chain))
