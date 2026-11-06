# world__island-main-face-il6

- **Approved:** 2026-11-06T10:59:53+00:00 from batch `batch-60-earth-face`, job `island-main-face-il6`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:48:13+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `island-main-face-il6.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass all hard QA, literal manual review and exact native lossless cap; take1 lowest style-lock load0.5622 versus0.8719 and Harmony76.9 versus76.2. Preserve existing Pofu and Mochi doors including tea-glass sign, lawn/earth-band identity and four roots; add a third softsage round recessed door at the right earth face with creamcrossbar round window,tiny gear sign and actual forkedwrench on nail. Native gear/wrench closeups and proper cream/dark composites verified. Approximate windowcenter x1245 is86to88percent of tapered earth cross-section at doorheight y640to700, consistent with about88percent; whole lawn width is not substituted for earth-face span. Diagnostics are not a new threshold; no global pixelcorrelation gate or literal unchanged-pixel certification. Light values,haze,contrast warnings advisory, never hard-QA waivers. Tested t1 exactlossless504330bytes andt2=566832 both under614400 at1536x1024; no pixel edits,deliveryscale,lossy master or extra retry. Parent IL2 was already officially promoted,Harmony174sources measured/checked and pushdecodeverified f0755042 before these two calls. Home family consumer was prelinked once and must remain byte-stable; originals/callbacks/QA/locked all retained. This completes all3 authored jobs despite stale queuecount2.

## References

- `design/art/masters/island-main-face-il2/island-main-face-il2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.
- `design/art/masters/door-findik/door-findik.png`: Fındık's door design: sage green, a small gear sign, a wrench on a nail; paint it INTO the earth.

## Prompt (fingerprint 60f0ba880a471c4f)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.
2. Fındık's door design: sage green, a small gear sign, a wrench on a nail; paint it INTO the earth.

Edit the attached floating island: paint a third small round door
into its earth body, set into the earth exactly like the other two
round doors, at the same height, at about 88 percent of the earth
body's width from its left edge. This door is painted a soft sage
green with a small round window, a tiny gear-shaped sign and a
small wrench hanging on a nail beside it, as in the attached door
design, framed by the same rim of small stones, with the same soft
recess shadow and light. Everything else stays exactly as it is.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a pasted-on look, a different light or texture, moving or resizing anything, characters, text

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 29 (R1 51))
- warn: light_values (day/subject: L p2 58 (at most 22), p98 91 (at least 90), spread 33 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 82 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.39 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 2.4 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 2.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.6)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 7.9, off-palette 1.3% (top: #888877 (0.5%), #888866 (0.4%)))
- pass: depth_ratio (earth depth / width 0.25 (at most 0.32))
- pass: lawn_chroma (lawn chroma p95 19 (palette meadow 38))
- pass: harmony (harmony score 77 against the world reference (outliers: C_p95))
- pass: edit_silhouette (99% of the parent's shape kept)
- pass: edit_stability (97% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
