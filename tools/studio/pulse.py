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
import glob
import json
import os
import subprocess
from datetime import date, datetime, timedelta, timezone


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


def root() -> str:
    return REPO or "."


def worktrees_merged(ref: str) -> list[str]:
    """Worktree paths (not the main checkout) whose branch is already merged into `ref`."""
    try:
        merged = {b.strip().lstrip("*+ ") for b in git("branch", "--merged", ref).splitlines()}
        out = git("worktree", "list", "--porcelain")
    except (subprocess.CalledProcessError, OSError):
        return []
    rows = []
    blocks = [b for b in out.strip().split("\n\n") if b]
    for b in blocks[1:]:                                   # the first block is the main checkout
        info = dict(l.split(" ", 1) for l in b.splitlines() if " " in l)
        br = info.get("branch", "").removeprefix("refs/heads/")
        if br and br in merged and br not in ("main", "master"):
            rows.append(f"{info['worktree']} ({br})")
    return rows


def old_prs(hours: int = 48, now: datetime | None = None) -> list[str]:
    """Open pull requests older than `hours`; empty without network or gh."""
    try:
        out = subprocess.run(["gh", "api", "repos/ErenDenizK/pofu/pulls?state=open&per_page=100"], check=True,
                             capture_output=True, text=True, timeout=30).stdout
        prs = json.loads(out)
    except (subprocess.SubprocessError, OSError, ValueError):
        return []
    now = now or datetime.now(timezone.utc)
    rows = []
    for p in prs:
        made = datetime.fromisoformat(p["created_at"].replace("Z", "+00:00"))
        if now - made > timedelta(hours=hours):
            rows.append(f"#{p['number']} {p['title'][:70]} (open {(now - made).days}d)")
    return rows


def open_friction(path: str) -> list[str]:
    """Table rows of docs/studio/friction.md whose last cell is empty."""
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        return []
    rows = []
    for l in lines:
        l = l.strip()
        if l.startswith("|") and l.endswith("|"):
            cells = [c.strip() for c in l.strip("|").split("|")]
            if len(cells) > 1 and not cells[-1] and any(cells[:-1]) and not set("".join(cells)) <= set("-: "):
                rows.append(" | ".join(c for c in cells if c)[:110])
    return rows


def caps(base: str) -> list[str]:
    """Files over their size cap: CLAUDE.md and agent files 80 lines, docs/studio.md 4,500 words."""
    over = []
    files = [os.path.join(base, "CLAUDE.md")] + sorted(glob.glob(os.path.join(base, ".claude/agents/*.md")))
    for p in files:
        try:
            n = len(open(p, encoding="utf-8").read().splitlines())
        except OSError:
            continue
        if n > 80:
            over.append(f"{os.path.relpath(p, base)}: {n} lines, cap 80")
    try:
        n = len(open(os.path.join(base, "docs/studio.md"), encoding="utf-8").read().split())
        if n > 4500:
            over.append(f"docs/studio.md: {n} words, cap 4,500")
    except OSError:
        pass
    return over


def route(base: str) -> str:
    try:
        for l in open(os.path.join(base, "docs/now.md"), encoding="utf-8"):
            if "**Route:**" in l:
                return l.strip()
    except OSError:
        pass
    return ""


def leftovers(ref: str, base: str, network: bool = True) -> None:
    print("Leftovers:")
    for title, rows in (("Worktrees merged into " + ref, worktrees_merged(ref)),
                        ("Open pull requests older than 48 hours", old_prs() if network else []),
                        ("Friction rows with no outcome", open_friction(os.path.join(base, "docs/studio/friction.md"))),
                        ("Files over their cap", caps(base))):
        print(f"  {title}: " + ("none" if not rows else ""))
        for r in rows:
            print(f"    {r}")
    print("  " + (route(base) or "Route: (no **Route:** line in docs/now.md)"))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--ref", default="origin/main")
    ap.add_argument("--today", default=None, help="YYYY-MM-DD, for tests")
    ap.add_argument("--no-network", action="store_true", help="skip the open pull request check")
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
    leftovers(a.ref, root(), not a.no_network)


if __name__ == "__main__":
    main()
