# prop__path-lamp

- **Approved:** 2026-11-05T17:51:31+00:00 from batch `batch-33-home-showcase-pilot`, job `path-lamp`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T17:50:36+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 5, "dy": 10}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `path-lamp.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both have a slim slightly crooked honey post, small stone foot, curled hook and one round cream lantern under a coral cap, unlit with no flame or glow. No guide marks, lettering or broad background halo. Official guide fit preserves the narrow silhouette with transparent margins; day light values warn only. The requested approximate 120px width remains a pilot review observation rather than an invented threshold. Full numerical hard QA passes; final 28pt review is pending the lead.

## References

- `design/art/templates/decor-guide.png`: The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint d1cb2dd29ebfa4f2)

```text
REFERENCES (attached, in this order):
1. The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its style, camera, light, colors and scale exactly (do not draw the stall).
3. The palette card for props: use only these colors (and mixes of them).

A small garden path lamp for the island diorama: one slim, slightly
crooked post of soft honey wood on a round flat stone foot, and at
its top a short curled hook holding a plump round lantern of cream
paper-tinted glass under a small rounded coral cap, unlit (a soft
pale shape, no flame, no glow). Toy-like proportions, few parts,
friendly. It stands on the guide's ground ellipse, centered on the
cross, and its lantern reaches the height bar's top.

Size: the post is thin and the whole lamp is narrow, about 120 px
wide in the 1024 x 1024 image; leave wide empty space on both sides.

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

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 46 (R1 51))
- warn: light_values (day/subject: L p2 57 (at most 22), p98 93 (at least 90), spread 36 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 75 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.4 (at least 3.5))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 2.4, off-palette 0.0%)
- pass: decor_anchor (on the decor guide)
- pass: harmony (harmony score 90 against the world reference (outliers: edge))
