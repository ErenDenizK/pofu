"""Manifest model, prompt composition and repository paths for the image pipeline.

Everything here is pure (no network, no image generation) so it can be
unit-tested on Linux. See tools/imagegen/README.md for the workflow.
"""
from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

import yaml

import light as lt
from legacy_ids import canonical

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[1]
# Where approved art lives (design/art). Tests point it at a temporary folder.
ART_ROOT = REPO_ROOT / "design" / "art"
BLOCKS_DIR = HERE / "blocks"
CONFIG_PATH = HERE / "config.yaml"

KINDS = ("char", "station", "world", "prop", "sheet", "plate", "icon", "ui", "widget", "appicon")
# Canonical canvas per kind (art bible section 7, game design section 15,
# ADR-0018 "Glass++" for the UI kinds). A job may override it with `canvas`.
CANVAS = {
    "char": (1024, 1536),
    "station": (1024, 1024),
    "world": (1536, 1024),
    "prop": (1024, 1024),
    "plate": (1024, 1536),
    "sheet": None,  # keeps the source size; sliced later by process_assets.py
    "icon": (1024, 1024),     # domain icon, transparent, legible at 24 and 30 pt
    "ui": (1024, 1024),       # painted UI object (seed jar, calm lantern), transparent
    "widget": (1536, 720),    # medium widget background (about 2.1 : 1), opaque
    "appicon": (1024, 1024),  # app icon master, opaque, no text
}
# Kinds that are opaque by nature: fitted by cropping (cover), not padding.
OPAQUE_KINDS = ("plate", "widget", "appicon")
# Chroma-key colors for the fallback when a backend cannot return alpha.
# Blue for anything green (lawns, leaves); green for everything else.
KEY_COLORS = {"green": "#00FF00", "blue": "#0000FF"}
ID_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
SIZE_RE = re.compile(r"^(\d{3,4})x(\d{3,4})$")
MAX_VARIANTS = 4  # art bible section 10: "ask 3-4 times", never more


class ManifestError(ValueError):
    pass


# The light standard applies to NEW manifests only; older batches are
# grandfathered by this switch (batch number, retry date, or an explicit
# `light_standard: true` in the manifest, which batch 19 and any older open
# manifest may use to opt in early).
LIGHT_FROM_BATCH = 20
LIGHT_FROM_DATE = (2026, 11, 4)


def light_required(data: dict) -> bool:
    if data.get("light_standard") is True:
        return True
    batch = str(data.get("batch", ""))
    m = re.match(r"^batch-(\d+)(?:-|$)", batch)
    if m:
        return int(m[1]) >= LIGHT_FROM_BATCH
    m = re.match(r"^retry-(\d{4})-(\d{2})-(\d{2})$", batch)
    if m:
        return tuple(int(x) for x in m.groups()) >= LIGHT_FROM_DATE
    return False


@dataclass
class Attach:
    ref: str          # alias, repo path, palette:<name> or approved:<job-id>
    role: str         # what the model should take from it, in plain words


