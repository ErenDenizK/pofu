# char__pofu-rig-clean

- **Approved:** 2026-11-02T18:02:55+00:00 from batch `batch-06-pofu-rig-pilot`, job `pofu-rig-clean`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T18:00:31+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pofu-rig-clean.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass QA. Alpha compositing on blue confirms transparent margins: the raw-image preview displayed RGB under alpha zero as a halo; it is not visible in actual composition. The temporary visual rejection was withdrawn after this check.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6c68c2e862f13579)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hamster. Remove only his two ears and his two
front paws:
1. Where each ear was, the top of the head continues as a smooth,
   rounded dome of the same golden-peach fur with the same soft
   fur strands along the outline. Keep the cream curl on top of
   the head exactly as it is.
2. Where the two front paws were held together at the chest, the
   chest continues as smooth, fluffy cream fur, the same as
   around it.
The eyes, face, blush, curl, body outline, feet, colors, size and
position stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: new ears, holes, bald patches, seams, arms, paws, a changed outline, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- pass: value_floor (lightness p5 66 (R1 59))
- pass: detail_budget (detail at display size 4.5 (R1 5.3))
- pass: palette_drift (mean dE 2.0, p95 6.7, off-palette 1.8% (top: #EE9955 (0.4%), #DD8844 (0.1%)))
- pass: ground_line (feet at 89.5% of the height (contract 88%))
- pass: edit_stability (92% of the parent level unchanged)
- pass: edit_chroma (chroma x0.88 of the parent level (drift compounds along a chain))
