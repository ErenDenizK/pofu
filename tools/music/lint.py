#!/usr/bin/env python3
"""What the machine checks (music-system-v1 section 7).

No agent can hear. This lint makes everything except taste a failing run:
the score rules read the ABC, the audio rules read the rendered cells.

    python3 -I tools/music/lint.py            # every tune under design/music/score, score and audio
    python3 -I tools/music/lint.py --score    # the score rules only (fast)

Every defect the founder's ear finds becomes a rule here, with a failing
fixture in tests/test_lint.py.
"""

from __future__ import annotations

import sys
from fractions import Fraction
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    __package__ = "music"
    import music  # noqa: F401

import numpy as np

from . import abc
from .band import BAND, SR, sound

ROOT = Path(__file__).resolve().parents[2]
SCORES = ROOT / "design" / "music" / "score"
MOTIF = SCORES / "motif.abc"

# The islands' modes (section 5). Every one contains D major pentatonic (D4).
ISLANDS = {
    "home": abc.Key("D", "ionian"),
    "koke": abc.Key("B", "aeolian"),
    "caglayan": abc.Key("D", "mixolydian"),
    "revontuli": abc.Key("D", "lydian"),
    "emanet": abc.Key("B", "dorian"),
    "mehtap": abc.Key("D", "lydian"),
}
PENTATONIC = frozenset({2, 4, 6, 9, 11})       # D E F# A B
LEAD_LOW, LEAD_HIGH = 62, 86                   # D4 to D6
TEMPO = {"day": (84, 104), "night": (60, 72)}
CELLS = (4, 6)                                 # cells in a tune
BARS = (4, 8)                                  # bars in a cell
REST_SHARE = Fraction(1, 5)
NOTES_A_BAR = 8
MAX_LEAP = 12

MIX_LUFS = -20.0
LUFS_TOLERANCE = 0.5
PEAK_DBTP = -1.0
LOW_SHARE = 0.45
TAIL_DBFS = -50.0
TAIL_WINDOW = 0.25             # seconds at the file's end that must be below it
SIZE_LIMIT_BYTES = 24_000_000

NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def name(midi: int) -> str:
    return f"{NAMES[midi % 12]}{midi // 12 - 1}"


# --------------------------------------------------------------------------
# The motif

def motif_notes(motif: abc.Tune) -> list[int]:
    return [e.pitches[0] for cell in motif.cells for e in cell.events("lead")]


def motif_shape(motif: abc.Tune) -> tuple[int, ...]:
    """The motif as steps of its own scale: what a tune in any mode has to quote."""
    degrees = [motif.key.degree(p) for p in motif_notes(motif)]
    return tuple(b - a for a, b in zip(degrees, degrees[1:]))


def motif_problems(motif: abc.Tune) -> list[str]:
    """Four notes on the kalimba, inside the pentatonic, rising and settling."""
    out = []
    notes = motif_notes(motif)
    if len(notes) != 4:
        return [f"motif: four notes, not {len(notes)}"]
    if [v.instrument for v in motif.voices] != ["kalimba"]:
        out.append("motif: one voice, the kalimba")
    outside = [name(p) for p in notes if p % 12 not in PENTATONIC]
    if outside:
        out.append(f"motif: outside D major pentatonic: {' '.join(outside)}")
    if not (notes[0] < notes[1] < notes[2] and notes[0] < notes[3] < notes[2]):
        out.append("motif: it rises for three notes and settles below its top")
    return out


# --------------------------------------------------------------------------
# The score rules. Each returns its problems, every one starting with the rule's name.

def rule_form(tune, motif):
    out = []
    if not CELLS[0] <= len(tune.cells) <= CELLS[1]:
        out.append(f"form: a tune is {CELLS[0]} to {CELLS[1]} cells, not {len(tune.cells)}")
    island = tune.pofu.get("island")
    if island not in ISLANDS:
        out.append(f"form: %%pofu island is one of {', '.join(ISLANDS)}, not {island!r}")
    if "lead" not in [v.stem for v in tune.voices]:
        out.append("form: no lead voice")
    for voice in tune.voices:
        if voice.instrument not in BAND:
            out.append(f"form: {voice.id} plays {voice.instrument!r}, which is not in the band")
    return out


def rule_tempo(tune, motif):
    time = tune.pofu.get("time")
    if time not in TEMPO:
        return [f"tempo: %%pofu time is day or night, not {time!r}"]
    low, high = TEMPO[time]
    if not low <= tune.bpm <= high:
        return [f"tempo: a {time} tune runs at {low} to {high} beats a minute, not {tune.bpm}"]
    return []


