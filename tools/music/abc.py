"""The score: a small subset of ABC notation, parsed to a model and written back.

A tune is one file. Its header names the meter, unit length, tempo, key and
voices; its body is cells (`P:` lines), each holding one line of music per
voice (`[V:id] ...`). A voice id is `<stem>` or `<stem>.<part>`; the stem is
`lead`, `bed` or `pulse` (music-system-v1 D5) and the voices of a stem are
rendered into one file.

The subset, and nothing else:

    X: T: M: L: Q: K:            header fields (K: ends the header)
    V:<id> instrument=<name> [gain=<dB>]
    %%pofu <key> <value...>      Pofu's own fields (island, time, order)
    % ...                        a comment
    P:<name>                     starts a cell
    [V:<id>] <music>             the voice's bars in this cell
    C D E F G A B c d e f g a b  pitches, with , and ' for octaves
    ^ _ =                        accidentals (they last to the bar line)
    2 /2 3/2 /                   lengths, as multiples of L:
    z                            a rest
    [DFA]2                       a chord
    -                            a tie to the next note of the same pitch
    | |]                         bar lines

No repeats, tuplets, grace notes, broken rhythm or decorations: a score an
agent can read back exactly is worth more than a rich one.

This module is imported as `music.abc`; never as a top-level `abc`, which is
the standard library's.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from fractions import Fraction
from pathlib import Path

LETTER_PC = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
LETTERS = "CDEFGAB"
MODES = {
    "ionian": (0, 2, 4, 5, 7, 9, 11),
    "dorian": (0, 2, 3, 5, 7, 9, 10),
    "phrygian": (0, 1, 3, 5, 7, 8, 10),
    "lydian": (0, 2, 4, 6, 7, 9, 11),
    "mixolydian": (0, 2, 4, 5, 7, 9, 10),
    "aeolian": (0, 2, 3, 5, 7, 8, 10),
    "locrian": (0, 1, 3, 5, 6, 8, 10),
}
MODE_NAMES = {"": "ionian", "maj": "ionian", "ion": "ionian", "m": "aeolian", "min": "aeolian",
              "aeo": "aeolian", "dor": "dorian", "phr": "phrygian", "lyd": "lydian",
              "mix": "mixolydian", "loc": "locrian"}
MODE_SUFFIX = {"ionian": "", "aeolian": "m", "dorian": "dor", "phrygian": "phr",
               "lydian": "lyd", "mixolydian": "mix", "locrian": "loc"}
STEMS = ("lead", "bed", "pulse")


class ScoreError(ValueError):
    """The text is outside the subset, or does not add up."""


@dataclass(frozen=True)
class Key:
    tonic: str   # "D", "B", "F#", "Bb"
    mode: str    # a key of MODES

    @property
    def tonic_pc(self) -> int:
        return (LETTER_PC[self.tonic[0]] + {"": 0, "#": 1, "b": -1}[self.tonic[1:]]) % 12

    @property
    def scale(self) -> tuple[int, ...]:
        """The mode's seven pitch classes, from the tonic up."""
        return tuple((self.tonic_pc + step) % 12 for step in MODES[self.mode])

    @property
    def signature(self) -> dict[str, int]:
        """Letter -> alteration in semitones that the key signature gives it."""
        start = LETTERS.index(self.tonic[0])
        out = {}
        for i, pc in enumerate(self.scale):
            letter = LETTERS[(start + i) % 7]
            out[letter] = (pc - LETTER_PC[letter] + 6) % 12 - 6
        return out

    def degree(self, midi: int) -> int:
        """The diatonic step number of a pitch in this mode (the tonic at or below C-1 is 0)."""
        octave, step = divmod(midi - self.tonic_pc, 12)
        return 7 * octave + MODES[self.mode].index(step)

    def text(self) -> str:
        return self.tonic + MODE_SUFFIX[self.mode]


@dataclass(frozen=True)
class Note:
    """One event in a bar: a note, a chord (several pitches) or a rest (none)."""
    pitches: tuple[int, ...]      # MIDI numbers, low to high
    length: Fraction              # in whole notes
    tie: bool = False

    @property
    def is_rest(self) -> bool:
        return not self.pitches


@dataclass(frozen=True)
class Event:
    """A sounding note or chord, ties joined: where it starts and how long it lasts, in whole notes."""
    start: Fraction
    length: Fraction
    pitches: tuple[int, ...]

    @property
    def end(self) -> Fraction:
        return self.start + self.length


