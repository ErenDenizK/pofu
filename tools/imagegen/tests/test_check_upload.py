"""The upload check: size limit, byte match, and full decode."""
from __future__ import annotations

import io
import sys
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


if __name__ == "__main__":
    unittest.main()
