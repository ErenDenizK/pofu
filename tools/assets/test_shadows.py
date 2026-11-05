"""Tests for tools/assets/shadows.py (unittest, also collected by pytest)."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import shadows  # noqa: E402


def make_catalog(root: Path, names: list[str], size=(64, 48)) -> Path:
    catalog = root / "World.xcassets"
    for name in names:
        folder = catalog / f"{name}.imageset"
        folder.mkdir(parents=True)
        image = Image.new("RGBA", size, (200, 120, 40, 0))
        for x in range(16, 48):
            for y in range(8, 44):
                image.putpixel((x, y), (200, 120, 40, 255))
        image.save(folder / f"{name}.png")
    return catalog


class ShadowsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.manifest = self.root / "shadows.json"

    def tearDown(self):
        self.tmp.cleanup()

    def test_casters_exclude_plates_glows_variants_and_shadows(self):
        names = [
            "world-mochi", "world-tea-stall-1", "world-tea-stall-1-glow", "world-island-main-band0",
            "world-isle-hamam-standin", "world-far-isle-1", "world-cloud-2", "world-mochi__soft",
            "world-pofu--normal", "world-harbor-island-s", "ui-jar-empty", "ui-pot-empty", "world-mochi-shadow",
        ]
        catalog = make_catalog(self.root, names)
        self.assertEqual(shadows.casters(catalog), ["ui-jar-empty", "world-mochi", "world-tea-stall-1"])

    def test_run_writes_a_quarter_size_blurred_silhouette(self):
        catalog = make_catalog(self.root, ["world-mochi"])
        self.assertEqual(shadows.run(catalog, self.manifest), 1)
        png = catalog / "world-mochi-shadow.imageset" / "world-mochi-shadow.png"
        self.assertTrue((catalog / "world-mochi-shadow.imageset" / "Contents.json").is_file())
        with Image.open(png) as out:
            self.assertEqual(out.size, (16, 12))
            self.assertEqual(out.getpixel((8, 6))[:3], (0, 0, 0))
            self.assertGreater(out.getpixel((8, 6))[3], 200)
            self.assertLess(out.getpixel((0, 0))[3], 40)

    def test_run_is_deterministic_and_idempotent(self):
        catalog = make_catalog(self.root, ["world-mochi", "world-findik"])
        self.assertEqual(shadows.run(catalog, self.manifest), 2)
        first = (catalog / "world-mochi-shadow.imageset" / "world-mochi-shadow.png").read_bytes()
        self.assertEqual(shadows.run(catalog, self.manifest), 0)
        (catalog / "world-mochi-shadow.imageset" / "world-mochi-shadow.png").unlink()
        self.assertEqual(shadows.run(catalog, self.manifest), 1)
        self.assertEqual((catalog / "world-mochi-shadow.imageset" / "world-mochi-shadow.png").read_bytes(), first)

    def test_check_flags_missing_stale_and_orphans(self):
        catalog = make_catalog(self.root, ["world-mochi"])
        self.assertEqual(shadows.problems(catalog, self.manifest), ["world-mochi: no shadow"])
        shadows.run(catalog, self.manifest)
        self.assertEqual(shadows.problems(catalog, self.manifest), [])
        # The source changes: the shadow is stale.
        Image.new("RGBA", (64, 48), (0, 0, 0, 255)).save(catalog / "world-mochi.imageset" / "world-mochi.png")
        self.assertEqual(shadows.problems(catalog, self.manifest), ["world-mochi: shadow is stale"])
        # A shadow whose caster is gone.
        shadows.run(catalog, self.manifest)
        (catalog / "world-gone-shadow.imageset").mkdir()
        self.assertEqual(shadows.problems(catalog, self.manifest), ["world-gone-shadow.imageset: no such caster"])

    def test_run_removes_orphans(self):
        catalog = make_catalog(self.root, ["world-mochi"])
        shadows.run(catalog, self.manifest)
        (catalog / "world-mochi.imageset" / "world-mochi.png").unlink()
        (catalog / "world-mochi.imageset").rmdir()
        shadows.run(catalog, self.manifest)
        self.assertFalse((catalog / "world-mochi-shadow.imageset").exists())

    def test_caster_without_a_png_is_skipped(self):
        catalog = make_catalog(self.root, [])
        (catalog / "world-pofu.imageset").mkdir(parents=True)
        self.assertEqual(shadows.run(catalog, self.manifest), 0)
        self.assertEqual(shadows.problems(catalog, self.manifest), [])

    def test_the_repo_is_current(self):
        self.assertEqual(shadows.problems(), [])


if __name__ == "__main__":
    unittest.main()
