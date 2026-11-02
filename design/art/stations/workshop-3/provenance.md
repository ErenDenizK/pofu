# station__workshop-3

- **Approved:** 2026-11-02T18:59:30+00:00 from batch `batch-05-fixes`, job `workshop-3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:57:49+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Advisory harmony warning retained; no failing checks.

## References

- `design/art/stations/workshop-2/workshop-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint d760acac38fc6ff9)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small wind vane on a short wooden pole on the roof's ridge:
four rounded cream and honey blades like a little pinwheel,
facing the viewer, matte.

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
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- pass: value_floor (lightness p5 56 (R1 59))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.0, p95 2.0, off-palette 0.0%)
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 66 against the world reference (outliers: C_p95, L_p98, edge))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
