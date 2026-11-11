"""Tests for skyset_export.py / skyset_render.py on the shipped home sky sets: the files, the budget,
the motion formulas the Swift runtime shares, frame zero against the painting, and the wrap."""
from __future__ import annotations

import json
import math
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import screen_check as sc  # noqa: E402
import skyset_export as ex  # noqa: E402
import skyset_render as rd  # noqa: E402

LIGHTS = ("day", "golden", "night")
DATA = json.loads((ex.JSON_DIR / "skyset-home.json").read_text())


class FileTests(unittest.TestCase):
    def test_every_layer_is_a_heic_imageset_and_the_budget_holds(self):
        for light in LIGHTS:
            spec = DATA["lights"][light]
            pixels = 0
            for layer in spec["layers"]:
                f = ex.ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}.heic"
                self.assertTrue(f.exists(), layer["asset"])
                with heic.open_image(f) as im:
                    pixels += im.width * im.height
            self.assertEqual(pixels, spec["pixels"], light)
            self.assertEqual(ex.state_bytes("home", light, pixels), spec["textureBytes"], light)
            self.assertLessEqual(spec["textureBytes"], ex.BUDGET, light)

    def test_the_island_is_copied_untouched_and_last(self):
        for light in LIGHTS:
            layers = DATA["lights"][light]["layers"]
            self.assertEqual(layers[0]["id"], "sky")
            self.assertEqual(layers[-1]["id"], "island")
            src = ex.PLATES / "home" / "sky" / light / "island.heic"
            dst = ex.ASSETS / f"{layers[-1]['asset']}.imageset" / f"{layers[-1]['asset']}.heic"
            self.assertEqual(src.read_bytes(), dst.read_bytes())
            self.assertFalse({"drift", "bob", "twinkle"} & set(layers[-1]), "the island never moves")

    def test_only_night_has_stars_and_they_are_the_skys_own_pixels(self):
        for light in ("day", "golden"):
            self.assertFalse([l for l in DATA["lights"][light]["layers"] if l["role"] == "stars"])
        stars = [l for l in DATA["lights"]["night"]["layers"] if l["role"] == "stars"]
        self.assertEqual(len(stars), ex.STAR_GROUPS)
        sky = np.asarray(heic.open_image(ex.PLATES / "home" / "sky" / "night" / "sky.heic").convert("RGB"), np.float32) / 255
        total = np.zeros(sky.shape[:2], np.float32)
        for s in stars:
            f = ex.ASSETS / f"{s['asset']}.imageset" / f"{s['asset']}.heic"
            total[: ex.STAR_ROWS] += (np.asarray(heic.open_image(f).convert("RGB"), np.float32) / 255).max(-1)
        # nothing is added below the star rows, and each lit pixel is a pixel the sky layer already has lit
        self.assertEqual(float(total[ex.STAR_ROWS:].sum()), 0.0)
        self.assertGreater(int((total > 0.04).sum()), 20)


class MotionTests(unittest.TestCase):
    def test_the_constants_are_the_stated_ones(self):
        layers = {l["id"]: l for l in DATA["lights"]["day"]["layers"]}
        self.assertEqual([layers[i]["drift"] for i in ("far", "mid", "sea")], [4, 9, 14])
        for i in ("far", "mid", "sea"):
            self.assertEqual((layers[i]["bob"]["amp"], layers[i]["bob"]["period"]), (3, 8))
        for i in ("isle_falls", "isle_house", "isle_dome", "isle_crystal"):
            self.assertEqual(layers[i]["bob"]["amp"], 2)
            self.assertNotIn("drift", layers[i])

    def test_time_zero_is_the_painting(self):
        for light in LIGHTS:
            for l in DATA["lights"][light]["layers"]:
                self.assertEqual(rd.bob_y(l.get("bob"), 0), 0)
                if "twinkle" in l:
                    self.assertEqual(rd.twinkle(l["twinkle"], 0), 0)

    def test_bob_is_bounded_and_twinkle_only_brightens(self):
        bob = {"amp": 3, "period": 8, "sign": 1}
        self.assertLessEqual(max(abs(rd.bob_y(bob, i * 0.05)) for i in range(2000)), 3 + 1e-9)
        tw = {"peak": 0.9, "period": 4}
        vals = [rd.twinkle(tw, i * 0.05) for i in range(400)]
        self.assertTrue(min(vals) >= 0 and max(vals) <= 0.9 + 1e-9)

    def test_the_whale_wraps_only_off_screen(self):
        width, screen, rest = 500.0, 1206.0, 330.0
        last = rest
        wraps = 0
        for i in range(1, 60000):
            left = rd.glide_left(rest, width, 5, i * 0.1, screen)
            if left < last - 1:
                wraps += 1
                self.assertGreaterEqual(last, screen)          # gone past the right edge
                self.assertLessEqual(left + width, 0)           # back in from beyond the left
            else:
                self.assertLessEqual(left - last, 0.5 + 1e-6)
            last = left
        self.assertGreaterEqual(wraps, 1)

    def test_a_tiles_seam_is_as_smooth_as_its_own_columns(self):
        for light in LIGHTS:
            for l in DATA["lights"][light]["layers"]:
                if l["role"] != "tile":
                    continue
                f = ex.ASSETS / f"{l['asset']}.imageset" / f"{l['asset']}.heic"
                a = np.asarray(heic.open_image(f).convert("RGBA"), np.float32) / 255
                seam = np.abs(a[:, 0] - a[:, -1]).mean()
                typical = np.abs(np.diff(a, axis=1)).mean()
                self.assertLess(seam, 4 * typical + 0.01, f"{light} {l['id']}")


