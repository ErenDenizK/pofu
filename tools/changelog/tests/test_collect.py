import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import collect  # noqa: E402

LOG = "# Changelog\n\n## [Unreleased]\n\n### Added\n\n- old\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- first\n"


class CollectTests(unittest.TestCase):
    def run_collect(self, *args):
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            (root / "changes").mkdir()
            (root / "CHANGELOG.md").write_text(LOG)
            (root / "changes" / "feat-a.md").write_text("Added: a new thing\n")
            (root / "changes" / "fix-b.md").write_text("Fixed: a bug\n")
            (root / "changes" / "plain.md").write_text("- tuned\n")
            self.assertEqual(collect.main(["--root", d, *args]), 0)
            return (root / "CHANGELOG.md").read_text(), sorted(p.name for p in (root / "changes").iterdir())

    def test_folds_into_unreleased_and_deletes(self):
        text, left = self.run_collect()
        unreleased = text.split("## [0.1.0]")[0]
        self.assertIn("- old\n- a new thing", unreleased)
        self.assertIn("### Changed\n\n- tuned", unreleased)
        self.assertIn("### Fixed\n\n- a bug", unreleased)
        self.assertIn("- first", text)
        self.assertEqual(left, [])

    def test_release_cut(self):
        text, _ = self.run_collect("--version", "0.2.0", "--date", "2026-12-01")
        self.assertIn("## [Unreleased]\n\n\n## [0.2.0] - 2026-12-01", text)
        self.assertLess(text.index("## [0.2.0]"), text.index("## [0.1.0]"))
        self.assertIn("- old\n- a new thing", text.split("## [0.1.0]")[0])


if __name__ == "__main__":
    unittest.main()
