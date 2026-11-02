# station__pond-4

- **Approved:** 2026-11-02T14:51:28+00:00 from batch `batch-03-home-island`, job `pond-4`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:50:55+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -9, "dy": 57}, alignment to the parent level {"scale": 0.9989, "cx": 500.5, "cy": 962.0, "dx": 8, "dy": -58}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `pond-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/pond-3/pond-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 92ea8b5806e3b05a)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a short, low wooden dock of four broad planks of soft honey
wood on two stubby posts, reaching from the front right edge of
the pond onto the water, inside the footprint.

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
- pass: edit_alignment (the edit rescaled the object x1.001 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 21 (R1 51))
- pass: value_floor (lightness p5 70 (R1 59))
- pass: detail_budget (detail at display size 1.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 4.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 3.6, off-palette 0.0% (top: #888866 (0.0%), #888877 (0.0%)))
- warn: station_anchor (width 945 px wider than the footprint (720))
- pass: edit_stability (92% of the parent level unchanged)
