# prop__flow-wheel

- **Approved:** 2026-11-10T16:50:27+00:00 from batch `batch-64-flow-pieces`, job `flow-wheel`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-10T16:45:24+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `flow-wheel.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1024 take; the master and raw are delivered at x0.25 (256x256, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both candidates show eight rounded honey-wood paddles, centered hub and circular rim, matte finish and small rim moss. Exact rotational pixel invariance is not certified; approximate84percent width is advisory. Proper cream alpha composites are clean; bright raw RGB fragments are at alpha0. Auto-picked by QA; founder review pending.

## References

- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The props palette card (wood colours).

## Prompt (fingerprint c22e116f9a3f4ebf)

```text
REFERENCES (attached, in this order):
1. A finished prop of the game: match its soft airbrushed finish, matte materials and warm light (do not draw the stall).
2. The props palette card (wood colours).

A mill water wheel seen straight from above, as a game sprite on a transparent background: a round wooden wheel, perfectly circular and centred, about 84 percent of the canvas wide, with a small round hub and a short axle, eight identical flat paddles at equal angles (every 45 degrees), a plain wooden rim joining their tips, honey-stained matte wood (no grain) with a slightly darker cocoa hub and a tiny touch of green moss on the rim. Soft, rounded, chunky shapes.

STYLE: soft painterly 2D illustration from the same picture book as the
attached hamster: the same gentle airbrushed shading, the same light,
high-key values and the same milky pastel colors. Simple, rounded, chunky
shapes with few parts; fewer, larger shapes, because this is seen small on
a phone. Every material is painted matte, as a soft form with broad,
smooth value changes: wood without grain, metal without hammering or
reflections, glass as a soft tinted shape, cloth without weave. At most
one small, soft highlight per object; no glints, no shine. Colors are
muted and lifted toward cream; the darkest shadow is a warm mid-brown,
never near black. Warm diffused key light from the upper left, a faint
warm rim light along the right edge, soft ambient shadow only where forms
touch. Clean, calm, uncluttered. No outlines, no hard edges. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.

AVOID: text, letters, symbols, an outline, a ground shadow, a background, glints, water, spokes that differ from each other, an off-centre hub, a perspective or three-quarter view, a 3D render look

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 41 (R1 51))
- warn: light_values (day/subject: L p2 43 (at most 22), p98 82 (at least 90), spread 38 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 72 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.25 (at most 0.20; no true dark means a wash))
- warn: light_contrast (day/subject: p75 local contrast 1.5 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.8 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.8, off-palette 0.0%)
- warn: harmony (harmony score 60 against the world reference (outliers: C_p95, L_p98, edge))
