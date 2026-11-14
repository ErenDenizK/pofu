import sys
import tempfile
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_assets  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


class CheckAssets(unittest.TestCase):
    def run_rows(self, rows: dict, bundled=(), masters=()) -> list:
        """One kit hook `ui-x` in a scratch repository; the paint and sticker sections empty."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            for section, (swift, bundle) in check_assets.SECTIONS.items():
                (root / swift).parent.mkdir(parents=True, exist_ok=True)
                body = 'case x = "ui-x"' if section == "kit" else ""
                (root / swift).write_text(body)
                (root / bundle).mkdir(parents=True, exist_ok=True)
            for name in bundled:
                (root / check_assets.SECTIONS["kit"][1] / f"{name}.png").write_bytes(b"png")
            for folder in masters:
                (root / folder).mkdir(parents=True)
            return check_assets.problems({"kit": rows}, root)

    def test_the_committed_table_is_true(self):
        data = yaml.safe_load((ROOT / "docs/state/assets.yaml").read_text(encoding="utf-8"))
        self.assertEqual(check_assets.problems(data, ROOT), [])

    def test_a_hook_without_a_row_fails(self):
        self.assertIn("kit: hook ui-x has no row", self.run_rows({}))

    def test_a_row_without_a_hook_fails(self):
        rows = {"ui-x": {"state": "unpainted", "master": None, "note": "n"}, "ui-y": {"state": "unpainted", "note": "n"}}
        self.assertTrue(any("row ui-y names no hook" in p for p in self.run_rows(rows)))

    def test_the_bundle_is_derived(self):
        stale = {"ui-x": {"state": "in_repo", "master": "m/ui-x", "note": "n"}}
        self.assertTrue(any("in the bundle" in p for p in self.run_rows(stale, bundled=["ui-x"], masters=["m/ui-x"])))
        claimed = {"ui-x": {"state": "in_bundle", "master": "m/ui-x", "note": "n"}}
        self.assertTrue(any("is missing" in p for p in self.run_rows(claimed, masters=["m/ui-x"])))
        self.assertEqual(self.run_rows(claimed, bundled=["ui-x"], masters=["m/ui-x"]), [])

    def test_in_repo_needs_its_master_and_short_of_a_frame_needs_a_note(self):
        problems = self.run_rows({"ui-x": {"state": "in_repo", "master": "m/ui-x"}})
        self.assertTrue(any("no master in this repository" in p for p in problems))
        self.assertTrue(any("without a note" in p for p in problems))


if __name__ == "__main__":
    unittest.main()
