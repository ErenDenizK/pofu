# world__cloud-curtain-3

- **Approved:** 2026-11-06T00:41:15+00:00 from batch `batch-35-experience`, job `cloud-curtain-3`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:50:55+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `cloud-curtain-3.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both original, full locked and official half-delivered takes are manually eligible and have no hard QA failures: a few long thin cream/peach cloud wisps across the upper and middle frame with ample genuine transparent gaps and side runoff, faint and airy, no sky, island, text or unrelated objects. No numerical cloud count is invented for the authored few. Take1 has the lowest eligible style-lock load0.2650. The official authored scale0.5 export creates768x512 from the saved1536x1024 lock; preserve exact master RGBA and delivery/preview proofs. No manual source edits, cleanup or threshold waiver. Own Harmony shard and real measure/check required; light warnings are advisory.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/masters/cloud-sea/cloud-sea.png`: The sea of clouds below every island: paint the clouds like this, in the same finish.

## Prompt (fingerprint 0ef4bb9b0af53443)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The sea of clouds below every island: paint the clouds like this, in the same finish.

The back layer of a loading curtain, on a transparent background: a few long, thin, slightly curved cloud
wisps in soft cream and pale peach, stretched horizontally across the upper and middle of the image,
faint and airy, with plenty of transparent space between them. They run off the canvas at both sides.

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

AVOID: a sky behind the clouds, a background, an island, text, outlines, hard edges, black or grey clouds, dark shadows, rain, characters, a border

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 10 (R1 51))
- warn: light_values (day/subject: L p2 87 (at most 22), p98 94 (at least 90), spread 7 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 91 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.82 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 0.7 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 2.2, off-palette 0.0%)
- warn: harmony (harmony score 39 against the world reference (outliers: C_p95, L_p2, edge))
