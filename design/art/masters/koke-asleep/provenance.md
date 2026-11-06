# char__koke-asleep

- **Approved:** 2026-11-06T01:42:08+00:00 from batch `batch-39-koke-production`, job `koke-asleep`, take t3
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud-retained-salvage;
  generated 2026-11-05T23:52:08+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `char-guard` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp q95), kept so the look can be re-locked; `koke-asleep.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Retained-source re-post only. Take 3 is the sole hard-eligible candidate: takes 1, 2 and 4 still fail the unchanged palette-drift check. Official ground fitting applies scale 1.0 and vertical dy -75 px to take 3, putting the feet on the 88 percent baseline without source edits or local translation. Full locked review shows the gentle living moss heap, closed soft eyes, calm smile, crown leaves, small clover and tucked paws with one curled forward, clear headroom and no flowers, text, head curl, island or painted ground shadow. Character-guard preserves original colours; Harmony and light warnings remain advisory. All four original generation ordinals, prompt/reference fingerprints, source bytes and account provenance retained; zero new generation.

## References

- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Pofu, the hamster: match his art style, lighting, level of fluff and finish exactly (do not draw him).
- `design/art/masters/mochi-v2/mochi-v2.webp`: Mochi, the bunny: the same family of soft plush characters (do not draw her).
- `design/reference/palette-card-character.png`: The character palette card.

## Prompt (fingerprint dfd55ae43a25fb26)

```text
REFERENCES (attached, in this order):
1. Pofu, the hamster: match his art style, lighting, level of fluff and finish exactly (do not draw him).
2. Mochi, the bunny: the same family of soft plush characters (do not draw her).
3. The character palette card.

Draw Koke, a huge, gentle, round moss creature fast asleep, as a game
sprite on a transparent background, in exactly the same art style,
lighting and level of softness as the attached hamster and bunny.
It lies curled up in a plump rounded heap like a small green hill
with a face, seen from the front, slightly from above. Its fur is
thick living moss in sage and fresh green with a few lighter
patches, soft and fluffy, with a small leafy sprout of two or three
leaves on its crown and a few tiny clover leaves in its fur. A round
sleepy face low at the front: a small blunt snout, a tiny dark nose,
two eyes gently closed as soft curved lids with a few soft lashes, a
calm small smile, a blush on each cheek, two tiny round ears. Four
stubby legs tucked under its belly, with one rounded front paw
curled out in front of its chin. It fills about 80 percent of the
canvas width, lies low (its top about 55 percent of the canvas
height), and rests on an invisible ground line at 88 percent of the
height, centered, with empty space above it. No flowers, no ground,
no shadow, no island.

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

AVOID: teeth, claws, open eyes, a frown, a whale or bear shape, glowing parts, flowers, a ground, a shadow, text, letters, zzz, outlines

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 56 (R1 51))
- warn: light_values (day/subject: L p2 52 (at most 22), p98 94 (at least 90), spread 43 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 78 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.14 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 4.4 (at least 3.5))
- pass: detail_budget (detail at display size 5.8 (R1 5.3))
- warn: palette_drift (mean dE 3.6, p95 12.7, off-palette 5.9% (top: #AABB44 (0.6%), #CCCC55 (0.5%)))
- pass: ground_line (feet at 88.0% of the height (contract 88%))
- warn: no_ground_shadow (a ground shadow seems painted in)
- warn: harmony (harmony score 67 against the char reference (outliers: C_p95, L_p2, detail))

Retained-source QA re-post, no new generation. Original run batch-39-koke-production, take 3. Original generation prompt/reference fingerprints, callback and source bytes are preserved in salvage-source.json; current fingerprint describes canonical evaluation context only.
