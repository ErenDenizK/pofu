# prop__decor-sailboat

- **Approved:** 2026-11-05T05:55:43+00:00 from batch `batch-08-decor-pilot`, job `decor-sailboat`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T05:50:27+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 12, "dy": 69}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `decor-sailboat.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. One retry pair only. Takes1/3 fail hard decor_anchor and remain ineligible. Initial take2 passes automated QA but is excluded for the bowl-shaped lower hull rather than the requested flat clean waterline; its unpublished preparation was preserved before commit and never uploaded. Retry take4 passes hard QA and visual review: honey hull with cream stripe, short mast, one cream triangular sail/rose stripe, plain pennant, rounded ends and a visible horizontal flat lower waterline; no water, wake, letters, guide or ground shadow. Official guide fit stays above its minimum and places it below the height bar. Choose take4 as the only semantically eligible passing take, lock load1.1409 and Harmony87.5; founder review pending. No prompt, manifest or threshold changed.

## References

- `design/art/templates/decor-guide.png`: The decor guide: the boat's waterline sits on the ground ellipse, centered on the cross; follow it, then remove it.
- `design/art/masters/decor-bench/decor-bench.png`: The first piece of this decor family: match its painting, light, colors, finish and scale exactly (do not draw the bench).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint d8a5c5aa65ace6ad)

```text
REFERENCES (attached, in this order):
1. The decor guide: the boat's waterline sits on the ground ellipse, centered on the cross; follow it, then remove it.
2. The first piece of this decor family: match its painting, light, colors, finish and scale exactly (do not draw the bench).
3. The palette card for props: use only these colors (and mixes of them).

A small toy sailboat for the same island diorama, as if folded
and painted by hand: a round-bottomed hull of soft honey wood with
a cream stripe, a short mast and one plump triangular cream sail
with a single soft rose stripe, a tiny plain pennant on top (no
symbols, no letters). Seen from the same low front three-quarter
camera, floating upright; its waterline is a flat, clean edge
with no water drawn.

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

AVOID: glossy or metallic shine, specular glints, reflections, hammered
or dimpled metal, wood grain, fine surface texture, photorealism, a 3D
render look, plastic or vinyl, high contrast, black or near-black
shadows, saturated or neon colors, outlines, cel shading, text, letters,
numbers, logos, watermarks, characters or animals, a floor, a background,
a ground shadow.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 44 (R1 51))
- pass: value_floor (lightness p5 61 (R1 59))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.0, p95 2.4, off-palette 0.0%)
- pass: decor_anchor (on the decor guide)
- pass: harmony (harmony score 88 against the world reference (outliers: edge))
