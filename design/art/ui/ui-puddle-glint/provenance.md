# ui__puddle-glint

- **Approved:** 2026-11-06T08:33:52+00:00 from batch `batch-44-weather-fx`, job `puddle-glint`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T07:34:24+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-puddle-glint.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Both have single flat roughly3:1 pale silver-blue shimmer at the low camera, one/two tiny highlights near the upper edge, soft black falloff, no outline/rings/disc/ground texture. Whole canonical1024x512 reviewed; hard QA passes, normalzero fallback then ordinal1.

## References

- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: An approved glow sprite of the game: match its painting, falloff and camera angle (a flat wide ellipse); do not draw a pool of lamplight.

## Prompt (fingerprint 0c2f6fc139884d33)

```text
REFERENCES (attached, in this order):
1. An approved glow sprite of the game: match its painting, falloff and camera angle (a flat wide ellipse); do not draw a pool of lamplight.

A small shimmer of reflected sky light on a wet patch of ground,
seen from a low camera about 17 degrees above the ground, so it is
a flat soft ellipse about three times as wide as tall, centered,
filling about 60 percent of the width: a soft pale silver-blue sheen
with one or two tiny brighter highlights near its upper edge,
fading smoothly to black.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

GLOW SPRITE: a painterly additive light sprite; the app adds it with
plus-lighter blending, so black means no light. Pure black
(#000000) background, soft airbrushed grain.

AVOID: a puddle outline, water ripples drawn as rings, a disc, any object, ground texture, text, letters, a border, banding

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x512)
- pass: chroma_ceiling (glow chroma p95 15 on 31% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.004 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (159 of 159 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
