# Colour script v1: light and colour design

Status: implemented (look round 3, 2026-11-02). Data:
`design/art/colour-script.json` (light) and `design/art/materials.json`
(local colour). Generator: `tools/assets/colour_script.py` writes
`PofuWorld/Look/ColourScript+Generated.swift`; CI fails when it is stale.
This is v1 of the plan in `docs/research/pro-game-craft.md` §4 (PR #73);
the cells and the material library are the same ones, as data.

## Why

The founder liked the rose copper of the original çaydanlık better than
round 2's warm shift, and warned that harmony must not average everything
toward a reference: "we should do a proper colour and light design".
Round 2 also left two measured faults: at night Pofu and the residents
turned lavender (their fur's hue moved from about 69 to about 300), and
the unwell sky stayed pale because only the world, not the sky, was
graded for it.

## Three layers, owned separately

| Layer | What it is | Where |
|---|---|---|
| Local colour | The colour of things under neutral light: rose copper, honey wood, milky glaze, sage lawn, Pofu's cream fur | `materials.json` (hue and chroma ranges); the masters, corrected by harmony only for generator errors |
| Light | Per hour: key (colour, intensity, direction), fill, shadow hue, rim, practicals (ember, window), fog on the far isles, sky, cloud sea | `colour-script.json` cells → `ColourCell` |
| Grade | The camera's residual: levels, contrast, saturation trim, vignette, the unwell mood | each cell's `grade`, the unwell state's overlay |

## The cells

Five hours on one schedule shared by the living sky and the world's light
(minute keys, 30-minute blends): night until 05:15, dawn 05:45–07:15, day
07:45–17:15 (the sun crosses), golden 17:45–19:15, dusk (the blue hour,
new) 19:45–20:15, night from 20:45. Bedtime is always night.

| Cell | Key | Practicals | Feeling |
|---|---|---|---|
| Dawn | low from the left, peach `#F4C7A4`, 0.7 | ember low | hush, promise |
| Day | high upper left, warm white `#FFF6EC`, 1.0 | off | bright, clear, toy-like |
| Golden | low from the right, honey `#F7C873`, 1.1 | ember on | the day's reward |
| Dusk | sky key from above, violet `#8F86C9`, 0.5 | ember, window on | coming home |
| Night | moon, lilac `#B8A8B1`, 0.35 | ember, window carry the frame | safe, cozy |

**Vivid pass (2026-11-05).** The founder found the island pale and heavy on
his iPhone ("colour and light"). Day went to saturation 1.32 and contrast
1.16 (was 1.14 and 1.10) with a lighter vignette (0.12), golden to 1.30 and
1.12, dawn to 1.22, and the night and dusk saturation cuts eased (0.72 and
0.90 from 0.62 and 0.82) so they stay moody but readable. Blacks are still
never lifted. The depth of field lost most of its radius at the same time
(`GraphicsSpike.field`): it was blurring the island's own ground.

**Unwell** (wellbeing 55 → 30 ramps in) is overcast, not grey fog: the
world's grade deepens and halves its saturation as before; the sky turns
cooler, about 12 % darker and lower in chroma (never brighter than the
hour's well sky); the door's window stays lit by day ("care is still
here"); Pofu keeps most of his colour (saturation ×0.78 of the hour's) and
his contrast, so he is quieter but readable (ADR-0017).

## The rule for Pofu (and the residents)

They take the hour's key and fill, never the world's saturation cut or
contrast push: each cell's `character` grade has saturation ≥ 1 (the
generator refuses less). They are drawn in their own layer, graded per
sprite, and lit by a soft rim: from the nearest practical when it
outshines the key (Mochi by the ember at night), otherwise from the key's
side in the cell's rim colour. At night Pofu's fur keeps its hue within a
few degrees of the day's (tested in `ColourScriptTests`, measured on the
frames by `frame_metrics.py`).

## The rose copper

The copper is a protected accent: `rose-copper` in `materials.json`, hue
50–57, chroma 38–50, pink-leaning, never brass. Harmony measures it on
the çaydanlık and pulls it back only if the generator drifts out of that
range, to the range's nearest edge. Round 2's shift to hue 59 is reverted;
the kettle reads warm at night because the ember's pool lights it (an
additive light masked by the stall's alpha), which is how copper beside a
coal fire looks. `look-teapot.jpg` shows the three versions (original
rose, round 2's warm, the colour script's lit rose) by day and night;
round 2's bake stays as `WorldLook.ArtSet.round2Copper` to compare.

## Harmony v2 (this round's part)

- Corrects only technical defects: value range against the approved
  island, white-balance drift, chroma lost along a station chain.
- Never moves a material toward another or toward a target hue.
- Frame checks: `grade-targets.json` now also checks Pofu's hue and chroma
  at night and unwell against the day frame, and the unwell sky's
  lightness and warmth.

Not yet (pro-game-craft §4.3–4.6): paintovers per cell, pseudo-normals so
the key wraps round forms, gamut masks and accent budgets measured on
frames, low wellbeing as its own cell, a lantern practical (no lantern art
exists yet).

## How a colour decision is made

1. Change the cell or the material range in the JSON.
2. `python3 -I tools/assets/colour_script.py generate` (and `harmony.py
   measure` plus `preblur.py app` for a material range).
3. CI renders `look-script` (the five cells at Home and the Island),
   `look-compare` and the grade metrics; compare against the targets.
4. The founder sees the strip and says yes or no.
