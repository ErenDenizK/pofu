# ui__pot-bud

- **Approved:** 2026-11-03T00:10:36+00:00 from batch `batch-11-ui-pilot`, job `ui-pot-bud`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:09:43+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-pot-bud.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass the strict edit_stability >0.9 gate (0.9668 and 0.9709). Four-background alpha composites are clean. The closed pointed green bud with a yellow hint and two rounded leaves is distinct from the bloom at native36x56pt. Pot, rim and soil remain aligned. Take2 has the lowest passing lock load0.6653 versus0.7266.

## References

- `design/art/ui/ui-pot-empty/ui-pot-empty.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 040b9c8ed6cc959e)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add one small closed bud growing from the soil on a short green
stem with two rounded leaves: a plump, pointed green bud with a hint
of golden yellow at its tip, simple soft shapes. The pot and soil
stay as they are.

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
- pass: chroma_ceiling (chroma p95 39 (R1 51))
- pass: value_floor (lightness p5 42 (R1 59))
- pass: detail_budget (detail at display size 1.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: palette_drift (mean dE 1.1, p95 1.5, off-palette 1.8% (top: #667722 (0.2%), #778833 (0.2%)))
- pass: edit_stability (97% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
