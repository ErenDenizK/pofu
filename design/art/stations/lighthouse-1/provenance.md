# station__lighthouse-1

- **Approved:** 2026-11-04T23:13:55+00:00 from batch `batch-21-harbor-ladders`, job `lighthouse-1`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T23:03:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 12, "dy": -101}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Queue operation refit-2026-11-04: reuse all4 verified original PNGs, no image generation. Official PR154 fit now places every candidate within the height bar and on ground900; all hard QA and station-anchor checks pass, with scale factors0.7911,0.7903,0.7812,0.7937 above0.6. Take3 has minimum eligible lock load1.8994, height749px from top151 to ground900, solid width449. Native28 and guide-review.jpg confirm a striped toy lighthouse, unlit dark lamp room, round window and arched door, no beam or ground shadow. Light-standard warnings are advisory only. Record the fit in meta, un-cut only this asset, add its station consumer link; lighthouse2-to5 remain skipped pending lead review. Auto-picked by QA; founder review pending.

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/stations/bagel-cart-1/bagel-cart-1.png`: The harbor's first station: same coral, cream and sea-blue family (do not draw the cart).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint b10f1c5114cf3709)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
3. The harbor's first station: same coral, cream and sea-blue family (do not draw the cart).
4. The palette card for props: use only these colors (and mixes of them).

A small lighthouse for the island diorama: a plump, slightly tapered
round tower painted in broad soft bands of coral and cream, a tiny arched
door at its foot, one small round window, a flat honey-wooden gallery
ring under a round lamp room of tinted dark glass (a soft shape, not
transparent, unlit) and a small round coral cap. Toy-like proportions,
few parts. It fills the lower to upper part of the height bar and stands
on the footprint.

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
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- warn: light_values (day/subject: L p2 43 (at most 22), p98 91 (at least 90), spread 48 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 76 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.29 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.3 (at least 3.5))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.9)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.8, off-palette 0.0%)
- pass: station_anchor (on the anchor)
- pass: harmony (harmony score 76 against the world reference (outliers: C_p95, edge))
