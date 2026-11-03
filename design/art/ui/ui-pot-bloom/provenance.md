# ui__pot-bloom

- **Approved:** 2026-11-02T23:57:50+00:00 from batch `batch-11-ui-pilot`, job `ui-pot-bloom`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T23:56:37+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-pot-bloom.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass the strict manual edit_stability >0.9 gate (0.9416 and 0.9420). White, blue, cream and dark alpha composites are clean. Single sunflower, brown centre and two rounded leaves remain legible at the native 36x56pt ship preview; pot, rim and soil remain aligned. Take1 is selected for lower non-failing lock load 1.0983 versus 1.1843; non-failing chroma/palette warnings are retained.

## References

- `design/art/ui/ui-pot-empty/ui-pot-empty.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 25b31c0a30b8afb5)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add one small sunflower growing from the soil on a short green
stem with two rounded leaves: a round golden-yellow bloom with a
warm-brown center facing the viewer, simple soft shapes. The pot
and soil stay as they are.

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
- warn: chroma_ceiling (chroma p95 52 (R1 51))
- pass: value_floor (lightness p5 41 (R1 59))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- warn: palette_drift (mean dE 1.6, p95 7.7, off-palette 3.0% (top: #889933 (0.4%), #99AA44 (0.4%)))
- pass: edit_stability (94% of the parent level unchanged)
- pass: edit_chroma (chroma x1.07 of the parent level (drift compounds along a chain))
