# ui__flow-pool

- **Approved:** 2026-11-10T16:50:28+00:00 from batch `batch-64-flow-pieces`, job `flow-pool`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-10T16:44:12+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-flow-pool.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both candidates show calm clear water, light rounded stone rim, moss and two grass tufts, faint ripples. Pool is somewhat wider than the approximate80percent brief; app framing not certified. Proper alpha composites clean; raw exterior glow is hidden RGB. Auto-picked by QA; founder review pending.

## References

- `design/art/takes/batch-17-islands-v2/x2-caglayan-b/plate__x2-caglayan-b--t1.webp`: Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).

## Prompt (fingerprint 4b85f8c1475026a7)

```text
REFERENCES (attached, in this order):
1. Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
2. A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).

A wide shallow pool seen from above with a slight tilt, as a game sprite on a transparent background: a soft oval of calm, clear blue-green water (soft painted, the same water as the island plate, a faint paler ripple, no glints), set in a rounded rim of pale warm-grey river stone with a little soft green moss and two tiny tufts of grass. About 80 percent of the canvas wide, centred. Even and calm in the middle.

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

AVOID: text, letters, numbers, symbols, an outline, a background, a ground shadow, foam clumps with hard edges, gloss, glints, pure black, neon blue, a 3D render look

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 30 (R1 51))
- pass: value_floor (lightness p5 72 (R1 59))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: palette_drift (mean dE 1.8, p95 4.7, off-palette 0.0%)