@dataclass
class Job:
    id: str
    kind: str
    name: str
    prompt: list[dict]
    attach: list[Attach] = field(default_factory=list)
    edit_of: str | None = None
    size: tuple[int, int] = (1024, 1024)
    transparent: bool = True
    key: str = "green"
    variants: int = 2
    acceptance: dict = field(default_factory=dict)
    chat: str | None = None
    notes: str = ""
    canvas: tuple[int, int] | None = None
    # The batch that generates this master. An external job is never
    # generated here: it only lets this manifest's jobs edit or attach a
    # master another batch made (approved once that master is on disk).
    external: str | None = None
    # An external master outside the pipeline's folder layout (R1, the
    # approved Pofu, predates the pipeline): a repository path to its image.
    master: str | None = None
    # Decor pieces are drawn on the decor guide and registered and checked
    # against it: "ground" (stands on the footprint) or "hang" (hangs from the
    # hang line). Set by `decor:` or, for a prop, by attaching `decor-guide`.
    decor: str | None = None
    # 9-slice insets for a surface the app stretches (ui-system-v2 section
    # 6.1): {caps: [top, left, bottom, right] in pt at 1x, ship_height: pt}.
    # Written to the master's meta.json on promote; the asset catalog step
    # converts it to Contents.json.
    slice: dict | None = None
    # Extra locked palettes for the drift check, added to the kind's list
    # (config.yaml `palettes`). For art whose brief names colors the kind's
    # palettes do not hold: an emissive glow (world-night), a violet
    # button (ui), a honey tabby (character-tabby).
    palettes: list[str] = field(default_factory=list)
    # The art light standard (docs/design/light-standard.md): {cell, layer}.
    # Required on new manifests for every kind except icon, ui, widget, appicon.
    light: dict | None = None
    # Guide fit (qa.fit_to_guide) override for a root station or ground decor:
    # {max_width, top}, or False to turn the downscale off. None = guide defaults.
    fit: dict | bool | None = None

    @property
    def asset(self) -> str:
        """Pipeline file stem, e.g. station__tea-stall-1."""
        return f"{self.kind}__{self.name}"

    def take_file(self, take: int) -> str:
        return f"{self.asset}--t{take}.png"


@dataclass
class Manifest:
    batch: str
    title: str
    jobs: list[Job]
    refs: dict[str, str]
    path: Path | None = None
    status: str = "open"            # open | blocked: `run` refuses to generate for a blocked batch
    blocked_on: list[str] = field(default_factory=list)

    def job(self, job_id: str) -> Job:
        job_id = canonical(job_id)  # old Turkish ids still resolve
        for j in self.jobs:
            if j.id == job_id:
                return j
        raise KeyError(job_id)


# ---------------------------------------------------------------------------
# Loading and validation
# ---------------------------------------------------------------------------

def load_config(path: Path = CONFIG_PATH) -> dict:
    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))


def parse_size(value) -> tuple[int, int]:
    m = SIZE_RE.match(str(value).replace(" ", ""))
    if not m:
        raise ManifestError(f"size must look like 1024x1024, got {value!r}")
    return int(m[1]), int(m[2])


