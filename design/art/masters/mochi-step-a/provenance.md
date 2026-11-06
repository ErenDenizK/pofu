# char__mochi-step-a

- **Approved:** 2026-11-06T10:18:31+00:00 from batch `batch-59-resident-walks`, job `mochi-step-a`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:10:02+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9911, "cx": 510.0, "cy": 1353.0, "dx": 2, "dy": 0}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `mochi-step-a.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked takes preserve Mochi identity, face, cream fur, long curl-free ears, native framing and scale. Viewer-right foot is raised forward and opposite foot planted, with only the authored slight sway. Full originals/locked and 28px alpha composites reviewed independently; apparent raw-view warm glow is hidden RGB under alpha0, not a painted halo. No new ground, shadow, text or motion marks. Both QA reports warn without hard failures; no lock_load check is emitted for these registered edits, so normal equal-load ranking selects take1 by Harmony87.8 versus85.6. Canonical light warnings remain disclosed; no force, QA edits or new style gate.

## References

- `design/art/masters/mochi-v2/mochi-v2.webp`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1bcc1c99d4b4e527)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached character, the bunny Mochi, into one animation frame: the left foot (the viewer's right) lifted and stepping forward, the right foot planted, the body leaning a tiny bit forward, her long ears swaying slightly back. Keep the face, the colours, the fur, the size and the exact position on the canvas the same; change only the legs and paws and a slight sway, as a cute cartoon step, never a realistic gait.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: motion lines, dust clouds, a ground, a shadow, a different size, moving the character on the canvas, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1024x1536)
- pass: edit_alignment (the edit rescaled the object x1.009 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- pass: light_values (day/subject: L p2 19 (at most 22), p98 98 (at least 90), spread 78 (at least 60))
- warn: light_median (day/subject: median L 92 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.23 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 3.8 (at least 3.5))
- pass: detail_budget (detail at display size 3.7 (R1 5.3))
- pass: palette_drift (mean dE 0.9, p95 2.2, off-palette 1.0% (top: #441100 (0.1%), #551100 (0.1%)))
- pass: ground_line (feet at 88.0% of the height (contract 88%))
- pass: harmony (harmony score 88 against the char reference (outliers: C_p95))
- warn: edit_silhouette (93% of the parent's shape kept)
- pass: edit_stability (80% of the parent level unchanged)
- pass: edit_chroma (chroma x1.14 of the parent level (drift compounds along a chain))
