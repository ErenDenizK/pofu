# world__island-main-l-v3

- **Approved:** 2026-11-02T18:01:48+00:00 from batch `batch-05-fixes-pilot`, job `island-main-l-v3`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:00:28+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `island-main-l-v3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass automated QA; t2 has lowest lock load 0.4545 (t1 0.4667). Manual lower bound passes: depth ratio 0.2505 >=0.21, target 0.22-0.26. Lawn remains in the same framing; edit stability 99.02%. Source composited over blue confirms clean transparency: a glow visible in the tool preview comes from RGB under alpha-zero pixels and is not visible in a correct alpha composite.

## References

- `design/art/masters/island-main-l-v2/island-main-l-v2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 560282a02ea4f2e0)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Make only the earth body under the lawn deeper, so the island
has visible thickness: about one and a half times as deep as now,
a full, rounded mass of the same light honey and caramel soil with
its gentle strata, and one more soft band of pale stone near the
bottom, so it reads as solid ground with a rocky underside, never
as a thin slab and never as a cone. Its underside stays soft and
rounded. Keep the round door, its window, the pebbles and the
roots where they are on the body; the roots hang from the new,
lower underside. The lawn, its outline, its front lip, its
position on the canvas and its size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: moving or resizing the lawn, a cone-shaped or pointed underside, dark or grey rock, a cliff face, hard edges, water, sky, background, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- pass: value_floor (lightness p5 71 (R1 59))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 4.4, off-palette 0.0%)
- pass: depth_ratio (earth depth / width 0.25 (target <= 0.30))
- pass: lawn_chroma (lawn chroma p95 18 (palette meadow 38))
- pass: edit_stability (99% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
