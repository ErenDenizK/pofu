# ui__flow-grass

- **Approved:** 2026-11-06T18:10:26+00:00 from batch `batch-64-flow-pieces`, job `flow-grass`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T17:56:16+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-flow-grass.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.25 (256x256, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Take1 is the sole hardQA/manual eligible candidate. Its palette_drift WARN4.3948 stays advisory; take2 actual palette_drift FAIL5.4329 is excluded by unchanged QA. Both inventories show full-bleed short grass in close greens and a few tiny pale clover leaves, no stone, groove, water, outline or frame. Owner reviewed native originals, actual official locked256 delivery and70pt repeated tiles; minor handpainted gradient/texture seams remain advisory, exact seamless app integration is not certified. No invented leaf count, species-petal anatomy or footprint gate, and no retry when take1 is eligible. Canonical scale.25 lossless delivery/raw/preview verified; official Harmony measure/check on194 actualBASE sources. UI is outside authoritative catalog, no fabricated shard. Existing22 family consumer links remain byte-stable; all originals/callbacks/refs/reports preserved.

## References

- `design/art/takes/batch-17-islands-v2/x2-caglayan-b/plate__x2-caglayan-b--t1.webp`: Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).
- `design/art/ui/ui-flow-tile-straight/ui-flow-tile-straight.png`: The straight tile: the same bank stone, light and soft finish (do not copy its groove).

## Prompt (fingerprint 6aa859ddc5685aea)

```text
REFERENCES (attached, in this order):
1. Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
2. A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).
3. The straight tile: the same bank stone, light and soft finish (do not copy its groove).

A game tile for a cozy mobile puzzle, seen straight from above with a very slight tilt, lit softly from the upper left, filling the canvas edge to edge (full bleed): a quiet bank of short soft green grass in two close greens, a few tiny pale clover leaves, nothing else. Even enough at the edges to sit beside other tiles. No groove, no water, no stones.

STYLE: soft painterly 2D illustration from the same picture book as the
attached hamster: the same gentle airbrushed shading, the same light,
high-key values and the same milky pastel colors. Simple, rounded, chunky
shapes with few parts; fewer, larger shapes, because this is seen small on
a phone. Every material is painted matte, as a soft form with broad,
smooth value changes: wood without grain, metal without hammering or
reflections, glass as a soft tinted shape, cloth without weave. At most
one small, soft highlight per object; no glints, no shine. Colors are
muted and lifted toward cream; the darkest shadow is a warm mid-brown,
never near black. Warm diffused key light from the upper left, a faint
warm rim light along the right edge, soft ambient shadow only where forms
touch. Clean, calm, uncluttered. No outlines, no hard edges. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.

AVOID: text, letters, numbers, symbols, arrows, icons, an outline, a border or margin around the tile, a drop shadow outside the tile, dark brown or black grooves, bars or slots, deep holes, harsh contrast, gloss or specular glints, glass, pure black, neon or saturated colors, a 3D render look, photorealism

Output: one image, opaque, full bleed, square 1024 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1254x1254 scaled x0.817 and center-cropped to 1024x1024)
- pass: chroma_ceiling (chroma p95 47 (R1 51))
- pass: value_floor (lightness p5 78 (R1 59))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.9)
- warn: palette_drift (mean dE 4.4, p95 8.1, off-palette 0.0%)
