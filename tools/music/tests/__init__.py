"""Tests for tools/music. Run: python3 -I -m unittest discover -s tools/music -p "test_*.py"."""

import sys
from pathlib import Path

# `python3 -I` leaves the tools directory off the path; the package is tools/music.
_TOOLS = str(Path(__file__).resolve().parents[2])
if _TOOLS not in sys.path:
    sys.path.insert(0, _TOOLS)
