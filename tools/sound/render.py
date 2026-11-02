#!/usr/bin/env python3
"""Render Pofu's sound proof: micro-sounds, an arrival cue, and island loops.

Everything is synthesized offline from numbers (no samples, no network):
filtered noise for breath and felt, modal synthesis for wood and kalimba,
additive pads for the island music. See docs/design/sound-identity.md.

    pip install -r tools/sound/requirements.txt
    python3 tools/sound/render.py      # writes design/sound/proof/, then measures it

The run is deterministic (fixed seeds). Each file is measured after
rendering: true peak (4x oversampled), loudness (ITU-R BS.1770-4, K-weighted,
gated), spectral centroid, energy above 6 kHz, DC offset, and the edges
(a file must start and end in silence, so it never clicks). The script exits
non-zero if a file breaks a limit.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import subprocess
import sys
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from scipy import signal

SR = 48_000
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "design" / "sound" / "proof"

# Targets (docs/design/sound-identity.md, section 6).
TRUE_PEAK_CEILING_DB = -1.0
MICRO_MOMENTARY_LUFS = -18.0  # loudest 400 ms window of a micro-sound
LOOP_INTEGRATED_LUFS = -20.0  # whole loop, gated
MAX_FILE_BYTES = 1_000_000


# --------------------------------------------------------------------------
# Pitch: everything tonal sits on D major pentatonic plus the island's mode.

NOTE_INDEX = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6,
              "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(note: str) -> float:
    """'F#5' -> frequency in Hz (A4 = 440)."""
    name, octave = note[:-1], int(note[-1])
    midi = 12 * (octave + 1) + NOTE_INDEX[name]
    return 440.0 * 2 ** ((midi - 69) / 12)


def midi_hz(midi: float) -> float:
    return 440.0 * 2 ** ((midi - 69) / 12)


# --------------------------------------------------------------------------
# Building blocks

def t_axis(seconds: float) -> np.ndarray:
    return np.arange(int(round(seconds * SR))) / SR


def silence(seconds: float) -> np.ndarray:
    return np.zeros(int(round(seconds * SR)))


def osc(freq: np.ndarray | float, seconds: float, phase: float = 0.0) -> np.ndarray:
    """Sine with a (possibly time-varying) frequency, by phase accumulation."""
    n = int(round(seconds * SR))
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,))
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def glide(f0: float, f1: float, seconds: float, curve: float = 1.0) -> np.ndarray:
    """Exponential glide from f0 to f1; curve > 1 lingers near f0."""
    x = np.linspace(0, 1, int(round(seconds * SR))) ** curve
    return f0 * (f1 / f0) ** x


def env_ar(seconds: float, attack: float, release_tau: float) -> np.ndarray:
    """Raised-cosine attack, then exponential decay."""
    t = t_axis(seconds)
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    a = 0.5 - 0.5 * np.cos(np.pi * a)
    d = np.exp(-np.clip(t - attack, 0, None) / release_tau)
    return a * d


def env_asr(seconds: float, attack: float, release: float) -> np.ndarray:
    """Raised-cosine attack, hold, raised-cosine release."""
    n = int(round(seconds * SR))
    e = np.ones(n)
    na, nr = int(attack * SR), int(release * SR)
    if na:
        e[:na] = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, na))
    if nr:
        e[-nr:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, nr))
    return e


def white(rng: np.random.Generator, seconds: float) -> np.ndarray:
    return rng.standard_normal(int(round(seconds * SR)))


def pink(rng: np.random.Generator, seconds: float) -> np.ndarray:
    """1/f noise by spectral shaping, unit RMS."""
    n = int(round(seconds * SR))
    spectrum = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = f[1]
    x = np.fft.irfft(spectrum / np.sqrt(f), n)
    return x / (np.std(x) + 1e-12)


def bandpass(x: np.ndarray, lo: float, hi: float, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, [lo, hi], btype="bandpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, cutoff, btype="lowpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def highpass(x: np.ndarray, cutoff: float, order: int = 2) -> np.ndarray:
    sos = signal.butter(order, cutoff, btype="highpass", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def sweep_lowpass(x: np.ndarray, start: float, end: float, blocks: int = 64) -> np.ndarray:
    """A low-pass whose cutoff glides; block-wise with carried filter state."""
    out = np.zeros_like(x)
    edges = np.linspace(0, len(x), blocks + 1).astype(int)
    cutoffs = start * (end / start) ** np.linspace(0, 1, blocks)
    zi = None
    for i in range(blocks):
        sos = signal.butter(2, cutoffs[i], btype="lowpass", fs=SR, output="sos")
        if zi is None:
            zi = np.zeros((sos.shape[0], 2))
        out[edges[i]:edges[i + 1]], zi = signal.sosfilt(sos, x[edges[i]:edges[i + 1]], zi=zi)
    return out


def place(buffer: np.ndarray, sound: np.ndarray, at: float, gain: float = 1.0) -> None:
    """Mix `sound` into `buffer` at `at` seconds (clipped to the buffer)."""
    start = int(round(at * SR))
    end = min(len(buffer), start + len(sound))
    if start < len(buffer):
        buffer[start:end] += gain * sound[: end - start]


def place_wrapped(buffer: np.ndarray, sound: np.ndarray, at: float, gain: float = 1.0) -> None:
    """Like `place`, but the part past the end wraps to the start (loops)."""
    start = int(round(at * SR)) % len(buffer)
    idx = (start + np.arange(len(sound))) % len(buffer)
    np.add.at(buffer, idx, gain * sound)


def fade_edges(x: np.ndarray, fade_in: float = 0.003, fade_out: float = 0.02) -> np.ndarray:
    x = x.copy()
    ni, no = int(fade_in * SR), int(fade_out * SR)
    if ni:
        x[:ni] *= np.linspace(0, 1, ni)
    if no:
        x[-no:] *= np.linspace(1, 0, no) ** 2
    return x


def room_ir(rng: np.random.Generator, rt60: float, channels: int = 1,
            damping_hz: float = 5000.0, predelay: float = 0.012) -> np.ndarray:
    """A synthetic room: decorrelated noise with an exponential decay whose
    high end dies faster than its low end (two bands)."""
    n = int((rt60 + predelay) * SR)
    t = np.arange(n) / SR
    irs = []
    for _ in range(channels):
        noise = rng.standard_normal(n)
        lo = lowpass(noise, damping_hz / 3)
        hi = noise - lo
        decay = np.exp(-6.9 * t / rt60)
        decay_hi = np.exp(-6.9 * t / (rt60 * 0.45))
        ir = lo * decay + 0.5 * hi * decay_hi
        ir[: int(predelay * SR)] = 0
        irs.append(ir / np.sqrt(np.sum(ir ** 2)))
    return np.stack(irs)


def reverb(x: np.ndarray, ir: np.ndarray, wet: float) -> np.ndarray:
    """Mono in, len(ir) channels out, padded by the tail."""
    tail = ir.shape[1]
    dry = np.concatenate([x, np.zeros(tail)])
    out = []
    for ch in ir:
        out.append(dry * (1 - wet) + wet * signal.fftconvolve(dry, ch)[: len(dry)])
    return np.stack(out)


# --------------------------------------------------------------------------
# Instruments (offline stand-ins for recorded foley; section 3 of the doc)

def kalimba(note: str | float, seconds: float = 1.2, velocity: float = 1.0,
            rng: np.random.Generator | None = None) -> np.ndarray:
    """A tine: a long fundamental, a quick inharmonic overtone, a felt thunk."""
    f = hz(note) if isinstance(note, str) else note
    t = t_axis(seconds)
    body = np.exp(-t / 0.55) * np.sin(2 * np.pi * f * t)
    body += 0.12 * np.exp(-t / 0.25) * np.sin(2 * np.pi * 2 * f * t)
    body += 0.18 * np.exp(-t / 0.035) * np.sin(2 * np.pi * 5.93 * f * t)
    attack = np.clip(t / 0.002, 0, 1)
    rng = rng or np.random.default_rng(int(f))
    thunk = lowpass(white(rng, seconds), 1800) * np.exp(-t / 0.006) * 0.25
    resonance = 0.15 * np.exp(-t / 0.08) * np.sin(2 * np.pi * 240 * t)
    # Damp the tine over the last 40 % so a note never ends with a click.
    return velocity * (attack * body + thunk + resonance * attack) * env_asr(seconds, 0, seconds * 0.4)


def felt_thump(rng: np.random.Generator, seconds: float = 0.14, cutoff: float = 1400,
               pitch: tuple[float, float] = (190, 120), tau: float = 0.025) -> np.ndarray:
    """A soft object landing on felt: low-passed noise plus a dull body."""
    noise = lowpass(pink(rng, seconds), cutoff) * env_ar(seconds, 0.002, tau)
    body = osc(glide(*pitch, seconds), seconds) * env_ar(seconds, 0.003, tau * 1.6)
    return 0.7 * noise / (np.max(np.abs(noise)) + 1e-9) + 0.6 * body


def wood_tok(note: str = "D5", seconds: float = 0.16) -> np.ndarray:
    """Modal wood block: free-bar mode ratios, fast decays, a dry click."""
    f = hz(note)
    t = t_axis(seconds)
    modes = [(1.0, 1.0, 0.045), (2.756, 0.45, 0.022), (5.404, 0.18, 0.011), (8.933, 0.06, 0.006)]
    x = sum(a * np.exp(-t / tau) * np.sin(2 * np.pi * f * r * t) for r, a, tau in modes)
    click = lowpass(white(np.random.default_rng(7), seconds), 3500) * np.exp(-t / 0.0015) * 0.3
    return x * np.clip(t / 0.0008, 0, 1) + click


def squeak(f_start: float, f_end: float, seconds: float, breath: float,
           rng: np.random.Generator) -> np.ndarray:
    """A tiny voiced chirp: sine plus soft harmonics, a breathy edge."""
    f = glide(f_start, f_end, seconds, curve=0.6)
    tone = osc(f, seconds) + 0.22 * osc(2 * f, seconds) + 0.06 * osc(3 * f, seconds)
    air = bandpass(white(rng, seconds), 2200, 5200) * breath
    return (tone + air) * env_asr(seconds, 0.008, seconds * 0.45)


def pad_voice(f: float, seconds: float, attack: float, release: float,
              brightness: float, rng: np.random.Generator) -> np.ndarray:
    """A soft additive voice: two detuned stacks of decaying harmonics."""
    t = t_axis(seconds)
    x = np.zeros_like(t)
    for detune in (-0.0018, 0.0018):
        ff = f * (1 + detune)
        for k in range(1, 7):
            amp = (1 / k ** (2.4 - brightness)) * (1 if k == 1 else 0.8)
            x += amp * np.sin(2 * np.pi * k * ff * t + rng.uniform(0, 2 * np.pi))
    lfo = 1 + 0.12 * np.sin(2 * np.pi * rng.uniform(0.05, 0.13) * t + rng.uniform(0, 6.28))
    return x * lfo * env_asr(seconds, attack, release)



# --------------------------------------------------------------------------
# Pofu's micro-sounds (stand-ins; see the doc for which ones a voice replaces)

def s_poke(rng):
    """Felt 'pff' for a poke."""
    x = felt_thump(rng, 0.24, cutoff=1900, pitch=(340, 230), tau=0.022)
    puff = bandpass(pink(rng, 0.24), 400, 1400) * env_ar(0.24, 0.004, 0.03) * 0.3
    return x + puff


def s_sniff(rng):
    """Three quick sniffs: rising, the last a bit bigger (curious)."""
    out = silence(0.42)
    for i, (at, amp) in enumerate([(0.0, 0.6), (0.1, 0.75), (0.2, 1.0)]):
        d = 0.075
        n = bandpass(white(rng, d), 1800 + 250 * i, 5200 + 300 * i, order=3)
        n = sweep_lowpass(n, 3200, 6000, blocks=8) * env_asr(d, 0.018, 0.04)
        place(out, n, at, amp)
    return out


def s_giggle(rng):
    """Four descending chirps on the pentatonic: 'hi-hi-hi-hi'."""
    out = silence(0.5)
    notes = ["D6", "B5", "A5", "F#5"]
    for i, n in enumerate(notes):
        f = hz(n)
        chirp = squeak(f * 2 ** (1.5 / 12), f, 0.065, breath=0.12, rng=rng)
        h = bandpass(white(rng, 0.012), 2500, 6000) * env_asr(0.012, 0.003, 0.006) * 0.25
        place(out, h, 0.085 * i)
        place(out, chirp, 0.085 * i + 0.008, 1.0 - 0.13 * i)
    return out


def s_sleepy_sigh(rng):
    """A long out-breath with a little falling hum under it."""
    d = 0.75
    breath = bandpass(pink(rng, d), 250, 2600)
    breath = sweep_lowpass(breath, 2400, 500) * env_ar(d, 0.18, 0.22)
    hum_f = glide(hz("A4"), hz("F#4"), d, curve=1.6)
    hum = (osc(hum_f, d) + 0.25 * osc(2 * hum_f, d)) * env_ar(d, 0.12, 0.2) * 0.32
    return 0.8 * breath / (np.max(np.abs(breath)) + 1e-9) + hum


def s_hop(rng):
    """Take-off chirp up a fifth, then a plush landing."""
    out = silence(0.42)
    up = squeak(hz("D5"), hz("A5"), 0.09, breath=0.05, rng=rng) * 0.55
    place(out, up, 0.0)
    place(out, felt_thump(rng, 0.2, cutoff=1300, pitch=(280, 185), tau=0.028), 0.2, 0.9)
    return out


def s_chew(rng):
    """Nibbling a seed: five crisp nibbles, a soft mouth, a tiny swallow."""
    out = silence(0.62)
    at = 0.0
    for i in range(5):
        d = 0.02
        nib = bandpass(white(rng, d), 1400, 4800, order=3) * env_ar(d, 0.001, 0.005)
        place(out, nib, at, rng.uniform(0.6, 1.0) * (1 - 0.08 * i))
        at += rng.uniform(0.07, 0.095)
    mouth = lowpass(pink(rng, 0.5), 320) * (0.5 + 0.5 * np.sin(2 * np.pi * 12 * t_axis(0.5)))
    place(out, mouth * env_asr(0.5, 0.05, 0.15) * 0.18, 0.0)
    gulp = osc(glide(320, 210, 0.05), 0.05) * env_asr(0.05, 0.006, 0.03) * 0.35
    place(out, gulp, at + 0.06)
    return out


def s_tok(rng):
    """Station tap: a soft wooden tok on D5."""
    return wood_tok("D5", 0.3)


def s_skip_chime(rng):
    """The skip / build settle: three rising kalimba notes, D F# A."""
    out = silence(1.35)
    for i, n in enumerate(["D5", "F#5", "A5"]):
        place(out, kalimba(n, 1.1, 0.75 + 0.1 * i, rng), 0.11 * i)
    return out


