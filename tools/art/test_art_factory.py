"""Tests for the art-factory scripts: art_closure, sync_to_art, check_closure, ingest.

Run: python3 -I -m unittest discover -s tools/art -p "test_*.py"
"""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import art_closure as ac  # noqa: E402
import check_closure as cc  # noqa: E402
import ingest as ig  # noqa: E402
import sync_to_art as sy  # noqa: E402

SOURCE = ac.SOURCE_ROOT
BATCH = "batch-76-redo-picks"
QUEUE = f"""# Queue
| # | Batch | Kind | Purpose | Needs | Jobs | State |
|---|---|---|---|---|---|---|
| 0-h3 | `{BATCH}` | exploration | redo | none | 5 | **READY** |
| 0-x | `batch-01-slice` | production | old | none | 1 | done (#1) |
| 0-y | `batch-02-ui` | production | old | none | 1 | DROPPED (collage-era) |
| 0-z | `batch-03-home-island` | production | old | none | 1 | BLOCKED (skip) |
| B1 | `batch-22-gezgin-forms`, `batch-23-stickers` | exploration | two | none | 9 | BACKLOG |
"""


def quiet(*_a, **_k):
    pass


class QueueTests(unittest.TestCase):
    def test_runnable_rows_skip_done_dropped_and_blocked(self):
        self.assertEqual(ac.runnable_batches(QUEUE), [BATCH, "batch-22-gezgin-forms", "batch-23-stickers"])

    def test_an_empty_queue_has_no_rows(self):
        self.assertEqual(ac.runnable_batches("no table here"), [])


@unittest.skipUnless((SOURCE / ac.MANIFEST_DIR / f"{BATCH}.yaml").is_file(), "batch-76 manifest not in this tree")
class SyncAndCheckTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.art = Path(cls.tmp.name)
        (cls.art / "QUEUE.md").write_text(QUEUE.replace("batch-22-gezgin-forms`, `batch-23-stickers", "batch-23-stickers"), encoding="utf-8")
        cls.first = sy.sync(SOURCE, cls.art, out=quiet)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_the_first_sync_copies_the_tools_the_manifests_and_the_closure(self):
        for f in ("tools/imagegen/run.py", "tools/imagegen/pipeline.py", f"tools/imagegen/manifest/{BATCH}.yaml",
                  "tools/imagegen/blocks/edit-keep-v1.txt", "tools/imagegen/tests/test_pipeline.py", "SYNCED_FROM.txt"):
            self.assertTrue((self.art / f).is_file(), f)
        # the references batch-76 attaches or edits (home-night alias, a picked take 2 as an external master)
        self.assertTrue((self.art / "design/art/takes/batch-66-home-flow/x-home-flow-night/plate__x-home-flow-night--t1.webp").is_file())
        self.assertTrue((self.art / "design/art/takes/batch-74-redo-states/x-home-flow-il1-v3/plate__x-home-flow-il1-v3--t2.webp").is_file())
        # a take of a past batch that no queue manifest uses stays in pofu
        self.assertFalse((self.art / "design/art/takes/batch-01-slice").exists())
        self.assertFalse(self.first["missing"])

    def test_a_second_sync_changes_nothing(self):
        again = sy.sync(SOURCE, self.art, out=quiet)
        self.assertEqual((again["added"], again["updated"], again["pruned"]), ([], [], []))
        self.assertFalse(again["changed"])

    def test_a_changed_tool_is_updated_and_a_dry_run_writes_nothing(self):
        target = self.art / "tools/imagegen/blocks/edit-keep-v1.txt"
        original = target.read_bytes()
        target.write_bytes(original + b"\nlocal fix\n")
        try:
            dry = sy.sync(SOURCE, self.art, dry_run=True, out=quiet)
            self.assertEqual(dry["updated"], ["tools/imagegen/blocks/edit-keep-v1.txt"])
            self.assertIn(b"local fix", target.read_bytes())
            real = sy.sync(SOURCE, self.art, out=quiet)
            self.assertEqual(real["updated"], ["tools/imagegen/blocks/edit-keep-v1.txt"])
            self.assertEqual(target.read_bytes(), original)
        finally:
            target.write_bytes(original)

    def test_sync_never_touches_the_art_repos_own_files(self):
        (self.art / "AGENTS.md").write_text("mine\n", encoding="utf-8")
        sy.sync(SOURCE, self.art, out=quiet)
        self.assertEqual((self.art / "AGENTS.md").read_text(encoding="utf-8"), "mine\n")
        self.assertIn("batch-76", (self.art / "QUEUE.md").read_text(encoding="utf-8"))

    def test_the_closure_check_passes_then_fails_when_a_reference_goes_missing(self):
        lines = []
        self.assertEqual(cc.check(self.art, SOURCE, out=lines.append), 0, lines)
        ref = self.art / "design/art/takes/batch-66-home-flow/x-home-flow-night/plate__x-home-flow-night--t1.webp"
        data = ref.read_bytes()
        ref.unlink()
        try:
            lines = []
            self.assertEqual(cc.check(self.art, SOURCE, out=lines.append), 1)
            self.assertTrue(any("x-home-flow-night" in l and l.startswith("MISSING") for l in lines), lines)
        finally:
            ref.write_bytes(data)

    def test_the_closure_check_fails_when_a_prompt_block_is_missing(self):
        block = self.art / "tools/imagegen/blocks/edit-keep-v1.txt"
        data = block.read_bytes()
        block.unlink()
        try:
            lines = []
            self.assertEqual(cc.check(self.art, out=lines.append), 1)
            self.assertTrue(any(l.startswith(("PROMPT", "MANIFEST")) for l in lines), lines)
        finally:
            block.write_bytes(data)

    def test_a_checkout_without_a_queue_is_a_usage_error(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / "tools/imagegen/manifest").mkdir(parents=True)
            self.assertEqual(cc.check(Path(d), out=quiet), 2)


