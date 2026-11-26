# 0029. Music is a score in the repository, rendered offline and played as cells

- **Status:** Proposed (the lead accepts it with the first music PR)
- **Date:** 2026-11-26

## Context

The founder wants game music (his examples of feeling and quality:
Animal Crossing, Minecraft, Zelda) for every island, state and
condition: all different, lively, and still one family
(founder-input 47). He asked what structure keeps it consistent and
lets it grow. The app has no music: 48 synthesized cue and ambience
files, one `AVAudioEngine` for cues and one for ambience
(`PofuSound/SoundEngine.swift`, `AmbienceConductor.swift`), every tonal
cue inside D major pentatonic (`PofuSound/SoundCue.swift:5`). A design
(`docs/design/sound-identity.md`, 2026-11-02) chose pre-rendered stems
and a small runtime composer; a proof renderer (`tools/sound/render.py`)
makes instruments from numbers and measures loudness. Nobody has heard
its output: no agent has ears.

"Every island, state and condition" is a product, not a list. Six
islands by three times of day by five weathers by four seasons is 360
pieces if each is a recording, and they would not sound like one family.

## Options considered

1. **Audio generators (Suno, ElevenLabs Music, Stable Audio).** Good
   sound in minutes. But a generator returns a mixed recording: no
   stems, no shared motif, no way to say "the same tune, in winter, on a
   music box". Each piece is a new stranger. Terms move (Suno's changed
   in August 2026), a paid account of his is needed, and the output
   cannot be diffed, reviewed or repaired by an agent.
2. **Licensed or commissioned loops.** The main-flow plan's earlier pick
   (Q3). Fine for two loops, wrong for a system: every new state is a
   new purchase, and nothing adapts.
3. **A runtime sampler** (`AVAudioUnitSampler` playing MIDI with a sound
   bank). Tiny files and endless variation, but what he hears exists
   only on a device, iOS-only code compiles only in CI, and bank loading
   has reported faults. Truth would be nowhere an agent can measure.
4. **A score in the repository, rendered offline into short cells, and a
   small director that plays cells by the game's state.** The tune is
   text (ABC notation, which language models write fluently and people
   can read). One renderer turns it into audio with one band of
   instruments. The app plays the files it was given.

## Decision

Option 4.

- **The score is the source.** `design/music/score/<island>/<tune>.abc`.
  A tune is a few cells (phrases of 4 to 8 bars); each cell has up to
  three voices: lead, bed, pulse.
- **One band.** Eight instruments made from numbers in
  `tools/music/band.py` (grown from `tools/sound/render.py`): no
  samples, no licences, fixed seeds, the same on every machine.
- **Rendered offline, measured, committed.** Each cell and voice becomes
  a stem with its reverb tail; the run fails on a note outside the
  island's mode, a level or peak outside its limit, or a stem over its
  size.
- **Played as cells.** A pure `MusicDirector` picks the next cell, the
  stems and the pause from the game's state; `AVAudioEngine` plays them
  sample-aligned. Variation comes from which cells, which stems and
  which instrument, not from new recordings.
- **Ears are the founder's,** at three gates only: the band's sound, the
  Home tune, and each island's tune. Everything else is derived by rule
  from what he approved.

## Consequences

- A condition (rain, winter, a festival) costs a rule or a re-render,
  not a composition. A new island costs one tune.
- The whole score can be revised at once: change the band and every
  piece changes with it.
- The tool chain is Python and runs beside the one Swift build, so the
  music desk never waits for the Swift lane.
- The band is limited to what synthesis does well: plucks, mallets,
  keys, a breathy whistle, pads. No strings, brass or voice. If his ear
  rejects an instrument twice, that one instrument is replaced by a
  CC0-licensed sample set behind the same interface; the score and the
  rest stand.
- A person can write for the same system: a composer's MIDI or ABC goes
  through the same renderer. If two auditions of the Home tune fail,
  the tunes are commissioned and the system stays.
- Reversing this (to a generator or a sampler) discards the renderer and
  the director: days, hence this record.
