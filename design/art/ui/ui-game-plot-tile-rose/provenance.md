# ui__game-plot-tile-rose

- **Approved:** 2026-11-03T14:57:01+00:00 from batch `retry-2026-11-03`, job `game-plot-tile-rose`, take t1
  of 3 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T14:01:15+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9953, "cx": 505.5, "cy": 958.0, "dx": -4, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `ui-game-plot-tile-rose.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Resume from the saved pre-stop choice t1, with zero new image generation. Re-posted all three real original PNGs under main9ede62e QA: all pass, t1 remains lowest lock load0.5414 versus0.5650 and0.5851, and selected locked RGBA is unchanged. Dusty rose glaze preserves tile shape, highlight, lip and sprout. Historical dispatch evidence remains four attempted calls and three retained images: one initial-pair result was unresolved after ARG_MAX/isolate interruption and a conservative600s timeout; retained initial output requestordinal is unknown. The single fresh retry pair was already spent before the stop. Official takes1/2/3 map to unknown initialordinal/dispatch3/dispatch4. No missing image/hash is invented and no fifthcall was made. This fresh preparation adopts no old partial master or journal.

## References

- `design/art/ui/ui-game-plot-tile-sage/ui-game-plot-tile-sage.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6a19a4c6554b8e58)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Change only the glaze color of the tile and its sprout to a soft
dusty rose, in the same finish and the same lightness as before.
The shape, highlight, lip and sprout stay.

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
- pass: edit_alignment (the edit rescaled the object x1.005 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 14 (R1 51))
- pass: value_floor (lightness p5 67 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: palette_drift (mean dE 0.5, p95 1.3, off-palette 0.0%)
- pass: edit_silhouette (98% of the parent's shape kept)
- pass: edit_structure (light structure matches the parent (r 0.95))
- pass: edit_lightness (mean lightness moved by 4.3 L (the same lightness was asked))