def review(job: str, pick) -> str:
    return (f"batch: batch-99-test\nmanifest: tools/imagegen/manifest/batch-99-test.yaml\njobs:\n  {job}:\n    pick: {pick}\n"
            f"    publication: exploration; not promoted\n")


class IngestTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.art, self.dest = root / "art", root / "pofu"
        self.dest.mkdir()
        for job, pick in (("x-a", 2), ("x-b", None), ("x-c", 1)):
            d = self.art / "design/art/takes/batch-99-test" / job
            d.mkdir(parents=True)
            (d / f"plate__{job}--t1.webp").write_bytes(b"take1-" + job.encode())
            (d / f"plate__{job}--t2.webp").write_bytes(b"take2-" + job.encode())
            (d / "contact.jpg").write_bytes(b"contact")
            (d / "review.yaml").write_text(review(job, "null" if pick is None else pick), encoding="utf-8")
        # the same job id in another batch, to make an id ambiguous
        d = self.art / "design/art/takes/batch-98-test/x-c"
        d.mkdir(parents=True)
        (d / "contact.jpg").write_bytes(b"other")

    def tearDown(self):
        self.tmp.cleanup()

    def dest_file(self, *parts):
        return self.dest.joinpath("design/art/takes/batch-99-test", *parts)

    def test_a_batch_brings_every_job_that_carries_a_pick(self):
        self.assertEqual(ig.ingest(self.art, self.dest, [], "batch-99-test", out=quiet), 0)
        self.assertEqual(self.dest_file("x-a", "plate__x-a--t2.webp").read_bytes(), b"take2-x-a")
        self.assertTrue(self.dest_file("x-a", "review.yaml").is_file())
        self.assertTrue(self.dest_file("x-c", "contact.jpg").is_file())
        self.assertFalse(self.dest_file("x-b").exists())  # no pick: stays in pofu-art

    def test_named_jobs_with_a_take_are_copied_whole_and_a_pick_mismatch_is_noted(self):
        lines = []
        self.assertEqual(ig.ingest(self.art, self.dest, ["x-a:1", "x-b"], "batch-99-test", out=lines.append), 0)
        self.assertTrue(self.dest_file("x-a", "plate__x-a--t1.webp").is_file())
        self.assertTrue(self.dest_file("x-b", "plate__x-b--t2.webp").is_file())
        self.assertTrue(any("says pick 2" in l for l in lines), lines)

    def test_unknown_missing_take_and_ambiguous_ids_are_problems(self):
        lines = []
        n = ig.ingest(self.art, self.dest, ["x-nope", "x-a:9", "x-c"], out=lines.append)
        self.assertEqual(n, 3, lines)
        self.assertFalse((self.dest / "design").exists())

    def test_ingest_is_idempotent_and_a_dry_run_writes_nothing(self):
        ig.ingest(self.art, self.dest, ["x-a"], dry_run=True, out=quiet)
        self.assertFalse((self.dest / "design").exists())
        ig.ingest(self.art, self.dest, ["x-a"], out=quiet)
        lines = []
        ig.ingest(self.art, self.dest, ["x-a"], out=lines.append)
        self.assertTrue(lines[-1].endswith("nothing changed"), lines)

    def test_a_batch_without_picks_is_a_problem(self):
        self.assertEqual(ig.ingest(self.art, self.dest, [], "batch-98-test", out=quiet), 1)


if __name__ == "__main__":
    unittest.main()
