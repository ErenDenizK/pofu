# station__tea-stall-4

- **Approved:** 2026-11-02T14:53:02+00:00 from batch `batch-01-slice`, job `tea-stall-4`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:52:01+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `tea-stall-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. t2 excluded by visual transparency QA: visible opaque halo and repeated edges fill the required transparent margin, despite automated transparency pass; t1 is lowest-load take passing complete QA.

## References

- `design/art/stations/tea-stall-3/tea-stall-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint a61bbf3e82c8ef3f)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add one string of small, round, warm cream light bulbs, unlit,
hanging in a gentle curve along the front edge of the awning
between the two poles. The bulbs are simple soft dots, not
glowing (the app adds the glow at night).

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
- pass: chroma_ceiling (chroma p95 17 (R1 51))
- pass: value_floor (lightness p5 68 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 5.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.8, p95 1.6, off-palette 0.0%)
- warn: station_anchor (top y 112 above the height bar (150))
- pass: edit_stability (100% of the parent level unchanged)
