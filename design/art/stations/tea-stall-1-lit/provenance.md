# station__tea-stall-1-lit

- **Approved:** 2026-11-02T18:07:38+00:00 from batch `batch-07-light-pilot`, job `tea-stall-1-lit`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:06:57+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `tea-stall-1-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass; t1 lowest lock load0.7482. Parent preservation98.48% exceeds90% manual gate. Alpha-aware blue composition is clean; flame remains inside burner, no added glow or brighter objects outside burner.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 14cf00a76e45d6a2)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the little round burner under the çaydanlık: inside its
opening, a small, soft flame of warm honey and coral shapes, and
the inside of the burner glows warm amber. Paint the flame as a
few soft, rounded tongues with no hard edges, matte, no sparks.
Only the burner changes: no glow, no light and no color change on
the teapot, the counter or anything else (the app adds the glow
and the warm light around it).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a big fire, sparks, smoke, steam, a glow outside the burner, light on other objects, yellow-white blown highlights, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 33 (R1 51))
- pass: value_floor (lightness p5 60 (R1 59))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.9, off-palette 0.0%)
- pass: station_anchor (on the anchor)
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x0.98 of the parent level (drift compounds along a chain))
