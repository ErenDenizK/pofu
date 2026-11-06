# ui__glow-pond-shimmer

- **Approved:** 2026-11-05T23:57:37+00:00 from batch `batch-35-experience`, job `glow-pond-shimmer`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:37:04+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-glow-pond-shimmer.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x512 take; the master and raw are delivered at x0.5 (512x256, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both full-size initial takes pass canonical additive background, falloff and banding QA; independent original and locked review confirms a wide flat cool teal-mint ellipse with broken horizontal ripples, brighter center, soft black falloff, no water surface, reflected object, lily, lantern, ring or text. Additive style lock is intentionally skipped; no lock_load or Harmony ranking metric is returned, so the deterministic equal-rank tie selects take1. Official authored scale0.5 creates the512x256 delivered master from its saved1024x512 full lock, with exact pixel/metadata proof. Real Harmony measure/check runs and the authoritative catalog excludes this UI asset without a fabricated shard. No source pixel cleanup.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: The approved ground pool: the same painterly grain and falloff, but this one is a cool teal (do not copy its color).

## Prompt (fingerprint d4948225487f1148)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The approved ground pool: the same painterly grain and falloff, but this one is a cool teal (do not copy its color).

Moonlit shimmer on pond water, seen from a low camera about 17 degrees above the surface: a wide flat
ellipse about twice as wide as tall, centered, filling about 85 percent of the width, made of soft
horizontal ripple bands of cool teal-mint light (#8CE0D0 at the brightest, fading through #3FA6A0 to black),
brighter near the middle and broken into a few gentle, slightly uneven bands. Cool teal only, never warm: no
water surface, no lily pads, no lantern, no reflection of objects.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

GLOW SPRITE: a painterly additive light sprite for a game: the app adds it on top of the world with
plus-lighter blending, so black means no light at all. Painted with the same soft airbrushed grain as the
attached art, a smooth falloff from a brighter center to nothing, a very slight painterly irregularity so
it is never a perfect digital gradient. Color is stated in the brief. Pure black (#000000) background, not transparent, no
other colors, no objects.

AVOID: any object, a lamp, a window, a flame, a sun, a sphere or a visible light source, stars, rays or spikes, lens flare, hard edges, outlines, text, letters, a border, a frame, grey or colored backgrounds, banding, a halo ring. Everything outside the glow is pure black (#000000).

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x512)
- pass: chroma_ceiling (glow chroma p95 41 on 41% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.012 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (198 of 198 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
