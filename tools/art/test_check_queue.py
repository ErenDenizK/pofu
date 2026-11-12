"""Tests for check_queue. Run: python3 -I -m unittest discover -s tools/art -p "test_*.py" """
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import art_closure as ac  # noqa: E402
import check_queue as cq  # noqa: E402

HEAD = "| # | Batch | Kind | Jobs | Notes | State |\n|---|---|---|---|---|---|\n"


def checkout(d: str, queue: str, manifests: dict[str, str], takes: list[str] = ()) -> Path:
    art = Path(d)
    (art / "QUEUE.md").write_text("# The art queue\n\n## Demand\n\n" + HEAD + queue)
    (art / cq.MANIFESTS).mkdir(parents=True)
    for name, body in manifests.items():
        (art / cq.MANIFESTS / f"{name}.yaml").write_text(body)
    for rel in takes:
        f = art / cq.TAKES / rel
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_bytes(b"x")
    return art


def manifest(status: str = "open") -> str:
    return f"batch: b\nstatus: {status}\njobs:\n  - id: x-a\n  - id: x-b\n"


class CheckQueue(unittest.TestCase):
    def run_queue(self, queue: str, manifests: dict[str, str], takes: list[str] = ()) -> list[str]:
        with tempfile.TemporaryDirectory() as d:
            return cq.problems(checkout(d, queue, manifests, takes))

    def test_a_ready_row_with_an_open_manifest_passes(self):
        row = "| 1 | `batch-90-a` | exploration | 2 | order | **READY** |\n"
        self.assertEqual(self.run_queue(row, {"batch-90-a": manifest()}), [])

    def test_a_half_delivered_row_passes(self):
        row = "| 1 | `batch-90-a` | exploration | 2 | order | **READY** |\n"
        takes = ["batch-90-a/x-a/plate__x-a--t1.webp"]
        self.assertEqual(self.run_queue(row, {"batch-90-a": manifest()}, takes), [])

    def test_a_delivered_row_fails(self):
        row = "| 1 | `batch-90-a` | exploration | 2 | order | **READY** |\n"
        takes = ["batch-90-a/x-a/plate__x-a--t1.webp", "batch-90-a/x-b/plate__x-b--t2.webp"]
        found = self.run_queue(row, {"batch-90-a": manifest()}, takes)
        self.assertEqual(len(found), 1)
        self.assertIn("all 2 jobs already have takes", found[0])

    def test_a_missing_or_blocked_manifest_fails(self):
        rows = ("| 1 | `batch-90-a` | exploration | 2 | order | **READY** |\n"
                "| 2 | `batch-91-b` | exploration | 2 | order | READY |\n")
        found = self.run_queue(rows, {"batch-91-b": manifest("blocked")})
        self.assertEqual(len(found), 2)
        self.assertIn("does not exist", found[0])
        self.assertIn("'blocked'", found[1])

    def test_a_finished_row_belongs_in_the_log(self):
        rows = ("| 1 | `batch-90-a` | exploration | 2 | order | **DONE** (merged in pofu #1) |\n"
                "| 2 | `batch-91-b` | exploration | 2 | order | DROPPED (collage-era) |\n")
        found = self.run_queue(rows, {})
        self.assertEqual(len(found), 2)
        self.assertTrue(all("QUEUE-LOG.md" in f for f in found))

    def test_blocked_and_backlog_rows_are_left_alone(self):
        rows = ("| 1 | `batch-90-a` | exploration | 2 | order | BLOCKED (no manifest yet) |\n"
                "| 2 | `batch-91-b` | exploration | 2 | purpose | BACKLOG |\n")
        self.assertEqual(self.run_queue(rows, {}), [])

    def test_rows_agree_with_the_closure_reader(self):
        """Every table of the queue ends in a State cell, so both readers see the same rows."""
        text = HEAD + ("| 1 | `batch-90-a` | exploration | 2 | order | **READY** |\n"
                       "| 2 | `batch-91-b` | exploration | 2 | purpose | BACKLOG |\n"
                       "| 3 | `batch-92-c` | production | 2 | waits | BLOCKED (the icon list) |\n")
        self.assertEqual(ac.runnable_batches(text), ["batch-90-a", "batch-91-b"])
        self.assertEqual([names[0] for names, state in cq.rows(text) if not state.startswith("blocked")],
                         ["batch-90-a", "batch-91-b"])


if __name__ == "__main__":
    unittest.main()
