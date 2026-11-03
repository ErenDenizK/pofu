# ui__game-plot-tile-honey

- **Approved:** 2026-11-03T13:56:30+00:00 from batch `retry-2026-11-03`, job `game-plot-tile-honey`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:35+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9792, "cx": 506.0, "cy": 957.0, "dx": 0, "dy": 1}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-plot-tile-honey.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes preserve the sage tile silhouette, highlight, lip and sprout while recoloring to warm honey yellow. All automated QA checks pass; select t1 by lower lock load0.7057 versus0.7267. Exactly two image requests were dispatched; original PNGs recovered after ARG_MAX callback failure and assigned stable completion-time numbering, not original request ordinal. Source hashes preserve lineage.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint fd886acce11b71c6)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Change only the glaze color of the tile and its sprout to a warm
honey yellow, in the same matte-to-soft-gloss finish and the same
lightness as before. The shape, highlight, lip and sprout stay.

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
- pass: edit_alignment (the edit rescaled the object x1.021 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 38 (R1 51))
- pass: value_floor (lightness p5 77 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: palette_drift (mean dE 1.2, p95 2.4, off-palette 0.0%)
- pass: edit_silhouette (96% of the parent's shape kept)
- pass: edit_structure (light structure matches the parent (r 0.88))
- pass: edit_lightness (mean lightness moved by 4.9 L (the same lightness was asked))
