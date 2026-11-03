# station__windmill-5-lit

- **Approved:** 2026-11-02T19:22:21+00:00 from batch `batch-07-light`, job `windmill-5-lit`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:20:02+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `windmill-5-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take1 has lowest non-failing load0.5129 and stability0.9870 above manual0.9 gate. Only window interiors are lit; frames, flower boxes and other objects retain their shapes/light. Harmony44.0 advisory warning retained. Already generated before global workshop stop.

## References

- `design/art/stations/windmill-5/windmill-5.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 95fc7d19cec89b0c)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the two small round windows on the tower from inside: each
window glass becomes a soft warm honey-amber, a little brighter
toward its center, with the window frame and the flower boxes
unchanged. Only the two window glasses change: no glow, light or
color change on the tower, the flowers, the cap or the sails (the
app adds the glow around them).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow outside the windows, lit flowers, blown yellow-white highlights, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 12 (R1 51))
- pass: value_floor (lightness p5 75 (R1 59))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 2.0, off-palette 0.0%)
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 44 against the world reference (outliers: C_p95, L_p2, L_p98, edge))
- pass: edit_stability (99% of the parent level unchanged)
- pass: edit_chroma (chroma x1.05 of the parent level (drift compounds along a chain))
