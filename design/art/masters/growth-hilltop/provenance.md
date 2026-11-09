# prop__growth-hilltop

- **Approved:** 2026-11-09T21:41:49+00:00 from batch `batch-65-growth-pieces`, job `growth-hilltop`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:40:29+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-hilltop.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).
- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home plate: match its grass, earth, rim stones and light exactly (do not draw the island).

## Prompt (fingerprint 9c59b70a53d7426d)

```text
REFERENCES (attached, in this order):
1. A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).
2. The home plate: match its grass, earth, rim stones and light exactly (do not draw the island).

A single small lawn piece for a cozy mobile game, as a game sprite
on a transparent background, in exactly the painting style, light
and finish of the attached home island and tea stall. The hilltop terrace above the gate: a small round grassy hill top, about three times as wide as tall, with a soft lighter grass lip, a short warm cocoa-brown earth face with rim stones, a few wildflowers at the edge, and one small round-crowned tree standing near the middle (a short trunk, a plump soft green crown). A bare patch of lawn to its right for a bench, left empty. The hill tapers into the ground at its ends. A transparent background around it.
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

AVOID: a bench, buildings, characters, a straight hard edge, a ground shadow, a background, text, letters, a border, characters

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
- warn: light_contrast (day/subject: p75 local contrast 1.5 (band 2.5-6.5; above it reads too contrasty) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.0, p95 2.1, off-palette 0.0%)
- warn: harmony (harmony score 62 against the world reference (outliers: C_p95, edge))

## Exact image-source receipt

- **Source receipt:** `source-growth-hilltop-t2.json` (SHA-256 `69c3a40d8f30a8e891a8ef032349747c6311d808aa982c729211dc0baffbd171`).
- **Original image file:** `exec-d1c4ddb7-d2a1-48d9-a44a-7f7a571523fe.png`; PNG SHA-256 `5f5038aab4ea930a47d9f1dd668993cd727159b0d4e02f7009f391bed4782aa4`; RGBA-pixel SHA-256 `245ae450eb0acfb07e980780f0f3e73f6d5e36d1f546ec8200a6b6af622b4b1b`; dimensions `1254x1254`; 847649 bytes.
- **Image tool returned:** `2026-11-09T21:36:53.252Z`; take ordinal `2`, round `1`.
- **Prompt binding:** SHA-256 `dc6e07ac52b04f4ee648cda24d252a44bd0586b8fb09d106afa404684284dbfe`; fingerprint `9c59b70a53d7426d`.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (`chatgpt-plan`).
- `meta.json` `generation.generated_at` records pipeline import/ingest time, not tool-return time; the exact tool-return time above comes from the preserved source receipt.
