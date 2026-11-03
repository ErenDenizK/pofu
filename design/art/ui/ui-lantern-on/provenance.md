# ui__lantern-on

- **Approved:** 2026-11-03T14:00:23+00:00 from batch `retry-2026-11-03`, job `ui-lantern-on`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:48:11+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `ui-lantern-on.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes light only the lantern paper inside its outline; ribs, caps, wooden post and foot retain the unlit shape. Alpha composites show no external halo or light spill. Select t2 by lower lock load 0.7053 vs 0.7130; chroma WARN 58.7 and palette WARN mean dE 2.3755 are retained as reported, with no threshold waiver. Region edit QA passes silhouette 0.9686 and stability 0.6209.

## References

- `design/art/ui/ui-lantern-off/ui-lantern-off.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 78db578785fa62d6)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the lantern from inside: the paper glows a warm honey-gold,
brightest at its center, the ribs, caps and post unchanged. Light
only inside the lantern's own outline: no halo, no glow, no rays and
no light spill outside the lantern (the app draws the glow around
it).

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
- warn: chroma_ceiling (chroma p95 59 (R1 51))
- pass: value_floor (lightness p5 63 (R1 59))
- pass: detail_budget (detail at display size 0.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- warn: palette_drift (mean dE 2.4, p95 9.8, off-palette 1.2% (top: #FFEE77 (1.1%), #FFEE88 (0.2%)))
- pass: edit_silhouette (97% of the parent's shape kept)
- pass: edit_stability (62% of the parent level unchanged)
- pass: edit_chroma (chroma x1.05 of the parent level (drift compounds along a chain))
