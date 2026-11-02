# char__pofu-cheeks-puff-1

- **Approved:** 2026-11-02T19:06:06+00:00 from batch `batch-06-pofu-rig`, job `pofu-cheeks-puff-1`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:04:27+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-cheeks-puff-1.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint eb18aadf4639c304)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his cheeks: fill both cheek
pouches a little, as if he is carrying a few sunflower seeds in
them, so the face is slightly rounder and wider at cheek height.
Keep the same blush, eyes, mouth and expression. No visible food.
Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: visible seeds, a changed mouth, a changed body outline below the cheeks, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- pass: value_floor (lightness p5 58 (R1 59))
- pass: detail_budget (detail at display size 5.0 (R1 5.3))
- warn: palette_drift (mean dE 2.4, p95 10.7, off-palette 4.1% (top: #EE9955 (0.8%), #EE7766 (0.4%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (96% of the parent level unchanged)
- pass: edit_chroma (chroma x1.04 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 84 against the char reference (outliers: C_p95, detail))
