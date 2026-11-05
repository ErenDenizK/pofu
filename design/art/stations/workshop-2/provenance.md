# station__workshop-2

- **Approved:** 2026-11-05T18:27:37+00:00 from batch `batch-03-home-island`, job `workshop-2`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T18:26:11+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. After exactly one retry pair, take4 is the only eligible source: all four numeric reports pass, but take1/2/3 have respectively 6/16/21 nonzero alpha pixels on the left source border and are manually excluded under the explicit queue rule. Take4 has zero alpha on all four source and locked borders, the entire building and vise within transparent margins, and the requested pegboard to the right of the door with five visible tools: hammer, saw, wrench, pliers and hand drill. The original building footprint, door, tiled roof and workbench remain stable against the official fitted parent. Source is the byte-identical alias design/art/stations/workshop-1/workshop-1.png of main-approved workshop-1--lock-light.png (1280 square), explicitly documented in docs/design/asset-integration.md; canonical clipped WebP and padded source were not edited. Official post fits that padded parent to the 1024 target before comparison and records parent_canvas. Re-promote only queue-authorized workshop-2 with force, own Harmony file and content node; founder review pending.

## References

- `design/art/stations/workshop-1/workshop-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint a953c17685623ddc)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a pale wooden pegboard on the shed's front wall, right of the
doorway, holding five simple, chunky tools: a hammer, a saw, a
wrench, a pair of pliers and a hand drill, with honey wood handles
and their metal painted as soft stone-beige shapes with no shine.

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
- pass: chroma_ceiling (chroma p95 45 (R1 51))
- pass: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 2.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.1, p95 2.7, off-palette 0.0% (top: #995522 (0.0%), #AA6622 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 78 against the world reference (outliers: detail, edge))
- pass: edit_stability (92% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
