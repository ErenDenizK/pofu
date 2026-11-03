# ui__game-plot-tile-mint

- **Approved:** 2026-11-03T14:54:17+00:00 from batch `retry-2026-11-03`, job `game-plot-tile-mint`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:49:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9941, "cx": 507.0, "cy": 956.0, "dx": -5, "dy": -2}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-plot-tile-mint.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Resume from the saved pre-stop choice t2, with zero image generation. Re-posted all two original PNGs under main9ede62e QA: both pass; t2 remains lowest lock load0.5998 versus0.6082 and its locked RGBA is unchanged from the retained candidate. Matte cool blue-mint glaze remains distinct from sage; tile silhouette, highlight, lip and sprout are preserved. Exactly two original image requests; source files recovered after the historical ARG_MAX callback failure and assigned stable completion-time numbering, not claimed original request ordinal. This fresh preparation adopts no old partial master or journal.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint f470d536dd3b0cd8)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Change only the glaze color of the tile and its sprout to a cool
mint, a little bluer than before, in the same finish and the same
lightness. The shape, highlight, lip and sprout stay.

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
- pass: edit_alignment (the edit rescaled the object x1.006 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 12 (R1 51))
- pass: value_floor (lightness p5 75 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: palette_drift (mean dE 1.3, p95 2.5, off-palette 0.0%)
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_structure (light structure matches the parent (r 0.96))
- pass: edit_lightness (mean lightness moved by 3.8 L (the same lightness was asked))
