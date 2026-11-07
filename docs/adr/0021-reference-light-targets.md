# 0021. Reference light targets: the light standard follows the liked references

- **Status:** Accepted (amends [0018](0018-visual-system-v1.md) §5 and replaces the light standard v1's value rules)
- **Date:** 2026-11-07

## Context

The founder (2026-11-07) asked to copy the references he picked one to one
in light and colour: I1's seasons for the day, golden, rain and snow light;
the gezgin f2 and Revontuli nights for night, and not the Tam Çiçek night
("too contrasty, too bright"). [Reference look](../research/reference-look.md)
measured them: every value sits between L* 50 and 97 by day; at night only
the sky is dark (liked nights: frame p50 72-77, chroma about 20, sky L* 25-36,
cloud sea 73-85); the cloud sea is the brightest large surface.

Our light standard v1 (`docs/design/light-standard.md`, 2026-11-03), built on
ADR-0018 §5's "less contrasty island take" read as "soft colour, never lifted
blacks", demands the opposite: day p2 <= 22, haze <= 0.20, night median
18-50. **All three liked references fail it**, every new Codex batch is
pushed away from them, and the runtime night (built to the same idea) crushes
the island to L* 13-38 with a near-black sea.

## Options considered

1. **Keep v1, tune the runtime only.** Cheap; art keeps drifting back to
   true darks and the QA keeps rejecting the look the founder wants.
2. **Targets measured from the references, per time-of-day cell** (chosen).
   One source of truth for art QA, the grade tool and the runtime re-key.
3. **No numeric standard, judge by eye.** The founder could not judge his
   own earlier fixes later (decisions §10.1.7); numbers are the memory.

## Decision

1. The light standard's value rules are **replaced** by targets measured
   from the founder-picked references, per colour-script cell x layer
   (`design/art/light-standard.json` v2, which lists the references):
   - subject region: a **floor** for the darks (L* p5 >= 50 day, 45 night),
     a median band (day 74-92, night 66-88), lights reaching cream
     (p98 >= 85-90), and a **local-contrast band** (night 1.5-5.0: the Tam
     Çiçek night, 6.6, fails it);
   - opaque takes: the sky (top eighth; night L* 24-46), the **cloud sea as
     a reflector** (bottom eighth; L* >= 82 day, >= 70 night) and at most 3 %
     of pixels below L* 30 under the sky.
   "Never lifted blacks", "haze <= 0.20" and "the subject uses the full value
   range" are gone. The prompt's LIGHT block asks for the reference envelope.
2. **Night is a hue change, not a value drop.** Only the sky goes dark; the
   island and the cloud sea stay light, shadows turn violet, lights stay
   cream, contrast and chroma soften. The runtime night and dusk cells
   (`colour-script.json`) are re-keyed to this; day stays as #324 left it.
3. **Practicals are atmosphere:** a lamp's halo spreads 3-4x its body.
4. Every liked reference must pass its cell; a test keeps it so. ADR-0018
   §5's style target now means this envelope.

## Consequences

- The standard now rejects what it used to demand: the current earth band
  (p5 ~26), the game's day Home frame (local contrast 8.3) and the old night frames fail.
  `tools/art/grade_take.py` lifts a take into the envelope (a toe lift toward
  the air's colour, softening) instead of dehazing it.
- `enforce` stays false (warnings) until the next production batch has been
  graded against v2; the founder sees the comparison sheet first.
- Still owed (reference-look §5): the day grade's contrast 1.16 and
  saturation 1.32, `style_lock`'s value floor 14, the earth-band art, a
  painted night state per island, and characters lit by practicals (V4).
- Our art is darker than the references, so the grade alone cannot reach the
  reference night (island p50 about 67 against 76); the paint has to follow.
