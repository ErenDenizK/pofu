"""Every lint rule, each with a fixture that fails it."""

import unittest

import numpy as np

from music import abc, lint
from music.band import SR

MOTIF = abc.parse("""X:1
T:The motif
M:4/4
L:1/8
Q:1/4=96
V:lead instrument=kalimba
K:D
P:MOTIF
[V:lead] D F B2 A4 |
""")

GOOD = """X:1
T:Fixture
M:4/4
L:1/8
Q:1/4=96
V:lead instrument=kalimba
V:bed.pad instrument=pad
K:D
%%pofu island home
%%pofu time day
%%pofu order A A2 B END
P:A
[V:lead] D F B2 A2 z2 | F A d3 B z2 | A B d e f2 e d | B4 z4 |
[V:bed.pad] [D,A,F]8 | [B,,F,D]8 | [D,A,F]8 | [G,,D,B,]8 |
P:A2
[V:lead] D F B2 A2 z2 | F A d3 e z2 | f e d B A2 B d | A4 z4 |
[V:bed.pad] [D,A,F]8 | [B,,F,D]8 | [D,A,F]8 | [A,,E,A,]8 |
P:B
[V:lead] g2 f e d2 z2 | e2 d c B2 z2 | g f e d c2 B A | e4 z4 |
[V:bed.pad] [G,,D,B,]8 | [A,,E,C]8 | [G,,D,B,]4 [A,,E,C]4 | [A,,E,A,]8 |
P:END
[V:lead] D F B2 A2 z2 | d2 B A F2 z2 | E F A B A2 F E | D4 z4 |
[V:bed.pad] [D,A,F]8 | [B,,F,D]8 | [A,,E,C]8 | [D,A,F]8 |
"""


