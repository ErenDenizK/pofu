"""Generation backends: codex, openai-api, manual.

A backend turns one request (prompt text plus reference images) into one
image file. It knows nothing about manifests, QA or review. Production art
is generated only on the founder's own OpenAI account (config `account`);
which of the two paths he uses is his decision:

    codex       OpenAI Codex CLI signed in with his ChatGPT plan; runs
                `codex exec` non-interactively and copies the image Codex
                saved. Refuses to run if OPENAI_API_KEY is set, so a plan
                run can never silently bill an API account.
    openai-api  the Images API with his own API key, read from the macOS
                Keychain or POFU_OPENAI_API_KEY in his local shell; the key
                is never written, logged or committed (key_guard), and every
                run prints a cost estimate and needs --yes.
    manual      no generation: writes a copy-paste pack for ChatGPT.
"""
from __future__ import annotations

import base64
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


class BackendError(RuntimeError):
    """A generation failed. `stop` means stop the whole run (limits, auth)."""

    def __init__(self, message: str, stop: bool = False, raw: str = ""):
        super().__init__(message)
        self.stop = stop
        self.raw = raw


@dataclass
class Request:
    prompt: str
    references: list[Path]
    out: Path
    size: tuple[int, int]
    transparent: bool
    timeout: int = 600


@dataclass
class Result:
    path: Path
    seconds: float
    meta: dict = field(default_factory=dict)


# Words that mean "stop for today" rather than "try again".
LIMIT_RE = re.compile(r"(rate.?limit|usage limit|too many requests|\b429\b|quota|limit reached|try again (later|in)|"
                      r"you've hit|you have hit|exceeded)", re.I)
AUTH_RE = re.compile(r"(not (logged|signed) in|log ?in|sign ?in|unauthori[sz]ed|\b401\b|\b403\b|authenticat|"
                     r"token (expired|invalid)|refresh token)", re.I)
REFUSAL_RE = re.compile(r"(can'?t|cannot|unable to|not able to|won'?t) (help|create|generate|make|produce)|"
                        r"(no|not have an?) image (generation )?tool|content polic", re.I)


def stage_references(refs: list[Path], scratch: Path) -> list[Path]:
    """Copy references to ref-1.png, ref-2.png ... in a scratch folder.

    Codex splits --image values on commas and silently skips files it cannot
    open, so every reference is checked here, converted to PNG when it is
    not PNG or JPEG, and given a comma-free name.
    """
    out = []
    for i, src in enumerate(refs, 1):
        if not src.exists():
            raise BackendError(f"reference image missing: {src}")
        ext = src.suffix.lower()
        if ext in (".png", ".jpg", ".jpeg"):
            dst = scratch / f"ref-{i}{ext}"
            shutil.copyfile(src, dst)
        else:
            dst = scratch / f"ref-{i}.png"
            with Image.open(src) as im:
                im.save(dst)
        out.append(dst)
    return out


# ---------------------------------------------------------------------------
# codex
# ---------------------------------------------------------------------------

CODEX_TASK = (
    "Use your built-in image generation tool exactly once to generate the image described below. "
    "Do not run shell commands, do not edit or create files yourself, and do not ask questions. "
    "When the image is saved, reply with only its full file path.\n"
    "{refs}\n\nIMAGE PROMPT:\n{prompt}"
)


def codex_task(prompt: str, n_refs: int) -> str:
    refs = ("The attached images are the references listed in the prompt, in the same order."
            if n_refs else "There are no attached images.")
    return CODEX_TASK.format(refs=refs, prompt=prompt)


# ============================================================================
# CODEX ADAPTER: the only place that knows Codex's command line and where it
# stores images. Verified against the openai/codex source on GitHub
# (2026-11-01): `codex exec` flags --json, -o/--output-last-message, -C,
# -s/--sandbox, --skip-git-repo-check, --ephemeral, --ignore-user-config,
# -i/--image (comma-delimited), -c key=value; the `image_generation`
# feature is stable and on by default. NOT verified by us (reported by
# community wrappers tested with codex-cli 0.159.2): that images land in
# $CODEX_HOME/generated_images/<thread_id>/, that `thread.started` carries
# the thread id, and whether the tool honours a transparent background.
# The first-run checklist (docs/design/art-pipeline.md) verifies these on
# the Mac; adjust only this block if they differ.
# ============================================================================

def codex_command(cfg: dict, scratch: Path, last_message: Path, refs: list[Path]) -> list[str]:
    args = [cfg.get("binary", "codex"), "exec", "--skip-git-repo-check", "--ephemeral", "--ignore-user-config",
            "--json", "-s", "read-only", "-C", str(scratch), "-o", str(last_message)]
    for feat in cfg.get("disable_features", []):
        args += ["-c", f"features.{feat}=false"]
    args += ["-c", "features.image_generation=true"]
    args += list(cfg.get("extra_args", []))
    # --image=FILE takes exactly one value each; images go last and there is
    # no positional prompt: with none given, `codex exec` reads the task
    # from stdin.
    args += [f"--image={p}" for p in refs]
    return args


def codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex").resolve()


