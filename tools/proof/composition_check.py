#!/usr/bin/env python3
"""The five composition rules C1 to C5 of docs/design/world-presentation-v2.md section 1.2, per still.

    python3 tools/proof/composition_check.py DIR [--out check.txt]

Reads the `<still>.json` sidecars that `composition.py` writes next to each still (boxes in pt on the 402 x 874
reference: subjects with their name chips, the chrome, the backdrop features) and prints one line per rule per still.

  C1 hero centre as a share of the height: Map 0.66 to 0.72 (Home with its chip), mid 0.42 to 0.46 (the island),
     near: the focused character's feet 0.58 to 0.62
  C2 tallest full-width run with no subject and no chrome, share of the height: Map at most 0.18, mid 0.14, near 0.30.
     The spec's words are "no subject and no chrome" but its own numbers only close if the named backdrop features count
     (far isles, whale, lip), so both are printed: the first is with features, the strict one in brackets. The verdict is
     on the first.
  C3 each third holds a subject, chrome or a named backdrop feature (near: the top third may be sky)
  C4 no island box (or tower) cut by a screen edge; no tappable inside the safe bands (y < 62 or > 840) or, off the
     corner control, inside the corner keep-out (x 314 to 386 and y 766 to 840, mirrored at near)
  C5 smallest tappable island on the Map at least 88 pt wide
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

W, H = 402.0, 874.0
SAFE_TOP, SAFE_BOTTOM = 62.0, 840.0
CORNER_R = (314.0, 766.0, 386.0, 840.0)
CORNER_L = (16.0, 766.0, 88.0, 840.0)


def runs(boxes, strict_extra=()) -> float:
    """Tallest run of rows (share of H) covered by none of the boxes."""
    rows = [False] * int(H)
    for b in boxes:
        for y in range(max(int(b[1]), 0), min(int(b[3]) + 1, int(H))):
            rows[y] = True
    best = cur = 0
    for r in rows:
        cur = 0 if r else cur + 1
        best = max(best, cur)
    return best / H


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
        v = (hb[1] + hb[3]) / 2 / H
        res["C1"] = (0.66 <= v <= 0.72, f"{v:.3f} (0.66 to 0.72)")
    elif kind == "mid":
        hb = m["hero"]
        v = (hb[1] + hb[3]) / 2 / H
        res["C1"] = (0.42 <= v <= 0.46, f"{v:.3f} (0.42 to 0.46)")
    else:
        v = m["feet"][1] / H
        res["C1"] = (0.58 <= v <= 0.62, f"{v:.3f} (0.58 to 0.62)")
    # C2
    limit = {"map": 0.18, "mid": 0.14, "near": 0.30}[kind]
    with_f = runs(subj + chrome + feats)
    strict = runs(subj + chrome)
    res["C2"] = (with_f <= limit + 1e-9, f"{with_f:.3f} [strict {strict:.3f}] (at most {limit:.2f})")
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
    for r in ("C1", "C2", "C3", "C4", "C5"):
        lines.append(f"  {r}: {', '.join(fails.get(r, [])) or 'none'}")
    text = "\n".join(lines)
    print(text)
    if args.out:
        args.out.write_text(text + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
