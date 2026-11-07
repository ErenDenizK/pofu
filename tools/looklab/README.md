# Look lab

Offline experiments that test, with pictures and numbers, which light and colour techniques bring
the game's screens toward the concept references (I1 seasons, Gezgin and Revontuli nights) before
anything is built into the runtime. Results and verdicts: `docs/research/look-lab.md`.

Everything is Python 3 (numpy, Pillow, scipy; `onnxruntime` only for the monocular depth model),
deterministic (fixed seeds), CPU only. It reuses `tools/assets/lookdev.py` (scene recipes, the
game's grade and shadows), `nightlab.py` (unlight, night sky), `normals.py` (sprite height maps)
and `tools/imagegen/style_lock.py` (CIELAB).

| File | What it does |
|---|---|
| `lab.py` | IO, CIELAB, CIEDE2000, the three numbers (region dE, L* histogram distance, back/front local contrast), sheets |
| `regions.json` | region boxes (sky, back, focal, earth, sea) per image kind |
| `depth.py` | Depth Anything V2 small (ONNX, CPU) or none; sky/island/sea masks; normals from depth |
| `scene.py` | the lab home scene (`home-lab.json`, lookdev format) with layer ids and a layered depth |
| `grade.py` | experiment 1: Reinhard, sliced-OT LUT, region LUT, per-material LUT on the Home screenshots |
| `relight.py` | experiments 2 and 3: AO, contact shadows, day/golden/rain ratio rig, night from sources |
| `atmos.py` | experiment 4: depth haze, bloom/halation, measured falloff against the references |
| `repaint.py` | experiment 5 (design): the Codex edit job's inputs and prompt, and the cut back into layers |
| `best.py` | the winners combined for day, golden, night, rain beside the references |

## Run

The depth model is not in the repo. Download it once (about 100 MB) outside the repo:

    curl -L -o /tmp/da2s.onnx https://huggingface.co/onnx-community/depth-anything-v2-small/resolve/main/onnx/model.onnx
    pip install onnxruntime        # plus tools/assets/requirements.txt
    export LOOKLAB_DEPTH_MODEL=/tmp/da2s.onnx

The game frames come from the screenshots branch of `feat/concept-match`, and the "game light
now" columns use that branch's colour script:

    mkdir -p /tmp/shots && for s in day golden night rain; do
      git show origin/screenshots/feat-concept-match:concept-$s-home.jpg > /tmp/shots/concept-$s-home.jpg; done
    git show origin/feat/concept-match:design/art/colour-script.json > /tmp/cs.json

    python3 -I tools/looklab/grade.py   /tmp/shots docs/research/look-lab/01-grade.jpg
    python3 -I tools/looklab/relight.py /tmp/out --cells /tmp/cs.json        # 02-depth-ao.jpg, 03-relight.jpg
    python3 -I tools/looklab/atmos.py   /tmp/out --cells /tmp/cs.json        # 04-atmos-bloom.jpg
    python3 -I tools/looklab/best.py    /tmp/shots docs/research/look-lab/06-best.jpg --cells /tmp/cs.json --frames /tmp/out/frames
    python3 -I tools/looklab/repaint.py docs/research/look-lab/repaint --frame /tmp/out/frames/best-day.png --sheet docs/research/look-lab/05-repaint.jpg

Each takes 30 to 80 s on four CPU cores. `grade.py --cube-dir DIR` also writes the fitted LUTs as
`.cube` files (loadable in any grading tool and as a Metal 3D texture).