ISKELE_MOTIF = [("A4", 0.0), ("B4", 0.13), ("D5", 0.26), ("C5", 0.42), ("D5", 0.6)]


def s_arrival_iskele(rng):
    """İskele's arrival: a wind swell under the cloud pass, the ferry's low
    horn (D3 + A3), the island motif on kalimba, a mixolydian cadence
    (C to D) resolving into the island's pad."""
    d = 3.0
    out = silence(d)
    wind = bandpass(pink(rng, 1.4), 250, 1600)
    wind = sweep_lowpass(wind, 500, 1800) * env_asr(1.4, 0.8, 0.55)
    place(out, 0.18 * wind / np.max(np.abs(wind)), 0.0)
    horn_d = 0.9
    horn = np.zeros(int(horn_d * SR))
    for n, a in (("D3", 1.0), ("A3", 0.6)):
        f = hz(n)
        for k in range(1, 6):
            horn += a / k ** 1.6 * osc(f * k * (1 + 0.0015 * (k % 2)), horn_d)
    horn = lowpass(horn, 650) * env_asr(horn_d, 0.15, 0.45)
    place(out, 0.22 * horn / np.max(np.abs(horn)), 0.35)
    for n, at in ISKELE_MOTIF:
        place(out, kalimba(n, 1.4 if at == 0.6 else 0.9, 0.7, rng), 0.75 + at)
    pad = sum(pad_voice(hz(n), 1.6, 0.5, 1.0, 0.6, rng) for n in ("D4", "A4", "E5", "F#5"))
    place(out, 0.05 * pad, 1.35)
    return out


