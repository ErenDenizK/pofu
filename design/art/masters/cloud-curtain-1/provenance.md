# world__cloud-curtain-1

- **Approved:** 2026-11-06T00:31:52+00:00 from batch `batch-35-experience`, job `cloud-curtain-1`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:47:06+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `cloud-curtain-1.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1536x1024 take; the master and raw are delivered at x0.5 (768x512, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass hard QA and are visually eligible in original, full locked and official half-delivered alpha composites. The front bank occupies the lower half, with rounded towers toward the middle, an otherwise transparent upper half and runoff at both side edges. Take1 has the lowest eligible lock load0.3608. Its tiny rounded tower reaches8px above the exact midpoint (0.0757percent upper-half alpha coverage), compatible with towers toward the middle; no invented hard midpoint cutoff is applied. No sky, island, lettering, frame or unrelated object. Official authored scale0.5 alone produces768x512 from the saved1536x1024 full lock, with exact master RGBA and delivery metadata proof. No manual source or master edits. Light warnings retained; own canonical Harmony shard required.

## References

- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
- `design/art/masters/cloud-sea/cloud-sea.png`: The sea of clouds below every island: paint the clouds like this, in the same finish.

## Prompt (fingerprint a3272d937b736c9d)

```text
REFERENCES (attached, in this order):
1. The approved tea stall: match its painting, finish, camera, scale and colors exactly (do not draw the stall).
2. The sea of clouds below every island: paint the clouds like this, in the same finish.

The front cloud bank of a loading curtain, on a transparent background: a wide band of plump, overlapping
cream-white clouds with soft pink-gold tops and lilac-grey undersides, filling the whole lower half of the
image and rising in a few rounded towers toward the middle, the upper half left empty and transparent. The
bank is wider than the image on both sides so it can slide apart. Chunky, soft, toy-like shapes.

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
- warn: light_values (day/subject: L p2 84 (at most 22), p98 95 (at least 90), spread 11 (at least 60) (warn-only until the founder has seen the light pilot))
- warn: light_median (day/subject: median L 90 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.80 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 0.5 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 0.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.4)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 2.0, p95 4.1, off-palette 0.0%)
- warn: harmony (harmony score 52 against the world reference (outliers: C_p95, L_p2))
