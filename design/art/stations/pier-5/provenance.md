# station__pier-5

- **Approved:** 2026-11-05T06:37:03+00:00 from batch `batch-21-harbor-ladders`, job `pier-5`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:32:26+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pier-5.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Exactly4 takes after the one allowed retry. Takes1/2/3 fail hard palette_drift; take4 is the only hard-QA-passing candidate. Visual review confirms small triangular coral/cream/sea-blue bunting flags in soft swags from front post to post, wholly inside the canvas. The original coral rope, mooring rope/ferry, unlit lantern, honey bench, exactly two tulip tea glasses on their cream tray, planks/posts, framing and scale remain. No water, wake, smoke, ground shadow or guide. Parent station-anchor passes with no width/ground warning. Edit stability0.9359, chroma1.0244, style-lock load1.3233 and Harmony70.0. Chroma/light/palette warnings are advisory; no hard gate waived, palette/manifest/threshold edit or root guide fit. Auto-pick take4; founder review pending.

## References

- `design/art/stations/pier-4/pier-4.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint d46a043bc63bf092)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a string of small triangular bunting flags in coral, cream and sea blue hung in soft swags from post to post along the pier's front edge. The bunting stays inside the canvas; everything else stays.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 55 (R1 51))
- warn: light_values (day/subject: L p2 42 (at most 22), p98 91 (at least 90), spread 50 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 75 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.12 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 8.4 (at least 3.5))
- pass: detail_budget (detail at display size 4.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 3.3, p95 13.6, off-palette 6.9% (top: #558899 (1.1%), #557788 (0.9%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 70 against the world reference (outliers: L_p2, detail, edge))
- pass: edit_stability (94% of the parent level unchanged)
- pass: edit_chroma (chroma x1.02 of the parent level (drift compounds along a chain))
