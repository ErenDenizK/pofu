# prop__bridge-east

- **Approved:** 2026-11-02T15:02:45+00:00 from batch `batch-03-home-island`, job `bridge-east`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-02T14:57:55+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `bridge-east.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/masters/island-main-l-v2/island-main-l-v2.png`: The large island: match its painting, light and camera (do not draw it).
- `design/art/masters/islet-east/islet-east.png`: The east islet the bridge leads to: same style and colors (do not draw it).

## Prompt (fingerprint 73fb39c3c16f7575)

```text
REFERENCES (attached, in this order):
1. The large island: match its painting, light and camera (do not draw it).
2. The east islet the bridge leads to: same style and colors (do not draw it).

A short rope bridge for the same diorama, on its own: six broad
planks of soft honey wood hung on two soft cream rope lines that
sag gently between a pair of short, stubby wooden posts at each
end. Seen from the same low front three-quarter camera, it runs
from the lower left of the canvas to the upper right, rising
gently, so the far end is higher and a little smaller. Chunky,
toy-like proportions; the ropes are thick and soft, never thin
lines. The posts end in the air (the islands are separate
images). Centered, with a clear transparent margin.

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

AVOID: glossy or metallic shine, specular glints, reflections, hammered
or dimpled metal, wood grain, fine surface texture, photorealism, a 3D
render look, plastic or vinyl, high contrast, black or near-black
shadows, saturated or neon colors, outlines, cel shading, text, letters,
numbers, logos, watermarks, characters or animals, a floor, a background,
a ground shadow.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 26 (R1 51))
- pass: value_floor (lightness p5 73 (R1 59))
- pass: detail_budget (detail at display size 1.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 7.8)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 0.7, p95 1.6, off-palette 0.0%)