class RenderTests(unittest.TestCase):
    def test_frame_zero_is_the_painting(self):
        for light in LIGHTS:
            s = rd.load("home", light)
            fr = sc.framing(s["manifest"])
            man = json.loads((sc.PLATES / "home" / "sky" / light / "manifest.json").read_text())
            plate = np.asarray(heic.open_image(sc.ROOT / man["source"]["plate"]).convert("RGB"), np.float32)
            plate[:2] = plate[2]
            plate[:, :2] = plate[:, 2:3]
            plate[:, -2:] = plate[:, -3:-2]
            master = sc.master_frame({"manifest": man}, plate, fr)
            cover = np.zeros(master.shape[:2], bool)
            c = 1 / fr["k"]
            cover[max(int(round(-fr["y0"] * c)), 0): min(int(round((man["size"][1] - fr["y0"]) * c)), master.shape[0])] = True
            r = sc.check_identity(rd.render(s, 0, fr, snap=True), master, cover, sc.THRESHOLDS["identity"])
            self.assertTrue(r["ok"], f"{light}: {r}")

    def test_the_island_never_moves_with_the_sky(self):
        s = rd.load("home", "day")
        fr = sc.framing(s["manifest"])
        a = rd.render(s, 0, fr)
        b = rd.render(s, 37.3, fr)
        alpha = sc.compose(sc.load_set(sc.PLATES / "home" / "sky" / "day"), 0, fr)["island_alpha"]
        import cv2
        solid = cv2.erode((alpha > 0.99).astype(np.uint8), np.ones((9, 9), np.uint8)) > 0
        self.assertGreater(int(solid.sum()), 200_000)
        # whatever the sky did, a pixel the island covers is unchanged
        self.assertLess(float(np.abs(a - b)[solid].max()), 0.5)
        # and the sky does move
        sky = alpha < 0.01
        self.assertGreater(float(np.abs(a - b)[sky].mean()), 0.25)

    def test_a_tile_returns_after_its_width_and_wraps_without_a_jump(self):
        s = rd.load("home", "day")
        fr = sc.framing(s["manifest"])
        sea = next(l for l in s["layers"] if l["id"] == "sea")
        img, _, _ = rd._scaled(sea, rd.geometry(s["manifest"], fr), tuple(s["master"]))
        tw = img.shape[1]
        self.assertTrue(np.allclose(rd._shift_tile(img, 0.0), rd._shift_tile(img, float(tw))))
        # a sub-pixel step moves the picture by under a grey level a pixel
        a, b = rd._shift_tile(img, 100.0), rd._shift_tile(img, 100.14)
        self.assertLess(float(np.abs(a - b).mean()), 0.01)

    def test_vivid_raises_chroma_nine_percent_on_sky_and_clouds_only(self):
        base = rd.load("home", "day")
        vivid = rd.load("home", "day", 1.09)
        import cv2
        for a, b in zip(base["layers"], vivid["layers"]):
            if a["role"] in rd.CHROMA_LAYERS:
                m = a["rgba"][..., 3] > 0.9
                if not m.any():
                    continue
                la = cv2.cvtColor(np.ascontiguousarray(a["rgba"][..., :3]), cv2.COLOR_RGB2Lab)[..., 1:][m]
                lb = cv2.cvtColor(np.ascontiguousarray(b["rgba"][..., :3]), cv2.COLOR_RGB2Lab)[..., 1:][m]
                ca, cb = np.hypot(*la.T).mean(), np.hypot(*lb.T).mean()
                self.assertGreater(cb / ca, 1.06, a["id"])
                self.assertLess(cb / ca, 1.10, a["id"])
            else:
                self.assertTrue(np.array_equal(a["rgba"], b["rgba"]), a["id"])


