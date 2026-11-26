"""The renderer and the committed music: stems add up, the run is seeded, every tune passes the lint."""

import json
import unittest

import numpy as np

from music import abc, lint, render
from music.band import SR

MOTIF = abc.load(lint.MOTIF)
TUNES = {path: abc.load(path) for path in lint.tune_paths()}


class RenderTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tune = next(t for p, t in TUNES.items() if p.name == "day-a.abc")
        cls.cell = cls.tune.cell("A")
        cls.stems, cls.mix = render.render_cell(cls.tune, cls.cell)

    def test_three_stems_one_length_adding_up(self):
        self.assertEqual(sorted(self.stems), ["bed", "lead", "pulse"])
        want = int(round((render.cell_seconds(self.tune, self.cell) + render.TAIL) * SR))
        self.assertEqual({len(x) for x in self.stems.values()}, {want})
        np.testing.assert_allclose(sum(self.stems.values()), self.mix, atol=1e-9)
        for stem, x in self.stems.items():
            self.assertGreater(np.max(np.abs(x)), 1e-3, f"{stem} is silent")

    def test_a_cell_is_its_bars_and_a_tail(self):
        self.assertAlmostEqual(render.cell_seconds(self.tune, self.cell), 4 * 4 * 60 / 96)

    def test_the_run_is_seeded(self):
        again, mix = render.render_cell(self.tune, self.cell)
        np.testing.assert_array_equal(mix, self.mix)
        other, _ = render.render_cell(self.tune, self.cell, seed=2)
        self.assertFalse(np.array_equal(other["lead"], self.stems["lead"]))

    def test_the_lead_carries_the_tune(self):
        level = {stem: lint.sound.lufs_integrated(x) for stem, x in self.stems.items()}
        self.assertGreater(level["lead"], level["bed"] + 4)
        self.assertGreater(level["lead"], level["pulse"] + 4)

    def test_a_score_may_set_a_voice_gain(self):
        quiet = abc.parse(abc.dump(self.tune).replace("V:bed.pad instrument=pad", "V:bed.pad instrument=pad gain=-40"))
        samples = len(self.mix)
        a = render.render_voice(self.tune, self.cell, self.tune.voice("bed.pad"), samples, 1)
        b = render.render_voice(quiet, quiet.cell("A"), quiet.voice("bed.pad"), samples, 1)
        self.assertLess(np.max(np.abs(b)), np.max(np.abs(a)) * 0.1)

    def test_audition_layout(self):
        layout = render.audition_layout(self.tune)
        self.assertEqual([name for name, _, _ in layout], self.tune.order)
        self.assertEqual(layout[0][1], 0.0)
        for (_, _, end), (_, start, _) in zip(layout, layout[1:]):
            self.assertAlmostEqual(start - end, render.AUDITION_PAUSE)

    def test_audition_name(self):
        path = next(p for p in TUNES if p.name == "day-a.abc")
        self.assertEqual(render.audition_name(path), "home-day-a")


class CommittedMusicTests(unittest.TestCase):
    """What is in design/music is what the tools make, and it passes the lint."""

    def test_the_motif(self):
        self.assertEqual(lint.motif_problems(MOTIF), [])
        self.assertEqual([lint.name(p) for p in lint.motif_notes(MOTIF)], ["D4", "F#4", "B4", "A4"])

    def test_three_home_day_candidates(self):
        self.assertEqual(sorted(p.name for p in TUNES if p.parent.name == "home"),
                         ["day-a.abc", "day-b.abc", "day-c.abc"])

    def test_every_tune_passes_the_score_rules(self):
        for path, tune in TUNES.items():
            self.assertEqual(lint.score_problems(tune, MOTIF), [], path.name)

    def test_every_cell_passes_the_audio_rules_and_matches_the_committed_levels(self):
        levels = json.loads((render.AUDITION / "levels.json").read_text(encoding="utf-8"))
        total = 0
        for path, tune in TUNES.items():
            row = levels[render.audition_name(path)]
            self.assertEqual((row["order"], row["bpm"]), (tune.order, tune.bpm), path.name)
            for name in dict.fromkeys(tune.order):
                stems, mix = render.render_cell(tune, tune.cell(name))
                self.assertEqual(lint.audio_problems(stems, mix), [], f"{path.name} cell {name}")
                fresh, kept = lint.audio_measures(mix), row["cells"][name]
                # A stale audition file: the score changed and `render.py audition` was not run.
                self.assertAlmostEqual(fresh["seconds"], kept["seconds"], places=2, msg=f"{path.name} {name}")
                self.assertAlmostEqual(fresh["true_peak_dbtp"], kept["true_peak_dbtp"], delta=0.3,
                                       msg=f"{path.name} {name}")
                self.assertAlmostEqual(fresh["below_250hz"], kept["below_250hz"], delta=0.02,
                                       msg=f"{path.name} {name}")
                total += 3 * len(mix) / SR * 8000           # three mono stems at 64 kbit/s
        self.assertEqual(lint.size_problems(int(total)), [])

    def test_every_tune_has_its_audition_file_and_roll(self):
        for path in TUNES:
            name = render.audition_name(path)
            for suffix in (".m4a", ".png"):
                file = render.AUDITION / (name + suffix)
                self.assertTrue(file.is_file(), file.name)
                self.assertLess(file.stat().st_size, 1_000_000, file.name)


if __name__ == "__main__":
    unittest.main()
