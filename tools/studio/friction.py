#!/usr/bin/env python3
"""The friction sub-agents reported, so the lead can fix the rules that cost them time.

    python3 -I tools/studio/friction.py [SESSION.jsonl] [--since YYYY-MM-DD]

For each sub-agent transcript beside the session (`<session>/subagents/*.jsonl`) takes the last
assistant text, finds its line starting "Friction:", skips "none" and prints date, the agent's
description (from `*.meta.json`) and that line. Default session: the newest lead transcript.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re


def last_text(path: str) -> tuple[str, str]:
    """(day, text) of the last assistant message that holds text."""
    day = text = ""
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("type") != "assistant":
                continue
            c = (r.get("message") or {}).get("content")
            t = c if isinstance(c, str) else "\n".join(
                p.get("text", "") for p in c or [] if isinstance(p, dict) and p.get("type") == "text")
            if t.strip():
                day, text = (r.get("timestamp") or "")[:10], t
    return day, text


def rows(session: str, since: str = ""):
    for p in sorted(glob.glob(os.path.join(session[:-6], "subagents", "*.jsonl"))):
        day, text = last_text(p)
        m = re.search(r"^\s*[-*]?\s*(Friction:.*)$", text, re.MULTILINE)
        if not m or day < since:
            continue
        line = m.group(1).strip()
        if re.fullmatch(r"Friction:\s*\**none\**\.?", line, re.IGNORECASE):
            continue
        try:
            desc = json.load(open(p[:-6] + ".meta.json")).get("description", "")
        except (OSError, ValueError):
            desc = ""
        yield day, desc, line


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("session", nargs="?")
    ap.add_argument("--since", default="")
    a = ap.parse_args()
    path = a.session or max(glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")), key=os.path.getmtime)
    found = sorted(rows(path, a.since))
    for day, desc, line in found:
        print(f"{day}  {desc[:40]:40s} {line}")
    if not found:
        print("no friction reported")


if __name__ == "__main__":
    main()
