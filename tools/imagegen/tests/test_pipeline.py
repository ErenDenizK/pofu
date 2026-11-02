"""Manifest parsing, validation and prompt composition.

Run: python3 -I -m pytest tools/imagegen/tests   (or: python3 -I -m unittest discover -s tools/imagegen/tests)
"""
from __future__ import annotations

import copy
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import pipeline as pl  # noqa: E402

BASE = {
    "batch": "test-batch",
    "jobs": [
        {"id": "cay-1", "kind": "station", "attach": [{"ref": "station-guide", "role": "the guide"}],
         "prompt": [{"text": "A tea stall."}, {"block": "view-v2"}, {"block": "prop-style-v2"}]},
        {"id": "cay-2", "kind": "station", "edit_of": "cay-1",
         "prompt": [{"text": "Add an awning."}, {"block": "edit-keep-v1"}]},
    ],
}
REFS = {"station-guide": "design/art/templates/station-guide.png"}


def manifest(**changes):
    data = copy.deepcopy(BASE)
    data.update(changes)
    return data


class ParseTests(unittest.TestCase):
    def test_valid_manifest(self):
        m = pl.parse_manifest(manifest(), REFS)
        self.assertEqual([j.id for j in m.jobs], ["cay-1", "cay-2"])
        j = m.job("cay-1")
        self.assertEqual((j.kind, j.name, j.size, j.canvas, j.transparent), ("station", "cay-1", (1024, 1024), (1024, 1024), True))
        self.assertEqual(j.take_file(2), "station__cay-1--t2.png")

    def test_parents_come_first(self):
        data = manifest()
        data["jobs"].reverse()
        self.assertEqual([j.id for j in pl.parse_manifest(data, REFS).jobs], ["cay-1", "cay-2"])

    def test_rejections(self):
        cases = {
            "unknown kind": lambda d: d["jobs"][0].update(kind="sprite"),
            "bad id": lambda d: d["jobs"][0].update(id="Cay 1"),
            "duplicate id": lambda d: d["jobs"][1].update(id="cay-1"),
            "unknown block": lambda d: d["jobs"][0]["prompt"].append({"block": "nope"}),
            "attachment without role": lambda d: d["jobs"][0].update(attach=[{"ref": "R1"}]),
            "too many variants": lambda d: d["jobs"][0].update(variants=9),
            "edit without keep block": lambda d: d["jobs"][1].update(prompt=[{"text": "x"}]),
            "unknown parent": lambda d: d["jobs"][1].update(edit_of="nope"),
            "bad size": lambda d: d["jobs"][0].update(size="big"),
            "transparent app icon": lambda d: d["jobs"][0].update(kind="appicon", transparent=True),
            "same output twice": lambda d: d["jobs"][1].update(name="cay-1"),
        }
        for label, mutate in cases.items():
            with self.subTest(label):
                data = manifest()
                mutate(data)
                with self.assertRaises(pl.ManifestError):
                    pl.parse_manifest(data, REFS)

    def test_cycle(self):
        data = manifest()
        data["jobs"][0]["attach"].append({"ref": "approved:cay-2", "role": "x"})
        with self.assertRaisesRegex(pl.ManifestError, "cycle"):
            pl.parse_manifest(data, REFS)

    def test_ui_kinds_defaults(self):
        data = {"batch": "ui", "jobs": [
            {"id": "w", "kind": "widget", "size": "1536x1024", "prompt": [{"text": "x"}]},
            {"id": "a", "kind": "appicon", "prompt": [{"text": "x"}]},
            {"id": "i", "kind": "icon", "prompt": [{"text": "x"}]}]}
        m = pl.parse_manifest(data, {})
        self.assertEqual((m.job("w").canvas, m.job("w").transparent), ((1536, 720), False))
        self.assertFalse(m.job("a").transparent)
        self.assertTrue(m.job("i").transparent)
        self.assertEqual(pl.approved_dir(m.job("i")).name, "icon-i")

    def test_external_parent_from_another_batch(self):
        data = manifest()
        data["jobs"][0] = {"id": "cay-1", "kind": "station", "external": "batch-01-slice"}
        m = pl.parse_manifest(data, REFS)
        self.assertEqual(m.job("cay-1").external, "batch-01-slice")
        self.assertEqual(m.job("cay-1").prompt, [])
        self.assertEqual(pl.approved_image(m.job("cay-1")), pl.ART_ROOT / "stations" / "cay-1" / "cay-1.png")
        self.assertEqual(pl.dependencies(m.job("cay-2")), ["cay-1"])
        for label, extra in {"edit": {"edit_of": "cay-2"}, "attach": {"attach": [{"ref": "R1", "role": "x"}]},
                             "bad batch": {"external": "Batch 01"}}.items():
            with self.subTest(label):
                bad = manifest()
                bad["jobs"][0] = {"id": "cay-1", "kind": "station", "external": "batch-01-slice", **extra}
                with self.assertRaises(pl.ManifestError):
                    pl.parse_manifest(bad, REFS)

    def test_external_master_at_its_own_path(self):
        data = manifest()
        r1 = "design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png"
        data["jobs"][0] = {"id": "cay-1", "kind": "station", "external": "r1", "master": r1}
        m = pl.parse_manifest(data, REFS)
        self.assertEqual(pl.approved_image(m.job("cay-1")), (pl.REPO_ROOT / r1).resolve())
        bad = manifest()
        bad["jobs"][0]["master"] = r1  # only an external job may name its image
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest(bad, REFS)


