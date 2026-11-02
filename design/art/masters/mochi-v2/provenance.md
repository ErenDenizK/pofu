# char__mochi-v2

- **Approved:** 2026-11-02T14:36:22+00:00 from batch `batch-03-home-island`, job `mochi-v2`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:35:26+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `mochi-v2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/mochi-base/mochi-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 60aeea5a68828d55)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached bunny, Mochi. Change only these two things:
1. Remove the single cream curl of fur on top of her head
   completely. The top of her head becomes a smooth, softly
   rounded dome of the same cream fur: no curl, no swirl, no
   tuft, no quiff of any kind. (That curl belongs to Pofu, the
   hamster, alone.)
2. Make her two floppy ears longer and softer: they hang from the
   top of her head down beside her face to about the level of her
   front paws, about one and a half times as long as now, with
   the same blush-pink insides and soft, fluffy edges.
Her eyes, face, cheeks, body, paws, feet, colors and size stay
exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: any curl, swirl or tuft of fur on top of the head, upright ears, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 31 (R1 51))
- pass: value_floor (lightness p5 68 (R1 59))
- pass: detail_budget (detail at display size 3.8 (R1 5.3))
- pass: palette_drift (mean dE 0.9, p95 1.7, off-palette 0.9% (top: #441100 (0.1%), #CC5544 (0.1%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: edit_stability (83% of the parent level unchanged)
