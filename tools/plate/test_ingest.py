"""Tests for ingest.py on synthetic images only (no art files, no OpenCV)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import ingest  # noqa: E402


def disc(shape, cx, cy, r) -> np.ndarray:
    ys, xs = np.mgrid[: shape[0], : shape[1]]
    return ((xs - cx) ** 2 + (ys - cy) ** 2 <= r * r).astype(np.float64)


class IngestTests(unittest.TestCase):
    def test_upscale_failure_is_loud_not_silent(self):
        import tempfile
        import unittest.mock as mock

        from PIL import Image

        with tempfile.TemporaryDirectory() as d, mock.patch.dict("os.environ", {"POFU_UPSCALE_CACHE": d}):
            path = Path(d) / "p.png"
            Image.new("RGB", (8, 8)).save(path)
            import upscale
            with mock.patch.object(upscale, "blend_image", side_effect=FileNotFoundError("model")):
                with self.assertRaises(SystemExit) as cm:
                    ingest.upscaled_plate(path)
            self.assertIn("--no-upscale", str(cm.exception))

    def test_no_upscale_flag_ships_scale_one(self):
        import tempfile

        from PIL import Image

        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / "p.png"
            size = ingest.SIZE
            Image.new("RGB", size).save(path)
            ingest.SCALE_UP = False
            try:
                rgb, k = ingest.source_plate(path)
            finally:
                ingest.SCALE_UP = True
            self.assertEqual(k, 1)
            self.assertEqual(rgb.shape[:2], (size[1], size[0]))

    def test_plate_layers_ship_as_heic_q70_within_delta_e_2_5_of_the_source(self):
        """ADR-0024: a painterly RGBA fixture (soft gradients, grain, a feathered alpha edge) written
        by `write_imageset` is a .heic, far smaller than the PNG, and within ΔE2000 p95 2.5."""
        import json
        import tempfile
        import unittest.mock as mock

        from PIL import Image, ImageFilter

        import heic

        rng = np.random.default_rng(7)
        h, w = 768, 512
        ys, xs = np.mgrid[:h, :w]
        base = np.stack([90 + 80 * xs / w, 140 + 60 * ys / h, 70 + 50 * np.sin(xs / 60.0) ** 2], -1)
        grain = np.asarray(Image.fromarray(rng.integers(0, 256, (h, w), np.uint8)).filter(ImageFilter.GaussianBlur(2.0)), np.float64)
        rgb = np.clip(base + (grain[..., None] - 128) * 0.25, 0, 255)
        alpha = np.clip((1 - np.hypot(xs - w / 2, ys - h / 2) / 330) * 12, 0, 1) * 255
        src = Image.fromarray(np.dstack([rgb, alpha]).astype(np.uint8), "RGBA")
        with tempfile.TemporaryDirectory() as d, mock.patch.object(ingest, "ASSETS", Path(d)):
            out = ingest.write_imageset("world-test-plate-day-0", src)
            self.assertEqual(out.suffix, ".heic")
            contents = json.loads((out.parent / "Contents.json").read_text())
            self.assertEqual(contents["images"][0]["filename"], "world-test-plate-day-0.heic")
            png = Path(d) / "p.png"
            src.save(png, optimize=True)
            self.assertLess(out.stat().st_size, png.stat().st_size / 3)
            back = heic.open_image(out)
            self.assertEqual(back.size, src.size)
            self.assertLessEqual(heic.p95_vs_source(src, back), 2.5)

    def test_a_backdrop_stays_jpeg(self):
        import tempfile
        import unittest.mock as mock

        from PIL import Image

        with tempfile.TemporaryDirectory() as d, mock.patch.object(ingest, "ASSETS", Path(d)):
            out = ingest.write_imageset("world-test-backdrop-day-0", Image.new("RGB", (16, 16)), jpeg=True)
            self.assertEqual(out.suffix, ".jpg")

    def test_missing_pillow_heif_is_loud(self):
        import unittest.mock as mock

        with mock.patch.dict(sys.modules, {"pillow_heif": None}):
            with self.assertRaises(SystemExit) as cm:
                ingest.heic.require()
        self.assertIn("pillow-heif", str(cm.exception))

    def test_delta_e2000_anchors(self):
        import heic

        # Identical colours are 0; black against white is about 100.
        z = np.zeros((1, 1, 3))
        w = np.full((1, 1, 3), 255.0)
        self.assertEqual(float(heic.delta_e2000(z, z)[0, 0]), 0.0)
        self.assertAlmostEqual(float(heic.delta_e2000(z, w)[0, 0]), 100.0, delta=0.5)

    def test_percent_round_trip(self):
        pts = [[10.0, 20.0], [55.5, 70.25]]
        back = ingest.px_to_pct(ingest.pct_to_px(pts))
        for (a, b), (c, d) in zip(pts, back):
            self.assertAlmostEqual(a, c, places=1)
            self.assertAlmostEqual(b, d, places=1)

    def test_foot_y_is_the_lowest_point(self):
        self.assertEqual(ingest.foot_y([[0, 3], [5, 9], [2, 4]]), 9)

    def test_light_map_of_a_flat_image_is_that_colour(self):
        rgb = np.zeros((100, 160, 3))
        rgb[:] = (0.2, 0.6, 0.4)
        a = np.ones((100, 160))
        lit, dark = ingest.light_map(rgb, a, grid=(8, 5))
        self.assertEqual(len(lit), 5)
        self.assertEqual(len(lit[0]), 8)
        self.assertEqual({c for row in lit for c in row}, {"#339966"})
        self.assertEqual({c for row in dark for c in row}, {"#339966"})

    def test_light_map_fills_empty_cells_from_neighbours(self):
        rgb = np.ones((100, 160, 3)) * 0.5
        a = np.zeros((100, 160))
        a[:, :80] = 1  # only the left half is island
        lit, _ = ingest.light_map(rgb, a, grid=(8, 5))
        self.assertTrue(all(c == "#808080" for row in lit for c in row))

    def test_lit_is_brighter_than_shadow(self):
        rgb = np.zeros((40, 40, 3))
        rgb[:, :20] = 0.9
        rgb[:, 20:] = 0.3
        lit, dark = ingest.light_map(rgb, np.ones((40, 40)), grid=(1, 1))
        self.assertGreater(int(lit[0][0][1:3], 16), int(dark[0][0][1:3], 16))

    def test_occluder_cut_keeps_only_the_polygon(self):
        rgb = np.random.default_rng(1).uniform(size=(80, 120, 3))
        a = np.ones((80, 120))
        cut, (x0, y0, x1, y1) = ingest.occluder_cut(rgb, a, [[20, 20], [60, 20], [60, 50], [20, 50]])
        self.assertEqual(cut.shape[:2], (y1 - y0, x1 - x0))
        self.assertLessEqual(x0, 20)
        self.assertGreaterEqual(x1, 60)
        alpha = cut[..., 3]
        self.assertGreater(alpha[(35 - y0), (40 - x0)], 0.99)
        self.assertLess(alpha[0, 0], 0.01)

    def test_occluder_cut_stays_inside_the_matte(self):
        rgb = np.ones((80, 120, 3))
        a = np.zeros((80, 120))
        a[:, :40] = 1
        cut, (x0, y0, x1, _) = ingest.occluder_cut(rgb, a, [[20, 20], [60, 20], [60, 50], [20, 50]])
        self.assertLessEqual(x1, 40 + 4 + 1)
        self.assertLess(cut[35 - y0, -1, 3], 0.5)

    def test_fill_holes_fills_from_the_surroundings(self):
        rgb = np.ones((60, 60, 3)) * 0.7
        rgb[20:40, 20:40] = 0
        hole = np.zeros((60, 60), bool)
        hole[20:40, 20:40] = True
        out = ingest.fill_holes(rgb, hole)
        self.assertAlmostEqual(float(out[30, 30, 0]), 0.7, places=2)

    def test_feathered_plate_keeps_the_island_and_fades_the_border(self):
        rgb = np.ones((200, 300, 3)) * 0.5
        a = disc((200, 300), 150, 100, 60)
        img = np.asarray(ingest.feathered_plate(rgb, a, feather=20), np.float64) / 255
        self.assertAlmostEqual(img[100, 150, 3], 1.0, places=2)
        self.assertAlmostEqual(img[0, 0, 3], 0.0, places=2)
        self.assertAlmostEqual(img[100, 40, 3], 1.0, places=2)

    def test_backdrop_covers_its_box_and_is_the_plate_on_the_island(self):
        rng = np.random.default_rng(3)
        rgb = np.zeros((ingest.SIZE[1], ingest.SIZE[0], 3))
        rgb[:] = (0.6, 0.75, 0.95)
        rgb[int(ingest.SIZE[1] * 0.6):] = (0.95, 0.93, 0.9)
        a = disc(rgb.shape[:2], 768, 500, 300)
        rgb[a > 0.5] = rng.uniform(0.2, 0.4, 3)
        box = (-200, -800, 1736, 2200)
        out = ingest.backdrop(rgb, a, box, scale=0.1)
        self.assertEqual(out.shape[:2], (round(3000 * 0.1), round(1936 * 0.1)))
        # The island's centre, in the backdrop.
        y, x = round((500 + 800) * 0.1), round((768 + 200) * 0.1)
        self.assertLess(np.abs(out[y, x] - rgb[500, 768]).max(), 0.03)
        # Far above: sky, deeper than the plate's top.
        self.assertGreater(out[2, x, 2], out[2, x, 0])

    def test_home_frame_puts_the_island_at_its_widths(self):
        a = np.zeros((ingest.SIZE[1], ingest.SIZE[0]))
        a[100:900, 100:1400] = 1
        f = ingest.home_frame({"framing": {"homeWidths": 1.3, "homeCenterX": 0.5, "homeTopY": 100}}, a)
        self.assertAlmostEqual(f["w"], 1300 / 1.3, places=6)
        self.assertAlmostEqual(f["x0"] + f["w"] / 2, 750, places=6)
        self.assertAlmostEqual(f["h"] / f["w"], ingest.SCREEN[1] / ingest.SCREEN[0], places=6)

    def _data(self, **overrides):
        data = {
            "island": "test", "lights": ["day"], "stages": 1, "textureBytes": 1000,
            "objects": [{"id": "hut", "polygon": [[40, 40], [60, 40], [60, 60], [40, 60]], "occluder": False}],
            "walkable": [[30, 30], [70, 30], [70, 70], [30, 70]],
            "characters": {"pofu": [50, 50]},
        }
        data.update(overrides)
        return data

    def test_check_passes_a_clean_island(self):
        a = np.ones((100, 100))
        assets = {"world-test-plate-day-0", "world-test-island-day-0", "world-test-backdrop-day-0"}
        self.assertEqual(ingest.problems(self._data(), a, assets), [])

    def test_check_flags_problems(self):
        a = np.zeros((100, 100))
        a[20:80, 20:80] = 1
        data = self._data(
            objects=[{"id": "far", "polygon": [[2, 2], [10, 2], [10, 10]], "occluder": True}],
            characters={"pofu": [5, 95]},
            textureBytes=10_000_000,
        )
        found = ingest.problems(data, a, set(), tolerance=4)
        text = "\n".join(found)
        self.assertIn("far: the polygon leaves the matte", text)
        self.assertIn("pofu: stands off the walkable lawn", text)
        self.assertIn("textureBytes", text)
        self.assertIn("missing asset world-test-plate-day-0", text)
        self.assertIn("missing asset world-test-occ-far-day-0", text)

    def test_json_has_the_schema_keys(self):
        a = np.zeros((ingest.SIZE[1], ingest.SIZE[0]))
        a[200:800, 200:1300] = 1
        hand = {
            "plates": {"day": {"0": "x.png"}}, "minLevel": 10, "standIn": True,
            "objects": [{"id": "hut", "tap": True, "station": "teaStall", "label": "home.hut", "occluder": True,
                         "points": [[20, 30], [30, 30], [30, 40], [20, 40]]}],
            "walkable": [[20, 50], [80, 50], [80, 70], [20, 70]],
            "characters": {"pofu": [50, 60]}, "pofuWidth": 7,
            "framing": {"homeWidths": 1.15, "homeCenterX": 0.5, "homeTopY": 190},
        }
        grid = [["#ffffff"] * 32] * 20
        data = ingest.build_json("test", hand, {("day", 0): a}, {("day", 0): (grid, grid)})
        for key in ("island", "version", "minLevel", "plateSize", "stages", "lights", "islandBox", "backdropBox",
                    "objects", "walkable", "characters", "pofuWidth", "framing", "lightDirection", "lightMap",
                    "shadowMap", "textureBytes", "residentBoost"):
            self.assertIn(key, data)
        hut = data["objects"][0]
        self.assertEqual(hut["footY"], max(p[1] for p in hut["polygon"]))
        self.assertEqual(hut["station"], "teaStall")
        self.assertEqual(len(hut["box"]), 4)
        self.assertEqual(len(data["lightMap"]["day"][0]), 20)

    def test_present_follows_the_day_stages(self):
        windmill = {"id": "windmill", "stages": [0, 1, 2]}
        self.assertTrue(ingest.present(windmill, "day", 2))
        self.assertFalse(ingest.present(windmill, "day", 3))
        self.assertTrue(ingest.present({"id": "door"}, "day", 8))

    def test_present_honours_stages_for_every_light(self):
        """A night stage is the day stage's island level: Home's night IL2 to IL9 paints that
        level's buildings, so `stages` applies to every light, and `check` agrees."""
        windmill = {"id": "windmill", "stages": [0, 1, 2]}
        for light in ("day", "golden", "night", "rain"):
            self.assertTrue(ingest.present(windmill, light, 2))
            self.assertFalse(ingest.present(windmill, light, 3))
        obj = {"id": "windmill", "polygon": [[40, 40], [60, 40], [60, 60]], "occluder": True, "stages": [0]}
        data = self._data(objects=[obj], stages=2, lightStages={"night": 2}, lights=["night"])
        assets = {f"world-test-{k}-night-{s}" for k in ("plate", "island", "backdrop") for s in (0, 1)} | {"world-test-occ-windmill-night-0"}
        self.assertEqual(ingest.problems(data, np.ones((100, 100)), assets), [])
        self.assertIn("missing asset world-test-occ-windmill-night-0",
                      "\n".join(ingest.problems(data, np.ones((100, 100)), assets - {"world-test-occ-windmill-night-0"})))

    def test_texture_bytes_leave_out_the_sky_sets_layers(self):
        import tempfile
        import unittest.mock as mock

        from PIL import Image

        hand = {"plates": {"day": {"0": "a.png"}}}
        with tempfile.TemporaryDirectory() as d:
            for name, size in (("world-t-plate-day-0", (10, 10)), ("world-t-occ-mill-day-0", (4, 5)), ("world-t-sky-far-day-0", (50, 50))):
                folder = Path(d) / f"{name}.imageset"
                folder.mkdir()
                Image.new("RGB", size).save(folder / f"{name}.png")
            with mock.patch.object(ingest, "ASSETS", Path(d)):
                self.assertEqual(ingest.texture_bytes("t", hand), 10 * 10 + 4 * 5)

    def test_matte_writes_only_the_named_state(self):
        import tempfile
        import unittest.mock as mock

        from PIL import Image

        size = ingest.SIZE
        self.addCleanup(setattr, ingest, "SIZE", size)  # load_hand sets the module's plate size
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / "t").mkdir()
            hand = {"size": [20, 30], "plates": {"day": {"0": "a.png", "9": "b.png"}, "night": {"9": "c.png"}},
                    "trace": [[10, 10]], "objects": []}
            (root / "t" / "objects.json").write_text(__import__("json").dumps(hand))
            with mock.patch.object(ingest, "PLATES", root), mock.patch.object(ingest, "REPO", root), \
                    mock.patch.object(ingest, "load_rgb", return_value=np.zeros((30, 20, 3))), \
                    mock.patch.object(ingest, "matte", return_value=np.ones((30, 20))):
                ingest.cmd_matte("t", "day:9")
            self.assertEqual(sorted(p.name for p in (root / "t").glob("matte-*.png")), ["matte-day-9.png"])
            self.assertEqual(Image.open(root / "t" / "matte-day-9.png").size, (20, 30))

    def test_check_wants_assets_per_painted_state_only(self):
        a = np.ones((100, 100))
        obj = {"id": "mill", "polygon": [[40, 40], [60, 40], [60, 60]], "occluder": True, "stages": [0]}
        data = self._data(objects=[obj], stages=2, lightStages={"day": 2}, lights=["day"])
        assets = {f"world-test-{k}-day-{s}" for k in ("plate", "island", "backdrop") for s in (0, 1)} | {"world-test-occ-mill-day-0"}
        self.assertEqual(ingest.problems(data, a, assets), [])  # no occluder asset for the stage that does not paint it
        self.assertIn("missing asset world-test-occ-mill-day-0",
                      "\n".join(ingest.problems(data, a, assets - {"world-test-occ-mill-day-0"})))


