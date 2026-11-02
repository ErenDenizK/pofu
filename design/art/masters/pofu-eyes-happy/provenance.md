# char__pofu-eyes-happy

- **Approved:** 2026-11-02T18:07:58+00:00 from batch `batch-06-pofu-rig-pilot`, job `pofu-eyes-happy`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:07:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-eyes-happy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes have warnings only; Pofu is never locked, so take 1 wins the zero-lock-load tie. Palette drift warning retained.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint fcec32b98755de03)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his eyes: make both eyes
happy closed arcs, the classic smiling ^ shape. Each eye becomes a
thick, soft, dark espresso-brown upward-curved arc at the height
of the top of the original eye, with soft cream fur below it where
the eye was. The cheeks lift very slightly. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: eyelashes, tears, eyebrows, a changed mouth, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: value_floor (lightness p5 69 (R1 59))
- pass: detail_budget (detail at display size 4.8 (R1 5.3))
- warn: palette_drift (mean dE 2.1, p95 9.0, off-palette 3.2% (top: #EE7766 (0.4%), #EE9955 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (94% of the parent level unchanged)
- pass: edit_chroma (chroma x0.95 of the parent level (drift compounds along a chain))
