"""Tests for `preblur.py app --only` (design/prototypes/interactions/tools/preblur.py): a scoped bake
touches only its own imagesets, Swift rows and shadows, and a second run changes no byte."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PREBLUR = REPO / "design/prototypes/interactions/tools/preblur.py"
CATALOG = REPO / "Packages/PofuKit/Sources/PofuWorld/Resources/World.xcassets"
SWIFT = REPO / "Packages/PofuKit/Sources/PofuWorld/Geometry/WorldArt+Generated.swift"
SHADOWS = REPO / "tools/assets/shadows.json"

# A small source to bake, and neighbours that a whole run would rebuild or delete.
SCOPE = "world-koke-stone"
OWN = ("world-koke-stone", "world-koke-stone__soft", "world-koke-stone__deep", "world-koke-stone-shadow")
OTHERS = ("world-koke-asleep", "world-koke-asleep__soft", "world-koke-asleep-shadow", "world-mochi", "world-cloud-2")


def load_preblur():
    spec = importlib.util.spec_from_file_location("pofu_preblur_test", PREBLUR)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def snapshot(root: Path) -> dict[str, str]:
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(root.rglob("*")) if p.is_file()}


class ScopedBakeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pb = load_preblur()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.catalog = root / "World.xcassets"
        for name in OWN + OTHERS:
            shutil.copytree(CATALOG / f"{name}.imageset", self.catalog / f"{name}.imageset")
        (self.catalog / "Contents.json").write_text('{"info": {"author": "xcode", "version": 1}}\n')
        self.swift = root / "WorldArt+Generated.swift"
        shutil.copy(SWIFT, self.swift)
        self.shadows = root / "shadows.json"
        shutil.copy(SHADOWS, self.shadows)
        self.saved = (self.pb.APP_CATALOG, self.pb.APP_SWIFT, self.pb.APP_SHADOWS)
        self.pb.APP_CATALOG, self.pb.APP_SWIFT, self.pb.APP_SHADOWS = str(self.catalog), str(self.swift), str(self.shadows)
        self.root = root

    def tearDown(self):
        self.pb.APP_CATALOG, self.pb.APP_SWIFT, self.pb.APP_SHADOWS = self.saved
        self.tmp.cleanup()

    def bake(self, *only):
        with redirect_stdout(StringIO()):
            return self.pb.app_main(["--only", *only])

    def test_a_scoped_run_touches_only_its_own_outputs_and_is_byte_stable(self):
        before = snapshot(self.root)
        swift_before = self.swift.read_text()
        self.assertEqual(self.bake(SCOPE), 0)
        first = snapshot(self.root)
        # Nothing outside the scope changed or vanished, and nothing new appeared outside it.
        for name in OTHERS:
            for key in [k for k in before if k.startswith(f"World.xcassets/{name}.imageset/")]:
                self.assertEqual(first.get(key), before[key], key)
        self.assertEqual(set(first) - set(before), set())
        for name in OWN:
            self.assertIn(f"World.xcassets/{name}.imageset/{name}.png", first)
        # Only koke-stone's row may differ in the Swift table; the other rows and the tail are kept.
        rows_before, tail_before = self.pb._read_swift(swift_before)
        rows_after, tail_after = self.pb._read_swift(self.swift.read_text())
        self.assertEqual(tail_after, tail_before)
        self.assertEqual(set(rows_after), set(rows_before))
        self.assertEqual({n for n in rows_before if rows_before[n] != rows_after[n]} - {"koke-stone"}, set())
        # The shadow manifest keeps every other entry.
        old, new = json.loads(SHADOWS.read_text()), json.loads(self.shadows.read_text())
        self.assertEqual({k: v for k, v in new.items() if k != SCOPE}, {k: v for k, v in old.items() if k != SCOPE})
        # A second run writes the same bytes.
        self.assertEqual(self.bake(SCOPE), 0)
        self.assertEqual(snapshot(self.root), first)

    def test_a_scope_that_matches_nothing_fails_and_writes_nothing(self):
        before = snapshot(self.root)
        with redirect_stdout(StringIO()), _quiet_stderr():
            self.assertEqual(self.pb.app_main(["--only", "world-no-such-*"]), 2)
        self.assertEqual(snapshot(self.root), before)

    def test_the_swift_table_reads_back_byte_for_byte(self):
        text = SWIFT.read_text()
        rows, tail = self.pb._read_swift(text)
        self.assertGreater(len(rows), 100)
        self.assertEqual(self.pb._swift_text(rows, tail), text)

    def test_scopes_match_by_imageset_or_source_name(self):
        self.assertTrue(self.pb._job_selected("koke-island-2", "", ["world-koke-island-*"]))
        self.assertTrue(self.pb._job_selected("koke-island-2", "", ["koke-island-2"]))
        self.assertFalse(self.pb._job_selected("koke-asleep", "", ["world-koke-island-*"]))
        self.assertTrue(self.pb._job_selected("anything", "", None))


class _quiet_stderr:
    def __enter__(self):
        self.saved, sys.stderr = sys.stderr, StringIO()

    def __exit__(self, *exc):
        sys.stderr = self.saved
        return False


if __name__ == "__main__":
    unittest.main()
