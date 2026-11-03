# char__simit-kitten-work

- **Approved:** 2026-11-03T15:02:19+00:00 from batch `retry-2026-11-03`, job `simit-kitten-work`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:53:29+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-kitten-work.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained pair re-posted under main9ede62e; no new image generation. Both preserve the approved kitten identity and framing and change the front paws to hold one round wooden tray with exactly three simit rings. No head curl, steam or text. Current reports have warnings only: chroma, value, palette drift and inherited ground line; t2 additionally warns on edit_chroma x1.183. Stability passes at0.8622/0.8681; no obsolete manual >0.9 gate. The previously unsealed proposal is now selected as t2 by Harmony79.8 versus79.0, with no character lock-load check and no failure waived.

## References

- `design/art/masters/simit-kitten/simit-kitten.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6c681022e2f2b0f5)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached kitten, Simit, into her working pose. Change only
her two front paws: they now hold a small round wooden tray in
front of her chest with three plump sesame-crusted simit rings
(golden-brown rings dotted with cream seeds) on it. Her ears, head,
face, body, tail and feet stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a ground shadow, steam, text, a curl on the head.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- warn: chroma_ceiling (chroma p95 57 (R1 51))
- warn: value_floor (lightness p5 44 (R1 59))
- pass: detail_budget (detail at display size 6.4 (R1 5.3))
- warn: palette_drift (mean dE 2.2, p95 9.6, off-palette 3.9% (top: #995522 (0.4%), #884411 (0.2%)))
- warn: ground_line (feet at 92.6% of the height (contract 88%))
- pass: harmony (harmony score 80 against the char reference (outliers: C_p95, detail))
- pass: edit_stability (87% of the parent level unchanged)
- warn: edit_chroma (chroma x1.18 of the parent level (drift compounds along a chain))