def parse_codex_events(text: str) -> dict:
    """Read `codex exec --json` JSONL: thread id, messages, errors."""
    out = {"thread_id": None, "messages": [], "errors": [], "completed": False, "failed": False}
    for line in text.splitlines():
        line = line.strip().lstrip("﻿")
        if not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        t = ev.get("type")
        if t == "thread.started" and isinstance(ev.get("thread_id"), str):
            out["thread_id"] = ev["thread_id"]
        elif t == "item.completed":
            item = ev.get("item") or {}
            if item.get("type") == "agent_message" and isinstance(item.get("text"), str):
                out["messages"].append(item["text"])
            elif item.get("type") == "error":
                out["errors"].append(str(item.get("message")))
        elif t == "turn.completed":
            out["completed"] = True
        elif t in ("turn.failed", "error"):
            out["failed"] = out["failed"] or t == "turn.failed"
            err = ev.get("error") if isinstance(ev.get("error"), dict) else {}
            out["errors"].append(str(ev.get("message") or err.get("message") or ev))
    return out


def find_codex_image(home: Path, thread_id: str | None, message: str, started: float) -> Path | None:
    """Trust the disk, not the message: the thread's folder first, then any
    image path in the final message written during this run, then the
    newest image anywhere under generated_images written during this run."""
    gen = home / "generated_images"
    if thread_id and re.fullmatch(r"[\w.-]+", thread_id):
        files = [p for p in (gen / thread_id).glob("*") if p.suffix.lower() in IMAGE_EXTS]
        if files:
            return max(files, key=lambda p: p.stat().st_mtime)
    for m in re.finditer(r"(/[^\s\"'`<>|]+\.(?:png|jpe?g|webp))", message or "", re.I):
        p = Path(m.group(1))
        if p.exists() and p.stat().st_mtime >= started - 2:
            return p
    if gen.exists():
        fresh = [p for p in gen.rglob("*") if p.suffix.lower() in IMAGE_EXTS and p.stat().st_mtime >= started - 2]
        if fresh:
            return max(fresh, key=lambda p: p.stat().st_mtime)
    return None

# ============================================================================


def run_codex(req: Request, cfg: dict) -> Result:
    if os.environ.get("OPENAI_API_KEY"):
        raise BackendError("OPENAI_API_KEY is set: Codex would bill the API instead of the ChatGPT plan. "
                           "Unset it (and remove it from your shell profile) before running the codex backend.", stop=True)
    binary = cfg.get("binary", "codex")
    if not shutil.which(binary):
        raise BackendError(f"`{binary}` not found. Install the Codex CLI and run `codex login` (Sign in with ChatGPT).", stop=True)
    started = time.time()
    with tempfile.TemporaryDirectory(prefix="pofu-imagegen-") as tmp:
        scratch = Path(tmp)
        refs = stage_references(req.references, scratch)
        last = scratch / "last-message.txt"
        cmd = codex_command(cfg, scratch, last, refs)
        try:
            proc = subprocess.run(cmd, input=codex_task(req.prompt, len(refs)), capture_output=True, text=True,
                                  timeout=req.timeout, cwd=scratch)
        except subprocess.TimeoutExpired:
            raise BackendError(f"codex timed out after {req.timeout} s (stopping: do not hammer a slow service)", stop=True)
        events = parse_codex_events(proc.stdout)
        message = last.read_text(encoding="utf-8", errors="replace") if last.exists() else "\n".join(events["messages"])
        blob = "\n".join([proc.stderr or "", "\n".join(events["errors"]), message])
        image = find_codex_image(codex_home(), events["thread_id"], message, started)
        if image is None:
            if LIMIT_RE.search(blob):
                raise BackendError("usage or rate limit reached; stopping the run", stop=True, raw=blob[-2000:])
            if AUTH_RE.search(blob):
                raise BackendError("Codex is not signed in; run `codex login` and choose Sign in with ChatGPT", stop=True, raw=blob[-2000:])
            if REFUSAL_RE.search(message or ""):
                raise BackendError("Codex answered without an image (refusal, or no image tool on this plan/version)",
                                   stop=True, raw=blob[-2000:])
            raise BackendError(f"codex exited {proc.returncode} without an image", stop=proc.returncode != 0, raw=blob[-2000:])
        req.out.parent.mkdir(parents=True, exist_ok=True)
        if image.suffix.lower() == ".png":
            shutil.copyfile(image, req.out)
        else:
            with Image.open(image) as im:
                im.save(req.out)
    return Result(req.out, time.time() - started, {"backend": "codex", "thread_id": events["thread_id"],
                                                    "source_file": str(image), "codex_message": (message or "")[-500:]})


# ---------------------------------------------------------------------------
# openai-api: the founder's own API key
# ---------------------------------------------------------------------------

KEYCHAIN_SERVICE = "pofu-openai-api"   # security add-generic-password -a "$USER" -s pofu-openai-api -w
KEY_ENV = "POFU_OPENAI_API_KEY"         # deliberately not OPENAI_API_KEY (that one would switch Codex to API billing)


