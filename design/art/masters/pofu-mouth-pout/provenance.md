# char__pofu-mouth-pout

- **Approved:** 2026-11-02T18:11:00+00:00 from batch `batch-06-pofu-rig-pilot`, job `pofu-mouth-pout`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:09:50+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-mouth-pout.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Pofu is never locked; lowest take number breaks the zero-lock-load tie. Automated warnings retained.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 2d78c4d3d7193949)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his mouth: make it a small,
playful pout, a tiny rounded mouth pushed slightly forward and a
little to one side, like a comic "hmph". Cute and theatrical,
never sad. Nothing else changes: the eyes, cheeks, blush and fur
stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a frown, tears, teeth, a tongue, eyebrows, an angry face, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 49 (R1 51))
- pass: value_floor (lightness p5 60 (R1 59))
- pass: detail_budget (detail at display size 4.9 (R1 5.3))
- pass: palette_drift (mean dE 2.1, p95 7.8, off-palette 2.9% (top: #EE9955 (0.4%), #EE7766 (0.3%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x0.95 of the parent level (drift compounds along a chain))
