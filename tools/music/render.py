#!/usr/bin/env python3
"""Render a tune: each cell as three sample-aligned stems, and an audition file.

    python3 -I tools/music/render.py audition          # design/music/audition/: m4a, piano roll, levels
    python3 -I tools/music/render.py stems <tune> <out-dir>

A cell's stems (lead, bed, pulse; music-system-v1 D5) are mono, one length,
and add up to the cell's mix, which is mastered to -20 LUFS: every step
between the instruments and the file is linear, and one gain is applied to
all three. The cell's file is its bars plus TAIL seconds, so the last note
and the room ring out.

An audition file is what the director would play, with the island's air cut
short: the cells in `%%pofu order`, each ringing into AUDITION_PAUSE seconds
of silence (the app leaves 4 to 12). It is mono AAC at 64 kbit/s, which is
what the app will ship.

The run is seeded; the same score gives the same samples. Needs ffmpeg for
the m4a files only.
"""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import zlib
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    __package__ = "music"
    import music  # noqa: F401

import numpy as np
from scipy import signal

from . import abc
from .band import BAND, SR, sound

ROOT = Path(__file__).resolve().parents[2]
AUDITION = ROOT / "design" / "music" / "audition"

TAIL = 2.5                    # seconds a cell's file runs past its last bar line
AUDITION_PAUSE = 2.0          # seconds of air between cells in an audition file
MIX_LUFS = -20.0
PEAK_CEILING_DBTP = -1.2
HIGHPASS_HZ = 90.0
ROOM_RT60 = 1.3
WET = {"lead": 0.20, "bed": 0.28, "pulse": 0.16}
CLOSE = 0.02                  # seconds: the last samples of a cell are brought to zero
JITTER = 0.004                # seconds: a struck note lands this close to its beat, not on it
BITRATE = "64k"

_ROOM: np.ndarray | None = None


def room() -> np.ndarray:
    global _ROOM
    if _ROOM is None:
        _ROOM = sound.room_ir(np.random.default_rng(11), ROOM_RT60, channels=1)[0]
    return _ROOM


def cell_seconds(tune: abc.Tune, cell: abc.Cell) -> float:
    return float(cell.length(tune.voices[0].id)) * tune.whole_seconds


def _velocity(tune: abc.Tune, start, rng: np.random.Generator) -> float:
    """A bar has a shape: the downbeat leads, the other strong beats follow, the rest is lighter."""
    position = start % tune.bar
    if position == 0:
        accent = 1.0
    elif position in tune.strong_beats:
        accent = 0.92
    elif position % tune.beat == 0:
        accent = 0.85
    else:
        accent = 0.76
    return accent * (1 + rng.uniform(-0.04, 0.04))


def render_voice(tune: abc.Tune, cell: abc.Cell, voice: abc.Voice, samples: int, seed: int) -> np.ndarray:
    instrument = BAND[voice.instrument]
    rng = np.random.default_rng([seed, zlib.crc32(tune.title.encode()), zlib.crc32(cell.name.encode()),
                                 zlib.crc32(voice.id.encode())])
    gain = 10 ** ((instrument.gain_db if voice.gain_db is None else voice.gain_db) / 20)
    out = np.zeros(samples)
    whole = tune.whole_seconds
    for event in cell.events(voice.id):
        velocity = _velocity(tune, event.start, rng)
        at = float(event.start) * whole
        if instrument.struck and voice.stem != "bed":
            at = max(0.0, at + rng.uniform(-JITTER, JITTER))
        for pitch in event.pitches:
            note = instrument.play(pitch, float(event.length) * whole,
                                   velocity / np.sqrt(len(event.pitches)), rng)
            sound.place(out, note, at, gain)
    return out


def render_cell(tune: abc.Tune, cell: abc.Cell, seed: int = 1) -> tuple[dict[str, np.ndarray], np.ndarray]:
    """One cell: its stems, mastered together, and their sum."""
    samples = int(round((cell_seconds(tune, cell) + TAIL) * SR))
    stems = {stem: np.zeros(samples) for stem in abc.STEMS}
    for voice in tune.voices:
        stems[voice.stem] += render_voice(tune, cell, voice, samples, seed)
    fade = int(CLOSE * SR)       # a click guard, not a fade-out: the lint's tail rule reads before it
    close = np.ones(samples)
    close[-fade:] = 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, fade))
    for stem, dry in stems.items():
        wet = signal.fftconvolve(dry, room())[:samples]
        stems[stem] = sound.highpass(dry * (1 - WET[stem]) + wet * WET[stem], HIGHPASS_HZ) * close
    mix = sum(stems.values())
    gain = 10 ** ((MIX_LUFS - sound.lufs_integrated(mix)) / 20)
    peak = sound.true_peak_db(mix * gain)
    if peak > PEAK_CEILING_DBTP:          # then the lint's loudness rule says so
        gain *= 10 ** ((PEAK_CEILING_DBTP - peak) / 20)
    stems = {stem: x * gain for stem, x in stems.items()}
    return stems, sum(stems.values())


