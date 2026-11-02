#!/usr/bin/env python3
"""Validate Pofu Atlas content: content/<folder>/<id>.yaml against content/schema.json.

    python3 -I tools/content/validate.py            # errors fail, warnings print
    python3 -I tools/content/validate.py --strict   # warnings fail too

Checks:
- every file parses and matches the JSON Schema; the file name is its id and
  the folder matches its type;
- ids are unique;
- every link target, level asset, resident, home and station exists, and level
  assets are asset nodes;
- every art path exists (an image on an art branch is checked with git when
  that branch is fetched, and is a warning otherwise);
- every asset maps to a manifest job or to an image, every job it names exists
  in tools/imagegen/manifest/, and every manifest job has an asset node;
- every source document exists and its anchor matches a heading;
- lead-brainstorm nodes are marked horizon: maybe.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]
CONTENT = REPO / "content"
MANIFESTS = REPO / "tools" / "imagegen" / "manifest"

FOLDERS = {
    "island": "islands", "station": "stations", "character": "characters", "system": "systems",
    "moment": "moments", "theme": "themes", "idea": "ideas", "asset": "assets",
}
REF_FIELDS = ("resident", "home", "station")


def load_content(root: Path = CONTENT) -> tuple[list[dict], list[str]]:
    """Every node with its file path under `_file`, plus parse errors."""
    nodes, errors = [], []
    for path in sorted(root.glob("*/*.yaml")):
        try:
            data = yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as e:
            errors.append(f"{rel(path)}: YAML error: {e}")
            continue
        if not isinstance(data, dict):
            errors.append(f"{rel(path)}: not a mapping")
            continue
        data["_file"] = path
        nodes.append(data)
    return nodes, errors


def load_manifest_jobs(root: Path = MANIFESTS) -> dict[str, dict]:
    """'<batch>:<job id>' -> job, for every job a manifest generates (not `external`)."""
    jobs = {}
    for path in sorted(root.glob("*.yaml")):
        m = yaml.safe_load(path.read_text(encoding="utf-8"))
        for job in m.get("jobs", []):
            if not job.get("external"):
                jobs[f"{m['batch']}:{job['id']}"] = {**job, "_batch": m["batch"], "_status": m.get("status")}
    return jobs


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO))
    except ValueError:
        return str(path)


def image_path(img) -> tuple[str, str | None]:
    return (img, None) if isinstance(img, str) else (img["path"], img.get("branch"))


def git_has(branch: str, path: str) -> bool | None:
    """True or False when the branch is fetched; None when git cannot tell."""
    for ref in (f"origin/{branch}", branch):
        ok = subprocess.run(["git", "-C", str(REPO), "rev-parse", "--verify", "--quiet", ref],
                            capture_output=True).returncode == 0
        if ok:
            return subprocess.run(["git", "-C", str(REPO), "cat-file", "-e", f"{ref}:{path}"],
                                  capture_output=True).returncode == 0
    return None


def heading_slugs(doc: Path) -> set[str]:
    """GitHub's heading anchors for a Markdown file."""
    slugs, seen, fence = set(), {}, False
    for line in doc.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("```"):
            fence = not fence
            continue
        m = None if fence else re.match(r"^(#{1,6})\s+(.*?)\s*#*\s*$", line)
        if not m:
            continue
        text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", m.group(2))
        s = re.sub(r"[^\w\- ]", "", text.strip().lower()).replace(" ", "-")
        n = seen.get(s, 0)
        seen[s] = n + 1
        slugs.add(s if n == 0 else f"{s}-{n}")
    return slugs


