#!/usr/bin/env python3
"""Studio pulse: what changed for the player, derived from git, so nobody has to remember.

    python3 -I tools/studio/pulse.py [--days 7] [--ref origin/main]

Prints, newest first, every changelog fragment (`changes/<branch>.md`, one line per user-visible
change) added to `--ref` in the last N days, then the merged pull requests per day by branch prefix.
Read the lines and ask which desk is missing: from 2026-11-07 to 2026-11-11 this list held four lines,
all about light and plates, while the tracker said every track was moving. Derived on purpose: every
hand-kept status page in this repository went stale within days.
"""
from __future__ import annotations

import argparse
import collections
import subprocess
from datetime import date, timedelta


REPO: str | None = None      # the repository to read; None is the current directory (tests set it)


def git(*args: str) -> str:
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True, cwd=REPO).stdout


def fragments(ref: str, since: str, until: str = "now") -> list[tuple[str, str, str]]:
    """(day, branch, first line) of each fragment added from `since` to `until`, newest first."""
    out = git("log", ref, f"--since={since}", f"--until={until}", "--diff-filter=A", "--format=@%cs", "--name-only", "--", "changes/")
    day, rows, seen = "", [], set()
    for line in out.splitlines():
        if line.startswith("@"):
            day = line[1:]
        elif line.endswith(".md") and line not in seen:
            seen.add(line)
            try:
                text = git("show", f"{ref}:{line}").strip().splitlines()[0]
            except (subprocess.CalledProcessError, IndexError):
                text = "(collected into CHANGELOG.md or removed)"
            rows.append((day, line.removeprefix("changes/").removesuffix(".md"), text))
    return sorted(rows, reverse=True)


def merges(ref: str, since: str, until: str = "now") -> dict[str, collections.Counter]:
    out = git("log", ref, "--first-parent", "--merges", f"--since={since}", f"--until={until}", "--format=%cs\t%s")
    days: dict[str, collections.Counter] = collections.defaultdict(collections.Counter)
    for line in out.splitlines():
        day, subject = line.split("\t", 1)
        branch = subject.rsplit(" from ", 1)[-1].split("/", 1)[-1]      # "owner/feat/x" -> "feat/x"
        days[day][branch.split("/", 1)[0] if "/" in branch else "other"] += 1
    return days


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--ref", default="origin/main")
    ap.add_argument("--today", default=None, help="YYYY-MM-DD, for tests")
    a = ap.parse_args()
    today = date.fromisoformat(a.today) if a.today else date.today()
    since = (today - timedelta(days=a.days)).isoformat()
    until = f"{today.isoformat()}T23:59:59"
    start = f"{since}T00:00:00"          # a bare date would start at the current time of day
    rows = fragments(a.ref, start, until)
    print(f"What changed for the player on {a.ref} since {since} ({len(rows)} lines):")
    for day, branch, text in rows:
        print(f"  {day}  {branch[:30]:30s} {text[:110]}")
    if not rows:
        print("  nothing: no user-visible change merged in this window")
    print("Merged pull requests per day:")
    for day, kinds in sorted(merges(a.ref, start, until).items(), reverse=True):
        print(f"  {day}  " + ", ".join(f"{k} {n}" for k, n in kinds.most_common()))


if __name__ == "__main__":
    main()
