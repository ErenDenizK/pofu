#!/usr/bin/env python3
"""Validate docs/state/plates.yaml: every painted path exists, every pick exists.

A cell is {painted, lead_pick, in_app, founder_ok}. A painted path must exist
and be a take of the form plate__<job>--t<N>.webp; lead_pick must equal N and
the take's review.yaml must name the same pick. A null painted cell has no
pick and is not in the app.

Usage: python3 -I tools/state/check_plates.py [plates.yaml] [repo_root]
"""
import re
import sys
from pathlib import Path

import yaml

TIMES = ("day", "golden", "night")
WEATHER = ("clear", "rain")
TAKE_RE = re.compile(r"plate__(?P<job>.+)--t(?P<n>\d+)\.webp$")


def check(plates_file: Path, root: Path) -> list[str]:
    errors: list[str] = []
    data = yaml.safe_load(plates_file.read_text())
    for island, body in (data.get("islands") or {}).items():
        for stage, times in (body.get("stages") or {}).items():
            for t in TIMES:
                for w in WEATHER:
                    where = f"{island}/{stage}/{t}/{w}"
                    c = ((times or {}).get(t) or {}).get(w)
                    if c is None:
                        errors.append(f"{where}: missing cell")
                        continue
                    errors += _cell(where, c, root)
    return errors


def _cell(where: str, c: dict, root: Path) -> list[str]:
    for k in ("painted", "lead_pick", "in_app", "founder_ok"):
        if k not in c:
            return [f"{where}: missing key {k}"]
    painted, pick = c["painted"], c["lead_pick"]
    if painted is None:
        if pick is not None or c["in_app"]:
            return [f"{where}: an unpainted cell has no pick and is not in the app"]
        return []
    path = root / painted
    if not path.is_file():
        return [f"{where}: painted path not found: {painted}"]
    m = TAKE_RE.search(path.name)
    if not m:
        return [f"{where}: not a take file name: {painted}"]
    if pick != int(m["n"]):
        return [f"{where}: lead_pick {pick} does not match take t{m['n']}"]
    review = path.parent / "review.yaml"
    if not review.is_file():
        return [f"{where}: no review.yaml beside {painted}"]
    got = ((yaml.safe_load(review.read_text()) or {}).get("jobs") or {}).get(m["job"], {}).get("pick")
    if got != pick:
        return [f"{where}: review.yaml pick is {got}, table says {pick}"]
    return []


def main(argv: list[str]) -> int:
    root = Path(argv[2]) if len(argv) > 2 else Path(__file__).resolve().parents[2]
    f = Path(argv[1]) if len(argv) > 1 else root / "docs/state/plates.yaml"
    errors = check(f, root)
    for e in errors:
        print(e)
    print(f"{'FAIL' if errors else 'ok'}: {len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
