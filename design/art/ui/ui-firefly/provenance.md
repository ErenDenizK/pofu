# ui__firefly

- **Approved:** 2026-11-05T23:27:35+00:00 from batch `batch-35-experience`, job `firefly`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:10:44+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-firefly.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes show exactly four separated matching plum-brown fireflies with two pale wings and two short antennae: dim amber, rising yellow core, brightest soft honey halo, then fading amber. Original and official locked images independently reviewed: no hard glow ring, text, floor or unrelated object. Select the lowest eligible style-lock load using the canonical QA reports. This UI asset is excluded by the authoritative Harmony catalog; run the real measure/check pair and retain its proof without fabricating an asset shard.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint ec5b08ffafde1251)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The palette card for props: use only these colors (and mixes of them).

A sprite sheet of one firefly shown four times in a single row, left to right, evenly spaced with wide empty
space between them: (1) body dim, abdomen a faint warm amber; (2) the abdomen glowing, a small warm yellow
core; (3) at its brightest, a warm yellow-white core with a soft honey-gold halo; (4) fading, amber again.
Each firefly is tiny, a plump rounded body of soft dark plum-brown with two pale translucent wings and two
short antennae, seen from the side. Chunky and toy-like, never realistic. On a plain transparent
background.

UI OBJECT: a painted object that the app places under or inside native
iOS glass controls. Never paint glass, frosted panels, buttons, frames,
progress bars or any interface chrome: the app draws all glass and all
controls natively. The object is centered with a generous transparent
margin of about 10% on every side.

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

AVOID: realistic insects, thin legs, detailed wings, outlines, text, a floor, a ground shadow, a jar, a person, a hard glow ring

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 39 (R1 51))
- pass: value_floor (lightness p5 43 (R1 59))
- pass: detail_budget (detail at display size 2.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.2)
- pass: palette_drift (mean dE 0.9, p95 1.9, off-palette 0.0%)
