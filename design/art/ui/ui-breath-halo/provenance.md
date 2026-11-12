# ui__breath-halo

- **Approved:** 2026-11-06T12:50:19+00:00 from batch `batch-62-breath-room`, job `breath-halo`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T11:05:19+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-breath-halo.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.5 (512x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Retained initial pair only; both hard QA and manual glow checks pass. Canonical fallback ranking selects take 1. Official locked1024 to512 delivery and original inbox1254 to627 raw remain distinct; no generation or source edits on resume.

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials, warm light and colors (do not draw the stall).

## Prompt (fingerprint e79937c1351e8b08)

```text
REFERENCES (attached, in this order):
1. A finished prop of the game: match its soft airbrushed finish, matte materials, warm light and colors (do not draw the stall).

A single large round bloom of warm light, centered, about nine tenths of the image across, brightest at the middle in soft cream-honey (#FFE6B0) and falling smoothly through warm gold (#FFC872) and rose-peach (#FF9F7A) to nothing before the border. The edge is slightly uneven and painterly, never a perfect digital circle.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

GLOW SPRITE: a painterly additive light sprite: the app adds it on top of the scene with plus-lighter blending, so black means no light at all. Painted with the same soft airbrushed grain as the attached art. Pure black (#000000) background, not transparent, no other colors, no objects.

AVOID: any object, a sun disc, a sphere, a ring or halo outline, rays or spikes, stars, lens flare, hard edges, outlines, text, letters, a border, grey or colored backgrounds, banding. Everything outside the glow is pure black (#000000).

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x1024)
- pass: chroma_ceiling (glow chroma p95 57 on 60% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.029 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.00% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (198 of 198 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
