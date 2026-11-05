# prop__door-mochi

- **Approved:** 2026-11-05T17:57:31+00:00 from batch `batch-33-home-showcase-pilot`, job `door-mochi`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T17:52:37+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `door-mochi.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both show a front-facing soft rose round door in a thick honey frame, cream crossbar round window, matte brass knob, flat honey doorstep and one blank tulip-glass hanging sign. Only a thin soft earth ring fades to transparency; no house, wall, grass, steps, text or background. Both hard QA reports pass; lowest lock-load take2 is selected. It reads as a small door at 28px on light and dark backgrounds. Posted width is 583px versus approximate 40 percent prose target; final socket scale and two-thirds relationship to the plate door remain explicit lead pilot review, not claimed as a registered plate edit. Light-value/haze warnings are advisory under the current standard.

## References

- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home island: copy the style, colors, size and front-facing angle of the small round wooden door with a round window set into its earth body. Do not draw the island.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: Mochi keeps this tea stall: borrow its rose and cream colors for the door (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint e1370662ecc0a39a)

```text
REFERENCES (attached, in this order):
1. The home island: copy the style, colors, size and front-facing angle of the small round wooden door with a round window set into its earth body. Do not draw the island.
2. Mochi keeps this tea stall: borrow its rose and cream colors for the door (do not draw the stall).
3. The palette card for props: use only these colors (and mixes of them).

A small round wooden door set into soft earth, seen straight from
the front, in the same style as the round door on the attached
island: a round door of soft rose-painted wood in a thick honey
wooden frame, a small round window with a cream cross bar, a tiny
round brass-colored knob painted matte, a flat honey doorstep, and
over the door a little hanging sign shaped like a tulip tea glass
(a shape, no letters). Around the frame only a thin soft ring of
caramel earth that fades to transparent, so it can sit on the
island's earth body. Centered on an empty transparent background,
about 40 % of the canvas wide.

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

AVOID: a wall, a house, a roof, stairs, grass, a full earth background, letters on the sign.

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
- warn: light_values (day/subject: L p2 54 (at most 22), p98 90 (at least 90), spread 35 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 73 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.31 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.6 (at least 3.5))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.2)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.7, off-palette 0.0%)
- pass: harmony (harmony score 72 against the world reference (outliers: C_p95, edge))
