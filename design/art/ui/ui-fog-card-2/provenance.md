# ui__fog-card-2

- **Approved:** 2026-11-06T08:17:16+00:00 from batch `batch-44-weather-fx`, job `fog-card-2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T07:21:16+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-fog-card-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Thin broken volumetric pale-grey mist, black gaps, two/three rising curls, soft falloff. Take2 curl reaches delivered top edge and is excluded under literal all-edge fade. Hard QA passes; absent lock_load/Harmony use0 fallback then ordinal1.

## References

- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: An approved glow sprite of the game: match its soft airbrushed grain and smooth falloff on pure black (do not draw a pool).

## Prompt (fingerprint abe209896a897a1e)

```text
REFERENCES (attached, in this order):
1. An approved glow sprite of the game: match its soft airbrushed grain and smooth falloff on pure black (do not draw a pool).

A thin, broken band of drifting mist across the middle of the image,
lighter and more transparent than a fog bank: separate soft wisps
with gaps of black between them, two or three slow curls of mist
rising from it like steam. Pale white-grey on pure black, fading to
black well before every edge.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

MASK SPRITE: painted light-on-black for a game; the app uses its
brightness as a soft mask, so pure black (#000000) means no mist.
Only white and soft greys, the same soft airbrushed grain as the
attached sprite, a slight painterly irregularity, never a digital
gradient.

AVOID: hard cloud outlines, cumulus puffs, any object, colour, stars, rays, text, letters, a border, banding, grey or coloured backgrounds

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024 scaled x1.000 and center-cropped to 1536x512)
- pass: chroma_ceiling (glow chroma p95 1 on 12% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.004 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (104 of 104 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.4 (R1 5.3))
