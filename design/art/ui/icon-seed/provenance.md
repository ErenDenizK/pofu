# icon__seed

- **Approved:** 2026-11-02T23:04:10+00:00 from batch `batch-11-ui-pilot`, job `icon-seed`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T23:02:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `icon-seed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes read as seeds at 28, 44 and 60 pt on light glass, dark glass and cream clay; the two cream stripes and pointed silhouette carry recognition. Canvas-fill warnings retained.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only: the hamster's soft painting and pastel colors.
- `design/art/stations/cay-1/cay-1.png`: Style reference for objects: how a prop is painted in this world (matte, simple, high key).
- `design/reference/palette-card-world-props.png`: The palette card for props.

## Prompt (fingerprint 319494e7b6cc11ac)

```text
REFERENCES (attached, in this order):
1. Style reference only: the hamster's soft painting and pastel colors.
2. Style reference for objects: how a prop is painted in this world (matte, simple, high key).
3. The palette card for props.

The icon for seeds, the game's one currency: a single plump
sunflower seed seen at a slight angle, a soft warm-brown shell with
two broad cream stripes, its tip pointing up and to the right.

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
- pass: chroma_ceiling (chroma p95 36 (R1 51))
- pass: value_floor (lightness p5 52 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: palette_drift (mean dE 0.8, p95 1.7, off-palette 0.0%)
- warn: icon_fill (icon spans 70% of the canvas (target 80-92%))
- pass: icon_thin_parts (0.2% of the silhouette is thinner than 1.5 pt at 24 pt)
- pass: icon_small_detail (detail at 24 pt @3x 4.9 (busy above 7))
- pass: icon_on_light_glass (57% of the icon separates from light glass at 24 pt)
- pass: icon_on_dark_glass (100% of the icon separates from dark glass at 24 pt)
