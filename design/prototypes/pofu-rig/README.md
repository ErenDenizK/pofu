# Pofu rig prototype

A browser-based, dependency-free prototype of the code-native Pofu rig
([ADR-0006](../../../docs/adr/0006-code-native-companion-rendering.md),
[character bible](../../../docs/brand/character.md)).

## Why a browser prototype first

The agent environment has no Xcode, but it can render web pages headlessly
and inspect screenshots. Iterating on geometry, proportions, and expressions
here is an order of magnitude faster than round-tripping through Swift
builds. Once the founder approves the look, the geometry and parameter
semantics are ported one-to-one to SwiftUI in `PofuCompanion`.

## Usage

Open `index.html` in any browser.

| Query | Effect |
|---|---|
| _(none)_ | Interactive editor: state presets, parameter sliders, tap to squish |
| `?sheet=1` | All core states side by side |
| `?state=curious` | Start in a given state |
| `?static=1` | Disable idle animation (deterministic screenshots) |
| `?bg=0` | Hide the scene background |

## Structure

- `BASE_POSE`, `STATES`: the parameter model and state presets.
- `makeTransform`: body space to screen space (ground-anchored squash, lean).
- `bodyPath`: the lobed fluff silhouette; `fluff` controls lobe height and
  regularity (matting).
- `tuftPath`: the curling perçem built from a tapered centerline.
- `renderPofu`: composes scene, shadow, feet, body, rim light, tuft, cheeks,
  eyes, mouth, and accents.
- `Spring`, `behaviorOffsets`, `blinkAt`: motion (springs toward targets,
  procedural breathing, hopping, blinking).

## Iteration log

- **v0.1:** first pass. Critique: the scalloped outline read as a bottle cap,
  the tuft was invisible, texture strokes read as eyebrows, and the tired lid
  read as annoyed. Fixed with bulbous, irregular lobes, calmer bottom lobes,
  a larger tuft in front of the body, clipped rim light instead of strokes,
  and outward-drooping lids. Snapshot:
  [`pofu-states-v0.1.png`](../../../docs/brand/assets/pofu-states-v0.1.png).
