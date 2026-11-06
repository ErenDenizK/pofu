# Koke prototype: the first wonder island in the game

**Status:** spec by the lead, 2026-11-06. Implements
[game plan §10](../product/game-plan.md#10-what-changes-in-code-and-docs-in-order)
steps 1 and 3 for one island, so the founder can play a wonder island
end to end. Art arrives from Codex (`batch-39-koke-production`); every
piece has a code placeholder that swaps in by name.

## 1. Rules (from the docs, made concrete)

| Rule | Value |
|---|---|
| Kind | main-story island, gentle register ([healing arc](island-healing-arc.md)) |
| Rumour | the first tended day ≥ 5 with the harbor open: a snoring mossy hump on the horizon, seen from the harbor; Pofu says one line |
| Arrival | the next tended day after the rumour |
| Stages | 0 (stuck) to 4 (healed). A visit advances one stage, at most one stage per day, and only on a day with at least one resisted reach (quiet days are the effort). No timer, never expires, a skipped day only pauses |
| Beats | one short line per stage from the duo (Pofu or Mochi), Turkish first; stage 3 is the turn (Mochi reads the carved stone); stage 4 is wordless |
| Gift | on stage 4: moss decor at home (`material-moss` placeholder until the art), Koke's faint light on the harbor horizon from then on |
| Seeds | none; islands never pay seeds |

Typical user: rumour about day 5, arrival day 6, healed about day 10.

## 2. Code

**PofuCore** (pure, tested on Linux):
- `WonderIslandID` (`koke` now; others later) and `WonderIslandState`
  (`rumouredOn`, `arrivedOn`, `stage`, `lastAdvanceDay`) in the saved game
  state; old saves decode with an empty map.
- `WonderIslands.advance(state:day:resistedToday:)` and
  `WonderIslands.status(game:day:)` giving rumour / arrived / stage /
  healed, plus the gift flag. `GameScenarioTests` gains the Koke timeline
  for the typical and the light user.

**PofuWorld:**
- A third place on the camera rail: `CameraPlace.koke`, shown in the
  place control only after arrival (the rumour shows the hump on the far
  sky from the harbor; reuse `FarSky`).
- `KokeScene`: the island plate for the stage (`world-koke-island-N`,
  placeholder: the home plate's shape, tinted moss and scaled 0.6), Koke
  (`world-koke-asleep` / `-one-eye` / `-stretch` / `-standing`,
  placeholder: a code-drawn mossy mound with eyes) and the stage's light:
  the world grade's saturation goes 0.4, 0.55, 0.7, 0.85, 1.0 with the
  stage and the first warm practical appears at stage 2 (code does this
  today, so the arc reads even before the art).
- Tapping Koke on a day it can advance plays the stage beat: the duo's
  line in a speech bubble, a soft light swell (reuse the level-up
  ceremony's burst at half strength), haptic `growth`, then the next
  stage. On other days Koke snores and the line says to come back after a
  quiet day.
- Home: the moss gift appears in a decor slot after stage 4; the harbor
  horizon shows Koke's light.

**Content:** lines in `Localizable.xcstrings` (Turkish and English),
written with the `pofu-story` voice rules; placeholders are fine if marked
in the PR.

## 3. Done when

Screenshots: harbor with the rumour hump, Koke at stages 0 to 4 (same
camera), the beat bubble at stage 3, home with the moss gift. Logic tests
cover gating (one stage a day, needs a resisted reach, old saves). The
frame policy holds (settled = 0 Hz).