@dataclass
class Cell:
    name: str
    voices: dict[str, list[list[Note]]] = field(default_factory=dict)   # voice id -> bars

    def events(self, voice: str) -> list[Event]:
        out: list[Event] = []
        at = Fraction(0)
        tied = False
        for bar in self.voices.get(voice, []):
            for note in bar:
                if not note.is_rest:
                    if tied and out and out[-1].pitches == note.pitches and out[-1].end == at:
                        out[-1] = Event(out[-1].start, out[-1].length + note.length, note.pitches)
                    else:
                        out.append(Event(at, note.length, note.pitches))
                tied = note.tie and not note.is_rest
                at += note.length
        return out

    def length(self, voice: str) -> Fraction:
        return sum((n.length for bar in self.voices.get(voice, []) for n in bar), Fraction(0))


@dataclass
class Voice:
    id: str
    instrument: str
    gain_db: float | None = None

    @property
    def stem(self) -> str:
        return self.id.split(".")[0]


@dataclass
class Tune:
    title: str
    meter: tuple[int, int]
    unit: Fraction                    # L:, in whole notes
    beat: Fraction                    # Q:'s note value, in whole notes
    bpm: int
    key: Key
    voices: list[Voice]
    cells: list[Cell]
    pofu: dict[str, str] = field(default_factory=dict)
    index: int = 1

    @property
    def bar(self) -> Fraction:
        return Fraction(self.meter[0], self.meter[1])

    @property
    def strong_beats(self) -> tuple[Fraction, ...]:
        """Where the strong beats fall in a bar, in whole notes from the bar line."""
        if self.meter == (4, 4):
            return (Fraction(0), Fraction(1, 2))
        if self.meter == (6, 8):
            return (Fraction(0), Fraction(3, 8))
        return (Fraction(0),)

    @property
    def whole_seconds(self) -> float:
        """How long a whole note lasts."""
        return 60.0 / self.bpm / float(self.beat)

    def voice(self, voice_id: str) -> Voice:
        for v in self.voices:
            if v.id == voice_id:
                return v
        raise KeyError(voice_id)

    def cell(self, name: str) -> Cell:
        for c in self.cells:
            if c.name == name:
                return c
        raise KeyError(name)

    @property
    def order(self) -> list[str]:
        """The cells in the order the director plays them (`%%pofu order`), or as written."""
        if "order" in self.pofu:
            return self.pofu["order"].split()
        return [c.name for c in self.cells]

    @property
    def ending(self) -> str:
        """The ending cell: the last of the order."""
        return self.order[-1]


# --------------------------------------------------------------------------
# Reading

_LENGTH = r"(\d+)?(/(\d+)?)?"
_PITCH = r"([_=^]?)([A-Ga-g])([,']*)"
_TOKEN = re.compile(
    rf"(?P<space>\s+)|(?P<end>\|\])|(?P<bar>\|)"
    rf"|(?P<chord>\[(?P<inside>(?:{_PITCH})+)\](?P<clen>{_LENGTH})(?P<ctie>-)?)"
    rf"|(?P<rest>z(?P<rlen>{_LENGTH}))"
    rf"|(?P<note>{_PITCH}(?P<nlen>{_LENGTH})(?P<ntie>-)?)")
_ONE_PITCH = re.compile(_PITCH)
_LEN = re.compile(_LENGTH + r"$")
_FRACTION = re.compile(r"^(\d+)/(\d+)$")


def _length(text: str, unit: Fraction) -> Fraction:
    m = _LEN.match(text)
    number, slash, denominator = m.group(1), m.group(2), m.group(3)
    value = Fraction(int(number) if number else 1)
    if slash:
        value /= int(denominator) if denominator else 2
    if value <= 0:
        raise ScoreError(f"a length of zero: {text!r}")
    return value * unit


def _pitch(accidental: str, letter: str, marks: str, key: Key, in_bar: dict) -> int:
    octave = 4 if letter.isupper() else 5
    octave += marks.count("'") - marks.count(",")
    name = letter.upper()
    slot = (name, octave)
    if accidental:
        in_bar[slot] = {"^": 1, "_": -1, "=": 0}[accidental]
    alter = in_bar.get(slot, key.signature[name])
    return 12 * (octave + 1) + LETTER_PC[name] + alter


