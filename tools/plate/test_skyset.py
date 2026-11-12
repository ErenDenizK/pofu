"""Tests for skyset_export.py / skyset_render.py on the shipped home sky sets: the files, the budget,
the motion formulas the Swift runtime shares, frame zero against the painting, and the wrap."""
from __future__ import annotations

import json
import math
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import heic  # noqa: E402
import screen_check as sc  # noqa: E402
import skyset_detail as sd  # noqa: E402
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
            self.assertEqual(ex.state_bytes("home", light, pixels + spec.get("detailPixels", 0)), spec["textureBytes"], light)
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


def _png(name: str) -> np.ndarray:
    return np.asarray(Image.open(ex.ASSETS / f"{name}.imageset" / f"{name}.png").convert("RGBA"), np.float32) / 255


def _details(light: str):
    for layer in DATA["lights"][light]["layers"]:
        for d in layer.get("details", []):
            yield layer, d


class CaglayanSkyTests(unittest.TestCase):
    """Çağlayan's day: five story stages over one portrait sky, the landscape plates placed on it by `plateFrame`."""
    DATA = json.loads((ex.JSON_DIR / "skyset-caglayan.json").read_text())
    HAND = json.loads((ex.PLATES / "caglayan" / "sky" / "sky.json").read_text())
    STAGES = range(5)

    def state(self, n):
        return self.DATA["lights"][f"day-{n}"]

    def test_every_stage_has_a_state_that_differs_only_in_its_island_layer(self):
        base = self.state(4)["layers"]
        assets = set()
        for n in self.STAGES:
            layers = self.state(n)["layers"]
            self.assertEqual(layers[0]["role"], "sky")
            self.assertEqual(layers[-1]["role"], "island")
            self.assertEqual([l["asset"] for l in layers[:-1]], [l["asset"] for l in base[:-1]])
            assets.add(layers[-1]["asset"])
            src = ex.PLATES / "caglayan" / "sky" / "day" / ("island.heic" if n == 4 else f"island-s{n}.heic")
            dst = ex.ASSETS / f"{layers[-1]['asset']}.imageset" / f"{layers[-1]['asset']}.heic"
            self.assertEqual(src.read_bytes(), dst.read_bytes(), f"stage {n}'s island is its plate's, copied untouched")
            self.assertFalse({"drift", "bob", "twinkle"} & set(layers[-1]), "the island never moves")
        self.assertEqual(len(assets), 5)

    def test_the_budget_holds_in_every_stage(self):
        for n in self.STAGES:
            spec = self.state(n)
            self.assertEqual(ex.state_bytes("caglayan", "day", spec["pixels"] + spec.get("detailPixels", 0), n), spec["textureBytes"])
            self.assertLessEqual(spec["textureBytes"], ex.BUDGET, f"stage {n}")

    def test_the_plates_place_on_the_master_is_the_one_in_the_hand_data(self):
        self.assertEqual(self.DATA["plateFrame"], {"scale": self.HAND["matteFrame"]["scale"], "offset": self.HAND["matteFrame"]["offset"]})
        objects = json.loads((ex.PLATES / "caglayan" / "objects.json").read_text())["portraitFrame"]
        # the same frame twice: the portrait master at 1024 x 1536 and the x2 working size
        self.assertAlmostEqual(self.HAND["matteFrame"]["scale"], objects["scale"] * 2, places=3)
        self.assertEqual(self.HAND["matteFrame"]["offset"], [objects["offset"][0] * 2, objects["offset"][1] * 2])

    def test_the_motion_is_homes(self):
        layers = {l["id"]: l for l in self.state(4)["layers"]}
        home = {l["id"]: l for l in DATA["lights"]["day"]["layers"]}
        for i in ("far", "mid", "sea"):
            self.assertEqual((layers[i]["drift"], layers[i]["bob"]), (home[i]["drift"], home[i]["bob"]), i)
        for i in ("isle_dome", "isle_crystal"):                       # the same isles by name: the same bob
            self.assertEqual(layers[i]["bob"], home[i]["bob"], i)
        for l in self.state(4)["layers"]:
            self.assertEqual(rd.bob_y(l.get("bob"), 0), 0, "time zero is the painting")

    def test_the_drift_tiles_carry_a_bridge_and_wrap_at_their_own_width(self):
        master_w = self.DATA["master"][0]
        for l in self.state(4)["layers"]:
            if l["role"] != "tile":
                continue
            self.assertEqual(l["size"][0], master_w + self.HAND["tileBridge"], l["id"])
            self.assertEqual(l["tileWidth"], l["size"][0], l["id"])

    def test_the_picture_runs_past_the_master_as_far_as_the_screen_shows(self):
        s = rd.load("caglayan", "day")
        fr = sc.framing(s["manifest"])
        over_top = -fr["y0"]
        over_bottom = fr["y0"] + sc.SCREEN[1] * fr["k"] - self.DATA["master"][1]
        layers = {l["id"]: l for l in self.state(4)["layers"]}
        self.assertGreater(over_top, 0)
        self.assertGreater(over_bottom, 0)
        self.assertLessEqual(layers["sky"]["pos"][1], -over_top, "the gradient reaches the top of the screen")
        self.assertGreaterEqual(layers["far"]["pos"][1], 0, "no cloud is drawn above the master: the far layer is the painting's own")
        for lid in ("sky", "sea"):
            self.assertGreaterEqual(layers[lid]["pos"][1] + layers[lid]["size"][1], self.DATA["master"][1] + over_bottom, f"{lid} reaches the bottom")
        self.assertLessEqual(layers["sky"]["pos"][0], -(fr["x0"] * -1 if fr["x0"] < 0 else 0))

    def test_no_layer_carries_speckle_and_the_sea_has_no_straight_line(self):
        s = rd.load("caglayan", "day")
        cloud = {l["id"]: l["rgba"] for l in s["layers"] if l["role"] in ("tile", "sprite")}
        self.assertEqual(sc.check_speckle(cloud, sc.SKY_THRESHOLDS["speckle"])["total"], 0)
        fr = sc.framing(s["manifest"])
        sea_top = int(round((s["manifest"]["islandBox"][3] - fr["y0"]) / fr["k"])) + 40
        for t in (0, 3):
            r = sc.check_horizontal_line(rd.render(s, t, fr), (sea_top, sc.SCREEN[1] - 4), sc.SKY_THRESHOLDS["sea_line"])
            self.assertTrue(r["ok"], r)

    def test_the_sky_extension_is_continuous_at_the_masters_top_edge(self):
        sky = np.asarray(heic.open_image(ex.ASSETS / "world-caglayan-sky-sky-day-0.imageset" / "world-caglayan-sky-sky-day-0.heic").convert("RGB"), np.float32) / 255
        layer = next(l for l in self.state(4)["layers"] if l["id"] == "sky")
        top_rows = round(-layer["pos"][1] / 8)
        edge = sky[top_rows: top_rows + 2].mean((0, 1))
        above = sky[top_rows - 2: top_rows].mean((0, 1))
        self.assertLess(float(np.abs(edge - above).max()), 0.02, "no step at the join")
        # it deepens toward the zenith and never runs off
        self.assertLess(float(sky[0].mean(0)[0]), float(edge[0]) + 1e-3)
        self.assertGreater(float(sky[0].mean()), 0.2)


