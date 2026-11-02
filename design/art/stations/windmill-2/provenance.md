# station__windmill-2

- **Approved:** 2026-11-02T14:52:34+00:00 from batch `batch-03-home-island`, job `windmill-2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:50:02+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -15, "dy": -25}, alignment to the parent level {"scale": 0.9981, "cx": 499.5, "cy": 877.0, "dx": 14, "dy": 23}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `windmill-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/windmill-1/windmill-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 2c11203610dc1a9b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add soft cream sail cloths stretched over each of the four sail
frames, matte cloth with one gentle fold, the slats showing only
at the edges.

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
- pass: edit_alignment (the edit rescaled the object x1.002 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 64 (R1 59))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 6.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.7, off-palette 0.0%)
- warn: station_anchor (top y 57 above the height bar (150))
- pass: edit_stability (80% of the parent level unchanged)