class SkyCheckTests(unittest.TestCase):
    """The checks that would have caught the first version's mirror, stripes and ghost stars."""

    def test_mirror_is_caught_and_a_plain_texture_is_not(self):
        rng = np.random.default_rng(0)
        tex = rng.random((600, 400, 3)).astype(np.float32) * 255
        th = sc.SKY_THRESHOLDS["mirror"]
        plain = sc.check_mirror(tex, 300, th)
        self.assertTrue(plain["ok"], plain)
        mirrored = tex.copy()
        mirrored[300:] = tex[:300][::-1]
        bad = sc.check_mirror(mirrored, 300, th)
        self.assertFalse(bad["ok"], bad)
        self.assertLess(bad["ratio"], 0.1)
        self.assertTrue(sc.check_mirror(tex[:310], 300, th)["ok"])         # no rows past the plate: nothing to check

    def test_stripes_and_a_box_edge_are_caught_and_a_smooth_gradient_is_not(self):
        h, w = 400, 300
        grad = np.repeat(np.linspace(0.2, 0.7, h)[:, None, None], w, 1) * np.array([0.6, 0.8, 1.0]) * 255
        th = sc.SKY_THRESHOLDS["sky_edges"]
        self.assertTrue(sc.check_sky_edges(grad.astype(np.float32), th)["ok"])
        box = grad.copy()
        box[:150, 200:] *= 1.08                                            # a rectangle edge
        self.assertFalse(sc.check_sky_edges(box.astype(np.float32), th)["ok"])
        stripes = grad.copy()
        for x in range(0, w, 40):
            stripes[:, x: x + 8] *= 1.05                                   # vertical bands
        self.assertFalse(sc.check_sky_edges(stripes.astype(np.float32), th)["ok"])

    def test_a_doubled_star_is_caught(self):
        below = np.full((200, 200, 3), 0.1, np.float32)
        below[50:53, 50:53] = 0.9                                          # a star
        th = sc.SKY_THRESHOLDS["ghosts"]
        self.assertTrue(sc.check_ghosts(below * 255, below * 255, th)["ok"])
        above = below.copy()
        above[56:59, 62:65] = 0.5                                          # a ghost beside it
        r = sc.check_ghosts(below * 255, above * 255, th)
        self.assertEqual(r["ghost_points"], 1)
        far = below.copy()
        far[150:160, 20:120] = 0.6                                         # a cloud far from any star
        self.assertTrue(sc.check_ghosts(below * 255, far * 255, th)["ok"])

    def test_the_shipped_sets_pass_all_three(self):
        for light in LIGHTS:
            r = sc.run_sky("home", light)
            self.assertTrue(r["ok"], f"{light}: {r}")

    def test_no_star_residue_is_left_in_the_far_and_mid_layers(self):
        spec = DATA["lights"]["night"]
        hand = json.loads((ex.PLATES / "home" / "sky" / "sky.json").read_text())
        sky0 = np.asarray(heic.open_image(ex.PLATES / "home" / "sky" / "night" / "sky.heic").convert("RGB"), np.float32) / 255
        centres = ex.star_centres(sky0, hand, "night")
        self.assertGreater(len(centres), 10)
        for lid in ("far", "mid"):
            layer = next(l for l in spec["layers"] if l["id"] == lid)
            f = ex.ASSETS / f"{layer['asset']}.imageset" / f"{layer['asset']}.heic"
            a = np.asarray(heic.open_image(f).convert("RGBA"), np.float32)[..., 3] / 255
            sx = a.shape[1] / layer["size"][0]
            for cx, cy in centres:
                x, y = int((cx - layer["pos"][0]) * sx), int((cy - layer["pos"][1]) * sx)
                if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
                    self.assertLess(float(a[max(y - 4, 0): y + 5, max(x - 4, 0): x + 5].max()), 0.05, f"{lid} at {cx:.0f},{cy:.0f}")

    def test_the_moon_is_a_sprite_with_a_soft_radial_edge(self):
        moon = next(l for l in DATA["lights"]["night"]["layers"] if l["id"] == "moon")
        f = ex.ASSETS / f"{moon['asset']}.imageset" / f"{moon['asset']}.heic"
        a = np.asarray(heic.open_image(f).convert("RGBA"), np.float32)[..., 3] / 255
        for edge in (a[0], a[-1], a[:, 0], a[:, -1]):
            self.assertLess(float(edge.max()), 0.02, "no rectangle: the alpha is zero at the sprite's border")
        self.assertGreater(float(a[a.shape[0] // 2, a.shape[1] // 2]), 0.99)

    def test_the_sea_below_the_plate_is_a_continuation_not_a_reflection(self):
        sea = next(l for l in DATA["lights"]["day"]["layers"] if l["id"] == "sea")
        self.assertEqual(sea["size"][1], 1728 + ex.SEA_PAD)


class CiFrameTests(unittest.TestCase):
    def test_the_same_frame_passes_and_a_changed_one_fails(self):
        s = rd.load("home", "day")
        fr = sc.framing(s["manifest"])
        f = rd.render(s, 0, fr, snap=True)
        ok = sc.check_ci("home", "day", f, f)
        self.assertTrue(ok["ok"], ok)
        shifted = np.roll(f, 40, axis=1)
        bad = sc.check_ci("home", "day", shifted, f)
        self.assertFalse(bad["identity"]["ok"])
        self.assertFalse(sc.check_ci("home", "day", f[:-1], f)["ok"])


if __name__ == "__main__":
    unittest.main()