MICRO = {
    "pofu-poke": s_poke,
    "pofu-sniff": s_sniff,
    "pofu-giggle": s_giggle,
    "pofu-sleepy-sigh": s_sleepy_sigh,
    "pofu-hop": s_hop,
    "pofu-chew": s_chew,
    "ui-tok": s_tok,
    "skip-chime": s_skip_chime,
    "arrival-iskele": s_arrival_iskele,
}


# --------------------------------------------------------------------------
# The island composer: key/mode, progression, calm opens the voicing.

@dataclass(frozen=True)
class Island:
    name: str
    tonic: int            # MIDI note of the tonic in octave 3
    scale: tuple          # semitones above the tonic (the mode)
    progression: tuple    # chords as scale-degree roots (0-based) with extra tones
    motif: tuple          # scale degrees, the island's four-to-five note idea
    melody_voice: str     # "kalimba" or "flute"
    bed: tuple            # (lo, hi) Hz of the air/water bed


# All modes contain D major pentatonic (D E F# A B), so any Pofu sound can
# overlap any island without clashing (design language §11, "One key").
D = 50  # D3
ISLANDS = {
    # D Ionian: I - IV - vi - Vsus  (Dadd9, Gmaj7, Bm7, Asus4)
    "aycicegi": Island("Ayçiçeği", D, (0, 2, 4, 5, 7, 9, 11),
                       ((0, 2, 4, 8), (3, 5, 7, 9), (5, 7, 9, 11), (4, 7, 8, 9)),
                       (0, 2, 4, 5), "kalimba", (300, 1400)),
    # D Lydian: I - II over a D pedal (Dmaj7, E/D): the floating night.
    "yildiz": Island("Yıldız", D, (0, 2, 4, 6, 7, 9, 11),
                     ((0, 2, 4, 6), (1, 3, 5, 7), (0, 4, 6, 8), (1, 3, 5, 8)),
                     (4, 6, 5, 2), "kalimba", (1800, 4200)),
    # D Mixolydian: I - bVII - IV - I (D, C, G, D): the harbor.
    "iskele": Island("İskele", D, (0, 2, 4, 5, 7, 9, 10),
                     ((0, 2, 4, 8), (6, 8, 10, 12), (3, 5, 7, 9), (0, 4, 7, 9)),
                     (4, 5, 7, 6, 7), "kalimba", (150, 700)),
    # B Dorian over the D-major-pentatonic core: i - IV (Bm9, E9).
    "kaplica": Island("Kaplıca", D - 3, (0, 2, 3, 5, 7, 9, 10),
                      ((0, 2, 4, 8), (3, 5, 7, 8), (0, 2, 4, 6), (3, 5, 7, 9)),
                      (4, 3, 2, 0), "flute", (120, 500)),
}


