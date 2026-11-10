# Plate tools

Offline tools for plate-first islands (ADR-0022, `docs/design/plate-islands.md`). Python 3 with
numpy, Pillow, scipy; OpenCV only for registration and the pilot's matte. Deterministic.

| File | What it does |
|---|---|
| `ingest.py` | plate-first ingest (`docs/design/plate-islands.md` §0): from `design/art/plates/<island>/objects.json` (plates, trace, tap and occluder polygons, walkable lawn, character spots, framing) the matte, the whole plate with a feathered border, the island cut, the plate's sky and cloud sea extended past its edges (the backdrop), occluder cut-outs, the light and shadow maps and `Plates/plate-<island>.json`; `check` guards polygons, assets and the texture budget |
| `harmony_check.py` | the character harmony rule as a measurement (`docs/design/visual-system.md` "Characters"): from a full-resolution Home frame (`home-plate-full-<state>.png`), each character's body L* and C* against its surrounding lawn, checked against the band calibrated on the level-10 day frame; `python3 -I tools/plate/test_harmony_check.py` |
| `pale.py` | the numbers behind `docs/research/pale-assets.md`: per-region L*, C*, hue, local contrast, fine detail, accent and dark shares for references, CI frames and raw sprites; the H2, H3 and H6 tests |
| `light.py` | can a fitted LUT replace a painted light state? fits golden, rain and night on one painted pair, applies to another plate, measures dE2000 against its painted truth: `docs/research/plate-pilot/light-fit.jpg` |
| `proofs.py` | the risky mechanisms as frames: occlusion behind a painted object, a sway mask, an upgrade insert, a tap highlight, light from the plate: `docs/research/plate-pilot/mechanisms.jpg` |
| `upscale.py` | offline AI x2 (or any scale) for plates: Real-ESRGAN general-x4v3 via onnxruntime, tiled, alpha kept, colour pinned to Lanczos; `docs/research/plate-upscale.md` |
| `pilot.py` | the plate-first pilot: Revontuli stand-ins composed at the CI frame (460 x 1000 = 402 x 874 pt) with a code sky, a code aurora, lit sprites and a diff-mask reveal; the sheet `docs/research/plate-pilot/plate-pilot.jpg` |

## Run

The home plate (batch 66's `x-home-flow-final-rich` t1, a 1024 x 1536 portrait: `size` in
`design/art/plates/home/objects.json`; swapping a plate is a data change there):

    python3 -I tools/plate/ingest.py matte home   # once per plate, needs OpenCV; writes matte-day-0.png
    python3 -I tools/plate/ingest.py all home     # deliver, objects, json, check; plates ship upscaled x2
                                                   # (0.8 model / 0.2 Lanczos); the first run takes a few minutes
    python3 -I tools/plate/ingest.py all home --no-upscale   # only when the model is unavailable: ships the original


States: `objects.json` lists the painted states (`plates`: `day` stages 0..8 are island levels 10..2, `stageLevels`; `golden` and `night` at level 10) and, per object, the day `stages` where it is painted (absent: all). Derive them by diffing each plate's object polygon against the level-10 plate (a high-pass normalised correlation separates a changed object from the edit's global drift), then check the crops by eye: `ingest.py` cuts an occluder only for the stages that paint it and `check` wants no more. The generated `Plates/plate-home.json` carries each state's character `harmony` (tint, contact).

The CI frames come from the look-pipeline-v2 screenshots branch:

    mkdir -p /tmp/shots && for f in concept-day-home caglayan-stage-0 caglayan-stage-4 \
        caglayan-night-0 caglayan-night-4 concept-night-home; do
      git show origin/screenshots/feat-look-pipeline-v2:$f.jpg > /tmp/shots/$f.jpg; done
    python3 -I tools/plate/pale.py /tmp/shots --json /tmp/pale.json        # ~10 s
    python3 -I tools/plate/pilot.py /tmp/shots docs/research/plate-pilot/plate-pilot.jpg --frames /tmp/frames   # ~60 s

    python3 -I tools/plate/light.py docs/research/plate-pilot/light-fit.jpg       # ~10 s
    python3 -I tools/plate/proofs.py docs/research/plate-pilot/mechanisms.jpg    # ~20 s

`pale.py --register` re-finds where Çağlayan's plate sits in the CI frame (scale 0.606, at 9, 316).

## Upscale (`upscale.py`)

Sharper plates on 3x screens than the GPU's bilinear stretch of a 1024 x 1536 image. Needs `pip install
onnxruntime` (CPU, no torch). Weights (5 MB) download on first run to `~/.cache/pofu-upscale/` (override
`POFU_UPSCALE_CACHE`) from a pinned URL, checked against a pinned sha256, never committed.

    python3 -I tools/plate/upscale.py plate.png plate@2x.png --scale 2 [--model general-x4v3|anime6b]
    python3 -I tools/plate/test_upscale.py     # skipped without onnxruntime or the cached model

Licence: Real-ESRGAN is BSD-3-Clause (code and weights, commercial use allowed); ONNX exports are
third-party Hugging Face re-hosts of the same weights (see the research note for the caveat). Time: ~18 s
for a 1536 x 1024 plate to 3072 x 2048 on 4 CPU cores (anime6b, not recommended: outlines, ~98 s).
