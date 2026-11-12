"""Tests for friction. Run: python3 -I -m unittest discover -s tools/studio -p "test_*.py" """
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import friction  # noqa: E402


def say(ts: str, text: str) -> str:
    return json.dumps({"type": "assistant", "timestamp": ts, "message": {"content": [{"type": "text", "text": text}]}})


class Friction(unittest.TestCase):
    def test_only_real_friction_in_the_last_message_is_listed(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "s.jsonl").write_text("{}\n")
            sub = root / "s" / "subagents"
            sub.mkdir(parents=True)
            cases = {
                "a": ("2026-11-10", "Friction: the queue waited 40 minutes", "Build tools"),
                "b": ("2026-11-10", "Friction: none", "Quiet one"),
                "c": ("2026-11-05", "Friction: old problem", "Old one"),
            }
            for k, (day, line, desc) in cases.items():
                (sub / f"agent-{k}.jsonl").write_text(
                    say(f"{day}T09:00:00Z", "Friction: stale early line") + "\n" + say(f"{day}T10:00:00Z", f"Result: ok\n{line}") + "\n")
                (sub / f"agent-{k}.meta.json").write_text(json.dumps({"description": desc}))
            (sub / "agent-d.jsonl").write_text(say("2026-11-10T10:00:00Z", "Result: ok, no such line") + "\n")
            self.assertEqual(list(friction.rows(str(root / "s.jsonl"), "2026-11-09")),
                             [("2026-11-10", "Build tools", "Friction: the queue waited 40 minutes")])
            self.assertEqual(len(list(friction.rows(str(root / "s.jsonl")))), 2)


if __name__ == "__main__":
    unittest.main()
