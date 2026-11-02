"""The whole loop against a stub Codex: run -> post -> review -> promote -> next round.

Everything happens in a temporary folder; the repository is not touched.
"""
from __future__ import annotations

import contextlib
import io
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
import yaml
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import backends as be  # noqa: E402
import pipeline as pl  # noqa: E402
import run  # noqa: E402
import review as rv  # noqa: E402
from test_qa import stall  # noqa: E402

MANIFEST = """
batch: e2e
jobs:
  - id: cay-1
    kind: station
    attach:
      - {ref: station-guide, role: "the guide"}
    prompt:
      - text: A tea stall.
      - block: view-v2
      - block: prop-style-v2
  - id: cay-2
    kind: station
    edit_of: cay-1
    prompt:
      - text: Add an awning.
      - block: edit-keep-v1
"""


def save(arr: np.ndarray, path: Path) -> Path:
    Image.fromarray(np.round(arr * 255).astype(np.uint8), "RGBA").save(path)
    return path


class EndToEnd(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="imagegen-e2e-"))
        self.old_art = pl.ART_ROOT
        pl.ART_ROOT = self.tmp / "art"
        stub = self.tmp / "codex"
        stub.write_text(f"#!/bin/sh\nexec {sys.executable} -I {HERE / 'stub_codex.py'} \"$@\"\n")
        stub.chmod(stub.stat().st_mode | stat.S_IEXEC)
        config = pl.load_config()
        config["paths"] = {k: str(self.tmp / k) for k in ("inbox", "build", "contact_sheets", "review")}
        config["backends"]["codex"]["binary"] = str(stub)
        config["rate"]["pause_seconds"] = 0
        config["account"] = {"owner": "Test Owner (founder)", "kind": "chatgpt-plan"}
        self.config = config
        self.config_path = self.tmp / "config.yaml"
        self.write_config()
        self.manifest = self.tmp / "e2e.yaml"
        self.manifest.write_text(MANIFEST, encoding="utf-8")
        self.env = {"CODEX_HOME": str(self.tmp / "codex-home"), "STUB_LOG": str(self.tmp / "stub.log")}
        self.old_env = {k: os.environ.get(k) for k in [*self.env, "STUB_IMAGE", "STUB_MODE", "OPENAI_API_KEY"]}
        os.environ.update(self.env)
        os.environ.pop("OPENAI_API_KEY", None)
        os.environ.pop("STUB_MODE", None)

    def write_config(self):
        self.config_path.write_text(yaml.safe_dump(self.config, allow_unicode=True), encoding="utf-8")

    def tearDown(self):
        pl.ART_ROOT = self.old_art
        for k, v in self.old_env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v

    def cli(self, *args) -> tuple[int, str]:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = run.main([*args, "--config", str(self.config_path)])
        return code, buf.getvalue()

    def test_full_loop(self):
        m = ["--manifest", str(self.manifest)]
        os.environ["STUB_IMAGE"] = str(save(stall(dx=30, scale=1.1, size=1254), self.tmp / "l1.png"))
        code, out = self.cli("run", *m, "--takes", "2")
        self.assertEqual(code, 0, out)
        self.assertIn("skip cay-2: waiting for cay-1", out)
        inbox = self.tmp / "inbox" / "e2e"
        self.assertEqual(sorted(p.name for p in inbox.glob("*.png")), ["station__cay-1--t1.png", "station__cay-1--t2.png"])
        side = json.loads((inbox / "station__cay-1--t1.json").read_text())
        self.assertEqual(side["backend"], "codex")
        self.assertTrue(side["thread_id"])
        calls = [json.loads(l) for l in (self.tmp / "stub.log").read_text().splitlines()]
        self.assertIn("IMAGE PROMPT:", calls[0]["task"])
        self.assertTrue(any(a.startswith("--image=") for a in calls[0]["argv"]))

        # resumable: a second run makes nothing new
        code, out = self.cli("run", *m, "--takes", "2")
        self.assertIn("Nothing to generate", out)

        code, out = self.cli("post", *m)
        self.assertEqual(code, 0, out)
        review_path = self.tmp / "review" / "e2e.yaml"
        self.assertTrue((self.tmp / "contact_sheets" / "e2e.png").exists())
        self.assertTrue((self.tmp / "review" / "e2e-contact.jpg").exists())
        data = rv.load_review(review_path)
        self.assertIsNone(data["jobs"]["cay-1"]["pick"])
        self.assertIn("t2", data["jobs"]["cay-1"]["takes"])

        data["jobs"]["cay-1"]["pick"] = 2
        data["jobs"]["cay-1"]["note"] = "the softer one"
        rv.save_review(review_path, data, "e2e.yaml")
        code, out = self.cli("promote", *m)
        self.assertEqual(code, 0, out)
        master = pl.ART_ROOT / "stations" / "cay-1"
        self.assertTrue((master / "cay-1.png").exists() and (master / "raw.webp").exists())
        self.assertFalse((master / "raw.png").exists())
        meta = json.loads((master / "meta.json").read_text())
        self.assertEqual(meta["take"], 2)
        self.assertEqual(meta["raw_encoding"], "webp lossless")  # a small test take fits
        self.assertEqual(meta["account"]["owner"], "Test Owner (founder)")
        self.assertIn("Generating account:** Test Owner (founder)", (master / "provenance.md").read_text())
        self.assertTrue(meta["registration"])  # the chain root was put on the anchor
        self.assertIn("the softer one", (master / "provenance.md").read_text())
        self.assertIn("cay-2", out)
        self.assertIn("ready (0/2 takes)", out)

        # round 2: the edit attaches the approved L1 first, and is aligned back on post
        os.environ["STUB_IMAGE"] = str(save(stall(dx=30, scale=0.95, awning=True, size=1254), self.tmp / "l2.png"))
        code, out = self.cli("run", *m, "--only", "cay-2", "--takes", "1")
        self.assertEqual(code, 0, out)
        task = json.loads((self.tmp / "stub.log").read_text().splitlines()[-1])["task"]
        self.assertIn("1. The image to edit", task)
        code, out = self.cli("post", *m, "--only", "cay-2")
        self.assertIn("cay-2 t1", out)
        report = json.loads((self.tmp / "build" / "e2e" / "qa" / "station__cay-2--t1.json").read_text())
        checks = {c["check"]: c for c in report["checks"]}
        self.assertEqual(checks["edit_stability"]["status"], "pass")

        # parallel mode: promote --only touches only the named job
        data = rv.load_review(review_path)
        data["jobs"]["cay-2"]["pick"] = 1
        rv.save_review(review_path, data, "e2e.yaml")
        code, out = self.cli("promote", *m, "--only", "cay-1")
        self.assertEqual(code, 0, out)
        self.assertFalse((pl.ART_ROOT / "stations" / "cay-2" / "cay-2.png").exists())
        code, out = self.cli("promote", *m, "--only", "cay-2")
        self.assertEqual(code, 0, out)
        self.assertTrue((pl.ART_ROOT / "stations" / "cay-2" / "cay-2.png").exists())

    def test_limit_stops_the_run(self):
        os.environ["STUB_IMAGE"] = str(save(stall(), self.tmp / "l1.png"))
        os.environ["STUB_MODE"] = "limit"
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertEqual(code, run.EXIT_STOP, out)
        self.assertIn("usage or rate limit", out)
        self.assertEqual(len((self.tmp / "stub.log").read_text().splitlines()), 1)  # no retry hammering

    def test_no_image_is_reported(self):
        os.environ["STUB_IMAGE"] = str(save(stall(), self.tmp / "l1.png"))
        os.environ["STUB_MODE"] = "noimage"
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertEqual(code, run.EXIT_STOP, out)
        self.assertIn("without an image", out)

    def test_api_key_blocks_codex(self):
        os.environ["OPENAI_API_KEY"] = "sk-test"
        os.environ["STUB_IMAGE"] = str(save(stall(), self.tmp / "l1.png"))
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertEqual(code, run.EXIT_STOP, out)
        self.assertIn("OPENAI_API_KEY is set", out)

    def test_manual_pack_and_ingest(self):
        m = ["--manifest", str(self.manifest)]
        code, out = self.cli("run", *m, "--backend", "manual")
        pack = (self.tmp / "build" / "e2e" / "manual-pack.md").read_text()
        self.assertIn("## cay-1", pack)
        self.assertNotIn("## cay-2", pack)
        self.assertIn("station-guide.png", pack)
        code, out = self.cli("ingest", *m, "--job", "cay-1", str(save(stall(), self.tmp / "dl.png")))
        self.assertTrue((self.tmp / "inbox" / "e2e" / "station__cay-1--t1.png").exists())

    def test_blocked_batch_refuses_to_generate(self):
        self.manifest.write_text(MANIFEST.replace("batch: e2e", "batch: e2e\nstatus: blocked\nblocked_on: [dogfood]"))
        os.environ["STUB_IMAGE"] = str(save(stall(), self.tmp / "l1.png"))
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertEqual(code, run.EXIT_ERR, out)
        self.assertIn("blocked on: dogfood", out)
        code, out = self.cli("run", "--manifest", str(self.manifest), "--dry-run")
        self.assertIn("Nothing was sent", out)
        self.assertFalse((self.tmp / "stub.log").exists())

    def test_account_must_be_named_and_match_the_backend(self):
        os.environ["STUB_IMAGE"] = str(save(stall(), self.tmp / "l1.png"))
        self.config["account"] = {"owner": "", "kind": "chatgpt-plan"}
        self.write_config()
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertIn("account.owner", out)
        self.config["account"] = {"owner": "Founder", "kind": "api"}
        self.write_config()
        code, out = self.cli("run", "--manifest", str(self.manifest))
        self.assertIn("needs account.kind chatgpt-plan", out)
        self.assertFalse((self.tmp / "stub.log").exists())

    def test_api_run_prints_an_estimate_and_needs_yes(self):
        self.config["account"] = {"owner": "Founder", "kind": "api"}
        self.write_config()
        os.environ["POFU_OPENAI_API_KEY"] = "sk-test-" + "x" * 30
        try:
            code, out = self.cli("run", "--manifest", str(self.manifest), "--backend", "openai-api")
            self.assertEqual(code, run.EXIT_ERR, out)
            self.assertIn("about $", out)
            self.assertIn("--yes", out)
            # with --yes, a key written into a file under the output folders is refused
            leak = self.tmp / "inbox" / "notes.txt"
            leak.parent.mkdir(parents=True, exist_ok=True)
            leak.write_text("key: " + os.environ["POFU_OPENAI_API_KEY"])
            code, out = self.cli("run", "--manifest", str(self.manifest), "--backend", "openai-api", "--yes")
            self.assertEqual(code, run.EXIT_STOP, out)
            self.assertIn("the API key is written in", out)
            self.assertNotIn(os.environ["POFU_OPENAI_API_KEY"], out)
        finally:
            os.environ.pop("POFU_OPENAI_API_KEY", None)

    def test_external_parent_is_never_generated(self):
        self.manifest.write_text(MANIFEST.replace(
            "    attach:\n      - {ref: station-guide, role: \"the guide\"}\n    prompt:\n      - text: A tea stall.\n"
            "      - block: view-v2\n      - block: prop-style-v2\n", "    external: batch-01-slice\n"), encoding="utf-8")
        m = ["--manifest", str(self.manifest)]
        os.environ["STUB_IMAGE"] = str(save(stall(dx=30, scale=0.95, awning=True, size=1254), self.tmp / "l2.png"))
        code, out = self.cli("plan", *m)
        self.assertIn("external: made by batch-01-slice", out)
        code, out = self.cli("run", *m, "--takes", "1")
        self.assertIn("skip cay-1: external", out)
        self.assertIn("skip cay-2: waiting for cay-1", out)
        self.assertFalse((self.tmp / "stub.log").exists())
        # once the other batch's master is on disk, the edit runs and the parent is never regenerated
        parent = pl.ART_ROOT / "stations" / "cay-1" / "cay-1.png"
        parent.parent.mkdir(parents=True)
        save(stall(), parent)
        code, out = self.cli("run", *m, "--takes", "1")
        self.assertEqual(code, 0, out)
        inbox = self.tmp / "inbox" / "e2e"
        self.assertEqual(sorted(p.name for p in inbox.glob("*.png")), ["station__cay-2--t1.png"])
        code, out = self.cli("ingest", *m, "--job", "cay-1", str(parent))
        self.assertEqual(code, run.EXIT_ERR, out)

    def test_dry_run_sends_nothing(self):
        code, out = self.cli("run", "--manifest", str(self.manifest), "--dry-run")
        self.assertIn("Nothing was sent", out)
        self.assertFalse((self.tmp / "stub.log").exists())


class ApiHelpers(unittest.TestCase):
    def test_redact(self):
        key = "sk-proj-" + "a1" * 20
        self.assertNotIn(key, be.redact(f"bad key {key} and sk-other1234567890abcd", key))
        self.assertNotIn("sk-other1234567890abcd", be.redact("sk-other1234567890abcd", None))

    def test_estimate(self):
        cfg = {"model": "m", "quality": "high", "prices_usd": {"high": {"1024x1024": 0.2, "1536x1024": 0.3}}, "per_reference_usd": 0.01}
        total, _ = be.estimate_cost([((1024, 1024), 2), ((1536, 1024), 0)], cfg)
        self.assertAlmostEqual(total, 0.52)


class EventParsing(unittest.TestCase):
    def test_parse_codex_events(self):
        text = "\n".join([
            "not json",
            json.dumps({"type": "thread.started", "thread_id": "abc"}),
            json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": "/x/y.png"}}),
            json.dumps({"type": "turn.completed"}),
        ])
        ev = be.parse_codex_events(text)
        self.assertEqual((ev["thread_id"], ev["messages"], ev["completed"]), ("abc", ["/x/y.png"], True))


if __name__ == "__main__":
    unittest.main()
