# station__pier-2

- **Approved:** 2026-11-05T05:50:32+00:00 from batch `batch-21-harbor-ladders`, job `pier-2`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T05:48:01+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pier-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass hard QA; take2 has the lowest style-lock load0.9659 versus0.9692 and higher Harmony84.7. Visual review confirms one short honey post with cream paper-tinted unlit lantern and coral cap at the outer plank end; original planks, four supports, coral rope, framing and footprint are preserved. No water, wake, clouds, painted glow, shadow or guide. Edit stability0.9955 and chroma1.0434; edits receive no root guide fit. Advisory warnings remain recorded. Founder review pending.

## References

- `design/art/stations/pier-1/pier-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint ce47fb37cb3d5dd3)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a short honey wooden post at the pier's outer end with a plump round lantern of cream paper-tinted glass under a small coral cap, unlit (the glow is code). The planks and posts stay as they are.

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
- pass: chroma_ceiling (chroma p95 45 (R1 51))
- warn: light_values (day/subject: L p2 50 (at most 22), p98 90 (at least 90), spread 40 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 75 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.22 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.3 (at least 3.5))
- pass: detail_budget (detail at display size 2.0 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.0)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.3, p95 3.0, off-palette 0.1% (top: #AA5533 (0.0%), #BB6633 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 85 against the world reference (outliers: edge))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.04 of the parent level (drift compounds along a chain))
