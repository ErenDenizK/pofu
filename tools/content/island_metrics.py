"""Island continuity, novelty and pacing metrics (design loop).

Reads content/islands/profiles.yaml and prints the derived arrival schedule
and every rule violation; exits 1 when there is one.

    python3 -I tools/content/island_metrics.py [profiles.yaml]

Checks (thresholds live in the file's `rules`):
- satellites share 2-3 of the six axes with the big island they orbit;
- consecutive big islands differ on >= 3 axes;
- consecutive arrivals keep >= 1 axis and change >= 2 (no cliff, no repeat);
- any two wonder islands differ on >= 3 axes, and on >= 3 from home;
- no three arrivals in a row share a game texture;
- palette deltas stay kin to home (bounded) yet distinct, keeping a home anchor;
- every cluster has its own atmosphere (hour, sky, key light, shadow, haze,
  floor, weather, value key): any two clusters differ on enough of these,
  and the home-only fields (home's shadow colour, haze and cloud sea) are
  never reused, so islands differ by light, not only by palette (loop 2);
- the schedule: each arrival day is derived from the previous island's
  content runway (its first day without a fresh beat), the minimum gaps and
  the wow spacing; then founder targets, dead days (no fresh beat from any
  island) and stacked wows (two wows closer than `wow_gap`) are checked.
"""
from __future__ import annotations

import sys
from itertools import combinations
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]
PROFILES = REPO / "content" / "islands" / "profiles.yaml"


def load(path: Path = PROFILES) -> dict:
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


def shared(data: dict, a: str, b: str) -> list[str]:
    ia, ib = data["islands"][a]["axes"], data["islands"][b]["axes"]
    return [ax for ax in data["axes"] if ia[ax] == ib[ax]]


def runway(island: dict) -> int:
    """Days of fresh beats in a row from arrival (offset 0)."""
    offsets = {int(k) for k in island["beats"]}
    k = 0
    while k in offsets:
        k += 1
    return k


def schedule(data: dict) -> dict[str, dict]:
    """Derive arrival days from runways, gaps and wow spacing."""
    r, islands = data["rules"], data["islands"]
    out: dict[str, dict] = {}
    wows: list[int] = []
    last_big = None
    prev = None
    for name in data["order"]:
        isl = islands[name]
        if prev is None:
            day = 1
        else:
            p = out[prev]
            day = max(p["arrival"] + p["runway"], p["arrival"] + r["min_gap"])
            if isl["size"] == "big":
                if last_big is not None:
                    day = max(day, last_big + r["big_gap"])
                while any(abs(day - w) < r["wow_gap"] for w in wows):
                    day += 1
        lead = isl.get("rumour_lead", r["rumour_lead"])
        rw = runway(isl)
        score = latest_score(isl)
        tiers = r.get("tiers") or {}
        if score is not None and "floor" in tiers and score < tiers["floor"]["premium"]:
            # A weak island (by the founder's score) holds the player less long.
            rw = min(rw, tiers.get("weak_runway", 2))
        entry = {"arrival": day, "runway": rw, "rumour": day - lead}
        if "bloom" in isl:
            entry["bloom"] = day + isl["bloom"]
        if isl["size"] == "big":
            last_big = day
            wows.append(day)
            if "bloom" in isl:
                wows.append(entry["bloom"])
        out[name] = entry
        prev = name
    return out


def wow_events(data: dict, sched: dict) -> list[tuple[int, str]]:
    ev = []
    for name, s in sched.items():
        if data["islands"][name]["size"] == "big":
            ev.append((s["arrival"], f"{name} arrives"))
            if "bloom" in s:
                ev.append((s["bloom"], f"{name} blooms"))
    return sorted(ev)


def covered_days(data: dict, sched: dict) -> dict[int, list[str]]:
    days: dict[int, list[str]] = {}
    for name, s in sched.items():
        for off, label in data["islands"][name]["beats"].items():
            days.setdefault(s["arrival"] + int(off), []).append(f"{name}: {label}")
    return days


