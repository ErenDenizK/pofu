# ui__glow-warm-halo

- **Approved:** 2026-11-05T23:42:54+00:00 from batch `batch-35-experience`, job `glow-warm-halo`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:36:51+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-glow-warm-halo.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.5 (512x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both initial full-size takes pass the canonical additive background, falloff and banding checks and independently reviewed originals and locked images show a soft round honey-amber halo with no object, ring, rays or white-hot core. Border channel maxima 3 and 2 are disclosed as near-black within the authored QA profile, not falsely described as exact zero; no pixel cleanup or stricter invented gate is applied. Style lock is deliberately skipped for additive sprites; with no lock_load or Harmony ranking check returned, the deterministic equal-rank tie selects take 1. Official authored scale 0.5 alone produces the delivered master from the saved full lock, with exact pixel and metadata proofs. This UI asset is excluded by the pinned canonical Harmony catalog: run real measure/check and retain proof without a fabricated shard. Exact five-blob PR227 dependency is explicit in this branch.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: The approved ground pool: the same painterly grain, falloff and warm honey-gold color as this halo (do not draw the pool).

## Prompt (fingerprint 574367cb936570a9)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The approved ground pool: the same painterly grain, falloff and warm honey-gold color as this halo (do not draw the pool).

A soft round halo of warm lantern light, centered in the image, filling about 85 percent of its width: a
gentle bright center that falls off smoothly and evenly in every direction, dying into black before the
border. The center is bright but not white-hot, as light that has been softened by paper. Warm honey-gold
only, a slightly irregular painterly edge.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

GLOW SPRITE: a painterly additive light sprite for a game: the app adds it on top of the world with
plus-lighter blending, so black means no light at all. Painted with the same soft airbrushed grain as the
attached art, a smooth falloff from a brighter center to nothing, a very slight painterly irregularity so
it is never a perfect digital gradient. Color is a warm candle-light honey-gold (#FFC872 at the center
fading through #FF9F4A to black) unless stated. Pure black (#000000) background, not transparent, no
other colors, no objects.

AVOID: any object, a lamp, a window, a flame, a sun, a sphere or a visible light source, stars, rays or spikes, lens flare, hard edges, outlines, text, letters, a border, a frame, grey or colored backgrounds, banding, a halo ring. Everything outside the glow is pure black (#000000).

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x1024)
- pass: chroma_ceiling (glow chroma p95 74 on 45% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.006 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (174 of 174 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
