# station__harbor-ferry-1

- **Approved:** 2026-11-04T23:18:15+00:00 from batch `retry-2026-11-04`, job `harbor-ferry-1`, take t4
  of 4 considered.
- **Generating account:** Founder's uncle's ChatGPT plan, used by the founder with permission
  (chatgpt-plan).
- **Tool:** codex-cloud;
  generated 2026-11-04T23:03:34+00:00.
- **Post-processing (human-authored, documented per art bible section 13):**
  canvas fit, registration {"dx": 17, "dy": -3}, style lock preset `lock-light` (style_lock.json v2).
- **Files:** `raw.webp` is the take as generated (webp lossless), kept so the look can be re-locked; `harbor-ferry-1.png` is the locked master the app and later edits use.
- **Review note:** auto-picked by QA; founder review pending. Queue operation refit-2026-11-04, no generation: re-post all4 verified retained original PNGs using PR154 and the manifest max_width640. All hard QA and station anchors now pass; fit scales0.8779,0.9453,0.8707,0.8355 stay above0.6. Select take4 at lowest eligible lock load1.0874; its solid width639px respects640 and ground is900. Visual and native28 review show a short sea-blue/cream vapur, one coral funnel, cabin round windows, a plain coral flag, flat waterline, no water/wake/smoke/shadow or guide residue. Updated guide-fit.json preserves old measurements and records current fitting. Commit fit/raw/Harmony, un-cut only this asset and link the harbor consumer; ferry2 stays skipped until lead review. Auto-picked by QA; founder review pending.

## References

- `design/art/templates/station-guide.png`: The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
- `design/art/masters/island-main-s/island-main-s.png`: The home island: match its camera angle, softness and colors.
- `design/art/stations/tea-stall-1/tea-stall-1.png`: The approved tea stall: match its painting, finish, scale and colors exactly (do not draw the stall).
- `design/reference/palette-card-world-props.png`: The palette card for props: use only these colors (and mixes of them).

## Prompt (fingerprint 0546b96661a2444a)

```text
REFERENCES (attached, in this order):
1. The composition guide: footprint ellipse, anchor cross and height bar. Follow it, then remove it.
2. The home island: match its camera angle, softness and colors.
3. The approved tea stall: match its painting, finish, scale and colors exactly (do not draw the stall).
4. The palette card for props: use only these colors (and mixes of them).

A small Istanbul-style passenger ferry (vapur), toy-like and
chunky, for the island diorama: a short, plump hull in soft sea
blue with a cream stripe and softly rounded ends, cut off at the
bottom by one straight horizontal line (it floats level in water
that is not drawn), a low cream cabin with three round windows, one
tall rounded funnel in soft coral with a cream band, and a small
flag on a short mast. Low front three-quarter camera, upright; no
water, no wake, no smoke.

Size (the earlier attempts were far too wide): the ferry is
SMALL. The hull is about 560 px wide in the 1024 px image, the
whole ferry never wider than 640 px, leaving at least 190 px of
empty canvas on each side, and it is as tall as the lower two
thirds of the height bar. It sits inside the guide's ground
ellipse, centered on the cross.

VIEW: the same fixed front three-quarter view as the attached island: a
low camera about 20 degrees above the horizon, so you see the front of
the object fully and only a narrow sliver of its top (a round tabletop
reads as a flat oval about a third as tall as it is wide). Follow the
attached guide exactly: the object stands on the magenta ground ellipse,
centered on the magenta cross, its front edge on the front of the
ellipse, no taller than the magenta height bar. Then remove the guide
completely: no ellipse, no cross, no bar, no magenta, no grid may remain
in the output.

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

LIGHT (hour: day, layer: subject). Bright, clear, toy-like.
Paint this under the clear daylight cell: key light #FFF6EC from the upper left, soft cool fill #BFD6EE, a faint rim #FFE9C9 on the far edge. The game relights and grades this sprite for the hour, so keep the light neutral and readable. Do NOT paint a cast shadow on the ground or onto a background: only soft contact occlusion where forms touch.
VALUES: haze is depth, not a filter over the whole frame. The subject plane uses the full value range: true darks in the deepest recesses (eyes, door, soil, gaps between forms) and clean highlights. Contrast falls only with distance from the subject. A soft, gentle look means soft local colour and soft edges, never lifted blacks, a milky veil or a grey-white wash.
This is the SUBJECT plane: no atmosphere at all, the strongest contrast and the deepest darks in the picture.

Output: one image, transparent background PNG, square 1024 x 1024.
```

## QA at approval

- pass: transparency (source has an alpha channel)
- pass: canvas (1254x1254 scaled x0.817 into 1024x1024)
- pass: chroma_ceiling (chroma p95 39 (R1 51))
- warn: light_values (day/subject: L p2 56 (at most 22), p98 93 (at least 90), spread 37 (at least 60) (warn-only until the founder has seen the light pilot))
- pass: light_median (day/subject: median L 78 (band 55-90))
- warn: light_haze (day/subject: dark-channel haze 0.37 (at most 0.20; no true dark means a wash) (warn-only until the founder has seen the light pilot))
- pass: light_contrast (day/subject: p75 local contrast 4.6 (at least 3.5))
- pass: detail_budget (detail at display size 1.9 (R1 5.3))
- pass: lock_load (the lock moved colors by mean dE 1.1)
- pass: no_guide_magenta (0 guide-magenta pixels (per 1024^2))
- pass: palette_drift (mean dE 1.8, p95 5.8, off-palette 0.6% (top: #667777 (0.4%), #668877 (0.2%)))
- pass: station_anchor (on the anchor)
- pass: harmony (harmony score 81 against the world reference (outliers: C_p95, edge))
