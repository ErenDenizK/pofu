"""The band: eight instruments made from numbers (music-system-v1 D3).

    kalimba      a tine: Home's lead                (from tools/sound/render.py)
    music_box    a comb tooth: bright, long, small
    felt_keys    a soft piano with the lid down
    nylon_pluck  a nylon string, plucked
    whistle      a breathy whistle, the ocarina's cousin
    pad          a soft additive pad                (from tools/sound/render.py)
    bass         a round bass
    tok, shaker  small percussion                   (the tok from tools/sound/render.py)

Every instrument is `play(midi, seconds, velocity, rng) -> samples`: mono, 48 kHz,
starting and ending at silence. `seconds` is the written length of the note; a
struck instrument rings past it and a held one releases after it. Each is
levelled so that its reference note, at velocity 1, reads REFERENCE_LUFS on the
momentary meter (the percussion PERCUSSION_LUFS); the mix balance is then a
column of plain decibels in the table below, which a score may override per
voice (`gain=`).

The kalimba, the pad and the wood tok are not copied here: they are the
functions the cues already ship with, so a cue and a tune stay one instrument.
"""

from __future__ import annotations

import dataclasses
import importlib.util
import sys
from pathlib import Path
from typing import Callable

import numpy as np

_SOUND = Path(__file__).resolve().parents[1] / "sound" / "render.py"


def _load_sound():
    name = "pofu_sound_render"
    if name in sys.modules:
        return sys.modules[name]
    spec = importlib.util.spec_from_file_location(name, _SOUND)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module          # dataclasses look their module up while it loads
    spec.loader.exec_module(module)
    return module


sound = _load_sound()
SR = sound.SR
REFERENCE_LUFS = -18.0
PERCUSSION_LUFS = -24.0        # a tok is over in a blink; at -18 it would clip


def _hz(midi: float) -> float:
    return sound.midi_hz(midi)


def _t(seconds: float) -> np.ndarray:
    return sound.t_axis(seconds)


def _close(x: np.ndarray, fade: float = 0.03) -> np.ndarray:
    """End at silence: a short raised-cosine fade over the last `fade` seconds."""
    n = min(len(x), int(fade * SR))
    if n:
        x = x.copy()
        x[-n:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, n))
    return x


# --------------------------------------------------------------------------
# The instruments, before levelling

def _kalimba(midi, seconds, rng):
    ring = float(np.clip(seconds * 1.6, 1.0, 2.2))
    return sound.kalimba(_hz(midi), ring, 1.0, rng)


def _music_box(midi, seconds, rng):
    """A steel comb tooth: a pure, long fundamental, the bar's own inharmonic
    partials dying fast above it, and the pin's tick."""
    f = _hz(midi)
    ring = float(np.clip(seconds * 2.0, 1.4, 3.0))
    t = _t(ring)
    tau = 0.75 * (523.25 / f) ** 0.35
    x = np.exp(-t / tau) * np.sin(2 * np.pi * f * t)
    x += 0.30 * np.exp(-t / (tau * 0.45)) * np.sin(2 * np.pi * 2.0 * f * t)
    x += 0.16 * np.exp(-t / (tau * 0.12)) * np.sin(2 * np.pi * 6.27 * f * t)
    if 17.55 * f < 0.45 * SR:
        x += 0.05 * np.exp(-t / 0.012) * np.sin(2 * np.pi * 17.55 * f * t)
    tick = sound.bandpass(sound.white(rng, ring), 3000, 7000) * np.exp(-t / 0.002) * 0.12
    return _close((x * np.clip(t / 0.001, 0, 1) + tick) * sound.env_asr(ring, 0, ring * 0.35))


