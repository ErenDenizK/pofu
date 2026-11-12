# tools/review: cheap visual review

`sheet.py` turns many images, a video, or two versions of one image into a
**single small JPEG** (long side at most 1400 px, quality 80), so a review
costs one image read instead of dozens.

**The rule.** Pixels first, by fresh eyes: a critic
(`.claude/agents/critic.md`) looks at 1:1 crops and lists defects. Then
the lead reviews **one sheet per review** with that list, never piles of
full-size frames. Numbers (harmony, `frame_metrics`, the screen checks)
guard against regressions and never clear a frame by themselves.

```sh
# a labeled contact sheet of many images
python3 -I tools/review/sheet.py montage a.png b.png c.png --max 1400 --cols 3 -o sheet.jpg

# N keyframes from a video (scene changes, topped up with even spacing)
python3 -I tools/review/sheet.py keyframes clip.mp4 -n 6 -o strip.jpg

# before/after: side by side plus a difference heatmap; prints the numbers
python3 -I tools/review/sheet.py diff before.jpg after.jpg -o diff.jpg
```

`keyframes` needs `ffmpeg` (`apt-get install ffmpeg`); if it is missing it
falls back to the one bundled in `imageio-ffmpeg` (`pip install imageio-ffmpeg`).
`diff` prints mean and max absolute difference (0 to 255), the percentage
of pixels that changed by more than 16 levels, and RMSE; the second image
is resized to the first when sizes differ.

Tests: `python3 -I -m pytest -q tools/review/tests`.
