# char__pofu-paws-wave

- **Approved:** 2026-11-02T19:10:14+00:00 from batch `batch-06-pofu-rig`, job `pofu-paws-wave`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:09:33+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-paws-wave.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 72ae6f0ae3d5ea71)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Change only his front paws: his right paw
(on the left side of the image) is raised beside his face, open and
waving, palm toward the viewer with its three toe creases; his left
paw stays at the chest as in the original. The chest fur shows where
the raised paw was. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: both paws raised, an arm longer than a short furry nub, a changed head, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- pass: value_floor (lightness p5 59 (R1 59))
- pass: detail_budget (detail at display size 5.2 (R1 5.3))
- warn: palette_drift (mean dE 2.1, p95 8.3, off-palette 3.0% (top: #EE7766 (0.3%), #EE9955 (0.3%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.05 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 85 against the char reference (outliers: detail))
