# station__cay-2

- **Approved:** 2026-11-02T14:31:40+00:00 from batch `batch-01-slice`, job `cay-2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:31:08+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `cay-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/cay-1/cay-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 0e67e6ef4a848e91)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add two thin wooden poles at the back corners of the counter and a
scalloped striped awning between them, soft rose-pink and cream
stripes, matte cloth. The awning's top stays below the top of the
canvas with a clear margin.

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
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 65 (R1 59))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 8.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.7, p95 1.6, off-palette 0.0%)
- warn: station_anchor (top y 115 above the height bar (150))
- pass: edit_stability (90% of the parent level unchanged)
