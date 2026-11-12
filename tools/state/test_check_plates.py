import json
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

    def plate_root(self, d: str, plate: dict, sky_lights=()) -> Path:
        root = Path(d)
        take = root / "t" / "job"
        take.mkdir(parents=True)
        (take / "plate__job--t1.webp").write_bytes(b"x")
        (take / "review.yaml").write_text("jobs:\n  job:\n    pick: 1\n")
        plates = root / check_plates.PLATES_DIR
        plates.mkdir(parents=True)
        (plates / "plate-x.json").write_text(json.dumps(plate))
        if sky_lights:
            (plates / "skyset-x.json").write_text(json.dumps({"lights": {light: {} for light in sky_lights}}))
        return root

    def test_in_app_must_match_the_plate_file(self):
        painted = '{painted: "t/job/plate__job--t1.webp", lead_pick: 1, in_app: %s, founder_ok: null}'
        plate = {"lights": ["day"], "stages": 1, "painted": {"day": [0]}}
        with tempfile.TemporaryDirectory() as d:
            root = self.plate_root(d, plate)
            f = root / "plates.yaml"
            f.write_text(table(painted % "false").replace("      s:\n", "      0:\n"))
            self.assertEqual(check_plates.check(f, root), ["x/0/day/clear: the app ships this state but in_app is false"])
            f.write_text(table(painted % "true").replace("      s:\n", "      0:\n"))
            self.assertEqual(check_plates.check(f, root), [])

    def test_in_app_without_a_shipped_state(self):
        cell = '{painted: "t/job/plate__job--t1.webp", lead_pick: 1, in_app: true, founder_ok: null}'
        errors = self.run_table(cell)
        self.assertEqual(errors, ["x/s/day/clear: in_app is true but the app's plate files do not ship this state"])

    def test_level_keyed_plate_names_final_and_il_rows(self):
        plate = {"lights": ["day", "golden", "night"], "stages": 3, "lightStages": {"day": 3, "golden": 1, "night": 1},
                 "stageLevels": [10, 9, 8]}
        with tempfile.TemporaryDirectory() as d:
            root = self.plate_root(d, plate)
            got = check_plates.shipped_states(root, "x", {"bare", "il8", "il9", "final"})
        self.assertEqual(got, {("final", "day", "clear"), ("il9", "day", "clear"), ("il8", "day", "clear"),
                               ("final", "golden", "clear"), ("final", "night", "clear")})

    def test_rain_light_is_the_day_in_rain(self):
        plate = {"lights": ["day", "rain"], "stages": 5, "painted": {"day": [0, 4], "rain": [4]}, "stageLevels": [0]}
        with tempfile.TemporaryDirectory() as d:
            root = self.plate_root(d, plate, sky_lights=("day", "day-0"))
            self.assertEqual(check_plates.shipped_states(root, "x", {0, 4}),
                             {(0, "day", "clear"), (4, "day", "clear"), (4, "day", "rain")})
            self.assertEqual(check_plates.shipped_sky_lights(root, "x"), {"day", "day-0"})

    def test_the_real_table_matches_the_app(self):
        self.assertEqual(check_plates.check(ROOT / "docs/state/plates.yaml", ROOT), [])


if __name__ == "__main__":
    unittest.main()