def daily_days(data: dict, sched: dict, last: int) -> set[int]:
    """Days with only an infrastructure daily (a rumour, a puzzle): thin, not dead."""
    out: set[int] = set()
    for name, s in sched.items():
        start = data["islands"][name].get("daily_from")
        if start is not None:
            out.update(range(s["arrival"] + int(start), last + 1))
    return out


def check(data: dict) -> tuple[list[str], dict]:
    r, islands, order = data["rules"], data["islands"], data["order"]
    v: list[str] = []
    n_axes = len(data["axes"])
    homes = [n for n in order if islands[n]["size"] == "home"]
    home = homes[0]
    wonders = [n for n in order if islands[n]["size"] != "home"]

    for name in wonders:
        isl = islands[name]
        missing = [ax for ax in data["axes"] if ax not in isl["axes"]]
        if missing:
            v.append(f"profile: {name} lacks axes {missing}")
            return v, {}

    # Satellites: continuity with the big they orbit.
    lo, hi = r["satellite_shared"]
    for name in wonders:
        isl = islands[name]
        if isl["size"] != "satellite":
            continue
        big = isl.get("orbits")
        if big not in islands or islands[big]["size"] != "big":
            v.append(f"satellite: {name} must orbit a big island (orbits: {big})")
            continue
        s = shared(data, name, big)
        if not lo <= len(s) <= hi:
            v.append(f"satellite: {name} shares {len(s)} axes with {big} {s}; want {lo}-{hi}")
        if order.index(name) < order.index(big):
            v.append(f"satellite: {name} arrives before the island it orbits ({big})")

    # Consecutive bigs: novelty.
    bigs = [n for n in order if islands[n]["size"] == "big"]
    for a, b in zip(bigs, bigs[1:]):
        d = n_axes - len(shared(data, a, b))
        if d < r["big_min_diff"]:
            v.append(f"bigs: {a} -> {b} differ on {d} axes; want >= {r['big_min_diff']}")

    # Consecutive arrivals: no cliff, no repeat.
    for a, b in zip(order, order[1:]):
        s = shared(data, a, b)
        if len(s) < r["step_min_shared"]:
            v.append(f"step: {a} -> {b} share nothing (a cliff)")
        if n_axes - len(s) < r["step_min_diff"]:
            v.append(f"step: {a} -> {b} change only {n_axes - len(s)} axes (a repeat)")

    # Uniqueness across all wonder islands and against home.
    for a, b in combinations(wonders, 2):
        d = n_axes - len(shared(data, a, b))
        if d < r["pair_min_diff"]:
            v.append(f"pair: {a} / {b} differ on {d} axes; want >= {r['pair_min_diff']}")
    for name in wonders:
        d = n_axes - len(shared(data, name, home))
        if d < r["home_min_diff"]:
            v.append(f"home: {name} differs from home on {d} axes; want >= {r['home_min_diff']}")
        if islands[name]["axes"]["palette"] == islands[home]["axes"]["palette"]:
            v.append(f"home: {name} uses the home palette (banned template)")

    # Runs: never too many arrivals in a row with one value on an axis.
    for axis, most in (r.get("run_max") or {}).items():
        run = 1
        for a, b in zip(order, order[1:]):
            run = run + 1 if islands[a]["axes"][axis] == islands[b]["axes"][axis] else 1
            if run > most:
                v.append(f"run: {run} arrivals in a row share {axis} {islands[b]['axes'][axis]} (ending {b})")

    # Palette kinship.
    k = r["palette_kin"]
    anchors = set(data["home_anchors"])
    for cname, cl in data["clusters"].items():
        if cname == islands[home]["cluster"]:
            continue
        pd = data["palette_deltas"].get(cname)
        if pd is None:
            v.append(f"palette: cluster {cname} has no delta")
            continue
        if abs(pd["hue"]) > k["hue_max"] or abs(pd["sat"]) > k["sat_max"] or abs(pd["value"]) > k["value_max"]:
            v.append(f"palette: {cname} drifts too far from home {pd}")
        if max(abs(pd["hue"]) / 100, abs(pd["sat"]), abs(pd["value"])) < k["distinct_min"]:
            v.append(f"palette: {cname} is too close to home to read as its own place {pd}")
        if len(set(pd["keeps"]) & anchors) < k["keeps_min"]:
            v.append(f"palette: {cname} keeps no home anchor")
        for m in cl["members"]:
            if islands[m]["cluster"] != cname:
                v.append(f"cluster: {m} listed in {cname} but says {islands[m]['cluster']}")

    v.extend(check_atmospheres(data))

    # Schedule: targets, dead days, stacked wows.
    sched = schedule(data)
    for name, t in (data.get("targets") or {}).items():
        s = sched[name]
        if "arrival" in t and not t["arrival"][0] <= s["arrival"] <= t["arrival"][1]:
            v.append(f"target: {name} arrives day {s['arrival']}; want {t['arrival']}")
        if "rumour_by" in t and s["rumour"] > t["rumour_by"]:
            v.append(f"target: {name}'s rumour on day {s['rumour']}; want by {t['rumour_by']}")
    days = covered_days(data, sched)
    last = max(days)
    daily = daily_days(data, sched, last)
    dead = [d for d in range(1, last + 1) if d not in days and d not in daily]
    if dead:
        v.append(f"dead days (no fresh beat): {dead}")
    run, worst = 0, []
    for d in range(1, last + 1):
        run = run + 1 if (d not in days and d in daily) else 0
        if run > r.get("thin_run_max", 2):
            worst.append(d)
    if worst:
        v.append(f"thin runs (only a daily, > {r.get('thin_run_max', 2)} days in a row) end on days: {worst}")
    ev = wow_events(data, sched)
    for (d1, e1), (d2, e2) in zip(ev, ev[1:]):
        if d2 - d1 < r["wow_gap"]:
            v.append(f"stacked wows: {e1} (day {d1}) and {e2} (day {d2})")
    v.extend(check_tiers(data, sched))
    return v, sched


