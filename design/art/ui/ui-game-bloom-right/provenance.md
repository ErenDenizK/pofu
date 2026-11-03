# ui__game-bloom-right

- **Approved:** 2026-11-03T13:51:56+00:00 from batch `retry-2026-11-03`, job `game-bloom-right`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:34+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-bloom-right.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Manual review passes: brown-disc centroid x606.78 versus front x502.35, a +104.43px shift; left petals are broad and right petals foreshortened. The second take also passes (+83.68px). Both have only automated silhouette warnings; t1 has lowest lock load. Infrastructure recovery: exactly two image requests were dispatched; after shell callback ARG_MAX failure, generated originals were visually identified and numbered in stable completion-time order, not claimed original request order. Source/inbox/RGBA hashes preserve lineage.

## References

- `design/art/ui/ui-game-bloom-front/ui-game-bloom-front.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 8001a8b0f185f41c)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Turn the sunflower head to the right, as if looking right: slide
the whole brown center clearly to the right, about one tenth of the
canvas width (about 100 px) further right than it is now, so it
sits well right of the middle; the petals on the right side are
narrow and foreshortened, the petals on the left side are broad and
open. The head stays the same size, colors and finish.

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
- pass: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: palette_drift (mean dE 1.3, p95 3.9, off-palette 0.0%)
- warn: edit_silhouette (92% of the parent's shape kept)
- pass: edit_stability (66% of the parent level unchanged)
- pass: edit_chroma (chroma x0.94 of the parent level (drift compounds along a chain))