class ExtensionTests(unittest.TestCase):
    def test_extend_sky_up_continues_value_and_slope_and_settles(self):
        h, w = 60, 40
        t = np.linspace(0.3, 0.6, h)[:, None, None]
        sky = np.repeat(t, w, 1).repeat(3, 2).astype(np.float32)
        sky[..., 2] = 0.95
        out = ex.extend_sky_up(sky, 100)
        self.assertEqual(out.shape, (h + 100, w, 3))
        np.testing.assert_array_equal(out[100:], sky)
        step = abs(float(out[99, 0, 0]) - float(out[100, 0, 0]))
        slope = abs(float(sky[1, 0, 0]) - float(sky[0, 0, 0]))
        self.assertAlmostEqual(step, slope, delta=slope * 0.5)             # slope carried on
        self.assertLess(float(out[0, 0, 0]), float(out[100, 0, 0]))        # deeper above
        d = np.abs(np.diff(out[:101, 0, 0]))
        self.assertLess(float(d[:10].mean()), float(d[-10:].mean()) + 1e-6)  # the change dies away upward
        self.assertTrue(np.isfinite(out).all() and out.min() >= 0 and out.max() <= 1)

    def test_extend_sky_up_flattens_a_corner_tint_with_height(self):
        sky = np.full((50, 40, 3), 0.6, np.float32)
        sky[:, :10, 0] = 0.8                                               # a tint at the left
        out = ex.extend_sky_up(sky, 120)
        self.assertGreater(float(out[119, :5, 0].mean() - out[119, 30:, 0].mean()), 0.05)
        self.assertLess(float(out[0, :5, 0].mean() - out[0, 30:, 0].mean()), 0.01)


