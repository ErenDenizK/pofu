# char__pofu-mouth-open

- **Approved:** 2026-11-02T19:19:42+00:00 from batch `batch-06-pofu-rig`, job `pofu-mouth-open`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:16:50+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-mouth-open.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Pofu is never locked; equal zero lock loads are resolved by higher harmony score. Alpha composites verify clean transparency.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9ff635f5c2b0b2b9)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his mouth: open it into a
small, happy laugh, a soft rounded opening under the nose with a
hint of pink tongue, the same width as the current smile. The muzzle
fur moves only around the mouth. Nothing else changes.

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
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- pass: value_floor (lightness p5 57 (R1 59))
- pass: detail_budget (detail at display size 5.2 (R1 5.3))
- warn: palette_drift (mean dE 2.4, p95 10.0, off-palette 3.8% (top: #EE9955 (0.5%), #EE7766 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: harmony (harmony score 83 against the char reference (outliers: C_p95, detail, tint_b))
- pass: edit_stability (99% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
