#!/usr/bin/env python3
"""Evidence-driven, local-only recovery ledger for the art operator.

This utility never generates, promotes, pushes, merges, or contacts a remote.
It inspects files and already-fetched Git refs, then records durable evidence.
"""
from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import sys
import tempfile

import yaml
from PIL import Image

HERE = Path(__file__).resolve().parent
DEFAULT_REPO = HERE.parents[1]
EXPECTED_IDENTITY = "Eren Deniz Kuyucaklıoğlu <109629701+ErenDenizK@users.noreply.github.com>"
STAGES = ("generated", "posted", "reviewed", "committed", "upload_verified")


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, default=str)


def digest(value):
    return hashlib.sha256(value if isinstance(value, bytes) else canonical(value).encode()).hexdigest()


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def atomic_json(path: Path, value):
    """Flush bytes, atomically replace, and flush the containing directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    name = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as f:
            name = f.name
            json.dump(value, f, indent=2, ensure_ascii=False, default=str)
            f.write("\n"); f.flush(); os.fsync(f.fileno())
        os.replace(name, path)
        fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    finally:
        if name and os.path.exists(name):
            os.unlink(name)


def connect(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path, timeout=30)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA synchronous=FULL")
    db.execute("PRAGMA busy_timeout=30000")
    db.executescript("""
      CREATE TABLE IF NOT EXISTS snapshots (
        repo TEXT NOT NULL, batch TEXT NOT NULL, hash TEXT NOT NULL, payload TEXT NOT NULL,
        observed_at TEXT NOT NULL, PRIMARY KEY(repo,batch));
      CREATE TABLE IF NOT EXISTS high_water (
        repo TEXT NOT NULL,batch TEXT NOT NULL,job TEXT NOT NULL,max_take INTEGER NOT NULL,
        PRIMARY KEY(repo,batch,job));
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY,at TEXT NOT NULL,kind TEXT NOT NULL,key TEXT NOT NULL,
        payload TEXT NOT NULL,payload_sha256 TEXT NOT NULL,UNIQUE(kind,key,payload_sha256));
      CREATE TABLE IF NOT EXISTS receipts (
        repo TEXT NOT NULL,batch TEXT NOT NULL,job TEXT NOT NULL,stage TEXT NOT NULL,
        source_set TEXT NOT NULL,qa_set TEXT NOT NULL,payload TEXT NOT NULL,
        PRIMARY KEY(repo,batch,job,stage));
      CREATE TABLE IF NOT EXISTS reservations (
        repo TEXT NOT NULL,batch TEXT NOT NULL,job TEXT NOT NULL,round INTEGER NOT NULL,
        request_key TEXT NOT NULL,takes TEXT NOT NULL,at TEXT NOT NULL,
        PRIMARY KEY(repo,batch,job,round),UNIQUE(request_key));
    """)
    return db


def event(db, kind, key, payload):
    encoded = canonical(payload)
    db.execute("INSERT OR IGNORE INTO events(at,kind,key,payload,payload_sha256) VALUES(?,?,?,?,?)",
               (now(), kind, key, encoded, digest(encoded.encode())))


def read_data(path: Path, errors: list, label: str, yaml_ok=False):
    if not path.exists():
        return None
    try:
        data = path.read_bytes()
        value = yaml.safe_load(data) if yaml_ok else json.loads(data)
        if not isinstance(value, dict):
            raise ValueError("expected a mapping")
        return value
    except (OSError, ValueError, yaml.YAMLError) as exc:
        errors.append(f"{label}: unreadable or incomplete ({type(exc).__name__})")
        return None


def git(repo, *args):
    p = subprocess.run(["git", "-C", str(repo), *args], capture_output=True)
    return p.stdout if p.returncode == 0 else None


def file_evidence(path: Path, role: str, errors: list):
    if not path.exists():
        return None
    if role == "original_generated_png" and path.resolve().suffix.lower() not in (".png", ".webp", ".jpg", ".jpeg"):
        errors.append(f"{path}: original source is not an image path")
        return None
    try:
        before = path.stat(); data = path.read_bytes(); after = path.stat()
        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
            errors.append(f"{path}: changed during inspection; retry reconciliation")
            return None
        record = {"path": str(path), "role": role, "sha256": digest(data), "bytes": len(data),
                  "storage": "local_only_no_upload_proof", "decoded": None}
        if path.suffix.lower() in (".png", ".webp", ".jpg", ".jpeg"):
            with Image.open(io.BytesIO(data)) as im:
                im.load()
                record.update(decoded=True, dimensions=list(im.size), mode=im.mode,
                              rgba_sha256=digest(im.convert("RGBA").tobytes()))
        return record
    except (OSError, ValueError) as exc:
        errors.append(f"{path}: incomplete/corrupt local artifact ({type(exc).__name__})")
        return None


def successful_upload_paths(runtime: Path):
    """Logs are evidence only; byte equality with a fetched Git ref is also required."""
    covered = set()
    for p in sorted(runtime.glob("*upload*.log")):
        text = p.read_text(errors="replace")
        if not re.search(r"\d+ file\(s\) checked, 0 problem\(s\)", text):
            continue
        covered.update(re.findall(r"^ok  (.+?) \(\d+ KB\)$", text, re.M))
    return covered


def paths_from_callback(data):
    if not isinstance(data, dict):
        return []
    hint = data.get("output_hint", "")
    found = re.search(r"as (/[^\n]+?\.png) by default", hint)
    return [Path(found.group(1))] if found else []


def archived_report(reports, take):
    value = reports.get(take, reports.get(str(take), {}))
    return value if isinstance(value, dict) else {}


def classify_error(message):
    m = message.lower()
    if any(t in m for t in ("quota", "rate limit", "usage-limit", "usage limit")):
        return "account_or_usage_stop"
    if (any(t in m for t in ("could not read username", "authentication failed", "sign-in", "sign in", "invalid username", "invalid password", "permission denied (publickey"))
            or re.search(r"\bpermission to \S+\.git denied to\b", m)):
        return "account_or_usage_stop"
    if any(t in m for t in ("transport disconnected", "recovery timed out", "no usable execution environment", "offline", "unavailable", "connection refused", "connection reset", "connection aborted", "econnrefused", "econnreset", "broken pipe")):
        return "transient_worker_unavailable_not_job_failure"
    if any(t in m for t in ("ipc frame", "message too large")):
        return "oversized_control_payload_reduce_group_not_regenerate"
    # A socket can refuse a connection and a filesystem can deny permission.
    # Neither is an image-model refusal or an authentication observation.
    model = r"\b(?:model|codex|assistant|image_gen|image(?:[- ]generation)?(?: tool)?)\b"
    refusal = r"\brefus(?:ed|al|es|ing)\b"
    if re.search(model + r"[^.\n]{0,80}" + refusal, m) or re.search(refusal + r"[^.\n]{0,80}" + model, m):
        return "refusal_stop"
    return "needs_inspection_no_success_assumed"


def import_control(body_path: Path, state_dir: Path):
    """Import a supplied PR-body checkpoint; no worker or network access needed."""
    text = body_path.read_text()
    match = re.search(r"<!-- POFU_QUEUE_WATCH_STATE\s*\n(.*?)\n-->", text, re.S)
    if not match:
        raise ValueError("No POFU_QUEUE_WATCH_STATE marker found")
    state = json.loads(match.group(1))
    if state.get("version") != 1:
        raise ValueError("Unsupported control-plane checkpoint version")
    required = {"version", "started_at", "deadline_at", "next_poll_at", "known_batches", "polls", "status", "errors"}
    if not required <= state.keys():
        raise ValueError("Incomplete control-plane checkpoint")
    if not isinstance(state["polls"], list) or not isinstance(state["known_batches"], list):
        raise ValueError("Invalid checkpoint collections")
    checkpoint = {"imported_at": now(), "source_file": str(body_path), "state": state,
                  "note": "Copied supplied remote-checkpoint text; does not prove a new poll or worker health."}
    db = connect(state_dir / "workflow.sqlite3")
    with db:
        event(db, "control_checkpoint_imported", "POFU_QUEUE_WATCH_STATE", state)
    db.close()
    atomic_json(state_dir / "control-watch-checkpoint.json", checkpoint)
    return checkpoint


def scan(repo: Path, batch: str, runtime: Path, db):
    manifest_path = repo / "tools/imagegen/manifest" / (batch + ".yaml")
    m = yaml.safe_load(manifest_path.read_text())
    branch = "art/" + batch + "/all"
    remote = "refs/remotes/origin/" + branch
    head = (git(repo, "rev-parse", "HEAD") or b"").decode().strip()
    fetched_head = (git(repo, "rev-parse", "--verify", remote) or b"").decode().strip() or None
    identity = (git(repo, "log", "-1", "--format=%an <%ae>%n%cn <%ce>") or b"").decode().splitlines()
    identity_ok = len(identity) == 2 and all(x == EXPECTED_IDENTITY for x in identity)
    upload_paths = successful_upload_paths(runtime)
    artifacts = {}
    jobs = []
    stop_path = runtime / "GLOBAL_STOP.json"
    stop = (read_data(stop_path, [], "global stop") or {"reason": "active stop marker is incomplete; preserve stop"}) if stop_path.exists() else None
    for spec in m["jobs"]:
        if spec.get("external"):
            continue
        j = spec["id"]; asset = spec["kind"] + "__" + spec.get("name", j); errors = []
        inbox = repo / "design/art/inbox" / batch
        qa_dir = repo / "build/imagegen" / batch / "qa"
        locked_dir = repo / "build/imagegen" / batch / "locked"
        out = repo / "design/art/takes" / batch / j
        rev_path = out / "review.yaml"; review = read_data(rev_path, errors, "review", True) or {}
        review_reports = review.get("qa_reports", {})
        if not isinstance(review_reports, dict):
            errors.append("archived QA reports are not a mapping")
            review_reports = {}
        published_sources = {int(x["take"]): x for x in review.get("sources", []) if "take" in x}
        recorded_hashes = {str(n): (x.get("original_generated_png_sha256") or x.get("original_png_sha256") or x.get("ingested_png_sha256")) for n, x in published_sources.items() if x.get("original_generated_png_sha256") or x.get("original_png_sha256") or x.get("ingested_png_sha256")}
        for x in review.get("source_recovery", review.get("recovery", {})).get("sources", []):
            if x.get("take") and x.get("sha256"):
                recorded_hashes[str(x["take"])] = x["sha256"]
        callbacks = []
        # Published reviews and takes preserve retry usage even if local caches or
        # the database have been lost. Never turn a lost cache into a new request.
        take_ids = {int(x) for x in review_reports if str(x).isdigit()}
        for p in out.glob(asset + "--t*.webp"):
            match = re.fullmatch(re.escape(asset + "--t") + r"(\d+)\.webp", p.name)
            if match:
                take_ids.add(int(match.group(1)))
        for p in runtime.glob("generated-" + j + "-t*.json"):
            match = re.fullmatch(re.escape("generated-" + j + "-t") + r"(\d+)\.json", p.name)
            if match:
                n = int(match.group(1)); take_ids.add(n)
                callbacks.append((n, p, read_data(p, errors, "callback")))
        for p in inbox.glob(asset + "--t*.png"):
            match = re.fullmatch(re.escape(asset + "--t") + r"(\d+)\.png", p.name)
            if match:
                take_ids.add(int(match.group(1)))
        old = db.execute("SELECT max_take FROM high_water WHERE repo=? AND batch=? AND job=?", (str(repo), batch, j)).fetchone()
        reserved = db.execute("SELECT * FROM reservations WHERE repo=? AND batch=? AND job=? ORDER BY round", (str(repo), batch, j)).fetchall()
        max_seen = max([0, *(take_ids or []), *((old[0],) if old else ()), *([max(json.loads(x["takes"])) for x in reserved])])
        source_set = {}; qa_set = {}; source_details = []; valid_qa = set(); valid_ingest = set(); review_hash_matches = {}
        for n in sorted(take_ids):
            p = inbox / (asset + f"--t{n}.png"); side_path = p.with_suffix(".json")
            side = read_data(side_path, errors, "take sidecar") or {}
            candidates = [x for num, _, data in callbacks if num == n for x in paths_from_callback(data)]
            if side.get("source_file"):
                candidates.append(Path(side["source_file"]))
            if published_sources.get(n, {}).get("source_file"):
                candidates.append(Path(published_sources[n]["source_file"]))
            candidates = list(dict.fromkeys(candidates))
            source_records = []
            for src in candidates:
                rec = file_evidence(src, "original_generated_png", errors)
                if rec:
                    artifacts[str(src)] = rec; source_records.append(rec)
            rec = file_evidence(p, "ingested_png", errors)
            if rec:
                artifacts[str(p)] = rec
                source_set[str(n)] = digest([rec["dimensions"], rec["rgba_sha256"]])
                if source_records and any((x["rgba_sha256"], x["dimensions"]) != (rec["rgba_sha256"], rec["dimensions"]) for x in source_records):
                    errors.append(f"take{n}: ingested pixels differ from original; identity hold")
                elif side.get("take") == n and side.get("job") == j and side.get("fingerprint"):
                    valid_ingest.add(n)
            elif source_records:
                source_set[str(n)] = digest([source_records[0]["dimensions"], source_records[0]["rgba_sha256"]])
            elif str(n) in recorded_hashes:
                source_set[str(n)] = recorded_hashes[str(n)]
            # ingest re-encodes PNG: file bytes can differ while canonical RGBA
            # pixels remain exact. Legacy archive fields named
            # original_png_sha256 sometimes hash that ingested PNG, so retain
            # both byte identities and accept the recorded one, never conflate.
            file_hashes = {x["sha256"] for x in source_records}
            if rec:
                file_hashes.add(rec["sha256"])
            review_hash_matches[str(n)] = (recorded_hashes.get(str(n)) in file_hashes) if file_hashes else str(n) in recorded_hashes
            source_details.append({"take": n, "original_paths": [x["path"] for x in source_records],
                                   "pixel_identity_sha256": source_set.get(str(n)), "fingerprint": side.get("fingerprint"),
                                   "account": side.get("account"), "ingested": n in valid_ingest,
                                   "source_hash_verified_locally": bool(rec or source_records)})
            qpath = qa_dir / (asset + f"--t{n}.json"); q = read_data(qpath, errors, "QA report")
            lock = file_evidence(locked_dir / p.name, "locked_png", errors)
            if lock:
                artifacts[lock["path"]] = lock
            if q and lock and n in valid_ingest and q.get("take") == n and q.get("job") == j and q.get("status") in ("pass", "warn", "fail") and q.get("fingerprint") == side.get("fingerprint"):
                valid_qa.add(n); qa_set[str(n)] = {"report_sha256": digest(q), "locked_sha256": lock["sha256"]}
        set_hash = digest(source_set); qa_hash = digest(qa_set)
        posted = read_data(runtime / (j + "-POSTED.json"), errors, "POSTED flag")
        posted_receipt = db.execute("SELECT * FROM receipts WHERE repo=? AND batch=? AND job=? AND stage='posted'", (str(repo), batch, j)).fetchone()
        if posted_receipt and posted_receipt["source_set"] == set_hash and posted_receipt["qa_set"] == qa_hash:
            posted_state = "hash_bound_current"
        elif posted_receipt:
            posted_state = "STALE_source_or_QA_hashset"
        elif posted and posted.get("source_set_sha256") == set_hash and posted.get("qa_set_sha256") == qa_hash:
            posted_state = "hash_bound_current"
        elif posted and posted.get("source_set_sha256"):
            posted_state = "STALE_source_or_QA_hashset"
        elif posted and posted.get("takes") != len(take_ids):
            posted_state = "STALE_take_inventory_mismatch"
        elif posted:
            posted_state = "legacy_unbound_do_not_trust_without_QA_inventory"
        else:
            posted_state = "absent"
        decision = review.get("jobs", {}).get(j, {})
        reviewed_ids = {int(x) for x in review_reports if str(x).isdigit()}
        review_qa_matches = reviewed_ids == take_ids and all(digest(archived_report(review_reports, n)) == digest(read_data(qa_dir / (asset + f"--t{n}.json"), errors, "QA report")) for n in take_ids)
        hashes_match = set(recorded_hashes) == set(source_set) and all(review_hash_matches.values())
        archived_qa_consistent = reviewed_ids == take_ids and bool(take_ids) and all(
            bool(published_sources.get(n, {}).get("fingerprint")) and published_sources[n]["fingerprint"] == archived_report(review_reports, n).get("fingerprint")
            for n in take_ids)
        pick = decision.get("pick"); publication = decision.get("publication", "")
        is_selection = type(pick) is int
        terminal = bool(is_selection or "skipped" in publication)
        local_review_bound = review_qa_matches and valid_qa == take_ids
        review_bound = bool(terminal and hashes_match and (local_review_bound or archived_qa_consistent))
        if terminal and recorded_hashes and not hashes_match:
            errors.append("manual review source-hash binding differs from current source inventory")
        if pick == "none" and "skipped" in publication and take_ids and max_seen < 4:
            review_bound = False; errors.append("terminal failed-job skip has not exhausted its allowed retry")
        if is_selection:
            selected = archived_report(review_reports, pick)
            valid_selection = (pick in take_ids and selected.get("status") in ("pass", "warn")
                               and selected.get("job") == j and type(selected.get("take")) is int
                               and selected["take"] == pick)
            if not valid_selection or pick in review.get("manual_review", {}).get("exclude", []):
                review_bound = False; errors.append("selected take is absent, invalid, failing or manually excluded")
        elif pick is not None and pick != "none":
            review_bound = False; errors.append("pick must be an integer take ID or none, never a boolean")
        artifact_records = []; committed = True; uploaded = True
        for p in sorted(out.glob("*")) if out.exists() else []:
            if not p.is_file():
                continue
            rec = file_evidence(p, "published_" + ("take" if p.suffix == ".webp" else "contact" if p.name == "contact.jpg" else "review"), errors)
            if not rec:
                committed = uploaded = False; continue
            rel = str(p.relative_to(repo)); rec["repo_path"] = rel
            local_blob = git(repo, "show", head + ":" + rel)
            rec["committed"] = local_blob is not None and digest(local_blob) == rec["sha256"]
            remote_blob = git(repo, "show", remote + ":" + rel) if fetched_head else None
            rec["fetched_ref_bytes_match"] = remote_blob is not None and digest(remote_blob) == rec["sha256"]
            rec["upload_checker_log_covers_path"] = rel in upload_paths
            rec["fetched_head"] = fetched_head
            rec["upload_verified"] = bool(rec["committed"] and rec["fetched_ref_bytes_match"] and rel in upload_paths and rec["bytes"] < 614400 and (rec["decoded"] is not False))
            if rec["upload_verified"]:
                rec["storage"] = "committed_and_fetched_ref_verified_not_a_fresh_network_fetch"
            elif rec["committed"]:
                rec["storage"] = "committed_local_no_complete_upload_proof"
            artifacts[str(p)] = rec; artifact_records.append(rec)
            committed &= rec["committed"]; uploaded &= rec["upload_verified"]
        expected = {str((out / "review.yaml").relative_to(repo))}
        if take_ids:
            expected.add(str((out / "contact.jpg").relative_to(repo)))
            expected.update(str((out / (asset + f"--t{n}.webp")).relative_to(repo)) for n in take_ids)
        bundle_complete = expected <= {a["repo_path"] for a in artifact_records}
        committed = bool(artifact_records) and bundle_complete and committed and identity_ok
        uploaded = bool(artifact_records) and uploaded and committed
        complete_sources = len(source_details) >= 2 and all(x["source_hash_verified_locally"] for x in source_details)
        complete_post = complete_sources and valid_qa == take_ids and valid_ingest == take_ids
        facts = {"generated": complete_sources, "posted": complete_post, "reviewed": review_bound,
                 "committed": committed and review_bound, "upload_verified": uploaded and review_bound and not errors}
        if stop:
            action = "hold_global_stop_preserve_completed_outputs"
        elif max_seen > 4:
            action = "hold_take_cap_violation"
        elif errors:
            action = "inspect_local_evidence_do_not_regenerate"
        elif facts["upload_verified"]:
            action = "take_fragments_verified_no_regeneration"
        elif facts["committed"]:
            action = "verify_existing_commit_upload_no_new_commit"
        elif facts["reviewed"]:
            action = "commit_existing_review_and_artifacts"
        elif complete_post:
            action = "manual_review_existing_candidates"
        elif len(source_set) < max_seen:
            action = "recover_or_await_missing_outputs_do_not_redispatch"
        elif source_set:
            action = "ingest_or_post_existing_sources"
        elif reserved:
            action = "reconcile_unknown_generation_dispatch_do_not_redispatch"
        else:
            action = "initial_pair_may_be_reserved_if_batch_ready"
        jobs.append({"job": j, "scope": "take_fragments_only", "max_take_seen": max_seen, "retry_rounds_used": int(max_seen > 2),
                     "take_ids": sorted(take_ids), "source_set_sha256": set_hash, "qa_set_sha256": qa_hash,
                     "sources": source_details, "posted_flag": posted_state, "review_pick": pick,
                     "publication": publication, "review_binding": "current_local_QA" if local_review_bound else "historical_committed_review_provenance",
                     "reservations": [{"round": x["round"], "request_key": x["request_key"], "takes": json.loads(x["takes"]), "at": x["at"]} for x in reserved],
                     "bundle_complete": bundle_complete, "facts": facts, "errors": sorted(set(errors)), "next_action": action})
    return {"schema": 1, "scope": "take_fragments_only", "scanner_sha256": digest(Path(__file__).read_bytes()), "repo": str(repo), "batch": batch, "batch_status": m.get("status", "open"), "branch": branch, "head": head,
            "fetched_ref": remote, "fetched_head": fetched_head, "identity_ok": identity_ok,
            "manifest_sha256": digest(manifest_path.read_bytes()), "global_stop": stop,
            "jobs": jobs, "artifacts": sorted(artifacts.values(), key=lambda x: x["path"])}


def reconcile(repo, batch, runtime, state_dir):
    db = connect(state_dir / "workflow.sqlite3")
    # Reconciliation is a serialized transaction; process death before COMMIT cannot
    # advance a high-water mark or snapshot. Existing evidence stays authoritative.
    with db:
        db.execute("BEGIN IMMEDIATE")
        snapshot = scan(repo, batch, runtime, db)
        encoded = canonical(snapshot); sha = digest(encoded.encode())
        key = str(repo) + "::" + batch
        for job in snapshot["jobs"]:
            db.execute("INSERT INTO high_water VALUES(?,?,?,?) ON CONFLICT(repo,batch,job) DO UPDATE SET max_take=MAX(max_take,excluded.max_take)",
                       (str(repo), batch, job["job"], job["max_take_seen"]))
        event(db, "reconcile", key, snapshot)
        db.execute("INSERT INTO snapshots VALUES(?,?,?,?,?) ON CONFLICT(repo,batch) DO UPDATE SET hash=excluded.hash,payload=excluded.payload,observed_at=excluded.observed_at",
                   (str(repo), batch, sha, encoded, now()))
    export = {"observed_at": now(), "snapshot_sha256": sha, **snapshot}
    atomic_json(state_dir / "recovery-manifest.json", export)
    summary = {"observed_at": export["observed_at"], "scope": "take_fragments_only", "snapshot_sha256": sha, "batch": batch,
               "head": snapshot["head"], "fetched_head": snapshot["fetched_head"], "identity_ok": snapshot["identity_ok"],
               "jobs": len(snapshot["jobs"]), "take_fragment_sets_upload_verified": sum(j["facts"]["upload_verified"] for j in snapshot["jobs"]),
               "next_actions": [{"job": j["job"], "action": j["next_action"], "errors": j["errors"]} for j in snapshot["jobs"] if j["next_action"] != "take_fragments_verified_no_regeneration"],
               "remaining_checks": "Production masters/raw/provenance/content/Harmony and batch/queue gates are not checked by this helper.",
               "originals_local_only": sum(a["role"] == "original_generated_png" for a in snapshot["artifacts"]),
               "originals_missing_locally": [{"job": j["job"], "take": t["take"]} for j in snapshot["jobs"] for t in j["sources"] if not t["source_hash_verified_locally"]],
               "artifacts_with_fetched_upload_proof": sum(a.get("upload_verified", False) for a in snapshot["artifacts"]),
               "global_stop": snapshot["global_stop"]}
    atomic_json(state_dir / "status.json", summary)
    return db, snapshot, summary


def reserve(db, repo, batch, job, round_number, request_key, initial_pair_confirmed=False, retry_reason=None):
    if round_number not in (0, 1):
        raise ValueError("only initial pair or one retry pair exists")
    with db:
        db.execute("BEGIN IMMEDIATE")
        old = db.execute("SELECT * FROM reservations WHERE request_key=?", (request_key,)).fetchone()
        if old:
            if (old["repo"], old["batch"], old["job"], old["round"]) != (str(repo), batch, job, round_number):
                raise ValueError("request key already belongs to another dispatch")
            return {"request_key": request_key, "takes": json.loads(old["takes"]), "action": "reconcile_existing_reservation_do_not_redispatch"}
        high = db.execute("SELECT max_take FROM high_water WHERE repo=? AND batch=? AND job=?", (str(repo), batch, job)).fetchone()
        used = high[0] if high else 0
        if round_number == 0 and used > 0:
            raise ValueError("initial outputs/reservation already exist; never regenerate the pair")
        if round_number == 1 and used != 2:
            raise ValueError("retry requires exactly the initial pair and no previous retry")
        if round_number == 1 and (not initial_pair_confirmed or not retry_reason):
            raise ValueError("retry requires completed initial-pair evidence and an explicit rejection reason")
        takes = [1, 2] if round_number == 0 else [3, 4]
        db.execute("INSERT INTO reservations VALUES(?,?,?,?,?,?,?)", (str(repo), batch, job, round_number, request_key, canonical(takes), now()))
        db.execute("INSERT INTO high_water VALUES(?,?,?,?) ON CONFLICT(repo,batch,job) DO UPDATE SET max_take=MAX(max_take,excluded.max_take)", (str(repo), batch, job, max(takes)))
        payload = {"request_key": request_key, "takes": takes, "action": "dispatch_reserved_pair_once_then_save_callbacks", "retry_reason": retry_reason}
        event(db, "generation_reserved", str(repo) + "::" + batch + "::" + job, payload)
        return payload


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--repo", type=Path, default=DEFAULT_REPO)
    ap.add_argument("--batch", required=True)
    ap.add_argument("--runtime", type=Path, help="callback/upload-log directory (default: build/operator-state)")
    ap.add_argument("--state-dir", type=Path, help="durable SQLite/JSON directory (default: build/operator-state/recovery)")
    sub = ap.add_subparsers(dest="command", required=True)
    sub.add_parser("reconcile")
    sub.add_parser("status")
    cp = sub.add_parser("checkpoint"); cp.add_argument("--job", required=True); cp.add_argument("--stage", choices=STAGES, required=True); cp.add_argument("--note", default="")
    rs = sub.add_parser("reserve"); rs.add_argument("--job", required=True); rs.add_argument("--round", type=int, choices=(0, 1), required=True); rs.add_argument("--request-key", required=True); rs.add_argument("--retry-reason")
    er = sub.add_parser("classify-error"); er.add_argument("message")
    ctl = sub.add_parser("import-control"); ctl.add_argument("--body", type=Path, required=True)
    wl = sub.add_parser("with-branch-lock"); wl.add_argument("--expected-head"); wl.add_argument("args", nargs=argparse.REMAINDER)
    args = ap.parse_args(argv)
    args.repo = args.repo.resolve()
    args.runtime = (args.runtime or args.repo / "build/operator-state").resolve()
    args.state_dir = (args.state_dir or args.runtime / "recovery").resolve()
    if args.command == "classify-error":
        print(classify_error(args.message)); return 0
    if args.command == "import-control":
        print(json.dumps(import_control(args.body, args.state_dir), indent=2)); return 0
    repo = args.repo.resolve(); args.state_dir.mkdir(parents=True, exist_ok=True)
    if args.command == "with-branch-lock":
        # flock is released by the kernel on process death. Metadata is evidence,
        # never a stale PID lock that needs manual deletion.
        branch = "art/" + args.batch + "/all"
        common = (git(repo, "rev-parse", "--git-common-dir") or str(repo).encode()).decode().strip()
        key = digest(str((repo / common).resolve()) + "::" + branch)[:16]
        with (args.state_dir / ("branch-" + key + ".lock")).open("a+") as writer:
            fcntl.flock(writer, fcntl.LOCK_EX)
            if (args.runtime / "GLOBAL_STOP.json").exists():
                raise SystemExit("Global stop active; branch writer not started")
            head = (git(repo, "rev-parse", "HEAD") or b"").decode().strip()
            if args.expected_head and args.expected_head != head:
                raise SystemExit("Branch head changed; reconcile before mutation")
            command = args.args[1:] if args.args[:1] == ["--"] else args.args
            if not command:
                raise SystemExit("No command supplied")
            atomic_json(args.state_dir / ("branch-" + key + "-owner.json"), {"pid": os.getpid(), "at": now(), "head": head, "branch": branch})
            # The child keeps the same open-file-description lock if this
            # wrapper is interrupted while the command is still running.
            return subprocess.run(command, cwd=repo, pass_fds=(writer.fileno(),)).returncode
    lock_path = args.state_dir / ("reconcile-" + digest(str(repo) + "::" + args.batch)[:16] + ".lock")
    with lock_path.open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        db, snapshot, summary = reconcile(repo, args.batch, args.runtime, args.state_dir)
        if args.command == "checkpoint":
            job = next((j for j in snapshot["jobs"] if j["job"] == args.job), None)
            if not job or not job["facts"][args.stage]:
                raise SystemExit("Evidence does not establish this completed stage; no receipt written")
            if snapshot["global_stop"]:
                raise SystemExit("Global stop active; no new completion receipt")
            payload = {"scope": "take_fragments_only", "stage": args.stage, "job": args.job, "head": snapshot["head"], "fetched_head": snapshot["fetched_head"], "note": args.note,
                       "source_set_sha256": job["source_set_sha256"], "qa_set_sha256": job["qa_set_sha256"]}
            with db:
                db.execute("INSERT OR REPLACE INTO receipts VALUES(?,?,?,?,?,?,?)", (str(repo), args.batch, args.job, args.stage, job["source_set_sha256"], job["qa_set_sha256"], canonical(payload)))
                event(db, "checkpoint", str(repo) + "::" + args.batch + "::" + args.job, payload)
            print(canonical(payload))
        elif args.command == "reserve":
            if snapshot["global_stop"]:
                raise SystemExit("Global stop active; no dispatch reserved")
            if snapshot["batch_status"] != "open":
                raise SystemExit("Batch is not open; no dispatch reserved")
            job = next((j for j in snapshot["jobs"] if j["job"] == args.job), None)
            if not job or job["facts"]["reviewed"] or job["errors"]:
                raise SystemExit("Job missing, already decided or held for evidence inspection")
            result = reserve(db, repo, args.batch, args.job, args.round, args.request_key,
                             initial_pair_confirmed=job["facts"]["posted"] and job["take_ids"] == [1, 2],
                             retry_reason=args.retry_reason)
            # Export the durable reservation before allowing a caller to dispatch.
            # A crash between DB commit and export is recovered from WAL next run.
            db.close()
            db, _, _ = reconcile(repo, args.batch, args.runtime, args.state_dir)
            print(canonical(result))
        else:
            print(json.dumps(summary, indent=2))
        db.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
