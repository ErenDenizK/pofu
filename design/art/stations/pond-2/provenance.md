# station__pond-2

- **Approved:** 2026-11-02T14:37:49+00:00 from batch `batch-03-home-island`, job `pond-2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:36:35+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -9, "dy": 57}, alignment to the parent level {"scale": 1.0, "cx": 504.0, "cy": 959.0, "dx": 9, "dy": -55}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `pond-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/pond-1/pond-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 8ba4a7ad469e4b56)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add five round lily pads of soft sage green floating flat on the
water, of different sizes, each with one small notch.

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
- pass: edit_alignment (the edit rescaled the object x1.000 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 20 (R1 51))
- pass: value_floor (lightness p5 74 (R1 59))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 4.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 3.9, off-palette 0.0%)
- warn: station_anchor (width 960 px wider than the footprint (720))
- pass: edit_stability (90% of the parent level unchanged)
