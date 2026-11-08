# Plate upscale pilot (offline AI x2)

Question: does an offline AI upscaler give a clearly sharper, faithful x2 of a painted plate than Lanczos?
Test image: stand-in summer plate (1536 x 1024), viewed at 2.4x (x2 result, then x1.2), 1:1 crops:
`docs/research/plate-upscale/upscale-sheet.jpg` (rows: sunflowers, pond, door, grass).

| Method | mean dE (CIELAB, result back to 1x vs original) | p99 dE | time, 1536x1024 -> 3072x2048, 4 CPU cores |
|---|---|---|---|
| Lanczos x2 | 0.14 | 1.06 | < 1 s |
| Real-ESRGAN general-x4v3 (ONNX) + low-frequency colour match | **1.12** | 10.4 | **~18 s** |
| general-x4v3 raw | 1.52 | 11.6 | ~31 s |
| Real-ESRGAN anime-6B (ONNX) | 2.42 | 11.0 | ~98 s |

What I saw: both AI models are far sharper than Lanczos (petal edges, lily pads, door planks, grass tips,
sun glitter), no tile seams, no halos. anime-6B draws dark ink outlines around shapes and shifts tone: not
painterly, rejected. general-x4v3 stays soft and painted; slight smoothing of fine fibre texture (sky, grass
tips), no invented texture. Raw general-x4v3 drifts contrast (dE 1.5); pinning its low frequencies to the
Lanczos result (`match_colour`, on by default) brings dE to 1.12 and keeps the detail. The residual dE is
mostly the sharper edges themselves (dE is sensitive to edge position).

Licence: Real-ESRGAN code and released weights are BSD-3-Clause (xinntao / Tencent ARC; commercial use of
code, weights and outputs allowed). The ONNX files are third-party re-hosts on Hugging Face
(`Heliosoph/realesrgan-onnx`, `RekluzLabs/realesrgan_anime6b.onnx`, both tagged bsd-3-clause, "converted, no
retraining"); we pin sha256. Caveat: BSD-3 covers the weights; the (synthetic) training data licences are not
stated upstream. Authoritative weights are xinntao's GitHub release `.pth`; if the HF mirror vanishes, export
once with CPU torch and self-host.

Verdict: clearly better and faithful enough: add `tools/plate/upscale.py --model general-x4v3` (default).
Not wired into `ingest.py` yet. Limits: only x4-native models tried, one image, grass/sky fibre is softened
a little (a 0.8 blend with Lanczos would restore it if the founder sees plastic on device); verify on the
real portrait plate on an iPhone before wiring in.
