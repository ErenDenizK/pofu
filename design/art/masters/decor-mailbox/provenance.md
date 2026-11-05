# prop__decor-mailbox

- **Approved:** 2026-11-05T05:47:37+00:00 from batch `batch-08-decor-pilot`, job `decor-mailbox`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T05:42:57+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 11, "dy": 2}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `decor-mailbox.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both candidates pass hard QA and visual review: sage round-topped mailbox, cream door, short chunky honey post and lowered rose flag, no letters or symbols, ground shadow or retained guide. Official guide fit places it on the ground ellipse below the height bar. Select the eligible take with lowest style-lock load, then Harmony. Founder review pending.

## References

- `design/art/templates/decor-guide.png`: The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/masters/decor-bench/decor-bench.png`: The first piece of this decor family: match its painting, light, colors, finish and scale exactly (do not draw the bench).
- `design/art/masters/island-main-s/island-main-s.png`: The island the piece stands on: same camera and softness.
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 3da494fad62baefa)

```text
REFERENCES (attached, in this order):
1. The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The first piece of this decor family: match its painting, light, colors, finish and scale exactly (do not draw the bench).
3. The island the piece stands on: same camera and softness.
4. The palette card for props: use only these colors (and mixes of them).

A little mailbox for the same island diorama: a round-topped box
of soft sage-painted wood with a small cream door, on a short,
chunky honey-wood post, and a small rose flag on its side, lowered.
Friendly, toy-like proportions with few parts. It stands on the
guide's ground ellipse, centered on the cross, no taller than the
height bar.

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
- pass: chroma_ceiling (chroma p95 37 (R1 51))
- pass: value_floor (lightness p5 63 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 2.2, p95 7.0, off-palette 0.3% (top: #998866 (0.3%), #888866 (0.0%)))
- pass: decor_anchor (on the decor guide)
- pass: harmony (harmony score 77 against the world reference (outliers: C_p95, edge))
