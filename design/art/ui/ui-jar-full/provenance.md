# ui__jar-full

- **Approved:** 2026-11-03T13:55:42+00:00 from batch `retry-2026-11-03`, job `ui-jar-full`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:47:27+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-jar-full.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes completely fill the front window with chunky warm-brown cream-striped seeds, without changing the lid, bow, body silhouette or framing. Region edit QA passes: t1 silhouette IoU 0.9923, stability 0.7653, chroma 0.893. Select t1 by lower lock load 0.7543 vs 0.7564. No obsolete manual stability >0.9 gate applied.

## References

- `design/art/ui/ui-jar-empty/ui-jar-empty.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 0d4a4c75e0a3ad72)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Fill the jar's front window panel completely with sunflower seeds:
a soft, full pile of chunky warm-brown and cream-striped seeds up
to the top of the window, painted simply (big shapes, not seed by
seed). Nothing else changes.

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
- pass: chroma_ceiling (chroma p95 36 (R1 51))
- pass: value_floor (lightness p5 41 (R1 59))
- pass: detail_budget (detail at display size 2.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.8)
- pass: palette_drift (mean dE 0.8, p95 1.8, off-palette 0.0%)
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_stability (77% of the parent level unchanged)
- pass: edit_chroma (chroma x0.89 of the parent level (drift compounds along a chain))
