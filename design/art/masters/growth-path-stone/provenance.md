# prop__growth-path-stone

- **Approved:** 2026-11-09T21:19:52+00:00 from batch `batch-65-growth-pieces`, job `growth-path-stone`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:18:22+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-path-stone.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

## Prompt (fingerprint 20352b454fd29ad7)

```text
REFERENCES (attached, in this order):
1. A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

A single small lawn piece for a cozy mobile game, as a game sprite
on a transparent background, in exactly the painting style, light
and finish of the attached home island and tea stall. One small flat path stone: a rounded warm-cream sandstone pebble about twice as wide as tall, lying flat on the lawn, a soft lighter top and a slightly darker lower rim, a tiny tuft of grass at one edge. Seen from the home camera, about 17 degrees above, so it is a low flat oval. Thumb-sized at game scale.
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

AVOID: path stone, a tuft of grass, a ground shadow, a background, text, letters, a border, characters

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside with a warm bounce.
This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 29 (R1 51))
- pass: light_values (day/subject: L p5 71 (at least 50: darks stay a light mid-tone), p98 94 (at least 90))
- pass: light_median (day/subject: median L 87 (band 74-92))
- warn: light_contrast (day/subject: p75 local contrast 0.7 (band 2.5-6.5; above it reads too contrasty) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.7, p95 1.5, off-palette 0.0%)
- warn: harmony (harmony score 62 against the world reference (outliers: C_p95, L_p2, edge))

## Exact image-source receipt

- **Source receipt:** `source-growth-path-stone-t2.json` (SHA-256 `a8f7958cffb8cf31b8042e08b148ed518925b4878917a6e1e9278dc65cc60520`).
- **Original image file:** `exec-b4352aef-7950-4a19-a086-e593e44725cf.png`; PNG SHA-256 `2bb7000146d36aff48a66b10b356162c51770e567fe1dcc9049481c7b3fb0aff`; RGBA-pixel SHA-256 `62d490b45e9bec21f22a7a39d0ad07d9ec092ec1fa4903483a9f350a1a954f29`; dimensions `1254x1254`; 435233 bytes.
- **Image tool returned:** `2026-11-09T21:14:30.273Z`; take ordinal `2`, round `1`.
- **Prompt binding:** SHA-256 `119dd61dcae139c540b2b84e2bb1cf49af3c0dadbd8262d8e7b51c3fa414b0bd`; fingerprint `20352b454fd29ad7`.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (`chatgpt-plan`).
- `meta.json` `generation.generated_at` records pipeline import/ingest time, not tool-return time; the exact tool-return time above comes from the preserved source receipt.