def degree_midi(island: Island, degree: int, octave: int = 0) -> int:
    n = len(island.scale)
    return island.tonic + 12 * (octave + degree // n) + island.scale[degree % n]


def voicing(island: Island, chord: tuple, calm: float) -> list[int]:
    """calm 1.0: root, fifth and third, close and low.
    calm 2.0: adds the 7th/9th colour tones and an upper-octave shimmer."""
    openness = (calm - 1.0)  # 0 ... 1
    root, third, fifth, colour = chord
    notes = [degree_midi(island, root, 0), degree_midi(island, fifth, 0),
             degree_midi(island, third, 1)]
    if openness >= 0.3:
        notes.append(degree_midi(island, colour, 1))
    if openness >= 0.7:
        notes.append(degree_midi(island, fifth, 2))
    return notes


@dataclass(frozen=True)
class Mood:
    calm: float = 1.0       # 1.0 ... 2.0 (game design §5)
    wellbeing: float = 0.7  # 0 ... 1: density and tempo only, never harmony
    hour: int = 14          # time of day sets register and brightness


def render_loop(island: Island, mood: Mood, seconds: float = 30.0, seed: int = 1) -> np.ndarray:
    """One seamless loop: four chords, a sparse melody from the motif, an
    air bed. The tail wraps to the start, so the end flows into the start."""
    rng = np.random.default_rng(seed)
    n = int(seconds * SR)
    pad = np.zeros(n)
    mel = np.zeros(n)
    openness = mood.calm - 1.0
    night = mood.hour >= 21 or mood.hour < 6
    morning = 6 <= mood.hour < 11
    chord_len = seconds / len(island.progression)

    # Pad: each chord fades in over 2.5 s and out across the next boundary.
    for i, chord in enumerate(island.progression):
        at = i * chord_len
        dur = chord_len + 3.0
        for j, m in enumerate(voicing(island, chord, mood.calm)):
            v = pad_voice(midi_hz(m), dur, 2.5, 3.0, 0.4 + 0.6 * openness, rng)
            # The root is felt more than heard: a phone speaker rolls off
            # under about 250 Hz, so the upper voices carry the chord.
            place_wrapped(pad, v, at, 0.55 if j == 0 else 1.0 / (1 + 0.15 * (m - island.tonic) / 12))
    cutoff = 800 + 2200 * openness
    if night:
        cutoff *= 0.7
    if morning:
        cutoff *= 1.15
    # Filter circularly: prime the filter with the end of the loop.
    pad = lowpass(np.concatenate([pad[-SR * 2:], pad]), cutoff, order=2)[SR * 2:]

    # Melody: a random walk that starts on the island's motif. Wellbeing
    # sets density (a tired Pofu means a sparser, slower island), calm adds
    # a few notes; the harmony never turns sad.
    density = (5 + 7 * openness) * (0.55 + 0.45 * mood.wellbeing) * (0.6 if night else 1.0)
    steps = max(3, int(round(density)))
    octave = 2 if not night else 1
    if morning:
        octave = 2
    degrees = list(island.motif)
    while len(degrees) < steps:
        last = degrees[-1]
        degrees.append(int(np.clip(last + rng.choice([-2, -1, 1, 1, 2]), -1, 9)))
    slots = np.sort(rng.choice(np.arange(int(seconds / 0.5) - 2), steps, replace=False)) * 0.5
    # Let the motif sound as a phrase: its first notes cluster.
    slots[: len(island.motif)] = 1.0 + np.arange(len(island.motif)) * 0.5
    slots = np.sort(slots)
    for deg, at in zip(degrees, slots):
        f = midi_hz(degree_midi(island, deg, octave))
        if island.melody_voice == "flute":
            note = breathy_flute_hz(f, 2.2, rng)
        else:
            note = kalimba(f, 2.0, rng.uniform(0.5, 0.8), rng)
        place_wrapped(mel, note, float(at) + rng.uniform(-0.03, 0.03))

    # A shimmer for full calm: soft high sines, like light on water.
    if openness >= 0.7:
        for _ in range(6):
            f = midi_hz(degree_midi(island, int(rng.choice([0, 2, 4])), 3))
            d = rng.uniform(2.5, 4.0)
            s = osc(f, d) * env_asr(d, d / 2, d / 2) * 0.05
            place_wrapped(mel, s, rng.uniform(0, seconds))

    # Bed: air for the meadow, a lapping sea for the harbor, a night hush.
    xf = int(0.5 * SR)  # the noise's own seam: crossfade its overhang into the start
    raw = bandpass(pink(rng, seconds + 2), *island.bed)[SR:SR + n + xf]
    bed = raw[:n].copy()
    bed[:xf] = raw[:xf] * np.sqrt(np.linspace(0, 1, xf)) + raw[n:] * np.sqrt(np.linspace(1, 0, xf))
    bed *= 1 + 0.5 * np.sin(2 * np.pi * (2 / seconds) * t_axis(seconds))  # loops exactly

    def norm(x):
        return x / (np.sqrt(np.mean(x ** 2)) + 1e-12)

    pad_gain = 0.5 / (np.sqrt(np.mean(pad ** 2)) + 1e-12)
    mono_pad = pad * pad_gain
    # Notes sit a fixed distance under the pad: one kalimba note peaks at
    # about the pad's RMS, so a sparse island is quieter, never louder.
    mono_mel = mel / 0.8 * 0.5 * (0.55 if not night else 0.4)
    mono_bed = norm(bed) * (0.05 if not night else 0.02)

    # Stereo: decorrelated circular reverb on pad and melody, width grows with calm.
    ir = room_ir(rng, 3.2 if not night else 4.5, channels=2)
    out = np.zeros((2, n))
    for src, wet, pan in ((mono_pad, 0.55, 0.0), (mono_mel, 0.45, 0.25), (mono_bed, 0.2, -0.2)):
        for ch in range(2):
            side = (1 - pan) if ch == 0 else (1 + pan)
            wet_sig = circular_convolve(src, ir[ch])
            out[ch] += side * 0.5 * ((1 - wet) * src + wet * wet_sig)
    width = 0.6 + 0.4 * openness
    mid, sidech = (out[0] + out[1]) / 2, (out[0] - out[1]) / 2
    return np.stack([mid + width * sidech, mid - width * sidech])


def breathy_flute_hz(f: float, seconds: float, rng) -> np.ndarray:
    t = t_axis(seconds)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 4.8 * t) * np.clip((t - 0.25) / 0.3, 0, 1)
    tone = osc(f * vib, seconds) + 0.18 * osc(2 * f * vib, seconds)
    air = bandpass(white(rng, seconds), f * 0.9, f * 3.0, order=4) * 0.2
    return (tone + air) * env_asr(seconds, 0.25, seconds * 0.55) * 0.8


