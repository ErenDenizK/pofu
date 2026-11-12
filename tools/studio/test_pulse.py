"""Tests for pulse. Run: python3 -I -m unittest discover -s tools/studio -p "test_*.py" """
from __future__ import annotations

import contextlib
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pulse  # noqa: E402


def git(repo: Path, *args: str, day: str = "2026-11-10") -> None:
    env = dict(os.environ, GIT_AUTHOR_DATE=f"{day}T12:00:00+0000", GIT_COMMITTER_DATE=f"{day}T12:00:00+0000",
               GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@example.com", GIT_COMMITTER_NAME="t",
               GIT_COMMITTER_EMAIL="t@example.com")
    subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True, env=env)


def merge_branch(repo: Path, branch: str, fragment: str | None, day: str) -> None:
    """A branch with one commit, merged the way GitHub merges a pull request."""
    git(repo, "checkout", "-q", "-b", branch, day=day)
    (repo / "code.txt").write_text(branch)
    if fragment:
        (repo / "changes").mkdir(exist_ok=True)
        (repo / "changes" / (branch.replace("/", "-") + ".md")).write_text(fragment + "\nmore detail\n")
    git(repo, "add", "-A", day=day)
    git(repo, "commit", "-q", "-m", f"work on {branch}", day=day)
    git(repo, "checkout", "-q", "main", day=day)
    git(repo, "merge", "-q", "--no-ff", "-m", f"Merge pull request #1 from owner/{branch}", branch, day=day)


class Pulse(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        git(self.repo, "init", "-q", "-b", "main")
        (self.repo / "README.md").write_text("x")
        git(self.repo, "add", "-A", day="2026-11-01")
        git(self.repo, "commit", "-q", "-m", "start", day="2026-11-01")
        merge_branch(self.repo, "feat/old-thing", "Added: an old thing", "2026-11-02")
        merge_branch(self.repo, "feat/home-plate", "Added: Home is drawn from its painted plate", "2026-11-08")
        merge_branch(self.repo, "docs/notes", None, "2026-11-10")
        merge_branch(self.repo, "fix/wonder-rules", "Fixed: the rumour comes on day twelve", "2026-11-12")
        pulse.REPO = str(self.repo)

    def tearDown(self):
        pulse.REPO = None
        self.tmp.cleanup()

    def test_fragments_are_listed_newest_first_inside_the_window(self):
        rows = pulse.fragments("main", "2026-11-07")
        self.assertEqual([(day, branch) for day, branch, _ in rows],
                         [("2026-11-12", "fix-wonder-rules"), ("2026-11-08", "feat-home-plate")])
        self.assertEqual(rows[0][2], "Fixed: the rumour comes on day twelve")

    def test_merges_are_counted_by_branch_prefix(self):
        days = pulse.merges("main", "2026-11-07")
        self.assertEqual(dict(days["2026-11-10"]), {"docs": 1})
        self.assertEqual(dict(days["2026-11-08"]), {"feat": 1})
        self.assertNotIn("2026-11-02", days)

    def test_a_window_with_no_player_change_says_so(self):
        out = io.StringIO()
        argv = sys.argv
        sys.argv = ["pulse.py", "--ref", "main", "--days", "1", "--today", "2026-11-11", "--no-network"]
        try:
            with contextlib.redirect_stdout(out):
                pulse.main()
        finally:
            sys.argv = argv
        self.assertIn("nothing: no user-visible change merged in this window", out.getvalue())
        self.assertIn("2026-11-10  docs 1", out.getvalue())

    def test_leftovers_name_caps_open_friction_and_the_route(self):
        (self.repo / "CLAUDE.md").write_text("line\n" * 81)
        (self.repo / "docs" / "studio").mkdir(parents=True)
        (self.repo / "docs" / "studio.md").write_text("word " * 4501)
        (self.repo / "docs" / "now.md").write_text("intro\n**Route:** build, then look\n")
        (self.repo / "docs" / "studio" / "friction.md").write_text(
            "| Date | Friction | Fix |\n|---|---|---|\n| 11-10 | slow queue | |\n| 11-11 | bad brief | done |\n")
        self.assertEqual(pulse.caps(str(self.repo)), ["CLAUDE.md: 81 lines, cap 80", "docs/studio.md: 4501 words, cap 4,500"])
        self.assertEqual(pulse.open_friction(str(self.repo / "docs/studio/friction.md")), ["11-10 | slow queue"])
        self.assertEqual(pulse.route(str(self.repo)), "**Route:** build, then look")
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            pulse.leftovers("main", str(self.repo), network=False)
        self.assertIn("**Route:** build, then look", out.getvalue())

    def test_a_merged_worktree_is_a_leftover_and_an_unmerged_one_is_not(self):
        wt = self.repo.parent / (self.repo.name + "-wt")
        git(self.repo, "worktree", "add", "-q", str(wt), "-b", "feat/old-thing-copy")      # same commit as main: merged
        try:
            rows = pulse.worktrees_merged("main")
            self.assertEqual(len(rows), 1)
            self.assertIn("feat/old-thing-copy", rows[0])
        finally:
            git(self.repo, "worktree", "remove", "--force", str(wt))


if __name__ == "__main__":
    unittest.main()
