# Look lab: which techniques bring the game's frames to the concepts

Founder, 2026-11-07: copy the whole look of the best references (light, shadow, colour, one
picture), try every technique, aim for one to one. This note is the experiments: each technique
run offline on the game's own frames and art, measured against the references, judged on the
sheet. The theory is in `reference-look.md` (parallel branch); the causes in `concept-match.md`
(depth of field, the night grade, overcast-as-day, the dark earth band, framing) are not repeated.
Scripts: `tools/looklab/` (README there). Sheets: `look-lab/01` to `06`.

## 1. Material

- **References.** Day: I1 `x-season-summer` t2. Golden: `x-season-summer-evening` t2. Rain:
  `x-season-rain` t1. Night: the mean of `x-gezgin-f2-night` t1, `x-revontuli-stuck` t1 and I1
  `x-season-snow-night` t1 (a calmer night than the Tam Çiçek night key: indigo sky L* 35 to 39,
  the island kept light, L* 70 to 80, lilac-tinted, sea L* 74 to 84).
- **Game frames.** The Home screenshots of `screenshots/feat-concept-match` (`concept-<state>-home`,
  the latest grade). For techniques that need layers (AO, relight, bloom) a **lab scene**:
  `tools/looklab/home-lab.json`, the game's own plate (`island-main-l-v3`), stations, lamp, Pofu
  and Mochi in the references' landscape camera, rendered by lookdev under the game's light as
  "game light now" and through the lab passes as "after".

## 2. Numbers

| Number | Meaning |
|---|---|
| **dE** | mean CIEDE2000 between the mean colour of five matched regions (sky, back row, focal row, earth face, cloud sea; `regions.json`). Different pictures can only be compared region to region. Below ~5 a viewer reads the same palette. |
| **hist** | Wasserstein distance of the island's L* histograms, in L* units (value structure). |
| **b/f** | local contrast of the back row over the front row (references 0.73 to 1.22). |

## 3. Experiment 1: fitted colour grade (sheet 01, Home screenshots)

| State | before | Reinhard | sliced-OT LUT | region LUT | per-material LUT |
|---|---|---|---|---|---|
| Day | 9.3 / 9.4 | 5.9 / 2.6 | **5.1 / 1.5** | 4.7 / 1.3 | 6.2 / 4.1 |
| Golden | 15.0 / 6.0 | 10.8 / 2.9 | **8.3 / 2.7** | 8.1 / 1.9 | 10.1 / 4.8 |
| Night | 23.9 / 24.8 | 9.7 / 10.7 | **7.5 / 11.9** | 7.7 / 12.1 | 17.4 / 18.2 |
| Rain | 12.4 / 13.3 | 7.7 / 3.4 | **6.6 / 2.1** | 8.3 / 4.9 | 6.8 / 2.2 |

(dE / hist.) The LUT is 17³, fitted from sliced optimal transport in CIELAB (24 rotations), then
smoothed with an identity prior so neighbouring colours cannot tear; it is one texture lookup.

- **Verdict: on a flattened frame a single global OT-LUT is the best grade**: it halves the gap
  in every state (night 23.9 → 7.5). Region LUTs gain little and, with masks from monocular
  depth, leave seams beside the island; per-material transfer needs exact masks and fails on a
  flattened frame (the earth mask catches the doors and the night goes wrong).
- **What a grade cannot reach** (visible in every column): the earth band's black doors and
  its dark strata (the art, `concept-match.md` cause 4), the back row's softness (b/f moves only
  because a LUT stretches tones, not because detail returns), and the density of the
  references' lawn (flowers, stones). The night LUT also lifts Pofu toward white-yellow: a
  global grade cannot keep characters apart from the ground.

## 4. Experiment 2: AO and contact shadows (sheet 02, lab scene)