def circular_convolve(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
    """Convolution whose tail wraps to the start: a loop's reverb continues
    across the seam."""
    y = signal.fftconvolve(x, ir)
    out = y[: len(x)].copy()
    tail = y[len(x):]
    while len(tail):
        k = min(len(tail), len(x))
        out[:k] += tail[:k]
        tail = tail[k:]
    return out


LOOPS = {
    "island-aycicegi-day-calm1.0": ("aycicegi", Mood(calm=1.0, wellbeing=0.7, hour=14), 11),
    "island-aycicegi-day-calm2.0": ("aycicegi", Mood(calm=2.0, wellbeing=0.9, hour=14), 11),
    "island-yildiz-night": ("yildiz", Mood(calm=1.5, wellbeing=0.7, hour=22), 23),
    "island-kaplica-evening": ("kaplica", Mood(calm=1.6, wellbeing=0.6, hour=19), 31),
}


# --------------------------------------------------------------------------
# Measurement

def k_weight(x: np.ndarray) -> np.ndarray:
    """ITU-R BS.1770-4 K-weighting at 48 kHz."""
    b1 = [1.53512485958697, -2.69169618940638, 1.19839281085285]
    a1 = [1.0, -1.69065929318241, 0.73248077421585]
    b2 = [1.0, -2.0, 1.0]
    a2 = [1.0, -1.99004745483398, 0.99007225036621]
    return signal.lfilter(b2, a2, signal.lfilter(b1, a1, x))



def _blocks_fast(x: np.ndarray, size: float = 0.4, hop: float = 0.1) -> np.ndarray:
    x = np.atleast_2d(x)
    nb, nh = int(size * SR), int(hop * SR)
    if x.shape[1] < nb:
        x = np.pad(x, ((0, 0), (0, nb - x.shape[1])))
    total = None
    for ch in x:
        sq = k_weight(ch) ** 2
        c = np.concatenate([[0.0], np.cumsum(sq)])
        starts = np.arange(0, len(sq) - nb + 1, nh)
        ms = (c[starts + nb] - c[starts]) / nb
        total = ms if total is None else total + ms
    return total


def lufs_integrated(x: np.ndarray) -> float:
    z = _blocks_fast(x)
    loud = -0.691 + 10 * np.log10(z + 1e-20)
    z = z[loud > -70]
    if not len(z):
        return -math.inf
    rel = -0.691 + 10 * np.log10(np.mean(z)) - 10
    z = z[-0.691 + 10 * np.log10(z) > rel]
    return float(-0.691 + 10 * np.log10(np.mean(z)))


def lufs_momentary_max(x: np.ndarray) -> float:
    z = _blocks_fast(x, 0.4, 0.01)
    return float(-0.691 + 10 * np.log10(np.max(z) + 1e-20))


def true_peak_db(x: np.ndarray) -> float:
    x = np.atleast_2d(x)
    peak = max(np.max(np.abs(signal.resample_poly(ch, 4, 1))) for ch in x)
    return float(20 * np.log10(peak + 1e-20))


def spectrum_stats(x: np.ndarray) -> tuple[float, float]:
    mono = np.mean(np.atleast_2d(x), axis=0)
    spec = np.abs(np.fft.rfft(mono * np.hanning(len(mono)))) ** 2
    f = np.fft.rfftfreq(len(mono), 1 / SR)
    total = np.sum(spec) + 1e-20
    centroid = float(np.sum(f * spec) / total)
    above = float(np.sum(spec[f > 6000]) / total)
    below = float(np.sum(spec[f < 250]) / total)
    return centroid, above, below


def self_test() -> None:
    """A 997 Hz sine at 0 dBFS reads -3.01 LUFS in mono (BS.1770)."""
    sine = np.sin(2 * np.pi * 997 * t_axis(5.0))
    got = lufs_integrated(sine)
    assert abs(got - (-3.01)) < 0.05, got
    stereo = 0.1 * np.stack([sine, sine])  # -20 dBFS sine on both channels
    assert abs(lufs_integrated(stereo) - (-20.0)) < 0.05


# --------------------------------------------------------------------------
# Mastering and files

def master_micro(x: np.ndarray) -> np.ndarray:
    x = highpass(x, 60)
    x = fade_edges(x)
    gain_db = MICRO_MOMENTARY_LUFS - lufs_momentary_max(x)
    x = x * 10 ** (gain_db / 20)
    tp = true_peak_db(x)
    if tp > TRUE_PEAK_CEILING_DB - 0.2:
        x *= 10 ** ((TRUE_PEAK_CEILING_DB - 0.2 - tp) / 20)
    return x


def master_loop(x: np.ndarray) -> np.ndarray:
    x = np.stack([highpass(np.concatenate([ch[-SR:], ch]), 90)[SR:] for ch in x])
    gain_db = LOOP_INTEGRATED_LUFS - lufs_integrated(x)
    x = x * 10 ** (gain_db / 20)
    tp = true_peak_db(x)
    if tp > TRUE_PEAK_CEILING_DB - 0.2:
        x *= 10 ** ((TRUE_PEAK_CEILING_DB - 0.2 - tp) / 20)
    return x


def write_wav(path: Path, x: np.ndarray) -> None:
    x = np.atleast_2d(x)
    pcm = np.clip(np.round(x.T * 32767), -32768, 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(x.shape[0])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def read_audio(path: Path) -> np.ndarray:
    """Decode any file to float stereo/mono at 48 kHz through ffmpeg."""
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
         "stream=channels", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True)
    channels = int(probe.stdout.strip())
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ar", str(SR), "-"],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype="<f4").reshape(-1, channels).T.astype(float)


def encode_m4a(wav: Path, m4a: Path, bitrate: str = "96k") -> None:
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-c:a", "aac",
                    "-b:a", bitrate, "-movflags", "+faststart", str(m4a)], check=True)


