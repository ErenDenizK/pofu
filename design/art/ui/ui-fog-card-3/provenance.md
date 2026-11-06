# ui__fog-card-3

- **Approved:** 2026-11-06T08:25:27+00:00 from batch `batch-44-weather-fx`, job `fog-card-3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T07:23:31+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-fog-card-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. auto-picked by QA; founder review pending. Both have one small wider-than-tall pale-grey mist drift, denser heart, wispy irregular falloff, black borders; no face/ghost/object/outline. Canonical1024x512 whole delivery reviewed. Hard QA passes; normalzero fallback then ordinal1.

## References

- `design/art/ui/ui-glow-ground-pool/ui-glow-ground-pool.png`: An approved glow sprite of the game: match its soft airbrushed grain and smooth falloff on pure black (do not draw a pool).

## Prompt (fingerprint e4e55c29ddb98642)

```text
REFERENCES (attached, in this order):
1. An approved glow sprite of the game: match its soft airbrushed grain and smooth falloff on pure black (do not draw a pool).

A single small, soft drift of mist, wider than tall, centered,
filling about 70 percent of the width: a soft pale white-grey veil
with a slightly denser heart and wispy ragged edges that fade into
pure black well before the border.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

MASK SPRITE: painted light-on-black for a game; the app uses its
brightness as a soft mask, so pure black (#000000) means no mist.
Only white and soft greys, the same soft airbrushed grain as the
attached sprite, never a digital gradient.

AVOID: a cloud with a hard outline, a ghost or face shape, any object, colour, text, letters, a border, banding, grey or coloured backgrounds

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x512)
- pass: chroma_ceiling (glow chroma p95 2 on 32% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.004 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (167 of 167 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
