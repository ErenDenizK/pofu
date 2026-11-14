# ui__bubble-paper-night

- **Approved:** 2026-11-12T16:50:14+00:00 from batch `batch-77-redo-61-65`, job `ui-bubble-paper-night`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated unknown.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-bubble-paper-night.png` is the locked master the app and later edits use.
- **Review note:** Lead retained pick t2, promoted per QUEUE.md Demand row 0-h6 after current night recolor QA pass. Visual review: even cocoa face, amber top edge, same parent outline. Source is retained q90 WebP. Founder review pending.

## References

- `design/art/ui/ui-bubble-paper/ui-bubble-paper.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 50e952bf7b455aef)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

NIGHT VERSION of the attached day piece: the identical shape, size and position, every edge in the same pixels; only the colour changes. The whole face becomes ONE EVEN warm night colour: soft cocoa-brown paper in the steady glow of a lantern across the room (about #4A3A36 to #54423C), the same value from corner to corner and from edge to edge, so the middle stays perfectly flat and even. Only the thin lighter lip along the top edge catches a soft amber line (about #C98A4E). Stitches, where the day piece has them, become pale warm cream (about #E8D4B0); a rim or bound edge becomes a slightly lighter cocoa. The soft shadow under it stays a deeper warm brown, never black. Matte and calm, the same soft milky finish.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a glow in a corner, a gradient or vignette across the face, blue, indigo, violet or purple, a dark-to-light diagonal, a lantern or light source drawn, black, new shapes, a changed outline, text

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 12 (R1 51))
- pass: value_floor (lightness p5 28 (R1 59))
- pass: night_lightness (night variant: median lightness 28 (dark band 18-50))
- pass: detail_budget (detail at display size 0.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.6)
- pass: palette_drift (mean dE 1.0, p95 1.2, off-palette 0.0%)
- pass: edit_silhouette (99% of the parent's shape kept)
