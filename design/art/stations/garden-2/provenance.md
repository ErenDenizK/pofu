# station__garden-2

- **Approved:** 2026-11-02T14:51:02+00:00 from batch `batch-01-slice`, job `garden-2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:50:38+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -11, "dy": 15}, alignment to the parent level {"scale": 0.9874, "cx": 498.0, "cy": 925.0, "dx": 8, "dy": -21}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `garden-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/garden-1/garden-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint bb1630c342bfaa16)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a low, rounded cream picket fence along the front edge of the
bed and two more sunflowers between the existing ones, a little
shorter than them.

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
- pass: edit_alignment (the edit rescaled the object x1.013 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 34 (R1 51))
- pass: value_floor (lightness p5 61 (R1 59))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 9.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 3.8, off-palette 0.0%)
- warn: station_anchor (width 862 px wider than the footprint (720))
- warn: edit_stability (69% of the parent level unchanged)
