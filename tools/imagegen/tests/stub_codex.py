#!/usr/bin/env python3
"""A stand-in for `codex exec`, built from what the adapter assumes.

It reads the task from stdin, checks the flags the adapter must pass, and
then behaves like Codex with the built-in image tool: it prints JSONL
events, saves an image under $CODEX_HOME/generated_images/<thread_id>/,
and writes the last message to the -o file.

STUB_MODE: ok (default) | limit | noimage | auth
STUB_IMAGE: the image to "generate" (copied as is)
STUB_LOG: append the received argv and task here (JSON lines)
"""
import json
import os
import shutil
import sys
import uuid
from pathlib import Path

argv = sys.argv[1:]
task = sys.stdin.read()
if os.environ.get("STUB_LOG"):
    with open(os.environ["STUB_LOG"], "a", encoding="utf-8") as f:
        f.write(json.dumps({"argv": argv, "task": task}) + "\n")

assert argv[0] == "exec", argv
for flag in ("--json", "--ephemeral", "--skip-git-repo-check", "-o", "-C"):
    assert flag in argv, f"missing {flag}"
images = [a.split("=", 1)[1] for a in argv if a.startswith("--image=")]
for p in images:
    assert Path(p).exists(), p
    assert "," not in p, p
last = Path(argv[argv.index("-o") + 1])
mode = os.environ.get("STUB_MODE", "ok")
tid = str(uuid.uuid4())
print(json.dumps({"type": "thread.started", "thread_id": tid}))
print(json.dumps({"type": "turn.started"}))
if mode == "limit":
    print(json.dumps({"type": "error", "message": "You've hit your usage limit. Try again in 3 hours."}))
    print(json.dumps({"type": "turn.failed", "error": {"message": "usage limit"}}))
    sys.exit(1)
if mode == "auth":
    print(json.dumps({"type": "error", "message": "Not logged in. Run codex login."}))
    sys.exit(1)
if mode == "noimage":
    msg = "I can't generate images in this environment."
else:
    home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    out = home / "generated_images" / tid / "ig_0001.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(os.environ["STUB_IMAGE"], out)
    msg = str(out)
print(json.dumps({"type": "item.completed", "item": {"type": "agent_message", "text": msg}}))
print(json.dumps({"type": "turn.completed", "usage": {}}))
last.write_text(msg, encoding="utf-8")
