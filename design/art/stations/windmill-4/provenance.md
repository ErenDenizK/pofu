# station__windmill-4

- **Approved:** 2026-11-02T15:02:24+00:00 from batch `batch-03-home-island`, job `windmill-4`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T15:01:38+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -15, "dy": -25}, alignment to the parent level {"scale": 0.9945, "cx": 502.0, "cy": 877.0, "dx": 16, "dy": 23}, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `windmill-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/windmill-3/windmill-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint eda7b0f2fb258626)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add five small round lanterns of honey-cream paper hanging along
the lower edge of the cap, unlit: simple soft shapes, not glowing
(the app adds the glow at night).

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
- pass: edit_alignment (the edit rescaled the object x1.006 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 13 (R1 51))
- pass: value_floor (lightness p5 74 (R1 59))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 3.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.8, off-palette 0.0%)
- warn: station_anchor (top y 57 above the height bar (150))
- pass: edit_stability (99% of the parent level unchanged)