def read_api_key(cfg: dict) -> tuple[str, str]:
    """The API key and where it came from: the macOS Keychain first, then
    POFU_OPENAI_API_KEY from the founder's local shell. Never a file."""
    service = cfg.get("keychain_service", KEYCHAIN_SERVICE)
    if shutil.which("security"):
        proc = subprocess.run(["security", "find-generic-password", "-a", os.environ.get("USER", ""), "-s", service, "-w"],
                              capture_output=True, text=True)
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout.strip(), f"keychain:{service}"
    key = os.environ.get(cfg.get("key_env", KEY_ENV), "").strip()
    if key:
        return key, f"env:{cfg.get('key_env', KEY_ENV)}"
    raise BackendError(f"no API key: add it to the Keychain (service {service}) or export {KEY_ENV} in your local shell", stop=True)


def redact(text: str, key: str | None) -> str:
    """Remove the key (and anything that looks like an OpenAI key) from text."""
    if key:
        text = text.replace(key, "[redacted]")
    return re.sub(r"sk-[A-Za-z0-9_\-]{12,}", "sk-[redacted]", text)


def key_guard(key: str, roots: list[Path], max_bytes: int = 2_000_000) -> None:
    """Refuse to run if the key is written anywhere it could leak from.

    Scans the given folders (the repository, the pipeline's output folders)
    for the key's text, including .env files, and refuses if the key has
    the shape of a placeholder. Run before every API batch.
    """
    if len(key) < 20 or " " in key:
        raise BackendError("the API key does not look like a key (too short or has spaces)", stop=True)
    needle = key.encode()
    skip = {".git", "node_modules", ".venv", "__pycache__", "DerivedData", ".build"}
    for root in roots:
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if any(part in skip for part in p.parts) or not p.is_file():
                continue
            if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp", ".woff2", ".pdf", ".mov", ".mp4"):
                continue
            try:
                if p.stat().st_size > max_bytes:
                    continue
                if needle in p.read_bytes():
                    raise BackendError(f"the API key is written in {p}; remove it (and rotate the key) before running", stop=True)
            except OSError:
                continue


def estimate_cost(jobs: list[tuple[tuple[int, int], int]], cfg: dict) -> tuple[float, list[str]]:
    """Rough USD for (size, reference count) per image, from the config's price table."""
    quality = cfg.get("quality", "high")
    prices = cfg.get("prices_usd", {}).get(quality, {})
    per_ref = float(cfg.get("per_reference_usd", 0.0))
    total, lines = 0.0, []
    for (w, h), refs in jobs:
        key = "1024x1024" if w == h else "1536x1024"
        price = float(prices.get(key, max(prices.values()) if prices else 0.0))
        total += price + refs * per_ref
    lines.append(f"{len(jobs)} image(s) at quality '{quality}' with model {cfg.get('model')}: about ${total:.2f}"
                 f" (table in config.yaml backends.openai-api.prices_usd, last checked {cfg.get('prices_checked', 'never')})")
    return total, lines


def run_openai_api(req: Request, cfg: dict, key: str) -> Result:
    try:
        from openai import OpenAI  # type: ignore
    except ImportError:
        raise BackendError("pip install openai to use the openai-api backend", stop=True)
    client = OpenAI(api_key=key)
    started = time.time()
    size = f"{req.size[0]}x{req.size[1]}"
    common = {"model": cfg.get("model", "gpt-image-1"), "prompt": req.prompt, "size": size, "n": 1,
              "quality": cfg.get("quality", "high")}
    if req.transparent:
        common["background"] = "transparent"
    try:
        if req.references:
            files = [open(p, "rb") for p in req.references]
            try:
                resp = client.images.edit(image=files, **common)
            finally:
                for f in files:
                    f.close()
        else:
            resp = client.images.generate(**common)
    except Exception as err:  # the SDK raises many types; all stop the run
        msg = redact(str(err), key)
        raise BackendError(f"Images API error: {msg}", stop=True, raw=msg)
    req.out.parent.mkdir(parents=True, exist_ok=True)
    req.out.write_bytes(base64.b64decode(resp.data[0].b64_json))
    usage = getattr(resp, "usage", None)
    return Result(req.out, time.time() - started, {"backend": "openai-api", "model": common["model"],
                                                   "quality": common["quality"],
                                                   "usage": usage.model_dump() if hasattr(usage, "model_dump") else None})


# ---------------------------------------------------------------------------
# manual pack
# ---------------------------------------------------------------------------

def manual_entry(job_id: str, chat: str | None, prompt: str, refs: list[tuple[str, Path]], save_as: list[str],
                 variants: int) -> str:
    lines = [f"## {job_id}", ""]
    if chat:
        lines.append(f"ChatGPT chat: **{chat}** (one chat per family; start a fresh one after two drifting results).")
    lines.append(f"Run it {variants} time(s). Save each result as:")
    lines += [f"- `{s}`" for s in save_as]
    if refs:
        lines += ["", "Attach, in this order:"]
        lines += [f"{i}. `{p}` ({role})" for i, (role, p) in enumerate(refs, 1)]
    lines += ["", "Prompt:", "", "```text", prompt.rstrip(), "```", ""]
    return "\n".join(lines)
