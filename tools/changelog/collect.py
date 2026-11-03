#!/usr/bin/env python3
"""Fold the per-PR changelog fragments in changes/ into CHANGELOG.md.

A fragment is changes/<branch-or-pr>.md holding one line, optionally prefixed with its
Keep a Changelog section: "Added: ...", "Changed: ...", "Fixed: ...", "Removed: ..."
(no prefix means Changed). Parallel PRs add their own file, so none touches CHANGELOG.md.

  python3 -I tools/changelog/collect.py              fold into [Unreleased], delete the fragments
  python3 -I tools/changelog/collect.py --version 0.2.0 [--date YYYY-MM-DD]
                                                      cut a release section instead
  python3 -I tools/changelog/collect.py --dry-run    print the result, change nothing
"""
import argparse
import datetime
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
SECTIONS = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]


def read_fragments(folder: pathlib.Path) -> tuple[dict[str, list[str]], list[pathlib.Path]]:
    found: dict[str, list[str]] = {}
    files = sorted(p for p in folder.glob("*.md") if p.name.lower() != "readme.md")
    for path in files:
        for line in path.read_text().splitlines():
            line = line.strip().lstrip("-* ").strip()
            if not line:
                continue
            m = re.match(r"(%s):\s*(.+)" % "|".join(SECTIONS), line, re.I)
            section, text = (m.group(1).capitalize(), m.group(2)) if m else ("Changed", line)
            found.setdefault(section, []).append(text)
    return found, files


def fold(changelog: str, found: dict[str, list[str]], version: str | None, date: str) -> str:
    """Adds the entries under [Unreleased], or under a new release heading below it."""
    head = re.search(r"^## \[Unreleased\]\s*$", changelog, re.M)
    if not head:
        raise SystemExit("CHANGELOG.md has no '## [Unreleased]' heading")
    rest_start = head.end()
    nxt = re.search(r"^## ", changelog[rest_start:], re.M)
    end = rest_start + nxt.start() if nxt else len(changelog)
    body = changelog[rest_start:end]
    parts = {}
    for sec in re.split(r"^### ", body, flags=re.M)[1:]:
        title, _, text = sec.partition("\n")
        parts[title.strip()] = text.strip("\n")
    for section, lines in found.items():
        add = "\n".join(f"- {t}" for t in lines)
        parts[section] = (parts[section] + "\n" + add) if section in parts else add

    def render(p):
        order = SECTIONS + [s for s in p if s not in SECTIONS]
        return "".join(f"\n### {s}\n\n{p[s]}\n" for s in order if s in p)

    if version:
        # The release takes the whole Unreleased body; Unreleased is left empty.
        return changelog[:rest_start] + f"\n\n## [{version}] - {date}\n" + render(parts) + "\n" + changelog[end:]
    return changelog[:rest_start] + "\n" + render(parts) + "\n" + changelog[end:]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--version")
    ap.add_argument("--date", default=datetime.date.today().isoformat())
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--root", type=pathlib.Path, default=REPO, help="repository root (for tests)")
    args = ap.parse_args(argv)
    found, files = read_fragments(args.root / "changes")
    if not files:
        print("no fragments in changes/")
        return 0
    path = args.root / "CHANGELOG.md"
    out = fold(path.read_text(), found, args.version, args.date)
    if args.dry_run:
        sys.stdout.write(out)
        return 0
    path.write_text(out)
    for f in files:
        f.unlink()
    print(f"folded {len(files)} fragment(s) into CHANGELOG.md")
    return 0


if __name__ == "__main__":
    sys.exit(main())
