"""Recovery fault tests use isolated local repos; no network or real art writes."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest

import yaml
from PIL import Image

SPEC = importlib.util.spec_from_file_location("operator_state", Path(__file__).resolve().parents[1] / "operator_state.py")
state = importlib.util.module_from_spec(SPEC); SPEC.loader.exec_module(state)


class RecoveryTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name); self.repo = self.root / "repo"
        self.runtime = self.root / "runtime"; self.work = self.root / "state"
        self.repo.mkdir(); self.runtime.mkdir(); self.work.mkdir()
        self.batch = "batch-fixture"; self.job = "flower"; self.asset = "plate__flower"
        self.run_git("init", "-q", "-b", "art/batch-fixture/all")
        self.run_git("config", "user.name", "Eren Deniz Kuyucaklıoğlu")
        self.run_git("config", "user.email", "109629701+ErenDenizK@users.noreply.github.com")
        m = self.repo / "tools/imagegen/manifest/batch-fixture.yaml"
        m.parent.mkdir(parents=True)
        m.write_text(yaml.safe_dump({"batch": self.batch, "status": "open", "jobs": [{"id": self.job, "kind": "plate", "name": self.job}]}))
        self.inbox = self.repo / "design/art/inbox" / self.batch
        self.qa = self.repo / "build/imagegen" / self.batch / "qa"
        self.locked = self.qa.parent / "locked"
        self.out = self.repo / "design/art/takes" / self.batch / self.job
        for p in (self.inbox, self.qa, self.locked, self.out): p.mkdir(parents=True)
        self.sources = self.root / "sources"; self.sources.mkdir()
        self.reports = {}; self.source_records = []
        self.add_take(1); self.add_take(2)
        self.write_review()
        Image.new("RGB", (8, 8), "white").save(self.out / "contact.jpg")
        self.commit()
        self.log_upload()
        (self.runtime / "flower-POSTED.json").write_text(json.dumps({"takes": 2}))

    def tearDown(self):
        self.tmp.cleanup()

    def run_git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], stderr=subprocess.DEVNULL)

    def add_take(self, n):
        src = self.sources / f"source{n}.png"
        # The real ingest re-encodes via PIL. Different PNG compression can
        # change bytes without changing decoded pixels or dimensions.
        Image.new("RGB", (8, 8), (n * 20, 110, 90)).save(src, compress_level=0)
        dest = self.inbox / f"{self.asset}--t{n}.png"
        Image.open(src).save(dest)
        side = {"job": self.job, "take": n, "fingerprint": "fixture-prompt", "source_file": str(src), "account": {"owner": "fixture", "kind": "chatgpt-plan"}}
        dest.with_suffix(".json").write_text(json.dumps(side))
        report = {"job": self.job, "take": n, "fingerprint": "fixture-prompt", "status": "pass", "checks": []}
        self.reports[n] = report
        (self.qa / f"{self.asset}--t{n}.json").write_text(json.dumps(report))
        shutil.copyfile(dest, self.locked / dest.name)
        Image.open(src).save(self.out / f"{self.asset}--t{n}.webp", "WEBP", quality=90)
        self.source_records.append({"take": n, "source_file": str(src), "fingerprint": "fixture-prompt", "original_png_sha256": state.digest(dest.read_bytes())})

    def write_review(self):
        data = {"jobs": {self.job: {"pick": 1, "publication": "selected exploration; never promoted"}}, "qa_reports": self.reports, "sources": self.source_records, "manual_review": {"exclude": []}}
        (self.out / "review.yaml").write_text(yaml.safe_dump(data))

    def commit(self):
        self.run_git("add", "design/art/takes", "tools/imagegen/manifest")
        self.run_git("commit", "-qm", "design(art): fixture\n\nGenerated-With: OpenAI Codex")
        self.run_git("update-ref", "refs/remotes/origin/art/batch-fixture/all", "HEAD")

    def log_upload(self):
        paths = [str(p.relative_to(self.repo)) for p in sorted(self.out.iterdir())]
        (self.runtime / "fixture-upload.log").write_text("\n".join("ok  " + p + " (1 KB)" for p in paths) + f"\n{len(paths)} file(s) checked, 0 problem(s). Everything arrived whole.\n")

    def reconcile(self):
        db, snapshot, summary = state.reconcile(self.repo, self.batch, self.runtime, self.work)
        self.addCleanup(db.close)
        return db, snapshot, summary

    def test_complete_reconcile_is_idempotent_and_encoding_is_not_corruption(self):
        db, first, summary = self.reconcile()
        count = db.execute("SELECT count(*) FROM events").fetchone()[0]
        _, second, summary2 = self.reconcile()
        self.assertEqual(first, second)
        self.assertEqual(count, db.execute("SELECT count(*) FROM events").fetchone()[0])
        self.assertEqual(summary2["take_fragment_sets_upload_verified"], 1)
        self.assertEqual(summary2["scope"], "take_fragments_only")
        self.assertFalse(summary["next_actions"])
        self.assertNotEqual((self.sources / "source1.png").read_bytes(), (self.inbox / f"{self.asset}--t1.png").read_bytes())
        self.assertEqual(first["jobs"][0]["errors"], [])

    def test_killed_transaction_rolls_back_without_phantom_completion(self):
        db = state.connect(self.work / "crash.sqlite3"); db.close()
        code = "import sqlite3,os,sys;d=sqlite3.connect(sys.argv[1]);d.execute('BEGIN IMMEDIATE');d.execute(\"INSERT INTO high_water VALUES('r','b','j',4)\");os._exit(47)"
        result = subprocess.run([sys.executable, "-c", code, str(self.work / "crash.sqlite3")])
        self.assertEqual(result.returncode, 47)
        db = state.connect(self.work / "crash.sqlite3"); self.addCleanup(db.close)
        self.assertEqual(db.execute("SELECT count(*) FROM high_water").fetchone()[0], 0)
        self.assertEqual(db.execute("PRAGMA synchronous").fetchone()[0], 2)
        self.assertEqual(db.execute("PRAGMA journal_mode").fetchone()[0], "wal")

    def test_unknown_dispatch_replays_reservation_without_second_dispatch(self):
        db = state.connect(self.work / "reserve.sqlite3"); self.addCleanup(db.close)
        first = state.reserve(db, self.repo, self.batch, "unstarted", 0, "stable-request")
        replay = state.reserve(db, self.repo, self.batch, "unstarted", 0, "stable-request")
        self.assertEqual(first["takes"], [1, 2])
        self.assertEqual(replay["action"], "reconcile_existing_reservation_do_not_redispatch")
        with self.assertRaises(ValueError): state.reserve(db, self.repo, self.batch, "unstarted", 0, "different-key")
        with self.assertRaises(ValueError): state.reserve(db, self.repo, self.batch, "unstarted", 1, "retry-without-output")
        retry = state.reserve(db, self.repo, self.batch, "unstarted", 1, "one-retry", True, "complete pair failed manual review")
        self.assertEqual(retry["takes"], [3, 4])
        db.close(); db = state.connect(self.work / "reserve.sqlite3"); self.addCleanup(db.close)
        with self.assertRaises(ValueError): state.reserve(db, self.repo, self.batch, "unstarted", 1, "third-round", True, "again")

    def test_stale_post_receipt_detects_hash_change_even_when_take_count_same(self):
        db, snapshot, _ = self.reconcile(); job = snapshot["jobs"][0]
        with db:
            db.execute("INSERT INTO receipts VALUES(?,?,?,?,?,?,?)", (str(self.repo), self.batch, self.job, "posted", job["source_set_sha256"], job["qa_set_sha256"], "{}"))
        _, snapshot, _ = self.reconcile()
        self.assertEqual(snapshot["jobs"][0]["posted_flag"], "hash_bound_current")
        p = self.locked / f"{self.asset}--t1.png"
        Image.new("RGBA", (8, 8), "red").save(p)
        _, snapshot, _ = self.reconcile()
        self.assertEqual(snapshot["jobs"][0]["posted_flag"], "STALE_source_or_QA_hashset")

    def test_new_take_invalidates_old_two_take_post_flag(self):
        self.add_take(3)
        _, snapshot, _ = self.reconcile()
        j = snapshot["jobs"][0]
        self.assertEqual(j["posted_flag"], "STALE_take_inventory_mismatch")
        self.assertFalse(j["facts"]["reviewed"])
        self.assertFalse(j["facts"]["upload_verified"])

    def test_upload_log_without_matching_remote_bytes_is_not_success(self):
        (self.out / "review.yaml").write_text((self.out / "review.yaml").read_text() + "\nchanged: true\n")
        _, snapshot, _ = self.reconcile()
        self.assertFalse(snapshot["jobs"][0]["facts"]["committed"])
        self.assertFalse(snapshot["jobs"][0]["facts"]["upload_verified"])

    def test_matching_git_bytes_without_upload_checker_log_is_not_verified(self):
        (self.runtime / "fixture-upload.log").unlink()
        _, snapshot, _ = self.reconcile()
        self.assertTrue(snapshot["jobs"][0]["facts"]["committed"])
        self.assertFalse(snapshot["jobs"][0]["facts"]["upload_verified"])
        self.assertEqual(snapshot["jobs"][0]["next_action"], "verify_existing_commit_upload_no_new_commit")

    def test_missing_archive_take_prevents_false_complete_bundle(self):
        (self.out / f"{self.asset}--t2.webp").unlink()
        _, snapshot, _ = self.reconcile()
        self.assertFalse(snapshot["jobs"][0]["bundle_complete"])
        self.assertFalse(snapshot["jobs"][0]["facts"]["upload_verified"])

    def test_deleted_local_caches_do_not_reopen_completed_generation(self):
        self.reconcile()
        shutil.rmtree(self.inbox); shutil.rmtree(self.qa.parent); shutil.rmtree(self.sources)
        # Simulate losing the DB too: committed review provenance preserves takes.
        other = self.root / "fresh-state"
        db, snapshot, summary = state.reconcile(self.repo, self.batch, self.runtime, other); self.addCleanup(db.close)
        j = snapshot["jobs"][0]
        self.assertEqual(j["max_take_seen"], 2)
        self.assertTrue(j["facts"]["upload_verified"])
        self.assertEqual(j["next_action"], "take_fragments_verified_no_regeneration")
        self.assertEqual(len(summary["originals_missing_locally"]), 2)
        with self.assertRaises(ValueError): state.reserve(db, self.repo, self.batch, self.job, 0, "do-not-regenerate")

    def test_four_take_cap_survives_lost_db_and_local_caches(self):
        self.add_take(3); self.add_take(4); self.write_review(); self.commit(); self.log_upload()
        shutil.rmtree(self.inbox); shutil.rmtree(self.qa.parent); shutil.rmtree(self.sources)
        db, snapshot, _ = state.reconcile(self.repo, self.batch, self.runtime, self.root / "fresh-state")
        self.addCleanup(db.close)
        self.assertEqual(snapshot["jobs"][0]["max_take_seen"], 4)
        self.assertEqual(snapshot["jobs"][0]["retry_rounds_used"], 1)
        with self.assertRaises(ValueError): state.reserve(db, self.repo, self.batch, self.job, 1, "no-fifth-take", True, "again")

    def test_source_hash_change_with_same_count_invalidates_manual_binding(self):
        db, snapshot, _ = self.reconcile(); job = snapshot["jobs"][0]
        with db:
            db.execute("INSERT INTO receipts VALUES(?,?,?,?,?,?,?)", (str(self.repo), self.batch, self.job, "posted", job["source_set_sha256"], job["qa_set_sha256"], "{}"))
        src = self.sources / "source1.png"; Image.new("RGB", (8, 8), "blue").save(src)
        Image.open(src).convert("RGBA").save(self.inbox / f"{self.asset}--t1.png")
        _, snapshot, _ = self.reconcile(); job = snapshot["jobs"][0]
        self.assertEqual(job["posted_flag"], "STALE_source_or_QA_hashset")
        self.assertFalse(job["facts"]["reviewed"])
        self.assertFalse(job["facts"]["upload_verified"])

    def test_partial_ingested_png_does_not_become_posted_success(self):
        p = self.inbox / f"{self.asset}--t1.png"; p.write_bytes(p.read_bytes()[:30])
        _, snapshot, _ = self.reconcile()
        self.assertTrue(snapshot["jobs"][0]["facts"]["generated"])  # intact original still exists
        self.assertFalse(snapshot["jobs"][0]["facts"]["posted"])
        self.assertFalse(snapshot["jobs"][0]["facts"]["upload_verified"])
        self.assertEqual(snapshot["jobs"][0]["next_action"], "inspect_local_evidence_do_not_regenerate")

    def test_worker_outage_is_not_a_job_failure(self):
        self.assertEqual(state.classify_error("exec-server transport disconnected; recovery timed out"), "transient_worker_unavailable_not_job_failure")
        self.assertEqual(state.classify_error("fatal: could not read Username"), "account_or_usage_stop")

    def test_partial_stop_marker_still_freezes_dispatch(self):
        (self.runtime / "GLOBAL_STOP.json").write_text("{")
        _, snapshot, _ = self.reconcile()
        self.assertIsNotNone(snapshot["global_stop"])
        self.assertEqual(snapshot["jobs"][0]["next_action"], "hold_global_stop_preserve_completed_outputs")

    def test_invalid_picks_never_verify_a_fragment_set(self):
        path = self.out / "review.yaml"
        baseline = yaml.safe_load(path.read_text())
        for label in ("missing_id", "boolean", "missing_status", "wrong_job", "wrong_take", "report_not_mapping"):
            with self.subTest(case=label):
                data = json.loads(json.dumps(baseline))
                if label == "missing_id": data["jobs"][self.job]["pick"] = 5
                elif label == "boolean": data["jobs"][self.job]["pick"] = True
                elif label == "missing_status": data["qa_reports"]["1"].pop("status")
                elif label == "wrong_job": data["qa_reports"]["1"]["job"] = "other"
                elif label == "wrong_take": data["qa_reports"]["1"]["take"] = 2
                else: data["qa_reports"]["1"] = []
                path.write_text(yaml.safe_dump(data)); self.commit(); self.log_upload()
                _, snapshot, _ = self.reconcile()
                self.assertFalse(snapshot["jobs"][0]["facts"]["reviewed"])
                self.assertFalse(snapshot["jobs"][0]["facts"]["upload_verified"])

    def test_manifest_name_defaults_to_job_id(self):
        path = self.repo / "tools/imagegen/manifest/batch-fixture.yaml"
        data = yaml.safe_load(path.read_text()); data["jobs"][0].pop("name")
        path.write_text(yaml.safe_dump(data))
        _, snapshot, summary = self.reconcile()
        self.assertEqual(snapshot["jobs"][0]["take_ids"], [1, 2])
        self.assertEqual(summary["take_fragment_sets_upload_verified"], 1)

    def test_atomic_export_failure_preserves_old_json(self):
        p = self.work / "export.json"; state.atomic_json(p, {"old": True})
        from unittest.mock import patch
        with patch.object(state.os, "replace", side_effect=OSError("crash before rename")):
            with self.assertRaises(OSError): state.atomic_json(p, {"new": True})
        self.assertEqual(json.loads(p.read_text()), {"old": True})

    def test_control_checkpoint_copy_never_invents_a_poll(self):
        payload = {"version": 1, "started_at": "2026-11-03T12:00:00Z", "deadline_at": "2026-11-03T14:00:00Z", "next_poll_at": "2026-11-03T12:20:00Z", "known_batches": [self.batch], "polls": [{"at": "2026-11-03T12:00:00Z"}], "status": "running", "errors": []}
        body = self.root / "pr-body.md"; body.write_text("<!-- POFU_QUEUE_WATCH_STATE\n" + json.dumps(payload) + "\n-->")
        result = state.import_control(body, self.work)
        self.assertEqual(result["state"], payload)
        self.assertEqual(len(json.loads((self.work / "control-watch-checkpoint.json").read_text())["state"]["polls"]), 1)

    def test_branch_command_keeps_lock_after_wrapper_is_killed(self):
        script = Path(state.__file__)
        prefix = [sys.executable, str(script), "--repo", str(self.repo), "--batch", self.batch, "--runtime", str(self.runtime), "--state-dir", str(self.work), "with-branch-lock", "--"]
        started = self.root / "started"; finished = self.root / "finished"; acquired = self.root / "acquired"
        code = "from pathlib import Path;import time;Path(" + repr(str(started)) + ").write_text('yes');time.sleep(.6);Path(" + repr(str(finished)) + ").write_text('yes')"
        first = subprocess.Popen(prefix + [sys.executable, "-c", code], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: first.poll() is None and first.kill())
        deadline = time.monotonic() + 3
        while not started.exists() and time.monotonic() < deadline: time.sleep(.01)
        self.assertTrue(started.exists()); first.kill(); first.wait()
        code2 = "from pathlib import Path;assert Path(" + repr(str(finished)) + ").exists();Path(" + repr(str(acquired)) + ").write_text('yes')"
        second = subprocess.run(prefix + [sys.executable, "-c", code2], capture_output=True, timeout=4)
        self.assertEqual(second.returncode, 0, second.stderr.decode())
        self.assertTrue(acquired.exists())


if __name__ == "__main__": unittest.main()
