#!/usr/bin/env python3
"""The composition rules C1 to C6 of docs/design/world-presentation-v2.md section 1.2, as corrected in round 3
(docs/design/world-presentation-round3-look.md), per still.

    python3 tools/proof/composition_check.py DIR [--out check.txt]

Reads the `<still>.json` sidecars that `composition.py` writes next to each still (boxes in pt on the 402 x 874
reference: subjects with their name chips, the chrome, the backdrop features) and prints one line per rule per still.

  C1 hero placement as a share of the height. Map, Home in front (journey): Home's foot, the island box without its
     chip, 0.79 to 0.81. Map, Home on top (homefirst): Home's box centre 0.30 to 0.36. Mid: the island's box centre
     0.42 to 0.46 with chrome. Near: the focused character's feet 0.58 to 0.62
  C2 tallest full-width run with no subject and no chrome, share of the height: Map at most 0.18, except the one run that
     holds the horizon, which may reach 0.21; mid at most 0.15; near at most 0.30. The spec's words are "no subject and no
     chrome" but its own numbers only close if the named backdrop features count (far isles, whale, lip), so both are
     printed: the first is with features, the strict one in brackets. The verdict is on the first.
  C3 each third holds a subject, chrome or a named backdrop feature (near: the top third may be sky)
  C4 no island box (or tower) cut by a screen edge; no tappable inside the safe bands (y < 59 or > 840) or, off the
     corner control, inside the corner keep-out (x 314 to 386 and y 766 to 840, mirrored at near)
  C5 smallest tappable island on the Map at least 88 pt wide
  C6 at rest no backdrop feature (far isle, whale) comes within 24 pt of a subject (its art box, with the chip), a slot
     (tower, veil) or a chrome box. Not checked: cloud puffs over 40 pt (the proof's puffs are one band, not cut-outs)
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

W, H = 402.0, 874.0
SAFE_TOP, SAFE_BOTTOM = 59.0, 840.0
CORNER_R = (314.0, 766.0, 386.0, 840.0)
CORNER_L = (16.0, 766.0, 88.0, 840.0)


def run_list(boxes) -> list[tuple[int, int]]:
    """Every run of rows (start, end) covered by none of the boxes."""
    rows = [False] * int(H)
    for b in boxes:
        for y in range(max(int(b[1]), 0), min(int(b[3]) + 1, int(H))):
            rows[y] = True
    out, start = [], None
    for y, r in enumerate(rows + [True]):
        if not r and start is None:
            start = y
        elif r and start is not None:
            out.append((start, y))
            start = None
    return out


def runs(boxes, horizon=None, allow=0.0) -> float:
    """Tallest run (share of H); the run holding row `horizon` is let off by `allow`, i.e. it counts that much less."""
    best = 0.0
    for a, b in run_list(boxes):
        v = (b - a) / H
        if horizon is not None and a <= horizon < b:
            v = max(v - allow, 0.0)
        best = max(best, v)
    return best


def gap(a, b) -> float:
    dx = max(0.0, a[0] - b[2], b[0] - a[2])
    dy = max(0.0, a[1] - b[3], b[1] - a[3])
    return (dx * dx + dy * dy) ** 0.5


def overlap(b, y0, y1) -> float:
    return max(0.0, min(b[3], y1) - max(b[1], y0))


def inter(a, b) -> bool:
    return a[0] < b[2] and a[2] > b[0] and a[1] < b[3] and a[3] > b[1]


def check(m: dict) -> dict[str, tuple[bool, str]]:
    kind = m["kind"]
    subj = [s["box"] for s in m["subjects"]]
    chrome = [c["box"] for c in m["chrome"]]
    feats = [f["box"] for f in m["features"]]
    res: dict[str, tuple[bool, str]] = {}
    # C1
    if kind == "map":
        hb = m["hero"]
        if m.get("order") == "homefirst":
            v = (hb[1] + hb[3]) / 2 / H
            res["C1"] = (0.30 <= v <= 0.36, f"Home on top, box centre {v:.3f} (0.30 to 0.36)")
        else:
            home = next(s for s in m["subjects"] if s["id"] == "home")
            v = home["island"][3] / H
            res["C1"] = (0.79 <= v <= 0.81, f"Home's foot {v:.3f} (0.79 to 0.81)")
    elif kind == "mid":
        hb = m["hero"]
        v = (hb[1] + hb[3]) / 2 / H
        res["C1"] = (0.42 <= v <= 0.46, f"{v:.3f} (0.42 to 0.46)")
    else:
        v = m["feet"][1] / H
        res["C1"] = (0.58 <= v <= 0.62, f"{v:.3f} (0.58 to 0.62)")
    # C2
    limit = {"map": 0.18, "mid": 0.15, "near": 0.30}[kind]
    hz = m.get("horizon") if kind == "map" else None
    allow = 0.21 - 0.18 if hz is not None else 0.0
    # a run is judged against `limit`; the one holding the horizon against 0.21 (its excess over limit is let off)
    with_f = runs(subj + chrome + feats, hz, allow)
    strict = runs(subj + chrome, hz, allow)
    res["C2"] = (with_f <= limit + 1e-9, f"{with_f:.3f} [strict {strict:.3f}] (at most {limit:.2f}{'; the horizon run 0.21' if hz is not None else ''})")
    # C3
    miss = []
    for i, (a, b) in enumerate(((0, H / 3), (H / 3, 2 * H / 3), (2 * H / 3, H))):
        if kind == "near" and i == 0:
            continue
        if not any(overlap(bx, a, b) >= 24 for bx in subj + chrome + feats):
            miss.append(["top", "middle", "bottom"][i])
    res["C3"] = (not miss, "all three thirds held" if not miss else "empty: " + ", ".join(miss))
    # C4
    bad = []
    keep = CORNER_L if kind == "near" else CORNER_R
    for s in m["subjects"]:
        b = s["box"]
        if s["type"] in ("island", "tower", "veil", "char") and not (kind == "near" and s["id"] == "lawn"):
            if b[0] < 0 or b[2] > W or b[1] < 0 or b[3] > H:
                bad.append(f"{s['id']} cut by the edge")
        if s.get("tappable") and kind != "near":
            if b[1] < SAFE_TOP or b[3] > SAFE_BOTTOM:
                bad.append(f"{s['id']} in a safe band")
            if inter(b, keep):
                bad.append(f"{s['id']} in the corner keep-out")
        if s["type"] == "char" and kind == "near":
            if b[0] < 0 or b[2] > W or b[1] < 0 or b[3] > H:
                bad.append(f"{s['id']} cut")
    for c in m["chrome"]:
        b = c["box"]
        corner = c["id"].startswith("corner") or c["id"] == "back_control"
        if not corner and (b[1] < SAFE_TOP - 0.5 or b[3] > SAFE_BOTTOM + 0.5):
            bad.append(f"{c['id']} in a safe band")
        if corner and (b[3] > SAFE_BOTTOM + 0.5):
            bad.append(f"{c['id']} in the bottom safe band")
    res["C4"] = (not bad, "none" if not bad else "; ".join(bad))
    # C6
    if kind == "near":
        res["C6"] = (True, "n/a")
    else:
        near_ = []
        others = [(s["id"], s.get("art", s["box"])) for s in m["subjects"] if s["type"] != "char"] + [(c["id"], c["box"]) for c in m["chrome"]]
        for f in m["features"]:
            if f["id"] == "lip":
                continue
            for oid, ob in others:
                g = gap(f["box"], ob)
                if g < 24.0:
                    near_.append(f"{f['id']} {g:.0f} pt from {oid}")
        res["C6"] = (not near_, "all at least 24 pt clear" if not near_ else "; ".join(near_))
    # C5
    if kind == "map":
        ws = {s["id"]: s["w_pt"] for s in m["subjects"] if s.get("tappable") and s["type"] == "island"}
        small = min(ws.values())
        res["C5"] = (small >= 88.0, f"smallest {min(ws, key=ws.get)} {small:.0f} pt (at least 88)")
    else:
        res["C5"] = (True, "n/a")
    return res


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("dir", type=Path)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args(argv)
    lines = []
    fails: dict[str, list[str]] = {}
    for f in sorted(args.dir.glob("*.json")):
        m = json.loads(f.read_text())
        if m["kind"] == "floor":
            continue
        lines.append(f"{m['name']}")
        for rule, (ok, txt) in check(m).items():
            lines.append(f"  {rule} {'PASS' if ok else 'FAIL'}  {txt}")
            if not ok:
                fails.setdefault(rule, []).append(m["name"])
    lines.append("")
    lines.append("failing, by rule:")
    for r in ("C1", "C2", "C3", "C4", "C5", "C6"):
        lines.append(f"  {r}: {', '.join(fails.get(r, [])) or 'none'}")
    text = "\n".join(lines)
    print(text)
    if args.out:
        args.out.write_text(text + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
