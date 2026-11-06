# station__lighthouse-1-lit

- **Approved:** 2026-11-06T01:24:45+00:00 from batch `batch-36-lit-ladder-pilot`, job `lighthouse-1-lit`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T23:16:26.824Z.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `lighthouse-1-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. All four full locked images and lamp-room crops retain the day geometry, cream posts, cap, railing, lower round window, door and base. Warm candle-amber fills only the lamp-room glass, with a soft rounded internal lamp impression; no beam, rays, exterior halo, night grade or blown white light. The warm lamp is visible against both light and dark at 28 px in full-canvas and fixed-parent-bounds diagnostics. Every outside-mask RGBA pixel exactly equals the day parent. All four are manually eligible; use unchanged official QA ranking.

## References

- `design/art/stations/lighthouse-1/lighthouse-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 5be4d915f2eaa8ef)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the lighthouse from inside: the lamp room under the coral cap
(the row of dark glass panes between the cream posts) now glows warm
candle-amber, brightest in the middle of the room with a soft
rounded lamp shape suggested inside, painted as soft broad shapes.
Only the glass panes of the lamp room change: the posts between
them, the cap, the balcony and railing, the stripes, the round
window, the door and the base keep their exact day colors (the app
adds the glow around the lamp, the beam and the night grade).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: a beam, light rays, a glow outside the glass, a halo, light on other parts, a night sky, darkening anything, blown yellow-white highlights, text.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 52 (R1 51))
- warn: light_values (day/subject: L p2 53 (at most 22), p98 91 (at least 90), spread 39 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 77 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.25 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 3.4 (at least 3.5))
- pass: detail_budget (detail at display size 1.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.9)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.4, p95 7.5, off-palette 0.2% (top: #CC7733 (0.1%), #BB6633 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 88 against the world reference (outliers: edge))
- pass: emit_leak (100% of the parent unchanged outside the emit region (masked out of the master))

Retained-source QA re-post, no new generation. Original run batch-36-lit-ladder-pilot, take 3. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
