# prop__growth-lantern-string-lit

- **Approved:** 2026-11-09T21:43:17+00:00 from batch `batch-65-growth-pieces`, job `growth-lantern-string-lit`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-09T21:42:06+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `growth-lantern-string-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/growth-lantern-string/growth-lantern-string.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint ca4a0eea1a7e34ff)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the lanterns from inside: every small round paper lantern now
glows warm candle-amber, a little brighter toward its middle,
painted as soft broad shapes. Only the lantern paper changes: the
cord, the posts and the lantern caps keep their exact day colors
(the app adds the glow, the halos and the night grade).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow or halo outside the paper, light on the cord or the posts, a night sky, darkening anything, blown yellow-white highlights, text.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES (the reference envelope): a high-key picture inside one envelope of soft, milky air. Every value sits between light mid-tone and cream-white; the darkest recesses (door holes, gaps, pond rims) are a mid-value tinted with the shadow hue, never black. Form turns in small value steps. Colour lives in the halftones; lights bleach to cream. No dark outlines: edges are found by value and hue. The cloud sea below is the brightest large surface and lights the island's underside with a warm bounce.
This is the SUBJECT plane: the clearest forms and the crispest edges in the picture, still inside the envelope.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: light_values (day/subject: L p5 70 (at least 50: darks stay a light mid-tone), p98 93 (at least 90))
- pass: light_median (day/subject: median L 80 (band 74-92))
- pass: light_contrast (day/subject: p75 local contrast 2.7 (band 2.5-6.5; above it reads too contrasty))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.7, p95 5.3, off-palette 0.0%)
- pass: harmony (harmony score 84 against the world reference (outliers: L_p2, edge))
- pass: emit_leak (100% of the parent unchanged outside the emit region (masked out of the master))

## Exact image-source receipt

- **Source receipt:** `source-growth-lantern-string-lit-t1.json` (SHA-256 `63b477fb239e464c5baa50ed48a0de5b59349f65ddc6baf858de0f2a4941628c`).
- **Original image file:** `exec-538fb486-3016-4680-a3a0-d4e9503bc609.png`; PNG SHA-256 `e6a77a932822bb457ffecbdf86ee2e8b201b22e1bedd5bcab5af256f4479ec91`; RGBA-pixel SHA-256 `4ce87535ac74cafa5324e0d7d70cbb9b00fc01adb5fb631b44fc6e7583651afb`; dimensions `1254x1254`; 369291 bytes.
- **Image tool returned:** `2026-11-09T21:40:45.125Z`; take ordinal `1`, round `1`.
- **Prompt binding:** SHA-256 `6ea24afccda971bfd33ee606c7752ddb1bdd68589bb4985dcb4f6b9f0c618ca5`; fingerprint `ca4a0eea1a7e34ff`.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission (`chatgpt-plan`).
- `meta.json` `generation.generated_at` records pipeline import/ingest time, not tool-return time; the exact tool-return time above comes from the preserved source receipt.
