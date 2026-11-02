# char__pofu-eyes-closed

- **Approved:** 2026-11-02T18:09:21+00:00 from batch `batch-06-pofu-rig-pilot`, job `pofu-eyes-closed`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:08:23+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-eyes-closed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Pofu is never locked; lowest take number breaks the zero-lock-load tie. Automated warnings retained.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 737029fac0b6b2f5)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his eyes: close both eyes
gently and calmly, as if peacefully asleep. Each closed eye is a
thin, soft, slightly downward-curved dark espresso line where the
lower edge of the eye was, with the eyelid area above it covered
by the same short cream fur as the surrounding face. Nothing else
changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: eyelashes, tears, wrinkles, a changed mouth, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: value_floor (lightness p5 70 (R1 59))
- pass: detail_budget (detail at display size 4.8 (R1 5.3))
- pass: palette_drift (mean dE 1.9, p95 7.3, off-palette 2.5% (top: #EE9955 (0.3%), #EE7766 (0.3%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (95% of the parent level unchanged)
- pass: edit_chroma (chroma x0.92 of the parent level (drift compounds along a chain))
