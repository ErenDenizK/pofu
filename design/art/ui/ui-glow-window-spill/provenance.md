# ui__glow-window-spill

- **Approved:** 2026-11-05T23:08:51+00:00 from batch `batch-35-experience-pilot`, job `glow-window-spill`, take t1
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T19:26:53.413Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-glow-window-spill.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.5 (512x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Four retained originals re-posted with the published canonical PR227 fix and declared soft delivery. All four pass every additive hard QA check; no style lock is applied, so stable take order selects t1. The requested narrow bright sill end, widening soft warm trapezoid and absence of window/frame/emitter/text are verified. Near-black tail statistics are retained explicitly; no claim that every border pixel is exactly zero. Official 512x512 lossless export only; no new generation or local pixel edits.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).

## Prompt (fingerprint 7c5b17050407f464)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).

Light from a lit window falling across grass, seen from a low camera about 17 degrees above the ground:
a trapezoid of warm light that starts narrow and bright at the top center of the image (where the window
sill would be, no window drawn) and fans out down the image to about three times that width, getting fainter
with distance and dying into black before the bottom edge. The two long edges are slightly broken and
painterly, as if softened by the window's frame and a few blades of grass, and the far end is soft. Warm
honey-gold only: no window, no frame, no wall, no grass blades.

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
- pass: chroma_ceiling (glow chroma p95 69 on 39% lit pixels (additive profile))
- pass: additive_background (border luma p99 0.026 (near-black, at most 0.05): the glow dies before the edge)
- pass: additive_falloff (0.33% of the image has a hard edge (luma step over 0.08 per px at 256 px; soft falloff, at most 0.8%))
- pass: additive_banding (181 of 181 luma levels used across the falloff (100%; low means banding))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))

Retained-source QA re-post, no new generation. Original run batch-35-experience-pilot, take 1. Current fingerprint identifies evaluation context only; original prompt/reference hashes and callback are preserved in salvage-source.json.