class ScoreRuleTests(unittest.TestCase):
    def problems(self, *changes, count=1):
        text = GOOD
        for old, new in changes:
            self.assertIn(old, text, "the fixture no longer holds what this test changes")
            text = text.replace(old, new, count)
        return lint.score_problems(abc.parse(text), MOTIF)

    def fails_only(self, rule, *changes, count=1):
        problems = self.problems(*changes, count=count)
        self.assertTrue(problems, f"nothing failed; wanted {rule}")
        self.assertEqual({p.split(":")[0] for p in problems}, {rule}, problems)
        return problems

    def test_the_good_tune_passes(self):
        self.assertEqual(lint.score_problems(abc.parse(GOOD), MOTIF), [])

    def test_form_cell_count(self):
        two_more = "".join(f"P:X{i}\n[V:lead] D4 z4 | E4 z4 | F4 z4 | A4 z4 |\n"
                           "[V:bed.pad] z8 | z8 | z8 | z8 |\n" for i in range(3))
        problems = self.problems(("P:END", two_more + "P:END"))
        self.assertTrue(any(p.startswith("form: a tune is 4 to 6 cells, not 7") for p in problems), problems)

    def test_form_island_and_band(self):
        self.fails_only("form", ("%%pofu island home", "%%pofu island atlantis"))
        self.fails_only("form", ("instrument=pad", "instrument=theremin"))
        self.assertEqual(lint.score_problems(abc.parse(GOOD.replace("V:lead", "V:pulse", 1)
                                                       .replace("[V:lead]", "[V:pulse]")), MOTIF),
                         ["form: no lead voice"])

    def test_tempo(self):
        self.fails_only("tempo", ("Q:1/4=96", "Q:1/4=120"))
        self.fails_only("tempo", ("%%pofu time day", "%%pofu time night"))
        self.fails_only("tempo", ("%%pofu time day", "%%pofu time noon"))
        self.assertEqual(self.problems(("Q:1/4=96", "Q:1/4=84")), [])

    def test_mode_a_note_outside(self):
        problems = self.fails_only("mode", ("e2 d c B2 z2", "e2 d =c B2 z2"))
        self.assertIn("C5", problems[0])
        self.fails_only("mode", ("[A,,E,C]8 | [D,A,F]8 |\n", "[A,,E,=C]8 | [D,A,F]8 |\n"))

    def test_mode_the_wrong_key_for_the_island(self):
        problems = self.problems(("K:D", "K:Dmix"))
        self.assertTrue(any(p.startswith("mode: home is in D") for p in problems), problems)

    def test_bars_a_short_bar(self):
        self.fails_only("bars", ("| B4 z4 |", "| B4 z2 |"))

    def test_bars_voices_of_different_lengths(self):
        problems = self.fails_only("bars", ("[D,A,F]8 | [G,,D,B,]8 |", "[D,A,F]8 |"))
        self.assertIn("not the same length", problems[0])

    def test_bars_a_cell_of_three(self):
        problems = self.problems(("| A B d e f2 e d | B4 z4 |", "| B4 z4 |"),
                                 ("[D,A,F]8 | [G,,D,B,]8 |", "[G,,D,B,]8 |"))
        self.assertTrue(any(p.startswith("bars: cell A is 3 bars") for p in problems), problems)

    def test_bars_a_missing_voice(self):
        problems = self.problems(("[V:bed.pad] [D,A,F]8 | [B,,F,D]8 | [D,A,F]8 | [G,,D,B,]8 |\n", ""))
        self.assertIn("bars: cell A has no bed.pad", problems)

    def test_range_of_the_lead(self):
        problems = self.fails_only("range", ("E F A B A2 F E", "E F A B A2 F C"))
        self.assertIn("C#4", problems[0])
        problems = self.fails_only("range", ("g2 f e d2 z2", "e'2 d' c' b2 z2"))
        self.assertIn("E6", problems[0])

    def test_range_of_an_instrument(self):
        problems = self.fails_only("range", ("[V:bed.pad] [D,A,F]8", "[V:bed.pad] [D,,,A,F]8"))
        self.assertIn("pad", problems[0])

    def test_leap(self):
        problems = self.fails_only("leap", ("F A d3 B z2", "F A d'3 B z2"))
        self.assertEqual(len(problems), 2)       # up to D6 and down again

    def test_cadence_outside_the_pentatonic(self):
        self.fails_only("cadence", ("| B4 z4 |", "| G4 z4 |"))

    def test_cadence_only_the_ending_lands_on_the_tonic(self):
        self.fails_only("cadence", ("| B4 z4 |", "| d4 z4 |"))
        self.fails_only("cadence", ("| D4 z4 |", "| E4 z4 |"))

    def test_motif(self):
        self.fails_only("motif", ("D F B2 A2 z2", "D E B2 A2 z2"), count=3)
        # One quote is enough, anywhere, at any pitch of the scale.
        self.assertEqual(self.problems(("D F B2 A2 z2", "D E B2 A2 z2"), count=2), [])
        self.assertEqual(lint.motif_shape(MOTIF), (2, 3, -1))

    def test_rest(self):
        self.fails_only("rest", ("| B4 z4 |", "| B8 |"))

    def test_density(self):
        problems = self.fails_only("density", ("A B d e f2 e d", "A B d e f e d e/ d/"))
        self.assertIn("bar 3 holds 9", problems[0])

    def test_semitone_on_a_strong_beat(self):
        problems = self.fails_only("semitone", ("[V:bed.pad] [G,,D,B,]8 | [A,,E,C]8", "[V:bed.pad] [D,A,F]8 | [A,,E,C]8"))
        self.assertIn("G5", problems[0])
        self.assertIn("F#4", problems[0])

    def test_a_semitone_in_passing_is_allowed(self):
        # The same clash on the second beat, which is weak.
        self.assertEqual(self.problems(("g2 f e d2 z2", "d2 g e d2 z2"),
                                       ("[V:bed.pad] [G,,D,B,]8 | [A,,E,C]8", "[V:bed.pad] [D,A,F]8 | [A,,E,C]8")), [])


