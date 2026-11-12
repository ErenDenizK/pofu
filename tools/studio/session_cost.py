#!/usr/bin/env python3
"""Where a lead session's budget went: context size times turns, per day and per agent.

    python3 -I tools/studio/session_cost.py [SESSION.jsonl] [--top 8] [--now]

Reads a Claude Code transcript (default: the newest `~/.claude/projects/*/*.jsonl`) and the
sub-agent transcripts beside it (`<session>/subagents/*.jsonl`). Each model turn re-reads the whole
context, so cost follows context x turns far more than the words written. Prices are dollars per
million input tokens as implied by the session cost record of 2026-11-12 (cache read 0.1 x input,
cache write 1.25 x or 2.0 x for a one-hour write, output 5 x); they are for comparing days and agents, not for billing.
"""
from __future__ import annotations

import argparse
import collections
import datetime
import glob
import json
import os

PRICE = {"haiku": 0.45, "sonnet": 1.5, "opus": 2.5, "fable": 6.0}


def family(model: str | None) -> str:
    return next((k for k in PRICE if model and k in model), "opus")


def turns(path: str):
    """(day, family, cache_read, cache_write, output) per model turn, once per message id."""
    for day, fam, read, write, out, _ in turns_full(path):
        yield day, fam, read, write, out


def turns_full(path: str):
    """Like turns, plus the part of cache_write that was a one-hour write (priced at 2.0 x input)."""
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
                   u.get("cache_creation_input_tokens") or 0, u.get("output_tokens") or 0,
                   (u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens") or 0)


def dollars(fam: str, read: int, write: int, out: int, write_1h: int = 0) -> float:
    """Dollars; a five-minute cache write costs 1.25 x input, a one-hour one 2.0 x."""
    write_1h = min(write_1h, write)
    return (read * 0.1 + (write - write_1h) * 1.25 + write_1h * 2.0 + out * 5) * PRICE[fam] / 1e6


def now(path: str, today: str) -> str:
    """One line: last turn's context, turns since the last compaction, today's turns, dollars, turns above 400k."""
    since = 0
    last_ctx = 0
    n = big = 0
    cost = 0.0
    seen = set()
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("subtype") == "compact_boundary":
                since = 0
                continue
            m = r.get("message") or {}
            u = m.get("usage")
            if r.get("type") != "assistant" or not u or m.get("id") in seen:
                continue
            seen.add(m.get("id"))
            since += 1
            read = (u.get("cache_read_input_tokens") or 0) + (u.get("input_tokens") or 0)
            write = u.get("cache_creation_input_tokens") or 0
            last_ctx = read + write
            if (r.get("timestamp") or "")[:10] == today:
                n += 1
                big += last_ctx > 400_000
                cost += dollars(family(m.get("model")), read, write, u.get("output_tokens") or 0,
                                (u.get("cache_creation") or {}).get("ephemeral_1h_input_tokens") or 0)
    return (f"now: context {last_ctx // 1000}k, {since} turns since last compact; "
            f"today {n} turns ${cost:.2f}, {big} above 400k")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("session", nargs="?")
    ap.add_argument("--top", type=int, default=8)
    ap.add_argument("--now", action="store_true", help="one line about the current context and today")
    ap.add_argument("--today", default=None, help="YYYY-MM-DD, for tests")
    a = ap.parse_args()
    path = a.session or max(glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")), key=os.path.getmtime)
    if a.now:
        print(now(path, a.today or datetime.date.today().isoformat()))
        return
    days: dict[str, list] = collections.defaultdict(lambda: [0, 0, 0, 0.0])      # turns, context, max, $
    for day, fam, read, write, out, w1 in turns_full(path):
        d = days[day]
        d[0] += 1; d[1] += read + write; d[2] = max(d[2], read + write); d[3] += dollars(fam, read, write, out, w1)
    print("Lead, per day: turns, average and largest context (k tokens), estimated $")
    for day in sorted(days):
        n, ctx, top, cost = days[day]
        print(f"  {day}  {n:5d} turns  avg {ctx // n // 1000:4d}k  max {top // 1000:4d}k  ${cost:7.2f}")
    print(f"  total ${sum(d[3] for d in days.values()):.2f}")
    agents = []
    for p in glob.glob(os.path.join(path[:-6], "subagents", "*.jsonl")):
        try:
            desc = json.load(open(p[:-6] + ".meta.json")).get("description", "")
        except (OSError, ValueError):
            desc = ""
        n = top = 0; cost = 0.0; fam = "?"
        for _, fam, read, write, out, w1 in turns_full(p):
            n += 1; top = max(top, read + write); cost += dollars(fam, read, write, out, w1)
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
