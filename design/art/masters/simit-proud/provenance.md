# char__simit-proud

- **Approved:** 2026-11-06T00:30:43+00:00 from batch `batch-41-resident-reactions`, job `simit-proud`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:05:48+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9996, "cx": 546.5, "cy": 1420.0, "dx": 0, "dy": 1}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `simit-proud.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Independent root review of parent/locked checkerboard confirms take2 preserves the lower-body silhouette, tail curl/stripes, paws and coral bandana layout. Face/chin lift and upright ears are the allowed changes; half-closed content eyes retain catchlights, and the small closed smile is warm rather than a sneer. Global edit stability .7031 is dominated by these requested large-face changes; central-body kept .9287 and alpha IoU .9978 support close registration without claiming literal texture identity or inventing a global threshold. Both initial takes hard-pass; char-guard applies no grading, so take2 wins higher Harmony71.2 vs68.3. Full-canvas lossless WebP570764 bytes is RGBA-identical to locked output. Advisory light/edit warnings are retained; no retry, resizing or local pixel edits.

## References

- `design/art/masters/simit-kitten/simit-kitten.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 839412cd2e79d38d)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached kitten, Simit, into a proud reaction. Change only the face and ears: the chin lifts a touch, both eyes become calm, content half-closed lids with the catchlights kept, the "w" mouth becomes a quietly confident small smile, the blush deepens a little, and both ears stand upright. Body, tail, paws, stripes, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a smirk, a sneer, tears, a worried look, a curl on the head, a ground shadow, text, motion lines.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: edit_alignment (the edit rescaled the object x1.000 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 54 (R1 51))
- warn: light_values (day/subject: L p2 54 (at most 22), p98 96 (at least 90), spread 42 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 84 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.20 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.4 (at least 3.5))
- pass: detail_budget (detail at display size 4.6 (R1 5.3))
- pass: palette_drift (mean dE 1.3, p95 3.7, off-palette 0.6% (top: #551100 (0.1%), #441100 (0.1%)))
- warn: ground_line (feet at 92.4% of the height (contract 88%))
- pass: harmony (harmony score 71 against the char reference (outliers: C_p95, L_p2, detail))
- warn: edit_stability (70% of the parent level unchanged)
- pass: edit_chroma (chroma x0.88 of the parent level (drift compounds along a chain))
