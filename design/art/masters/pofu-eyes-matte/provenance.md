# char__pofu-eyes-matte

- **Approved:** 2026-11-02T19:10:49+00:00 from batch `batch-06-pofu-rig`, job `pofu-eyes-matte`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:05:22+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9973, "cx": 516.5, "cy": 1375.0, "dx": 0, "dy": -1}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-eyes-matte.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Pofu is never locked; equal zero lock loads are resolved by higher harmony score. Alpha composites verify clean transparency.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 60461ef0fc43b04d)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his eyes: remove the white
catchlights and the tiny sparkles, so each eye is a plain soft dark
espresso-brown with its lighter warm-brown lower iris. Same eye
shapes, sizes and positions. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: white dots, reflections, glints, changed eye shapes, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: edit_alignment (the edit rescaled the object x1.003 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: value_floor (lightness p5 58 (R1 59))
- pass: detail_budget (detail at display size 5.1 (R1 5.3))
- warn: palette_drift (mean dE 2.3, p95 8.7, off-palette 3.2% (top: #EE9955 (0.4%), #EE7766 (0.4%)))
- pass: ground_line (feet at 89.4% of the height (contract 88%))
- pass: harmony (harmony score 85 against the char reference (outliers: detail, tint_b))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.04 of the parent level (drift compounds along a chain))
