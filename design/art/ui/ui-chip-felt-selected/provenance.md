# ui__chip-felt-selected

- **Approved:** 2026-11-10T16:42:16+00:00 from batch `batch-61-ui-kit-v3`, job `ui-chip-felt-selected`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-10T16:41:09+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9986, "cx": 767.5, "cy": 780.0, "dx": 0, "dy": 1}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-chip-felt-selected.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take 2 clears every hard check; edit_structure warns. Existing parent aspect ratio inherited; slicing not certified.

## References

- `design/art/ui/ui-chip-felt/ui-chip-felt.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 9b72c83e90a46bf4)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

The same chip, selected: the felt a shade darker and warmer (#E3C79A) and the stitches just inside the rim now bold honey-gold thread (#E9A93B), slightly larger. The outline, size and position stay.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: edit_alignment (the edit rescaled the object x1.001 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- pass: value_floor (lightness p5 73 (R1 59))
- pass: detail_budget (detail at display size 1.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: palette_drift (mean dE 2.3, p95 4.1, off-palette 1.3% (top: #CC8822 (0.4%), #DD9933 (0.2%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- warn: edit_structure (light structure matches the parent (r 0.70))
- pass: edit_lightness (mean lightness moved by 8.2 L (the same lightness was asked))