class PromptTests(unittest.TestCase):
    def test_blocks_are_verbatim_and_refs_listed_in_order(self):
        m = pl.parse_manifest(manifest(), REFS)
        p = pl.compose_prompt(m.job("cay-1"))
        self.assertIn(pl.read_block("view-v2"), p)
        self.assertIn(pl.read_block("prop-style-v2"), p)
        self.assertTrue(p.startswith("REFERENCES (attached, in this order):\n1. the guide"))
        self.assertTrue(p.rstrip().endswith("Output: one image, transparent background PNG, square 1024 x 1024."))

    def test_edit_attaches_parent_first(self):
        m = pl.parse_manifest(manifest(), REFS)
        refs = pl.attachments_for(m.job("cay-2"))
        self.assertEqual(refs[0].ref, "approved:cay-1")
        self.assertEqual(pl.resolve_ref(refs[0].ref, m), pl.approved_image(m.job("cay-1")))
        self.assertIn("1. The image to edit", pl.compose_prompt(m.job("cay-2")))

    def test_chroma_fallback_line(self):
        data = manifest()
        data["jobs"][0]["key"] = "blue"
        m = pl.parse_manifest(data, REFS)
        line = pl.output_line(m.job("cay-1"), "chroma")
        self.assertIn("#0000FF", line)
        self.assertNotIn("transparent", line)

    def test_fingerprint_changes_with_prompt_or_reference(self):
        guide = pl.REPO_ROOT / REFS["station-guide"]
        a = pl.fingerprint("x", [guide])
        self.assertNotEqual(a, pl.fingerprint("y", [guide]))
        self.assertNotEqual(a, pl.fingerprint("x", []))
        self.assertEqual(a, pl.fingerprint("x", [guide]))

    def test_art_bible_anchors_are_copied_verbatim(self):
        bible = (pl.REPO_ROOT / "docs" / "design" / "art-bible.md").read_text(encoding="utf-8")
        for heading, block in (("### Style anchor v1", "style-anchor-v1"), ("### Character anchor v1", "character-anchor-v1"),
                               ("### Negative list", "negative-v1")):
            section = bible.split(heading, 1)[1]
            text = re.search(r"```text\n(.*?)```", section, re.S).group(1).strip()
            self.assertEqual(text, pl.read_block(block), block)

    def test_blocks_never_name_artists_and_ui_blocks_forbid_painted_glass(self):
        for path in pl.BLOCKS_DIR.glob("*.txt"):
            self.assertNotIn("in the style of", path.read_text(encoding="utf-8").lower(), path.name)
        for name in ("icon-style-v1", "ui-object-v1", "widget-v1", "appicon-v1"):
            text = pl.read_block(name).lower()
            self.assertRegex(text, r"no\s+glass|never\s+paint\s+glass", name)


