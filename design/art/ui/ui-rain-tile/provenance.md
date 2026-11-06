# ui__rain-tile

- **Approved:** 2026-11-06T08:29:33+00:00 from batch `batch-44-weather-fx`, job `rain-tile`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T07:41:38+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-rain-tile.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Only3 passes hard QA after the sole retry. Roughly60 thin soft pale blue-white slanted tapered streaks, varied length/brightness, even coverage, no objects. Actual normalized2x2 diagnostic has no conspicuous straight seam or empty-corner block; visual review does not claim exact pixel periodicity.

## References

- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: An approved glow sprite of the game: match its soft painted grain on pure black (do not draw a pool).

## Prompt (fingerprint f68a6bd7f676a5c2)

```text
REFERENCES (attached, in this order):
1. An approved glow sprite of the game: match its soft painted grain on pure black (do not draw a pool).

A seamless, tileable pattern of gentle falling rain on pure black:
about sixty thin, soft, slightly slanted streaks of pale white-blue
light, varied in length and brightness, evenly scattered over the
whole square with no clumps and no empty corners, each streak
softly tapered at both ends. The pattern continues across the edges
so copies placed side by side or stacked join without a seam.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

MASK SPRITE: painted light-on-black for a game, pure black
(#000000) background, only white and pale blue-white, soft painted
streaks, never hard digital lines.

AVOID: a storm, lightning, splashes, drops with outlines, clouds, a ground, any object, colour beyond pale blue-white, text, letters, a border, a visible seam

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x1024)
- pass: chroma_ceiling (glow chroma p95 12 on 1% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.038 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.36% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (149 of 149 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
