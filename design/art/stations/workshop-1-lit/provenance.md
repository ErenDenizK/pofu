# station__workshop-1-lit

- **Approved:** 2026-11-04T13:22:11+00:00 from batch `batch-07-light`, job `workshop-1-lit`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T13:20:29+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 0, "dy": 0}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `workshop-1-lit.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Authorized 2026-11-04 re-run of workshop-1-lit only. Take1 passes all hard QA and strict manual edit_stability>0.9 at0.9033; take2 fails chroma_ceiling60.5. The selected source and aligned master retain the workshop framing, roof, bench and wood without a visible external light halo or rays; warm lamp/glow is confined to the doorway interior. Take1 chroma55.9 is an automatic warning, not a failed check. Lowest eligible lock load0.5328; no retry needed. Old batch is grandfathered by the light standard; no prompt or threshold edits.

## References

- `design/art/stations/workshop-1/workshop-1.png`: The image to edit (the approved previous level). Edit it; do not redraw it.

## Prompt (fingerprint 402bc9b40f2c9a5e)

```text
REFERENCES (attached, in this order):
1. The image to edit (the approved previous level). Edit it; do not redraw it.

Light the workshop from inside: the open, round-topped doorway now
shows a warm honey-amber glow filling its opening, brightest low
in the middle, painted as soft broad shapes with a hint of a
hanging lamp's round shape inside. Only the doorway's inside
changes: no glow, light or color change on the wood, the roof,
the bench or anything else (the app adds the glow and the light
pool around it).

KEEP: everything not named above stays exactly the same as in the
attached image: every existing part, its shape, color, position and size,
the canvas, the camera, the light and the painting style. Do not zoom out
or reframe: if a new part does not fit, make the new part smaller, never
the existing ones. Outside the new parts, the result must line up with
the attached image pixel for pixel.

AVOID: light rays, a glow outside the doorway, light on other objects, blown yellow-white highlights, text.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- warn: chroma_ceiling (chroma p95 56 (R1 51))
- pass: value_floor (lightness p5 59 (R1 59))
- pass: detail_budget (detail at display size 1.6 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.5)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.3, p95 5.7, off-palette 0.0%)
- pass: station_anchor (on the parent's anchor)
- pass: harmony (harmony score 82 against the world reference (outliers: edge))
- pass: edit_stability (90% of the parent level unchanged)
- pass: edit_chroma (chroma x0.97 of the parent level (drift compounds along a chain))
