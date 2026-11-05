# station__pier-3

- **Approved:** 2026-11-05T06:09:45+00:00 from batch `batch-21-harbor-ladders`, job `pier-3`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T06:03:40+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `pier-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. One retry pair only. Takes1/4 fail hard palette_drift. Initial take2 is manually excluded because station_anchor reports width842 versus parent width bar722: the added ferry expands the footprint too far despite high edit stability. Retry take3 passes hard QA and the parent station-anchor check without a width/ground warning; no edit guide fitting or rescaling is used to manufacture that result. Visual review confirms a small one-funnel blue/cream ferry moored by a short rope beside the outer half, about half the pier length, a clean lower waterline, unchanged planks/posts/coral rope and unlit lantern; no water, wake or smoke. Original pier scale is retained, edit stability0.9830, chroma1.0293, lock load1.0873 and Harmony81.8. Light/palette warnings are advisory. Take3 is the only semantically eligible hard-passing candidate; founder review pending.

## References

- `design/art/stations/pier-2/pier-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint bc4aee294462591b)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Moor a small toy-like steam ferry beside the pier's outer half: a plump rounded sea-blue hull with a cream stripe, a low cream cabin with round windows, one rounded coral funnel with a cream band, about half the pier's length, its waterline a flat clean edge, tied with a short rope to a post. No water, no wake, no smoke.

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
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- warn: light_values (day/subject: L p2 45 (at most 22), p98 92 (at least 90), spread 47 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 76 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.19 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.9 (at least 3.5))
- pass: detail_budget (detail at display size 3.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 2.3, p95 11.3, off-palette 4.6% (top: #558899 (1.3%), #557788 (0.8%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 82 against the world reference (outliers: detail, edge))
- pass: edit_stability (98% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
