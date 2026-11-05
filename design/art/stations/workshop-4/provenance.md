# station__workshop-4

- **Approved:** 2026-11-05T18:57:40+00:00 from batch `batch-03-home-island`, job `workshop-4`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T18:55:26+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-4.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take4 is the only eligible take after the single retry pair: all source and locked borders have zero alpha, the full workshop/bench/vice remain within transparent margins and the short round cream-stone chimney with rose-copper cap is correctly on the left roof with no smoke. Four-blade ridge pinwheel, five-tool pegboard, doorway, roof tiles and bench are preserved against the newly published workshop-3 parent. Source-border exclusions: take1 bottom18 left33, take2 left6, retry3 bottom16 left21 nonzero alpha pixels. No cleanup, third round or QA waiver. Re-promote only the explicitly queued job with force; own Harmony file and content node are included. Padded L1 origin remains documented in earlier chain provenance.

## References

- `design/art/stations/workshop-3/workshop-3.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint b785b9f9ec508871)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a short, round chimney of soft cream stones on the left side
of the roof, with a small rose-copper cap. No smoke (the app adds
it).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 48 (R1 51))
- pass: value_floor (lightness p5 48 (R1 59))
- pass: detail_budget (detail at display size 2.1 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.9, p95 5.7, off-palette 0.1% (top: #AA6622 (0.0%), #995522 (0.0%)))
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 78 against the world reference (outliers: L_p98, edge))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.03 of the parent level (drift compounds along a chain))
