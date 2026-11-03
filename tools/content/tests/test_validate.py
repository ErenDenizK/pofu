"""Tests for the Pofu Atlas content validator (python3 -I -m pytest -q tools/content/tests)."""
import shutil
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import validate  # noqa: E402


def copy_content(tmp_path: Path) -> Path:
    root = tmp_path / "content"
    shutil.copytree(validate.CONTENT, root)
    return root


def edit(root: Path, rel: str, **changes) -> None:
    f = root / rel
    node = yaml.safe_load(f.read_text(encoding="utf-8"))
    node.update(changes)
    f.write_text(yaml.safe_dump(node, allow_unicode=True, sort_keys=False), encoding="utf-8")


def test_repository_content_is_valid():
    errors, _, nodes = validate.validate()
    assert errors == []
    assert len(nodes) > 100


def test_every_manifest_job_has_an_asset_node():
    _, _, nodes = validate.validate()
    named = {j for n in nodes for j in (n.get("art") or {}).get("jobs", [])}
    assert set(validate.load_manifest_jobs()) <= named


def test_broken_link_is_an_error(tmp_path):
    root = copy_content(tmp_path)
    edit(root, "stations/station-cay.yaml", links={"part_of": ["island-nowhere"]})
    errors, _, _ = validate.validate(root)
    assert any("island-nowhere" in e for e in errors)


def test_duplicate_id_and_file_name(tmp_path):
    root = copy_content(tmp_path)
    shutil.copy(root / "stations/station-cay.yaml", root / "stations/station-tea-stall-copy.yaml")
    errors, _, _ = validate.validate(root)
    assert any("duplicate id" in e for e in errors)
    assert any("file name must be the id" in e for e in errors)


def test_missing_art_path_is_an_error(tmp_path):
    root = copy_content(tmp_path)
    edit(root, "assets/asset-tea-stall-1.yaml", art={"images": ["design/art/nope.png"], "jobs": ["batch-01-slice:tea-stall-1"]})
    errors, _, _ = validate.validate(root)
    assert any("design/art/nope.png" in e for e in errors)


def test_unknown_job_and_bad_anchor(tmp_path):
    root = copy_content(tmp_path)
    edit(root, "assets/asset-tea-stall-1.yaml", art={"images": [], "jobs": ["batch-01-slice:no-such-job"]},
         sources=[{"doc": "docs/product/game-design.md", "anchor": "#no-such-heading"}])
    errors, _, _ = validate.validate(root)
    assert any("no-such-job" in e for e in errors)
    assert any("#no-such-heading" in e for e in errors)


def test_brainstorm_must_be_maybe(tmp_path):
    root = copy_content(tmp_path)
    edit(root, "ideas/idea-island-leylek.yaml", horizon="next")
    errors, _, _ = validate.validate(root)
    assert any("lead-brainstorm" in e for e in errors)


def test_heading_slugs_follow_github(tmp_path):
    doc = tmp_path / "d.md"
    doc.write_text("# Seeds (TR: *çekirdek*)\n## Home ↔ island\n## Home ↔ island\n```\n# not a heading\n```\n", encoding="utf-8")
    assert validate.heading_slugs(doc) == {"seeds-tr-çekirdek", "home--island", "home--island-1"}
