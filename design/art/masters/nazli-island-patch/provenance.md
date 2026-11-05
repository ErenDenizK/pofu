# char__nazli-island-patch

- **Approved:** 2026-11-05T23:46:50+00:00 from batch `batch-37-nazli-rig-pilot`, job `nazli-island-patch`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:32:48+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `nazli-island-patch.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked initial takes pass independent content and actual published-body comparison: a small lawn-only mossy patch on the middle of the back, clear of face and paper-lantern scar, with a short wooden bench, exactly one mooring post and coiled rope, a grass tuft and exactly one empty curled honey-wood lantern hook. No soil bowl, roots, door, house, tree, lit lantern, character or unrelated object. Camera-facing face, eyes, faint smile, blush, scar, body placement and rounded stock tip remain visually registered on shared1536x1024 canvas, without fins or tail flukes. Canonical hard QA passes both, edit_stability0.9764/0.9761 and edit_chroma1.1497/1.0864 pass. No lock_load reported for char takes; equal-load fallback selects higher Harmony take2 (53.5 versus49.8). Light/Harmony warnings advisory; no invented numeric patch-size limit, stricter stability threshold, manual alignment, palette or alpha cleanup. Independent whole-whale edit of body only, not cumulative with other parts. Stable consumer links unchanged. Founder review pending.

## References

- `design/art/masters/nazli-body/nazli-body.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/takes/batch-34-islands-in-game/x-gezgin-f1-harbor/plate__x-gezgin-f1-harbor--t1.webp`: The approved Nazlı: copy the back patch only (a small mossy lawn with a bench, a mooring post and a hook), at that small size.

## Prompt (fingerprint d4b864b7295d3dfe)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. The approved Nazlı: copy the back patch only (a small mossy lawn with a bench, a mooring post and a hook), at that small size.

Edit the attached whale. Add the small island patch on her back: on
the middle of her back, well behind the head and clear of the scar,
a small mossy lawn no bigger than a cottage lot, grown into her
skin, with a short wooden bench, a single wooden mooring post with a
coil of rope round it, a tuft of grass, and one dark honey-wood
lantern hook curling over, with nothing hanging on it. Seen in the
same three-quarter view and the same painting; a lawn only, with no
soil bowl, roots, door or house. Only the patch is added: her head,
face, body, scar and everything else stay exactly as in the
attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a lit lantern, a bulb, a house, a door, soil or roots hanging below, a tree, characters, a pier, clouds, changing the face or the body, a shadow, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 26 (R1 51))
- warn: light_values (day/subject: L p2 55 (at most 22), p98 94 (at least 90), spread 39 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.33 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.2 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 2.0 (R1 5.3))
- pass: palette_drift (mean dE 1.5, p95 3.5, off-palette 0.0% (top: #995522 (0.0%), #884422 (0.0%)))
- warn: ground_line (feet at 85.8% of the height (contract 88%))
- warn: harmony (harmony score 54 against the char reference (outliers: C_p95, L_p2, tint_b))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.09 of the parent level (drift compounds along a chain))