def check_atmospheres(data: dict) -> list[str]:
    """Each cluster's own light and air (design loop 2).

    A palette delta alone left every island under one pastel daylight, one
    cream haze and one cloud sea; the atmosphere is what a visit repaints.
    """
    rule = data["rules"].get("atmosphere")
    if not rule:
        return []
    fields, atm = rule["fields"], data.get("atmospheres") or {}
    home = data["islands"][data["order"][0]]["cluster"]
    v: list[str] = []
    for cname in data["clusters"]:
        a = atm.get(cname)
        if a is None:
            v.append(f"atmosphere: cluster {cname} has none")
            continue
        missing = [f for f in fields if f not in a]
        if missing:
            v.append(f"atmosphere: {cname} lacks {missing}")
    if v:
        return v
    for a, b in combinations(list(data["clusters"]), 2):
        same = [f for f in fields if atm[a][f] == atm[b][f]]
        if len(fields) - len(same) < rule["min_diff"]:
            v.append(f"atmosphere: {a} / {b} differ on {len(fields) - len(same)} of {len(fields)}; want >= {rule['min_diff']} (same {same})")
    for cname in data["clusters"]:
        if cname == home:
            continue
        for f in rule.get("home_only", []):
            if atm[cname][f] == atm[home][f]:
                v.append(f"atmosphere: {cname} reuses home's {f} ({atm[home][f]})")
    return v


