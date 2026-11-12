#!/usr/bin/env python3
"""Find the exact words of a message a compaction dropped.

    python3 -I tools/studio/recall.py "<regex>" [--who founder|lead|all] [--since YYYY-MM-DD] [--max 20]

Searches every lead transcript `~/.claude/projects/*/*.jsonl` (not sub-agents) and prints timestamp,
who spoke and up to 400 characters around each match, oldest first. A founder message is a `user`
record whose content is a string or holds text parts, and is neither meta nor a compaction summary.
"""
from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys


def text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(p.get("text", "") for p in content if isinstance(p, dict) and p.get("type") == "text")
    return ""


def messages(path: str):
    """(timestamp, who, text) per message in a transcript; who is 'founder' or 'lead'."""
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            m = r.get("message") or {}
            if r.get("type") == "user":
                if r.get("isMeta") or r.get("isCompactSummary"):
                    continue
                who = "founder"
            elif r.get("type") == "assistant":
                who = "lead"
            else:
                continue
            text = text_of(m.get("content"))
            if text:
                yield r.get("timestamp") or "", who, text


def search(paths, pattern: str, who: str = "all", since: str = "", limit: int = 20):
    rx = re.compile(pattern, re.IGNORECASE)
    rows = []
    for p in paths:
        for ts, w, text in messages(p):
            if (who != "all" and w != who) or ts[:10] < since:
                continue
            hit = rx.search(text)
            if hit:
                a = max(0, hit.start() - 150)
                rows.append((ts, w, text[a:a + 400].replace("\n", " ")))
    rows.sort(key=lambda r: r[0])
    return rows[:limit]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("regex")
    ap.add_argument("--who", choices=["founder", "lead", "all"], default="all")
    ap.add_argument("--since", default="")
    ap.add_argument("--max", type=int, default=20)
    ap.add_argument("--root", default=os.path.expanduser("~/.claude/projects"), help="for tests")
    a = ap.parse_args()
    try:
        rows = search(sorted(glob.glob(os.path.join(a.root, "*", "*.jsonl"))), a.regex, a.who, a.since, a.max)
    except re.error as e:
        sys.exit(f"bad regex: {e}")
    for ts, who, snippet in rows:
        print(f"{ts[:19]}  {who:7s} {snippet}")
    if not rows:
        print("no match")


if __name__ == "__main__":
    main()