def seam_ratio(x: np.ndarray) -> float:
    """The jump across the loop point vs. a typical (p99) sample step."""
    step = np.abs(np.diff(x, axis=1))
    return float(np.max(np.abs(x[:, 0] - x[:, -1])) / (np.percentile(step, 99) + 1e-12))


def measure(path: Path, kind: str, master: np.ndarray | None = None) -> dict:
    x = read_audio(path)
    centroid, above, below = spectrum_stats(x)
    row = {
        "file": path.name,
        "kind": kind,
        "seconds": round(x.shape[1] / SR, 2),
        "bytes": path.stat().st_size,
        "true_peak_dbtp": round(true_peak_db(x), 2),
        "lufs_integrated": round(lufs_integrated(x), 2),
        "lufs_momentary_max": round(lufs_momentary_max(x), 2),
        "centroid_hz": round(centroid),
        "energy_above_6k_pct": round(100 * above, 2),
        "energy_below_250_pct": round(100 * below, 1),
        "dc_offset": round(float(np.max(np.abs(np.mean(x, axis=1)))), 5),
    }
    if kind == "micro":
        row["first_last_sample"] = round(float(max(np.max(np.abs(x[:, 0])), np.max(np.abs(x[:, -1])))), 5)
        tail_rms = np.sqrt(np.mean(x[:, -int(0.02 * SR):] ** 2))
        row["tail_dbfs"] = round(float(20 * np.log10(tail_rms + 1e-12)), 1)
    else:
        # Measured on the master before AAC: the encoder's priming and padding
        # are not part of the loop (sound-identity.md, section 5).
        row["seam_vs_p99_step"] = round(seam_ratio(master), 2) if master is not None else None
        row["loudness_range_lu"] = round(row["lufs_momentary_max"] - row["lufs_integrated"], 1)
    problems = []
    if row["true_peak_dbtp"] > TRUE_PEAK_CEILING_DB + 0.05:
        problems.append("true peak above -1 dBTP")
    if row["bytes"] > MAX_FILE_BYTES:
        problems.append("file over 1 MB")
    if row["seconds"] >= 0.5 and row["dc_offset"] > 0.002:
        problems.append("DC offset")
    if kind == "micro":
        peak_limited = row["true_peak_dbtp"] > TRUE_PEAK_CEILING_DB - 0.5
        if row["lufs_momentary_max"] > MICRO_MOMENTARY_LUFS + 1.0 or (
                row["lufs_momentary_max"] < MICRO_MOMENTARY_LUFS - 1.0 and not peak_limited):
            problems.append("momentary loudness off target")
        if row["first_last_sample"] > 0.001:
            problems.append("clicks: does not start/end at zero")
        if row["energy_below_250_pct"] > 50:
            problems.append("lost on a phone speaker: most energy below 250 Hz")
        if row["tail_dbfs"] > -45:
            problems.append("truncated: still sounding at the end")
        if row["energy_above_6k_pct"] > 5:
            problems.append("harsh: too much energy above 6 kHz")
    else:
        if abs(row["lufs_integrated"] - LOOP_INTEGRATED_LUFS) > 1.0:
            problems.append("integrated loudness off target")
        if row["seam_vs_p99_step"] is not None and row["seam_vs_p99_step"] > 1.0:
            problems.append("audible seam at the loop point")
        if row["energy_below_250_pct"] > 45:
            problems.append("lost on a phone speaker: too much energy below 250 Hz")
        if row["loudness_range_lu"] > 6.0:
            problems.append("uneven: a moment pokes out over 6 LU above the bed")
        if row["energy_above_6k_pct"] > 3:
            problems.append("harsh: too much energy above 6 kHz")
    row["problems"] = problems
    return row


