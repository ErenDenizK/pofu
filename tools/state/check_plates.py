#!/usr/bin/env python3
"""Validate docs/state/plates.yaml: every painted path exists, every pick exists.

A cell is {painted, lead_pick, in_app, founder_ok}. A painted path must exist
and be a take of the form plate__<job>--t<N>.webp; lead_pick must equal N and
the take's review.yaml must name the same pick. A null painted cell has no
pick and is not in the app.

Each island also has sky_sets (ADR-0025): a cell per light in SKY_LIGHTS, same rules.

`in_app` is not trusted: it must equal what the app's plate files ship
(`Packages/PofuKit/Sources/PofuWorld/Resources/Plates/plate-<island>.json` and
`skyset-<island>.json`, read as `PlateIsland` reads them). A hand-kept flag went stale
within days (ten shipped Home states read `false` on 2026-11-12), so the check derives it.

Usage: python3 -I tools/state/check_plates.py [plates.yaml] [repo_root]
"""
import json
import re
import sys
from pathlib import Path

import yaml

TIMES = ("day", "golden", "night")
WEATHER = ("clear", "rain")
SKY_LIGHTS = ("day", "golden", "night", "rain")
TAKE_RE = re.compile(r"plate__(?P<job>.+)--t(?P<n>\d+)\.webp$")
PLATES_DIR = "Packages/PofuKit/Sources/PofuWorld/Resources/Plates"


def shipped_states(root: Path, island: str, stage_keys) -> set:
    """The (stage key, time, weather) cells the app draws from a painted plate.

    Mirrors `PlateIsland`: `painted` names the stages each light paints; without it every stage
    up to `lightStages[light]` is painted. A plate with several `stageLevels` (Home) is keyed by
    island level, stage 0 first: its highest level is the table's `final` row and level N is
    `il<N>`. Any other plate is keyed by its story stage number. The `rain` light is the day in
    rain; every other light is that time in clear weather. No plate file: nothing ships.
    """
    f = root / PLATES_DIR / f"plate-{island}.json"
    if not f.is_file():
        return set()
    plate = json.loads(f.read_text())
    lights = plate.get("lights") or []
    counts = plate.get("lightStages") or {light: plate.get("stages", 1) for light in lights}
    painted = plate.get("painted") or {light: list(range(counts.get(light, 0))) for light in lights}
    levels = plate.get("stageLevels") or []
    cells = set()
    for light in lights:
        time, weather = ("day", "rain") if light == "rain" else (light, "clear")
        for stage in painted.get(light, []):
            if len(levels) > 1:
                if stage >= len(levels):
                    continue
                level = levels[stage]
                key = "final" if level == max(levels) and "final" in stage_keys else f"il{level}"
            else:
                key = stage
            cells.add((key, time, weather))
    return cells


def shipped_sky_lights(root: Path, island: str) -> set:
    """The lights whose sky set the app ships (the keys of `lights` in `skyset-<island>.json`)."""
    f = root / PLATES_DIR / f"skyset-{island}.json"
    if not f.is_file():
        return set()
    return set((json.loads(f.read_text()).get("lights") or {}).keys())


def _in_app(where: str, cell: dict, ships: bool) -> list[str]:
    if bool(cell.get("in_app")) == ships:
        return []
    if ships:
        return [f"{where}: the app ships this state but in_app is false"]
    return [f"{where}: in_app is true but the app's plate files do not ship this state"]


def check(plates_file: Path, root: Path) -> list[str]:
    errors: list[str] = []
    data = yaml.safe_load(plates_file.read_text())
    for island, body in (data.get("islands") or {}).items():
        stages = body.get("stages") or {}
        shipped = shipped_states(root, island, set(stages))
        sky_shipped = shipped_sky_lights(root, island)
        for stage, times in stages.items():
            for t in TIMES:
                for w in WEATHER:
                    where = f"{island}/{stage}/{t}/{w}"
                    c = ((times or {}).get(t) or {}).get(w)
                    if c is None:
                        errors.append(f"{where}: missing cell")
                        continue
                    errors += _cell(where, c, root) or _in_app(where, c, (stage, t, w) in shipped)
        sky = body.get("sky_sets")
        if not isinstance(sky, dict):
            errors.append(f"{island}/sky_sets: missing section")
            continue
        for extra in sorted(set(sky) - set(SKY_LIGHTS)):
            errors.append(f"{island}/sky_sets/{extra}: unknown light")
        for light in SKY_LIGHTS:
            where = f"{island}/sky_sets/{light}"
            c = sky.get(light)
            if c is None:
                errors.append(f"{where}: missing cell")
                continue
            errors += _cell(where, c, root) or _in_app(where, c, light in sky_shipped)
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
    edited = c.get("edited")
    if edited is not None and not (root / edited).is_file():
        return [f"{where}: edited plate not found: {edited}"]
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
