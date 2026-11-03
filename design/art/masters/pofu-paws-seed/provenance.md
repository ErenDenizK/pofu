# char__pofu-paws-seed

- **Approved:** 2026-11-02T19:10:07+00:00 from batch `batch-06-pofu-rig`, job `pofu-paws-seed`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:09:09+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-paws-seed.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1781281a8df586c6)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his two front paws: they now
hold one plump sunflower seed upright in front of his chest, a soft
warm-brown shell with two broad cream stripes, the paws wrapped
around it. The chest fur shows around the paws as in the original.
Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: more than one seed, a bowl, food in the mouth, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 51 (R1 51))
- warn: value_floor (lightness p5 46 (R1 59))
- pass: detail_budget (detail at display size 5.7 (R1 5.3))
- warn: palette_drift (mean dE 2.3, p95 9.1, off-palette 3.2% (top: #EE7766 (0.4%), #EE9955 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (94% of the parent level unchanged)
- warn: edit_chroma (chroma x1.30 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 83 against the char reference (outliers: detail))
