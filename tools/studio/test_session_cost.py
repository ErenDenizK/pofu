"""Tests for session_cost. Run: python3 -I -m unittest discover -s tools/studio -p "test_*.py" """
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import session_cost  # noqa: E402


def turn(mid: str, model: str, day: str, read: int, write: int, out: int) -> str:
    return json.dumps({"type": "assistant", "timestamp": f"{day}T10:00:00Z",
                       "message": {"id": mid, "model": model,
                                   "usage": {"input_tokens": 0, "cache_read_input_tokens": read,
                                             "cache_creation_input_tokens": write, "output_tokens": out}}})


class SessionCost(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.session = root / "s.jsonl"
        self.session.write_text("\n".join([
            turn("a", "claude-opus-5-5", "2026-11-05", 400_000, 0, 1_000),
            turn("a", "claude-opus-5-5", "2026-11-05", 400_000, 0, 1_000),      # the same message, streamed twice
            json.dumps({"type": "user", "message": {"content": "hello"}}),
            "not json",
            turn("b", "claude-opus-5-5", "2026-11-06", 100_000, 100_000, 0),
        ]) + "\n")
        sub = root / "s" / "subagents"
        sub.mkdir(parents=True)
        (sub / "agent-1.jsonl").write_text(turn("c", "claude-sonnet-5-5", "2026-11-06", 1_000_000, 0, 0) + "\n")
        (sub / "agent-1.meta.json").write_text(json.dumps({"description": "Build the thing"}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_each_message_counts_once(self):
        rows = list(session_cost.turns(str(self.session)))
        self.assertEqual([(day, fam, read, write, out) for day, fam, read, write, out in rows],
                         [("2026-11-05", "opus", 400_000, 0, 1_000), ("2026-11-06", "opus", 100_000, 100_000, 0)])

    def test_cost_follows_context(self):
        # a million re-read tokens cost a tenth of the input price; written context 1.25 times; output 5 times
        self.assertAlmostEqual(session_cost.dollars("sonnet", 1_000_000, 0, 0), 0.15)
        self.assertAlmostEqual(session_cost.dollars("opus", 0, 1_000_000, 0), 3.125)
        self.assertAlmostEqual(session_cost.dollars("opus", 0, 0, 1_000_000), 12.5)

    def test_report_names_days_and_agents(self):
        out = io.StringIO()
        argv = sys.argv
        sys.argv = ["session_cost.py", str(self.session)]
        try:
            with contextlib.redirect_stdout(out):
                session_cost.main()
        finally:
            sys.argv = argv
        text = out.getvalue()
        self.assertIn("2026-11-05      1 turns  avg  400k  max  400k", text)
        self.assertIn("sonnet    1 agents", text)
        self.assertIn("Build the thing", text)


if __name__ == "__main__":
    unittest.main()