class DetailTests(unittest.TestCase):
    """The isles' and the whale's painted-detail motion (`skyset_detail.py`): masks, texture budget, t = 0."""

    def test_every_sprite_with_a_painted_fall_has_it_and_the_budget_holds(self):
        for light in LIGHTS:
            spec = DATA["lights"][light]
            falls = {l["id"] for l, d in _details(light) if d["kind"] == "fall"}
            self.assertEqual(falls, {"isle_falls", "whale"}, light)
            pixels = 0
            for _, d in _details(light):
                for key in ("mask", "flow", "crop", "asset"):
                    if key in d:
                        pixels += _png(d[key]).shape[0] * _png(d[key]).shape[1]
            self.assertEqual(pixels, spec["detailPixels"], light)
            self.assertLessEqual(spec["textureBytes"], ex.BUDGET, light)
            self.assertLess(spec["detailPixels"], 0.01 * ex.BUDGET, "the masks are small crops, not sprites")

    def test_masks_stay_inside_the_sprites_alpha(self):
        for light in LIGHTS:
            for layer, d in _details(light):
                sprite = sd.load_sprite(layer)
                sh, sw = sprite.shape[:2]
                rx, ry = layer["size"][0] / sw, layer["size"][1] / sh
                x0, y0 = round((d["pos"][0] - layer["pos"][0]) / rx), round((d["pos"][1] - layer["pos"][1]) / ry)
                key = "asset" if d["kind"] == "glow" else "mask"
                m = _png(d[key])[..., 3]
                a = sprite[y0: y0 + m.shape[0], x0: x0 + m.shape[1], 3]
                self.assertEqual(m.shape, a.shape, f"{light} {layer['id']} {d['id']}")
                self.assertLessEqual(float((m - a).max()), 0.05, f"{light} {layer['id']} {d['id']}: a mask never reaches past the sprite")
                self.assertGreater(float(m.max()), 0.9, f"{light} {layer['id']} {d['id']}: not empty")
                self.assertGreater(float((m > 0.5).mean()), 0.05)

    def test_the_committed_png_masks_are_the_ones_shipped(self):
        for light in LIGHTS:
            for layer, d in _details(light):
                f = sd.mask_path("home", light, layer["id"], d["id"])
                self.assertTrue(f.exists(), f.name)
                src = sd.read_mask(f)
                key = "asset" if d["kind"] == "glow" else "mask"
                self.assertLess(float(np.abs(src - _png(d[key])[..., 3]).max()), 1 / 255 + 1e-6, f.name)

    def test_a_fall_veil_is_lighter_and_darker_in_equal_measure(self):
        for light in LIGHTS:
            for _, d in _details(light):
                if d["kind"] != "fall":
                    continue
                flow, mask = _png(d["flow"]), _png(d["mask"])[..., 3]
                h = mask.shape[0]
                self.assertEqual(flow.shape[0], 2 * h, "a mirrored tile: it wraps without a seam")
                self.assertTrue(np.allclose(flow[0], flow[-1]) or np.abs(flow[0, :, 3] - flow[-1, :, 3]).max() < 0.02)
                lum = flow[..., :3].mean(-1)
                col = np.median(lum, axis=0)
                signed = (lum - col[None]) * flow[..., 3]
                self.assertLess(abs(float(signed.mean())), 0.008, f"{light} {d['id']}")

    def test_time_zero_draws_nothing_and_the_frame_is_the_painting(self):
        for light in LIGHTS:
            for _, d in _details(light):
                self.assertEqual(rd.ease(0, d["ramp"]), 0)
                self.assertEqual(rd.sway_top({**d, "amp": d.get("amp", 1), "period": d.get("period", 1)}, 0), 0)
                if d["kind"] == "glow":
                    self.assertEqual(rd.flicker(d, 0), 0)
                if d["kind"] == "fall":
                    self.assertEqual(rd.mist_level(d["mist"], 0, rd.ease(0, d["ramp"])), 0)
            s = rd.load("home", light)
            fr = sc.framing(s["manifest"])
            with_detail, without = rd.render(s, 0, fr), rd.render(s, 0, fr, detail=False)
            self.assertTrue(np.array_equal(with_detail, without), light)
            # and the existing frame-zero identity check holds (RenderTests.test_frame_zero_is_the_painting)

    def test_a_falls_mean_colour_holds_while_it_flows_and_the_canopy_silhouette_stays(self):
        import cv2
        for light in LIGHTS:
            s = rd.load("home", light)
            fr = sc.framing(s["manifest"])
            g = rd.geometry(s["manifest"], fr)
            for t in (2.2, 4.1, 7.7):
                on = cv2.cvtColor(rd.render(s, t, fr).astype(np.float32) / 255, cv2.COLOR_RGB2Lab)
                off = cv2.cvtColor(rd.render(s, t, fr, detail=False).astype(np.float32) / 255, cv2.COLOR_RGB2Lab)
                for layer in s["layers"]:
                    for d in layer.get("details", []):
                        rd._detail_prep(d, g)
                        if d["kind"] == "fall":
                            m = d["_mask"]
                            h, w = m.shape
                            dy = rd.bob_y(layer.get("bob"), t)
                            dx = 0.0
                            if layer["role"] == "whale":
                                img, x, _ = rd._scaled(layer, g, tuple(s["master"]))
                                dx = rd.glide_left(x, img.shape[1], layer.get("drift", 0), t, rd.SCREEN[0]) - x
                            x0, y0 = round(d["_x"] + dx), round(d["_y"] + dy)
                            A, B = on[y0: y0 + h, x0: x0 + w], off[y0: y0 + h, x0: x0 + w]
                            ma = (A * m[..., None]).sum((0, 1)) / m.sum()
                            mb = (B * m[..., None]).sum((0, 1)) / m.sum()
                            self.assertLess(float(np.linalg.norm(ma - mb)), 1.0, f"{light} {layer['id']} {d['id']} t={t}: dE of the mean colour")
                            self.assertGreater(float(np.abs(A - B).max()), 0.5)       # and it does move

    def test_motion_constants_live_in_the_json(self):
        for light in LIGHTS:
            for _, d in _details(light):
                self.assertIn("ramp", d)
                if d["kind"] == "fall":
                    self.assertEqual(d["speed"], sd.DETAIL_MOTION["fall"]["speed"])
                    self.assertLessEqual(d["mist"]["peak"], 0.2)
                if d["kind"] == "glow":
                    self.assertLessEqual(d["amp"], 0.06)
                if d["kind"] == "sway":
                    self.assertLessEqual(d["amp"], 2)

    def test_the_scroll_is_seamless_within_one_tile(self):
        self.assertAlmostEqual(rd.flow_offset(20, 0, 100), 0)
        self.assertAlmostEqual(rd.flow_offset(20, 5, 100), 0, places=9)
        self.assertLess(rd.flow_offset(20, 4.9, 100), 100)


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