class MotifRuleTests(unittest.TestCase):
    def variant(self, music, instrument="kalimba"):
        return abc.parse(f"X:1\nT:m\nM:4/4\nL:1/8\nQ:1/4=96\nV:lead instrument={instrument}\nK:D\n"
                         f"P:MOTIF\n[V:lead] {music} |\n")

    def test_the_motif_passes(self):
        self.assertEqual(lint.motif_problems(MOTIF), [])

    def test_failing_motifs(self):
        self.assertTrue(lint.motif_problems(self.variant("D F B A A4")))       # five notes
        self.assertTrue(lint.motif_problems(self.variant("D G B2 A4")))        # G is outside the pentatonic
        self.assertTrue(lint.motif_problems(self.variant("B A F2 D4")))        # it falls
        self.assertTrue(lint.motif_problems(self.variant("D F A2 B4")))        # it never settles
        self.assertTrue(lint.motif_problems(self.variant("D F B2 A4", "whistle")))


class AudioRuleTests(unittest.TestCase):
    def setUp(self):
        t = np.arange(8 * SR) / SR
        fade = np.clip((8.0 - t) / 2.0, 0, 1) ** 4
        body = np.sin(2 * np.pi * 440 * t) + 0.5 * np.sin(2 * np.pi * 660 * t)
        mix = body * fade
        mix *= 10 ** ((lint.MIX_LUFS - lint.sound.lufs_integrated(mix)) / 20)
        self.stems = {"lead": mix * 0.6, "bed": mix * 0.3, "pulse": mix * 0.1}
        self.mix = sum(self.stems.values())
        self.t = t

    def rules(self, stems, mix):
        return {p.split(":")[0] for p in lint.audio_problems(stems, mix)}

    def test_a_good_cell_passes(self):
        self.assertEqual(lint.audio_problems(self.stems, self.mix), [])

    def test_loudness(self):
        self.assertEqual(self.rules({k: v * 2 for k, v in self.stems.items()}, self.mix * 2), {"loudness"})
        self.assertEqual(self.rules({k: v / 2 for k, v in self.stems.items()}, self.mix / 2), {"loudness"})

    def test_peak(self):
        click = np.zeros_like(self.mix)
        click[SR] = 0.99
        stems = dict(self.stems, pulse=self.stems["pulse"] + click)
        self.assertEqual(self.rules(stems, sum(stems.values())), {"peak"})

    def test_low(self):
        rumble = 0.2 * np.sin(2 * np.pi * 80 * self.t) * np.clip((8.0 - self.t) / 2.0, 0, 1) ** 4
        stems = dict(self.stems, bed=self.stems["bed"] + rumble)
        self.assertIn("low", self.rules(stems, sum(stems.values())))

    def test_tail(self):
        cut = {k: v[: 5 * SR] for k, v in self.stems.items()}
        self.assertIn("tail", self.rules(cut, sum(cut.values())))

    def test_aligned(self):
        short = dict(self.stems, pulse=self.stems["pulse"][:-1])
        self.assertIn("aligned", self.rules(short, self.mix))
        moved = dict(self.stems, pulse=np.roll(self.stems["pulse"], 480))
        self.assertEqual(self.rules(moved, self.mix), {"aligned"})

    def test_size(self):
        self.assertEqual(lint.size_problems(lint.SIZE_LIMIT_BYTES), [])
        self.assertTrue(lint.size_problems(lint.SIZE_LIMIT_BYTES + 1)[0].startswith("size:"))

    def test_the_limits_are_the_spec(self):
        self.assertEqual((lint.MIX_LUFS, lint.PEAK_DBTP, lint.LOW_SHARE, lint.TAIL_DBFS, lint.SIZE_LIMIT_BYTES),
                         (-20.0, -1.0, 0.45, -50.0, 24_000_000))


if __name__ == "__main__":
    unittest.main()
