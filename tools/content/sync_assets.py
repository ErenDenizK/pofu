#!/usr/bin/env python3
"""Keep asset nodes in step with the image manifests and the promoted art.

    python3 -I tools/content/sync_assets.py           # write changes
    python3 -I tools/content/sync_assets.py --dry-run # only list them

For every job in tools/imagegen/manifest/*.yaml (except `external` ones):
- no asset node yet: writes a stub content/assets/asset-<job id>.yaml with
  the job, its kind, its batch and the first prompt line as the summary;
- the approved image now exists on disk (after `run.py promote`): adds it to
  `art.images` (replacing a branch entry for the same path) and moves the
  status from planned to in-production.

It never deletes a node and never touches titles, notes or links, so the lead
and Codex can edit those by hand. Validate afterwards with validate.py.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate import CONTENT, MANIFESTS, REPO, image_path  # noqa: E402


class _Dumper(yaml.SafeDumper):
    pass


def _str(dumper, s):
    style = ">" if len(s) > 72 or "\n" in s else None
    return dumper.represent_scalar("tag:yaml.org,2002:str", s, style=style)


_Dumper.add_representer(str, _str)


def dump_node(node: dict) -> str:
    """The house YAML style for content nodes (folded long strings, key order kept)."""
    body = {k: v for k, v in node.items() if not k.startswith("_")}
    return yaml.dump(body, Dumper=_Dumper, allow_unicode=True, sort_keys=False, width=88)


def approved_image(kind: str, name: str) -> str:
    """Mirror of tools/imagegen/pipeline.py approved_image()."""
    if kind == "station":
        d = f"design/art/stations/{name}"
    elif kind in ("icon", "ui", "widget", "appicon"):
        d = f"design/art/ui/{kind}-{name}"
    else:
        d = f"design/art/masters/{name}"
    return f"{d}/{d.rsplit('/', 1)[1]}.png"


def first_prompt_line(job: dict) -> str:
    for block in job.get("prompt") or []:
        if isinstance(block, dict) and block.get("text"):
            text = " ".join(block["text"].split())
            return text[:420] + ("…" if len(text) > 420 else "")
    return f"{job.get('kind', 'image')} job {job['id']}."


def sync(dry_run: bool = False) -> list[str]:
    changes = []
    for mf in sorted(MANIFESTS.glob("*.yaml")):
        m = yaml.safe_load(mf.read_text(encoding="utf-8"))
        for job in m.get("jobs", []):
            if job.get("external"):
                continue
            aid = f"asset-{job['id']}"
            path = CONTENT / "assets" / f"{aid}.yaml"
            img = approved_image(job["kind"], job["name"])
            on_disk = (REPO / img).is_file()
            if not path.exists():
                node = {
                    "id": aid, "type": "asset", "title_tr": job["id"],
                    "title_en": f"{job['name']} ({job['kind']})",
                    "status": "in-production" if on_disk or m.get("status") == "open" else "planned",
                    "horizon": "later" if m.get("status") == "blocked" else "now",
                    "summary": first_prompt_line(job),
                }
                if job.get("edit_of"):
                    node["links"] = {"variant_of": [f"asset-{job['edit_of']}"]}
                node["art"] = {"images": [img] if on_disk else [], "jobs": [f"{m['batch']}:{job['id']}"]}
                node["sources"] = [{"doc": f"tools/imagegen/manifest/{mf.name}"}]
                node.update({"kind": job["kind"], "batch": m["batch"]})
                if job.get("size"):
                    node["size"] = job["size"]
                changes.append(f"new  {path.relative_to(REPO)}")
                if not dry_run:
                    path.write_text(dump_node(node), encoding="utf-8")
                continue
            if not on_disk:
                continue
            node = yaml.safe_load(path.read_text(encoding="utf-8"))
            art = node.setdefault("art", {})
            images = art.setdefault("images", [])
            if img in images:
                continue
            art["images"] = [img] + [i for i in images if image_path(i)[0] != img]
            if node.get("status") in ("idea", "planned"):
                node["status"] = "in-production"
            changes.append(f"art  {path.relative_to(REPO)} <- {img}")
            if not dry_run:
                path.write_text(dump_node(node), encoding="utf-8")
    return changes


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    changes = sync(args.dry_run)
    print("\n".join(changes) or "Asset nodes are in step with the manifests.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