def _felt_keys(midi, seconds, rng):
    """A piano behind felt: a soft hammer, few harmonics, the string a little
    stiff, damped when the key comes up."""
    f = _hz(midi)
    held = max(seconds, 0.12)
    total = held + 0.35
    t = _t(total)
    tau = 1.5 * (261.63 / f) ** 0.5
    x = np.zeros_like(t)
    for k in range(1, 9):
        fk = k * f * np.sqrt(1 + 0.0004 * k * k)
        if fk > 5000:
            break
        x += (1 / k ** 2.1) * np.exp(-t * (1 + 0.45 * (k - 1)) / tau) * np.sin(
            2 * np.pi * fk * t + rng.uniform(0, 0.4))
    hammer = sound.lowpass(sound.white(rng, total), 900) * np.exp(-t / 0.012) * 0.10
    attack = 0.5 - 0.5 * np.cos(np.pi * np.clip(t / 0.009, 0, 1))
    damper = np.exp(-np.clip(t - held, 0, None) / 0.07)
    return _close((x * attack + hammer) * damper)


def _nylon_pluck(midi, seconds, rng):
    """A nylon string plucked a fifth of the way along: the harmonics a pluck
    there leaves out are left out, and the high ones die first."""
    f = _hz(midi)
    ring = float(np.clip(seconds * 1.5, 1.2, 2.4))
    t = _t(ring)
    tau = 0.9 * (220.0 / f) ** 0.4
    x = np.zeros_like(t)
    for k in range(1, 15):
        if k * f > 7000:
            break
        amp = np.sin(np.pi * k * 0.2) / k ** 1.25
        x += amp * np.exp(-t * (1 + 0.28 * (k - 1) ** 1.3) / tau) * np.sin(2 * np.pi * k * f * t)
    nail = sound.bandpass(sound.white(rng, ring), 900, 3200) * np.exp(-t / 0.004) * 0.10
    body = 0.06 * np.exp(-t / 0.05) * np.sin(2 * np.pi * 110 * t)
    return _close((x + body) * np.clip(t / 0.0015, 0, 1) + nail * np.clip(t / 0.0005, 0, 1),
                  0.05) * sound.env_asr(ring, 0, ring * 0.3)


def _whistle(midi, seconds, rng):
    """A breathy whistle: nearly a sine, a breath around the pitch, a chiff at
    the start and a slow vibrato that arrives late."""
    f = _hz(midi)
    held = max(seconds, 0.18)
    total = held + 0.16
    t = _t(total)
    vibrato = 0.004 * np.clip((t - 0.25) / 0.3, 0, 1) * np.sin(2 * np.pi * 5.2 * t)
    scoop = -0.012 * np.exp(-t / 0.03)
    freq = f * (1 + vibrato + scoop)
    tone = sound.osc(freq, total) + 0.10 * sound.osc(2 * freq, total) + 0.03 * sound.osc(3 * freq, total)
    noise = sound.white(rng, total)
    breath = sound.bandpass(noise, f * 0.8, min(f * 2.6, 9000)) * 0.20
    chiff = sound.bandpass(noise, 1800, 6000) * np.exp(-t / 0.025) * 0.18
    env = np.clip(t / 0.05, 0, 1) ** 1.5 * np.clip((total - t) / 0.16, 0, 1) ** 2
    swell = 1 + 0.06 * np.sin(2 * np.pi * 5.2 * t + 1.0) * np.clip((t - 0.25) / 0.3, 0, 1)
    return _close((tone * swell + breath + chiff) * env, 0.02)


def _pad(midi, seconds, rng):
    held = max(seconds, 0.6)
    attack = min(0.6, held * 0.35)
    release = 0.9
    return sound.pad_voice(_hz(midi), held + release, attack, release, 0.5, rng)


def _bass(midi, seconds, rng):
    """A round bass: a sine and two harmonics a phone speaker can find, a soft
    start, a slow sag while it is held."""
    f = _hz(midi)
    held = max(seconds, 0.15)
    total = held + 0.18
    t = _t(total)
    x = np.sin(2 * np.pi * f * t) + 0.32 * np.sin(2 * np.pi * 2 * f * t) + 0.12 * np.sin(2 * np.pi * 3 * f * t)
    attack = 0.5 - 0.5 * np.cos(np.pi * np.clip(t / 0.018, 0, 1))
    sag = 0.55 + 0.45 * np.exp(-t / 0.7)
    release = np.clip((total - t) / 0.18, 0, 1) ** 2
    return _close(x * attack * sag * release, 0.01)


