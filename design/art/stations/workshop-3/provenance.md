# station__workshop-3

- **Approved:** 2026-11-05T18:40:40+00:00 from batch `batch-03-home-island`, job `workshop-3`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T18:38:10+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Initial take1/2 excluded under the strict source-border rule: take1 left4; take2 top6 bottom197 left123 nonzero alpha pixels. The single retry takes3/4 both have zero alpha on all source and locked borders and keep the whole approved L2 building, vise and five-tool pegboard inside clear transparent margins. Both add only the specified small front-facing pinwheel on a short ridge pole with four rounded cream/honey blades, a visible upgrade. Pick the eligible take with lowest lock load, then higher Harmony, without repainting or alpha cleanup. Sequential parent is newly published workshop-2 from this PR, whose padded L1 source origin is fully documented in prior provenance. Queue authorizes force replacement of this closed delivered manifest job only; own Harmony and content included.

## References

- `design/art/stations/workshop-2/workshop-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6263640504a3ade6)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small wind vane on a short wooden pole on the roof's ridge:
four rounded cream and honey blades like a little pinwheel,
facing the viewer, matte.

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
- pass: chroma_ceiling (chroma p95 46 (R1 51))
- pass: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 2.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 4.1, off-palette 0.0% (top: #885522 (0.0%), #995522 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 79 against the world reference (outliers: edge))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.00 of the parent level (drift compounds along a chain))
