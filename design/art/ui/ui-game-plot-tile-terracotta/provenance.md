# ui__game-plot-tile-terracotta

- **Approved:** 2026-11-03T14:02:03+00:00 from batch `retry-2026-11-03`, job `game-plot-tile-terracotta`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:37+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 1.0288, "cx": 506.0, "cy": 954.0, "dx": 4, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-plot-tile-terracotta.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes preserve tile shape and sprout, with soft terracotta-orange glaze. Select t1 by lower passing lock load1.3340 versus1.6657; lightness warns14.0L, without threshold waiver. T2 additionally warns structure. Exactly two image requests were dispatched. After a shell callback ARG_MAX failure, original PNGs were recovered by visual identity and numbered in stable completion-time order; original request ordinal is not claimed. Source/inbox/RGBA hashes preserve lineage.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 99d61d01b95566e3)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Change only the glaze color of the tile and its sprout to a soft
terracotta orange, in the same finish and the same lightness as
before. The shape, highlight, lip and sprout stay.

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
- pass: edit_alignment (the edit rescaled the object x0.972 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 44 (R1 51))
- pass: value_floor (lightness p5 56 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: palette_drift (mean dE 1.5, p95 4.4, off-palette 0.1% (top: #AA5533 (0.1%), #995522 (0.0%)))
- pass: edit_silhouette (94% of the parent's shape kept)
- pass: edit_structure (light structure matches the parent (r 0.83))
- warn: edit_lightness (mean lightness moved by 14.0 L (the same lightness was asked))
