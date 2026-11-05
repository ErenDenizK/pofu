# prop__decor-bench

- **Approved:** 2026-11-04T23:04:16+00:00 from batch `batch-08-decor-pilot`, job `decor-bench`, take t1
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T23:02:48+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": -34, "dy": 48}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `decor-bench.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Queue operation refit-2026-11-04: reuse all4 retained original PNGs with verified source hashes; zero generation. Official post from PR154 uniformly fits the bench to its360px decor footprint before registration and lock. All4 now pass hard QA and guide fit; scale factors0.7709,0.7273,0.7438,0.7965 all exceed minimum0.6. Guide-review.jpg shows the new fitted locked takes, not the old failure overlays. Take1 has the minimum eligible lock load1.0857 and retains the honey bench and rose/cream striped cushion. No threshold, prompt or manifest edits; auto-picked by QA, founder review pending. Only this asset is un-cut; its dependents remain skipped pending lead review.

## References

- `design/art/templates/decor-guide.png`: The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
- `design/art/masters/island-main-s/island-main-s.png`: The island the piece stands on: same camera and softness.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 47ef92de1ab65d50)

```text
REFERENCES (attached, in this order):
1. The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
3. The island the piece stands on: same camera and softness.
4. The palette card for props: use only these colors (and mixes of them).

A small, cozy garden bench for two little animals, for the island
diorama: a short, chunky bench of soft honey wood with rounded
ends and a low curved backrest, and one plump cushion on the seat
with simple soft stripes of rose and cream (plain stripes, no
pattern, no motif). Friendly, toy-like proportions with few parts.
It stands on the guide's ground ellipse, centered on the cross,
and is no taller than the height bar.

Size (the first attempt came out twice too wide): the bench is
small. It is about 340 px wide in the 1024 x 1024 image, a third
of the image width, never wider than the guide's ground ellipse
(360 px), and about 220 px tall, its top well below the height
bar. Leave empty space on both sides of it.

VIEW: the same fixed front three-quarter view as the attached island: a
low camera about 20 degrees above the horizon, so you see the front of
the object fully and only a narrow sliver of its top (a round tabletop
reads as a flat oval about a third as tall as it is wide). Follow the
attached guide exactly: the object stands on the magenta ground ellipse,
centered on the magenta cross, its front edge on the front of the
ellipse, no taller than the magenta height bar. Then remove the guide
completely: no ellipse, no cross, no bar, no magenta, no grid may remain
in the output.

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
- pass: chroma_ceiling (chroma p95 43 (R1 51))
- pass: value_floor (lightness p5 65 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.0, p95 2.0, off-palette 0.0%)
- pass: decor_anchor (on the decor guide)
- pass: harmony (harmony score 84 against the world reference (outliers: edge))
