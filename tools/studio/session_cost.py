#!/usr/bin/env python3
"""Where a lead session's budget went: context size times turns, per day and per agent.

    python3 -I tools/studio/session_cost.py [SESSION.jsonl] [--top 8]

Reads a Claude Code transcript (default: the newest `~/.claude/projects/*/*.jsonl`) and the
sub-agent transcripts beside it (`<session>/subagents/*.jsonl`). Each model turn re-reads the whole
context, so cost follows context x turns far more than the words written. Prices are dollars per
million input tokens as implied by the session cost record of 2026-11-12 (cache read 0.1 x input,
cache write 1.25 x, output 5 x); they are for comparing days and agents, not for billing.
"""
from __future__ import annotations

import argparse
import collections
import glob
import json
import os

PRICE = {"haiku": 0.45, "sonnet": 1.5, "opus": 2.5, "fable": 6.0}


def family(model: str | None) -> str:
    return next((k for k in PRICE if model and k in model), "opus")


def turns(path: str):
    """(day, family, cache_read, cache_write, output) per model turn, once per message id."""
    seen = set()
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            m = r.get("message") or {}
            u = m.get("usage")
            if r.get("type") != "assistant" or not u or m.get("id") in seen:
                continue
            seen.add(m.get("id"))
            yield ((r.get("timestamp") or "")[:10], family(m.get("model")),
                   (u.get("cache_read_input_tokens") or 0) + (u.get("input_tokens") or 0),
                   u.get("cache_creation_input_tokens") or 0, u.get("output_tokens") or 0)


def dollars(fam: str, read: int, write: int, out: int) -> float:
    return (read * 0.1 + write * 1.25 + out * 5) * PRICE[fam] / 1e6


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("session", nargs="?")
    ap.add_argument("--top", type=int, default=8)
    a = ap.parse_args()
    path = a.session or max(glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")), key=os.path.getmtime)
    days: dict[str, list] = collections.defaultdict(lambda: [0, 0, 0, 0.0])      # turns, context, max, $
    for day, fam, read, write, out in turns(path):
        d = days[day]
        d[0] += 1; d[1] += read + write; d[2] = max(d[2], read + write); d[3] += dollars(fam, read, write, out)
    print("Lead, per day: turns, average and largest context (k tokens), estimated $")
    for day in sorted(days):
        n, ctx, top, cost = days[day]
        print(f"  {day}  {n:5d} turns  avg {ctx // n // 1000:4d}k  max {top // 1000:4d}k  ${cost:7.2f}")
    print(f"  total ${sum(d[3] for d in days.values()):.2f}; target: average context under 150k")
    agents = []
    for p in glob.glob(os.path.join(path[:-6], "subagents", "*.jsonl")):
        try:
            desc = json.load(open(p[:-6] + ".meta.json")).get("description", "")
        except (OSError, ValueError):
            desc = ""
        n = top = 0; cost = 0.0; fam = "?"
        for _, fam, read, write, out in turns(p):
            n += 1; top = max(top, read + write); cost += dollars(fam, read, write, out)
        if n:
            agents.append((cost, fam, n, top, desc))
    by = collections.defaultdict(lambda: [0, 0, 0.0])
    for cost, fam, n, top, _ in agents:
        by[fam][0] += 1; by[fam][1] += n; by[fam][2] += cost
    print("Sub-agents, per model: agents, turns per agent, estimated $ and $ per agent")
    for fam, (k, n, cost) in sorted(by.items(), key=lambda kv: -kv[1][2]):
        print(f"  {fam:6s} {k:4d} agents  {n // k:4d} turns each  ${cost:7.2f}  ${cost / k:5.2f} each")
    print(f"The {a.top} costliest agents (a context past 250k means: next time hand over to a fresh agent)")
    for cost, fam, n, top, desc in sorted(agents, reverse=True)[: a.top]:
        print(f"  ${cost:6.2f}  {fam:6s} {n:4d} turns  max {top // 1000:4d}k  {desc}")


if __name__ == "__main__":
    main()
