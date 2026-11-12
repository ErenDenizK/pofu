"""The file set the art factory (pofu-art) needs, worked out from the pipeline code.

pofu-art holds `tools/imagegen`, every manifest, and the references that the
queue's runnable manifests use. The reference closure is not guessed: each
manifest is loaded with `tools/imagegen/pipeline.py` and every attachment is
turned into a path by the pipeline's own `attachments_for` and `resolve_ref`
(plus an edit's parent and an external job's `master`), so a change in how
refs resolve is picked up here. Used by `sync_to_art.py` and `check_closure.py`.

Pure Python, no network. Needs PyYAML, Pillow and numpy (`pipeline` imports `light`).
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

HERE = Path(__file__).resolve().parent
SOURCE_ROOT = HERE.parents[1]
sys.path.insert(0, str(SOURCE_ROOT / "tools" / "imagegen"))
import pipeline as pl  # noqa: E402

MANIFEST_DIR = "tools/imagegen/manifest"
CONFIG = "tools/imagegen/config.yaml"
QUEUE = "QUEUE.md"
# Where the queue lives in the main repo until the factory repo takes over (the pointer
# section there says so; the source of truth for the queue is pofu-art/QUEUE.md).
PLAN_FALLBACK = "docs/design/art-production-plan.md"

# Files outside tools/imagegen that its code reads at run time (found by reading qa.py,
# light.py, process_assets.py and run.py), plus the standing references and docs that
# AGENTS.md tells Codex to read.
TOOL_FILES = [
    "tools/assets/process_assets.py",
    # Codex standing work reads the plate state list.
    "docs/state/plates.yaml",
    "tools/art/grade_take.py",
    "tools/review/sheet.py",
    # The QA harmony check (qa.check_harmony) imports harmony and its config; without them
    # the check is skipped, so the auto-pick would lose its tie-break.
    "tools/assets/harmony.py",
    "tools/assets/vivid.py",
    "tools/assets/vivid.json",
    "design/art/materials.json",
    "docs/design/art-bible.md",
    "tools/assets/requirements.txt",
    "design/tokens/pofu-tokens.json",
    "design/art/light-standard.json",
    "design/art/colour-script.json",
    "design/art/templates/station-guide.png",
    "design/art/templates/decor-guide.png",
    "design/art/tests/2026-11-01/world__island-main-s_take1.png",
    "design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png",
    "docs/design/art-direction-study.md",
    "docs/design/light-standard.md",
    "docs/design/visual-system.md",
]
TOOL_DIRS = ["tools/imagegen", "design/art/harmony"]
# Never copied: caches and the git-ignored run folders.
SKIP_PARTS = {"__pycache__", ".pytest_cache", ".venv", "inbox"}


@dataclass
class Closure:
    files: set[str] = field(default_factory=set)       # repo-relative posix paths that exist in `root`
    pending: dict[str, set[str]] = field(default_factory=dict)  # ref -> manifests: made by an earlier job, not on disk yet
    missing: dict[str, set[str]] = field(default_factory=dict)  # ref -> manifests: should exist but does not
    manifests: list[str] = field(default_factory=list)  # the manifests the closure was computed for
    errors: list[str] = field(default_factory=list)  # manifests that do not load in `root` (a block or alias is missing)
    unmanifested: list[str] = field(default_factory=list)  # queue rows whose manifest is not written yet


def _set_root(root: Path) -> None:
    pl.REPO_ROOT = root
    pl.ART_ROOT = root / "design" / "art"
    pl.BLOCKS_DIR = root / "tools" / "imagegen" / "blocks"


def _rel(root: Path, p: Path) -> str:
    try:
        return p.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return p.as_posix()


def _twin(p: Path) -> Path | None:
    """A master stored only as .webp (the upload cap) stands in for its .png, and back."""
    for suf in ((".webp",) if p.suffix == ".png" else (".png",) if p.suffix == ".webp" else ()):
        q = p.with_suffix(suf)
        if q.exists():
            return q
    return None


def queue_text(root: Path) -> str:
    """The queue table: pofu-art/QUEUE.md, or (before the move) the main repo's plan."""
    for name in (QUEUE, PLAN_FALLBACK):
        f = Path(root) / name
        if f.is_file():
            return f.read_text(encoding="utf-8")
    return ""


