# tools/sound

`render.py` renders Pofu's sound proof from numbers: no samples, no network,
fixed seeds. The reasoning (when sound plays, the micro-sound list, the
island keys and the iOS path) is in
[`docs/design/sound-identity.md`](../../docs/design/sound-identity.md).

```sh
pip install -r tools/sound/requirements.txt   # numpy, scipy; matplotlib optional
python3 tools/sound/render.py                 # needs ffmpeg on PATH
```

It writes to `design/sound/proof/`:

| File | What it is |
|---|---|
| `pofu-poke.wav` … `pofu-chew.wav` | Six of Pofu's micro-sounds (stand-ins; the vocal ones get a performer) |
| `ui-tok.wav`, `skip-chime.wav` | A station tap and the skip / build-settle chime |
| `arrival-harbor.wav` | İskele's arrival cue, built from the island's motif |
| `island-*.m4a` | 30-second seamless island loops: Ayçiçeği at calm ×1.0 and ×2.0, Yıldız at night, Kaplıca in the evening |
| `levels.json` | The measurements below, per file |
| `spectrograms.png` | A contact sheet, 0–10 kHz, to eyeball clicks and harshness |

Every file is measured after rendering, and the run fails if one breaks a
limit:

- true peak (4× oversampled) ≤ −1 dBTP;
- micro-sounds: loudest 400 ms window at −18 LUFS (peak-limited transients
  may sit lower), first and last sample at zero, decayed below −45 dBFS
  in the last 20 ms, under 5 % of energy above 6 kHz, under half below
  250 Hz (a phone speaker loses it);
- loops: −20 LUFS integrated (ITU-R BS.1770-4, gated), no moment more than
  6 LU above that, the loop seam no larger than a typical sample step
  (measured before AAC encoding), under 45 % of energy below 250 Hz;
- every file under 1 MB.

The loudness meter checks itself against BS.1770's reference (a 997 Hz
sine at 0 dBFS reads −3.01 LUFS) before it measures anything.

Nobody has listened to these yet: the agent environment has no speakers.
The numbers say they are clean, level and loopable; only ears can say they
are charming.

## Game cues for the app

```sh
python3 tools/sound/render.py --cues
```

renders the 30 cues `PofuSound` plays (seed-pop ladder, bloom ladder, combo
rise, piece pickup/snap/drop/put-back, deal, cheek, round end, collect, skip
chime, hop, gulp) as mono 32 kHz CAF files into
`Packages/PofuKit/Sources/PofuSound/Resources/`, under the same micro-sound
limits (≤ −1 dBTP, −18 LUFS momentary, clean edges) plus 100 KB per file.
A few are also written as WAV to `design/sound/proof/cues/` for listening.
The file names are `SoundCue.assetName`; a test checks every cue has a file.
Vocal sounds stay synthesized placeholders until a performer records them.

## World sound pass: `world.py`

`python3 tools/sound/world.py` renders the world's cues and ambience into
`Packages/PofuKit/Sources/PofuSound/Resources/` (each file under 50 KB, the
run fails otherwise): `level-up`, `door-knock`, `kettle`, `water-wheel`,
`water-splash`, `water-pour` (32 kHz cues); `ambience-wind`, `-crickets`,
`-rain`, `-hush` (8 kHz, 3 s, periodic by construction so the loop has no
seam); `gull-0`, `gull-1`; `breath-pad` (a 1 s loop the app bends upward on
the in-breath and back down on the out-breath). Nobody has listened yet.
