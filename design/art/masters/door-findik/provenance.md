# prop__door-findik

- **Approved:** 2026-11-05T19:51:11+00:00 from batch `batch-33-home-showcase`, job `door-findik`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T19:48:05+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `door-findik.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take2 selected among hard-QA/manual eligible sources. Both paint the sage/honey round door in a thick honey frame with cream-crossbar round window, round knob, flat doorstep, blank gear hanging sign and tiny wrench on nail, only a thin earth fade and no wall/house/roof/grass/stairs/text/background/cast ground shadow. Same front-facing Mochi-door family and readable sage/gear/wrench distinction at28px on light/dark. Size compared to actual approved sibling alpha-over24 bbox555x550 on1024: take1 is690x653 (about24percent wider) and excluded for family scale; take2 is595x574, close sibling scale within about7percent width and4percent height, accepted as family consistency rather than falsely claimed pixel registration. Eligible take2 lock0.6816/Harmony78.6, all hard QA passes, light/haze warnings advisory. No manual resize/repaint or threshold waiver. Auto-picked by QA; founder review pending; own Harmony measure/check, raw, provenance and content node included.

## References

- `design/art/masters/door-mochi/door-mochi.png`: Mochi's door, the first of this family: match its size on the canvas, front-facing angle, frame, earth ring and finish exactly (do not draw it).
- `design/art/stations/workshop-1/workshop-1.webp`: Fındık's workshop: borrow its sage-green and honey colors (do not draw the workshop).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 4ac5fd59fc446d3a)

```text
REFERENCES (attached, in this order):
1. Mochi's door, the first of this family: match its size on the canvas, front-facing angle, frame, earth ring and finish exactly (do not draw it).
2. Fındık's workshop: borrow its sage-green and honey colors (do not draw the workshop).
3. The palette card for props: use only these colors (and mixes of them).

A small round wooden door set into soft earth, seen straight from
the front, same family as the attached door: soft sage-green
painted wood in a thick honey wooden frame, a small round window
with a cream cross bar, a round knob, a flat honey doorstep, a
little hanging sign shaped like a round gear (a shape, no letters)
and a tiny wrench hanging on a nail beside the frame. A thin soft
ring of caramel earth around the frame that fades to transparent.
Centered on an empty transparent background, the same size as the
attached door.

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
- pass: chroma_ceiling (chroma p95 42 (R1 51))
- warn: light_values (day/subject: L p2 55 (at most 22), p98 90 (at least 90), spread 34 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 77 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.31 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.1 (at least 3.5))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 3.4, p95 10.6, off-palette 3.8% (top: #888855 (1.1%), #999966 (1.1%)))
- pass: harmony (harmony score 79 against the world reference (outliers: edge))
