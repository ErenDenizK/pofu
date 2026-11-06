# sheet__shield-pofu-door

- **Approved:** 2026-11-06T00:49:11+00:00 from batch `batch-35-experience`, job `shield-pofu-door`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T23:55:28+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `shield-pofu-door.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked candidates are independently visually eligible: exactly three complete separate scenes with the same Pofu and honey round door/window in a low cream wall segment. Calm has gentle open eyes; proud has lifted chin/chest and a paw on the frame; sleepy droops, yawns and leans with heavy lids. Signature curl is retained only on Pofu, cheeks are natural and unpuffed, and no island, lettering, sparkle, extra limbs or background is painted. Take2 has the lowest eligible lock load0.0100 versus0.0138. The canonical sheet char-guard preserves the fur finish without a prop-lock override; no manual pixel edits. Exact-RGBA lossless preflight verifies its553930-byte WebP can preserve the full1536x1024 master under614400 without resizing. Real Harmony measure/check and own shard accompany the master; advisory light warnings remain for founder review.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Pofu, the hamster: his exact look, fur, colors, eyes and signature curl.
- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home island: copy ONLY the round door (its shape, wood, color and size relative to the plate) and the soft painting. Do not draw the island.

## Prompt (fingerprint 2c7fcf6eee9b3cb4)

```text
REFERENCES (attached, in this order):
1. Pofu, the hamster: his exact look, fur, colors, eyes and signature curl.
2. The home island: copy ONLY the round door (its shape, wood, color and size relative to the plate) and the soft painting. Do not draw the island.

A sheet of three small scenes in one row, each showing Pofu the hamster, in his exact attached look, standing
at his round wooden door (the attached island's round door: a round honey-wood door with a small round
window, set in a low rounded cream wall segment), the same door and the same place in all three, evenly
spaced with wide empty space between them: (1) calm: standing relaxed beside the door, a soft content
smile, eyes open and gentle; (2) proud: chest out, chin up, eyes bright, a small proud smile, one paw
resting on the door frame; (3) sleepy: eyes half closed, head drooping, a tiny yawn, leaning gently on
the door frame. Pofu's cheeks are never puffed in any of them. On a plain transparent background, each
scene complete, none touching another.

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

AVOID: puffed cheeks, a floor, a ground shadow, cast shadows, text, speech bubbles, hearts, sparkles, a curl on any head except Pofu's, extra limbs, a background, a border

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 45 (R1 51))
- warn: light_values (day/subject: L p2 48 (at most 22), p98 94 (at least 90), spread 46 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 83 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.22 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.2 (at least 3.5))
- warn: detail_budget (detail at display size 6.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.0)
- pass: palette_drift (mean dE 1.8, p95 5.6, off-palette 0.9% (top: #EE7766 (0.1%), #DD7755 (0.1%)))
