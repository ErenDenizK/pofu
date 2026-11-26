# The music system v1

**Status:** spec by Fable for founder-input 47 (item 3), 2026-11-26.
The architecture is [ADR-0029](../adr/0029-music-is-a-score.md). Builds
on [sound-identity.md](sound-identity.md) (2026-11-02) and replaces its
sections 4.4, 5 and 7 and its island list. Answers the main-flow plan's
G10 and Q3.

**Basis:** pofu `origin/main` a816a65e. **[seen]** opened in this
session; **[scout]** from `docs/research/studio-2026-11-26/raw-music-studio.md`
on the lead branch. Paths are under `Packages/PofuKit/Sources/` unless
they start with `App/`, `tools/`, `design/` or `docs/`.

## 0. The goal, restated

He asked for game music, not film music: a tune you can hum, for every
island, state and condition, all different and lively, all one family.
He does not know how music is made and asked what structure would keep
it consistent and let it grow.

Three things decide the design, and none of them is a tool:

1. **No agent can hear.** Every agent here can write, measure and draw
   sound, and none can say whether a tune is lovely. The only ears are
   his. So the system must make everything except taste checkable by a
   machine, and must spend his ears on few, decisive listens.
2. **"Every state" is a product, not a list.** Six islands by three
   times of day by five weathers by four seasons is 360 recordings, and
   360 recordings do not sound like one family. A family comes from a
   few tunes and a set of rules that vary them.
3. **A visit is short.** The design's own number is a median visit of
   90 seconds or less (`sound-identity.md` section 4.4) [seen]. A loop
   heard forty times a day is a nuisance. A phrase that arrives, ends
   and leaves the island's air behind is a pleasure.

So this is not "generate tracks". It is: **write tunes as text, give
them one band, and let the island decide what to play.**

## 1. What "done" means

1. He opens Home by day and, a few seconds after the wind, a short tune
   plays on a kalimba, ends, and leaves the island's air. A minute later
   it answers itself with its second phrase. He can hum it afterwards.
2. At night the island has another, slower tune. In rain the same tune
   comes thinner and lower. In the island's winter a music box plays it.
   He never hears the same half minute twice in a visit.
3. On Köke the tune is another tune and plainly the same family; riding
   the Gezgin there, the music travels with him.
4. Building a station, growing the island and a special day each have
   their own few notes, in key with whatever was playing.
5. A new island's music is one tune written, one command run, one listen
   by him.

## 2. Where it stands

| Thing | Today | Evidence |
|---|---|---|
| Music in the app | None: no asset, cue or player | [scout] section 1; main-flow plan G10 |
| One key | Every tonal cue is inside D major pentatonic | `PofuSound/SoundCue.swift:5` [seen] |
| Playback | `AVAudioEngine`, buffers scheduled by player nodes; a second engine loops ambience beds by hour and weather, ducks under cues, is silent from 23:00 | `PofuSound/SoundEngine.swift:68`, `AmbienceConductor.swift:263` [seen]; `Ambience.swift:58-110` [scout] |
| A renderer | Instruments from numbers (a kalimba, a pad, a wood tok, a room reverb), island modes and motifs, a 30 s loop maker, a loudness meter that checks itself | `tools/sound/render.py:175,207,250,537-600` [seen] |
| Things to listen to | Four island loops and nine sounds, rendered on 11-02. "Nobody has listened to these yet" | `design/sound/proof/island-home-day-calm1.0.m4a` and three more; `tools/sound/README.md` [seen] |
| A design | One key, a mode per island, stems and a runtime composer; written for islands that are no longer the plan (İskele, Yıldız, Kaplıca, Kitap) | `sound-identity.md` section 4 [seen] |
| A home for the work | No desk, no queue, no skill, no state record | [scout] section 3 |
| His words | "sound B" (procedural music welcome); later "do not start it"; now a major line, with Animal Crossing, Minecraft and Zelda as the feeling | `docs/product/founder-input.md:458,779` [scout]; founder-input 47 |

The proof loops are chords with a sparse generated melody. They are the
"dümdüz" he does not want as music, and they are exactly right as a
test of one thing: whether instruments made from numbers sound good
enough to him. That listen costs nothing and decides D3 below (Q-C).

## 3. Gaps, ranked by what the player feels

