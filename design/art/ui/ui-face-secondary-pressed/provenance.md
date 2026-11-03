# ui__face-secondary-pressed

- **Approved:** 2026-11-03T14:08:08+00:00 from batch `retry-2026-11-03`, job `ui-face-secondary-pressed`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:55:47+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-face-secondary-pressed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both edits retain the cream capsule outline and show a darker inset top shadow with the upper highlight removed and lower lip flatter. t1 has the lower lock load and no failed automated checks. Reviewed against the approved secondary face and at the 52 pt shipping height.

## References

- `design/art/ui/ui-face-secondary/ui-face-secondary.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 64d136be7dd79b51)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Show the capsule pressed in: a soft shadow along its top edge, the
highlight gone, the lip along the bottom edge flatter, and the
whole capsule a touch darker. The shape and outline stay.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 22 (R1 51))
- pass: value_floor (lightness p5 73 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.2)
- pass: palette_drift (mean dE 0.6, p95 1.5, off-palette 0.0%)
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_stability (76% of the parent level unchanged)
- pass: edit_chroma (chroma x1.15 of the parent level (drift compounds along a chain))