def rule_mode(tune, motif):
    out = []
    island = ISLANDS.get(tune.pofu.get("island"))
    if island is None:
        return out
    if tune.key != island:
        out.append(f"mode: {tune.pofu['island']} is in {island.text() or island.tonic} "
                   f"({island.mode}), the tune says K:{tune.key.text()}")
    scale = set(island.scale)
    for cell in tune.cells:
        for voice in tune.voices:
            outside = sorted({name(p) for e in cell.events(voice.id) for p in e.pitches
                              if p % 12 not in scale})
            if outside:
                out.append(f"mode: cell {cell.name}, {voice.id}: outside the mode: {' '.join(outside)}")
    return out


def rule_bars(tune, motif):
    out = []
    for cell in tune.cells:
        counts = set()
        for voice in tune.voices:
            bars = cell.voices.get(voice.id)
            if not bars:
                out.append(f"bars: cell {cell.name} has no {voice.id}")
                continue
            counts.add(len(bars))
            for number, bar in enumerate(bars, 1):
                length = sum((n.length for n in bar), Fraction(0))
                if length != tune.bar:
                    out.append(f"bars: cell {cell.name}, {voice.id}, bar {number} holds {length} "
                               f"of a whole note, the meter says {tune.bar}")
        if len(counts) > 1:
            out.append(f"bars: cell {cell.name}: its voices are not the same length")
        elif counts and not BARS[0] <= min(counts) <= BARS[1]:
            out.append(f"bars: cell {cell.name} is {min(counts)} bars; a cell is {BARS[0]} to {BARS[1]}")
    return out


def _lead(tune) -> str | None:
    return next((v.id for v in tune.voices if v.stem == "lead"), None)


def rule_range(tune, motif):
    out = []
    for cell in tune.cells:
        outside = sorted({name(p) for e in cell.events(_lead(tune)) for p in e.pitches
                          if not LEAD_LOW <= p <= LEAD_HIGH})
        if outside:
            out.append(f"range: cell {cell.name}: the lead lives between D4 and D6: {' '.join(outside)}")
        for voice in tune.voices:
            instrument = BAND.get(voice.instrument)
            if instrument is None or voice.stem == "lead":
                continue
            outside = sorted({name(p) for e in cell.events(voice.id) for p in e.pitches
                              if not instrument.low <= p <= instrument.high})
            if outside:
                out.append(f"range: cell {cell.name}, {voice.id}: outside the {voice.instrument}'s "
                           f"range ({name(instrument.low)} to {name(instrument.high)}): {' '.join(outside)}")
    return out


def rule_leap(tune, motif):
    out = []
    for cell in tune.cells:
        events = cell.events(_lead(tune))
        for a, b in zip(events, events[1:]):
            if abs(b.pitches[-1] - a.pitches[-1]) > MAX_LEAP:
                out.append(f"leap: cell {cell.name}: {name(a.pitches[-1])} to {name(b.pitches[-1])} "
                           "is over an octave")
    return out


def rule_cadence(tune, motif):
    out = []
    tonic = tune.key.tonic_pc
    for cell in tune.cells:
        events = cell.events(_lead(tune))
        if not events:
            out.append(f"cadence: cell {cell.name}: the lead is silent")
            continue
        last = events[-1].pitches[-1]
        if cell.name == tune.ending:
            if last % 12 != tonic:
                out.append(f"cadence: the ending cell {cell.name} lands on the tonic, not {name(last)}")
        elif last % 12 not in PENTATONIC:
            out.append(f"cadence: cell {cell.name} ends on {name(last)}, outside the pentatonic")
        elif last % 12 == tonic:
            out.append(f"cadence: cell {cell.name} lands on the tonic; only the ending does")
    return out


def rule_motif(tune, motif):
    shape = motif_shape(motif)
    scale = set(tune.key.scale)
    for cell in tune.cells:
        notes = [e.pitches[0] for e in cell.events(_lead(tune)) if len(e.pitches) == 1]
        if any(p % 12 not in scale for p in notes):
            continue
        degrees = [tune.key.degree(p) for p in notes]
        steps = tuple(b - a for a, b in zip(degrees, degrees[1:]))
        for i in range(len(steps) - len(shape) + 1):
            if steps[i:i + len(shape)] == shape:
                return []
    return [f"motif: the tune never quotes the Pofu motif's shape (steps {shape})"]


def rule_rest(tune, motif):
    out = []
    for cell in tune.cells:
        bars = cell.voices.get(_lead(tune), [])
        total = sum((n.length for bar in bars for n in bar), Fraction(0))
        rest = sum((n.length for bar in bars for n in bar if n.is_rest), Fraction(0))
        if total and rest / total < REST_SHARE:
            out.append(f"rest: cell {cell.name}: the lead rests for {float(rest / total):.0%} "
                       "of the cell; a tune breathes for at least a fifth")
    return out


def rule_density(tune, motif):
    out = []
    for cell in tune.cells:
        per_bar: dict[int, int] = {}
        for event in cell.events(_lead(tune)):
            bar = int(event.start / tune.bar)
            per_bar[bar] = per_bar.get(bar, 0) + 1
        for bar, count in sorted(per_bar.items()):
            if count > NOTES_A_BAR:
                out.append(f"density: cell {cell.name}, bar {bar + 1} holds {count} lead notes; "
                           f"{NOTES_A_BAR} at most")
    return out


