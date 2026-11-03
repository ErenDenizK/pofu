"""The upload check: size limit, byte match, and full decode."""
from __future__ import annotations

import io
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import check_upload as cu  # noqa: E402


def webp(size=(64, 48)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGBA", size, (240, 220, 200, 255)).save(buf, "WEBP", quality=90)
    return buf.getvalue()


class CheckUploadTests(unittest.TestCase):
    def test_whole_file_passes(self):
        data = webp()
        self.assertEqual(cu.problems("t1.webp", data, data), [])

    def test_truncated_image_fails_to_decode(self):
        data = webp((512, 512))
        found = cu.problems("t1.webp", data[: len(data) // 2], data)
        self.assertTrue(any("does not decode" in p for p in found), found)
        self.assertTrue(any("differs" in p for p in found), found)

    def test_size_limit(self):
        found = cu.problems("notes.yaml", b"x" * cu.LIMIT, None)
        self.assertEqual(len(found), 1)
        self.assertIn("not under 600 KB", found[0])


def noisy(size=(1536, 1024)) -> Image.Image:
    # Photographic noise does not compress: the lossless raw cannot fit.
    import numpy as np
    rng = np.random.default_rng(7)
    a = rng.integers(0, 256, (size[1], size[0], 4), dtype=np.uint8)
    a[..., 3] = 255
    return Image.fromarray(a, "RGBA")


class RawRuleTests(unittest.TestCase):
    def test_small_raw_is_kept_lossless(self):
        im = Image.new("RGBA", (512, 512), (240, 200, 160, 255))
        data, encoding = cu.encode_raw(im)
        self.assertEqual(encoding, "webp lossless")
        with Image.open(io.BytesIO(data)) as back:
            self.assertEqual(back.convert("RGBA").tobytes(), im.tobytes())

    def test_large_raw_is_kept_lossy_under_the_limit_never_dropped(self):
        im = noisy((900, 700))
        data, encoding = cu.encode_raw(im)
        self.assertTrue(encoding.startswith("webp q"), encoding)
        self.assertLess(len(data), cu.LIMIT)
        self.assertEqual(cu.problems("raw.webp", data, data), [])

    def test_save_raw_replaces_an_old_raw_png(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp) / "tea-stall-1"
            folder.mkdir()
            src = Path(tmp) / "take.png"
            Image.new("RGBA", (64, 64), (10, 20, 30, 255)).save(src)
            (folder / "raw.png").write_bytes(b"old")
            out, _ = cu.save_raw(src, folder)
            self.assertEqual(out.name, "raw.webp")
            self.assertFalse((folder / "raw.png").exists())

    def test_master_folder_without_a_raw_fails(self):
        names = [
            "design/art/stations/tea-stall-1/tea-stall-1.png",
            "design/art/stations/tea-stall-1/meta.json",
            "design/art/stations/tea-stall-2/tea-stall-2.png",
            "design/art/stations/tea-stall-2/meta.json",
            "design/art/stations/tea-stall-2/raw.webp",
            "design/art/masters/old/meta.json",
            "design/art/masters/old/raw.png",
            "design/art/takes/batch-01/tea-stall-1/contact.jpg",
        ]
        self.assertEqual(cu.missing_raws(names), ["design/art/stations/tea-stall-1"])


if __name__ == "__main__":
    unittest.main()