def audition_layout(tune: abc.Tune, pause: float = AUDITION_PAUSE) -> list[tuple[str, float, float]]:
    """(cell, start, end of its last bar) in seconds, in the director's order."""
    out, at = [], 0.0
    for name in tune.order:
        length = cell_seconds(tune, tune.cell(name))
        out.append((name, at, at + length))
        at += length + pause
    return out


def render_audition(tune: abc.Tune, seed: int = 1) -> tuple[np.ndarray, dict]:
    layout = audition_layout(tune)
    out = np.zeros(int(round((layout[-1][2] + TAIL) * SR)))
    cells = {}
    from . import lint
    for name, start, _ in layout:
        if name not in cells:
            stems, mix = render_cell(tune, tune.cell(name), seed)
            cells[name] = (mix, {**lint.audio_measures(mix), "problems": lint.audio_problems(stems, mix)})
        sound.place(out, cells[name][0], start)
    return out, {name: row for name, (_, row) in cells.items()}


def encode_m4a(x: np.ndarray, path: Path, bitrate: str = BITRATE) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        wav = Path(tmp) / "x.wav"
        sound.write_wav(wav, x)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav), "-ac", "1", "-c:a", "aac",
                        "-b:a", bitrate, "-movflags", "+faststart", str(path)], check=True)


def audition_name(path: Path) -> str:
    """design/music/score/home/day-a.abc -> home-day-a"""
    return f"{path.parent.name}-{path.stem}"


def write_auditions(paths: list[Path], out: Path) -> int:
    from . import lint, roll
    sound.self_test()
    motif = abc.load(lint.MOTIF)
    out.mkdir(parents=True, exist_ok=True)
    levels, failed, written = {}, [], []
    for path in paths:
        tune = abc.load(path)
        problems = lint.score_problems(tune, motif)
        name = audition_name(path)
        if not problems:
            audio, cells = render_audition(tune)
            encode_m4a(audio, out / f"{name}.m4a")
            written.append(out / f"{name}.m4a")
            decoded = sound.read_audio(out / f"{name}.m4a")
            peak = round(sound.true_peak_db(decoded), 2)
            if peak > lint.PEAK_DBTP:
                problems.append(f"peak: the encoded file reaches {peak} dBTP")
            problems += [f"cell {c}: {p}" for c, row in cells.items() for p in row["problems"]]
            roll.piano_roll(tune, out / f"{name}.png")
            levels[name] = {
                "score": str(path.relative_to(ROOT)), "title": tune.title,
                "key": f"{tune.key.tonic} {tune.key.mode}", "meter": f"{tune.meter[0]}/{tune.meter[1]}",
                "bpm": tune.bpm, "order": tune.order, "seconds": round(len(audio) / SR, 2),
                "bytes": (out / f"{name}.m4a").stat().st_size, "encoded_true_peak_dbtp": peak,
                "cells": {c: {k: v for k, v in row.items() if k != "problems"} for c, row in cells.items()},
            }
        print(f"{name}: {'ok' if not problems else 'FAILED'}")
        failed += [f"{name}: {p}" for p in problems]
    if written:
        roll.spectrogram_sheet(written, out / "spectrograms.png")
    (out / "levels.json").write_text(json.dumps(levels, indent=2) + "\n", encoding="utf-8")
    for line in failed:
        print("  " + line)
    return 1 if failed else 0


def write_stems(path: Path, out: Path) -> int:
    """The cells of one tune as mono AAC stems: <cell>-<stem>.m4a (MU2 reads these)."""
    tune = abc.load(path)
    out.mkdir(parents=True, exist_ok=True)
    for name in dict.fromkeys(tune.order):
        stems, _ = render_cell(tune, tune.cell(name))
        for stem, x in stems.items():
            encode_m4a(x, out / f"{name.lower()}-{stem}.m4a")
    return 0


def main(argv: list[str] | None = None) -> int:
    import argparse
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    a = sub.add_parser("audition", help="render the audition file, roll and levels of each tune")
    a.add_argument("paths", nargs="*", type=Path)
    a.add_argument("--out", type=Path, default=AUDITION)
    s = sub.add_parser("stems", help="render one tune's cells as stems")
    s.add_argument("path", type=Path)
    s.add_argument("out", type=Path)
    args = parser.parse_args(argv)
    if args.command == "audition":
        from . import lint
        return write_auditions([p.resolve() for p in args.paths] or lint.tune_paths(), args.out)
    return write_stems(args.path, args.out)


if __name__ == "__main__":
    sys.exit(main())
