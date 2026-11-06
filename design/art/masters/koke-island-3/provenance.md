# plate__koke-island-3

- **Approved:** 2026-11-06T07:10:00+00:00 from batch `batch-39-koke-production`, job `koke-island-3`, take t1
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-06T01:43:03.920Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `koke-island-3.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** lead-selected per queue row 0-k; founder review pending. lead-selected per queue row 0-k of docs/design/art-production-plan.md at main76d7d09a509202b464e48224f1d9e84f5da21bc4. The lead explicitly selected this retained original and requested official promote --force. No generation, source-pixel modification, prompt/palette/profile edit or QA threshold change. Original generating account, timestamps, callbacks, prompt/reference fingerprints and all four original takes are preserved; all historical CUT notes stay labelled and retained. This is a lead selection, not a QA auto-pick. Publish original take1 exactly. Historical canonical hard QA clears (warn-only), but its original and locked art leave the upper/back-right blue cluster shut while the outermost far-right yellow cluster is open: the explicit far-right remaining-bud position is not followed. This known manual content deviation remains accepted only by the exact unconditional row0-k selection; it is not erased or asserted to match the brief. Canonical half-size plate delivery768x512 is unchanged. Raking motion is explicitly requested and was not an invented registration failure. Current selected-take canonical QA status: warn. Actual hard failures (recorded unchanged): none. The exact retained lead selection uses official promote --force; this is not an automatic QA pass.

## References

- `design/art/masters/koke-island-0/koke-island-0.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint a490e481b0ac5fda)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Edit the attached island plate from stage 0 to stage 3: nearly
there. The moss on Koke's hump and the lawn is now almost entirely a
rich living green, with only a few pale grey spots left in the
deepest folds. Four of the five flower clusters are in open bloom:
butter yellow, blush pink, soft lilac and white blossoms with fresh
green leaves; the fifth, at the far right, still has buds. A warm
sun from the upper left lights the crown and the near side, with
soft warm shadows. Koke's near eye is open a sliver, a soft
sleepy half-moon of warm brown with a catchlight, looking at nothing
yet; the other eye is closed, and Koke is still lying down. The
small dormouse is out on the lawn with the little wooden rake,
raking the stepping-stone path, busy, at the size of a bagel. The
sprout on the crown is a small leafy shoot. The picture is almost
full colour (chroma about 85 percent of a healthy meadow) but
still, as if the island is holding its breath: no petals in the air,
no sparkles, no glow, no flowers growing on Koke's back. Every
shape, prop, stone, outline, the island's size, the camera and the
composition stay exactly where they are in the attached image.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: drifting petals, sparkles, a glow or halo, light rays, Koke standing, flowers on Koke's back, new props, moving or resizing anything, scary details, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1536x1024)
- warn: chroma_ceiling (chroma p95 58 (R1 51))
- warn: light_values (day/subject: L p2 38 (at most 22), p98 96 (at least 90), spread 58 (at least 60))
- pass: light_median (day/subject: median L 72 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.12 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.7 (at least 3.5))
- pass: detail_budget (detail at display size 3.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.0)
- warn: palette_drift (mean dE 4.2, p95 13.6, off-palette 9.2% (top: #BBBB44 (1.5%), #AABB44 (1.4%)))
- pass: edit_silhouette (100% of the parent's shape kept)
- pass: edit_stability (63% of the parent level unchanged)
- pass: edit_chroma (chroma x1.78 of the parent level (drift compounds along a chain))

Retained-source QA re-post, no new generation. Original run batch-39-koke-production, take 1. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