class HarmonyTests(unittest.TestCase):
    def setUp(self):
        self._size = ingest.SIZE

    def tearDown(self):
        ingest.SIZE = self._size

    def _plate(self, lawn, w=200, h=300):
        return np.full((h, w, 3), lawn, np.float64)

    def _hand(self, w=200, h=300):
        ingest.SIZE = (w, h)
        return {"walkable": [[10, 40], [90, 40], [90, 90], [10, 90]], "pofuWidth": 10,
                "characters": {"pofu": [50, 60], "mochi": [30, 60], "findik": [70, 60]}}

    def test_the_reference_state_is_neutral(self):
        h = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), self._hand(), None)
        self.assertEqual(h["tint"], [1.0, 1.0, 1.0])
        self.assertEqual(h["contact"], 1.0)

    def test_a_darker_lawn_darkens_the_tint_and_a_brighter_one_never_brightens_it(self):
        hand = self._hand()
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        dark = ingest.harmony_state(self._plate([0.2, 0.35, 0.3]), hand, ref)
        self.assertLess(dark["tint"][0], 0.9)
        self.assertLess(dark["tint"][1], 0.9)
        self.assertGreater(dark["tint"][2], dark["tint"][0])  # blue did not fall: half of the cast stays
        self.assertLessEqual(dark["tint"][2], 1.0)
        bright = ingest.harmony_state(self._plate([0.6, 0.9, 0.6]), hand, ref)
        self.assertEqual(bright["tint"], [1.0, 1.0, 1.0])

    def test_tint_and_contact_stay_in_their_ranges(self):
        hand = self._hand()
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        black = ingest.harmony_state(self._plate([0.0, 0.0, 0.0]), hand, ref)
        self.assertTrue(all(0.25 <= v <= 1 for v in black["tint"]))
        self.assertTrue(0.5 <= black["contact"] <= 1.2)

    def test_golden_keeps_all_of_the_cast_and_day_half_of_it(self):
        hand = self._hand()
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        lawn = self._plate([0.2, 0.35, 0.3])
        day = ingest.harmony_state(lawn, hand, ref, "day")["tint"]
        golden = ingest.harmony_state(lawn, hand, ref, "golden")["tint"]
        self.assertGreater(golden[2] - golden[0], day[2] - day[0])  # the cast is the light: all of it

    def test_the_golden_and_night_states_carry_a_key_light_and_every_state_a_bounce(self):
        hand = {**self._hand(), "lamps": [[20, 80], [80, 80]]}
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        self.assertGreater(ref["bounce"], 0)
        day = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, ref, "day")
        self.assertNotIn("rim", day)
        golden = ingest.harmony_state(self._plate([0.5, 0.5, 0.4]), hand, ref, "golden")
        self.assertGreater(golden["rim"], 0)
        self.assertEqual(len(golden["key"]), 3)
        self.assertNotIn("pool", golden)  # no lamps lit at golden hour
        night = ingest.harmony_state(self._plate([0.5, 0.5, 0.4]), hand, ref, "night")
        self.assertGreater(night["pool"], 0)
        self.assertEqual(set(night["scale"]), {"pofu", "mochi", "findik"})

    def test_pool_starts_at_the_lamp_level(self):
        """The lamps are lit from `lampsFromLevel` (Home: 6): a night plate below it has no lamp
        pool under a character; at and above it does, and a hand without the key keeps the pool."""
        hand = {**self._hand(), "lamps": [[20, 80], [80, 80]], "stageLevels": [10, 9, 6, 5, 2], "lampsFromLevel": 6}
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        night = lambda h, stage: ingest.harmony_state(self._plate([0.5, 0.5, 0.4]), h, ref, "night", stage)
        self.assertGreater(night(hand, 2)["pool"], 0)  # level 6
        self.assertNotIn("pool", night(hand, 3))  # level 5
        self.assertNotIn("pool", night(hand, 4))  # level 2
        self.assertGreater(night({k: v for k, v in hand.items() if k != "lampsFromLevel"}, 4)["pool"], 0)
        self.assertGreater(night(hand, 3)["rim"], 0)  # the key light stays

    def test_a_scale_trim_from_the_app_frame_multiplies_one_states_character_scale(self):
        import unittest.mock as mock

        hand = {**self._hand(), "plates": {"day": {"0": "d.png"}, "night": {"0": "n.png"}}}
        lawns = {"d.png": self._plate([0.4, 0.7, 0.3]), "n.png": self._plate([0.45, 0.6, 0.45])}
        with mock.patch.object(ingest, "load_rgb", side_effect=lambda path: lawns[Path(path).name]):
            plain = ingest.harmony_all(hand, {})["night"][0]["scale"]["mochi"]
            hand["characterLight"] = {"scaleTrim": {"night:0": {"mochi": 0.5}}, "saturationTrim": {"night:0": 0.8}}
            trimmed = ingest.harmony_all(hand, {})["night"][0]
            untrimmed = ingest.harmony_all({**hand, "characterLight": {}}, {})["night"][0]
        self.assertAlmostEqual(trimmed["scale"]["mochi"], round(plain * 0.5, 3), places=3)
        self.assertEqual(trimmed["saturation"], 0.8)
        self.assertNotIn("saturation", untrimmed)

    def test_cast_from_gives_every_state_of_a_light_the_root_states_colour_at_its_own_lightness(self):
        import unittest.mock as mock

        hand = {**self._hand(), "lamps": [[20, 80], [80, 80]],
                "plates": {"day": {"0": "d.png"}, "night": {"0": "n0.png", "1": "n1.png"}}}
        lawns = {"d.png": self._plate([0.4, 0.7, 0.3]), "n0.png": self._plate([0.32, 0.4, 0.5]),
                 "n1.png": self._plate([0.36, 0.30, 0.12])}  # darker, and a warm cast where the root's is blue

        def tints(hand):
            with mock.patch.object(ingest, "load_rgb", side_effect=lambda path: lawns[Path(path).name]):
                return ingest.harmony_all(hand, {})["night"]

        own = tints(hand)
        shared = tints({**hand, "characterLight": {"castFrom": {"night": 0}}})
        self.assertEqual(shared[0]["tint"], own[0]["tint"])  # the root is itself
        self.assertGreater(own[1]["tint"][0], own[1]["tint"][2])  # its own cast is warm ...
        self.assertGreater(shared[1]["tint"][2], shared[1]["tint"][0])  # ... the shared one is the root's blue
        self.assertEqual(shared[1]["key"], shared[0]["key"])
        self.assertLess(sum(shared[1]["tint"]), sum(shared[0]["tint"]))  # at its own, darker, lightness

    def test_at_night_a_sprites_top_stays_under_the_brightest_stone_around_it(self):
        hand = self._hand()
        ref = ingest.harmony_state(self._plate([0.4, 0.7, 0.3]), hand, None)
        lawn = self._plate([0.45, 0.6, 0.45])
        night = ingest.harmony_state(lawn, hand, ref, "night")
        stone = min(ingest.stone_levels(lawn, hand, ingest.poly_mask(lawn.shape[:2], ingest.pct_to_px(hand["walkable"]))).values())
        top = ingest.lstar_to_srgb(ingest.SPRITE_L) * float(np.mean(night["tint"]))
        self.assertLessEqual(top, ingest.lstar_to_srgb(stone - ingest.STONE_MARGIN["night"]) + 0.01)
        self.assertTrue(all(0.25 <= v <= 1 for v in night["tint"]))
        self.assertTrue(all(0 < v <= 1 for v in night["scale"].values()))

    def test_a_sparse_light_pads_its_arrays_and_lists_what_it_paints(self):
        hand = {"plates": {"day": {"0": "a", "1": "b"}, "night": {"1": "c"}}}
        self.assertTrue(ingest.is_sparse(hand))
        self.assertEqual(ingest.painted_stages(hand), {"day": [0, 1], "night": [1]})
        self.assertEqual(ingest.stage_count(hand, "night"), 2)
        self.assertFalse(ingest.is_sparse({"plates": {"day": {"0": "a", "1": "b"}, "golden": {"0": "c"}}}))

    def test_a_calm_backdrop_runs_the_sea_on_below_the_plate_without_repeating_it(self):
        rgb = np.zeros((ingest.SIZE[1], ingest.SIZE[0], 3))
        rgb[:] = (0.6, 0.75, 0.95)
        rgb[int(ingest.SIZE[1] * 0.85):] = (0.93, 0.92, 0.97)
        a = np.zeros(rgb.shape[:2])
        a[300:800, 300:1200] = 1.0
        box = (-200, -800, 1736, 2200)
        out = ingest.backdrop(rgb, a, box, scale=0.1, calm=True)
        self.assertEqual(out.shape[:2], (300, 194))
        below = out[int((1024 + 800) * 0.1) + 20:]
        # No puffs: the rows below the plate vary slowly (a repeated cloud band would not).
        self.assertLess(np.abs(np.diff(below, axis=0)).max(), 0.02)
        self.assertLess(below.std(axis=1).max(), 0.05)

    def test_saturation_follows_a_paler_lawn_and_is_never_asked_for_without_the_flag(self):
        ingest.SIZE = (200, 300)
        hand = {"walkable": [[10, 40], [90, 40], [90, 90], [10, 90]], "pofuWidth": 10, "characters": {"damla": [50, 60]},
                "characterLight": {"saturate": True}}
        lush = np.full((300, 200, 3), (0.4, 0.7, 0.3))
        pale = np.full((300, 200, 3), (0.8, 0.75, 0.7))
        ref = ingest.harmony_state(lush, hand, None)
        self.assertLess(ingest.harmony_state(pale, hand, ref)["saturation"], 0.8)
        self.assertGreaterEqual(ingest.harmony_state(pale, hand, ref)["saturation"], ingest.SATURATION_FLOOR)
        self.assertNotIn("saturation", ingest.harmony_state(lush, hand, ref))
        plain = {k: v for k, v in hand.items() if k != "characterLight"}
        self.assertNotIn("saturation", ingest.harmony_state(pale, plain, ref))


if __name__ == "__main__":
    unittest.main()
