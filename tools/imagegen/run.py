#!/usr/bin/env python3
"""Pofu image pipeline: manifest -> generation -> style lock and QA -> review -> masters.

    python3 -I tools/imagegen/run.py plan     --manifest tools/imagegen/manifest/batch-01-slice.yaml
    python3 -I tools/imagegen/run.py prompt   --manifest ... --job tea-stall-1
    python3 -I tools/imagegen/run.py run      --manifest ... [--backend codex|manual|openai-api] [--only ID ...] [--dry-run]
    python3 -I tools/imagegen/run.py ingest   --manifest ... --job tea-stall-1 ~/Downloads/file.png [...]
    python3 -I tools/imagegen/run.py post     --manifest ...
    python3 -I tools/imagegen/run.py promote  --manifest ...
    python3 -I tools/imagegen/run.py palette-card --palette world-props --out design/reference/palette-card-world-props.png

The whole workflow, the roles and the first-run checklist are in
docs/design/art-pipeline.md. Account and etiquette rules are in
AGENTS.md: one generation at a time, pauses, small batches, stop on the
first limit message.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import math
import os
import shutil
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import backends as be  # noqa: E402
import check_upload as cu  # noqa: E402
import pipeline as pl  # noqa: E402
from legacy_ids import canonical  # noqa: E402
import qa  # noqa: E402
import review as rv  # noqa: E402
import style_lock as sl  # noqa: E402

EXIT_OK, EXIT_ERR, EXIT_STOP = 0, 1, 3


def now() -> str:
    return dt.datetime.now().astimezone().isoformat(timespec="seconds")


def rel(p: Path) -> str:
    try:
        return str(Path(p).resolve().relative_to(pl.REPO_ROOT))
    except ValueError:
        return str(p)


# ---------------------------------------------------------------------------
# Job state
# ---------------------------------------------------------------------------

def existing_takes(job: pl.Job, inbox: Path) -> list[tuple[int, Path, dict]]:
    out = []
    for p in sorted(inbox.glob(f"{job.asset}--t*.png")):
        try:
            n = int(p.stem.rsplit("--t", 1)[1])
        except (IndexError, ValueError):
            continue
        out.append((n, p, pl.read_sidecar(p)))
    return sorted(out)


def job_refs(job: pl.Job, m: pl.Manifest) -> list[tuple[pl.Attach, Path]]:
    return [(a, pl.resolve_ref(a.ref, m)) for a in pl.attachments_for(job)]


def job_state(job: pl.Job, m: pl.Manifest, config: dict, background: str) -> dict:
    deps = pl.dependencies(job)
    blocked = [d for d in deps if not pl.approved_image(m.job(d)).exists()]
    refs = job_refs(job, m)
    missing = [rel(p) for a, p in refs if not p.exists() and not a.ref.startswith("approved:")]
    prompt = pl.compose_prompt(job, background)
    fp = pl.fingerprint(prompt, [p for _, p in refs]) if not blocked and not missing else None
    takes = existing_takes(job, pl.inbox_dir(config, m.batch))
    fresh = [t for t in takes if fp and t[2].get("fingerprint") == fp]
    return {"approved": pl.approved_image(job).exists(), "external": job.external, "blocked": blocked, "missing": missing,
            "prompt": prompt, "fingerprint": fp, "takes": takes, "fresh": fresh, "refs": refs}


def background_mode(args, config) -> str:
    return getattr(args, "background", None) or config["backends"]["codex"].get("background", "transparent")


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_plan(args, config, m: pl.Manifest) -> int:
    bg = background_mode(args, config)
    print(f"{m.batch}: {m.title}\n")
    for job in m.jobs:
        st = job_state(job, m, config, bg)
        if st["approved"]:
            state = "approved" + (f" (made by {job.external})" if job.external else "")
        elif job.external:
            state = f"external: made by {job.external}; fetch its master, never generate it here"
        elif st["blocked"]:
            state = "waiting for approval of " + ", ".join(st["blocked"])
        elif st["missing"]:
            state = "missing reference " + ", ".join(st["missing"])
        else:
            state = f"ready ({len(st['fresh'])}/{job.variants} takes)"
        stale = len(st["takes"]) - len(st["fresh"])
        print(f"  {job.id:18s} {job.kind:8s} {state}" + (f" · {stale} stale take(s) from an older prompt" if stale and st["fingerprint"] else ""))
    return EXIT_OK


def cmd_prompt(args, config, m: pl.Manifest) -> int:
    job = m.job(args.job)
    if job.external:
        path = pl.approved_image(job)
        print(f"{job.id} is external: {job.external} generates it; here it is only a parent or a reference.")
        print(f"  {rel(path)}{'' if path.exists() else '  (missing: fetch it)'}")
        return EXIT_OK
    st = job_state(job, m, config, background_mode(args, config))
    print(st["prompt"])
    print("--- attachments, in order:")
    for a, p in st["refs"]:
        print(f"  {rel(p)}{'' if p.exists() else '  (missing)'}  [{a.role}]")
    return EXIT_OK


class RunLock:
    """One generation run at a time on this machine."""

    def __init__(self, path: Path):
        self.path = path

    def __enter__(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if self.path.exists():
            raise SystemExit(f"Another run holds {rel(self.path)} (pid {self.path.read_text().strip()}). "
                             "If no run is active, delete the file.")
        self.path.write_text(str(os.getpid()))
        return self

    def __exit__(self, *exc):
        self.path.unlink(missing_ok=True)


def cmd_run(args, config, m: pl.Manifest) -> int:
    rate = config["rate"]
    bg = background_mode(args, config)
    pause = args.pause if args.pause is not None else rate["pause_seconds"]
    max_images = min(args.max_images or rate["max_images_per_run"], rate["max_images_per_run"])
    per_job_cap = min(args.takes or rate["max_takes_per_job"], rate["max_takes_per_job"])
    inbox = pl.inbox_dir(config, m.batch)
    log_path = pl.build_dir(config, m.batch) / "run-log.jsonl"
    jobs = [j for j in m.jobs if not args.only or j.id in [canonical(o) for o in args.only]]

    if args.backend == "manual":
        problem = generation_gate(m, config, "manual")
        if problem:
            print(problem)
            return EXIT_ERR
        return write_manual_pack(jobs, m, config, bg, per_job_cap)

    plan = []
    for job in jobs:
        st = job_state(job, m, config, bg)
        if job.external:
            if not st["approved"]:
                print(f"skip {job.id}: external, made by {job.external}; fetch its master")
            continue
        if st["approved"] and not args.redo_approved:
            continue
        if st["blocked"] or st["missing"]:
            print(f"skip {job.id}: " + ("waiting for " + ", ".join(st["blocked"]) if st["blocked"] else "missing " + ", ".join(st["missing"])))
            continue
        want = max(0, min(job.variants, per_job_cap) - len(st["fresh"]))
        next_n = max([t[0] for t in st["takes"]] + [0]) + 1
        for k in range(want):
            plan.append((job, st, next_n + k))
    if not plan:
        print("Nothing to generate: every ready job has its takes. Run `post`, then review.")
        return EXIT_OK
    if len(plan) > max_images:
        print(f"Plan has {len(plan)} generations; this run makes the first {max_images} (max_images_per_run).")
        plan = plan[:max_images]

    if args.dry_run:
        for job, st, n in plan:
            print(f"[dry-run] {job.id} t{n} -> {rel(inbox / job.take_file(n))}  fingerprint {st['fingerprint']}")
            if args.backend == "codex":
                cmd = be.codex_command(config["backends"]["codex"], Path("<scratch>"), Path("<scratch>/last-message.txt"),
                                       [Path(f"<scratch>/ref-{i}{p.suffix if p.suffix in ('.png', '.jpg', '.jpeg') else '.png'}")
                                        for i, (_, p) in enumerate(st["refs"], 1)])
                print("          " + " ".join(cmd))
        eta = len(plan) * 60 + (len(plan) - 1) * pause
        print(f"\n{len(plan)} generation(s), about {math.ceil(eta / 60)} min with {pause} s pauses. Nothing was sent.")
        return EXIT_OK

    problem = generation_gate(m, config, args.backend)
    if problem:
        print(problem)
        return EXIT_ERR
    account = dict(config["account"])

    key = None
    if args.backend == "openai-api":
        api = config["backends"]["openai-api"]
        total, lines = be.estimate_cost([(job.size, len(st["refs"])) for job, st, _ in plan], api)
        print("\n".join(lines))
        if not args.yes:
            print("Nothing was sent. Re-run with --yes to accept this estimate and bill the founder's API account.")
            return EXIT_ERR
        try:
            key, source = be.read_api_key(api)
            roots = {pl.REPO_ROOT, pl.inbox_dir(config, m.batch).parent, pl.build_dir(config, m.batch).parent}
            be.key_guard(key, sorted(roots))
        except be.BackendError as err:
            print(f"ERROR: {be.redact(str(err), key)}")
            return EXIT_STOP
        account["key_source"] = source  # where the key came from, never the key
        account["estimate_usd"] = round(total, 2)

    made = 0
    with RunLock(pl.build_dir(config, m.batch).parent / ".run.lock"):
        for i, (job, st, n) in enumerate(plan):
            if i:
                print(f"  pausing {pause} s")
                time.sleep(pause)
            out = inbox / job.take_file(n)
            req = be.Request(prompt=st["prompt"], references=[p for _, p in st["refs"]], out=out, size=job.size,
                             transparent=job.transparent and bg == "transparent", timeout=rate["timeout_seconds"])
            print(f"generate {job.id} t{n} ({i + 1}/{len(plan)}) ...", flush=True)
            try:
                if args.backend == "codex":
                    res = be.run_codex(req, config["backends"]["codex"])
                else:
                    res = be.run_openai_api(req, config["backends"]["openai-api"], key)
            except be.BackendError as err:
                message, raw = be.redact(str(err), key), be.redact(err.raw or "", key)
                log(log_path, {"event": "error", "job": job.id, "take": n, "message": message, "stop": err.stop, "raw": raw})
                print(f"  ERROR: {message}")
                if raw:
                    print("  last output:\n    " + raw.strip().replace("\n", "\n    ")[-1200:])
                if err.stop:
                    print(f"Stopped after {made} image(s). Read the error, then decide; do not loop.")
                    return EXIT_STOP
                continue
            side = {"job": job.id, "take": n, "batch": m.batch, "fingerprint": st["fingerprint"], "prompt": st["prompt"],
                    "attachments": [{"path": rel(p), "role": a.role, "sha256": pl.sha256_file(p)} for a, p in st["refs"]],
                    "background": bg, "generated_at": now(), "seconds": round(res.seconds, 1), "account": account, **res.meta}
            out.with_suffix(".json").write_text(json.dumps(side, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            log(log_path, {"event": "generated", "job": job.id, "take": n, "seconds": round(res.seconds, 1)})
            made += 1
            print(f"  saved {rel(out)} in {res.seconds:.0f} s")
    print(f"\nDone: {made} image(s). Next: run.py post --manifest {rel(m.path)}")
    return EXIT_OK


ACCOUNT_KIND_FOR_BACKEND = {"codex": "chatgpt-plan", "manual": "chatgpt-plan", "openai-api": "api"}


def generation_gate(m: pl.Manifest, config: dict, backend: str) -> str | None:
    """Why this run must not generate, or None. Checked before anything is sent."""
    if m.status != "open":
        return (f"Batch {m.batch} is {m.status}; nothing is generated until it is opened in a reviewed PR.\n"
                + "".join(f"  blocked on: {b}\n" for b in m.blocked_on) + "  (plan, prompt and --dry-run still work.)")
    account = config.get("account") or {}
    if not str(account.get("owner", "")).strip() or account.get("kind") not in ("chatgpt-plan", "api"):
        return ("Fill in `account.owner` and `account.kind` in tools/imagegen/config.yaml first. Production art is "
                "generated only on the founder's own OpenAI account, and provenance names that owner.")
    want = ACCOUNT_KIND_FOR_BACKEND[backend]
    if account["kind"] != want:
        return f"The {backend} backend needs account.kind {want}, but the config says {account['kind']}."
    return None


def log(path: Path, entry: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "a", encoding="utf-8") as f:
        f.write(json.dumps({"at": now(), **entry}, ensure_ascii=False) + "\n")


def write_manual_pack(jobs, m, config, bg, per_job_cap) -> int:
    inbox = pl.inbox_dir(config, m.batch)
    entries = [f"# Manual pack: {m.batch}\n\n{m.title}\n\nPaste each prompt into ChatGPT (Images), attach the files in order, "
               f"download each result, then run `run.py ingest --manifest {rel(m.path)} --job <id> <files>`.\n"]
    count = 0
    for job in jobs:
        st = job_state(job, m, config, bg)
        if job.external or st["approved"] or st["blocked"] or st["missing"]:
            continue
        want = max(0, min(job.variants, per_job_cap) - len(st["fresh"]))
        if not want:
            continue
        first = max([t[0] for t in st["takes"]] + [0]) + 1
        names = [rel(inbox / job.take_file(first + k)) for k in range(want)]
        entries.append(be.manual_entry(job.id, job.chat, st["prompt"], [(a.role, rel(p)) for a, p in st["refs"]], names, want))
        count += want
    out = pl.build_dir(config, m.batch) / "manual-pack.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(entries), encoding="utf-8")
    print(f"Wrote {rel(out)}: {count} generation(s) for the jobs that are ready.")
    return EXIT_OK


def cmd_ingest(args, config, m: pl.Manifest) -> int:
    job = m.job(args.job)
    if job.external:
        print(f"{job.id} is external: ingest its takes with {job.external}'s manifest.")
        return EXIT_ERR
    bg = background_mode(args, config)
    st = job_state(job, m, config, bg)
    owner = (args.account_owner or (config.get("account") or {}).get("owner") or "").strip()
    if not owner:
        print("Whose account made these images? Set account.owner in config.yaml or pass --account-owner. "
              "Production art comes only from the founder's own account.")
        return EXIT_ERR
    inbox = pl.inbox_dir(config, m.batch)
    inbox.mkdir(parents=True, exist_ok=True)
    n = max([t[0] for t in st["takes"]] + [0])
    for f in args.files:
        n += 1
        out = inbox / job.take_file(n)
        with Image.open(f) as im:
            im.save(out)
        side = {"job": job.id, "take": n, "batch": m.batch, "fingerprint": st["fingerprint"], "prompt": st["prompt"],
                "attachments": [{"path": rel(p), "role": a.role} for a, p in st["refs"]], "background": bg,
                "generated_at": now(), "backend": args.source, "source_file": str(f),
                "account": {"owner": owner, "kind": args.account_kind or (config.get("account") or {}).get("kind", "")}}
        out.with_suffix(".json").write_text(json.dumps(side, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"ingested {f} -> {rel(out)}")
    return EXIT_OK


def load_meta(job: pl.Job) -> dict:
    p = pl.approved_dir(job) / "meta.json"
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else {}


def cmd_post(args, config, m: pl.Manifest) -> int:
    presets = sl.load_presets()
    inbox = pl.inbox_dir(config, m.batch)
    out_dir = pl.build_dir(config, m.batch)
    rows, takes_by_job = [], {}
    worst = "pass"
    for job in m.jobs:
        if args.only and job.id not in [canonical(o) for o in args.only]:
            continue
        takes = existing_takes(job, inbox)
        if not takes:
            continue
        preset_name, preset = sl.preset_for(job.kind, presets)
        parent_locked, registration, parent_img = None, None, None
        if job.edit_of:
            pj = m.job(job.edit_of)
            if pl.approved_image(pj).exists():
                parent_locked = sl.load_rgba(pl.approved_image(pj))
                parent_img = Image.open(pl.approved_image(pj)).copy()
                # The edit is drawn on the approved master, which is already
                # on the anchor: applying the chain root's registration again
                # moved bagel-cart-2 and workshop-2 110 px off their parent and
                # failed edit_stability (batch 03). align_to_parent handles
                # any drift the edit itself introduces.
                registration = dict(qa.EDIT_REGISTRATION)
        row = {"job": job.id, "kind": f"{job.kind} · {preset_name}", "parent": parent_img, "takes": [],
               "notes": [f"{len(takes)} take(s)", f"variants {job.variants}"]}
        results = []
        for n, path, side in takes:
            raw = sl.load_rgba(path)
            res = qa.process_take(raw, job.kind, job.canvas, preset, list(dict.fromkeys(config["palettes"][job.kind] + job.palettes)),
                                  {**job.acceptance, **({"exploration": True} if qa.is_exploration(job.id, job.acceptance) else {})},
                                  registration=registration, parent_locked=parent_locked,
                                  register_root=((job.kind == "station" or bool(job.decor)) and not job.edit_of),
                                  transparent=job.transparent, decor=job.decor, light=job.light)
            locked_path = out_dir / "locked" / path.name
            sl.save_rgba(res.locked, locked_path)
            report = {"job": job.id, "take": n, "status": res.status, "preset": preset_name,
                      "checks": [c.as_dict() for c in res.checks], "info": res.info, "fingerprint": side.get("fingerprint")}
            (out_dir / "qa").mkdir(parents=True, exist_ok=True)
            (out_dir / "qa" / f"{path.stem}.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
            bad = [c for c in res.checks if c.status != "pass"]
            lines = [f"{c.status}: {c.name}" for c in bad][:4] or ["all checks pass"]
            img = Image.open(locked_path).copy()
            t = {"n": n, "image": img, "status": res.status, "lines": lines,
                 "summary": "; ".join(f"{c.name} {c.status}" for c in bad) or "all pass"}
            if job.kind == "icon":
                t["icon_strip"] = rv.icon_strip(img, 72)
            row["takes"].append(t)
            results.append(t)
            worst = qa.worst([worst, res.status])
            print(f"{job.id} t{n}: {res.status}" + "".join(f"\n    {c.status}: {c.name}: {c.message}" for c in bad))
        rows.append(row)
        takes_by_job[job.id] = results
    if not rows:
        print("No takes in the inbox for this manifest.")
        return EXIT_OK
    sheet = rv.contact_sheet(rows, f"Pofu · {m.batch}", pl.contact_sheet_path(config, m.batch))
    small = rv.small_copy(sheet, pl.review_file(config, m.batch).with_name(f"{m.batch}-contact.jpg"))
    rv.update_review(pl.review_file(config, m.batch), m.batch, rel(m.path), takes_by_job, rel(small))
    print(f"\nContact sheet: {rel(sheet)} (full) and {rel(small)} (for the PR)")
    print(f"Review file:   {rel(pl.review_file(config, m.batch))}  (set pick: <take> per job, then run promote)")
    return EXIT_OK


def cmd_promote(args, config, m: pl.Manifest) -> int:
    review_path = pl.review_file(config, m.batch)
    review = rv.load_review(review_path)
    if not review:
        print(f"No review file at {rel(review_path)}. Run post first.")
        return EXIT_ERR
    presets = json.loads(sl.PRESETS_PATH.read_text(encoding="utf-8"))
    inbox, out_dir = pl.inbox_dir(config, m.batch), pl.build_dir(config, m.batch)
    changed = False
    only = set(getattr(args, "only", None) or [])
    for job_id, pick in rv.decisions(review).items():
        if not isinstance(pick, int):
            continue
        if only and job_id not in only:  # parallel tasks promote only their own job
            continue
        job = m.job(job_id)
        entry = review["jobs"][job_id]
        if (entry.get("approved") or {}).get("take") == pick and pl.approved_image(job).exists():
            continue
        raw_path = inbox / job.take_file(pick)
        locked_path = out_dir / "locked" / job.take_file(pick)
        qa_path = out_dir / "qa" / f"{Path(job.take_file(pick)).stem}.json"
        if not (raw_path.exists() and locked_path.exists() and qa_path.exists()):
            print(f"{job_id}: take t{pick} is not processed; run post first")
            continue
        report = json.loads(qa_path.read_text(encoding="utf-8"))
        if not (pl.read_sidecar(raw_path).get("account") or {}).get("owner"):
            print(f"{job_id}: t{pick} has no generating account owner on record; it cannot become a master")
            continue
        if report["status"] == "fail" and not args.force:
            print(f"{job_id}: t{pick} failed QA; approve it only with --force and a note in the review file")
            continue
        dest = pl.approved_dir(job)
        if pl.approved_image(job).exists() and not args.force:
            print(f"{job_id}: already has an approved master (later levels depend on it); use --force to replace it")
            continue
        dest.mkdir(parents=True, exist_ok=True)
        # The unlocked source is always kept (AGENTS.md, Uploads): the look
        # can be re-locked from it, never from the locked master.
        raw_kept, raw_encoding = cu.save_raw(raw_path, dest)
        shutil.copyfile(locked_path, pl.approved_image(job))
        side = pl.read_sidecar(raw_path)
        meta = {"job": job.id, "batch": m.batch, "asset": job.asset, "take": pick,
                "takes_considered": len(existing_takes(job, inbox)), "approved_at": now(),
                "image": rel(pl.approved_image(job)), "raw": rel(raw_kept), "raw_encoding": raw_encoding,
                "fingerprint": side.get("fingerprint"), "prompt": side.get("prompt", ""),
                "attachments": side.get("attachments", []),
                "generation": {k: side.get(k) for k in ("backend", "model", "quality", "thread_id", "generated_at", "seconds", "background")},
                "account": side.get("account") or {},
                "style_lock": {"preset": report["preset"], "version": presets.get("version")},
                "registration": report["info"].get("registration"), "alignment": report["info"].get("alignment"),
                "qa": {"status": report["status"], "checks": report["checks"]}, "note": entry.get("note", "")}
        if job.slice:
            meta["slice"] = job.slice
        if job.edit_of and not meta["registration"]:
            meta["registration"] = load_meta(m.job(job.edit_of)).get("registration")
        (dest / "meta.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        (dest / "provenance.md").write_text(rv.provenance_md(job, meta), encoding="utf-8")
        entry["approved"] = {"take": pick, "at": meta["approved_at"]}
        changed = True
        print(f"{job_id}: approved t{pick} -> {rel(pl.approved_image(job))}")
    if changed:
        rv.save_review(review_path, review, rel(m.path))
    print("\nNow ready:")
    return cmd_plan(args, config, m)


def cmd_palette_card(args, config, m) -> int:
    sets = qa.palette_sets([args.palette])
    colors = [c for v in sets.values() for c in v]
    size, cols, margin, gap = 1024, 4, 64, 24
    cell = (size - 2 * margin - (cols - 1) * gap) // cols
    rows = math.ceil(len(colors) / cols)
    card = Image.new("RGB", (size, 2 * margin + rows * cell + (rows - 1) * gap), (255, 246, 236))
    d = ImageDraw.Draw(card)
    for i, c in enumerate(colors):
        r, k = divmod(i, cols)
        x, y = margin + k * (cell + gap), margin + r * (cell + gap)
        d.rounded_rectangle((x, y, x + cell, y + cell), radius=cell // 4, fill=c)
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    card.save(args.out, optimize=True)
    print(f"Wrote {args.out} ({len(colors)} swatches, no text)")
    return EXIT_OK


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="run.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    def add(name, help_text, manifest=True):
        sp = sub.add_parser(name, help=help_text)
        if manifest:
            sp.add_argument("--manifest", required=True)
        sp.add_argument("--config", default=str(pl.CONFIG_PATH))
        sp.add_argument("--background", choices=["transparent", "chroma"], help="override backends.codex.background")
        return sp

    add("plan", "list jobs, their state and what is ready")
    sp = add("prompt", "print one job's composed prompt and attachments")
    sp.add_argument("--job", required=True)
    sp = add("run", "generate the missing takes of ready jobs")
    sp.add_argument("--backend", choices=["codex", "manual", "openai-api"], default="codex")
    sp.add_argument("--only", nargs="+", help="job ids")
    sp.add_argument("--takes", type=int, help="takes per job this run (capped by config)")
    sp.add_argument("--pause", type=int, help="seconds between generations (default from config)")
    sp.add_argument("--max-images", type=int, help="images this run (capped by config)")
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--redo-approved", action="store_true", help="also generate for jobs that are already approved")
    sp.add_argument("--yes", action="store_true", help="accept the printed cost estimate (required for --backend openai-api)")
    sp = add("ingest", "add externally made images (ChatGPT downloads) as takes")
    sp.add_argument("--job", required=True)
    sp.add_argument("--source", default="manual-chatgpt")
    sp.add_argument("--account-owner", help="whose OpenAI account made the files (default: config account.owner)")
    sp.add_argument("--account-kind", help="chatgpt-plan or api (default: config account.kind)")
    sp.add_argument("files", nargs="+")
    sp = add("post", "style-lock and QA every take, build the contact sheet and the review file")
    sp.add_argument("--only", nargs="+")
    sp = add("promote", "copy approved takes to design/art/{masters,stations,ui}")
    sp.add_argument("--only", nargs="+", help="job ids (parallel mode: promote only this task's job)")
    sp.add_argument("--force", action="store_true")
    sp = add("palette-card", "render a palette card from tokens or palettes.json", manifest=False)
    sp.add_argument("--palette", required=True)
    sp.add_argument("--out", required=True)
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    config = pl.load_config(Path(args.config))
    m = None
    if getattr(args, "manifest", None):
        try:
            m = pl.load_manifest(Path(args.manifest), config)
        except pl.ManifestError as err:
            print(f"manifest error: {err}")
            return EXIT_ERR
    handler = {"plan": cmd_plan, "prompt": cmd_prompt, "run": cmd_run, "ingest": cmd_ingest, "post": cmd_post,
               "promote": cmd_promote, "palette-card": cmd_palette_card}[args.cmd]
    return handler(args, config, m)


if __name__ == "__main__":
    sys.exit(main())
