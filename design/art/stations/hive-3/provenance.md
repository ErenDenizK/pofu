# station__hive-3

- **Approved:** 2026-11-05T20:29:26+00:00 from batch `batch-33-home-showcase`, job `hive-3`, take t2
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T20:19:12+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `hive-3.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Take2 is the only eligible source across all4 takes. It adds two rounded rectangular cream hive-body boxes beneath a separate sunflower-bearing cream gable-end cap and sunflower-yellow roof, behind/left of the two skeps. A gable cap is part of the requested roof, not a third body box; this reasonable construction interpretation was confirmed by independent source/locked review and root inspection. The initial conservative review overcounted that cap and requested the sole retry; preserve that historical decision and all4sources, but supersede the mistaken manual exclusion of2 before picking. No further generation, threshold waiver or pixel edit. T1 hardchroma61.1, T3 hardchroma61.9 pluspalette4.4776, T4 hardchroma60.1; T2 C9558.9 passes, lock1.3192,Harmony53.7warning retained, editstability0.9966/chroma1.0184 pass. Both skeps/ownstumps/frontstone/all5lavender groups and source framing remain; new roof below guide heightbar. Tiny greenleaf at new box foot belongs to that base, not a missing lavender group. Parent is uploadverified hive2take4 commit0c7e627db87d9dd2c981a2072672858fefee5799. OwnHarmonymeasure/check/raw/provenance/contentrequired. Auto-pickedbyQA; founderreviewpending.

## References

- `design/art/stations/hive-2/hive-2.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint c2e6833bc6b940b4)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a small painted wooden hive box behind the two skeps, on the left: a short stack of two rounded cream boxes with a soft sunflower-yellow gabled roof and one tiny painted sunflower on the front (a simple round shape, no letters). It is no taller than the height bar. Everything else stays.

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 59 (R1 51))
- warn: light_values (day/subject: L p2 31 (at most 22), p98 89 (at least 90), spread 58 (at least 60))
- pass: light_median (day/subject: median L 73 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.10 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 7.1 (at least 3.5))
- pass: detail_budget (detail at display size 2.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 3.7, p95 12.1, off-palette 5.1% (top: #888855 (0.9%), #AA88AA (0.8%)))
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 54 against the world reference (outliers: C_p95, L_p2, L_p98, detail, edge))
- pass: edit_stability (100% of the parent level unchanged)
- pass: edit_chroma (chroma x1.02 of the parent level (drift compounds along a chain))
