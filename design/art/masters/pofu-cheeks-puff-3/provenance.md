# char__pofu-cheeks-puff-3

- **Approved:** 2026-11-02T19:06:14+00:00 from batch `batch-06-pofu-rig`, job `pofu-cheeks-puff-3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:05:01+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-cheeks-puff-3.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/pofu-cheeks-puff-2/pofu-cheeks-puff-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1c43d2e89180b99e)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his cheeks and eyes: puff
the cheek pouches out much further, as if stuffed with far too
many sunflower seeds: the cheeks bulge clearly past the outline of
the head on both sides and slightly down, the face becomes wider
than the body at cheek height, the blush stretches with them, and
the eyes squint a little in proud delight. Still cute. No visible
food. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: visible seeds, an open mouth, a changed body below the cheeks, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: value_floor (lightness p5 67 (R1 59))
- pass: detail_budget (detail at display size 4.4 (R1 5.3))
- warn: palette_drift (mean dE 1.8, p95 9.1, off-palette 3.6% (top: #EE7766 (0.5%), #EE9955 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (82% of the parent level unchanged)
- pass: edit_chroma (chroma x1.07 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 74 against the char reference (outliers: L_p2))
