# Why the game reads pale ("soluk"): a measured diagnosis

Founder, 2026-11-08: in-game assets still look pale; the look-lab sheet
(`look-lab/06-best.jpg`) does not. Question: was producing assets as pastel,
soft, isolated sprites the wrong decision? This note measures it. It builds on
`reference-look.md` (§3), `look-lab.md` and `concept-match.md` and does not
repeat them. Numbers: `tools/plate/pale.py` (run steps in
`tools/plate/README.md`).

## 1. Method

- **Pictures.** References: I1 summer t2 (day), Revontuli stuck t1 and healed
  t2 (night). Game: `origin/screenshots/feat-look-pipeline-v2` (2026-11-07):
  `concept-day-home`, `caglayan-stage-0/4`, `caglayan-night-4`. Raw art:
  `World.xcassets` (windmill-5, garden-5, tea-stall-5, island band 0, Pofu,
  Mochi, the Çağlayan plates).
- **Phone scale.** The CI frame is 460 px for 402 pt. References are resized
  so their island is as wide as the game's island in the frame they are
  compared with; sprites at their drawn size.
- **Regions.** Sky, props, lawn (snow top at Revontuli), earth face (ice body),
  characters, cloud sea; boxes set by eye on a 10 % grid (`pale.py BOXES`).
- **Metrics.** L*, C* (mean and p95), hue, local contrast (`loc`, RMS of L*
  minus its 2 px blur), fine detail (0.7 px), accents (share C* > 50), darks
  (share L* < 45), Lp2 (2nd percentile L*, the black point).
- **The key test (H3).** Çağlayan's plate is registered into the CI frame by
  template matching (scale 0.606, at 9, 316). The same pixels are then
  compared raw and on screen, and a per-channel fit `screen = gain · raw + lift`
  says what the runtime did to them.

## 2. Results

**Whole frame.** The lead's reading is right: the home pose is not globally
paler than the reference (C* 18.5 against 22.8, L* 83.2 against 83.1). The
frames that look pale are the island stops: Çağlayan by day is C* **9.9**
(p95 28.9), and by night C* **8.8** (p95 17.5). The Revontuli references are
C* 20.1 and 17.6 at night.

**Per region, day, I1 against the home frame** (L*/C*, p95, hue):

| Region | Reference | Game | Read |
|---|---|---|---|
| Sky | 81.5 / 23.9, hue 261 | 85.9 / **11.7**, hue 211 | half the chroma, cyan instead of blue |
| Props | 76.3 / 37.6, p95 64.6, accents **24.9 %**, Lp2 47 | 82.0 / 31.8, p95 55.5, accents **9.4 %**, Lp2 66 | fewer accents, no darks, half the local contrast (2.2 against 4.2) |
| Lawn | 75.1 / 41.6, hue 109 | 69.6 / 40.0, hue 107 | matched |
| Earth | 84.2 / 27.7, hue 67 | 80.8 / 32.5, hue 76 | close |
| Cloud sea | 88.4 / 7.3, hue 268 | 89.5 / **2.8** | grey-white, no lilac shade |

**H3, the same pixels raw and on screen (Çağlayan):**

| | Raw plate | On screen |
|---|---|---|
| Stage 4, day, island | L* 69.9, C* 23.6, loc 5.4, darks 5.5 %, Lp2 39.8 | L* 76.2, C* 23.7, loc **3.6**, darks **0 %**, Lp2 **53.4** |
| Fit, top 70 % of the island | | gain 0.6 to 0.7, lift 0.26 to 0.38 per channel |
| Fit, bottom 30 % | | gain 0.2 to 0.37, lift 0.5 to 0.73 |
| Stage 4, night, island | C* 23.6 | C* **5.7** (−76 %), loc 2.9, Lp2 52 |
| The day grade alone (`lookdev.apply_grade`) | | gain 1.09, lift −0.05: it expands, it is not the veil |

So something composited after the grade lays a cream veil of about 35 % over
the whole island at its stop, and 50 to 75 % over its foot (the front fog
card and the cloud sea). The grade's saturation 1.32 hides it in the mean
chroma, but the black point rises 14 L* and every dark disappears. At night
the night grade (blue lift 0.45, saturation 0.88) plus the same veil leaves
a quarter of the plate's chroma. Which layer it is (front fog card, screen
haze, cloud sea, the far-isle stack the island is drawn in) is a one-hour
toggle test in `CaglayanScreenshotTests`; the numbers stand either way.

