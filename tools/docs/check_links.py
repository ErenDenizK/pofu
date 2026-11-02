#!/usr/bin/env python3
"""Check relative links and anchors in the repository's Markdown files.

Usage: python3 -I tools/docs/check_links.py [files...]   (default: all tracked .md)

Checks `[text](target)` links whose target is a relative path: the file or
directory must exist, and a `#anchor` into a Markdown file must match one of
its headings (GitHub slug rules). External links (http, mailto) are skipped.
Exit code 1 when anything is broken.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEAD = re.compile(r"^#{1,6}\s+(.*?)\s*#*\s*$")
SKIP_DIRS = {"node_modules", ".venv", "build", ".build"}


def slug(title: str) -> str:
    title = re.sub(r"[`*_\[\]]", "", title.lower())
    title = re.sub(r"[^\w\- ]", "", title, flags=re.UNICODE)
    return title.strip().replace(" ", "-")


_anchors: dict = {}


def anchors(path: Path) -> set:
    if path not in _anchors:
        found, seen, fence = set(), {}, False
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("```"):
                fence = not fence
            m = None if fence else HEAD.match(line)
            if m:
                s = slug(m.group(1))
                n = seen.get(s, 0)
                seen[s] = n + 1
                found.add(s if n == 0 else f"{s}-{n}")
        _anchors[path] = found
    return _anchors[path]


def markdown_files(args):
    if args:
        return [Path(a).resolve() for a in args]
    out = subprocess.run(["git", "ls-files", "*.md"], cwd=ROOT,
                         capture_output=True, text=True, check=True)
    return [ROOT / p for p in out.stdout.split()
            if not SKIP_DIRS & set(Path(p).parts) and (ROOT / p).exists()]


def check(md: Path):
    bad, fence = [], False
    for no, line in enumerate(md.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        if line.startswith("```"):
            fence = not fence
        if fence:
            continue
        line = re.sub(r"`[^`]*`", "", line)
        for m in LINK.finditer(line):
            target = m.group(1).strip("<>")
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("//") or "NNNN" in target:
                continue
            path, _, frag = target.partition("#")
            if path.startswith("/"):
                dest = (ROOT / path.lstrip("/")).resolve()
            else:
                dest = (md.parent / path).resolve() if path else md
            if not dest.exists():
                bad.append((no, target, "missing file"))
            elif frag and dest.suffix == ".md" and frag.lower() not in anchors(dest):
                bad.append((no, target, "missing anchor"))
    return bad


def main():
    total = 0
    for md in markdown_files(sys.argv[1:]):
        for no, target, why in check(md):
            total += 1
            print(f"{md.relative_to(ROOT)}:{no}: {why}: {target}")
    print(f"{total} broken link(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
