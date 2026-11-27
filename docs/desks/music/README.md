# Music desk: charter

**For:** everything the player hears: music first, then ambience and
cues. The founder's bar (founder-input 47): game music, not film music;
a tune for every island, state and condition, all different and lively,
all one family. His examples of feeling: Animal Crossing, Minecraft,
Zelda. Never copies.

**Read before any work:** this page, [plan.md](plan.md), and the
section of [the music system](../../design/music-system-v1.md) your
row names. The architecture is
[ADR-0029](../../adr/0029-music-is-a-score.md) and is not reopened in
a brief.

## Truth

| What | Where |
|---|---|
| The tunes | `design/music/score/<island>/<tune>.abc` (text; the source) |
| The band and the renderer | `tools/music/` |
| What ships | `Packages/PofuKit/Sources/PofuSound/Resources/Music/` and its `music.json` |
| What plays when | `PofuSound/Music/MusicDirector.swift` and `MusicDirectorTests` |
| Cues and ambience (older, same desk) | `PofuSound/`, `tools/sound/`, `docs/design/sound-identity.md` |

A tune that is not in `score/` does not exist. An audio file with no
score is deleted.

## How work is made

1. **Write** the tune as ABC with the `pofu-music` skill: the bible
   (the system's section 5), the island's row, the Pofu motif.
2. **Render** with `python3 -I tools/music/render.py`. It runs the lint
   and stops on the first failure. Nothing is committed that fails it.
3. **Look**: the piano roll and the spectrogram sheet. No agent can
   hear; an agent can see a tune that never rests or never moves.
4. **Audition**: for a new tune, three candidates of about 40 s in
   `design/music/audition/`, named `<date>-<what>-A|B|C.m4a`.
5. **His ear**, only at the three gates: the band's sound, the Home
   tune, one listen per new island. A link, a default, a time.

## Accepted by

The lint and the unit tests for everything a machine can check; his ear
for whether it is lovely. Never the reverse: a clean meter has never
made a tune good, and "it sounds nice" from an agent is not a fact.

## Never

- A tune modelled on a named melody.
- A recording from a generator or a library in the bundle: every sound
  is made by `tools/music/band.py` or `tools/sound/`, so the public
  repository carries no licence to track.
- A note outside the island's mode by accident, or harmony that turns
  sad to punish a bad day.
- Music on the gate, the shield, the breath room, or from 23:00 to
  06:00.
- A loop that plays without a pause.

## Who works it

| Work | Who |
|---|---|
| The first of a kind: the Pofu motif, the Home tunes, the voyage | Fable, with the skill |
| An island's tune, a stinger, a special day | Opus, with the skill |
| The tools, the director, the player | builder (Sonnet; tests accept it) |
| A tune review, on the roll and the score | critic (Opus), lens: "can you hum it; does it breathe" |

The Python lane: no Swift build, so this desk runs beside the Swift
lane. Only MU2 and MU3 need the Swift lane.

## Budget

24 MB of music in the bundle for Book One (the lint's limit). A tune is
about a day of one agent, an island about two with its stingers.