def parse_manifest(data: dict, config_refs: dict | None = None, path: Path | None = None) -> Manifest:
    """Validate a manifest dict and build the model. Raises ManifestError."""
    if not isinstance(data, dict):
        raise ManifestError("manifest must be a mapping")
    batch = data.get("batch")
    if not batch or not ID_RE.match(str(batch)):
        raise ManifestError("batch must be a kebab-case id, e.g. vertical-slice-01")
    defaults = data.get("defaults", {}) or {}
    refs = dict(config_refs or {})
    refs.update(data.get("refs", {}) or {})
    need_light = light_required(data)
    jobs: list[Job] = []
    seen: set[str] = set()
    assets: set[str] = set()
    for i, raw in enumerate(data.get("jobs") or []):
        where = f"jobs[{i}]"
        merged = {**defaults, **raw}
        jid = merged.get("id")
        if not jid or not ID_RE.match(str(jid)):
            raise ManifestError(f"{where}: id must be kebab-case")
        where = f"job {jid}"
        if jid in seen:
            raise ManifestError(f"{where}: duplicate id")
        seen.add(jid)
        kind = merged.get("kind")
        if kind not in KINDS:
            raise ManifestError(f"{where}: kind must be one of {', '.join(KINDS)}")
        name = merged.get("name", jid)
        if not ID_RE.match(str(name)):
            raise ManifestError(f"{where}: name must be kebab-case")
        if f"{kind}__{name}" in assets:
            raise ManifestError(f"{where}: another job already writes {kind}__{name}")
        assets.add(f"{kind}__{name}")
        external = merged.get("external")
        if external is not None and not ID_RE.match(str(external)):
            raise ManifestError(f"{where}: external must name the batch that makes this master, e.g. batch-01-slice")
        prompt = merged.get("prompt")
        if external:
            if merged.get("edit_of") or merged.get("attach"):
                raise ManifestError(f"{where}: an external job only points at another batch's master (no edit_of, no attach)")
            prompt = prompt or []
        master = merged.get("master")
        if master is not None and not external:
            raise ManifestError(f"{where}: master names an external job's image; add external: <who made it>")
        if not isinstance(prompt, list) or (not prompt and not external):
            raise ManifestError(f"{where}: prompt must be a non-empty list of {{text: ...}} or {{block: ...}} parts")
        for part in prompt:
            if not isinstance(part, dict) or len(part) != 1 or not ({"text", "block"} & set(part)):
                raise ManifestError(f"{where}: each prompt part is {{text: ...}} or {{block: <name>}}")
            if "block" in part and not (BLOCKS_DIR / f"{part['block']}.txt").exists():
                raise ManifestError(f"{where}: unknown block {part['block']!r} (no blocks/{part['block']}.txt)")
        attach = []
        for a in merged.get("attach", []) or []:
            if isinstance(a, str):
                a = {"ref": a, "role": ""}
            if not a.get("ref") or not a.get("role"):
                raise ManifestError(f"{where}: every attachment needs ref and role (say what the model should take from it)")
            attach.append(Attach(str(a["ref"]), str(a["role"]).strip()))
        variants = int(merged.get("variants", 2))
        if not 1 <= variants <= MAX_VARIANTS:
            raise ManifestError(f"{where}: variants must be 1-{MAX_VARIANTS} (generate wide, select hard, but never bulk)")
        key = merged.get("key", "green")
        if key not in KEY_COLORS:
            raise ManifestError(f"{where}: key must be one of {', '.join(KEY_COLORS)}")
        size = parse_size(merged.get("size", "x".join(map(str, CANVAS.get(kind) or (1024, 1024)))))
        canvas = parse_size(merged["canvas"]) if merged.get("canvas") else CANVAS.get(kind)
        transparent = bool(merged.get("transparent", kind not in OPAQUE_KINDS))
        if kind == "appicon" and transparent:
            raise ManifestError(f"{where}: an app icon is opaque (transparent: false)")
        slice_ = merged.get("slice")
        if slice_ is not None:
            caps = slice_.get("caps") if isinstance(slice_, dict) else None
            height = slice_.get("ship_height") if isinstance(slice_, dict) else None
            if (not isinstance(caps, list) or len(caps) != 4 or not all(isinstance(c, (int, float)) and c >= 0 for c in caps)
                    or not isinstance(height, (int, float)) or height <= 0 or set(slice_) - {"caps", "ship_height"}):
                raise ManifestError(f"{where}: slice must be {{caps: [top, left, bottom, right], ship_height: pt}} with non-negative caps")
            if kind not in ("ui", "icon"):
                raise ManifestError(f"{where}: slice applies to ui jobs only")
            if 2 * max(caps[0], caps[2]) >= height:
                raise ManifestError(f"{where}: top and bottom caps must leave a stretchable centre inside ship_height")
            slice_ = {"caps": [float(c) for c in caps], "ship_height": float(height)}
        fit = merged.get("fit")
        if fit is not None and fit is not False and (
                not isinstance(fit, dict) or set(fit) - {"max_width", "top"}
                or not all(isinstance(v, int) and not isinstance(v, bool) and v > 0 for v in fit.values())):
            raise ManifestError(f"{where}: fit is {{max_width: px, top: y}} or false")
        decor = merged.get("decor")
        if decor is None and kind == "prop" and any(a.ref == "decor-guide" for a in attach):
            decor = "ground"
        if decor not in (None, "ground", "hang") or (decor and kind != "prop"):
            raise ManifestError(f"{where}: decor is ground or hang, and applies to prop jobs only")
        extra = merged.get("palettes") or []
        if not isinstance(extra, list) or not all(isinstance(x, str) and ID_RE.match(x) for x in extra):
            raise ManifestError(f"{where}: palettes must be a list of palette names, e.g. [world-night]")
        light = merged.get("light")
        if light is not None:
            try:
                light = lt.parse_light(light, where)
            except lt.LightError as e:
                raise ManifestError(str(e)) from None
            if kind in lt.EXEMPT_KINDS:
                raise ManifestError(f"{where}: {kind} jobs carry no scene light (drop `light`)")
            if lt.is_sprite(kind, transparent) and light["cell"] != "day":
                raise ManifestError(f"{where}: a sprite ({kind}, transparent) is painted under the day cell; the game relights it (got {light['cell']!r})")
        elif need_light and not external and kind not in lt.EXEMPT_KINDS:
            raise ManifestError(f"{where}: a {kind} job needs `light: {{cell, layer}}` (docs/design/light-standard.md); set it per job or in defaults")
        job = Job(id=jid, kind=kind, name=name, prompt=prompt, attach=attach, edit_of=merged.get("edit_of"),
                  size=size, transparent=transparent, key=key,
                  variants=variants, acceptance=merged.get("acceptance", {}) or {}, chat=merged.get("chat"),
                  notes=merged.get("notes", "") or "", canvas=canvas, external=str(external) if external else None,
                  master=str(master) if master else None, slice=slice_, decor=decor, palettes=list(extra), light=light, fit=fit)
        jobs.append(job)
    if not jobs:
        raise ManifestError("manifest has no jobs")
    ids = {j.id for j in jobs}
    for j in jobs:
        for dep in dependencies(j):
            if dep not in ids:
                raise ManifestError(f"job {j.id}: depends on unknown job {dep!r}")
        if j.edit_of and not any(p.get("block") == "edit-keep-v1" for p in j.prompt):
            raise ManifestError(f"job {j.id}: an edit (edit_of) must include the edit-keep-v1 block")
    order = topological_order(jobs)  # raises on cycles
    by_id = {j.id: j for j in jobs}
    status = str(data.get("status", "open"))
    if status not in ("open", "blocked"):
        raise ManifestError("status must be open or blocked")
    blocked_on = [str(x) for x in (data.get("blocked_on") or [])]
    if status == "blocked" and not blocked_on:
        raise ManifestError("a blocked batch must say what it is blocked_on")
    return Manifest(batch=batch, title=data.get("title", batch), jobs=[by_id[i] for i in order], refs=refs, path=path,
                    status=status, blocked_on=blocked_on)


