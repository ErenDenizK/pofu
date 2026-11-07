# ui__breath-ring-spark

- **Approved:** 2026-11-06T12:55:12+00:00 from batch `batch-62-breath-room`, job `breath-ring-spark`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T11:20:30+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-breath-ring-spark.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained initial pair only; both pass hard QA and manual round-head/soft-left-tail checks including14px review. Canonical fallback ranking selects take1. Native512 master and original1254 raw, no invented delivery scale, no generation or source edits on resume.

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials, warm light and colors (do not draw the stall).

## Prompt (fingerprint 06e168e3c1499d58)

```text
REFERENCES (attached, in this order):
1. A finished prop of the game: match its soft airbrushed finish, matte materials, warm light and colors (do not draw the stall).

A tiny soft spark of light: a bright cream-white core (#FFF3D6) with a round warm-gold bloom (#FFC872) around it and a short faint comet tail trailing to the left, fading to nothing. Centered, small, about a fifth of the image across.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

GLOW SPRITE: a painterly additive light sprite: the app adds it with plus-lighter blending, so black means no light at all. Pure black (#000000) background, not transparent, no other colors, no objects.

AVOID: a four-point star, cross flare, rays, a ring, any object, text, letters, hard edges, grey or colored backgrounds. Everything outside the glow is pure black (#000000).

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.408 and center-cropped to 512x512)
- pass: chroma_ceiling (glow chroma p95 44 on 3% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.004 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (212 of 212 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.2 (R1 5.3))
