# prop__growth-lily-pad

- **Approved:** 2026-11-09T21:43:13+00:00 from batch `batch-65-growth-pieces`, job `growth-lily-pad`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:42:39+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-lily-pad.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

## Prompt (fingerprint e3a8115ec370984c)

```text
REFERENCES (attached, in this order):
1. A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

A single small lawn piece for a cozy mobile game, as a game sprite
on a transparent background, in exactly the painting style, light
and finish of the attached home island and tea stall. One floating lily pad: a round soft green leaf with a small wedge notch cut out, a lighter green inner area, and one small pale-pink lotus blossom with a honey-yellow centre sitting on it. Flat on the water as seen from about 17 degrees above, a low oval. No water drawn around it.
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

AVOID: water, ripples, a frog, a ground shadow, a background, text, letters, a border, characters

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside with a warm bounce.
This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 25 (R1 51))
- warn: light_values (day/subject: L p5 66 (at least 50: darks stay a light mid-tone), p98 90 (at least 90))
- pass: light_median (day/subject: median L 80 (band 74-92))
- warn: light_contrast (day/subject: p75 local contrast 1.1 (band 2.5-6.5; above it reads too contrasty) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.7 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.0)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 2.1, off-palette 0.0%)
- warn: harmony (harmony score 60 against the world reference (outliers: C_p95, edge))

## Exact image-source receipt

- **Source receipt:** `source-growth-lily-pad-t2.json` (SHA-256 `421c03b846f943682ac4a40dac8db724f31eeef53cd0ed5a9a8f8d0543ae02be`).
- **Original image file:** `exec-b4ab2088-ef7b-4055-ab24-1af3cab252b8.png`; PNG SHA-256 `a2a5b017a4aed2df0bd8559e581b3b9614cd21a4cef2b72cc686dc783c7b364f`; RGBA-pixel SHA-256 `f997bf17100ef8280543177f384a6cd283adf4f989bb2936f746237469675fac`; dimensions `1254x1254`; 508614 bytes.
- **Image tool returned:** `2026-11-09T21:26:43.857Z`; take ordinal `2`, round `1`.
- **Prompt binding:** SHA-256 `5e2ef9e72170d47e56b6f2f0533c213c430087236a5bf50dd4feaa546515dd88`; fingerprint `e3a8115ec370984c`.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (`chatgpt-plan`).
- `meta.json` `generation.generated_at` records pipeline import/ingest time, not tool-return time; the exact tool-return time above comes from the preserved source receipt.
