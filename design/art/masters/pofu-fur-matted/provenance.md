# char__pofu-fur-matted

- **Approved:** 2026-11-02T19:13:54+00:00 from batch `batch-06-pofu-rig`, job `pofu-fur-matted`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:13:14+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-fur-matted.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 360d959517d2dc67)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Make the fur look tired: flatter and
smoother, lying close to the body in soft clumps, with fewer fluffy
wisps on the outline, and the colors gently washed toward warm ash
(warm grayish cream and muted beige-peach, never blue-gray, never
green). Same pose, same size, same face and expression. Still cute
and clean, never dirty, wet, sick or injured. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: dirt, wetness, bandages, a thermometer, tears, a changed face, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 30 (R1 51))
- pass: value_floor (lightness p5 57 (R1 59))
- pass: detail_budget (detail at display size 4.0 (R1 5.3))
- pass: palette_drift (mean dE 1.3, p95 3.0, off-palette 0.8% (top: #BB4433 (0.1%), #441100 (0.1%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- warn: edit_stability (68% of the parent level unchanged)
- pass: edit_chroma (chroma x1.06 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 81 against the char reference (outliers: C_p95, detail))
