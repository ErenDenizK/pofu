# char__findik-work

- **Approved:** 2026-11-02T15:03:51+00:00 from batch `batch-03-home-island`, job `findik-work`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T15:02:53+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `findik-work.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/findik-base/findik-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 3d824fc66ecc84dc)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hedgehog, Fındık, into a working pose at the
workshop. Change only the two front paws: they now hold a small,
chunky, round wooden gear in front of the chest, as if showing a
finished part: soft honey wood, six rounded teeth and a round
hole in the middle, matte, no shine. Everything else stays
exactly as it is.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: metal tools, sharp quills, a curl on the head, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- warn: value_floor (lightness p5 44 (R1 59))
- pass: detail_budget (detail at display size 6.8 (R1 5.3))
- warn: palette_drift (mean dE 3.4, p95 13.9, off-palette 8.7% (top: #AA5533 (1.9%), #BB6633 (1.1%)))
- pass: ground_line (feet at 89.7% of the height (contract 88%))
- pass: edit_stability (94% of the parent level unchanged)

Master downscaled from 1024x1536 to 870x1306 to meet the 600 KB upload cap; saved lossless WebP (589662 bytes).

For the single retry round, the shipped 870x1306 findik-base WebP was decoded and reconstructed at the manifest 1024x1536 canvas using Lanczos before attaching and parent QA. First-round t1/t2 failed edit_stability at 0% due to the different pixel grids; these takes became stale when the reference changed. Fresh retry t3 passed with warnings (value_floor, palette_drift); t4 failed palette_drift. Selected t3; character lock load is zero. No prompt or QA threshold changed. All four takes are retained.
