# ui__flow-tile-straight

- **Approved:** 2026-11-06T13:26:27+00:00 from batch `batch-64-flow-pieces`, job `flow-tile-straight`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T12:53:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-flow-tile-straight.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.25 (256x256, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Take 1 passes all hard QA and independent manual review, with the lowest eligible style-lock load 0.3843. One visually square full-bleed pale carved stone field, soft light shallow centered north-south channel, moss on banks only, closed east/west shoulders, no dark bar or writing. Actual canonical 256px export and 70pt single/2x2 abutting previews reviewed. Tiny corner antialias artifacts on take1 are disclosed as advisory; no invented zero-dark-pixel threshold. Exclude take2 despite numeric hardpass: its large dark rounded-card corners create visible junction holes at 70pt, violating explicit full-bleed geometry. No certified exact512px segmentation or completed app integration claimed. No retry because take1 eligible. Official deliver.scale0.25 is verified against canonical downscale RGBA, dimensions/meta, preview and raw encoding; no local pixel edits. UI lives outside the authoritative master/station catalog: official Harmony measure/check still runs against all194 currentBASE sources; no fabricated own shard. Only exact22flow family asset links are prelinked once in existing sys-island-games; unrelated fields/links and Damla consumer preserved. All originals/callbacks/ordered refs/QA/locked/source hashes retained. Queue count24 is stale; authored23 realjobs govern. This is the pilot: its ten true approved-ref dependents wait for promotion plus uploaddecode receipt.

## References

- `design/art/takes/batch-17-islands-v2/x2-caglayan-b/plate__x2-caglayan-b--t1.webp`: Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).

## Prompt (fingerprint 2a07ca3a47f536f4)

```text
REFERENCES (attached, in this order):
1. Çağlayan's concept plate: take ONLY the look of its pale rounded cliff stone, its soft moss and grass, its soft painted water and its light. Do not draw the island, the cliff, the mill or the pool as a scene.
2. A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).

A game tile for a cozy mobile puzzle, seen straight from above with a very slight tilt, lit softly from the upper left. A SQUARE of carved, mossy river stone that fills the whole canvas edge to edge (full bleed, no margin, no outline, no shadow around it): pale warm-grey stone with a faint cream and sage tint, rounded and softly worn, a little soft green moss gathered on the shoulders and corners, never on the groove. The channel is a SHALLOW, SOFT, LIGHT groove carved into the same stone: a gentle dip about 30 percent of the tile wide, centred, its floor only a little cooler and darker than the stone face (a pale grey-green, never brown, never near black), its walls softly rounded and lit, so it reads as a calm empty water-bed waiting for water, not as a slot or a bar. Matte, painted, soft, with broad smooth value changes.

The straight tile: one groove runs straight from the exact middle of the top edge to the exact middle of the bottom edge, 30 percent of the tile wide, perfectly vertical and centred. The left and right sides are closed: an even stone shoulder with a little moss near the outer corners.

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
- pass: chroma_ceiling (chroma p95 28 (R1 51))
- pass: value_floor (lightness p5 76 (R1 59))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: palette_drift (mean dE 0.9, p95 1.8, off-palette 0.0%)
