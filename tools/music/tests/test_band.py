"""The band: each instrument's level and decay."""

import unittest

import numpy as np

from music.band import BAND, PERCUSSION, PERCUSSION_LUFS, REFERENCE_LUFS, SR, reference_lufs, sound


def db(x: float) -> float:
    return 20 * np.log10(x + 1e-12)


class BandTests(unittest.TestCase):
    def test_the_band_of_eight(self):
        # Seven pitched instruments and the small percussion (shaker and wood tok).
        self.assertEqual(sorted(BAND), ["bass", "felt_keys", "kalimba", "music_box", "nylon_pluck",
                                        "pad", "shaker", "tok", "whistle"])

    def test_the_meter_checks_itself(self):
        sound.self_test()

    def test_level_at_the_reference_note(self):
        for name, instrument in BAND.items():
            self.assertAlmostEqual(reference_lufs(instrument), instrument.target, delta=0.3, msg=name)
            self.assertEqual(instrument.target, PERCUSSION_LUFS if name in PERCUSSION else REFERENCE_LUFS)

    def test_level_holds_across_the_range(self):
        for name, instrument in BAND.items():
            if name == "shaker":
                continue
            for midi in range(instrument.low, instrument.high + 1, 5):
                level = reference_lufs(instrument, midi)
                self.assertTrue(instrument.target - 9 <= level <= instrument.target + 6, f"{name} at {midi}: {level:.1f} LUFS")

    def test_no_note_clips_and_every_note_is_clean(self):
        for name, instrument in BAND.items():
            for midi in (instrument.low, instrument.reference, instrument.high):
                x = instrument.play(midi, 0.5)
                self.assertTrue(np.all(np.isfinite(x)), name)
                self.assertLess(np.max(np.abs(x)), 0.9, f"{name} at {midi}")
                self.assertLess(abs(x[0]), 0.03, f"{name} starts with a click")
                self.assertLess(abs(x[-1]), 1e-3, f"{name} ends with a click")
                self.assertLess(abs(np.mean(x)), 2e-3, f"{name} carries DC")

    def test_struck_instruments_ring_and_die_by_themselves(self):
        for name, instrument in BAND.items():
            if not instrument.struck:
                continue
            short, long = instrument.play(instrument.reference, 0.2), instrument.play(instrument.reference, 4.0)
            self.assertLessEqual(len(long) / SR, 3.05, f"{name} rings for ever")
            for x in (short, long):
                peak = np.max(np.abs(x))
                at_peak = int(np.argmax(np.abs(x)))
                self.assertLess(at_peak / SR, 0.03, f"{name}: the strike is the loudest moment")
                tail = np.max(np.abs(x[-int(0.05 * SR):]))
                self.assertLess(db(tail / peak), -40, f"{name} is cut off while it rings")
            if name not in ("tok", "shaker"):
                self.assertGreater(len(short) / SR, 0.9, f"{name}: a short note still rings")

    def test_held_instruments_last_their_note_and_release(self):
        for name, instrument in BAND.items():
            if instrument.struck:
                continue
            for seconds in (0.6, 2.0):
                x = instrument.play(instrument.reference, seconds)
                over = len(x) / SR - seconds
                self.assertTrue(0.1 <= over <= 1.0, f"{name}: releases for {over:.2f} s")
                peak = np.max(np.abs(x))
                held = np.max(np.abs(x[int((seconds - 0.1) * SR):int(seconds * SR)]))
                tail = np.max(np.abs(x[-int(0.02 * SR):]))
                self.assertLess(db(tail / peak), -30, f"{name} does not release")
                if name != "felt_keys":             # a piano note dies under the finger
                    self.assertGreater(db(held / peak), -12, f"{name} does not hold")

    def test_the_felt_keys_decay_while_held(self):
        x = BAND["felt_keys"].play(69, 2.0)
        early = np.max(np.abs(x[: int(0.2 * SR)]))
        late = np.max(np.abs(x[int(1.7 * SR):int(1.9 * SR)]))
        self.assertLess(db(late / early), -6)

    def test_velocity_is_plain_gain_and_notes_are_seeded(self):
        for name, instrument in BAND.items():
            loud, soft = instrument.play(instrument.reference, 0.5, 1.0), instrument.play(instrument.reference, 0.5, 0.5)
            np.testing.assert_allclose(soft, loud * 0.5, atol=1e-12, err_msg=name)

    def test_pitched_instruments_sound_their_pitch(self):
        for name, instrument in BAND.items():
            if name == "shaker":
                continue
            x = instrument.play(instrument.reference, 1.0)
            spectrum = np.abs(np.fft.rfft(x * np.hanning(len(x))))
            f = np.fft.rfftfreq(len(x), 1 / SR)
            want = sound.midi_hz(instrument.reference)
            band = (f > 60) & (f < 6000)
            got = f[band][np.argmax(spectrum[band])]
            self.assertAlmostEqual(got / want, 1.0, delta=0.02, msg=f"{name}: {got:.1f} Hz for {want:.1f}")


if __name__ == "__main__":
    unittest.main()
