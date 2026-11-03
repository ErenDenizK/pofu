# ui__game-bloom-left

- **Approved:** 2026-11-03T01:19:17+00:00 from batch `batch-12-minigame-art`, job `game-bloom-left`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T01:07:06+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-bloom-left.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both are non-failing automated reports. Manual review excludes take1 for its clipped upper petal after alignment. Take2 preserves an unclipped silhouette, seed-swirl centre and colours at44pt, with the centre shifted left and right-side petals foreshortened as specified. Lowest complete-QA eligible lock load0.3700. Batch12 has no extra >0.9 manual stability gate; pipeline stability0.7659 passes its unchanged checks.

## References

- `design/art/ui/ui-game-bloom-front/ui-game-bloom-front.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 7ac31336ca1e4725)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Turn the sunflower head slightly to the left, as if looking left:
the center sits a little left of the middle and the petals on the
right side are foreshortened. Same size, colors and finish.

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
- warn: chroma_ceiling (chroma p95 58 (R1 51))
- pass: value_floor (lightness p5 44 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: palette_drift (mean dE 1.3, p95 5.1, off-palette 0.0%)
- pass: edit_stability (77% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
