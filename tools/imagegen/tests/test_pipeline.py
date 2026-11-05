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
        {"id": "tea-stall-1", "kind": "station", "attach": [{"ref": "station-guide", "role": "the guide"}],
         "prompt": [{"text": "A tea stall."}, {"block": "view-v2"}, {"block": "prop-style-v2"}]},
        {"id": "tea-stall-2", "kind": "station", "edit_of": "tea-stall-1",
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
        self.assertEqual([j.id for j in m.jobs], ["tea-stall-1", "tea-stall-2"])
        j = m.job("tea-stall-1")
        self.assertEqual((j.kind, j.name, j.size, j.canvas, j.transparent), ("station", "tea-stall-1", (1024, 1024), (1024, 1024), True))
        self.assertEqual(j.take_file(2), "station__tea-stall-1--t2.png")

    def test_parents_come_first(self):
        data = manifest()
        data["jobs"].reverse()
        self.assertEqual([j.id for j in pl.parse_manifest(data, REFS).jobs], ["tea-stall-1", "tea-stall-2"])

    def test_rejections(self):
        cases = {
            "unknown kind": lambda d: d["jobs"][0].update(kind="sprite"),
            "bad id": lambda d: d["jobs"][0].update(id="tea-stall 1"),
            "duplicate id": lambda d: d["jobs"][1].update(id="tea-stall-1"),
            "unknown block": lambda d: d["jobs"][0]["prompt"].append({"block": "nope"}),
            "attachment without role": lambda d: d["jobs"][0].update(attach=[{"ref": "R1"}]),
            "too many variants": lambda d: d["jobs"][0].update(variants=9),
            "edit without keep block": lambda d: d["jobs"][1].update(prompt=[{"text": "x"}]),
            "unknown parent": lambda d: d["jobs"][1].update(edit_of="nope"),
            "bad size": lambda d: d["jobs"][0].update(size="big"),
            "transparent app icon": lambda d: d["jobs"][0].update(kind="appicon", transparent=True),
            "same output twice": lambda d: d["jobs"][1].update(name="tea-stall-1"),
        }
        for label, mutate in cases.items():
            with self.subTest(label):
                data = manifest()
                mutate(data)
                with self.assertRaises(pl.ManifestError):
                    pl.parse_manifest(data, REFS)

    def test_cycle(self):
        data = manifest()
        data["jobs"][0]["attach"].append({"ref": "approved:tea-stall-2", "role": "x"})
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
        data["jobs"][0] = {"id": "tea-stall-1", "kind": "station", "external": "batch-01-slice"}
        m = pl.parse_manifest(data, REFS)
        self.assertEqual(m.job("tea-stall-1").external, "batch-01-slice")
        self.assertEqual(m.job("tea-stall-1").prompt, [])
        self.assertEqual(pl.approved_image(m.job("tea-stall-1")), pl.ART_ROOT / "stations" / "tea-stall-1" / "tea-stall-1.png")
        self.assertEqual(pl.dependencies(m.job("tea-stall-2")), ["tea-stall-1"])
        for label, extra in {"edit": {"edit_of": "tea-stall-2"}, "attach": {"attach": [{"ref": "R1", "role": "x"}]},
                             "bad batch": {"external": "Batch 01"}}.items():
            with self.subTest(label):
                bad = manifest()
                bad["jobs"][0] = {"id": "tea-stall-1", "kind": "station", "external": "batch-01-slice", **extra}
                with self.assertRaises(pl.ManifestError):
                    pl.parse_manifest(bad, REFS)

    def test_slice_field_is_validated(self):
        data = manifest()
        data["jobs"][0].update(kind="ui", slice={"caps": [16, 26, 16, 26], "ship_height": 52})
        job = pl.parse_manifest(data, REFS).jobs[0]
        self.assertEqual(job.slice, {"caps": [16.0, 26.0, 16.0, 26.0], "ship_height": 52.0})
        for bad_slice in ({"caps": [16, 26, 16], "ship_height": 52},      # three caps
                          {"caps": [30, 26, 30, 26], "ship_height": 52},  # no centre left
                          {"caps": [16, 26, 16, 26]},                      # no ship height
                          {"caps": [-1, 26, 16, 26], "ship_height": 52}):
            bad = manifest()
            bad["jobs"][0].update(kind="ui", slice=bad_slice)
            with self.assertRaises(pl.ManifestError, msg=str(bad_slice)):
                pl.parse_manifest(bad, REFS)
        bad = manifest()  # a station is never sliced
        bad["jobs"][0]["slice"] = {"caps": [1, 1, 1, 1], "ship_height": 52}
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest(bad, REFS)

    def test_deliver_scale_is_validated(self):
        data = manifest()
        data["jobs"][0]["deliver"] = {"scale": 0.5}
        self.assertEqual(pl.parse_manifest(data, REFS).jobs[0].deliver, {"scale": 0.5})
        self.assertIsNone(pl.parse_manifest(manifest(), REFS).jobs[0].deliver)
        for bad_deliver in ({"scale": 0}, {"scale": 1.5}, {"scale": True}, {"scale": 0.5, "q": 1}, {}, 0.5):
            bad = manifest()
            bad["jobs"][0]["deliver"] = bad_deliver
            with self.assertRaises(pl.ManifestError, msg=str(bad_deliver)):
                pl.parse_manifest(bad, REFS)

    def test_style_exclude_drops_only_the_named_sentence(self):
        data = manifest()
        data["jobs"][0]["prompt"] = [{"text": "A frog."}, {"block": "style-anchor-v2"}]
        plain = pl.compose_prompt(pl.parse_manifest(data, REFS).jobs[0])
        self.assertIn("fur texture", plain)
        data["jobs"][0]["style_exclude"] = ["fur"]
        job = pl.parse_manifest(data, REFS).jobs[0]
        out = pl.compose_prompt(job)
        self.assertNotIn("fur", out)
        self.assertIn("Light direction, colours and shadow hue", out)
        data["jobs"][0]["style_exclude"] = ["nonsense"]
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest(data, REFS)

    def test_job_palettes_extend_the_drift_check(self):
        data = manifest()
        data["jobs"][0]["palettes"] = ["world-night", "character-tabby"]
        self.assertEqual(pl.parse_manifest(data, REFS).jobs[0].palettes, ["world-night", "character-tabby"])
        self.assertEqual(pl.parse_manifest(manifest(), REFS).jobs[0].palettes, [])
        for bad_value in ("world-night", [3], ["Not Kebab"]):
            bad = manifest()
            bad["jobs"][0]["palettes"] = bad_value
            with self.assertRaises(pl.ManifestError, msg=str(bad_value)):
                pl.parse_manifest(bad, REFS)

    def glow(self, **over):
        data = manifest()
        job = {"id": "glow-test", "kind": "ui", "transparent": False, "blend": "additive",
               "prompt": [{"text": "A glow."}]}
        job.update(over)
        data["jobs"].append(job)
        return data

    def test_blend_reaches_the_acceptance_profile(self):
        m = pl.parse_manifest(self.glow(), REFS)
        self.assertEqual(m.job("glow-test").acceptance["blend"], "additive")
        self.assertNotIn("blend", m.job("tea-stall-1").acceptance)

    def test_blend_must_be_known_and_on_an_opaque_ui_job(self):
        for over in ({"blend": "multiply"}, {"transparent": True}, {"kind": "prop"}):
            with self.assertRaises(pl.ManifestError, msg=str(over)):
                pl.parse_manifest(self.glow(**over), REFS)

    def test_job_palettes_reach_the_job(self):
        m = pl.parse_manifest(self.glow(palettes=["world-foliage"]), REFS)
        self.assertEqual(m.job("glow-test").palettes, ["world-foliage"])

    def test_batch_35_glows_are_additive_and_sheets_carry_foliage(self):
        for name in ("batch-35-experience-pilot", "batch-35-experience"):
            m = pl.load_manifest(HERE.parent / "manifest" / f"{name}.yaml")
            for j in m.jobs:
                if j.external:
                    continue
                if j.id.startswith("glow-"):
                    self.assertEqual(j.acceptance.get("blend"), "additive", j.id)
                if j.id.startswith(("dressing-", "critter-")):
                    self.assertIn("world-foliage", j.palettes, j.id)

    def test_retry_manifest_loads_and_its_palettes_and_modes_exist(self):
        import qa
        m = pl.load_manifest(HERE.parent / "manifest" / "retry-2026-11-03.yaml")
        todo = [j for j in m.jobs if not j.external]
        self.assertEqual(len(todo), 32)
        for j in todo:
            qa.palette_sets(j.palettes)  # KeyError on an unknown palette
            self.assertIn(j.acceptance.get("edit_mode", "keep"), qa.EDIT_MODES, j.id)
        # a recolor or region edit says so; a plain edit does not need to
        self.assertEqual(m.job("game-plot-tile-rose").acceptance["edit_mode"], "recolor")
        self.assertEqual(m.job("ui-lantern-on").acceptance["edit_mode"], "region")
        # no pilot cascade: the harbor props do not wait for the ferry, the goat not for bagel-cart
        deps = {j.id: pl.dependencies(j) for j in todo}
        self.assertNotIn("harbor-ferry-1", deps["harbor-crates-1"] + deps["harbor-horn-1"] + deps["harbor-lamp-1"])
        self.assertNotIn("simit-kitten", deps["harbor-goat"])
        self.assertTrue(all("ui-sheet-paper" not in deps[j.id] for j in todo if j.id.startswith("icon-")))

    def test_external_master_at_its_own_path(self):
        data = manifest()
        r1 = "design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png"
        data["jobs"][0] = {"id": "tea-stall-1", "kind": "station", "external": "r1", "master": r1}
        m = pl.parse_manifest(data, REFS)
        self.assertEqual(pl.approved_image(m.job("tea-stall-1")), (pl.REPO_ROOT / r1).resolve())
        bad = manifest()
        bad["jobs"][0]["master"] = r1  # only an external job may name its image
        with self.assertRaises(pl.ManifestError):
            pl.parse_manifest(bad, REFS)


class PromptTests(unittest.TestCase):
    def test_blocks_are_verbatim_and_refs_listed_in_order(self):
        m = pl.parse_manifest(manifest(), REFS)
        p = pl.compose_prompt(m.job("tea-stall-1"))
        self.assertIn(pl.read_block("view-v2"), p)
        self.assertIn(pl.read_block("prop-style-v2"), p)
        self.assertTrue(p.startswith("REFERENCES (attached, in this order):\n1. the guide"))
        self.assertTrue(p.rstrip().endswith("Output: one image, transparent background PNG, square 1024 x 1024."))

    def test_edit_attaches_parent_first(self):
        m = pl.parse_manifest(manifest(), REFS)
        refs = pl.attachments_for(m.job("tea-stall-2"))
        self.assertEqual(refs[0].ref, "approved:tea-stall-1")
        self.assertEqual(pl.resolve_ref(refs[0].ref, m), pl.approved_image(m.job("tea-stall-1")))
        self.assertIn("1. The image to edit", pl.compose_prompt(m.job("tea-stall-2")))

    def test_chroma_fallback_line(self):
        data = manifest()
        data["jobs"][0]["key"] = "blue"
        m = pl.parse_manifest(data, REFS)
        line = pl.output_line(m.job("tea-stall-1"), "chroma")
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
        for name in ("icon-style-v1", "ui-object-v1", "widget-v1", "appicon-v1", "crafted-face-v1"):
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
            self.assertEqual([a.ref for a in first.attach][:2], ["station-guide", "approved:tea-stall-1"])
            for level in range(2, 6):
                self.assertEqual(m.job(f"{station}-{level}").edit_of, f"{station}-{level - 1}")
        # chains batch 01 started continue from its masters
        self.assertEqual((m.job("garden-3").edit_of, m.job("garden-2").external), ("garden-2", "batch-01-slice"))
        self.assertEqual((m.job("bagel-cart-2").edit_of, m.job("bagel-cart-1").external), ("bagel-cart-1", "batch-01-slice"))
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


class LegacyIdTests(unittest.TestCase):
    def test_old_turkish_ids_resolve_to_english(self):
        from legacy_ids import canonical

        self.assertEqual(canonical("cay-1"), "tea-stall-1")
        self.assertEqual(canonical("batch-01-slice:simit-2"), "batch-01-slice:bagel-cart-2")
        self.assertEqual(canonical("iskele-vapur-1"), "harbor-ferry-1")
        self.assertEqual(canonical("simit-kitten"), "simit-kitten")
        self.assertEqual(canonical("tea-stall-1"), "tea-stall-1")
