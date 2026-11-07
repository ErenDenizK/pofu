# Pofu's Sound Identity

_Status: v1 proposal, 2026-11-02. Founder decision: **sound B**, Pofu's
tiny sounds on, ambience optional; music and effects may be made
mathematically from chords and progressions. Builds on the [design
language §11](../archive/design-language.md#11-haptics-and-sound) (plush foley, one
key, Pofu has no words, silence for failure) and the [interaction spec
§6.2](interaction-spec.md#62-sound-palette-optional-off-when-the-sounds-toggle-is-off)
(the interaction sound palette). The words are in
[pofu-voice.md](../brand/pofu-voice.md). The proof renderer is
[`tools/sound/render.py`](../../tools/sound/README.md); its output is in
`design/sound/proof/`._

## 0. The answer in one page

- **The fine line: a sound must be caused by you, shorter than the
  gesture, quieter than your music, and absent when you are not alone with
  your phone.** Four tests decide every sound (section 1.2): the hundredth
  time, the bus, the music, and 1 a.m.
- **The shield is silent, always.** That is a choice and also a fact:
  a `ShieldConfiguration` extension returns a configuration, not audio.
  Notifications stay silent (gate v2 §5.7). Sound lives in Hop!, the
  minute, and the island.
- **`AVAudioSession.Category.ambient`**: obeys the Silent switch, mixes
  under the user's music, never ducks it. Ambience does not start while
  other audio plays. Sad states (worried, unwell) and failures have no
  sound.
- **About 22 micro-sounds** (section 2). Physical and tonal ones are
  synthesized offline and shipped as tiny files; textures are foley; **the
  vocal ones (giggle, hmph, yawn, hum) come from a human performer pitched
  up**, because synthesized voices are where procedural audio sounds
  cheapest. No babble: Pofu has no words.
- **One key, many moods** (section 4): every island's mode contains D
  major pentatonic, so any Pofu sound fits any island. Ayçiçeği D Ionian,
  İskele D Mixolydian, Yıldız D Lydian, Kaplıca B Dorian, Kitap B Aeolian.
  Calm ×1.0 → ×2.0 opens the voicing and the filter; wellbeing changes only
  density, **never the harmony**: shame has no soundtrack.
- **iOS path: pre-rendered stems plus a tiny runtime composer on
  `AVAudioEngine`** (section 5). Visits last 90 seconds, so runtime
  generative synthesis buys nothing a 40-second stem cannot; the composer
  schedules sparse note samples so the melody never repeats. About 5 days
  of engineering, about 6 MB of audio, low risk, no dependencies.
- **The proof** (section 7): 9 sounds and 4 seamless 30-second island
  loops rendered from numbers and measured: every file ≤ −1 dBTP, loops at
  −20.0 LUFS, micro-sounds at −18 LUFS momentary, no clicks, no seams,
  under 1 MB each. Nobody has heard them yet.

## 1. The fine line

### 1.1 What makes a sound charming, and what makes it intrusive

| Charming | Intrusive |
|---|---|
| Caused by a touch you just made | Plays on its own (a timer, an idle nag) |
| Shorter than the gesture (under 400 ms) | Longer than the moment that caused it |
| Changes a little each time | The same sample, every time, forever |
| Under your music, in its key | Ducks your music, or clashes with it |
| Says the same thing as the haptic and the face | The only carrier of meaning |
| Rare for big moments | A fanfare for every small thing |
| Silent when you are sad | A sad trombone |

### 1.2 Four tests for every sound

1. **The hundredth time.** Play it a hundred times in a row. If it
   annoys by the tenth, it needs variation, rationing, or deletion.
2. **The bus.** Sound on, phone in hand, strangers around. Would you be
   embarrassed? Then it is too loud, too long, or too vocal.
3. **The music.** Spotify playing. Does Pofu sit inside the song or fight
   it? (One key and `ambient` are the answer; ambience never starts over
   other audio.)
4. **1 a.m.** Someone asleep next to you. Bedtime has no sound except the
   stargazing ritual's three quiet notes, and even those only with
   ambience on.

### 1.3 When sound plays

| Surface | Sound | Why |
|---|---|---|
| **Shield** | **Never** | The system draws it; an extension cannot play audio. It would also be the most public moment (the user is mid-reach, often in public). |
| Gate notification | None | Gate v2 §5.7: the phone is already in his hand. |
| Live Activity, widgets | None | Glances answer, never ask (A18). |
| **Hop!** landing | Pofu's sniff (curious), once | The user just chose to come; a small "I see you". |
| Hop! "Boş ver" | The hop; the skip chime only on the first skip of the day and a run of three | The skip is the most frequent celebration; a chime every time would wear out by day 3. |
| Hop! open, quick check, hand-off | None, or a nod's soft tok | No reward sound for opening; no punishment sound either. |
| The minute | Brush strokes, the hum, the ending's one breath | It is a sensory ritual; sound earns its place here most. |
| Breathing break | Optional breath guide (a soft swell that follows the orb) | Pacing helps; off unless ambience is on. |
| **Island** | Taps, residents, builds, arrivals; ambience if enabled | The world is where sound lives. |
| Navigation, sheets, menus | **Silence** | Interaction spec §6.2. |
| Errors, a reset calm, a pout | **Silence** (a pout gets the hmph at most once a day, with its line) | Shame has no soundtrack. |
| Bedtime window | Silence; Yıldız's stargazing gets its three-note lullaby with ambience on | A21: nights are a dead end. |
| Onboarding end, milestones | The four-note Pofu motif | The sonic logo, rationed (design language §11). |

### 1.4 Defaults and switches

- **Settings → Sounds**: "Pofu'nun sesleri" (Pofu's sounds) **on** by
  default; "Ada müziği" (island music) **off** by default, offered once on
  the island (section 8, Q1).
- **Silent switch** (or the Action button's Silent mode): everything off,
  through `.ambient`. We never use `.playback`.
- **Other audio playing** (`secondaryAudioShouldBeSilencedHint`): ambience
  does not start, and fades out if it was playing; micro-sounds still play,
  mixed under.
- **VoiceOver running**: ambience 10 dB lower; sounds never carry meaning
  alone (every sound has a face, a haptic, or a line).
- **Interruptions** (a call, Siri): stop, and do not resume ambience
  automatically; resume on the next island visit.

## 2. Pofu's micro-sounds

Rules: one sound per interaction (interaction spec §6.2); each has 3–4
takes picked round-robin with ±30 cents of random detune (noise sounds) or
a choice of pentatonic pitch (tonal sounds); runs of repeated touches get
quieter, like the haptic rule (0.5 → 0.3 → none after 8).

How made: **S** synthesized offline (render.py), **F** recorded foley,
**V** a human performer pitched up (section 3). ✓ = rendered in the proof
as a stand-in.

| # | Sound | Trigger | Length | Made | Haptic pair | Proof |
|---|---|---|---|---|---|---|
| 1 | **Poke "pff"** (felt) | Poke | 120–240 ms | S + F | soft impact 0.5 | ✓ `pofu-poke` |
| 2 | **Stroke** (brush on felt) | Pet stroke | 150 ms | F | none (continuous) | |
| 3 | **Melt hum** | Long press melt | 300 ms | V | Core Haptics "melt" | |
| 4 | **Sleepy sigh** | Doze after 8 strokes, bedtime | 600–750 ms | V | none | ✓ `pofu-sleepy-sigh` |
| 5 | **Giggle** | Third poke in a run (with the playful line) | 400–500 ms | V | none | ✓ `pofu-giggle` |
| 6 | **Sniff** | Hop! landing, curious | 300–420 ms | S or V | none | ✓ `pofu-sniff` |
| 7 | **Hop** (take-off chirp + plush landing) | Skip, proud | 420 ms | S + F | `.success` on landing | ✓ `pofu-hop` |
| 8 | **Chew** | Seed into the jar, Pofu eating | 600 ms | F (real seeds) | none | ✓ `pofu-chew` |
| 9 | **Cheek stuff "pomf"** | A seed into Pofu's cheeks | 150 ms | F | light | |
| 10 | **Hmph** (a puff of air) | Pout, ≤ 1 a day | 250 ms | V | none | |
| 11 | **Surprised "o"** | Surprised (the island grew) | 150 ms | V | none | |
| 12 | **Yawn** | Sleepy, bedtime tuck-in | 700 ms | V | none | |
| 13 | **Smug sparkle** | Calm reaches ×2.0 | 300 ms | S (two high kalimba notes, B6 D7) | none | |
| 14 | **Seed plip** | A seed hops into the jar | 120 ms | S | none | |
| 15 | **Bead drop** | A tally bead fills | 100 ms | S (tiny wood) | `.success` (gate v2) | |
| 16 | **Station tok** | Station tap | 80 ms | S (modal wood) | `.selection` | ✓ `ui-tok` |
| 17 | **Build swap / settle** | Build | 120 / 600 ms | S (tok + three rising kalimba notes) | medium / `.success` | ✓ `skip-chime` (same three notes) |
| 18 | **Resident motifs** | First resident tap of a visit | ≤ 300 ms | F + S (Mochi: a tea glass and spoon; Simit: a paper bag; Nane: two soft hoots on Yıldız's motif; Pamuk: a water "bloop"; Fındık: a tiny ratchet) | none | |
| 19 | **Lawn rustle** | Lawn tap | 200 ms at −30 dBFS | F | none | |
| 20 | **Cloud pass** | Island arrival, map travel | 1.3 s | S (wind swell) | `.success` when the island settles | ✓ inside `arrival-iskele` |
| 21 | **Arrival cue** | A new island's first morning | 2–3 s | S | `.success` | ✓ `arrival-iskele` |
| 22 | **Pofu motif** | End of onboarding, milestones | 1.2 s | S (kalimba) | celebration pattern | |
| — | Worried, unwell, tired, reset, "not enough seeds" | — | — | **Silence** | — | |

**Never:** real hamster recordings. A hamster's audible squeaks are
mostly distress calls; they read as pain on a phone speaker.

## 3. How to make them: synthesis, foley, or a voice

| | Offline synthesis (render.py) | Recorded foley | A human performer, pitched up |
|---|---|---|---|
| Good at | Tonal sounds in key (kalimba, chimes, pads), wood, wind, plips, thumps; exact level and length; infinite takes; reviewable as code and numbers | Textures with real grain: felt, brush, seeds, paper, a tea glass | Life: giggles, sighs, hums, a pout's "hmph". The thing that makes a character feel like someone |
| Bad at | Voices: synthesized giggles drift to "toy" or "uncanny" | Variation (needs many takes); room noise; editing time | Cost and rights; the chipmunk trap if pitched too far |
| Cost | Already built; minutes per sound | An afternoon with a phone or a cheap mic in a closet, or CC0 libraries with recorded provenance | A one-hour session with a 10-minute script, then editing |
| Our use | Every tonal and physical sound; all music | Brush, seeds, cheek stuff, lawn, resident props | Sounds 3, 4, 5, 10, 11, 12 |

**Recommendation: all three, each where it is best.** The proof shows
synthesis already gets the physical and tonal sounds clean and in key.
The vocal stand-ins in the proof (giggle, sigh) are placeholders; replace
them with a performer before the friends beta. Pitch the performer up 5–8
semitones with formant correction (the "small animal" range without the
chipmunk cartoon), high-pass at 150 Hz, keep each under 500 ms. Who
performs is Q2 in section 8.

**No babble.** Animal Crossing's Animalese works because villagers talk a
lot and players skim; Pofu's lines are short and meant to be read, and
babble on the hundredth Hop! would fail test 1 and test 2.

**A proposed amendment to the design language.** §11 says "Nothing
synthetic". The intent is right (no beeps, no chiptune, nothing that
sounds like a notification), but the proof's kalimba and wood are
synthesized. Proposed wording: **"Nothing that sounds synthetic."**

## 4. Music: one key, many moods

### 4.1 Island keys

The design language fixes **D major pentatonic** (D E F♯ A B) for every
tonal sound, so any two overlap without clashing. Each island picks a
**mode that contains those five notes**; the two extra notes give it a
colour. Pofu's sounds never need retuning between islands.

| Island | Mode (extra notes) | Mood | Progression (stems) | Motif | Lead timbre | Bed |
|---|---|---|---|---|---|---|
| **Ayçiçeği** | D Ionian (G, C♯) | Sunny, home | Dadd9 – Gmaj7 – Bm7 – Asus4 (I–IV–vi–Vsus) | D F♯ A B (the sunflower opening) | Kalimba, felt | Meadow air |
| **İskele** | D Mixolydian (G, C♮) | A harbour morning, a little folk | D – C – G – D (I–♭VII–IV–I) | A B D C D (the ♭7 cadence) | Kalimba, later a plucked bağlama colour | Lapping water, a distant ferry horn |
| **Yıldız** | D Lydian (G♯, C♯) | Floating, night, wonder | Dmaj7 – E/D (I–II over a D pedal) | A C♯ B F♯ | Music box, long reverb | Night hush |
| **Kaplıca** | B Dorian (G♯, C♯) | Warm, steamy, unhurried | Bm9 – E9 (i–IV vamp) | F♯ E D B | Breathy ney-like flute | Low water, steam |
| **Kitap** | B Aeolian (G, C♯) | Bookish, gentle | Bm – G – D – A (i–VI–III–VII) | B D C♯ A | Felt piano, page-turn foley | Room tone, rain on a window |

A hint of Turkish colour comes from **timbre** (a ney-like breath, a
bağlama-like pluck, the tea glass), not from makam scales: Hicaz on D
(E♭, B♭) would clash with the pentatonic and break the one-key rule.

### 4.2 What drives the music

| Input | Drives | Never |
|---|---|---|
| **Calm ×1.0 → ×2.0** | The voicing opens: ×1.0 is root, fifth and third, close and low; ×1.3 adds the 7th or 9th colour layer; ×1.7 adds the upper-octave shimmer. The low-pass opens from about 800 Hz to 3 kHz; the stereo image widens; the melody gets a few more notes. | Calm resetting to ×1.0 never "drops" the music audibly: layers fade over 8 seconds on the next visit, not live. |
| **Wellbeing** | Density and pace only: a tired Pofu means a sparser, slower island; unwell means the base pad alone, quieter. | **The harmony never turns minor or sad.** A sad soundtrack for a reach is guilt with a melody. |
| **Time of day** | 06–11 brighter and higher; 11–17 full; 17–23 warmer (filter × 0.85), lower register; 23–06 the islands sleep: no melody, only the night bed. | Music at bedtime, except Yıldız's 20-second ritual. |
| **The island's stage** | Each stage adds a stem layer (stage 1 the bed and pad; stage 3 the melody; stage 5 the shimmer), so the island literally sounds fuller as it grows. | Unlocking sound as a reward to chase: it follows the stage, it is never a goal. |

### 4.3 Arrival cues

A new island's first morning gets a 2–3 second cue built from its motif:
the cloud-pass wind swell, the island's signature low (İskele: the ferry's
soft D–A horn; Yıldız: two hoots from Nane; Kaplıca: a water bloop), the
motif on the lead timbre, a cadence to the tonic (İskele's is the
Mixolydian C → D), resolving into the island's pad. **Once per island,
ever.** Later travel gets the 1.3-second wind swell only (interaction spec
§6.2).

The **Pofu motif** (the sonic logo) stays separate: four kalimba notes,
only at the end of onboarding and at milestones.

### 4.4 How long a loop needs to be

Game design A10 sets the median visit at 90 seconds or less. A
30–40-second stem with a non-repeating melody on top will not be heard to
repeat in one visit. That fact chooses the implementation.

## 5. The iOS implementation path

| Option | Quality | App size | CPU and battery | Engineering | Risk |
|---|---|---|---|---|---|
| **A. Stems + runtime composer on `AVAudioEngine`** (recommended) | High: stems are rendered offline with care; the melody never repeats | ≈ 6 MB for five islands and ≈ 25 micro-sounds (AAC 64–96 kbps) | Low: a few player nodes, one EQ, one reverb | ≈ 5 days | Low |
| B. Full runtime synthesis (`AVAudioSourceNode` oscillators in Swift) | Medium: the same DSP, but tuned live on device only | < 1 MB | Medium: a real-time render thread in Swift (no allocation, no locks) | 10–15 days | High: real-time safety, glitches, battery |
| C. AudioKit (SPM) | Medium-high | +2–4 MB of library | Medium | 4–6 days | Medium: a large dependency, API churn between majors, warnings-as-errors in CI |
| D. Stems only, no composer | High but repetitive over many visits | ≈ 6 MB | Lowest | ≈ 3 days | Low, but the island sounds the same every day |

**Choice: A.** Visits are short, so live synthesis buys nothing; the
offline renderer (this proof, grown up) gives quality we can measure in
CI; a small composer gives the never-the-same feel for almost nothing.

**Shape.**

- `PofuCore/Audio` (pure, unit-tested on CI): `IslandScore` (mode,
  progression, motif, stems) and `MusicMood` (calm, wellbeing, hour,
  stage) → layer gains, filter cutoff, and a deterministic list of note
  events for the next 30 seconds from a daily seed. The same numbers the
  Python renderer uses, so the proof and the app agree.
- `PofuAudio` (new PofuKit target): the session (`.ambient`), the
  toggles, one `AVAudioEngine` with a pool of `AVAudioPlayerNode`s for
  micro-sounds (round-robin takes, run rationing), one player per stem
  layer, an `AVAudioUnitEQ` low-pass and an `AVAudioUnitReverb` on the
  music bus, interruption and route-change handling, VoiceOver ducking.
- Signature haptic sounds (melt, celebration) play through Core Haptics
  with the audio in the AHAP, so they land on the same frame (design
  language §11).
- Start the engine when the island or Hop! appears (prewarmed buffers, so
  the first poke is instant); stop it after 20 seconds without sound when
  ambience is off.

**Estimate:** session and toggles 0.5 day; engine, buffer cache and
micro-sound player 1.5; music controller 1.5; composer in `PofuCore`
0.5; interruptions, routes, accessibility 0.5; tests 1. Authoring: grow
`render.py` to export stems and note samples, 1–2 days; two 30-minute
listening sessions with the founder on his iPhone.

**Risks and mitigations.**

| Risk | Mitigation |
|---|---|
| AAC loops are not gapless (encoder priming and padding) | Decode stems to PCM buffers and loop with `.loops` (sample-accurate; ≈ 11 MB of RAM per 30-second stereo layer while the island is on screen), or schedule the file segment repeatedly and verify on device on day 1 |
| The phone speaker loses everything under ~250 Hz | The renderer checks it (section 7); the root of every chord is felt, the upper voices carry it |
| The simulator's audio is not the phone's | Tune only on the founder's iPhone; CI checks numbers only |
| Nobody on the team can listen in the agent environment | Numbers in CI (levels, seams, spectra) plus the founder's ears in two short sessions; nothing ships unheard |
| Sound becomes a reason to open the app | No sound is ever a reward to chase, nothing plays outside the app, and ambience is off by default |

**When.** Not before the gate: the founder's dogfood week comes first.
Micro-sounds land with the touch reactions in stage W (after W4, when
prototypes stop being rough); the ambience follows the friends beta.

## 6. Levels

| Bus | Asset target | Runtime gain (default) | Result |
|---|---|---|---|
| Micro-sounds | −18 LUFS, loudest 400 ms window; ≤ −1 dBTP | −12 dB | Peaks around −18 dBFS (interaction spec §6.2) |
| Lawn, quiet taps | −18 LUFS asset | −24 dB | Around −30 dBFS |
| Island music | −20 LUFS integrated; no moment more than 6 LU above; ≤ −1 dBTP | −8 dB | About −28 LUFS: clearly under streamed music, which is normalized to around −14 LUFS |
| Arrival cue, Pofu motif | −18 LUFS momentary | −10 dB | The loudest thing Pofu does, still gentle |

Assets are mastered to a common loudness so the runtime gains are the
only mix decisions, and those live in config, not in files.

## 7. The proof

`python3 tools/sound/render.py` renders everything below from numbers in
about 40 seconds, then measures it (BS.1770-4 loudness with a self-test,
4× oversampled true peak, spectra, edges, loop seams) and fails if a
limit breaks. Files are in `design/sound/proof/`; `spectrograms.png` is
the contact sheet.

| File | Length | Size | True peak | Loudness | Centroid | < 250 Hz | Notes |
|---|---|---|---|---|---|---|---|
| `pofu-poke.wav` | 0.24 s | 23 KB | −1.2 dBTP | −23.0 LUFS-M | 341 Hz | 2 % | Peak-limited transient: sits under the −18 target by design |
| `pofu-sniff.wav` | 0.42 s | 40 KB | −2.3 | −18.0 | 3.5 kHz | 0 % | Three rising sniffs; 1.4 % above 6 kHz |
| `pofu-giggle.wav` | 0.50 s | 48 KB | −8.7 | −18.0 | 960 Hz | 0 % | D6 B5 A5 F♯5 chirps; vocal stand-in |
| `pofu-sleepy-sigh.wav` | 0.75 s | 72 KB | −4.9 | −18.0 | 625 Hz | 7 % | Breath with a falling A4 → F♯4 hum; vocal stand-in |
| `pofu-hop.wav` | 0.42 s | 40 KB | −4.0 | −18.0 | 293 Hz | 19 % | D5 → A5 chirp, plush landing |
| `pofu-chew.wav` | 0.62 s | 60 KB | −1.3 | −18.0 | 1.3 kHz | 34 % | Five nibbles and a swallow; foley will beat it |
| `ui-tok.wav` | 0.30 s | 29 KB | −1.2 | −20.2 | 598 Hz | 0 % | Modal wood on D5 (free-bar ratios 1, 2.76, 5.40, 8.93) |
| `skip-chime.wav` | 1.35 s | 130 KB | −7.9 | −18.0 | 799 Hz | 0 % | Kalimba D5 F♯5 A5 |
| `arrival-iskele.wav` | 3.00 s | 288 KB | −7.5 | −18.0 | 539 Hz | 1 % | Wind, D–A ferry horn, motif A B D C D, Mixolydian cadence |
| `island-aycicegi-day-calm1.0.m4a` | 30 s loop | 368 KB | −10.3 | −20.0 LUFS-I | 398 Hz | 11 % | Closed voicing, sparse kalimba; seam 0.09 × a typical step |
| `island-aycicegi-day-calm2.0.m4a` | 30 s loop | 367 KB | −9.8 | −20.1 | 609 Hz | 18 % | Same seed, calm ×2.0: 9ths, shimmer, open filter, wider |
| `island-yildiz-night.m4a` | 30 s loop | 367 KB | −9.6 | −20.0 | 417 Hz | 25 % | Lydian I–II, long reverb, sparser |
| `island-kaplica-evening.m4a` | 30 s loop | 367 KB | −10.5 | −20.0 | 388 Hz | 27 % | B Dorian vamp, ney-like flute |

What the numbers show: every file is under the −1 dBTP ceiling and 1 MB;
the loops hit −20 LUFS within 0.1 LU and never rise more than 3.8 LU
above it (no kalimba note pokes out); the loop points are continuous
(the seam is smaller than an ordinary sample step); nothing has more than
1.4 % of its energy above 6 kHz (nothing harsh); calm ×2.0 is audibly
brighter than ×1.0 (centroid 609 vs 398 Hz) with the same seed. An
earlier pass failed the checks for exactly the things a listener would
have caught: note tails cut off (clicks), a noise bed with a seam, a hop
whose landing lived below 200 Hz where a phone speaker is deaf, and a
sparse melody that the mixer was boosting. The checks caught all four.

What they cannot show: whether any of it is charming. That needs ears,
on the founder's iPhone (Q4).

## 8. Open questions for the founder

| # | Question | My recommendation |
|---|---|---|
| Q1 | Island music: off by default, or on? | **Off by default, offered once, diegetically**: on the second visit to the island, Mochi's little radio by the çay ocağı plays the island for 10 seconds; tap the radio to keep it. It respects the user's silence and makes the toggle part of the world. |
| Q2 | Who performs Pofu's vocal sounds? | **You, for the first version**: a 10-minute script of giggles, sighs, hums and "hmph"s recorded in Voice Memos in a quiet room; I pitch and edit them. Free, personal, and the rights are yours. A professional session (about an hour) before launch if they do not hold up. |
| Q3 | Yıldız's stargazing at bedtime: three quiet notes, or silence? | **Three notes, only with island music on**, then silence with "İyi geceler". It is the one ritual designed to end with the phone down. |
| Q4 | How do you review sound? | **Two 30-minute sessions on your iPhone** (speaker, then AirPods): one for the micro-sounds after they land in Rehearsal mode, one for the island music. I send the files and a one-page sheet; you mark each "keep / change / cut". |
| Q5 | Turkish colour: a ney-like flute and a bağlama-like pluck? | **Yes, as timbre only** on İskele and Kaplıca, in key. No makam scales (they break the one-key rule). |
| Q6 | Amend "Nothing synthetic" to "Nothing that sounds synthetic" in the design language? | **Yes.** The intent stays; the rule stops forbidding the tools that make the sounds. |

## 9. Proposed changes to other documents (after the gate week)

- Design language §11: "Nothing synthetic" → "Nothing that sounds
  synthetic"; add "sad states and resets are silent"; add the four tests.
- Interaction spec §6.2: add sniff (Hop! landing), hop (skip), chew and
  cheek stuff (seeds), the skip chime's rationing (first skip of the day
  and a run of three), and the stage-driven stem layers.
- Game design §15: add the `PofuAudio` target and the `PofuCore/Audio`
  score model.

## 10. Self-critique

- **I have not heard a single one of these sounds.** The checks prove
  they are clean, level, in key and loopable; they prove nothing about
  charm. The vocal stand-ins in particular are probably not good enough,
  which is why section 3 replaces them.
- **The pad is a generic additive synth.** Good enough to prove the
  harmony, the calm mapping and the loop; the shipped stems should use a
  warmer source (a sampled felt piano, a real kalimba multisample) through
  the same score.
- **Five islands, five modes, one key** is elegant on paper; in practice
  the modes' colour notes are quiet in sparse music, and islands may
  sound more alike than the table suggests. Timbre and bed will carry
  more of the identity than the mode. Watch it in the first listening
  session.
- **Ambience may simply not matter.** Most iPhones live on silent. Sound
  B is right to make the tiny sounds the default and the music optional;
  if the founder's own phone is on silent all week, that is the answer to
  how much to invest here.

## Sources

- Design language §11 and interaction spec §6.2 (this repository).
- Rich Vreeland (Disasterpeace) on Mini Metro's programmed music, Designing
  Sound: https://designingsound.org/2016/02/18/the-programmed-music-of-mini-metro-interview-with-rich-vreeland-disasterpeace
- Nookipedia, Animal Crossing's hourly music and Animalese:
  https://nookipedia.com/wiki/Animalese
- Apple, `AVAudioSession.Category.soloAmbient` (silenced by the Silent
  switch; use `ambient` to mix):
  https://developer.apple.com/tutorials/data/documentation/avfaudio/avaudiosession/category-swift.struct/soloambient.md
- ITU-R BS.1770-4, loudness measurement (K-weighting and gating), as
  implemented in `tools/sound/render.py`.
