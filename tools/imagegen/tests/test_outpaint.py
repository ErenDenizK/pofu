"""Outpaint jobs: the placed parent, the mask, and the manifest field."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import pipeline as pl  # noqa: E402
import run  # noqa: E402


class OutpaintTests(unittest.TestCase):
    def test_input_and_mask_geometry(self):
        parent = Image.new("RGBA", (1536, 1024), (200, 50, 50, 255))
        inp, mask = run.outpaint_input(parent, (1024, 1536), 0.52)
        self.assertEqual(inp.size, (1024, 1536))
        self.assertEqual(mask.size, (1024, 1536))
        a, m = np.asarray(inp)[..., 3], np.asarray(mask)
        rows = np.where(a.max(axis=1) > 0)[0]
        band_h = rows[-1] - rows[0] + 1
        self.assertEqual(band_h, round(1024 * 1024 / 1536))
        self.assertLess(abs((rows[0] + rows[-1]) / 2 - 0.52 * 1536), 2)
        self.assertTrue((a[rows[0]:rows[-1] + 1] == 255).all())      # band full width, opaque
        self.assertTrue((a[:rows[0]] == 0).all() and (a[rows[-1] + 1:] == 0).all())
        self.assertTrue((m[rows[0]:rows[-1] + 1] == 0).all())         # keep the band
        self.assertTrue((m[:rows[0]] == 255).all() and (m[rows[-1] + 1:] == 255).all())

    def test_manifest_and_refs(self):
        text = """batch: t
title: t
refs: {guide: g.png}
jobs:
  - {id: p, kind: plate, name: p, external: b, master: p.webp}
  - id: q
    kind: plate
    name: q
    size: 1024x1536
    canvas: 1024x1536
    edit_of: p
    outpaint: {anchor_y: 0.52}
    light: {cell: day, layer: subject}
    prompt:
      - text: Outpaint.
      - block: edit-keep-v1
"""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "m.yaml").write_text(text)
            m = pl.load_manifest(root / "m.yaml")
            job = m.job("q")
            self.assertEqual(job.outpaint, {"anchor_y": 0.52})
            self.assertEqual([a.ref for a in pl.attachments_for(job)],
                             ["outpaint-input:p", "outpaint-mask:p"])
            config = pl.load_config()
            config["paths"] = {k: str(root / k) for k in ("inbox", "build", "contact_sheets", "review")}
            parent = root / "p.png"
            Image.new("RGBA", (1536, 1024), (1, 2, 3, 255)).save(parent)
            refs = run.job_refs(job, m, {"p": (1, parent)}, config)
            self.assertEqual(Image.open(refs[0][1]).size, (1024, 1536))
            self.assertEqual(Image.open(refs[1][1]).mode, "L")

    def test_outpaint_needs_edit_of(self):
        text = """batch: t
title: t
jobs:
  - id: q
    kind: plate
    name: q
    outpaint: {anchor_y: 0.5}
    light: {cell: day, layer: subject}
    prompt:
      - text: x
"""
        with tempfile.TemporaryDirectory() as tmp:
            f = Path(tmp) / "m.yaml"
            f.write_text(text)
            with self.assertRaises(pl.ManifestError):
                pl.load_manifest(f)


if __name__ == "__main__":
    unittest.main()