def spectrogram_sheet(paths: list[Path], out: Path) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    cols = 3
    rows = math.ceil(len(paths) / cols)
    fig, axes = plt.subplots(rows, cols, figsize=(12, 2.6 * rows), squeeze=False)
    for ax, p in zip(axes.flat, paths):
        x = np.mean(read_audio(p), axis=0)
        f, t, s = signal.spectrogram(x, SR, nperseg=1024, noverlap=768)
        ax.pcolormesh(t, f / 1000, 10 * np.log10(s + 1e-12), shading="auto",
                      vmin=-140, vmax=-50, cmap="magma")
        ax.set_ylim(0, 10)
        ax.set_title(p.name, fontsize=8)
        ax.tick_params(labelsize=6)
        ax.set_ylabel("kHz", fontsize=6)
    for ax in list(axes.flat)[len(paths):]:
        ax.axis("off")
    fig.tight_layout()
    fig.savefig(out, dpi=56)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, default=OUT)
    args = parser.parse_args()
    if not shutil.which("ffmpeg"):
        print("ffmpeg is required (apt install ffmpeg / brew install ffmpeg)", file=sys.stderr)
        return 2
    self_test()
    out: Path = args.out
    out.mkdir(parents=True, exist_ok=True)

    rows = []
    for i, (name, fn) in enumerate(MICRO.items()):
        x = master_micro(fn(np.random.default_rng(100 + i)))
        write_wav(out / f"{name}.wav", x)
        rows.append(measure(out / f"{name}.wav", "micro"))
    for name, (key, mood, seed) in LOOPS.items():
        x = master_loop(render_loop(ISLANDS[key], mood, 30.0, seed))
        tmp = out / f"{name}.tmp.wav"
        write_wav(tmp, x)
        encode_m4a(tmp, out / f"{name}.m4a")
        tmp.unlink()
        rows.append(measure(out / f"{name}.m4a", "loop", master=x))
    files = [(out / r["file"], r["kind"]) for r in rows]
    (out / "levels.json").write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n")
    try:
        spectrogram_sheet([p for p, _ in files], out / "spectrograms.png")
    except ImportError:
        print("matplotlib not installed: no spectrogram sheet", file=sys.stderr)

    header = (f"{'file':34} {'s':>5} {'KB':>5} {'dBTP':>6} {'LUFS-I':>7} {'LUFS-M':>7} "
              f"{'cent':>6} {'>6k%':>5} {'<250%':>6}  problems")
    print(header)
    failed = False
    for r in rows:
        print(f"{r['file']:34} {r['seconds']:5.2f} {r['bytes'] / 1000:5.0f} {r['true_peak_dbtp']:6.1f} "
              f"{r['lufs_integrated']:7.1f} {r['lufs_momentary_max']:7.1f} {r['centroid_hz']:6d} "
              f"{r['energy_above_6k_pct']:5.1f} {r['energy_below_250_pct']:6.1f}  {', '.join(r['problems']) or 'ok'}")
        failed |= bool(r["problems"])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