def rule_semitone(tune, motif):
    out = []
    beds = [v.id for v in tune.voices if v.stem == "bed"]
    for cell in tune.cells:
        lead = cell.events(_lead(tune))
        bed = [e for v in beds for e in cell.events(v)]
        bars = int(cell.length(_lead(tune)) / tune.bar)
        for bar in range(bars):
            for beat in tune.strong_beats:
                at = bar * tune.bar + beat
                high = {p for e in lead if e.start <= at < e.end for p in e.pitches}
                low = {p for e in bed if e.start <= at < e.end for p in e.pitches}
                for a in sorted(high):
                    for b in sorted(low):
                        if (a - b) % 12 in (1, 11):
                            out.append(f"semitone: cell {cell.name}, bar {bar + 1}, beat at {beat}: "
                                       f"the lead's {name(a)} sits a semitone from the bed's {name(b)}")
    return out


SCORE_RULES = [rule_form, rule_tempo, rule_mode, rule_bars, rule_range, rule_leap, rule_cadence,
               rule_motif, rule_rest, rule_density, rule_semitone]


def score_problems(tune: abc.Tune, motif: abc.Tune) -> list[str]:
    if _lead(tune) is None:
        return rule_form(tune, motif)
    return [problem for rule in SCORE_RULES for problem in rule(tune, motif)]


# --------------------------------------------------------------------------
# The audio rules: one cell's stems and their mix, as rendered (before AAC).

def audio_measures(mix: np.ndarray) -> dict:
    _, _, low = sound.spectrum_stats(mix)
    tail = float(np.max(np.abs(mix[-int(TAIL_WINDOW * SR):])))
    return {
        "lufs": round(sound.lufs_integrated(mix), 2),
        "true_peak_dbtp": round(sound.true_peak_db(mix), 2),
        "below_250hz": round(low, 3),
        "tail_dbfs": round(20 * np.log10(tail + 1e-12), 1),
        "seconds": round(len(mix) / SR, 3),
    }


def audio_problems(stems: dict[str, np.ndarray], mix: np.ndarray) -> list[str]:
    out = []
    lengths = {len(x) for x in stems.values()} | {len(mix)}
    if len(lengths) > 1:
        out.append(f"aligned: the stems and the mix are not one length: {sorted(lengths)} samples")
    elif float(np.max(np.abs(sum(stems.values()) - mix))) > 1e-6:
        out.append("aligned: the stems do not add up to the mix")
    m = audio_measures(mix)
    if abs(m["lufs"] - MIX_LUFS) > LUFS_TOLERANCE:
        out.append(f"loudness: the mix is at {m['lufs']} LUFS, not {MIX_LUFS}")
    if m["true_peak_dbtp"] > PEAK_DBTP:
        out.append(f"peak: true peak {m['true_peak_dbtp']} dBTP is over {PEAK_DBTP}")
    if m["below_250hz"] >= LOW_SHARE:
        out.append(f"low: {m['below_250hz']:.0%} of the energy is below 250 Hz; "
                   f"a phone speaker loses it ({LOW_SHARE:.0%} at most)")
    if m["tail_dbfs"] > TAIL_DBFS:
        out.append(f"tail: the file ends at {m['tail_dbfs']} dBFS; the tail decays below {TAIL_DBFS}")
    return out


def size_problems(total_bytes: int) -> list[str]:
    if total_bytes > SIZE_LIMIT_BYTES:
        return [f"size: {total_bytes / 1e6:.1f} MB of music; the limit is {SIZE_LIMIT_BYTES / 1e6:.0f} MB"]
    return []


# --------------------------------------------------------------------------

def tune_paths() -> list[Path]:
    return sorted(p for p in SCORES.rglob("*.abc") if p != MOTIF)


def main(argv: list[str] | None = None) -> int:
    import argparse
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--score", action="store_true", help="the score rules only")
    parser.add_argument("paths", nargs="*", type=Path, help="tunes (default: all under design/music/score)")
    args = parser.parse_args(argv)
    sound.self_test()
    motif = abc.load(MOTIF)
    failed = [f"{MOTIF.name}: {p}" for p in motif_problems(motif)]
    for path in args.paths or tune_paths():
        tune = abc.load(path)
        problems = score_problems(tune, motif)
        if not problems and not args.score:
            from . import render
            for cell_name in dict.fromkeys(tune.order):
                stems, mix = render.render_cell(tune, tune.cell(cell_name))
                problems += [f"cell {cell_name}: {p}" for p in audio_problems(stems, mix)]
        print(f"{path.relative_to(ROOT)}: {'ok' if not problems else f'{len(problems)} problems'}")
        failed += [f"{path.name}: {p}" for p in problems]
    for line in failed:
        print("  " + line)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
