"""The ABC subset: what it reads, what it refuses, and that it writes back what it read."""

import unittest
from fractions import Fraction

from music import abc
from music.lint import MOTIF, tune_paths

TUNE = """X:7
T:Fixture
M:4/4
L:1/8
Q:1/4=96
V:lead instrument=kalimba
V:bed.pad instrument=pad gain=-9.5
K:D
%%pofu island home
% a comment
P:A
[V:lead] D F B2 A2 z2 | ^G =G G/ G3/ [DFA]4- | [DFA]8 |]
[V:bed.pad] [D,A,F]8 | D,,8 | z8 |
P:B
[V:lead] d' c' b a g f e d | z8 | _B B =B ^A z4 |
[V:bed.pad] z8 | z8 | z8 |
"""


class ParseTests(unittest.TestCase):
    def setUp(self):
        self.tune = abc.parse(TUNE)

    def test_header(self):
        t = self.tune
        self.assertEqual((t.index, t.title, t.meter, t.unit, t.beat, t.bpm),
                         (7, "Fixture", (4, 4), Fraction(1, 8), Fraction(1, 4), 96))
        self.assertEqual(t.key, abc.Key("D", "ionian"))
        self.assertEqual([(v.id, v.instrument, v.gain_db, v.stem) for v in t.voices],
                         [("lead", "kalimba", None, "lead"), ("bed.pad", "pad", -9.5, "bed")])
        self.assertEqual(t.pofu, {"island": "home"})
        self.assertEqual([c.name for c in t.cells], ["A", "B"])
        self.assertAlmostEqual(t.whole_seconds, 2.5)

    def test_the_key_signature_sharpens_f_and_c(self):
        first = self.tune.cell("A").voices["lead"][0]
        self.assertEqual([n.pitches for n in first], [(62,), (66,), (71,), (69,), ()])
        self.assertEqual([n.length for n in first],
                         [Fraction(1, 8), Fraction(1, 8), Fraction(1, 4), Fraction(1, 4), Fraction(1, 4)])
        run = self.tune.cell("B").voices["lead"][0]
        self.assertEqual([n.pitches[0] for n in run], [86, 85, 83, 81, 79, 78, 76, 74])

    def test_an_accidental_lasts_to_the_bar_line(self):
        second = self.tune.cell("A").voices["lead"][1]
        self.assertEqual([n.pitches for n in second[:4]], [(68,), (67,), (67,), (67,)])
        self.assertEqual([n.length for n in second[2:4]], [Fraction(1, 16), Fraction(3, 16)])
        third = self.tune.cell("B").voices["lead"][2]
        self.assertEqual([n.pitches for n in third[:4]], [(70,), (70,), (71,), (70,)])

    def test_octave_marks_and_chords(self):
        pad = self.tune.cell("A").voices["bed.pad"]
        self.assertEqual(pad[0][0].pitches, (50, 57, 66))
        self.assertEqual(pad[1][0].pitches, (38,))

    def test_ties_join_into_one_event(self):
        events = self.tune.cell("A").events("lead")
        self.assertEqual(events[-1], abc.Event(Fraction(3, 2), Fraction(3, 2), (62, 66, 69)))
        self.assertEqual(self.tune.cell("A").length("lead"), Fraction(3))

    def test_order_and_ending(self):
        self.assertEqual(self.tune.order, ["A", "B"])
        self.assertEqual(self.tune.ending, "B")
        ordered = abc.parse(TUNE.replace("%%pofu island home", "%%pofu order B A B"))
        self.assertEqual((ordered.order, ordered.ending), (["B", "A", "B"], "B"))

    def test_strong_beats(self):
        self.assertEqual(self.tune.strong_beats, (Fraction(0), Fraction(1, 2)))
        six = abc.parse(TUNE.replace("M:4/4", "M:6/8"))
        self.assertEqual(six.strong_beats, (Fraction(0), Fraction(3, 8)))


class KeyTests(unittest.TestCase):
    def test_every_island_mode(self):
        cases = {"D": ("ionian", "F C"), "Bm": ("aeolian", "F C"), "Dmix": ("mixolydian", "F"),
                 "Dlyd": ("lydian", "F C G"), "Bdor": ("dorian", "F C G"), "D ionian": ("ionian", "F C")}
        for text, (mode, sharps) in cases.items():
            key = abc._key(text)
            self.assertEqual(key.mode, mode, text)
            self.assertEqual({k for k, v in key.signature.items() if v == 1}, set(sharps.split()), text)
            self.assertEqual({k for k, v in key.signature.items() if v == -1}, set(), text)

    def test_degrees_count_scale_steps(self):
        key = abc.Key("D", "ionian")
        self.assertEqual([key.degree(p) - key.degree(62) for p in (62, 66, 71, 69, 74)], [0, 2, 5, 4, 7])
        aeolian = abc.Key("B", "aeolian")
        self.assertEqual(aeolian.degree(74) - aeolian.degree(71), 2)


class RoundTripTests(unittest.TestCase):
    def test_the_fixture(self):
        tune = abc.parse(TUNE)
        text = abc.dump(tune)
        self.assertEqual(abc.parse(text), tune)
        self.assertEqual(abc.dump(abc.parse(text)), text)

    def test_every_committed_score(self):
        paths = tune_paths() + [MOTIF]
        self.assertGreaterEqual(len(paths), 4)
        for path in paths:
            tune = abc.load(path)
            self.assertEqual(abc.parse(abc.dump(tune)), tune, path.name)

    def test_other_modes_spell_back(self):
        for key in ("Bm", "Dmix", "Dlyd", "Bdor"):
            tune = abc.parse(TUNE.replace("K:D", f"K:{key}"))
            self.assertEqual(abc.parse(abc.dump(tune)), tune, key)


class RefusalTests(unittest.TestCase):
    def refuses(self, old, new):
        self.assertIn(old, TUNE)
        with self.assertRaises(abc.ScoreError):
            abc.parse(TUNE.replace(old, new))

    def test_outside_the_subset(self):
        self.refuses("D F B2 A2 z2", "(3DFB A2 z2")          # a tuplet
        self.refuses("D F B2 A2 z2 |", "|: D F B2 A2 z2 :|")  # a repeat
        self.refuses("D F B2", "D>F B2")                      # broken rhythm
        self.refuses("D F B2", "D F ~B2")                     # a decoration
        self.refuses("D F B2", "D F H2")                      # not a note

    def test_structure(self):
        self.refuses("K:D\n", "")
        self.refuses("Q:1/4=96\n", "")
        self.refuses("Q:1/4=96", "Q:96")
        self.refuses("[V:bed.pad] [D,A,F]8", "[V:bed.keys] [D,A,F]8")   # a voice nobody declared
        self.refuses("V:bed.pad instrument=pad gain=-9.5", "V:choir.pad instrument=pad")
        self.refuses("V:bed.pad instrument=pad gain=-9.5", "V:bed.pad")
        self.refuses("P:B", "P:A")
        self.refuses("%%pofu island home", "%%pofu order A C")
        self.refuses("K:D", "K:Dblues")
        self.refuses("K:D", "R:reel\nK:D")


if __name__ == "__main__":
    unittest.main()
