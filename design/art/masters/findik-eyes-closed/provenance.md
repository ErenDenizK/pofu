# char__findik-eyes-closed

- **Approved:** 2026-11-02T19:11:56+00:00 from batch `batch-06-pofu-rig`, job `findik-eyes-closed`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T19:11:17+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `findik-eyes-closed.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Reference adaptation: original committed findik-base WebP (870x1306) is unchanged. Its exact decoded pixels were center-padded at offset (77,115) into an untracked 1024x1536 transparent PNG for generation and QA, without rescaling. Selected master remains canonical 1024x1536. Lead composite inverse crop is (left77,top115,right947,bottom1421); no direct pixel alignment to unpadded base is claimed. Ground-line warning from padding, palette/value warnings retained. Publication resumed under the repeated user request from original cached PNGs/local raw; no new generation. Current harmony audit at f35258d leaves the selected take unchanged; QA implementation, presets and rig manifest are byte-unchanged.

## References

- `design/art/masters/findik-base/findik-base.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 6b7543f46469b023)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hedgehog, Fındık. Change only the eyes: make both
eyes gently closed, as if peacefully asleep: a thin, soft, slightly
downward-curved dark line where the lower edge of each eye was, with
fur above it. Nothing else changes.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: eyelashes, tears, a changed mouth, a curl on the head, a ground shadow, text.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- warn: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 5.9 (R1 5.3))
- warn: palette_drift (mean dE 2.9, p95 13.3, off-palette 7.3% (top: #AA5533 (1.7%), #BB6633 (1.3%)))
- warn: ground_line (feet at 83.7% of the height (contract 88%))
- pass: edit_stability (96% of the parent level unchanged)
- pass: edit_chroma (chroma x0.99 of the parent level (drift compounds along a chain))
- pass: harmony (harmony score 74 against the char reference (outliers: L_p2, detail))