def check_tiers(data: dict, sched: dict) -> list[str]:
    """The sawtooth: a premium floor, god-tier peaks spaced, both rising.

    Big and parallel islands carry `tier` (premium | god) and `intensity`
    (the intended height, 1-10). Satellites are rhythm keepers, untiered.
    """
    t = data["rules"].get("tiers")
    if not t:
        return []
    v: list[str] = []
    islands = data["islands"]
    tiered = [n for n in data["order"] if islands[n]["size"] in ("big", "parallel")]
    for n in tiered:
        tier = islands[n].get("tier")
        if tier not in t["floor"]:
            v.append(f"tier: {n} needs a tier ({', '.join(t['floor'])})")
            return v
        if intensity(islands[n]) < t["floor"][tier]:
            who = "founder score" if latest_score(islands[n]) is not None else "intensity"
            v.append(f"tier: {n} {who} {intensity(islands[n])} below the {tier} floor {t['floor'][tier]}: redesign or re-tier")
    for a, b in zip(tiered, tiered[1:]):
        if islands[a]["tier"] == islands[b]["tier"] == "god":
            v.append(f"tier: two god-tier islands back to back ({a}, {b})")
    gods = [n for n in tiered if islands[n]["tier"] == "god"]
    if not gods:
        return v + ["tier: no god-tier island"]
    if sched[gods[0]]["arrival"] > t["hook_by"]:
        v.append(f"tier: the first god-tier island ({gods[0]}) arrives day {sched[gods[0]]['arrival']}; the hook must land by day {t['hook_by']}")
    if t.get("finale_god") and islands[tiered[-1]]["tier"] != "god":
        v.append(f"tier: the finale ({tiered[-1]}) is not god-tier")
    for a, b in zip(gods, gods[1:]):
        gap = sched[b]["arrival"] - sched[a]["arrival"]
        if gap < t["god_min_days"]:
            v.append(f"tier: god-tier {a} and {b} only {gap} days apart; want >= {t['god_min_days']}")
    base = [intensity(islands[n]) for n in tiered if islands[n]["tier"] == "premium"]
    if any(y < x for x, y in zip(base, base[1:])):
        v.append(f"tier: the premium baseline falls somewhere in {base}; it must rise")
    peaks = [intensity(islands[n]) for n in gods]
    if peaks[-1] < max(peaks):
        v.append(f"tier: the last peak ({gods[-1]}, {peaks[-1]}) is lower than an earlier one {peaks}")
    return v


def latest_score(island: dict):
    """The founder's latest numeric score of the island's current design, or None.

    Scores of a design older than `design_loop` are history: they explain the
    redesign but no longer judge it.
    """
    current = island.get("design_loop", 0)
    scores = [s for s in island.get("founder_scores") or [] if s.get("score") is not None and s["loop"] >= current]
    return scores[-1]["score"] if scores else None


def intensity(island: dict) -> float:
    """The founder's score when he has scored this design; else the designed intensity."""
    s = latest_score(island)
    return s if s is not None else island.get("intensity", 0)


def report(data: dict, sched: dict) -> str:
    islands = data["islands"]
    lines = ["island        size       cluster  rumour  arrival  runway  bloom  tier     int  score"]
    awaiting = []
    for name in data["order"]:
        s, isl = sched[name], islands[name]
        score = latest_score(isl)
        if score is None and isl["size"] != "home":
            awaiting.append(name)
        lines.append(
            f"{name:<13} {isl['size']:<10} {isl['cluster']:<8} "
            f"{s['rumour']:>6}  {s['arrival']:>7}  {s['runway']:>6}  {s.get('bloom', '-'):>5}  "
            f"{isl.get('tier', '-'):<7}  {isl.get('intensity', '-'):>3}  {score if score is not None else '-':>5}"
        )
    lines.append("")
    lines.append(f"awaiting the founder's score of the current design: {', '.join(awaiting) or 'none'}")
    lines.append("")
    lines.append("satellite continuity:")
    for name in data["order"]:
        if islands[name]["size"] == "satellite":
            lines.append(f"  {name} ~ {islands[name]['orbits']}: shares {shared(data, name, islands[name]['orbits'])}")
    bigs = [n for n in data["order"] if islands[n]["size"] == "big"]
    lines.append("big-to-big novelty:")
    for a, b in zip(bigs, bigs[1:]):
        lines.append(f"  {a} -> {b}: differ on {len(data['axes']) - len(shared(data, a, b))}")
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else PROFILES
    data = load(path)
    violations, sched = check(data)
    if sched:
        print(report(data, sched))
        print()
    if violations:
        print(f"{len(violations)} violation(s):")
        for x in violations:
            print(f"  - {x}")
        return 1
    print("no violations")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
