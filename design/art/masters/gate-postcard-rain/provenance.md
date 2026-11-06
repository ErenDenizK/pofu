# plate__gate-postcard-rain

- **Approved:** 2026-11-06T10:10:40+00:00 from batch `batch-50-gate-postcards`, job `gate-postcard-rain`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T09:19:02+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `gate-postcard-rain.png` is the locked master the app and later edits use.
- **Soft delivery:** QA and the pick ran on the full 1024x1536 take; the master and raw are delivered at x0.5 (512x768, Lanczos, lossless) to stay under the upload cap. Logical size = the original size.
- **Review note:** auto-picked by QA; founder review pending. Both original and official locked candidates show gentle visible rain, lilac-grey sky with brighter breaks, wet green lawn and silver/ripple glints on side stones/pond, with clear empty central standing ground, leading stepping stones, fence left/pond right, calm copy sky and quiet bottom area. No creature/character/text. Same-landmark family is retained without claiming pixel-identical registration; style/light warnings remain advisory.

## References

- `design/art/masters/island-main-l-v3/island-main-l-v3.webp`: The home island: its lawn, flowers, stones, round door and soft painting; this is a view standing on it.
- `design/art/stations/tea-stall-5/tea-stall-5.png`: A finished prop of the game: props in the scene are this scale and finish.
- `design/art/masters/cloud-sea/cloud-sea.png`: The sea of clouds beyond the edge of the lawn.

## Prompt (fingerprint fcf3ddbc2cbb2544)

```text
REFERENCES (attached, in this order):
1. The home island: its lawn, flowers, stones, round door and soft painting; this is a view standing on it.
2. A finished prop of the game: props in the scene are this scale and finish.
3. The sea of clouds beyond the edge of the lawn.

A portrait painting for a cozy mobile game: standing on a small
floating island's lawn, looking across it toward its edge and the
sea of clouds beyond, in a gentle light rain, a soft lilac-grey sky with brighter breaks, the lawn wet and deep green with silver glints on the stones. In the lower middle, at about two
thirds of the height, an empty soft patch of lawn with a few
stepping stones leading to it, clearly a place where a small
character could stand, with nothing on it. Around it, at the sides,
a few flowers, a round stone, a small pond edge at the right, a
wooden fence post at the left. The upper third is open sky, calm,
for words. The bottom fifth is quiet grass and stones in soft focus.
No characters, no animals, no creatures anywhere.

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

AVOID: any character, animal, hamster, bunny, bird, frog or creature, text, letters, a border, a phone frame, busy details in the centre

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Key light #FFF6EC from the upper left; fill #BFD6EE; rim #FFE9C9 along the edge facing away from the key. Shadows are tinted #A99BC4 (never grey or black) and fall toward the lower right; paint a contact shadow in that hue under every object that touches the ground or another form, firmest in the subject plane.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, opaque, full bleed, portrait 1024 x 1536.
```

## QA at approval

- pass: transparency (opaque, as this kind must be)
- pass: canvas (1024x1536)
- pass: chroma_ceiling (chroma p95 32 (R1 51))
- warn: light_values (day/subject: L p2 62 (at most 22), p98 94 (at least 90), spread 32 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 79 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.42 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- warn: light_contrast (day/subject: p75 local contrast 1.1 (at least 3.5) (warn-only until the founder has seen the light pilot))
- pass: detail_budget (detail at display size 1.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: palette_drift (mean dE 1.2, p95 3.1, off-palette 0.0%)
