#!/usr/bin/env python3
"""WCAG 2.x contrast report for Pofu's semantic color tokens.

Reads design/tokens/pofu-tokens.json and prints a Markdown table of every
pair listed under "contrastChecks", in light and dark mode. Exits with a
non-zero status if any pair falls below its required minimum, so it can run
in CI later.

Usage:
    python3 -I tools/design/contrast_report.py [--tokens PATH] [--json]

Standard library only.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

DEFAULT_TOKENS = Path(__file__).resolve().parents[2] / "design" / "tokens" / "pofu-tokens.json"


def relative_luminance(hex_color: str) -> float:
    """WCAG 2.x relative luminance of an sRGB hex color."""
    value = hex_color.lstrip("#")
    channels = [int(value[i:i + 2], 16) / 255 for i in (0, 2, 4)]

    def linearize(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (linearize(c) for c in channels)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(a: str, b: str) -> float:
    la, lb = sorted((relative_luminance(a), relative_luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def wcag_level(ratio: float) -> str:
    if ratio >= 7:
        return "AAA"
    if ratio >= 4.5:
        return "AA"
    if ratio >= 3:
        return "AA large / UI"
    return "decorative"


def resolve(tokens: dict, semantic_name: str, mode: str) -> str:
    primitive = tokens["semantic"][semantic_name][mode]
    return tokens["primitives"][primitive]


def build_rows(tokens: dict) -> list[dict]:
    rows = []
    for check in tokens["contrastChecks"]:
        for bg in check["bg"]:
            for mode in ("light", "dark"):
                fg_hex = resolve(tokens, check["fg"], mode)
                bg_hex = resolve(tokens, bg, mode)
                ratio = contrast_ratio(fg_hex, bg_hex)
                rows.append({
                    "fg": check["fg"],
                    "bg": bg,
                    "mode": mode,
                    "fgHex": fg_hex,
                    "bgHex": bg_hex,
                    "ratio": round(ratio, 2),
                    "level": wcag_level(ratio),
                    "min": check["min"],
                    "pass": ratio >= check["min"],
                })
    return rows


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tokens", type=Path, default=DEFAULT_TOKENS)
    parser.add_argument("--json", action="store_true", help="print JSON instead of Markdown")
    args = parser.parse_args(argv)

    tokens = json.loads(args.tokens.read_text(encoding="utf-8"))
    rows = build_rows(tokens)

    if args.json:
        print(json.dumps(rows, indent=2))
    else:
        print("| Foreground | Background | Mode | Colors | Ratio | Level | Required |")
        print("|---|---|---|---|---|---|---|")
        for r in rows:
            mark = "" if r["pass"] else " **FAIL**"
            required = f"{r['min']}:1" if r["min"] > 1 else "decorative"
            print(
                f"| `{r['fg']}` | `{r['bg']}` | {r['mode']} | `{r['fgHex']}` on `{r['bgHex']}` "
                f"| {r['ratio']:.2f}:1 | {r['level']} | {required}{mark} |"
            )

    failures = [r for r in rows if not r["pass"]]
    if failures:
        print(f"\n{len(failures)} pair(s) below the required minimum.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