def runnable_batches(text: str) -> list[str]:
    """Batch names in the queue tables whose state is not done, dropped or blocked.

    A row's second cell names the batch(es) in backticks; its last cell is the state.
    READY, BACKLOG and a bare "to do" all count as not yet run.
    """
    out: list[str] = []
    for line in text.splitlines():
        if not line.startswith("|") or line.startswith("|---") or line.startswith("| #"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 3:
            continue
        state = re.sub(r"[*_`]", "", cells[-1]).strip().lower()
        if state.startswith(("done", "dropped", "blocked")) or not state:
            continue
        for name in re.findall(r"`(batch-[a-z0-9-]+|retry-[0-9-]+)`", cells[1]):
            if name not in out:
                out.append(name)
    return out


def all_manifests(root: Path) -> list[Path]:
    return sorted((root / MANIFEST_DIR).glob("*.yaml"))


def load(root: Path, path: Path) -> pl.Manifest:
    _set_root(root)
    cfg = yaml.safe_load((root / CONFIG).read_text(encoding="utf-8"))
    return pl.load_manifest(path, cfg)


def manifest_refs(root: Path, path: Path) -> list[tuple[str, Path, str]]:
    """Every (ref, resolved path, kind) a manifest reads from disk.

    kind is `file` (alias, repo path, palette card, external master) or `parent`
    (an approved:/outpaint-* ref to a job of this manifest, which the batch itself may make).
    """
    m = load(root, path)
    out: list[tuple[str, Path, str]] = []
    for job in m.jobs:
        if job.master:
            out.append((job.master, pl.approved_image(job), "file"))
        for a in pl.attachments_for(job):
            kind, _, pid = a.ref.partition(":")
            if kind in ("approved", "outpaint-input", "outpaint-mask"):
                parent = m.job(pid)
                if parent.external or parent.master:
                    out.append((a.ref, pl.approved_image(parent), "file"))
                else:
                    out.append((a.ref, pl.approved_image(parent), "parent"))
            else:
                out.append((a.ref, pl.resolve_ref(a.ref, m), "file"))
    return out


def standard_references(root: Path) -> list[str]:
    """The liked takes the light standard measures against (`reference` in light-standard.json)."""
    f = root / "design/art/light-standard.json"
    if not f.is_file():
        return []
    refs = json.loads(f.read_text(encoding="utf-8")).get("reference", {})
    return [f"design/art/takes/{r}" for rels in refs.values() if isinstance(rels, list) for r in rels]


def prompt_errors(root: Path, path: Path) -> list[str]:
    """Jobs whose prompt cannot be composed in `root` (a style or prompt block is missing)."""
    m = load(root, path)
    out = []
    for job in m.jobs:
        try:
            pl.compose_prompt(job)
        except (OSError, KeyError, ValueError) as e:
            out.append(f"{path.name}: {job.id}: {e}")
    return out


def static_files(root: Path) -> set[str]:
    """tools/imagegen with its tests and every manifest, plus the files its code reads."""
    out: set[str] = set()
    for d in TOOL_DIRS:
        for p in (root / d).rglob("*"):
            if p.is_file() and not SKIP_PARTS & set(p.relative_to(root).parts):
                out.add(_rel(root, p))
    out.update(f for f in TOOL_FILES if (root / f).is_file())
    out.update(f for f in standard_references(root) if (root / f).is_file())
    return out


def compute(root: Path, batches: list[str] | None = None, source: Path | None = None) -> Closure:
    """The closure for `batches` (default: the runnable queue rows), read from `root`.

    `source` is the main-repo checkout used to tell "not copied yet" from "made later by
    the batch": a ref missing in `root` but present in `source` is `missing`; missing in
    both, and a parent of the same manifest, is `pending`.
    """
    root = Path(root).resolve()
    source = Path(source).resolve() if source else root
    if batches is None:
        batches = runnable_batches(queue_text(source))
    c = Closure()
    for name in batches:
        path = root / MANIFEST_DIR / f"{name}.yaml"
        if not path.is_file():
            c.unmanifested.append(name)  # a backlog row the lead has not written a manifest for yet
            continue
        c.manifests.append(name)
        try:
            refs = manifest_refs(root, path)
        except (pl.ManifestError, KeyError, OSError, yaml.YAMLError) as e:
            c.errors.append(f"{name}: {e}")
            continue
        for ref, p, kind in refs:
            q = p if p.exists() else _twin(p)
            if q is not None and q.exists():
                c.files.add(_rel(root, q))
                continue
            rel = _rel(root, p)
            if source != root:
                s = source / rel
                s = s if s.exists() else _twin(s)
                if s is not None and s.exists():
                    c.missing.setdefault(rel, set()).add(name)
                    continue
            (c.pending if kind == "parent" else c.missing).setdefault(rel, set()).add(name)
    return c


def wanted_files(source: Path, art: Path | None = None) -> tuple[set[str], Closure]:
    """Everything pofu-art should hold, as repo-relative paths in `source`.

    The runnable batches come from the QUEUE.md of the art checkout (the lead edits the
    queue there), else from the source's own plan document.
    """
    source = Path(source).resolve()
    text = queue_text(Path(art)) if art else ""
    c = compute(source, runnable_batches(text) if text else None)
    files = static_files(source) | c.files
    return files, c


def size_mb(root: Path, files) -> float:
    return sum((Path(root) / f).stat().st_size for f in files if (Path(root) / f).is_file()) / 1e6
