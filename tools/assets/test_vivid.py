"""The vividness regrade (tools/assets/vivid.py): deterministic, bounded, and aimed at props only."""
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vivid  # noqa: E402

CFG = vivid.load_config()


def sprite(seed: int = 3, size: int = 96) -> np.ndarray:
    """A pale, flat-ish painted blob on transparency."""
    rng = np.random.default_rng(seed)
    rgb = np.clip(np.array([0.84, 0.76, 0.62]) + rng.normal(0, 0.015, (size, size, 3)), 0, 1)
    rgb[:, size // 2:, :] = np.clip(np.array([0.70, 0.80, 0.66]) + rng.normal(0, 0.015, (size, size // 2, 3)), 0, 1)
    alpha = np.zeros((size, size))
    alpha[8:-8, 8:-8] = 1.0
    return np.dstack([rgb, alpha])


def test_kinds_and_exclusions():
    assert vivid.kind_of("garden-3") == "plant"
    assert vivid.kind_of("tea-stall-2") == "station"
    assert vivid.kind_of("decor-bench") == "prop"
    assert vivid.kind_of("paint-pot-bloom", "ui") == "home"
    for never in ("mochi", "mochi-work", "findik-eyes-happy", "simit-kitten", "pofu", "island-main", "harbor-island-s",
                  "isle-hamam-standin", "cloud-sea", "far-isle-1", "tea-stall-1-glow", "workshop-1-glow"):
        assert vivid.kind_of(never) is None, never
    for chrome in ("paint-face-primary", "paint-icon-seed", "paint-panel-paper", "paint-lantern-on"):
        assert vivid.kind_of(chrome, "ui") is None, chrome


def test_deterministic_and_alpha_kept():
    a = vivid.regrade(sprite(), "plant")
    b = vivid.regrade(sprite(), "plant")
    assert np.array_equal(a, b)
    assert np.array_equal(a[..., 3], sprite()[..., 3])


@pytest.mark.parametrize("kind", sorted(CFG["kinds"]))
def test_more_vivid_within_limits(kind):
    src = sprite()
    out = vivid.regrade(src, kind)
    m0, m1 = vivid.measure(src), vivid.measure(out)
    assert m1["chroma_mean"] > m0["chroma_mean"] * 1.1
    assert m1["L_mean"] < m0["L_mean"]
    assert m1["contrast"] > m0["contrast"]
    assert m1["chroma_p95"] <= max(CFG["chroma_p95_cap"], m0["chroma_p95"]) + 1e-3
    assert m1["L_p5"] >= min(CFG["value_floor"], m0["L_p5"]) - 1e-3


def test_cap_holds_for_a_sprite_already_above_it():
    src = sprite()
    src[..., :3] = np.clip(src[..., :3] * np.array([1.0, 0.55, 0.2]) + np.array([0.12, 0.0, 0.0]), 0, 1)
    out = vivid.regrade(src, "plant")
    assert vivid.measure(out)["chroma_p95"] <= CFG["chroma_p95_cap"] + 1e-3


def test_neutrals_stay_neutral():
    src = sprite()
    src[..., :3] = 0.8
    out = vivid.regrade(src, "plant")
    lab = vivid.sl.srgb_to_lab(out[..., :3])
    assert np.hypot(lab[..., 1], lab[..., 2])[src[..., 3] > 0].max() < 3.5


def test_regrade_image_skips_never_names():
    from PIL import Image

    img = Image.fromarray((sprite() * 255).astype(np.uint8), "RGBA")
    assert vivid.regrade_image("mochi", img) is img
    assert vivid.regrade_image("garden-1", img) is not img
