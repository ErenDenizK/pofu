# Plate tools

Offline tools for plate-first islands (ADR-0022, `docs/design/plate-islands.md`). Python 3 with
numpy, Pillow, scipy, pillow-heif (`pip install -r tools/plate/requirements.txt`); OpenCV for registration, the pilot's matte and the sky split. Deterministic.

| File | What it does |
|---|---|
| `ingest.py` | plate-first ingest (`docs/design/plate-islands.md` §0): from `design/art/plates/<island>/objects.json` (plates, trace, tap and occluder polygons, walkable lawn, character spots, framing) the matte, the whole plate with a feathered border, the island cut, the plate's sky and cloud sea extended past its edges (the backdrop), occluder cut-outs, the light and shadow maps and `Plates/plate-<island>.json`; `check` guards polygons, assets and the texture budget. A light painted at some stages only (Çağlayan's night: 2 and 3) is "sparse": its arrays are padded and the JSON lists `painted` per light; `referenceState` names the harmony reference (default: the first plate); `backdrop: "calm"` and `backdropScale` give a landscape plate a quiet sea below it; `characterLight` overrides the rim, `stoneMargin` and turns on `saturate` per island |
| `harmony_check.py` | the character harmony rule as a measurement (`docs/design/visual-system.md` "Characters"): from a full-resolution Home frame (`home-plate-full-<state>.png`), each character's body L* and C* against its surrounding lawn, checked against the band calibrated on the level-10 day frame, plus the night "no sticker" and golden "fur follows the lawn's hue" rules; `--island caglayan --reference s4-day` measures Damla in `caglayan-plate-full-s<stage>-<light>.png` against the island's own root frame; `python3 -I tools/plate/test_harmony_check.py` |
| `portrait.py` | the portrait master of an island whose stage plates are landscape (Çağlayan, ADR-0025): `register` measures where a landscape plate sits in Codex's portrait outpaint (ECC on the island's body; `portraitFrame` in `objects.json` stores it: scale 2/3 at (0, 425) of the 1024 x 1536 master), `master` cuts the island out of the master by the committed matte and pastes the picked stage plate's island and a feathered margin over it at that place (so the island is the stage plate's, pixel for pixel before the resample), `stage_master` does the same for each stage; `python3 tools/plate/test_portrait.py` |
| `sprite_matte.py` | mattes for a sky set's distant isles from the master's own pixels (where the painting leaves the fitted sky), written to `sky/mattes/` as hand data; Home's were BiRefNet-lite's |
| `split.py` | the plate-first sky split: one painted master per light cut into an island plate (alpha matte unmixed from what is behind it, the cloud bank at its base kept so the seam falls in soft cloud) over a sky set (gradient, far and mid clouds, distant isles and the whale as sprites, a cloud sea whose area behind the island is quilted from the visible sea, drift tiles that wrap), HEIC q70 plus `manifest.json` under `design/art/plates/<island>/sky/<light>/`; hand data `sky/sky.json` |
| `inpaint.py` | exemplar fills for it: `quilt` (masked-SSD block quilting by FFT correlation, no smear: the cloud-sea fill and the wrap seams) and a small multi-scale PatchMatch `inpaint` |
| `screen_check.py` | six checks on composited frames at the Home framing (1206 x 2622): frame-zero identity, seam under drift (t = 0, 30, 120 s), colour drift, dead composition, life, resolution; the same functions read a CI screenshot (`check_frame`); thresholds and what Home measured: `design/art/plates/home/sky/calibration.json` |
| `skyset_export.py` | ships a sky set to the app: the layers as HEIC imagesets `world-<island>-sky-<layer>-<light>-0` (the soft cloud layers smaller than the master to fit the 9 MB state budget, the island byte for byte, the gradient and the sea padded past the plate, the night's stars as their own light in three groups) and `Plates/skyset-<island>.json`, the one source of the motion constants and the state's texture bytes; `PofuWorld/Sky/SkySet.swift` reads it |
| `skyset_detail.py` | gives the isles and the whale painted-detail motion from their own pixels, code only (run by `skyset_export.py`): a waterfall's water flows down inside a mask with a breathing mist at its foot, a canopy's inside sways 1 to 2 px, a lamp or window flickers a few per cent; boxes in `design/art/plates/home/sky/detail.json`, hand-adjustable PNG masks in `design/art/plates/home/sky/detail/`, assets `world-<island>-sky-fx-*`, constants (`DETAIL_MOTION`) in `skyset-<island>.json`; nothing is drawn at t = 0 |
| `skyset_render.py` | renders the shipped sky set offline with the app's motion formulas (`SkyMotion`): a still or an H.264 clip at 1206 x 2622, with `--vivid` for an offline chroma raise of the sky and cloud layers; the review clips come from it because the simulator cannot record in CI |
| `pale.py` | the numbers behind `docs/research/pale-assets.md`: per-region L*, C*, hue, local contrast, fine detail, accent and dark shares for references, CI frames and raw sprites; the H2, H3 and H6 tests |
| `light.py` | can a fitted LUT replace a painted light state? fits golden, rain and night on one painted pair, applies to another plate, measures dE2000 against its painted truth: `docs/research/plate-pilot/light-fit.jpg` |
| `proofs.py` | the risky mechanisms as frames: occlusion behind a painted object, a sway mask, an upgrade insert, a tap highlight, light from the plate: `docs/research/plate-pilot/mechanisms.jpg` |
| `heic.py` | shipped plate, island and occluder layers are HEIC q70 with alpha (ADR-0024; backdrops stay JPEG): `save`, `open_image`, and the ΔE2000 p95 check the tests use |
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

Çağlayan (landscape 1536 x 1024, `design/art/plates/caglayan/objects.json`; one matte, the stage 4 day's, `matte-day-0.png`):

    python3 -I tools/plate/ingest.py all caglayan
    python3 -I tools/plate/harmony_check.py --island caglayan --reference s4-day caglayan-plate-full-*.png

`pale.py --register` re-finds where Çağlayan's plate sits in the CI frame (scale 0.606, at 9, 316).

Çağlayan's day is drawn as the stage plate's island over a sky set (ADR-0025). The set is split from one portrait
master, `design/art/plates/caglayan/sky/master-day.heic` (x-caglayan-portrait-s4-day t1, x2, the picked plate's island
pasted over it); the five stages share its sky and each cuts its own island layer (`island-s<stage>.heic`,
`world-caglayan-sky-island-day-<stage>`), so the app's `SkySet.shipped(island:light:stage:)` looks up `day-<stage>`.
The plates themselves, the characters, objects, tap polygon and light maps stay in the landscape plates' coordinates;
only the sky set's picture is placed by `plateFrame` in `Plates/skyset-caglayan.json`. Golden, night and rain keep the
landscape plate and its calm backdrop (`backdrop: calm` is still used by them) until their portrait masters exist.

    python3 tools/plate/portrait.py register caglayan      # measure; compare with portraitFrame
    python3 tools/plate/portrait.py master caglayan        # the day master
    python3 tools/plate/sprite_matte.py caglayan           # the two distant isles' mattes (hand data, adjust by eye)
    python3 tools/plate/split.py caglayan --light day      # ~2 min; also the four other stages' island layers
    SKYSET_CACHE=/tmp/q python3 tools/plate/skyset_export.py caglayan --light day   # ~25 min: two block quilts, cached
    python3 tools/plate/screen_check.py caglayan all --frames /tmp/frames
    python3 tools/plate/screen_check.py caglayan sky
    python3 tools/plate/skyset_render.py caglayan day --out caglayan-sky-day.mp4

The picture runs on past the master: at the Island stop the screen shows about 1.03 master widths and 1.5 master heights
(about 20 % above the master's top edge and 12 % below its bottom). `sky.json`'s `export` says how far: the sky gradient
continues upward by a fitted field (`extend_sky_up`: the first row's own colours, the fitted slope easing off, so the
join is continuous in value and slope), the far clouds continue upward by quilting their own blocks (`continue_up`,
thinning toward the zenith), the sea downward as Home's does. Only the drifting cloud layers cross the join.

## Sky split (`split.py`, `screen_check.py`)

    python3 tools/plate/split.py home --light all        # ~4 min per light (the quilt); writes design/art/plates/home/sky/<light>/
    python3 tools/plate/screen_check.py home all --frames /tmp/frames --json /tmp/check.json

The master is the shipped x2 plate of each light (the three share their geometry, so the island matte
and the sprite mattes in `sky/` serve all). Bottom to top: sky, far, sprites, mid, sea, island. The
island layer's colours are unmixed against the layers behind it, so at rest the composite is the
painting and on any other background no halo shows. Motion is code only: the manifest suggests
parallax (far 4, mid 9, sea 14 screen px/s at 1206 wide) and the tile widths.

The app draws the set (`PofuWorld/Sky/`, ADR-0025): `python3 tools/plate/skyset_export.py home` writes the imagesets and
`Plates/skyset-home.json` (frame-zero identity of the shipped layers: mean dE 0.56 to 0.63, p99 2.1 to 4.3; `screen_check.py home sky` adds the mirror, stripe and ghost-star checks), then Home's level-10 day,
golden hour and night draw it behind the island layer and the other states keep their plate. The simulator's CI frames
(`home-plate-full-l10-<light>.png`, the sky at time zero) are checked against the previous plate-only build's frames:

    python3 -I tools/plate/screen_check.py home ci --frames shots --before before-shots

    python3 tools/plate/skyset_render.py home day --out day.mp4          # 6 s at 30 fps, the app's motion
    python3 tools/plate/skyset_render.py home day --out vivid.mp4 --vivid 1.09
    python3 tools/plate/test_skyset.py

Calibration on Home (`design/art/plates/home/sky/calibration.json`, written by `screen_check.py home all --json`):
the lead's guesses held except three. Identity measures mean dE 0.48 to 0.54 and p99 2.8 to 4.7 (limits 1.5 and
6). The seam ring (halo lines) is clean to 6e-5 of the ring, limit 0.2 %; a second measure, straight block edges in
the sea round the island (`blocks`), caught the earlier stripe fills at 0.15 to 0.2 % and sits at 0 to 0.02 % now,
limit 0.05 %. Dead composition: golden's own master already has a 19.5 % run (a smooth sky), so the limit is 20 %
and at most 2 points over the master's own. Life: the sky moves 2.2 to 2.8 grey levels in 2 s (floor 0.25), the
island 0.08 to 0.13 from lossy alpha (limit 0.5). Colour: the sky-to-lawn ratio drifts 0.4 to 1.3 % (night 5.9 % at
t = 120 s, as the far clouds leave the sky; limit 10 %). Leak: island greens in a drifting layer are 0 to 17 px
(limit 200; golden's yellow-green clouds start at hue 105). The leak check keys on the island matte's own colours (the island layer's lawn greens as eight CIELAB cluster centres; a pixel in the island's hue band within 12 dE of one is the lawn's), not on every green: Revontuli's aurora is green too.

## Upscale (`upscale.py`)

Sharper plates on 3x screens than the GPU's bilinear stretch of a 1024 x 1536 image. Needs `pip install
onnxruntime` (CPU, no torch). Weights (5 MB) download on first run to `~/.cache/pofu-upscale/` (override
`POFU_UPSCALE_CACHE`) from a pinned URL, checked against a pinned sha256, never committed.

    python3 -I tools/plate/upscale.py plate.png plate@2x.png --scale 2 [--model general-x4v3|anime6b]
    python3 -I tools/plate/test_upscale.py     # skipped without onnxruntime or the cached model

Licence: Real-ESRGAN is BSD-3-Clause (code and weights, commercial use allowed); ONNX exports are
third-party Hugging Face re-hosts of the same weights (see the research note for the caveat). Time: ~18 s
for a 1536 x 1024 plate to 3072 x 2048 on 4 CPU cores (anime6b, not recommended: outlines, ~98 s).