def _music(text: str, tune_key: Key, unit: Fraction, where: str) -> list[list[Note]]:
    bars: list[list[Note]] = []
    bar: list[Note] = []
    in_bar: dict = {}
    at = 0
    while at < len(text):
        m = _TOKEN.match(text, at)
        if not m or m.end() == at:
            raise ScoreError(f"{where}: outside the subset at {text[at:at + 12]!r}")
        at = m.end()
        if m.group("space"):
            continue
        if m.group("bar") or m.group("end"):
            if bar:
                bars.append(bar)
            bar, in_bar = [], {}
        elif m.group("rest"):
            bar.append(Note((), _length(m.group("rlen"), unit)))
        elif m.group("chord"):
            pitches = tuple(sorted(_pitch(a, l, o, tune_key, in_bar)
                                   for a, l, o in _ONE_PITCH.findall(m.group("inside"))))
            bar.append(Note(pitches, _length(m.group("clen"), unit), bool(m.group("ctie"))))
        else:
            a, l, o = _ONE_PITCH.match(m.group("note")).groups()
            pitch = _pitch(a, l, o, tune_key, in_bar)
            bar.append(Note((pitch,), _length(m.group("nlen"), unit), bool(m.group("ntie"))))
    if bar:
        bars.append(bar)
    return bars


def _key(text: str) -> Key:
    m = re.match(r"^([A-G])([#b]?)\s*([A-Za-z]*)$", text.strip())
    if not m:
        raise ScoreError(f"K: not understood: {text!r}")
    suffix = m.group(3).lower()
    mode = suffix if suffix in MODES else MODE_NAMES.get(suffix[:3] if len(suffix) > 1 else suffix)
    if mode is None:
        raise ScoreError(f"K: unknown mode {m.group(3)!r}")
    return Key(m.group(1) + m.group(2), mode)


def _fraction(text: str, name: str) -> Fraction:
    m = _FRACTION.match(text.strip())
    if not m:
        raise ScoreError(f"{name} wants a fraction, got {text!r}")
    return Fraction(int(m.group(1)), int(m.group(2)))


def parse(text: str) -> Tune:
    """Read a tune. Raises ScoreError on anything outside the subset."""
    head: dict[str, str] = {}
    voices: list[Voice] = []
    pofu: dict[str, str] = {}
    cells: list[Cell] = []
    tune_key: Key | None = None
    unit = Fraction(1, 8)
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        where = f"line {number}"
        if not line:
            continue
        if line.startswith("%%pofu"):
            parts = line.split(None, 2)
            if len(parts) < 3:
                raise ScoreError(f"{where}: %%pofu wants a key and a value")
            pofu[parts[1]] = parts[2].strip()
            continue
        if line.startswith("%"):
            continue
        if tune_key is None:
            m = re.match(r"^([A-Za-z]):(.*)$", line)
            if not m:
                raise ScoreError(f"{where}: music before K:")
            name, value = m.group(1), m.group(2).strip()
            if name == "V":
                parts = value.split()
                options = dict(p.split("=", 1) for p in parts[1:] if "=" in p)
                if len(options) != len(parts) - 1 or "instrument" not in options:
                    raise ScoreError(f"{where}: V: wants `<id> instrument=<name> [gain=<dB>]`")
                if parts[0].split(".")[0] not in STEMS:
                    raise ScoreError(f"{where}: a voice belongs to lead, bed or pulse, not {parts[0]!r}")
                if any(v.id == parts[0] for v in voices):
                    raise ScoreError(f"{where}: voice {parts[0]!r} twice")
                gain = float(options["gain"]) if "gain" in options else None
                voices.append(Voice(parts[0], options["instrument"], gain))
            elif name == "K":
                tune_key = _key(value)
                unit = _fraction(head.get("L", "1/8"), "L:")
            elif name in "XTMLQ":
                head[name] = value
            else:
                raise ScoreError(f"{where}: field {name}: is outside the subset")
            continue
        if line.startswith("P:"):
            name = line[2:].strip()
            if not name or any(c.name == name for c in cells):
                raise ScoreError(f"{where}: a cell needs a name of its own")
            cells.append(Cell(name))
            continue
        m = re.match(r"^\[V:([\w.]+)\](.*)$", line)
        if not m:
            raise ScoreError(f"{where}: a line of music starts with [V:<id>]")
        if not cells:
            raise ScoreError(f"{where}: music before the first P:")
        if not any(v.id == m.group(1) for v in voices):
            raise ScoreError(f"{where}: voice {m.group(1)!r} is not in the header")
        cells[-1].voices.setdefault(m.group(1), []).extend(_music(m.group(2), tune_key, unit, where))
    if tune_key is None:
        raise ScoreError("no K: field")
    for needed in ("T", "M", "Q"):
        if needed not in head:
            raise ScoreError(f"no {needed}: field")
    _fraction(head["M"], "M:")
    q = re.match(r"^(\d+)/(\d+)\s*=\s*(\d+)$", head["Q"])
    if not q:
        raise ScoreError(f"Q: wants `<note>=<beats a minute>`, got {head['Q']!r}")
    tune = Tune(title=head["T"],
                meter=tuple(int(n) for n in head["M"].split("/")),
                unit=unit, beat=Fraction(int(q.group(1)), int(q.group(2))), bpm=int(q.group(3)),
                key=tune_key, voices=voices, cells=cells, pofu=pofu,
                index=int(head.get("X", "1")))
    written = {c.name for c in cells}
    for name in tune.order:
        if name not in written:
            raise ScoreError(f"%%pofu order names a cell that is not written: {name!r}")
    return tune


