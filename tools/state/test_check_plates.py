import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_plates  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
EMPTY = "{painted: null, lead_pick: null, in_app: false, founder_ok: null}"


def table(cell: str) -> str:
    rows = []
    for t in check_plates.TIMES:
        rows.append(f"        {t}:")
        for w in check_plates.WEATHER:
            rows.append(f"          {w}: {cell if (t, w) == ('day', 'clear') else EMPTY}")
    sky = "\n".join(f"      {l}: {EMPTY}" for l in check_plates.SKY_LIGHTS)
    return "islands:\n  x:\n    stages:\n      s:\n" + "\n".join(rows) + "\n    sky_sets:\n" + sky + "\n"


class CheckPlates(unittest.TestCase):
    def run_table(self, cell: str, take_pick=1) -> list[str]:
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            take = root / "t" / "job"
            take.mkdir(parents=True)
            (take / "plate__job--t1.webp").write_bytes(b"x")
            (take / "review.yaml").write_text(f"jobs:\n  job:\n    pick: {take_pick}\n")
            f = root / "plates.yaml"
            f.write_text(table(cell))
            return check_plates.check(f, root)

    def test_good(self):
        cell = '{painted: "t/job/plate__job--t1.webp", lead_pick: 1, in_app: false, founder_ok: null}'
        self.assertEqual(self.run_table(cell), [])

    def test_missing_path(self):
        cell = '{painted: "t/job/plate__job--t2.webp", lead_pick: 2, in_app: false, founder_ok: null}'
        self.assertIn("not found", self.run_table(cell)[0])

    def test_pick_mismatch(self):
        cell = '{painted: "t/job/plate__job--t1.webp", lead_pick: 1, in_app: false, founder_ok: null}'
        self.assertIn("review.yaml pick", self.run_table(cell, take_pick=2)[0])

    def test_unpainted_with_pick(self):
        cell = "{painted: null, lead_pick: 1, in_app: false, founder_ok: null}"
        self.assertIn("unpainted", self.run_table(cell)[0])

    def test_sky_sets_missing(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "plates.yaml"
            f.write_text(table(EMPTY).split("    sky_sets:")[0])
            self.assertEqual(check_plates.check(f, Path(d)), ["x/sky_sets: missing section"])

    def test_sky_set_bad_cell(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "plates.yaml"
            f.write_text(table(EMPTY).replace("rain: " + EMPTY + "\n", "rain: {painted: null, lead_pick: 1, in_app: false, founder_ok: null}\n").rstrip("\n").rsplit("\n", 1)[0] + "\n      rain: {painted: null, lead_pick: 1, in_app: false, founder_ok: null}\n")
            errs = check_plates.check(f, Path(d))
            self.assertTrue(any("sky_sets/rain" in e and "unpainted" in e for e in errs))

    def test_real_table(self):
        self.assertEqual(check_plates.check(ROOT / "docs/state/plates.yaml", ROOT), [])


if __name__ == "__main__":
    unittest.main()
