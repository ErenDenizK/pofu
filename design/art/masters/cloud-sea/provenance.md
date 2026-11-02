# world__cloud-sea

- **Approved:** 2026-11-02T15:00:06+00:00 from batch `batch-04-sky`, job `cloud-sea`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:58:39+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `cloud-sea.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/cloud-1/cloud-1.png`: The approved large cloud: paint the sea of clouds with exactly its billows, light, colors and softness.
- `design/art/masters/cloud-4/cloud-4.png`: The approved long cloud: the same calm, horizontal rhythm.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint dbc1568684050588)

```text
REFERENCES (attached, in this order):
1. The approved large cloud: paint the sea of clouds with exactly its billows, light, colors and softness.
2. The approved long cloud: the same calm, horizontal rhythm.
3. The palette card: use only these colors (and mixes of them).

A wide band of soft, dense, plump clouds seen from slightly above,
like a calm sea of clouds, for the bottom of the same sky. The
band fills the bottom 40% of the image from edge to edge; its top
edge is a gentle, even row of rounded billows of similar size, and
everything above it is fully transparent. The left and right edges
must tile seamlessly when two copies are placed side by side: the
band has the same height and the same shading at both edges, and
no billow is cut in half there. Calm and low in detail, because
interface buttons float over it.

STYLE: soft painterly 2D illustration from the same picture book as the
attached hamster: the same gentle airbrushed shading, the same light,
high-key values and the same milky pastel colors. Simple, rounded, chunky
shapes with few parts; fewer, larger shapes, because this is seen small on
a phone. Every material is painted matte, as a soft form with broad,
smooth value changes: wood without grain, metal without hammering or
reflections, glass as a soft tinted shape, cloth without weave. At most
one small, soft highlight per object; no glints, no shine. Colors are
muted and lifted toward cream; the darkest shadow is a warm mid-brown,
never near black. Warm diffused key light from the upper left, a faint
warm rim light along the right edge, soft ambient shadow only where forms
touch. Clean, calm, uncluttered. No outlines, no hard edges. No text, no
letters, no numbers, no logos, no watermark, no border, no frame, no
sticker outline.

AVOID: islands, mountains, the sun, rays, birds, a sky color above the band, a dark bottom edge, a big single billow that breaks the row, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 7 (R1 51))
- pass: value_floor (lightness p5 85 (R1 59))
- pass: detail_budget (detail at display size 0.5 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 2.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.9, p95 1.9, off-palette 0.0%)
