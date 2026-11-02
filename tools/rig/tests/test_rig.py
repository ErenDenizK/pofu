"""The rig compositor on a synthetic hamster (no generated art needed)."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import rig  # noqa: E402

W, H = 256, 384
BODY, EAR, EYE, FUR = (240, 200, 160), (240, 150, 150), (60, 40, 30), (250, 240, 230)

CONFIG = {
    "r1": "unused",
    "plate": "plate",
    "feather_px": 3,
    "diff_threshold": 6.0,
    "seam_warn": 6.0,
    "regions": {
        "fur": {"mode": "region", "full": True},
        "cheeks": {"mode": "envelope", "ellipses": [[128, 250, 125, 50]]},
        "ears": {"mode": "envelope", "restore": True, "ellipses": [[80, 150, 40, 40], [176, 150, 40, 40]],
                 "pivots": [[90, 175], [166, 175]]},
        "eyes": {"mode": "region", "ellipses": [[100, 230, 18, 18], [156, 230, 18, 18]]},
    },
    "layers": ["fur", "cheeks", "ears", "eyes"],
    "expressions": {"neutral": {}, "happy": {"eyes": "eyes-happy"}, "puff": {"cheeks": "puff"},
                    "sleepy": {"eyes": "eyes-closed"}},
    "pilot": ["neutral", "happy"],
}


def hamster(ears=True, eye=EYE, cheeks=0) -> np.ndarray:
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if ears:
        d.ellipse((55, 125, 105, 175), fill=EAR + (255,))
        d.ellipse((151, 125, 201, 175), fill=EAR + (255,))
    d.ellipse((38, 150, 218, 330), fill=BODY + (255,))   # head-body ball; covers the ear bases
    if cheeks:
        d.ellipse((38 - cheeks, 220, 98, 290), fill=BODY + (255,))
        d.ellipse((158, 220, 218 + cheeks, 290), fill=BODY + (255,))
    for cx in (100, 156):
        d.ellipse((cx - 10, 220, cx + 10, 240), fill=eye + (255,))
    return np.asarray(im, dtype=np.float64) / 255.0


def make_rig(parts=None) -> rig.Rig:
    return rig.Rig(hamster(), hamster(ears=False), parts or {}, CONFIG)


class RigTests(unittest.TestCase):
    def test_neutral_rebuilds_r1_from_the_plate(self):
        r = make_rig()
        comp = r.compose("neutral")
        self.assertEqual(comp.used, {"ears": "R1"})
        self.assertLess(r.fidelity(comp), 1.0)
        self.assertGreater(comp.image[150, 80, 3], 0.95)  # the ear is back

    def test_region_part_changes_only_its_region(self):
        happy = hamster(eye=FUR)
        r = make_rig({"eyes-happy": happy})
        comp = r.compose("happy")
        self.assertTrue(np.allclose(comp.image[230, 100, :3], np.array(FUR) / 255, atol=0.02))
        far = (slice(290, 320), slice(100, 160))
        self.assertTrue(np.allclose(comp.image[far], r.r1[far], atol=0.01))
        self.assertEqual(comp.used["eyes"], "eyes-happy")

    def test_envelope_part_grows_past_the_silhouette(self):
        r = make_rig({"puff": hamster(cheeks=30)})
        comp = r.compose("puff")
        self.assertLess(r.r1[255, 20, 3], 0.05)          # outside R1's outline
        self.assertGreater(comp.image[255, 20, 3], 0.5)  # the pouch bulges there

    def test_missing_part_is_reported_and_r1_stands_in(self):
        comp = make_rig().compose("sleepy")
        self.assertEqual(comp.missing, ["eyes-closed"])
        self.assertNotIn("eyes", comp.used)

    def test_missing_plate_falls_back_to_r1(self):
        r = rig.Rig(hamster(), None, {}, CONFIG)
        comp = r.compose("neutral")
        self.assertTrue(r.plate_missing)
        self.assertTrue(any("stands in as the plate" in n for n in comp.notes))

    def test_ear_flick_keeps_the_head_whole(self):
        r = make_rig()
        comp = r.compose("neutral", ear_flick=20)
        inside_head = comp.image[175:200, 100:156, 3]
        self.assertGreater(inside_head.min(), 0.95)  # the plate's dome shows, no hole
        self.assertFalse(np.allclose(comp.image[130:150, 55:105], r.compose("neutral").image[130:150, 55:105]))

    def test_seam_score_flags_a_mismatched_part(self):
        off = hamster(eye=FUR)
        off[..., :3] = off[..., :3] * 0.7  # a part painted darker than the plate
        comp = make_rig({"eyes-happy": off}).compose("happy")
        self.assertGreater(comp.seams["eyes"], CONFIG["seam_warn"])

    def test_sheet_writes_a_contact_sheet(self):
        out = Path(tempfile.mkdtemp(prefix="rig-")) / "sheet.jpg"
        comps = rig.sheet(make_rig({"eyes-happy": hamster(eye=FUR)}), ["neutral", "happy"], out)
        self.assertTrue(out.exists())
        self.assertEqual([c.name for c in comps], ["neutral", "happy", "neutral"])  # plus the ear flick row

    def test_shipped_config_names_every_layer_and_region(self):
        cfg = rig.load_config()
        self.assertEqual(set(cfg["layers"]), set(cfg["regions"]))
        for name, parts in cfg["expressions"].items():
            self.assertTrue(set(parts) <= set(cfg["layers"]), name)
        self.assertTrue(set(cfg["pilot"]) <= set(cfg["expressions"]))
        self.assertTrue((rig.REPO / cfg["r1"]).exists())


if __name__ == "__main__":
    unittest.main()