def load(path: Path | str) -> Tune:
    return parse(Path(path).read_text(encoding="utf-8"))


# --------------------------------------------------------------------------
# Writing

def _length_text(length: Fraction, unit: Fraction) -> str:
    value = length / unit
    if value == 1:
        return ""
    if value.denominator == 1:
        return str(value.numerator)
    head = "" if value.numerator == 1 else str(value.numerator)
    return f"{head}/" if value.denominator == 2 else f"{head}/{value.denominator}"


def _pitch_text(midi: int, key: Key, in_bar: dict) -> str:
    signature = key.signature
    octave, pc = midi // 12 - 1, midi % 12
    spelled = None
    for letter in LETTERS:                      # the key's own spelling first
        if (LETTER_PC[letter] + signature[letter]) % 12 == pc:
            spelled = (letter, signature[letter])
    if spelled is None:                         # then a natural, then a sharp
        for letter in LETTERS:
            if LETTER_PC[letter] == pc:
                spelled = (letter, 0)
        if spelled is None:
            spelled = next((letter, 1) for letter in LETTERS if LETTER_PC[letter] + 1 == pc)
    letter, alter = spelled
    octave = (midi - LETTER_PC[letter] - alter) // 12 - 1
    slot = (letter, octave)
    mark = ""
    if in_bar.get(slot, signature[letter]) != alter:
        mark = {1: "^", -1: "_", 0: "="}[alter]
        in_bar[slot] = alter
    if octave >= 5:
        return mark + letter.lower() + "'" * (octave - 5)
    return mark + letter + "," * (4 - octave)


def _bars_text(bars: list[list[Note]], key: Key, unit: Fraction) -> str:
    out = []
    for bar in bars:
        in_bar: dict = {}
        words = []
        for note in bar:
            length = _length_text(note.length, unit)
            if note.is_rest:
                words.append("z" + length)
                continue
            names = [_pitch_text(p, key, in_bar) for p in note.pitches]
            body = names[0] if len(names) == 1 else "[" + "".join(names) + "]"
            words.append(body + length + ("-" if note.tie else ""))
        out.append(" ".join(words))
    return " | ".join(out) + " |"


def dump(tune: Tune) -> str:
    """Write a tune in one canonical form: parse(dump(t)) == t."""
    lines = [f"X:{tune.index}", f"T:{tune.title}", f"M:{tune.meter[0]}/{tune.meter[1]}",
             f"L:{tune.unit.numerator}/{tune.unit.denominator}",
             f"Q:{tune.beat.numerator}/{tune.beat.denominator}={tune.bpm}"]
    for voice in tune.voices:
        gain = "" if voice.gain_db is None else f" gain={voice.gain_db:g}"
        lines.append(f"V:{voice.id} instrument={voice.instrument}{gain}")
    lines.append(f"K:{tune.key.text()}")
    for name, value in tune.pofu.items():
        lines.append(f"%%pofu {name} {value}")
    for cell in tune.cells:
        lines.append(f"P:{cell.name}")
        for voice_id, bars in cell.voices.items():
            lines.append(f"[V:{voice_id}] " + _bars_text(bars, tune.key, tune.unit))
    return "\n".join(lines) + "\n"
