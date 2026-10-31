"""Self-test for the Pofu asset pipeline.

Uses the approved hamster concept crop (docs/brand/assets/concepts/) as real-world
input and builds every other fixture from it in a temporary folder, so the
test needs no network and no extra binaries.

Run:  python3 -I tools/assets/process_assets.py selftest
"""

from __future__ import annotations

import functools
import json
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import process_assets as pa  # noqa: E402

CONCEPT = pa.REPO_ROOT / "docs" / "brand" / "assets" / "concepts" / "hamster-gpt-image.png"


@functools.lru_cache(maxsize=1)
def _keyed_hamster() -> np.ndarray:
    rgba, has_alpha = pa.load_rgba(CONCEPT)
    assert not has_alpha, "the concept crop is expected to be opaque RGB"
    keyed, _ = pa.key_background(rgba)
    return keyed


def keyed_hamster() -> np.ndarray:
    return _keyed_hamster().copy()


def trimmed(rgba: np.ndarray) -> Image.Image:
    return pa.crop(rgba, pa.measure(rgba))


class KeyingTests(unittest.TestCase):
    def test_keys_flat_background_and_keeps_cream_face(self):
        rgba, _ = pa.load_rgba(CONCEPT)
        keyed, info = pa.key_background(rgba)
        h, w = keyed.shape[:2]
        self.assertEqual(keyed[2, 2, 3], 0.0, "corner should be transparent")
        self.assertGreater(keyed[int(h * 0.45), w // 2, 3], 0.99, "cream face must survive keying")
        self.assertLess(info["interiorHoleFraction"], pa.KEY_LEAK_MAX)
        self.assertGreater(info["keyedFraction"], 0.3)

    def test_detects_leak_through_a_gap_in_the_outline(self):
        img = Image.new("RGB", (600, 600), "#FEEEE6")
        draw = ImageDraw.Draw(img)
        draw.ellipse((100, 100, 500, 500), fill="#FDF1EA", outline="#ECA96E", width=24)
        draw.rectangle((296, 90, 304, 140), fill="#FEEEE6")  # a gap in the fur rim
        rgba = np.asarray(img.convert("RGBA"), dtype=np.float64) / 255
        _, info = pa.key_background(rgba)
        self.assertGreater(info["interiorHoleFraction"], pa.KEY_LEAK_MAX)

    def test_refuses_busy_background(self):
        rng = np.random.default_rng(3)
        noise = np.concatenate([rng.random((200, 200, 3)), np.ones((200, 200, 1))], axis=-1)
        with self.assertRaises(ValueError):
            pa.key_background(noise)


class DriftTests(unittest.TestCase):
    def setUp(self):
        self.tokens = pa.load_tokens()
        self.sets = pa.palette_sets(self.tokens, ["character", "character-wilting"])

    def test_approved_hamster_is_on_palette(self):
        report = pa.palette_drift(keyed_hamster(), self.sets)
        self.assertEqual(report.status, "ok", report.as_dict())

    def test_channel_swapped_hamster_fails(self):
        swapped = keyed_hamster()[..., [2, 0, 1, 3]]  # peach becomes mint
        report = pa.palette_drift(swapped, self.sets)
        self.assertEqual(report.status, "fail", report.as_dict())
        self.assertTrue(report.top_off_palette)

    def test_slight_warm_shift_is_tolerated_but_measured(self):
        shifted = keyed_hamster().copy()
        shifted[..., 0] = np.clip(shifted[..., 0] * 1.02, 0, 1)
        base = pa.palette_drift(keyed_hamster(), self.sets)
        report = pa.palette_drift(shifted, self.sets)
        self.assertGreater(report.mean, base.mean)
        self.assertNotEqual(report.status, "fail")


class ProcessTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.inbox = self.root / "inbox"
        self.inbox.mkdir()
        self.catalog = self.root / "out" / "PofuArt.xcassets"
        self.config = self.root / "config.json"
        # The concept crop is 532 px wide; real masters are 1024+.
        self.config.write_text(json.dumps({"char": {"min_source_px": 500}, "badge": {"min_source_px": 500}}))

    def tearDown(self):
        self.tmp.cleanup()

    def run_process(self, *extra: str) -> int:
        return pa.main(["process", "--inbox", str(self.inbox), "--out", str(self.catalog),
                        "--config", str(self.config), *extra])

    def test_character_frames_share_scale_and_ground_line(self):
        # Frame A: the raw opaque concept (exercises keying).
        Image.open(CONCEPT).save(self.inbox / "char__pofu-content.png")
        # Frame B: the same hamster at 70 % size, placed off-centre and high
        # on a larger transparent canvas, as a careless generation might be.
        small = trimmed(keyed_hamster())
        small = small.resize((round(small.width * 0.7), round(small.height * 0.7)), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (700, 900), (0, 0, 0, 0))
        canvas.alpha_composite(small, (40, 60))
        canvas.save(self.inbox / "char__pofu-small.png")

        self.assertEqual(self.run_process(), 0)
        frames = {}
        for name in ("pofu-content", "pofu-small"):
            imageset = self.catalog / "Character" / f"{name}.imageset"
            contents = json.loads((imageset / "Contents.json").read_text())
            files = {i["scale"]: i.get("filename") for i in contents["images"]}
            self.assertEqual(files["2x"], f"{name}@2x.png")
            self.assertEqual(files["3x"], f"{name}@3x.png")
            img3 = Image.open(imageset / files["3x"])
            img2 = Image.open(imageset / files["2x"])
            self.assertEqual(img3.size, (960, 960))
            self.assertEqual(img2.size, (640, 640))
            frames[name] = pa.measure(np.asarray(img3, dtype=np.float64) / 255)

        a, b = frames["pofu-content"], frames["pofu-small"]
        self.assertLessEqual(abs(a.baseline - b.baseline), 2, "feet must share one ground line")
        self.assertLessEqual(abs(a.base_x - b.base_x), 2, "feet must share one centre")
        self.assertAlmostEqual(b.width / a.width, 0.7, delta=0.03, msg="scale is shared, not re-fitted")
        self.assertAlmostEqual(a.baseline / 960, 0.92, delta=0.01)

        group = json.loads((self.catalog / "Character" / "Contents.json").read_text())
        self.assertTrue(group["properties"]["provides-namespace"])
        report = json.loads((self.catalog.parent / "PofuArt-report.json").read_text())
        statuses = {i["name"]: i["status"] for i in report["items"]}
        self.assertEqual(statuses["pofu-content"], "warn")  # keyed, so a warning

    def test_badge_is_trimmed_and_padded(self):
        canvas = Image.new("RGBA", (1200, 1200), (0, 0, 0, 0))
        canvas.alpha_composite(trimmed(keyed_hamster()), (20, 30))
        canvas.save(self.inbox / "badge__first-resist.png")
        self.assertEqual(self.run_process(), 0)
        img = Image.open(self.catalog / "Badges" / "first-resist.imageset" / "first-resist@3x.png")
        self.assertEqual(img.size, (360, 360))
        g = pa.measure(np.asarray(img, dtype=np.float64) / 255)
        self.assertLessEqual(abs((g.top + g.bottom) / 2 - 180), 2)
        self.assertGreaterEqual(g.top, 360 * 0.03 - 1)

    def test_app_icon_must_be_opaque(self):
        opaque = Image.new("RGB", (1024, 1024), "#FEEEE6")
        opaque.paste(trimmed(keyed_hamster()).convert("RGB"), (250, 140))
        opaque.save(self.inbox / "icon__app-icon.png")
        self.assertEqual(self.run_process(), 0)
        contents = json.loads((self.catalog / "AppIcon.appiconset" / "Contents.json").read_text())
        self.assertEqual(contents["images"][0]["size"], "1024x1024")
        self.assertEqual(Image.open(self.catalog / "AppIcon.appiconset" / "AppIcon.png").mode, "RGB")

        see_through = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        see_through.save(self.inbox / "icon__app-icon.png")
        self.assertEqual(self.run_process(), 1)

    def test_scene_upscale_is_reported(self):
        Image.new("RGB", (1024, 1536), "#BFE1F0").save(self.inbox / "scene__meadow-day.png")
        self.assertEqual(self.run_process(), 0)
        img = Image.open(self.catalog / "Scenes" / "meadow-day.imageset" / "meadow-day@3x.png")
        self.assertEqual(img.size, (1320, 1980))
        report = json.loads((self.catalog.parent / "PofuArt-report.json").read_text())
        self.assertIn("upscales", report["items"][0]["issues"][0]["message"])

    def test_unknown_names_are_skipped(self):
        Image.new("RGB", (10, 10)).save(self.inbox / "Pofu Final FINAL.png")
        Image.open(CONCEPT).save(self.inbox / "char__pofu-content.png")
        self.assertEqual(self.run_process(), 0)
        report = json.loads((self.catalog.parent / "PofuArt-report.json").read_text())
        self.assertEqual(report["skipped"], ["Pofu Final FINAL.png"])


class SliceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        figure = trimmed(keyed_hamster())
        self.figure = figure.resize((figure.width // 3, figure.height // 3), Image.Resampling.LANCZOS)
        self.cell = 260
        # A 3x3 sheet with the figure jittered inside each cell, frame 4 hopping.
        rng = np.random.default_rng(11)
        self.offsets = []
        sheet = Image.new("RGBA", (self.cell * 3, self.cell * 3), (0, 0, 0, 0))
        for i in range(9):
            r, c = divmod(i, 3)
            dx, dy = (int(v) for v in rng.integers(-12, 13, size=2))
            lift = 30 if i == 4 else 0
            x = c * self.cell + (self.cell - self.figure.width) // 2 + dx
            y = r * self.cell + self.cell - self.figure.height - 20 + dy - lift
            sheet.alpha_composite(self.figure, (x, y))
            self.offsets.append((dx, dy, lift))
        self.sheet = self.root / "pofu-blink-sheet.png"
        sheet.save(self.sheet)

    def tearDown(self):
        self.tmp.cleanup()

    def slice(self, *extra: str) -> dict:
        out = self.root / "anim"
        code = pa.main(["slice", "--sheet", str(self.sheet), "--name", "pofu-blink", "--grid", "3x3",
                        "--fps", "12", "--out", str(out), *extra])
        self.assertEqual(code, 0)
        return json.loads((out / "pofu-blink" / "manifest.json").read_text())

    def frame_geometry(self, manifest: dict, index: int) -> pa.Geometry:
        path = self.root / "anim" / "pofu-blink" / manifest["frames"][index]["files"]["1x"]
        return pa.measure(np.asarray(Image.open(path), dtype=np.float64) / 255)

    def test_feet_registration_removes_jitter(self):
        manifest = self.slice()
        self.assertEqual(manifest["frameCount"], 9)
        self.assertEqual(manifest["fps"], 12)
        self.assertAlmostEqual(manifest["durationSeconds"], 0.75)
        geos = [self.frame_geometry(manifest, i) for i in range(9)]
        sizes = {Image.open(self.root / "anim" / "pofu-blink" / f["files"]["1x"]).size for f in manifest["frames"]}
        self.assertEqual(len(sizes), 1, "every frame shares one canvas")
        self.assertLessEqual(max(g.baseline for g in geos) - min(g.baseline for g in geos), 1)
        self.assertLessEqual(max(g.base_x for g in geos) - min(g.base_x for g in geos), 1.0)
        self.assertEqual(manifest["paletteDriftWorst"], "ok")

    def test_cell_registration_keeps_the_hop(self):
        manifest = self.slice("--register", "cell")
        geos = [self.frame_geometry(manifest, i) for i in range(9)]
        expected = (self.offsets[4][1] - self.offsets[4][2]) - self.offsets[1][1]
        self.assertAlmostEqual(geos[4].baseline - geos[1].baseline, expected, delta=2)

    def test_point_height_exports_retina_scales(self):
        manifest = self.slice("--point-height", "60")
        files = manifest["frames"][0]["files"]
        self.assertEqual(set(files), {"2x", "3x"})
        img = Image.open(self.root / "anim" / "pofu-blink" / files["3x"])
        self.assertEqual(img.height, 180)


class PaletteCardTests(unittest.TestCase):
    def test_writes_card(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "card.png"
            self.assertEqual(pa.main(["palette-card", "--palettes", "character", "--out", str(out)]), 0)
            self.assertEqual(Image.open(out).width, 1024)


if __name__ == "__main__":
    unittest.main()
