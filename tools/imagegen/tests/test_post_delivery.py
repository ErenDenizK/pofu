"""Soft-delivery review images use the saved, canonically quantized lock."""
from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import pipeline as pl  # noqa: E402
import qa  # noqa: E402
import run  # noqa: E402


class PostDeliveryTests(unittest.TestCase):
    def test_float_lock_delivers_saved_pixels_and_finishes_review(self):
        for scale in (0.5, 1.0):
            with self.subTest(scale=scale), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                config = pl.load_config()
                config["paths"] = {k: str(root / k) for k in
                                   ("inbox", "build", "contact_sheets", "review")}
                job = pl.Job("soft-glow", "prop", "soft-glow", [], deliver={"scale": scale})
                manifest = pl.Manifest("delivery-test", "Delivery test", [job], {}, root / "manifest.yaml")
                source = pl.inbox_dir(config, manifest.batch) / job.take_file(1)
                source.parent.mkdir(parents=True)
                Image.new("RGBA", (64, 48), (10, 20, 30, 255)).save(source)
                # Real process_take returns float64 RGBA, not Pillow's uint8.
                # Use fractional values and partial alpha to exercise canonical
                # quantization and premultiplied delivery resampling together.
                yy, xx = np.mgrid[:48, :64]
                locked = np.stack(((xx + 0.49) / 64, (yy + 0.51) / 48,
                                   (xx + yy + 0.37) / 112,
                                   0.3 + 0.7 * xx / 63), axis=-1)
                result = qa.TakeResult(locked.copy(), locked.copy(), locked)
                with patch.object(run.qa, "process_take", return_value=result), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(run.cmd_post(SimpleNamespace(only=None), config, manifest), run.EXIT_OK)
                out = pl.build_dir(config, manifest.batch)
                with Image.open(out / "locked" / source.name) as saved:
                    expected = np.asarray(run.cu.downscale(saved, scale).convert("RGBA"))
                with Image.open(out / "delivered" / f"{source.stem}.webp") as delivered:
                    self.assertEqual(delivered.size, (round(64 * scale), round(48 * scale)))
                    np.testing.assert_array_equal(np.asarray(delivered.convert("RGBA")), expected)
                report = json.loads((out / "qa" / f"{source.stem}.json").read_text())
                self.assertEqual((report["job"], report["take"], report["status"]), (job.id, 1, "pass"))
                self.assertTrue(pl.contact_sheet_path(config, manifest.batch).is_file())
                self.assertTrue(pl.review_file(config, manifest.batch).is_file())