**Framing.** At its stop Çağlayan's island covers **17 %** of the portrait
frame; in its own take it covers 55 %. The other 83 % is the sky (C* 11.7)
and the cloud sea (C* 2.8). A portrait phone cannot show a landscape island
whole at more than about 28 % of the frame.

**Raw sprites against the same object in the reference** (C*, p95):
windmill 22.8, **31.5** against 24.1, **48.6**; tea stall 31.9, **40.0**
against the stall 33.8, **51.3**; garden-5 31.8, 49.9 (accents 4.3 %) against
the sunflower field 43.2, 67.7 (accents **36.5 %**). Raw lightness is right
(71 to 76 against 73 to 83). Island band 0 (the lawn lip): p95 42.4 against
the reference lawn's 54.8; the lock's green ceiling is 48.

**H2, delivery at phone scale** (the healed take's props and characters,
island 1157 phone px wide): full resolution loc 2.24, fine 0.73; delivered at
0.5 then upscaled 1.59x: 1.93, 0.52; plus the lock's `detail.keep 0.5`:
**1.68, 0.45** (−25 % and −38 %). Chroma does not change (20.2 to 19.7).

**H6, contact** (L* under the feet minus beside them): game Pofu −2.5, Mochi
−0.3; reference duo −3.4 (stuck) and +2.5 (healed, painted bounce on lit
snow). The metric does not separate them; the difference is visible
(painted characters sit in the snow, sprites sit on it) but not measured.

## 3. Ranking

| # | Cause | Evidence | Verdict |
|---|---|---|---|
| 1 | **H3 runtime layers** over the island at its stop | gain 0.64, lift 0.32; darks 5.5 % to 0; Lp2 +14; loc −33 %; night chroma −76 % | **main cause**, code |
| 2 | **Framing and backdrop** (new, not in the brief) | island 17 % of the frame; sky C* 11.7 against 23.9; sea C* 2.8 against 7.3; frame C* 9.9 against 22.8 | **second**, code and camera |
| 3 | **H1 + H4 accents** | same object p95 −25 to −35 %; accent share 9.4 % against 24.9 %; one pot against a field | **third**, prompts and content |
| 4 | H2 delivery 0.5 and `detail.keep` | fine detail −38 %, loc −25 %, chroma 0 | causes "soft", not "pale" |
| 5 | H6 isolated light | not separated by the metric | real for "pasted on", not for "pale" |
| 6 | H5 lawn and earth hue | lawn hue 107 against 109, C* 40 against 42 | **rejected** |

## 4. What was wrong and what was right

Wrong:

- **"Keep the files neutral; the runtime shapes the look"** (lock-light's
  premise). The runtime then stacked light layers over the island, and the
  painted darks never reach the screen. Painted pixels must be the final
  pixels on the island; code may only add light and life on top.
- **"Colors muted and lifted toward cream; the darkest shadow a warm
  mid-brown"** (`blocks/prop-style-v2.txt`): this is what takes a third off
  every object's peak chroma. "Milky pastel" was the wrong word for the
  references, which are high-key but with saturated accents and real darks.
- **Delivering at 0.5 with `detail.keep 0.5`**: the phone draws Çağlayan's
  island 1157 px wide from 728 px of art.
- **The island stop camera**: a whole island at 17 % of a portrait frame,
  under a pale sky and a grey sea.

Right, keep:

- The **high-key palette**: reference L* 83, the game's home pose L* 83.
- The lawn and earth hues, the characters' chroma (sprite Pofu C* 21.9 against
  the painted Pofu's 17), the LIGHT block that gave Çağlayan's plate real
  darks (5.5 %), and painting a stage chain as edits of one picture
  (batch 43, batch 68).

Isolated sprite painting is not the main cause of "pale"; it costs contact
and bounce, which read as "pasted on". The fix order: remove the veil at
island stops, frame islands larger with a saturated sky and a lilac sea, and
paint islands as final pixels with accents (ADR-0022).
