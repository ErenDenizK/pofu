#!/usr/bin/env python3
"""Validate docs/state/assets.yaml: every asset hook in the code has a row, and its state is true.

The hooks are the raw values of `PofuKitArt`, `PofuPaint` and `Sticker` (asset system v1
section 4.4). A row is {state, master, note}. state is one of STATES, in order. The checker
fails when:

- a hook has no row, or a row names no hook (the table and the code drift apart);
- a row at in_repo or later has no master (a master folder, or the take a sheet is cut from);
- the bundle disagrees: a hook whose file is in its bundle must read in_bundle or in_frame,
  and one whose file is not must read neither (derived, like plates' in_app: a hand-kept
  flag goes stale);
- a row short of in_frame gives no note saying why.

in_frame cannot be derived; the lead sets it after a 1:1 crop of a device-size frame.

Usage: python3 -I tools/state/check_assets.py [assets.yaml] [repo_root]
"""
import re
import sys
from pathlib import Path

import yaml

STATES = ("unpainted", "painted", "picked", "in_repo", "in_bundle", "in_frame")
DESIGN = "Packages/PofuKit/Sources/PofuDesignSystem"
# table section -> (Swift file declaring the hooks, bundle folder or None when not bundled yet)
SECTIONS = {
    "kit": (f"{DESIGN}/Kit/KitArt.swift", f"{DESIGN}/Resources"),
    "paint": (f"{DESIGN}/PofuPaint.swift", f"{DESIGN}/Resources"),
    "sticker": (f"{DESIGN}/Sticker.swift", f"{DESIGN}/Resources"),
}


def hooks(root: Path, swift: str) -> list:
    return re.findall(r'case \w+ = "([\w-]+)"', (root / swift).read_text(encoding="utf-8"))


def problems(data: dict, root: Path) -> list:
    found = []
    for section, (swift, bundle) in SECTIONS.items():
        rows = data.get(section) or {}
        names = hooks(root, swift)
        for name in names:
            if name not in rows:
                found.append(f"{section}: hook {name} has no row")
        for name, row in rows.items():
            if name not in names:
                found.append(f"{section}: row {name} names no hook in {swift}")
                continue
            state = (row or {}).get("state")
            if state not in STATES:
                found.append(f"{name}: unknown state {state!r}")
                continue
            rank = STATES.index(state)
            master = row.get("master")
            if rank >= STATES.index("in_repo") and not (master and (root / master).exists()):
                found.append(f"{name}: {state} but no master in this repository ({master})")
            shipped = (root / bundle / f"{name}.png").is_file()
            if shipped and rank < STATES.index("in_bundle"):
                found.append(f"{name}: its file is in the bundle; state must be in_bundle or in_frame, not {state}")
            if not shipped and rank >= STATES.index("in_bundle"):
                found.append(f"{name}: {state} but {bundle}/{name}.png is missing")
            if state != "in_frame" and not row.get("note"):
                found.append(f"{name}: {state} without a note saying why it is not in a frame")
    return found


def main(argv: list) -> int:
    root = Path(argv[2]) if len(argv) > 2 else Path(__file__).resolve().parents[2]
    table = Path(argv[1]) if len(argv) > 1 else root / "docs/state/assets.yaml"
    data = yaml.safe_load(table.read_text(encoding="utf-8"))
    found = problems(data, root)
    for line in found:
        print("FAIL", line, file=sys.stderr)
    if not found:
        counts = {}
        for section in SECTIONS:
            for row in (data.get(section) or {}).values():
                counts[row["state"]] = counts.get(row["state"], 0) + 1
        print("assets.yaml ok:", ", ".join(f"{counts.get(s, 0)} {s}" for s in STATES))
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
