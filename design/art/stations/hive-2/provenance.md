# station__hive-2

- **Approved:** 2026-11-05T20:12:57+00:00 from batch `batch-33-home-showcase`, job `hive-2`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-05T20:07:25+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `hive-2.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. After the sole retry, take4 is the only eligible source. It adds the smaller honey-coiled skep on its own stump behind/right and exactly two front lavenderclumps, five total distinct leaf-base groups including the three original groups. Original primaryskep/stump/steppingstone/canvas placement are kept. Independent source/locked review confirms no bees/honey/text or added opaque item. All hard QA passes for4: editstability0.9506,chroma1.0865; lock1.3046,Harmony51.9 warning retained. T1 hardpalette4.1434, T2 numericalwarnbutonlyfourclumps hence manualexcluded, retry3 hardstation_anchor from an actual18x18opaque white cornerblock. That generatedartifact is an ordinary rejectedtake, not sourceidentity/uploadcorruption; no cleanup. T4 dramatic rawviewerfringes are lowalpha(abovebodymax2), locked alphaover24 has oneconnectedforegroundcomponent. No invented workshop-border rule. Parenthive1 is exactbyte-verified localuntracked cache of uploadverified PR204 commitd750e81ff4f3271f506d593dd206dbf31a63452a; externalcache/proof excludedfromthiscommit. Userauthorizes fetching approved parent from parallelbranch beforemerge; ownhive2 Harmonymeasure/check/raw/provenance/contentrequired. Auto-pickedbyQA; founderreviewpending.

## References

- `design/art/stations/hive-1/hive-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint ddec932ab52fe196)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Add a second, smaller straw skep of the same golden-honey coils on its own low stump just behind and to the right of the first, and two more small clumps of lavender at the front. The first skep, its stump and the stepping stone stay as they are.

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
- warn: chroma_ceiling (chroma p95 60 (R1 51))
- warn: light_values (day/subject: L p2 31 (at most 22), p98 88 (at least 90), spread 57 (at least 60))
- pass: light_median (day/subject: median L 73 (band 55-90))
- pass: light_haze (day/subject: dark-channel haze 0.08 (at most 0.20; no true dark means a wash))
- pass: light_contrast (day/subject: p75 local contrast 6.9 (at least 3.5))
- pass: detail_budget (detail at display size 2.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.3)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- warn: palette_drift (mean dE 4.1, p95 13.6, off-palette 7.4% (top: #888855 (1.5%), #AA88AA (1.2%)))
- pass: station_anchor (on the parent's anchor)
- warn: harmony (harmony score 52 against the world reference (outliers: C_p95, L_p2, L_p98, detail, edge))
- pass: edit_stability (95% of the parent level unchanged)
- pass: edit_chroma (chroma x1.09 of the parent level (drift compounds along a chain))
