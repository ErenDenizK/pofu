# prop__growth-lantern-string

- **Approved:** 2026-11-09T21:37:30+00:00 from batch `batch-65-growth-pieces`, job `growth-lantern-string`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:35:18+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-lantern-string.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

## Prompt (fingerprint 0b9cf63c71f7d268)

```text
REFERENCES (attached, in this order):
1. A finished piece on the home lawn: match its painting, light, finish and camera exactly; the scale reference (do not draw the stall).

A single small lawn piece for a cozy mobile game, as a game sprite
on a transparent background, in exactly the painting style, light
and finish of the attached home island and tea stall. A string of small warm paper lanterns hung along a terrace: a thin cord drooping in two gentle curves between two short honey-wood posts, with seven small round paper lanterns hanging from it in soft coral, cream and honey colours, each with a tiny cap, DAY state: the paper is plain, matte and unlit (the app adds the glow at night). About 200 pt wide and 76 pt tall at game scale, the lowest lantern near the middle.
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

AVOID: glowing lanterns, light rays, a halo, a night sky, a ground shadow, a background, text, letters, a border, characters

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside with a warm bounce.
This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- pass: light_values (day/subject: L p5 69 (at least 50: darks stay a light mid-tone), p98 91 (at least 90))
- pass: light_median (day/subject: median L 79 (band 74-92))
- pass: light_contrast (day/subject: p75 local contrast 3.0 (band 2.5-6.5; above it reads too contrasty))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.0)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 2.2, off-palette 0.0%)
- pass: harmony (harmony score 75 against the world reference (outliers: C_p95, L_p2, edge))

## Exact image-source receipt

- **Source receipt:** `source-growth-lantern-string-t1.json` (SHA-256 `606d8c68c375c048c760a6530fcb7abfc2c13317b3e58f6221c13a7c9037489a`).
- **Original image file:** `exec-70bdf6c2-193d-4d01-aa9f-9ba60f56eca9.png`; PNG SHA-256 `3eb236aa06fcf3d81123135509b7660a226f759fd26b3520aae44475201147d1`; RGBA-pixel SHA-256 `bf58d53c5b1ab786c86858fe8a98f50c6809dcae8a0a28691092139e1d6bd545`; dimensions `1254x1254`; 384177 bytes.
- **Image tool returned:** `2026-11-09T21:31:42.398Z`; take ordinal `1`, round `1`.
- **Prompt binding:** SHA-256 `0b7f48168bbb6157fe2102e683ff555d266a067cf0672d8c9938943d84d19023`; fingerprint `0b9cf63c71f7d268`.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (`chatgpt-plan`).
- `meta.json` `generation.generated_at` records pipeline import/ingest time, not tool-return time; the exact tool-return time above comes from the preserved source receipt.
