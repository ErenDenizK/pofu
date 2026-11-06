#!/usr/bin/env python3
"""Renders the world's sound pass: five world cues, the ambience loops and
the breath pad, into Packages/PofuKit/Sources/PofuSound/Resources/.

Everything is synthesized from numbers (no samples, fixed seeds). Reuses the
building blocks of render.py. Every file must stay under 50 KB.

    python3 tools/sound/world.py          # needs numpy, scipy, ffmpeg

World cues (32 kHz mono, the engine's pool format, mastered like the other
cues): level-up, door-knock, kettle, water-wheel, water-splash, water-pour.
Ambience (8 kHz mono, one seamless 3 s loop each, periodic by construction,
so there is no seam to measure): ambience-wind, -crickets, -rain, -hush.
One-shots on the same bus: gull-0, gull-1. The breath pad: breath-pad, a
1 s loop the engine bends upward over the in-breath and back down over the
out-breath. Ambience files are peak-normalised to -3 dBFS; the runtime gain
is the mix (PofuSound.AmbienceLevels).
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import render as R  # noqa: E402

OUT = R.CUES_OUT
AR = 8_000          # ambience sample rate
LOOP_SECONDS = 3.0
MAX_BYTES = 50_000


# --------------------------------------------------------------------------
# World cues (48 kHz building blocks, resampled to 32 kHz by ffmpeg)

def w_level_up(rng):
    """The Pofu motif: four kalimba notes climbing the pentatonic ladder."""
    out = R.silence(0.74)
    for i, n in enumerate(["D5", "F#5", "A5", "B5"]):
        R.place(out, R.kalimba(n, 0.55 if i == 3 else 0.3, 0.75 + 0.08 * i, rng), 0.085 * i, 1.0)
    return out


def w_door_knock(rng):
    """Two soft knocks on wood: a low modal tok, then a slightly lower one."""
    out = R.silence(0.62)
    for i, (note, at, g) in enumerate([("D3", 0.0, 1.0), ("C3", 0.22, 0.8)]):
        R.place(out, R.wood_tok(note, 0.2), at, g)
        R.place(out, R.felt_thump(rng, 0.12, cutoff=900, pitch=(150, 95)), at, 0.5 * g)
    return out


def w_kettle(rng):
    """A kettle coming up to the whistle: a rising airy tone, then a held note."""
    d = 0.72
    f = R.glide(1250, 1980, d, curve=0.5)
    tone = R.osc(f, d) + 0.18 * R.osc(2 * f, d)
    tone *= 1 + 0.04 * R.osc(7.0, d)
    steam = R.bandpass(R.white(rng, d), 2600, 6200) * 0.5
    return (tone * 0.6 + steam * 0.35) * R.env_asr(d, 0.14, 0.2)


def w_water_wheel(rng):
    """A wooden wheel catching: a creak and a slosh."""
    d = 0.42
    creak = R.osc(R.glide(180, 260, d), d) * (1 + 0.5 * R.osc(31.0, d))
    creak = R.bandpass(creak + 0.4 * R.osc(R.glide(360, 520, d), d), 160, 900)
    slosh = R.bandpass(R.pink(rng, d), 400, 2400) * R.env_asr(d, 0.1, 0.18)
    return 0.7 * creak * R.env_asr(d, 0.04, 0.15) + 0.5 * slosh / (np.max(np.abs(slosh)) + 1e-9)


def w_water_splash(rng):
    d = 0.36
    n = R.bandpass(R.white(rng, d), 900, 5200) * R.env_ar(d, 0.004, 0.07)
    drip = R.osc(R.glide(900, 1700, 0.09), 0.09) * R.env_ar(0.09, 0.002, 0.03)
    out = n / (np.max(np.abs(n)) + 1e-9) * 0.7
    R.place(out, drip, 0.03, 0.5)
    return out


def w_water_pour(rng):
    """The full pour: a gush that settles into three pentatonic notes."""
    out = R.silence(0.72)
    gush = R.bandpass(R.pink(rng, 0.5), 500, 3800) * R.env_asr(0.5, 0.1, 0.25)
    R.place(out, gush / (np.max(np.abs(gush)) + 1e-9), 0.0, 0.55)
    for i, n in enumerate(["D5", "A5", "D6"]):
        R.place(out, R.kalimba(n, 0.5, 0.75, rng), 0.2 + 0.1 * i, 0.9)
    return out


CUES = {
    "level-up": w_level_up,
    "door-knock": w_door_knock,
    "kettle": w_kettle,
    "water-wheel": w_water_wheel,
    "water-splash": w_water_splash,
    "water-pour": w_water_pour,
}


def encode(wav: Path, path: Path, rate: int) -> None:
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-ar", str(rate), "-ac", "1",
                    "-c:a", "pcm_s16le", "-f", "caf", str(path)], check=True)


def render_cues() -> list[str]:
    problems = []
    tmp = OUT / "_world.tmp.wav"
    for i, (name, fn) in enumerate(CUES.items()):
        x = R.master_micro(np.concatenate([fn(np.random.default_rng(900 + i)), R.silence(0.02)]))
        R.write_wav(tmp, x)
        path = OUT / f"{name}.caf"
        encode(tmp, path, R.CUE_SR)
        problems += check(path, f"{x.size / R.SR:.2f}s")
    tmp.unlink()
    return problems


# --------------------------------------------------------------------------
# Ambience at 8 kHz, periodic by construction

N = int(AR * LOOP_SECONDS)
T = np.arange(N) / AR


def periodic_noise(rng, shape) -> np.ndarray:
    """Noise whose spectrum is `shape(f)`; random phases make the inverse
    transform exactly periodic over the loop, so the seam cannot click."""
    f = np.fft.rfftfreq(N, 1 / AR)
    phase = rng.uniform(0, 2 * np.pi, f.size)
    spectrum = shape(f) * np.exp(1j * phase)
    spectrum[0] = 0
    x = np.fft.irfft(spectrum, N)
    return x / (np.std(x) + 1e-12)


def cycles(k: float, phase: float = 0.0) -> np.ndarray:
    """A sine with `k` whole cycles per loop."""
    return np.sin(2 * np.pi * k * T / LOOP_SECONDS + phase)


def finish(x: np.ndarray) -> np.ndarray:
    x = x - np.mean(x)
    return x / (np.max(np.abs(x)) + 1e-12) * 10 ** (-3 / 20)


def a_wind(rng):
    body = periodic_noise(rng, lambda f: (f / 140) ** 0.8 / (1 + (f / 420) ** 3.0))
    gust = 1 + 0.28 * cycles(1, 0.7) + 0.12 * cycles(3, 2.0)
    return finish(body * gust)


def a_hush(rng):
    body = periodic_noise(rng, lambda f: 1 / (1 + (f / 260) ** 2.2) * (f / 60) ** 0.5)
    return finish(body * (1 + 0.08 * cycles(1, 1.1)))


def a_rain(rng):
    bed = periodic_noise(rng, lambda f: (f / 900) ** 1.2 / (1 + (f / 2600) ** 4.0))
    drops = np.zeros(N)
    for _ in range(int(AR * LOOP_SECONDS / 150)):  # about 55 leaf taps per loop
        at = int(rng.integers(0, N))
        length = int(AR * rng.uniform(0.006, 0.014))
        k = np.arange(length)
        tick = np.sin(2 * np.pi * rng.uniform(1500, 3300) * k / AR) * np.exp(-k / (length * 0.25))
        for j, v in enumerate(tick):
            drops[(at + j) % N] += v * rng.uniform(0.3, 1.0)
    return finish(0.8 * bed / np.max(np.abs(bed)) + 0.5 * drops / (np.max(np.abs(drops)) + 1e-9))


def a_crickets(rng):
    out = np.zeros(N)
    # (centre Hz, chirps per loop, level): whole numbers, so the loop closes.
    for centre, chirps, level in [(2650, 9, 0.9), (2900, 10, 0.7), (3150, 7, 0.55)]:
        offset = rng.uniform(0, 1)
        for c in range(chirps):
            start = ((c + offset) / chirps) * N
            for p in range(3):  # three pulses per chirp
                at = int(start + p * AR * 0.026)
                length = int(AR * 0.014)
                k = np.arange(length)
                pulse = np.sin(2 * np.pi * centre * k / AR) * np.sin(np.pi * k / length) ** 2
                idx = (at + k) % N
                out[idx] += level * pulse
    out += 0.02 * periodic_noise(rng, lambda f: (f > 1500) * (f < 3600) * 1.0)
    return finish(out * (1 + 0.15 * cycles(1, 0.3)))


def a_gull(variant: int):
    """Two cries: a falling 'ee-ow' with a breathy edge, low-passed under 3.6 kHz."""
    rng = np.random.default_rng(40 + variant)
    d = 1.1
    n = int(AR * d)
    t = np.arange(n) / AR
    out = np.zeros(n)
    cries = [(0.02, 0.42, 1500, 1050), (0.5, 0.5, 1380, 900)] if variant == 0 else [(0.05, 0.36, 1650, 1150), (0.46, 0.3, 1450, 1000), (0.78, 0.28, 1300, 880)]
    for start, length, f0, f1 in cries:
        m = int(AR * length)
        k = np.arange(m) / AR
        x = np.linspace(0, 1, m)
        f = f0 * (f1 / f0) ** x * (1 + 0.025 * np.sin(2 * np.pi * 24 * k))
        phase = 2 * np.pi * np.cumsum(f) / AR
        tone = np.sin(phase) + 0.55 * np.sin(2 * phase) + 0.2 * np.sin(3 * phase)
        env = np.sin(np.pi * np.clip(x, 0, 1)) ** 0.8
        i = int(AR * start)
        out[i:i + m] += tone * env * (0.9 + 0.2 * rng.random())
    from scipy import signal
    sos = signal.butter(4, 3600, btype="lowpass", fs=AR, output="sos")
    out = signal.sosfilt(sos, out)
    out *= np.clip(t / 0.01, 0, 1) * np.clip((d - t) / 0.03, 0, 1)
    return out / (np.max(np.abs(out)) + 1e-12) * 10 ** (-3 / 20)


def a_breath_pad():
    """A soft D chord, 1 s loop (whole-Hz partials)."""
    t = np.arange(AR) / AR
    x = sum(a * np.sin(2 * np.pi * f * t + p) for f, a, p in
            [(147, 1.0, 0.0), (148, 0.6, 1.3), (220, 0.8, 2.1), (294, 0.7, 0.4), (370, 0.35, 3.0), (440, 0.25, 5.0)])
    return x / np.max(np.abs(x)) * 10 ** (-3 / 20)


def write_caf(x: np.ndarray, path: Path) -> None:
    tmp = OUT / "_amb.tmp.wav"
    import wave
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(str(tmp), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(AR)
        w.writeframes(pcm.tobytes())
    encode(tmp, path, AR)
    tmp.unlink()


def render_ambience() -> list[str]:
    problems = []
    items = {
        "ambience-wind": a_wind(np.random.default_rng(11)),
        "ambience-hush": a_hush(np.random.default_rng(12)),
        "ambience-rain": a_rain(np.random.default_rng(13)),
        "ambience-crickets": a_crickets(np.random.default_rng(14)),
        "gull-0": a_gull(0),
        "gull-1": a_gull(1),
        "breath-pad": a_breath_pad(),
    }
    for name, x in items.items():
        path = OUT / f"{name}.caf"
        write_caf(x, path)
        problems += check(path, f"{x.size / AR:.2f}s")
        if name.startswith("ambience"):
            seam = abs(x[0] - x[-1]) / (np.percentile(np.abs(np.diff(x)), 99) + 1e-12)
            if seam > 1.5:
                problems.append(f"{name}: loop seam {seam:.2f}")
    return problems


def check(path: Path, label: str) -> list[str]:
    size = path.stat().st_size
    print(f"{path.name:24} {label:>7} {size / 1000:6.1f} KB")
    return [f"{path.name}: {size} bytes over {MAX_BYTES}"] if size > MAX_BYTES else []


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    problems = render_cues() + render_ambience()
    for p in problems:
        print("PROBLEM:", p, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
