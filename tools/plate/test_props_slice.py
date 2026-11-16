import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import props_slice as ps  # noqa: E402


def blob(h=60, w=40):
    rgba = np.zeros((h + 20, w + 20, 4), np.uint8)
    rgba[10:10 + h, 10:10 + w] = (200, 120, 80, 255)
    return rgba


def test_clean_alpha_drops_ringing_and_detached_specks():
    a = blob()
    a[0, 0] = (255, 255, 255, 3)           # encoder ringing
    a[2:4, 2:4] = (255, 255, 255, 200)     # a detached speck
    out = ps.clean_alpha(a)
    assert out[0, 0, 3] == 0 and out[3, 3, 3] == 0
    assert out[40, 30, 3] == 255


def test_clean_alpha_edge_is_a_short_ramp_with_no_fringe_colour():
    out = ps.clean_alpha(blob())
    row = out[40, :, 3]
    ramp = int(((row > 12) & (row < 243)).sum())
    assert 2 <= ramp <= 6
    edge = out[40, 9]
    assert edge[3] > 0 and tuple(edge[:3]) == (200, 120, 80)


def test_states_share_one_canvas_with_feet_on_the_bottom():
    tiles = {"a": np.pad(blob(60, 40), ((0, 0), (0, 0), (0, 0))), "b": blob(40, 40)}
    for k in tiles:
        tiles[k] = ps.clean_alpha(tiles[k])
    out = ps.aligned(tiles)
    assert out["a"].shape == out["b"].shape
    for t in out.values():
        ys = np.nonzero(t[..., 3] > 0)[0]
        assert ys.max() == t.shape[0] - 1 - 3 + 0 or ys.max() >= t.shape[0] - 5
