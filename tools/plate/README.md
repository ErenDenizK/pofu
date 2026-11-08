# Plate tools

Offline tools for plate-first islands (ADR-0022, `docs/design/plate-islands.md`). Python 3 with
numpy, Pillow, scipy; OpenCV only for registration and the pilot's matte. Deterministic.

| File | What it does |
|---|---|
| `pale.py` | the numbers behind `docs/research/pale-assets.md`: per-region L*, C*, hue, local contrast, fine detail, accent and dark shares for references, CI frames and raw sprites; the H2, H3 and H6 tests |
| `pilot.py` | the plate-first pilot: Revontuli stand-ins composed at the CI frame (460 x 1000 = 402 x 874 pt) with a code sky, a code aurora, lit sprites and a diff-mask reveal; the sheet `docs/research/plate-pilot/plate-pilot.jpg` |

## Run

The CI frames come from the look-pipeline-v2 screenshots branch:

    mkdir -p /tmp/shots && for f in concept-day-home caglayan-stage-0 caglayan-stage-4 \
        caglayan-night-0 caglayan-night-4 concept-night-home; do
      git show origin/screenshots/feat-look-pipeline-v2:$f.jpg > /tmp/shots/$f.jpg; done
    python3 -I tools/plate/pale.py /tmp/shots --json /tmp/pale.json        # ~10 s
    python3 -I tools/plate/pilot.py /tmp/shots docs/research/plate-pilot/plate-pilot.jpg --frames /tmp/frames   # ~60 s

`pale.py --register` re-finds where Çağlayan's plate sits in the CI frame (scale 0.606, at 9, 316).
