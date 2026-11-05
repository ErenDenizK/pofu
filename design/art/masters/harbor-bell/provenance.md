# prop__harbor-bell

- **Approved:** 2026-11-05T20:18:33+00:00 from batch `batch-33-home-showcase`, job `harbor-bell`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T19:56:05+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 20, "dy": -17}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `harbor-bell.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take2 is the only eligible initial source: narrow honey-wood post and short crossbar on a round flat stone foot, matte warm bronze-honey bell and short coral rope pull, no shine/reflections, lettering, guide, characters or cast ground shadow. Independent source/locked content review passes. Harddecor guide passes after official fit0.6488; lock0.8262,Harmony71.6. Take1 harddecor_anchor fails because top171isabove500heightbar and official requiredfit0.54isbelowminimum0.6; do not manually shrink or waive. Choosepassingloweststyleloadwithineligible, notnumericallyfailedtake. Lockedtake2PNG78398bytesfitslosslessly atfull1024canvas, sourcepixelsunchanged. Lightwarningsadvisory. OwnHarmonymeasure/check, provenance,rawandcontentrequired. Auto-pickedbyQA; founderreviewpending.

## References

- `design/art/templates/decor-guide.png`: The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/masters/path-lamp/path-lamp.png`: The path lamp of this island: same honey wood, finish and scale family (do not draw the lamp).
- `design/art/stations/bagel-cart-1/bagel-cart-1.png`: The harbor's first station: same coral, cream and sea-blue family (do not draw the cart).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 884be861a91c444f)

```text
REFERENCES (attached, in this order):
1. The decor guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The path lamp of this island: same honey wood, finish and scale family (do not draw the lamp).
3. The harbor's first station: same coral, cream and sea-blue family (do not draw the cart).
4. The palette card for props: use only these colors (and mixes of them).

A small harbor bell post for the island diorama: one sturdy honey
wooden post on a round flat stone foot with a short crossbar at the
top, from which hangs a plump round bell of matte warm bronze-honey
color (no shine, no reflections), a short coral rope pull hanging
from it. Narrow, toy-like. It stands on the guide's ground ellipse,
centered on the cross, and reaches the height bar's top.

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
- pass: chroma_ceiling (chroma p95 49 (R1 51))
- warn: light_values (day/subject: L p2 54 (at most 22), p98 84 (at least 90), spread 29 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 72 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.00 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.6 (at least 3.5))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.6, p95 3.5, off-palette 0.0%)
- pass: decor_anchor (on the decor guide)
- pass: harmony (harmony score 72 against the world reference (outliers: L_p98, edge))
