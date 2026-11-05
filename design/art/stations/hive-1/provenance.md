# station__hive-1

- **Approved:** 2026-11-05T19:43:08+00:00 from batch `batch-33-home-showcase-pilot`, job `hive-1`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T19:40:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 14, "dy": -38}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `hive-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Re-posted the four unchanged original PNGs from merged PR190 under the lead-authorized row0a-r guide-fit max_width360; no image generation and no manual resize or recolouring. Original generation prompt, reference hashes and fingerprint 9797062cde8fbe9d match the current exact CLI packet. Every original and prior inbox/build/review cache is retained. All four official numerical QA reports have no hard failure, but take1 and take3 need fit scales below the pipeline minimum0.6 (0.58 and0.53), so official fit is skipped and posted widths625/673 remain too large; exclude them under the explicit half-footprint brief. Take2 fits360px at scale0.6522 and take4 fits359px at scale0.6883, both on baseline900 and within the lower half of the station height budget. Select take4 by the lower style-lock load0.9349 versus1.0037; Harmony76.1 versus75.8 is the tie breaker only. The honey-coil bell-shaped straw skep on a low stump, dark round entrance, three tiny lavender clumps and one flat stepping stone read as a beehive at28px on light and dark backgrounds. No bees, lettering, fence, floor, guide or painted ground shadow. Light-value/haze and minor palette warnings remain advisory under current policy. auto-picked by QA; founder review pending.

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/stations/garden-1/garden-1.png`: The garden the hive stands near: same honey, sage and sunflower family (do not draw the garden).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 9797062cde8fbe9d)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
3. The garden the hive stands near: same honey, sage and sunflower family (do not draw the garden).
4. The palette card for props: use only these colors (and mixes of them).

A small beehive station for the island diorama: one plump,
bell-shaped straw skep of soft golden-honey coils, a small round
dark entrance at its foot, sitting on a low round stump of honey
wood, with three tiny clumps of lavender and a flat stepping stone
in front. Toy-like and cozy, few parts. It is small: it fills about
half the footprint's width and only the lower half of the height
bar, standing on the footprint, centered on the cross.

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

AVOID: bees, insects, honey dripping, a box hive, a fence.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- warn: light_values (day/subject: L p2 46 (at most 22), p98 88 (at least 90), spread 42 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 74 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.22 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.5 (at least 3.5))
- pass: detail_budget (detail at display size 1.2 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.9)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 2.4, p95 11.3, off-palette 4.0% (top: #888855 (1.1%), #999966 (0.7%)))
- pass: station_anchor (on the anchor)
- pass: harmony (harmony score 76 against the world reference (outliers: L_p98, edge))
