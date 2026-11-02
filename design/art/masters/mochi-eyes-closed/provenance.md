# char__mochi-eyes-closed

- **Approved:** 2026-11-02T19:07:06+00:00 from batch `batch-06-pofu-rig`, job `mochi-eyes-closed`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:06:15+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-eyes-closed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/mochi-v2/mochi-v2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 733c930804f463bd)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi. Change only the eyes: make both eyes
gently closed, as if peacefully asleep: a thin, soft, slightly
downward-curved dark line where the lower edge of each eye was, with
fur above it. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: eyelashes, tears, a changed mouth, a curl on the head, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 30 (R1 51))
- pass: value_floor (lightness p5 75 (R1 59))
- pass: detail_budget (detail at display size 3.2 (R1 5.3))
- pass: palette_drift (mean dE 0.7, p95 1.4, off-palette 0.7% (top: #441100 (0.1%), #DD6655 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: edit_stability (96% of the parent level unchanged)
- pass: edit_chroma (chroma x1.00 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 70 against the char reference (outliers: C_p95, L_p2))