def validate(root: Path = CONTENT, manifests: Path = MANIFESTS) -> tuple[list[str], list[str], list[dict]]:
    errors, warnings = [], []
    nodes, parse_errors = load_content(root)
    errors += parse_errors

    schema = json.loads((root / "schema.json").read_text(encoding="utf-8"))
    try:
        import jsonschema
        validator = jsonschema.Draft202012Validator(schema)
    except ImportError:
        validator = None
        warnings.append("jsonschema is not installed: schema checks skipped (pip install -r tools/content/requirements.txt)")

    by_id: dict[str, dict] = {}
    for n in nodes:
        f = rel(n["_file"])
        body = {k: v for k, v in n.items() if k != "_file"}
        if validator:
            for e in sorted(validator.iter_errors(body), key=lambda e: list(e.path)):
                where = "/".join(str(p) for p in e.path) or "(root)"
                errors.append(f"{f}: schema: {where}: {e.message}")
        nid = n.get("id")
        if not isinstance(nid, str):
            continue
        if nid in by_id:
            errors.append(f"{f}: duplicate id {nid!r} (also {rel(by_id[nid]['_file'])})")
        by_id[nid] = n
        if n["_file"].stem != nid:
            errors.append(f"{f}: file name must be the id ({nid}.yaml)")
        folder = FOLDERS.get(n.get("type"))
        if folder and n["_file"].parent.name != folder:
            errors.append(f"{f}: a {n['type']} lives in content/{folder}/")
        if n.get("source") == "lead-brainstorm" and n.get("horizon") != "maybe":
            errors.append(f"{f}: lead-brainstorm nodes are horizon: maybe until the founder picks them up")

    def ref(f, what, target, want_type=None):
        t = by_id.get(target)
        if t is None:
            errors.append(f"{f}: {what} -> {target!r} does not exist")
        elif want_type and t.get("type") != want_type:
            errors.append(f"{f}: {what} -> {target!r} is a {t.get('type')}, not a {want_type}")

    jobs = load_manifest_jobs(manifests)
    jobs_with_node = set()
    slug_cache: dict[Path, set[str]] = {}

    for n in nodes:
        f = rel(n["_file"])
        for edge, targets in (n.get("links") or {}).items():
            for t in targets or []:
                ref(f, f"links.{edge}", t, "asset" if edge == "uses_asset" else None)
                if t == n.get("id"):
                    errors.append(f"{f}: links.{edge} points at itself")
        for lv in n.get("levels") or []:
            if lv.get("asset"):
                ref(f, f"levels[{lv.get('level')}].asset", lv["asset"], "asset")
        for field in REF_FIELDS:
            if n.get(field):
                ref(f, field, n[field])
        for r in n.get("residents") or []:
            ref(f, "residents", r, "character")

        art = n.get("art") or {}
        for img in art.get("images") or []:
            path, branch = image_path(img)
            if (REPO / path).is_file():
                continue
            if branch is None:
                errors.append(f"{f}: art image {path} does not exist")
                continue
            has = git_has(branch, path)
            if has is False:
                errors.append(f"{f}: art image {path} is not on {branch}")
            elif has is None:
                warnings.append(f"{f}: {path} is on {branch}, which is not fetched here; not checked")
        for job in art.get("jobs") or []:
            if job not in jobs:
                errors.append(f"{f}: art job {job} is not in tools/imagegen/manifest/")
            jobs_with_node.add(job)
        if n.get("type") == "asset" and not (art.get("images") or art.get("jobs")):
            errors.append(f"{f}: an asset needs a manifest job or an image")

        for s in n.get("sources") or []:
            doc = REPO / s.get("doc", "")
            if not doc.is_file():
                errors.append(f"{f}: source {s.get('doc')} does not exist")
                continue
            anchor = s.get("anchor")
            if anchor and doc.suffix == ".md":
                if doc not in slug_cache:
                    slug_cache[doc] = heading_slugs(doc)
                if anchor[1:] not in slug_cache[doc]:
                    errors.append(f"{f}: source {s['doc']}{anchor} matches no heading")

    for job in sorted(set(jobs) - jobs_with_node):
        errors.append(f"tools/imagegen/manifest: job {job} has no asset node "
                      f"(run python3 -I tools/content/sync_assets.py)")

    return errors, warnings, nodes


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--strict", action="store_true", help="fail on warnings too")
    args = ap.parse_args()
    errors, warnings, nodes = validate()
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    counts: dict[str, int] = {}
    for n in nodes:
        counts[n.get("type", "?")] = counts.get(n.get("type", "?"), 0) + 1
    summary = ", ".join(f"{k} {v}" for k, v in sorted(counts.items()))
    print(f"{len(nodes)} nodes ({summary}); {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors or (args.strict and warnings) else 0


if __name__ == "__main__":
    sys.exit(main())
