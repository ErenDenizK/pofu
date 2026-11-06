# char__koke-stretch

- **Approved:** 2026-11-06T07:31:06+00:00 from batch `batch-39-koke-production`, job `koke-stretch`, take t2
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-06T01:53:51.304Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, alignment to the parent level {"scale": 0.9283, "cx": 506.0, "cy": 910.0, "dx": 0, "dy": -5}, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `koke-stretch.png` is the locked master the app and later edits use.
- **Review note:** lead-selected per queue row 0-k; founder review pending. lead-selected per queue row 0-k of docs/design/art-production-plan.md at main76d7d09a509202b464e48224f1d9e84f5da21bc4. The lead explicitly selected this retained original and requested official promote --force. No generation, source-pixel modification, prompt/palette/profile edit or QA threshold change. Original generating account, timestamps, callbacks, prompt/reference fingerprints and all four original takes are preserved; all historical CUT notes stay labelled and retained. This is a lead selection, not a QA auto-pick. Publish original take2 exactly. Historical hard failures include BOTH edit_silhouette alpha overlap0.6712 AND edit_stability parent-kept fraction0.1868; the latter failure is explicitly disclosed even though the queue summary names silhouette. The large stretch/yawn pose changes most of the asleep parent. Native1024square delivery, canonical QA and actual report values remain unchanged. Current selected-take canonical QA status: fail. Actual hard failures (recorded unchanged): edit_silhouette: 67% of the parent's shape kept; edit_stability: 19% of the parent level unchanged. The exact retained lead selection uses official promote --force; this is not an automatic QA pass.

## References

- `design/art/masters/koke-asleep/koke-asleep.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 1f7d6f437e69f6b7)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached moss creature, Koke, into a big waking-up
stretch. The front legs stretch far forward along the ground with
the paws spread, the haunches rise and the back arches up in a
rounded hump, the head lifts and tilts back a little in a huge soft
yawn: a wide round open mouth with a small pink tongue and no teeth,
the eyes squeezed shut in happy creases, the ears folded back. The
moss, the sprout on the crown, the colours, the style and the
lighting stay exactly as in the attached image; the creature keeps
the same ground line at 88 percent of the height and stays fully
inside the canvas.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: teeth, fangs, claws, a roar, an angry or scared look, open eyes, a changed art style, a ground, a shadow, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: edit_alignment (the edit rescaled the object x1.077 and moved it; aligned back to the parent)
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- warn: light_values (day/subject: L p2 40 (at most 22), p98 94 (at least 90), spread 54 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 74 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.16 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.2 (at least 3.5))
- pass: detail_budget (detail at display size 5.8 (R1 5.3))
- warn: palette_drift (mean dE 3.1, p95 10.7, off-palette 3.4% (top: #AA4433 (0.5%), #993322 (0.4%)))
- pass: ground_line (feet at 88.4% of the height (contract 88%))
- pass: harmony (harmony score 74 against the char reference (outliers: C_p95, L_p2, detail))
- fail: edit_silhouette (67% of the parent's shape kept)
- fail: edit_stability (19% of the parent level unchanged)
- pass: edit_chroma (chroma x0.91 of the parent level (drift compounds along a chain))

Retained-source QA re-post, no new generation. Original run batch-39-koke-production, take 2. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
