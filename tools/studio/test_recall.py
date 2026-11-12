"""Tests for recall. Run: python3 -I -m unittest discover -s tools/studio -p "test_*.py" """
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import recall  # noqa: E402


def rec(kind: str, ts: str, content, **extra) -> str:
    return json.dumps({"type": kind, "timestamp": ts, "message": {"content": content}, **extra})


class Recall(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        proj = Path(self.tmp.name) / "proj"
        (proj / "s1" / "subagents").mkdir(parents=True)
        (proj / "s1.jsonl").write_text("\n".join([
            rec("user", "2026-11-09T08:00:00Z", "the lighthouse must glow " + "x" * 600),
            rec("assistant", "2026-11-09T08:01:00Z", [{"type": "text", "text": "I will make the lighthouse glow"}]),
            rec("user", "2026-11-09T08:02:00Z", "lighthouse meta", isMeta=True),
            rec("user", "2026-11-09T08:03:00Z", "lighthouse summary", isCompactSummary=True),
            rec("user", "2026-11-10T08:00:00Z", [{"type": "text", "text": "Lighthouse again"}]),
            rec("user", "2026-11-10T09:00:00Z", [{"type": "tool_result", "content": "lighthouse"}]),
        ]) + "\n")
        (proj / "s1" / "subagents" / "a.jsonl").write_text(rec("user", "2026-11-09T07:00:00Z", "lighthouse in a sub-agent") + "\n")
        self.paths = [str(proj / "s1.jsonl")]

    def tearDown(self):
        self.tmp.cleanup()

    def test_meta_summary_and_tool_results_are_not_founder_messages(self):
        rows = recall.search(self.paths, "lighthouse", who="founder")
        self.assertEqual([r[0] for r in rows], ["2026-11-09T08:00:00Z", "2026-11-10T08:00:00Z"])

    def test_snippet_is_capped_and_results_are_oldest_first_with_who(self):
        rows = recall.search(self.paths, "lighthouse")
        self.assertEqual([r[1] for r in rows], ["founder", "lead", "founder"])
        self.assertLessEqual(len(rows[0][2]), 400)

    def test_since_and_max(self):
        self.assertEqual(len(recall.search(self.paths, "lighthouse", since="2026-11-10")), 1)
        self.assertEqual(len(recall.search(self.paths, "lighthouse", limit=2)), 2)


if __name__ == "__main__":
    unittest.main()
