# tools/music

The music line's tools ([music-system-v1](../../docs/design/music-system-v1.md),
ADR-0029): music is a score in text, played by one band made from numbers,
checked by a lint, and drawn so that an agent who cannot hear can read it.

```sh
pip install -r tools/sound/requirements.txt       # numpy, scipy; Pillow for the pictures
python3 -I tools/music/lint.py                    # every tune: score rules, then audio rules
python3 -I tools/music/render.py audition         # design/music/audition/ (needs ffmpeg)
python3 -I tools/music/render.py stems <tune.abc> <out-dir>
python3 -I tools/music/roll.py <tune.abc> <out.png>
python3 -I -m unittest discover -s tools/music -p "test_*.py"
```

| File | What it is |
|---|---|
| `abc.py` | The score: a small subset of ABC notation, parsed and written back exactly. Its docstring is the whole grammar |
| `band.py` | The band of eight: kalimba, music box, felt keys, nylon pluck, whistle, pad, bass, small percussion (tok, shaker). The kalimba, pad and tok are the functions in `tools/sound/render.py`, imported, so a cue and a tune stay one instrument |
| `render.py` | A cell as three sample-aligned mono stems (lead, bed, pulse) that add up to a mix at -20 LUFS; an audition file per tune |
| `lint.py` | Section 7 of the spec as failing rules |
| `roll.py` | The piano roll and the spectrogram sheet |

The package is `music` (`tools/` on the path): `abc.py` must never be
imported as a top-level `abc`, which is the standard library's.

## Writing a tune

A tune is one file under `design/music/score/<island>/`. Copy
`home/day-a.abc`. The header names the meter, the unit length, the tempo,
the key and the voices; `%%pofu island`, `%%pofu time` (day or night) and
`%%pofu order` (the cells in the order the director plays them; the last is
the ending) are Pofu's own fields. Each `P:` starts a cell and each voice
has one `[V:id]` line in it. A voice id is `lead`, `bed.<part>` or
`pulse.<part>`: the first word is the stem it is rendered into.

In `K:D` an `F` is F sharp and a `c` is C sharp: `D` is D4, `d` is D5, `d'`
is D6, `D,` is D3.

Then run the lint until it is quiet, render, and **look at the roll**
before anyone is asked to listen.

## What the lint fails

Score (each rule has a failing fixture in `tests/test_lint.py`):

| Rule | Fails when |
|---|---|
| `form` | not 4 to 6 cells; no lead; an island or an instrument that does not exist |
| `tempo` | a day tune outside 84 to 104 beats a minute, a night tune outside 60 to 72 |
| `mode` | the key is not the island's; any note of any voice is outside the mode |
| `bars` | a bar does not fill the meter; a cell is not 4 to 8 bars; its voices differ in length or one is missing |
| `range` | the lead leaves D4 to D6; another voice leaves its instrument's range |
| `leap` | the lead jumps more than an octave |
| `cadence` | a cell ends off the pentatonic or on the tonic; the ending cell does not land on the tonic |
| `motif` | no cell quotes the Pofu motif's shape (`score/motif.abc`: up two scale steps, up three, down one) |
| `rest` | the lead rests for less than a fifth of a cell |
| `density` | a bar holds more than eight lead notes |
| `semitone` | lead and bed hold a semitone apart on a strong beat |

Audio, per cell, on the samples before encoding: `loudness` (-20 LUFS,
within 0.5), `peak` (true peak at or under -1 dBTP), `low` (under 45 % of
the energy below 250 Hz), `tail` (the last quarter second below -50 dBFS),
`aligned` (stems one length, adding up to the mix), and `size` (24 MB for
all the music).

Every defect the founder's ear finds becomes a rule here, with its fixture.

## What nobody has checked

No agent can hear. The numbers say the files are level, clean and in the
mode; the roll says the tune rests, repeats and moves. Whether a tune is
lovely is the founder's to say (the spec's gate 2).
