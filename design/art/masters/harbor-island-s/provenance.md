# world__harbor-island-s

- **Approved:** 2026-11-03T00:51:15+00:00 from batch `batch-14-harbor`, job `harbor-island-s`, take t1
  of 2 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-03T00:47:58+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `harbor-island-s.webp` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Both takes pass manual real-alpha/world review: wide empty cream/sage lawn, only the requested right-hand honey-wood pier with two rope-wrapped posts, soft coral earth, few pebbles/roots, no water/boat/stations/characters. Camera and earth depth match the home family (0.2174/0.2075, target within0.32); take1 has lowest lock load0.6694, harmony83.9. Full1536x1024 master stays lossless with no resizing. Temporary decoded reference PNGs are hidden only during Harmony catalog generation, then restored.

## References

- `design/art/masters/island-main-s/island-main-s.png`: The home island: the same painting, the same low camera (about 20 degrees), the same softness, lights, scale and depth of earth. Paint a sibling of it, not a copy.
- `design/art/masters/pofu-hamster-base-v1/pofu-hamster-base.png`: Style reference only (no characters): the hamster's soft painting and pastel colors.
- `design/reference/palette-card-world-day.png`: The palette card: use only these colors (and mixes of them).

## Prompt (fingerprint 37abd6e24818be18)

```text
REFERENCES (attached, in this order):
1. The home island: the same painting, the same low camera (about 20 degrees), the same softness, lights, scale and depth of earth. Paint a sibling of it, not a copy.
2. Style reference only (no characters): the hamster's soft painting and pastel colors.
3. The palette card: use only these colors (and mixes of them).

A sibling of the attached floating island, for a cozy mobile game:
İskele, a harbor island. Same size, same low camera and same
earth body as the attached island, but:
- The lawn is a wide, flat, empty oval of soft cream-sand and
  pale sage, filling about 80% of the image width, with nothing
  on it.
- On the right a short, chunky wooden pier of honey planks juts
  out past the lawn's edge, with two stubby round mooring posts
  with coiled cream rope, at the height of the lawn, ending in
  open air (no water, no boat).
- The earth body underneath is a soft, rounded underside in warm
  coral-tinted earth with two or three gentle strata, no deeper
  than the attached island's.
- Keep the same few cream pebbles, and three or four thin
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

AVOID: characters, stations, a boat, buildings, water, sky, clouds, background, ground shadow, saturated colors, a deep cone-shaped underside, text.

Output: one image, transparent background PNG, landscape 1536 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1536x1024)
- pass: chroma_ceiling (chroma p95 38 (R1 51))
- pass: value_floor (lightness p5 69 (R1 59))
- pass: detail_budget (detail at display size 1.4 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 0.7)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.5, p95 3.2, off-palette 0.0%)
- pass: depth_ratio (earth depth / width 0.22 (at most 0.32))
- pass: lawn_chroma (lawn chroma p95 23 (palette meadow 38))
- pass: harmony (harmony score 84 against the world reference (outliers: C_p95))