class ShippedManifestTests(unittest.TestCase):
    def test_shipped_manifests_parse_and_resolve(self):
        config = pl.load_config()
        for path in sorted((pl.HERE / "manifest").glob("*.yaml")):
            with self.subTest(path.name):
                m = pl.load_manifest(path, config)
                for job in m.jobs:
                    pl.compose_prompt(job)
                    for a in pl.attachments_for(job):
                        target = pl.resolve_ref(a.ref, m)
                        if a.ref.startswith(("approved:",)) or "masters/island" in str(target) or "stations/" in str(target):
                            continue  # produced by an earlier round
                        self.assertTrue(target.exists(), f"{job.id}: {a.ref} -> {target}")

    def test_batch_02_is_about_twelve_images(self):
        m = pl.load_manifest(pl.HERE / "manifest" / "batch-02-ui.yaml")
        kinds = [j.kind for j in m.jobs]
        self.assertEqual(len(m.jobs), 12)
        self.assertEqual(kinds.count("icon"), 6)
        self.assertEqual(m.job("jar-1").edit_of, "jar-0")
        self.assertEqual(m.job("lantern-on").edit_of, "lantern-off")

    def test_batch_03_completes_the_home_island(self):
        m = pl.load_manifest(pl.HERE / "manifest" / "batch-03-home-island.yaml")
        made = [j for j in m.jobs if not j.external]
        self.assertTrue(all(j.variants == 2 for j in made))
        for station in ("pond", "workshop", "windmill"):
            first = m.job(f"{station}-1")
            self.assertEqual([a.ref for a in first.attach][:2], ["station-guide", "approved:cay-1"])
            for level in range(2, 6):
                self.assertEqual(m.job(f"{station}-{level}").edit_of, f"{station}-{level - 1}")
        # chains batch 01 started continue from its masters
        self.assertEqual((m.job("garden-3").edit_of, m.job("garden-2").external), ("garden-2", "batch-01-slice"))
        self.assertEqual((m.job("simit-2").edit_of, m.job("simit-1").external), ("simit-1", "batch-01-slice"))
        # founder feedback: Mochi loses Pofu's curl; Fındık never gets one
        self.assertEqual(m.job("mochi-v2").edit_of, "mochi")
        self.assertIn("Remove the single cream curl", pl.compose_prompt(m.job("mochi-v2")))
        self.assertIn("No curl or swirl", pl.compose_prompt(m.job("findik")))
        self.assertEqual(m.job("mochi-work").edit_of, "mochi-v2")
        self.assertEqual(m.job("findik-work").edit_of, "findik")
        self.assertIn("40% wider", pl.compose_prompt(m.job("island-main-l-v2")))
        self.assertIn("approved:island-main-l-v2", [a.ref for a in m.job("terrace-v2").attach])

    def test_batch_04_sky_is_transparent_and_has_no_characters(self):
        m = pl.load_manifest(pl.HERE / "manifest" / "batch-04-sky.yaml")
        made = [j for j in m.jobs if not j.external]
        self.assertEqual(len(made), 10)
        self.assertEqual(sum(j.id.startswith("cloud-") and j.id != "cloud-sea" for j in made), 5)
        for j in made:
            with self.subTest(j.id):
                self.assertTrue(j.transparent)
                self.assertNotEqual(j.kind, "char")
                self.assertRegex(pl.compose_prompt(j), r"No text")
        self.assertIn("tile seamlessly", pl.compose_prompt(m.job("cloud-sea")))


if __name__ == "__main__":
    unittest.main()
