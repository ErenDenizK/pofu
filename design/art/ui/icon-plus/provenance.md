# icon__plus

- **Approved:** 2026-11-03T15:18:53+00:00 from batch `retry-2026-11-03`, job `icon-plus`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:58:48+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `icon-plus.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Resume from the fixed pre-stop original candidate, with zero image generation. Re-posted both retained PNGs under main9ede62e; both locked RGBA rasters match their retained versions exactly and the same eligible take remains lowest lock load. Fresh light/dark small-size visual review reconfirms the choice. Both takes show a warm-brown centre and eight plump sun-gold petals, with small cream highlights and no stem, pot or background badge. The sunflower head remains readable at 28, 44 and 60 pt on pale and dark backgrounds.

## References

- `design/art/ui/icon-seed/icon-seed.png`: The approved seed icon: the icon family's look. Match its painting, size on the canvas, light and value structure exactly (do not draw a seed).
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 96c9f6f38dc2ad19)

```text
REFERENCES (attached, in this order):
1. The approved seed icon: the icon family's look. Match its painting, size on the canvas, light and value structure exactly (do not draw a seed).
2. The palette card for props.

The icon for Plus: one sun-gold sunflower head seen straight on, a
round warm-brown center and eight plump rounded petals in a richer
gold than a normal sunflower, with a small cream highlight on each
petal.

ICON STYLE: a painted icon from the same picture book as the attached
hamster and island: the same soft airbrushed shading, the same warm
light from the upper left and the same milky pastel colors, simplified
for small sizes. One object only, centered, filling about 86% of the
canvas, built from three or four large, rounded shapes, so it reads as a
silhouette at 24 points. No thin parts: nothing narrower than a tenth of
the icon's width (no stems, strings, whiskers, spikes or tiny dots). A
clear value structure: the shadow side, or one warm-brown accent shape,
is dark enough to read on pale frosted glass, and the lit side reads on
dark glass. Matte, no glints, no texture. No outline, no drop shadow, no
background shape: no circle, tile, badge or plate behind the object. No
glass, no frosted panel, no glossy button. No text, no letters, no
numbers.

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

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 58 (R1 51))
- pass: value_floor (lightness p5 42 (R1 59))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- warn: palette_drift (mean dE 3.6, p95 6.7, off-palette 0.0%)
- pass: icon_fill (icon spans 91% of the canvas (target 80-92%))
- pass: icon_thin_parts (0.4% of the silhouette is thinner than 1.5 pt at 24 pt)
- pass: icon_small_detail (detail at 24 pt @3x 3.4 (busy above 7))
- pass: icon_on_light_glass (51% of the icon separates from light glass at 24 pt)
- pass: icon_on_dark_glass (100% of the icon separates from dark glass at 24 pt)
