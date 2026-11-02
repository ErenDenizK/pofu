# station__workshop-5

- **Approved:** 2026-11-02T19:14:48+00:00 from batch `batch-05-fixes`, job `workshop-5`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:12:45+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, alignment to the parent level {"scale": 0.9989, "cx": 437.0, "cy": 909.0, "dx": -1, "dy": -1}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-5.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/stations/workshop-4/workshop-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 3099bdf03b4c0a15)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a big, round, gear-shaped wooden sign above the doorway: soft
honey wood with a cream rim and eight rounded teeth, plain (no
letters, no symbols).

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
- pass: edit_alignment (the edit rescaled the object x1.001 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- pass: value_floor (lightness p5 58 (R1 59))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.0)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 2.4, off-palette 0.1% (top: #AA6622 (0.0%), #BB7722 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 81 against the world reference (outliers: L_p98, edge))
- pass: edit_stability (88% of the parent level unchanged)
- pass: edit_chroma (chroma x0.99 of the parent level (drift compounds along a chain))