| # | Gap | Closed by |
|---|---|---|
| G1 | The island has no tune | MU1, MU2 |
| G2 | Nothing he can listen to and judge on his phone | MU1 (files), MU3 (in the app) |
| G3 | Night, rain, season and island would all sound alike | MU4 |
| G4 | Travel, building and special days are silent | MU4, MU5 |
| G5 | Nobody owns music, so it would be made once and drift | the Music desk and the `pofu-music` skill ([../studio/desks-2026-11-26.md](../studio/desks-2026-11-26.md)) |

## 4. Decisions

| # | Decision | Not taken, and why | Who |
|---|---|---|---|
| D1 | **The score is text in the repository** (ABC notation, a small subset), rendered offline, played as cells: ADR-0029 | Generators, bought loops, a runtime sampler: the ADR | [now] |
| D2 | **Tunes, not loops.** A tune is four to six cells (phrases of 4 to 8 bars: A, A', B, an ending). The director plays one cell, lets its tail ring, leaves 4 to 12 s of the island's own air, and plays the next in musical order. Home's first phrase starts 3 to 8 s after the app opens | *A 30 s loop* (`sound-identity.md` 4.4): heard forty times a day. *Music all the time:* the air and the cues are part of the sound; silence is what makes a phrase a visit | [now] |
| D3 | **One band of eight, made from numbers:** kalimba, music box, felt keys, nylon pluck, a breathy whistle (the ocarina's cousin), a soft pad, a round bass, and small percussion (shaker, wood tok). Plucks, mallets, keys and pads are what synthesis does well and what these games' music is mostly made of | *Sample libraries or a sound font:* better strings and winds, which the band does not use; licences to track in a public repository. Kept as the fallback for one instrument at a time | [now]; his ear confirms (Q-C) |
| D4 | **One key, kept.** Every island's mode contains D major pentatonic, so every cue, bell and stinger is in tune over any music, and two islands' music can cross. The modes and motifs of `sound-identity.md` section 4.1 are the model; the table is rewritten for the islands that exist (section 5) | *A key per island:* every cue would need a version per island | [now] |
| D5 | **Three voices a cell:** lead (the tune), bed (pad and bass), pulse (pluck pattern, percussion). Each is its own stem, the same length, sample-aligned. The state turns stems on and off; it never needs a new recording | *One mixed file a cell:* every condition would be a re-render and a file | [now] |
| D6 | **What each condition changes** (section 6). One rule each: the island chooses the tune and mode; the hour chooses the day or night tune; the weather thins the stems; the island's season changes the lead instrument; the island's stage adds stems; wellbeing changes only the pauses. **The harmony never turns sad** (`sound-identity.md` 4.2, kept) | *A piece per combination:* 360 | [now] |
| D7 | **Music is on by default, quiet** (the tune at -20 LUFS under a gain in `tuning.json`), with its own switch in Settings ("Ada müziği"). It obeys the silent switch and yields to other audio, as ambience does (`.ambient`), and is silent from 23:00 to 06:00 with the islands | *Off by default behind Mochi's radio* (`sound-identity.md` Q1): he now calls music a major line; a thing nobody finds is not one | [now]; he vetoes on his phone |
| D8 | **No music on the Gate, the shield, the breath room or onboarding's permission screens.** The shield cannot link `PofuSound` at all (`PofuSound/SoundEngine.swift:10-12`) [scout], and the gate is where the app asks for a pause | *A tune on the gate:* the wrong moment to charm | [now] |
| D9 | **His ears, at three gates:** the band (Q-C, now, on files that exist); the Home day tune (three candidates of about 40 s after MU1); then one listen per new island. Each is a file link and, from MU3, a row in Rehearsal mode. Each carries a default and a time | *Approve every cell:* he has said he decides only large directions | [now] |
| D10 | **Machines hear what machines can:** a lint over the score and the audio (section 7), and a piano-roll picture of every tune so an agent can see its contour and rhythm | *Trust the composer:* the proof loops were "clean, level and loopable" and unheard | [now] |
| D11 | **Tunes are written by Opus with the `pofu-music` skill; Fable writes the first of each kind** (the Pofu motif, the Home tunes, the voyage). If two auditions of the Home tune fail his ear, the six tunes are commissioned from a person and enter through the same renderer | *A person from the start:* slower to begin and worth trying second, not first, when a trial costs a day | [now] |
| D12 | **Nothing is modelled on a named melody.** The examples he gave set feeling and quality: short phrases, small ensemble, room to breathe. A composer brief never names a piece to imitate | | [now] |

## 5. The bible, v0

The music desk keeps this section as its own page when it has grown
(`docs/desks/music/` if the desk proposal is taken).

**The Pofu motif.** Four notes on the kalimba, inside the pentatonic,
rising and settling: the sonic logo (`sound-identity.md` 4.3). Every
island's tune quotes its shape once, in its own mode. Written in MU1.

**Islands.** The mode adds two notes to the pentatonic; they are the
island's colour and are used on purpose, not in passing.

| Island | Mode | Feeling | Lead | Colour |
|---|---|---|---|---|
| Ayçiçeği (Home) | D Ionian | sunny, home, a little bouncy | kalimba | felt keys, wood tok |
| Köke | B Aeolian | an old root, low and kind | nylon pluck | bass, pad |
| Çağlayan | D Mixolydian | water running, a folk lilt | whistle | pluck pattern, shaker |
| Revontuli | D Lydian | polar night, floating, wide | music box | long pad |
| Emanet | B Dorian | a kept thing, warm, unhurried | felt keys | whistle |
| Mehtap | D Lydian, slower, over an A pedal | moonlight, the last island | music box and whistle together | pad |

The moods are mine, from each island's place in Book One; the Story
desk corrects them against `docs/product/story-map/book-one.md` before
an island's tune is written.

**Tempo.** Day tunes 84 to 104 beats a minute, night tunes 60 to 72.
Nothing faster in the world; a game may go to 120.

**Range.** The lead lives between D4 and D6: a phone speaker loses what
is lower, and higher is shrill. Bass is felt on headphones and absent on
the speaker, so no tune depends on it.

**Form.** Cells end on a note of the pentatonic, so any cell may follow
any other across a pause. Only the ending cell lands on the tonic.

## 6. What changes the music

| Input | Changes | Costs |
|---|---|---|
| Island | The tune, the mode, the lead instrument | one tune per island |
| Hour | 06 to 17 the day tune; 17 to 23 the night tune, slower and lower; 23 to 06 silence | one more tune per island (Home first; other islands may share their day tune, slowed, until theirs is written) |
| Weather | Overcast: no pulse. Rain: no pulse, longer pauses, the rain bed louder. Mist: bed only. Golden haze: all three, the lead a little softer | a rule |
| Island season (Home only, [island-calendar-v1.md](island-calendar-v1.md)) | The lead's instrument: spring kalimba, summer nylon pluck, autumn felt keys, winter music box | the lead stems rendered four times |
| Island stage | A healing island starts with the bed alone, gains the lead at its middle stage and the pulse when healed | a rule |
| Wellbeing | Pauses grow when Pofu is tired. Nothing else | a rule |
| A station built | The island's motif, three notes, on the lead instrument | a stinger per island |
| The island grows | The whole motif with a cadence | a stinger per island |
| The voyage | A travelling piece in the bare pentatonic, so it fits both shores; the lead passes from the island left to the island reached | one piece |
| A special day | One tune for the day, in the island's mode, in place of the day tune | one tune per day |
| A game | Nothing in v1: the garden and stream games keep their cues over the island's bed | none |

**Size.** A stem is mono AAC at 64 kbit/s, about 8 kB a second. Home:
two tunes of six cells of about 10 s, with a bed, a pulse and four
leads, is about 5.8 MB. Each other island, with one lead, about 2.9 MB.
Book One whole: about 20 MB. The limit is 24 MB, a number in the lint.

## 7. What the machine checks

The run fails on any of these. Every defect his ear finds becomes a
line here.

- Score: every note is in the island's mode; the lead stays in range;
  no leap over an octave; a cell is 4 to 8 bars and all its voices are
  the same length; every cell but the ending ends on a pentatonic note;
  the tune quotes the Pofu motif's shape; the lead rests for at least a
  fifth of each cell (a tune has to breathe); no bar holds more than
  eight lead notes; lead and bed never hold a semitone apart on a
  strong beat.
- Audio, with the meter `tools/sound/render.py` already has: the full
  mix of each cell at -20 LUFS, true peak at or under -1 dBTP, under
  45 % of energy below 250 Hz, a tail that has decayed below -50 dBFS
  at the file's end, stems sample-aligned, the size limit.
- A picture for agents: a piano roll of every tune (pitch against time,
  one colour a voice) and the spectrogram sheet, so a critic can see a
  tune that never rests, never repeats or never moves.

## 8. Pull requests

MU1 is Python only and runs beside the Swift lane from tonight.

| PR | Branch | Kind | Files (owned) | Change | Acceptance | Fallback |
|---|---|---|---|---|---|---|
| MU1 | `feat/music-score` | test, then his ear | new `tools/music/` (`abc.py`, `band.py`, `render.py`, `lint.py`, `roll.py`, `tests/`), new `design/music/score/home/day.abc` and `motif.abc`, new `design/music/audition/`, `.github/workflows/ci.yml` (one line in `python-tools`) | The ABC subset parser, the band (the kalimba, pad and tok move from `tools/sound/render.py`; five instruments are new), the renderer and the lint. Three candidate Home day tunes (A, B, C), each rendered as one 40 s audition file in the order the director would play it, with its piano roll | `python3 -I -m unittest discover -s tools/music -p "test_*.py"` (parser round trip, each instrument's level and decay, every lint rule with a failing fixture); the three files and rolls committed. Then he listens (gate 2): the file links go to him with a default | If an instrument cannot be made to pass its level and decay tests, the tune uses the three that exist and the instrument gets a row in the desk's plan |
| MU2 | `feat/music-director` | test | new `PofuSound/Music/` (`MusicScore.swift`, `MusicDirector.swift`, `MusicPlayer.swift`), `PofuSound/SoundPolicy.swift` (`isMusicOn`), `PofuSound/Resources/Music/`, `PofuTuning/Resources/tuning.json`, `App/WorldSound.swift`, `App/Settings/SettingsView.swift`, `Tests/PofuSoundTests/MusicDirectorTests.swift` | `MusicDirector`, pure: island, hour, weather, season, stage, wellbeing and a seed in; the next cell, its stems and the pause out. `MusicPlayer` schedules the stems on one `AVAudioEngine` at one sample time and ducks with the cue rule that exists. The renderer writes `music.json`, the cells' index | `MusicDirectorTests`: cells come in order; no cell repeats within four; 23:00 returns silence; rain drops the pulse; every state in section 6 has a case; a year of simulated visits never plays two cells at once. A test checks every cell in `music.json` has its files | If stems drift on a device, each cell is rendered as one mixed file per weather and D5 is given up for v1 |
| MU3 | `feat/music-room` | his ear | `App/Rehearsal/` (one panel) | "Müzik odası" in Rehearsal mode: choose island, hour, weather and season and hear what the director would play; every stinger as a button | He plays three states on his phone and says what he hears | none |
| MU4 | `feat/music-home` | test, then his ear | `design/music/score/home/` (night tune, stingers, New Year), rendered stems, `music.json` | Home whole: night, the four leads, the stingers, the New Year tune | lint; `MusicDirectorTests` over the new index; he listens in the music room | A tune that fails two listens stays out; the day tune covers its hours |
| MU5 | `feat/music-voyage` | test, then his ear | `design/music/score/voyage/`, `PofuSound/Music/MusicDirector.swift` (the hand-over) | The travelling piece, with step 2d of the main-flow plan | lint; a director test for the hand-over; heard on the ride | Without it the ride keeps its wind |
| MU6+ | `feat/music-<island>` | test, then his ear | `design/music/score/<island>/` | One tune per island, with step 5 | as MU4 | as MU4 |

## 9. What is the founder's

| # | Question | My pick, applied meanwhile | What to send |
|---|---|---|---|
| Q-C | Bu enstrümanların sesi hoşuna gidiyor mu? Melodiyi değil, sesin kendisini soruyorum: kalimba ve arkasındaki yumuşak ses | Yes: the band is built from them (D3). "Hayır" changes the instrument, not the plan | `design/sound/proof/island-home-day-calm1.0.m4a` and `design/sound/proof/island-yildiz-night.m4a` (on `main`; 30 s each; made on 11-02 and never heard) |

After MU1: three Home tunes, one link each, "hangisi Pofu'nun adası?".

## 10. Out of scope

Game music for the garden and stream games; a soundtrack to sell or
stream; vocals; recorded foley and the performer for Pofu's voice
(`sound-identity.md` section 2 keeps that); spatial audio; music in the
widget, the shield or any extension; a tool that analyses reference
tracks; importing a composer's MIDI (written when D11's fallback is
taken); the islands after Book One.

## 11. Corrections

- `docs/design/sound-identity.md`: section 1.4 says ambience is off by
  default (on since #515) and names a Settings row that does not exist;
  section 4.1 lists islands that are not in the plan; sections 4.4, 5
  and 7 (30 s stems, `PofuAudio`, `IslandScore`) are replaced by this
  page and ADR-0029.
- `changes/feat-world-sound.md` still says ambience is off by default.
- `docs/design/mainflow-plan-2026-11-26.md` Q3 ("one calm loop for day
  and one for night, licensed or commissioned") was my pick on 11-26 and
  is withdrawn: his brief asks for a system, and two bought loops are
  the opposite of one.