def load_manifest(path: Path, config: dict | None = None) -> Manifest:
    config = config if config is not None else load_config()
    data = yaml.safe_load(Path(path).read_text(encoding="utf-8"))
    return parse_manifest(data, config.get("refs", {}), Path(path))


def dependencies(job: Job) -> list[str]:
    deps = [job.edit_of] if job.edit_of else []
    for a in job.attach:
        if a.ref.startswith("approved:"):
            dep = a.ref.split(":", 1)[1]
            if dep not in deps:
                deps.append(dep)
    return deps


def topological_order(jobs: list[Job]) -> list[str]:
    """Stable order: manifest order, but parents before children."""
    by_id = {j.id: j for j in jobs}
    out: list[str] = []
    state: dict[str, int] = {}

    def visit(jid: str, trail: tuple[str, ...]) -> None:
        if state.get(jid) == 2:
            return
        if state.get(jid) == 1:
            raise ManifestError(f"dependency cycle: {' -> '.join(trail + (jid,))}")
        state[jid] = 1
        for dep in dependencies(by_id[jid]):
            if dep in by_id:
                visit(dep, trail + (jid,))
        state[jid] = 2
        out.append(jid)

    for j in jobs:
        visit(j.id, ())
    return out


# ---------------------------------------------------------------------------
# Prompt composition
# ---------------------------------------------------------------------------

def read_block(name: str) -> str:
    return (BLOCKS_DIR / f"{name}.txt").read_text(encoding="utf-8").strip()


