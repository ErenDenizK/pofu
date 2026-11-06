# char__findik-sleepy

- **Approved:** 2026-11-06T00:56:56+00:00 from batch `batch-41-resident-reactions`, job `findik-sleepy`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T00:37:26+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 1.0013, "cx": 435.0, "cy": 1169.0, "dx": 1, "dy": 1}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `findik-sleepy.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Initial takes1/2 and sole retry take3 fail the authoritative palette_drift check (exact reports retained; mean dE3.1/3.0/3.4, p9514.8/14.5/15.2). Retry4 alone hard-passes, with genuine thin closed lower eyelids, fur above, calm small mouth line, and no zzz, tears, worried brow or teeth. Parent/locked comparison confirms spine silhouette, ears, compact body and all paws remain close to base; central body kept.9823 and alphaIoU.9966, global kept.9577 are diagnostic support rather than added thresholds. Same870x1306 canonical parent canvas. Exact lossless567318 bytes fits; higher off-palette failures never waived. Pick4 is the only eligible candidate. All24 batch originals and every initial/retry callback remain immutable; no further generation for this job.

## References

- `design/art/masters/findik-base/findik-base.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 4b04a076442f0088)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached hedgehog, Fındık, into a sleepy nap face. Change only the eyes and mouth: both eyes become gently closed, a thin soft slightly downward-curved dark line where the lower edge of each eye was, and the mouth relaxes into a calm small line. His spines, ears, body, paws, colors and size stay exactly as they are.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: tears, a worried look, open eyes, teeth, a ground shadow, text, motion lines, zzz.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536 scaled x0.850 into 870x1306)
- pass: edit_alignment (the edit rescaled the object x0.999 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 50 (R1 51))
- warn: light_values (day/subject: L p2 44 (at most 22), p98 96 (at least 90), spread 52 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 86 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.13 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 8.9 (at least 3.5))
- pass: detail_budget (detail at display size 6.1 (R1 5.3))
- warn: palette_drift (mean dE 3.1, p95 14.0, off-palette 8.5% (top: #AA5533 (2.3%), #BB6633 (1.5%)))
- pass: ground_line (feet at 89.6% of the height (contract 88%))
- pass: harmony (harmony score 73 against the char reference (outliers: L_p2, detail))
- pass: edit_stability (96% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
