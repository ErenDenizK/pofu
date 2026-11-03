# icon__mood-content

- **Approved:** 2026-11-03T15:07:37+00:00 from batch `retry-2026-11-03`, job `icon-mood-content`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:56:46+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `icon-mood-content.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Resume from the fixed pre-stop original candidate, with zero image generation. Re-posted both retained PNGs under main9ede62e; both locked RGBA rasters match their retained versions exactly and the same eligible take remains lowest lock load. Fresh light/dark small-size visual review reconfirms the choice. Both takes simplify Pofu to his round golden-peach face, cream blaze and single curl, two round ears, espresso eyes with one catchlight each, blush ovals and a small w smile. Smooth silhouette, no whiskers or body. Reviewed at 28, 44 and 60 pt on pale and dark backgrounds.

## References

- `design/art/ui/icon-seed/icon-seed.png`: The approved seed icon: the icon family's look. Match its painting, size on the canvas, light and value structure exactly (do not draw a seed).
- `design/art/ui/icon-calm/icon-calm.png`: A second family member: the same painting and value structure.
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Pofu: the face to simplify. Same colors, same eyes, same tuft.

## Prompt (fingerprint 9b76f6be62eb8d92)

```text
REFERENCES (attached, in this order):
1. The approved seed icon: the icon family's look. Match its painting, size on the canvas, light and value structure exactly (do not draw a seed).
2. A second family member: the same painting and value structure.
3. Pofu: the face to simplify. Same colors, same eyes, same tuft.

A mood glyph, content: Pofu's face only, simplified into a round
icon: the golden-peach head with the cream blaze, the single cream
curl on top, two small round ears, two big round espresso eyes with
one round catchlight each, two blush ovals and a tiny "w" smile.
No whiskers, no fur strands along the outline (a smooth soft edge),
no body.

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

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- pass: value_floor (lightness p5 46 (R1 59))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: palette_drift (mean dE 1.4, p95 5.5, off-palette 0.6% (top: #BB5533 (0.2%), #BB6633 (0.1%)))
- pass: icon_fill (icon spans 84% of the canvas (target 80-92%))
- pass: icon_thin_parts (0.2% of the silhouette is thinner than 1.5 pt at 24 pt)
- pass: icon_small_detail (detail at 24 pt @3x 6.0 (busy above 7))
- warn: icon_on_light_glass (26% of the icon separates from light glass at 24 pt)
- pass: icon_on_dark_glass (96% of the icon separates from dark glass at 24 pt)
