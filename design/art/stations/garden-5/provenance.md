# station__garden-5

- **Approved:** 2026-11-02T17:59:38+00:00 from batch `batch-05-fixes-pilot`, job `garden-5`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T17:58:41+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `garden-5.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. t1 is the only non-failing take (lock load 0.7074); t2 fails edit_chroma (1.4618). Manifest visual checks pass: no top-height warning, width 864 px versus parent 861 px (difference 3 px <=20). Retained width and chroma warnings.

## References

- `design/art/stations/garden-4/garden-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1839c71f6da75a2d)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Make the one sunflower in the middle of the bed, under the arch,
a giant: a thick soft stem and three broad leaves rising from
the center of the bed, and one big round head of honey-yellow
petals around a warm brown center, about twice as wide as the
other sunflower heads, facing up and to the left toward the
light. The whole giant sunflower stays INSIDE the arch's opening:
its head sits just below the top of the arch, nothing of it
reaches above or outside the arch, and the arch, the bunting, the
fence and the other flowers stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: anything above the arch, a sunflower taller than the arch, a wider bed, a zoomed-out view.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- pass: value_floor (lightness p5 62 (R1 59))
- pass: detail_budget (detail at display size 2.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 6.4, off-palette 0.5% (top: #888866 (0.4%), #888877 (0.1%)))
- warn: station_anchor (width 864 px wider than the footprint (720))
- pass: edit_stability (82% of the parent level unchanged)
- warn: edit_chroma (chroma x1.34 of the parent level (drift compounds along a chain))
