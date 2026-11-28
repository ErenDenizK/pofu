# 0033. The sky gradient follows the colour script

- **Status:** Accepted (amends [0025](0025-sky-sets-split-from-the-painting.md) for the gradient field only)
- **Date:** 2026-11-28

## Context

ADR-0025 ships a sky set whose layers are "never graded, only resampled". Home's golden gradient therefore carries
the golden master's violet (top eighth L64 C39 h305; frames L65 C36 h306), while the colour script
(`design/art/colour-script.json`, golden) asks for zenith `#E2ADC7` (L76 C24 h346) and horizon `#FFCAB3`, and the
liked golden reference is pink (L72 C31 h340). The founder asked for a softer, pastel, Vice City pink at golden hour.

## Options considered

1. **Repaint the golden master's sky:** days of generation for a smooth field, and every plate drawn over it changes.
2. **Refit the gradient field at export, to the script's zenith and horizon:** the field is smooth and has no painted
   detail, so nothing is lost. The script's colours are already about half way to a full Vice City pink (C47), which
   reads as synthwave.
3. **A whole-frame pastel grade:** costs Pofu's chroma and separation in every light. Rejected (art pass D5).

## Decision

A sky set's gradient field may be refit to its light's colour-script zenith and horizon at export (option 2):
in CIELAB, row by row, the field moves by the gap between its median and the line from zenith (top row) to horizon
(the lowest row that shows). Layers with painted detail (clouds, isles, sea, island) are still only resampled and
are unmixed against the painting's own field, so their soft edges carry no old-coloured air. Home's golden light
uses it (`fitScript` in `design/art/plates/home/sky/sky.json`); day and night are exported as before. The golden far
tile also loses its shade lobes (alpha under 0.6 and more than 2 L* below the sky behind), because they are the
painting's violet shade on a sky that is no longer violet. Frame-zero identity for golden is measured against the
refit sky, so it is checked from the island box down.

## Consequences

The golden sky is pink and soft with no dark cut-out clouds. The art gate's `sky.golden` measures it against the
script. A later light that wants the same treatment adds itself to `fitScript`; a painted sky detail is never graded.