- **Layered depth** (what the game knows: sky far, the lawn a plane tilted toward the camera,
  the earth face a rounded wall, each sprite at its foot's depth plus a dome from its alpha):
  screen-space AO on **height above the ground** (raw depth AO greys the whole tilted lawn), only
  across layers (a sprite never darkens itself), and a short depth-buffer ray march toward the
  key for contact shadows. Result: a soft, cool ring where every prop and character meets the
  lawn, like the references' painted contact; dE 4.7 (raw) → 5.5 (it darkens a little).
- **Monocular depth** (Depth Anything V2 small, ONNX on CPU, ~1 s): good silhouettes and an
  excellent island/sky/sea mask, but its AO is noise on the clouds and the plate rim (dE 7.8).
- **Verdict: layered depth wins; monocular depth is for masks only.** The game's current
  projected shadow plus foot pad grounds harder than the references; AO + contact is closer to
  them, but weak alone: use both, the pad lighter.

## 5. Experiment 3: relight with a light rig (sheet 03)

Day, golden, rain: a **ratio relight**: the art times rig(normal) / day-rig(flat normal), so the
paint's own light stays and the rig adds a warm key, a cool sky fill, a cloud-sea bounce on the
underside, a rim, and for golden and rain the light's colour and level. Normals: per layer from
the layered depth; the plate's from its known shape (lawn up, earth face rounding down).
Night: nightlab's unlight, a moon and sky hemisphere, and **point lights at the lamp, the tea
stall and the house door** (inverse square in screen + depth, wrap 0.8, a 1.35 character lift),
emissive lamp glass.

| | game light now | nightlab | relit |
|---|---|---|---|
| Day dE / hist | 6.3 / 2.6 | – | **4.6 / 3.5** |
| Golden | 15.2 / 4.9 | – | **12.6 / 5.6** |
| Night | 28.1 / 22.2 | 30.4 / 26.6 | **17.3 / 14.3** |

- **Verdict: the night relight is the biggest single step.** The lamp lights Pofu, Mochi and a
  pool of lawn from where it stands, the founder's ask; nightlab's model is darker and browner
  (its earth reads mud). The day ratio rig is subtle (a lighter lip, a bounce on the underside):
  right, because the art is already painted in daylight. The golden rig warms but cannot make
  the references' pink-lilac sky; that is the grade's job.

## 6. Experiment 4: haze and bloom (sheet 04)

- **Haze toward the back.** The references' island is not hazed: by depth quartile their island
  stays as crisp at the back as at the front (contrast back/front 0.92); the paleness is the sky
  and the cloud sea. A depth haze on our island moves chroma 32.3 → 31.1 at the back and nothing
  else. **Verdict: no haze on the island** (it would repeat the depth-of-field mistake); haze only
  the backdrop, far isles and cloud sea.
- **Bloom.** Measured as the radius where a lantern's excess luminance halves: reference
  Gezgin lantern **2.0 % of the frame width** (10 % at 6.0 %); game now 1.0 % (the lamp is unlit
  in lookdev, the game adds a glow sprite); relit glass 2.5 %; with three-octave bloom and warm
  halation 3.5 %. **Verdict: emissive glass plus a small halo matches;** bloom should be about
  half as wide as the lab's (sigma ≈ 1 % of the width), and a pre-blurred glow sprite does it.

## 7. Experiment 5: harmonise by repaint (design; sheet 05)

The one gap no pass closes is **density and finish**: the references' lawn is a carpet of
flowers and stones, every prop sits in painted contact, one brush covers all. An image-model
edit can repaint the composed frame as one picture; the lab cannot call it, so it prepares the job.

- **Inputs** (`look-lab/repaint/`): `frame-day.webp` (the best-pipeline day frame, 1536 × 1024),
  `layout.png` (one flat colour per layer: sky, sea, lawn, earth, each sprite), and the I1
  summer take by path. `repaint-job-day.yaml` is a ready manifest job (attachments in order,
  prompt, KEEP and AVOID: nothing moves, faces kept, only light and finish change); other states
  with `repaint.py --state`.
- **Cut back** (`repaint.cut`): each sprite = the repaint inside the sprite's **own** alpha (the
  game's silhouettes, rigs and animation stay); the plate = the repaint outside the sprites, the
  holes filled from a **bare-island take** (job A of `concept-match.md` §6) or, without it, from
  the surrounding plate (sheet: visible patches, so job A is needed); a **contact-shadow layer**
  = min(1, B / A) in a ring around each foot, kept separate so a moving character does not leave
  its shadow baked in the lawn. Round trip on an unchanged frame: dE 0.04.
- Pilot one day frame; if it keeps the layout (overlay the mask), run golden, night and rain as
  edits of the day result, and use them as targets for the per-material LUTs.

## 8. Best combined pipeline (sheet 06, the comparison sheet)

AO + contact (layered) → rig relight → **per-material grade baked into one 17³ LUT per layer
group** (backdrop, plate, sprites; Reinhard per material: sky, sea, lawn, earth toward the same
material in the references, sprites half way) → haze on the backdrop only → bloom on emissives.

| State | Home now | lab scene, game light now | **best** |
|---|---|---|---|
| Day | 9.3 / 9.4 | 6.3 / 2.6 | **3.2 / 1.9** |
| Golden | 15.0 / 6.0 | 15.2 / 4.9 | **8.4 / 2.2** |
| Night | 23.9 / 24.8 | 28.1 / 22.2 | **9.6 / 5.8** |
| Rain | 12.4 / 13.3 | – | **4.8 / 1.3** |

- With layers, sliced OT washed the island out (the lawn was asked to become the reference's
  mix of lawn, sunflowers and stones); per material it cannot, so it wins here, while the
  global OT-LUT wins on flattened frames (section 3).
- **How close:** day reads as the reference's palette (dE 3.2: sky 2.4, sea 1.7, earth 5.1).
  Night is the references' storybook night: indigo sky, the island light and pastel, the lamp
  warm on Pofu (dE 9.6, sky 3.5). Golden is closest in value but its sky is lilac where the
  reference is peach-pink with clouds (sky dE 16.8; a sky-art gap, not a grade gap). Rain lacks
  streaks and wet glints (overlays the game already has).
- **What still separates it from one to one:** content density and painted finish (section 7),
  sky art (clouds, stars, moon in the backdrop), and the Home framing (`concept-match.md` 5).

## 9. Runtime cost on iPhone, and what bakes

| Part | Runtime | Bake offline |
|---|---|---|
| Grade | one 3D-texture lookup in the existing grade shader (two to blend states): well under 0.1 ms | the LUTs, per colour-script cell, fitted by `grade.py` / `best.py` |
| AO + contact | none | per static prop at its slot, a multiply layer under it; characters keep a soft pad plus a baked contact gradient |
| Relight, day/golden/rain | none (or one normal-mapped pass) | the ratio rig per cell into each layer's form-shading map |
| Relight, night | yes: 3 to 5 point lights through baked normal maps, one fragment pass per lit layer (~0.3 to 0.6 ms at full resolution, quarter resolution for the plate) | the normal maps (`normals.py`), the plate's analytic normals |
| Haze | a per-layer tint by its depth: free | – |
| Bloom | none | pre-blurred additive glow sprites (sigma ≈ 1 % of width) on emissives; the glow sprites exist |
| Monocular depth | never | only to mask references |

So the runtime adds one LUT lookup and the night light pass; everything else bakes.

## 10. Recommendations (for the lead)

1. Replace the hand-tuned grade with fitted LUTs per cell (global OT on frames now; per material
   once layers are graded separately). Cheapest, largest step: night 23.9 → 7.5.
2. Build the night as light from sources (relight from baked normals), not a grade; Q-10 and
   the night ADR (V4) decide how bright (the references say storybook-bright).
3. Bake AO + contact per prop; lighten the foot pad. No haze on the island.
4. Queue the repaint pilot (`look-lab/repaint/repaint-job-day.yaml`) with a bare-island job A.
