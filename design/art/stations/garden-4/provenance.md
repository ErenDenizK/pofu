# station__garden-4

- **Approved:** 2026-11-02T15:02:20+00:00 from batch `batch-03-home-island`, job `garden-4`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T15:01:47+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -11, "dy": 15}, alignment to the parent level {"scale": 0.9965, "cx": 495.0, "cy": 922.0, "dx": 11, "dy": -18}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `garden-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/garden-3/garden-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 88924ce5ffcb5149)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a low, rounded arch of soft honey wood over the back of the
bed, wound with small sunflowers and leaves, and a short string of
small triangular bunting in soft rose, honey and cream (plain, no
symbols, no letters) along the arch. The arch's top stays below
the top of the canvas with a clear margin.

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
- pass: edit_alignment (the edit rescaled the object x1.004 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 20 (R1 51))
- pass: value_floor (lightness p5 68 (R1 59))
- pass: detail_budget (detail at display size 1.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 5.2)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 4.5, off-palette 0.0%)
- warn: station_anchor (width 861 px wider than the footprint (720))
- pass: edit_stability (99% of the parent level unchanged)
