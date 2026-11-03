# char__simit-kitten-ears

- **Approved:** 2026-11-03T15:05:44+00:00 from batch `retry-2026-11-03`, job `simit-kitten-ears`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T13:53:51+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-kitten-ears.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained pair re-posted under main9ede62e; no new image generation. Both raise the front paws to cover both ears, squeeze the eyes into happy curves and open a soft o mouth, with no tears or worried look. Body, tail, feet and kitten identity remain. Current reports have warnings only from the inherited ground line; t2 also warns on Harmony69.1. Stability passes at0.7572/0.7804; no obsolete manual >0.9 gate. The previously unsealed proposal is now selected as t1 by Harmony71.7 versus69.1, with no character lock-load check and no failure waived.

## References

- `design/art/masters/simit-kitten/simit-kitten.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 549bb6831e90149b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached kitten, Simit: both front paws are raised and
pressed flat over her two ears, and her eyes are squeezed shut in
two happy-scrunched curves with her small mouth open in a soft "o".
Her body, tail, feet, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 54 (R1 51))
- pass: value_floor (lightness p5 60 (R1 59))
- pass: detail_budget (detail at display size 4.6 (R1 5.3))
- pass: palette_drift (mean dE 1.4, p95 4.0, off-palette 1.1% (top: #552211 (0.2%), #662211 (0.1%)))
- warn: ground_line (feet at 92.4% of the height (contract 88%))
- pass: harmony (harmony score 72 against the char reference (outliers: C_p95, L_p2, detail))
- pass: edit_stability (76% of the parent level unchanged)
- pass: edit_chroma (chroma x0.91 of the parent level (drift compounds along a chain))
