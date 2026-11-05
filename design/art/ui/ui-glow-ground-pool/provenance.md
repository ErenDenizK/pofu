# ui__glow-ground-pool

- **Approved:** 2026-11-05T21:36:22+00:00 from batch `batch-35-experience-pilot`, job `glow-ground-pool`, take t1
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T19:26:31.841Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-glow-ground-pool.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained-only re-post under the authoritative additive profile; all four original sources pass every hard check. Official additive post skips style lock and preserves near-black rather than lifting it to gray. All lock loads are zero by construction; stable take-order tie picks evaluation t1. Wide warm painterly ellipse, smooth falloff, no emitter, objects, text, ring or rays. Border-band luma p99 0.0129 passes the new 0.05 target; no manual black cleanup. Original prompt/reference hashes and run-qualified take identity preserved in salvage sources. No generation. UI location is excluded by the canonical Harmony catalog; official measure/check still run and proof is preserved.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).

## Prompt (fingerprint 70315e48ce0ae4e8)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).

A pool of warm lamplight lying on a lawn, seen from a low camera about 17 degrees above the ground, so the
pool is a wide flat ellipse about twice as wide as it is tall, centered in the image and filling about
80 percent of the width. Brightest near the middle, with a soft, slightly uneven painterly edge that
dies into black well before the image border. Warm honey-gold light only: no grass blades, no ground, no
shadows, no object casting it.

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
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x512)
- pass: chroma_ceiling (glow chroma p95 70 on 46% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.013 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (167 of 167 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))

Retained-source QA re-post, no new generation. Original run batch-35-experience-pilot, take 1. Current fingerprint identifies evaluation context only; original prompt/reference hashes and callback are preserved in salvage-source.json.