def _tok(midi, seconds, rng):
    name = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"][int(midi) % 12]
    return _close(sound.wood_tok(f"{name}{int(midi) // 12 - 1}", 0.3), 0.01)


def _shaker(midi, seconds, rng):
    """Seeds in a gourd: a band of noise that swells for a moment and falls."""
    total = 0.25
    t = _t(total)
    x = sound.bandpass(sound.white(rng, total), 4200, 9500)
    env = np.clip(t / 0.012, 0, 1) ** 2 * np.exp(-np.clip(t - 0.012, 0, None) / 0.03)
    return _close(x * env, 0.01)


# --------------------------------------------------------------------------
# The band

@dataclasses.dataclass(frozen=True)
class Instrument:
    name: str
    play_raw: Callable
    reference: int        # the MIDI note it is levelled at
    level: float          # the factor that puts the reference note at `target`
    target: float         # REFERENCE_LUFS, or PERCUSSION_LUFS
    struck: bool          # True: rings and dies by itself. False: held, then released
    low: int              # the range it is written in
    high: int
    gain_db: float        # its place in the mix, when the score does not say

    def play(self, midi: int, seconds: float, velocity: float = 1.0,
             rng: np.random.Generator | None = None) -> np.ndarray:
        rng = rng or np.random.default_rng(1000 + int(midi))
        return velocity * self.level * self.play_raw(midi, seconds, rng)


# name: (function, reference note, level, struck, low, high, mix gain in dB)
_TABLE = {
    "kalimba":     (_kalimba, 69, 1.0, True, 57, 88, 0.0),
    "music_box":   (_music_box, 81, 1.0, True, 62, 93, -1.0),
    "felt_keys":   (_felt_keys, 69, 1.0, False, 45, 86, -9.0),
    "nylon_pluck": (_nylon_pluck, 69, 1.0, True, 45, 86, -2.0),
    "whistle":     (_whistle, 74, 1.0, False, 62, 93, -3.0),
    "pad":         (_pad, 57, 1.0, False, 43, 76, -13.0),
    "bass":        (_bass, 45, 1.0, False, 33, 57, -10.0),
    "tok":         (_tok, 74, 1.0, True, 60, 86, -8.0),
    "shaker":      (_shaker, 74, 1.0, True, 0, 127, -14.0),
}
# The levels, measured once by `python3 tools/music/band.py` (the run is seeded) and
# checked by tests/test_band.py.
_LEVELS: dict[str, float] = {
    "kalimba": 0.2639,
    "music_box": 0.2328,
    "felt_keys": 0.2212,
    "nylon_pluck": 0.327,
    "whistle": 0.1887,
    "pad": 0.1085,
    "bass": 0.2272,
    "tok": 0.376,
    "shaker": 0.422,
}

PERCUSSION = ("tok", "shaker")
BAND = {name: Instrument(name, fn, ref, _LEVELS.get(name, level),
                         PERCUSSION_LUFS if name in PERCUSSION else REFERENCE_LUFS, struck, low, high, gain)
        for name, (fn, ref, level, struck, low, high, gain) in _TABLE.items()}


def reference_lufs(instrument: Instrument, midi: int | None = None) -> float:
    """The momentary loudness of one half-second note at velocity 1."""
    x = instrument.play(instrument.reference if midi is None else midi, 0.5, 1.0)
    return sound.lufs_momentary_max(x)


def _measure_levels() -> dict[str, float]:
    out = {}
    for name, instrument in BAND.items():
        raw = dataclasses.replace(instrument, level=1.0)
        out[name] = round(10 ** ((instrument.target - reference_lufs(raw)) / 20), 4)
    return out


if __name__ == "__main__":
    for name, level in _measure_levels().items():
        print(f'    "{name}": {level},')
