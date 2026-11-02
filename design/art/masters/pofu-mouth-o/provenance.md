# char__pofu-mouth-o

- **Approved:** 2026-11-02T19:21:09+00:00 from batch `batch-06-pofu-rig`, job `pofu-mouth-o`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:16:52+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9973, "cx": 516.5, "cy": 1375.0, "dx": 0, "dy": -1}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-mouth-o.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Pofu is never locked; equal zero lock loads are resolved by higher harmony score. Alpha composites verify clean transparency.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9f9c4f3f5faa7e10)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his mouth: make it a small
round "o" of surprise and curiosity under the nose, about a third
the width of the current smile. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: teeth, a wide-open shout, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: edit_alignment (the edit rescaled the object x1.003 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- pass: value_floor (lightness p5 58 (R1 59))
- pass: detail_budget (detail at display size 5.1 (R1 5.3))
- warn: palette_drift (mean dE 2.4, p95 10.6, off-palette 4.0% (top: #EE9955 (0.7%), #EE7766 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: harmony (harmony score 83 against the char reference (outliers: C_p95, detail, tint_b))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
