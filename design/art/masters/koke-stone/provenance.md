# prop__koke-stone

- **Approved:** 2026-11-06T10:32:13+00:00 from batch `batch-60-earth-face`, job `koke-stone`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T10:17:20+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `koke-stone.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both initial takes pass all hard QA and literal manual review; take1 has the lowest style-lock load0.5303 versus0.5405. One upright rounded grey-sage stone with moss cap and side patches, exactly three faint horizontal carved grooves and small grass base; no letters,runes,face or signpost. Matte soft moss and stone match the listed Koke plate. Tiny extra bells and fern are disclosed, with no exclusive only-parts clause; no imported decor or raw pixel-footprint gate. Proper cream/dark alpha composites show no visible fringe despite near-transparent native-view edge colors. Day values/haze/contrast and Harmony69.5 warn only, never waived hard failures. Official locked1024square PNG443566bytes fits the614400cap unchanged; no scaling or lossy master. All immutable originals/callbacks/QA/locked/source hashes preserved. Queue stale count2 versus authored3 realjobs resolved as trackall includes this independent stone. No source/manifest/palette/threshold changes.

## References

- `design/art/masters/koke-island-0/koke-island-0.png`: Koke's island plate: match its painting, light, boulders and moss exactly; the stone stands on this lawn.

## Prompt (fingerprint 474551559e805047)

```text
REFERENCES (attached, in this order):
1. Koke's island plate: match its painting, light, boulders and moss exactly; the stone stands on this lawn.

A small upright standing stone for a cozy mobile game, as a game
sprite on a transparent background: a soft rounded grey-sage stone
a little taller than wide, with a cap of fresh moss on its top and a
few moss patches on its sides, three faint carved horizontal lines
on its face like an old message worn smooth, softly lit from the
upper left with a cool shade on the right, standing on a tiny tuft
of grass, in exactly the painting style of the attached island.

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

AVOID: letters, runes, text, a face, a gravestone look, a sign post, a shadow on the ground, a background

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 27 (R1 51))
- warn: light_values (day/subject: L p2 54 (at most 22), p98 91 (at least 90), spread 37 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 71 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.42 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.9 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.3 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.2, p95 2.8, off-palette 0.0%)
- warn: harmony (harmony score 70 against the world reference (outliers: C_p95, edge))