def output_line(job: Job, background: str = "transparent") -> str:
    w, h = job.size
    shape = "square" if w == h else ("landscape" if w > h else "portrait")
    if not job.transparent:
        return f"Output: one image, opaque, full bleed, {shape} {w} x {h}."
    if background == "chroma":
        color = KEY_COLORS[job.key]
        return (f"Output: one image, {shape} {w} x {h}, on a perfectly flat, uniform pure {color} background "
                f"(a chroma key: no gradient, no shadow, no texture, and none of that color inside the object).")
    return f"Output: one image, transparent background PNG, {shape} {w} x {h}."


def compose_prompt(job: Job, background: str = "transparent") -> str:
    """The exact prompt text, identical for every backend.

    Attachments are listed first, in order, with their role, so a model (or
    a person pasting into ChatGPT) knows what each image is for.
    """
    parts: list[str] = []
    refs = attachments_for(job)
    if refs:
        lines = ["REFERENCES (attached, in this order):"]
        for i, a in enumerate(refs, 1):
            lines.append(f"{i}. {a.role}")
        parts.append("\n".join(lines))
    for p in job.prompt:
        parts.append(read_block(p["block"]) if "block" in p else str(p["text"]).strip())
    if job.light:
        parts.append(lt.render_block(job.light, sprite=lt.is_sprite(job.kind, job.transparent)))
    parts.append(output_line(job, background))
    return "\n\n".join(parts) + "\n"


def attachments_for(job: Job) -> list[Attach]:
    """Attachments in order; an edit's parent always comes first."""
    out = []
    if job.edit_of:
        out.append(Attach(f"approved:{job.edit_of}", "The image to edit (the approved previous level). Edit it; do not redraw it."))
    out.extend(a for a in job.attach if a.ref != f"approved:{job.edit_of}")
    return out


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

def dest_root(kind: str) -> Path:
    """Where approved takes live: stations, UI art (ADR-0018), or masters."""
    if kind == "station":
        sub = "stations"
    elif kind in ("icon", "ui", "widget", "appicon"):
        sub = "ui"
    else:
        sub = "masters"
    return ART_ROOT / sub


def approved_dir(job: Job) -> Path:
    # UI kinds share one folder, so the kind prefixes the name (icon-seed, ui-jar-0).
    prefix = f"{job.kind}-" if job.kind in ("icon", "ui", "widget", "appicon") else ""
    return dest_root(job.kind) / f"{prefix}{job.name}"


def approved_image(job: Job) -> Path:
    if job.master:
        return (REPO_ROOT / job.master).resolve()
    d = approved_dir(job)
    return d / f"{d.name}.png"


def resolve_ref(ref: str, manifest: Manifest) -> Path:
    """Turn an attachment ref into a file path (it may not exist yet)."""
    if ref.startswith("approved:"):
        return approved_image(manifest.job(ref.split(":", 1)[1]))
    if ref.startswith("palette:"):
        return REPO_ROOT / "design" / "reference" / f"palette-card-{ref.split(':', 1)[1]}.png"
    target = manifest.refs.get(ref, ref)
    return (REPO_ROOT / target).resolve()


def inbox_dir(config: dict, batch: str) -> Path:
    return REPO_ROOT / config["paths"]["inbox"] / batch


def build_dir(config: dict, batch: str) -> Path:
    return REPO_ROOT / config["paths"]["build"] / batch


def review_file(config: dict, batch: str) -> Path:
    return REPO_ROOT / config["paths"]["review"] / f"{batch}.yaml"


def contact_sheet_path(config: dict, batch: str) -> Path:
    return REPO_ROOT / config["paths"]["contact_sheets"] / f"{batch}.png"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def fingerprint(prompt: str, attachment_paths: list[Path]) -> str:
    """Identifies a take's inputs: the prompt text and every attachment's bytes."""
    h = hashlib.sha256(prompt.encode("utf-8"))
    for p in attachment_paths:
        h.update(sha256_file(p).encode() if p.exists() else b"missing:" + str(p).encode())
    return h.hexdigest()[:16]


def read_sidecar(png: Path) -> dict:
    side = png.with_suffix(".json")
    return json.loads(side.read_text(encoding="utf-8")) if side.exists() else {}
