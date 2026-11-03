#!/usr/bin/env python3
"""Generate docs/development/rename-map.md: every Turkish identifier -> English.

Usage: python3 -I tools/docs/rename_map.py [--check]

Scans every tracked text file (paths and contents) for identifier runs that
contain a Turkish token from RULES, derives the English replacement from the
rules, and writes the mapping table per layer. `--check` fails when the file
on disk is out of date; once the rename PRs are in, only deferred rows remain.

Only identifiers are scanned (runs of letters, digits, `_` and `-`, split into
camelCase / kebab / snake sub-tokens). In Markdown only backticked code is
scanned; display strings and prose stay Turkish on purpose.
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/development/rename-map.md"

# token -> (English words, rule). Words are joined per style (teaStall / tea-stall).
RULES = {
    "cay": (["tea", "stall"], "common noun: cay ocagi (Mochi's tea stall) becomes tea stall"),
    "simit": (["bagel", "cart"], "common noun: the simit stall becomes bagel cart (the kitten `simit-kitten` keeps its name)"),
    "iskele": (["harbor"], "common noun: iskele becomes harbor"),
    "vapur": (["ferry"], "common noun: vapur becomes ferry"),
    "aycicegi": (["home"], "the home island as a concept becomes home"),
    "ayar": (["tuning", "lab"], "common noun: ayar (the tuning panel) becomes tuning lab"),
}
# Kept on purpose (counted and reported, not renamed).
KEEP = {
    "findik": "character proper name (the hedgehog); no hazelnut resource exists in code",
    "mochi": "character proper name",
    "yildiz": "provisional island of the retired five-island catalog; revisit with the wonder-island redesign",
    "kaplica": "same as yildiz",
    "kitap": "same as yildiz",
    "hamam": "same as yildiz (loanword)",
    "serbet": "same as yildiz",
}
# A token followed by one of these is a character, not the noun.
CHAR_FOLLOW = {"simit": {"kitten"}}

DEFERRED = ("content/islands/", "content/characters/", "content/ideas/", "content/stories/", "docs/")
LAYERS = [
    ("swift", "Swift (packages, app, extensions, tests)"),
    ("assets", "Assets and pipeline (art, manifests, harmony, catalogs, tools)"),
    ("deferred", "Content and docs ids (deferred: the design loop owns these)"),
]
BINARY = {".png", ".webp", ".jpg", ".jpeg", ".caf", ".m4a", ".mp4", ".mov", ".gif", ".woff", ".woff2", ".ttf", ".otf", ".pdf", ".icns", ".wav", ".ico"}
RUN = re.compile(r"[A-Za-z0-9_\-]+")
SUB = re.compile(r"[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+|[^A-Za-z0-9]+")


def layer_of(path: str) -> str:
    if path.endswith(".swift"):
        return "swift"
    if path.startswith(DEFERRED) or re.match(r"content/[^/]+\.yaml$", path):
        return "deferred"
    return "assets"


def convert(run: str, camel: bool):
    """Return (new run or None, rules applied, kept tokens) for one identifier run."""
    toks = SUB.findall(run)
    low = [t.lower() for t in toks]
    kept = sorted({k for k in low if k in KEEP})
    if not any(k in RULES for k in low):
        return None, [], kept
    kebab = "-" in run or "_" in run or not camel
    out, rules, renamed = [], set(), False
    for i, t in enumerate(toks):
        k = low[i]
        nxt = next((low[j] for j in range(i + 1, len(low)) if low[j].isalpha()), None)
        if k in RULES and nxt not in CHAR_FOLLOW.get(k, ()):
            words = RULES[k][0]
            rules.add(RULES[k][1])
            renamed = True
            if t.isupper() and len(t) > 1:
                out.append("_".join(words).upper())
            elif kebab:
                out.append("-".join(words))
            elif i == 0 and t[0].islower():
                out.append(words[0] + "".join(w.capitalize() for w in words[1:]))
            else:
                out.append("".join(w.capitalize() for w in words))
        else:
            out.append(t)
    return ("".join(out) if renamed else None), sorted(rules), kept


def tracked():
    out = subprocess.check_output(["git", "ls-files"], cwd=ROOT).decode().split("\n")
    return [p for p in out if p and Path(p).suffix.lower() not in BINARY and p != "docs/development/rename-map.md"]


def main():
    rows = {name: defaultdict(lambda: [set(), 0, "", ()]) for name, _ in LAYERS}
    keeps = defaultdict(lambda: [set(), 0])

    def record(layer, old, path, camel):
        new, rules, kept = convert(old, camel)
        for k in kept:
            keeps[k][0].add(path)
            keeps[k][1] += 1
        if new and new != old:
            row = rows[layer][old]
            row[0].add(path)
            row[1] += 1
            row[2], row[3] = new, tuple(rules)

    for path in tracked():
        layer = layer_of(path)
        for comp in re.split(r"[/.]", path):
            for run in RUN.findall(comp):
                record(layer, run, path, False)
        try:
            text = (ROOT / path).read_text(encoding="utf-8")
        except (UnicodeDecodeError, FileNotFoundError, IsADirectoryError):
            continue
        if path.endswith(".md"):
            text = " ".join(re.findall(r"`([^`\n]+)`", text))
        for run in RUN.findall(text):
            record(layer, run, path, path.endswith((".swift", ".json", ".py")))

    lines = [
        "# Rename map: Turkish identifiers to English",
        "",
        "Generated by `python3 -I tools/docs/rename_map.py` (do not edit by hand). Part of the",
        "English-identifiers rename (founder input 2026-11-03). One PR per layer; user-facing",
        "Turkish strings, Turkish prose and merged PR titles are untouched.",
        "",
        "## Rules",
        "",
    ]
    for tok, (words, rule) in RULES.items():
        camel = words[0] + "".join(w.capitalize() for w in words[1:])
        lines.append(f"- `{tok}` becomes `{camel}` (code) or `{'-'.join(words)}` (asset ids, files): {rule}.")
    lines += [
        "- Character proper names stay (ASCII); where one token is both food and character, the character keeps a role (`simit-kitten`) and the noun becomes English.",
        "- Wonder-island and resident proper names (caglayan, revontuli, koke, gezgin, mehtap, fanus, ...) stay as ASCII ids.",
        "- Persisted Swift ids (station and island raw values) get new values that also decode the old ones, so saves keep working.",
        "- Style: camelCase in Swift and JSON values, kebab-case in asset ids and file names.",
        "- Old asset ids stay resolvable through the alias map in the pipeline (assets PR).",
        "- The rows below are regenerated from the tree; a layer whose PR has merged shows no remaining rows.",
        "",
        "## Kept on purpose",
        "",
        "| Token | Occurrences | Why |",
        "|---|---|---|",
    ]
    for k, why in KEEP.items():
        files, n = keeps.get(k, (set(), 0))
        lines.append(f"| `{k}` | {n} in {len(files)} files | {why} |")
    for name, title in LAYERS:
        lines += ["", f"## {title}", ""]
        r = rows[name]
        if not r:
            lines.append("No remaining identifiers.")
            continue
        total = sum(v[1] for v in r.values())
        nfiles = len(set().union(*[v[0] for v in r.values()]))
        lines += [
            f"{len(r)} distinct identifiers, {total} occurrences in {nfiles} files.",
            "",
            "| Old | New | Occurrences | Files | Rule |",
            "|---|---|---|---|---|",
        ]
        for old in sorted(r):
            files, n, new, rules = r[old]
            lines.append(f"| `{old}` | `{new}` | {n} | {len(files)} | {'; '.join(rules)} |")
    text = "\n".join(lines) + "\n"
    if "--check" in sys.argv:
        if not OUT.exists() or OUT.read_text() != text:
            print("rename-map.md is out of date; run tools/docs/rename_map.py")
            sys.exit(1)
        return
    OUT.write_text(text)
    print("wrote docs/development/rename-map.md: " + ", ".join(f"{n}={len(rows[n])}" for n in rows))


if __name__ == "__main__":
    main()
