# world__island-main-s

- **Approved:** 2026-11-01T20:27:33-05:00 from batch `batch-01-slice`, job `island-main-s`, take t2
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-01T20:26:48-05:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `soft-lock` (style_lock.json v1).
- **Files:** `raw.png` is the take as generated; `island-main-s.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending

## References

- `design/art/tests/2026-11-01/world__island-main-s_take1.png`: The image to edit: my favorite take of the floating island. Keep its soft, light painting, its warm light, its round door and its pebbles.
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only (no characters): the hamster's soft painting, light and pastel colors.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint a72a328c7c2fde8d)

```text
REFERENCES (attached, in this order):
1. The image to edit: my favorite take of the floating island. Keep its soft, light painting, its warm light, its round door and its pebbles.
2. Style reference only (no characters): the hamster's soft painting, light and pastel colors.
3. The palette card: use only these colors (and mixes of them).

Edit the attached floating island into a flatter, wider diorama for
a cozy mobile game. Change only its proportions and its lawn:
- The lawn is a wide, flat, empty oval filling about 85% of the
  image width, seen from a low camera about 20 degrees above the
  horizon, so the oval is about 0.3 times as tall as it is wide.
- The lawn is a soft, muted sage-to-spring green, milky and
  pastel, painted as a smooth velvety surface: only a hint of
  short grass along the darker front lip, no individual blades
  across the lawn.
- The earth body underneath is about half as deep as now, no
  deeper than 30% of the island's width: a soft, rounded
  underside, not a cone. Light honey and caramel earth with two or
  three gentle strata.
- Keep the tiny round wooden door with its round window and ledge
  on the lower left, a few cream pebbles and three or four thin
  dangling roots.

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

AVOID: characters, plants or objects on the lawn, water, sky, clouds, background, ground shadow, saturated or yellow-green grass, a deep cone-shaped underside, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 35 (R1 51))
- pass: value_floor (lightness p5 65 (R1 59))
- pass: detail_budget (detail at display size 2.3 (R1 5.3))
- warn: lock_load (the lock moved colors by mean dE 11.3 (prefer a take that needs less))
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.7, p95 5.5, off-palette 0.2% (top: #888866 (0.1%), #998866 (0.1%)))
- pass: depth_ratio (earth depth / width 0.20 (target <= 0.30))
- pass: lawn_chroma (lawn chroma p95 26 (palette meadow 38))
