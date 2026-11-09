# prop__growth-flag-pole

- **Approved:** 2026-11-09T21:19:36+00:00 from batch `batch-65-growth-pieces`, job `growth-flag-pole`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:19:00+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-flag-pole.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

## Prompt (fingerprint 4895e54ef25638bc)

```text
REFERENCES (attached, in this order):
1. A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

A single small lawn piece for a cozy mobile game, as a game sprite
on a transparent background, in exactly the painting style, light
and finish of the attached home island and tea stall. A harbor flag on a slim wooden pole standing on a tiny mound of grass: a straight pale honey-wood pole with a small round finial, and a soft cream triangular pennant with a gently wavy edge flying to the right from near the top, with one small honey-yellow sunflower painted on the cream cloth (a simple round flower shape, no letters). The pole is about twice the height of the attached tea stall's counter. It must not look like any country's flag: no stripes, no bands of colour, no crosses, no stars, no crescent.
Centered, its feet or base on the bottom edge of the picture,
lit softly from the upper left.

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

AVOID: pennant with stripes, tricolour, cross, star, crescent, national flag, a ground shadow, a background, text, letters, a border, characters

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside with a warm bounce.
This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 44 (R1 51))
- pass: light_values (day/subject: L p5 70 (at least 50: darks stay a light mid-tone), p98 93 (at least 90))
- pass: light_median (day/subject: median L 82 (band 74-92))
- warn: light_contrast (day/subject: p75 local contrast 2.0 (band 2.5-6.5; above it reads too contrasty))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 2.1, off-palette 0.0%)
- pass: harmony (harmony score 80 against the world reference (outliers: L_p2, edge))
