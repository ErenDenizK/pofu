# char__mochi-work

- **Approved:** 2026-11-02T14:52:22+00:00 from batch `batch-03-home-island`, job `mochi-work`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:51:10+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `mochi-work.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/mochi-v2/mochi-v2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/stations/cay-1/cay-1.png`: The tea stall she runs: paint the tea glass and saucer exactly like the ones on its counter (do not draw the stall).

## Prompt (fingerprint ad3e0a5b0241e148)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. The tea stall she runs: paint the tea glass and saucer exactly like the ones on its counter (do not draw the stall).

Edit the attached bunny, Mochi, into her working pose at the tea
stall. Change only her two front paws: they now hold a small
tulip-shaped tea glass of warm amber tea on a tiny cream saucer in
front of her chest, as if offering it. The glass is a soft tinted
shape, matte, with no shine. Her ears, head, face, body and feet
stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a curl on the head, a teapot, a tray, steam, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 36 (R1 51))
- pass: value_floor (lightness p5 63 (R1 59))
- pass: detail_budget (detail at display size 4.0 (R1 5.3))
- pass: palette_drift (mean dE 1.1, p95 2.8, off-palette 2.1% (top: #DD7744 (0.3%), #441100 (0.2%)))
- pass: ground_line (feet at 87.8% of the height (contract 88%))
- pass: edit_stability (96% of the parent level unchanged)
