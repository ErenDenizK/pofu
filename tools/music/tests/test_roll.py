"""The piano roll: a picture an agent can read a tune from."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image

from music import abc, lint, render, roll


class RollTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tune = abc.load(lint.SCORES / "home" / "day-a.abc")
        cls.image = roll.piano_roll(cls.tune)
        cls.colours = roll.voice_colours(cls.tune)

    def column(self, seconds):
        x = roll.LEFT + int(round(seconds * roll.PX_PER_SECOND))
        return [self.image.getpixel((x, y)) for y in range(roll.TOP, self.image.size[1] - roll.BOTTOM)]

    def test_size_follows_the_audition(self):
        end = render.audition_layout(self.tune)[-1][2]
        self.assertEqual(self.image.size[0], roll.LEFT + int((end + 1.0) * roll.PX_PER_SECOND) + roll.RIGHT)

    def test_one_colour_a_voice(self):
        self.assertEqual(len(set(self.colours.values())), len(self.tune.voices))

    def test_the_first_note_is_drawn_at_its_pitch(self):
        # D4, the motif's first note, a little after the cell starts.
        x = roll.LEFT + 4
        y = roll.TOP + (roll.HIGH - 62) * roll.ROW + roll.ROW // 2
        self.assertEqual(self.image.getpixel((x, y)), self.colours["lead"])

    def test_a_rest_shows_as_no_lead(self):
        whole = self.tune.whole_seconds
        self.assertIn(self.colours["lead"], self.column(0.3 * whole))      # the long B of bar one
        self.assertNotIn(self.colours["lead"], self.column(0.9 * whole))   # the rest that ends it
        self.assertIn(self.colours["bed.pad"], self.column(0.9 * whole))   # the pad holds through

    def test_the_pause_between_cells_is_empty(self):
        _, _, end = render.audition_layout(self.tune)[0]
        column = self.column(end + render.AUDITION_PAUSE / 2)
        for colour in self.colours.values():
            self.assertNotIn(colour, column)

    def test_it_writes_a_png(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "roll.png"
            roll.piano_roll(self.tune, out)
            with Image.open(out) as written:
                self.assertEqual(written.size, self.image.size)


if __name__ == "__main__":
    unittest.main()
