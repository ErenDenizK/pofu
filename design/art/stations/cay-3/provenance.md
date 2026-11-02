# station__cay-3

- **Approved:** 2026-11-02T14:42:07+00:00 from batch `batch-01-slice`, job `cay-3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:41:36+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `cay-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/cay-2/cay-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint ce6314468af9c122)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add two small round wooden stools and one tiny round table with a
rose-and-cream striped tablecloth in front of the counter's left
end, all inside the stall's footprint and smaller than the
counter.

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
- pass: chroma_ceiling (chroma p95 20 (R1 51))
- pass: value_floor (lightness p5 67 (R1 59))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 6.9)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.7, off-palette 0.0%)
- warn: station_anchor (top y 114 above the height bar (150))
- pass: edit_stability (94% of the parent level unchanged)
