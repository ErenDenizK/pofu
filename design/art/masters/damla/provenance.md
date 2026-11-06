# char__damla

- **Approved:** 2026-11-06T07:10:11+00:00 from batch `batch-43-caglayan-production`, job `damla`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-06T06:47:09+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `damla.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both source and canonical locked initial candidates show the intended soft cocoa and cream otter, one empty tulip glass held by both front paws at chest, curled ground tail, no forehead curl, teeth, claws, floor, cast shadow, water or text. Full alpha-composited and 28px review is eligible. Canonical fit.ground scale1.0 dy-56/-48 places feet at88percent. No lock_load is emitted by char-guard, so higher Harmony87.4 versus87.3 selects take1. Exact native lossless WebP473570bytes preserves canonical RGBA under614400 without resizing or pixel cleanup. Hard QA passes; advisory light warnings remain for founder review. No header force exception used. The first successful Damla commit links both existing planned family assets; all unrelated character fields remain unchanged.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Pofu, the hamster: match his art style, lighting, level of fluff and finish exactly (do not draw him).
- `design/art/masters/mochi-v2/mochi-v2.webp`: Mochi, the bunny: the same family of soft plush characters, the same size on the canvas (do not draw her).
- `design/reference/palette-card-character.png`: The character palette card.

## Prompt (fingerprint 02883be7453bf938)

```text
REFERENCES (attached, in this order):
1. Pofu, the hamster: match his art style, lighting, level of fluff and finish exactly (do not draw him).
2. Mochi, the bunny: the same family of soft plush characters, the same size on the canvas (do not draw her).
3. The character palette card.

Draw Damla, a small, round, plush river otter, as a game sprite on a
transparent background, in exactly the same art style, lighting and
level of softness as the attached hamster and bunny. She stands on
her hind legs facing the viewer, three quarters to the left, her
long soft tail curled on the ground beside her. Warm cocoa-brown fur
with a cream face, chin and belly, a round head with tiny round
ears, big warm dark eyes with soft catchlights, a small dark nose,
short whiskers, a hopeful little smile, a blush on each cheek. In
both front paws, held at her chest, a small empty tulip-shaped tea
glass. She is about as tall as the attached bunny on the canvas,
centered, standing on an invisible ground line at 88 percent of the
height. No ground, no shadow, no water.

STYLE: soft painterly 2D digital illustration with the polish of a premium
storybook and a top-tier mobile app mascot. Gentle airbrushed shading, no
outlines, no hard edges. Fine, soft fur strands along the silhouette and a
velvety fur texture inside it. Warm diffused key light from the upper left,
a faint warm rim light along the right edge, soft ambient shadow only where
forms touch. Pastel warm palette of cream, golden peach and blush pink with
dark espresso-brown eyes. Clean, calm, uncluttered. No text, no letters,
no numbers, no logos, no watermark, no border, no frame, no sticker outline.

AVOID: outlines, cel shading, 3D plastic or vinyl render, anime sparkle
eyes with many highlights, extra limbs, extra toes or fingers, claws,
teeth, eyebrows, a long tail, lilac or gray fur, a ground shadow, a floor,
a cast shadow, a white sticker border, text, watermarks, signatures,
motion blur, film grain, paper texture, vignette.

AVOID: teeth, claws, a realistic otter, a fish, a frown, wet spiky fur, water splashes, a ground, a shadow, text, letters, outlines

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 40 (R1 51))
- pass: light_values (day/subject: L p2 20 (at most 22), p98 94 (at least 90), spread 75 (at least 60))
- pass: light_median (day/subject: median L 64 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.14 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 5.0 (at least 3.5))
- pass: detail_budget (detail at display size 6.1 (R1 5.3))
- warn: palette_drift (mean dE 3.0, p95 8.8, off-palette 1.5% (top: #773322 (0.2%), #662211 (0.1%)))
- pass: ground_line (feet at 88.0% of the height (contract 88%))
- warn: no_ground_shadow (a ground shadow seems painted in)
- pass: harmony (harmony score 87 against the char reference (outliers: detail))
